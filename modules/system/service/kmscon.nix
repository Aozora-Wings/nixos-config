{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
    kmscon = {
      enable = true;
      hwRender = true; # Hardware accelerated rendering
      fonts = [
        {
          name = "WenQuanYi Micro Hei Mono";
          package = pkgs.wqy_microhei;
        }
        {
          name = "Noto Sans CJK SC";
          package = pkgs.noto-fonts-cjk-sans;
        }
        {
          name = "DejaVu Sans Mono";
          package = pkgs.dejavu_fonts;
        }
        {
          name = "Source Code Pro";
          package = pkgs.source-code-pro;
        }
      ];
    };
    
    };
}