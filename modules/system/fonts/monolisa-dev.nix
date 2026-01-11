{ config, pkgs, lib, install-config, secrets_file, ... }:

let
  username = install-config.username;
  
  # 先检查文件是否存在，再读取内容
  hasItalicFile = builtins.pathExists "/run/agenix/MonoLisa-Italic";
  hasNormalFile = builtins.pathExists "/run/agenix/MonoLisa-Normal";
  
  # 安全读取函数 - 只在文件存在时读取
  readFileIfExists = path:
    if builtins.pathExists path
    then builtins.readFile path
    else "";
  
  # 读取文件内容（如果存在）
  italicContent = readFileIfExists "/run/agenix/MonoLisa-Italic";
  normalContent = readFileIfExists "/run/agenix/MonoLisa-Normal";
  
  debugMsg = ''
    检查内容长度:
    Normal: ${toString (builtins.stringLength normalContent)} 字符
    Italic: ${toString (builtins.stringLength italicContent)} 字符
  '';
  
  hasContent = italicContent != "" && normalContent != "";
  
  # 创建字体包
  monolisaFont = if hasContent then pkgs.stdenvNoCC.mkDerivation {
    name = "monolisa-variable";
    
    nativeBuildInputs = with pkgs; [
      coreutils
      file
    ];
    
    # 将内容作为变量传递（使用 passAsFile 避免命令行长度限制）
    passAsFile = [ "italicContent" "normalContent" "debugMsg" ];
    italicContent = italicContent;
    normalContent = normalContent;
    debugMsg = debugMsg;
    
    buildCommand = ''
      # 输出调试信息
      cat "$debugMsgPath"
      
      mkdir -p $out/share/fonts/truetype
      
      echo "处理 Italic 字体..."
      
      # 先检查内容是否为空
      if [ ! -s "$italicContentPath" ]; then
        echo "❌ Italic 内容为空"
        exit 1
      fi
      
      if [ ! -s "$normalContentPath" ]; then
        echo "❌ Normal 内容为空"
        exit 1
      fi
      
      echo "解码 Italic 字体..."
      
      # 清理可能的空白字符（换行、空格等）后解码
      tr -d '[:space:]' < "$italicContentPath" | \
        base64 -d > "$out/share/fonts/truetype/MonoLisaVariableItalic.ttf" 2>/dev/null
      
      # 检查解码是否成功
      if [ $? -ne 0 ]; then
        echo "❌ Italic base64 解码失败，尝试直接解码..."
        # 如果清理后解码失败，尝试直接解码（可能有换行但格式正确）
        base64 -d "$italicContentPath" > "$out/share/fonts/truetype/MonoLisaVariableItalic.ttf" 2>/dev/null
      fi
      
      # 验证 Italic 字体 - 修复 grep 模式
      FONT_INFO=$(file "$out/share/fonts/truetype/MonoLisaVariableItalic.ttf")
      echo "字体文件信息: $FONT_INFO"
      
      if echo "$FONT_INFO" | grep -qi "TrueType.*font"; then
        echo "✅ Italic 字体验证成功"
      else
        echo "❌ Italic 字体验证失败"
        exit 1
      fi
      
      echo "处理 Normal 字体..."
      
      # 清理可能的空白字符（换行、空格等）后解码
      tr -d '[:space:]' < "$normalContentPath" | \
        base64 -d > "$out/share/fonts/truetype/MonoLisaVariableNormal.ttf" 2>/dev/null
      
      # 检查解码是否成功
      if [ $? -ne 0 ]; then
        echo "❌ Normal base64 解码失败，尝试直接解码..."
        # 如果清理后解码失败，尝试直接解码（可能有换行但格式正确）
        base64 -d "$normalContentPath" > "$out/share/fonts/truetype/MonoLisaVariableNormal.ttf" 2>/dev/null
      fi
      
      # 验证 Normal 字体 - 修复 grep 模式
      FONT_INFO=$(file "$out/share/fonts/truetype/MonoLisaVariableNormal.ttf")
      echo "字体文件信息: $FONT_INFO"
      
      if echo "$FONT_INFO" | grep -qi "TrueType.*font"; then
        echo "✅ Normal 字体验证成功"
      else
        echo "❌ Normal 字体验证失败"
        exit 1
      fi
      
      echo "✅ 所有字体处理完成"
      echo "字体文件详情:"
      ls -lh $out/share/fonts/truetype/*.ttf
    '';
  } else null;
  
  # 条件判断：只有当字体包创建成功时才添加相关配置
  shouldInstallFont = monolisaFont != null;
  
in
{
  # 只有 shouldInstallFont 为 true 时才安装
  environment.systemPackages = lib.mkIf shouldInstallFont [ monolisaFont ];
  fonts.packages = lib.mkIf shouldInstallFont [ monolisaFont ];
}