#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec) (language wisp))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) -x .w --language=wisp -e '(examples network)' -c '' "$@"
; !#

define-module : examples network
    . #:export : main

import : srfi srfi-9 ; records
         ice-9 vlist ; vhashes
         srfi srfi-42 ; list-ec
         srfi srfi-1 ; fold
         oop goops
         only (rnrs base (6)) mod ; modulo on reals

set! *random-state* : random-state-from-platform

define max-htl 18 ;; set for more convenient testing
define peer-count-scaling 0.2 ;; probabilistic reduction of the peers to make the network topology more challenging

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
    format port "#<<node> ~a peers: ~a htl-set: ~a>"
        node-location node
        length : node-peers node
        length : node-decrement-htl node

;; list of 1,000,000 random floats: 75 MiB
;; list of 1,000,000 records, each with a random float and a list: 110 MiB
;; list of lists with two random floats: 108 MiB
;; vhash with 1,000,000 keys pointing to lists: 105 MiB
;; 100k nodes, 30 peers, 120 MiB of memory
define : create-locations count
    list-ec (: i count) : random:uniform

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
                when {peer-count-scaling > (random:uniform)}
                    node-set-peers! node : cons peer (node-peers node)
                    node-set-peers! peer : cons node (node-peers peer)
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
        list-ec (: i locations)
            make-node i (list)
    define steps : truncate : + 1 : log2 (length locations)
    connect-neighbor-nodes 
        reverse
            connect-neighbor-nodes : sort nodes : λ(a b) : < (node-location a) (node-location b)
                . steps 1
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
                  reverse
                      connect-neighbor-nodes : sort nodes : λ(a b) : < (node-location a) (node-location b)
                          . steps stepsize
                  . steps stepsize
              . steps
              . {stepsize * 2}


define : modulo-distance loc1 loc2
    min
        abs (- loc1 loc2)
        abs (- (- loc1 1) loc2)
        abs (- loc1 (- loc2 1))

define-method : dist (node <node>) (other <node>)
    modulo-distance
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


define : find-best-peer node location exclude
    ;; TODO: Optimize by putting the peers into a skip list for O(logN) retrieval
    let loop 
        : best-peer #f
          peers : node-peers node
        ;; format (current-error-port) "peers ~a exclude ~a\n" peers exclude
        cond
          : null? peers
            . best-peer
          : member (first peers) exclude
            loop
              . best-peer
              cdr peers
          : or (not best-peer) {(dist (first peers) location) < (dist best-peer location)}
            loop
                first peers
                cdr peers
          else
            loop best-peer : cdr peers


define-method : route-simple-greedy (origin <node>) (location <node>) (HTL <number>)
    route-simple-greedy origin (node-location location) HTL

define-method : route-simple-greedy (origin <node>) (location <number>) (HTL <number>)
    let loop
        : origin origin
          route : list
          HTL HTL
        ;; format (current-error-port) "origin ~a route ~a\n" origin route
        let : : best-peer : find-best-peer origin location route
            if
                or : not best-peer ;; no peers at all
                   . {HTL < 1}
                   . {(dist origin location) < (dist best-peer location)}
                reverse : cons origin route
                loop best-peer
                     cons origin route
                     decrement-htl best-peer origin HTL

define-method : route-for-swap (origin <node>) (location <node>) (HTL <number>)
    route-for-swap origin (node-location location) HTL

define-method : route-for-swap (origin <node>) (location <number>) (HTL <number>)
    define : step-back? best-peer route
        and (not best-peer) : not (null? route)
    define : cannot-continue? best-peer route
        and (not best-peer) (null? route)
    let loop
        : origin origin
          route : list
          seen : list
          HTL HTL
        ;; format (current-error-port) "origin ~a route ~a seen ~a HTL ~a\n" origin route seen HTL
        let : : best : find-best-peer origin location seen
            cond
              {HTL <= 0}
                reverse : cons origin seen
              : cannot-continue? best route
                reverse : cons origin seen
              : step-back? best route
                loop
                    car route
                    cdr route
                    cons origin seen
                    decrement-htl (car route) origin HTL
              else
                loop
                    . best
                    cons origin route
                    cons origin seen
                    decrement-htl best origin HTL
          

