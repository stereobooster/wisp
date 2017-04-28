define-module : example unbiased-std
              . #:export : std

define factors⁻¹
  ' ;; from https://en.wikipedia.org/wiki/Unbiased_estimation_of_standard_deviation#Results_for_the_normal_distribution
    2  . 0.7978845608
    3  . 0.8862269255
    4  . 0.9213177319
    5  . 0.9399856030
    6  . 0.9515328619
    7  . 0.9593687891
    8  . 0.9650304561
    9  . 0.9693106998
    10 . 0.9726592741

define : std . vals
  . "Calculate the unbiased standard deviation of the values (the biased std for more than 10 values)."
  let : : len : length vals
     if : < len 2
        . +inf.0
        let
          : mean (/ (apply + vals) len)
            factor (or (assoc-ref factors⁻¹ len) 1)
          * (/ 1 factor) : sqrt : * (/ 1 (- len 1)) : apply + : map (λ(x) (expt (- x mean) 2)) vals .

;; quick test
let : : res : std 0 0 3
  when : not : > 0.01 : abs : - res : * 1.129 : sqrt 3 ;; calculated by hand
         format #t "Bug: (std 0 0 3) gives ~a instead of 1.995\n" res

