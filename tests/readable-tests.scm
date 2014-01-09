(define (fibfast n)
      (if (< n 2))
      n           
      (fibup n 2 1 0 ))

(define (fibup maxnum count n-1 n-2)
       (if (= maxnum count)
         (+ n-1  n-2)
         (fibup maxnum 
               (+ count 1 )
               (+ n-1 n-2 )
               n-1)))

(define (factorial n)
       (if (<= n 1)
         1
         (* n 
           (factorial (- n 1)))))

(define (gcd x y)
       (if (= y 0))
       x
       (gcd y
         (rem x y)))

(define (add-if-all-numbers lst)
       (call/cc 
         (lambda (exit)
                (let loop 
                  (()
                    (lst lst )
                    (sum 0))
                  (if (null? lst)
                     sum
                     (if (not (number? (car lst)))
                        (exit #f)
                        (+ (car lst)
                          (loop (cdr lst)))))))))

