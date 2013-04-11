#!/bin/bash
# wisp-call.sh --- run multiline wisp code

# Copyright (C) 2013 Arne Babenhauserheide <arne_bab@web.de>

# Author: Arne Babenhauserheide <arne_bab@web.de>

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

version="wisp call 0.1"

# Parse commandline options

getopt -T > /dev/null
if [ $? -eq 4 ]; then
    # GNU enhanced getopt is available
    set -- `getopt --long help,lisp:,verbose,version --options hl:v -- "$@"`
else
    # Original getopt is available
    set -- `getopt hl:v "$@"`
fi

PROGNAME=`basename $0`
ARGS=`getopt --name "$PN" --long help,lisp:,verbose,version --options hl:v -- "$@"`
if [ $? -ne 0 ]; then
  exit 1
fi
eval set -- $ARGS

# default options
HELP=no
LISP=guile
verbose=no
VERSION=no

while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)     HELP=yes;;
        -l | --lisp)     LISP="$2"; shift;;
        -v | --verbose)  VERBOSE=yes;;
        --version)       VERSION=yes;;
        --)              shift; break;;
    esac
    shift
done

if [ $# -gt 0 ]; then
  # Remaining parameters can be processed
  for ARG in "$@"; do
    echo "$PROGNAME: argument: $ARG"
  done
fi

# Provide help output

if [[ $HELP == "yes" ]]; then
    echo "$0 [-h] [-l] [-v]
        -h | --help)     This help output.
        -l | --lisp)     Select the Lisp interpreter to call. Options: guile
        -v | --verbose)  Provide verbose output.
        --version)       Print the version string of this script.
"
    exit 0
fi

if [[ $VERSION == "yes" ]]; then
    echo "$version"
    exit 0
fi

# Select the lisp interpreter

if [[ $LISP != "guile" ]]; then
    echo "Interpreter $LISP not known."
    exit 1
fi

# Run the code

echo ";; Welcome to wisp. Please enter your code. 
;; Finish with two linebreaks, then execute with CTRL-D."

while IFS= read wisp ; do echo "$wisp" ; done | ./wisp.py - | guile -s /dev/stdin



