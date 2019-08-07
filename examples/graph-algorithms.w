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
    define adjacency-lists : make-vector number-of-nodes '()
    define : get-start idx
        u16vector-ref (car edges) idx
    define : get-end idx
        u16vector-ref (cdr edges) idx
    ;; collect edges
    let loop : : idx 0
        when {idx < number-of-edges}
           let : : start : get-start idx
               vector-set! adjacency-lists start
                   cons : get-end idx
                       vector-ref adjacency-lists start
               loop {idx + 1}
    ;; compress edges, requires about 50 MiB for 6 million edges
    let loop : : idx {(vector-length adjacency-lists) - 1}
        when {idx >= 0}
            let : : this-nodes-edges : vector-ref adjacency-lists idx
              if : null? this-nodes-edges
                   vector-set! adjacency-lists idx #f
                   vector-set! adjacency-lists idx : list->u16vector this-nodes-edges
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
           let : : current-node : car queue
               ;; display current-node
               ;; newline
               let lp
                   : edges : u16vector->list : vector-ref adjacency-list current-node
                     new : list
                   cond
                     : null? edges
                       loop : append (cdr queue) new
                     : not : bitvector-ref discovered (car edges)
                       bitvector-set! discovered (car edges) #t
                       lp (cdr edges)
                          cons (car edges) new
                     else
                       lp (cdr edges) new
                       

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
    
