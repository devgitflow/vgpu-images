#!/bin/bash
# aio layer A: ComfyUI and avatar, both on torch 2.8. Environments that share a torch build are built in the same layer with a shared
# uv cache and hardlinks, so identical wheels are stored once. Two layers instead of one, so the two
# halves download in parallel on the rented host.
set -euxo pipefail
export UV_CACHE_DIR=/opt/uvcache UV_LINK_MODE=hardlink UV_PYTHON_INSTALL_DIR=/opt/python
export UV_EXTRA_INDEX_URL=https://download.pytorch.org/whl/cu128 UV_INDEX_STRATEGY=unsafe-best-match
unset UV_NO_CACHE
CU=https://download.pytorch.org/whl/cu128
T28="torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0"
T271="torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1"
lock() { uv pip freeze --python "$1" | grep -iE '^(torch|torchvision|torchaudio|triton|nvidia-)' > "$2"; cat "$2"; }
uv python install 3.11

# ---- ComfyUI (default python, /opt/venv)
uv venv --python 3.11 /opt/venv; P=/opt/venv/bin/python
uv pip install --python $P $T28 --index-url $CU
lock $P /opt/torch-comfy.txt
git clone https://github.com/comfyanonymous/ComfyUI /opt/ComfyUI
(cd /opt/ComfyUI && (git checkout -q "${COMFY_REF:-v0.43.0}" || echo "staying on default branch"))
uv pip install --python $P -c /opt/torch-comfy.txt -r /opt/ComfyUI/requirements.txt
cd /opt/ComfyUI/custom_nodes
for r in Kosinkadink/ComfyUI-VideoHelperSuite kijai/ComfyUI-KJNodes kijai/ComfyUI-WanVideoWrapper kijai/ComfyUI-MMAudio city96/ComfyUI-GGUF; do
  git clone --depth 1 https://github.com/$r
done
for d in */; do [ -f "$d/requirements.txt" ] && uv pip install --python $P -c /opt/torch-comfy.txt -r "$d/requirements.txt" || true; done
uv pip install --python $P -c /opt/torch-comfy.txt sageattention==1.0.6 hf_transfer huggingface_hub

# ---- avatar (/opt/avatar): LivePortrait, Ditto, TensorRT
uv venv --python 3.11 /opt/avatar; P=/opt/avatar/bin/python
uv pip install --python $P $T28 --index-url $CU
lock $P /opt/torch-avatar.txt
git clone --depth 1 https://github.com/KwaiVGI/LivePortrait /opt/LivePortrait
git clone --depth 1 https://github.com/antgroup/ditto-talkinghead /opt/ditto
( grep -viE '^(torch|torchvision|torchaudio|onnxruntime)' /opt/LivePortrait/requirements_base.txt 2>/dev/null \
  || grep -viE '^(torch|torchvision|torchaudio|onnxruntime)' /opt/LivePortrait/requirements.txt ) > /tmp/lp.txt
uv pip install --python $P -c /opt/torch-avatar.txt -r /tmp/lp.txt
uv pip install --python $P -c /opt/torch-avatar.txt onnxruntime-gpu tensorrt-cu12 cuda-python polygraphy librosa soundfile imageio imageio-ffmpeg \
   scikit-image filetype colored cython huggingface_hub hf_transfer fastapi uvicorn opencv-python-headless
uv pip install --python $P -c /opt/torch-avatar.txt "numpy<2.3"


rm -rf /opt/uvcache /tmp/lp.txt /root/.cache
/opt/venv/bin/python -c "import torch; f=torch._C._cuda_getArchFlags(); assert 'sm_120' in f; print('comfy', torch.__version__)"
cd /opt/ComfyUI && /opt/venv/bin/python main.py --cpu --quick-test-for-ci
/opt/avatar/bin/python -c "import tensorrt, onnxruntime, torch; print('avatar', torch.__version__, tensorrt.__version__)"
