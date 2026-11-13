# Talking head avatars: LivePortrait and Ditto (TensorRT engines are built on the GPU at first start).
FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04

ENV NVIDIA_DRIVER_CAPABILITIES=all DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    PIP_NO_CACHE_DIR=1 UV_NO_CACHE=1 UV_LINK_MODE=copy UV_PYTHON_INSTALL_DIR=/opt/python \
    PATH=/opt/venv/bin:$PATH HF_HUB_ENABLE_HF_TRANSFER=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl wget aria2 ca-certificates rsync ffmpeg libgl1 libglib2.0-0 libsndfile1 build-essential zstd jq tmux \
    && rm -rf /var/lib/apt/lists/*
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
    && uv venv --python 3.11 /opt/venv
ENV UVP="uv pip install --python /opt/venv/bin/python"
RUN $UVP torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cu128
RUN git clone --depth 1 https://github.com/KwaiVGI/LivePortrait /opt/LivePortrait \
    && git clone --depth 1 https://github.com/antgroup/ditto-talkinghead /opt/ditto \
    && grep -viE '^(torch|torchvision|torchaudio|onnxruntime)' /opt/LivePortrait/requirements_base.txt > /tmp/lp.txt 2>/dev/null \
       || grep -viE '^(torch|torchvision|torchaudio|onnxruntime)' /opt/LivePortrait/requirements.txt > /tmp/lp.txt \
    && $UVP -r /tmp/lp.txt \
    && $UVP onnxruntime-gpu tensorrt-cu12 cuda-python polygraphy librosa soundfile imageio imageio-ffmpeg \
       scikit-image filetype colored cython huggingface_hub hf_transfer fastapi uvicorn opencv-python-headless \
    && $UVP torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --reinstall \
      --index-url https://download.pytorch.org/whl/cu128 \
    && $UVP "numpy<2.3" \
    && (/opt/venv/bin/python -m pip list 2>/dev/null || uv pip list --python /opt/venv/bin/python) | grep -iE '^(torch|nvidia|numpy|scipy)'
RUN python -c "import torch; f=torch._C._cuda_getArchFlags(); print(torch.__version__, f); assert 'sm_120' in f; import tensorrt, onnxruntime; print('trt', tensorrt.__version__)"

# Vast copies the account key in at start; on some hosts it lands with the wrong owner and sshd's
# StrictModes rejects it ("bad ownership or modes"). Single user container, so turn the check off.
RUN mkdir -p /root/.ssh /etc/ssh/sshd_config.d && chmod 700 /root/.ssh \
    && printf 'StrictModes no\n' > /etc/ssh/sshd_config.d/vgpu.conf
WORKDIR /workspace
LABEL org.opencontainers.image.source=https://github.com/devgitflow/vgpu-images
