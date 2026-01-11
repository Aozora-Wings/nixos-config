{ config, pkgs, lib, install-config, secrets_file, ... }:

let
  username = install-config.username;
  privateKeyPath = "/home/${username}/.ssh/vw_wt";
  
  # 检查私钥是否存在
  hasPrivateKey = builtins.pathExists privateKeyPath;
  
  # 创建字体包
  monolisaFont = pkgs.stdenv.mkDerivation {
    name = "monolisa-variable";
    
    nativeBuildInputs = with pkgs; [
      age        # 使用 age 而不是 agenix
      coreutils
      file
    ];
    
    # 将私钥作为构建输入
    src = if hasPrivateKey then privateKeyPath else null;
    
    # 只有在有私钥时才构建
    phases = if hasPrivateKey then [ "buildPhase" ] else [];
    
    buildPhase = ''
      mkdir -p $out/share/fonts/truetype
      
      if [ ! -f "$src" ]; then
        echo "跳过字体安装: 私钥不存在"
        exit 0
      fi
      
      # 解密 Italic 字体
      echo "解密 Italic 字体..."
      ${pkgs.age}/bin/age -d \
        -i "$src" \
        -o /tmp/font_italic.b64 \
        ${secrets_file.MonoLisaVariableItalic}
      
      # base64 解码
      ${pkgs.coreutils}/bin/base64 -d /tmp/font_italic.b64 > \
        $out/share/fonts/truetype/MonoLisaVariableItalic.ttf
      
      # 验证 Italic 字体
      if ! ${pkgs.file}/bin/file $out/share/fonts/truetype/MonoLisaVariableItalic.ttf | \
        grep -q "TrueType font data"; then
        echo "Italic 字体解密失败"
        exit 1
      fi
      
      # 解密 Normal 字体
      echo "解密 Normal 字体..."
      ${pkgs.age}/bin/age -d \
        -i "$src" \
        -o /tmp/font_normal.b64 \
        ${secrets_file.MonoLisaVariableNormal}
      
      # base64 解码
      ${pkgs.coreutils}/bin/base64 -d /tmp/font_normal.b64 > \
        $out/share/fonts/truetype/MonoLisaVariableNormal.ttf
      
      # 验证 Normal 字体
      if ! ${pkgs.file}/bin/file $out/share/fonts/truetype/MonoLisaVariableNormal.ttf | \
        grep -q "TrueType font data"; then
        echo "Normal 字体解密失败"
        exit 1
      fi
      
      echo "✅ 字体解密完成"
    '';
    
    # 如果私钥不存在，创建空占位
    installPhase = if !hasPrivateKey then ''
      mkdir -p $out/share/fonts/truetype
      touch $out/share/fonts/truetype/MonoLisaVariableItalic.ttf
      touch $out/share/fonts/truetype/MonoLisaVariableNormal.ttf
    '' else null;
  };
  
in
{
  environment.systemPackages = [ monolisaFont ];
  fonts.packages = [ monolisaFont ];
}