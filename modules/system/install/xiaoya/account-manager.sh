#!/usr/bin/env bash
set -e

CONFIG_DIR="$1"

# 创建必要的目录
mkdir -p "$CONFIG_DIR"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
SKY_BLUE='\033[36m'
RESET='\033[0m'

# 函数定义
info() { echo -e "${GREEN}[INFO]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }

# 扫码获取阿里云盘 Refresh Token
get_aliyun_refresh_token() {
  info "开始获取阿里云盘 Refresh Token..."
  
  # 清理之前的扫码容器
  podman rm -f xiaoya-qrcode-token 2>/dev/null || true
  
  # 使用扫码获取 token（浏览器模式）
  local_ip=$(hostname -I | awk '{print $1}')
  if [ -z "$local_ip" ]; then
    local_ip="小雅服务器IP"
  fi
  info "请浏览器访问 http://${local_ip}:34256 并使用手机APP扫描二维码！"
  
  podman run -i --rm \
    -v "$CONFIG_DIR:/data" \
    -e LANG=C.UTF-8 \
    --network=host \
    --privileged \
    ddsderek/xiaoya-glue:python \
    /aliyuntoken/aliyuntoken.py --qrcode_mode=web
  
  # 检查获取的 token
  if [ -f "$CONFIG_DIR/mytoken.txt" ] && [ -s "$CONFIG_DIR/mytoken.txt" ]; then
    token=$(head -n1 "$CONFIG_DIR/mytoken.txt")
    token_len=${#token}
    if [ "$token_len" -eq 32 ]; then
      info "阿里云盘 Refresh Token 获取成功！"
      return 0
    else
      warn "获取的 Token 长度不正确 ($token_len)，可能需要手动输入"
      return 1
    fi
  else
    error "Token 获取失败"
    return 1
  fi
}

# 扫码获取阿里云盘 Open Token
get_aliyun_open_token() {
  info "开始获取阿里云盘 Open Token..."
  
  # 清理之前的扫码容器
  podman rm -f xiaoya-qrcode-opentoken 2>/dev/null || true
  
  # 使用扫码获取 token（浏览器模式）
  local_ip=$(hostname -I | awk '{print $1}')
  if [ -z "$local_ip" ]; then
    local_ip="小雅服务器IP"
  fi
  info "请浏览器访问 http://${local_ip}:34256 并使用手机APP扫描二维码！"
  
  podman run -i --rm \
    -v "$CONFIG_DIR:/data" \
    -e LANG=C.UTF-8 \
    --network=host \
    --privileged \
    ddsderek/xiaoya-glue:python \
    /aliyunopentoken/aliyunopentoken.py --qrcode_mode=web --api_url=auth.xiaoya.pro
  
  # 检查获取的 token
  if [ -f "$CONFIG_DIR/myopentoken.txt" ] && [ -s "$CONFIG_DIR/myopentoken.txt" ]; then
    token=$(head -n1 "$CONFIG_DIR/myopentoken.txt")
    token_len=${#token}
    if [ "$token_len" -eq 280 ] || [ "$token_len" -eq 335 ]; then
      info "阿里云盘 Open Token 获取成功！"
      return 0
    else
      warn "获取的 Token 长度不正确 ($token_len)，可能需要手动输入"
      return 1
    fi
  else
    error "Open Token 获取失败"
    return 1
  fi
}

# 扫码获取 115 Cookie
get_115_cookie() {
  info "开始获取 115 Cookie..."
  
  # 清理之前的扫码容器
  podman rm -f xiaoya-qrcode-115 2>/dev/null || true
  
  # 使用扫码获取 cookie（浏览器模式）
  local_ip=$(hostname -I | awk '{print $1}')
  if [ -z "$local_ip" ]; then
    local_ip="小雅服务器IP"
  fi
  info "请浏览器访问 http://${local_ip}:34256 并使用手机APP扫描二维码！"
  
  podman run -i --rm \
    -v "$CONFIG_DIR:/data" \
    -e LANG=C.UTF-8 \
    --network=host \
    --privileged \
    ddsderek/xiaoya-glue:python \
    /115cookie/115cookie.py --qrcode_mode=web --qrcode_app=alipaymini
  
  # 检查获取的 cookie
  if [ -f "$CONFIG_DIR/115_cookie.txt" ] && [ -s "$CONFIG_DIR/115_cookie.txt" ]; then
    info "115 Cookie 获取成功！"
    return 0
  else
    error "115 Cookie 获取失败"
    return 1
  fi
}

# 扫码获取夸克 Cookie
get_quark_cookie() {
  info "开始获取夸克 Cookie..."
  
  # 清理之前的扫码容器
  podman rm -f xiaoya-qrcode-quark 2>/dev/null || true
  
  # 使用扫码获取 cookie（浏览器模式）
  local_ip=$(hostname -I | awk '{print $1}')
  if [ -z "$local_ip" ]; then
    local_ip="小雅服务器IP"
  fi
  info "请浏览器访问 http://${local_ip}:34256 并使用手机APP扫描二维码！"
  
  podman run -i --rm \
    -v "$CONFIG_DIR:/data" \
    -e LANG=C.UTF-8 \
    --network=host \
    --privileged \
    ddsderek/xiaoya-glue:python \
    /quarkcookie/quarkcookie.py --qrcode_mode=web
  
  # 检查获取的 cookie
  if [ -f "$CONFIG_DIR/quark_cookie.txt" ] && [ -s "$CONFIG_DIR/quark_cookie.txt" ]; then
    info "夸克 Cookie 获取成功！"
    return 0
  else
    error "夸克 Cookie 获取失败"
    return 1
  fi
}

# 扫码获取 UC Cookie
get_uc_cookie() {
  info "开始获取 UC Cookie..."
  
  # 清理之前的扫码容器
  podman rm -f xiaoya-qrcode-uc 2>/dev/null || true
  
  # 使用扫码获取 cookie（浏览器模式）
  local_ip=$(hostname -I | awk '{print $1}')
  if [ -z "$local_ip" ]; then
    local_ip="小雅服务器IP"
  fi
  info "请浏览器访问 http://${local_ip}:34256 并使用手机APP扫描二维码！"
  
  podman run -i --rm \
    -v "$CONFIG_DIR:/data" \
    -e LANG=C.UTF-8 \
    --network=host \
    --privileged \
    ddsderek/xiaoya-glue:python \
    /uccookie/uccookie.py --qrcode_mode=web
  
  # 检查获取的 cookie
  if [ -f "$CONFIG_DIR/uc_cookie.txt" ] && [ -s "$CONFIG_DIR/uc_cookie.txt" ]; then
    info "UC Cookie 获取成功！"
    return 0
  else
    error "UC Cookie 获取失败"
    return 1
  fi
}

# 手动输入配置
manual_input() {
  local account_type="$1"
  
  case "$account_type" in
    "115")
      echo "请输入 115 Cookie："
      read -r cookie
      echo "$cookie" > "$CONFIG_DIR/115_cookie.txt"
      info "115 Cookie 已保存"
      ;;
    "quark")
      echo "请输入夸克 Cookie："
      read -r cookie
      echo "$cookie" > "$CONFIG_DIR/quark_cookie.txt"
      info "夸克 Cookie 已保存"
      ;;
    "aliyun_refresh")
      while true; do
        echo "请输入阿里云盘 Refresh Token（32位长）："
        read -r token
        token_len=${#token}
        if [ "$token_len" -ne 32 ]; then
          error "长度不对，阿里云盘 Refresh Token 是 32 位长"
        else
          echo "$token" > "$CONFIG_DIR/mytoken.txt"
          info "阿里云盘 Refresh Token 已保存"
          break
        fi
      done
      ;;
    "aliyun_open")
      while true; do
        echo "请输入阿里云盘 Open Token（280位或335位长）："
        read -r token
        token_len=${#token}
        if [[ "$token_len" -ne 280 ]] && [[ "$token_len" -ne 335 ]]; then
          error "长度不对，阿里云盘 Open Token 是 280 位或 335 位长"
        else
          echo "$token" > "$CONFIG_DIR/myopentoken.txt"
          info "阿里云盘 Open Token 已保存"
          break
        fi
      done
      ;;
    "uc")
      echo "请输入 UC Cookie："
      read -r cookie
      echo "$cookie" > "$CONFIG_DIR/uc_cookie.txt"
      info "UC Cookie 已保存"
      ;;
    "pikpak")
      echo "请输入 PikPak 账号（格式：账号 密码）："
      read -r account password
      echo "$account $password" > "$CONFIG_DIR/pikpak.txt"
      info "PikPak 账号已保存"
      ;;
    "ali2115")
      echo "请输入阿里转存115播放配置（任意内容启用）："
      read -r content
      echo "$content" > "$CONFIG_DIR/ali2115.txt"
      info "阿里转存115播放配置已保存"
      ;;
  esac
}

