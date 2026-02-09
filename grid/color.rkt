#lang racket

(provide color
         with-opacity)

;; Color helpers

(define (color r g b [a 1.0])
  (vector r g b a))

(define (with-opacity color-vec opacity)
  (vector (vector-ref color-vec 0)
          (vector-ref color-vec 1)
          (vector-ref color-vec 2)
          opacity))