# Makefile for dotfiles environment
# Maintainer Michael Vilain <michael@vilain.com>
# 201712.14 added support for CentOS 6.9 + make 3.8.1
# 201712.23 added support for Fedora 27
# 201912.15 updated docker-compose and added CentOS 8
# 202001.18 fixed time destination
# 202001.26 added git.core editor
# 202002.15 update docker-compose url+fix if block tests
# 202002.17 add Debian and OpenSuse support
# 203005.01 fix CentOS 8

.PHONY : test clean install

DOCKER_COMPOSE_URL = "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose"

# vanilla debian 10 doesn't have curl or net-tools' ifconfig installed out of the box
IP = $(shell test -e /usr/bin/curl && curl -m 2 -s -f http://169.254.169.254/latest/meta-data/public-ipv4)
ifeq ($(IP),)
#IP = $(shell ifconfig -a | grep -i "BROADCAST,RUNNING" -A2 | grep 'inet ' | sed -e 's/ netmask.*//i' -e 's/.*inet //')
IP = $(shell ip addr | grep -i "BROADCAST,MULTICAST,UP," -A2 | grep 'inet ' | sed -e 's@/24 .*@@' -e 's/.*inet //')
AWS = "n"
else
AZ = $(shell curl -m 2 -s -f http://169.254.169.254/latest/meta-data/placement/availability-zone)
endif

# centos or ubuntu (no others tested)
# /etc/os-release doesn't exist on CentOS 6 but does on CentOS 7+8, Ubuntu, and Debian
# make 3.81 only tests for empty/non-empty string
# returns OS=fedora
REL = $(shell test -e /etc/os-release && echo "Y")
ifeq ($(REL),)
OS =  $(shell grep -q "CentOS release 6" /etc/redhat-release && echo "centos6")
else ifeq ($(REL),Y)
ID = $(shell awk '/^ID=/{print $1}' /etc/os-release | sed -e "s/ID=//" -e "s/-leap//" -e "s/open//")
VER = $(shell grep "VERSION_ID" /etc/os-release | sed -e 's/VERSION_ID=//' -e 's/"//g')
OS = $(ID)$(VER)
endif


DOTFILES := .aliases .bash_profile .bash_prompt .bashrc .exports .exrc .forward \
	.functions .inputrc .screenrc .vimrc

RHEL_PKGS := wget vim lsof bash-completion bind-utils net-tools
C8_PKGS := $(RHEL_PKGS) yum-utils epel-release 
C7_PKGS := $(RHEL_PKGS) yum-utils epel-release 
C6_PKGS := $(RHEL_PKGS) yum-utils epel-release sudo
F_PKGS := $(RHEL_PKGS) dnf-utils
U_PKGS := curl vim lsof bash-completion dnsutils
D_PKGS := $(U_PKGS) sudo rsync net-tools open-vm-tools
S_PKGS = wget vim lsof bash-completion bind-utils net-tools
PY_VER = 3.6.3

TARGETS :=  install

all: $(TARGETS)

test: 
	@echo "/etc/os-release exists? " $(REL)
	@echo "ID="$(ID)   "VER="$(VER)  "OS="$(OS)
	@echo "IP="$(IP)
	@echo "docker-compose: "$(DOCKER_COMPOSE_URL)
	@echo "logname:" $(LOGNAME) " sudo_user:" $(SUDO_USER)

clean: 

install: files packages

files: $(DOTFILES)
	/bin/cp -v $(DOTFILES) ${HOME}/
ifneq ($(SUDO_USER),)
	echo "$(SUDO_USER) ALL = NOPASSWD: ALL" > /etc/sudoers.d/$(SUDO_USER)
else
	@echo '***Append as root***  echo "$(LOGNAME) ALL = NOPASSWD: ALL" > /etc/sudoers.d/$(LOGNAME)'
endif

# requires https://centos[678].iuscommunity.org/ius-release.rpm
# prerequisite for centos git2u and python36u
packages:
	@echo $(OS)
ifeq ($(OS),"centos6")
	yum install -y $(C6_PKGS)
	yum install -y https://centos6.iuscommunity.org/ius-release.rpm

else ifeq ($(OS),"centos7")
	yum install -y $(C7_PKGS)
	yum install -y https://centos7.iuscommunity.org/ius-release.rpm

else ifeq ($(OS),"centos8")
	yum install -y $(C8_PKGS)
	#yum install -y https://centos8.iuscommunity.org/ius-release.rpm

else ifeq ($(ID),fedora)
	dnf install -y $(F_PKGS)

else ifeq ($(ID),ubuntu)
	apt-get install -y $(U_PKGS)

else ifeq ($(ID),debian)
	apt-get install -y $(D_PKGS)

else ifeq ($(ID),"suse")
	zypper --non-interactive install $(S_PKGS)
endif


update:
ifeq ($(OS),"centos6")
	-yum update -y
	-sed -i -e 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
	-sed -i -e 's/ rhgb quiet//' /boot/grub/grub.conf
else ifeq ($(OS),"centos7")
	-yum update -y
	-sed -i -e 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
	-sed -i -e 's/ rhgb quiet//' /etc/default/grub
	-grub2-mkconfig -o /boot/grub2/grub.cfg
else ifeq ($(OS),"centos8")
	-yum update -y
	-sed -i -e 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
	-sed -i -e 's/ rhgb quiet//' /etc/default/grub
	-grub2-mkconfig -o /boot/grub2/grub.cfg
else ifeq ($(ID),fedora)
	-dnf update -y
	-sed -i -e 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
	-sed -i -e 's/ rhgb quiet//' /etc/default/grub
	-grub2-mkconfig -o /boot/grub2/grub.cfg
else ifeq ($(ID),ubuntu)
	-apt-get update && apt-get upgrade -y
else ifeq ($(ID),debian)
	-apt-get update && apt-get upgrade -y
else ifeq ($(ID),"suse")
	-sed -i.orig -e 's/splash=silent/splash=verbose/' /etc/default/grub
	-grub2-mkconfig -o /boot/grub2/grub.cfg
	zypper up
endif


# fedora 27 already has git 2.x installed
git : git-install git-config

git-install:
ifeq ($(OS),"centos6")
	-yum install  -y git
else ifeq ($(OS),"centos7")
	-yum install -y git
else ifeq ($(ID),fedora)
	-dnf install -y git
# 	-git --version
# 	-echo "git 2.x already installed"
else ifeq ($(ID),ubuntu)
	-apt-get install -y git
else ifeq ($(ID),debian)
	-apt-get install -y git
else ifeq ($(ID),"suse")
	-zypper --non-interactive install git
endif

git2: packages
ifeq ($(OS),"centos6")
	-yum remove -y git
	-yum install  -y git2u
else ifeq ($(OS),"centos7")
	-yum remove -y git
	-yum install -y git2u
endif


git-config: git-install
	git config --global user.name "Michael Vilain"
	git config --global user.email "michael@vilain.com"
	git config --global color.ui true
	git config --global push.default simple
	git config --global alias.st status 
	git config --global alias.co checkout 
	git config --global alias.br branch 
	git config --global alias.cl commit 
	git config --global alias.origin "remote show origin"
	git config --global alias.mylog "log --pretty = format:'%h %s [%an]' --graph" 
	git config --global alias.lol "log --graph --decorate --pretty=oneline --abbrev-commit --all"


# must be run as root or it won't install
docker:
	if [ ! -e /bin/docker ]; then \
		curl -fsSL https://get.docker.com/ | sh; \
		curl -L $(DOCKER_COMPOSE_URL) > /usr/local/bin/docker-compose; \
		chmod +x /usr/local/bin/docker-compose; \
		sed -i -e "/^MountFlags/d" /lib/systemd/system/docker.service; \
		systemctl enable docker; \
		systemctl daemon-reload; \
		systemctl start docker; \
	fi
ifneq ($(SUDO_USER),)
	usermod -aG docker $(SUDO_USER)
endif

ntp: ntp-install ntp-config
ntp-install :
ifeq ($(OS),"centos6")
	-yum install -y ntp
	-yum install -y ntp
else ifeq ($(OS),"centos7")
	-yum install -y ntp
else ifeq ($(OS),"centos8")
	-yum install -y chrony
else ifeq ($(ID),fedora)
	-dnf install -y ntp
else ifeq ($(ID),ubuntu)
	-apt-get install -y ntp ntpdate ntp-doc
else ifeq ($(ID),debian)
	-apt-get install -y ntp ntpdate ntp-doc
else ifeq ($(ID),"suse")
	echo use "chronyc sources"
endif

ntp-config :
ifneq ($(AWS),"n")
	sed -i.orig -e "s/centos.pool/amazon.pool/g" /etc/ntp.conf # only if on AWS
endif
ifeq ($(OS),"centos6")
	chkconfig --level 2 --level 3 ntpd on
	service ntpd start
	#[ ! -e /etc/localtime.orig ] && mv /etc/localtime /etc/localtime.orig
	# ln -s /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
else ifeq ($(OS),"centos7")
	systemctl enable ntpd
	systemctl start ntpd
	timedatectl set-timezone America/Los_Angeles
else ifeq ($(OS),"centos8")
	systemctl enable chronyd
	systemctl start chronyd
	timedatectl set-timezone America/Los_Angeles
else ifeq ($(ID),fedora)
	systemctl enable ntpd
	systemctl start ntpd
	timedatectl set-timezone America/Los_Angeles
else ifeq ($(ID),ubuntu)
	systemctl enable ntp
	systemctl start ntp
	timedatectl set-timezone America/Los_Angeles
else ifeq ($(ID),debian)
	systemctl enable ntp
	systemctl start ntp
	timedatectl set-timezone America/Los_Angeles
else ifeq ($(ID),"suse")
	systemctl status chronyd
	systemctl start chronyd
	timedatectl set-timezone America/Los_Angeles
	chronyc sources
endif


# centos7 Mate and Gnome won't resize with extensions installed
# http://jensd.be/125/linux/rel/install-mate-or-xfce-on-centos-7
# 5/16/17 epel's xfce seems to be broken requiring wrong version
# skip-broken fixes this temporarily
gui :
ifeq ($(OS),"centos7")
	yum groupinstall -y "X Window system"
	yum groupinstall -y "Xfce" --skip-broken
	yum install -y firefox gvim
	systemctl set-default graphical.target
else ifeq ($(OS),"centos6")
	yum groupinstall -y "X Window system"
	yum groupinstall -y "Xfce" "Fonts" --skip-broken
	yum install -y firefox gvim xorg-x11-fonts-Type1 xorg-x11-fonts-misc
	sed -i.mu3 -e "s/id:3/id:5/" /etc/inittab
else ifeq ($(ID),fedora)
	dnf install -y @xfce-desktop-environment
	dnf install -y firefox gvim
	systemctl set-default graphical.target
	systemctl enable lightdm.service
else ifeq ($(ID),ubuntu)
	apt-get update
	apt-get install -y xfce4 vim-gnome
	systemctl set-default graphical.target
else ifeq ($(ID),debian)
	apt-get update
	apt-get install -y xfce4 vim-gtk3
	systemctl set-default graphical.target
else ifeq ($(ID),"suse")
	-zypper -n in patterns-openSUSE-xfce
	-zypper --non-interactive install gvim
	systemctl set-default graphical.target
endif
	@echo "reboot to start with GUI"

no-gui:
ifeq ($(OS),"centos6")
	sed -i.x11 -e "s/id:5/id:3/" /etc/inittab
else ifeq ($(OS),"centos7")
	systemctl set-default multi-user.target
else ifeq ($(ID),fedora)
	systemctl set-default multi-user.target
	systemctl disable lightdm.service
else ifeq ($(ID),ubuntu)
	systemctl set-default multi-user.target
else ifeq ($(ID),debian)
	systemctl set-default multi-user.target
else ifeq ($(ID),"suse")
	systemctl set-default multi-user.target
endif
	@echo "reboot to start with without GUI"

# Centos assumes installed w/o GUI at command line
# ubunut assumes installed on top of GUI with mount point
vbox:
ifeq ($(OS),"centos7")
	-yum update kernel*
	-yum install -y dkms gcc make kernel-devel bzip2 binutils patch libgomp glibc-headers glibc-devel kernel-headers
	-mount /dev/sr0 /mnt
	-cd /mnt && ./VBoxLinuxAdditions.run
	@echo "You can now reboot the system"
else ifeq ($(ID),ubuntu)
	-apt-get update && apt-get -y upgrade
	-apt-get install -y build-essential module-assistant
	-cd /media/mivilain/VBOXADDITIONS_5.1.22_115126 && ./VBoxLinuxAdditions.run
	@echo "You can now reboot the system"
endif


python3: packages
ifeq ($(OS),"centos6")
	-yum install -y python27 python27-pip python27-setuptools
	-yum install -y python36u python36u-setuptools python36u-pip
else ifeq ($(OS),"centos7")
	-yum install -y python2-pip
	-easy_install pip
	-yum install -y python36u python36u-setuptools python36u-pip
endif


# ubuntu 17.10+, fedora 27, debian 10, and opensuse-leap has python3
python3u:
ifeq ($(ID),ubuntu)
	apt-get install gcc libssl-dev make build-essential libssl-dev zlib1g-dev libbz2-dev libsqlite3-dev
	-wget https://www.python.org/ftp/python/$(PY_VER)/Python-$(PY_VER).tgz
	-tar -xzf Python-$(PY_VER).tgz
	-cd Python-$(PY_VER) && ./configure && make altinstall
	-rm Python-$(PY_VER).tgz
endif
