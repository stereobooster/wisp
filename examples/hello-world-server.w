#!./wisp-multiline.sh
; !#

use-modules 
  web server

; first the plain text header
define : header
  ' : content-type . : text/plain

; now content building functions
define : timestring
  string-join 
    list
        ; use gmtime instead of localtime if you want UTC
        number->string : tm:hour : localtime : current-time
        number->string : tm:min : localtime : current-time
    . ":" ; delimiter

define : greeting
  if : string? : getlogin
    getlogin
    . "Mellon?"

define : content
  let : : text "Hello World!" ; the let is wisp syntax showoff…
    string-join
      list 
        . text
        greeting
        timestring
      . "\n" ; delimiter

; and the request handler
define : hello-world-handler request request-body
  values 
    header
    content

display "Server starting. Test it at http://127.0.0.1:8081"
newline

run-server hello-world-handler 'http ' : #:port 8081
