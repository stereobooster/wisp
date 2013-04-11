Wisp: Whitespace-Lisp
=====================

    (defun a (b c)
      (let 
        ((d e)
         ((f)
          '(g)))
      (h i)
      j))

becomes

    defun a (b c)
      let
        : 
          d e
          : 
            f
            ' g
        h i
        . j


Usage: ./wisp.py infile.wisp > outfile.lisp

More powerful usage (in case you use unix):

    cat infile.wisp | ./wisp.py - | guile -s /dev/stdin

That converts the infile to scheme and executes it via guile.

Or with bash, extend this to a multiline input:

    while read in ; do echo $in ; done | ./wisp.py - | guile -s /dev/stdin

(finish the input with CTRL-D)
