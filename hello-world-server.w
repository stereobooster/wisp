#!/home/arne/Quell/Programme/wisp/wisp-multiline.sh   !#

use-modules : web server
define : hello-world-handler request request-body
  values 
    ' :                            
        content-type . : text/plain
    . "Hello World!"
run-server hello-world-handler 'http ' : #:port 8081