define : decrement-htl node origin HTL
    if {HTL < max-htl}
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


define : swap origin target
    let : : origin-location : node-location origin
        node-set-location! origin : node-location target
        node-set-location! target origin-location

define : node-peer-dists node nodelist
    map : λ (peer) : dist node peer
        . nodelist

define : should-swap-distances? before1 before2 after1 after2
    let
        : D1 : * (apply * before1) (apply * before2)
          D2 : * (apply * after1) (apply * after2)
        ;; format (current-error-port) "before1 ~a before2 ~a after1 ~a after2 ~a\n" before1 before2 after1 after2
        ;; format (current-error-port) "D1 ~a D2 ~a\n" D1 D2
        or
            . {D2 <= D1}
            . {{D1 / D2} > (random:uniform)} ;; probability D1/D2

define : replace-in-list li from to
    map : λ(x) : if (equal? x from) to x
        . li

define-method : should-swap-locations? origin origin-peer-locs target target-peer-locs
    let
        : origin-dists : node-peer-dists origin origin-peer-locs
          target-dists : node-peer-dists target target-peer-locs
          origin-swap-dists : node-peer-dists target : replace-in-list origin-peer-locs target origin
          target-swap-dists : node-peer-dists origin : replace-in-list target-peer-locs origin target
        ;; format (current-error-port) "origin ~a origin-peer-locs ~a target ~a target-peer-locs ~a\n" origin origin-peer-locs target target-peer-locs
        should-swap-distances?
            . origin-dists target-dists
            . origin-swap-dists target-swap-dists

define : should-swap? origin target
    should-swap-locations?
        node-location origin
        map node-location : node-peers origin
        node-location target
        map node-location : node-peers target


define : swap-target-uniform origin
    closest-node origin : random:uniform

define : random-node nodes
    list-ref nodes : inexact->exact : truncate : * (random:uniform) : length nodes

define : swap-target-concave origin
    . "target selection following the thesis from Vilhelm Verendel, 2007"
    define peers : node-peers origin
    define random-peer-location
        if : null? peers
            random:uniform
            node-location
                random-node peers
    define peer-distance : dist origin random-peer-location
    closest-node origin
        mod
            + random-peer-location
                * peer-distance
                    random:normal
            . 1.

define : swap-request origin target
    define path : reverse! : route-for-swap origin target max-htl
    define closest : first path
    define : did-swap? last
        not : equal? last closest
    let loop : (last closest) (path (cdr path))
        cond
          : null? path
            did-swap? last
          : should-swap? last (first path)
            ;; format (current-error-port) "swapping ~a and ~a\n" last (first path)
            swap last (first path)
            loop (first path) (cdr path)
          else
            loop last (cdr path)

define : swap-single-try origin target
    when : should-swap? origin target
        swap origin target

define : swap-all-once nodes target-selection
    let loop
        : to-swap nodes
          target : target-selection : car nodes
        when : not : null? to-swap
           swap-request target : car to-swap
           ;; swap-single-try target : car to-swap
           loop
               cdr to-swap
               target-selection : car to-swap
               
define pitch-black-target-location : random:uniform
define : swap-steps nodes steps target-selection pitch-black-per-step
    let 
        : pitch-black-location pitch-black-target-location
          attacker : random-node nodes
        format (current-error-port) "swapping ~a steps\n" steps
        do-ec (: i steps)
            begin
                swap-all-once nodes target-selection
                display "." : current-error-port
                when {pitch-black-per-step > 0}
                    display pitch-black-per-step : current-error-port
                force-output : current-error-port
                do-ec (: j pitch-black-per-step)
                    begin
                        pitch-black-attack attacker pitch-black-location
        format (current-error-port) "finished swapping ~a steps\n" steps
        . nodes


