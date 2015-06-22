(package (newbase60 (0))
         (synopsis "Implementation of Tanteks New Base 60")
         (depends (srfi) (ice-9))
         (libraries
          (scm -> "newbase60"))
         (programs
          (("newbase60.scm") -> "newbase60")))
