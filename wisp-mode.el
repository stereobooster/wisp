;;; wisp-mode.el --- Major mode for editing wisp: Whitespace-to-Lisp

;; Copyright (C) 2013  Arne Babenhauserheide <arne_bab@web.de>

;; Author: Arne Babenhauserheide <arne_bab@web.de>
;; Version: 0.1.1
;; Keywords: languages, lisp

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; For details on wisp, see 
;; http://draketo.de/light/english/wisp-lisp-indentation-preprocessor

;;; Code:

(require 'scheme)

; allow users to run hooks when they enter my mode
(defvar wisp-mode-hook nil)

; use this mode automatically
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.w\\'" . wisp-mode))

; see http://www.emacswiki.org/emacs/DerivedMode

; font-lock-builtin-face 	font-lock-comment-delimiter-face
; font-lock-comment-face 	font-lock-constant-face
; font-lock-doc-face 	font-lock-fic-author-face
; font-lock-fic-face 	font-lock-function-name-face
; font-lock-keyword-face 	font-lock-negation-char-face
; font-lock-preprocessor-face 	font-lock-reference-face
; font-lock-string-face
; font-lock-type-face 	font-lock-variable-name-face
; font-lock-warning-face

; note: for easy testing: emacs -Q wisp-mode.el -e eval-buffer wisp-guile.w -e delete-other-windows


(defvar wisp-builtin '("define" "define-syntax" "syntax-rules" "defun" "let*" "let" "setq" "set!" "set" "if" "when" "while" "set!" "and" "or" "not" "char=?"))

; TODO: Add special treatment for defun foo : bar baz ⇒ foo = function, bar and baz not.
; TODO: Add highlighting for `, , and other macro-identifiers.
; TODO: take all identifiers from scheme.el
(defvar wisp-font-lock-keywords
  `((
     ("\\`#!.*" . font-lock-comment-face) ; initial hashbang
     ("\"\\.\\*\\?" . font-lock-string-face) ; strings (anything between "")
     ("^\\(?:_* +\\| *\\): *$" . font-lock-keyword-face) ; line with only a : + whitespace, not at the beginning
     ("^\\(?:_* +\\| *\\): \\| *\\. " . font-lock-keyword-face) ; leading : or .
     ( ,(regexp-opt wisp-builtin 'symbols) . font-lock-builtin-face) ; generic functions
     ;                                 v there is a tab here.
     ("^\\(?:_*\\)\\(?: +\\)\\([^:][^ 	]*\\)" . font-lock-function-name-face) ; function calls as start of the line
     ;                     v there is a tab here.
     ("^\\(?: *\\)[^ :][^ 	]*" . font-lock-function-name-face) ; function calls as start of the line
     (" : " "\\=\\([^ 	]+\\)" nil nil (1 font-lock-function-name-face)) ; function calls with inline :
     ("[^']( *" "\\=\\([^ 	)]+\\)" nil nil (1 font-lock-function-name-face)) ; function calls with (
     ("#[tf]"  . font-lock-constant-face) ; #t and #f
     ("#\\\\[^ 	]+"  . font-lock-constant-face) ; character literals
     (";" . 'font-lock-comment-delimiter-face)
     ("\\_<[+-]?[0-9]+\\_>\\|\\_[+-]<[0-9]*\\.[0-9]*\\(e[+-]?[0-9]+\\)?\\_>" . font-lock-constant-face) ; numbers
     ("'()" . font-lock-constant-face) ; empty list
     ("[ 	]'[^	 ]+" . font-lock-constant-face) ; 'name
     (" : \\| \\. " . font-lock-keyword-face) ; leading : or .
     ))
  "Default highlighting expressions for wisp mode.")

(define-derived-mode wisp-mode
  emacs-lisp-mode "Wisp"
  "Major mode for whitespace-to-lisp files.

  \\{wisp-mode-map}"
  ; :group wisp
  (set (make-local-variable 'indent-tabs-mode) nil)
  (setq comment-start ";")
  (setq comment-end "")
  (set (make-local-variable 'font-lock-comment-start-skip) ";+ *")
  (set (make-local-variable 'parse-sexp-ignore-comments) t)
  (set (make-local-variable 'font-lock-defaults) wisp-font-lock-keywords)
  (set (make-local-variable 'mode-require-final-newline) t))

                        

(provide 'wisp-mode)
;;; wisp-mode.el ends here
