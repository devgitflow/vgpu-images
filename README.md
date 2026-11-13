# vgpu-images

Docker images for short GPU rentals on RTX 5090 (Blackwell, sm_120) class cards.

Everything a job needs is baked in, so the rented box spends its paid time on the work and none on installs. On Vast.ai the image pull happens while the instance is still in Loading, which is not billed for GPU time.

| image | stack | for |
| --- | --- | --- |
| `ghcr.io/devgitflow/vgpu-torch` | CUDA 12.8, PyTorch cu128 (latest), diffusers, transformers, ffmpeg NVENC | general PyTorch work, image models such as Z-Image |
| `ghcr.io/devgitflow/vgpu-rust-cuda` | CUDA 12.8 devel, Rust stable, sccache, cargo-chef, ffmpeg NVENC | Rust and CUDA builds and runs |
| `ghcr.io/devgitflow/vgpu-comfyui` | Python 3.12, torch 2.8.0 cu128, ComfyUI, SageAttention, VideoHelperSuite, KJNodes, WanVideoWrapper, MMAudio, GGUF | Wan 2.2 and 2.1 video, S2V, InfiniteTalk, LTX-2, foley, upscaling |
| `ghcr.io/devgitflow/vgpu-wanapps` | CUDA 13, Python 3.11, torch 2.10 cu130, SageAttention 2.2, Wan2GP | Wan2GP web UI (needs a CUDA 13 driver on the host) |
| `ghcr.io/devgitflow/vgpu-voice` | torch 2.7.1 cu128, Kokoro, Chatterbox, Qwen3-TTS, Pocket TTS, snac, faster-whisper | text to speech, voice cloning, transcription |
| `ghcr.io/devgitflow/vgpu-avatar` | torch 2.8.0 cu128, TensorRT 10, onnxruntime-gpu, LivePortrait, Ditto | talking head avatars |
| `ghcr.io/devgitflow/vgpu-llm` | Ollama, llama.cpp and whisper.cpp built for sm_89 and sm_120 | LLM serving, fast speech recognition |
| `ghcr.io/devgitflow/vgpu-train` | torch 2.8.0 cu128, Unsloth, TRL, PEFT, bitsandbytes, DeepSpeed, diffusers, ai-toolkit | LLM fine tuning, image and video LoRA training |

No model weights are baked in. A 30 GB image would take minutes to pull on any host that has not cached it, while the same weights come from Hugging Face in a minute or two on a well connected box.

GitHub Actions builds each folder under `images/` on push and tags it `latest` plus the commit sha.

For a project image, start `FROM` one of these, copy the source in and run `cargo build --release` during the build. The compile then happens on the CI runner and the GPU box only runs the binary.

Host requirement: an NVIDIA driver new enough for CUDA 12.8 (570 or later).

Both images set `NVIDIA_DRIVER_CAPABILITIES=all`. The NVIDIA base images ask only for compute and utility, and on some hosts that hides the NVENC encoder from the container.
