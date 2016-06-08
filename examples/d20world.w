#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples d20world) main)' -s "$0" "$@"
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
use-modules : srfi srfi-1
use-modules 
  : ice-9 popen
        . #:select : open-output-pipe close-pipe

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
       let leapfrog : : targets '(0 1 2)
           if : null?  targets
             . world
             let loop : : neighbors-to-diffuse : iota : vector-length neighbors
                cond 
                  : null? neighbors-to-diffuse
                    leapfrog : cdr targets
                  else
                      let*
                          : originidx : car neighbors-to-diffuse ; index in world and in neighbors
                            targetleap : car targets
                            targetidx : vector-ref (vector-ref neighbors originidx) targetleap
                            originval : vector-ref world originidx
                            targetval : vector-ref world targetidx
                            diff : * (/ D 3) : - targetval originval
                          vector-set! world originidx : + originval diff
                          vector-set! world targetidx : - targetval diff
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


define d20numbers '(1 14 10 6
                    19 18 4 8 9 16
                    2 3 17 13 12 5
                    11 15 7 20)

define : cellidx->dienumber idx
       list-ref d20numbers idx

define : dienumber->cellidx number
       list-index (λ(x)(= x number)) d20numbers


define : latlonsixthslabidx latfromtop lonfrac
       . "calculate the index in a sixth longitude slab of the icosaeder"
       ; TODO: use shortest surface distance from center of triangle as faster metric.
       let*
          : triangleheight : / (sqrt 3) 2
            length-top-to-bottom-at-lon0 : + 1 (* 2 triangleheight)
            height-deg : * 180 : / triangleheight length-top-to-bottom-at-lon0
            side-deg : * 180 : / 1 length-top-to-bottom-at-lon0
          ; in one sixth of the icosaeder, there are 6 reachable
          ; fields. I am indexing them from top to bottom.
          ; format #t "latfromtop: ~a, lonfrac: ~a, height-deg/3: ~a, side-deg: ~a\n" latfromtop lonfrac (/ height-deg 3) side-deg
          cond
            : < latfromtop : / height-deg 3
              . 0
            : < latfromtop : - (* 2 (/ height-deg 3)) (* lonfrac (/ height-deg 3))
              . 0
            : < latfromtop : * 2 : / height-deg 3
              . 1
            : < latfromtop : + (* 2 (/ height-deg 3)) (* lonfrac (* 2 (/ height-deg 3)))
              . 1
            : < latfromtop : * 4 : / height-deg 3
              . 2
            : < latfromtop : - (+ side-deg (* 2 (/ height-deg 3))) (* lonfrac (- (+ side-deg (* 2 (/ height-deg 3))) (* 4 (/ height-deg 3))))
              . 2
            : < latfromtop : + side-deg : * 2 : / height-deg 3
              . 3
            : < latfromtop : + (+ side-deg (* 2 (/ height-deg 3))) (* lonfrac (- (+ side-deg (* 4 (/ height-deg 3))) (+ side-deg (* 2 (/ height-deg 3)))))
              . 3
            : < latfromtop : - (+ side-deg (* 5 (/ height-deg 3))) (* lonfrac (- (+ side-deg (* 5 (/ height-deg 3))) (+ side-deg (* 4 (/ height-deg 3)))))
              . 4
            else
              . 5
         

define : latlon2cellidx lat lon 
        . "Convert a position given as latitude (-90 .. 90) and
longitude (0 .. 360) into the correct cell index.

This uses heavy linear approximation."
        ; cell 1 (index 0) is on top, cell 20 at the bottom. The left
        ; border of cell 2 is situated at longitude 0. We can cleanly
        ; divide the upper part of the icosaeder into 3 regions by
        ; longitude. Let's do that.
        let* ; the sector number is defined by the uppermost triangle
            : sector : if (< lon 120) 2 (if (< lon 270) 4 3)
              ; we start by calculating the fraction inside the sector
              lonsectorfraction : modulo lon 120
              ; we can further subdivide the sector by longitude into two subsectors
              subsector : if (< lonsectorfraction 60) 0 1
              subseclon : if (= subsector 0) lonsectorfraction (- 120 lonsectorfraction)
              lonfrac : / subseclon 60
              latfromtop : - 90 lat
              sixthslab : latlonsixthslabidx latfromtop lonfrac
              ; for each sector and subsector, set the dienumber
              slabsec->index '((2 . ((1 14 19 13 15 20) (1 14 16 17 11 20)))
                               (4 . ((1 6 9 3 11 20) (1 6 8 2 7 20)))
                               (3 . ((1 10 4 5 7 20) (1 10 18 12 15 20))))
            dienumber->cellidx
              list-ref
                list-ref
                  assoc-ref slabsec->index sector
                  . subsector
                . sixthslab


