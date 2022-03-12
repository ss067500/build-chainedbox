#!/bin/bash
WORK_DIR=$(pwd)
origin="Rock64"
target="Chainedbox"

mount_point="tmp"

DTB=mods/boot
IDB=mods/loader/idbloader.bin
UBOOT=mods/loader/uboot.img
TRUST=mods/loader/trust.bin
UBOOT_WITH_FIP=mods/loader/btld-rk3328.bin
echo 当前工作目录："$WORK_DIR"
echo -e "01.01 读取镜像"
#设置镜像路径
imgdir=./build/output/images
imgfile="$(ls ${imgdir}/*.img)"
echo "找到镜像: $imgfile"

echo -e "01.02 识别镜像名称"
#获取镜像名称
imgname=`basename $imgfile`
echo "镜像名称: $imgname"
echo -e "完成"

echo -e "02.01 挂载镜像"

umount -f tmp
losetup -D
echo "挂载镜像 ... "
losetup -D
losetup -f -P ${imgfile}

BLK_DEV=$(losetup | grep "$imgname" | head -n 1 | gawk '{print $1}')
echo "挂载镜像成功 位置："${BLK_DEV}""

echo "设置卷标"
e2label ${BLK_DEV}p1 ROOTFS
tune2fs ${BLK_DEV}p1 -L ROOTFS

lsblk -l
mkdir -p ${WORK_DIR}/tmp
mount ${BLK_DEV}p1 ${WORK_DIR}/$mount_point
echo "挂载镜像根目录到 ${WORK_DIR}/$mount_point "

echo -e "完成"

echo -e "03.01 复制文件"
echo "复制文件"
cp -v ${WORK_DIR}/$DTB/*.dtb $mount_point/boot/
#cp -v ${WORK_DIR}/l1pro/install-docker.sh $mount_point/root/
#cp -v ${WORK_DIR}/l1pro/install-omv.sh $mount_point/root/
#cp -v ${WORK_DIR}/l1pro/pwm-fan.service $mount_point/etc/systemd/system/
#cp -v ${WORK_DIR}/l1pro/pwm-fan.pl $mount_point/usr/bin/ && chmod 700 $mount_point/usr/bin/pwm-fan.pl

echo -e "完成"



#echo "写入 bootloader ..."
#echo "dd if=${UBOOT_WITH_FIP}  of=${BLK_DEV} conv=fsync,notrunc bs=512 skip=1 seek=1"
#echo "dd if=${UBOOT_WITH_FIP}  of=${BLK_DEV} conv=fsync,notrunc bs=1 count=444"

#dd if=${UBOOT_WITH_FIP}  of=${BLK_DEV} conv=fsync,notrunc bs=512 skip=1 seek=1
#dd if=${UBOOT_WITH_FIP}  of=${BLK_DEV} conv=fsync,notrunc bs=1 count=444

sync
echo "完成"

cd ${WORK_DIR}

umount -f $mount_point

echo "添加引导项： idb,uboot,trust"

dd if=${IDB} of=${imgfile} seek=64 bs=512 conv=notrunc status=none && echo " ${IDB}" 写入到 ${imgfile} 成功 || { echo "idb patch 失败"; exit 1; }
dd if=${UBOOT} of=${imgfile} seek=16384 bs=512 conv=notrunc status=none && echo "${UBOOT}" 写入到 ${imgfile} 成功 || { echo "u-boot patch 失败"; exit 1; }
dd if=${TRUST} of=${imgfile} seek=24576 bs=512 conv=notrunc status=none && echo "${TRUST}" 写入到 ${imgfile} 成功 || { echo "trust patch 失败"; exit 1; }


imgname_new=`basename $imgfile | sed "s/${origin}/${target}/"`
echo "新文件名: $imgname_new"
mv $imgfile ${imgdir}/${imgname_new}
rm -rf ${tmpdir}


losetup -D
blkid
echo "ok"

