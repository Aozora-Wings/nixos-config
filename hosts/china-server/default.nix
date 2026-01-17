{ config, pkgs,install-config,lib,hostName, ... }:
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
      };
    };
  };
  networking.hostName = hostName; # Define your hostname.
  networking.networkmanager.enable = true;
    users.users.demo = {                            # ← 改成你的用户名
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "12345678";                 # 登录后立即改密码！
  };

  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "24.05"; # Did you read the comment?
}