define : get-option args name default
    let : : index : list-index (λ(x) (equal? x name)) args
        if : not index 
           . default
           let : : option : list-ref args {index + 1}
               if : number? default
                    string->number option
                    . option

define : get-argument args name
    member name args

define : choose-network args
         let : : name : get-option args "--network" "random"
           cond
               : equal? name "random"
                 . random-network
               : equal? name "neighbor"
                 . neighbor-network
               : equal? name "smallworld"
                 . smallworld-network

define : choose-swap-target-selection args
         let : : name : get-option args "--swap-target-selection" "uniform"
           cond
               : equal? name "uniform"
                 . swap-target-uniform
               : equal? name "concave"
                 . swap-target-concave




define : output-peer-distances nodes
    let
       :
         distances
            fold
                λ (node previous)
                    append
                        map (λ (peer) (dist peer (node-location node)))
                            node-peers node
                        . previous
                . '()
                . nodes
       map : λ (x) (display x) (newline)
             sort distances <

define : output-node-locations nodes
    let : : locations : map node-location nodes
       map : λ (x) (display x) (newline)
             sort locations <


define : output-path-lengths nodes
    map : λ (x) (display x) (newline)
        sort
            map
                λ (node) : length : route-simple-greedy node (random:uniform) max-htl
                . nodes
            . <

define : output-path-lengths-fixed-target nodes
    let : : loc : random:uniform
        map : λ (x) (display x) (newline)
            sort
                map
                    λ (node) : length : route-simple-greedy node loc max-htl
                    . nodes
                . <


define : output-routing-accuracy nodes
    map : λ (x) (display x) (newline)
        sort
            map
                λ (node) 
                    let : : loc : random:uniform
                        dist loc : closest-node node loc
                . nodes
            . <

define : output-routing-accuracy-fixed-target nodes
    let : : loc pitch-black-target-location
        map : λ (x) (display x) (newline)
            sort
                map
                    λ (node)
                        let : : closest : closest-node node loc
                            format (current-error-port) "Accuracy: ~a, loc ~a, closest ~a\n"
                               dist closest loc
                               . loc closest
                            dist loc closest
                    . nodes
                . <

define : choose-output-data args
         let : : name : get-option args "--output-data" "peer-distances"
           cond
               : equal? name "peer-distances"
                 . output-peer-distances
               : equal? name "node-locations"
                 . output-node-locations
               : equal? name "path-lengths"
                 . output-path-lengths
               : equal? name "path-lengths-fixed-target"
                 . output-path-lengths-fixed-target
               : equal? name "routing-accuracy"
                 . output-routing-accuracy
               : equal? name "routing-accuracy-fixed-target"
                 . output-routing-accuracy-fixed-target
               else
                   error "unknown option: --output-data ~a" name

define : optimize-steps args
    get-option args "--optimize-steps" 0

define : network-size args
    get-option args "--network-size" 100

define : pitch-black-per-step args
    get-option args "--pitch-black-per-step" 0

define : closest-node origin location
    car
      take-right : route-simple-greedy origin location max-htl
                 . 1

define : pitch-black-attack? origin
    . "If the best found node is worse than to be expected in a random network, assume being under the pitch black attack."
    let*
        : loc : random:uniform
          closest : closest-node origin loc
        ;; format #t "closest: ~a loc: ~a dist: ~a\n" closest loc : dist closest loc
        ;; display 0.0037
        ;; newline
        . {0.0037 < (dist closest loc)}

define : pitch-black-attack origin location-to-attack
    ;; TODO: use multiple attackers, since it soon cannot find a new node
    let* 
        : closest : closest-node origin location-to-attack
          fake-locations
              list-ec (: i (length (node-peers origin)))
                  + : node-location closest
                    * 0.000001
                        random:normal
        ;; format (current-error-port) "attack: ~a\n" location-to-attack
        when : should-swap-locations? origin fake-locations closest : map node-location : node-peers closest
               display "!" : current-error-port
               node-set-location! closest : node-location origin

