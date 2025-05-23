#!/usr/bin/env make
# Makefile for dotfiles environment
# Maintainer Michael Vilain <michael@vilain.com>
# 201712.14 added support for CentOS 6.9 + make 3.8.1
# 201712.23 added support for Fedora 27
# 201912.15 updated docker-compose and added CentOS 8
# 202001.18 fixed time destination
# 202001.26 added git.core editor
# 202002.15 update docker-compose url+fix if block tests
# 202002.17 add Debian and OpenSuse support
# 202005.11 fix CentOS eval of $(OS); add tar to CentOS 8 packages
# 202006.27 update current version of docker-compose; add notes for CentOS 8.2
# 202011.18 change docker to use RPMs; docker compose 1.26 -> 1.27.4
# 202107.13 updated docker compose; added additional support for OpenSUSE
# 202108.22 add dev target for developer tools
# 202108.23 add alma and rocky targets
# 202201.07 added git pager config
# 202202.01 added gitpager to config
# 202202.27 add support for zsh install; updated docker compose release; update .vimrc+.inputs; add .osx config script
# 202207.09 added zsh config for Kali linux but default is still ohmyzsh's config; added candy.zsh-theme
# 202303.02 added interactive_git_rebase to toolchain
# 202303.22 change git l1 output format
# 202309.18 update zorin 16.3 uses chronyd instead of ntpd
# 202309.21 change zorin to use chrony instead of ntpd
# 202311.18 alama9 update fix grub update
# 202312.11 add git merge style for git 2.35+
# 202402.17 add git config options
# 202405.16 makefile sections should be indented with at least a tab. 2 spaces won't work
# 202407.03 removed interactive_rebase_tool from .gitconfig; remove vim-go; git merge zdiff3 --> diff3
# 202407.07 add github username; change git l1 alias
# 202505.12 add ngrep to required packages; remove open-vm-tools

.PHONY : test clean install

DOCKER_COMPOSE_URL = "https://github.com/docker/compose/releases/tag/2.2.3/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose"

