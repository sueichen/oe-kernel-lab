# oe-kernel-lab

基于 openEuler 的 QEMU 内核调试环境：一键构建 rootfs、qcow2 镜像与 initramfs，方便在 QEMU 中启动并调试内核。

## 功能

- **多架构**：支持 x86_64、aarch64
- **可配置包列表**：默认提供调试/开发工具包（gdb、strace、vim 等），可切换为最小集或自定义
- **标准流程**：rootfs → qcow2 → initramfs，配合自带 QEMU 运行脚本与 GDB 连接脚本

## 依赖

- 宿主机为 openEuler / CentOS / RHEL 等（使用 dnf/yum）
- 构建 rootfs：`dnf`、`rpm`、`curl`、`python3`
- 构建 qcow2：`qemu-img`（raw 转 qcow2）、`e2fsprogs`（mkfs.ext4）
- 构建 initramfs：`dracut`
- 运行 QEMU：按宿主机架构安装 `qemu-system-x86`（x86_64）或 `qemu-system-aarch64`（aarch64）
- 调试内核需自备编译好的内核与模块（见下方「前期准备」）

### 一键安装依赖（dnf）

在 openEuler / CentOS / RHEL 上执行以下命令，按宿主机架构**二选一**安装 QEMU 运行包：

```bash
# 构建 rootfs + qcow2 + initramfs 所需（所有架构通用）
sudo dnf install -y dnf rpm curl python3 e2fsprogs util-linux qemu-img dracut

# 运行 QEMU 时启动虚拟机：按宿主机架构二选一
# x86_64 宿主机：
sudo dnf install -y qemu-system-x86_64

# aarch64 宿主机：
sudo dnf install -y qemu-system-aarch64
```

若仅构建 rootfs 与 qcow2、暂不制作 initramfs 或运行 QEMU，可只安装前一行中的 `qemu-img` 等必要包。

## 前期准备：内核与模块

在构建 initramfs 和运行 QEMU 之前，需要准备好**内核可引导镜像**（`bzImage`/`Image`）、**带符号的 vmlinux** 以及**内核模块目录**（`modules_dir`）。这些由内核源码编译生成。

### 必须准备的产物

| 产物 | 用途 | 说明 |
|------|------|------|
| **bzImage**（x86_64）或 **Image**（aarch64） | QEMU 启动内核 | 可引导的压缩内核镜像 |
| **vmlinux** | GDB 调试符号 | 带调试信息的 ELF，用于 `make gdb` |
| **modules_dir**（即 `lib/modules/<内核版本>`） | initramfs 与根文件系统加载驱动 | 内含 `modules.dep`、`kernel/` 等，供 dracut 打包 |

### 内核编译生成上述产物

在内核源码目录下执行（以 x86_64 为例）：

```bash
# 进入内核源码目录
cd /path/to/linux-src

# 配置（可选：make menuconfig 按需修改）
make defconfig

# 编译内核与模块
make -j$(nproc)
make modules

# 安装模块到指定目录（将 <项目根> 替换为 oe-kernel-lab 所在路径，或你在 config/default.yaml 中配置的 modules_dir 的父目录）
make modules_install INSTALL_MOD_PATH=<项目根>/my_modules

# 产物位置（示例，x86_64）：
# - 可引导镜像: arch/x86/boot/bzImage  → 拷贝到项目根或配置 kernel_image 指向
# - 符号文件:   vmlinux                    → 拷贝到项目根或配置 vmlinux 指向
# - 模块目录:   <INSTALL_MOD_PATH>/lib/modules/$(make -s kernelrelease)  → 与 config 中 modules_dir 对应
```

aarch64 时，可引导镜像为 `arch/arm64/boot/Image`，编译前需指定架构，例如：

```bash
make defconfig ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
make modules ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
make modules_install INSTALL_MOD_PATH=<项目根>/my_modules ARCH=arm64
```

编译完成后，请确保 `config/default.yaml`（或 `default.conf`）中的 **modules_dir** 指向上述 `INSTALL_MOD_PATH` 下的 `lib/modules/<kver>` 的**父目录**（即包含 `lib/modules` 的目录），**kernel_image** 与 **vmlinux** 指向你的 `bzImage`/`Image` 和 `vmlinux` 路径（可为绝对路径）。

## 快速开始

```bash
# 1. 构建 rootfs（默认 x86_64 + 调试工具包）
make rootfs

# 2. 打包为 qcow2
make qcow2

# 3. 准备内核模块目录后生成 initramfs（需先完成「前期准备」中的 modules_dir）
make initramfs

# 4. 将 bzImage/Image 与 vmlinux 放到项目根或已在 config/default.yaml 中配置路径后，启动 QEMU
make run
```

一键执行 rootfs → qcow2 → initramfs：

```bash
make all
```

## 配置

配置可通过 **`config/default.conf`**（KEY=value）、**`config/default.yaml`**（YAML）或**环境变量**指定。脚本先读 `default.conf`，再用 `default.yaml` 覆盖，最后环境变量优先。

### config/default.yaml 用法

- **与 default.conf 等效**：YAML 中的项会覆盖同名的 conf 配置（键名对应关系见下表）。
- **支持绝对路径**：`modules_dir`、`kernel_image`、`initramfs_img`、`qcow2_img`、`vmlinux` 可写绝对路径，便于内核与模块放在项目外时使用。

| YAML 键（default.yaml） | 说明 | 默认 |
|-------------------------|------|------|
| arch | 架构（x86_64 / aarch64） | x86_64 |
| rootfs_dir | rootfs 目录名 | rootfs |
| qcow2_img | 输出的 qcow2 文件名或绝对路径 | rootfs.qcow2 |
| initramfs_img | initramfs 输出文件名或绝对路径 | initramfs.img |
| package_list | 包列表 profile（debug / minimal） | debug |
| root_password | root 密码 | OpenEuler@123 |
| **modules_dir** | **内核模块目录**（用于 initramfs；可为绝对路径，如 `/path/to/my_modules`） | my_modules |
| **kernel_image** | **内核镜像路径**（bzImage/Image 或绝对路径） | bzImage / Image（按架构） |
| **vmlinux** | **GDB 符号文件路径**（可为绝对路径） | 空 |
| memory_mb / smp | 内存与 CPU 数 | 4096 / 4 |

示例（将内核与模块放在项目外时，在 `config/default.yaml` 中写）：

```yaml
modules_dir: /path/to/my_modules    # 含 lib/modules/<kver> 的目录
kernel_image: /path/to/bzImage     # 或 /path/to/Image（aarch64）
vmlinux: /path/to/vmlinux          # 可选，GDB 调试用
```

### config/default.conf 与环境变量

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

需事先完成「前期准备」：内核镜像（x86_64 为 `bzImage`，aarch64 为 `Image`）与模块目录就绪；镜像可放在项目根，或在 `config/default.yaml` 中配置 `kernel_image`（可写绝对路径）。

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

若需带符号调试，将 `vmlinux` 放在项目根或在 `config/default.yaml` 中配置 `vmlinux`（可写绝对路径）。更多说明见 [docs/gdb.md](docs/gdb.md)。

## 目录结构

```
oe-kernel-lab/
├── README.md
├── Makefile              # 统一入口
├── config/
│   ├── default.conf      # 默认配置
│   ├── default.yaml      # 主配置（YAML，可覆盖 default.conf，支持绝对路径）
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
