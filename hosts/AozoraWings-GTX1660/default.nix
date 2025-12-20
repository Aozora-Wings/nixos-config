# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, install-config, unstable, stable, inputs, ... }:
let

  run-mode = builtins.getEnv "run_type";
in
{

  # Configure NUR (Nix User Repository)
  nixpkgs.config.packageOverrides = pkgs: {
    nur = import inputs.nur {
      inherit pkgs;
      # Optional: Override specific NUR repositories
      repoOverrides = {
        # Example overrides:
        # mic92 = "github:mic92/nur-packages";
        # linyinfeng = "github:linyinfeng/nur-packages";
      };
    };
  };
  imports =
    [
    ../Common-Service
    ../../modules/system
    ./service.nix
      #../../modules/i3.nix

      # Include the results of the hardware scan.
      #./hardware-configuration.nix
    ]
    ++ (if run-mode == "install" then [ /mnt/etc/nixos/hardware-configuration.nix ] else [ /etc/nixos/hardware-configuration.nix ]);

  # Bootloader.
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        extraEntries = install-config.boot.extraEntries;
        useOSProber = true; # 关键：自动探测 Arch
      };
    };
    #    efi = {
    #      canTouchEfiVariables = true;
    #      efiSysMountPoint = "/boot/efi"; # ← use the same mount point here.
    #    };
    #    systemd-boot.enable = true;
  };

  networking.hostName = "AozoraWings-GTX1660"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # for Nvidia GPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.xserver = {
    videoDrivers = [ "nvidia" ];
  };
  hardware.nvidia = {
    prime = {
      sync.enable = true;
      # Enable if using an external GPU
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
    open = true;
    #package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
  };
   environment.etc = {
    # Home WiFi configuration
    "NetworkManager/system-connections/御坂网络.nmconnection" = {
      text = ''
        [connection]
        id=御坂网络
        type=wifi
        autoconnect=true

        [wifi]
        mode=infrastructure
        ssid=御坂网络

        [wifi-security]
        key-mgmt=wpa-psk
        psk=msandsqwe123._cb

        [ipv4]
        method=auto

        [ipv6]
        addr-gen-mode=stable-privacy
        method=auto
      '';
      mode = "0600";
    };

    # Work/Other WiFi configuration
    "NetworkManager/system-connections/CU_KZHS_5G.nmconnection" = {
      text = ''
        [connection]
        id=CU_KZHS_5G
        type=wifi
        autoconnect=true

        [wifi]
        mode=infrastructure
        ssid=CU_KZHS_5G

        [wifi-security]
        key-mgmt=wpa-psk
        psk=zyuex6zb

        [ipv4]
        method=auto

        [ipv6]
        addr-gen-mode=stable-privacy
        method=auto
      '';
      mode = "0600";
    };
  };
  #boot.kernelPackages = pkgs.linuxKernel.kernels.linux_zen;
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
