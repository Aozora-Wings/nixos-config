{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    programs = {
          firefox = {
    enable = true;
    # 使用标准包即可，通常已经包含硬件加速支持
    #package = pkgs.firefox;
    
    # 可选：添加一些有用的设置
    # preferences = {
    #   # 启用硬件加速
    #   "media.ffmpeg.vaapi.enabled" = true;
    #   "media.rdd-ffmpeg.enabled" = true;
    #   "media.av1.enabled" = true;
      
    #   # Wayland 支持（如果你使用 Wayland）
    #   "widget.dmabuf.force-enabled" = true;
    #   "gfx.webrender.all" = true;
    # };
  };
    };
}