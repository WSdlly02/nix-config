# Windows 11 虚拟机配置基线

两套 XML 于 2026-09-05 从 `qemu:///system` 的 `Windows 11` 导出，使用
`virsh dumpxml --inactive` 保存持久配置，不包含运行时分配的设备别名等信息。
这是供手动比较、恢复的参考文件，NixOS rebuild 不会自动应用它。

| 文件 | 用途 |
| --- | --- |
| `windows11.xml` | 日常配置：显卡与音频直通，视频模型为 `none`，通过 Looking Glass IDD 显示。 |
| `windows11-rescue-vga.xml` | 救援配置：在日常配置基础上加入 VGA，供 virt-manager/SPICE 控制台使用。 |

两套配置指向同一个虚拟机和系统盘，仅视频设备不同；它们是切换方案，不是两个独立虚拟机。

## 已验证状态

- Windows 正常启动，AMD 核显及音频直通已恢复。
- Looking Glass 客户端与 Windows IDD 使用同一提交 `236efcb155`（B7-826）。
- 客户端日志确认 IDD 会话建立、收到 2560×1440 画面，剪贴板使用 LGMP。
- 日常配置已移除救援 VGA。用户确认启动及注销后的 Looking Glass 画面正常。
- 带 VGA 时曾出现注销后登录界面转到 VGA、登录后再转回 Looking Glass 的现象，因此仅在救援时启用 VGA；Windows 的显示设置仍可能关闭这个输出。
- 救援时曾禁用旧的 MikeTheTech Virtual Display Driver（`ROOT\DISPLAY\0000`）；新版 IDD 自带虚拟显示器，不依赖旧驱动。
- 临时安全模式启动标志已经清除。旧 Looking Glass Host 不应与 IDD 同时运行。
- 冷启动后无需人工桌面操作即可通过 `ssh guest-windows-11` 连接，具备管理员权限；`sshd`、`LGIddHelper` 自动运行，旧 Host 停止且禁用。
- 测试时 Windows 已自动建立用户桌面会话，因此不单独证明完全未登录时的 SSH 状态。
- 无 VGA 启动日志确认 IDD 使用 `mode=hw`；D3D12 共享内存资源测试仍出现 `0x887A0007`，随后回退间接复制并正常出画面，不能视为无错误启动。

Windows 内部驱动、显示设置不保存在 XML 中；画面传输成功也不单独证明 IDD 已使用 GPU 加速。

## 配置要点与外部依赖

- 8 GiB 大页内存，12 vCPU；CPU 绑核及 VFIO、kvmfr、大页钩子依赖同目录 `virtualisation.nix`。
- 系统盘：`/home/wsdlly02/Disks/Files/Files/VMs/windows11.qcow2`，VirtIO 接口。
- 直通宿主 PCI `0000:13:00.0`（显卡）及 `0000:13:00.1`（音频）。
- ROM：`/var/lib/libvirt/vbios/vbios_9700x.bin`、`/var/lib/libvirt/vbios/AMDGopDriver_9700x.rom`。
- 救援配置的 VGA 固定在客机 PCI `00:1e.0`，避免占用 IVSHMEM 使用的 `00:01.0`。
- Looking Glass 使用 `/dev/kvmfr0`，共享内存 128 MiB。
- 保留 VM UUID、MAC、UEFI NVRAM 路径和 TPM 定义。XML 不包含磁盘、NVRAM、TPM 状态或 ROM 文件的备份。
- 机器类型、固件及 QEMU 路径是本机当前环境的值；迁移主机或升级后应重新核对。

## 比较、更新与恢复

在仓库根目录比较当前持久配置：

```sh
virsh -c qemu:///system dumpxml --inactive 'Windows 11' > /tmp/windows11-current.xml
diff -u hosts/WSdlly02-PC/system-modules/windows11.xml /tmp/windows11-current.xml
```

确认新的配置可正常使用后，可将上述导出文件复制覆盖基线，并更新此说明。
若修改了磁盘、直通或其他公共配置，也应同步另一套 XML，使两者保持仅视频设备不同。

恢复时先在 Windows 内正常关机，确认 `domstate` 返回 `shut off`，备份当时的配置后再定义：

```sh
virsh -c qemu:///system domstate 'Windows 11'
virsh -c qemu:///system dumpxml --inactive 'Windows 11' > /tmp/windows11-before-restore.xml
virsh -c qemu:///system define --validate hosts/WSdlly02-PC/system-modules/windows11.xml
virsh -c qemu:///system start 'Windows 11'
```

需要救援 VGA 时，在上述关机、备份流程中将 `define` 命令替换为：

```sh
virsh -c qemu:///system define --validate hosts/WSdlly02-PC/system-modules/windows11-rescue-vga.xml
```

救援完成后正常关机，再定义 `windows11.xml` 即可恢复日常配置。

直通显卡曾在强制关机后出现下一次初始化失败；日常应从 Windows 正常关机。
