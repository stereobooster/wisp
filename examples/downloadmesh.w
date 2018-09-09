#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples downloadmesh)' -s "$0" "$@"
; !#

;;; downloadmesh --- multi-source swarming downloads via HTTP

;; This follows the Gnutella download mesh, and adds a parity option
;; to compensate variable upload speeds by clients.

define-module : examples downloadmesh
              . #:export : main

import
    only (srfi srfi-27) random-source-make-integers
      . make-random-source random-source-randomize!
    only (srfi srfi-1) first second third iota
    srfi srfi-11 ;; let-values
    srfi srfi-42
    ice-9 optargs
    ice-9 format
    ice-9 match
    ice-9 threads
    ice-9 pretty-print
    fibers web server
    web client
    web request
    web uri
    examples doctests

define xalt : list ;; per file: (hash IP)
define xnalt : list ;; per file: (hash IP)
define : assoc-item l k
    assoc k l
define hashes : list ;; (filename hash)

define : download-file url
    let*
        : uri : string->uri-reference url
          port : open-socket-for-uri uri
        pretty-print : http-get uri #:port port

define : server-file-download-handler request body
    values `((content-type . (text/plain))
             (X-Alt . (::1)))
           . "Hello World!"

define : serve folder-path
    pretty-print folder-path
    run-server server-file-download-handler #:family AF_INET #:port 8083 #:addr INADDR_ANY

define : help-message args
       ##
         tests
             test-assert : string-contains (help-message '("./program")) "./program"
             test-equal #\U : string-ref (help-message '("./program")) 0
       format #f "Usage: ~a [options]

Options:
   [link [link ...]] download file(s)
   --serve <folder>  serve the files in FOLDER
   --help            show this message
   --test            run unit tests
" : first args

define : help args
       display : help-message args

define %this-module : current-module
define : test
         doctests-testmod %this-module

define : main args
 let : : arguments : cdr args
   cond
     : or (null? arguments) (member "--help" arguments) (member "-h" arguments)
       help args
     : member "--test" arguments
       test
     : and {(length arguments) > 1} : equal? "--server" : car arguments
       serve : second arguments
     else
       download-file : car arguments

