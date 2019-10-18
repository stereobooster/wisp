dnl run `autoreconf -i` to generate a configure script. 
dnl Then run ./configure to generate a Makefile.
dnl Finally run make to generate the project.
AC_INIT([wisp], [1.0.3],
        [arne_bab@web.de])
# Add macros in m4/ to ensure that wisp builds without having Guile in the aclocal path
AC_CONFIG_MACRO_DIR([m4])

# Check for programs I need for my build
AC_CANONICAL_TARGET

# search for Guile using the guile m4 files.
# see https://www.gnu.org/software/guile/manual/html_node/Autoconf-Macros.html
# This provides @GUILE@ to Makefile.am
GUILE_PKG([2.2 2.0 1.8])
GUILE_PROGS
GUILE_SITE_DIR

dnl set installation prefix for language file to Guile location
AC_PREFIX_PROGRAM([guile])

AC_ARG_VAR([python3], [How to call Python 3.])
AC_CHECK_TARGET_TOOL([python3], [python3], [no])
AS_IF([test "x$python3" = "xno"],
      [AC_MSG_WARN([cannot find Python 3 which is required for development bootstrapping.])])

# Is this a normal install, or a "make distcheck"?  We need to disable
# the tests in a "make distcheck" that won't work.
# FIXME: automake should honor DESTDIR set by make distcheck
is_make_distcheck=no
AS_CASE([$prefix],
  [*/_inst],
    [AC_MSG_NOTICE([[Prefix ends in /_inst; this is a 'make distcheck'.]])
     is_make_distcheck=yes])
AM_CONDITIONAL([IS_MAKE_DISTCHECK], [test "x$is_make_distcheck" = x"yes"])
AC_MSG_CHECKING([final decision IS_MAKE_DISTCHECK (running "make distcheck"?)])
AM_COND_IF([IS_MAKE_DISTCHECK], [AC_MSG_RESULT([yes])], [AC_MSG_RESULT([no])]) 

# Run automake
# Use GNU style. Note that ChangeLog is created on every commit 
# by a commit hook in .hg/hgrc
#     [hooks]
#     post-commit = hg log --style changelog > ChangeLog
AM_INIT_AUTOMAKE([gnu])
AM_MAINTAINER_MODE([enable])
AC_CONFIG_FILES([Makefile])
AC_CONFIG_LINKS([tests/realpath.sh:tests/realpath.sh])

AC_OUTPUT
