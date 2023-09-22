#!/usr/bin/env sh

# write the url from which a file came into its metadata
# see http://hints.macworld.com/article.php?story=20110102222441243

# command line flags sanity check
# $1 is target pathname
# $2 is source url to write into target pathname's metadata
case $# in
  2)	;;
  *)	echo "Usage: $0 pathname source_url"
	exit 1;;
esac

# verify existence of source url
# sed script extracts HTTP status code returned by curl document info request
http_status=`curl -I "$2" 2> /dev/null | sed -n -e '/^HTTP/s/^[^ ]* \([0-9]*\) .*$/\1/p'`
case $http_status in
  2??)	;;
  *)	echo "URL '$2' not found"
	exit 1;;
esac

# fail if target file isn't writeable or doesn't exist
test -w $1 || { echo "Can't write to $1"; exit 1; }

# write metadata
xattr -w 'com.apple.metadata:kMDItemWhereFroms' \
	'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array><string>'"$2"'</string></array></plist>' \
	"$1"

