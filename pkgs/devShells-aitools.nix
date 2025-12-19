{
  ffmpeg,
  mkShell,
  python3Env,
}:
mkShell {
  buildInputs = [
    ffmpeg
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
