#!/home/arne/Quell/Programme/wisp/wisp-multiline.sh   !#

define : hello-world-handler request request-body
  values 
    ' :                            
        content-type . : text/plain
    . "Hello World!"

use-modules : web server

run-server hello-world-handler 'http ' : #:port 8081
