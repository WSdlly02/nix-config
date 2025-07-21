{
  mkShell,
  nixfmt,
}:
mkShell {
  buildInputs = [
    nixfmt
  ];
  shellHook = ''
    fish
  '';
}
