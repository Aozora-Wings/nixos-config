# 在 Nix 配置中直接嵌入转换逻辑
{ config, pkgs, lib, install-config, unstable, stable, flakeSoftware, hyprlandConfigPath, secrets_file, ... }:

let
  # 注意：构建时检查的路径可能不准确，建议改为运行时检查
  username = install-config.username;
  
  # 创建字体包
  monolisaFont = pkgs.stdenv.mkDerivation {
    name = "monolisa-variable";
    
    nativeBuildInputs = with pkgs; [
      agenix
      coreutils
      file
    ];
    
    # 将私钥作为构建输入（注意安全风险！）
    privateKey = "/home/${username}/.ssh/vw_wt";
    
    buildCommand = ''
      mkdir -p $out/share/fonts/truetype
      
      # 检查私钥是否存在
      if [ ! -f "${privateKey}" ]; then
        echo "私钥不存在: ${privateKey}"
        exit 1
      fi
      
      # 解密 Italic 字体
      echo "解密 Italic 字体..."
      ${pkgs.agenix}/bin/agenix -d ${secrets_file.MonoLisaVariableItalic} -i "${privateKey}" > /tmp/font_italic.b64
      
      # base64 解码
      ${pkgs.coreutils}/bin/base64 -d /tmp/font_italic.b64 > $out/share/fonts/truetype/MonoLisaVariableItalic.ttf
      
      # 验证 Italic 字体
      if ! ${pkgs.file}/bin/file $out/share/fonts/truetype/MonoLisaVariableItalic.ttf | grep -q "TrueType font data"; then
        echo "Italic 字体解密失败"
        exit 1
      fi
      
      # 解密 Normal 字体
      echo "解密 Normal 字体..."
      ${pkgs.agenix}/bin/agenix -d ${secrets_file.MonoLisaVariableNormal} -i "${privateKey}" > /tmp/font_normal.b64
      
      # base64 解码
      ${pkgs.coreutils}/bin/base64 -d /tmp/font_normal.b64 > $out/share/fonts/truetype/MonoLisaVariableNormal.ttf
      
      # 验证 Normal 字体
      if ! ${pkgs.file}/bin/file $out/share/fonts/truetype/MonoLisaVariableNormal.ttf | grep -q "TrueType font data"; then
        echo "Normal 字体解密失败"
        exit 1
      fi
      
      echo "✅ 字体解密完成"
    '';
  };
  
  # 检查私钥是否存在的条件
  hasPrivateKey = builtins.pathExists "/home/${username}/.ssh/vw_wt";
in
{
  # 只在有私钥时才安装
  environment.systemPackages = lib.mkIf hasPrivateKey [ monolisaFont ];
  
  fonts.packages = lib.mkIf hasPrivateKey [ monolisaFont ];
}