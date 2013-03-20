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



