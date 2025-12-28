{ config, lib, pkgs, install-config, unstable,hostName, ... }:
let
  wslstatus = if hostName == "wsl" then false else true;
in {
  imports = [
    ./rbw.nix
    ./clouddrive2.nix
    ./docker-compose.nix
    ./iflow
    ./xiaoya  # 小雅套件模块
    # Minecraft 服务器模块在 hosts/AozoraWings-GTX1660/service/mc.nix 中定义
  ];
  modules-install = {
    rbw = {
      enable = true;
      email = "wt@qkzy.net";
      host = "https://vw.qkzy.net";
      syncInterval = 300;
      lockTimeout = 900;
      pinentry = "pinentry-gtk-2";
    };
    xiaoya = {
      configDir = "/service/xiaoya2/config";
      mediaDir = "/service/xiaoya2/media";
      enable = true;
    };
  };
  services = {
    clouddrive2 = lib.mkIf wslstatus {
      enable = true;
      mountPoints = [
        "/cloud/115open"
        "/cloud/ct-共享空间" # 整个路径用字符串
        "/cloud/ct-私人空间"
      ];
      extraArgs = [ "--port" "19798" ]; # 示例参数
    };
    iflow-cli = {
      enable = true;
      enableUV = true;
    };
    # Minecraft 服务器配置在 hosts/AozoraWings-GTX1660/service.nix 中定义
  };

}
