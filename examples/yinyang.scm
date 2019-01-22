; from http://en.wikipedia.org/wiki/Scheme_%28programming_language%29
(let* 
   (
     (yin
         ((lambda (cc) (display "@") cc)
           (call/cc (lambda (c) c))))
     (yang
         ((lambda (cc) (display "*") cc )
           (call/cc (lambda (c) c)))))
   (yin yang))



