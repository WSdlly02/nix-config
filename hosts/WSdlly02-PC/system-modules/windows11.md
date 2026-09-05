# Windows 11 虚拟机配置基线

`windows11.xml` 于 2026-09-05 从 `qemu:///system` 的 `Windows 11` 导出，使用
`virsh dumpxml --inactive` 保存持久配置，不包含运行时分配的设备别名等信息。
这是供手动比较、恢复的参考文件，NixOS rebuild 不会自动应用它。

## 已验证状态

- Windows 正常启动，AMD 核显及音频直通已恢复。
- Looking Glass 客户端与 Windows IDD 使用同一提交 `236efcb155`（B7-826）。
- 客户端日志确认 IDD 会话建立、收到 2560×1440 画面，剪贴板使用 LGMP。
- 保留救援 VGA，便于通过 virt-manager/SPICE 查看安装弹窗；Windows 的显示设置仍可能关闭这个输出。
- Windows 中旧的 MikeTheTech Virtual Display Driver（`ROOT\DISPLAY\0000`）已禁用，未卸载；新版 IDD 自带虚拟显示器。
- 临时安全模式启动标志已经清除。旧 Looking Glass Host 不应与 IDD 同时运行。

Windows 内部驱动、显示设置不保存在 XML 中；画面传输成功也不单独证明 IDD 已使用 GPU 加速。

## 配置要点与外部依赖

- 8 GiB 大页内存，12 vCPU；CPU 绑核及 VFIO、kvmfr、大页钩子依赖同目录 `virtualisation.nix`。
- 系统盘：`/home/wsdlly02/Disks/Files/Files/VMs/windows11.qcow2`，VirtIO 接口。
- 直通宿主 PCI `0000:13:00.0`（显卡）及 `0000:13:00.1`（音频）。
- ROM：`/var/lib/libvirt/vbios/vbios_9700x.bin`、`/var/lib/libvirt/vbios/AMDGopDriver_9700x.rom`。
- 救援 VGA 固定在客机 PCI `00:1e.0`，避免占用 IVSHMEM 使用的 `00:01.0`。
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

恢复时先在 Windows 内正常关机，确认 `domstate` 返回 `shut off`，备份当时的配置后再定义：

```sh
virsh -c qemu:///system domstate 'Windows 11'
virsh -c qemu:///system dumpxml --inactive 'Windows 11' > /tmp/windows11-before-restore.xml
virsh -c qemu:///system define --validate hosts/WSdlly02-PC/system-modules/windows11.xml
virsh -c qemu:///system start 'Windows 11'
```

直通显卡曾在强制关机后出现下一次初始化失败；日常应从 Windows 正常关机。
