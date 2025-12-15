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
    #       xiaoya = {
    #   enable = true;  # 启用xiaoya套件
      
    #   # 小雅Alist配置
    #   alist = {
    #     enable = true;  # 启用小雅Alist
    #     containerName = "xiaoya";  # 容器名称
    #     configDir = "/etc/xiaoya";  # 配置目录
    #     mediaDir = "/opt/media";  # 媒体目录
    #     hostNetwork = true;  # 使用主机网络模式
        
    #     # 端口配置
    #     ports = {
    #       alistPort = 5678;  # Alist服务端口
    #       webdavPort = 2345;  # WebDAV服务端口
    #       tvboxPort = 2346;  # TVBox服务端口
    #       internalPort = 2347;  # 内部服务端口
    #     };
    #   };
      
    #   # 小雅Emby全家桶配置
    #   emby = {
    #     enable = true;  # 启用Emby
    #     containerName = "emby";  # 容器名称
    #     configDir = "/server/xiaoya/config";  # 配置目录
    #     mediaDir = "/server/xiaoya/media";  # 媒体目录
    #     version = "4.9.0.42";  # Emby版本
        
    #     # Emby端口配置
    #     ports = {
    #       embyPort = 6908;  # Emby服务端口
    #     };
    #   };
      
    #   # 小雅助手配置
    #   helper = {
    #     enable = true;  # 启用小雅助手
    #     containerName = "xiaoyakeeper";  # 容器名称
    #     mode = 3;  # 助手模式 (3: 定时清理, 5: 立即清理)
    #     enableTelegram = false;  # 是否启用Telegram通知
    #   };
      
    #   # 115清理助手配置
    #   cleaner = {
    #     enable = true;  # 启用115清理助手
    #     containerName = "xiaoya-115cleaner";  # 容器名称
    #     configDir = "/server/xiaoya/";  # 配置目录
    #   };
    # };
    # clouddrive2 = {
    #   enable = true;
    # };
    # docker-compose = {
    #   enable = true;
    #   containers = {
    #     "1panel" = {
    #       image = "moelin/1panel:latest";
    #       networkMode = "host";
    #       privileged = true;
    #       volumes = [
    #         "/var/run/docker.sock:/var/run/docker.sock"
    #         "/var/lib/docker:/var/lib/docker"
    #         "/opt:/opt"
    #         "/root:/root"

    #         "${config.environment.etc."docker/daemon.json".source}:/etc/docker/daemon.json:ro"
    #         "${config.environment.etc."docker/registry-mirrors.json".source}:/etc/docker/registry-mirrors.json:ro"

    #         #"${pkgs.docker}/bin/docker:/usr/bin/docker:ro"
    #       ];
    #       environment = {
    #         TZ = "Asia/Shanghai";
    #       };
    #     };
    #   };
    # };
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
  };

}
