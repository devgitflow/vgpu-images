# All in one media box: ComfyUI video, the voice stack, Ming TTS, talking head avatars and the LLM tools,
# so a job that needs several of them rents one box instead of several. Each stack keeps its own
# environment because their torch versions differ:
#   ComfyUI     python (default, /opt/venv, torch 2.8)          /opt/ComfyUI
#   voice       /opt/voice/bin/python  (torch 2.7.1)             Kokoro, Chatterbox, Qwen3-TTS, Pocket TTS, faster-whisper
#   Ming TTS    /opt/ming/bin/python   (torch 2.7.1)             /opt/Ming-3.0-tts
#   avatar      /opt/avatar/bin/python (torch 2.8, TensorRT)     /opt/LivePortrait, /opt/ditto
#   LLM         ollama, llama-server, whisper-cli on PATH
# Wan2GP and FramePack are left out: they need CUDA 13 hosts, which would shrink the pool for every aio job.
FROM ghcr.io/devgitflow/vgpu-llm:latest AS llm
FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04

ENV NVIDIA_DRIVER_CAPABILITIES=all DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    PIP_NO_CACHE_DIR=1 PATH=/opt/venv/bin:$PATH:/opt/llm/bin HF_HUB_ENABLE_HF_TRANSFER=1 COMFY=/opt/ComfyUI \
    OLLAMA_HOST=0.0.0.0:11434 OLLAMA_KEEP_ALIVE=24h OLLAMA_NUM_PARALLEL=2 OLLAMA_CONTEXT_LENGTH=32768

RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-dev build-essential git git-lfs curl wget aria2 ca-certificates rsync \
      ffmpeg espeak-ng libsndfile1 libgl1 libglib2.0-0 libsm6 libxext6 libcurl4 libgomp1 zstd pigz jq tmux \
    && rm -rf /var/lib/apt/lists/* \
    && curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

COPY build_a.sh build_b.sh /tmp/
# two layers: ComfyUI and avatar (torch 2.8), then voice and Ming (torch 2.7.1); Python itself lives in layer A
RUN bash /tmp/build_a.sh && rm /tmp/build_a.sh
RUN bash /tmp/build_b.sh && rm /tmp/build_b.sh

COPY --from=llm /opt/llm /opt/llm
COPY --from=llm /usr/local/bin/ollama /usr/local/bin/ollama
COPY --from=llm /usr/local/lib/ollama /usr/local/lib/ollama
RUN test -x /usr/local/bin/ollama && test -x /opt/llm/bin/llama-server && test -x /opt/llm/bin/whisper-cli && echo "llm tools present"

RUN mkdir -p /root/.ssh /etc/ssh/sshd_config.d && chmod 700 /root/.ssh \
    && printf 'StrictModes no\n' > /etc/ssh/sshd_config.d/vgpu.conf
WORKDIR /workspace
EXPOSE 8188 11434
LABEL org.opencontainers.image.source=https://github.com/devgitflow/vgpu-images
