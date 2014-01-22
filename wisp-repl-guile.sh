#!/bin/sh

# if the spec file does not exist yet, run the build chain
if test ! -f language/wisp/spec.scm; then
    autoreconf -i && ./configure && make
fi

guile -L . --language=wisp
