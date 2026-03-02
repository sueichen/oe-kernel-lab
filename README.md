# oe-kernel-lab

基于 openEuler 的 QEMU 内核调试环境：一键构建 rootfs、qcow2 镜像与 initramfs，方便在 QEMU 中启动并调试内核。

## 功能

- **多架构**：支持 x86_64、aarch64
- **可配置包列表**：默认提供调试/开发工具包（gdb、strace、vim 等），可切换为最小集或自定义
- **标准流程**：rootfs → qcow2 → initramfs，配合自带 QEMU 运行脚本与 GDB 连接脚本

## 依赖

- 宿主机为 openEuler / CentOS / RHEL 等（使用 dnf/yum）
- `dnf` / `yum`、`rpm`、`curl`
- `qemu-system-x86_64` 或 `qemu-system-aarch64`
- 制作 initramfs 需安装 `dracut`
- 调试内核需自备编译好的内核与模块（见下）

## 快速开始

```bash
# 1. 构建 rootfs（默认 x86_64 + 调试工具包）
make rootfs

# 2. 打包为 qcow2
make qcow2

# 3. 准备内核模块目录后生成 initramfs
# 将内核编译产出的 lib/modules/<kver> 放到项目根下的 my_modules/lib/modules/<kver>
make initramfs

# 4. 将 bzImage（x86_64）或 Image（aarch64）放到项目根，然后启动 QEMU
make run
```

一键执行 rootfs → qcow2 → initramfs：

```bash
make all
```

## 配置

主配置在 `config/default.conf`，可通过环境变量覆盖：

| 变量 | 说明 | 默认 |
|------|------|------|
| ARCH | 架构 | x86_64 |
| ROOTFS_DIR | rootfs 目录名 | rootfs |
| QCOW2_IMG | 输出的 qcow2 文件名 | rootfs.qcow2 |
| PACKAGE_LIST | 包列表 profile（base + debug/minimal） | debug |
| ROOT_PASSWORD | root 密码 | OpenEuler@123 |
| MODULES_DIR | 内核模块目录（用于 initramfs） | my_modules |
| KERNEL_IMAGE | 内核镜像文件名 | bzImage（x86_64）/ Image（aarch64） |
| MEMORY_MB / SMP | 内存与 CPU 数 | 4096 / 4 |

示例：

```bash
# aarch64 rootfs
ARCH=aarch64 make rootfs

# 最小包列表
PACKAGE_LIST=minimal make rootfs
```

## 包列表

- **base**（`config/packages/base.txt`）：系统与网络基础包，必选
- **debug**（默认）：在 base 上增加 gdb、strace、htop、vim、gcc、cmake、make 等，便于内核与用户态调试
- **minimal**：在 base 外不增加额外包，仅保证能启动与基本 shell

可自定义 `config/packages/<profile>.txt` 或在配置中指定 `PACKAGE_LIST`。

## 运行与调试

### 启动 QEMU

```bash
make run
# 或直接
./run/run-qemu.sh
```

需事先将内核镜像（x86_64 为 `bzImage`，aarch64 为 `Image`）放在项目根，或设置 `KERNEL_IMAGE=/path/to/kernel`。

### GDB 调试内核

1. 终端一：以调试模式启动 QEMU（会等待 GDB 连接）

   ```bash
   DEBUG=1 make run
   ```

2. 终端二：连接 GDB

   ```bash
   make gdb
   # 或
   ./run/gdb-attach.sh
   ```

若需带符号调试，将 `vmlinux` 放在项目根或设置 `VMLINUX=/path/to/vmlinux`。更多说明见 [docs/gdb.md](docs/gdb.md)。

## 目录结构

```
oe-kernel-lab/
├── README.md
├── Makefile              # 统一入口
├── config/
│   ├── default.conf      # 默认配置
│   ├── default.yaml      # 配置说明（YAML）
│   ├── packages/         # 包列表 base.txt, debug.txt, minimal.txt
│   └── openeuler/        # openEuler 源配置
├── scripts/
│   ├── mk_rootfs.sh
│   ├── mk_qcow2.sh
│   └── mk_initramfs.sh
├── run/
│   ├── run-qemu.sh       # 启动 QEMU
│   └── gdb-attach.sh     # GDB 连接
└── docs/
    ├── gdb.md            # GDB 调试说明
    └── initramfs-init.md # 可选静态 init 方案说明
```

## 许可

MIT 或与 openEuler 兼容的开放许可。
