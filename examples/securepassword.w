#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples securepassword) main)' -s "$0" "$@"
; !#

;; Create secure passwords, usable on US and German keyboards without problems

;; As of 2011, a single device can do 2,800,000,000 guesses per
;; second.  Today this should be 10 billion guesses per second.
;; According to a recovery company which sells crackers at 1.5k$, as
;; of 2016 a zip-file can be attacked with 100,000 guesses per
;; second. Ars Technica reports 8 billion attacks on md5 on a single
;; device in 2013[1].

;; Codinghorror quotes[2] codohale[3] on the cost of buying 5 billion
;; cracked md5 hashes per second in 2010 for just 3$ per hour. This
;; should be around 20 billion guesses per second today.

;; [1]: http://arstechnica.com/security/2013/05/how-crackers-make-minced-meat-out-of-your-passwords/
;; [2]: https://blog.codinghorror.com/speed-hashing/
;; [3]: http://codahale.com/how-to-safely-store-a-password/ 

;; A password with 8 letters and 2 delimiters (length 8, entropy 50)
;; would on average withstand the strong attack with a single device
;; for 2.5 days. It would take around one day to crack with 20 billion
;; guesses per second, so you could buy a cracked md5-secured 8 letter
;; + 2 delimiter password for 72$ (assuming that it was salted,
;; otherwise you can buy all these md5’ed passwords for around 144$).

;; The 8 letter and 2 delimiter password would withstand the weak
;; attack until 2032 (when it would be cracked in one year), assuming
;; doubling of processing power every two years. Cracking it in one
;; day would be possible in 2049.

;; A password with 12 letters and 3 delimiters (length 12, entropy 75)
;; should withstand the strong attack until 2069 (then it would be
;; cracked in one year), assuming doubling of processing power every
;; two years, the weak until 2099.

;; For every factor of 1000 (i.e. 1024 computers), the time to get a
;; solution is reduced by 20 years.  Using every existing cell phone,
;; the 12 letter key would be cracked by the method with 100,000
;; guesses per second in 2039 (within one year). Facebook could do
;; that with Javascript, so you might want to use a longer password if
;; your data has to be secure for longer than 22 years.

;; Using Landauer’s principle[4], we can estimate the minimum energy
;; needed to to check a password solution with a computer at room
;; temperature, assuming that reversible entropy computing isn’t
;; realized and quantum computers have to stick to Landauer’s limit: A
;; single bit-flip requires approximately 3 Zeptojoule[5] at room
;; temperature, so we can flip 333 e18 bits per second with one Watt
;; of Energy. Processing any information requires at least one
;; bit-flip. Reducing the temperature to 1.e-7K (reachable with
;; evaporative cooling) would theoretically allow increasing the bit
;; flips per Joule to 1e30. That gives a plausible maximum of password
;; checks per expended energy. Assuming that someone would dedicate a
;; large nuclear powerplant with 1 Gigawatt of output to cracking your
;; password, a 160 bit password would withstand the attack for about
;; 23 years.

;; [4]: https://en.wikipedia.org/wiki/Landauer's_principle
;; [5]: http://advances.sciencemag.org/content/2/3/e1501492 "DOI: 10.1126/sciadv.1501492"

;; With the password scheme described here, a password with 28 letters
;; and 6 delimiters (172 bits of entropy) should be secure for almost
;; 100,000 years in the Landauer limit at 1.e-7K, with the energy of a
;; large nuclear power plant devoted to cracking it.

;; With 24 letters and 5 delimiters it would only last about a month,
;; though. Mind exponentials and the linear limit of the human
;; lifespan :)

;; However using the total energy of the sun (about 0.5e21 W), a 28
;; letter, 6 delimiter password would survive for just about 5
;; seconds. To reach 50 years of password survival against an attacker
;; harnessing the energy of the sun (a type II civilization on the
;; Kardashev scale[6] devoting its whole civilization to cracking your
;; password), you’d need 200 bits of entropy. A 36 letter, 8 delimiter
;; password (221 bits of entropy) would last about 100 billion
;; years. With that it would very likely outlast that civilization
;; (and maybe even its star).

