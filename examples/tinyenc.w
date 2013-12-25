#!/home/arne/wisp/wisp-multiline.sh 
; !#

define-module : examples tinyenc
   . #:export : encrypt decrypt

use-modules : 

; http://en.wikipedia.org/wiki/Tiny_Encryption_Algorithm#toctitle

logxor 1 3

define delta #x9e3779b9

define : encrypt v k
  . "Encrypt the 64bit (8 byte, big endian) value V with the 128bit key K (16 byte)."
  let
    : k0 : ash k -96
      k1 : modulo (ash k -64) : integer-expt 2 32
      k2 : modulo (ash k -32) : integer-expt 2 64
      k3 : modulo k : integer-expt 2 96
    let loop 
      : sum delta
        cycle 0
        v0 : ash v -32
        v1 : modulo v : integer-expt 2 32
      if : > cycle 31
         + v1 : * v0 : integer-expt 2 32
         let 
           :
             v0tmp 
               + v0 
                 logxor
                   + k0 : ash v1 -4
                   + v1 sum
                   + k1 : ash v1 5
         loop
           + sum delta
           + cycle 1
           . v0tmp
           + v1
             logxor
               + k2 : ash v0tmp -4
               + v0tmp sum
               + k3 : ash v0tmp 5


display : encrypt : + : integer-expt 2 33
