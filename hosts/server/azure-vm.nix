{ config, pkgs, lib,install-config, ... }:
let
  run-mode = builtins.getEnv "run_type";
in
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

  networking.useDHCP = true;
  users.mutableUsers = lib.mkForce true;

  # Azure 服务
  services.waagent.enable = true;
  services.cloud-init.enable = true;
  services.cloud-init.network.enable = true;

  # 配置 cloud-init 正确处理 Azure 用户数据
#  services.cloud-init.settings = {
#    datasource_list = [ "Azure" ];
#    datasource.Azure.apply_network_config = true;
#    system_info.default_user = {
#      name = "azureuser";
#      groups = [ "wheel" "sudo" ];
#    };
#  };

  # 用户配置
  users.users.aaa = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "AzureDebug123!";
    openssh.authorizedKeys.keys = [ ];
  };

  # 性能优化
  nix.settings.max-jobs = lib.mkDefault 4;
  nix.settings.cores = lib.mkDefault 1;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "25.05";
}