;; [6]: https://en.wikipedia.org/wiki/Kardashev_scale

;; An example of a 28 letter, 6 delimiter password would be:
;; GV7r!dcbm!venf,nGoH-MDjX,vBT8.1vWF
;; Don’t use this one, though :)

;; If you ever wanted to anger a type II civilization, encrypt their
;; vital information with a 36 letter, 8 delimiter password like this:
;; CB6d,D7fX-5sLV!mgCp,kTvG-He6n-7Fg9.REX3-r9F5
;; Keep in mind, though, that they might have other means to get it
;; than brute force. And when they come for you, they will all be
;; *really angry* :)
;; Or they might just have developed reversible computing, then all
;; these computations are just a fun game to stretch the mind :)


define-module : examples securepassword
              . #:export : password yearstillcrackable

import
    only (srfi srfi-27) random-source-make-integers
      . make-random-source random-source-randomize!
    only (srfi srfi-1) second third iota
    srfi srfi-42
    ice-9 optargs


define : years-to-crack-landau-limit-evaporative-cooling-nuclear-powerplant entropy
       . "Estimate of the years needed to crack the password in the landauer limit"
       let*
        : seconds/day : * 60 60 24
          days/year 365.25
          tempK 1e-7
          room-temp-fraction {tempK / 300}
          guesses/Joule {1 / {3e-21 * room-temp-fraction}}
          Gigawatt 1e9
          guesses/second : * Gigawatt guesses/Joule
          seconds/day : * 60 60 24
          days/year 365.25
          guesses/year : * guesses/second seconds/day days/year
        / (expt 2 entropy) guesses/year 2


define* : yearstillcrackable entropy #:key (guesses/second 100000) (number-of-devices 1)
       . "Estimate of the years it will take until the password is crackable"
       let 
        : seconds/day : * 60 60 24
          days/year 365.25
        ` 
             in-one-second
               , * 2
                  / 
                    log : / (expt 2 entropy) (* guesses/second number-of-devices)
                    log 2
             in-one-day
               , * 2
                  / 
                    log : / (expt 2 entropy) (* seconds/day guesses/second number-of-devices)
                    log 2
             in-one-year 
               , * 2
                  / 
                    log : / (expt 2 entropy) (* days/year seconds/day guesses/second number-of-devices)
                    log 2


;; newbase60 without yz_: 55 letters, 5.78 bits of entropy per letter.
define qwertysafeletters "0123456789ABCDEFGHJKLMNPQRSTUVWXabcdefghijkmnopqrstuvwx"
;; delimiters: 2 bits of entropy per delimiter.
define delimiters ",.!-"

define random-source : make-random-source
random-source-randomize! random-source


define random-integer 
       random-source-make-integers random-source


define : randomletter letters
      string-ref letters
        random-integer
          string-length letters


define : flatten e
    cond 
       : pair? e
         ` 
           ,@ flatten : car e 
           ,@ flatten : cdr e
       : null? e
         list
       else 
         list e


define : password/srfi-42 length
       list->string
         append-ec (: i (iota length 1))
           cons : randomletter qwertysafeletters
             if : and (not (= i length)) : zero? : modulo i 4
                cons : randomletter delimiters
                  list
                list


define : password/map length
       list->string
         flatten
           map
             lambda : i
               let
                 : letter : randomletter qwertysafeletters
                 if : and (not (= i length)) : zero? : modulo i 4
                    list letter 
                      randomletter delimiters
                    list letter
             iota length 1


define : password length
       let fill
         : letters '()
           remaining length
         if : zero? remaining
            reverse-list->string letters
            fill
              cons : randomletter qwertysafeletters
                if : and (not (= length remaining)) : zero? : modulo remaining 4
                   cons : randomletter delimiters
                        . letters
                   . letters
              - remaining 1


define : main args
      let
       :
         len
           if : <= 2 : length args
              string->number : second args
              . 8
       let 
         : idx (if (> 3 (length args)) 1 (string->number (third args)))
         cond
           : = idx 1
             display : password len
           : = idx 2
             display : password/map len
           : = idx 3
             display : password/srfi-42 len
         newline

