;; the name is an in-joke
import : only (fake import) file-or-http-url? resource-reference string-replace-substring

define : ptifrrabirrf path unresolved
    define : convert s
             string-replace-substring s "%20" " "
    when : or (not path) (not unresolved)
           error "Illegal Argument: path and unresolved must not be #false, but path was ~a and unresolved was ~a"
                 . path unresolved

    if : or (file-or-http-url? path) (file-exists? path)
       resource-reference path unresolved
       let : : converted-path : convert path
           if : file-exists? converted-path
                resource-reference converted-path : convert unresolved
                resource-reference path unresolved
         
