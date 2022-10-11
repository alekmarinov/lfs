#!/bin/bash
set -e
echo "Building vim.."
echo "Approximate build time: 2.5 SBU"
echo "Required disk space: 217 MB"

# 8.69. Vim
# The Vim package contains a powerful text editor.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/vim.html

VER=$(ls /sources/vim-*.tar.gz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/vim-*.tar.gz -C /tmp/ \
    && mv /tmp/vim* /tmp/vim \
    && pushd /tmp/vim \
    && echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h \
    && ./configure \
      --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then \
        chown -Rv tester .; \
        su tester -c "LANG=en_US.UTF-8 make -j1 test" &> vim-test.log; \
    fi \
    && make install \
    && ln -sv vim /usr/bin/vi \
    && for L in  /usr/share/man/{,*/}man1/vim.1; do \
        ln -sv vim.1 $(dirname $L)/vi.1; \
    done \
    && ln -sv ../vim/vim90/doc /usr/share/doc/vim-$VER

# 8.69.2. Configuring Vim
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF

popd \
  && rm -rf /tmp/vim
