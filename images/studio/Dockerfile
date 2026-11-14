# Studio: ComfyUI video (torch 2.8) and the voice stack (torch 2.7.1) in one image, for jobs that render
# video and narrate it on the same rented box. Two separate environments, no reinstall:
#   ComfyUI:  /opt/venv  (default python)        voice: /opt/voice/bin/python
FROM ghcr.io/devgitflow/vgpu-voice:latest AS voice
FROM ghcr.io/devgitflow/vgpu-comfyui:latest
RUN apt-get update && apt-get install -y --no-install-recommends espeak-ng libsndfile1 && rm -rf /var/lib/apt/lists/*
COPY --from=voice /opt/python /opt/python
COPY --from=voice /opt/venv /opt/voice
RUN sed -i 's#/opt/venv#/opt/voice#g' /opt/voice/bin/activate* /opt/voice/pyvenv.cfg 2>/dev/null; \
    grep -lI '^#!/opt/venv/bin/python' /opt/voice/bin/* 2>/dev/null | xargs -r sed -i '1s#/opt/venv#/opt/voice#'; \
    /opt/voice/bin/python -c "import kokoro, faster_whisper, chatterbox, torch; print('voice env ok', torch.__version__)" \
    && python -c "import torch; print('comfy env', torch.__version__)"
RUN mkdir -p /root/.ssh /etc/ssh/sshd_config.d && chmod 700 /root/.ssh \
    && printf 'StrictModes no\n' > /etc/ssh/sshd_config.d/vgpu.conf
WORKDIR /workspace
LABEL org.opencontainers.image.source=https://github.com/devgitflow/vgpu-images
