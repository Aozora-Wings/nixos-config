# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, install-config, unstable, stable, inputs,hostName, ... }:

let
  # Determine run mode from environment variable
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

  # System imports
  imports = [
    ../Common-Service
    ../../modules/system
    ./service
    #../kernel_patch

    # Conditionally import hardware configuration based on run mode
  ] ++ (if run-mode == "install" then
    [ /mnt/etc/nixos/hardware-configuration.nix ]
  else
    [ ./hardware-configuration.nix ]
  );

  # Boot configuration
  boot = {
    # Use Zen kernel for better desktop performance
    #kernelPackages = pkgs.linuxKernel.kernels.linux_lqx;
    #kernelPackages = pkgs.linuxPackages_zen;

    # GRUB bootloader configuration with theme
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        extraEntries = install-config.boot.extraEntries;

        # Minegrub theme configuration
        minegrub-theme = {
          enable = true;
          # Optional theme customization:
          # splash = "NixOS - Reproducible, Declarative, Reliable";
          # background = "background_options/1.8  - [Classic Minecraft].png";
          boot-options-count = 7; # Adjust based on your boot options
        };
      };
    };

    # Kernel parameters for touchpad fixes
    kernelParams = [
      "i8042.reset"
      "i8042.nomux=1"
      "i8042.nopnp=1"
    ];

    # Additional module configuration for multitouch support
    extraModprobeConfig = ''
      options hid_multitouch report_size=8
    '';
  };

  # Network configuration
  networking = {
    hostName = hostName;

    # NetworkManager for network management
    networkmanager = {
      enable = true;
    };
  };
  # Pre-configured WiFi connections
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

  # Hardware configuration for hybrid graphics (Intel + NVIDIA)
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;

      # Graphics drivers and libraries
      extraPackages = with pkgs; [
        intel-vaapi-driver # Intel VAAPI driver
        libva-vdpau-driver # VAAPI ↔ VDPAU translation
        libvdpau-va-gl # VDPAU → VAAPI fallback
        intel-compute-runtime # Intel OpenCL runtime
        mesa # Mesa graphics library
        nvidia-vaapi-driver
        intel-media-driver
      ];

      # 32-bit graphics packages for compatibility
      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-vaapi-driver
        mesa
      ];
    };

    # NVIDIA graphics configuration
    nvidia = {
      open = true; # Use open-source kernel module
      package = config.boot.kernelPackages.nvidiaPackages.latest;
      modesetting.enable = true; # Use kernel mode setting
      powerManagement.enable = true; # Enable power management

      # Prime sync configuration for hybrid graphics
      prime = {
        sync.enable = true;
        # Bus IDs for Intel and NVIDIA GPUs
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";

        # Alternative: Offload mode configuration
        # offload = {
        #   enable = true;
        #   enableOffloadCmd = true;
        # };
      };
    };
  };

  # X11 server configuration
  services.xserver = {
    videoDrivers = [ "nvidia" ];
  };
  services.ollama = {
  enable = true;
  package = pkgs.ollama-cuda;
  #loadModels = ["deepseek-r1:8b-q8_0"];
};
nixpkgs.config.cudaSupport = true;
  # Environment variables for graphics and Wayland
  environment.sessionVariables = {
    # HDR and graphics compatibility
    # KWIN_DRM_HDR_ENABLED = "1";           # Force HDR enable
    KWIN_DRM_USE_EGL_STREAMS = "1"; # Improve NVIDIA compatibility
    # WLR_DRM_NO_ATOMIC = "1";              # Required for some NVIDIA cards
    # GBM_BACKEND = "nvidia-drm";           # Ensure GBM uses NVIDIA
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # Force NVIDIA GLX

    # Wayland and desktop environment
    # XDG_CURRENT_DESKTOP = "Hyprland";

    # Wayland support for applications
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GL_GSYNC_ALLOWED = "0";
    __GL_VRR_ALLOWED = "0";
    WLR_NO_HARDWARE_CURSORS = "1";
    LIBVA_DRIVER_NAME = "nvidia";

  };

  # Security configuration
  security.sudo.wheelNeedsPassword = false;
  #nixpkgs.config.allowBroken = true;
  # System state version - do not change without reading documentation
  system.stateVersion = "24.05";
}
