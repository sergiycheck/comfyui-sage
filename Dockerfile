# =============================================================================
# Build arguments
# =============================================================================
ARG RUNPOD_VERSION=1.0.3
ARG CUDA_VERSION=cu1281
ARG TORCH_VERSION=torch280
ARG UBUNTU_VERSION=ubuntu2404

# =============================================================================
# Builder stage
# =============================================================================
FROM alpine/git AS builder

WORKDIR /build
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git

WORKDIR /build/custom_nodes
RUN git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git

# =============================================================================
# Final stage
# =============================================================================
FROM runpod/pytorch:${RUNPOD_VERSION}-${CUDA_VERSION}-${TORCH_VERSION}-${UBUNTU_VERSION}

# Re-declare ARGs (REQUIRED after FROM)
ARG RUNPOD_VERSION
ARG CUDA_VERSION
ARG TORCH_VERSION
ARG UBUNTU_VERSION

ARG SAGE_ATTENTION_VERSION=2.2.0
ARG COMPUTE_CAP=86
ARG PYTHON_VERSION=cp312

WORKDIR /tmp

# Copy requirements
COPY --from=builder /build/ComfyUI/requirements.txt /tmp/comfyui.txt
COPY --from=builder /build/custom_nodes/ComfyUI-Manager/requirements.txt /tmp/manager.txt

# Install deps
RUN pip --no-cache-dir install -r /tmp/comfyui.txt \
 && pip --no-cache-dir install -r /tmp/manager.txt \
 && pip --no-cache-dir install huggingface-hub \
 && pip --no-cache-dir install sageattention==2.2.0 --no-build-isolation \
 && rm -rf /tmp /root/.cache/pip

# Runtime layout
WORKDIR /workspace/ComfyUI

COPY --from=builder /build/ComfyUI .
COPY --from=builder /build/custom_nodes ./custom_nodes

CMD ["python", "main.py", "--listen", "0.0.0.0"]
