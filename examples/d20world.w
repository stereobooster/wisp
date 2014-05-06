#!/home/arne/wisp/wisp-multiline.sh 
; !#

; A world projected on a d20 (20-sided die, ikosaeder)

; For this we need a vector with 20 elements, a vector which shows the
; neighboring elements and accessor functions which give us the
; relevant elements for any set of longitude and latitude as well as
; its inverse (element-id to lon+lat). For further subdivisions, just
; elevate the center of each edge and connect these centers.

; Advection: Give each field a wind direction: target fields with an
; advection fraction: The fraction of the value which will be
; transported into the other field. Basic system: Follow the numbers.

define-module : examples d20world
              . #:export : world neighbors d20-as-text d20-diffuse

use-modules : ice-9 format

define world : make-vector 20 0
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
      vector-set! world idx : 1+ idx
      vector-set! neighbors idx : make-vector 3
      let setidx : : idxtoset '(0 1 2)
        cond 
         : null? idxtoset
           ; the outer loop continues here
           loop : cdr relationships
         else
            vector-set!
                vector-ref neighbors idx
                car idxtoset
                1- : list-ref vec : car idxtoset
            setidx : cdr idxtoset

define advection-directions
       make-vector 20

let loop : : index 20
    cond 
      : = 0 index
        . advection-directions
      : = 20 index
        vector-set! advection-directions (1- index) (1- index)
        loop : 1- index
      else
        vector-set! advection-directions (1- index) index
        loop : 1- index

define : d20-value-ascii-color-string letter value
         . "Create an ascii color string for d20."
         let 
           : csi "["
             color : inexact->exact : max 17 : min 230 : floor : * 12 value
           format #f "~A38;5;~dm~A~Am" csi color letter csi

define : d20-value-ascii-color-string-show-values letter value
         . "Create an ascii color string for d20."
         let 
           : csi "["
             color : inexact->exact : max 17 : min 230 : floor : * 12 value
             int : inexact->exact : floor : * 12 value
           format #f "~A38;5;~dm~A~Am" csi color int csi

define : d20-as-text-base world-vector function
         . "show the given d20 world as text"
         let 
           : template "
 ~A         ~A     
   ~A    ~A        
      ~A           
 ~A    ~A    ~A    
    ~A   ~A        
                   
 ~A       ~A       
  ~A    ~A         
     ~A            
~A   ~A   ~A       
  ~A    ~A         
"
             indexes ' : 7 8 3 4 1 6 2 9 5 10 14 13 18 17 20 15 19 12 16 11
           apply format : append (list #f template) : map function indexes : map (lambda (x) (vector-ref world (1- x))) indexes

define : d20-as-text world-vector
         . "show the given d20 world as text"
         d20-as-text-base world-vector d20-value-ascii-color-string-show-values

define : d20-cursor-up-text world-vector
         . "Kill each line of the text of the world vector in a terminal."
         let* 
           : text : d20-as-text-base world-vector d20-value-ascii-color-string-show-values
             lines : string-split text #\newline
           format #t "[~AA" : 1- : length lines

define : d20-diffuse world neighbors D
         . "Diffuse the values on the d20 using the diffusion constant D. Step 1: Simply iterative."
         let loop : : neighbors-to-diffuse : iota : vector-length neighbors
             cond 
               : null? neighbors-to-diffuse
                 . world
               else
                 let : : edges-to-diffuse-targets : vector-ref neighbors (car neighbors-to-diffuse)
                         let*
                           : edges-to-diffuse : append (list (car neighbors-to-diffuse)) : vector->list edges-to-diffuse-targets
                             idx0 : list-ref edges-to-diffuse 0
                             idx1 : list-ref edges-to-diffuse 1
                             idx2 : list-ref edges-to-diffuse 2
                             idx3 : list-ref edges-to-diffuse 3
                             val0 : vector-ref world idx0
                             val1 : vector-ref world idx1
                             val2 : vector-ref world idx2
                             val3 : vector-ref world idx3
                             diff0 : * (/ D 3) : - val1 val0
                             diff1 : * (/ D 3) : - val2 val0
                             diff2 : * (/ D 3) : - val3 val0
                           vector-set! world idx0 : + val0 diff0 diff1 diff2
                           vector-set! world idx1 : - val1 diff0
                           vector-set! world idx2 : - val2 diff1
                           vector-set! world idx3 : - val3 diff2
                 loop : cdr neighbors-to-diffuse


define : d20-advect world advection-directions A
         . "Advect the values on the d20 using the advection constant A."
         let loop : : neighbors-to-advect : iota : vector-length advection-directions
             cond 
               : null? neighbors-to-advect
                 . world
               else
                 let*
                   : source : car neighbors-to-advect
                     target : vector-ref advection-directions source
                     source-value : vector-ref world source
                     target-value : vector-ref world target
                     change : * A source-value
                     source-new : - source-value change
                     target-new : + target-value change
                   ; format #t "target: ~A, source: ~A, change: ~A\n" target source change
                   when : not : = source target
                       vector-set! world source source-new
                       vector-set! world target target-new
                 loop : cdr neighbors-to-advect


define φ : * (/ 1 2) : 1+ : sqrt 5


display : d20-as-text world
newline
format #t "Diffuse ~A\n" 0.01
d20-diffuse world neighbors 0.01
display : d20-as-text world
newline
format #t "Advect ~A\n" 0.1
d20-advect world advection-directions 0.1
display : d20-as-text world
newline
format #t "Diffuse ~A\n" 0.1
d20-diffuse world neighbors 0.1
display : d20-as-text world
newline
format #t "Advect ~A\n" 0.1
d20-advect world advection-directions 0.1
display : d20-as-text world
newline
format #t "Advect ~A\n" 0.1
d20-advect world advection-directions 0.1
display : d20-as-text world
newline
format #t "Advect: ~A*(~A)\n" 1000 0.001
let loop : : steps 1000
    cond
      : = 0 steps
        . world
      else
        d20-advect world advection-directions 0.001
        display : d20-as-text world
        d20-cursor-up-text world
        loop : 1- steps
display : d20-as-text world
newline
format #t "Diffuse: ~A*(~A)\n" 1000 0.004
let loop : : steps 1000
    cond
      : = 0 steps
        . world
      else
        d20-diffuse world neighbors 0.004
        display : d20-as-text world
        d20-cursor-up-text world
        loop : 1- steps
display : d20-as-text world
newline
format #t "Diffuse+Advect: ~A*(~A+~A)\n" 10000 0.002 0.001
let loop : : steps 10000
    cond
      : = 0 steps
        . world
      else
        d20-diffuse world neighbors 0.002
        d20-advect world advection-directions 0.001
        display : d20-as-text world
        d20-cursor-up-text world
        loop : 1- steps
display : d20-as-text world
newline
