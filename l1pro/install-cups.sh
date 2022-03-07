#!/bin/bash


sudo apt-get -y update
sudo apt-get -y upgrade

echo "修改时区为东八区"
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
	dpkg-reconfigure --frontend noninteractive tzdata


sudo apt-get -y install aptitude

#sudo apt-get update -y && sudo apt-get  upgrade -y
# 添加自定义安装软件列表
sudo apt-get -y install ufw
# 安装 CUPS 相关组件
sudo aptitude -y install ghostscript dc foomatic-db-engine cups printer-driver-gutenprint
# 安装 AVAHI 相关组件
sudo aptitude -y install avahi-daemon avahi-discover libnss-mdns
# 安装 SAMBA 相关组件
sudo aptitude -y install samba samba-common-bin

# 在本地网络上显示共享打印机
sed -i 's/Browsing Off/Browsing On/g' /etc/cups/cupsd.conf

# 让 CUPS 侦听所有可用的网络接口
sed -i 's/Listen localhost:631/Port 631/g' /etc/cups/cupsd.conf

# 允许来自同一网络中的其他计算机的访问
sed -i "/Order allow,deny/a\\  Allow all" /etc/cups/cupsd.conf


# 把 CUPS 用户加入 ROOT 权限组
sudo usermod -a -G lpadmin root
sudo cupsctl --remote-any

# 重启 CUPS 服务
sudo systemctl restart cups

# 安装 Avahi 守护进程
# CUPS 可以通过 mDNS（多播 DNS）和 DNS-SD（DNS 服务发现）协议（也称为 Bonjour）宣布其在网络上的存在。为此，您需要安装并运行avahi-daemon，这是一项类似于 Apple Bonjour 服务的服务，允许计算机自动发现本地网络上的共享设备和服务。
sudo apt install avahi-daemon
# 启动 avahi 守护进程。
sudo systemctl start avahi-daemon
sudo ufw allow 5353/udp

echo "通过 Samba 共享 CUPS 打印机"
echo "配置 smbd nmbd 服务"
echo "spoolssd 建议在共享打印机时启用该服务。当有大量打印作业时，这将使 Samba 更有效率"
sed -i '/\[global\]/a\   rpc_daemon:spoolssd = fork' /etc/samba/smb.conf && \
sed -i "/\[global\]/a\   rpc_server:spoolss = external" /etc/samba/smb.conf && \

echo "开启访客打印权限"
sed -i '/\[printers\]/{:\[printers\];n;s/browseable = no/browseable = yes/g;/# printer drivers/!b\[printers\}' /etc/samba/smb.conf && \
sed -i '/\[printers\]/{:\[printers\];n;s/guest ok = no/guest ok = yes/g;/# printer drivers/!b\[printers\}' /etc/samba/smb.conf && \

echo "启动 smbd nmbd 服务"
sudo systemctl start smbd
sudo systemctl start nmbd

# 在启动时启用自动启动。
sudo systemctl restart smbd nmbd
echo "重启 cups avahi-daemon smbd nmbd 服务"
sudo systemctl enable cups avahi-daemon smbd nmbd

echo "重启 cups avahi-daemon smbd nmbd 服务"
sudo systemctl restart cups avahi-daemon smbd nmbd
echo "完成"
