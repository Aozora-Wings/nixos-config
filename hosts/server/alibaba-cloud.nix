{ config, pkgs, unstable, stable, install-config, MySecrets, ... }:

{
  imports = [
    ./system
    #../../modules/i3.nix
    #./hardware-configuration.nix
  ];

  swapDevices = [
    {
      device = "/swapfile";
      size = 4096; # 2GB 交换空间
    }
  ];
  # 阿里云特定的配置
  virtualisation.alibaba-cloud = {
    enable = true;
    # 阿里云需要额外的配置
  };

  # 网络配置适配阿里云
  networking = {
    useNetworkd = true;
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
  };

  # 阿里云需要的服务
  systemd.services."serial-getty@ttyS0" = {
    enable = true;
    wantedBy = [ "getty.target" ];
    serviceConfig.Restart = "always";
  };

  # 阿里云控制台支持
  boot.kernelParams = [
    "console=tty1"
    "console=ttyS0,115200n8"
  ];

  # 确保有串口控制台
  boot.loader.timeout = 10;

  # 阿里云镜像构建配置
  system.build.alibabaCloudImage = config.system.build.vhd;
}
