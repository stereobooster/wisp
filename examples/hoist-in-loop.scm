;; This is partial example code taken from the loop optimization Guile code at
;; http://git.savannah.gnu.org/gitweb/?p=guile.git;a=blob;f=module/language/cps/licm.scm;h=3b343a66bd8ed4a591a9e97edbf1179a4d3a78a8;hb=HEAD

; I chose this example because this code felt very dense when I first
; read it, so I wanted to check whether this improves with wisp
; syntax.

; but first the copyright information from the header of the file:

;;; Continuation-passing style (CPS) intermediate language (IL)

;; Copyright (C) 2013, 2014, 2015 Free Software Foundation, Inc.

;;;; This library is free software; you can redistribute it and/or
;;;; modify it under the terms of the GNU Lesser General Public
;;;; License as published by the Free Software Foundation; either
;;;; version 3 of the License, or (at your option) any later version.
;;;;
;;;; This library is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;;; Lesser General Public License for more details.
;;;;
;;;; You should have received a copy of the GNU Lesser General Public
;;;; License along with this library; if not, write to the Free Software
;;;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

(define (hoist-in-loop cps entry body-labels succs preds effects)
  (let* 
       ( 
         (interior-succs 
             (intmap-map 
                 (lambda (label succs)
                          (intset-intersect succs body-labels))
                 succs))
         (sorted-labels (compute-reverse-post-order interior-succs entry))
         (header-label (fresh-label))
         (header-cont (intmap-ref cps entry))
         (loop-vars 
             (match header-cont
                   (($ $kargs names vars)
                       (list->intset vars))))
         (loop-effects
             (persistent-intmap
                       (intset-fold
                        (lambda (label loop-effects)
                           (let 
                             ( 
                               (label*
                                 (if (eqv? label entry)
                                      header-label
                                      label))
                               (fx (intmap-ref effects label)))
                             (intmap-add! loop-effects label* fx)))
                        (body-labels empty-intmap))))
         (pre-header-label entry)
         (pre-header-cont 
             (match header-cont
               (($ $kargs names vars term)
                   (let ((vars* (map (lambda (_) (fresh-var)) vars)))
                     (build-cont
                      ($kargs names vars*
                        ($continue header-label #f
                          ($values vars*))))))))
         (cps (intmap-add! cps header-label header-cont))
         (cps (intmap-replace! cps pre-header-label pre-header-cont))
         (to-visit 
             (match sorted-labels
                     ((head . tail)
                       (unless (eqv? head entry)
                                (error "what?"))
                       (cons header-label tail)))))
    (define (rename-back-edges cont)
      (define (rename label)
               (if (eqv? label entry)
                    header-label
                    label))
      (rewrite-cont cont
        (($ $kargs names vars ($ $continue kf src ($ $branch kt exp)))
            ($kargs names vars
              ($continue (rename kf) src ($branch (rename kt) ,exp))))
        (($ $kargs names vars ($ $continue k src exp))
            ($kargs names vars
              ($continue (rename k) src ,exp)))
        (($ $kreceive ($ $arity req () rest) k)
            ($kreceive req rest (rename k))))
      (let lp 
        ((cps cps)
          (to-visit to-visit)
          (loop-vars loop-vars)
          (loop-effects loop-effects)
          (pre-header-label pre-header-label)
          (always-reached? #t))
        (match to-visit
          (() cps)
          ((label . to-visit)
            (call-with-values
               (lambda ()
                 (hoist-one cps label (intmap-ref cps label) preds
                           loop-vars loop-effects
                           pre-header-label always-reached?))
               (lambda (cps cont loop-vars loop-effects pre-header-label always-reached?)
                  (lp (intmap-replace! cps label (rename-back-edges cont))
                     to-visit
                     loop-vars loop-effects pre-header-label always-reached?)))))))))


