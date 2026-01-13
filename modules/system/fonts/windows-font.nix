{ config, lib, pkgs, install-config, unstable, ... }:
let
  windows-font = pkgs.stdenv.mkDerivation rec {
    pname = "nix-font-windows";
    version = "1.0.8";
    src = pkgs.fetchgit {
      url = "https://wt-ives@dev.azure.com/wt-ives/windows_font/_git/windows_font";
      rev = "c956c13ad9eb9d32c6e9b649370cfd75b5644c16";
      sha256 = "sha256-JKx4eOtB+80Br6f2rq4o4qdX1+IL/5ETcxzguPrMhhM=";
      #sshKey = ./id_rsa;
    };

    installPhase = ''
      mkdir -p $out/share/fonts
      cp -a $src/*.ttf $out/share/fonts/
      cp -a $src/*.ttc $out/share/fonts/
    '';

    meta = with lib; {
      homepage = "https://wt-ives@dev.azure.com/wt-ives/windows_font";
      license = licenses.asl20;
      description = "Import windows fonts to nixos";
    };
  };
in
{
  # 启用 fontconfig
  fonts.fontconfig.enable = true;

  # 通过 fonts.packages 安装字体
  fonts.packages = with pkgs; [
    windows-font  # 你的自定义字体
  ];

}