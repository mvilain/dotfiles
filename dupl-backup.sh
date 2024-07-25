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
LOG=/var/log/${SCRIPT}-${NAME}.log
DEST=file:///mnt/backups/zorin/

[ ! -e ${TMPDIR} ] && echo "${TMPDIR} and ${DEST} not found" && exit 1

# these should be in ~/.duplicity/.env-variables
GPG_KEY=473CE91EAC5BEBC3459A429BD26BD6CBD7CA8525
ENC_KEY=D7CA8525
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

duplicity \
  --encrypt-sign-key=${ENC_KEY} \
  remove-older-than 90D --force ${DEST}

duplicity backup --verbosity Error \
  --encrypt-sign-key=${GPG_KEY} \
  --tempdir ${TMPDIR} \
  --log-file ${LOG} \
  --full-if-older-than ${DUR} \
  --exclude-other-filesystems --exclude-device-files \
  --exclude-filelist ${EXCL_FILE} \
  / ${DEST}

duplicity \
  cleanup --force \
  --encrypt-sign-key=${ENC_KEY} \
  ${DEST}

duplicity collection-status \
  --encrypt-sign-key=${ENC_KEY} \
  ${DEST}

date

cat ${LOG}

exit
