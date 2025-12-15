# 小雅套件 (Xiaoya Suite) NixOS 模块

这个模块为NixOS提供了小雅套件的完整配置，包括：
- 小雅Alist容器
- 小雅Emby全家桶
- 小雅助手(xiaoyahelper)
- 115清理助手
- 账号管理工具

## 功能特性

1. **小雅Alist**：提供云盘挂载和WebDAV服务
2. **小雅Emby**：提供媒体服务器功能
3. **小雅助手**：自动清理和维护功能
4. **115清理助手**：清理115网盘转存文件
5. **账号管理工具**：便捷配置各种云盘token和cookie

## 使用方法

### 1. 在配置中引入模块

在你的 `configuration.nix` 中添加：

```nix
{ config, lib, pkgs, ... }: {
  imports = [
    # ... 其他导入
    ./modules-install/xiaoya  # 引入xiaoya模块
  ];
  
  modules-install.xiaoya = {
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
}
```

### 2. 配置账号信息

使用账号管理工具来配置各种云盘的token和cookie：

```bash
xiaoya-account-manager
```

该工具提供菜单式界面，可以方便地配置：
- 115 Cookie
- 夸克 Cookie
- 阿里云盘 Refresh Token
- 阿里云盘 Open Token
- UC Cookie
- PikPak账号
- 阿里转存115播放配置
- 阿里云盘转存目录ID

### 3. 启用服务

重新构建和部署NixOS配置：

```bash
sudo nixos-rebuild switch
```

## 容器管理

所有服务都通过systemd进行管理，但默认不会自动启动，需要手动启动：

- 启动服务：`sudo systemctl start xiaoya-alist`
- 查看服务状态：`systemctl status xiaoya-alist`
- 重启服务：`sudo systemctl restart xiaoya-alist`
- 停止服务：`sudo systemctl stop xiaoya-alist`
- 设置为开机自启：`sudo systemctl enable xiaoya-alist`（一般不推荐，因为需要先配置token）

## 端口信息

- **小雅Alist**：
  - 5678: Alist服务
  - 2345: WebDAV服务
  - 2346: TVBox服务
  - 2347: 内部服务

- **小雅Emby**：
  - 6908: Emby服务

## 注意事项

1. 确保Docker服务已启用
2. 配置目录和媒体目录需要足够的存储空间
3. 根据网络环境选择合适的网络模式（host或bridge）
4. 由于token需要后期获取，需要先使用账号管理工具进行配置后才能启动服务
5. 服务默认不会自动启动，需要手动启动

## 环境要求

- NixOS 22.11 或更高版本
- Docker 已启用
- 足够的磁盘空间和内存

## 启动流程

由于小雅套件需要先配置token才能正常运行，服务默认设置为手动启动模式。请按以下步骤操作：

1. **配置账号信息**：使用账号管理工具配置必要的token和cookie：
   ```bash
   xiaoya-account-manager
   ```

2. **启动小雅Alist服务**：
   ```bash
   sudo systemctl start xiaoya-alist
   ```

3. **验证Alist服务正常运行后**，启动Emby服务：
   ```bash
   sudo systemctl start xiaoya-emby
   ```

4. **其他服务**（助手和清理工具）也可以按需启动：
   ```bash
   sudo systemctl start xiaoya-helper
   sudo systemctl start xiaoya-115cleaner
   ```

## 维护

模块包含以下组件：
- `alist.nix`: 小雅Alist容器配置
- `emby.nix`: 小雅Emby容器配置
- `helper.nix`: 小雅助手配置
- `cleaner.nix`: 115清理助手配置
- `account.nix`: 账号管理工具
- `default.nix`: 主配置文件