# 显示当前配置状态
show_status() {
  echo -e "当前配置状态："
  
  # 115 Cookie
  if [ -f "$CONFIG_DIR/115_cookie.txt" ]; then
    echo -e "1、115 Cookie                        （当前：${GREEN}已配置${RESET}）"
  else
    echo -e "1、115 Cookie                        （当前：${RED}未配置${RESET}）"
  fi
  
  # 夸克 Cookie
  if [ -f "$CONFIG_DIR/quark_cookie.txt" ]; then
    echo -e "2、夸克 Cookie                       （当前：${GREEN}已配置${RESET}）"
  else
    echo -e "2、夸克 Cookie                       （当前：${RED}未配置${RESET}）"
  fi
  
  # 阿里云盘 Refresh Token
  if [ -f "$CONFIG_DIR/mytoken.txt" ]; then
    echo -e "3、阿里云盘 Refresh Token（mytoken） （当前：${GREEN}已配置${RESET}）"
  else
    echo -e "3、阿里云盘 Refresh Token（mytoken） （当前：${RED}未配置${RESET}）"
  fi
  
  # 阿里云盘 Open Token
  if [ -f "$CONFIG_DIR/myopentoken.txt" ]; then
    echo -e "4、阿里云盘 Open Token（myopentoken）（当前：${GREEN}已配置${RESET}）"
  else
    echo -e "4、阿里云盘 Open Token（myopentoken）（当前：${RED}未配置${RESET}）"
  fi
  
  # UC Cookie
  if [ -f "$CONFIG_DIR/uc_cookie.txt" ]; then
    echo -e "5、UC Cookie                         （当前：${GREEN}已配置${RESET}）"
  else
    echo -e "5、UC Cookie                         （当前：${RED}未配置${RESET}）"
  fi
  
  # PikPak
  if [ -f "$CONFIG_DIR/pikpak.txt" ]; then
    echo -e "6、PikPak                            （当前：${GREEN}已配置${RESET}）"
  else
    echo -e "6、PikPak                            （当前：${RED}未配置${RESET}）"
  fi
  
  # 阿里转存115播放
  if [ -f "$CONFIG_DIR/ali2115.txt" ]; then
    echo -e "7、阿里转存115播放（ali2115.txt）    （当前：${GREEN}已配置${RESET}）"
  else
    echo -e "7、阿里转存115播放（ali2115.txt）    （当前：${RED}未配置${RESET}）"
  fi
}

