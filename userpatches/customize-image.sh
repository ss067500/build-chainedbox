#!/bin/bash
#对镜像进行一些定制操作
wget -P /boot https://raw.githubusercontent.com/WingonWu/Chainedbox-build/main/mods/boot/rk3328-l1pro-1296mhz.dtb
wget -P/root https://raw.githubusercontent.com/WingonWu/Chainedbox-build/main/mods/root/install-cups.sh && chmod 755 /root/*.sh
wget -P/root https://raw.githubusercontent.com/WingonWu/Chainedbox-build/main/mods/root/install-docker.sh && chmod 755 /root/*.sh
wget -P/root https://raw.githubusercontent.com/WingonWu/Chainedbox-build/main/mods/root/install-omv.sh && chmod 755 /root/*.sh
wget -P/root https://raw.githubusercontent.com/WingonWu/Chainedbox-build/main/mods/root/install-zerotier.sh && chmod 755 /root/*.sh
#下载风扇服务
wget -P /etc/systemd/system https://raw.githubusercontent.com/WingonWu/Chainedbox-build/main/mods/pwm-fan.service
wget -P /usr/bin https://raw.githubusercontent.com/WingonWu/Chainedbox-build/main/mods/pwm-fan.pl && chmod 700 /usr/bin/pwm-fan.pl
#启动风扇服务
systemctl enable pwm-fan.service

#锁定内核文件，防止升级的时候 我家云 的专用内核被通用内核替换导致不开机 
apt-mark hold linux-dtb-legacy-rockchip64 linux-image-legacy-rockchip64 linux-dtb-current-rockchip64 linux-image-current-rockchip64 linux-dtb-edge-rockchip64 linux-image-edge-rockchip64


sed -i 's/ENABLED=true/#ENABLED=true/' /etc/default/armbian-zram-config
sed -i 's/ENABLED=true/#ENABLED=true/' /etc/default/armbian-ramlog
rm -f /etc/systemd/system/getty.target.wants/serial-getty\@ttyS2.service

#设置默认密码
echo root:1234 | chpasswd
#删除登录修改密码的选项
rm -f /root/.not_logged_in_yet
#删除时区
rm -rf /etc/localtime
#修改时区
echo "修改时区为东八区"
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
	dpkg-reconfigure --frontend noninteractive tzdata
echo Etc/UTC > /etc/timezone

# 修改 Hostname
#sed -i 's/Rock 64/Chainedbox/' /etc/armbian-image-release
#sed -i 's/rock64/Chainedbox/' /etc/armbian-image-release
#sed -i 's/rock64/Chainedbox/' /etc/armbian-release
#sed -i 's/Rock 64/Chainedbox/' /etc/armbian-release
#sed -i 's/rock64/Chainedbox/' /etc/hostname
#sed -i 's/rock64/Chainedbox/' /etc/host

#修改镜像源
echo "修改为国内软件源"
cat > /etc/apt/sources.list <<- EOF
deb [arch=arm64,armhf] https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
deb [arch=arm64,armhf] https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
deb [arch=arm64,armhf] https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free
deb [arch=arm64,armhf] https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free
EOF

cat > /etc/apt/sources.list.d/armbian.list <<- EOF
deb [arch=arm64,armhf] https://mirrors.tuna.tsinghua.edu.cn/armbian/ bullseye main bullseye-utils bullseye-desktop
EOF

#更新源
apt-get update&&apt-get -y upgrade

#清除安装包
apt-get clean

#关闭自动休眠,长时间不登录导致无法连上ssh,不知道是否有效，有待观察
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target sleep.targetsuspend.target

