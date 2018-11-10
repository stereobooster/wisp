#!/usr/bin/env bash
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp) (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples downloadmesh)' -c '' "$@"
; !#

;;; downloadmesh --- multi-source swarming downloads via HTTP

;; This follows the Gnutella download mesh, and adds a parity option
;; to compensate variable upload speeds by clients.

;; Provide the parity block in the headers.

;; Plan:
;; - Content-URN-Addressed downloading (sha1/sha256)
;; - Download from multiple trusted servers (pre-set xalt)
;; - Download from multiple trusted clients (collect xalt)
;; - Add bitprint from bitcollider[1] and TigerTree exchange
;; - Verify each chunk -> can swarm from untrusted clients
;; - Implement X-NAlt
;; - Add a parity block of 5% of the file (assuming 20 clients)

;; [1] things you only know when you where there when they were built: 
;;     https://sourceforge.net/projects/bitcollider/

;; Download mesh specification:
;; http://rfc-gnutella.sourceforge.net/developer/tmp/download-mesh.html

;; To make this robust against attackers, it also needs THEX and
;; TigerTreeHash to allow for verifying individual chunks.
;; bitprint-urn: http://www.nuke24.net/docs/2015/HashURNs.html
;; https://web.archive.org/web/20091203212059/http://open-content.net/specs/draft-jchapweske-thex-02.html

define-module : examples downloadmesh
              . #:export : main serve download-file

import
    only (srfi srfi-27) random-source-make-integers
      . make-random-source random-source-randomize!
    only (srfi srfi-1) first second third iota
    srfi srfi-11 ;; let-values
    srfi srfi-42
    srfi srfi-1 ;; list operations
    only (srfi srfi-9) define-record-type
    only (ice-9 popen) open-input-pipe
    only (ice-9 rdelim) read-string
    ice-9 optargs
    ice-9 format
    ice-9 match
    ice-9 threads
    ice-9 pretty-print
    ice-9 binary-ports
    fibers web server ;; using fibers, mind the different arguments of run-server!
    ;; web server ;; standard Guile server, mind the different arguments of run-server!
    web client
    web request
    web response
    web uri
    ice-9 iconv ;; bytevector->string
    ice-9 ftw ; file tree walk TODO: only import what I need
    only (ice-9 ftw) file-system-fold
    only (ice-9 vlist) alist->vhash vhash-cons vhash-assoc vhash-fold
    only (web http) declare-opaque-header!
    examples doctests
    only (oop goops) define-generic define-method <string>

define-generic length
define-method : length (str <string>)
    string-length str

define-record-type <served>
    served serverpath accesspath sha256
    . served-file?
    serverpath served-serverpath
    accesspath served-accesspath
    sha256 served-sha256

define xalt : list ;; per file: (hash IP IP ...)
define xnalt : list ;; per file: (hash IP IP ...)
define : assoc-item l k
    assoc k l
define served-files : list ;; (<served> ...)
define served-hashes : alist->vhash '()
define served-paths : alist->vhash '()
;; additional servers whose IP we can hand out
define seed-server-ips : list "2003:f4:4bd5:8898:bd45:2049:139f:62d8"

define : declare-download-mesh-headers!
    ;; TODO: add validation to the header instead of giving them as opaque strings
    declare-opaque-header! "X-Alt" ;; good sources, list of IP:port, separated by commas. Default port 6346 may be omitted.
    declare-opaque-header! "X-NAlts" ;; bad sources, list of IP:port, separated by commas
    declare-opaque-header! "X-Gnutella-Content-URN"


define : download-file url
    let*
        : uri : string->uri-reference url
          headers `((range bytes (0 . #f))) ;; minimal range header so that the server can serve a content range
        display uri
        newline
        let-values : : (resp body) : http-get uri #:headers headers
          pretty-print resp
          pretty-print : if (string? body) body : bytevector->string body "ISO-8859-1"


define : list-files
  let*
      : files : map served-serverpath served-files
        file-list
          if : not files
               list "EMPTY: no served files"
               map : λ(x) : string-append "<li><a href=\"" x "\">" x "</a></li>\n"
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

define : resolve-urn urn
    define sha256-prefix "urn:sha256:"
    pretty-print urn
    if : string-prefix-ci? sha256-prefix urn
         vhash-assoc (string-drop urn (length sha256-prefix)) served-hashes
         . #f

define : resolve-path path
    ;; URN: https://www.ietf.org/rfc/rfc2169.txt
    ;; extended to simplify my parsing: http://www.nuke24.net/docs/2015/HashURNs.html
    define uri-res-prefix "uri-res/raw/"
    pretty-print path
    vhash-fold (λ(key value result) (pretty-print key)(pretty-print value)) #f served-paths
    if : string-prefix-ci? uri-res-prefix path
        resolve-urn : string-drop path : length uri-res-prefix
        vhash-assoc path served-paths

define : xalt->header xalt
    pretty-print xalt
    string-join (remove not (append (map second xalt) seed-server-ips)) ","

define : server-serve-file range begin-end path
   let*
       : served-file : resolve-path path
         foo : pretty-print served-file
         data 
             if : not served-file
                 . "File not found"
                 get-file-chunk (served-accesspath (cdr served-file)) (car begin-end) (cdr begin-end)
         code : if (not served-file) 400 : if range 206 200
       values
          build-response
            . #:headers `((content-type . (application/octet-stream))
                          (accept-ranges . (bytes))
                          (X-Alt . ,(xalt->header xalt)))
            . #:code code
          . data

