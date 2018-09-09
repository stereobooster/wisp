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
    srfi srfi-1 ;; list operations
    ice-9 optargs
    ice-9 format
    ice-9 match
    ice-9 threads
    ice-9 pretty-print
    ice-9 binary-ports
    fibers web server
    web client
    web request
    web response
    web uri
    ice-9 iconv ;; bytevector->string
    ice-9 ftw ; file tree walk
    only (web http) declare-opaque-header!
    examples doctests

define xalt : list ;; per file: (hash IP)
define xnalt : list ;; per file: (hash IP)
define : assoc-item l k
    assoc k l
define hashes : list ;; (filename hash)

define : declare-download-mesh-headers!
    ;; TODO: add validation to the header instead of giving them as opaque strings
    declare-opaque-header! "X-Alt" ;; good sources, list of IP:port, separated by commas
    declare-opaque-header! "X-NAlts" ;; bad sources, list of IP:port, separated by commas
    declare-opaque-header! "X-Gnutella-Content-URN"


define : download-file url
    let*
        : uri : string->uri-reference url
          headers `((range bytes (0 . #f))) ;; minimal range header so that the server can serve a content range
        let-values : : (resp body) : http-get uri #:headers headers
          pretty-print resp
          pretty-print : bytevector->string body "ISO-8859-1"


define : list-files files-path
  let*
      : files : scandir files-path
        file-list
          if : not files
            begin : mkdir files-path
                    list "." ".."
            map : λ(x) : string-append "<li><a href=\"files/" x "\">" x "</a></li>\n"
                . files
      string-join
        append
          list "<!DOCTYPE html><html><head><title>Files</title></head><body><h2>Upload</h2><form action='/upload' method='POST' enctype='multipart/form-data'>
    <input type='file' name='img' multiple />
    <input type='submit' value='Upload' />
</form><h2>Files</h2><ul>"
          . file-list
          list "</ul></body></html>\n"


define : get-file-chunk abspath begin end
    . "open the file, seek to BEGIN, return bytearray from BEGIN to END"
    if : not : file-exists? abspath
       . ""
       let : : port : open-input-file abspath #:binary #t
         seek port begin SEEK_SET
         let : : data : if end (get-bytevector-n port (- end begin)) (get-bytevector-all port)
           close port
           pretty-print : list abspath begin end data
           if : eof-object? data
              . ""
              bytevector->string data "ISO-8859-1"

define : join-path-elements-safely path-elements
    . "Remove every .. and / from the path elements and join as path"
    string-join
        remove : λ (x) : or (equal? x "..") (equal? x "/")
            . path-elements
        . "/" ;; TODO: make platform independent

define : server-serve-file folder-path range begin-end path-elements
   let*
       : path : join-path-elements-safely path-elements
         abspath : string-join (list folder-path path) "/"
         data : get-file-chunk abspath (car begin-end) (cdr begin-end)
       values
          build-response
            . #:headers `((content-type . (application/octet-stream))
                          (accept-ranges . (bytes))
                          (X-Alt . "::1,::2"))
            . #:code : if range 206 200
          . data


define : server-list-files folder-path range begin-end path-elements
       values
          build-response 
            . #:headers `((content-type . (text/html))
                          (accept-ranges . (bytes)))
          list-files folder-path


define : server-file-download-handler folder-path request body
    ;; TODO: serve range requests, see https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests
    ;; TODO: return status code 206 for range requests (also for initial?): https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/206
    let*
        : headers : request-headers request
          range : assoc-item headers 'range
          begin-end
              if : or (not range) {(length range) < 3}
                 . '(0 . #f)
                 third range
          path-elements : split-and-decode-uri-path : uri-path : request-uri request
        pretty-print request
        pretty-print : request-port request
        pretty-print : sockaddr:addr : getpeername : request-port request
        cond
            : null? path-elements
              server-list-files folder-path range begin-end path-elements
            else
              server-serve-file folder-path range begin-end path-elements

define : serve folder-path
    define : handler-with-path request body
        server-file-download-handler folder-path request body
    run-server handler-with-path #:family AF_INET #:port 8083 #:addr INADDR_ANY

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
   declare-download-mesh-headers!
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