define : main args
    let*
      : create-network : choose-network args
        locations : create-locations : network-size args
        nodes
            swap-steps
                create-network locations
                optimize-steps args
                choose-swap-target-selection args
                pitch-black-per-step args
        output : choose-output-data args
      output nodes
      ;; display : pitch-black-attack? : car nodes
      ;; newline
      ;; exit 0
      ;; display : car nodes
      ;; newline
      ;; display : sort (node-peers (car nodes)) (λ(a b) (< (dist (node-location a) (node-location (car nodes))) (dist (node-location b)  (node-location (car nodes)))))
      ;; newline
      ;; display "ROUTE: "
      ;; display : route-simple-greedy (car nodes) 0.25 max-htl
      ;; newline
      ;; exit 0

;; plot network: 
;;     for data in peer-distances node-locations path-lengths path-lengths-fixed-target routing-accuracy routing-accuracy-fixed-target; do for selection in concave uniform; do for size in 1000; do for steps in 64; do for i in random neighbor smallworld; do ./network.w --output-data $data --swap-target-selection $selection --network-size $size --optimize-steps $steps --network $i > /tmp/$i & done; time wait; echo -e 'set title "'$data' with size: '$size', steps: '$steps', pitchblack: '$pitchblack', selection: '$selection'"\nset term X\nset logscale y\nset yrange [0.0000001:1]\nplot "/tmp/random" title "random" with lines, "/tmp/smallworld" title "smallworld" with lines, "/tmp/neighbor" title "neighbor" with lines\n' | gnuplot -p; done; done; done; done
;; most interesting metric right now:
;;     for data in routing-accuracy-fixed-target; do for selection in uniform; do for size in 100; do for steps in 1 4 16; do for pitchblack in 1 10; do for i in random neighbor smallworld; do ./network.w --pitch-black-per-step $pitchblack  --output-data $data --swap-target-selection $selection --network-size $size --optimize-steps $steps --network $i > /tmp/$i & done; time wait; echo -e 'set title "'$data' with size: '$size', steps: '$steps', pitchblack: '$pitchblack', selection: '$selection'"\nset term X\nset logscale y\nset yrange [0.0000001:1]\nplot "/tmp/random" title "random" with lines, "/tmp/smallworld" title "smallworld" with lines, "/tmp/neighbor" title "neighbor" with lines\n' | gnuplot -p; done; done; done; done; done
;; peer distances
;;     for data in peer-distances; do for selection in uniform; do for size in 1000; do for steps in 0 16; do for pitchblack in 0; do for i in random neighbor smallworld; do ./network.w --pitch-black-per-step $pitchblack  --output-data $data --swap-target-selection $selection --network-size $size --optimize-steps $steps --network $i > /tmp/$i & done; time wait; echo -e 'set title "'$data' with size: '$size', steps: '$steps', pitchblack: '$pitchblack', selection: '$selection'"\nset term X\nset logscale y\nset yrange [0.0000001:1]\nplot "/tmp/random" title "random" with lines, "/tmp/smallworld" title "smallworld" with lines, "/tmp/neighbor" title "neighbor" with lines\n' | gnuplot -p; done; done; done; done; done

;;    for data in peer-distances; do for selection in uniform; do for size in 300; do for steps in 1; do for pitchblack in 0 10 100; do for i in random neighbor smallworld; do ./network.w --pitch-black-per-step $pitchblack  --output-data $data --swap-target-selection $selection --network-size $size --optimize-steps $steps --network $i > /tmp/$i & done; time wait; echo -e 'set title "'$data' with size: '$size', steps: '$steps', pitchblack: '$pitchblack', selection: '$selection'"\nset term X\nset logscale y\nset yrange [0.0000001:1]\nplot "/tmp/random" title "random" with lines, "/tmp/smallworld" title "smallworld" with lines, "/tmp/neighbor" title "neighbor" with lines\n' | gnuplot -p; done; done; done; done; done  
