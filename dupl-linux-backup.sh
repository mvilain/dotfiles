#!/usr/bin/env bash
# zorin backup to local /media/
#

SCRIPT=`basename $0`
NAME=daily-$(date "+%Y%m%d-%M%d%S")
NAME=daily-$(date "+%Y%m%d")
CONF=~/.duplicity/.env_variables.conf

EXCL_FILE=exclude-${SCRIPT}
DUR=14D
TMPDIR=/mnt/backups/tmp/
LOG=/var/log/${NAME}.log
DEST=file:///mnt/backups/zorin/

[ ! -e ${TMPDIR} ] && echo "${TMPDIR} and ${DEST} not found" && exit 1

# these should be in ~/.duplicity/.env-variables
GPG_KEY=473CE91EAC5BEBC3459A429BD26BD6CBD7CA8525
ENC_KEY="D7CA8525" # zorin-backup
[ -e ${CONF} ] && source ${CONF}
[ -z "$GPG_KEY" ] && echo "GPG_KEY not defined" && exit 1
# PASSPHRASE can be underdefined

cat >${EXCL_FILE} <<-EOF
	/tmp
	/proc
	/sys
	/swapfile
EOF

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>`date`"

duplicity \
  --encrypt-sign-key=${ENC_KEY} \
  remove-older-than 90D --force ${DEST}

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>`date`"

duplicity backup --verbosity Error --copy-links \
  --encrypt-sign-key=${GPG_KEY} \
  --tempdir ${TMPDIR} \
  --full-if-older-than ${DUR} \
  --exclude-other-filesystems --exclude-device-files \
  --exclude-filelist ${EXCL_FILE} \
  / ${DEST} | tee ${LOG}

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>`date`"

duplicity \
  cleanup --force \
  --encrypt-sign-key=${ENC_KEY} \
  ${DEST}

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>`date`"

duplicity collection-status \
  --encrypt-sign-key=${ENC_KEY} \
  ${DEST}

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>`date`"

cat ${LOG}

exit
