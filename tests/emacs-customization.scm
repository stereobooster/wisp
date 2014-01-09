(if (file-directory-p "~/.emacs.d/private/journal/")
     (setq-default journal-dir "~/.emacs.d/private/journal/"))

(global-set-key [(control meta .)] 'goto-last-change-reverse)

(require 'org-latex)
(add-to-list 'org-export-latex-packages-alist 
  '("" "minted"))

(add-to-list 'org-export-latex-packages-alist 
  '("" "color"))

(setq org-export-latex-listings 'minted)

(add-hook 'outline-mode-hook 
          (lambda ()
             (require 'outline-magic)))


(defun find-file-as-root ()
  "Like `ido-find-file, but automatically edit the file with
root-privileges (using tramp/sudo), if the file is not writable by
user."
  (interactive)
  (let ((file (ido-read-file-name "Edit as root: ")))
    (unless (file-writable-p file)
      (setq file (concat find-file-root-prefix file)))
    (find-file file)))

(defun find-current-as-root ()
  "Reopen current file as root"
  (interactive)
  (set-visited-file-name (concat find-file-root-prefix (buffer-file-name)))
  (setq buffer-read-only nil))

; the next function definition is equivalent, due to inline : 

(defun find-current-as-root ()
  "Reopen current file as root"
  (interactive)
  (set-visited-file-name 
    (concat find-file-root-prefix 
      (buffer-file-name)))
  (setq buffer-read-only nil))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(bbdb-complete-name-allow-cycling t)
 '(bbdb-ignore-some-messages-alist (quote (("From" . "mailer-daemon"))))
 '(bbdb-offer-save (quote savenoprompt)))


(setq a "x"
   b "y"
   c "z")

