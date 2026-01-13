{ config, lib, pkgs, install-config, unstable, LxgwWenKai-font, ... }:
let
  # 将输入的LXGW字体打包成Nix包
  lxgwFontPkg = pkgs.stdenv.mkDerivation rec {
    pname = "lxgw-wenkai";
    version = "1.0.0";
    src = LxgwWenKai-font;
    
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      # 复制所有TTF字体文件
      find $src/fonts/TTF -name "*.ttf" -exec cp {} $out/share/fonts/truetype/ \;
    '';

    meta = with lib; {
      description = "LXGW WenKai fonts";
      homepage = "https://github.com/lxgw/LxgwWenKai";
      license = licenses.ofl;
    };
  };
in
{
  # 启用 fontconfig
  fonts.fontconfig.enable = true;

  # 通过 fonts.packages 安装字体
  fonts.packages = with pkgs; [
    lxgwFontPkg   # LXGW WenKai字体
  ];

}