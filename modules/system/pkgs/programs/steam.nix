{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
        programs = {
        steam = {
      enable = true;
      gamescopeSession = {
        enable = true;
        env = {
          STEAM_DISABLE_GPU = "0";
        };
        args = [
          "--fullscreen"
          "--expose-wayland" # 暴露 Wayland 支持
          "--adaptive-sync" # 启用 Adaptive Sync
          # 自动使用当前显示器的原生分辨率
        ];
      };
    };
        
    };
}