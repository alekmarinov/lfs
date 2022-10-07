#!/bin/bash
set -e
echo "Building GCC.."
echo "Approximate build time: 160 SBU (with tests)"
echo "Required disk space: 5.1 GB"

# 8.26. GCC
# The GCC package contains the GNU compiler collection, which includes the C and C++ compilers.
VER=$(ls /sources/gcc-*.tar.xz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
tar -xf /sources/gcc-*.tar.xz -C /tmp/ \
    && mv /tmp/gcc-* /tmp/gcc \
    && pushd /tmp/gcc

# If building on x86_64, change the default directory name for 64-bit libraries to “lib”:
case $(uname -m) in
    x86_64)
        sed -e '/m64=/s/lib64/lib/' \
            -i.orig gcc/config/i386/t-linux64
    ;;
esac

# The GCC documentation recommends building GCC in a dedicated
# build directory:
mkdir -v build
cd       build

# prepare for compilation
../configure \
    --prefix=/usr \
    LD=ld \
    --enable-languages=c,c++ \
    --disable-multilib \
    --disable-bootstrap \
    --with-system-zlib

# Compile the package:
make

# Test the results, but do not stop at errors:
if [ $LFS_TEST -eq 1 ]; then
    # One set of tests in the GCC test suite is known to exhaust the
    # stack, so increase the stack size prior to running the tests:
    ulimit -s 32768

    make -k check || true
    # To receive a summary of the test suite results, run:
    ../contrib/test_summary
fi

# Install the package:
make install

# The GCC build directory is owned by tester now and the ownership of 
# the installed header directory (and its content) will be incorrect.
# Change the ownership to root user and group:
chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/$VER/include{,-fixed}

# Create a symlink required by the FHS for "historical" reasons.
ln -svr /usr/bin/cpp /usr/lib

# Add a compatibility symlink to enable building programs with Link Time Optimization (LTO):
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/12.2.0/liblto_plugin.so \
    /usr/lib/bfd-plugins/

# Now that our final toolchain is in place, it is important to again ensure that compiling
# and linking will work as expected. We do this by performing some sanity checks:
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

# Now make sure that we're setup to use the correct start files:
grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log

# Verify that the compiler is searching for the correct header files:
grep -B4 '^ /usr/include' dummy.log

# Next, verify that the new linker is being used with the correct search paths:
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'

# Next make sure that we're using the correct libc:
grep "/lib.*/libc.so.6 " dummy.log

# Finally, move a misplaced file:
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

# Cleanup
popd \
  && rm -rf /tmp/gcc
