#!/bin/bash
# 连接已以 -s -S 启动的 QEMU（默认 localhost:1234），用于内核调试。
# 用法: 先在一个终端 DEBUG=1 ./run/run-qemu.sh，再在另一终端执行本脚本。
set -e

WORKDIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$WORKDIR"

if [ -f "$WORKDIR/config/default.conf" ]; then
    set -a
    source "$WORKDIR/config/default.conf"
    set +a
fi

VMLINUX=${VMLINUX:-}
GDB_PORT=${GDB_PORT:-1234}

# 若配置了带符号的 vmlinux，优先使用
if [ -n "$VMLINUX" ] && [ -f "$VMLINUX" ]; then
    VMLINUX_PATH="$VMLINUX"
elif [ -f "$WORKDIR/vmlinux" ]; then
    VMLINUX_PATH="$WORKDIR/vmlinux"
else
    # 无 vmlinux 时仍可连接，但无符号；用户可 later add-symbol-file
    VMLINUX_PATH=""
fi

echo "连接 GDB 到 localhost:$GDB_PORT"
if [ -n "$VMLINUX_PATH" ]; then
    echo "使用符号文件: $VMLINUX_PATH"
    exec gdb -ex "target remote :$GDB_PORT" \
        -ex "break start_kernel" \
        -ex "c" \
        "$VMLINUX_PATH"
else
    echo "未找到 vmlinux，将无符号连接。可设置 VMLINUX=/path/to/vmlinux"
    exec gdb -ex "target remote :$GDB_PORT" \
        -ex "break start_kernel" \
        -ex "c"
fi
