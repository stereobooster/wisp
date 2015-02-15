; http://stackoverflow.com/questions/23167464/scheme-self-reference-lambda-macro
; because this is as cool as things get
define-syntax slambda
  lambda : x
    syntax-case x :
      : slambda formals body0 body1 ...
        with-syntax 
                    : self : datum->syntax #'slambda 'self
                    #' letrec : : self : lambda formals body0 body1 ...
                       . self



: 
  slambda (x) : + x 1
  . 10

: slambda () self

