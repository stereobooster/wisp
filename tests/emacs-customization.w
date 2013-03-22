if : file-directory-p "~/.emacs.d/private/journal/"
     setq-default journal-dir "~/.emacs.d/private/journal/"

global-set-key [(control meta .)] 'goto-last-change-reverse

require 'org-latex
add-to-list 'org-export-latex-packages-alist 
  ' "" "minted"

add-to-list 'org-export-latex-packages-alist 
  ' "" "color"

setq org-export-latex-listings 'minted

add-hook 'outline-mode-hook 
          lambda :
             require 'outline-magic

