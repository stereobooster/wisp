#!/bin/sh

# if the spec file does not exist yet, run the build chain
if test ! -f language/wisp/spec.scm; then
    # if we are in a distribution tarball, just run configure
    if test -f ./configure; then
        ./configure && make check
    # otherwise run the full autoconf chain
    else
        autoreconf -i && ./configure && make check
    fi
fi

# if the file still does not exist, our chain is broken
if test ! -f language/wisp/spec.scm; then
    echo "ERROR: wisp failed to compile. Please check the previous output."
else
    guile -L . --language=wisp
fi
