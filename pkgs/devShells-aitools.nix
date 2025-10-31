{
  mkShell,
  python3Env,
}:
mkShell {
  buildInputs = [
    (python3Env.override {
      extraPackages =
        f: with f; [
          markitdown
          openai-whisper
        ];
    })
  ];
  shellHook = ''
    fish
  '';
}
