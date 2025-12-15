{ pkgs, ... }:

let
  # 包装 VSCode
  vscode-wrapped = pkgs.vscode.overrideAttrs (finalAttrs: previousAttrs: {
    nativeBuildInputs = (previousAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
    
    postInstall = (previousAttrs.postInstall or "") + ''
      wrapProgram $out/bin/code \
        --set ELECTRON_OZONE_PLATFORM_HINT wayland \
        --set NIXOS_OZONE_WL 1 \
        --set XDG_SESSION_TYPE wayland \
        --prefix LD_LIBRARY_PATH : ${pkgs.curl}/lib \
        --prefix LD_LIBRARY_PATH : ${pkgs.stdenv.cc.cc.lib}/lib
      
      [ -f "$out/bin/code-insiders" ] && wrapProgram $out/bin/code-insiders \
        --set ELECTRON_OZONE_PLATFORM_HINT wayland \
        --set NIXOS_OZONE_WL 1 \
        --set XDG_SESSION_TYPE wayland \
        --prefix LD_LIBRARY_PATH : ${pkgs.curl}/lib \
        --prefix LD_LIBRARY_PATH : ${pkgs.stdenv.cc.cc.lib}/lib || true
    '';
  });

  # 导入扩展配置
  extensionsConfig = import ./extensions { inherit pkgs; };
in
{
  programs.vscode = {
    enable = true;
    package = vscode-wrapped;
    extensions = extensionsConfig.enabledExtensions;
  };
}