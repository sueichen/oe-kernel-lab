# v1.0.0

---

## 中文 / Chinese

### 架构支持

- **x86_64**：在 x86_64 宿主机上构建 rootfs、qcow2、initramfs，并使用 QEMU 启动与调试内核。
- **aarch64 / arm64**：在 aarch64 宿主机或交叉环境下，支持 `ARCH=arm64` 或 `ARCH=aarch64` 构建 aarch64 rootfs，使用 QEMU（virt-7.2 + cortex-a72）启动，串口为 ttyAMA0，可正常进入系统并登录。

### 主要功能

- 基于 openEuler 24.03 LTS SP3 一键构建 rootfs、qcow2 镜像与 initramfs。
- 可配置包列表（base + debug/minimal），支持多架构及环境变量/配置文件覆盖。
- 提供 QEMU 启动脚本与 GDB 连接脚本，便于内核调试。
- 依赖说明与 dnf 一键安装命令已写入 README，便于在 openEuler/CentOS/RHEL 上安装 qemu-img、qemu-system-x86 / qemu-system-aarch64、dracut 等。

### 使用示例

```bash
# x86_64
make rootfs && make qcow2 && make initramfs && make run

# aarch64（宿主机或配置好内核/模块后）
make rootfs ARCH=aarch64    # 或 ARCH=arm64
make qcow2 && make initramfs ARCH=aarch64 && make run ARCH=aarch64
```

### 文档与配置

- 详见仓库内 README.md（中文）、README_EN.md（英文）。
- 配置可通过 `config/default.conf`、`config/default.yaml` 或环境变量（如 `ARCH`、`PACKAGE_LIST`）覆盖。

---

## English

### Architecture Support

- **x86_64**: Build rootfs, qcow2, and initramfs on an x86_64 host, then boot and debug the kernel with QEMU.
- **aarch64 / arm64**: On an aarch64 host or in a cross-build environment, use `ARCH=arm64` or `ARCH=aarch64` to build aarch64 rootfs. Boot with QEMU (virt-7.2 + cortex-a72), serial console on ttyAMA0; the system boots and login works as expected.

### Main Features

- One-command build of rootfs, qcow2 image, and initramfs based on openEuler 24.03 LTS SP3.
- Configurable package sets (base + debug/minimal), multi-arch support, and overrides via environment variables or config files.
- QEMU run script and GDB attach script for kernel debugging.
- README documents dependencies and dnf one-liners for installing qemu-img, qemu-system-x86 / qemu-system-aarch64, dracut, etc. on openEuler/CentOS/RHEL.

### Usage Examples

```bash
# x86_64
make rootfs && make qcow2 && make initramfs && make run

# aarch64 (after preparing kernel and modules)
make rootfs ARCH=aarch64    # or ARCH=arm64
make qcow2 && make initramfs ARCH=aarch64 && make run ARCH=aarch64
```

### Documentation and Configuration

- See README.md (Chinese) and README_EN.md (English) in the repository.
- Configuration can be overridden via `config/default.conf`, `config/default.yaml`, or environment variables (e.g. `ARCH`, `PACKAGE_LIST`).
