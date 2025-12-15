{ pkgs }:

let
  customBuildVscodeExtension = { name, publisher, version, sha256, ... }:
    pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = {
        inherit name publisher version;
        hash = sha256;
      };
    };
      nixpkgs-fmt = pkgs.vscode-extensions.b4dm4n.vscode-nixpkgs-fmt;
  nix-ide = pkgs.vscode-extensions.jnoortheen.nix-ide;

  chinese-language-ui = import ./chinese.nix { inherit pkgs; };
in
{

  # 自定义扩展
  
  # 启用的扩展列表 - 现在可以引用上面的属性了
  enabledExtensions = [
    nixpkgs-fmt
    nix-ide
    pkgs.vscode-extensions.ms-vscode-remote.remote-ssh
    chinese-language-ui
  ];
}