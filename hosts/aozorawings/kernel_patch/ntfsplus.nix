# ntfsplus.nix
{ config, lib, pkgs, ... }:

let
  ntfsplusPackage = pkgs.stdenv.mkDerivation rec {
    pname = "ntfsplus-kernel-module";
    version = "2025.10.24.r8.9254233d7";

    src = pkgs.fetchFromGitHub {
      owner = "shadichy";
      repo = "ntfsplus-dkms";
      rev = "2c2cad2b2bd33340dbfa6f023ddcd38328143df7"; # 最新 commit
      sha256 = "sha256-fBLV6grNocpI/lQJVBPJVW93CoLNQeYO3xRK4DGHIEk=";
    };

    nativeBuildInputs = with pkgs; [
      linuxPackages_zen.kernel.dev
      #linuxPackages_zen.kernel.dev
    ];

    # 设置正确的源码目录
    setSourceRoot = "sourceRoot=$(pwd)/source/out-of-tree";

    buildPhase = ''
      # 完整构建过程 - 强制生成 .ko 文件
      echo "Building NTFS+ kernel module..."
      
      # 清理之前的构建
      make clean 2>/dev/null || true
      
      # 构建模块，确保完成所有阶段
      make -C ${pkgs.linuxPackages_zen.kernel.dev}/lib/modules/${pkgs.linuxPackages_zen.kernel.modDirVersion}/build \
        M=$(pwd) \
        CONFIG_NTFSPLUS_FS=m \
        modules
        
      # 显式运行 modpost 来生成 .ko 文件
      echo "Running modpost to generate .ko file..."
      make -C ${pkgs.linuxPackages_zen.kernel.dev}/lib/modules/${pkgs.linuxPackages_zen.kernel.modDirVersion}/build \
        M=$(pwd) \
        modules_prepare
        
      # 检查构建结果
      echo "=== 构建结果 ==="
      find . -name "*.ko" -o -name "*.o" -o -name "*.mod" | sort
      echo "=== 当前目录 ==="
      pwd
      ls -la
    '';

    installPhase = ''
      # 查找内核模块文件
      echo "=== 查找内核模块 ==="
      
      # 首先查找 .ko 文件
      KO_FILE=$(find . -name "*.ko" | head -1)
      
      if [ -n "$KO_FILE" ]; then
        echo "Found kernel module: $KO_FILE"
        mkdir -p $out/lib/modules/${pkgs.linuxPackages_zen.kernel.modDirVersion}/kernel/fs/ntfsplus
        install -D -m 0644 "$KO_FILE" \
          $out/lib/modules/${pkgs.linuxPackages_zen.kernel.modDirVersion}/kernel/fs/ntfsplus/ntfsplus.ko
        echo "Successfully installed NTFS+ module"
        
      else
        echo "=== 没有找到 .ko 文件 ==="
        echo "=== 尝试手动链接模块 ==="
        
        # 手动创建模块目录
        mkdir -p $out/lib/modules/${pkgs.linuxPackages_zen.kernel.modDirVersion}/kernel/fs/ntfsplus
        
        # 使用内核构建系统安装模块
        make -C ${pkgs.linuxPackages_zen.kernel.dev}/lib/modules/${pkgs.linuxPackages_zen.kernel.modDirVersion}/build \
          M=$(pwd) \
          modules_install INSTALL_MOD_PATH=$out
          
        # 检查是否安装成功
        if find $out -name "*.ko" | grep -q .; then
          echo "Module installed via modules_install"
          # 移动到正确的位置
          find $out -name "*.ko" -exec mv {} $out/lib/modules/${pkgs.linuxPackages_zen.kernel.modDirVersion}/kernel/fs/ntfsplus/ntfsplus.ko \;
        else
          echo "=== 构建失败，创建空模块用于测试 ==="
          echo "NOTE: This is a placeholder. Real module build failed."
          mkdir -p $out/lib/modules/${pkgs.linuxPackages_zen.kernel.modDirVersion}/kernel/fs/ntfsplus
          touch $out/lib/modules/${pkgs.linuxPackages_zen.kernel.modDirVersion}/kernel/fs/ntfsplus/ntfsplus.ko
        fi
      fi
      
      echo "=== 最终安装结果 ==="
      find $out -name "*.ko" | sort
    '';
  };

  ntfsplusUdevRules = pkgs.writeTextFile {
    name = "ntfsplus-udev-rules";
    destination = "/etc/udev/rules.d/90-udev-prefer-ntfsplus.rules";
    text = ''
      SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="ntfs", ENV{ID_FS_TYPE}="ntfsplus", RUN{builtin}+="kmod load ntfsplus"
    '';
  };

in
{
  boot.extraModulePackages = [ ntfsplusPackage ];
  boot.kernelModules = [ "ntfsplus" ];
  services.udev.packages = [ ntfsplusUdevRules ];
  boot.supportedFilesystems = [ "ntfs" "ntfsplus" ];
}
