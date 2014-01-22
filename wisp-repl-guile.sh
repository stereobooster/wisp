#!/bin/sh

# if the spec file does not exist yet, run the build chain
if test ! -f language/wisp/spec.scm; then
    autoreconf -i && ./configure && make check
fi

# if the file still does not exist, our chain is broken
if test ! -f language/wisp/spec.scm; then
    echo "ERROR: wisp failed to compile. Please check the previous output."
else
    guile -L . --language=wisp
fi
