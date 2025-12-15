  # iflow-cli/module.nix
  { config, lib, pkgs, ... }:

  let
    cfg = config.services.iflow-cli;
    
    # 自定义的 iFlow CLI 包
iflow-cli-pkg = pkgs.writeShellScriptBin "iflow" ''
  export PATH="${pkgs.nodejs_22}/bin:$PATH"
  ${pkgs.nodejs_22}/bin/npx --yes @iflow-ai/iflow-cli "$@"
'';

    # NVM 环境设置
    nvm-setup-script = pkgs.writeShellScriptBin "nvm-setup" ''
      export NVM_DIR="$HOME/.nvm"
      if [ -s "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh"
      fi
    '';

  in
  {
    options.services.iflow-cli = {
      enable = lib.mkEnableOption "iFlow CLI service";
      
      package = lib.mkOption {
        type = lib.types.package;
        default = iflow-cli-pkg;
        defaultText = "iflow-cli-pkg";
        description = "iFlow CLI package to use";
      };
      
      nodeVersion = lib.mkOption {
        type = lib.types.str;
        default = "22";
        description = "Node.js version to use with NVM";
      };
      
      enableNVM = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable NVM for Node.js version management";
      };
      
      enableUV = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to install UV package manager";
      };
      
      autoSetup = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to automatically setup npm configuration";
      };
      
      user = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Specific user to setup iFlow CLI for (empty for all users)";
      };
    };

    config = lib.mkIf cfg.enable {
      # 基础包依赖
      environment.systemPackages = with pkgs; [
        cfg.package
        nodejs_22
        yarn
      ] ++ lib.optional cfg.enableUV uv
        ++ lib.optional cfg.enableNVM nvm-setup-script;

      # 环境变量
      environment.variables = {
        NPM_CONFIG_REGISTRY = "https://registry.npmmirror.com";
      } // lib.optionalAttrs cfg.enableNVM {
        NVM_DIR = "$HOME/.nvm";
        NODE_VERSION = cfg.nodeVersion;
      };

      # 为用户设置 npm 配置
      system.activationScripts.iflow-npm-config = lib.mkIf cfg.autoSetup ''
        echo "Setting up npm configuration for iFlow CLI..."
        
        # 设置 npm 镜像源
        npm_config_dir="/etc/npm"
        mkdir -p "$npm_config_dir"
        cat > "$npm_config_dir/npmrc" <<EOF
        registry=https://registry.npmmirror.com
        prefix=\$HOME/.npm-global
        EOF
      '';

      # 如果启用了 NVM，设置 NVM
      system.activationScripts.iflow-nvm-setup = lib.mkIf cfg.enableNVM ''
        if [ ! -d "$HOME/.nvm" ] && [ -n "$SUDO_USER" ]; then
          user_home=$(getent passwd $SUDO_USER | cut -d: -f6)
          nvm_dir="$user_home/.nvm"
          
          if [ ! -d "$nvm_dir" ]; then
            echo "Setting up NVM for user $SUDO_USER..."
            sudo -u $SUDO_USER git clone https://github.com/nvm-sh/nvm.git "$nvm_dir"
            cd "$nvm_dir"
            sudo -u $SUDO_USER git checkout v0.40.3
            
            # 添加 nvm 到 shell 配置
            for shell_file in "$user_home/.bashrc" "$user_home/.zshrc"; do
              if [ -f "$shell_file" ]; then
                if ! grep -q "NVM_DIR" "$shell_file"; then
                  cat >> "$shell_file" <<'EOF'

  # NVM configuration
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  EOF
                fi
              fi
            done
          fi
        fi
      '';
    };
  }