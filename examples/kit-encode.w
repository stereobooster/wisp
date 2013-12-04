#!./wisp-multiline.sh
; !#

use-modules 
  srfi srfi-1
  rnrs io ports
  rnrs bytevectors

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
  setlocale LC_ALL ""
  display foo
  newline
; map displaywithnewline
;     map base60encode
;         map inexact->exact testnumbers
; map displaywithnewline
;   map base60decode
;     map base60encode
;         map inexact->exact testnumbers

; This logo is a registered trademark by the Karlsruhe Institute of
; Technology (KIT). Remove this comment at your own risk.
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
; This logo is a registered trademark by the Karlsruhe Institute of
; Technology (KIT). Remove this comment at your own risk.
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


; displaywithnewline : kittify : map inexact->exact : take testnumbers 35
; displaywithnewline : unkittify : kittify : map inexact->exact : take testnumbers 35
; displaywithnewline : map inexact->exact : take testnumbers 35

; Take files, read them as bytevectors, turn the bytevectors into ints and encode them. Same in reverse. Then we can encode any file in kitty-style - uh I mean KIT-style :)

; first some prior work: Optimization for plain text files (to get most regular characters into the 0-60 range).

define : shiftbytedownfortext number
  . "Reduce a number by 65 (A becomes code number 0). If the result is negative, add 256."
  let*
    : reduced : - number 65
    if : >= reduced 0
      . reduced
      + reduced 256

define : shiftbyteupfortext number
  . "Reduce a number by 65 (A becomes code number 0). If the result is negative, add 256."
  let*
    : reduced : + number 65
    if : < reduced 256
      . reduced
      - reduced 256

define* : kittyfile filepath #:optional (text #f)
  . "Kittify the contents of the file at FILEPATH, as individual bytes.

If TEXT is #t, transform the numbers to optimize for text."
  let* 
    : file : open-file-input-port filepath
      bv : get-bytevector-all file
      numbers : bytevector->u8-list bv
      numbers : if text (map shiftbytedownfortext numbers) numbers
    kittify numbers

define : kittytextfile filepath
  . "Kittify the contents of the file at FILEPATH, with a transformation to optimize for text files."
  kittyfile filepath #t

define* : unkittyfile filepath #:optional (text #f)
  . "Un-Kittify the contents of the file at FILEPATH, returning it as bytevector.

If TEXT is #t, transform the numbers to undo the optimization for text."
  let* 
    : file : open-file-input-port filepath
      bv : get-bytevector-all file
      text : utf8->string bv
      numbers : unkittify text
      numbers : if text (map shiftbyteupfortext numbers) numbers
    u8-list->bytevector numbers

define : unkittytextfile filepath
  . "Un-Kittify the contents of the file at FILEPATH, undoing the transformation for text and rendering at utf8-text."
  utf8->string : unkittyfile filepath #t

; displaywithnewline : kittytextfile "examples/kit-encode.w"
; displaywithnewline : kittyfile ".hg/store/00changelog.i"
; displaywithnewline : unkittytextfile "1.kit"

; TODO: Final step: Add commandline handling which allows to write into files and set the text flag and so on.
; ./kit-encode [-e|--encode|-d|--decode] [--text] [--template file] [--killstring "stringtoremove"] [-o|--output file] [file|-]

; Now for the ultimate Kittyfication

displaywithnewline "
     === TEXT MODE ==="

displaywithnewline : kittify : map shiftbytedownfortext : bytevector->u8-list : string->utf8 "Karlsruhe Institut für Technologie (KIT)"

displaywithnewline : utf8->string : u8-list->bytevector : map shiftbyteupfortext : unkittify "
     A.Y  .p.i    .q.p .s.e .b.3i.8.
      k.q  .r.  f.r.   s.r. 3i.c.2A.
 23.p   .3 i.K.b._     .e.k   .m.i
    .m.d .f .b.3i.3    r.A.   8.K.
3s..    .... .  ....   ....   ....
..............    .... ....   ....
Karlsruher Institut fuer Technologie
"


displaywithnewline "

     === BINARY MODE ==="

displaywithnewline : kittify : bytevector->u8-list : string->utf8 "Karlsruhe Institut für Technologie (KIT)"

displaywithnewline : utf8->string : u8-list->bytevector : unkittify "
     1F.  1c.1    u.1o .1v. 1u.1x.1j
      .1g  .Y.  1D.1   q.1v .1w.1k.1
 w.1x   .1 w.Y.1h.     3F.3   8.1u
    .Y.1 Q. 1g.1e.1    j.1q   .1r.
1o.1    r.1i .  1k.1   g.Y.   f.1F
.1D.1Q.g......    .... ....   ....
Karlsruher Institut fuer Technologie
"
