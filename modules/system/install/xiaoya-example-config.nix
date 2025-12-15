# 示例配置文件，展示如何使用xiaoya模块
{ config, lib, pkgs, install-config, unstable, ... }: {
  imports = [
    ./rbw.nix
    ./clouddrive2.nix
    ./docker-compose.nix
    ./iflow
    ./xiaoya  # 引入xiaoya模块
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
    
    # 小雅模块配置示例
    xiaoya = {
      enable = true;  # 启用xiaoya套件
      
      # 小雅Alist配置
      alist = {
        enable = true;  # 启用小雅Alist
        containerName = "xiaoya";  # 容器名称
        configDir = "/etc/xiaoya";  # 配置目录
        mediaDir = "/opt/media";  # 媒体目录
        hostNetwork = true;  # 使用主机网络模式
        
        # 端口配置
        ports = {
          alistPort = 5678;  # Alist服务端口
          webdavPort = 2345;  # WebDAV服务端口
          tvboxPort = 2346;  # TVBox服务端口
          internalPort = 2347;  # 内部服务端口
        };
      };
      
      # 小雅Emby全家桶配置
      emby = {
        enable = true;  # 启用Emby
        containerName = "emby";  # 容器名称
        configDir = "/etc/xiaoya";  # 配置目录
        mediaDir = "/opt/media";  # 媒体目录
        version = "4.9.0.42";  # Emby版本
        
        # Emby端口配置
        ports = {
          embyPort = 6908;  # Emby服务端口
        };
      };
      
      # 小雅助手配置
      helper = {
        enable = true;  # 启用小雅助手
        containerName = "xiaoyakeeper";  # 容器名称
        mode = 3;  # 助手模式 (3: 定时清理, 5: 立即清理)
        enableTelegram = false;  # 是否启用Telegram通知
      };
      
      # 115清理助手配置
      cleaner = {
        enable = true;  # 启用115清理助手
        containerName = "xiaoya-115cleaner";  # 容器名称
        configDir = "/etc/xiaoya";  # 配置目录
      };
    };
  };
  
  services = {
    clouddrive2 = {
      enable = true;
      mountPoints = [
        "/cloud/115open"
        "/cloud/ct-共享空间"
        "/cloud/ct-私人空间"
      ];
      extraArgs = [ "--port" "19798" ];
    };
    iflow-cli = {
      enable = true;
      enableUV = true;
    };
  };
}