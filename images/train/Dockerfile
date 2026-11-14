# Training: LLM fine tuning (Unsloth, TRL, PEFT, bitsandbytes, DeepSpeed) and image LoRA training
# (diffusers, ostris ai-toolkit for Flux / Z-Image / SDXL / Wan LoRAs). torch 2.11 cu128 (current Unsloth and
# torchao need it); ai-toolkit keeps torch 2.8 in its own environment.
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

ENV NVIDIA_DRIVER_CAPABILITIES=all DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    PIP_NO_CACHE_DIR=1 UV_EXTRA_INDEX_URL=https://download.pytorch.org/whl/cu128 UV_INDEX_STRATEGY=unsafe-best-match UV_NO_CACHE=1 UV_LINK_MODE=copy UV_PYTHON_INSTALL_DIR=/opt/python \
    PATH=/opt/venv/bin:$PATH HF_HUB_ENABLE_HF_TRANSFER=1 TORCH_CUDA_ARCH_LIST="12.0"

RUN apt-get update && apt-get install -y --no-install-recommends \
      git git-lfs curl wget aria2 ca-certificates rsync ffmpeg libgl1 libglib2.0-0 build-essential zstd jq tmux \
    && rm -rf /var/lib/apt/lists/*
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
    && uv venv --python 3.11 /opt/venv
ENV UVP="uv pip install --python /opt/venv/bin/python"
RUN $UVP torch==2.11.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 && uv pip freeze --python /opt/venv/bin/python | grep -iE '^(torch|torchvision|torchaudio|triton|nvidia-)' > /opt/torch.txt && cat /opt/torch.txt
RUN $UVP -c /opt/torch.txt unsloth unsloth_zoo trl peft bitsandbytes datasets accelerate deepspeed liger-kernel \
      transformers diffusers safetensors sentencepiece protobuf einops tensorboard huggingface_hub hf_transfer \
      wandb soundfile librosa pyyaml omegaconf
RUN uv pip list --python /opt/venv/bin/python | grep -iE '^(torch|nvidia|unsloth|trl|peft|bitsandbytes|numpy)'

# ai-toolkit pins numpy 1.26 while datasets/pyarrow above need numpy 2, so it gets its own environment:
#   /opt/aitk/bin/python /opt/ai-toolkit/run.py config.yaml
RUN git clone --depth 1 https://github.com/ostris/ai-toolkit /opt/ai-toolkit \
    && uv venv --python 3.11 /opt/aitk \
    && uv pip install --python /opt/aitk/bin/python torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cu128 \
    && uv pip freeze --python /opt/aitk/bin/python | grep -iE '^(torch|torchvision|torchaudio|triton|nvidia-)' > /opt/aitk-torch.txt && cat /opt/aitk-torch.txt \
    && cd /opt/ai-toolkit && uv pip install --python /opt/aitk/bin/python -c /opt/aitk-torch.txt -r requirements.txt \
    && /opt/aitk/bin/python -c "import torch, numpy; print('aitk env', torch.__version__, numpy.__version__)"
RUN python -c "import torch; f=torch._C._cuda_getArchFlags(); print(torch.__version__, f); assert 'sm_120' in f; import trl, peft, bitsandbytes, diffusers, datasets; print('train imports ok')"

# Vast copies the account key in at start; on some hosts it lands with the wrong owner and sshd's
# StrictModes rejects it ("bad ownership or modes"). Single user container, so turn the check off.
RUN mkdir -p /root/.ssh /etc/ssh/sshd_config.d && chmod 700 /root/.ssh \
    && printf 'StrictModes no\n' > /etc/ssh/sshd_config.d/vgpu.conf
WORKDIR /workspace
LABEL org.opencontainers.image.source=https://github.com/devgitflow/vgpu-images
