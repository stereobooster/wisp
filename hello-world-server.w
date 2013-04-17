#!/home/arne/Quell/Programme/wisp/wisp-multiline.sh   !#

define : hello-world-handler request request-body
  values 
    ' : content-type . : text/plain
    let : : text "Hello World!"
      display : getlogin
      if : string? : getlogin
         set! text : string-append text : getlogin
         set! text : string-append text " Sucker!"
      . text

use-modules : web server

display : string-append "Server starting. Test it at http://127.0.0.1:8081"
newline

run-server hello-world-handler 'http ' : #:port 8081
