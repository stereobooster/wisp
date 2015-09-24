#!/bin/bash

# Simple test runner for wisp, mainly intended to be run by autotools.

if [[ x"$1" == x"" || x"$1" == x"." ]]; then
    srcdir="$(pwd)"
else
    srcdir="$1"
fi

if [[ x"$2" == x"" || x"$2" == x"."  ]]; then
    builddir="$(pwd)"
else
    builddir="$2"
fi

failed=0
cd ${srcdir}/tests
for i in *.w; do
    # skip strangecomments
    if test x"${i}" = x"strangecomments.w"; then continue; fi
    d=$(guile ${srcdir}/wisp.scm "$i" > ${builddir}/testtempfoo.scm; diff -wuB ${builddir}/testtempfoo.scm "$(basename "$i" .w)".scm; rm ${builddir}/testtempfoo.scm)
    if test x"$d" = x""; then
        continue
    else
        echo test "$i" failed. Diff: "$d"
        failed=1
    fi
done
cd - >/dev/null # undo dir change
exit $failed
