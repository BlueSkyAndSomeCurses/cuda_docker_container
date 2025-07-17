FROM nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04
WORKDIR /home/ubuntu

ENV PATH="/home/ubuntu/miniconda3/bin:${PATH}"
ARG PATH="/home/ubuntu/miniconda3/bin:${PATH}"
ARG COMPUTE_CAP

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

RUN wget https://github.com/Kitware/CMake/releases/download/v3.30.1/cmake-3.30.1.tar.gz && \
    tar xfvz cmake-3.30.1.tar.gz && cd cmake-3.30.1 && \
    ./bootstrap && make -j$(nproc) && sudo make install

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


EXPOSE 5000

COPY .zshrc /home/ubuntu/.zshrc
COPY ./entrypoint.sh /tmp/entrypoint.sh

# SETUP CONDA ENV

RUN chsh -s /usr/bin/zsh root

RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

RUN /usr/bin/zsh -c conda init && \
    /usr/bin/zsh -c conda activate

COPY environment.yaml .
RUN conda env create -f environment.yaml

RUN apt-get update && apt-get upgrade -y

COPY .zshrc /home/ubuntu/.zshrc
RUN chmod +x /tmp/entrypoint.sh
USER ubuntu
WORKDIR /home/ubuntu

CMD ["/tmp/entrypoint.sh"]

