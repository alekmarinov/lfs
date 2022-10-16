FROM debian:11

# image info
LABEL description="Automated LFS build"
LABEL version="11.2"
LABEL maintainer="alekmarinov@gmail.com"

# LFS mount point
ENV LFS=/mnt/lfs
ENV LFS_BASE=/mnt/base
ENV LFS_PACKAGE=/mnt/package

# Setup environment
ENV LC_ALL=POSIX
ENV LFS_TGT=x86_64-lfs-linux-gnu
# ENV PATH=/tools/bin:/bin:/usr/bin:/sbin:/usr/sbin
ENV MAKEFLAGS="-j4"

# set 1 to run tests; running tests takes much more time
ENV LFS_TEST=0

# set 1 to install documentation; slightly increases final size
ENV LFS_DOCS=0

# degree of parallelism for compilation
ENV JOB_COUNT=4

# size of the output image in MB
ENV IMAGE_SIZE=10000

# output image file name
ENV IMAGE_FILE=/tmp/lfs.img

# set bash as default shell
WORKDIR /bin
RUN rm sh && ln -s bash sh

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

# Prevent environment interference
RUN [ ! -e /etc/bash.bashrc ] || cat /dev/null > /etc/bash.bashrc

WORKDIR $LFS_BASE/sources
CMD "$LFS_BASE/scripts/tools/build-tools.sh"
