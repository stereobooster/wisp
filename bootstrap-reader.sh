#!/bin/bash

if [[ x"$1" == x"" ]]; then 
    srcdir=.
else
    srcdir="$1"
fi

if [[ x"$2" == x"" ]]; then 
    builddir=.
else
    builddir="$2"
fi


if [[ x"$3" == x"" ]]; then 
    guile='guile'
else
    guile="$3"
fi


if test -f wisp.scm; then 
    wisp=wisp.scm
elif test -f "${builddir}/wisp.scm"; then
    wisp="${builddir}/wisp.scm"
else
    wisp="${srcdir}/wisp.scm"
fi


mkdir -p ${builddir}/language/wisp

echo ";;;" preparing the reader: wisp at the REPL 1>&2

echo ";;;" parsing wisp-scheme.w with the parser for the REPL 1>&2
${guile} ${wisp} ${srcdir}/wisp-scheme.w 2>/dev/null > ${builddir}/wisp-scheme.scm \
    && echo ";;;" ...precompiling the parser... 1>&2 \
    && ${guile} -s ${builddir}/wisp-scheme.scm 2>/dev/null \
    && echo ";;;" ...succeeded 1>&2 \
    || echo creating wisp-scheme.scm failed

echo ";;;"  parsing the spec file... 1>&2
${guile} ${wisp} ${srcdir}/wisp-reader.w 2>/dev/null > ${builddir}/language/wisp/spec.scm \
    && echo ";;;" ...precompiling the spec file... 1>&2 \
    && ${guile} -L . -s ${builddir}/language/wisp/spec.scm \
    && echo ";;;" ...succeeded 1>&2 \
    && echo ";;;" to use wisp at the REPL, run '`'${guile} -L . --language=wisp'`' 1>&2 \
    || echo creating language/wisp/spec.scm failed

