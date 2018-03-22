FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        curl \
        vim \
        ca-certificates \
        libjpeg-dev \
        libpng-dev

RUN curl -o ~/miniconda.sh -O  https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh  && \
     chmod +x ~/miniconda.sh && \
     ~/miniconda.sh -b -p /opt/conda && \
     rm ~/miniconda.sh && \
     /opt/conda/bin/conda install -y numpy pyyaml scipy ipython mkl mkl-include && \
     /opt/conda/bin/conda install -yc soumith magma-cuda90
ENV PATH /opt/conda/bin:$PATH

# Everything before this point comes from
# github.com/pytorch/pytorch/blob/master/Dockerfile

# Usage:
# $ docker build -f Dockerfile . --build-arg USR=<usr> --build-arg PW=<pw>

LABEL maintainer "Joan Puigcerver <joapuipe@gmail.com>"

# We aren't building from Pytorch's Dockerfile because
# v0.3.1 Dockerfile doesn't seem to work and we
# don't support 0.4 yet.
# TODO: Use PyTorch's Dockerfile once we upgrade
RUN conda install -y pytorch torchvision cuda90 -c pytorch

# TODO: Remove credentials once PyLaia goes public
ARG USR
ARG PW
# Install PyLaia
RUN git clone https://"$USR":"$PW"@github.com/jpuigcerver/PyLaia && \
    cd PyLaia && \
    git submodule update --init && \
    pip install -v .

# Install third party libraries
WORKDIR /PyLaia/third_party/imgdistort/build
RUN cmake .. -DPYTORCH_SETUP_PREFIX=/opt/conda && \
    make && make install

WORKDIR /PyLaia/third_party/nnutils/build
RUN cmake .. -DPYTORCH_SETUP_PREFIX=/opt/conda && \
    make && make install

WORKDIR /PyLaia/third_party/warp-ctc/build
RUN cmake .. && make && \
    cd ../pytorch_binding && \
    python setup.py build && \
    python setup.py install

# Cleanup
WORKDIR /
RUN apt-get clean && \
    conda clean -ya && \
    rm -rf /tmp/* && \
    rm -rf /var/lib/apt/lists/*