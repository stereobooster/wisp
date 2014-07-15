wisp = wisp.scm language/wisp/spec.scm
wisp_SOURCES = wisp-guile.w wisp-reader.w
EXTRA_DIST = $(wisp_SOURCES) $(wisp_DATA) bootstrap.sh wisp.py examples tests runtests.sh wisp-repl-guile.sh
CLEANFILES = ${wisp} ChangeLog
DISTCLEANFILES = ${CLEANFILES} @abs_top_builddir@/1 @abs_top_builddir@/2 @abs_top_builddir@/syntaxtests.sh

all : ${wisp}

ChangeLog :
	hg log --style changelog > ChangeLog

# emacs org-mode beamer build instructions
${wisp} : input.in.intermediate

.INTERMEDIATE: input.in.intermediate
input.in.intermediate: ${wisp_SOURCES}
	@abs_top_srcdir@/bootstrap.sh @abs_top_srcdir@ @guile@ @python3@ 2>&1 | sed "s/;;;.*//" 2>&1 | grep . 1>&2 ; test ! $$? -eq 0 # grep did not find anything

.PHONY: syntaxtests.sh
syntaxtests.sh : wisp.scm runtests.sh
	echo '#!/bin/bash' > @abs_top_builddir@/syntaxtests.sh
	echo @abs_top_srcdir@/runtests.sh @abs_top_srcdir@ @abs_top_builddir@ >> @abs_top_builddir@/syntaxtests.sh
	chmod +x @abs_top_builddir@/syntaxtests.sh

TESTS=syntaxtests.sh
