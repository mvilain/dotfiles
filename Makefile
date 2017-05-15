# Makefile for dotfiles environment
# Maintainer Michael Vilain <michael@vilain.com> [201705.15]

.PHONY : build clean install

DOCKER_COMPOSE_URL=https://github.com/docker/compose/releases/download/1.13.0/docker-compose-`uname -s`-`uname -m`

IP=$(shell curl -m 2 -s -f http://169.254.169.254/latest/meta-data/public-ipv4)
ifeq ($(IP),)
IP=$(shell ifconfig -a | grep "inet " | grep "broadcast" | grep -Ev "172|127.0.0.1" | awk '{print $2}')
AWS=n
else
AZ=$(shell curl -m 2 -s -f http://169.254.169.254/latest/meta-data/placement/availability-zone)
endif

# centos or ubuntu (no others tested)
OS=$(shell grep '^ID=' /etc/os-release | sed -e 's/ID=//')

DOTFILES := .aliases .bash_profile .bash_prompt .bashrc .exports .exrc .forward .functions .inputrc .screenrc

TARGETS := install

all: $(TARGETS)

build: 
	echo $(OS)
	echo $(IP)

clean: 

install : ntp files

files: $(DOTFILES)
	/bin/cp -v $(DOTFILES) ${HOME}/

git:
ifeq ($(OS),centos)
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
	git config --global alias.mylog "log --pretty=format:'%h %s [%an]' --graph" 
	git config --global alias.lol "log --graph --decorate --pretty=oneline --abbrev-commit --all"

packages:
ifeq ($(OS),centos)
	-yum install -y wget vim lsof bash-completion epel-release bind-utils
else ifeq ($(OS),ubuntu)
	-apt-get install -y curl vim lsof bash-completion dnsutils
endif

ntp: ntp-install ntp-config
ntp-install:
ifeq ($(OS),"centos")
	-yum install -y ntp
else ifeq ($(OS),"ubuntu")
	apt-get install -y ntp ntpdate ntp-doc
endif

ntp-config: ntp-install
ifneq ($(AWS),n)
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
		usermod -aG docker mivilain; \
	fi
