#!/home/arne/wisp/wisp-multiline.sh  
; !#
(define (hello who)
  (display who))

(let hello
  ((who 0))
  (if (= who 5)
    (display who)
    (hello (+ 1 who))))


