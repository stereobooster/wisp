(import (rnrs))

(define range
 (case-lambda
   ((n ); one-argument syntax
     (range 0 n 1))
   ((n0 n ); two-argument syntax
     (range n0 n 1))
   ((n0 n s ); three-argument syntax
     (assert 
         (and 
             (for-all number? (list n0 n s))
             (not (zero? s))))
     (let ((cmp (if (positive? s) >= <= )))
       (let loop 
           ((i n0 )
             (acc '()))
           (if 
             (cmp i n )
             (reverse acc)
             (loop (+ i s) (cons i acc))))))))
             
(display (apply string-append "" (map number->string (range 5))))
(newline)

