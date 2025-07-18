FROM nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04
WORKDIR /home/ubuntu

ENV PATH="/home/ubuntu/miniconda3/bin:${PATH}"
ARG PATH="/home/ubuntu/miniconda3/bin:${PATH}"
ARG COMPUTE_CAP

# BASIC DEPENDENCIES

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    sudo \
    zsh \
    git \
    curl \
    wget \
    cmake \
    ninja-build \
    build-essential \
    libboost-program-options-dev \
    libboost-graph-dev \
    libboost-system-dev \
    libeigen3-dev \
    libfreeimage-dev \
    libmetis-dev \
    libgoogle-glog-dev \
    libgtest-dev \
    libgmock-dev \
    libsqlite3-dev \
    libglew-dev \
    qtbase5-dev \
    libqt5opengl5-dev \
    libcgal-dev \
    libceres-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libopenblas-dev \
    liblapack-dev \
    && rm -rf /var/lib/apt/lists/*


# NEWER VERSION OF CMAKE

RUN wget https://github.com/Kitware/CMake/releases/download/v3.30.1/cmake-3.30.1.tar.gz && \
    tar xfvz cmake-3.30.1.tar.gz && cd cmake-3.30.1 && \
    ./bootstrap && make -j$(nproc) && sudo make install


# BUILD COLMAP, GLOMAP

RUN apt-get update && apt-get upgrade -y && \
    apt install -y  \
    libflann-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/colmap/colmap.git && \
    cd colmap && \
    mkdir build && \
    cd build && \
    cmake .. -GNinja && \
    ninja && ninja install

ENV COMPUTE_CAP=${COMPUTE_CAP}
RUN echo "hi $COMPUTE_CAP "

RUN git clone https://github.com/colmap/glomap.git --depth=1 && \
    mkdir glomap/build && \
    cd glomap/build && \
    cmake .. -GNinja -DCMAKE_CUDA_ARCHITECTURES=${COMPUTE_CAP} && \ 
    ninja && ninja install

COPY .zshrc /home/ubuntu/.zshrc
RUN chsh -s /usr/bin/zsh root

# CREATE NON-ROOT USER

RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu

USER ubuntu
WORKDIR /home/ubuntu

# INSTALL MINICONDA

RUN arch=$(uname -m) && \
    if [ "$arch" = "x86_64" ]; then \
    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"; \
    elif [ "$arch" = "aarch64" ]; then \
    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"; \
    else \
    echo "Unsupported architecture: $arch"; \
    exit 1; \
    fi && \
    wget $MINICONDA_URL -O miniconda.sh && \
    mkdir -p /home/ubuntu/.conda && \
    bash miniconda.sh -b -p /home/ubuntu/miniconda3 && \
    rm -f miniconda.sh 


# SETUP CONDA

RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

RUN /usr/bin/zsh -c conda init && \
    /usr/bin/zsh -c conda activate

COPY environment.yaml .
RUN conda env create -f environment.yaml

# SETUP SSH

EXPOSE 5000
EXPOSE 22
RUN sudo apt update && sudo apt install -y openssh-server 

COPY ./entrypoint.sh /tmp/entrypoint.sh
RUN sudo chmod +x /tmp/entrypoint.sh

RUN sudo apt-get update && sudo apt-get upgrade -y
CMD ["/tmp/entrypoint.sh"]


