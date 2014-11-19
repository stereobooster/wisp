(use-modules (sxml simple))

; write xml to the output port
(sxml->xml
   (quote
     (html
         (head (title "test"))
         (body
             (h1 "test")
             (p "it " (em "works!")
               (br)
               (" it actually works!"))))))

(newline)


