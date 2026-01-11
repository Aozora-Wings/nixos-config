{ config, pkgs, lib, install-config, ... }:

let
  username = install-config.username;
  hasDecryptedSecret = builtins.pathExists "/run/agenix/MonoLisa-Italic";
  # 创建字体包，将 agenix 解密的内容作为输入
  monolisaFont = pkgs.stdenv.mkDerivation {
    name = "monolisa-variable";
    
    # 使用 derivation 来接收 agenix 解密的内容
    italicBase64 = config.age.secrets."MonoLisa-Italic".path or null;
    normalBase64 = config.age.secrets."MonoLisa-Normal".path or null;
    
    nativeBuildInputs = with pkgs; [
      coreutils
      file
    ];
    
    buildCommand = ''
      mkdir -p $out/share/fonts/truetype
      
      echo "处理 Italic 字体..."
      
      # 检查文件是否存在
      if [ ! -f "$italicBase64" ]; then
        echo "错误: Italic 字体文件不存在"
        exit 1
      fi
      
      if [ ! -f "$normalBase64" ]; then
        echo "错误: Normal 字体文件不存在"
        exit 1
      fi
      
      # 解码 base64 文件
      ${pkgs.coreutils}/bin/base64 -d "$italicBase64" > \
        $out/share/fonts/truetype/MonoLisaVariableItalic.ttf
      
      # 验证 Italic 字体
      if ! ${pkgs.file}/bin/file $out/share/fonts/truetype/MonoLisaVariableItalic.ttf | \
        grep -q "TrueType font data"; then
        echo "Italic 字体解码失败"
        exit 1
      fi
      
      echo "处理 Normal 字体..."
      ${pkgs.coreutils}/bin/base64 -d "$normalBase64" > \
        $out/share/fonts/truetype/MonoLisaVariableNormal.ttf
      
      # 验证 Normal 字体
      if ! ${pkgs.file}/bin/file $out/share/fonts/truetype/MonoLisaVariableNormal.ttf | \
        grep -q "TrueType font data"; then
        echo "Normal 字体解码失败"
        exit 1
      fi
      
      echo "✅ 字体处理完成"
    '';
  };
  
in
{
  # 确保 agenix 配置正确
  age.identityPaths = [
    "/home/${username}/.ssh/vw_wt"
  ];
  
  age.secrets = {
    "MonoLisa-Normal" = {
      file = secrets_file.MonoLisaVariableNormal;
      owner = install-config.username;
    };
    "MonoLisa-Italic" = {
      file = secrets_file.MonoLisaVariableItalic;
      owner = install-config.username;
    };
  };
  
  # 安装字体包
  environment.systemPackages = lib.mkIf hasDecryptedSecret [ monolisaFont ];
  fonts.packages =lib.mkIf hasDecryptedSecret  [ monolisaFont ];
}