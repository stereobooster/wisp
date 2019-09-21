;;; ob-wisp.el --- org-babel functions for wisp evaluation

;; Copyright (C) 2009-2017 Free Software Foundation, Inc.

;; Authors: Eric Schulte
;;	 Dan Davison
;;   Arne Babenhauserheide
;; Keywords: literate programming, reproducible research
;; Homepage: http://orgmode.org

;; Version: 0.1
;; Keywords: languages, lisp

;; This file is not part of GNU Emacs. It is modified from ob-python.el

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Org-Babel support for evaluating wisp source code.

;; ChangeLog:
;;  - 0.1: search for modules with .w extension


;;; Code:
(require 'ob)
(eval-when-compile (require 'cl))

(declare-function org-remove-indentation "org" )
(declare-function wisp-shell "ext:wisp-mode" (&optional argprompt))
(declare-function wisp-toggle-shells "ext:wisp-mode" (arg))
(declare-function run-wisp "ext:wisp-mode" (cmd &optional dedicated show))

(defvar org-babel-tangle-lang-exts)
(add-to-list 'org-babel-tangle-lang-exts '("wisp" . "w"))

(defvar org-babel-default-header-args:wisp '())

(defcustom org-babel-wisp-command "guile -L $HOME/wisp --language=wisp -x .w -e '(lambda (args) (set! (@@ (system repl common) repl-welcome) (const #f)))' -c ''"
  ;; setting repl-welcome to #f gets rid of printing the REPL prefix and Guile version
  "Name of the command for executing Wisp code."
  :version "24.4"
  :package-version '(Org . "8.0")
  :group 'org-babel
  :type 'string)

(defcustom org-babel-wisp-mode
  'wisp-mode
  "Preferred wisp mode for use in running wisp interactively.
This will typically be either 'wisp or 'wisp-mode."
  :group 'org-babel
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'symbol)

(defcustom org-babel-wisp-hline-to "#f"
  "Replace hlines in incoming tables with this when translating to wisp."
  :group 'org-babel
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'string)

(defcustom org-babel-wisp-false-to 'hline
  "Replace `#f' in wisp tables with this before returning."
  :group 'org-babel
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'symbol)

(defun org-babel-execute:wisp (body params)
  "Execute a block of Wisp code with Babel.
This function is called by `org-babel-execute-src-block'."
  (let* ((session (org-babel-wisp-initiate-session
		   (cdr (assoc :session params))))
         (result-params (cdr (assoc :result-params params)))
         (result-type (cdr (assoc :result-type params)))
	 (return-val (when (and (eq result-type 'value) (not session))
		       (cdr (assoc :return params))))
	 (preamble (cdr (assoc :preamble params)))
         (full-body
	  (org-babel-expand-body:generic
	   (concat body (if return-val (format ". %s\n" return-val) "\n"))
	   params (org-babel-variable-assignments:wisp params)))
         (result (org-babel-wisp-evaluate
		  session full-body result-type result-params preamble)))
    (org-babel-reassemble-table
     result
     (org-babel-pick-name (cdr (assoc :colname-names params))
			  (cdr (assoc :colnames params)))
     (org-babel-pick-name (cdr (assoc :rowname-names params))
			  (cdr (assoc :rownames params))))))

(defun org-babel-prep-session:wisp (session params)
  "Prepare SESSION according to the header arguments in PARAMS.
VARS contains resolved variable references"
  (let* ((session (org-babel-wisp-initiate-session session))
	 (var-lines
	  (org-babel-variable-assignments:wisp params)))
    (org-babel-comint-in-buffer session
      (mapc (lambda (var)
              (end-of-line 1) (insert var) (comint-send-input)
              (org-babel-comint-wait-for-output session))
            var-lines))
    session))

(defun org-babel-load-session:wisp (session body params)
  "Load BODY into SESSION."
  (save-window-excursion
    (let ((buffer (org-babel-prep-session:wisp session params)))
      (with-current-buffer buffer
        (goto-char (process-mark (get-buffer-process (current-buffer))))
        (insert (org-babel-chomp body)))
      buffer)))

;; helper functions

(defun org-babel-variable-assignments:wisp (params)
  "Return a list of Wisp statements assigning the block's variables."
  (mapcar
   (lambda (pair)
     (format "define %s %s"
	     (car pair)
	     (org-babel-wisp-var-to-wisp (cdr pair))))
   (org-babel--get-vars params)))

(defun org-babel-wisp-var-to-wisp (var)
  "Convert an elisp value to a wisp variable.
Convert an elisp value, VAR, into a string of wisp source code
specifying a variable of the same value."
  (if (listp var)
      (concat "list" (mapconcat #'org-babel-wisp-var-to-wisp var " "))
    (if (equal var 'hline)
	org-babel-wisp-hline-to
      (format ;; TODO: adjust to wisp
       (if (and (stringp var) (string-match "[\n\r]" var)) "\"\"%S\"\"" "%S")
       (if (stringp var) (substring-no-properties var) var)))))

(defun org-babel-wisp-table-or-string (results)
  "Convert RESULTS into an appropriate elisp value.
If the results look like a list or tuple, then convert them into an
Emacs-lisp table, otherwise return the results as a string."
  (let ((res (org-babel-script-escape results)))
    (if (listp res)
        (mapcar (lambda (el) (if (equal el "#f")
                            org-babel-wisp-false-to el))
                res)
      res)))

(defvar org-babel-wisp-buffers '((:default . "*Wisp*")))

(defun org-babel-wisp-session-buffer (session)
  "Return the buffer associated with SESSION."
  (cdr (assoc session org-babel-wisp-buffers)))

(defun org-babel-wisp-with-earmuffs (session)
  (let ((name (if (stringp session) session (format "%s" session))))
    (if (and (string= "*" (substring name 0 1))
	     (string= "*" (substring name (- (length name) 1))))
	name
      (format "*%s*" name))))

(defun org-babel-wisp-without-earmuffs (session)
  (let ((name (if (stringp session) session (format "%s" session))))
    (if (and (string= "*" (substring name 0 1))
	     (string= "*" (substring name (- (length name) 1))))
	(substring name 1 (- (length name) 1))
      name)))

(defvar wisp-default-interpreter)
(defvar wisp-which-bufname)
(defvar wisp-shell-buffer-name)
(defun org-babel-wisp-initiate-session-by-key (&optional session)
  "Initiate a wisp session.
If there is not a current inferior-process-buffer in SESSION
then create.  Return the initialized session."
  (require org-babel-wisp-mode)
  (save-window-excursion
    (let* ((session (if session (intern session) :default))
           (wisp-buffer (org-babel-wisp-session-buffer session))
	   (cmd (if (member system-type '(cygwin windows-nt ms-dos))
		    (concat org-babel-wisp-command " -i")
		  org-babel-wisp-command)))
      (cond
       ((and (eq 'wisp-mode org-babel-wisp-mode)
	     (fboundp 'run-wisp)) ; wisp.el
	(if (not (version< "24.1" emacs-version))
	    (run-wisp cmd)
	  (unless wisp-buffer
	    (setq wisp-buffer (org-babel-wisp-with-earmuffs session)))
	  (let ((wisp-shell-buffer-name
		 (org-babel-wisp-without-earmuffs wisp-buffer)))
	    (run-wisp cmd))))
       ((and (eq 'wisp-mode org-babel-wisp-mode)
	     (fboundp 'wisp-shell)) ; wisp-mode.el
	;; Make sure that wisp-which-bufname is initialized, as otherwise
	;; it will be overwritten the first time a Wisp buffer is
	;; created.
	(wisp-toggle-shells wisp-default-interpreter)
	;; `wisp-shell' creates a buffer whose name is the value of
	;; `wisp-which-bufname' with '*'s at the beginning and end
	(let* ((bufname (if (and wisp-buffer (buffer-live-p wisp-buffer))
			    (replace-regexp-in-string ;; zap surrounding *
			     "^\\*\\([^*]+\\)\\*$" "\\1" wisp-buffer)
			  (concat "Wisp-" (symbol-name session))))
	       (wisp-which-bufname bufname))
	  (wisp-shell)
	  (setq wisp-buffer (org-babel-wisp-with-earmuffs bufname))))
       (t
	(error "No function available for running an inferior Wisp")))
      (setq org-babel-wisp-buffers
	    (cons (cons session wisp-buffer)
		  (assq-delete-all session org-babel-wisp-buffers)))
      session)))

(defun org-babel-wisp-initiate-session (&optional session params)
  "Create a session named SESSION according to PARAMS."
  (unless (string= session "none")
    (org-babel-wisp-session-buffer
     (org-babel-wisp-initiate-session-by-key session))))

(defvar org-babel-wisp-eoe-indicator "'org_babel_wisp_eoe'"
  "A string to indicate that evaluation has completed.")
(defvar org-babel-wisp-wrapper-method
  "
define : main
%s

write (main) : open-output-file '%s' .")
(defvar org-babel-wisp-pp-wrapper-method
  "
import : ice-9 pretty-print
define : main
%s

pretty-print (main) : open-output-file '%s' .")

(defun org-babel-wisp-evaluate
  (session body &optional result-type result-params preamble)
  "Evaluate BODY as Wisp code."
  (if session
      (org-babel-wisp-evaluate-session
       session body result-type result-params)
    (org-babel-wisp-evaluate-external-process
     body result-type result-params preamble)))

(defun org-babel-wisp-evaluate-external-process
  (body &optional result-type result-params preamble)
  "Evaluate BODY in external wisp process.
If RESULT-TYPE equals 'output then return standard output as a
string.  If RESULT-TYPE equals 'value then return the value of the
last statement in BODY, as elisp."
  (let ((raw
         (case result-type
           (output (org-babel-eval org-babel-wisp-command
                                   (concat (if preamble (concat preamble "\n"))
                                           body)))
           (value (let ((tmp-file (org-babel-temp-file "wisp-")))
                    (org-babel-eval
                     org-babel-wisp-command
                     (concat
                      (if preamble (concat preamble "\n") "")
                      (format
                       (if (member "pp" result-params)
                           org-babel-wisp-pp-wrapper-method
                         org-babel-wisp-wrapper-method)
                       (mapconcat
                        (lambda (line) (format "\t%s" line))
                        (split-string
                         (org-remove-indentation
                          (org-trim body))
                         "[\r\n]") "\n")
                       (org-babel-process-file-name tmp-file 'noquote))))
                    (org-babel-eval-read-file tmp-file))))))
    (org-babel-result-cond result-params
      raw
      (org-babel-wisp-table-or-string (org-trim raw)))))

(defun org-babel-wisp-evaluate-session
    (session body &optional result-type result-params)
  "Pass BODY to the Wisp process in SESSION.
If RESULT-TYPE equals 'output then return standard output as a
string.  If RESULT-TYPE equals 'value then return the value of the
last statement in BODY, as elisp."
  (let* ((send-wait (lambda () (comint-send-input nil t) (sleep-for 0 5)))
	 (dump-last-value
	  (lambda
	    (tmp-file pp)
	    (mapc
	     (lambda (statement) (insert statement) (funcall send-wait))
	     (if pp
		 (list
		  "import : ice-9 pretty-print ."
		  (format "pretty-print (main) : open-output-file '%s' ."
			  (org-babel-process-file-name tmp-file 'noquote)))
	       (list (format "write (main) : open-output-file '%s' ."
			     (org-babel-process-file-name tmp-file
                                                          'noquote)))))))
	 (input-body (lambda (body)
		       (mapc (lambda (line) (insert line) (funcall send-wait))
			     (split-string body "[\r\n]"))
		       (funcall send-wait)))
         (results
          (case result-type
            (output
             (mapconcat
              #'org-babel-trim
              (butlast
               (org-babel-comint-with-output
                   (session org-babel-wisp-eoe-indicator t body)
                 (funcall input-body body)
                 (funcall send-wait) (funcall send-wait)
                 (insert org-babel-wisp-eoe-indicator)
                 (funcall send-wait))
               2) "\n"))
            (value
             (let ((tmp-file (org-babel-temp-file "wisp-")))
               (org-babel-comint-with-output
                   (session org-babel-wisp-eoe-indicator nil body)
                 (let ((comint-process-echoes nil))
                   (funcall input-body body)
                   (funcall dump-last-value tmp-file
                            (member "pp" result-params))
                   (funcall send-wait) (funcall send-wait)
                   (insert org-babel-wisp-eoe-indicator)
                   (funcall send-wait)))
               (org-babel-eval-read-file tmp-file))))))
    (unless (string= (substring org-babel-wisp-eoe-indicator 1 -1) results)
      (org-babel-result-cond result-params
	results
        (org-babel-wisp-table-or-string results)))))

(defun org-babel-wisp-read-string (string)
  "Strip \"s from around Wisp STRING."
  (if (string-match "^\"\\([^\000]+\\)\"$" string)
      (match-string 1 string)
    string))

(provide 'ob-wisp)



;;; ob-wisp.el ends here
