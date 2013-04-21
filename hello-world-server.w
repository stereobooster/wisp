#!/home/arne/Quell/Programme/wisp/wisp-multiline.sh   
; !#

define : hello-world-handler request request-body
  values 
    ; header
    ' : content-type . : text/plain
    ; content
    let : : text "Hello World!"
      if : string? : getlogin
        set! text : string-append text : getlogin
        set! text : string-append text " Sucker!"

      set! text 
        string-append text " "
          number->string : tm:hour : gmtime : current-time
          . ":"
          number->string : tm:min : gmtime : current-time

      . text


use-modules : web server

display : string-append "Server starting. Test it at http://127.0.0.1:8081"
newline

run-server hello-world-handler 'http ' : #:port 8081


