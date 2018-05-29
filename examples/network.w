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
    list-ec (: i 100000) : random:uniform
    
;; add 30 random peers to each node, since these are unordered, I can simply use a sliding window
define : random-network locations
    define network vlist-null
    ;; setup network with nodes without peers
    do-ec (: i locations)
        set! network : vhash-cons i (make-node i (list)) network
    ;; connect nodes at random
    let loop
        : shift 0
          shifted locations
          seen '()
          unprocessed locations
        cond
          {shift >= 30}
            . 'done
          : null? unprocessed
            loop {shift + 1}
              cons (car seen) : reverse! (cdr seen)
              . '()
              . locations
          else
            let 
                : node : cdr : vhash-assoc (car unprocessed) network
                  peer : cdr : vhash-assoc (car shifted) network
                node-set-peers! node (cons peer (node-peers node))
            loop shift
                cdr shifted
                cons (car shifted) seen
                cdr unprocessed
    . network

define : main args
    display : random-network locations
    sleep 10
