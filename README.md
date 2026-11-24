# nix-config

四台主机的 NixOS 和 Home Manager 配置，用户为 `wsdlly02`。

## 配置入口

| 主机 | NixOS | Home Manager |
| --- | --- | --- |
| WSdlly02-PC | [nixos.nix](hosts/WSdlly02-PC/nixos.nix) | [home.nix](hosts/WSdlly02-PC/home.nix) |
| WSdlly02-RPi5 | [nixos.nix](hosts/WSdlly02-RPi5/nixos.nix) | [home.nix](hosts/WSdlly02-RPi5/home.nix) |
| WSdlly02-WSL | [nixos.nix](hosts/WSdlly02-WSL/nixos.nix) | [home.nix](hosts/WSdlly02-WSL/home.nix) |
| WSdlly02-SRV-JP | [nixos.nix](hosts/WSdlly02-SRV-JP/nixos.nix) | [home.nix](hosts/WSdlly02-SRV-JP/home.nix) |

主机专属配置放在各自主机目录。要看某台机器启用了哪些共享配置，直接看入口中的 `imports`。共享的系统配置在 [profiles/nixos/](profiles/nixos/)，四台主机共用的用户配置在 [profiles/home/base.nix](profiles/home/base.nix)。

SRV-JP 从 Debian 就地切换到 NixOS 的步骤、验收和快照回退方式见[迁移记录](hosts/WSdlly02-SRV-JP/migration/migration.md)。

自定义包在 [pkgs/default.nix](pkgs/default.nix) 登记一次，[flake.nix](flake.nix) 从这里生成默认 overlay 和各平台的 `legacyPackages`。

## 构建

在仓库根目录运行。构建其他主机时，将命令中的 `WSdlly02-PC` 换成表中的主机名。

```bash
nixos-rebuild build --flake .#WSdlly02-PC
home-manager build --flake .#wsdlly02@WSdlly02-PC
nix flake check
```

在构建机上运行 [remote-deploy.py](remote-deploy.py)，参数是目标主机的 SSH 别名。脚本使用当前工作树及其中的 `flake.lock` 在本机构建。已跟踪文件的修改直接生效，新配置文件先用 `git add` 纳入跟踪即可。默认先切换 NixOS，再激活 Home Manager。目标是本机时直接激活，远端主机通过 SSH 增量传输和激活。构建机需要能构建目标架构。

`--nixos-only` 和 `--hm-only` 分别选择系统或用户配置，两者互斥。加上 `--build-only` 只构建选中的配置。

```bash
./remote-deploy.py wsdlly02-pc --nixos-only --build-only
./remote-deploy.py wsdlly02-rpi5 --hm-only
./remote-deploy.py wsdlly02-rpi5
./remote-deploy.py wsdlly02-srv-jp
```

### SRV-JP 首次从 Quadlet 切换到原生服务

Hysteria、Xray 和 Yunzhizuo 的 Cloudflare Tunnel 由 NixOS 管理。三份密文和收件人规则在 [secrets/](hosts/WSdlly02-SRV-JP/secrets/)。在该目录用 `agenix -e 文件名.age` 编辑。重装时先恢复 SRV-JP 的 SSH 主机私钥，或用管理员密钥为新主机重新加密。

首次切换时，先在 PC 运行 `./remote-deploy.py wsdlly02-srv-jp --build-only`。在 VPS 上以 `wsdlly02` 导出旧 Xray 的配置卷供回退，再停止三个旧用户服务，复制 Hysteria 的现有 ACME 账户和证书。

```bash
backup=$(mktemp -d "$HOME/xray-quadlet.XXXXXX")
volume=$(podman inspect xray -f '{{range .Mounts}}{{if eq .Destination "/usr/local/etc/xray"}}{{.Name}}{{end}}{{end}}')
podman volume export "$volume" --output "$backup/config-volume.tar"
systemctl --user stop hysteria.service xray.service yunzhizuo-cloudflared.service
sudo install -d -m 0700 /var/lib/private/hysteria
sudo test ! -e /var/lib/private/hysteria/acme && sudo cp -a --no-preserve=ownership ~/.local/share/hysteria/acme /var/lib/private/hysteria/
```

确认复制成功后，在 PC 运行 `./remote-deploy.py wsdlly02-srv-jp`。在 VPS 用 `systemctl is-active hysteria xray yunzhizuo-cloudflared` 检查系统服务，再确认 UDP/TCP 443 和 Tunnel 的实际连通性。Yunzhizuo 后端仍是用户服务，监听 `127.0.0.1:3080`。
