#!/usr/bin/env python3
import argparse
import shlex
import socket
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

TARGETS = {
    "wsdlly02-pc": "WSdlly02-PC",
    "wsdlly02-rpi5": "WSdlly02-RPi5",
    "wsdlly02-srv-jp": "WSdlly02-SRV-JP",
}


def build(repo: Path, attribute: str, link: Path, nix_args: list[str]) -> Path:
    subprocess.run(
        [
            "nix",
            "build",
            "--builders",
            "",
            "--no-update-lock-file",
            "--out-link",
            link,
            f".#{attribute}",
            *nix_args,
        ],
        cwd=repo,
        check=True,
    )
    return link.resolve(strict=True)


def run_on_target(ssh_host: str | None, *args: str) -> None:
    command = ["ssh", ssh_host, shlex.join(args)] if ssh_host else args
    subprocess.run(command, check=True)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="在本机构建当前工作树的 NixOS 和 Home Manager，并部署到目标主机。",
        epilog="在 -- 后追加 nix build 参数，例如 -- --show-trace -L。"
    )
    parser.add_argument("target", choices=TARGETS, help="目标主机的 SSH 别名")
    parser.add_argument("--build-only", action="store_true", help="只在本机构建")
    scope = parser.add_mutually_exclusive_group()
    scope.add_argument("--nixos-only", action="store_true", help="只处理 NixOS")
    scope.add_argument("--hm-only", action="store_true", help="只处理 Home Manager")
    argv = sys.argv[1:]
    nix_args = []
    if "--" in argv:
        separator = argv.index("--")
        nix_args = argv[separator + 1 :]
        argv = argv[:separator]
    args = parser.parse_args(argv)

    nixos_config = TARGETS[args.target]
    is_local = socket.gethostname().casefold() == nixos_config.casefold()
    ssh_host = None if is_local else args.target
    home_config = "wsdlly02@" + nixos_config

    repo = Path(__file__).resolve().parent
    print(f"Building {nixos_config} from {repo}", flush=True)

    with TemporaryDirectory() as tmp:
        nixos = home = None
        if not args.hm_only:
            nixos = build(
                repo,
                f"nixosConfigurations.{nixos_config}.config.system.build.toplevel",
                Path(tmp) / "system",
                nix_args,
            )
            print(f"NixOS: {nixos}", flush=True)
        if not args.nixos_only:
            home = build(
                repo,
                f'homeConfigurations."{home_config}".activationPackage',
                Path(tmp) / "home",
                nix_args,
            )
            print(f"Home Manager: {home}", flush=True)
        if args.build_only:
            return

        if home and ssh_host:
            subprocess.run(
                [
                    "nix",
                    "copy",
                    "--substitute-on-destination",
                    "--to",
                    f"ssh://{ssh_host}",
                    home,
                ],
                check=True,
            )
        if nixos:
            switch = ["nixos-rebuild", "switch", "--store-path", str(nixos), "--sudo"]
            if ssh_host:
                switch.extend(["--target-host", ssh_host, "--use-substitutes"])
            subprocess.run(switch, check=True)
            run_on_target(ssh_host, "test", "/run/current-system", "-ef", str(nixos))
        if home:
            run_on_target(ssh_host, str(home / "activate"))


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        raise SystemExit(str(error))
