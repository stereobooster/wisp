#!/bin/sh
# realpath implementation for systems which lack it (like OSX)
if command -v realpath 2>/dev/null 1>/dev/null; then
    realpath "$@"
elif command -v perl 2>/dev/null 1>/dev/null; then
    perl -MCwd -le 'print Cwd::realpath($ARGV[0])' "$@"
else # fallback, though not getting out of a/../a
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
fi
