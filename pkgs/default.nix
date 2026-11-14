{ inputs, pkgs }:
{
  atrust-rs = pkgs.rustPlatform.callPackage ./atrust-rs.nix { inherit inputs; };
  currentNixConfig = pkgs.callPackage ./currentNixConfig.nix { inherit inputs; };
  looking-glass-client-dev = pkgs.callPackage ./looking-glass-client-dev.nix { };
  prismagent = pkgs.rustPlatform.callPackage ./prismagent.nix { inherit inputs; };
}
