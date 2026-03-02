# oe-kernel-lab

OpenEuler-based QEMU kernel debugging environment: build rootfs, qcow2 image, and initramfs in one go, then boot and debug the kernel in QEMU.

## Features

- **Multi-arch**: x86_64 and aarch64
- **Configurable package sets**: Default debug/dev packages (gdb, strace, vim, etc.); optional minimal or custom lists
- **Simple workflow**: rootfs → qcow2 → initramfs, with QEMU run and GDB attach scripts

## Requirements

- Host: openEuler, CentOS, RHEL, or similar (dnf/yum)
- `dnf` / `yum`, `rpm`, `curl`
- `qemu-system-x86_64` or `qemu-system-aarch64`
- `dracut` for building initramfs
- Your own built kernel and modules (see **Environment preparation** below)

## Environment preparation: kernel and modules

Before building initramfs and running QEMU, you must have the **bootable kernel image** (`bzImage`/`Image`), **vmlinux** (with symbols), and the **kernel modules directory** (`modules_dir`). These are produced by building the kernel source.

### Required artifacts

| Artifact | Purpose | Notes |
|----------|---------|--------|
| **bzImage** (x86_64) or **Image** (aarch64) | Kernel boot in QEMU | Compressed bootable kernel image |
| **vmlinux** | GDB debug symbols | ELF with debug info, used by `make gdb` |
| **modules_dir** (i.e. `lib/modules/<kernel-version>`) | Initramfs and rootfs drivers | Contains `modules.dep`, `kernel/`, etc., for dracut |

### Building the kernel to produce these artifacts

From the kernel source tree (x86_64 example):

```bash
# Enter kernel source directory
cd /path/to/linux-src

# Configure (optional: make menuconfig)
make defconfig

# Build kernel and modules
make -j$(nproc)
make modules

# Install modules to a chosen directory (replace <project-root> with oe-kernel-lab path or parent of your modules_dir)
make modules_install INSTALL_MOD_PATH=<project-root>/my_modules

# Resulting paths (example):
# - Bootable image: arch/x86/boot/bzImage  → copy to project root or set kernel_image in config
# - Symbol file:   vmlinux                    → copy to project root or set vmlinux in config
# - Modules:        <INSTALL_MOD_PATH>/lib/modules/$(make -s kernelrelease)  → must match modules_dir in config
```

For aarch64, the bootable image is `arch/arm64/boot/Image`. Example:

```bash
make defconfig ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
make modules ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
make modules_install INSTALL_MOD_PATH=<project-root>/my_modules ARCH=arm64
```

After building, ensure **modules_dir** in `config/default.yaml` (or `default.conf`) points to the directory that **contains** `lib/modules` (the parent of `lib/modules/<kver>`). Set **kernel_image** and **vmlinux** to your `bzImage`/`Image` and `vmlinux` paths (absolute paths are supported).

## Quick start

```bash
# 1. Build rootfs (default: x86_64 + debug packages)
make rootfs

# 2. Pack into qcow2
make qcow2

# 3. Build initramfs (after preparing modules_dir in "Environment preparation")
make initramfs

# 4. Run QEMU (put bzImage/Image and vmlinux in project root or set paths in config/default.yaml)
make run
```

One-shot: rootfs → qcow2 → initramfs:

```bash
make all
```

## Configuration

Configuration is read from **`config/default.conf`** (KEY=value), then **`config/default.yaml`** (YAML overlay), then **environment variables** (highest priority).

### config/default.yaml usage

- **Overlays default.conf**: Keys in the YAML file override the same options from `default.conf` (see table below).
- **Absolute paths supported**: `modules_dir`, `kernel_image`, `initramfs_img`, `qcow2_img`, and `vmlinux` can be set to absolute paths so the kernel and modules can live outside the project.

| YAML key (default.yaml) | Description | Default |
|-------------------------|-------------|---------|
| arch | Architecture (x86_64 / aarch64) | x86_64 |
| rootfs_dir | Rootfs directory name | rootfs |
| qcow2_img | Output qcow2 file or path | rootfs.qcow2 |
| initramfs_img | Initramfs output file or path | initramfs.img |
| package_list | Package profile (debug / minimal) | debug |
| root_password | Root password | OpenEuler@123 |
| **modules_dir** | **Kernel modules directory** for initramfs; can be absolute (e.g. `/path/to/my_modules`) | my_modules |
| **kernel_image** | **Kernel image path** (bzImage/Image or absolute path) | bzImage / Image by arch |
| **vmlinux** | **GDB symbol file path** (can be absolute) | empty |
| memory_mb / smp | Memory and CPU count | 4096 / 4 |

Example when kernel and modules are outside the project (`config/default.yaml`):

```yaml
modules_dir: /path/to/my_modules
kernel_image: /path/to/bzImage     # or /path/to/Image for aarch64
vmlinux: /path/to/vmlinux          # optional, for GDB
```

### config/default.conf and environment variables

| Variable       | Description                    | Default                    |
|----------------|--------------------------------|----------------------------|
| ARCH           | Architecture                   | x86_64                     |
| ROOTFS_DIR     | Rootfs directory name          | rootfs                     |
| QCOW2_IMG      | Output qcow2 filename          | rootfs.qcow2               |
| PACKAGE_LIST   | Package profile (debug/minimal)| debug                      |
| ROOT_PASSWORD  | Root password                  | OpenEuler@123              |
| MODULES_DIR    | Kernel modules dir (initramfs) | my_modules                 |
| KERNEL_IMAGE   | Kernel image filename          | bzImage / Image (by arch)  |
| MEMORY_MB/SMP  | Memory and CPU count          | 4096 / 4                    |

Examples:

```bash
# aarch64 rootfs
ARCH=aarch64 make rootfs

# Minimal package set
PACKAGE_LIST=minimal make rootfs
```

## Package lists

- **base** (`config/packages/base.txt`): System and network base; always installed
- **debug** (default): Adds gdb, strace, htop, vim, gcc, cmake, make, etc. for kernel/userspace debugging
- **minimal**: No extra packages beyond base; enough to boot and get a shell

Add custom `config/packages/<profile>.txt` or set `PACKAGE_LIST` in config.

## Run and debug

### Start QEMU

```bash
make run
# or
./run/run-qemu.sh
```

Complete **Environment preparation** first (kernel image and modules). Put the kernel image in the project root or set `kernel_image` in `config/default.yaml` (absolute path supported).

### GDB kernel debug

1. Terminal 1: Start QEMU in debug mode (waits for GDB):

   ```bash
   DEBUG=1 make run
   ```

2. Terminal 2: Attach GDB:

   ```bash
   make gdb
   # or
   ./run/gdb-attach.sh
   ```

For symbols, put `vmlinux` in the project root or set `vmlinux` in `config/default.yaml` (absolute path supported). See [docs/gdb.md](docs/gdb.md).

## Directory layout

```
oe-kernel-lab/
├── README.md
├── README_EN.md
├── Makefile
├── config/
│   ├── default.conf
│   ├── default.yaml       # Main config (YAML, overlays default.conf, supports absolute paths)
│   ├── packages/          # base.txt, debug.txt, minimal.txt
│   └── openeuler/
├── scripts/
│   ├── mk_rootfs.sh
│   ├── mk_qcow2.sh
│   └── mk_initramfs.sh
├── run/
│   ├── run-qemu.sh
│   └── gdb-attach.sh
└── docs/
    ├── gdb.md
    └── initramfs-init.md
```

## License

MIT or compatible open license.
