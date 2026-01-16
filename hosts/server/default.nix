{ config, pkgs,install-config,lib, ... }:
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
        # minegrub-theme = {
        #   enable = true;
        #   # 可选配置
        #   # splash = "NixOS - Reproducible, Declarative, Reliable";
        #   # background = "background_options/1.8  - [Classic Minecraft].png";
        #   # boot-options-count = 4;  # 根据您的启动选项数量调整
        # };
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
    connections = {
    "eth0" = {
      # 或者你的网卡名，如 "enp3s0"
      name = "eth0";
      uuid = "19548d39-43f6-4a43-b86c-0e7995dd2512"; # 生成一个唯一 UUID
      connection = {
        type = "802-3-ethernet";
        interface-name = "eth0";
        autoconnect = true;
        autoconnect-priority = 0;
      };
      ipv4 = {
        method = "manual";
        address = "192.168.1.100/24";
        gateway = "192.168.1.1";
        dns = "192.168.1.1;8.8.8.8;8.8.4.4";
        dns-search = "";
        # 或者使用数组格式
        # addresses = [ { address = "192.168.1.100"; prefix = 24; } ];
        # gateway = "192.168.1.1";
        # dns = [ "192.168.1.1" "8.8.8.8" ];
      };
      ipv6 = {
        method = "ignore"; # 或 "manual" 配置 IPv6
      };
    };
  };
  };
  system.stateVersion = "24.05"; # Did you read the comment?
}
