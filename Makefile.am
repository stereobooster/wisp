SUFFIXES = .w .scm .sh

sitedir = $(GUILE_SITE)
site_DATA = language/wisp.scm

langdir = ${datarootdir}/guile/site/$(GUILE_EFFECTIVE_VERSION)/language/wisp
lang_DATA = language/wisp/spec.scm language/wisp.scm

WISP = wisp-guile.w wisp-reader.w wisp-scheme.w

EXTRA_DIST = $(WISP) bootstrap.sh bootstrap-reader.sh language examples tests wisp-repl-guile.sh testrunner.w wisp.py wisp.scm m4
CLEANFILES = 1 2
DISTCLEANFILES = $(lang_DATA) $(site_DATA)
# don't spout out lots of stuff at each distcheck. Disable for debugging.
AM_DISTCHECK_CONFIGURE_FLAGS="--quiet"

ChangeLog :
	hg log --style changelog > ChangeLog

.INTERMEDIATE: .mydatastuff
$(site_DATA) $(lang_DATA): .wispbootstrap
.wispbootstrap : ${WISP} wisp.scm
	@abs_top_srcdir@/bootstrap-reader.sh @abs_top_srcdir@ @abs_top_builddir@ @GUILE@ wisp.scm 2>&1 | sed "s/^;;;.*//" 2>&1 | grep . 1>&2 ; test ! $$? -eq 0 # it worked if grep does not find anything

wisp.scm: wisp-guile.w wisp.py
	@abs_top_srcdir@/bootstrap.sh @abs_top_srcdir@ @GUILE@ @python3@ 2>&1 | sed "s/^;;;.*//" 2>&1 | grep . 1>&2 ; test ! $$? -eq 0 # it worked if grep does not find anything

.INTERMEDIATE: syntaxtests.sh
syntaxtests.sh : wisp.scm tests/runtests-scheme-preprocessor.sh
	echo '#!/usr/bin/env bash' > @abs_top_builddir@/$@
	echo @abs_top_srcdir@/tests/runtests-scheme-preprocessor.sh @abs_top_srcdir@ @abs_top_builddir@ >> @abs_top_builddir@/$@
	chmod +x @abs_top_builddir@/$@

.INTERMEDIATE: syntaxtestsreader.sh
syntaxtestsreader.sh : ${WISP} wisp.scm tests/runtests-scheme-reader.sh
	echo '#!/usr/bin/env bash' > @abs_top_builddir@/$@
	echo @abs_top_srcdir@/tests/runtests-scheme-reader.sh @abs_top_srcdir@ @abs_top_builddir@ >> @abs_top_builddir@/$@
	chmod +x @abs_top_builddir@/$@

TESTS=syntaxtests.sh syntaxtestsreader.sh

# The installchecks won't work in a "make distcheck", because
# they won't be installed in the final location used by the tools.
# FIXME: automake should honor DESTDIR set by make distcheck
if IS_MAKE_DISTCHECK
install-siteDATA:
	echo "Running 'make distcheck'; local installchecks disabled."
install-langDATA:
	echo "Running 'make distcheck'; local installchecks disabled."
uninstall-siteDATA:
	echo "Running 'make distcheck'; local installchecks disabled."
uninstall-langDATA:
	echo "Running 'make distcheck'; local installchecks disabled."
else !IS_MAKE_DISTCHECK
endif !IS_MAKE_DISTCHECK

ACLOCAL_AMFLAGS = -I m4
