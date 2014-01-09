wisp = wisp.scm language/wisp/spec.scm
wisp_SOURCES = wisp-guile.w wisp-reader.w
EXTRA_DIST = $(wisp_SOURCES) $(wisp_DATA) bootstrap.sh wisp.py examples tests runtests.sh
CLEANFILES = ${wisp} 
DISTCLEANFILES = ${CLEANFILES} @abs_top_builddir@/1 @abs_top_builddir@/2 @abs_top_builddir@/test.sh

all : ${wisp} $(changelog)

# emacs org-mode beamer build instructions
${wisp} : input.in.intermediate

.INTERMEDIATE: input.in.intermediate
input.in.intermediate: ${wisp_SOURCES}
	@abs_top_srcdir@/bootstrap.sh @abs_top_srcdir@

.PHONY: test.sh
test.sh : wisp.scm runtests.sh
	echo '#!/bin/bash' > @abs_top_builddir@/test.sh
	echo @abs_top_srcdir@/runtests.sh @abs_top_srcdir@ @abs_top_builddir@ >> @abs_top_builddir@/test.sh
	chmod +x @abs_top_builddir@/test.sh

TESTS=test.sh
