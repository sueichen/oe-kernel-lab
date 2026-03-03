#!/bin/bash
# 将可发布内容打包为 tar.gz 与 zip，排除构建产物与本地配置。
# 用法: ./scripts/mk_release.sh [版本号]
#       版本号可选，默认从 git 取 tag（如 v1.0.0）或 v1.0.0

set -e

WORKDIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$WORKDIR"

VERSION="${1:-$(git describe --tags --exact-match 2>/dev/null || echo 'v1.0.0')}"
# 去掉版本号前可能存在的 v，用于目录名；包名统一用 oe-kernel-lab-<VERSION>
NAME="oe-kernel-lab"
ARCHIVE_BASE="${NAME}-${VERSION}"
OUTDIR="${WORKDIR}/dist"
mkdir -p "$OUTDIR"

# 排除项：构建产物、git、本地/临时文件
EXCLUDE_TAR=(
    --exclude='.git'
    --exclude='.gitignore'
    --exclude='rootfs'
    --exclude='rootfs.qcow2'
    --exclude='rootfs.raw'
    --exclude='initramfs.img'
    --exclude='my_modules'
    --exclude='*.raw'
    --exclude='bzImage'
    --exclude='Image'
    --exclude='vmlinux'
    --exclude='vmlinux.gz'
    --exclude='config/local.conf'
    --exclude='dist'
    --exclude='*.tar.gz'
    --exclude='*.zip'
)

echo "=== 打包 $NAME $VERSION ==="
echo "  输出目录: $OUTDIR"
echo ""

PROJECT_DIR="$(basename "$WORKDIR")"
# 在临时目录构造 oe-kernel-lab-<VERSION>/，保证两种包解压后均为单一顶层目录
TMP_PACK=$(mktemp -d)
trap "rm -rf '$TMP_PACK'" EXIT
( cd "$WORKDIR/.." && tar cf - "${EXCLUDE_TAR[@]}" "$PROJECT_DIR" ) | ( cd "$TMP_PACK" && tar xf - )
mv "$TMP_PACK/$PROJECT_DIR" "$TMP_PACK/$ARCHIVE_BASE"

# 1. tar.gz
( cd "$TMP_PACK" && tar czvf "$OUTDIR/${ARCHIVE_BASE}.tar.gz" "$ARCHIVE_BASE" )
echo "  已生成: $OUTDIR/${ARCHIVE_BASE}.tar.gz"

# 2. zip
( cd "$TMP_PACK" && zip -rq "$OUTDIR/${ARCHIVE_BASE}.zip" "$ARCHIVE_BASE" )
echo "  已生成: $OUTDIR/${ARCHIVE_BASE}.zip"

echo ""
echo "完成。发布包: $OUTDIR/${ARCHIVE_BASE}.tar.gz, $OUTDIR/${ARCHIVE_BASE}.zip"
