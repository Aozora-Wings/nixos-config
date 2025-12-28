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

# 全局UA变量
GLOBAL_UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" # MacOS
GLOBAL_UA_2="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"     # Windows
QUARK_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) quark-cloud-drive/2.5.20 Chrome/100.0.4896.160 Electron/18.3.5.4-b478491100 Safari/537.36 Channel/pckk_other_ch"
UC_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) uc-cloud-drive/2.5.20 Chrome/100.0.4896.160 Electron/18.3.5.4-b478491100 Safari/537.36 Channel/pckk_other_ch"

# 函数定义
info() { echo -e "${GREEN}[INFO]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }

# 检查函数
check_quark_cookie() {
    if [[ ! -f "${1}/quark_cookie.txt" ]] && [[ ! -s "${1}/quark_cookie.txt" ]]; then
        return 1
    fi
    local cookie url headers response status url2 response2 member member_type vip_88
    cookie=$(head -n1 "${1}/quark_cookie.txt")
    url="https://drive-pc.quark.cn/1/clouddrive/config?pr=ucpro&fr=pc&uc_param_str="
    headers="Cookie: $cookie; User-Agent: $QUARK_UA; Referer: https://pan.quark.cn"
    response=$(curl -s -D - -H "$headers" "$url")
    status=$(echo "$response" | grep -i status | cut -f2 -d: | cut -f1 -d,)
    if [ "$status" == "401" ] || grep -qv "__puus" "${1}/quark_cookie.txt"; then
        error "无效夸克 Cookie"
        return 1
    elif [ "$status" == "200" ]; then
        url2="https://drive-pc.quark.cn/1/clouddrive/member?pr=ucpro&fr=pc&uc_param_str=&fetch_subscribe=true&_ch=home&fetch_identity=true"
        response2=$(curl -s -H "$headers" "$url2")
        member=$(echo $response2 | grep -o '"member_type":"[^"]*"' | sed 's/"member_type":"\(.*\)"/\1/')
        if [ $member == 'EXP_SVIP' ] || [ $member == 'SVIP' ]; then
            vip_88=$(echo $response2 | grep -o '"vip88_new":[t|f]' | cut -f2 -d:)
            if [ $vip_88 == 't' ]; then
                member_type="88VIP会员"
            else
                member_type="SVIP会员"
            fi
        elif [ $member == 'NORMAL' ]; then
            member_type="普通用户"
        else
            member_type="${member//\"/}会员"
        fi
        info "有效 夸克 Cookie，${member_type}"
        return 0
    else
        error "请求失败，请检查 Cookie 或网络连接是否正确。"
        return 1
    fi
}

check_uc_cookie() {
    if [[ ! -f "${1}/uc_cookie.txt" ]] && [[ ! -s "${1}/uc_cookie.txt" ]]; then
        return 1
    fi
    local cookie url headers response status referer set_cookie
    cookie=$(head -n1 "${1}/uc_cookie.txt")
    referer="https://drive.uc.cn"
    url="https://pc-api.uc.cn/1/clouddrive/file/sort?pr=UCBrowser&fr=pc&pdir_fid=0&_page=1&_size=50&_fetch_total=1&_fetch_sub_dirs=0&_sort=file_type:asc,updated_at:desc"
    headers="Cookie: $cookie; User-Agent: $UC_UA; Referer: $referer"
    response=$(curl -s -D - -H "$headers" "$url")
    set_cookie=$(echo "$response" | grep -i "^Set-Cookie:" | sed 's/Set-Cookie: //')
    status=$(echo "$response" | grep -i status | cut -f2 -d: | cut -f1 -d,)
    if [ "$status" == "401" ] || grep -qv "__puus" "${1}/uc_cookie.txt"; then
        error "无效 UC Cookie"
        return 1
    elif [ -n "${set_cookie}" ]; then
        local new_puus new_cookie
        new_puus=$(echo "$set_cookie" | cut -f2 -d: | cut -f1 -d\;)
        new_cookie=${cookie//__puus=[^;]*/$new_puus}
        echo "$new_cookie" > ${1}/uc_cookie.txt
        info "有效 UC Cookie 并更新"
        return 0
    elif [ -z "${set_cookie}" ] && [ "${status}" == "200" ]; then
        info "有效 UC Cookie"
        return 0
    else
        error "请求失败，请检查 Cookie 或网络连接是否正确。"
        return 1
    fi
}

check_115_cookie() {
    if [[ ! -f "${1}/115_cookie.txt" ]] && [[ ! -s "${1}/115_cookie.txt" ]]; then
        return 1
    fi
    local cookie url headers response vip
    cookie=$(head -n1 "${1}/115_cookie.txt")
    url="https://my.115.com/?ct=ajax&ac=nav"
    headers="Cookie: $cookie; User-Agent: $GLOBAL_UA_2; Referer: https://115.com/"
    response=$(curl -s -D - -H "$headers" "$url")
    vip=$(echo -e "$response" | grep -o '"vip":[^,]*' | sed 's/"vip"://')
    if echo -e "${response}" | grep -q "user_id"; then
        if [ $vip == "0" ]; then
            info "有效 115 Cookie，普通用户"
        else
            info "有效 115 Cookie，VIP用户"
        fi
        return 0
    else
        error "请求失败，请检查 Cookie 或网络连接是否正确。"
        return 1
    fi
}

check_aliyunpan_tvtoken() {
    local token url response refresh_token data_dir
    data_dir="${1}"
    if [ -n "${2}" ]; then
        token="${2}"
    else
        token=$(head -n1 "${data_dir}/myopentoken.txt")
    fi
    url=$(head -n1 "${data_dir}/open_tv_token_url.txt")
    if ! response=$(curl -s "${url}" -X POST -H "User-Agent: $GLOBAL_UA" -H "Rererer: https://www.aliyundrive.com/" -H "Content-Type: application/json" -d '{"refresh_token":"'$token'", "grant_type": "refresh_token"}'); then
        warn "网络问题，无法检测 阿里云盘 TV Token 有效性"
        return 0
    fi
    refresh_token=$(echo "$response" | sed 's/:\s*/:/g' | sed -n 's/.*"refresh_token":"\([^"]*\).*/\1/p')
    if [ -n "${refresh_token}" ]; then
        echo "${refresh_token}" > "${data_dir}/myopentoken.txt"
        info "有效 阿里云盘 TV Token"
        return 0
    else
        error "无效 阿里云盘 TV Token"
        return 1
    fi
}

check_aliyunpan_refreshtoken() {
    local token referer response refresh_token data_dir
    data_dir="${1}"
    if [ -n "${2}" ]; then
        token="${2}"
    else
        token=$(head -n1 "${data_dir}/mytoken.txt")
    fi
    referer=https://www.aliyundrive.com/
    if ! response=$(curl -s https://auth.aliyundrive.com/v2/account/token -X POST -H "User-Agent: $GLOBAL_UA_2" -H "Content-Type:application/json" -H "Referer: $referer" -d '{"refresh_token":"'$token'", "grant_type": "refresh_token"}'); then
        warn "网络问题，无法检测 阿里云盘 Refresh Token 有效性"
        return 0
    fi
    refresh_token=$(echo "$response" | sed 's/:\s*/:/g' | sed -n 's/.*"refresh_token":"\([^"]*\).*/\1/p')
    if [ -n "${refresh_token}" ]; then
        echo "${refresh_token}" > "${data_dir}/mytoken.txt"
        info "有效 阿里云盘 Refresh Token"
        return 0
    else
        error "无效 阿里云盘 Refresh Token"
        return 1
    fi
}

check_aliyunpan_opentoken() {
    local token response refresh_token data_dir
    data_dir="${1}"
    if [ -n "${2}" ]; then
        token="${2}"
    else
        token=$(head -n1 "${data_dir}/myopentoken.txt")
    fi
    if ! response=$(curl -s "http://auth.xiaoya.pro/api/ali_open/refresh" -X POST -H "User-Agent: $GLOBAL_UA" -H "Rererer: https://www.aliyundrive.com/" -H "Content-Type: application/json" -d '{"refresh_token":"'$token'", "grant_type": "refresh_token"}'); then
        warn "网络问题，无法检测 阿里云盘 Open Token 有效性"
        return 0
    fi
    refresh_token=$(echo "$response" | sed 's/:\s*/:/g' | sed -n 's/.*"refresh_token":"\([^"]*\).*/\1/p')
    if [ -n "${refresh_token}" ]; then
        echo "${refresh_token}" > "${data_dir}/myopentoken.txt"
        info "有效 阿里云盘 Open Token"
        return 0
    else
        error "无效 阿里云盘 Open Token"
        return 1
    fi
}

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
  echo -e "——————————————————————————————————————————————————————————————————————————————————"
  echo -e "${BLUE}账号管理${RESET}\n"
  echo -e "${SKY_BLUE}小雅留言，会员购买指南：
基础版：阿里非会员+115会员
升级版：阿里svip+115会员（用TV token破解阿里svip的高速流量限制）
豪华版：阿里svip+第三方权益包+115会员
乞丐版：满足看emby画报但不要播放，播放用tvbox各种免费源${RESET}\n"
  echo -ne "${GREEN}[INFO]${RESET} 界面加载中...${RESET}\r"
  
  echo -e "1、115 Cookie                        （当前：$(if [ -f "${CONFIG_DIR}/115_cookie.txt" ]; then if CHECK_OUT=$(check_115_cookie "${CONFIG_DIR}" 2>&1); then echo -e "${GREEN}$(echo -e ${CHECK_OUT} | sed 's/\[.*\] //')${RESET}"; else echo -e "${RED}错误${RESET}"; fi; else echo -e "${RED}未配置${RESET}"; fi)）"
  echo -e "2、夸克 Cookie                       （当前：$(if [ -f "${CONFIG_DIR}/quark_cookie.txt" ]; then if CHECK_OUT=$(check_quark_cookie "${CONFIG_DIR}" 2>&1); then echo -e "${GREEN}$(echo -e ${CHECK_OUT} | sed 's/\[.*\] //')${RESET}"; else echo -e "${RED}错误${RESET}"; fi; else echo -e "${RED}未配置${RESET}"; fi)）"
  echo -e "3、阿里云盘 Refresh Token（mytoken） （当前：$(if [ -f "${CONFIG_DIR}/mytoken.txt" ]; then if CHECK_OUT=$(check_aliyunpan_refreshtoken "${CONFIG_DIR}" 2>&1); then echo -e "${GREEN}$(echo -e ${CHECK_OUT} | sed 's/\[.*\] //')${RESET}"; else echo -e "${RED}错误${RESET}"; fi; else echo -e "${RED}未配置${RESET}"; fi)）"
  echo -e "4、阿里云盘 Open Token（myopentoken）（当前：$(if [ -f "${CONFIG_DIR}/myopentoken.txt" ]; then if [ -f "${CONFIG_DIR}/open_tv_token_url.txt" ]; then if CHECK_OUT=$(check_aliyunpan_tvtoken "${CONFIG_DIR}" 2>&1); then echo -e "${GREEN}$(echo -e ${CHECK_OUT} | sed 's/\[.*\] //')${RESET}"; else echo -e "${RED}阿里云盘 TV Token 已失效${RESET}"; fi; elif CHECK_OUT=$(check_aliyunpan_opentoken "${CONFIG_DIR}" 2>&1); then echo -e "${GREEN}$(echo -e ${CHECK_OUT} | sed 's/\[.*\] //')${RESET}"; else echo -e "${RED}阿里云盘 Open Token 已失效${RESET}"; fi; else echo -e "${RED}未配置${RESET}"; fi)）"
  echo -e "5、UC Cookie                         （当前：$(if [ -f "${CONFIG_DIR}/uc_cookie.txt" ]; then if CHECK_OUT=$(check_uc_cookie "${CONFIG_DIR}" 2>&1); then echo -e "${GREEN}$(echo -e ${CHECK_OUT} | sed 's/\[.*\] //')${RESET}"; else echo -e "${RED}错误${RESET}"; fi; else echo -e "${RED}未配置${RESET}"; fi)）"
  echo -e "6、PikPak                            （当前：$(if [ -f "${CONFIG_DIR}/pikpak.txt" ]; then echo -e "${GREEN}已配置${RESET}"; else echo -e "${RED}未配置${RESET}"; fi)）"
  echo -e "7、阿里转存115播放（ali2115.txt）    （当前：$(if [ -f "${CONFIG_DIR}/ali2115.txt" ]; then echo -e "${GREEN}已配置${RESET}"; else echo -e "${RED}未配置${RESET}"; fi)）"
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
