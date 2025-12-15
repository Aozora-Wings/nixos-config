{ config, pkgs, install-config, unstable, ... }: {
  hardware.nvidia-container-toolkit = {
    enable = true;
    suppressNvidiaDriverAssertion = true; # 在 WSL 中必须的！
  };
  # hardware.opengl = {
  #   enable = true;
  #   driSupport = true;
  #   driSupport32Bit = true; # 替代原来的 enable32Bit
  #   extraPackages = with pkgs; [
  #     libva
  #     nvidia-vaapi-driver # NVIDIA 的 VAAPI 桥接
  #     vaapiVdpau # VAAPI ↔ VDPAU 转换层
  #     libvdpau-va-gl # VDPAU → VAAPI 回退
  #   ];
  #   extraPackages32 = with pkgs.pkgsi686Linux; [
  #     libva
  #   ];
  # };
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
    # nvidia = {
    #   open = true; # Use open-source kernel module
    #   package = config.boot.kernelPackages.nvidiaPackages.latest;
    #   modesetting.enable = true; # Use kernel mode setting
    #   powerManagement.enable = true; # Enable power management

    #   # Prime sync configuration for hybrid graphics
    #   prime = {
    #     sync.enable = true;
    #     # Bus IDs for Intel and NVIDIA GPUs
    #     intelBusId = "PCI:0:2:0";
    #     nvidiaBusId = "PCI:1:0:0";

    #     # Alternative: Offload mode configuration
    #     # offload = {
    #     #   enable = true;
    #     #   enableOffloadCmd = true;
    #     # };
    #   };
    # };
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    NVIDIA_DRIVER_CAPABILITIES = "all";
    WSL2_ENABLE_GPU = "1";
    # 对于 Wayland 应用
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # 对于 X11 应用
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __VK_LAYER_NV_optimus = "NVIDIA_only";
  };
  environment.systemPackages = with pkgs; [
    cudaPackages.cuda_cudart
    cudaPackages.cuda_nvcc
    cudaPackages.libcublas
    # 诊断工具
    mesa-demos
    libva-utils
    nvidia-system-monitor-qt
  ];
}
