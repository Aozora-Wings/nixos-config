# ntfsplus.nix
{ config, lib, pkgs, ... }:

let
  # 在这里选择你要使用的内核
  # 选项1: 使用 linux_lqx 内核
   targetKernel = pkgs.linuxKernel.kernels.linux_lqx;
   targetKernelPackages = pkgs.linuxKernel.packages.linux_lqx;
  
  # 选项2: 使用 linux_zen 内核
 # targetKernel = pkgs.linuxKernel.kernels.linux_zen;
 # targetKernelPackages = pkgs.linuxPackages_zen;
  
  # 选项3: 使用当前系统的内核
  # targetKernel = config.boot.kernelPackages.kernel;
  # targetKernelPackages = config.boot.kernelPackages;

  # 工具函数：获取内核模块构建参数
  kernelBuildParams = kernel: {
    kernelDev = kernel.dev;
    modDirVersion = kernel.modDirVersion;
    buildDir = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";
  };

  params = kernelBuildParams targetKernel;

  ntfsplusPackage = pkgs.stdenv.mkDerivation rec {
    pname = "ntfsplus-kernel-module";
    version = "2025.12.21.r1.0931";

    src = pkgs.fetchFromGitHub {
      owner = "Aozora-Wings";
      repo = "ntfsplus-nix";
      rev = "890cc24888991021685d986943199d6bf3e565d8";
      sha256 = "sha256-E1qMKXqmfwmAjLd5tjOSEJO2lIcEtjhbvxPav07VDrc=";
    };

    nativeBuildInputs = with pkgs; [
      targetKernel.dev
    ];

    # 设置正确的源码目录
    setSourceRoot = "sourceRoot=$(pwd)/source/out-of-tree";

    buildPhase = ''
      echo "Building NTFS+ kernel module for ${params.modDirVersion}..."
      
      # 清理之前的构建
      make clean 2>/dev/null || true
      
      # 构建模块
      make -C ${params.buildDir} \
        M=$(pwd) \
        CONFIG_NTFSPLUS_FS=m \
        modules
        
      # 运行 modpost
      echo "Running modpost..."
      make -C ${params.buildDir} \
        M=$(pwd) \
        modules_prepare
        
      # 检查构建结果
      echo "=== 构建结果 ==="
      find . -name "*.ko" -o -name "*.o" -o -name "*.mod" | sort
    '';

    installPhase = ''
      echo "=== 安装内核模块 ==="
      
      # 查找内核模块文件
      KO_FILE=$(find . -name "*.ko" | head -1)
      
      if [ -n "$KO_FILE" ]; then
        echo "Found kernel module: $KO_FILE"
        mkdir -p $out/lib/modules/${params.modDirVersion}/kernel/fs/ntfsplus
        install -D -m 0644 "$KO_FILE" \
          $out/lib/modules/${params.modDirVersion}/kernel/fs/ntfsplus/ntfsplus.ko
        echo "Successfully installed NTFS+ module"
        
      else
        echo "=== 没有找到 .ko 文件，尝试使用 modules_install ==="
        
        # 使用内核构建系统安装模块
        make -C ${params.buildDir} \
          M=$(pwd) \
          modules_install INSTALL_MOD_PATH=$out
          
        # 移动模块到正确位置
        INSTALLED_KO=$(find $out -name "*.ko" | head -1)
        if [ -n "$INSTALLED_KO" ]; then
          mkdir -p $out/lib/modules/${params.modDirVersion}/kernel/fs/ntfsplus
          cp "$INSTALLED_KO" \
            $out/lib/modules/${params.modDirVersion}/kernel/fs/ntfsplus/ntfsplus.ko
          echo "Module installed via modules_install"
        else
          echo "=== 构建失败 ==="
          exit 1
        fi
      fi
      
      echo "=== 最终安装结果 ==="
      find $out -name "*.ko" | sort
    '';

    # 模块的 meta 信息
    meta = {
      description = "NTFS+ kernel module for ${params.modDirVersion}";
      license = lib.licenses.gpl2Only;
      platforms = lib.platforms.linux;
      broken = false;
    };
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
  # 使用选定的内核包
  boot.kernelPackages = targetKernelPackages;
  
  # 安装模块
  boot.extraModulePackages = [ ntfsplusPackage ];
  boot.kernelModules = [ "ntfsplus" ];
  services.udev.packages = [ ntfsplusUdevRules ];
  boot.supportedFilesystems = [ "ntfs" "ntfsplus" ];
  
}