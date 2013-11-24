#!./wisp-multiline.sh
; !#

use-modules 
  web server
  web request
  web response
  web uri
  rnrs unicode
  rnrs bytevectors ; for utf8->string

define : header-html
  ' : content-type . : text/html

define : show-comments request comments-hash-table
  let* 
      : path : uri-path : request-uri request
        uri-components : split-and-decode-uri-path path
      string-join 
        list "<!DOCTYPE html><html><head><title>Comments</title></head><body><form action='" path "' method='post'>
    <input type='text' name='comment' />
    <input type='submit' name='submit' value='Save' />
</form>"
          hash-ref comments-hash-table uri-components
            string-join uri-components
          . "</body></html>\n"

define : change-comment-content current to-add
  if current 
    string-join : list "<div class='comment'>" to-add "</div><div class='commentsep'></div>" current
    string-join : list "<div class='comment'>" to-add "</div>"

define : body->comment request-body
  let : : request-string : utf8->string request-body
         substring request-string
            string-length "comment="
            string-index request-string #\& ; FIXME: This will break for comments with &. Ignore that: This is just a mockup.

define : add-comment request request-body comments-hash-table
  let : : uri-components : split-and-decode-uri-path : uri-path : request-uri request
      hash-set! comments-hash-table uri-components
        change-comment-content 
          hash-ref comments-hash-table uri-components
          body->comment request-body
      show-comments request comments-hash-table


define global-comment-hash-table : make-hash-table

define : uri-comment-showing-handler request request-body
  values
    header-html
    if request-body
      add-comment request request-body global-comment-hash-table
      show-comments request global-comment-hash-table

display "Server starting. Test it at http://127.0.0.1:8081"
newline

run-server uri-comment-showing-handler 'http ' : #:port 8081
