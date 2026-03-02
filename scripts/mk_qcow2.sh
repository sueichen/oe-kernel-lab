#!/bin/bash
# 将 rootfs 目录打包为 qcow2 镜像。
set -e

WORKDIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$WORKDIR"

if [ -f "$WORKDIR/config/default.conf" ]; then
    set -a
    source "$WORKDIR/config/default.conf"
    set +a
fi

ROOTFS_DIR=${ROOTFS_DIR:-rootfs}
QCOW2_IMG=${QCOW2_IMG:-rootfs.qcow2}
QCOW2_SIZE_GB=${QCOW2_SIZE_GB:-16}

ROOTFS=$WORKDIR/$ROOTFS_DIR
RAW=${WORKDIR}/rootfs.raw
MNT=/mnt/rootfs_img

if [ ! -d "$ROOTFS" ]; then
    echo "错误: rootfs 目录不存在: $ROOTFS"
    echo "请先执行: make rootfs"
    exit 1
fi

echo "=== 构建 QCOW2 镜像 ==="
echo "  ROOTFS=$ROOTFS"
echo "  输出: $WORKDIR/$QCOW2_IMG"
echo "  大小: ${QCOW2_SIZE_GB}G"
echo ""

rm -f "$RAW" "$WORKDIR/$QCOW2_IMG"

# 1. 创建稀疏 RAW
dd if=/dev/zero of="$RAW" bs=1M seek=$((QCOW2_SIZE_GB * 1024)) count=0

# 2. 格式化 ext4
mkfs.ext4 -F -m 1 -E lazy_itable_init=1,lazy_journal_init=1 "$RAW"

# 3. 挂载并拷贝
mkdir -p "$MNT"
mount -o loop "$RAW" "$MNT"
cp -a "$ROOTFS"/. "$MNT"/

# 4. 清理 /dev
rm -rf "$MNT/dev"
mkdir -p "$MNT/dev"

# 5. fstab 与基础配置
mkdir -p "$MNT/etc"
cat > "$MNT/etc/fstab" << 'EOF'
/dev/vda / ext4 defaults 0 1
EOF
echo "openeuler" > "$MNT/etc/hostname"
grep -q "^root:" "$MNT/etc/passwd" || echo "root:x:0:0:root:/root:/bin/bash" >> "$MNT/etc/passwd"

# 6. 同步并卸载
sync
umount "$MNT"

# 7. 转换为 qcow2
qemu-img convert -f raw -O qcow2 -c "$RAW" "$WORKDIR/$QCOW2_IMG"
rm -f "$RAW"

echo "======================================="
echo "✅ QCOW2 镜像构建完成: $WORKDIR/$QCOW2_IMG"
echo "======================================="
ls -lh "$WORKDIR/$QCOW2_IMG"
