{ pkgs, ... }:
let
  # 获取原始 vscode 包的所有属性
  originalVscode = pkgs.vscode;
  
  vscode-wrapped = originalVscode.overrideAttrs (finalAttrs: previousAttrs: {
    # 确保包装器有所有必要的属性
    nativeBuildInputs = (previousAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
    
    # 在 postInstall 阶段添加包装
    postInstall = (previousAttrs.postInstall or "") + ''
      # 包装主程序
      wrapProgram $out/bin/code \
        --set ELECTRON_OZONE_PLATFORM_HINT wayland \
        --set NIXOS_OZONE_WL 1 \
        --set XDG_SESSION_TYPE wayland \
        --prefix LD_LIBRARY_PATH : ${pkgs.curl}/lib \
        --prefix LD_LIBRARY_PATH : ${pkgs.stdenv.cc.cc.lib}/lib
      
      # 包装 code-insiders 等变体
      [ -f "$out/bin/code-insiders" ] && wrapProgram $out/bin/code-insiders \
        --set ELECTRON_OZONE_PLATFORM_HINT wayland \
        --set NIXOS_OZONE_WL 1 \
        --set XDG_SESSION_TYPE wayland \
        --prefix LD_LIBRARY_PATH : ${pkgs.curl}/lib \
        --prefix LD_LIBRARY_PATH : ${pkgs.stdenv.cc.cc.lib}/lib || true
    '';
  });
in
{
  programs.vscode = {
    enable = true;
     package = vscode-wrapped;
     extensions = with pkgs.vscode-extensions; [
       b4dm4n.vscode-nixpkgs-fmt
       jnoortheen.nix-ide
     ];
  };
}