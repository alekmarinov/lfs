#!/bin/bash
# Boots the image under qemu and checks lpkg on the running system.
#
#   test-boot.sh [<distro>]
#
# 'make test' runs lpkg in a container, which is the same rootfs but not the
# same machine: no firmware, no kernel, no init, no network. This is the level
# above - it answers whether the thing boots, and whether lpkg can reach a
# channel over http once it has.
#
# The image is copied first and the copy is patched, so the image 'make image'
# produced is left alone. Three things have to be arranged, none of them
# obvious, and all three cost a wasted boot to discover:
#
#   the nvram is reset. It is a UEFI variable store which survives between
#   boots, and a stale one sent the firmware to its internal shell instead of
#   the disk - the image was fine and never got a chance to load.
#
#   a serial console is added to the kernel command line, because the image is
#   built for a screen. Without it a headless boot prints nothing at all and
#   there is no way to tell a hang from a success.
#
#   the test waits for the network. dhcpcd configures eth0 asynchronously and
#   a fixed sleep raced it - the first run reported the channel unreachable on
#   a system whose networking was about to come up perfectly.
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/.." &> /dev/null && pwd )
cd "$BASE_DIR"

DISTRO="${1:-minimal}"
OUT=$("$BASE_DIR/scripts/resolve-distro.sh" -o "$DISTRO")
IMAGE="$OUT/image.img"
PORT="${BOOT_TEST_PORT:-8099}"
TIMEOUT="${BOOT_TEST_TIMEOUT:-300}"

[ -f "$IMAGE" ] || { echo "No image at $IMAGE - run 'make image DISTRO=$DISTRO' first"; exit 1; }
command -v qemu-system-x86_64 > /dev/null || { echo "qemu-system-x86_64 is not installed"; exit 1; }

for dir in /usr/share/OVMF /usr/share/ovmf /usr/share/edk2/ovmf; do
    for name in OVMF_CODE_4M.fd OVMF_CODE.fd; do
        [ -f "$dir/$name" ] && { OVMF_CODE="$dir/$name"; OVMF_VARS="$dir/${name/CODE/VARS}"; break 2; }
    done
done
[ -n "${OVMF_CODE:-}" ] || { echo "No OVMF firmware; install it with 'sudo apt install ovmf'"; exit 1; }

ABI=$(sed -n 's/^ABI_ID=//p' "$OUT/rootfs/etc/os-release" 2>/dev/null)
[ -d "repo/$ABI" ] || { echo "No channel for this image at repo/$ABI - run 'make repo'"; exit 1; }

WORK=$(mktemp -d)
TESTIMG="$WORK/image.img"
SERIAL="$WORK/serial.log"
cleanup() {
    [ -n "${HTTP_PID:-}" ] && kill "$HTTP_PID" 2>/dev/null
    [ -n "${LOOP:-}" ] && sudo losetup -d "$LOOP" 2>/dev/null
    sudo rm -rf "$WORK"
}
trap cleanup EXIT

echo "Copying $IMAGE..."
cp --reflink=auto "$IMAGE" "$TESTIMG"

echo "Patching the copy for a headless boot..."
LOOP=$(sudo losetup -fP --show "$TESTIMG")
MNT="$WORK/mnt"; mkdir -p "$MNT"
sudo mount "${LOOP}p2" "$MNT"

sudo sed -i 's|\(linux .*root=[^ ]* ro[^\n]*\)|\1 console=tty0 console=ttyS0,115200|; s/^set timeout=.*/set timeout=0/' \
    "$MNT/boot/grub/grub.cfg"
printf 'REPO_URL=http://10.0.2.2:%s\n' "$PORT" | sudo tee "$MNT/etc/lpkg/lpkg.conf" > /dev/null

sudo tee "$MNT/usr/local/sbin/lpkg-boottest" > /dev/null <<EOF
#!/bin/bash
exec > /dev/console 2>&1
echo "=====BOOTTEST-BEGIN====="
for i in \$(seq 1 40); do
    curl -fsS -o /dev/null --max-time 2 http://10.0.2.2:$PORT/ 2>/dev/null && break
    sleep 1
