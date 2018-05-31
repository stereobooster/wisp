#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec) (language wisp))'
exec guile -L $(dirname $(dirname $(realpath "$0"))) -x .w --language=wisp -e '(examples network)' -s "$0" "$@"
; !#

define-module : examples network
    . #:export : main

import : srfi srfi-9 ; records
         ice-9 vlist ; vhashes
         srfi srfi-42 ; list-ec
         srfi srfi-1 ; fold
         oop goops

set! *random-state* : random-state-from-platform

define-class <node> ()
    location #:init-value #f #:getter node-location #:setter node-set-location! #:init-keyword #:location
    peers #:init-value (list) #:getter node-peers #:setter node-set-peers! #:init-keyword #:peers
    decrement-htl #:init-value (list) #:getter node-decrement-htl #:setter node-set-decrement-htl!  #:init-keyword #:decrement-htl

;; convenience methods
define : make-node location peers
    make <node> #:location location #:peers peers
define-method : display (node <node>)
    display node #f
define-method : display (node <node>) port
    format port "#<<node> ~a peers: ~a htl-set: ~a"
        node-location node
        length : node-peers node
        length : node-decrement-htl node

;; list of 1,000,000 random floats: 75 MiB
;; list of 1,000,000 records, each with a random float and a list: 110 MiB
;; list of lists with two random floats: 108 MiB
;; vhash with 1,000,000 keys pointing to lists: 105 MiB
;; 100k nodes, 30 peers, 120 MiB of memory
define locations
    list-ec (: i 10000) : random:uniform

define : connect-neighbor-nodes nodes steps stepsize
    . "Add neighbors of the nodes to the peers of the respective nodes"
    ;; connect nodes at random
    let loop
        : shift 0
          shifted '()
          seen : reverse nodes
          unprocessed '()
        cond
          {shift > steps}
            . 'done
          : null? unprocessed
            loop {shift + 1}
              append
                  reverse! : take seen stepsize
                  reverse! : drop seen stepsize
              . '()
              . nodes
          else
            let 
                : node : car unprocessed
                  peer : car shifted
                node-set-peers! node : cons peer (node-peers node)
            loop shift
                cdr shifted
                cons (car shifted) seen
                cdr unprocessed
    . nodes
       
define : log2 number
    / : log number
        log 2

;; add 30 random peers to each node, since these are unordered, I can simply use a sliding window
define : random-network locations
    define nodes
        list-ec (: i locations)
            make-node i (list)
    define steps : truncate : * 2 : + 1 : log2 (length locations)
    connect-neighbor-nodes nodes steps 1

define : neighbor-network locations
    define nodes
        list-ec (: i (sort locations < ))
            make-node i (list)
    define steps : truncate : + 1 : log2 (length locations)
    connect-neighbor-nodes 
        reverse : connect-neighbor-nodes nodes steps 1
        . steps 1

define : smallworld-network locations
    . "create an approximate small world network. Approximate, because it only uses the order of the locations, not their distance"
    define nodes
        list-ec (: i (sort locations <))
            make-node i (list)
    let loop
        : nodes nodes
          steps 1
          stepsize 1
        if {stepsize > (length nodes)}
          . nodes
          loop
              connect-neighbor-nodes 
                  reverse : connect-neighbor-nodes nodes steps stepsize
                  . steps stepsize
              . steps
              . {stepsize * 2}


define : modulo-distance loc1 loc2
    min
        abs (- loc1 loc2)
        abs (- (- loc1 1) loc2)
        abs (- loc1 (- loc2 1))

define-method : dist (node <node>) (other <node>)
    module-distance
        node-location node
        node-location other
define-method : dist (node <node>) (other <number>)
    modulo-distance
        node-location node
        . other
define-method : dist (node <number>) (other <node>)
    modulo-distance
        . node
        node-location other
define-method : dist (node <number>) (other <number>)
    modulo-distance
        . node
        . other


define : find-best-peer node location
    ;; TODO: Optimize by putting the peers into a skip list for O(N) retrieval
    let loop 
        : best-peer #f
          peers : node-peers node
        cond
          : null? peers
            . best-peer
          : or (not best-peer) {(dist (first peers) location) < (dist best-peer location)}
            loop
                first peers
                cdr peers
          else
            loop best-peer : cdr peers


define : route-between origin location HTL
    let : : best-peer : find-best-peer origin location
        if
            or : not best-peer ;; no peers at all
               . {HTL < 1}
               . {(dist origin location) < (dist best-peer location)}
            list origin
            cons origin
                route-between best-peer location
                    decrement-htl best-peer origin HTL

define : decrement-htl node origin HTL
    if {HTL < 18}
        - HTL 1
        let*
          : decrement-info : node-decrement-htl node
            decrement-origin : assoc origin decrement-info
          cond
             : not decrement-origin ;; not set, decide now
               node-set-decrement-htl! node : alist-cons origin {(random:uniform) < 0.5} decrement-info
               decrement-htl node origin HTL
             : cdr decrement-origin
                - HTL 1
             else
                . HTL


define : get-argument args name default
    let : : index : list-index (λ(x) (equal? x name)) args
        if : not index 
           . default
           list-ref args {index + 1}

define : choose-network args
         let : : name : get-argument args "--network" "random"
           cond
               : equal? name "random"
                 . random-network
               : equal? name "neighbor"
                 . neighbor-network
               : equal? name "smallworld"
                 . smallworld-network
        

define : closest-node origin location
    take-right : route-between origin location
               . 1

define : main args
    let*
      : network-function : choose-network args
        nodes : network-function locations
        distances
            fold
                λ (node previous)
                    append
                        map (λ (peer) (dist peer (node-location node)))
                            node-peers node
                        . previous
                . '()
                . nodes
      ;; display : car nodes
      ;; newline
      ;; display : sort (node-peers (car nodes)) (λ(a b) (< (dist (node-location a) (node-location (car nodes))) (dist (node-location b)  (node-location (car nodes)))))
      ;; newline
      ;; display "ROUTE: "
      ;; display : route-between (car nodes) 0.25 18
      ;; newline
      ;; exit 0
      map : λ (x) (display x) (newline)
          sort distances <

;; plot network: 
;;     for i in random neighbor smallworld; do ./network.w --network $i > /tmp/$i; done; echo -e 'set term X\nset logscale y\nplot "/tmp/random" title "random", "/tmp/smallworld" title "smallworld", "/tmp/neighbor" title "neighbor"\n' | gnuplot -p
