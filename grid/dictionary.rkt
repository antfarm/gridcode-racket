#lang racket

(provide dictionary
         dictionary?
         dictionary-ref)

(struct dictionary-data (hash)
  #:methods gen:custom-write
  [(define (write-proc r port mode)
     (fprintf port "(dictionary")
     (for ([(k v) (in-hash (dictionary-data-hash r))])
       (fprintf port " [~a ~a]" k v))
     (fprintf port ")"))])

(define dictionary? dictionary-data?)

(define (dictionary . key-val-pairs)
  (dictionary-data (apply hash key-val-pairs)))

(define (dictionary-ref r key [default #f])
  (hash-ref (dictionary-data-hash r) key default))
