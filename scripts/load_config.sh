# 加载 config/default.conf 与 config/default.yaml（YAML 覆盖）
# 被 scripts/*.sh 与 run/*.sh source，需在设置 WORKDIR 之后 source
# 环境变量优先于配置文件（make run ARCH=aarch64 等才能生效）
SAVED_ARCH=$ARCH
[ -n "$WORKDIR" ] || WORKDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CONFIG_DIR="$WORKDIR/config"

if [ -f "$CONFIG_DIR/default.conf" ]; then
    set -a
    # shellcheck source=../config/default.conf
    source "$CONFIG_DIR/default.conf"
    set +a
fi

# 简单解析 default.yaml 覆盖（key: value 或 key: "value"）
if [ -f "$CONFIG_DIR/default.yaml" ]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        if [[ "$line" =~ ^([a-z_]+):[[:space:]]*(.*)$ ]]; then
            ykey="${BASH_REMATCH[1]}"
            yval="${BASH_REMATCH[2]}"
            yval=$(echo "$yval" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            yval="${yval#\"}"; yval="${yval%\"}"
            case "$ykey" in
                arch) ARCH="$yval";;
                modules_dir) MODULES_DIR="$yval";;
                kernel_image) KERNEL_IMAGE="$yval";;
                rootfs_dir) ROOTFS_DIR="$yval";;
                qcow2_img) QCOW2_IMG="$yval";;
                initramfs_img) INITRAMFS_IMG="$yval";;
                package_list) PACKAGE_LIST="$yval";;
                qcow2_size_gb) QCOW2_SIZE_GB="$yval";;
                root_password) ROOT_PASSWORD="$yval";;
                memory_mb) MEMORY_MB="$yval";;
                smp) SMP="$yval";;
                vmlinux) VMLINUX="$yval";;
            esac
        fi
    done < "$CONFIG_DIR/default.yaml"
fi

# 环境变量优先；统一架构名：openEuler/QEMU 使用 aarch64，用户可能传入 arm64
ARCH=${SAVED_ARCH:-${ARCH:-x86_64}}
if [ "$ARCH" = "arm64" ]; then ARCH=aarch64; fi