# 账号配置子菜单
account_submenu() {
  local account_name="$1"
  local account_type="$2"
  
  while true; do
    clear
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BLUE}        $account_name 配置${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    echo ""
    echo -e "1、扫码自动获取"
    echo -e "2、手动输入"
    echo -e "3、删除配置"
    echo -e "0、返回上级"
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    read -p "请选择操作 [0-3]: " choice
    
    case "$choice" in
      1)
        case "$account_type" in
          "115") get_115_cookie ;;
          "quark") get_quark_cookie ;;
          "aliyun_refresh") get_aliyun_refresh_token ;;
          "aliyun_open") get_aliyun_open_token ;;
          "uc") get_uc_cookie ;;
          "pikpak") 
            echo "PikPak 暂不支持扫码获取，请使用手动输入"
            sleep 2
            continue
            ;;
          "ali2115")
            echo "阿里转存115播放配置，请使用手动输入"
            sleep 2
            continue
            ;;
        esac
        read -p "按任意键继续..." -n1 -s
        ;;
      2)
        manual_input "$account_type"
        read -p "按任意键继续..." -n1 -s
        ;;
      3)
        case "$account_type" in
          "115") rm -f "$CONFIG_DIR/115_cookie.txt" ;;
          "quark") rm -f "$CONFIG_DIR/quark_cookie.txt" ;;
          "aliyun_refresh") rm -f "$CONFIG_DIR/mytoken.txt" ;;
          "aliyun_open") rm -f "$CONFIG_DIR/myopentoken.txt" ;;
          "uc") rm -f "$CONFIG_DIR/uc_cookie.txt" ;;
          "pikpak") rm -f "$CONFIG_DIR/pikpak.txt" ;;
          "ali2115") rm -f "$CONFIG_DIR/ali2115.txt" ;;
        esac
        info "配置已删除"
        sleep 2
        ;;
      0)
        return 0
        ;;
      *)
        error "无效选择"
        sleep 1
        ;;
    esac
  done
}

