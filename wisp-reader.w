#!/home/arne/wisp/wisp-multiline.sh 
; !#
;;
;; Implement wisp in guile
;;
;; -Author: Arne Babenhauserheide

; adapted from guile-sweet: https://gitorious.org/nacre/guile-sweet/source/ae306867e371cb4b56e00bb60a50d9a0b8353109:sweet/common.scm


; adapted from spec.scm: https://gitorious.org/nacre/guile-sweet/source/ae306867e371cb4b56e00bb60a50d9a0b8353109:sweet/spec.scm
(define-module (wisp-reader)
  #:use-module (wisp)
  #:use-module (system base compile)
  #:use-module (system base language)
  #:use-module (language scheme compile-tree-il)
  #:use-module (language scheme decompile-tree-il)
  #:export (scheme))

;;;
;;; Language definition
;;;

(define-language wisp
  #:title "Wisp Scheme Syntax"
  #:reader (lambda (port env)
             (wisp-read port))
  #:compilers `((tree-il . ,compile-tree-il))
  #:decompilers `((tree-il . ,decompile-tree-il))
  #:evaluator (lambda (x module) (primitive-eval x))
  #:printer write
  #:make-default-environment
  (lambda ()
    ;; Ideally we'd duplicate the whole module hierarchy so that `set!',
    ;; `fluid-set!', etc. don't have any effect in the current environment.
    (let ((m (make-fresh-user-module)))
      ;; Provide a separate `current-reader' fluid so that
      ;; compile-time changes to `current-reader' are
      ;; limited to the current compilation unit.
      (module-define! m 'current-reader (make-fluid))
      ;; Default to `simple-format', as is the case until
      ;; (ice-9 format) is loaded. This allows
      ;; compile-time warnings to be emitted when using
      ;; unsupported options.
      (module-set! m 'format simple-format)
      m)))

; adapted from sugar.scm: https://gitorious.org/nacre/guile-sweet/source/ae306867e371cb4b56e00bb60a50d9a0b8353109:sweet/sugar.scm

(define* (wisp-read #:optional (port (current-input-port)))
  ; Read single complete I-expression.
  (let* ((indentation (list->string (accumulate-hspace port)))
         (c (peek-char port)))
    (cond
     ((eof-object? c) c) ; EOF - return it, we're done.
     ((eqv? c #\; ) ; comment - consume and see what's after it.
      (let ((d (consume-to-eol port)))
        (cond
         ((eof-object? d) d) ; If EOF after comment, return it.
         (#t
          (read-char port) ; Newline after comment. Consume NL
          (sugar-read port))))) ; and try again
     ((eqv? c #\newline)
      (read-char port) ; Newline (with no preceding comment).
      (sugar-read port)) ; Consume and again
     (#t
                                        ; TODO: Handle (> (string-length indentation) 0)
      (let* ((read (readblock-clean "" port))
             (level (car read))
             (block (cdr read)))
        (cond
         ((eq? block '.)
          '())
         (#t
          block)))))))

