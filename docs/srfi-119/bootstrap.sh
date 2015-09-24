#!/bin/sh

# Bootstrap wisp using Python 3

# This creates wisp-preprocessor.scm (the version in the tarball is called wisp-guile.scm to avoid overwriting it)
# and wisp-parser.scm (the version in the tarball is called wisp-scheme.scm)

# usage: guile wisp-preprocessor.scm <wisp-file> > <scheme-file>

# wisp-parser.scm provides procedures for reading s-expressions from wisp-files.

python3 wisp.py wisp-guile.w > 1 \
  && guile 1 wisp-guile.w > 2 \
  && guile 2 wisp-guile.w > wisp-preprocessor.scm \
  && diff 2 wisp-preprocessor.scm \
  && guile wisp-preprocessor.scm wisp-scheme.w > wisp-parser.scm \
  && rm 1 2

