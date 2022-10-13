#!/bin/bash
set -e
echo "Building Ninja.."
echo "Approximate build time: 0.6 SBU"
echo "Required disk space: 79 MB"

# 8.52. Ninja
# Ninja is a small build system with a focus on speed.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/ninja.html

tar -xf /sources/ninja-*.tar.gz -C /tmp/ \
    && mv /tmp/ninja-* /tmp/ninja \
    && pushd /tmp/ninja \
    && export NINJAJOBS=$JOB_COUNT \
    && sed -i '/int Guess/a \
        int j = 0; \
        char* jobs = getenv( "NINJAJOBS" ); \
        if ( jobs != NULL ) j = atoi( jobs ); \
        if ( j > 0 ) return j; \
        ' src/ninja.cc \
    && python3 configure.py --bootstrap \
    && if [ $LFS_TEST -eq 1 ]; then \
        ./ninja ninja_test; \
        ./ninja_test --gtest_filter=-SubprocessTest.SetWithLots; \
    fi \
    && install -vm755 ninja /usr/bin/ \
    && install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja \
    && install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja \
    && popd \
    && rm -rf /tmp/ninja
