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

WORKDIR /tmp

COPY --from=builder /build/ComfyUI/requirements.txt /tmp/comfyui.txt
COPY --from=builder /build/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt /tmp/manager.txt

RUN pip --no-cache-dir install -r /tmp/comfyui.txt \
 && pip --no-cache-dir install -r /tmp/manager.txt \
 && pip --no-cache-dir install huggingface-hub \
 && pip --no-cache-dir install sageattention==${SAGE_ATTENTION_VERSION} --no-build-isolation \
 && rm -rf /tmp /root/.cache/pip

WORKDIR /workspace/ComfyUI
COPY --from=builder /build/ComfyUI .

CMD ["python", "main.py", "--listen", "0.0.0.0"]
