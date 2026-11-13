# Text to speech, voice cloning and speech recognition on one torch 2.7.1 cu128 stack:
# Kokoro, Chatterbox (Turbo), Qwen3-TTS, Pocket TTS, Orpheus/Maya1 via transformers + snac, faster-whisper.
FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04

ENV NVIDIA_DRIVER_CAPABILITIES=all DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    PIP_NO_CACHE_DIR=1 UV_NO_CACHE=1 UV_LINK_MODE=copy UV_PYTHON_INSTALL_DIR=/opt/python \
    PATH=/opt/venv/bin:$PATH HF_HUB_ENABLE_HF_TRANSFER=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl wget aria2 ca-certificates rsync ffmpeg espeak-ng libsndfile1 build-essential zstd jq tmux \
    && rm -rf /var/lib/apt/lists/*
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
    && uv venv --python 3.11 /opt/venv
ENV UVP="uv pip install --python /opt/venv/bin/python"
RUN $UVP torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 --index-url https://download.pytorch.org/whl/cu128
RUN $UVP "setuptools<81" wheel numpy soundfile librosa transformers accelerate safetensors huggingface_hub hf_transfer \
      fastapi uvicorn pydantic einops omegaconf conformer diffusers resemble-perth s3tokenizer snac \
      faster-whisper kokoro "misaki[en]" qwen-tts pocket-tts \
    && $UVP --no-deps chatterbox-tts==0.1.7 \
    && $UVP torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 --index-url https://download.pytorch.org/whl/cu128
# Kokoro's English front end (misaki) loads this spaCy model at first use; fetching it on the box cost 30 s
RUN python -m spacy download en_core_web_sm || $UVP en_core_web_sm@https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl
RUN python -c "import torch; f=torch._C._cuda_getArchFlags(); print(torch.__version__, f); assert 'sm_120' in f" \
    && python -c "import kokoro, faster_whisper, chatterbox, snac, transformers; print('voice imports ok')"

# Vast copies the account key in at start; on some hosts it lands with the wrong owner and sshd's
# StrictModes rejects it ("bad ownership or modes"). Single user container, so turn the check off.
RUN mkdir -p /root/.ssh /etc/ssh/sshd_config.d && chmod 700 /root/.ssh \
    && printf 'StrictModes no\n' > /etc/ssh/sshd_config.d/vgpu.conf
WORKDIR /workspace
EXPOSE 8880
LABEL org.opencontainers.image.source=https://github.com/devgitflow/vgpu-images
