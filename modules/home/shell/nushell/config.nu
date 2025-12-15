# 欢迎信息
$env.config.show_banner = true

# 简单别名
alias k = kubectl
alias nixdr = ^nix-store --add

# 带环境变量的别名
alias nixup = ^https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 all_proxy=socks5://127.0.0.1:7897 nix flake update
alias nhsw = ^nh os switch --impure --accept-flake-config
alias ll = ls -l
# 自定义命令（处理复杂逻辑）
def urldecode [] {
    python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'
}

def urlencode [] {
    python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'
}

# Starship 提示符
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
source ~/.cache/starship/init.nu
carapace _carapace nushell |  save -f ~/.cache/carapace.nu
source ~/.cache/carapace.nu