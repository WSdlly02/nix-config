/*
  pkgs.rust.packages.stable.rustc = pkgs.rustc
  pkgs.rustPlatform.buildRustPackage = pkgs.rust.packages.stable.rustPlatform.buildRustPackage
*/
{
  pkgs,
  ...
}:
{
  imports = [
    ./code-server.nix
  ];
  environment = {
    systemPackages = with pkgs; [
      cloc # counts blank lines, comment lines, and physical lines of source code

      # C/C++
      gcc
      zig # can also compile C/C++ code

      # Rust
      cargo
      cargo-edit
      clippy
      rust-analyzer
      rustc
      rustfmt

      # Haskell
      # haskellEnv

      # Python
      python3Env

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
