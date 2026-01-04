# Build arguments
# https://hub.docker.com/r/runpod/pytorch/tags?page=3
ARG RUNPOD_VERSION=1.0.3
ARG CUDA_VERSION=cu1281
ARG TORCH_VERSION=torch280
ARG UBUNTU_VERSION=ubuntu2404

# =============================================================================
# Builder stage - clone repos and extract requirements
# =============================================================================
FROM alpine/git AS builder

WORKDIR /build
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git

WORKDIR /custom_nodes
RUN git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git

# =============================================================================
# Final stage - install dependencies
# =============================================================================
FROM runpod/pytorch:${RUNPOD_VERSION}-${CUDA_VERSION}-${TORCH_VERSION}-${UBUNTU_VERSION}

WORKDIR /tmp

# Copy only requirements files from builder
COPY --from=builder /build/ComfyUI/requirements.txt /tmp/comfyui-requirements.txt
COPY --from=builder /custom_nodes/ComfyUI-Manager/requirements.txt /tmp/manager-requirements.txt

# Install all dependencies
RUN pip --no-cache-dir install -r comfyui-requirements.txt && \
    pip --no-cache-dir install -r manager-requirements.txt && \
    pip --no-cache-dir install huggingface-hub && \
    pip --no-cache-dir install sageattention==2.2.0 --no-build-isolation && \
    rm -rf /tmp/*.txt /root/.cache/pip

WORKDIR /workspace
COPY --from=builder /build/ComfyUI ComfyUI
COPY --from=builder /custom_nodes/ComfyUI-Manager ComfyUI/custom_nodes

CMD ["python", "main.py", "--listen", "0.0.0.0"]
