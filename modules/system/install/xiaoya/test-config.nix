{ config, lib, pkgs, ... }: {
  imports = [
    ./xiaoya  # 引入xiaoya模块
  ];
  
  modules-install.xiaoya = {
    enable = true;
    
    # 小雅Alist配置
    alist = {
      enable = true;
      containerName = "xiaoya";
      configDir = "/etc/xiaoya";
      mediaDir = "/opt/media";
      hostNetwork = true;
      
      # 端口配置
      ports = {
        alistPort = 5678;
        webdavPort = 2345;
        tvboxPort = 2346;
        internalPort = 2347;
      };
    };
    
    # 小雅Emby全家桶配置
    emby = {
      enable = true;
      containerName = "emby";
      configDir = "/etc/xiaoya";
      mediaDir = "/opt/media";
      version = "4.9.0.42";
      
      # Emby端口配置
      ports = {
        embyPort = 6908;
      };
    };
    
    # 小雅助手配置
    helper = {
      enable = true;
      containerName = "xiaoyakeeper";
      mode = 3;
      enableTelegram = false;
    };
    
    # 115清理助手配置
    cleaner = {
      enable = true;
      containerName = "xiaoya-115cleaner";
      configDir = "/etc/xiaoya";
    };
  };
}