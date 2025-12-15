sudo  https_proxy="172.20.32.1:7897" http_proxy="172.20.32.1:7897" nixos-rebuild switch -v --flake .#wsl --impure --option substituters "https://mirror.sjtu.edu.cn/nix-channels/store"
