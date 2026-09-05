# Looking Glass development client

The `looking-glass-client-dev` overlay attribute pins build
`B7-826-236efcb1` (commit `236efcb155f952f5d7d9fcd5891a3060ad254e68`),
including its recursive submodules. The normal `looking-glass-client`
attribute remains B7, but WSdlly02-PC selects `looking-glass-client-dev` in
`hosts/WSdlly02-PC/system-modules/virtualisation.nix`. The active system client
is the development build; `/run/current-system/sw/bin/looking-glass-client`
is not a B7 rollback path.

Build without activating a NixOS generation:

```sh
nix build --no-write-lock-file \
  'path:/home/wsdlly02/Documents/nix-config#legacyPackages.x86_64-linux.nixpkgs-unstable.looking-glass-client-dev' \
  --out-link /home/wsdlly02/looking-glass-client-dev-result
```

Inspect help without connecting to the guest:

```sh
/home/wsdlly02/looking-glass-client-dev-result/bin/looking-glass-client --help
```

After the Windows side has prepared the matching Looking Glass IDD build,
close the old client normally and run:

```sh
/home/wsdlly02/looking-glass-client-dev-result/bin/looking-glass-client \
  -f /dev/kvmfr0 win:size=1920x1080
```

The installed system client can also be launched with `looking-glass-client`.
Windows uses the standalone IDD, which provides its own virtual monitor; keep
the legacy Host disabled. Update client and IDD to matching releases.

For rollback to B7, first build the explicit stable attribute into a separate
output link (do not assume the system executable is stable):

```sh
nix build --no-write-lock-file \
  'path:/home/wsdlly02/Documents/nix-config#legacyPackages.x86_64-linux.nixpkgs-unstable.looking-glass-client' \
  --out-link /home/wsdlly02/looking-glass-client-b7-result
```

Verify that attribute still resolves to B7 before using it. Through SSH and,
if needed, the rescue VGA console, remove the IDD before restoring the B7
Windows Host and its display source. Then use the explicit B7 output link's
`bin/looking-glass-client`. Do not run both Windows servers together.
Shut Windows down normally when switching VM hardware configurations.

VM baselines and rescue instructions:
[windows11.md](../hosts/WSdlly02-PC/system-modules/windows11.md).

Packaging differences from nixpkgs B7:

- Fixed source hash and explicit VERSION matching the Windows build label.
- Upstream NanoSVG submodule instead of the B7-specific unvendoring patch.
- FUSE3 for the new file clipboard implementation, libunwind/elfutils for
  backtraces, and usbredir for optional USB audio support.

Sources: [build downloads](https://looking-glass.io/downloads),
[PureSpice clipboard fix](https://github.com/gnif/PureSpice/commit/b66cdfa4d4da0a9205405ab4ab535de653db9952).

## Local validation (2026-09-05)

- Nix build and dependency checks passed. `--help` reports
  `B7-826-236efcb1` and exits with status 255 by upstream design.
- The development client is active in the NixOS system profile. The Windows
  IDD identifies itself as `B7-826-g236efcb155`, the same source commit.
- Client handshake and 2560×1440 frame reception were verified; clipboard
  transport switched to LGMP. Repeated clear/copy stress testing is not recorded
  as completed.
- Windows cold boot and unattended SSH access passed. After removing rescue
  VGA, the user confirmed Looking Glass display and sign-out behavior worked.
- Looking Glass USB Audio is present in Windows and an active Looking Glass
  playback stream is routed through host PipeWire. USB audio uses SPICE USB
  redirection, not LGMP; keep an available USB redirector and SPICE connection.
- IDD logs show hardware processing with an indirect-copy fallback after a
  D3D12 transport-memory resource test error (`0x887A0007`). This remains a
  separate performance investigation, not a clean error-free startup result.
