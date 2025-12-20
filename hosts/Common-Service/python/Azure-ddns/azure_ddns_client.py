import requests
import time
from datetime import datetime
import os
import platform
import socket
import logging
import sys
import argparse

from azure.identity import DefaultAzureCredential,AzureCliCredential
from azure.mgmt.dns import DnsManagementClient
from azure.core.exceptions import AzureError

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)
class AzureDDNSClient:
    def __init__(self):
        """
        使用 DefaultAzureCredential 自动获取认证令牌
        支持以下认证方式（按顺序尝试）:
        1. 环境变量 (AZURE_CLIENT_ID + AZURE_CLIENT_SECRET/AZURE_CLIENT_CERTIFICATE_PATH)
        2. Managed Identity (Azure VM/App Service)
        3. VS Code Azure Account 插件
        4. Azure CLI (`az login`)
        """
        self.subscription_id = os.getenv('AZURE_SUBSCRIPTION_ID')
        self.resource_group = os.getenv('AZURE_RESOURCE_GROUP', 'dns')
        self.dns_zone = os.getenv('AZURE_DNS_ZONE')
        self.record_set = os.getenv('AZURE_RECORD_SET', 'service')
        self.record_type = os.getenv('AZURE_RECORD_TYPE', 'AAAA')
        self.current_platform = platform.system().lower()
        # self.credential = AzureCliCredential()
        # 初始化 Azure 认证和 DNS 客户端
        self.credential = DefaultAzureCredential()

        self.dns_client = DnsManagementClient(
            self.credential,
            self.subscription_id
        )

    def get_ip_address(self):
        """获取当前公网IP（自动区分IPv4/IPv6）"""
        try:
            if self.record_type == 'A':
                return self._get_public_ipv4()
            elif self.record_type == 'AAAA':
                if self.current_platform == 'linux':
                    return self._get_linux_ipv6()
                elif self.current_platform == 'windows':
                    return self._get_windows_ipv6()
                else:  # macOS和其他系统
                    return self._get_generic_ipv6()
        except Exception as e:
            logger.info(f"[错误] 获取IP地址失败: {e}")
            return None

    def _get_public_ipv4(self):
        """获取IPv4地址"""
        services = [
            'https://api.ipify.org?format=json',
            'https://ipinfo.io/json',
            'https://ifconfig.me/all.json'
        ]
        for url in services:
            try:
                response = requests.get(url, timeout=5)
                return response.json()['ip']
            except:
                continue
        raise Exception("所有IPv4 API请求失败")

    def _get_linux_ipv6(self):
        """获取稳定的全局IPv6地址（优先非临时地址）"""
        logger.info(f"进入linux模式")
        try:
            # 方案1：优先通过API获取（避免本地接口复杂性）
            # try:
            #     response = requests.get('https://api6.ipify.org?format=json', timeout=5)
            #     if response.status_code == 200:
            #         return response.json()['ip']
            # except:
            #     pass

            # 方案2：从网络接口获取（精确筛选稳定地址）
            try:
                import netifaces
                # 常见接口名称（按优先级排序）
                interfaces = ['eth0', 'ens33', 'wlan0', 'wlp2s0', 'wlo1','enp3s0']  # 添加了您的wlo1接口
                for iface in interfaces:
                    try:
                        # 获取该接口所有IPv6地址
                        addrs = netifaces.ifaddresses(iface).get(netifaces.AF_INET6, [])
                        
                        # 按优先级筛选地址
                        stable_global_addrs = []
                        temp_global_addrs = []
                        
                        for addr in addrs:
                            ip = addr['addr'].split('%')[0]  # 去除作用域ID
                            
                            # 排除本地地址和特殊地址
                            if ip.startswith(('fe80::', '::1', 'fd00::')):
                                continue
                                
                            # 判断地址类型（根据RFC 4941隐私扩展和临时地址标志）
                            if 'stable' in addr.get('flags', []) or \
                            not ('temporary' in addr.get('flags', []) or 'dynamic' in addr.get('flags', [])):
                                stable_global_addrs.append(ip)
                            else:
                                temp_global_addrs.append(ip)
                        
                        # 优先返回稳定地址
                        if stable_global_addrs:
                            return stable_global_addrs[0]  # 返回第一个稳定地址
                        if temp_global_addrs:
                            return temp_global_addrs[0]  # 没有稳定地址则返回临时地址
                            
                    except (KeyError, ValueError):
                        continue
                        
            except ImportError:
                # 回退到ip命令（如果netifaces不可用）
                try:
                    import subprocess
                    result = subprocess.run(['ip', '-6', 'addr', 'show', 'scope', 'global'], 
                                        capture_output=True, text=True)
                    if result.returncode == 0:
                        # 提取非临时地址（优先）
                        for line in result.stdout.splitlines():
                            if 'inet6' in line and 'temporary' not in line:
                                ip = line.split()[1].split('/')[0]
                                if not ip.startswith(('fe80::', '::1')):
                                    return ip
                        # 如果没找到非临时地址，返回第一个全局地址
                        for line in result.stdout.splitlines():
                            if 'inet6' in line:
                                ip = line.split()[1].split('/')[0]
                                if not ip.startswith(('fe80::', '::1')):
                                    return ip
                except:
                    pass

            # 方案3：终极回退 - 通过socket获取
            hostname = socket.gethostname()
            ipv6_addrs = [
                addr[4][0] for addr in socket.getaddrinfo(hostname, None)
                if addr[0] == socket.AF_INET6
            ]
            for addr in ipv6_addrs:
                if not addr.startswith(('fe80::', '::1')):
                    return addr
                    
            return None
            
        except Exception as e:
            logger.info(f"[警告] IPv6地址获取失败: {e}")
            return None

            # 最后尝试socket
            hostname = socket.gethostname()
            ipv6_addrs = [
                addr[4][0] for addr in socket.getaddrinfo(hostname, None)
                if addr[0] == socket.AF_INET6
            ]
            for addr in ipv6_addrs:
                if not addr.startswith(('fe80::', '::1')):
                    return addr
            return None
        except Exception as e:
            logger.info(f"[警告] Linux IPv6获取失败: {e}")
            return None

    def _get_windows_ipv6(self):
        """Windows专用IPv6获取方法"""
        try:
            hostname = socket.gethostname()
            ipv6_addrs = [
                addr[4][0] for addr in socket.getaddrinfo(hostname, None)
                if addr[0] == socket.AF_INET6
            ]
            for addr in ipv6_addrs:
                if not addr.startswith(('fe80::', '::1')):
                    return addr
            return None
        except Exception as e:
            logger.info(f"[警告] Windows IPv6获取失败: {e}")
            return None

    def _get_generic_ipv6(self):
        """通用IPv6获取方法"""
        try:
            response = requests.get('https://api6.ipify.org?format=json', timeout=5)
            return response.json()['ip']
        except:
            return None

    def update_dns_record(self, ip_address):
        """更新Azure DNS记录"""
        try:
            if self.record_type == 'A':
                record = self.dns_client.record_sets.create_or_update(
                    self.resource_group,
                    self.dns_zone,
                    self.record_set,
                    self.record_type,
                    {
                        "ttl": 60,
                        "arecords": [{"ipv4_address": ip_address}]
                    }
                )
            elif self.record_type == 'AAAA':
                record = self.dns_client.record_sets.create_or_update(
                    self.resource_group,
                    self.dns_zone,
                    self.record_set,
                    self.record_type,
                    {
                        "ttl": 60,
                        "aaaarecords": [{"ipv6_address": ip_address}]
                    }
                )
            logger.info(f"[成功] DNS记录已更新: {record.name} -> {ip_address}")
            return record
        except AzureError as e:
            logger.info(f"[错误] DNS更新失败: {e}")
            raise

    def run(self, interval=300):
        """运行DDNS客户端"""
        last_ip = None
        logger.info(f"启动Azure DDNS客户端 (记录类型: {self.record_type})")
        while True:
            try:
                current_ip = self.get_ip_address()
                if not current_ip:
                    logger.info("[警告] 无法获取当前IP地址")
                elif current_ip != last_ip:
                    logger.info(f"[信息] 检测到IP变化: {last_ip or '无'} -> {current_ip}")
                    self.update_dns_record(current_ip)
                    last_ip = current_ip
                else:
                    logger.info(f"[信息] IP未变化: {current_ip}")
            except Exception as e:
                logger.info(f"[错误] 运行异常: {e}")
            
            time.sleep(interval)

if __name__ == "__main__":
    
    interval = int(os.getenv('AZURE_CHECK_INTERVAL', '300'))

    # 你的 AzureDDNSClient 类定义...
    client = AzureDDNSClient()

    client.run(interval=interval)
