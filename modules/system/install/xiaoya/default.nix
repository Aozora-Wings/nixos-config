{ config, lib, pkgs, ... }:

let
  cfg = config.modules-install.xiaoya;
  
  # 小雅配置目录
  alistConfigDir = cfg.alist.configDir;
  
  # 小雅媒体目录
  alistMediaDir = cfg.alist.mediaDir;
  
  # Emby配置目录
  embyConfigDir = cfg.emby.configDir;
  
  # Emby媒体目录
  embyMediaDir = cfg.emby.mediaDir;
  
in
{
  options.modules-install.xiaoya = {
    enable = lib.mkEnableOption "xiaoya suite";
    
    # 小雅Alist相关配置
    alist = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "启用小雅Alist容器";
      };
      
      containerName = lib.mkOption {
        type = lib.types.str;
        default = "xiaoya";
        description = "小雅Alist容器名称";
      };
      
      configDir = lib.mkOption {
        type = lib.types.str;
        default = "/etc/xiaoya";
        description = "小雅配置目录";
      };
      
      mediaDir = lib.mkOption {
        type = lib.types.str;
        default = "/opt/media";
        description = "小雅媒体目录";
      };
      
      networkMode = lib.mkOption {
        type = lib.types.enum [ "host" "bridge" ];
        default = "host";
        description = "网络模式";
      };
      
      hostNetwork = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "是否使用主机网络";
      };
      
      ports = {
        alistPort = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 5678;
          description = "Alist服务端口";
        };
        
        webdavPort = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 2345;
          description = "WebDAV服务端口";
        };
        
        tvboxPort = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 2346;
          description = "TVBox服务端口";
        };
        
        internalPort = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 2347;
          description = "内部服务端口";
        };
      };
    };
    
    # 小雅Emby全家桶相关配置
    emby = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "启用小雅Emby全家桶";
      };
      
      containerName = lib.mkOption {
        type = lib.types.str;
        default = "emby";
        description = "Emby容器名称";
      };
      
      configDir = lib.mkOption {
        type = lib.types.str;
        default = "/etc/xiaoya";
        description = "Emby配置目录";
      };
      
      mediaDir = lib.mkOption {
        type = lib.types.str;
        default = "/opt/media";
        description = "Emby媒体目录";
      };
      
      image = lib.mkOption {
        type = lib.types.str;
        default = "emby/embyserver";
        description = "Emby镜像名称";
      };
      
      version = lib.mkOption {
        type = lib.types.str;
        default = "4.9.0.42";
        description = "Emby版本";
      };
      
      ports = {
        embyPort = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 6908;
          description = "Emby服务端口";
        };
      };
    };
    
    # 小雅助手相关配置
    helper = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "启用小雅助手";
      };
      
      containerName = lib.mkOption {
        type = lib.types.str;
        default = "xiaoyakeeper";
        description = "小雅助手容器名称";
      };
      
      mode = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 3;
        description = "助手模式 (3: 定时清理, 5: 立即清理)";
      };
      
      enableTelegram = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "启用Telegram通知";
      };
    };
    
    # 115清理助手相关配置
    cleaner = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "启用115清理助手";
      };
      
      containerName = lib.mkOption {
        type = lib.types.str;
        default = "xiaoya-115cleaner";
        description = "115清理助手容器名称";
      };
      
      configDir = lib.mkOption {
        type = lib.types.str;
        default = "/etc/xiaoya";
        description = "115清理助手配置目录";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # 使用Podman替代Docker
    virtualisation.podman = {
      enable = true;
      dockerSocket.enable = true;  # 提供Docker兼容接口
    };
    
    # 创建小雅Alist容器
    systemd.services.xiaoya-alist = lib.mkIf cfg.alist.enable {
      description = "小雅Alist服务";
      after = [ "podman.service" ];
      # 移除自动启动，改为手动启动
      # wantedBy = [ "multi-user.target" ];
      
      preStart = ''
        # 创建配置目录
        mkdir -p ${alistConfigDir}
        mkdir -p ${alistConfigDir}/data
        chmod 755 ${alistConfigDir}
        chmod 755 ${alistConfigDir}/data
        
        # 生成初始配置文件
        touch ${alistConfigDir}/mytoken.txt ${alistConfigDir}/myopentoken.txt ${alistConfigDir}/temp_transfer_folder_id.txt
        chmod 644 ${alistConfigDir}/mytoken.txt
        chmod 644 ${alistConfigDir}/myopentoken.txt
        chmod 644 ${alistConfigDir}/temp_transfer_folder_id.txt
      '';
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          networkConfig = if cfg.alist.hostNetwork then
            "--network=host"
          else
            "--publish ${toString cfg.alist.ports.alistPort}:80 " +
            "--publish ${toString cfg.alist.ports.webdavPort}:${toString cfg.alist.ports.webdavPort} " +
            "--publish ${toString cfg.alist.ports.tvboxPort}:${toString cfg.alist.ports.tvboxPort} " +
            "--publish ${toString cfg.alist.ports.internalPort}:${toString cfg.alist.ports.internalPort}";
        in
          pkgs.lib.concatStringsSep " " [
            "${pkgs.podman}/bin/podman run -d"
            "--replace"
            "--name ${cfg.alist.containerName}"
            "--privileged"
            networkConfig
            "--volume ${alistConfigDir}:/data"
            "--volume ${alistConfigDir}/data:/www/data"
            "--restart=no"  # 不自动重启，等待用户手动启动
            "xiaoyaliu/alist:latest"
          ];
        
        ExecStop = "${pkgs.podman}/bin/podman stop ${cfg.alist.containerName}";
        ExecStopPost = "${pkgs.podman}/bin/podman rm -f ${cfg.alist.containerName}";
      };
    };
    
    # 创建小雅Emby容器服务
    systemd.services.xiaoya-emby = lib.mkIf cfg.emby.enable {
      description = "小雅Emby服务";
      after = [ "podman.service" ];  # 移除对xiaoya-alist的依赖，因为需要手动启动
      # 移除自动启动，改为手动启动
      # wantedBy = [ "multi-user.target" ];
      
      preStart = ''
        # 创建必要目录
        mkdir -p ${embyMediaDir}/config
        mkdir -p ${embyMediaDir}/xiaoya
        mkdir -p ${embyConfigDir}
        
        # 如果有现成的配置文件，可以进行初始化
        # 检查Alist是否已经运行，以获取连接信息
        # 注意：这里可能需要更复杂的逻辑来确保Alist已经完全启动
      '';
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          # 根据架构选择镜像
          embyImage = if pkgs.stdenv.isx86_64 then
            "emby/embyserver"
          else if pkgs.stdenv.isAarch64 then
            "emby/embyserver_arm64v8"
          else
            "emby/embyserver";
            
          networkConfig = "--publish ${toString cfg.emby.ports.embyPort}:${toString cfg.emby.ports.embyPort}";
        in
          pkgs.lib.concatStringsSep " " [
            "${pkgs.podman}/bin/podman run -d"
            "--replace"
            "--name ${cfg.emby.containerName}"
            "--volume ${embyMediaDir}/config:/config"
            "--volume ${embyMediaDir}/xiaoya:/media"
            "--add-host xiaoya.host:127.0.0.1"  # 连接小雅alist
            networkConfig
            "--privileged"
            "--env UID=0"
            "--env GID=0"
            "--env TZ=Asia/Shanghai"
            "--restart=no"  # 不自动重启，等待用户手动启动
            "${embyImage}:${cfg.emby.version}"
          ];
        
        ExecStop = "${pkgs.podman}/bin/podman stop ${cfg.emby.containerName}";
        ExecStopPost = "${pkgs.podman}/bin/podman rm -f ${cfg.emby.containerName}";
      };
    };
    
    # 创建小雅助手服务
    systemd.services.xiaoya-helper = lib.mkIf cfg.helper.enable {
      description = "小雅助手服务";
      after = [ "podman.service" "xiaoya-alist.service" ];  # 等待Alist启动
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          tgParam = if cfg.helper.enableTelegram then "-tg" else "";
        in
          pkgs.lib.concatStringsSep " " [
            "${pkgs.podman}/bin/podman run -d"
            "--replace"
            "--name ${cfg.helper.containerName}"
            "--network=host"
            "--env TZ=Asia/Shanghai"
            "--restart=always"
            "ddsderek/xiaoyakeeper:latest"
            "${toString cfg.helper.mode} ${tgParam}"
          ];
        
        ExecStop = "${pkgs.podman}/bin/podman stop ${cfg.helper.containerName}";
        ExecStopPost = "${pkgs.podman}/bin/podman rm -f ${cfg.helper.containerName}";
      };
    };
    
    # 创建115清理助手服务
    systemd.services.xiaoya-115cleaner = lib.mkIf cfg.cleaner.enable {
      description = "115清理助手服务";
      after = [ "podman.service" "xiaoya-alist.service" ];  # 等待Alist启动
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.lib.concatStringsSep " " [
          "${pkgs.podman}/bin/podman run -d"
          "--replace"  # 替换已存在的同名容器
          "--name ${cfg.cleaner.containerName}"
          "--volume ${cfg.cleaner.configDir}:/data"
          "--network=host"
          "--env TZ=Asia/Shanghai"
          "--restart=always"
          "ddsderek/xiaoya-115cleaner:latest"
        ];
        
        ExecStop = "${pkgs.podman}/bin/podman stop ${cfg.cleaner.containerName}";
        ExecStopPost = "${pkgs.podman}/bin/podman rm -f ${cfg.cleaner.containerName}";
      };
    };
    
    # 安装账号管理脚本
    environment.systemPackages = lib.mkIf (cfg.alist.enable) [
      (pkgs.writeScriptBin "xiaoya-account-manager" ''
        #!/usr/bin/env bash
        
        # 从配置文件中获取实际的配置目录
        export CONFIG_DIR="${cfg.alist.configDir}"
        
        ${builtins.readFile ./account-script.sh}
      '')
    ];
    
    # 为小雅配置目录设置权限
    systemd.tmpfiles.rules = 
      (lib.optionals cfg.alist.enable [
        "d ${alistConfigDir} 0755 root users - -"
        "d ${alistConfigDir}/data 0755 root users - -"
        "f ${alistConfigDir}/mytoken.txt 0664 root users - -"
        "f ${alistConfigDir}/myopentoken.txt 0664 root users - -"
        "f ${alistConfigDir}/temp_transfer_folder_id.txt 0664 root users - -"
        "f ${alistConfigDir}/115_cookie.txt 0664 root users - -"
        "f ${alistConfigDir}/quark_cookie.txt 0664 root users - -"
        "f ${alistConfigDir}/uc_cookie.txt 0664 root users - -"
        "f ${alistConfigDir}/pikpak.txt 0664 root users - -"
        "f ${alistConfigDir}/ali2115.txt 0664 root users - -"
      ]) ++
      (lib.optionals cfg.emby.enable [
        "d ${embyMediaDir}/config 0755 root root - -"
        "d ${embyMediaDir}/xiaoya 0755 root root - -"
        "d ${embyConfigDir} 0755 root root - -"
      ]) ++
      # 确保父目录存在
      (lib.optionals (cfg.alist.enable || cfg.emby.enable) [
        "d /server 0755 root root - -"
        "d /server/xiaoya 0755 root root - -"
        "d /server/xiaoya/config 0755 root root - -"
        "d /server/xiaoya/media 0755 root root - -"
      ]);
  };
}