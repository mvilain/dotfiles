#!/usr/bin/env bash
# zorin backup to local /media/
# 2408.05 removed keys to CONF file
# 2409.03 use /usr/bin/duplicity for default location
# 2409.22 change to do full backups for 90days
# 2501.04 change to do full backups daily; keep 14 days worth

SCRIPT=`basename $0`
NAME=daily-$(date "+%Y%m%d")
CONF=~/.config/duplicity/.env_variables.conf
# use duplicity in path otherwise set it to /usr/local/bin
#DUPL=$(/usr/bin/env duplicity)
DUPL="${DUPL:-/usr/local/bin/duplicity}"

EXCL_FILE=exclude-${SCRIPT}
DUR=1D
EXPIRED=30D
TMPDIR=/mnt/backups/tmp/
LOG=/var/log/${NAME}.log
DEST=/mnt/backups/zorin/

[ ! -e ${TMPDIR} ] && echo "${TMPDIR} not found"
[ ! -e ${DEST} ] && echo "${DEST} not found" && exit 1

[ -e ${CONF} ] && source ${CONF}
[ -z "$GPG_KEY" ] && echo "GPG_KEY not defined" && env && exit 1
# PASSPHRASE can be underdefined

cat >${EXCL_FILE} <<-EOF
	/tmp
	/proc
	/sys
	/swapfile
EOF

echo "========================================>>>>> `date`"

${DUPL} \
  --encrypt-sign-key ${GPG_KEY} \
  remove-older-than ${EXPIRED} --force file://${DEST}

echo "========================================>>>>> `date`"

${DUPL} backup --verbosity Error --copy-links \
  --encrypt-sign-key ${GPG_KEY} \
  --tempdir ${TMPDIR} \
  --full-if-older-than ${DUR} \
  --exclude-other-filesystems --exclude-device-files \
  --exclude-filelist ${EXCL_FILE} \
  / file://${DEST} | tee ${LOG}

echo "========================================>>>>> `date`"

${DUPL} \
  cleanup --force \
  --encrypt-sign-key=${GPG_KEY} \
  file://${DEST}

echo "========================================>>>>> `date`"

${DUPL} collection-status \
  --encrypt-sign-key=${GPG_KEY} \
  file://${DEST}

echo "========================================>>>>> `date`"

[ -e ${EXCL_FILE} ] && rm -v ${EXCL_FILE}
find /var/log/daily-* -mtime +30 -delete
exit
