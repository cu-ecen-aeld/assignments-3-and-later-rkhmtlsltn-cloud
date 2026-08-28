#!/bin/bash

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
    echo "Using default directory ${OUTDIR} for output"
else
    OUTDIR=$1
    echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p "${OUTDIR}"

# Build Linux kernel
cd "${OUTDIR}"

if [ ! -d "${OUTDIR}/linux-stable" ]
then
    echo "Cloning Linux kernel ${KERNEL_VERSION}"
    git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION} linux-stable
fi

cd "${OUTDIR}/linux-stable"

git checkout ${KERNEL_VERSION}

if [ ! -e "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" ]
then
    echo "Building Linux kernel"

    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} Image
fi

cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "${OUTDIR}/Image"

# Create root filesystem
cd "${OUTDIR}"

if [ -d "${OUTDIR}/rootfs" ]
then
    echo "Deleting old rootfs"
    sudo rm -rf "${OUTDIR}/rootfs"
fi

mkdir -p "${OUTDIR}/rootfs"
mkdir -p "${OUTDIR}/rootfs"/{bin,sbin,etc,proc,sys,dev,tmp,home,var,usr/bin,usr/sbin}

# Build BusyBox
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone git://busybox.net/busybox.git
fi

cd "${OUTDIR}/busybox"
git checkout ${BUSYBOX_VERSION}

make distclean
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig

# Static BusyBox is easier for initramfs
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config

make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX="${OUTDIR}/rootfs" install

# Create init script
cat > "${OUTDIR}/rootfs/init" << 'EOF'
#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

echo
echo "Welcome to AELD Linux"
echo

exec /bin/sh
EOF

chmod +x "${OUTDIR}/rootfs/init"

# Build writer for ARM64
cd "${FINDER_APP_DIR}"

make clean
make CROSS_COMPILE=${CROSS_COMPILE} LDFLAGS="-static"

cp writer "${OUTDIR}/rootfs/home/writer"
# Copy finder application files
cp finder.sh "${OUTDIR}/rootfs/home/"
cp finder-test.sh "${OUTDIR}/rootfs/home/"
cp autorun-qemu.sh "${OUTDIR}/rootfs/home/"

mkdir -p "${OUTDIR}/rootfs/home/conf"

cp ../conf/username.txt "${OUTDIR}/rootfs/home/conf/"
cp ../conf/assignment.txt "${OUTDIR}/rootfs/home/conf/"

# Fix paths for target filesystem
sed -i 's#../conf/username.txt#conf/username.txt#' \
    "${OUTDIR}/rootfs/home/finder-test.sh"

sed -i 's#../conf/assignment.txt#conf/assignment.txt#' \
    "${OUTDIR}/rootfs/home/finder-test.sh"

# Make scripts executable
chmod +x "${OUTDIR}/rootfs/home/"*.sh
chmod +x "${OUTDIR}/rootfs/home/writer"

# Create device nodes
sudo mknod -m 666 "${OUTDIR}/rootfs/dev/null" c 1 3 || true
sudo mknod -m 666 "${OUTDIR}/rootfs/dev/console" c 5 1 || true

# Set ownership
sudo chown -R root:root "${OUTDIR}/rootfs"

# Create initramfs
cd "${OUTDIR}/rootfs"

sudo find . -print0 | sudo cpio --null -ov --format=newc | gzip -9 > "${OUTDIR}/initramfs.cpio.gz"

echo
echo "========================================"
echo "Assignment 3 Part 2 build complete"
echo "Kernel:    ${OUTDIR}/Image"
echo "Initramfs: ${OUTDIR}/initramfs.cpio.gz"
echo "========================================"

