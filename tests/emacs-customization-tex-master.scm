(defun guess-TeX-master (filename)
      "Guess the master file for FILENAME from currently open .tex files."
      (let 
          (()
            (candidate nil)
            (filename (file-name-nondirectory filename)))
          (save-excursion
            (dolist (buffer (buffer-list))
              (with-current-buffer buffer

                (let 
                   (()
                     (name (buffer-name))
                     (file buffer-file-name))
                   (if 
                     (and file (string-match "\\.tex$" file))

                     (progn
                       (goto-char (point-min))
                       (if 
                          (re-search-forward 
                            (concat "\\\\input{" filename "}")
                            nil t)
                          (setq candidate file))
                       (if 
                          (re-search-forward 
                            (concat "\\\\include{" (file-name-sans-extension filename) "}")
                            nil t)
                          (setq candidate file))))))))
          
          (if candidate
            (message "TeX master document: %s" (file-name-nondirectory candidate)))
          candidate))


