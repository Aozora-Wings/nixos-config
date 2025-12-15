{ pkgs }:
pkgs.vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "vscode-language-pack-zh-hans";
    publisher = "MS-CEINTL";
    version = "1.107.2025121009";  # 注意：去掉开头的 "v"
    hash = "sha256-TW9ErKMCWuiuHX13kYjqq0aCaLnljstlGbuWHr6JOM0="; # 临时值
  };
  meta = {
    description = "Chinese (Simplified) Language Pack for Visual Studio Code";
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=MS-CEINTL.vscode-language-pack-zh-hans";
    homepage = "https://github.com/Microsoft/vscode-loc";
    license = pkgs.lib.licenses.mit;
    maintainers = [ pkgs.lib.maintainers.your-name ];
  };
}