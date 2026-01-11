# home-manager configuration
{ config, pkgs, lib, monolisaItalicPath, monolisaNormalPath, ... }:

let
  # 检查路径是否提供
  hasMonolisaPaths = monolisaItalicPath != null && monolisaNormalPath != null;
  
  # 解密和安装脚本
  setupFontsScript = pkgs.writeShellScript "setup-monolisa-fonts" ''
    #!/usr/bin/env bash
    
    ITALIC_PATH="${monolisaItalicPath}"
    NORMAL_PATH="${monolisaNormalPath}"
    
    # 检查文件是否存在
    if [ ! -f "$ITALIC_PATH" ]; then
      echo "错误: Italic 字体文件不存在: $ITALIC_PATH"
      echo "请确保 agenix 服务已运行: systemctl start agenix-MonoLisa-Italic.service"
      exit 1
    fi
    
    if [ ! -f "$NORMAL_PATH" ]; then
      echo "错误: Normal 字体文件不存在: $NORMAL_PATH"
      echo "请确保 agenix 服务已运行: systemctl start agenix-MonoLisa-Normal.service"
      exit 1
    fi
    
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    
    echo "安装 MonoLisa 字体..."
    
    # 处理 Italic
    echo "处理 Italic 字体..."
    if file "$ITALIC_PATH" | grep -q "ASCII text"; then
      base64 -d "$ITALIC_PATH" > "$FONT_DIR/MonoLisaVariableItalic.ttf"
      echo "  ✓ base64 解码完成"
    else
      cp "$ITALIC_PATH" "$FONT_DIR/MonoLisaVariableItalic.ttf"
      echo "  ✓ 复制完成"
    fi
    
    # 处理 Normal
    echo "处理 Normal 字体..."
    if file "$NORMAL_PATH" | grep -q "ASCII text"; then
      base64 -d "$NORMAL_PATH" > "$FONT_DIR/MonoLisaVariableNormal.ttf"
      echo "  ✓ base64 解码完成"
    else
      cp "$NORMAL_PATH" "$FONT_DIR/MonoLisaVariableNormal.ttf"
      echo "  ✓ 复制完成"
    fi
    
    # 验证
    echo "验证字体文件..."
    VALID_COUNT=0
    for font in "$FONT_DIR"/MonoLisaVariable*.ttf; do
      if [ -f "$font" ] && file "$font" | grep -q "TrueType font data"; then
        echo "  ✓ $(basename "$font") 验证通过"
        VALID_COUNT=$((VALID_COUNT + 1))
      else
        echo "  ✗ $(basename "$font") 验证失败"
        rm -f "$font"
      fi
    done
    
    if [ $VALID_COUNT -eq 2 ]; then
      # 更新字体缓存
      echo "更新字体缓存..."
      fc-cache -f
      echo "✅ MonoLisa 字体安装完成！"
      echo "位置: $FONT_DIR"
    else
      echo "❌ 字体安装失败"
      exit 1
    fi
  '';
  
in lib.mkIf hasMonolisaPaths {
  home.activation = {
    installMonolisaFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # 只在第一次安装或更新时运行
      if [ ! -f "$HOME/.local/share/fonts/MonoLisaVariableItalic.ttf" ] || \
         [ ! -f "$HOME/.local/share/fonts/MonoLisaVariableNormal.ttf" ]; then
        ${setupFontsScript}
      fi
    '';
  };
  
  home.packages = [
    (pkgs.writeShellScriptBin "install-monolisa" ''
      ${setupFontsScript}
    '')
  ];
}