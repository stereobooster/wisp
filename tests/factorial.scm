;; short version
; note: once you use one inline colon, all the following forms on that
; line will get closed at the end of the line

(define (factorial n)
  (if (zero? n)
    1
    (* n (factorial (- n 1)))))

(display (factorial 5 ))


;; more vertical space, less colons
(define (factorial n)
  (if (zero? n)
    1
    (* n 
      (factorial 
        (- n 1)))))

(display (factorial 5 ))



