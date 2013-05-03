;;; wisp-mode.el --- Major mode for editing wisp: Whitespace-to-Lisp

;; Copyright (C) 2013  Arne Babenhauserheide <arne_bab@web.de>

;; Author: Arne Babenhauserheide <arne_bab@web.de>
;; Version: 0.0
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

;;; Code:

(require 'scheme)

(define-derived-mode wisp-mode
  emacs-lisp-mode "Wisp" 
  "Major mode for whitespace-to-lisp files.

  \\{wisp-mode-map}"
  ; :group wisp
  (set (make-local-variable 'indent-tabs-mode) nil)
  (set (make-local-variable 'comment-start) "; ")
  (set (make-local-variable 'font-lock-comment-start-skip) ";+ *")
  (set (make-local-variable 'parse-sexp-ignore-comments) t)
  (set (make-local-variable 'font-lock-defaults)
              '((scheme-font-lock-keywords
                 scheme-font-lock-keywords-1 scheme-font-lock-keywords-2)
                nil ; keywords only
                nil ; case fold
                (("_" . "-")) ; syntax alist
                backward-paragraph)) ; syntax begin
  (set (make-local-variable 'mode-require-final-newline) t))

(font-lock-add-keywords 'wisp-mode 
                        '(("^ *\\(\\w+\\)\\| : *\\(\\w+\\)" . 'font-lock-function-call-face)
                          ("^ *\\(\\w+\\)\\| : *\\(\\w+\\)" . 'font-lock-function-call-face)))
                        

(provide 'wisp-mode)
;;; wisp-mode.el ends here
