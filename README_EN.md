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
- Your own built kernel and modules for initramfs (see below)

## Quick start

```bash
# 1. Build rootfs (default: x86_64 + debug packages)
make rootfs

# 2. Pack into qcow2
make qcow2

# 3. After preparing kernel modules, build initramfs
# Put kernel build output lib/modules/<kver> under my_modules/lib/modules/<kver>
make initramfs

# 4. Put bzImage (x86_64) or Image (aarch64) in project root, then run QEMU
make run
```

One-shot: rootfs → qcow2 → initramfs:

```bash
make all
```

## Configuration

Main config: `config/default.conf`. Override with environment variables:

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

Put the kernel image (`bzImage` for x86_64, `Image` for aarch64) in the project root, or set `KERNEL_IMAGE=/path/to/kernel`.

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

For symbols, put `vmlinux` in the project root or set `VMLINUX=/path/to/vmlinux`. See [docs/gdb.md](docs/gdb.md).

## Directory layout

```
oe-kernel-lab/
├── README.md
├── README_EN.md
├── Makefile
├── config/
│   ├── default.conf
│   ├── default.yaml
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
