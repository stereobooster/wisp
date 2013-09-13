#!/bin/sh

# Bootstrap wisp-guile with wisp.py

diff=$(python3 wisp.py wisp-guile.w > 1 && guile 1 wisp-guile.w > 2 && guile 2 wisp-guile.w > wisp.scm && diff 2 wisp.scm)
if [[ x"${diff}" == x ]]; then
    echo "successfully bootstrapped wisp.scm"
else
    echo "failed to bootstrap wisp.scm. diff: " ${diff}
fi

# Now setup the reader so we can use it with guile -L . and then > ,L wisp

mkdir -p language/wisp
guile wisp.scm wisp-reader.w > language/wisp/spec.scm
