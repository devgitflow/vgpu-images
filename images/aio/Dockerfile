# All in one media box: ComfyUI video, the voice stack, Ming TTS, talking head avatars and the LLM tools,
# so a job that needs several of them rents one box instead of several. Each stack keeps its own
# environment because their torch versions differ:
#   ComfyUI     python (default, /opt/venv, torch 2.8)          /opt/ComfyUI
#   voice       /opt/voice/bin/python  (torch 2.7.1)             Kokoro, Chatterbox, Qwen3-TTS, Pocket TTS, faster-whisper
#   Ming TTS    /opt/ming/bin/python   (torch 2.7.1)             /opt/Ming-3.0-tts
#   avatar      /opt/avatar/bin/python (torch 2.8, TensorRT)     /opt/LivePortrait, /opt/ditto
#   LLM         ollama, llama-server, whisper-cli on PATH
# Wan2GP and FramePack are left out: they need CUDA 13 hosts, which would shrink the pool for every aio job.
FROM ghcr.io/devgitflow/vgpu-voice:latest AS voice
FROM ghcr.io/devgitflow/vgpu-avatar:latest AS avatar
FROM ghcr.io/devgitflow/vgpu-llm:latest AS llm
FROM ghcr.io/devgitflow/vgpu-comfyui:latest

RUN apt-get update && apt-get install -y --no-install-recommends espeak-ng libsndfile1 libcurl4 libgomp1 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=voice  /opt/python /opt/python
COPY --from=avatar /opt/python /opt/python
COPY --from=voice  /opt/venv /opt/voice
COPY --from=voice  /opt/ming /opt/ming
COPY --from=voice  /opt/Ming-3.0-tts /opt/Ming-3.0-tts
COPY --from=avatar /opt/venv /opt/avatar
COPY --from=avatar /opt/LivePortrait /opt/LivePortrait
COPY --from=avatar /opt/ditto /opt/ditto
COPY --from=llm    /opt/llm /opt/llm
COPY --from=llm    /usr/local/bin/ollama /usr/local/bin/ollama
COPY --from=llm    /usr/local/lib/ollama /usr/local/lib/ollama

ENV PATH=$PATH:/opt/llm/bin OLLAMA_HOST=0.0.0.0:11434 OLLAMA_KEEP_ALIVE=24h OLLAMA_NUM_PARALLEL=2 \
    OLLAMA_CONTEXT_LENGTH=32768

# the copied environments were built at /opt/venv; point their config and script headers at the new homes
RUN for e in voice avatar; do \
      sed -i "s#/opt/venv#/opt/$e#g" /opt/$e/pyvenv.cfg /opt/$e/bin/activate*; \
      grep -lI '^#!/opt/venv/bin/python' /opt/$e/bin/* 2>/dev/null | xargs -r sed -i "1s#/opt/venv#/opt/$e#"; \
    done \
    && python -c "import torch; print('comfy', torch.__version__)" \
    && /opt/voice/bin/python -c "import kokoro, faster_whisper, chatterbox, torch; print('voice', torch.__version__)" \
    && cd /opt/Ming-3.0-tts && /opt/ming/bin/python -c "import sys; sys.path.insert(0,'.'); import ming_tts; print('ming ok')" \
    && /opt/avatar/bin/python -c "import tensorrt, onnxruntime, torch; print('avatar', torch.__version__, tensorrt.__version__)" \
    && test -x /usr/local/bin/ollama && test -x /opt/llm/bin/llama-server && test -x /opt/llm/bin/whisper-cli && echo "llm tools present"

RUN mkdir -p /root/.ssh /etc/ssh/sshd_config.d && chmod 700 /root/.ssh \
    && printf 'StrictModes no\n' > /etc/ssh/sshd_config.d/vgpu.conf
WORKDIR /workspace
EXPOSE 8188 11434
LABEL org.opencontainers.image.source=https://github.com/devgitflow/vgpu-images
