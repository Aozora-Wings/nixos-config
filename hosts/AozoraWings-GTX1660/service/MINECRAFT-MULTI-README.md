# Minecraft 多实例服务器配置

## 概述

此配置允许在同一台机器上运行多个 Minecraft 服务器实例，每个实例可以有不同的版本、配置和端口。

## 配置示例

在 `service.nix` 中配置多个 Minecraft 服务器实例：

```nix
services.minecraft-servers = {
  # 秘境时代服务器实例
  mystical-era = {
    enable = true;
    dataDir = "/server/minecraft/mystical-era";
    serverJar = null;  # 需要手动放置 server.jar 文件
    javaPackage = pkgs.jdk17;
    minMemory = 2048;  # 2GB
    maxMemory = 8192;  # 8GB
    serverPort = 25565;  # 默认端口
    useTmux = true;
    tmuxSessionName = "minecraft-mystical-era";
    autoStart = false;
    backupOnStop = true;
  };

  # 机械工业服务器实例
  mechanical-industry = {
    enable = true;
    dataDir = "/server/minecraft/mechanical-industry";
    serverJar = null;
    javaPackage = pkgs.jdk17;
    minMemory = 3072;  # 3GB
    maxMemory = 12288;  # 12GB
    serverPort = 25566;  # 不同端口避免冲突
    useTmux = true;
    tmuxSessionName = "minecraft-mechanical-industry";
    autoStart = false;
    backupOnStop = true;
  };

  # 可以添加更多实例...
  # another-instance = { ... };
};
```

## 管理命令

每个实例都有独立的管理命令：

### 启动服务器
```bash
# 秘境时代
minecraft-manage-mystical-era start
# 或使用 systemd
sudo systemctl start minecraft-server-mystical-era

# 机械工业
minecraft-manage-mechanical-industry start
sudo systemctl start minecraft-server-mechanical-industry
```

### 停止服务器
```bash
minecraft-manage-mystical-era stop
minecraft-manage-mechanical-industry stop
```

### 查看状态
```bash
minecraft-manage-mystical-era status
minecraft-manage-mechanical-industry status
```

### 连接到控制台（需要启用 tmux）
```bash
minecraft-manage-mystical-era console
minecraft-manage-mechanical-industry console
```

### 创建备份
```bash
minecraft-manage-mystical-era backup
minecraft-manage-mechanical-industry backup
```

### 查看日志
```bash
minecraft-manage-mystical-era logs
minecraft-manage-mechanical-industry logs
```

### 发送命令到服务器
```bash
minecraft-manage-mystical-era command "say Hello from console"
minecraft-manage-mechanical-industry command "time set day"
```

## 文件结构

每个实例有独立的数据目录：
```
/server/minecraft/
├── mystical-era/
│   ├── server.jar          # 服务器文件（需要手动放置）
│   ├── world/              # 世界数据
│   ├── logs/               # 日志文件
│   ├── backups/            # 自动备份
│   └── server.properties   # 服务器配置
└── mechanical-industry/
    ├── server.jar
    ├── world/
    ├── logs/
    ├── backups/
    └── server.properties
```

## 配置选项

每个实例支持以下配置选项：

| 选项 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `enable` | bool | `false` | 是否启用此实例 |
| `dataDir` | path | `/var/lib/minecraft` | 数据目录 |
| `serverJar` | path | `null` | server.jar 文件路径 |
| `javaPackage` | package | `pkgs.jdk17` | Java 版本 |
| `minMemory` | int | `1024` | 最小内存 (MB) |
| `maxMemory` | int | `4096` | 最大内存 (MB) |
| `serverPort` | int | `null` | 服务器端口 |
| `extraJavaArgs` | list | [优化参数] | 额外的 JVM 参数 |
| `extraServerArgs` | list | `[]` | 额外的服务器参数 |
| `useTmux` | bool | `true` | 是否使用 tmux |
| `tmuxSessionName` | string | `"minecraft-server"` | tmux 会话名 |
| `autoStart` | bool | `false` | 是否开机自启 |
| `backupOnStop` | bool | `false` | 停止时是否备份 |

## 向后兼容

原有的单实例配置仍然可用，但默认已禁用：
```nix
services.minecraft-server.enable = false;  # 使用多实例配置
```

## 注意事项

1. **server.jar 文件**：需要手动将对应的 server.jar 文件放置到每个实例的 `dataDir` 目录中
2. **端口冲突**：确保每个实例使用不同的端口
3. **内存分配**：根据服务器版本和预期玩家数量调整内存设置
4. **备份**：建议启用 `backupOnStop` 选项，重要数据定期备份
5. **防火墙**：确保防火墙允许对应的端口访问

## 添加新实例

要添加新的 Minecraft 服务器实例：

1. 在 `service.nix` 的 `services.minecraft-servers` 中添加新配置
2. 创建对应的数据目录：`sudo mkdir -p /server/minecraft/instance-name`
3. 将 server.jar 文件复制到数据目录
4. 重新构建配置：`sudo nixos-rebuild switch`
5. 启动新实例：`sudo systemctl start minecraft-server-instance-name`

## 故障排除

### 服务器无法启动
- 检查 `server.jar` 文件是否存在
- 检查 Java 版本是否兼容
- 查看日志：`journalctl -u minecraft-server-instance-name`

### 端口冲突
- 确保每个实例使用不同的端口
- 检查端口是否被其他程序占用：`sudo netstat -tulpn | grep :2556`

### 内存不足
- 调整 `minMemory` 和 `maxMemory` 设置
- 检查系统可用内存：`free -h`

### 权限问题
- 确保数据目录权限正确：`sudo chown -R minecraft:minecraft /server/minecraft/`