use-modules : srfi srfi-1

; only for the nice test
. #!curly-infix

define-syntax fast-sum
  syntax-rules : iota
    : fast-sum : iota count start
      + 1
        apply - 
          map : lambda (x) : / {x * {x + 1} } 2
                list {count + {start - 1}} start
    : fast-sum e
      apply + e
