# rbw.nix
{ config, lib, pkgs, install-config, ... }:

let
  cfg = config.modules-install.rbw;
  username = install-config.username;
in
{
  options.modules-install.rbw = {
    enable = lib.mkEnableOption "Enable RBW password manager";

    email = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Bitwarden email address";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "https://vault.bitwarden.com";
      description = "Bitwarden server host";
    };

    syncInterval = lib.mkOption {
      type = lib.types.int;
      default = 300;
      description = "Sync interval in seconds";
    };

    lockTimeout = lib.mkOption {
      type = lib.types.int;
      default = 900;
      description = "Lock timeout in seconds";
    };

    pinentry = lib.mkOption {
      type = lib.types.str;
      default = "pinentry-gtk-2";
      description = "Pinentry program to use";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rbw
      rofi-rbw-wayland
      pinentry-gtk2
    ];

    home-manager.users.${username} = {
      home.file.".config/rbw/config.json".text = ''
        {
          "email": "${cfg.email}",
          "base_url": "${cfg.host}",
          "lock_timeout": ${toString cfg.lockTimeout},
          "pinentry": "${cfg.pinentry}",
          "sync_interval": ${toString cfg.syncInterval}
        }
      '';

      home.file.".gnupg/gpg-agent.conf".text = ''
        pinentry-program ${pkgs.pinentry-gtk2}/bin/pinentry-gtk-2
        default-cache-ttl ${toString cfg.lockTimeout}
        max-cache-ttl ${toString (cfg.lockTimeout * 2)}
      '';
    };
  };
}
