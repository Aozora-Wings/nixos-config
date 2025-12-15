{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
        xserver = {
            desktopManager = {
        retroarch = {
          enable = true;
          package = unstable.retroarch-full;
        };

            };
        };
    };
}