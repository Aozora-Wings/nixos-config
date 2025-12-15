{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
    displayManager = {
        dms-greeter.compositor = lib.mkIf install-config.niri.enable {
    name = "niri";
  };
    };
    };
}