# vanilla debian 10 doesn't have curl or
#         net-tools' ifconfig installed out of the box
IP := $(shell test -e /usr/bin/curl && curl -m 2 -s -f http://169.254.169.254/latest/meta-data/public-ipv4)
ifeq ($(strip $(IP)),)
# works on Linux ip addr command
IP := $(shell ip addr | grep -i "BROADCAST,MULTICAST,UP," -A2 | grep 'inet ' | sed -e 's@/24 .*@@' -e 's/.*inet //')
# works on MacOS ip addr command
ifeq ($(strip $(IP)),)
IP := $(shell ip addr | grep -i "8863<UP,BROADCAST,SMART,RUNNING" -A7 | grep 'inet ' | sed -e 's@/24 .*@@' -e 's/.*inet //')
endif
AWS := "n"
else
AZ := $(shell curl -m 2 -s -f http://169.254.169.254/latest/meta-data/placement/availability-zone)
endif

# centos or ubuntu (no others tested)
# /etc/os-release doesn't exist on CentOS 6 or MacOS but does on CentOS 7+8, Ubuntu, and Debian
# uname -s returns "Darwin|Linux"; OSX="Y" or blank if not OSX
# sw_vers gives different names in older version, so make sure they're all the same for testing
# make 3.81 only tests for empty/non-empty string
# returns OS=fedora
OSX := $(shell uname -s | sed -e 's/Darwin/Y/' -e 's/Linux//')
ifeq ($(OSX),Y)
ID := "macos"
VER := $(shell sw_vers -productVersion)
OS := $(ID) $(VER)

else ifeq ($(strip $(OSX)),)
REL := $(shell test -e /etc/os-release && echo "Y")
ifeq ($(strip $(REL)),)
OS=$(shell grep -q "CentOS release 6" /etc/redhat-release && echo "centos6")
ID := "centos"
VER := "6"

else ifeq ($(REL),Y)
ID := $(shell awk '/^ID=/{print $1}' /etc/os-release | sed -e "s/ID=//" -e "s/-leap//" -e "s/open//" -e 's/"//g')
VER = $(shell grep "VERSION_ID" /etc/os-release | sed -e 's/VERSION_ID=//' -e 's/"//g')
OS := $(ID)$(VER)
endif
endif


DOTFILES := .aliases .bash_profile .bash_prompt .bashrc .exports .exrc .forward \
	.functions .inputrc .screenrc .vimrc .zshrc .zshrc-ohmyzsh.sh .zshrc-kali.sh

RHEL_PKGS := wget vim lsof bind-utils net-tools yum-utils epel-release ngrep
C6_PKGS := $(RHEL_PKGS)
C7_PKGS := $(RHEL_PKGS) bash-completion
C8_PKGS := $(RHEL_PKGS) bash-completion tar python38
F_PKGS := $(RHEL_PKGS) dnf-utils
U_PKGS := curl vim lsof bash-completion dnsutils ngrep
D_PKGS := $(U_PKGS) sudo rsync net-tools 
S_PKGS := wget vim lsof bash-completion bind-utils net-tools ngrep
# used for installing from scratch on Ubuntu python3u recipe
PY_VER := 3.8.2
# used for installing git from scratch
GIT_VER := 2.37.0
GIT_DEV_RPM_PKGS := automake curl-devel gettext-devel openssl-devel perl-CPAN perl-devel zlib-devel wget
GIT_DEV_DEB_PKGS := build-essential autoconf libghc-zlib-dev libssl-dev libcurl4-gnutls-dev lib-expat1-dev gettext

TARGETS :=  install

all: $(TARGETS)

test:
# 	@echo "/etc/os-release exists?  $(REL)"
	@echo "ID=<$(ID)>  VER=<$(VER)>  OS=<$(OS)>"
	@echo "IP=$(IP)"
	@echo "docker-compose: $(DOCKER_COMPOSE_URL)"
	@echo "logname: $(LOGNAME)  sudo_user: $(SUDO_USER)"
# ------------------------------------------------------------------------ RHEL distros
ifeq ($(ID),almalinux)
	@echo "packages= $(C8_PKGS)"
else ifeq ($(OS),centos6)
	@echo "packages= $(C6_PKGS)"
else ifeq ($(OS),centos7)
	@echo "packages= $(C7_PKGS)"
else ifeq ($(OS),centos8)
	@echo "packages= $(C8_PKGS)"
else ifeq ($(ID),fedora)
	@echo "packages= $(F_PKGS)"
else ifeq ($(ID),rocky)
	@echo "packages= $(C8_PKGS)"
# ------------------------------------------------------------------------ DEBIAN distros
else ifeq ($(ID),ubuntu)
	@echo "packages= $(U_PKGS)"
else ifeq ($(ID),debian)
	@echo "packages= $(D_PKGS)"
else ifeq ($(ID),"suse")
	@echo "packages= $(S_PKGS)"
else ifeq ($(ID),zorin)
	@echo "packages= $(U_PKGS)"
# else
# 	@echo "packages="
endif


clean:

install: files

files: $(DOTFILES)
	/bin/cp -v $(DOTFILES) ${HOME}/
ifneq ($(SUDO_USER),)
	echo "$(SUDO_USER) ALL = NOPASSWD: ALL" > /etc/sudoers.d/$(SUDO_USER)
else
	@echo '***Append as root***  echo "$(LOGNAME) ALL = NOPASSWD: ALL" > /etc/sudoers.d/$(LOGNAME)'
endif

# requires https://centos[67].iuscommunity.org/ius-release.rpm
# prerequisite for centos git2u and python36
packages:
	@echo '<$(OS)>'
# ------------------------------------------------------------------------ RHEL distros
ifeq ($(ID),almalinux)
	-yum install -y $(C8_PKGS)
else ifeq ($(OS),centos6)
	-yum install -y $(C6_PKGS)
else ifeq ($(OS),centos7)
	-yum install -y $(C7_PKGS)
	-yum install -y https://repo.ius.io/ius-release-el7.rpm
	-yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
else ifeq ($(OS),centos8)
	-yum install -y $(C8_PKGS)
else ifeq ($(ID),fedora)
	-dnf install -y $(F_PKGS)
else ifeq ($(ID),rocky)
	-yum install -y $(C8_PKGS)
# ------------------------------------------------------------------------ DEBIAN distros
else ifeq ($(ID),ubuntu)
	-apt-get install -y $(U_PKGS)
else ifeq ($(ID),debian)
	-apt-get install -y $(D_PKGS)
else ifeq ($(ID),suse)
	-zypper --non-interactive install $(S_PKGS)
else ifeq ($(ID),zorin)
	-apt-get install -y $(D_PKGS)
else
	@echo "can't evaluate OS"
endif


update:
# ------------------------------------------------------------------------ RHEL distros
ifeq ($(ID),almalinux)
	-yum update -y
	-sed -i -e 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
	-sed -i -e 's/ rhgb quiet//' /etc/default/grub.cfg
	-grub2-mkconfig -o /boot/grub2/grub.cfg
else ifeq ($(OS),centos6)
	-yum update -y
	-sed -i -e 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
	-sed -i -e 's/ rhgb quiet//' /boot/grub/grub.conf
else ifeq ($(OS),centos7)
	-yum update -y
	-sed -i -e 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
	-sed -i -e 's/ rhgb quiet//' /etc/default/grub
	-grub2-mkconfig -o /boot/grub2/grub.cfg
else ifeq ($(OS),centos8)
	-yum update -y
	-sed -i -e 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
	-sed -i -e 's/ rhgb quiet//' /etc/default/grub
	-grub2-mkconfig -o /boot/grub2/grub.cfg
else ifeq ($(ID),fedora)
	-dnf update -y
	-sed -i -e 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
	-sed -i -e 's/ rhgb quiet//' /etc/default/grub
	-grub2-mkconfig -o /boot/grub2/grub.cfg
else ifeq ($(ID),rocky)
	-yum update -y
	-sed -i -e 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
	-sed -i -e 's/ rhgb quiet//' /etc/default/grub
	-grub2-mkconfig -o /boot/grub2/grub.cfg
# ------------------------------------------------------------------------ DEBIAN distros
else ifeq ($(ID),ubuntu)
	-apt-get update && apt-get upgrade -y
else ifeq ($(ID),debian)
	-apt-get update && apt-get upgrade -y
else ifeq ($(ID),suse)
	-sed -i.orig -e 's/splash=silent/splash=verbose/' /etc/default/grub
	-grub2-mkconfig -o /boot/grub2/grub.cfg
	-zypper up
else ifeq ($(ID),zorin)
	-apt-get update && apt-get upgrade -y
endif


# fedora 27 and centos8 already has git 2.x installed
git : git-install git-config

git-install:
# ------------------------------------------------------------------------ RHEL distros
ifeq ($(OS),almalinux)
	-yum install -y git
else ifeq ($(OS),centos6)
	-yum install  -y git
else ifeq ($(OS),centos7)
	-yum install -y git
else ifeq ($(OS),centos8)
	-yum install -y git
else ifeq ($(ID),fedora)
	-dnf install -y git
# 	-git --version
# 	-echo "git 2.x already installed"
else ifeq ($(ID),rocky)
	-yum install -y git
# ------------------------------------------------------------------------ DEBIAN distros
else ifeq ($(ID),ubuntu)
	-apt-get install -y git
else ifeq ($(ID),debian)
	-apt-get install -y git
else ifeq ($(ID),suse)
	-zypper --non-interactive install git
else ifeq ($(ID),zorin)
	-apt-get install -y git
endif

git2: packages
ifeq ($(OS),centos6)
	-yum remove -y git
	-yum install  -y git2u-all
else ifeq ($(OS),centos7)
	-yum remove -y git
	-yum install -y https://repo.ius.io/ius-release-el7.rpm \
		https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	-yum install -y git2u
endif


# https://git-scm.com/docs/git-config
git-config: git-install
	git config --global user.name "Michael Vilain"
	git config --global user.email "michael@vilain.com"
	git config --global user.username "mvilain"
	git config --global color.ui true
	#git config --global --replace-all core.pager "less -F -X"
	git config --global core.pager ''

	# https://stackoverflow.com/questions/71252026/how-do-i-use-zealous-diff3-with-git-and-what-are-the-pros-and-cons
	git config --global merge.conflictStyle diff3

	# https://jvns.ca/blog/2024/02/16/popular-git-config-options
	git config --global pull.rebase true
	git config --global rebase.autosquash true
	git config --global init.defaultBranch main
	git config --global commit.verbose true
	git config --global diff.algorithm histogram

	# https://stackoverflow.com/questions/1441156/git-how-to-save-a-preset-git-log-format
	git config --global pretty.mev1 "%Cred%h%Creset [%an %Cgreen%as%Creset] %s"
	git config --global pretty.mev2 "%Cred%h%Creset %Cgreen[%as]%Creset %s"
	git config --global pretty.mev-long "%Cred%h%Creset -%d %s %Cgreen(%cr) %C(bold blue)<%an>%Creset"
	git config --global alias.ll 'log --graph --pretty=mev-long --abbrev-commit'
	git config --global alias.mylog 'log --pretty=mev1 --graph --date=short --graph'
	git config --global alias.l1 'log -30 --decorate --pretty=mev2 --abbrev-commit'

	git config --global push.default simple
	git config --global alias.st status
	git config --global alias.co checkout
	git config --global alias.br branch
	git config --global alias.c commit
	git config --global alias.ca commit -a
	git config --global alias.cam commit -am
	git config --global alias.d diff
	git config --global alias.dc diff --cached
	git config --global alias.origin 'remote show origin'


# must be run as root or it won't install
# don't use recommended repository because that's OS-dependent...use script
docker:
	if [ ! -e /bin/docker ]; then \
		curl -fsSL https://get.docker.com/ | sh; \
		curl -L $(DOCKER_COMPOSE_URL) > /usr/local/bin/docker-compose; \
		chmod +x /usr/local/bin/docker-compose; \
		sed -i -e "/^MountFlags/d" /lib/systemd/system/docker.service; \
		systemctl enable docker; \
		systemctl daemon-reload; \
		systemctl start docker; \
		docker run hello-world; \
	fi
ifneq ($(SUDO_USER),)
	usermod -aG docker $(SUDO_USER)
endif

ntp: ntp-install ntp-config

ntp-install :
# ------------------------------------------------------------------------ RHEL distros
ifeq ($(ID),almalinux)
	-yum install -y chrony
else ifeq ($(OS),"centos6")
	-yum install -y ntp
	-yum install -y ntp
else ifeq ($(OS),centos7)
	-yum install -y ntp
else ifeq ($(OS),centos8)
	-yum install -y chrony
else ifeq ($(ID),fedora)
	-dnf install -y ntp
else ifeq ($(ID),rocky)
	-yum install -y chrony
# ------------------------------------------------------------------------ DEBIAN distros
else ifeq ($(ID),ubuntu)
	-apt-get install -y ntp ntpdate ntp-doc
else ifeq ($(ID),debian)
	-apt-get install -y ntp ntpdate ntp-doc
else ifeq ($(ID),suse)
	echo use "chronyc sources"
else ifeq ($(ID),zorin)
	-apt-get install -y chrony
endif

ntp-config :
ifneq ($(AWS),"n")
	sed -i.orig -e "s/centos.pool/amazon.pool/g" /etc/ntp.conf # only if on AWS
endif
# ------------------------------------------------------------------------ RHEL distros
ifeq ($(ID),almalinux)
	systemctl enable chronyd
	systemctl start chronyd
	timedatectl set-timezone America/Los_Angeles
	chronyc sources

else ifeq ($(OS),centos6)
	chkconfig --level 2 --level 3 ntpd on
	service ntpd start
	ntpdc -c pe
	#[ ! -e /etc/localtime.orig ] && mv /etc/localtime /etc/localtime.orig
	# ln -s /usr/share/zoneinfo/America/Los_Angeles /etc/localtime

else ifeq ($(OS),centos7)
	systemctl enable ntpd
	systemctl start ntpd
	timedatectl set-timezone America/Los_Angeles
	ntpdc -c pe

else ifeq ($(OS),centos8)
	systemctl enable chronyd
	systemctl start chronyd
	timedatectl set-timezone America/Los_Angeles
	chronyc sources

else ifeq ($(ID),fedora)
	systemctl enable ntpd
	systemctl start ntpd
	timedatectl set-timezone America/Los_Angeles
	ntpdc -c pe

else ifeq ($(ID),rocky)
	systemctl enable chronyd
	systemctl start chronyd
	timedatectl set-timezone America/Los_Angeles
	chronyc sources
# ------------------------------------------------------------------------ DEBIAN distros
else ifeq ($(ID),ubuntu)
	systemctl enable ntp
	systemctl start ntp
	timedatectl set-timezone America/Los_Angeles

else ifeq ($(ID),debian)
	systemctl enable ntp
	systemctl start ntp
	timedatectl set-timezone America/Los_Angeles
	ntpq -c pe

else ifeq ($(ID),suse)
	systemctl status chronyd
	systemctl start chronyd
	timedatectl set-timezone America/Los_Angeles
	chronyc sources

else ifeq ($(ID),zorin)
	systemctl enable chronyd
	systemctl status chronyd
	systemctl start chronyd
	timedatectl set-timezone America/Los_Angeles
	chronyc sources
endif


# centos7 Mate and Gnome won't resize with extensions installed
# http://jensd.be/125/linux/rel/install-mate-or-xfce-on-centos-7
# 5/16/17 epel's xfce seems to be broken requiring wrong version
# skip-broken fixes this temporarily
gui:
# ------------------------------------------------------------------------ RHEL distros
ifeq ($(ID),almalinux)
	yum groupinstall -y "Server with GUI"
	yum install -y firefox gvim
	systemctl set-default graphical.target

else ifeq ($(OS),"centos6")
	yum groupinstall -y "X Window system"
	yum groupinstall -y "Xfce" "Fonts" --skip-broken
	yum install -y firefox gvim xorg-x11-fonts-Type1 xorg-x11-fonts-misc
	sed -i.mu3 -e "s/id:3/id:5/" /etc/inittab

else ifeq ($(OS),centos7)
	yum groupinstall -y "Server with GUI"
# 	yum groupinstall -y "X Window system"
# 	yum groupinstall -y "Xfce" --skip-broken
	yum install -y firefox gvim
	systemctl set-default graphical.target

else ifeq ($(OS),centos8)
	yum groupinstall -y "Server with GUI"
	yum install -y firefox gvim
	systemctl set-default graphical.target

else ifeq ($(ID),fedora)
	dnf install -y @xfce-desktop-environment
	dnf install -y firefox gvim
	systemctl set-default graphical.target
	systemctl enable lightdm.service

else ifeq ($(ID),rocky)
	yum groupinstall -y "Server with GUI"
	yum install -y firefox gvim
	systemctl set-default graphical.target

# ------------------------------------------------------------------------ DEBIAN distros
else ifeq ($(ID),ubuntu)
	apt-get update
	apt-get install -y xfce4 vim-gnome
	systemctl set-default graphical.target

else ifeq ($(ID),debian)
	apt-get update
	apt-get install -y xfce4 vim-gtk3
	systemctl set-default graphical.target

else ifeq ($(ID),suse)
	-zypper -n in patterns-openSUSE-xfce
	-zypper --non-interactive install gvim
	systemctl set-default graphical.target

else ifeq ($(ID),zorin)
	apt-get update
	apt-get install -y xfce4 vim-gtk3
	systemctl set-default graphical.target
endif
	@echo "reboot to start with GUI"

no-gui:
# ------------------------------------------------------------------------ RHEL distros
ifeq ($(OS),centos6)
	sed -i.x11 -e "s/id:5/id:3/" /etc/inittab
else ifeq ($(OS),centos7)
	systemctl set-default multi-user.target
else ifeq ($(ID),fedora)
	systemctl set-default multi-user.target
	systemctl disable lightdm.service
# ------------------------------------------------------------------------ DEBIAN distros
else ifeq ($(ID),ubuntu)
	systemctl set-default multi-user.target
else ifeq ($(ID),debian)
	systemctl set-default multi-user.target
else ifeq ($(ID),suse)
	systemctl set-default multi-user.target
else ifeq ($(ID),zorin)
	systemctl set-default multi-user.target
endif
	@echo "reboot to start without GUI"

# VirtualBox extensions
# Centos assumes installed w/o GUI at command line
# ubunut assumes installed on top of GUI with mount point
vbox:
# ------------------------------------------------------------------------ RHEL distros
ifeq ($(OS),centos7)
	-yum update kernel*
	-yum install -y dkms gcc make kernel-devel bzip2 binutils patch libgomp glibc-headers glibc-devel kernel-headers
	-mount /dev/sr0 /mnt
	-cd /mnt && ./VBoxLinuxAdditions.run
	@echo "You can now reboot the system"
# ------------------------------------------------------------------------ DEBIAN distros
else ifeq ($(ID),ubuntu)
	-apt-get update && apt-get -y upgrade
	-apt-get install -y build-essential module-assistant
	-cd /media/mivilain/VBOXADDITIONS_5.1.22_115126 && ./VBoxLinuxAdditions.run
	@echo "You can now reboot the system"
endif


python3: packages
# ------------------------------------------------------------------------ RHEL distros
ifeq ($(OS),centos6)
	-yum install -y python27 python27-pip python27-setuptools
	-yum install -y python36 python36-setuptools python36-pip
	-pip2.7 install pip --upgrade
	-pip3.6 install pip --upgrade

else ifeq ($(OS),centos7)
	-yum install -y python2-pip
	-yum install -y python3 python3-setuptools python3-pip
	-pip install pip --upgrade
	-pip3 install pip3 --upgrade

else ifeq ($(OS),centos8)
	-yum install -y python3-pip
	-pip3 install wheel
	-pip3 install pip setuptools certifi --upgrade
# ------------------------------------------------------------------------ DEBIAN distros
else ifeq ($(OS),suse)
	-zypper install -y python3-setuptools
	-easy_install install wheel pip certifi

endif

# ubuntu 17.10+, fedora 27, debian 10+, opensuse-leap, and zorin have python3
python3u:
ifeq ($(ID),ubuntu)
	-apt-get install gcc libssl-dev make build-essential libssl-dev zlib1g-dev libbz2-dev libsqlite3-dev
	-wget https://www.python.org/ftp/python/$(PY_VER)/Python-$(PY_VER).tgz
	-tar -xzf Python-$(PY_VER).tgz
	-cd Python-$(PY_VER) && ./configure && make altinstall
	-rm Python-$(PY_VER).tgz
else
	@echo "python3u target is for ubuntu systems only"
endif

# install git from source; requires development tools
git-src:
# ------------------------------------------------------------------------ RHEL distros
ifeq ($(ID),almalinux)
	-yum groupinstall -y "Development Tools"
	-yum install -y $(GIT_DEV_RPM_PKGS)
	-wget https://github.com/git/git/archive/refs/tags/v2.33.0.tar.gz -O git.tar.gz
	-tar -xzf git.tar.gz && cd git-* && make configure && ./configure --prefix=/usr/local && make
	-make install
	-cd .. && rm -rf git-* git.tar.gz

else ifeq ($(OS),"centos6")
	-yum groupinstall -y "Development Tools"
	-yum install -y $(GIT_DEV_RPM_PKGS)
	-wget https://github.com/git/git/archive/refs/tags/v$(GIT_VER).tar.gz -O git.tar.gz
	-tar -xzf git.tar.gz && cd git-* && make configure && ./configure --prefix=/usr/local && make
	-make install
	-cd .. && rm -rf git-* git.tar.gz

else ifeq ($(OS),centos7)
	-yum groupinstall -y "Development Tools"
	-yum install -y $(GIT_DEV_RPM_PKGS)
	-wget https://github.com/git/git/archive/refs/tags/v$(GIT_VER).tar.gz -O git.tar.gz
	-tar -xzf git.tar.gz && cd git-* && make configure && ./configure --prefix=/usr/local && make
	-make install
	-cd .. && rm -rf git-* git.tar.gz

else ifeq ($(OS),centos8)
	-yum groupinstall -y "Development Tools"
	-yum install -y $(GIT_DEV_RPM_PKGS)
	-wget https://github.com/git/git/archive/refs/tags/v$(GIT_VER).tar.gz -O git.tar.gz
	-tar -xzf git.tar.gz && cd git-* && make configure && ./configure --prefix=/usr/local && make
	-make install
	-cd .. && rm -rf git-* git.tar.gz

else ifeq ($(ID),fedora)
	-dnf groupinstall -y "Development Tools"
	-dnf install -y $(GIT_DEV_RPM_PKGS)
	-wget https://github.com/git/git/archive/refs/tags/v$(GIT_VER).tar.gz -O git.tar.gz
	-tar -xzf git.tar.gz && cd git-* && make configure && ./configure --prefix=/usr/local && make
	-make install
	-cd .. && rm -rf git-* git.tar.gz

else ifeq ($(ID),rocky)
	-yum groupinstall -y "Development Tools"
	-yum install -y $(GIT_DEV_RPM_PKGS)
	-wget https://github.com/git/git/archive/refs/tags/v2.33.0.tar.gz -O git.tar.gz
	-tar -xzf git.tar.gz && cd git-* && make configure && ./configure --prefix=/usr/local && make
	-make install
	-cd .. && rm -rf git-* git.tar.gz

# ------------------------------------------------------------------------ DEBIAN distros
else ifeq ($(ID),debian)
	-apt-get install -y $(GIT_DEV_DEB_PKGS)

else ifeq ($(ID),ubuntu)
	-apt-get install -y build-essential autoconf libghc-zlib-dev libssl-dev libcurl4-gnutls-dev lib-expat1-dev gettext

endif

# add code for zsh install and configuration
zsh: git
# ------------------------------------------------------------------------ RHEL distros
ifeq ($(OS),centos6)
	yum install -y zsh vim
else ifeq ($(OS),centos7)
	yum install -y zsh vim
else ifeq ($(OS),centos8)
	yum install -y zsh vim
else ifeq ($(ID),fedora)
	dnf install -y zsh vim
# ------------------------------------------------------------------------ DEBIAN distros
else ifeq ($(ID),ubuntu)
	apt-get install -y zsh-static zsh-syntax-highlighting zshdb vim-syntastic
else ifeq ($(ID),debian)
	apt-get install -y zsh-static zsh-syntax-highlighting zshdb vim-syntastic
else ifeq ($(ID),suse)
	zypper --non-interactive install zsh
else ifeq ($(ID),zorin)
	-apt-get install -y zsh-static zsh-syntax-highlighting vim-syntastic
endif

zsh-config:
	-git clone https://github.com/ohmyzsh/ohmyzsh.git ${HOME}/.oh-my-zsh
# 	-/bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	-/bin/cp -v robbyrussell-mv.zsh-theme candy-mv.zsh-theme ${HOME}/.oh-my-zsh/custom/
	-echo "run 'chsh -s /bin/zsh ${LOGNAME}' ... to change your shell"

