#!./wisp-multiline.sh
; !#

define base60chars 
  . "0123456789ABCDEFGHJKLMNPQRSTUVWXYZ_abcdefghijkmnopqrstuvwxyz"

define : base60encode number
  let moddown : (base60 "") (quotient number)
    if : < quotient 60
      string-append (string-ref base60chars quotient) base60
      moddown 
        string-append : string-ref base60chars : floor-remainder quotient 60
        floor-quotient quotient 60

define : base60decode string 
  display string

