#!/bin/bash

if [[ x"$1" == x"" ]]; then 
    srcdir=.
else
    srcdir="$1"
fi

if [[ x"$2" == x"" ]]; then 
    guile='guile'
else
    guile="$2"
fi

if [[ x"$3" == x"" ]]; then 
    wisp=wisp.scm
else
    wisp="$3"
fi



mkdir -p language/wisp

echo ";;;" preparing the reader: wisp at the REPL 1>&2

echo ";;;" parsing wisp-scheme.w with the parser for the REPL 1>&2
${guile} ${wisp} ${srcdir}/wisp-scheme.w 2>/dev/null > wisp-scheme.scm \
    && echo ";;;" ...precompiling the parser... 1>&2 \
    && ${guile} -s wisp-scheme.scm 2>/dev/null \
    && echo ";;;" ...succeeded 1>&2 \

echo ";;;"  parsing the spec file... 1>&2
${guile} ${wisp} ${srcdir}/wisp-reader.w 2>/dev/null > language/wisp/spec.scm \
    && echo ";;;" ...precompiling the spec file... 1>&2 \
    && ${guile} -L . -s language/wisp/spec.scm \
    && echo ";;;" ...succeeded 1>&2 \
    && echo ";;;" to use wisp at the REPL, run '`'${guile} -L . --language=wisp'`' 1>&2
