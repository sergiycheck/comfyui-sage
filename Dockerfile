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

WORKDIR /build/ComfyUI/custom_nodes
RUN git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git

# =============================================================================
# Final stage
# =============================================================================
FROM runpod/pytorch:${RUNPOD_VERSION}-${CUDA_VERSION}-${TORCH_VERSION}-${UBUNTU_VERSION}

ARG SAGE_ATTENTION_VERSION=2.2.0

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Ensure we have the latest pip and build tools for SageAttention
RUN pip install --upgrade pip setuptools wheel

# Setup a dedicated directory for requirements to avoid /tmp permission issues
WORKDIR /deps
COPY --from=builder /build/ComfyUI/requirements.txt ./comfyui_reqs.txt
COPY --from=builder /build/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt ./manager_reqs.txt

# Install requirements in logical layers
RUN pip --no-cache-dir install -r comfyui_reqs.txt
RUN pip --no-cache-dir install -r manager_reqs.txt
RUN pip --no-cache-dir install huggingface-hub

# Install SageAttention with build isolation disabled as requested
RUN pip --no-cache-dir install sageattention==${SAGE_ATTENTION_VERSION} --no-build-isolation

# Set up the workspace
WORKDIR /workspace/ComfyUI
COPY --from=builder /build/ComfyUI .

# Cleanup temporary build files to keep image size down
RUN rm -rf /deps /root/.cache/pip

EXPOSE 8188

CMD ["python", "main.py", "--listen", "0.0.0.0"]