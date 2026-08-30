#!/bin/bash
set -e
echo "Building Python.."
echo "Approximate build time: 3.4 SBU"
echo "Required disk space: 283 MB"

# 8.50. Python
# The Python 3 package contains the Python development environment.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/Python.html
#
# BUILD_REQUIRES: 8.40-make-expat 8.50-make-libffi 8.48-make-openssl
# REBUILD_AFTER: 22-make-sqlite 8.79-make-util-linux
#
# Python is built twice. It has to exist early because meson and ninja are
# written in it and most of the build needs them, and at that point sqlite has
# not been built yet - so setup.py finds no sqlite3.h and quietly leaves the
# _sqlite3 module out. Nothing notices until something imports it: firefox's
# mach does, and stops with "No module named '_sqlite3'".
#
# The second build, after sqlite, is what puts the module in. This is the same
# shape as freetype and harfbuzz - see order-deps.sh.

VER=$(ls /sources/Python-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/Python-*.tar.xz -C /tmp/ \
    && mv /tmp/Python-* /tmp/python \
    && pushd /tmp/python \
    && ./configure \
        --prefix=/usr \
        --enable-shared \
        --with-system-expat \
        --with-system-ffi \
        --enable-optimizations \
    && make \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -dm755 /usr/share/doc/python-$VER/html; \
        tar --strip-components=1 \
            --no-same-owner \
            --no-same-permissions \
            -C /usr/share/doc/python-$VER/html \
            -xvf ../python-$VER-docs-html.tar.bz2; \
    fi \
    && popd \
    && rm -rf /tmp/python

# Python's setup.py builds each optional C extension only if it finds the
# library while python itself is compiling. When it does not, it prints a
# summary of what it skipped and exits 0 - the build succeeds and the module
# simply does not exist. Nothing notices until something imports it, which for
# _sqlite3 was firefox's mach, two days and two hundred packages later.
#
# The rule checked below needs no knowledge of the build order: if the library
# is installed now, the module must exist. On the first pass sqlite is not
# built yet so nothing is required of _sqlite3; on the rebuild after sqlite it
# is. A library which is never built - tk, here - is never required either.
echo "Checking the optional modules against the libraries which are installed.."
missing=""
check_module() {
    # check_module <module> <a header the library installs>
    [ -e "$2" ] || return 0
    python3 -c "import $1" 2>/dev/null && return 0
    echo "  $1 is missing, though $2 is installed"
    missing="$missing $1"
}
check_module _sqlite3 /usr/include/sqlite3.h
check_module _ssl     /usr/include/openssl/ssl.h
check_module _hashlib /usr/include/openssl/evp.h
check_module zlib     /usr/include/zlib.h
check_module _bz2     /usr/include/bzlib.h
check_module _lzma    /usr/include/lzma.h
check_module _curses  /usr/include/ncurses.h
check_module readline /usr/include/readline/readline.h
check_module _gdbm    /usr/include/gdbm.h
check_module _uuid    /usr/include/uuid/uuid.h
check_module _ctypes  /usr/include/ffi.h
check_module _tkinter /usr/include/tk.h

if [ -n "$missing" ]; then
    echo "
python was built without:$missing
The libraries are installed, so python was compiled before them. Build python
again after them - see the REBUILD_AFTER line above - rather than leaving the
modules out, because nothing else will report them absent."
    exit 1
fi
echo "  every module whose library is installed is present"
