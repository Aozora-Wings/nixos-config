{ config, pkgs, ... }:
let

  run-mode = builtins.getEnv "run_type";
in
{
  imports =
    [
      ./system
      #../../modules/i3.nix

      # Include the results of the hardware scan.
      #./hardware-configuration.nix

    ]
    ++ (if run-mode == "install" then [ /mnt/etc/nixos/hardware-configuration.nix ] else [ install-config.hardwarefiles ]);
  # Bootloader.
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        extraEntries = install-config.boot.extraEntries;
        minegrub-theme = {
          enable = true;
          # 可选配置
          # splash = "NixOS - Reproducible, Declarative, Reliable";
          # background = "background_options/1.8  - [Classic Minecraft].png";
          # boot-options-count = 4;  # 根据您的启动选项数量调整
        };
      };
    };
    #    efi = {
    #      canTouchEfiVariables = true;
    #      efiSysMountPoint = "/boot/efi"; # ← use the same mount point here.
    #    };
    #    systemd-boot.enable = true;
  };
  networking.hostName = install-config.hostname; # Define your hostname.
  networking.networkmanager = {
    enable = true;
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
