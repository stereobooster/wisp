# automake: explicitly set the supported suffixes
SUFFIXES = .w .scm .sh

# define the programs to install
bin_SCRIPTS = wisp2lisp

# where to install guile modules to import
sitedir = $(datarootdir)/guile/site/$(GUILE_EFFECTIVE_VERSION)
site_DATA = wisp.scm

# where to install the language modules
langdir = $(sitedir)/language
# nobase_ as prefix prevents stripping leading directories
# see https://www.gnu.org/software/automake/manual/html_node/Alternative.html#index-nobase_005f
nobase_lang_DATA = language/wisp.scm language/wisp/spec.scm

GOBJECTS = $(nobase_lang_DATA:%.scm=%.go)
nobase_go_DATA = $(GOBJECTS)
godir=$(libdir)/guile/$(GUILE_EFFECTIVE_VERSION)/site-ccache

WISP = wisp-guile.w wisp-reader.w wisp-scheme.w

# Make sure source files are installed first, so that the mtime of
# installed compiled files is greater than that of installed source
# files.  See
# <http://lists.gnu.org/archive/html/guile-devel/2010-07/msg00125.html>
# for details.
guile_install_go_files = install-nobase_go_DATA
$(guile_install_go_files): install-nobase_lang_DATA

EXTRA_DIST = $(WISP) bootstrap.sh bootstrap-reader.sh language examples tests wisp-repl-guile.sh testrunner.w wisp.py wisp.scm m4 ob-wisp.el wisp-mode.el AUTHORS.in
CLEANFILES = 1 2 $(GOBJECTS)
DISTCLEANFILES = $(bin_SCRIPTS) $(site_DATA) $(nobase_lang_DATA)
# don't spout out lots of stuff at each distcheck. Disable for debugging.
AM_DISTCHECK_CONFIGURE_FLAGS="--quiet"

# precompile all scheme files
.scm.go:
	$(GUILE_TOOLS) compile $(GUILE_WARNINGS) -o "$@" "$<"

wisp2lisp: wisp.scm ## build only the wisp2lisp converter
	cp $< $@

.INTERMEDIATE: .mydatastuff
$(nobase_lang_DATA): .wispbootstrap
.wispbootstrap : ${WISP} wisp.scm
	@abs_top_srcdir@/bootstrap-reader.sh @abs_top_srcdir@ @abs_top_builddir@ @GUILE@ wisp.scm 2>&1 | sed "s/^;;;.*//" 2>&1 | grep . 1>&2 ; test ! $$? -eq 0 # it worked if grep does not find anything

wisp.scm: wisp-guile.w wisp.py
	@abs_top_srcdir@/bootstrap.sh @abs_top_srcdir@ @GUILE@ @python3@ 2>&1 | sed "s/^;;;.*//" 2>&1 | grep . 1>&2 ; test ! $$? -eq 0 # it worked if grep does not find anything
	chmod +x $@

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

ACLOCAL_AMFLAGS = -I m4

.PHONY: help
help: ## Show this help message.
	@echo 'Usage:'
	@echo ':make [target] ...' | sed "s/\(target\)/\\x1b[36m\1\\x1b[m/" | column -c2 -t -s :
	@echo
	@echo 'Targets:'
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/:\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
	@echo
	@echo '(see ./configure --help for setup options)'


# create basic files for the tarballl
.SECONDARY: ChangeLog AUTHORS
ChangeLog: ## create the ChangeLog from the history
	echo "For user-visible changes, see the NEWS file" > "$@"
	echo >> "$@"
	if test -d "@abs_top_srcdir@/.git"; then cd @abs_top_srcdir@; git log --date-order --date=short | sed -e '/^commit.*$/d' | awk '/^Author/ {sub(/\\$/,""); getline t; print $0 t; next}; 1' | sed -e 's/^Author: //g' | sed -e 's/\(.*\)>Date:   \([0-9]*-[0-9]*-[0-9]*\)/\2  \1>/g' | sed -e 's/^\(.*\) \(\)\t\(.*\)/\3    \1    \2/g' >> "$@"; cd -; fi
	if test -d "@abs_top_srcdir@/.hg"; then hg -R "@abs_top_srcdir@" log --style changelog >> "$@"; fi
AUTHORS: AUTHORS.in ## create the AUTHORS file from the history and AUTHORS.in
	cp "$<" "$@"
	if test -d "@abs_top_srcdir@/.git"; then cd "@abs_top_srcdir@"; git log --format='%aN' | sort -u >> "$@"; cd -; fi
	if test -d "@abs_top_srcdir@/.hg"; then hg -R "@abs_top_srcdir@" --config extensions.churn= churn -t "{author}" >> "$@"; fi
