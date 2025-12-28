
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
    # Minecraft 服务器配置（默认启用但不会自动启动）
    minecraft-server = {
      enable = true;  # 启用服务（安装相关文件和脚本）
      dataDir = "/var/lib/minecraft";  # 数据目录
      serverJar = null;  # 需要手动放置 server.jar 文件
      javaPackage = pkgs.jdk17;  # 使用 JDK 17
      minMemory = 1024;  # 最小内存 1GB
      maxMemory = 4096;  # 最大内存 4GB
      useTmux = true;  # 启用 tmux 以便后台访问
      tmuxSessionName = "minecraft-server";
      autoStart = false;  # 不自动启动，需要时手动启动
      backupOnStop = false;  # 停止时不自动备份
    };
  };
 }
