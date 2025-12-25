# Nix Configuration

This repository is home to the nix code that builds my systems.


## Why Nix?

Nix allows for easy to manage, collaborative, reproducible deployments. This means that once something is setup and configured once, it works forever. If someone else shares their configuration, anyone can make use of it.


## How to install Nix and Deploy this Flake?

**Warning:** During installation, the system will use the automatically generated hardware configuration from `/mnt/etc/nixos/hardware-configuration.nix`. However, after installation, this repository's configuration (aozorawing node) will be used. If you want to use this repository's configuration with `nixos-rebuild`, make sure to copy your `hardware-configuration.nix` file to the `hosts/aozorawings/` directory first, otherwise it will use my hardware configuration and may fail to boot.

First of all, you need to partition the hard disk, here I recommend using btrfs to format the disk.
```sh
#This is just an example, you need to fill in the actual situation with reference to the hard drive
parted -a optimal /dev/nvme0n1
mkpart primary 344GB -16GiB 
quit
mkfs.btrfs -L nixos /dev/sda2
mkswap -L swap /dev/nvme0n1p5
mount /dev/sda2 /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/service
btrfs subvolume create /mnt/game
btrfs subvolume create /mnt/var
btrfs subvolume create /mnt/Developer
umount /mnt

mount -o compress=zstd,subvol=root /dev/sda2 /mnt
mkdir /mnt/{home,nix,boot,Developer,var,game,service}
mount -o compress=zstd,subvol=home /dev/sda2 /mnt/home
mount -o compress=zstd,noatime,subvol=nix /dev/sda2 /mnt/nix
mount -o compress=zstd,noatime,subvol=service /dev/sda2 /mnt/service
mount -o compress=zstd,noatime,subvol=game /dev/sda2 /mnt/game
mount -o compress=zstd,noatime,subvol=var /dev/sda2 /mnt/var
mount -o compress=zstd,noatime,subvol=Developer /dev/sda2 /mnt/Developer
mount /dev/sda1 /mnt/boot
swapon /dev/nvme0n1p5
nixos-generate-config --root /mnt
```
hardware-configuration.nix need add btrfs compress parameters. "compress=zstd"
```sh
nano /mnt/etc/nixos/hardware-configuration.nix
```
options 
```nix
            "/" = {
                device = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
                fsType = "btrfs";
                options = [ "subvol=root"];
            };
            to
                        "/" = {
                device = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
                fsType = "btrfs";
                options = [ "subvol=root" "compress=zstd" ];
            };
```

Change the config.nix file to the parameters you want.
If you don't need a proxy, modify the install.sh file to delete https_proxy.
```sh
chmod +x install.sh
./install.sh
```
