{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    imports = [
        ./aria2.nix
        ./webdav.nix
        ./power-profiles-daemon.nix
        ./kmscon.nix
        ./code-server.nix
        ./sunshine.nix
        ./openssh.nix
    # PC/SC smart card support
        ./pcscd.nix
        ./desktopManager
        ./displayManager
        ./xserver
        ./mpd.nix
        ./dbus.nix
        ./geoclue2.nix
        ./pipewire.nix
        ./udev.nix
        ./hardware.nix
        ./avahi.nix
        ./print.nix
    ];

    #plasma 6 enable orca
    services.orca.enable = false;
}