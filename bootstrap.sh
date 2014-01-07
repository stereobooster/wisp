#!/bin/sh

# Bootstrap wisp-guile with wisp.py
if [[ x"$1" == x"" ]]; then 
    srcdir=.
else
    srcdir="$1"
fi

diff=$(python3 ${srcdir}/wisp.py ${srcdir}/wisp-guile.w > 1 && guile 1 ${srcdir}/wisp-guile.w > 2 && guile 2 ${srcdir}/wisp-guile.w > wisp.scm && diff 2 wisp.scm && echo success)
if [[ x"${diff}" == x"success" ]]; then
    echo "successfully bootstrapped wisp.scm"
    echo preparing the reader: wisp at the REPL
    mkdir -p language/wisp
    guile wisp.scm ${srcdir}/wisp-reader.w 2>/dev/null > language/wisp/spec.scm \
        && echo ...succeeded \
        && echo 'to use wisp at the REPL, run `guile -L` . and then in guile `,L wisp`'
else
    echo "failed to bootstrap wisp.scm. diff: " ${diff}
fi
