use-modules : sxml simple
use-modules : ice-9 match

; define a template
define template
   quote
     html
         head : title "test"
         body
             h1 "test"
             header-foo "the header"
             p "it " : em "works!"
               br
               " it actually works!"

; transform it
define template2
 let loop
  : l template
  match l
    : 'header-foo a ...
      list 'p '(@ (style "margin-left: 2em")) : list 'strong : map loop a
    : a ...
      map loop a 
    a
      . a

; write xml to the output port
sxml->xml template2

newline
