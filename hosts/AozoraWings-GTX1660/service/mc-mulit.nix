{ config, lib, pkgs, ... }:

with lib;

let
  # 为每个实例生成配置
  mkInstanceConfig = instanceName: instanceCfg:
    let
      # 创建启动脚本
      startScript = pkgs.writeShellScriptBin "minecraft-start-${instanceName}" ''
        #!/usr/bin/env bash
        set -e
        
        SERVER_DIR="${toString instanceCfg.dataDir}"
        JAVA_EXEC="${toString instanceCfg.javaPackage}/bin/java"
        
        # 检查数据目录
        if [ ! -d "$SERVER_DIR" ]; then
          echo "创建 Minecraft 服务器目录: $SERVER_DIR"
          mkdir -p "$SERVER_DIR"
          chown ${toString instanceCfg.user}:shared "$SERVER_DIR"
        fi
        
        # 确保整个目录树有正确的所有权和权限
        # echo "设置服务器目录权限..."
        # chown -R ${toString instanceCfg.user}:shared "$SERVER_DIR"
        # chmod -R u+rwX,g+rX,o-rwx "$SERVER_DIR"
        # find "$SERVER_DIR" -type d -exec chmod g+s {} \;  # 设置 setgid

        cd "$SERVER_DIR"
        
        # 检查是否已有 server.jar
        if [ ! -f "server.jar" ]; then
          if [ -n "${toString instanceCfg.serverJar}" ] && [ -f "${toString instanceCfg.serverJar}" ]; then
            echo "使用指定的 server.jar: ${toString instanceCfg.serverJar}"
            cp "${toString instanceCfg.serverJar}" "server.jar"
          else
            echo "错误: 未找到 server.jar 文件"
            echo "请将 server.jar 文件放置在 $SERVER_DIR 目录中"
            echo "或通过 services.minecraft-servers.${instanceName}.serverJar 配置指定路径"
            exit 1
          fi
        fi
        
        # 构建 Java 参数
        JAVA_ARGS=(
          -Xmx${toString instanceCfg.maxMemory}M
          -Xms${toString instanceCfg.minMemory}M
        )
        
        # 添加额外的 JVM 参数
        ${lib.concatMapStrings (arg: "JAVA_ARGS+=(${lib.escapeShellArg arg})\n") instanceCfg.extraJavaArgs}
        
        # 添加服务器参数
        SERVER_ARGS=(
          -jar server.jar
          nogui
        )
        
        # 添加额外的服务器参数
        ${lib.concatMapStrings (arg: "SERVER_ARGS+=(${lib.escapeShellArg arg})\n") instanceCfg.extraServerArgs}
        
        # 添加服务器端口参数（如果指定）
        if [ -n "${toString instanceCfg.serverPort}" ] && [ "${toString instanceCfg.serverPort}" != "null" ]; then
          SERVER_ARGS+=(--port "${toString instanceCfg.serverPort}")
        fi
        
        echo "启动 Minecraft 服务器实例: ${instanceName}"
        echo "工作目录: $(pwd)"
        echo "Java 命令: $JAVA_EXEC"
        echo "Java 参数: ''${JAVA_ARGS[@]}"
        echo "服务器参数: ''${SERVER_ARGS[@]}"
        
        # 使用 tmux 运行服务器以便后台访问
        if [ "${toString instanceCfg.useTmux}" = true ]; then
          echo "使用 tmux 会话运行服务器 (会话名: ${toString instanceCfg.tmuxSessionName})"
          
          # 检查是否已有 tmux 会话
          if tmux has-session -t "${toString instanceCfg.tmuxSessionName}" 2>/dev/null; then
            echo "tmux 会话已存在: ${toString instanceCfg.tmuxSessionName}"
            echo "使用 'tmux attach -t ${toString instanceCfg.tmuxSessionName}' 连接到会话"
            exit 0
          fi
          
          # 创建新的 tmux 会话并运行服务器
          exec tmux new-session -d -s "${toString instanceCfg.tmuxSessionName}" \
            "$JAVA_EXEC" "''${JAVA_ARGS[@]}" "''${SERVER_ARGS[@]}"
          
          echo "服务器已在 tmux 会话中启动"
          echo "使用以下命令连接到服务器控制台:"
          echo "  tmux attach -t ${toString instanceCfg.tmuxSessionName}"
          echo "退出控制台: Ctrl+B, D"
        else
          # 直接运行服务器
          exec "$JAVA_EXEC" "''${JAVA_ARGS[@]}" "''${SERVER_ARGS[@]}"
        fi
      '';
      
      # 创建管理脚本
      manageScript = pkgs.writeShellScriptBin "minecraft-manage-${instanceName}" ''
        #!/usr/bin/env bash
        set -e
        
        SERVER_DIR="${toString instanceCfg.dataDir}"
        TMUX_SESSION="${toString instanceCfg.tmuxSessionName}"
        
        case "$1" in
          start)
            if [ "${toString instanceCfg.useTmux}" = true ]; then
              if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
                echo "服务器已在运行 (tmux 会话: $TMUX_SESSION)"
              else
                echo "启动 Minecraft 服务器实例: ${instanceName}..."
                systemctl start ${instanceName}
              fi
            else
              systemctl start ${instanceName}
            fi
            ;;
          
          stop)
            if [ "${toString instanceCfg.useTmux}" = true ]; then
              if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
                echo "向服务器发送停止命令..."
                tmux send-keys -t "$TMUX_SESSION" "stop" Enter
                echo "等待服务器停止..."
                sleep 10
              fi
            fi
            systemctl stop ${instanceName}
            ;;
          
          restart)
            $0 stop
            sleep 5
            $0 start
            ;;
          
          status)
            if [ "${toString instanceCfg.useTmux}" = true ]; then
              if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
                echo "服务器状态: 运行中 (tmux 会话: $TMUX_SESSION)"
                echo "使用 'tmux attach -t $TMUX_SESSION' 连接到控制台"
              else
                echo "服务器状态: 未运行 (tmux)"
              fi
            else
              systemctl status ${instanceName} --no-pager
            fi
            ;;
          
          console|attach)
            if [ "${toString instanceCfg.useTmux}" != true ]; then
              echo "错误: 未启用 tmux，无法连接到控制台"
              echo "请设置 services.minecraft-servers.${instanceName}.useTmux = true;"
              exit 1
            fi
            
            if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
              echo "连接到 Minecraft 服务器控制台 (实例: ${instanceName})..."
              echo "退出控制台: Ctrl+B, D"
              exec tmux attach -t "$TMUX_SESSION"
            else
              echo "错误: 未找到 tmux 会话: $TMUX_SESSION"
              echo "服务器可能未运行"
              exit 1
            fi
            ;;
          
          backup)
            if [ ! -d "$SERVER_DIR" ]; then
              echo "错误: 服务器目录不存在: $SERVER_DIR"
              exit 1
            fi
            
            BACKUP_DIR="$SERVER_DIR/backups"
            BACKUP_FILE="backup-$(date +%Y%m%d-%H%M%S).tar.gz"
            
            mkdir -p "$BACKUP_DIR"
            
            echo "创建服务器备份 (实例: ${instanceName})..."
            tar -czf "$BACKUP_DIR/$BACKUP_FILE" -C "$SERVER_DIR" \
              --exclude="backups" \
              --exclude="*.tar.gz" \
              --exclude="logs" .
            
            echo "备份完成: $BACKUP_DIR/$BACKUP_FILE"
            
            # 清理旧备份（保留最近7天）
            find "$BACKUP_DIR" -name "backup-*.tar.gz" -mtime +7 -delete
            ;;
          
          logs)
            if [ ! -d "$SERVER_DIR/logs" ]; then
              echo "错误: 日志目录不存在: $SERVER_DIR/logs"
              exit 1
            fi
            
            tail -f "$SERVER_DIR/logs/latest.log"
            ;;
          
          command|cmd)
            if [ "${toString instanceCfg.useTmux}" != true ]; then
              echo "错误: 未启用 tmux，无法发送命令"
              exit 1
            fi
            
            if [ -z "$2" ]; then
              echo "用法: $0 command <minecraft命令>"
              exit 1
            fi
            
            if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
              # 拼接所有参数作为命令
              CMD="''${@:2}"
              tmux send-keys -t "$TMUX_SESSION" "$CMD" Enter
              echo "已发送命令: $CMD"
            else
              echo "错误: 服务器未运行"
              exit 1
            fi
            ;;
          
          *)
            echo "Minecraft 服务器管理工具 (实例: ${instanceName})"
            echo ""
            echo "用法: $0 <命令>"
            echo ""
            echo "命令:"
            echo "  start     启动服务器"
            echo "  stop      停止服务器"
            echo "  restart   重启服务器"
            echo "  status    查看服务器状态"
            echo "  console   连接到服务器控制台 (需要启用 tmux)"
            echo "  attach    同 console"
            echo "  backup    创建服务器备份"
            echo "  logs      查看服务器日志"
            echo "  command   向服务器发送命令 (需要启用 tmux)"
            echo "  cmd       同 command"
            echo ""
            echo "配置信息:"
            echo "  数据目录: $SERVER_DIR"
            echo "  Tmux 会话: $TMUX_SESSION"
            echo "  使用 Tmux: ${toString instanceCfg.useTmux}"
            echo "  服务器端口: ${toString instanceCfg.serverPort}"
            exit 1
            ;;
        esac
      '';
      
    in {
      startScript = startScript;
      manageScript = manageScript;
    };
  
  # 获取所有实例配置
  instances = config.services.minecraft-servers;
  
  # 为每个实例生成配置
  instanceConfigs = lib.mapAttrs mkInstanceConfig instances;

