dnl run `autoreconf -i` to generate a configure script. 
dnl Then run ./configure to generate a Makefile.
dnl Finally run make to generate the project.
AC_INIT([wisp], [0.9.0],
        [arne_bab@web.de])
# Check for programs I need for my build
AC_CANONICAL_TARGET

# search for Guile using the guile m4 files.
# see https://www.gnu.org/software/guile/manual/html_node/Autoconf-Macros.html
# This provides @GUILE@ to Makefile.am
GUILE_PROGS([2.0.11])

AC_ARG_VAR([python3], [How to call Python 3.])
AC_CHECK_TARGET_TOOL([python3], [python3], [no])
AS_IF([test "x$python3" = "xno"],
      [AC_MSG_WARN([cannot find Python 3 which is required for development bootstrapping.])])
# Run automake
# Use GNU style. Note that ChangeLog is created on every commit 
# by a commit hook in .hg/hgrc
#     [hooks]
#     post-commit = hg log --style changelog > ChangeLog
AM_INIT_AUTOMAKE([gnu])
AM_MAINTAINER_MODE([enable])
AC_CONFIG_FILES([Makefile])

AC_OUTPUT
