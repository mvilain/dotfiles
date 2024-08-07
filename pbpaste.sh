#!/usr/bin/env bash
# https://github.com/westurner/dotfiles/blob/develop/scripts/pbpaste

# Shim to support something like pbpaste on Linux
__IS_MAC=${__IS_MAC:-$(test $(uname -s) == "Darwin" && echo 'true')}

if [ -n "${__IS_MAC}" ]; then
    /usr/bin/pbpaste ${@}
    exit
else
    xclip -selection clipboard -o
    exit
fi
