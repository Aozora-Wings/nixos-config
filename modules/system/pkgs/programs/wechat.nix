# ./wechat.nix
{ pkgs, lib, install-config, unstable, stable, flakeSoftware, hyprlandConfigPath, wechat-monitor, ... }:

let
  # 从 monitor 仓库读取最新版本
  version = lib.removeSuffix "\n" (builtins.readFile "${wechat-monitor}/data/last_release_version.txt");
  
  # 读取哈希数据
  versionsData = builtins.fromJSON (builtins.readFile "${wechat-monitor}/data/versions.json");
  
  # 查找对应版本的条目
  versionEntry = let
    filtered = lib.filter (v: v.version == version) versionsData.versions;
  in
    if filtered != [] then builtins.head filtered
    else throw "Version ${version} not found in versions.json";
  
  # 根据架构和包类型获取哈希
  getHash = arch: pkgType: versionEntry.files.${arch}.${pkgType}.sha256;
  
  # 创建 overlay
  wechatOverlay = final: prev: {
    wechat = prev.wechat.overrideAttrs (oldAttrs:
      # 只覆盖 Linux 版本
      if prev.stdenvNoCC.hostPlatform.isLinux then
        let
          system = prev.stdenvNoCC.hostPlatform.system;
          arch = if system == "x86_64-linux" then "x86"
                else if system == "aarch64-linux" then "arm64"
                else throw "Unsupported Linux system: ${system}";
          
          # 使用 AppImage 版本
          pkgType = "appimage";
          extension = "appimage";
          filename = "wechat_linux_${arch}_${version}.${extension}";
          
          # 检查架构是否支持
          supported = arch == "x86" || arch == "arm64";
        in
        if supported then
          {
            version = version;
            
            src = prev.fetchurl {
              url = "https://github.com/Aozora-Wings/wechat-linux-monitor/releases/download/v${version}/${filename}";
              sha256 = getHash arch pkgType;
            };
            
            # 保持其他所有属性不变
          }
        else
          oldAttrs
      else
        oldAttrs  # macOS 保持不变
    );
  };
in
{
  # 方式1: 使用 nixpkgs.overlays（推荐）
  #nixpkgs.overlays = [ wechatOverlay ];
  
  # 方式2: 如果你需要更精确的控制，可以使用这种方式
  environment.systemPackages = [
    (pkgs.extend wechatOverlay).wechat
  ];
  
  # 添加调试信息（可选）
   system.activationScripts.debugWechat = {
     text = ''
       echo "=== WeChat Debug Info ==="
       echo "Version from monitor: ${version}"
       echo "System architecture: ${pkgs.stdenvNoCC.hostPlatform.system}"
       echo "Supported arch in data: ${toString (builtins.attrNames versionEntry.files)}"
     '';
     deps = [];
   };
}