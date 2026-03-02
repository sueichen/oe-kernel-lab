#!/bin/bash
# 启动 QEMU 虚拟机，支持 x86_64 / aarch64，可选 GDB 调试（DEBUG=1）。
set -e

WORKDIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$WORKDIR"

# 加载 config（default.conf + default.yaml 覆盖）
# shellcheck source=../scripts/load_config.sh
source "$WORKDIR/scripts/load_config.sh"

ARCH=${ARCH:-x86_64}
QCOW2_IMG=${QCOW2_IMG:-rootfs.qcow2}
INITRAMFS_IMG=${INITRAMFS_IMG:-initramfs.img}
if [ -z "$KERNEL_IMAGE" ]; then
    [ "$ARCH" = "aarch64" ] && KERNEL_IMAGE=Image || KERNEL_IMAGE=bzImage
fi
MEMORY_MB=${MEMORY_MB:-4096}
SMP=${SMP:-4}
DEBUG=${DEBUG:-0}

# 支持绝对路径（可在 default.yaml 中配置为绝对路径）
[[ "$QCOW2_IMG" = /* ]] && QCOW2_PATH="$QCOW2_IMG" || QCOW2_PATH="$WORKDIR/$QCOW2_IMG"
[[ "$INITRAMFS_IMG" = /* ]] && INITRD_PATH="$INITRAMFS_IMG" || INITRD_PATH="$WORKDIR/$INITRAMFS_IMG"
[[ "$KERNEL_IMAGE" = /* ]] && KERNEL_PATH="$KERNEL_IMAGE" || KERNEL_PATH="$WORKDIR/$KERNEL_IMAGE"

if [ ! -f "$QCOW2_PATH" ]; then
    echo "错误: 未找到镜像 $QCOW2_PATH，请先执行 make qcow2"
    exit 1
fi
if [ ! -f "$INITRD_PATH" ]; then
    echo "错误: 未找到 initramfs $INITRD_PATH，请先执行 make initramfs"
    exit 1
fi
if [ ! -f "$KERNEL_PATH" ]; then
    echo "错误: 未找到内核 $KERNEL_PATH，请指定 KERNEL_IMAGE 或将内核放到项目根目录"
    exit 1
fi

# x86_64 使用 dracut 生成的 initramfs 时建议 -cpu max，避免宿主机二进制触发 invalid opcode
QEMU_EXTRA=""
if [ "$ARCH" = "x86_64" ]; then
    QEMU_BIN="qemu-system-x86_64"
    QEMU_EXTRA="-cpu max"
    KERNEL_ARG="-kernel $KERNEL_PATH"
elif [ "$ARCH" = "aarch64" ]; then
    QEMU_BIN="qemu-system-aarch64"
    QEMU_EXTRA="-machine virt -cpu max"
    KERNEL_ARG="-kernel $KERNEL_PATH"
else
    echo "错误: 不支持的架构 ARCH=$ARCH（支持 x86_64, aarch64）"
    exit 1
fi

GDB_ARGS=""
if [ "$DEBUG" = "1" ] || [ "$DEBUG" = "yes" ]; then
    GDB_ARGS="-s -S"
    echo "GDB 调试模式已开启：QEMU 将等待 GDB 连接 :1234"
    echo "在另一终端执行: ./run/gdb-attach.sh 或 make gdb"
fi

echo "启动 QEMU ($ARCH): $QCOW2_PATH"
exec $QEMU_BIN \
    $QEMU_EXTRA \
    $KERNEL_ARG \
    -initrd "$INITRD_PATH" \
    -m "$MEMORY_MB" \
    -smp "$SMP" \
    -drive "file=$QCOW2_PATH,format=qcow2,if=virtio" \
    -nographic \
    $GDB_ARGS \
    -append "root=/dev/vda console=ttyS0 rw"