done
echo "net       \$(ip -4 -o addr show scope global 2>/dev/null | awk '{print \$2, \$4}' | tr '\n' ' ')after \${i}s"
echo "kernel    \$(uname -sr)"
echo "abi       \$(sed -n 's/^ABI_ID=//p' /etc/os-release)"
echo "lpkg      \$(lpkg version), \$(lpkg list | wc -l) packages recorded"
echo "awk       \$(echo ok | awk '{print \$1}')"
echo "owns      \$(lpkg owns /usr/bin/bash)"
echo "verify    \$(lpkg verify 2>&1 | tail -1)"
lpkg sync 2>&1 | sed 's/^/sync      /'
echo "guard     \$(lpkg --yes --reinstall install glibc 2>&1 | head -1)"
lpkg --yes install unzip 2>&1 | sed 's/^/install   /'
echo "runs      \$(unzip -v 2>/dev/null | head -1 | cut -c1-40)"
echo "owned     \$(lpkg owns /usr/bin/unzip)"
lpkg --yes remove unzip 2>&1 | sed 's/^/remove    /'
echo "gone      \$([ -e /usr/bin/unzip ] && echo no || echo yes)"
echo "=====BOOTTEST-END====="
sleep 2
/sbin/poweroff -f
EOF
sudo chmod +x "$MNT/usr/local/sbin/lpkg-boottest"
grep -q lpkg-boottest "$MNT/etc/inittab" 2>/dev/null \
    || sudo sed -i '/^1:2345:respawn/i bt:2345:once:/usr/local/sbin/lpkg-boottest' "$MNT/etc/inittab"

sudo umount "$MNT"; sudo losetup -d "$LOOP"; LOOP=""

# a fresh variable store, or the firmware may prefer whatever it booted last
cp -f "$OVMF_VARS" "$TESTIMG.nvram"

echo "Serving repo/ on port $PORT..."
( cd repo && exec python3 -m http.server "$PORT" --bind 0.0.0.0 ) > /dev/null 2>&1 &
HTTP_PID=$!
sleep 1

echo "Booting..."
sudo timeout "$TIMEOUT" qemu-system-x86_64 \
    -enable-kvm -cpu host -m "${QEMU_MEMORY:-2048}" -smp "${QEMU_CPUS:-4}" -machine q35 \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    -drive if=pflash,format=raw,file="$TESTIMG.nvram" \
    -drive file="$TESTIMG",format=raw,if=none,id=disk0 \
    -device ahci,id=ahci -device ide-hd,drive=disk0,bus=ahci.0 \
    -netdev user,id=net0 -device e1000e,netdev=net0 \
    -display none -serial "file:$SERIAL" -no-reboot > /dev/null 2>&1
qemu_rc=$?

echo
if ! grep -aq 'BOOTTEST-BEGIN' "$SERIAL" 2>/dev/null; then
    echo "The system did not reach the test. Last of the serial log:"
    tail -20 "$SERIAL" 2>/dev/null | tr -d '\r' | sed 's/^/    /'
    exit 1
fi
sed -n '/BOOTTEST-BEGIN/,/BOOTTEST-END/p' "$SERIAL" | tr -d '\r' | sed 's/^/  /'
echo

fail=0
want() {
    if grep -aq "$2" "$SERIAL"; then printf '  ok    %s\n' "$1"
    else printf '  FAIL  %s\n' "$1"; fail=$((fail + 1)); fi
}
want "it boots and init runs"          'BOOTTEST-BEGIN'
want "awk works"                       '^awk *ok'
want "the database survived the image" 'packages recorded'
want "the channel verifies over http"  'signature ok'
want "core refuses a live install"     'cannot be installed into a running system'
want "a package installs from http"    '^owned .*owned by unzip'
want "and the program runs"            '^runs *UnZip'
want "and removal takes it away"       '^gone *yes'
want "it powered off cleanly"          'BOOTTEST-END'
echo
[ "$qemu_rc" -eq 0 ] || echo "  note: qemu exited $qemu_rc (124 means it never powered off)"
[ "$fail" -eq 0 ] && echo "boot test passed" || { echo "$fail check(s) failed"; exit 1; }
