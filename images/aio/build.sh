#!/bin/bash
# aio: every environment built in ONE layer with a shared uv cache and hardlinks, so identical wheels
# (torch 2.8 for ComfyUI and avatar, torch 2.7.1 for voice and Ming, NVIDIA libraries with matching
# versions) are stored once. Copying four finished images instead needed more disk than a CI runner has.
set -euxo pipefail
export UV_CACHE_DIR=/opt/uvcache UV_LINK_MODE=hardlink UV_PYTHON_INSTALL_DIR=/opt/python
unset UV_NO_CACHE
CU=https://download.pytorch.org/whl/cu128
T28="torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0"
T271="torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1"
uv python install 3.11

# ---- ComfyUI (default python, /opt/venv)
uv venv --python 3.11 /opt/venv; P=/opt/venv/bin/python
uv pip install --python $P $T28 --index-url $CU
git clone https://github.com/comfyanonymous/ComfyUI /opt/ComfyUI
(cd /opt/ComfyUI && (git checkout -q "${COMFY_REF:-v0.43.0}" || echo "staying on default branch"))
uv pip install --python $P -r /opt/ComfyUI/requirements.txt
cd /opt/ComfyUI/custom_nodes
for r in Kosinkadink/ComfyUI-VideoHelperSuite kijai/ComfyUI-KJNodes kijai/ComfyUI-WanVideoWrapper kijai/ComfyUI-MMAudio city96/ComfyUI-GGUF; do
  git clone --depth 1 https://github.com/$r
done
for d in */; do [ -f "$d/requirements.txt" ] && uv pip install --python $P -r "$d/requirements.txt" || true; done
uv pip install --python $P sageattention==1.0.6 hf_transfer huggingface_hub
uv pip install --python $P $T28 --reinstall --index-url $CU

# ---- avatar (/opt/avatar): LivePortrait, Ditto, TensorRT
uv venv --python 3.11 /opt/avatar; P=/opt/avatar/bin/python
uv pip install --python $P $T28 --index-url $CU
git clone --depth 1 https://github.com/KwaiVGI/LivePortrait /opt/LivePortrait
git clone --depth 1 https://github.com/antgroup/ditto-talkinghead /opt/ditto
( grep -viE '^(torch|torchvision|torchaudio|onnxruntime)' /opt/LivePortrait/requirements_base.txt 2>/dev/null \
  || grep -viE '^(torch|torchvision|torchaudio|onnxruntime)' /opt/LivePortrait/requirements.txt ) > /tmp/lp.txt
uv pip install --python $P -r /tmp/lp.txt
uv pip install --python $P onnxruntime-gpu tensorrt-cu12 cuda-python polygraphy librosa soundfile imageio imageio-ffmpeg \
   scikit-image filetype colored cython huggingface_hub hf_transfer fastapi uvicorn opencv-python-headless
uv pip install --python $P $T28 --reinstall --index-url $CU
uv pip install --python $P "numpy<2.3"

# ---- voice (/opt/voice): Kokoro, Chatterbox, Qwen3-TTS, Pocket TTS, faster-whisper
uv venv --python 3.11 /opt/voice; P=/opt/voice/bin/python
uv pip install --python $P $T271 --index-url $CU
uv pip install --python $P "setuptools<81" wheel numpy soundfile librosa transformers accelerate safetensors huggingface_hub \
   hf_transfer fastapi uvicorn pydantic einops omegaconf conformer diffusers resemble-perth s3tokenizer snac \
   faster-whisper kokoro "misaki[en]" qwen-tts pocket-tts
uv pip install --python $P --no-deps chatterbox-tts==0.1.7
uv pip install --python $P "en_core_web_sm@https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl"
uv pip install --python $P $T271 --reinstall-package torch --reinstall-package torchvision --reinstall-package torchaudio --index-url $CU

# ---- Ming 3.0 TTS (/opt/ming)
git clone --depth 1 https://github.com/inclusionAI/Ming-3.0-tts /opt/Ming-3.0-tts
uv venv --python 3.11 /opt/ming; P=/opt/ming/bin/python
uv pip install --python $P $T271 --index-url $CU
cd /opt/Ming-3.0-tts && grep -viE '^(torch|torchaudio|torchvision)[=<> ]' requirements.txt > req_vgpu.txt
uv pip install --python $P -r req_vgpu.txt hf_transfer
uv pip install --python $P $T271 --reinstall-package torch --reinstall-package torchvision --reinstall-package torchaudio --index-url $CU

# the cache held one copy of every wheel; the environments keep their hardlinks to it
rm -rf /opt/uvcache /tmp/lp.txt /root/.cache

# ---- checks (no GPU here)
/opt/venv/bin/python -c "import torch; f=torch._C._cuda_getArchFlags(); assert 'sm_120' in f; print('comfy', torch.__version__)"
cd /opt/ComfyUI && /opt/venv/bin/python main.py --cpu --quick-test-for-ci
/opt/avatar/bin/python -c "import tensorrt, onnxruntime, torch; print('avatar', torch.__version__, tensorrt.__version__)"
/opt/voice/bin/python -c "import kokoro, faster_whisper, chatterbox, snac, torch; print('voice', torch.__version__)"
cd /opt/Ming-3.0-tts && /opt/ming/bin/python -c "import sys; sys.path.insert(0,'.'); import ming_tts; print('ming ok')"
du -sh /opt/venv /opt/avatar /opt/voice /opt/ming /opt/python 2>/dev/null || true
