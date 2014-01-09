; Test using a . as first parameter on a line by prefixing it with a second .
(define
  (a i
    . b)
  (unless (>= i (length b))
    (display (number->string (length b )))
    (display (list-ref b i))
    (newline)
    (apply a ( + i 1 ) b)))
    

(a 0 "123" "345" "567")


