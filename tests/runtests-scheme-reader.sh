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
    if guile -L . --language=wisp ${srcdir}/testrunner.w "${i}" "${srcdir}/tests/$(basename "${i}" .w).scm" | grep -q "have equivalent content"; then
        continue
    fi
    echo test "$i" failed. Diff: $(guile -L . --language=wisp ${srcdir}/testrunner.w "${i}" "${srcdir}/tests/$(basename "${i}" .w).scm")
    failed=$((failed + 1))
done
cd - >/dev/null # undo dir change
# if test $failed -eq 0; then echo "Tests succeeded"; 
# else echo "tests failed: ${failed}";
# fi
exit $failed
