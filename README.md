# dotfiles

mvilain's Linux dotfiles and assorted other stuff

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
* **macos/stime.sh** -- speak date and time using MacOS "say" command
* **macos/xxattr** -- remove all extended attributes for a file
* **Makefile** -- targets to install git, ntp, dot files, and various packages (tested on centos and ubuntu)
* **rename.pl** -- perl script to use regex to rename files
* **striphtml** -- perl script to remove html markup from a file and remap international characters to marked up values
* **xero** -- perl script to open and trucate a file making it zero length

## python3.5 on CentOS 7

[https://tecadmin.net/install-python-3-5-on-centos/]
[http://stackoverflow.com/questions/37723236/pip-error-while-installing-python-ignoring-ensurepip-failure-pip-8-1-1-requir/37723517]
