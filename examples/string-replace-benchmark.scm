(define-module (examples string-replace-benchmark)
              #:export (string-replace-substring string-replace-substring/startindex string-replace-substring/addindex string-replace-substring/naive))

; ,time (string-replace-substring (xsubstring "abcdefghijkl" 0 99999) "def" "abc")
; 0.010369s real time, 0.010348s run time.  0.000000s spent in GC.
(define* 
       (string-replace-substring s substr replacement 
           #:optional (start 0) (end (string-length s)))
       "Replace every instance of substring in s by replacement."
       (let ((substr-length (string-length substr)))
          (if (zero? substr-length)
             (error "string-replace-substring: empty substr")
             (let loop 
                 ((start start)
                   (pieces (list (substring s 0 start))))
                 (let ((idx (string-contains s substr start end)))
                   (if idx
                     (loop (+ idx substr-length)
                           (cons* replacement
                                  (substring s start idx)
                                  pieces))
                     (string-concatenate-reverse 
                                                (cons (substring s start)
                                                    pieces))))))))

; ,time (string-replace-substring (xsubstring "abcdefghijkl" 0 99999) "def" "abc")
; 1.112429s real time, 1.083435s run time.  0.780863s spent in GC.
(define (string-replace-substring/startindex s substring replacement)
       "Replace every instance of substring in s by replacement."
       (let ((sublen (string-length substring)))
           (let replacer
               ((newstring s)
                 (index (string-contains s substring)))
               (if (not (equal? index #f))
                  (let ((replaced (string-replace newstring replacement index (+ index sublen))))
                    (replacer replaced (string-contains replaced substring index ))); only look at parts after index
                  newstring))))


; ,time (string-replace-substring (xsubstring "abcdefghijkl" 0 99999) "def" "abc")
; 1.044660s real time, 1.042901s run time.  0.761600s spent in GC.
(define (string-replace-substring/addindex s substring replacement)
       "Replace every instance of substring in s by replacement."
       (let ((sublen (string-length substring)))
           (let replacer
               ((newstring s)
                 (startindex 0)
                 (addindex (string-contains s substring)))
               (if (not (equal? addindex #f))
                  (let*
                      ((index (+ startindex addindex))
                        (replaced (string-replace newstring replacement index (+ index sublen)))
                        (newaddindex (string-contains (substring/read-only replaced index) substring)))
                      (replacer replaced index newaddindex))
                  newstring))))


; ,time (string-replace-substring (xsubstring "abcdefghijkl" 0 99999) "def" "abc")
; 7.547528s real time, 7.534397s run time.  0.764280s spent in GC.
(define (string-replace-substring/naive s substring replacement)
       "Replace every instance of substring in s by replacement."
       (let ((sublen (string-length substring)))
           (let replacer
               ((newstring s)
                 (index (string-contains s substring)))
               (if (not (equal? index #f))
                  (let ((replaced (string-replace newstring replacement index (+ index sublen))))
                    (replacer replaced (string-contains replaced substring)))
                  newstring))))


