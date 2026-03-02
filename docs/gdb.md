# GDB 调试内核

## 步骤

1. **编译内核并保留符号**  
   构建时生成 `vmlinux`（带符号）和 `bzImage`/`Image`（可引导镜像）。将 `vmlinux` 放到项目根或设置 `VMLINUX=/path/to/vmlinux`，便于 GDB 加载符号。

2. **准备 initramfs 所用模块**  
   将内核编译产出的 `lib/modules/<kver>` 放到项目根下 `my_modules/lib/modules/<kver>`，然后执行 `make initramfs`。

3. **以调试模式启动 QEMU**  
   在终端一执行：
   ```bash
   DEBUG=1 make run
   ```
   QEMU 会加上 `-s -S`，在 1234 端口等待 GDB 连接并暂停在启动阶段。

4. **连接 GDB**  
   在终端二执行：
   ```bash
   make gdb
   # 或指定符号文件
   VMLINUX=/path/to/vmlinux ./run/gdb-attach.sh
   ```

## 常用 GDB 命令

- `target remote :1234` — 连接 QEMU（脚本已自动执行）
- `break start_kernel` — 在 `start_kernel` 下断点（脚本已预设）
- `c` — 继续执行
- `break *<addr>` — 在指定地址下断点
- `list` — 查看源码（需已加载 vmlinux 符号）

## 多架构说明

- **x86_64**：使用宿主机的 `gdb` 即可。
- **aarch64**：若内核为 aarch64 编译，需使用 `gdb-multiarch` 或 `aarch64-linux-gnu-gdb`，并在 `gdb-attach.sh` 中或手动指定该 GDB。当前脚本默认调用 `gdb`，交叉调试时请自行替换为对应 GDB。
