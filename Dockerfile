FROM nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04
WORKDIR /home/ubuntu

ENV PATH="/root/miniconda3/bin:${PATH}"
ARG PATH="/root/miniconda3/bin:${PATH}"
ARG COMPUTE_CAP

EXPOSE 5000

COPY .zshrc .
COPY ./entrypoint.sh .

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

# RUN DISTRO_CODENAME=$(grep -oP 'VERSION_CODENAME=\K\w+' /etc/os-release) && \
#     wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | \
#     gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
#     echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ ${DISTRO_CODENAME} main" | \
#     tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
#     apt-get update && \
#     apt-get install -y cmake && \
#     cmake --version

RUN wget https://github.com/Kitware/CMake/releases/download/v3.30.1/cmake-3.30.1.tar.gz && \
    tar xfvz cmake-3.30.1.tar.gz && cd cmake-3.30.1 && \
    ./bootstrap && make -j$(nproc) && sudo make install

RUN chsh -s /usr/bin/zsh root

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
    mkdir -p /root/.conda && \
    bash miniconda.sh -b -p /root/miniconda3 && \
    rm -f miniconda.sh 

RUN /usr/bin/zsh -c conda init && \
    /usr/bin/zsh -c conda activate
    # conda install nvidia


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

CMD [ "./entrypoint.sh" ]

# ENTRYPOINT [ "/usr/bin/zsh" ]
