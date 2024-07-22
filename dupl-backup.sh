#!/usr/bin/env bash
# zorin backup to local /media/
#

SCRIPT=`basename $0`
NAME=daily-$(date "+%Y%m%d-%M%d%S")
NAME=daily-$(date "+%Y%m%d")


EXCL_FILE=exclude-${SCRIPT}
DUR=7D
TMPDIR=/mnt/backups/tmp/
DEST=file:///mnt/backups/zorin/

if [ ! -e ~/.duplicity/.env-variables.conf.gpg ]; then
  echo "enter zorin-backup gpg password"
  source "gpg2 -dq ~/.duplicity/.env-variables.conf.gpg |"
fi
# these should be in ~/.duplicity/.env-variables
#ENC_KEY="xxxxxxxx" # zorin-backup
#GPG_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"  # "zorin-backup"
[ -z "${GPG_KEY}" ] && echo "GPG_KEY not defined" && exit 1

cat >${EXCL_FILE} <<-EOF
	/tmp
	/proc
	/sys
	/swapfile
EOF

date
duplicity backup --verbosity Error \
  --encrypt-sign-key=${GPG_KEY} \
  --tempdir ${TMPDIR} \
  --log-file ~/.duplicity/info-${NAME}.log \
  --full-if-older-than ${DUR} \
  --exclude-other-filesystems --exclude-device-files \
  --exclude-filelist ${EXCL_FILE} \
  / ${DEST}
date

exit
