wisp = wisp.scm language/wisp/spec.scm
wisp_SOURCES = wisp-guile.w wisp-reader.w
EXTRA_DIST = $(wisp_SOURCES) $(wisp_DATA) bootstrap.sh wisp.py examples tests
CLEANFILES = ${wisp} 
DISTCLEANFILES = ${CLEANFILES} @builddir@/1 @builddir@/2

all : ${wisp} $(changelog)

# emacs org-mode beamer build instructions
${wisp} : input.in.intermediate

.INTERMEDIATE: input.in.intermediate
input.in.intermediate: ${wisp_SOURCES}
	@srcdir@/bootstrap.sh @srcdir@
