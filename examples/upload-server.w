#!/usr/bin/env sh
# -*- wisp -*-
guile-2.0 -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec guile-2.0 -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -s "$0" "$@"
; !#

import
  web server
  web request
  web response
  web uri
  ice-9 ftw ; file tree walk
  ice-9 iconv
  ice-9 textual-ports
  ice-9 optargs
  srfi srfi-27 ; random-integer
  rnrs unicode
  rnrs bytevectors ; for utf8->string

define : header-html
  ' : content-type . : text/html

define files-path "files/"

define : list-files
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

define : part-content-disposition part
    post-part-header-content-disposition : part-headers part

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

define : find-free-filename filename
    let : : files : scandir files-path
      let loop : : filename filename
          if : not : member filename files
             . filename
             loop : filename-add-number filename
     

define : save-part-upload part
    let*
        : filename : find-free-filename : basename : part-filename part
          port : open-output-file (string-append files-path filename) #:binary #t
        put-string port : part-content part
        close-port port

define : upload request request-body
  let*
    : content-type : request-content-type request
      boundary : assoc-ref (cdr content-type) 'boundary
      content : bytevector->string request-body : port-encoding : request-port request
      parts : string-split-string content boundary
    write : map save-part-upload parts
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



define : header-html
  ' : content-type . : text/html

define : file-upload-handler request POST-data
  values
    header-html
    if POST-data
      upload request POST-data
      list-files

display "Server starting. Test it at http://127.0.0.1:8083
                 Hit CTRL-C twice to stop the server.
"

run-server file-upload-handler 'http ' : #:port 8083
