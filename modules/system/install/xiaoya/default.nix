{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules-install.xiaoya;
  
  # 创建网盘账号管理脚本包装器
  accountManagerScript = pkgs.writeShellScriptBin "xiaoya-account-manager" ''
    #!/usr/bin/env bash
    set -e
    
    CONFIG_DIR="${toString cfg.configDir}"
    
    # 创建必要的目录
    mkdir -p "$CONFIG_DIR"
    
    # 执行外部脚本
    exec ${./account-manager.sh} "$CONFIG_DIR"
  '';
  
  # 创建元数据解压脚本包装器
  metadataExtractorScript = pkgs.writeShellScriptBin "xiaoya-metadata-extractor" ''
    #!/usr/bin/env bash
    set -e
    
    CONFIG_DIR="${toString cfg.configDir}"
    MEDIA_DIR="${toString cfg.mediaDir}"
    
    # 创建必要的目录
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$MEDIA_DIR"
    
    # 执行外部脚本
    exec ${./metadata-extractor.sh} "$CONFIG_DIR" "$MEDIA_DIR"
  '';
  
  # 创建小雅 Alist 服务启动脚本
  xiaoyaAlistScript = pkgs.writeShellScriptBin "xiaoya-alist-start" ''
    #!/usr/bin/env bash
    set -e
    
    CONFIG_DIR="${toString cfg.configDir}"
    MEDIA_DIR="${toString cfg.mediaDir}"
    
    # 获取容器网络接口 IP（用于 xiaoya.host 映射）
    docker0=""
    if command -v ip > /dev/null 2>&1; then
      docker0=$(ip addr show podman0 2>/dev/null | awk '/inet / {print $2}' | cut -d '/' -f 1)
      if [ -z "$docker0" ]; then
        docker0=$(ip addr show docker0 2>/dev/null | awk '/inet / {print $2}' | cut -d '/' -f 1)
      fi
    fi
    [ -z "$docker0" ] && docker0="127.0.0.1"
    
    # 检查必要的配置文件
    if [ ! -f "$CONFIG_DIR/mytoken.txt" ] && [ ! -f "$CONFIG_DIR/myopentoken.txt" ]; then
      echo "错误：未找到阿里云盘 Token 文件"
      echo "请先运行 xiaoya-account-manager 配置账号"
      exit 1
    fi
    
    # 检查元数据是否已解压
    if [ ! -d "$MEDIA_DIR/xiaoya" ]; then
      echo "警告：未找到元数据目录"
      echo "建议先运行 xiaoya-metadata-extractor 解压元数据"
      echo "是否继续？[y/N]"
      read -r confirm
      if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        exit 1
      fi
    fi
    
    # 启动小雅 Alist 容器
    echo "启动小雅 Alist 容器..."
    
    # 清理可能存在的旧容器
    podman rm -f xiaoya-alist 2>/dev/null || true
    
    # 启动新容器
    podman run -d \
      --name xiaoya-alist \
      --restart=unless-stopped \
      -v "$CONFIG_DIR:/data" \
      -v "$CONFIG_DIR/data:/www/data" \
      -v "$MEDIA_DIR:/media" \
      -p 5678:80 \
      -p 5244:5244 \
      -p 2345:2345 \
      -e TZ=Asia/Shanghai \
      --add-host="xiaoya.host:$docker0" \
      xiaoyaliu/alist:latest
    
    echo "小雅 Alist 容器已启动"
    echo "访问地址: http://localhost:5678"
  '';
  
  # 创建小雅 Emby 服务启动脚本
  xiaoyaEmbyScript = pkgs.writeShellScriptBin "xiaoya-emby-start" ''
    #!/usr/bin/env bash
    set -e
    
    CONFIG_DIR="${toString cfg.configDir}"
    MEDIA_DIR="${toString cfg.mediaDir}"
    
    # 检查元数据是否已解压
    if [ ! -d "$MEDIA_DIR/xiaoya" ]; then
      echo "错误：未找到元数据目录"
      echo "请先运行 xiaoya-metadata-extractor 解压元数据"
      exit 1
    fi
    
    # 启动小雅 Emby 容器
    echo "启动小雅 Emby 容器..."
    
    # 清理可能存在的旧容器
    podman rm -f xiaoya-emby 2>/dev/null || true
    
    # 获取容器网络接口 IP（用于 xiaoya.host 映射）
    docker0=""
    if command -v ip > /dev/null 2>&1; then
      docker0=$(ip addr show podman0 2>/dev/null | awk '/inet / {print $2}' | cut -d '/' -f 1)
      if [ -z "$docker0" ]; then
        docker0=$(ip addr show docker0 2>/dev/null | awk '/inet / {print $2}' | cut -d '/' -f 1)
      fi
    fi
    [ -z "$docker0" ] && docker0="127.0.0.1"
    
    # 启动新容器
    podman run -d \
      --name xiaoya-emby \
      --restart=unless-stopped \
      -v "$MEDIA_DIR:/media" \
      -p 8096:8096 \
      -p 8920:8920 \
      -e TZ=Asia/Shanghai \
      -e UID=1000 \
      -e GID=1000 \
      --add-host="xiaoya.host:$docker0" \
      ddsderek/emby:latest
    
    echo "小雅 Emby 容器已启动"
    echo "访问地址: http://localhost:8096"
  '';
  
  # 创建小雅服务停止脚本
  xiaoyaStopScript = pkgs.writeShellScriptBin "xiaoya-stop" ''
    #!/usr/bin/env bash
    set -e
    
    echo "停止小雅服务..."
    
    # 停止容器
    podman stop xiaoya-alist 2>/dev/null || true
    podman stop xiaoya-emby 2>/dev/null || true
    
    echo "小雅服务已停止"
  '';
  
  # 创建小雅服务重启脚本
  xiaoyaRestartScript = pkgs.writeShellScriptBin "xiaoya-restart" ''
    #!/usr/bin/env bash
    set -e
    
    echo "重启小雅服务..."
    
    # 重启容器
    podman restart xiaoya-alist 2>/dev/null || true
    podman restart xiaoya-emby 2>/dev/null || true
    
    echo "小雅服务已重启"
  '';
  
  # 创建小雅服务状态检查脚本
  xiaoyaStatusScript = pkgs.writeShellScriptBin "xiaoya-status" ''
    #!/usr/bin/env bash
    set -e
    
    echo "小雅服务状态:"
    echo ""
    
    # 检查 Alist 容器
    if podman container inspect xiaoya-alist >/dev/null 2>&1; then
      echo "小雅 Alist: 运行中"
      echo "  访问地址: http://localhost:5678"
    else
      echo "小雅 Alist: 未运行"
    fi
    
    echo ""
    
    # 检查 Emby 容器
    if podman container inspect xiaoya-emby >/dev/null 2>&1; then
      echo "小雅 Emby: 运行中"
      echo "  访问地址: http://localhost:8096"
    else
      echo "小雅 Emby: 未运行"
    fi
    
    echo ""
    echo "配置目录: ${toString cfg.configDir}"
    echo "媒体目录: ${toString cfg.mediaDir}"
  '';
  
in {
  options.modules-install.xiaoya = {
    enable = mkEnableOption "小雅网盘服务";
    
    configDir = mkOption {
      type = types.str;
      default = "/etc/xiaoya";
      description = "小雅配置文件目录";
    };
    
    mediaDir = mkOption {
      type = types.str;
      default = "/opt/media";
      description = "小雅媒体文件目录";
    };
    
    enableAutoStart = mkOption {
      type = types.bool;
      default = false;
      description = "是否自动启动小雅服务（不推荐，需要先配置账号和解压元数据）";
    };
  };
  
  config = mkIf cfg.enable {
    # 创建必要的目录
    systemd.tmpfiles.rules = [
      "d '${cfg.configDir}' 0755 root root -"
      "d '${cfg.mediaDir}' 0755 root root -"
    ];
    
    # 安装必要的软件包
    environment.systemPackages = [
      accountManagerScript
      metadataExtractorScript
      xiaoyaAlistScript
      xiaoyaEmbyScript
      xiaoyaStopScript
      xiaoyaRestartScript
      xiaoyaStatusScript
      pkgs.podman
      pkgs.curl
      pkgs.unzip
      pkgs.zip
    ];
    
    # 如果启用自动启动，创建 systemd 服务
    systemd.services = mkIf cfg.enableAutoStart {
      xiaoya-alist = {
        description = "小雅 Alist 服务";
        after = [ "network.target" "podman.service" ];
        requires = [ "podman.service" ];
        wantedBy = [ "multi-user.target" ];
        
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${xiaoyaAlistScript}/bin/xiaoya-alist-start";
          ExecStop = "${xiaoyaStopScript}/bin/xiaoya-stop";
          ExecReload = "${xiaoyaRestartScript}/bin/xiaoya-restart";
        };
      };
      
      xiaoya-emby = {
        description = "小雅 Emby 服务";
        after = [ "network.target" "podman.service" "xiaoya-alist.service" ];
        requires = [ "podman.service" "xiaoya-alist.service" ];
        wantedBy = [ "multi-user.target" ];
        
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${xiaoyaEmbyScript}/bin/xiaoya-emby-start";
          ExecStop = "${xiaoyaStopScript}/bin/xiaoya-stop";
          ExecReload = "${xiaoyaRestartScript}/bin/xiaoya-restart";
        };
      };
    };
    
    # 创建用户组和权限
    users.groups.xiaoya = {};
    
    # 虚拟化设置
    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };
  };
}