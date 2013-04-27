Wisp: Whitespace to Lisp
========================

    defun a : b c
      let
        : d e
          : f
            ' g
        h i
        . j

becomes

    (defun a (b c)
      (let 
        ((d e)
         ((f)
          '(g)))
      (h i)
      j))


Wisp turns indentation based syntax into Lisp. The conversion is homoiconic[^h], generic[^g], and backwards-compatible[^b]. It is inspired by project readable, but tries to keep itself simple (and stupid: just a preprocessor). More information on the [wisp-website][].

[wisp-website]: http://draketo.de/light/english/wisp-lisp-indentation-preprocessor

Usage: ./wisp.py infile.wisp > outfile.lisp

More powerful usage (in case you use unix):

    cat infile.wisp | ./wisp.py - | guile -s /dev/stdin

That converts the infile to scheme and executes it via guile.

Or with bash, extend this to a multiline input:

    while IFS= read in ; do echo "$in" ; done | ./wisp.py - | guile -s /dev/stdin

(finish the input with CTRL-D)
(Note: IFS= ensures that initial blanks are kept)

Also see `./wisp-multiline.sh --help`

License: GPLv3 or later.

[^h]: Wisp is homoiconic because everything you write gets turned into lisp which is homoiconic.

[^g]: Wisp is generic, because it works for any language which uses brackets to start a function call - which is true for most lisps. You simply get rid of the speerwall of parentheses without losing their power.

[^b]: Wisp is backwards compatible, because you can simply use arbitrary lisp code in wisp: Indentation processing skipps expressions in brackets.
