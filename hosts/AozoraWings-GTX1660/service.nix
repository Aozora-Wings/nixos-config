
{ config, pkgs, install-config, unstable, stable, inputs, ... }:
let

  unstable = import <unstable> { config = { allowUnfree = true; }; };
  username = install-config.username;
  hyprlandConfigPath = "${toString ../config/hyprland.conf}";

in
{
  imports = [
    ./service
  ];
    services = {

    minecraft-servers = {
      # 秘境时代服务器实例
      tmeo = {
        enable = true;  # 启用此实例
        dataDir = "/var/lib/minecraft/tmeo";  # 独立的数据目录
        serverJar = ./server.jar;  # 需要手动放置 server.jar 文件
        javaPackage = pkgs.jdk17;  # 使用 JDK 17
        minMemory = 2048;  # 最小内存 2GB
        maxMemory = 32000;  # 最大内存 8GB
        serverPort = 25565;  # 默认 Minecraft 端口
        useTmux = true;  # 启用 tmux 以便后台访问
        tmuxSessionName = "minecraft-tmeo";  # 唯一的 tmux 会话名
        autoStart = true;  # 不自动启动，需要时手动启动
        backupOnStop = true;  # 停止时自动备份
        #group = "shared";
      };

      # 机械工业服务器实例
      # mechanical-industry = {
      #   enable = true;  # 启用此实例
      #   dataDir = "/server/minecraft/mechanical-industry";  # 独立的数据目录
      #   serverJar = null;  # 需要手动放置 server.jar 文件
      #   javaPackage = pkgs.jdk17;  # 使用 JDK 17
      #   minMemory = 3072;  # 最小内存 3GB
      #   maxMemory = 12288;  # 最大内存 12GB
      #   serverPort = 25566;  # 使用不同的端口避免冲突
      #   useTmux = true;  # 启用 tmux 以便后台访问
      #   tmuxSessionName = "minecraft-mechanical-industry";  # 唯一的 tmux 会话名
      #   autoStart = false;  # 不自动启动，需要时手动启动
      #   backupOnStop = true;  # 停止时自动备份
      # };
    };
  };
 }
