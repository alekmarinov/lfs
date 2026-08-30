#!/bin/bash
set -e
echo "Building Python-3.10 (build-time only).."
echo "Approximate build time: 1.5 SBU"
echo "Required disk space: 450 MB"

# BUILD_ONLY: firefox is built with it; nothing at runtime uses a second python
# BUILD_REQUIRES: 8.48-make-openssl 22-make-sqlite 8.6-make-zlib
# RUNTIME_REQUIRES:
#
# A second Python, kept only so firefox can be built.
#
# Firefox 102 comes from BLFS 11.2 and its build tooling predates Python 3.12:
# mach imports the imp module, and the pip and pkg_resources it vendors reach
# for pkgutil.ImpImporter and distutils. All of those were removed by the 3.13
# that LFS 12.4 installs, and they live inside vendored wheels rather than in
# mozilla's own source, so patching them is open ended. Mozilla supports 3.6 to
# 3.10 for this release, so firefox is handed the interpreter it expects.
#
# NOTE 'make altinstall', not 'make install'. altinstall installs python3.10 and
# leaves /usr/bin/python3 alone; a plain install would point python3 at 3.10 and
# quietly downgrade the interpreter the rest of the system uses.
#
# This is a build dependency only - see BUILD_ONLY above - so it is not part of
# any distro.

tar -xf /sources/Python-3.10*.tar.xz -C /tmp/ \
    && mv /tmp/Python-3.10* /tmp/python310 \
    && pushd /tmp/python310 \
    && ./configure \
        --prefix=/usr \
        --enable-shared \
        --with-system-expat \
        --with-ensurepip=yes \
    && make \
    && make altinstall \
    && popd \
    && rm -rf /tmp/python310

# The interpreter must exist and be able to build things, or firefox will fail
# far later for a reason that looks unrelated.
python3.10 --version
python3.10 -c "import ssl, sqlite3, zlib, ctypes; print('python3.10 modules ok')"
