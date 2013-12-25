#!/home/arne/wisp/wisp-multiline.sh -l guile
; !#

define-module : examples tinyenc
   . #:export : encrypt decrypt

; http://en.wikipedia.org/wiki/Tiny_Encryption_Algorithm#toctitle

logxor 1 3

define delta #x9e3779b9

define : uint32 number
  . "ensure that the number fits a uint32"
  modulo number : integer-expt 2 32

define : encrypt v k
  . "Encrypt the 64bit (8 byte, big endian) value V with the 128bit key K (16 byte)."
  let*
    : k0 : ash k -96
      k1 : uint32 : ash k -64
      k2 : uint32 : ash k -32
      k3 : uint32 k
    let loop 
      : sum delta
        cycle 0
        v0 : ash v -32
        v1 : uint32 v
      if : = cycle 32
         + v1 : * v0 : integer-expt 2 32
         let 
           :
             v0tmp 
              uint32
               + v0
                 logxor
                   + k0 : ash v1 -4
                   + v1 sum
                   + k1 : ash v1 5
           loop
             uint32 : + sum delta
             + cycle 1
             . v0tmp
             uint32
              + v1
               logxor
                 + k2 : ash v0tmp -4
                 + v0tmp sum
                 + k3 : ash v0tmp 5

define : decrypt v k
  . "Decrypt the 64bit (8 byte, big endian) value V with the 128bit key K (16 byte)."
  let*
    : k0 : ash k -96
      k1 : uint32 : ash k -64
      k2 : uint32 : ash k -32
      k3 : uint32 k
    let loop
      : sum #xc6ef3720
        cycle 0
        v0 : ash v -32
        v1 : uint32 v
      if : = cycle 32
         + v1 : * v0 : integer-expt 2 32
         let 
           :
             v1tmp 
              uint32
               - v1 
                 logxor
                   + k2 : ash v0 -4
                   + v0 sum
                   + k3 : ash v0 5
           loop
             uint32 : + sum delta
             + cycle 1
             uint32
              - v0
               logxor
                 + k0 : ash v1tmp -4
                 + v1tmp sum
                 + k1 : ash v1tmp 5
             . v1tmp


display 
    decrypt
        encrypt 
          . 5
          + 7 : integer-expt 2 96 
        + 7 : integer-expt 2 96 
newline
display
        encrypt 
          . 5
          + 7 : integer-expt 2 96 
newline
