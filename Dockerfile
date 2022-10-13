FROM debian:11

# image info
LABEL description="Automated LFS build"
LABEL version="11.2"
LABEL maintainer="alekmarinov@gmail.com"

# LFS mount point
ENV LFS=/mnt/lfs

# Setup environment
ENV LC_ALL=POSIX
ENV LFS_TGT=x86_64-lfs-linux-gnu
ENV PATH=/tools/bin:/bin:/usr/bin:/sbin:/usr/sbin
ENV MAKEFLAGS="-j4"

# set 1 to run tests; running tests takes much more time
ENV LFS_TEST=0

# set 1 to install documentation; slightly increases final size
ENV LFS_DOCS=0

# degree of parallelism for compilation
ENV JOB_COUNT=4

# inital ram disk size in KB
# must be in sync with CONFIG_BLK_DEV_RAM_SIZE
ENV IMAGE_SIZE=4000000

# location of initrd tree
ENV INITRD_TREE=/mnt/lfs

# output image
ENV IMAGE=isolinux/ramdisk.img

# set bash as default shell
WORKDIR /bin
RUN rm sh && ln -s bash sh

# install required packages
RUN apt-get update && apt-get install -y \
    build-essential                      \
    bison                                \
    file                                 \
    gawk                                 \
    texinfo                              \
    wget                                 \
    sudo                                 \
    genisoimage                          \
    libelf-dev                           \
    bc                                   \
    libssl-dev                           \
    rsync                                \
    python3-dev                          \
 && apt-get -q -y autoremove             \
 && rm -rf /var/lib/apt/lists/*

# create sources directory as writable and sticky
RUN mkdir -pv     $LFS/sources \
 && chmod -v a+wt $LFS/sources
WORKDIR $LFS/sources

# copy scripts
COPY [ "scripts", "$LFS/scripts/" ]

# make all scripts executable and check environment
RUN chmod -R +x $LFS/scripts \
    && sync \
    && $LFS/scripts/2-version-check.sh

# create tools directory and symlink
RUN mkdir -pv $LFS/{tools/{lfs,blfs},etc,var,tmp} $LFS/usr/{bin,lib,sbin} \
    && for i in bin lib sbin; do \
        ln -sv usr/$i $LFS/$i; \
    done \
    && ln -sv $LFS/tools / \
    && case $(uname -m) in \
        x86_64) mkdir -pv $LFS/lib64 ;; \
    esac

# Prevent environment interference
RUN [ ! -e /etc/bash.bashrc ] || cat /dev/null > /etc/bash.bashrc

# The entrypoint
ENTRYPOINT [ "../scripts/start.sh" ]
