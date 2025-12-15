{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "vmd" "xhci_pci" "thunderbolt" "nvme" "usbhid" "uas" "sd_mod" "md_mod" "raid0" "btrfs"];
  boot.initrd.kernelModules = [ "sd_mod" "md_mod" "raid0" "btrfs" "vmd" "nvme"];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.swraid.enable = true;
  #23.05
  # boot.kernelParams = [
  # "pci=realloc"
  # "intel_iommu=on"
  # ];
  # 启用 zram swap
  zramSwap.enable = true;
  zramSwap.memoryPercent = 25;  # 16GB zram

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/ba090634-638b-4ce4-aa62-19901f1832eb";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" "noatime" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/ba090634-638b-4ce4-aa62-19901f1832eb";
      fsType = "btrfs";
      options = [ "subvol=home" "compress=zstd" "noatime" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/ba090634-638b-4ce4-aa62-19901f1832eb";
      fsType = "btrfs";
      options = [ "subvol=nix" "compress=zstd" "noatime" ];
    };

  fileSystems."/var" =
    { device = "/dev/disk/by-uuid/ba090634-638b-4ce4-aa62-19901f1832eb";
      fsType = "btrfs";
      options = [ "subvol=var" "compress=zstd" ];
    };

  fileSystems."/developer" =
    { device = "/dev/disk/by-uuid/ba090634-638b-4ce4-aa62-19901f1832eb";
      fsType = "btrfs";
      options = [ "subvol=developer" "compress=zstd" "noatime" ];
    };

  fileSystems."/service" =
    { device = "/dev/disk/by-uuid/ba090634-638b-4ce4-aa62-19901f1832eb";
      fsType = "btrfs";
      options = [ "subvol=service" "compress=zstd" "noatime" ];
    };

  fileSystems."/game" =
    { device = "/dev/disk/by-uuid/ba090634-638b-4ce4-aa62-19901f1832eb";
      fsType = "btrfs";
      options = [ "subvol=game" "compress=zstd" "noatime" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/CCD9-B5C5";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

