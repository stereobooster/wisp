#!/usr/bin/env bash
# -*- wisp -*-
function die () {
    echo $1 && exit 1 
}
guile -c '(import (fibers web server))' || die "ERROR: cannot import fibers, exiting"
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp) (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples downloadmesh)' -c '' "$@"
; !#

;;; downloadmesh --- multi-source swarming downloads via HTTP

;; This follows the Gnutella download mesh, and adds a parity option
;; to compensate variable upload speeds by clients.

;; Provide the parity block in the headers.

;; Plan:
;; - Content-URN-Addressed downloading (sha1/sha256)
;; - Download in chunks from a single server
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
;; http://rfc-gnutella.sourceforge.net/src/Partial_File_Sharing_Protocol_1.0.txt

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
    prefix (fibers web server) fibers: ;; using fibers, mind the different arguments of run-server!
    web server ;; standard Guile server, mind the different arguments of run-server!
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
    only (rnrs bytevectors) bytevector-length utf8->string
    only (srfi srfi-27) random-integer
    only (ice-9 textual-ports) put-string


define : run-ipv4-fibers-server handler-with-path ip
    fibers:run-server handler-with-path #:family AF_INET #:port 8083 #:addr INADDR_ANY
    
define : run-ipv6-fibers-server handler-with-path ip
    define s
        let : : s : socket AF_INET6 SOCK_STREAM 0
            setsockopt s SOL_SOCKET SO_REUSEADDR 1
            bind s AF_INET6 (inet-pton AF_INET6 ip) 8083
            . s
    fibers:run-server handler-with-path #:family AF_INET6 #:port 8083 #:addr (inet-pton AF_INET6 "::") #:socket s

define : run-ipv4-standard-server handler-with-path ip
    run-server handler-with-path 'http `(#:host "localhost" #:family ,AF_INET #:addr ,INADDR_ANY #:port 8083)

define : run-ipv6-standard-server handler-with-path ip
    define s
        let : : s : socket AF_INET6 SOCK_STREAM 0
            setsockopt s SOL_SOCKET SO_REUSEADDR 1
            bind s AF_INET6 (inet-pton AF_INET6 ip) 8083
            . s
    run-server handler-with-path 'http `(#:family ,AF_INET6 #:addr (inet-pton AF_INET6 "::") #:port 8083 #:socket ,s)


define-generic length
define-method : length (str <string>)
    string-length str

define-record-type <served>
    served serverpath accesspath size sha256
    . served-file?
    serverpath served-serverpath
    accesspath served-accesspath
    size served-sizebytes
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
    declare-opaque-header! "X-Gnutella-Content-URN" ;; the content
    declare-opaque-header! "Content-Range" ;; the content returned


define : download-file url
    let*
        : uri : string->uri-reference url
          headers `((range bytes (0 . #f))) ;; minimal range header so that the server can serve a content range
        display "Downloading file "
        display uri
        ;; TODO: parse content range response headers, assemble the file from chunks
        newline
        let-values : : (resp body) : http-get uri #:headers headers
          pretty-print resp
          pretty-print : response-headers resp
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
    ;; example: uri-res/urn:sha256:
    define uri-res-prefix "uri-res/raw/"
    pretty-print path
    vhash-fold (λ(key value result) (pretty-print key)(pretty-print value)) #f served-paths
    if : string-prefix-ci? uri-res-prefix path
        resolve-urn : string-drop path : length uri-res-prefix
        vhash-assoc path served-paths

define : xalt->header xalt
    pretty-print xalt
    string-join (remove not (append (map second xalt) seed-server-ips)) ","

define : server-serve-file range-requested begin-end path
   define 4KiB : expt 2 12
   define 16B : expt 2 4
   define range-begin : car begin-end
   define range-end
       if range-requested
          or (cdr begin-end) 16B
          . #f
   let*
       : served-file : resolve-path path
         foo : pretty-print served-file
         data 
             if : not served-file
                 . "File not found"
                 get-file-chunk
                     served-accesspath (cdr served-file)
                     . range-begin
                     . range-end
         code : if (not served-file) 400 : if range-requested 206 200
         base-headers `((content-type . (application/octet-stream))
                        (accept-ranges . (bytes))
                        (X-Alt . ,(xalt->header xalt)))
         headers
             if range-end
                cons `(content-range . ,(format #f "bytes ~d-~d/~d" range-begin {range-end - 1} 
                                                            (served-sizebytes (cdr served-file))))
                     . base-headers
                . base-headers
       values
          build-response
            . #:headers headers
            . #:code code
          . data

define : server-list-files
       values
          build-response 
            . #:headers `((content-type . (text/html))
                          (accept-ranges . (bytes)))
          list-files


