#!/bin/bash
# aio layer B: voice and Ming TTS, both on torch 2.7.1. Environments that share a torch build are built in the same layer with a shared
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

# ---- voice (/opt/voice): Kokoro, Chatterbox, Qwen3-TTS, Pocket TTS, faster-whisper
uv venv --python 3.11 /opt/voice; P=/opt/voice/bin/python
uv pip install --python $P $T271 --index-url $CU
lock $P /opt/torch-voice.txt
uv pip install --python $P -c /opt/torch-voice.txt "setuptools<81" wheel numpy soundfile librosa transformers accelerate safetensors huggingface_hub \
   hf_transfer fastapi uvicorn pydantic einops omegaconf conformer diffusers resemble-perth s3tokenizer snac \
   faster-whisper kokoro "misaki[en]" qwen-tts pocket-tts
uv pip install --python $P --no-deps chatterbox-tts==0.1.7
uv pip install --python $P "en_core_web_sm@https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl"

# ---- Ming 3.0 TTS (/opt/ming)
git clone --depth 1 https://github.com/inclusionAI/Ming-3.0-tts /opt/Ming-3.0-tts
uv venv --python 3.11 /opt/ming; P=/opt/ming/bin/python
uv pip install --python $P $T271 --index-url $CU
lock $P /opt/torch-ming.txt
cd /opt/Ming-3.0-tts && grep -viE '^(torch|torchaudio|torchvision)[=<> ]' requirements.txt > req_vgpu.txt
uv pip install --python $P -c /opt/torch-ming.txt -r req_vgpu.txt hf_transfer


rm -rf /opt/uvcache /tmp/lp.txt /root/.cache
/opt/voice/bin/python -c "import kokoro, faster_whisper, chatterbox, snac, torch; print('voice', torch.__version__)"
cd /opt/Ming-3.0-tts && /opt/ming/bin/python -c "import sys; sys.path.insert(0,'.'); import ming_tts; print('ming ok')"
