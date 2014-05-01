#!/home/arne/wisp/wisp-multiline.sh 
; !#

; A world projected on a d20 (20-sided die)

; For this we need a vector with 20 elements, a vector which shows the
; neighboring elements and accessor functions which give us the
; relevant elements for any set of longitude and latitude as well as
; its inverse (element-id to lon+lat). For further subdivisions, just
; elevate the center of each edge and connect these centers.

define world : make-vector 20
define neighbors : make-vector 20
; count from the top
; Contains the numbers instead of the indexes, to make it easier for
; me to think about them.
; 
;   7       8
;    3    4  
;       1        
;   6   2   9
;     5   10
; 
;    14       13
;     18    17
;        20        
;   15   19   12
;     16    11
; 
define neighbors-helper
  ' : 1 2 3 4
      2 1 5 10
      3 1 6 7
      4 1 8 9
      5 2 6 14
      6 3 5 15
      7 3 8 16
      8 4 7 11
      9 4 10 12
      10 1 9 13
      20 19 18 17
      19 20 16 11
      18 20 15 14
      17 20 13 12
      16 19 17 7
      15 18 16 6
      14 18 13 5
      13 17 14 10
      12 17 11 9
      11 19 12 8

let loop : : relationships neighbors-helper
  cond 
   : null? relationships
     . neighbors
   else
    let* 
      : cur : car relationships
          idx : 1- : car cur
          vec : cdr cur
      vector-set! world idx idx
      vector-set! neighbors idx : make-vector 3
      let setidx : : idxtoset '(0 1 2)
        cond 
         : null? idxtoset
           . #t
         else
            vector-set!
                vector-ref neighbors idx
                car idxtoset
                1- : list-ref vec : car idxtoset
            setidx : cdr idxtoset
      loop : cdr relationships

display world
newline
display neighbors
newline
display : vector-ref world 0
newline
