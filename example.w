defun a (b c)
  let
    : 
      d "i am a string
do not break me!"
      : 
  ; comment: 0
        f
; comment : 1
        ` g ; comment " : " 2
      : 
        h (I am in brackets:
           do not : change "me")
        . i
  , ' j k

  . l

; comment

  a c

defun b : :n o
  . "second defun : with a docstring!"
  message "I am here"
  . t

defun _ : \:
__
__ . \:

\_ b
      