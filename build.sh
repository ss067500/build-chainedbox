#!/bin/bash

echo "初始化环境"
	sudo rm -rf /etc/apt/sources.list.d/* /usr/share/dotnet /usr/local/lib/android /opt/ghc
	sudo -E apt-get -qq update
	sudo -E apt-get -qq install $(curl -fsSL git.io/depends-ubuntu-2004)
	sudo -E apt-get -qq autoremove --purge
	sudo -E apt-get -qq clean
	sudo timedatectl set-timezone "$TZ"

echo "下载源代码"
	git clone --depth 1 https://github.com/armbian/build.git build
	sudo cp -r ./config ./build
	sudo cp -r ./userpatches ./build
	sed -i 's/0x9000000/0x39000000/' ./build/config/bootscripts/boot-rockchip64.cmd && \
	sed -i 's#${prefix}dtb/${fdtfile}#${prefix}/${fdtfile}#' ./build/config/bootscripts/boot-rockchip64.cmd && \
	sed -i 's/verbosity "1"/verbosity "7"/' ./build/config/bootscripts/boot-rockchip64.cmd && \
	sed -i '/setenv rootfstype "ext4"/a setenv rootflags "rw"' ./build/config/bootscripts/boot-rockchip64.cmd && \
	echo "查看 boot-rockchip64.cmd 内容"
	cat ./build/config/bootscripts/boot-rockchip64.cmd
	sed -i 's/verbosity=1/verbosity=7/' ./build/config/bootenv/rockchip.txt && \
	echo "extraargs=usbcore.autosuspend=-1" >> ./build/config/bootenv/rockchip.txt && \
	echo "extraboardargs=" >> ./build/config/bootenv/rockchip.txt && \
	echo "usbstoragequirks=0x05e3:0x0612:u,0x1d6b:0x0003:u,0x05e3:0x0610:u" >> ./build/config/bootenv/rockchip.txt
	echo "查看 rockchip.txt 内容"
	cat ./build/config/bootenv/rockchip.txt

echo "编译 Armbian "
	cd build/
	sudo chmod +x compile.sh
	sudo ./compile.sh BOARD=$1 BRANCH=$2  RELEASE=$3 BUILD_MINIMAL=no BUILD_DESKTOP=no BUILD_KSRC=yes INSTALL_KSRC=yes KERNEL_ONLY=no KERNEL_CONFIGURE=no BSPFREEZE=yes INSTALL_HEADERS=yes COMPRESS_OUTPUTIMAGE=img DOWNLOAD_MIRROR=tuna EXTRAWIFI=no
	
echo "打包 Armbian"
	# 编辑镜像
	sudo chmod +x ./rebuild.sh
	sudo ./rebuild.sh
	echo "镜像编辑完成"
	cd ./build/output/images/ && sudo gzip *.img

echo "完成"
	