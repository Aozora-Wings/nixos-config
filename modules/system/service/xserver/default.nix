{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
  imports = [
    ./kodi.nix
    ./retroarch.nix
  ];
    services = {
    xserver = {
      enable = true;
      extraConfig = ''
        Section "Monitor"
          Identifier "Unknown-1"
          Option "Ignore" "true"
        EndSection
      '';
    };
    };
}