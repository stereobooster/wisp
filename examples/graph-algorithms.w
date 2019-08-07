#!/usr/bin/env bash
# -*- wisp -*- 
# set Guile if unset
if [ -z ${GUILE+x} ]; then
	GUILE=guile
fi
exec -a "$0" "${GUILE}" -L "$(dirname "$(dirname "$(realpath "$0")")")" -x .w --language=wisp -e '(examples graph-algorithms)' -c '' "$@"
; !#

define-module : examples graph-algorithms
   . #:export : main

import : ice-9 pretty-print
         srfi srfi-4

define nodelist : list->u16vector : iota : * 64 1024 ;; max value for u16 vector!

define : create-edges
  define nodecount : u16vector-length nodelist
  define edgecount {nodecount * 100}
  define edgecar : make-u16vector edgecount
  define edgecdr : make-u16vector edgecount
  let loop : (edgeidx  0) (nodeidx 0)
      when {nodeidx < nodecount}
          let lp : : edges-of-this-node 0
              cond
                {edges-of-this-node < 100}
                  u16vector-set! edgecar {edgeidx + edges-of-this-node} nodeidx
                  u16vector-set! edgecdr {edgeidx + edges-of-this-node} 
                      modulo {nodeidx + edges-of-this-node} nodecount
                  lp {edges-of-this-node + 1}
                else
                  loop {edgeidx + edges-of-this-node} {nodeidx + 1}
                  
  cons edgecar edgecdr

define : nodes-and-edges->adjacency-lists-by-index nodelist edges
    . "Assemble adjacency lists by index in the nodelist"
    define number-of-nodes : u16vector-length nodelist
    define number-of-edges : u16vector-length : car edges
    define adjacency-lists : make-vector number-of-nodes 0
    define adjacency-lists-current-idx : make-u16vector number-of-nodes 0
    define edge-start : car edges
    define edge-target : cdr edges
    define : get-start idx
        u16vector-ref edge-start idx
    define : get-end idx
        u16vector-ref edge-target idx
    ;; count targets per node
    let loop : : idx {number-of-edges - 1}
        when {idx > 0}
           let : : start : get-start idx
               vector-set! adjacency-lists start
                  + 1 : vector-ref adjacency-lists start
           loop {idx - 1}
    ;; prepare u16vectors
    let loop : : idx {number-of-nodes - 1}
        when {idx > -1}
           let : : len : vector-ref adjacency-lists idx
             if {len = 0}
                 vector-set! adjacency-lists idx #f
                 vector-set! adjacency-lists idx : make-u16vector {len + 1}
           loop {idx - 1}
    ;; collect edges
    let loop : : idx {number-of-edges - 1}
        when {idx > -1}
           let* 
               : start : get-start idx
                 edgelist-idx : u16vector-ref adjacency-lists-current-idx start
               u16vector-set! : vector-ref adjacency-lists start
                   . edgelist-idx
                   get-end idx
               u16vector-set! adjacency-lists-current-idx start {edgelist-idx + 1}
           loop {idx - 1}
    . adjacency-lists


define : bfs adjacency-list seed
    . "Traverse all nodes in the adjacency list via breadth first search"
    define discovered : make-bitvector (vector-length adjacency-list) #f
    define processed : make-bitvector (vector-length adjacency-list) #f
    bitvector-set! discovered seed #t
    let loop : : queue : list seed
        if : null? queue
           . #f ;; done
           let*
               : current-node : car queue
                 edges : vector-ref adjacency-list current-node
                 edgecount : if edges (u16vector-length edges) 0
               ;; display current-node
               ;; newline
               let lp
                   : idx {edgecount - 1}
                     new : list
                   if {idx < 0}
                     loop : append (cdr queue) new
                     let : : current-target : u16vector-ref edges idx
                         cond
                           : not : bitvector-ref discovered current-target
                             bitvector-set! discovered current-target #t
                             lp {idx - 1} : cons current-target new
                           else
                             lp {idx - 1} new
                       

define : main args
    ; pretty-print nodelist
    define edgelist : create-edges
    define adjacency : nodes-and-edges->adjacency-lists-by-index nodelist edgelist
    pretty-print
        u16vector-length
            car edgelist
    pretty-print : vector-ref adjacency 0
    ; pretty-print : nodes-and-edges->adjacency-lists-by-index nodelist edges
    bfs adjacency 0
    ;; let lp : : i 1000000000
    ;;     when {i > 0}
    ;;         lp {i - 1}
    
