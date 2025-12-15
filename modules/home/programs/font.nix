{ config, lib, pkgs, install-config, unstable, ... }:
let
  environment.variables.NIX_SSHOPTS = "-i ./id_rsa";
  myfont = pkgs.stdenv.mkDerivation rec {
    #
    pname = "nix-font-myfont";
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
  home.packages = with pkgs; [
    noto-fonts
    myfont
  ];
  home.file.".config/fontconfig/conf.d/10-myfont.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <dir>${myfont}/share/fonts</dir>
    </fontconfig>
  '';

  # home.activation.appendMyFont = lib.hm.dag.entryAfter ["writeBoundary"] ''
  #   if [ -f "$HOME/.config/fontconfig/conf.d/10-myfont.conf" ]; then
  #     if ! grep -q '<dir>${myfont}/share/fonts</dir>' "$HOME/.config/fontconfig/conf.d/10-myfont.conf"; then
  #       echo '<dir>${myfont}/share/fonts</dir>' >> "$HOME/.config/fontconfig/conf.d/10-myfont.conf"
  #     fi
  #   else
  #     mkdir -p "$HOME/.config/fontconfig/conf.d"
  #     cat > "$HOME/.config/fontconfig/conf.d/10-myfont.conf" <<EOF
  # <?xml version="1.0"?>
  # <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
  # <fontconfig>
  #   <dir>${myfont}/share/fonts</dir>
  # </fontconfig>
  # EOF
  #   fi
  #   cat "$HOME/.config/fontconfig/conf.d/10-myfont.conf"
  # '';
}
