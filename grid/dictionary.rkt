#lang racket

(provide dictionary
         dictionary?
         dictionary-ref
         dictionary-set
         dictionary-remove)

(struct dictionary-data (hash)
  #:methods gen:custom-write
  [(define (write-proc r port _mode)
     (fprintf port "(dictionary")
     (for ([(k v) (in-hash (dictionary-data-hash r))])
       (fprintf port " [~a ~a]" k v))
     (fprintf port ")"))])

(define dictionary? dictionary-data?)

(define (dictionary . key-val-pairs)
  (dictionary-data (apply hash key-val-pairs)))

(define (dictionary-ref r key)
  (hash-ref (dictionary-data-hash r) key #f))

(define (dictionary-set r key value)
  (dictionary-data (hash-set (dictionary-data-hash r) key value)))

(define (dictionary-remove r key)
  (dictionary-data (hash-remove (dictionary-data-hash r) key)))
