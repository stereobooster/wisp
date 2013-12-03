#!./wisp-multiline.sh
; !#

define base60chars 
  . "0123456789ABCDEFGHJKLMNPQRSTUVWXYZ_abcdefghijkmnopqrstuvwxyz"

define : base60encode number
  let moddown : (base60 "") (quotient number)
    if : < quotient 60
      string-append (substring base60chars quotient (+ 1 quotient)) base60
      let : : remainder : floor-remainder quotient 60
        moddown 
          string-append 
            substring base60chars remainder : + 1 remainder
            . base60
          floor-quotient quotient 60

define : base60decode string 
  let decode : (number 0) (rest string)
    if : = 1 : string-length rest
       + (* number 60) : string-index base60chars : string-ref rest 0
       decode 
         + (* number 60) : string-index base60chars : string-ref rest 0
         string-drop rest 1

define testnumbers 
  let 
    : start : list 0 1 10 60 59 61 100 1000 1e4 1e5 1e6 1e7 1e8 1e9 64 128
      multiplesof256 1000
    let loop : (numbers start) (exponent 1)
      if : > exponent multiplesof256
        . numbers
        loop 
          append numbers : list : expt 256 exponent
          + 1 exponent
        

define : displaywithnewline foo
  display foo
  newline
; map displaywithnewline 
;     map base60encode 
;         map inexact->exact testnumbers
; map displaywithnewline 
;   map base60decode 
;     map base60encode 
;         map inexact->exact testnumbers

displaywithnewline 
  base60encode : list-ref testnumbers : - (length testnumbers) 1
