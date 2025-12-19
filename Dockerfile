FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"

RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    python3-dev \
    git \
    libjpeg-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Symlink python3 to python
RUN ln -s /usr/bin/python3.10 /usr/bin/python

# Install PyTorch
RUN pip install --no-cache-dir torch==2.6.0 torchvision==0.21.0 --index-url https://download.pytorch.org/whl/cu124

# Basic dependencies from setup.sh
RUN pip install --no-cache-dir \
    imageio \
    imageio-ffmpeg \
    tqdm \
    easydict \
    opencv-python-headless \
    ninja \
    trimesh \
    transformers \
    gradio==6.0.1 \
    tensorboard \
    pandas \
    lpips \
    zstandard \
    kornia \
    timm \
    pillow-simd

RUN pip install --no-cache-dir git+https://github.com/EasternJournalist/utils3d.git@9a4eb15e4021b67b12c460c7057d642626897ec8

# Flash Attention
RUN pip install --no-cache-dir flash-attn==2.7.3

# Set TORCH_CUDA_ARCH_LIST for building extensions
ENV TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0"

# Extensions
WORKDIR /tmp/extensions

# nvdiffrast
RUN git clone -b v0.4.0 https://github.com/NVlabs/nvdiffrast.git nvdiffrast && \
    pip install ./nvdiffrast --no-build-isolation

# nvdiffrec
RUN git clone -b renderutils https://github.com/JeffreyXiang/nvdiffrec.git nvdiffrec && \
    pip install ./nvdiffrec --no-build-isolation

# cumesh
RUN git clone https://github.com/JeffreyXiang/CuMesh.git CuMesh --recursive && \
    pip install ./CuMesh --no-build-isolation

# flexgemm
RUN git clone https://github.com/JeffreyXiang/FlexGEMM.git FlexGEMM --recursive && \
    pip install ./FlexGEMM --no-build-isolation

WORKDIR /app

# Copy o-voxel and install
COPY o-voxel /app/o-voxel
RUN pip install /app/o-voxel --no-build-isolation

# Copy application code
COPY . /app

EXPOSE 7860
ENV GRADIO_SERVER_NAME="0.0.0.0"

CMD ["python", "app.py"]
