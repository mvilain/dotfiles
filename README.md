# dotfiles

my Linux dotfiles and assorted other stuff

## files

* **.aliases** -- various aliases for ls, grep, docker functions
* **.bash_profile** -- actual script that does everything
* **.bash_prompt** -- sets prompt to "tod # user $"
* **.bashrc** -- redirects to .bash_profile
* **.exports** -- various environment variables like EDITOR so man pages don't blank and SYSTEMD_PAGER to disable paging of journalctl output
* .**exrc** -- setup vi environment
* **.forward** -- disable email forwarding
* **.functions** -- define various web-centric functions for a bash session
* **.inputrc .screenrc** -- setup input and screen environments
* **.vimrc** -- setup default VIM environment to use slate colors with .exrc's defaults
* **macos/** -- directory of MacOS scripts
  * **stime.sh** -- speak date and time using MacOS "say" command
  * **xxattr** -- remove all extended attributes for a file
  * **xxfrom** -- add URL to MacOS file attributes so they show up in GetInfo
* **Makefile** -- targets to install git, ntp, dot files, and various packages (tested on centos, fedora, debian, and ubuntu)
* **vagrant/** -- directory for vagrant testing of Makefile
  * **Vagrantfile** -- vagrant config to create VB guests to test Makefile in CentOS, Fedora, and Ubuntu environments
  * **pb-centos.yaml** -- ansible playbook to provision on CentOS 6 + 7
  * **pb-fedora.yaml** -- ansible playbook to provision on Fedora 27
  * **pb-ubuntu.yaml** -- ansible playbook to provision on Ubuntu 14.04, 16.04, 18.04
* **rename.pl** -- perl script to use regex to rename files
* **striphtml** -- perl script to remove html markup from a file and remap international characters to marked up values
* **xero** -- perl script to open and trucate a file making it zero length

## python3.5 on CentOS 7

[https://tecadmin.net/install-python-3-5-on-centos/]
[http://stackoverflow.com/questions/37723236/pip-error-while-installing-python-ignoring-ensurepip-failure-pip-8-1-1-requir/37723517]

## open-vmware-tools

Many OS' support this package as pre-installed rather than the VMware Tools.

To mount a mount point defined in the VMware shared folder definitions, use 

    .host:/<mount>  /mnt/hgfs fuse.vmhgfs-fuse allow_other,defaults 0 0

in /etc/fstab.

https://unix.stackexchange.com/questions/310458/vmhgfs-fuse-permission-denied-issue


## Debian 10 setup

Debian 10 doesn't allow for setting static IP address through standard boot off of ISO.

So do the following:

- modify /etc/network/interfaces to have the following:
```
iface ens33 inet static
  address 192.168.x.xxx
  netmask 255.255.255.0
  gateway 192.168.x.xxx
  dns-nameservers 8.8.8.8 8.8.4.4
```

- modify /etc/resolve.config and reboot
```
domain local.net
search local.net
nameserver 8.8.8.8
nameserver 8.8.4.4
```

- remove the CDROM entry from /etc/apt/sources.list

    sed -i -e "/^deb cdrom:/d" /etc/apt/sources.list
