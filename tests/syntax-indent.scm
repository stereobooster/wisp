(define 
  (hello who)
  (format #t "Hello ~A\n" who))

(define
    (let
      (
        (a 1)
        (b 2)
        (c 3))
      (format #t "a: ~A, b: ~A, c: ~A"
                   (+ a 2)
                          b      c)))



