#!/usr/bin/env bash
# zorin backup to local /media/
#

SCRIPT=`basename $0`
NAME=daily-$(date "+%Y%m%d-%M%d%S")
NAME=daily-$(date "+%Y%m%d")
CONF=~/.duplicity/.env_variables.conf

EXCL_FILE=exclude-${SCRIPT}
DUR=7D
TMPDIR=/mnt/backups/tmp/
DEST=file:///mnt/backups/zorin/

[ ! -e ${TMPDIR} ] && echo "${TMPDIR} and ${DEST} not found" && exit 1

# these should be in ~/.duplicity/.env-variables
GPG_KEY=AF387140DA632FC0D7D97E8FA73B71C8020FF318
ENC_KEY="020ff318" # zorin-backup
[ -e ${CONF} ] && source ${CONF}
[ -z "$GPG_KEY" ] && echo "GPG_KEY not defined" && exit 1
# PASSPHRASE can be underdefined

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
