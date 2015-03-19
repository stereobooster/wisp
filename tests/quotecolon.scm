#!/home/arne/wisp/wisp-multiline.sh  
; !#
(define a 1 ); test whether ' : correctly gets turned into '(
; and whether brackets in commments are treated correctly.

(define a '(1 2 3))

(define
  (a b)
  (c))

(define a (quasiquote ,(+ 2 2)))
