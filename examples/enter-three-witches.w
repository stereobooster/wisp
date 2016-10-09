#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples enter-three-witches) main)' -s "$0" "$@"
; !#

define-module : examples enter-three-witches

use-modules : ice-9 optargs
              srfi srfi-1
              system syntax

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

define-syntax Speak
 syntax-rules ::: ()
  ;; Support form for modifiers: enclose by double parens (used later)
  ;; when using this name, print all lines indented, with the name in front.
  : _ (((name :::))) ((mod :::)) (word :::) line :::
    say
      quote : name ::: mod :::
      quote : (word :::) line :::
  ;; extend mod keywords
  : _ (((name :::))) ((mod :::)) modifier line :::
    begin
      ;; extend the modifier keyword list
      Speak (((name :::))) ((mod ::: modifier)) line :::
  ;; say form without modifier
  : _ (((name :::))) (word :::) line :::
    Speak (((name :::))) (()) (word :::) line :::
  ;; first modifier keyword after the name
  : _ (((name :::))) modifier line :::
    begin
      ;; append to mod helper form
      Speak (((name :::))) ((modifier)) line :::
  ;; Strip the name from lines with empty arguments
  : _ (((name :::))) symbol :::
    begin #t symbol :::

define-syntax Enter
 lambda (x)
  syntax-case x ()
   : _ (name more ...) b ...
     ; new binding: only create it if the binding is not already a macro
     not : eq? 'macro (syntax-local-binding (syntax name))
     #' begin
       ;; process the name: define special syntax for this name (only
       ;; for the first word of the name, the correctness of the rest
       ;; of the words is checked at runtime in the say procedure)
       define-syntax name
        lambda (y)
         with-ellipsis :::
          syntax-case y (more ...)
           ; just forward matching rules to Speak
           : _ more ... symbol :::
             #' Speak (((name more ...))) symbol :::
           ; : _ more ... symbol :::
           ;   syntax-error
           ;     . "Name not introduced:" name more ...
           : _ symbol ::: ; FIXME: This prevents checking at compiletime :(
             with-syntax ((oldname (datum->syntax y 'name)))
               ; FIXME: this does not correctly make the second name
               ; part of the name, preventing differentiation between
               ; name and modifier
               #` Speak (((oldname))) symbol :::
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
   : _ (name more ...) b ...
     ; existing binding: Just allow using this. TODO: Make the checking happen at compile time.
     with-syntax ((oldname (datum->syntax x 'name)))
       #' begin 
          set! introduced-names : cons '(name more ...) introduced-names
   : _ b ...
     #' begin 


define : main args
  Enter : First Witch
          Second Witch
          Third Witch
          First Eldritch

  First Witch
      When shall we three meet again
      In thunder, lightning, or in rain?
  
  Second Witch
      When the hurlyburly's done,
      When the battle's lost and won.

  Third Witch
      That will be ere the set of sun.

  First Eldritch
      gnignigni!

  Enter : Second Eldritch
  
  Second Eldritch
      Guh!

;; Adding one who did not enter throws an Error, but only at runtime:
;  Third Eldritch
;      Guh!
;; ⇒ ERROR: Tried to use (Third Eldritch) who did not Enter. Introduced names: ((Second Eldritch) (First Witch) (Second Witch) (Third Witch) (First Eldritch))





