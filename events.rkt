#lang racket

(provide on emit)

(define event-handlers (make-hash))

(define (on event handler)
  (hash-set! event-handlers event
             (cons handler (hash-ref event-handlers event '()))))

(define (emit event . args)
  (for ([handler (hash-ref event-handlers event '())])
    (apply handler args)))