define : main args
       . "Test the code"
       if : > 2 (length args)
         set! args : append args '("88") ; lat
       if : > 3 (length args)
         set! args : append args '("45") ; lon
       display : latlon2cellidx (string->number (first (take-right args 2))) (string->number (last args))
       newline
       display : d20-as-text world
       newline
       
       ; format #t "Diffuse ~A\n" 0.01
       ; d20-diffuse world neighbors 0.01
       ; display : d20-as-text world
       ; newline
       ; format #t "Advect ~A\n" 0.1
       ; d20-advect world advection-directions 0.1
       ; display : d20-as-text world
       ; newline
       ; format #t "Diffuse ~A\n" 0.1
       ; d20-diffuse world neighbors 0.1
       ; display : d20-as-text world
       ; newline
       format #t "Diffuse: ~A*(~A)\n" 100 0.1
       let loop : : steps 100
           cond
             : = 0 steps
               . world
             else
               d20-diffuse world neighbors 0.1
               loop : 1- steps
       display : d20-as-text world
       newline
       ; let 
       ;   : number 20
       ;     val 1
       ;   format #t "disturb: ~A to ~A\n" number val
       ;   vector-set! world (1- number) val
       ;   display : d20-as-text world
       ;   newline
       ; format #t "Diffuse ~A\n" 0.1
       ; d20-diffuse world neighbors 0.1
       ; display : d20-as-text world
       ; newline
       ; 
       ; format #t "Advect: ~A*(~A)\n" 1000 0.001
       ; let loop : : steps 1000
       ;     cond
       ;       : = 0 steps
       ;         . world
       ;       else
       ;         d20-advect world advection-directions 0.001
       ;         display : d20-as-text world
       ;         d20-cursor-up-text world
       ;         loop : 1- steps
       ; display : d20-as-text world
       ; newline
       ; format #t "Diffuse: ~A*(~A)\n" 1000 0.004
       ; let loop : : steps 1000
       ;     cond
       ;       : = 0 steps
       ;         . world
       ;       else
       ;         d20-diffuse world neighbors 0.004
       ;         display : d20-as-text world
       ;         d20-cursor-up-text world
       ;         loop : 1- steps
       display : d20-as-text world
       newline
       format #t "Diffuse+Advect: ~A*(~A+~A)\n" 1000 0.002 0.001
       let loop : : steps 1000
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
       
       let
         :
           v
              let loop 
                : lon 359
                  lat 89
                  map '()
                  zone '()
                cond
                  : and (= lat -90) (= lon 0)
                    cons : cons (vector-ref world (latlon2cellidx lat lon)) zone 
                      . map
                  : = lon 0
                    loop
                      . 359
                      - lat 1
                      cons : cons (vector-ref world (latlon2cellidx lat lon)) zone 
                        . map
                      . '()
                  else
                    loop
                      - lon 1
                      . lat
                      . map
                      cons : vector-ref world : latlon2cellidx lat lon
                        . zone
           port : open-output-pipe "python"
         display "a = \"" port
         write v port 
         display "\"" port
         newline port
         display "a = eval(a.replace('(', '[').replace(')', ']').replace(' ',', '))" port
         newline port
         display "import numpy as np
import pylab as pl
import mpl_toolkits.basemap as bm
arr = np.array(a)

m = bm.Basemap(projection='cea', resolution='l', lat_ts=37.5)
m.drawcoastlines(color='k',linewidth=0.3)
m.drawmeridians(np.arange(-120.0, 180.0, 60), labels=[0,0,0,1], linewidth=0.15) # , yoffset=6) # labels = [left,right,top,bottom]
m.drawparallels(np.arange(-60.0, 90.0, 30), labels=[1,0,0,0], linewidth=0.15)
ny, nx = arr.shape
lons, lats = pl.meshgrid(range(-nx/2, nx/2 + nx%2),
                         range(-ny/2, ny/2 + ny%2))
x, y = m(lons, lats)

m.pcolormesh(x, y, arr)
pl.show()
" port
         close-pipe port
       newline
         
       
;        ; now plot the result
;        let : : port : open-output-pipe "python"
;          format port "from mpl_toolkits.mplot3d import Axes3D, art3d
; import numpy as np
; import scipy as sp
; from matplotlib import cm
; import matplotlib.pyplot as plt
; from scipy.spatial import Delaunay
; 
; def Icosahedron():
;     h = 0.5*(1+np.sqrt(5))
;     p1 = np.array([[0,1,h],[0,1,-h],[0,-1,h],[0,-1,-h]])
;     p2 = p1[:,[1,2,0]]
;     p3 = p1[:,[2,0,1]]
;     return np.vstack((p1,p2,p3))
; 
; Ico = Icosahedron()
; tri = Delaunay(Ico)
; CH = tri.convex_hull
; points = tri.points
; 
; fig = plt.figure(figsize=(4.0,4.0))
; ax = fig.add_subplot(111, projection='3d')
; 
; print points
; for i in range(points.shape[0]):
;     neighbors = tri.neighbors[i,:]
;     for n in range(points.shape[0]):
;         pts = []
;         for u in range(points.shape[0]):
;             pt = np.zeros((3,3))
;             pt[0,:] = points[(i),:]
;             pt[1,:] = points[(n),:]
;             pt[2,:] = points[(u),:]
;             # print pt
;             pt *= 0.5
;             pt += 0.5
;             pts.append(pt)
;         tr = art3d.Poly3DCollection(pts)
;         tr.set_color([(0.9*i)/points.shape[0]] + [(0.9*n)/points.shape[0]]*3)
;         ax.add_collection3d(tr)
; # ax.plot_surface(x, y, z, color='g')
; 
; plt.show()
; 
; exit()\n"
;          close-pipe port
