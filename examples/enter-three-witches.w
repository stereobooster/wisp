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

define : ->string x
       cond
         : symbol? x
           symbol->string x
         : number? x
           format #f "~a" x
         else
           format #f "~A" x

define : say nameparts lines
       . "Show the lines as said by the name defined by the list
of name parts.
       "
       let 
         ;; symbols starting with : are not treated as part of the
         ;; name. They can be used as actor instructions
         : pure-name : remove (lambda (x) (string-prefix? ":" (symbol->string x))) : remove pair? nameparts
         if : not : member pure-name introduced-names
              error 
                format #f "Tried to use ~A who did not Enter. Introduced names: ~A" 
                  . pure-name introduced-names
       format #t "~A\n  ~A\n\n"
         string-join : map symbol->string nameparts
         string-join
           map : lambda (x) (string-join (map ->string x))
               . lines
           . "\n  "


define : longest-common-prefix li introduced-names
       . "Get the name with the longest common prefix with list li"
       let loop
         : names introduced-names
           longest '()
         if : null? names
            reverse longest
            let lp
              : prefix '()
                name : car names
                l li
              if
                or 
                  null? name
                  null? l
                  not : equal? (car name) (car l)
                loop 
                  cdr names
                  if (> (length prefix) (length longest))
                     . prefix
                     . longest
                lp
                  cons (car name) prefix
                  cdr name
                  cdr l


define : Squeak . li
       . "somehow say the given list"
       let : : name : longest-common-prefix li introduced-names
         say name : drop li (length name)
       

define-syntax Speak
 lambda (x)
  with-ellipsis :::
   syntax-case x ()
     ;; Support form for modifiers: enclose by double parens (used later)
     ;; when using this name, print all lines indented, with the name in front.
     : _ (((name :::))) ((mod :::)) (word :::) line :::
         #` say
             quasiquote : name ::: mod :::
             quasiquote : (word :::) line :::
     ;; extend mod keywords
     : _ (((name :::))) ((mod :::)) modifier line :::
         ;; extend the modifier keyword list
         #` Speak (((name :::))) ((mod ::: modifier)) line :::
     ;; say form without modifier
     : _ (((name :::))) (word :::) line :::
         #` Speak (((name :::))) (()) (word :::) line :::
     ;; first modifier keyword after the name
     : _ (((name :::))) modifier line :::
         ;; append to mod helper form
         #` Speak (((name :::))) ((modifier)) line :::
     ;; Strip the name from lines with empty arguments
     : _ (((name :::))) symbol :::
         #` begin #t symbol :::


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
           : _ symbol ::: ; FIXME: This prevents checking at compiletime :(
               ; this does not correctly make the second name part of
               ; the name, preventing differentiation between name and
               ; modifier, therefore we have to do that in the Speak
               ; macro
               #` let* 
                    : n : longest-common-prefix '(name symbol :::) introduced-names
                      lines : drop '(symbol :::) : 1- : length n
                      line-start-index : list-index pair? lines
                      line-head : drop-right lines : - (length lines) line-start-index
                      line-tail : drop lines line-start-index
                    say
                      append n line-head ; add mood markers
                      . line-tail
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
  
  Second Witch :resolute
      When the hurlyburly's done, (we ,(+ 1 2)) ; inline-code is allowed!
      When the battle's lost and won.

  Third Witch
      That will be ere the set of sun.

  First Eldritch :crazy
      gnignigni!

  Enter : Second Eldritch
  
  Second Eldritch :quick
      Guh!
      ; . :goo ; invalid ⇒ would be an error
      ; . foo ; invalid ⇒ would be an error
      Moo

;; Making the name longer throws an Error, but only at runtime:
;  Second Eldritch shoo
;      Guh!
;; ⇒ ERROR: Tried to use (Second Eldritch shoo) who did not Enter. Introduced names: ((Second Eldritch) (First Witch) (Second Witch) (Third Witch) (First Eldritch))

;; Adding one who did not enter throws an Error, but only at runtime:
;  Third Eldritch
;      Guh!
;; ⇒ ERROR: Tried to use (Third Eldritch) who did not Enter. Introduced names: ((Second Eldritch) (First Witch) (Second Witch) (Third Witch) (First Eldritch))





