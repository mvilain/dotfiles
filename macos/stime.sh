#!/usr/bin/env bash
# speak the time every 5 seconds until control-c
#
# http://hints.macworld.com/article.php?story=2011043006554823
#
echo "saying the time...press ^C to exit"
while [ 1 ]; do
	z=`date +%S`
	if [ `expr $z % 5` -eq 0 ]; then 
		say `date "+%l %M and %S seconds"`
	fi
done

