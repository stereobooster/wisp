#!/usr/bin/env sh
(# -*- wisp -*-)
(guile-2.0 -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))')
(exec guile-2.0 -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(examples commandline-handling)' -s "$0" "$@")
; !#

;; This is an example for complex commandline handling for a tool
;; which takes a list of tasks to run as arguments.

(define-module (examples commandline-handling)
              #:export (main))

(import
    (ice-9 format)
    (srfi srfi-1)
    (srfi srfi-37)
    (ice-9 popen ); for pipe-open*
    (ice-9 rdelim )); for read-string



(define (runcommand cmd)
  (let*
    ((port (open-input-pipe cmd))
      (output (read-string port)))
    (display output)
    (newline)))


(define (run-my-shell-command)
    "Run a predefined shell command"
    (let
      (
        (cmd
          (string-join
            (list "for i in {1..5}; do echo $i; done"))))
      (when (debug?)
        (display cmd (current-error-port))
        (newline (current-error-port)))
      (runcommand cmd)))


(define (help . args ); args used for simpler option parsing
         (if
              (and
                 (>= (length args) 3)
                 (third args)
                 (member (string->symbol (third args)) (task-list ))); help got an argument
              (let*
                  ((fun (string->symbol (third args)))
                    (mod (resolve-module '(examples commandline-handling)))
                    (doc (procedure-documentation (module-ref mod fun))))
                  (format #t "~a\n\n~a\n" fun doc))
              (format #t "Usage: commandline-handling.w [option ...] [--] [task ...]

Run the selected tasks given on the commandline.

  -h [TASK] --help[=TASK]
                 display this help or infomation about the task and exit
  -V --version   output version information and exit
     --tasks     list all available tasks
  -d [LEVEL] --debug[=LEVEL]
                 set logging to debug or to the given level

Defined tasks:

  ~a

" (string-join (map symbol->string (task-list)))))
         (exit 0))


(define (version)
         (display "commandline-handling 0.0.0

Copyright (C) 2016 Arne Babenhauserheide, for IMK-ASF at Karlsruhe Institute for Technology
See the file COPYING. There is NO warranty.
"))

(define help-option
  (option '(#\h "help")
          #f #t help))

(define version-option
  (option '(#\V "version")
          #f #f
          (λ (option name arg operands)
              (version)
              (exit 0))))

(define (debug?)
    (equal? 'debug (assoc-ref %options 'log-level)))


(define debug-option
  (let
    ((required #f)
      (optional #t )); can take an argument
    (option '(#\d "debug")
          required optional
          (λ (option name arg operands)
              (if arg
                 (set! %options (alist-cons 'log-level (string->symbol arg) %options))
                 (set! %options (alist-cons 'log-level 'debug %options)))
              (format (current-error-port)
                     "debug: activate log level ~a\n"
                     (if arg arg 'debug))
              operands))))


(define utility-procedures
    '(parse-args main run-task task-list runcommand debug?))

(define debug-procedures
    '(tasks help options version))

(define (task-list)
      (let ((mod (resolve-module '(examples commandline-handling))))
          (delete #f
                (module-map
                    (λ (x y)
                        (if
                          (and
                            (procedure? (module-ref mod x))
                            (not (member x utility-procedures))
                            (if (equal? 'debug (assoc-ref %options 'log-level))
                               #t
                               (not (member x debug-procedures))))
                          x
                          #f))
                    mod))))

(define (tasks . args)
    (map (λ (x) (display x)(newline))
          (task-list)))

(define tasks-option
  (option '("tasks")
          #f #f
          (λ (option name arg operands)
              (tasks)
              (exit 0))))


(define %options
    '(
      (log-level . info)))

(define (options)
         (format (current-error-port)
                "Currently active options: ~A\n"
                %options))

(define %option-list
    (list help-option version-option debug-option tasks-option))


(define (run-task task)
       (let*
         ((mod (resolve-module '(examples commandline-handling)))
           (t (string->symbol task))
           (var (module-variable mod t)))
         (cond
           (var
             (let ((T (module-ref mod t)))
               (if (procedure? T)
                  (T)
                  (format (current-error-port)
                         "Not a procedure: ~a refers to ~a\n" task var))))
           (else
              (format (current-error-port)
                     "Unknown task: ~a\n" task)))))


(define (parse-args args)
    (let
      (
        (tasks
           (reverse
            (args-fold args
             %option-list
             (λ (option name arg operands)
               (format (current-error-port)
                      "unrecognized command line argument name: ~a arg: ~a operands: ~a\n"
                      name arg operands)
               (exit 1))
             (λ (operand operands)
               (cons operand operands))
             '()))))
      (for-each
       (λ (task)
           (if (and (equal? task "help") (not (null? (delete "help" tasks))))
                (map
                  (λ (x)
                      (help #f #f x))
                  (delete "help" tasks))
                (run-task task)))
       tasks)))

(define* (main args)
    (if (null? (cdr args))
         (help)
         (parse-args (cdr args))))