define : server-list-files
       values
          build-response 
            . #:headers `((content-type . (text/html))
                          (accept-ranges . (bytes)))
          list-files


define : server-file-download-handler request body
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
          path : join-path-elements-safely path-elements
          served-file : vhash-assoc path served-paths
          sha256 : and served-file : served-sha256 : cdr served-file
          peer : getpeername : request-port request
          ip : sockaddr:addr peer
          port : sockaddr:port peer
          ;; ipv4 : inet-ntop AF_INET ip
          ipv6 : inet-ntop AF_INET6 ip
        pretty-print : list 'xalt xalt 'ipv6 ipv6 'peer peer
        cond
            : null? path-elements
              server-list-files
            else
              set! xalt
                  delete-duplicates
                      alist-cons sha256
                          delete-duplicates : cons ipv6 : or (assoc-ref xalt sha256) : list
                          . xalt
              server-serve-file range begin-end path

define : sha256sum path
  let*
    : port : open-input-pipe : string-append "sha256sum " path
      output : read-string port
    close port
    first
        string-split output #\space


define : hash-folder-tree folder-path
    ## 
        tests 
            test-equal : list : served "test" "files/test" "b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c"
                hash-folder-tree "files"
    ;; add a <served> for every file
    define : leaf name stat result
        let : : serverpath : string-drop name : + 1 : length folder-path
          cons : served serverpath name : sha256sum name
               . result
    ;; skip dot-directories
    define : enter? name stat result
        not (string-prefix? "." (basename name))
    ;; ignore directories
    define (ignore name stat result) result
    define down ignore
    define up ignore
    define skip ignore
    ;; ignore unreadable files/directories
    define error ignore
    file-system-fold enter? leaf down up skip error (list) folder-path

define : update-served-files folder-path
    define to-serve : hash-folder-tree folder-path
    set! served-files to-serve
    map
        λ : x
            set! served-hashes : vhash-cons (served-sha256 x) x served-hashes
            set! served-paths : vhash-cons (served-serverpath x) x served-paths
        . to-serve

define : serve folder-path ip
    define : handler-with-path request body
        server-file-download-handler request body
    define s
        let : : s : socket AF_INET6 SOCK_STREAM 0
            setsockopt s SOL_SOCKET SO_REUSEADDR 1
            bind s AF_INET6 (inet-pton AF_INET6 ip) 8083
            . s
    update-served-files folder-path
    pretty-print served-files
    pretty-print served-hashes

    format : current-error-port
           . "Serving ~d files on http://[~a]:~d\n" (length served-files) ip 8083
    ;; fibers server
    ;; run-server handler-with-path #:family AF_INET #:port 8083 #:addr INADDR_ANY
    run-server handler-with-path #:family AF_INET6 #:port 8083 #:addr (inet-pton AF_INET6 "::") #:socket s
    ;; standard server
    ;; IPv4
    ;; run-server handler-with-path 'http `(#:host "localhost" #:family ,AF_INET #:addr ,INADDR_ANY #:port 8083)
    ;; IPv6
    ;; run-server handler-with-path 'http `(#:family ,AF_INET6 #:addr (inet-pton AF_INET6 "::") #:port 8083 #:socket ,s)

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

define : opt-member arguments opt
   let : : opt : member opt arguments
      if : or (not opt) : < 2 : length opt
         . #f
         . opt

define : main args
   declare-download-mesh-headers!
   let : : arguments : cdr args
     cond
       : or (null? arguments) (member "--help" arguments) (member "-h" arguments)
         help args
       : member "--test" arguments
         test
       : and {(length arguments) > 1} : equal? "--serve" : car arguments
         let : : ip-opt : or (opt-member arguments "--ip") '("--ip" "::")
             serve (second arguments) (second ip-opt)
       else
         download-file : car arguments

