FROM debian:11

# image info
LABEL description="Automated LFS build"
LABEL version="11.2"
LABEL maintainer="alekmarinov@gmail.com"

# LFS mount point
ENV LFS=/mnt/lfs

# Other LFS parameters
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

# loop device (loop0 and loop1 are allocated by docker)
ENV LOOP=/dev/loop2

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

# create tools directory and symlink
RUN mkdir -pv $LFS/{tools/{lfs,blfs},etc,var} $LFS/usr/{bin,lib,sbin} \
    && for i in bin lib sbin; do \
        ln -sv usr/$i $LFS/$i; \
    done \
    && ln -sv $LFS/tools / \
    && case $(uname -m) in \
        x86_64) mkdir -pv $LFS/lib64 ;; \
    esac

# check environment
RUN chmod +x $LFS/scripts/{,prepare,build/{,lfs,blfs},image}/*.sh    \
    && sync                        \
    && $LFS/scripts/version-check.sh \
    && $LFS/scripts/library-check.sh

# create lfs user with 'lfs' password
RUN groupadd lfs                                    \
    && useradd -s /bin/bash -g lfs -m -k /dev/null lfs \
    && echo "lfs:lfs" | chpasswd
RUN adduser lfs sudo

# avoid sudo password
RUN echo "lfs ALL = NOPASSWD : ALL" >> /etc/sudoers
RUN echo 'Defaults env_keep += "LFS LC_ALL LFS_TGT PATH MAKEFLAGS FETCH_TOOLCHAIN_MODE LFS_TEST LFS_DOCS JOB_COUNT LOOP IMAGE_SIZE INITRD_TREE IMAGE"' >> /etc/sudoers

RUN chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools,scripts/{prepare,build/{,lfs,blfs},image}} \
    && case $(uname -m) in \
        x86_64) chown -v lfs $LFS/lib64 ;; \
    esac

# This file has the potential to modify the lfs user's environment
# in ways that can affect the building of critical LFS packages.
RUN [ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE

# login as lfs user
USER lfs
COPY [ "config/.bash_profile", "config/.bashrc", "/home/lfs/" ]
RUN source ~/.bash_profile

# let's the party begin
ENTRYPOINT [ "../scripts/run-all.sh" ]
