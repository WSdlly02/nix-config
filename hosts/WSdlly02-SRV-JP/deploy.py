#!/usr/bin/env python3
import argparse
import shlex
import subprocess
from pathlib import Path
from tempfile import TemporaryDirectory

TARGET = "wsdlly02-srv-jp"


def build(flake: str, attribute: str, link: Path) -> Path:
    subprocess.run(
        [
            "nix", "build", "--builders", "", "--no-update-lock-file",
            "--out-link", link, f"{flake}#{attribute}",
        ],
        check=True,
    )
    return link.resolve(strict=True)


def remote(*args: str) -> None:
    subprocess.run(["ssh", TARGET, shlex.join(args)], check=True)


def main() -> None:
    parser = argparse.ArgumentParser(description="在本机构建并部署 SRV-JP 的 NixOS 和 Home Manager。")
    parser.add_argument("--build-only", action="store_true", help="只在本机构建")
    args = parser.parse_args()

    repo = Path(__file__).resolve().parents[2]
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()
    flake = f"git+{repo.as_uri()}?rev={revision}"
    print(f"Building WSdlly02-SRV-JP from {revision}", flush=True)

    with TemporaryDirectory() as tmp:
        system = build(
            flake, "nixosConfigurations.WSdlly02-SRV-JP.config.system.build.toplevel",
            Path(tmp) / "system",
        )
        home = build(
            flake, 'homeConfigurations."wsdlly02@WSdlly02-SRV-JP".activationPackage',
            Path(tmp) / "home",
        )
        print(f"NixOS: {system}\nHome Manager: {home}", flush=True)
        if args.build_only:
            return

        subprocess.run(["nix", "copy", "--to", f"ssh://{TARGET}", home], check=True)
        subprocess.run(
            ["nixos-rebuild", "switch", "--store-path", system, "--target-host", TARGET, "--sudo"],
            check=True,
        )
        remote("test", "/run/current-system", "-ef", str(system))
        remote(str(home / "activate"))

        wants = home / "home-files/.config/systemd/user/default.target.wants"
        for unit in sorted(wants.glob("*.service")):
            print(f"Checking {unit.name}", flush=True)
            remote("systemctl", "--user", "is-active", unit.name)


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        raise SystemExit(str(error))
