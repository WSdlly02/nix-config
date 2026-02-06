/*
  pkgs.rust.packages.stable.rustc = pkgs.rustc
  pkgs.rustPlatform.buildRustPackage = pkgs.rust.packages.stable.rustPlatform.buildRustPackage
*/
{
  lib,
  pkgs,
  enableDevEnv,
  ...
}:
lib.mkIf enableDevEnv {
  environment = {
    systemPackages = with pkgs; [
      cloc # counts blank lines, comment lines, and physical lines of source code

      # C/C++
      # stdenv.cc # gcc
      zig # can also compile C/C++ code

      # Rust
      cargo
      clippy
      rustc
      rustfmt

      # Haskell
      # haskellEnv

      # Python
      python3Env
      # python3FHSEnv

      # Golang
      go

      # Node.js
      nodejs
      npm-check-updates
    ];
    sessionVariables = {
      RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
    };
  };
}
