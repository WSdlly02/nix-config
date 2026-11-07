{
  inputs,
  buildRustPackage,
  lib,
  ...
}:
buildRustPackage {
  pname = "atrust-rs";
  version = "0.1.0";

  src = inputs.atrust-rs;

  cargoLock.lockFile = inputs.atrust-rs + "/Cargo.lock";

  meta = {
    description = "aTrust VPN companion for Mihomo";
    license = lib.licenses.agpl3Only;
    mainProgram = "atrust-client";
  };
}
