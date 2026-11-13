# PyTorch for Blackwell (cu128 wheels) + video tools. Used for model inference jobs.
FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8 PIP_NO_CACHE_DIR=1 \
    PIP_BREAK_SYSTEM_PACKAGES=1 HF_HUB_ENABLE_HF_TRANSFER=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-pip python3-dev git git-lfs curl wget ca-certificates rsync ffmpeg \
      libgl1 libglib2.0-0 zstd pigz jq tmux \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --index-url https://download.pytorch.org/whl/cu128 torch torchvision torchaudio \
    && pip3 install numpy pillow opencv-python-headless imageio imageio-ffmpeg \
       huggingface_hub hf_transfer safetensors accelerate transformers diffusers tqdm

# get_arch_list() is empty without a GPU, so read the compiled arch flags instead
RUN python3 -c "import torch; f=torch._C._cuda_getArchFlags(); print(torch.__version__, torch.version.cuda, f); assert 'sm_120' in f, 'no Blackwell kernels'"

WORKDIR /workspace

LABEL org.opencontainers.image.source=https://github.com/devgitflow/vgpu-images
