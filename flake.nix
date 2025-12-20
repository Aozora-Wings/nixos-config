{
  description = "NixOS configuration of Wu Tong";

  nixConfig = {
    extra-substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    # home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";
    # 添加 MineGRUB 主题
    minegrub-theme.url = "github:Lxtharia/minegrub-theme";
    minegrub-theme.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };
    connecttool-qt.url = "github:moeleak/connecttool-qt";
        noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
     # inputs.quickshell.follows = "quickshell";
    };
    agenix.url="github:ryantm/agenix";
    mySoftware = {
      url = "github:Aozora-Wings/my-nixos-app/main";
      flake = false;
    };
    
    wechat-auto-update = {
      url = "github:Aozora-Wings/wechat-auto-update";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs @ { self
    , nixpkgs
    , home-manager
    , nixos-generators
    , connecttool-qt
    , agenix
    , mySoftware
    , ...
    }:
    let
      system = "x86_64-linux";
      flakeSoftware={
        #connecttool-qt = inputs.connecttool-qt.packages.${system}.default;
      };
      lib = nixpkgs.lib;
      install-config = import ./config.nix;
      MySecrets = import ./secrets/wt;
      secrets_file = {
        azure = "${toString ./secrets/azure.age}";
      };
      hyprlandConfigPath = "${toString ./config/hyprland.conf}";
      # 创建 unstable pkgs 实例
      unstable = import inputs.nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      stable = import inputs.nixpkgs-stable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      
        parseConfigFile = file:
  let
    content = builtins.readFile file;
    lines = lib.splitString "\n" content;
    
    parseLine = line:
      let
        # 使用正则表达式匹配 "key: value" 格式，忽略前后空格
        matches = builtins.match "([^:[:space:]]+)[[:space:]]*:[[:space:]]*(.*)" line;
      in
      if matches != null then
        let
          name = lib.head matches;
          value = lib.elemAt matches 1;
        in
        # 如果值非空则返回，否则忽略
        if value != "" then { inherit name value; } else null
      else null;
    
    # 解析所有行，过滤掉空行和无效行
    parsedPairs = lib.filter (x: x != null) (map parseLine lines);
    
    # 将键值对列表转换为属性集
    toAttrs = pairs:
      lib.listToAttrs (map (pair: {
        name = pair.name;
        value = pair.value;
      }) pairs);
  in
  toAttrs parsedPairs;

      # 定义要传递的共享参数
      sharedArgs = {
        inherit install-config unstable stable MySecrets flakeSoftware hyprlandConfigPath;
        inherit inputs secrets_file mySoftware parseConfigFile;
      };

      # 为所有系统定义 formatter
      eachSystem = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # 定义创建 NixOS 配置的函数
      mkNixOSConfig = hostName: system: extraModules: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = sharedArgs // { inherit hostName; };
        modules = [
          { nix.settings.cores = 30; }
          (./hosts + "/${hostName}")
          agenix.nixosModules.default
          (if builtins.elem hostName ["aozorawings" "AozoraWings-GTX1660" "server"] then 
            inputs.minegrub-theme.nixosModules.default 
          else {})
          home-manager.nixosModules.home-manager
          {
            environment.systemPackages = [agenix.packages.${system}.default];
            home-manager.backupFileExtension = "backup-$(date +%Y%m%d%H%M%S)";
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = sharedArgs // { inherit hostName; };
            home-manager.users.${install-config.username} = {
              imports = [
                (if hostName == "wsl" then 
                # ./wsl/home/home.nix 
                  ./modules/home/home.nix
                else if hostName == "azure-vm" then
                  ./hosts/server/home
                else
                  ./modules/home/home.nix)
                  agenix.homeManagerModules.default
              ];
              _module.args.hostName = hostName;
            };
          }
        ] ++ extraModules;
      };

      # Azure VM 的特殊配置函数（需要特殊处理）
      mkAzureVMConfig = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = sharedArgs // { hostName = "azure-vm"; };
        modules = [
          { nix.settings.cores = 4; }
          # Azure 基础模块
          (import "${nixpkgs}/nixos/modules/virtualisation/azure-image.nix")
          agenix.nixosModules.default
          ./hosts/server/azure-vm.nix

          # Home Manager 配置 - 修复版本
          home-manager.nixosModules.home-manager
          ({ config, pkgs, lib, ... }: {
            home-manager.backupFileExtension = "backup-$(date +%Y%m%d%H%M%S)";
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = sharedArgs // { hostName = "azure-vm"; };

            # 关键：处理云环境下的用户映射
            home-manager.users =
              let
                # 获取 Azure 注入的实际用户名
                azureUsername =
                  if (builtins.pathExists "/etc/cloud/cloud-init.log") then
                    let
                      # 尝试从 cloud-init 日志中获取实际用户名
                      logContent = builtins.readFile "/etc/cloud/cloud-init.log";
                      usernameMatch = builtins.match ".*Setting up user ([a-zA-Z0-9_-]+).*" logContent;
                    in
                    if usernameMatch != null then builtins.head usernameMatch
                    else install-config.username 
                  else install-config.username;
              in
              {
                # 使用动态用户名或回退到配置的用户名
                ${azureUsername} = {
                  imports = [ 
                    ./hosts/server/home 
                    agenix.homeManagerModules.default
                  ];
                  _module.args.hostName = "azure-vm";
                };
              };
          })
        ];
      };

    in
    {
      formatter = eachSystem (system:
        nixpkgs.legacyPackages.${system}.nixpkgs-fmt
      );
      
      packages.${system} = {
        # 阿里云 VHD 镜像（推荐）
        alibaba-cloud-image = nixos-generators.nixosGenerate {
          inherit system;
          specialArgs = sharedArgs // { hostName = "alibaba-cloud"; };
          modules = [
            ./hosts/server/alibaba-cloud.nix

            # 加入 home-manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.useGlobalPkgs = true;
              home-manager.extraSpecialArgs = sharedArgs // { hostName = "alibaba-cloud"; };
              home-manager.users.${install-config.username} = {
                imports = [ ./hosts/server/home ];
                _module.args.hostName = "alibaba-cloud";
              };
            }
          ];
          format = "raw-efi"; # 阿里云支持 UEFI 启动的 raw 镜像
        };

        # 或者使用 VHD 格式（阿里云原生支持）
        alibaba-cloud-vhd = nixos-generators.nixosGenerate {
          inherit system;
          specialArgs = sharedArgs // { hostName = "alibaba-cloud"; };
          modules = [
            ./hosts/server/alibaba-cloud.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.useGlobalPkgs = true;
              home-manager.extraSpecialArgs = sharedArgs // { hostName = "alibaba-cloud"; };
              home-manager.users.${install-config.username} = {
                imports = [ ./hosts/server/home ];
                _module.args.hostName = "alibaba-cloud";
              };
            }
          ];
          format = "vhd"; # 阿里云可以直接上传 VHD
        };

        # 使用阿里云官方镜像格式
        alibaba-cloud-qcow2 = nixos-generators.nixosGenerate {
          inherit system;
          specialArgs = sharedArgs // { hostName = "alibaba-cloud"; };
          modules = [
            ./hosts/server/alibaba-cloud.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.useGlobalPkgs = true;
              home-manager.extraSpecialArgs = sharedArgs // { hostName = "alibaba-cloud"; };
              home-manager.users.${install-config.username} = {
                imports = [ ./hosts/server/home ];
                _module.args.hostName = "alibaba-cloud";
              };
            }
          ];
          format = "qcow2"; # 阿里云也支持 QCOW2
        };
        
        # 方法1: 使用 nixos-generators（推荐）
        azure-image = nixos-generators.nixosGenerate {
          inherit system;
          specialArgs = sharedArgs // { hostName = "azure-image"; };
          modules = [
            ./hosts/server/azure-vm.nix

            # 加入 home-manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.useGlobalPkgs = true;
              home-manager.extraSpecialArgs = sharedArgs // { hostName = "azure-image"; };
              home-manager.users.${install-config.username} = {
                imports = [ ./hosts/server/home ];
                _module.args.hostName = "azure-image";
              };
            }
          ];
          format = "azure";
        };

        # 方法2: 使用原生 Azure 模块
        azure-image-native = (import (nixpkgs + "/nixos/lib/eval-config.nix") {
          inherit system;
          specialArgs = sharedArgs // { hostName = "azure-image-native"; };
          modules = [
            (nixpkgs + "/nixos/modules/virtualisation/azure-image.nix")
            ./hosts/server/azure-vm.nix

            # 加入 home-manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.useGlobalPkgs = true;
              home-manager.extraSpecialArgs = sharedArgs // { hostName = "azure-image-native"; };
              home-manager.users.${install-config.username} = {
                imports = [ ./hosts/server/home ];
                _module.args.hostName = "azure-image-native";
              };
            }
          ];
        }).config.system.build.azureImage;

        default = self.packages.${system}.azure-image;
      };
      
      nixosConfigurations = {
        # 使用 mkNixOSConfig 函数创建配置
        wsl = mkNixOSConfig "wsl" "x86_64-linux" [];
        aozorawings = mkNixOSConfig "aozorawings" "x86_64-linux" [];
        "AozoraWings-GTX1660" = mkNixOSConfig "AozoraWings-GTX1660" "x86_64-linux" [];
        server = mkNixOSConfig "server" "x86_64-linux" [];
        
        # Azure VM 使用特殊配置函数
        nixos = mkAzureVMConfig;
      };
    };
}