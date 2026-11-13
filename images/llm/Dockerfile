# LLM serving and fast speech recognition without torch:
# Ollama, llama.cpp llama-server and whisper.cpp whisper-server, both compiled for sm_89 and sm_120.
FROM nvidia/cuda:12.8.1-devel-ubuntu24.04 AS build
ARG LLAMA_REF=b12233
ARG WHISPER_REF=d1be6fd
RUN apt-get update && apt-get install -y --no-install-recommends git cmake ninja-build build-essential ca-certificates libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/ggml-org/llama.cpp /src/llama.cpp && cd /src/llama.cpp \
    && (git checkout -q "$LLAMA_REF" || echo "llama.cpp ref $LLAMA_REF missing, using default branch") \
    && cmake -B build -G Ninja -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="89;120" -DLLAMA_CURL=ON \
       -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined \
    && cmake --build build -j"$(nproc)" --target llama-server llama-cli llama-bench
RUN git clone https://github.com/ggml-org/whisper.cpp /src/whisper.cpp && cd /src/whisper.cpp \
    && (git checkout -q "$WHISPER_REF" || echo "whisper.cpp ref $WHISPER_REF missing, using default branch") \
    && cmake -B build -G Ninja -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="89;120" -DCMAKE_BUILD_TYPE=Release \
       -DBUILD_SHARED_LIBS=OFF -DCMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined \
    && cmake --build build -j"$(nproc)" --target whisper-server whisper-cli
RUN mkdir -p /out/bin /out/lib \
    && cp /src/llama.cpp/build/bin/llama-server /src/llama.cpp/build/bin/llama-cli /src/llama.cpp/build/bin/llama-bench /out/bin/ \
    && cp /src/whisper.cpp/build/bin/whisper-server /src/whisper.cpp/build/bin/whisper-cli /out/bin/ \
    && echo "static builds: each binary carries its own ggml (both projects ship libggml*.so with the same names)"

FROM nvidia/cuda:12.8.1-runtime-ubuntu24.04
ENV NVIDIA_DRIVER_CAPABILITIES=all DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    LD_LIBRARY_PATH=/opt/llm/lib:$LD_LIBRARY_PATH PATH=/opt/llm/bin:$PATH \
    OLLAMA_HOST=0.0.0.0:11434 OLLAMA_KEEP_ALIVE=24h OLLAMA_NUM_PARALLEL=2 OLLAMA_CONTEXT_LENGTH=32768
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl wget aria2 ca-certificates rsync ffmpeg libcurl4 libgomp1 zstd jq tmux python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://ollama.com/install.sh | sh && ollama --version || true
COPY --from=build /out /opt/llm
# binaries need libcuda from the host driver, so only check they exist here
RUN ls -la /opt/llm/bin && test -x /opt/llm/bin/llama-server && test -x /opt/llm/bin/whisper-server
# Vast copies the account key in at start; on some hosts it lands with the wrong owner and sshd's
# StrictModes rejects it ("bad ownership or modes"). Single user container, so turn the check off.
RUN mkdir -p /root/.ssh /etc/ssh/sshd_config.d && chmod 700 /root/.ssh \
    && printf 'StrictModes no\n' > /etc/ssh/sshd_config.d/vgpu.conf
WORKDIR /workspace
EXPOSE 11434 8080
LABEL org.opencontainers.image.source=https://github.com/devgitflow/vgpu-images
