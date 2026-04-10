{
  imports = [
    ./syncthing.nix
  ];

  home = {
    sessionPath = [
      "$HOME/.cargo/bin"
      "$HOME/.npm-global/bin"
      "$HOME/go/bin"
    ];
    sessionVariables = {
      NODE_PATH = "$HOME/.npm-global/lib/node_modules";
    };
  };
}