# 主菜单
while true; do
  clear
  echo -e "${BLUE}========================================${RESET}"
  echo -e "${BLUE}        小雅网盘账号管理${RESET}"
  echo -e "${BLUE}========================================${RESET}"
  echo ""
  echo -e "${SKY_BLUE}小雅留言，会员购买指南：${RESET}"
  echo -e "${SKY_BLUE}基础版：阿里非会员+115会员${RESET}"
  echo -e "${SKY_BLUE}升级版：阿里svip+115会员（用TV token破解阿里svip的高速流量限制）${RESET}"
  echo -e "${SKY_BLUE}豪华版：阿里svip+第三方权益包+115会员${RESET}"
  echo -e "${SKY_BLUE}乞丐版：满足看emby画报但不要播放，播放用tvbox各种免费源${RESET}"
  echo ""
  
  show_status
  
  echo ""
  echo -e "8、应用配置（重启小雅服务）"
  echo -e "0、退出"
  echo -e "${BLUE}========================================${RESET}"
  read -p "请选择要配置的账号 [0-8]: " choice
  
  case "$choice" in
    1)
      account_submenu "115 Cookie" "115"
      ;;
    2)
      account_submenu "夸克 Cookie" "quark"
      ;;
    3)
      account_submenu "阿里云盘 Refresh Token" "aliyun_refresh"
      ;;
    4)
      account_submenu "阿里云盘 Open Token" "aliyun_open"
      ;;
    5)
      account_submenu "UC Cookie" "uc"
      ;;
    6)
      account_submenu "PikPak" "pikpak"
      ;;
    7)
      account_submenu "阿里转存115播放" "ali2115"
      ;;
    8)
      info "重启小雅服务中..."
      # 重启小雅容器
      if podman container inspect xiaoya-alist >/dev/null 2>&1; then
        podman restart xiaoya-alist
        info "小雅容器已重启"
      else
        warn "小雅容器未运行"
      fi
      sleep 2
      ;;
    0)
      info "退出账号管理"
      exit 0
      ;;
    *)
      error "无效选择，请重新输入"
      sleep 1
      ;;
  esac
done