in
{
  options.services.minecraft-servers = lib.mkOption {
    type = with types; attrsOf (submodule {
      options = {
        enable = mkEnableOption "Minecraft server instance";
        
        user = mkOption {
          type = types.str;
          default = "minecraft";
          description = "User to run Minecraft server as";
        };

        group = mkOption {
          type = types.str;
          default = "minecraft";
          description = "Group to run Minecraft server as";
        };

        dataDir = mkOption {
          type = types.path;
          default = "/var/lib/minecraft";
          description = "Data directory for Minecraft server";
        };

        serverJar = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to server.jar file (if not provided, expects server.jar in dataDir)";
        };

        javaPackage = mkOption {
          type = types.package;
          default = pkgs.jdk17;
          description = "Java package to use for running Minecraft server";
        };

        minMemory = mkOption {
          type = types.int;
          default = 1024;
          description = "Minimum memory in MB";
        };

        maxMemory = mkOption {
          type = types.int;
          default = 4096;
          description = "Maximum memory in MB";
        };

        serverPort = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Server port (default: 25565)";
        };

        extraJavaArgs = mkOption {
          type = types.listOf types.str;
          default = [
            "-XX:+UseG1GC"
            "-XX:+ParallelRefProcEnabled"
            "-XX:MaxGCPauseMillis=200"
            "-XX:+UnlockExperimentalVMOptions"
            "-XX:+DisableExplicitGC"
            "-XX:+AlwaysPreTouch"
            "-XX:G1NewSizePercent=30"
            "-XX:G1MaxNewSizePercent=40"
            "-XX:G1HeapRegionSize=8M"
            "-XX:G1ReservePercent=20"
            "-XX:G1HeapWastePercent=5"
            "-XX:G1MixedGCCountTarget=4"
            "-XX:InitiatingHeapOccupancyPercent=15"
            "-XX:G1MixedGCLiveThresholdPercent=90"
            "-XX:G1RSetUpdatingPauseTimePercent=5"
            "-XX:SurvivorRatio=32"
            "-XX:+PerfDisableSharedMem"
            "-XX:MaxTenuringThreshold=1"
            "-Dusing.aikars.flags=https://mcflags.emc.gs"
            "-Daikars.new.flags=true"
          ];
          description = "Extra JVM arguments";
        };

        extraServerArgs = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Extra server arguments";
        };

        useTmux = mkOption {
          type = types.bool;
          default = true;
          description = "Use tmux for server console access";
        };

        tmuxSessionName = mkOption {
          type = types.str;
          default = "minecraft-server";
          description = "Tmux session name for server console";
        };

        autoStart = mkOption {
          type = types.bool;
          default = false;
          description = "Automatically start the server on boot";
        };

        backupOnStop = mkOption {
          type = types.bool;
          default = false;
          description = "Create backup when stopping the server";
        };
      };
    });
    default = {};
    description = "Multiple Minecraft server instances configuration";
  };

  config = let
    # 过滤启用的实例
    enabledInstances = lib.filterAttrs (name: cfg: cfg.enable) instances;
    
    # 收集所有需要的软件包
    allPackages = with pkgs; [ tmux ] ++
      (lib.unique (lib.mapAttrsToList (name: cfg: cfg.javaPackage) enabledInstances)) ++
      (lib.mapAttrsToList (name: cfg: instanceConfigs.${name}.startScript) enabledInstances) ++
      (lib.mapAttrsToList (name: cfg: instanceConfigs.${name}.manageScript) enabledInstances);
    
    # 收集所有用户
    allUsers = lib.mapAttrsToList (name: cfg: cfg.user) enabledInstances;
    allGroups = lib.mapAttrsToList (name: cfg: cfg.group) enabledInstances;
    
    # 生成 systemd 服务配置
    systemdServices = lib.mapAttrs (instanceName: instanceCfg:
      let
        cfg = instanceConfigs.${instanceName};
      in {
        description = "Minecraft Server (${instanceName})";
        after = [ "network.target" ];
        wantedBy = lib.mkIf instanceCfg.autoStart [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${cfg.startScript}/bin/minecraft-start-${instanceName}";
          ExecStop = "${cfg.manageScript}/bin/minecraft-manage-${instanceName} stop";
          Restart = "on-failure";
          RestartSec = "10s";
          User = instanceCfg.user;
          Group = instanceCfg.group;
          WorkingDirectory = instanceCfg.dataDir;
          
          # 安全设置
          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectSystem = "false";
          ProtectHome = true;
          ReadWritePaths = instanceCfg.dataDir;
          
          # 资源限制
          LimitNOFILE = 65536;
          LimitNPROC = 65536;
        };

        # 环境变量 - 使用 mkForce 覆盖系统默认值
        environment = lib.mkForce {
          JAVA_HOME = "${toString instanceCfg.javaPackage}";
          PATH = "${toString instanceCfg.javaPackage}/bin:${pkgs.tmux}/bin:${pkgs.coreutils}/bin";
        };

        # 服务停止时的清理脚本
        postStop = lib.mkIf instanceCfg.backupOnStop ''
          echo "创建服务器备份..."
          ${cfg.manageScript}/bin/minecraft-manage-${instanceName} backup
        '';
      }
    ) enabledInstances;
    
    # 生成 tmpfiles 规则
    tmpfilesRules = lib.concatLists (lib.mapAttrsToList (instanceName: instanceCfg: [
      "d '${toString instanceCfg.dataDir}' 0750 ${toString instanceCfg.user} ${toString instanceCfg.group} -"
      "d '${toString instanceCfg.dataDir}/backups' 0750 ${toString instanceCfg.user} ${toString instanceCfg.group} -"
    ]) enabledInstances);
    
    # 生成用户配置
    usersConfig = lib.foldl (acc: user: acc // {
      "${user}" = {
        isSystemUser = true;
        group = user;
        home = "/var/lib/${user}";
        extraGroups = [ "shared" ];  # 加入共享组
        createHome = true;
      };
    }) {} (lib.unique allUsers);
    
    # 生成组配置
    groupsConfig = lib.foldl (acc: group: acc // {
      "${group}" = {};
    }) {} (lib.unique allGroups);
    
  in lib.mkIf (enabledInstances != {}) {
    # 安装必要的软件包
    environment.systemPackages = allPackages;

    # 用户和组配置
    users.users = usersConfig;
    users.groups = groupsConfig;

    # 创建数据目录
    systemd.tmpfiles.rules = tmpfilesRules;

    # Systemd 服务配置
    systemd.services = systemdServices;
  };
}
