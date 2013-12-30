#!/home/arne/wisp/wisp-multiline.sh -l guile
; !#

define-module : examples tinyenc
   . #:export : encrypt decrypt
   . #:use-syntax : ice-9 syncase
; http://en.wikipedia.org/wiki/Tiny_Encryption_Algorithm#toctitle

define delta #x9e3779b9

define : uint32 number
  . "ensure that the number fits a uint32"
  modulo number : integer-expt 2 32

define : v0change k0 v1 sum k1
;         format #t "sum: ~A, + k0 : ash v1 4: ~A, + v1 sum: ~A, + k1 : ash v1 -5: ~A\n"
;           . sum
;           uint32 : + k0 : ash v1 4
;           uint32 : + v1 sum
;           uint32 : + k1 : uint32 : ash v1 -5
         logxor
           uint32 : + k0 : ash v1 4
           uint32 : + v1 sum
           uint32 : + k1 : uint32 : ash v1 -5

define : v1change k2 v0 sum k3
         logxor
           uint32 : + k2 : ash v0 4
           uint32 : + v0 sum
           uint32 : + k3 : uint32 : ash v0 -5

; TODO: Define a macro with-split-kv which executes its body with let bindings to k0 k1 k2 k3 v0 and v1
; http://www.gnu.org/software/guile/manual/html_node/Syntax-Case.html#index-with_002dsyntax
define-syntax with-split-vk
    syntax-rules :
      : with-split-vk v k exp exp* ...
          let ; TODO: This defines syntmp-v0-# instead of v0. TODO: report bug: this breaks hygiene: (define-syntax with-car-a-cdr-b (syntax-rules () ((_ some-list exp exp* ...) (let ((a (car some-list))(b (cdr some-list))) exp exp* ...)))) (with-car-a-cdr-b (list "1" "2" "3") (display syntmp-a-235)) - adjust syntmp-a-# as needed. To avoid: walk the code to ensure that no used variables are bound.
            : v0 : uint32 : ash v -32
              v1 : uint32 v
              k0 : uint32 : ash k -96
              k1 : uint32 : ash k -64
              k2 : uint32 : ash k -32
              k3 : uint32 k
            . exp exp* ...


; TODO: Define a macro with-split-kv which executes its body with let bindings to k0 k1 k2 k3 v0 and v1
; Use syntax-case to be able to break hygiene.
; http://www.gnu.org/software/guile/manual/html_node/Syntax-Case.html#index-with_002dsyntax
define-syntax with-split-vk
  lambda : x
    syntax-case x :
      : with-split-vk v k exp exp* ...
        with-syntax
          : k0 : datum->syntax x 'k0
            k1 : datum->syntax x 'k1
            k2 : datum->syntax x 'k2
            k3 : datum->syntax x 'k3
            v0 : datum->syntax x 'v0
            v1 : datum->syntax x 'v1
          let
            : v0 : uint32 : ash v -32
              v1 : uint32 v
              k0 : uint32 : ash k -96
              k1 : uint32 : ash k -64
              k2 : uint32 : ash k -32
              k3 : uint32 k
            . exp exp* ...


define : encrypt v k
  . "Encrypt the 64bit (8 byte, big endian) value V with the 128bit key K (16 byte)."
;   with-split-vk v k
  let
    : k0 : uint32 : ash k -96
      k1 : uint32 : ash k -64
      k2 : uint32 : ash k -32
      k3 : uint32 k
      v0 : uint32 : ash v -32
      v1 : uint32 v
    let loop 
      : sum delta
        cycle 0
        v0 v0
        v1 v1
;      format #t "v0: ~A, v1: ~A\n" v0 v1
 ;     if (= cycle 32) : format #t "k0: ~A, k1: ~A, k2: ~A, k3: ~A\n" k0 k1 k2 k3
      if : = cycle 32
         + v1 : * v0 : integer-expt 2 32
         let : : v0tmp : uint32 : + v0 : v0change k0 v1 sum k1
           loop
             uint32 : + sum delta
             + cycle 1
             . v0tmp
             uint32 : + v1 : v1change k2 v0tmp sum k3

define : decrypt v k
  . "Decrypt the 64bit (8 byte, big endian) value V with the 128bit key K (16 byte)."
  let
    : k0 : uint32 : ash k -96
      k1 : uint32 : ash k -64
      k2 : uint32 : ash k -32
      k3 : uint32 k
      v0 : uint32 : ash v -32
      v1 : uint32 v
    let loop
      : sum #xc6ef3720
        cycle 0
        v0 v0
        v1 v1
      if : = cycle 32
         + v1 : * v0 : integer-expt 2 32
         let : : v1tmp : uint32 : - v1 : v1change k2 v0 sum k3
           loop
             uint32 : - sum delta
             + cycle 1
             uint32 : - v0 : v0change k0 v1tmp sum k1
             . v1tmp


format #t "decrypted: ~A\n" 
    decrypt
        encrypt 
          . 5
          . 9
        . 9
format #t "encrypted: ~A\n" 
        encrypt 
          . 5
          . 9
