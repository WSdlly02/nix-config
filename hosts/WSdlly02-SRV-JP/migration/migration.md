# 只有 SSH 和面板快照时，如何把 VPS 就地换成 NixOS

2026-11-15，WSdlly02-SRV-JP 从 Debian 13 切换到 NixOS 26.11。ByteVirt 面板提供了整机快照，操作时可用的远程入口只有 SSH。我们在 PC 上造好系统盘，让 VPS 从内存启动一个能接受 SSH 的 Linux，在那里覆盖旧盘，再把业务数据和主机身份还原到新盘。

这条路径适合能控制引导器、能从客户机内写整盘的虚拟机。**最重要的分界是第一次写盘**。此前还能靠一次性引导返回旧系统。此后能用于恢复的是仍在运行的内存系统、服务商快照和 PC 冷备份。

## 换一台机器，先确认什么

| 项目 | SRV-JP 的做法 | 换机时要确定的值 |
| --- | --- | --- |
| 引导与磁盘 | x86_64 KVM、BIOS/GRUB、30 GiB VirtIO 单盘、MBR/ext4 | CPU 架构、固件、控制器、磁盘字节数和分区布局。UEFI 需要 EFI 系统分区和相应引导器。整盘哈希比对要求镜像和目标盘等长。 |
| 网络 | 按 MAC 识别网卡，静态双栈，IPv6 网关在分配的前缀之外 | 从运行态和 cloud-init seed 核对地址、前缀、网关、路由、DNS。维护系统和新系统都要能从 PC 连入。此机的 IPv6 默认路由需要 `onlink`。 |
| 身份与业务 | 复用 SSH 主机密钥、用户公钥、UID/GID 和 rootless Podman 的 subuid/subgid | 区分操作者的公钥、服务器主机密钥和应用凭据。盘点挂载、匿名卷、密钥及仍在写入的服务。 |
| 故障恢复 | PC 上用 QEMU 演练切换和回退，线上写盘前创建面板快照 | 确认从 SSH 失联状态还能怎样重启或恢复快照。容器型 VPS 如果由宿主管理内核和引导，就没有这里所需的启动入口。 |

## 1. 在 PC 上制作镜像和维护系统

主机的引导、磁盘、网络和账户由 [nixos.nix](../nixos.nix) 定义，用户服务由 [home.nix](../home.nix) 定义。[disk-image.nix](disk-image.nix) 生成含 GRUB 的 qcow2 整盘镜像，也把 Home Manager generation 放入镜像。[maintenance.nix](maintenance.nix) 生成运行在 RAM 中的 initramfs，带网卡和磁盘驱动、Dropbear、zstd、dd 和 sha256sum。

在仓库根目录运行，按输出目录名识别系统镜像（srv-jp-bios-image）、基础 initramfs（srv-jp-maintenance-initramfs）和 Linux 内核。将三个目录中的 `nixos.qcow2`、`initrd` 和 `bzImage` 取到 PC 工作目录。

```bash
nix build --impure --no-link --print-out-paths --expr '
  let
    f = builtins.getFlake (toString ./.);
    host = f.nixosConfigurations.WSdlly02-SRV-JP;
    home = f.homeConfigurations."wsdlly02@WSdlly02-SRV-JP";
  in [
    (import ./hosts/WSdlly02-SRV-JP/migration/disk-image.nix { inherit host home; })
    (import ./hosts/WSdlly02-SRV-JP/migration/maintenance.nix { inherit host; })
    host.config.system.build.kernel
  ]'
```

在 PC 工作目录将 qcow2 转为可直接写盘的 raw，记录逻辑字节数和本次构建的哈希。SRV-JP 的 raw 为 32,212,254,720 字节，zstd 压缩后约 810 MiB。

```bash
qemu-img convert -f qcow2 -O raw nixos.qcow2 system.raw
zstd -T0 system.raw -o system.raw.zst
stat -c %s system.raw
sha256sum system.raw system.raw.zst > SHA256SUMS
```

基础 initramfs 需要追加一个私有的 gzip 压缩 `newc` 归档。其中 `etc/dropbear/host-key` 是本次维护专用的 Dropbear 格式主机私钥，`root/.ssh/authorized_keys` 放操作者已有的公钥。两个文件归 root、权限 0600，`root/.ssh` 权限 0700。将基础 initramfs 和这个归档按顺序拼接成最终 initrd，在 Nix store 和 Git 之外保存。在 PC 为维护 SSH 单独固定主机公钥，同时保留原系统的 SSH 指纹，供新系统启动时核对。例如，在 PC 的私有工作目录中运行下面的命令；`id_rsa.pub` 替换为这次要用的用户公钥。

