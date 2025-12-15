{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    programs = {
            clash-verge = {
      enable = true;
      tunMode = true;
      serviceMode = true;
      autoStart = true;
    };
    };
}