define* : string-part-ref s sep key #:optional (matches? string-prefix-ci?)
    . "Retrieve part identified by KEY in a structured string S with parts separated by SEP. Returns #f if no matching part is found.

The optional MATCHES? is called as (matches? part key)."
    let loop
        : parts : string-split-string s sep
        cond
          : null? parts
            . #f
          : matches? key : car parts
            car parts
          else
            loop : cdr parts

define : part-header-content-disposition part
    string-part-ref part "\r\n" "content-disposition:"

define : part-header-filename part
  let*
      : key "filename=\""
        disp : part-header-content-disposition part
        arg : and disp : string-part-ref disp "; " key
      if arg
         string-drop
                string-drop-right arg 1
                string-length key
         . #f

define : part-filename part
    part-header-filename : part-headers part

define : part-headers part
  let : : sep "\r\n\r\n"
    car : string-split-string part sep

define : part-content part
  let : : sep "\r\n\r\n"
    string-join
      cdr : string-split-string part sep
      . sep

define : filename-add-number filename
    define : random-number-string
        number->string : random-integer 10
    let : : extidx : string-index-right filename #\.
        if : not extidx
             string-append filename : random-number-string
             let
                 : ext : substring filename : + extidx 1
                   base : substring filename 0 extidx
                 string-append base : random-number-string
                   . "." ext             

define : find-free-filename files-path filename
    let : : files : scandir files-path
      let loop : : filename filename
          if : not : member filename files
             . filename
             loop : filename-add-number filename
     

define : save-part-upload files-path part
    when : part-filename part
      let*
        : filename : find-free-filename files-path : basename : part-filename part
          port : open-output-file (string-append files-path file-name-separator-string filename) #:binary #t
        put-string port : part-content part
        close-port port

define : upload files-path request request-body
  let*
    : content-type : request-content-type request
      boundary : string-append "\r\n--" : assoc-ref (cdr content-type) 'boundary ;; following https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
      content : bytevector->string request-body : port-encoding : request-port request
      parts : string-split-string content boundary
    write : map (λ(x) (save-part-upload files-path x)) parts
    newline
    list-files


define* : string-split-string s substr #:optional (start 0) (end (string-length s))
       . "Split string s by substr."
       let : : substr-length : string-length substr
          if : zero? substr-length
             error "string-replace-substring: empty substr"
             let loop
                 : start start
                   pieces : list : substring s 0 start
                 let : : idx : string-contains s substr start end
                   if idx
                     loop : + idx substr-length
                           cons* : substring s start idx
                                 . pieces
                     cdr 
                         reverse 
                              cons : substring s start
                                   . pieces



define : server-file-download-handler folder-path request body
    ;; TODO: serve range requests, see https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests
    ;; TODO: return status code 206 for range requests (also for initial?): https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/206
    define headers : request-headers request
    pretty-print request
    let*
        : range-requested : assoc-item headers 'range
          begin-end
              if : or (not range-requested) {(length range-requested) < 3}
                 . '(0 . #f)
                 third range-requested
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
            : equal? '("upload") path-elements
              when body
                  upload folder-path request body
                  update-served-files! folder-path
              server-list-files
            else
              set! xalt
                  delete-duplicates
                      alist-cons sha256
                          delete-duplicates : cons ipv6 : or (assoc-ref xalt sha256) : list
                          . xalt
              server-serve-file range-requested begin-end path

define : sha256sum path
  let*
    : port : open-input-pipe : string-append "sha256sum \"" path "\""
      output : read-string port
    close port
    first
        string-split output #\space


define : hash-folder-tree folder-path
    ## 
        tests 
            test-equal : list : served "test" "files/test" 4 "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
                hash-folder-tree "files"
    ;; add a <served> for every file
    define : leaf name stat result
        let : : serverpath : string-drop name : + 1 : length folder-path
          cons : served serverpath name (stat:size stat) (sha256sum name)
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

define : update-served-files! folder-path
    define to-serve : hash-folder-tree folder-path
    set! served-files to-serve
    map
        λ : x
            set! served-hashes : vhash-cons (served-sha256 x) x served-hashes
            set! served-paths : vhash-cons (served-serverpath x) x served-paths
        . to-serve

define : serve folder-path ip
    define : handler-with-path request body
        server-file-download-handler folder-path request body
    update-served-files! folder-path
    pretty-print served-files
    pretty-print served-hashes

    format : current-error-port
           . "Serving ~d files on http://[~a]:~d\n" (length served-files) ip 8083
    run-ipv6-fibers-server handler-with-path ip
    
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