```bash
set -euo pipefail
umask 077
mkdir -m 700 private-initrd
ssh-keygen -q -t ed25519 -N '' -f private-initrd/maintenance-host
dropbearconvert openssh dropbear private-initrd/maintenance-host private-initrd/host-key
install -Dm600 private-initrd/host-key private-initrd/etc/dropbear/host-key
install -Dm600 ~/.ssh/id_rsa.pub private-initrd/root/.ssh/authorized_keys
chmod 700 private-initrd/root private-initrd/root/.ssh
( cd private-initrd && find etc root -print0 | cpio --null -o -H newc -R 0:0 | gzip -n ) > private-initrd/keys.gz
cat initrd private-initrd/keys.gz > maintenance.initrd
ssh-keygen -lf private-initrd/maintenance-host.pub
```

## 2. 演练一次性启动和回退

先在 QEMU 用匹配的固件、磁盘与网卡型号走完整条路径。给演练磁盘留一份可恢复的副本，实际验证从旧系统进入 RAM、写入新盘、从新盘启动，以及还原旧盘后能重新登录。线上再单独演练一次**只进 RAM、原盘不写**的往返。

在旧系统的 `/boot/srv-jp-maintenance/` 以 root 属主、0600 权限放入维护内核和最终 initrd，分别命名为 `kernel` 和 `initrd`。给现有 GRUB 增加一个独立菜单项，保留默认启动项。本次的菜单项如下，`<BOOT_FS_UUID>` 要换成 GRUB 能读取这两个文件的文件系统 UUID。这里的 `/boot` 位于根分区；独立 boot 分区应使用相对于该分区的路径。

```grub
menuentry 'SRV-JP maintenance (RAM)' --id srv-jp-maintenance {
  search --no-floppy --fs-uuid --set=root <BOOT_FS_UUID>
  linux /boot/srv-jp-maintenance/kernel console=tty0 console=ttyS0,115200 net.ifnames=0 panic=15
  initrd /boot/srv-jp-maintenance/initrd
}
```

确认现有 GRUB 配置会加载该项，再执行 `sudo grub-reboot srv-jp-maintenance`。用 `sudo grub-editenv list` 确认 `next_entry`，然后重启。通过维护指纹登录，检查 `/proc/mounts` 中根位于 RAM、目标盘及其分区均未挂载，`/proc/swaps` 只有表头，并实际验证网络。此时重启应回到 Debian，原 SSH 指纹和业务均应恢复。一次性引导只决定**下次重启**的去向；如果 RAM 系统启动后网络不通，仍需要面板发起重启或恢复。

## 3. 停业务，做一份能恢复的冷备份

创建面板快照后，先记下每个运行容器的镜像名、镜像 ID 和挂载。停止 Quadlet 可能连同容器一起删除匿名卷，因此本次先导出了运行中的 Tunnel 凭据，并暂停 Xray、复制两个匿名卷。然后停止六项用户服务，确认它们全部 inactive、`podman ps -q` 为空，才归档应用文件。

| 备份 | 本次归档的内容 |
| --- | --- |
| `cold.tar.zst.gpg` | 用户和 root 家目录、`/etc`、`/var/www`、`/var/lib` 等持久数据。包括 Yunzhizuo 程序和数据库、resolver 的环境与缓存、Hysteria 的 ACME 状态。保留数字属主、ACL 和扩展属性。 |
| `migration.tar.zst.gpg` | 用 `podman save` 导出的五个原镜像、镜像 ID 清单、Tunnel 凭据和 Xray 卷。可在新的 rootless 容器存储中离线恢复。 |
| `identity.tar.zst.gpg` | 三种 SSH 主机密钥及公钥、原有两个账户的密码哈希。 |

在旧系统上先将归档与源文件比对，再记录压缩归档的 SHA-256。通过 SSH 传到 PC，加密保存。在 PC **实际解密**，对解密出的压缩流重新计算 SHA-256，与旧系统记录逐一比对；再读 tar 成员表，确认业务文件、密钥、卷均在，导出的五个镜像 ID 等于停机前的 ID。这些检查通过后才开始覆盖磁盘。

本次备份在 PC 的 `~/.local/state/srv-jp-backups/20261115-100259/`，解密口令文件单独在 `~/.local/state/srv-jp-backup-keys/20261115-100259.key`。在备份目录执行 `sha256sum -c ENCRYPTED-SHA256SUMS` 可以复核现存密文。要再次核对解密结果，可运行以下只读命令。

```bash
set -euo pipefail
for archive in cold migration identity; do
  file="$archive.tar.zst"
  gpg --batch --pinentry-mode loopback \
    --passphrase-file ~/.local/state/srv-jp-backup-keys/20261115-100259.key \
    --decrypt "$file.gpg" | sha256sum | diff - <(awk -v f="$file" '$2 == f {print $1 "  -"}' SHA256SUMS)
done
```

## 4. 从 RAM 写盘并回读

再次一次性启动维护环境。通过固定的维护主机指纹登录，重新核对主机名、网卡 MAC、挂载和 swap，并用 `blockdev --getsize64 /dev/vda` 对照 PC 记录的 raw 字节数。迁移多盘主机时，在旧系统用 `lsblk -o NAME,SIZE,SERIAL,WWN,PARTUUID,UUID,MOUNTPOINTS` 记录系统盘；进入 RAM 后按可用的序列号、分区 UUID 和布局识别到唯一设备再写。SRV-JP 的覆盖目标是**整盘** `/dev/vda`，包括引导器和分区表。

