#!/usr/bin/env sh
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples enter-three-witches) main)' -s "$0" "$@"
; !#

define-module : examples enter-three-witches

use-modules : ice-9 optargs
              srfi srfi-1

;; FIXME: This version currently does not allow using the same first
;; name several times. It will need a more refined macro generator
;; which first gathers all the necessary definitions and then builds
;; them.

define introduced-names '()

define : say nameparts lines
       . "Show the lines as said by the name defined by the list
of name parts.
       "
       let 
         ;; symbols starting with : are not treated as part of the
         ;; name. They can be used as actor instructions
         : pure-name : remove (lambda (x) (string-prefix? ":" (symbol->string x))) nameparts
         if : not : member pure-name introduced-names
              error 
                format #f "Tried to use ~A who did not Enter. Introduced names: ~A" 
                  . pure-name introduced-names
       format #t "~A\n  ~A\n\n"
         string-join : map symbol->string nameparts
         string-join
           map : lambda (x) (string-join (map symbol->string x))
               . lines
           . "\n  "

define-syntax Enter
 syntax-rules ()
  : _ (name more ...) b ...
    begin
      ;; process the name: define special syntax for this name (only
      ;; for the first word of the name, the correctness of the rest
      ;; of the words is checked at runtime in the say procedure)
      define-syntax name
        syntax-rules ::: (more ...)
          ;; Support form for modifiers: enclose by double parens (used later)
          ;; when using this name, print all lines indented, with the name in front.
          : _ more ... ((mod :::)) (word :::) line :::
            say
              ` name more ... mod :::
              quote : (word :::) line :::
          ;; extend mod keywords
          : _ more ... ((mod :::)) modifier line :::
            begin
              ;; extend the modifier keyword list
              name ((mod ::: modifier)) line :::
          ;; say form without modifier
          : _ more ... (word :::) line :::
            say
              ' name more ...
              quote : (word :::) line :::
          ;; first modifier keyword after the name
          : _ more ... modifier line :::
            begin
              ;; append to mod helper form
              name ((modifier)) line :::
          ;; Strip the name from lines with empty arguments
          : _ more ... symbol :::
            begin #t symbol :::
          ; : _ more ... symbol :::
          ;   syntax-error
          ;     . "Name not introduced:" name more ...
      ;; process the rest of the names
      Enter b ...
      ;; record that the name was introduced. I do not see a way to do
      ;; this directly in the compiler, therefore it is checked later
      ;; during runtime.
      set! introduced-names : cons '(name more ...) introduced-names
      ;; add debug output, must be added it here, not in front
      ; write 
      ;   quote : list Enter (name more ...) b ...
      ; newline
  : _ b ...
    begin 


define : main args
  Enter : First Witch
          Second Witch
          Third Witch
  
  First Witch
      When shall we three meet again
      In thunder, lightning, or in rain?
  
  Second Witch
      When the hurlyburly's done,
      When the battle's lost and won.

  Third Witch
      That will be ere the set of sun.

