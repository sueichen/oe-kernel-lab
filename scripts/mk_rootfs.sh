#!/bin/bash
# 基于 openEuler 构建 rootfs，支持多架构与可配置包列表。
set -e

WORKDIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$WORKDIR"

# 保存 make 传入的环境变量（source 会覆盖）
SAVED_ARCH=$ARCH
# 加载配置（环境变量优先）
if [ -f "$WORKDIR/config/default.conf" ]; then
    set -a
    # shellcheck source=../config/default.conf
    source "$WORKDIR/config/default.conf"
    set +a
fi
# 环境变量优先于配置文件（make ARCH=arm64 rootfs 才能生效）
ARCH=${SAVED_ARCH:-${ARCH:-x86_64}}
# 统一架构名：openEuler 使用 aarch64，用户可能传入 arm64
[ "$ARCH" = "arm64" ] && ARCH=aarch64
ROOTFS_DIR=${ROOTFS_DIR:-rootfs}
PACKAGE_LIST=${PACKAGE_LIST:-debug}
ROOT_PASSWORD=${ROOT_PASSWORD:-OpenEuler@123}

if [ -f "$WORKDIR/config/openeuler/repos.conf" ]; then
    set -a
    # shellcheck source=../config/openeuler/repos.conf
    source "$WORKDIR/config/openeuler/repos.conf"
    set +a
fi

RELEASE_URL_KEY="RELEASE_URL_$ARCH"
RELEASE_URL="${!RELEASE_URL_KEY}"
REPO_FILE_URL=${REPO_FILE_URL:-https://raw.atomgit.com/src-openeuler/openEuler-repos/raw/openEuler-24.03-LTS-SP3/generic.repo}

if [ -z "$RELEASE_URL" ]; then
    echo "错误: 未找到架构 $ARCH 的 release 包配置，请检查 config/openeuler/repos.conf"
    exit 1
fi

ROOTFS=$WORKDIR/$ROOTFS_DIR
PACKAGES_BASE="$WORKDIR/config/packages/base.txt"
PACKAGES_EXTRA="$WORKDIR/config/packages/${PACKAGE_LIST}.txt"

echo "=== 构建 rootfs (ARCH=$ARCH) ==="
echo "  ROOTFS=$ROOTFS"
echo "  包列表: base + $PACKAGE_LIST"
echo ""

# 1. 创建基础目录
mkdir -p "$ROOTFS"/{var/lib/rpm,etc/yum.repos.d,proc,sys,dev,run,tmp}
chmod 1777 "$ROOTFS/tmp"

# 2. 初始化 RPM 数据库
rpm --root "$ROOTFS" --initdb

# 3. 安装 openEuler 发布包
rpm -ivh --nodeps --root "$ROOTFS" "$RELEASE_URL"

# 4. 添加 yum 源
curl -o "$ROOTFS/etc/yum.repos.d/openEuler.repo" "$REPO_FILE_URL"

# 5. 安装 dnf
dnf --installroot="$ROOTFS" install dnf --nogpgcheck -y
dnf --installroot="$ROOTFS" makecache

# 6. 安装软件包：base + 可选 profile
EXTRA_PKGS=""
if [ -f "$PACKAGES_EXTRA" ]; then
    EXTRA_PKGS=$(grep -v '^#' "$PACKAGES_EXTRA" | grep -v '^[[:space:]]*$' | tr '\n' ' ')
fi
BASE_PKGS=$(grep -v '^#' "$PACKAGES_BASE" | grep -v '^[[:space:]]*$' | tr '\n' ' ')
ALL_PKGS="$BASE_PKGS $EXTRA_PKGS"
dnf --installroot="$ROOTFS" install -y $ALL_PKGS

# 7. 配置 DNS
mkdir -p "$ROOTFS/etc"
cat > "$ROOTFS/etc/resolv.conf" << 'EOF'
nameserver 8.8.8.8
nameserver 114.114.114.114
EOF

# 8. 配置网络
mkdir -p "$ROOTFS/etc/sysconfig/network-scripts"
cat > "$ROOTFS/etc/sysconfig/network-scripts/ifcfg-eth0" << 'EOF'
TYPE=Ethernet
BOOTPROTO=dhcp
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
NAME=eth0
ONBOOT=yes
DEVICE=eth0
EOF

# 9. 系统配置
echo "openeuler" > "$ROOTFS/etc/hostname"
ln -sf /usr/share/zoneinfo/Asia/Shanghai "$ROOTFS/etc/localtime" 2>/dev/null || true

# 10. 设置 root 密码
echo "正在设置 root 密码..."
HASH=$(python3 - <<EOF
import crypt
print(crypt.crypt("$ROOT_PASSWORD", crypt.mksalt(crypt.METHOD_SHA512)))
EOF
)
sed -i "s|^root:[^:]*:|root:$HASH:|" "$ROOTFS/etc/shadow"
chmod 600 "$ROOTFS/etc/shadow"
echo "✓ 密码设置成功"

# 11. 启用服务
chroot "$ROOTFS" systemctl enable sshd NetworkManager 2>/dev/null || true

echo "rootfs 构建完成: $ROOTFS"
