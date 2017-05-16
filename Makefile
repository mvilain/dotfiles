# Makefile for dotfiles environment
# Maintainer Michael Vilain <michael@vilain.com> [201705.15]
# for some reason, conditional executes don't work on Ubuntu's make

.PHONY : build clean install

DOCKER_COMPOSE_URL = "https://github.com/docker/compose/releases/download/1.13.0/docker-compose-`uname -s`-`uname -m`"

IP = $(shell curl -m 2 -s -f http://169.254.169.254/latest/meta-data/public-ipv4)
ifeq ($(IP),)
IP = $(shell ifconfig -a | grep "inet " | grep "broadcast" | grep -Ev "172|127.0.0.1" | awk '{print $2}')
AWS = "n"
else
AZ = $(shell curl -m 2 -s -f http://169.254.169.254/latest/meta-data/placement/availability-zone)
endif

# centos or ubuntu (no others tested)
OS = $(shell grep '^ID=' /etc/os-release | sed -e 's/ID=//')

DOTFILES := .aliases .bash_profile .bash_prompt .bashrc .exports .exrc .forward .functions .inputrc .screenrc

TARGETS :=  install

all: $(TARGETS)

build: 
ifeq ($(OS),"centos")
	@echo -n "!!"
else ifeq ($(OS),ubuntu)
	@echo -n "!"
endif
	@echo $(OS)
	@echo $(IP)
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

git: git-install git-config
git-install:
ifeq ($(OS),"centos")
	-[ -e /bin/git ] && yum remove -y git
	-yum install -y https://centos7.iuscommunity.org/ius-release.rpm
	-yum install -y git2u
else ifeq ($(OS),ubuntu)
	-apt-get install -y git
endif

git-config: git
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

pkgs:
ifeq ($(OS),"centos")
	-yum install -y wget vim lsof bash-completion epel-release bind-utils gvim net-tools
else ifeq ($(OS),ubuntu)
	apt-get install -y curl vim lsof bash-completion dnsutils vim-gnome
endif

update:
ifeq ($(OS),"centos")
	-yum update -y
	-sed -i -e 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
	-sed -i -e 's/ rhgb quiet//' /etc/default/grub
	-grub2-mkconfig -o /boot/grub2/grub.cfg 
else ifeq ($(OS),ubuntu)
	-apt-get update && apt-get upgrade -y
endif


vbox:
ifeq ($(OS),"centos")
	-yum update kernel*
	-yum install -y dkms gcc make kernel-devel bzip2 binutils patch libgomp glibc-headers glibc-devel kernel-headers
else ifeq ($(OS),ubuntu)
	-apt-get update && apt-get -y upgrade
	-apt-get install -y build-essential module-assistant
endif
	-mount /dev/sr0 /mnt
	-cd /mnt && ./VBoxLinuxAdditions.run
	-echo "You can now reboot the system"

ntp: ntp-install ntp-config
ntp-install:
ifeq ($(OS),"centos")
	-yum install -y ntp
else ifeq ($(OS),ubuntu)
	-apt-get install -y ntp ntpdate ntp-doc
endif

ntp-config:
ifneq ($(AWS),"n")
	sed -i.orig -e "s/centos.pool/amazon.pool/g" /etc/ntp.conf # only if on AWS
endif
ifeq ($(OS),"centos")
	systemctl enable ntpd
	systemctl start ntpd
else ifeq ($(OS),ubuntu)
	systemctl enable ntp
	systemctl start ntp
endif
	timedatectl set-timezone America/Los_Angeles

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


# centos Mate and Gnome wont' resize with extentions installed
# http://jensd.be/125/linux/rel/install-mate-or-xfce-on-centos-7
gui:
ifeq ($(OS),"centos")
	yum groupinstall "X Window system"
	yum groupinstall "Xfce"
else ifeq ($(OS),ubuntu)
	apt-get update
	apt-get install xfce4
endif
	systemctl set-default graphical.target
	echo "reboot to start with GUI"

no-gui:
	systemctl set-default multi-user.target
	echo "reboot to start with without GUI"
