# 可选：静态 init 方案（initramfs init）

本项目默认使用 **dracut** 生成 initramfs（`make initramfs`），无需手写 init 程序，且能自动处理依赖与驱动。

若你希望使用**最小化、静态链接的 init**（不依赖 dracut 与宿主机用户态），可采用“手写 C init + cpio”的方式：

## 思路

- 使用一个纯 C、静态链接的 `init` 程序，在 initramfs 中挂载 `proc`、`sys`、`dev`，加载 ext4/virtio 等内核模块，等待 `/dev/vda` 出现后挂载根文件系统并 `pivot_root`，最后 `execve("/sbin/init", ...)`。
- 该 init 不依赖 busybox，可避免与当前内核/环境不兼容导致的 page fault。
- 编译时需指定模块目录，例如：`-DMODDIR=\"/lib/modules/6.6.0+\"`，并将对应内核的 `lib/modules/<kver>/kernel/fs/` 等模块打包进 cpio。

## 与 dracut 的对比

| 方式 | 优点 | 缺点 |
|------|------|------|
| dracut | 与发行版一致、驱动与依赖自动处理、维护简单 | 依赖宿主机 dracut、体积相对大 |
| 静态 init | 最小依赖、可完全控制内容、便于学习 | 需自行维护模块列表与 cpio 打包流程 |

## 参考实现

你可参考“手写 init + cpio”的示例代码（例如仓库中或其它项目中的 `initramfs_init.c`），按需修改 `MODDIR` 与加载的模块列表，再编写脚本将 init、模块和必要设备节点打成 cpio，替换 `initramfs.img`。本仓库以 dracut 流程为主，静态 init 仅作扩展方案文档说明。
