# Minecraft 服务器模块使用指南

## 概述

这是一个用于在 NixOS 上运行 Minecraft 服务器的模块，支持通过脚本指定 Java 文件传递给服务执行，并提供了方便的后台维护和监控功能。

## 功能特性

- ✅ 通过环境变量/配置文件传递 Java 文件路径
- ✅ 使用 tmux 进行后台会话管理
- ✅ 完整的服务器管理工具集
- ✅ 自动备份功能
- ✅ 资源限制和安全性配置
- ✅ 灵活的 JVM 参数配置

## 快速开始

### 1. 配置说明

在 AozoraWings-GTX1660 主机配置中，Minecraft 服务器已经默认启用但不会自动启动。这意味着：

- ✅ 服务已安装（systemd 服务文件、管理脚本等）
- ✅ 相关软件包已安装（Java、tmux 等）
- ❌ 服务器不会自动启动
- ✅ 可以通过命令手动启动/停止

配置位于 `hosts/AozoraWings-GTX1660/service.nix`：

```nix
services.minecraft-server-custom = {
  enable = true;           # 启用服务（安装相关文件和脚本）
  dataDir = "/var/lib/minecraft";
  javaPackage = pkgs.jdk17;
  minMemory = 1024;
  maxMemory = 4096;
  useTmux = true;
  autoStart = false;       # 不自动启动，需要时手动启动
};
```

### 2. 准备 server.jar 文件

将 Minecraft 服务器的 `server.jar` 文件放置在数据目录中：

```bash
# 创建数据目录（如果不存在）
sudo mkdir -p /var/lib/minecraft

# 复制 server.jar 到数据目录
sudo cp /path/to/your/server.jar /var/lib/minecraft/
```

或者通过配置指定路径：

```nix
services.minecraft-server.serverJar = /path/to/server.jar;
```

### 2. 通过命令手动管理（无需重新 build）

由于服务已安装但 `autoStart = false`，你可以随时通过命令启动/停止服务器，**无需修改配置或重新 `nixos-rebuild`**：

```bash
# 启动 Minecraft 服务器
sudo systemctl start minecraft-server

# 停止服务器
sudo systemctl stop minecraft-server

# 查看服务状态
sudo systemctl status minecraft-server

# 启用开机自启（如果需要）
sudo systemctl enable minecraft-server

# 禁用开机自启
sudo systemctl disable minecraft-server
```

### 3. 准备 server.jar 文件

将 Minecraft 服务器的 `server.jar` 文件放置在数据目录中：

```bash
# 创建数据目录（如果不存在）
sudo mkdir -p /var/lib/minecraft

# 复制 server.jar 到数据目录
sudo cp /path/to/your/server.jar /var/lib/minecraft/

# 设置正确的权限
sudo chown minecraft:minecraft /var/lib/minecraft/server.jar
```

## 管理命令

模块提供了 `minecraft-manage` 命令来管理服务器。**使用这些命令不需要重新 `nixos-rebuild`**：

### 基本管理

```bash
# 启动服务器（无需重新 build）
minecraft-manage start

# 停止服务器
minecraft-manage stop

# 重启服务器
minecraft-manage restart

# 查看状态
minecraft-manage status
```

### 控制台访问

```bash
# 连接到服务器控制台（需要启用 tmux）
minecraft-manage console
# 或
minecraft-manage attach

# 退出控制台：按 Ctrl+B，然后按 D
```

### 服务器操作

```bash
# 向服务器发送命令
minecraft-manage command "say Hello from NixOS!"
# 或
minecraft-manage cmd "time set day"

# 查看实时日志
minecraft-manage logs

# 创建备份
minecraft-manage backup
```

## 高级配置

### 完整配置示例

```nix
services.minecraft-server-custom = {
  enable = true;
  
  # 基本配置
  user = "minecraft";
  group = "minecraft";
  dataDir = "/var/lib/minecraft";
  serverJar = /path/to/server.jar;
  
  # Java 配置
  javaPackage = pkgs.jdk17;  # 使用 JDK 17
  minMemory = 2048;  # 2GB 最小内存
  maxMemory = 8192;  # 8GB 最大内存
  
  # JVM 参数（优化版）
  extraJavaArgs = [
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
  
  # 服务器参数
  extraServerArgs = [ ];
  
  # 会话管理
  useTmux = true;
  tmuxSessionName = "minecraft-server";
  
  # 自动管理
  autoStart = false;      # 开机自启
  backupOnStop = true;    # 停止时自动备份
};
```

### 通过环境变量传递 Java 文件

模块支持通过多种方式指定 Java 文件：

1. **放置在数据目录**：将 `server.jar` 直接放在 `dataDir` 中
2. **通过配置指定**：使用 `serverJar` 选项
3. **运行时替换**：启动前替换数据目录中的 `server.jar`

### 自定义启动脚本

如果需要更复杂的启动逻辑，可以创建自定义脚本：

```bash
#!/usr/bin/env bash
# custom-minecraft-start.sh

# 设置环境变量
export MINECRAFT_SERVER_JAR="/path/to/custom/server.jar"

# 调用模块的启动脚本
exec minecraft-start
```

然后在 systemd 服务中替换 `ExecStart`：

```nix
systemd.services.minecraft-server.serviceConfig.ExecStart = "/path/to/custom-minecraft-start.sh";
```

## 故障排除

### 常见问题

1. **服务器无法启动**
   - 检查 `server.jar` 文件是否存在
   - 查看日志：`journalctl -u minecraft-server`
   - 确保有足够的磁盘空间和内存

2. **无法连接到控制台**
   - 确保 `useTmux = true;`
   - 检查 tmux 是否安装：`which tmux`
   - 服务器可能未运行：`minecraft-manage status`

3. **性能问题**
   - 调整 `minMemory` 和 `maxMemory` 参数
   - 优化 `extraJavaArgs` 中的 JVM 参数
   - 考虑使用更快的存储（SSD）

### 日志查看

```bash
# Systemd 日志
journalctl -u minecraft-server -f

# 服务器日志文件
tail -f /var/lib/minecraft/logs/latest.log

# 通过管理工具
minecraft-manage logs
```

## 备份与恢复

### 自动备份

启用停止时自动备份：

```nix
services.minecraft-server.backupOnStop = true;
```

备份文件保存在：`{dataDir}/backups/`

### 手动备份

```bash
# 创建备份
minecraft-manage backup

# 查看备份文件
ls -la /var/lib/minecraft/backups/

# 恢复备份
tar -xzf /var/lib/minecraft/backups/backup-20231228-143022.tar.gz -C /var/lib/minecraft/
```

## 安全建议

1. **使用专用用户**：模块默认使用 `minecraft` 用户运行
2. **限制权限**：数据目录权限为 0750
3. **网络隔离**：考虑使用防火墙限制访问
4. **定期更新**：及时更新 server.jar 到最新版本
5. **启用备份**：重要服务器务必启用自动备份

## 相关资源

- [Minecraft 服务器官方下载](https://www.minecraft.net/zh-hans/download/server)
- [Aikar's JVM Flags](https://aikar.co/2018/07/02/tuning-the-jvm-g1gc-garbage-collector-flags-for-minecraft/)
- [NixOS 手册](https://nixos.org/manual/nixos/stable/)

## 许可证

此模块遵循与 NixOS 相同的许可证。