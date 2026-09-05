# Looking Glass development client

The `looking-glass-client-dev` overlay attribute pins build
`B7-826-236efcb1` (commit `236efcb155f952f5d7d9fcd5891a3060ad254e68`),
including its recursive submodules. The normal `looking-glass-client`
attribute and the system package selection remain B7.

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

After the Windows side has prepared the matching Looking Glass Host build,
close the old client normally and run:

```sh
/home/wsdlly02/looking-glass-client-dev-result/bin/looking-glass-client \
  -f /dev/kvmfr0 win:size=1920x1080
```

This command connects to the VM; it is not part of the build check. Coordinate
with the Windows-side operator before running it. Preserve the B7 Windows
installer/configuration and an independent guest recovery path. If reverting
the Windows Host to B7, use `/run/current-system/sw/bin/looking-glass-client`
with the same arguments. Shut Windows down normally when a reboot is needed.

Packaging differences from nixpkgs B7:

- Fixed source hash and explicit VERSION matching the Windows build label.
- Upstream NanoSVG submodule instead of the B7-specific unvendoring patch.
- FUSE3 for the new file clipboard implementation, libunwind/elfutils for
  backtraces, and usbredir for optional USB audio support.

Sources: [build downloads](https://looking-glass.io/downloads),
[PureSpice clipboard fix](https://github.com/gnif/PureSpice/commit/b66cdfa4d4da0a9205405ab4ab535de653db9952).

Compilation and help checks do not validate guest display, input, or clipboard
behavior. After both sides are ready, test both copy directions and repeated
clear-then-copy operations on each side before adopting this package as the
system default.

## Local validation (2026-09-05)

- Nix build completed successfully; `--help` printed the option table and
  reported `B7-826-236efcb1` (the help invocation exits with status 255).
- `ldd` reported no missing libraries.
- The original `looking-glass-client.version` still evaluates to `B7`.
- No system activation, guest connection using the new client, or VM restart
  was performed. Guest interoperability remains to be tested.
