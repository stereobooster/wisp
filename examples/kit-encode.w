#!./wisp-multiline.sh
; !#

use-modules 
  srfi srfi-1

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

define kitlogo "

                                                     ......                   .................   ...............   ...................................
                                              .............                 .................     ...............   ...................................
                                   .          .............               .................       ...............   ...................................
                              ........         ............             .................         ...............   ...................................
                          .............         ...........           .................           ...............   ...................................
                         ...............        ...........         .................             ...............   ...................................
                           ..............        ..........       .................               ...............             ...............
                             .............        .........     ..................                ...............             ...............
                ...            ............       .........   .................                   ...............             ...............
              ........           ............      ........   ...............                     ...............             ...............
             ............          ...........      .......   .............                       ...............             ...............
           .................         .. .......     .......   .............                       ...............             ...............
          .....................        .........     ......   ...............                     ...............             ...............
               ...................       ........    ......   .................                   ...............             ...............
                    .................      ........   .....     .................                 ...............             ...............
                          ..............     .......   ....       .................               ...............             ...............
      ..                       ............    ......  ....         .................             ...............             ...............
      ...........                   ..........   .....  ...           .................           ...............             ...............
     ......................               .......   ...  ..             .................         ...............             ...............
     ................................          .....  .. ..               .................       ...............             ...............
     ..........................................       . . .                 .................     ...............             ...............
     ......................................................                   .................   ...............             ...............

"
define kitlogosmall "
     ...  ....    .... .... ........
      ...  ...  ....   .... ........
 ....   .. .......     ....   ....
    .... .. .......    ....   ....
....    .... .  ....   ....   ....
..............    .... ....   ....
Karlsruher Institut fuer Technologie

"

define : kittify numbers
  . "Display a list of numbers as Text in a KIT Logo."
  let* 
    : base60numbers : map base60encode numbers
      requiredletters : + (length base60numbers) : apply + : map string-length base60numbers
      logo kitlogosmall
      charsinlogo : string-count logo #\.
      requiredlogos : ceiling-quotient requiredletters charsinlogo
      text : xsubstring logo 0 : * requiredlogos : string-length logo
    let logofyer
      : kittified "" ; the new logo with the numbers
        rawlogo text ; the template
        nums base60numbers ; the numbers to add to the logo
        justadded #f ; did I just add a number, in that case, keep one .
      if : equal? rawlogo ""
         . kittified
         let : : s : substring rawlogo 0 1
           if : not : equal? s "."
              logofyer 
                string-append kittified s
                string-drop rawlogo 1
                . nums
                . justadded
              ; else: we have a .
              if justadded ; need one more . to separate numbers
                 logofyer
                   string-append kittified s
                   string-drop rawlogo 1
                   . nums
                   . #f
                 if : = 0 : length nums ; no more numbers to add, just add a .
                   logofyer
                     string-append kittified s
                     string-drop rawlogo 1
                     . nums
                     . #f
                   ; check whether the last number was completely
                   ; added. In that case drop the number and note that
                   ; we just added a number
                   if : = 0 : string-length : list-ref nums 0
                     logofyer
                       . kittified
                       . rawlogo
                       drop nums 1
                       . #t
                     ; otherwise add the first char of the number to
                     ; kittified and take it away from the number.
                     let : : firstnum : list-ref nums 0
                       logofyer
                         string-append kittified : substring firstnum 0 1
                         string-drop rawlogo 1
                         append (list (string-drop firstnum 1)) : drop nums 1
                         . #f ; not yet done



                     

; unkittify: first take out "Karlsruher Institut fuer Technologie" and all spaces and linebreaks, then split by . and base60decode the result.

; we first need a quick way to replace substrings in strings
; taken from string-replace-benchmark.w
define* 
       string-replace-substring s substr replacement 
           . #:optional (start 0) (end (string-length s))
       . "Replace every instance of substring in s by replacement."
       let : : substr-length : string-length substr
          if : zero? substr-length
             error "string-replace-substring: empty substr"
             let loop 
                 : start start
                   pieces : list : substring s 0 start
                 let : : idx : string-contains s substr start end
                   if idx
                     loop : + idx substr-length
                           cons* replacement
                                  substring s start idx
                                  . pieces
                     string-concatenate-reverse 
                                                cons : substring s start
                                                    . pieces


define : emptystring? string
  if : equal? "" string 
    . #t
    . #f

define : unkittify text
  . "Turn a kittified string into a list of numbers."
  ; first remove the name and spaces
  let*
    : text : string-replace-substring text "Karlsruher Institut fuer Technologie" ""
      text : string-replace-substring text " " ""
      text : string-replace-substring text "\n" ""
      text : string-replace-substring text "\r" ""
      base60numbers : string-split text #\.
      base60numbers : remove emptystring? base60numbers
    map base60decode base60numbers

display : unkittify : kittify : map inexact->exact : take testnumbers 35
newline


; TODO: Final step: Take files, read them as bytevectors, turn the bytevectors into ints and encode them. Same in reverse. Then we can encode any file in kitty-style - uh I mean KIT-style :)



