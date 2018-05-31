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

set! *random-state* : random-state-from-platform

define-record-type <node>
    make-node location peers
    . node?
    location node-location
    peers node-peers node-set-peers!

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
          {shift >= steps}
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
       

;; add 30 random peers to each node, since these are unordered, I can simply use a sliding window
define : random-network locations
    define nodes
        list-ec (: i locations)
            make-node i (list)
    connect-neighbor-nodes nodes 30 1

define : modulo-distance loc1 loc2
    min
        abs (- loc1 loc2)
        abs (- (- loc1 1) loc2)
        abs (- loc1 (- loc2 1))

define : main args
    let
      :
        distances
            fold
                λ (node previous)
                    append
                        map (λ (peer) (modulo-distance (node-location peer) (node-location node)))
                            node-peers node
                        . previous
                . '()
                random-network locations
      map : λ (x) (display x) (newline)
          sort distances <
