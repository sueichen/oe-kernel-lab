# oe-kernel-lab 统一入口
# 用法: make rootfs | make qcow2 | make initramfs | make all | make run | make gdb
# 配置见 config/default.conf，可通过环境变量覆盖（如 ARCH=aarch64 make rootfs）

WORKDIR := $(shell pwd)
export WORKDIR
# 将 make ARCH=arm64 等传入脚本（否则脚本拿不到 ARCH，会用 default.conf 的 x86_64）
export ARCH
export PACKAGE_LIST
export ROOTFS_DIR

.PHONY: rootfs qcow2 initramfs all run gdb clean help

help:
	@echo "oe-kernel-lab - openEuler QEMU 内核调试环境"
	@echo ""
	@echo "  make rootfs     - 构建 rootfs（可设置 ARCH= PACKAGE_LIST=）"
	@echo "  make qcow2     - 将 rootfs 打包为 qcow2"
	@echo "  make initramfs  - 使用 dracut 生成 initramfs（需 my_modules）"
	@echo "  make all        - 依次执行 rootfs -> qcow2 -> initramfs"
	@echo "  make run        - 启动 QEMU（可设置 DEBUG=1 等待 GDB）"
	@echo "  make gdb        - 连接 QEMU GDB 服务（需先 DEBUG=1 make run）"
	@echo "  make clean      - 删除构建产物（rootfs 目录、qcow2、initramfs、raw）"
	@echo ""
	@echo "环境变量示例: ARCH=aarch64 make rootfs   PACKAGE_LIST=minimal make rootfs"

rootfs:
	@bash scripts/mk_rootfs.sh

qcow2:
	@bash scripts/mk_qcow2.sh

initramfs:
	@bash scripts/mk_initramfs.sh

all: rootfs qcow2 initramfs
	@echo "全部构建完成。"

run:
	@bash run/run-qemu.sh

gdb:
	@bash run/gdb-attach.sh

clean:
	@echo "清理构建产物..."
	@rm -rf rootfs rootfs.qcow2 rootfs.raw initramfs.img
	@echo "清理完成。"
