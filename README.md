# dotfiles

my Linux dotfiles and assorted other stuff

## files

- **.aliases** -- various aliases for ls, grep, docker functions
- **.bash_profile** -- actual script that does everything
- **.bash_prompt** -- sets prompt to "tod # user $"
- **.bashrc** -- redirects to .bash_profile
- **.exports** -- various environment variables like EDITOR so man pages don't blank 
  and SYSTEMD_PAGER to disable paging of journalctl output
- .**exrc** -- setup vi environment
- **.forward** -- disable email forwarding
- **.functions** -- define various web-centric functions for a bash session
- **.inputrc .screenrc** -- setup input and screen environments
- **.vimrc** -- setup default VIM environment to use slate colors with .exrc's defaults
- **macos/** -- directory of MacOS scripts
  * **stime.sh** -- speak date and time using MacOS "say" command
  * **xxattr** -- remove all extended attributes for a file
  * **xxfrom** -- add URL to MacOS file attributes so they show up in GetInfo
  * **.osx** -- settings for MacOS from geerlingguy.dotfiles plus my own mods
- **Makefile** -- targets to install git, ntp, dot files, and various packages 
  (tested on centos, fedora, debian, and ubuntu)
- **robbyrussell.zsh-theme** -- modified theme to use for zsh (prompt changed to `-> TIME USER@HOST pwd git-status` )
- **vagrant/** -- directory for vagrant testing of Makefile
  * **Vagrantfile** -- vagrant config to create VB guests to test Makefile in 
    CentOS, Fedora, and Ubuntu environments
  * **pb-centos.yml** -- ansible playbook to provision on CentOS 6 + 7
  * **pb-fedora.yml** -- ansible playbook to provision on Fedora 27
  * **pb-ubuntu.yml** -- ansible playbook to provision on Ubuntu 14.04, 16.04, 18.04
- **rename.pl** -- perl script to use regex to rename files
- **striphtml** -- perl script to remove html markup from a file and remap 
  international characters to marked up values
- **xero** -- perl script to open and trucate a file making it zero length
- **.zshrc.ohmyzsh** -- zsh config file using ohmyzsh and modified **robbyrussell** theme
- **.zshrc.kali** -- zsh config file using [Kali Linux's prompt](https://statropy.com/blog/kali-linux-zsh-for-macos/)


## [python3.5 on CentOS 7](https://tecadmin.net/install-python-3-5-on-centos/)

http://stackoverflow.com/questions/37723236/pip-error-while-installing-python-ignoring-ensurepip-failure-pip-8-1-1-requir/37723517


## VM Guest's Shared Folders

Many OS' support this package as pre-installed rather than the VMware Tools or installing the VirtualBox Guest Toolkit.


## CentOS VIRTUALBOX

For VirtualBox Guests, they require kernel development and a bunch of other packages.

    yum install -y gcc make perl bzip2 tar elfutils-libelf-devel kernel-headers kernel-devel
    yum update -y
    [reboot]
    [select Insert Guest Additions CD Image from Devices menu]
    mount /dev/cdrom /mnt
    cd /mnt
    /mnt/VBoxLinuxAdditions.run install
    umount /mnt
    mkdir /mnt/<mount-point>
    mount -t vboxsf <mount-point> /mnt/<mount-point>

And add the following to /etc/fstab

    /<mount-point> /mnt/<mount-point> vboxsf defaults 0 0

[https://www.virtualbox.org/manual/ch04.html#additions-linux]


## CentOS and Fedora VMWARE

CentOS 8.1's open-vm-tools does not work.  You must remove the package and install VMware tools.

    dnf remove -y open-vm-tools open-vm-tools-desktop
    dnf install -y tar perl
    mkdir /mnt/hgfs

Then install the VMware Tools from the client's GUI, which will make the CD available
for mounting.

    [configure VM to have shared folder]
    yum uninstall open-vm-tools
    [select VMware Tools Installation from Virtual Machine menu]
    mount /dev/cdrom /mnt
    tar -xvzf /mnt/VMwareTools-x.y.z-nnnnnnn.tar.gz -C /tmp
    /tmp/vmware-tools-distrib/vmware-install.pl
    [do you still want to proceed with this installation? [no] YES]
    [take the defaults for the rest of the choices]
    [reboot and mount points will appear /mnt/hgfs/<mount-point>]

[https://linuxconfig.org/how-to-install-vmware-tools-on-rhel-8-centos-8]

In CentOS 7.x and 8.2's minimal install, open-vm-tools is already installed and just needs to be started. This also works for Fedora 33.

    mkdir /mnt/hgfs
    systemctl restart vmtoolsd

[https://www.virtualbox.org/manual/ch02.html#externalkernelmodules]

To mount all the shared folders configured with the VM, type the following as root:

    mount -t fuse.vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other

To ensure the /mnt/hgfs mount points at boot, insert the following into /etc/fstab:

    .host:/<mount-point> /mnt/hgfs fuse.vmhgfs-fuse allow_other,defaults 0 0

[https://unix.stackexchange.com/questions/310458/vmhgfs-fuse-permission-denied-issue]


## Debian VIRTUALBOX

As root (sudo isn't installed on Debian 9 by default), install the following:

```bash
sed -i "s/^deb cdrom/#deb cdrom/" /etc/apt/sources.list
apt-get update -y
apt-get install -y sudo gcc make perl bzip2 tar build-essential dkms linux-headers-$(uname -r)
[reboot]
[select Insert Guest Additions CD Image from Devices menu]
mount /dev/cdrom /mnt
/mnt/VBoxLinuxAdditions.run install
umount /mnt
[reboot]
mount -t vboxsf <mount-point> /mnt/<mount-point>
```

And add the following to /etc/fstab

    /<mount-point> /mnt/<mount-point> vboxsf defaults 0 0

[https://linuxize.com/post/how-to-install-virtualbox-guest-additions-on-debian-10/]


## Debian VMWARE

As root with su (sudo isn't installed on Debian by default), install the following:

```base
sed -i "s/^deb cdrom/#deb cdrom/" /etc/apt/sources.list
apt-get install -y sudo make git perl bzip2 tar open-vm-tools
```

On Debian 9, this will automatically start the open-vm-tools service on the host. 
/mnt/hgfs will contain all the mount point defined in the Guest's configuration.

On Debian 10, you have to create the mount point and restart the service,

```bash
mkdir /mnt/hgfs
systemctl restart open-vm-tools
mount -t fuse.vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other
echo ".host:/ /mnt/hgfs fuse.vmhgfs-fuse defaults,allow_other 0 0" >> /etc/fstab
```

Debian 10's VMware Guest works best with 2 cores and 4096MB of memory.  It als doesn't allow 
for setting static IP address through standard boot off of ISO.  So do the following:

  - modify /etc/network/interfaces to have the following:

```
allow-hotplug ens33
#iface ens33 inet dhcp
iface ens33 inet static
  address 192.168.x.xxx
  netmask 255.255.255.0
  gateway 192.168.x.xxx
  dns-nameservers 8.8.8.8 8.8.4.4
```

  + modify /etc/resolve.config and reboot
```
domain local.net
search local.net
nameserver 8.8.8.8
nameserver 8.8.4.4
```


## Ubuntu VIRTUALBOX

For Ubuntu 16.04 and 14.04, install a minimal system using the entire disk with the LVM. 
If you upgrade the OS, the upgrade scripts make changes to the volume groups and 
will fail if you don't use the volume manager.

This procedure has been tested with Ubuntu 14.04, 16.04, 18.04, and 20.04

    [minimal Ubuntu Server install with security updates]
    apt-get update -y
    apt-get install -y virtualbox-guest-dkms
    [reboot]
    [select Insert Guest Additions CD Image from Devices menu]
    mount /dev/cdrom /mnt
    /mnt/VBoxLinuxAdditions.run install
    [reboot]
    mkdir /mnt/<mount-point>
    lsmod | grep vbox # [you should see the VBox additions]
    mount -t vboxsf <mount-point> /mnt/<mount-point>

And add the following to /etc/fstab

    /<mount-point> /mnt/<mount-point> vboxsf defaults 0 0


## Ubuntu VMWARE

For Ubuntu 14.04, 16.04, and 18.04, open-vm-tools doesn't work, so do the following:

    [minimal Ubuntu Server install with security updates]
    [configure VM to have shared folder]
    apt-get install -y make
    apt-get purge open-vm-tools # on 16.04, remove the broken package
    [select VMware Tools Installation from Virtual Machine menu]
    mount /dev/cdrom /mnt
    tar -xvzf /mnt/VMwareTools-x.y.z-nnnnnnn.tar.gz -C /tmp
    /tmp/vmware-tools-distrib/vmware-install.pl
    [do you still want to proceed with this installation? [no] YES]
    [take the defaults for the rest of the choices]
    [reboot and mount points will appear /mnt/hgfs/<mount-point>]

For Ubuntu 20.04, do the following:

    [minimal Ubuntu Server install with the old installer]
    [configure VM to have shared folder]
    apt-get update -y
    apt-get install -y open-vm-tools
    [reboot]
    mkdir /mnt/hgfs
    mount -t fuse.vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other

Add the following to /etc/fstab

    .host:/ /mnt/hgfs fuse.vmhgfs-fuse defaults,allow_other 0 0_

[https://linuxconfig.org/install-vmware-tools-on-ubuntu-20-04-focal-fossa-linux]



## APPENDIX

### adding submodule to git

This creates a HEADless snapshot of the submodule in the main repo.

    cd ./macos
    git submodule add https://github.com/mvilain/mac-dev-playbook.git

When you update the submodule and push it, the snapshot must be refreshed with the changes.

    git submodule update
    git submodule update --remote
    git commit -a -m "submodule update"

### removing submodules from git

Here's how to remove submodules (from [How to delete a submodule](https://gist.github.com/myusuf3/7f645819ded92bda6677))

- Delete the relevant section from the .gitmodules file.
- Stage the .gitmodules changes `git add .gitmodules`
- Delete the relevant section from .git/config.
- Run `git rm --cached path_to_submodule` (no trailing slash).
- Run `rm -rf .git/modules/path_to_submodule` (no trailing slash).
- Delete the now untracked submodule files `rm -rf path_to_submodule`
- Commit `git commit -m "Removed submodule"`
