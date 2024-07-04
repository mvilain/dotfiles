#!/usr/bin/env bash
# https://github.com/westurner/dotfiles/blob/develop/scripts/pbcopy

### pbcopy
# Shim to support something like pbcopy on Linux
# note: requires Xforwarding for ssh client

function pbcopy {
    __IS_MAC=${__IS_MAC:-$(test "$(uname -s)" == "Darwin" && echo 'true')}

    if [ -n "${__IS_MAC}" ]; then
        cat | /usr/bin/pbcopy
        exit
    else
        # copy to selection buffer AND clipboard
        cat | xclip -i -sel c -f | xclip -i -sel p
        exit
    fi
}

if [ -n "${BASH_SOURCE}" ] && [ "$BASH_SOURCE" == "$0" ]; then
    pbcopy
fi

