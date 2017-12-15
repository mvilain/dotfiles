# Makefile for dotfiles environment
# Maintainer Michael Vilain <michael@vilain.com> [201710.10]
# 201712.14 added support for CentOS 6.9 + make 3.8.1

.PHONY : build clean install

DOCKER_COMPOSE_URL = "https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m`"

IP = $(shell curl -m 2 -s -f http://169.254.169.254/latest/meta-data/public-ipv4)
ifeq ($(IP),)
IP = $(shell ifconfig -a | grep "inet " | grep "broadcast" | grep -Ev "172|127.0.0.1" | awk '{print $2}')
AWS = "n"
else
AZ = $(shell curl -m 2 -s -f http://169.254.169.254/latest/meta-data/placement/availability-zone)
endif

# centos or ubuntu (no others tested)
# /etc/os-release doesn't exist on CentOS 6 but does on Ubuntu
# make 3.81 only tests for empty/non-empty string
REL = $(shell test -e /etc/os-release && echo "Y")
ifeq ($(REL),)
OS =  $(shell grep -q "CentOS release 6" /etc/redhat-release && echo "centos6")
else ifeq ($(REL),Y)
OS = $(shell test -e /etc/os-release && grep '^ID=' /etc/os-release | sed -e 's/ID=//')
endif

DOTFILES := .aliases .bash_profile .bash_prompt .bashrc .exports .exrc .forward \
	.functions .inputrc .screenrc .vimrc

# requires https://centos[67].iuscommunity.org/ius-release.rpm
C7_PKGS := wget vim lsof bash-completion epel-release bind-utils net-tools yum-utils
C6_PKGS := $(C7_PKGS) sudo
U_PKGS := curl vim lsof bash-completion dnsutils
PY_VER = 3.6.3

TARGETS :=  install

all: $(TARGETS)

build: 
#ifeq ($(OS),"centos6")
#	@echo "!!"
#else ifeq ($(OS),"centos")
#	@echo "!!!"
#else ifeq ($(OS),ubuntu)
#	@echo "!"
#endif
	@echo "/etc/os-release exists? " $(REL)
	@echo "OS = " $(OS)
	@echo "IP = " $(IP)
	@echo "docker-compose = " $(DOCKER_COMPOSE_URL)
	@echo "logname =" $(LOGNAME) " sudo_user=" $(SUDO_USER)

clean: 

install : ntp files pkgs

files: $(DOTFILES)
	/bin/cp -v $(DOTFILES) ${HOME}/
ifneq ($(SUDO_USER),)
	echo "$(SUDO_USER) ALL = NOPASSWD: ALL" > /etc/sudoers.d/$(SUDO_USER)
else
	echo "$(LOGNAME) ALL = NOPASSWD: ALL" > /etc/sudoers.d/$(LOGNAME)
endif

# prerequisite for git2u and python36u
pkgs:
ifeq ($(OS),centos6)
	-yum install -y $(C7_PKGS)
	-yum install -y https://centos6.iuscommunity.org/ius-release.rpm
else ifeq ($(OS),centos)
	-yum install -y $(C6_PKGS)
	-yum install -y https://centos7.iuscommunity.org/ius-release.rpm
else ifeq ($(OS),ubuntu)
	apt-get install -y $(U_PKGS)
endif

update:
ifeq ($(OS),centos)
	-yum update -y
	-sed -i -e 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
	-sed -i -e 's/ rhgb quiet//' /etc/default/grub
	-grub2-mkconfig -o /boot/grub2/grub.cfg
else ifeq ($(OS),centos6)
	-yum update -y
	-sed -i -e 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
	-sed -i -e 's/ rhgb quiet//' /boot/grub/grub.conf
else ifeq ($(OS),ubuntu)
	-apt-get update && apt-get upgrade -y
endif


git: git-install git-config

git-install:
ifeq ($(OS),centos)
	-yum install -y git
else ifeq ($(OS),centos6)
	-yum install  -y git
else ifeq ($(OS),ubuntu)
	-apt-get install -y git
endif

git2: pkgs
ifeq ($(OS),centos)
	-yum remove -y git
	-yum install -y git2u
else ifeq ($(OS),centos6)
	-yum remove -y git
	-yum install  -y git2u
endif


git-config:
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
ntp-install:
ifeq ($(OS),centos)
	-yum install -y ntp
else ifeq ($(OS),centos6)
	-yum install -y ntp
else ifeq ($(OS),ubuntu)
	-apt-get install -y ntp ntpdate ntp-doc
endif

ntp-config:
ifneq ($(AWS),"n")
	sed -i.orig -e "s/centos.pool/amazon.pool/g" /etc/ntp.conf # only if on AWS
endif
ifeq ($(OS),centos6)
	chkconfig --level 2 --level 3 ntpd on
	service ntpd start
	#[ ! -e /etc/localtime.orig ] && mv /etc/localtime /etc/localtime.orig
	# ln -s /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
else ifeq ($(OS),centos)
	systemctl enable ntpd
	systemctl start ntpd
	timedatectl set-timezone America/Los_Angeles
else ifeq ($(OS),ubuntu)
	systemctl enable ntp
	systemctl start ntp
	timedatectl set-timezone America/Los_Angeles
endif


# centos7 Mate and Gnome won't resize with extensions installed
# http://jensd.be/125/linux/rel/install-mate-or-xfce-on-centos-7
# 5/16/17 epel's xfce seems to be broken requiring wrong version
# skip-broken fixes this temporarily
gui:
ifeq ($(OS),centos)
	yum groupinstall -y "X Window system"
	yum groupinstall -y "Xfce" --skip-broken
	yum install -y firefox gvim
	systemctl set-default graphical.target
else ifeq ($(OS),centos6)
	yum groupinstall -y "X Window system"
	yum groupinstall -y "Xfce" --skip-broken
	yum install -y firefox gvim
else ifeq ($(OS),ubuntu)
	apt-get update
	apt-get install -y xfce4 vim-gnome
	systemctl set-default graphical.target
endif
	@echo "reboot to start with GUI"

no-gui:
ifeq ($(OS),centos)
	systemctl set-default multi-user.target
	echo "reboot to start with without GUI"
else ifeq ($(OS),ubuntu)
	systemctl set-default multi-user.target
	echo "reboot to start with without GUI"
endif

# Centos assumes installed w/o GUI at command line
# ubunut assumes installed on top of GUI with mount point
vbox:
ifeq ($(OS),centos)
	-yum update kernel*
	-yum install -y dkms gcc make kernel-devel bzip2 binutils patch libgomp glibc-headers glibc-devel kernel-headers
	-mount /dev/sr0 /mnt
	-cd /mnt && ./VBoxLinuxAdditions.run
else ifeq ($(OS),ubuntu)
	-apt-get update && apt-get -y upgrade
	-apt-get install -y build-essential module-assistant
	-cd /media/mivilain/VBOXADDITIONS_5.1.22_115126 && ./VBoxLinuxAdditions.run
endif
	@echo "You can now reboot the system"


python3: pkgs
ifeq ($(OS),centos)
	-yum install -y python2-pip
	-easy_install pip
	-yum install -y python36u python36u-setuptools python36u-pip
else ifeq ($(OS),centos6)
	-yum install -y python27 python27-pip python27-setuptools
	-yum install -y python36u python36u-setuptools python36u-pip
endif


# ubuntu 17.10 has python3 already installed
python3u:
ifeq ($(OS),ubuntu)
	apt-get install gcc libssl-dev make build-essential libssl-dev zlib1g-dev libbz2-dev libsqlite3-dev
	-wget https://www.python.org/ftp/python/$(PY_VER)/Python-$(PY_VER).tgz
	-tar -xzf Python-$(PY_VER).tgz
	-cd Python-$(PY_VER) && ./configure && make altinstall
	-rm Python-$(PY_VER).tgz
endif
