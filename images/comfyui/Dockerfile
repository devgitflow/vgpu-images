# ComfyUI for Wan 2.2 / 2.1 (i2v, t2v, s2v), InfiniteTalk, LTX-2, MMAudio foley, upscaling, SDXL.
# Same stack that ran on a local 5090: Python 3.12, torch 2.8.0 cu128, SageAttention.
# Weights are NOT baked in; fetch them on the box (see the vgpu fetch presets).
FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04

ENV NVIDIA_DRIVER_CAPABILITIES=all DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    PIP_NO_CACHE_DIR=1 UV_NO_CACHE=1 UV_LINK_MODE=copy PATH=/opt/venv/bin:$PATH \
    HF_HUB_ENABLE_HF_TRANSFER=1 COMFY=/opt/ComfyUI

RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-venv python3-dev build-essential git git-lfs curl wget aria2 ca-certificates rsync \
      ffmpeg libgl1 libglib2.0-0 libsm6 libxext6 zstd pigz jq tmux \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv && pip install -U pip uv
RUN uv pip install --python /opt/venv/bin/python torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 \
      --index-url https://download.pytorch.org/whl/cu128

ARG COMFY_REF=v0.43.0
RUN git clone https://github.com/comfyanonymous/ComfyUI $COMFY \
    && (cd $COMFY && (git checkout -q "$COMFY_REF" || echo "ref $COMFY_REF not found, staying on default branch") \
        && git log -1 --format='ComfyUI %H %cd') \
    && uv pip install --python /opt/venv/bin/python -r $COMFY/requirements.txt

# custom nodes used for the Wan, InfiniteTalk and foley work
RUN cd $COMFY/custom_nodes && for r in \
      Kosinkadink/ComfyUI-VideoHelperSuite kijai/ComfyUI-KJNodes kijai/ComfyUI-WanVideoWrapper \
      kijai/ComfyUI-MMAudio city96/ComfyUI-GGUF; do \
      git clone --depth 1 https://github.com/$r || exit 1; done \
    && for d in */; do [ -f "$d/requirements.txt" ] && uv pip install --python /opt/venv/bin/python -r "$d/requirements.txt" || true; done

RUN uv pip install --python /opt/venv/bin/python sageattention==1.0.6 hf_transfer huggingface_hub \
    && uv pip install --python /opt/venv/bin/python torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 \
      --index-url https://download.pytorch.org/whl/cu128

RUN python -c "import torch; f=torch._C._cuda_getArchFlags(); print(torch.__version__, f); assert 'sm_120' in f" \
    && cd $COMFY && python main.py --cpu --quick-test-for-ci

# Vast copies the account key in at start; on some hosts it lands with the wrong owner and sshd's
# StrictModes rejects it ("bad ownership or modes"). Single user container, so turn the check off.
RUN mkdir -p /root/.ssh /etc/ssh/sshd_config.d && chmod 700 /root/.ssh \
    && printf 'StrictModes no\n' > /etc/ssh/sshd_config.d/vgpu.conf
WORKDIR /workspace
EXPOSE 8188
LABEL org.opencontainers.image.source=https://github.com/devgitflow/vgpu-images
