# Rust + CUDA 12.8 (Blackwell / RTX 5090 ready) + video tools.
# Everything a job needs is baked in here, because image pull time on Vast is not billed
# and install time after the box is running is.
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo PATH=/opt/cargo/bin:$PATH \
    CARGO_TERM_COLOR=never CUDA_COMPUTE_CAP=120

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential pkg-config clang lld cmake ninja-build git git-lfs curl wget ca-certificates \
      rsync openssh-client unzip zstd pigz jq htop nvtop tmux \
      libssl-dev libclang-dev protobuf-compiler \
      ffmpeg libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libavfilter-dev libavdevice-dev \
      python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable \
      -c rustfmt -c clippy \
    && cargo install --locked sccache cargo-chef \
    && rm -rf /opt/cargo/registry /opt/cargo/git

# sanity at build time (no GPU here, so only the toolchain)
RUN nvcc --version && rustc --version && cargo --version && ffmpeg -hide_banner -encoders | grep -q nvenc

WORKDIR /workspace
