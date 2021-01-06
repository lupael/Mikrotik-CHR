#!/bin/bash
#
# Digital Ocean Ubuntu 18.04 x64 Droplet
# Running:
# git clone https://gist.github.com/2ed28799efa38ca79b00dd700c56c0e6.git
# cd 2ed28799efa38ca79b00dd700c56c0e6/
# chmod +x make-chr.sh
# ./make-chr.sh
#
# Once the reboot is done, login with root/CHANGEME and change the password!
# You might get a "Segmentation fault" on line 56 while the image is being written.
# Most of the time this is absolutely fine. Reboot the droplet and attempt to login using Winbox.
# If it didn't work, just trash the droplet and try it again.
#
wget http://download2.mikrotik.com/routeros/6.37/chr-6.37.img.zip -O chr.img.zip  && \
gunzip -c chr.img.zip > chr.img  && \
apt-get update && \
apt install -y qemu-utils pv && \
qemu-img convert chr.img -O qcow2 chr.qcow2 && \
qemu-img resize chr.qcow2 1073741824 && \
modprobe nbd && \
qemu-nbd -c /dev/nbd0 chr.qcow2 && \
echo "Give some time for qemu-nbd to be ready" && \
sleep 2 && \
partprobe /dev/nbd0 && \
sleep 5 && \
mount /dev/nbd0p2 /mnt && \
ADDRESS=`ip addr show eth0 | grep global | cut -d' ' -f 6 | head -n 1` && \
GATEWAY=`ip route list | grep default | cut -d' ' -f 3` && \
PASSWORD="CHANGEME" && \
echo "/ip address add address=$ADDRESS interface=[/interface ethernet find where name=ether1]
/ip route add gateway=$GATEWAY
/ip service disable telnet
/user set 0 name=root password=$PASSWORD
/ip dns set servers=1.1.1.1,1.0.0.1
/system package update install
 " > /mnt/rw/autorun.scr && \
umount /mnt && \
echo "Magic constant is 65537 (second partition address). You can check it with fdisk before appliyng this" && \
echo "This scary sequence removes seconds partition on nbd0 and creates new, but bigger one" && \
echo -e 'd\n2\nn\np\n2\n65537\n\nw\n' | fdisk /dev/nbd0 && \
e2fsck -f -y /dev/nbd0p2 || true && \
resize2fs /dev/nbd0p2 && \
sleep 1 && \
echo "Compressing to gzip, this can take several minutes" && \
mount -t tmpfs tmpfs /mnt && \
pv /dev/nbd0 | gzip > /mnt/chr-extended.gz && \
sleep 1 && \
killall qemu-nbd && \
sleep 1 && \
echo u > /proc/sysrq-trigger && \
echo "Warming up sleep" && \
sleep 1 && \
echo "Writing raw image, this will take time" && \
zcat /mnt/chr-extended.gz | pv > /dev/vda && \
echo "Don't forget your password: $PASSWORD" && \
echo "Sleep 5 seconds (if lucky)" && \
sleep 5 || true && \
echo "sync disk" && \
echo s > /proc/sysrq-trigger && \
echo "Ok, reboot" && \
echo b > /proc/sysrq-trigger
