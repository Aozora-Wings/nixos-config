{ config, pkgs, lib, install-config, ... }:

let
  username = install-config.username;
  
  # 检查 agenix 解密的文件是否存在
  hasDecryptedItalic = builtins.pathExists "/run/agenix/MonoLisa-Italic";
  hasDecryptedNormal = builtins.pathExists "/run/agenix/MonoLisa-Normal";
  
  # 只有在两个文件都存在时才创建字体包
  monolisaFont = if hasDecryptedItalic && hasDecryptedNormal then pkgs.stdenv.mkDerivation {
    name = "monolisa-variable";
    
    nativeBuildInputs = with pkgs; [
      coreutils
      file
    ];
    
    buildCommand = ''
      mkdir -p $out/share/fonts/truetype
      
      # 复制已解密的 Italic 字体
      echo "复制 Italic 字体..."
      cp /run/agenix/MonoLisa-Italic $out/share/fonts/truetype/MonoLisaVariableItalic.ttf
      
      # 验证 Italic 字体
      if ! ${pkgs.file}/bin/file $out/share/fonts/truetype/MonoLisaVariableItalic.ttf | \
        grep -q "TrueType font data"; then
        echo "Italic 字体文件验证失败"
        exit 1
      fi
      
      # 复制已解密的 Normal 字体
      echo "复制 Normal 字体..."
      cp /run/agenix/MonoLisa-Normal $out/share/fonts/truetype/MonoLisaVariableNormal.ttf
      
      # 验证 Normal 字体
      if ! ${pkgs.file}/bin/file $out/share/fonts/truetype/MonoLisaVariableNormal.ttf | \
        grep -q "TrueType font data"; then
        echo "Normal 字体文件验证失败"
        exit 1
      fi
      
      echo "✅ 字体复制完成"
    '';
  } else null;
  
in
{
  # 只有在字体包存在时才安装
  environment.systemPackages = lib.optional (monolisaFont != null) monolisaFont;
  fonts.packages = lib.optional (monolisaFont != null) monolisaFont;
}