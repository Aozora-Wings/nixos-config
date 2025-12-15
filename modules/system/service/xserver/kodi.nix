{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
        xserver = {
            desktopManager = {
        kodi = {
          enable = true;
          package = stable.kodi-wayland.withPackages (p: with p; [
            pvr-iptvsimple
            #vfs-sftp
            steam-launcher
            inputstream-ffmpegdirect
          ]);
        };
            };
        };
    };
}