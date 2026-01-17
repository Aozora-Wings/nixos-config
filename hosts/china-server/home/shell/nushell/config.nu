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
# systemctl 子命令补全
def "nu-complete systemctl-commands" [] {
    [
        "start", "stop", "restart", "reload", "status", 
        "enable", "disable", "is-enabled", "mask", "unmask",
        "list-unit-files", "list-units", "list-timers", 
        "list-sockets", "daemon-reload", "show", "edit"
    ]
}

# 系统单元补全
def "nu-complete systemctl-units" [] {
    try {
        ^systemctl list-unit-files --no-legend --no-pager 
        | lines 
        | parse "{unit} {status}" 
        | get unit
    } catch {
        []
    }
}

# 主补全函数 - 使用正确的参数
def "nu-complete systemctl" [context: string, offset: int] {
    let words = ($context | split row " " | skip 1)
    let current_word = if ($words | is-empty) { "" } else { $words | last }
    
    match ($words | length) {
        0 => { 
            # 只有 systemctl，建议所有子命令
            nu-complete systemctl-commands
        }
        1 => { 
            # 有一个参数，过滤匹配的子命令
            let commands = (nu-complete systemctl-commands)
            $commands | where $it =~ $current_word
        }
        _ => {
            # 多个参数，第二个参数开始建议单元名
            let first_arg = ($words | first)
            let unit_commands = ["start", "stop", "restart", "status", "enable", "disable", "mask", "unmask", "show"]
            
            if $first_arg in $unit_commands {
                let units = (nu-complete systemctl-units)
                $units | where $it =~ $current_word
            } else {
                []
            }
        }
    }
}

# 定义外部命令
extern "systemctl" [
    command?: string@"nu-complete systemctl"
    unit?: string
    --help(-h)
    --version
]

# Starship 提示符
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
source ~/.cache/starship/init.nu