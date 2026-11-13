# vgpu-images

Docker images for short GPU rentals on RTX 5090 (Blackwell, sm_120) class cards.

Everything a job needs is baked in, so the rented box spends its paid time on the work and none on installs. On Vast.ai the image pull happens while the instance is still in Loading, which is not billed for GPU time.

| image | base | contents |
| --- | --- | --- |
| `ghcr.io/devgitflow/vgpu-rust-cuda` | CUDA 12.8 cuDNN devel, Ubuntu 24.04 | Rust stable, sccache, cargo-chef, clang, cmake, ffmpeg with NVENC, Python 3 |
| `ghcr.io/devgitflow/vgpu-torch` | CUDA 12.8 cuDNN runtime, Ubuntu 24.04 | PyTorch cu128, diffusers, transformers, accelerate, OpenCV, ffmpeg with NVENC |

GitHub Actions builds each folder under `images/` on push and tags it `latest` plus the commit sha.

For a project image, start `FROM` one of these, copy the source in and run `cargo build --release` during the build. The compile then happens on the CI runner and the GPU box only runs the binary.

Host requirement: an NVIDIA driver new enough for CUDA 12.8 (570 or later).

Both images set `NVIDIA_DRIVER_CAPABILITIES=all`. The NVIDIA base images ask only for compute and utility, and on some hosts that hides the NVENC encoder from the container.
