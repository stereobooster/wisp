SUFFICES = .w .scm .sh

sitedir = $(GUILE_SITE)
site_DATA = wisp-scheme.scm

langdir = ${datarootdir}/guile/$(GUILE_EFFECTIVE_VERSION)/language/wisp
lang_DATA = language/wisp/spec.scm

WISP = wisp-guile.w wisp-reader.w wisp-scheme.w

EXTRA_DIST = $(WISP) bootstrap.sh bootstrap-reader.sh examples tests wisp-repl-guile.sh testrunner.w wisp.py wisp.scm
DISTCLEANFILES = ${CLEANFILES} @abs_top_builddir@/1 @abs_top_builddir@/2 @abs_top_builddir@/syntaxtests.sh @abs_top_builddir@/syntaxtestsreader.sh
# don't spout out lots of stuff at each distcheck. Disable for debugging.
AM_DISTCHECK_CONFIGURE_FLAGS="--quiet"

ChangeLog :
	hg log --style changelog > ChangeLog

$(site_DATA) $(lang_DATA): ${WISP} wisp.scm
	@abs_top_srcdir@/bootstrap-reader.sh @abs_top_srcdir@ @abs_top_builddir@ @GUILE@ wisp.scm 2>&1 | sed "s/^;;;.*//" 2>&1 | grep . 1>&2 ; test ! $$? -eq 0 # it worked if grep does not find anything

wisp.scm: wisp-guile.w wisp.py
	@abs_top_srcdir@/bootstrap.sh @abs_top_srcdir@ @GUILE@ @python3@ 2>&1 | sed "s/^;;;.*//" 2>&1 | grep . 1>&2 ; test ! $$? -eq 0 # it worked if grep does not find anything

.PHONY: syntaxtests.sh
syntaxtests.sh : wisp.scm tests/runtests-scheme-preprocessor.sh
	echo '#!/usr/bin/env bash' > @abs_top_builddir@/$@
	echo @abs_top_srcdir@/tests/runtests-scheme-preprocessor.sh @abs_top_srcdir@ @abs_top_builddir@ >> @abs_top_builddir@/$@
	chmod +x @abs_top_builddir@/$@

.PHONY: syntaxtestsreader.sh
syntaxtestsreader.sh : ${WISP} wisp.scm tests/runtests-scheme-reader.sh
	echo '#!/usr/bin/env bash' > @abs_top_builddir@/$@
	echo @abs_top_srcdir@/tests/runtests-scheme-reader.sh @abs_top_srcdir@ @abs_top_builddir@ >> @abs_top_builddir@/$@
	chmod +x @abs_top_builddir@/$@

TESTS=syntaxtests.sh syntaxtestsreader.sh