单路传输可以在 PC 把 `system.raw.zst` 经 SSH 送入维护机的 `zstd -dc | dd of=/dev/vda bs=4M iflag=fullblock conv=fsync`。在远端 shell 开启 `set -o pipefail`，并检查 SSH 退出状态。本次上行单路较慢，改用 8 条独立 SSH 连接。先停止原写入进程，记录已写字节偏移并向下对齐到 8 MiB。PC 将剩余 raw 按 8 MiB 分块独立压缩，各连接按块号用 `dd bs=8M seek=<起始块号> conv=notrunc,fsync` 写入互不重叠的区间。失败的区间可从同一偏移重写。单个 zstd 流中任意截取的片段不能独立解压。

所有写入进程成功退出后，在维护机执行以下命令，并与 PC 上 **raw 文件**的 SHA-256 比较。相等后才重新读取分区表并挂载新根。线上已回读并匹配全部 30 GiB。

```sh
sync
blockdev --flushbufs /dev/vda
sha256sum /dev/vda
```

核对上述输出与 PC 上 `SHA256SUMS` 中 `system.raw` 一行。匹配后，再单独运行：

```sh
blockdev --rereadpt /dev/vda
mkdir -p /mnt
mount -t ext4 /dev/vda1 /mnt
```

## 5. 恢复身份、数据和服务

1. 在维护环境将 PC 备份恢复到新根。先放回 `/etc/ssh/ssh_host_*_key*` 和 `/var/lib/local-credentials/`，再恢复业务文件、用户配置和卷数据。使用新盘自带的 GNU tar 保留数字属主、ACL 和扩展属性，落盘后与归档比对。旧 Debian 的 Podman 存储和手写用户单元保留在备份中，由 NixOS 的 Podman 和 [home.nix](../home.nix) 接管运行。
2. 同步并卸载新根后重启。用原主机指纹和原用户密钥登录，核对 `nixos-version`、根设备、双栈路由和 swap。单独用 `passwd -S` 检查账户状态。镜像里预建的账户即使收到了 `hashedPasswordFile`，首次启动后也可能仍处于锁定状态。
3. 以原来的普通用户执行 `podman load`，核对五个镜像 ID，并通过标准输入重新创建 `yunzhizuo-tunnel-token`。随后执行 `gen=$(cat /etc/nixos/home-activation-path)` 和 `HOME_MANAGER_BACKUP_EXT=pre-nixos "$gen/activate"`。原有冲突配置会以 `.pre-nixos` 后缀保留。
4. 检查 `loginctl show-user "$USER" -p Linger`、六个用户单元和五个运行容器。此机首次启动时网卡已可用，但 Podman 仍在等待系统级 `network-online.target`。已在 NixOS 配置里让 `multi-user.target` 拉起它，并部署了该修正。业务恢复后清理 VPS 上临时解包的凭据和归档。

## 中断后如何回退

| 中断的位置 | 可用的恢复路径 |
| --- | --- |
| 已停业务，尚未写盘 | 如果已进入 RAM，重启回默认的 Debian。在旧系统核对 Xray 匿名卷和 Tunnel 凭据，按需从冷备份恢复并挂到原路径，再启动或重启对应服务、核对业务。 |
| 已开始写盘，维护 SSH 仍通 | 保持 RAM 系统运行。可以重新传输受影响的区间，或从头写入镜像。整盘哈希匹配后再挂载。如果决定返回 Debian，从面板恢复迁移前快照。 |
| 已覆盖旧盘，维护 SSH 失联或新系统起不来 | 从面板还原快照，启动 Debian 并核对原 SSH 指纹。快照与停机之间产生的数据以 PC 冷备份为准。上线新系统后若已产生新写入，回滚前还需保存这部分增量。 |

## 本次验收

2026-11-15 复核时，VPS 运行 NixOS `26.11.20261111.d4f25a3`，根分区为 `/dev/vda1`。EasyTier、Hysteria、Xray、mihomo-updater-resolver、yunzhizuo-server 和 yunzhizuo-cloudflared 六项服务均为 active。resolver 和 Yunzhizuo 的本机 `/health` 均返回 HTTP 200。切换时还核对了五个镜像 ID、Xray 两个卷的内容，Cloudflare Tunnel 已注册四条连接。线上验证了网络启动依赖修正生效，修正后未另行重启业务做冷启动验收。

用户在迁移后重新设置了 `wsdlly02` 和 `root` 的密码。两者均已设置，root 的 SSH 登录仍被禁用。PC 备份和 VPS 上 `/var/lib/local-credentials/` 中的哈希对应迁移时的密码；下次从头重建并沿用当前密码时，应准备更新后的凭据。
