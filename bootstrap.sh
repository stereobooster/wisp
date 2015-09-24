#!/bin/bash

# Bootstrap wisp-guile with wisp.py
if [[ x"$1" == x"" ]]; then 
    srcdir=.
else
    srcdir="$1"
fi

# Bootstrap wisp-guile with wisp.py
if [[ x"$2" == x"" ]]; then 
    guile='guile'
else
    guile="$2"
fi

# Bootstrap wisp-guile with wisp.py
if [[ x"$3" == x"" ]]; then 
    python3="python3"
else
    python3="$3"
fi

diff=$(${python3} ${srcdir}/wisp.py ${srcdir}/wisp-guile.w > 1 && ${guile} 1 ${srcdir}/wisp-guile.w > 2 && ${guile} 2 ${srcdir}/wisp-guile.w > wisp.scm && diff 2 wisp.scm && echo success)
if [[ ! x"${diff}" == x"success" ]]; then
    echo "failed to bootstrap wisp.scm. diff: " ${diff}
    exit 1
fi
# put all output into stderr via 1>&2 and prefix it with ;;; to make it possible to kill it alongside the auto-compile output from guile with one sed.
echo ";;;" "successfully bootstrapped wisp.scm" 1>&2
