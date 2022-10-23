FROM debian:11

# image info
LABEL description="Automated LFS build"
LABEL version="11.2"
LABEL maintainer="alekmarinov@gmail.com"

# install required packages
RUN apt-get update -y \
    && apt-get install -y \
        build-essential \
        bison \
        file \
        gawk \
        texinfo \
        wget \
        libelf-dev \
        bc \
        libssl-dev \
        rsync \
        python3-dev \
    && apt-get -q -y autoremove \
    && rm -rf /var/lib/apt/lists/*

# set bash as default shell
RUN rm bin/sh && ln -s bash bin/sh

# Prevent environment interference
RUN [ ! -e /etc/bash.bashrc ] || cat /dev/null > /etc/bash.bashrc

WORKDIR /
CMD "$LFS_BASE/scripts/tools/build-tools.sh"
