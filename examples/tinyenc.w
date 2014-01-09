#!/home/arne/wisp/wisp-multiline.sh -l guile
; !#

define-module : examples tinyenc
   . #:export : encrypt decrypt
;   . #:use-syntax : ice-9 syncase
; `use-syntax' is deprecated. For compatibility with old and new guile I therefore need this.
; Syntax-case macros are now a part of Guile core; importing (ice-9 syncase) is no longer necessary.
use-syntax : ice-9 syncase

; http://en.wikipedia.org/wiki/Tiny_Encryption_Algorithm#toctitle

define delta #x9e3779b9
define uint32-limit #x100000000 ; 2**32
define uint32-max #xFFFFFFFF ; 2**32 - 1

define : uint32 number
  . "ensure that the number fits a uint32"
  ; instead of modulo, use bitwise and: simply throws out the higher bits
  logand number uint32-max

define : v0change k0 v1 sum k1
           logxor
             + k0 : ash v1 4
             + v1 sum
             + k1 : uint32 : ash v1 -5

define : v1change k2 v0 sum k3
           logxor
             + k2 : ash v0 4
             + v0 sum
             + k3 : uint32 : ash v0 -5

; Define a macro with-split-kv which executes its body with let bindings to k0 k1 k2 k3 v0 and v1
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
          #' let
            : v0 : uint32 : ash v -32
              v1 : uint32 v
              k0 : uint32 : ash k -96
              k1 : uint32 : ash k -64
              k2 : uint32 : ash k -32
              k3 : uint32 k
            . exp exp* ...


define : encrypt v k
  . "Encrypt the 64bit (8 byte, big endian) value V with the 128bit key K (16 byte)."
  with-split-vk v k
    let loop 
      : sum delta
        cycle 0
        v0 v0
        v1 v1
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
  with-split-vk v k
    let loop
      : sum #xc6ef3720
        cycle 0
        v0 v0
        v1 v1
      if : = cycle 32
         + v1 : * v0 : integer-expt 2 32
         ; (x-y) mod N is the same as (x mod N) - (y mod N)
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
