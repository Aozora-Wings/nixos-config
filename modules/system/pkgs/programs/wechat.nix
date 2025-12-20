# ./wechat-new-simple.nix
{ pkgs, lib, wechat-monitor, ... }:

let
  # 获取版本信息
  version = lib.removeSuffix "\n" (builtins.readFile "${wechat-monitor}/data/last_release_version.txt");
  versionsData = builtins.fromJSON (builtins.readFile "${wechat-monitor}/data/versions.json");
  versionEntry = builtins.head (lib.filter (v: v.version == version) versionsData.versions);
  
  pname = "wechat-new";
  
  # 提取 AppImage 内容
  appimageContents = pkgs.appimageTools.extract {
    inherit pname version;
    src = let
      system = pkgs.stdenv.hostPlatform.system;
      arch = if system == "x86_64-linux" then "x86"
            else if system == "aarch64-linux" then "arm64"
            else throw "Unsupported system: ${system}";
      filename = "wechat_linux_${arch}_${version}.appimage";
    in pkgs.fetchurl {
      url = "https://github.com/Aozora-Wings/wechat-linux-monitor/releases/download/v${version}/${filename}";
      sha256 = versionEntry.files.${arch}.appimage.sha256;
    };
    
    postExtract = ''
      # 修复 libtiff 依赖（原仓库的修复）
      if [ -f "$out/opt/wechat/wechat" ]; then
        patchelf --replace-needed libtiff.so.5 libtiff.so "$out/opt/wechat/wechat"
      fi
    '';
  };
  
  # 包装为可执行文件
  wechat_new = pkgs.appimageTools.wrapAppImage {
    inherit pname version;
    
    src = appimageContents;
    
    extraInstallCommands = ''
      # 重命名二进制文件为 wechat_new
      mv $out/bin/wechat-new $out/bin/wechat_new
      
      # 复制并修改桌面文件
      mkdir -p $out/share/applications
      cp ${appimageContents}/wechat.desktop $out/share/applications/wechat_new.desktop
      substituteInPlace $out/share/applications/wechat_new.desktop \
        --replace "Name=WeChat" "Name=WeChat New" \
        --replace "Exec=AppRun" "Exec=wechat_new" \
        --replace "Icon=wechat" "Icon=wechat"
      
      # 复制图标
      mkdir -p $out/share/icons/hicolor/256x256/apps
      cp ${appimageContents}/wechat.png $out/share/icons/hicolor/256x256/apps/wechat.png
    '';
    
    meta = {
      description = "WeChat New - Tracking version with automatic updates";
      homepage = "https://weixin.qq.com/";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" "aarch64-linux" ];
      mainProgram = "wechat_new";
    };
  };
in
{
  nixpkgs.overlays = [
    (final: prev: {
      wechat_new = wechat_new;
    })
  ];
  
  environment.systemPackages = with pkgs; [
    wechat_new
  ];
}