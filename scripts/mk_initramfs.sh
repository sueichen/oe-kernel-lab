#!/bin/bash
# 使用 dracut 生成 initramfs，供 QEMU 启动指定内核使用。
set -e

WORKDIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$WORKDIR"

# 加载 config（default.conf + default.yaml 覆盖）
# shellcheck source=./load_config.sh
source "$WORKDIR/scripts/load_config.sh"

MODULES_DIR=${MODULES_DIR:-my_modules}
INITRAMFS_IMG=${INITRAMFS_IMG:-initramfs.img}

# 支持绝对路径：若已在 default.yaml 中配置为绝对路径则直接使用
if [[ "$MODULES_DIR" = /* ]]; then
    MODULES_PATH="$MODULES_DIR"
else
    MODULES_PATH="$WORKDIR/$MODULES_DIR"
fi
if [[ "$INITRAMFS_IMG" = /* ]]; then
    OUT_IMG="$INITRAMFS_IMG"
else
    OUT_IMG="$WORKDIR/$INITRAMFS_IMG"
fi

if [ ! -d "$MODULES_PATH/lib/modules" ]; then
    echo "错误: 未找到 $MODULES_PATH/lib/modules，请先准备内核模块目录。"
    echo "  可将内核编译产出中的 lib/modules/<kver> 拷贝到 $MODULES_PATH/lib/modules/ 下。"
    exit 1
fi

KERNEL_VERSION=$(ls -1 "$MODULES_PATH/lib/modules/" | head -1)
if [ -z "$KERNEL_VERSION" ]; then
    echo "错误: $MODULES_PATH/lib/modules 下无内核版本目录。"
    exit 1
fi

echo "=== 使用 dracut 生成 initramfs ==="
echo "  工作目录: $WORKDIR"
echo "  内核版本: $KERNEL_VERSION"
echo "  模块目录: $MODULES_PATH"
echo "  输出镜像: $OUT_IMG"
echo ""

if ! command -v dracut &>/dev/null; then
    echo "错误: 未找到 dracut，请安装 dracut 后再运行。"
    echo "  示例: dnf install dracut 或 yum install dracut"
    exit 1
fi

export DRACUT_KMODDIR_OVERRIDE=1
SRCMODS="$MODULES_PATH/lib/modules/$KERNEL_VERSION"

dracut \
    -f \
    -k "$SRCMODS" \
    --kver "$KERNEL_VERSION" \
    --no-hostonly \
    --drivers "virtio virtio_ring virtio_pci virtio_blk ext4 jbd2 mbcache" \
    --strip \
    "$OUT_IMG" \
    "$KERNEL_VERSION"

echo ""
echo "=== 生成完成 ==="
ls -lh "$OUT_IMG"
echo ""
echo "使用示例: make run 或 ./run/run-qemu.sh"
