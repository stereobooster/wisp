#!/bin/bash

# Simple test runner for wisp, mainly intended to be run by autotools.

if [[ x"$1" == x"" || x"$1" == x"." ]]; then
    srcdir="$(realpath "$(pwd)")"
else
    srcdir="$(realpath "$1")"
fi

if [[ x"$2" == x"" || x"$2" == x"."  ]]; then
    builddir="$(realpath $(pwd))"
else
    builddir="$(realpath "$2")"
fi

failed=0
cd ${builddir}
for i in ${srcdir}/tests/*.w; do
    d=$(guile -L . --language=wisp ${srcdir}/testrunner.w "${i}" "${srcdir}/tests/$(basename "${i}" .w).scm")
    if test $? -eq 0; then
        continue
    else
        echo test "$i" failed. Diff: "$d"
        failed=$((failed + 1))
    fi
done
cd - >/dev/null # undo dir change
# if test $failed -eq 0; then echo "Tests succeeded"; 
# else echo "tests failed: ${failed}";
# fi
exit $failed
