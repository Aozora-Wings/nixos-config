# Nix 配置

本仓库存放用于构建我系统的 Nix 代码。

## 为什么选择 Nix？

Nix 允许进行易于管理、可协作、可重复的部署。这意味着一旦某样东西被设置和配置一次，它将永久有效。如果其他人分享了他们的配置，任何人都可以使用它。

## 如何安装 Nix 并部署此 Flake？

**警告：** 在安装过程中，系统将使用自动生成的硬件配置文件 `/mnt/etc/nixos/hardware-configuration.nix`。然而，安装完成后，将使用此仓库的配置（aozorawing 节点）。如果你想在使用 `nixos-rebuild` 时使用此仓库的配置，请确保先将你的 `hardware-configuration.nix` 文件复制到 `hosts/aozorawings/` 目录中，否则它将使用我的硬件配置，并可能导致启动失败。

### 步骤 1：分区和格式化磁盘

首先，你需要对硬盘进行分区，这里我推荐使用 btrfs 格式化磁盘。

```bash
# 这只是一个示例，你需要根据硬盘的实际情况进行调整
parted -a optimal /dev/nvme0n1
mkpart primary 344GB -16GiB 
quit
mkfs.btrfs -L nixos /dev/sda2
mkswap -L swap /dev/nvme0n1p5
# 或者使用图形化磁盘编辑器进行操作，总之，需要一个主盘和一个启动盘
mount /dev/sda2 /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/service
btrfs subvolume create /mnt/game
btrfs subvolume create /mnt/var
btrfs subvolume create /mnt/Developer
umount /mnt
```

### 步骤 2：挂载子卷
```bash
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
### 步骤 3：修改硬件配置文件
`hardware-configuration.nix` 需要添加 btrfs 压缩参数 "compress=zstd"
```bash
nano /mnt/etc/nixos/hardware-configuration.nix
```
修改选项：
```nix
"/" = {
    device = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
    fsType = "btrfs";
    options = [ "subvol=root"];
};
```
改为
```nix
"/" = {
    device = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
    fsType = "btrfs";
    options = [ "subvol=root" "compress=zstd" ];
};
```
步骤 4：配置和安装

根据需要修改 config.nix 文件的参数。

如果不需要代理，请修改 install.sh 文件，删除 https_proxy。
```bash
chmod +x install.sh
./install.sh .#配置名(wsl,aozorawings,AozoraWings-GTX1660,server)
```
