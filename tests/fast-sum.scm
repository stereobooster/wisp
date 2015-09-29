(use-modules (srfi srfi-1))


(define-syntax fast-sum
  (syntax-rules (iota)
    ((fast-sum (iota count start))
     (+ 1
        (apply - (map (lambda (x) (/ (* x (+ x 1)) 2))
                      (list (+ count (- start 1)) start)))))
    ((fast-sum e)
     (apply + e))))
