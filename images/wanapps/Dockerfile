# Wan2GP (web UI for Wan, Hunyuan, LTX and friends) on torch 2.10 cu130 with SageAttention 2.2.
# Needs a host driver with CUDA 13 support. Weights download on first use inside Wan2GP.
# base, not runtime: the runtime image ships its own cuBLAS 13.0 next to the 13.1 that torch 2.10 brings,
# and loading parts of both broke every fp16 GEMM (CUBLAS_STATUS_INVALID_VALUE). torch wheels carry all CUDA libs.
FROM nvidia/cuda:13.0.0-base-ubuntu24.04

ENV NVIDIA_DRIVER_CAPABILITIES=all DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    PIP_NO_CACHE_DIR=1 UV_NO_CACHE=1 UV_LINK_MODE=copy UV_PYTHON_INSTALL_DIR=/opt/python \
    PATH=/opt/venv/bin:$PATH HF_HUB_ENABLE_HF_TRANSFER=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl wget aria2 ca-certificates rsync ffmpeg libgl1 libglib2.0-0 build-essential zstd jq tmux \
    && rm -rf /var/lib/apt/lists/*
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
    && uv venv --python 3.11 /opt/venv
RUN uv pip install --python /opt/venv/bin/python torch==2.10.0 torchvision==0.25.0 torchaudio==2.10.0 \
      --index-url https://download.pytorch.org/whl/cu130
RUN git clone --depth 1 https://github.com/deepbeepmeep/Wan2GP /opt/Wan2GP \
    && uv pip install --python /opt/venv/bin/python -r /opt/Wan2GP/requirements.txt --index-strategy unsafe-best-match \
    && uv pip install --python /opt/venv/bin/python hf_transfer \
       https://github.com/deepbeepmeep/SageAttention/releases/download/v2.2.0-linux.cg1/sageattention-2.2.0+cu130torch2.10.0.cg1-cp311-cp311-linux_x86_64.whl \
    && uv pip install --python /opt/venv/bin/python torch==2.10.0 torchvision==0.25.0 torchaudio==2.10.0 --reinstall \
      --index-url https://download.pytorch.org/whl/cu130 \
    && (/opt/venv/bin/python -m pip list 2>/dev/null || uv pip list --python /opt/venv/bin/python) | grep -iE '^(torch|nvidia)'
RUN python -c "import torch; f=torch._C._cuda_getArchFlags(); print(torch.__version__, f); assert 'sm_120' in f; import sageattention" \
    && ls /usr/local/cuda/lib64 2>/dev/null | grep -i cublas && echo "WARNING system cuBLAS present" || echo "no system cuBLAS, good"

# Vast copies the account key in at start; on some hosts it lands with the wrong owner and sshd's
# StrictModes rejects it ("bad ownership or modes"). Single user container, so turn the check off.
RUN mkdir -p /root/.ssh /etc/ssh/sshd_config.d && chmod 700 /root/.ssh \
    && printf 'StrictModes no\n' > /etc/ssh/sshd_config.d/vgpu.conf
WORKDIR /workspace
EXPOSE 7860
LABEL org.opencontainers.image.source=https://github.com/devgitflow/vgpu-images
