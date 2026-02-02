#lang racket

(require "grid/main.rkt"
         "runtime.rkt"
         "ui.rkt")

(provide run)

(define (run prog)
  (init! (hash-ref prog 'grid-size))
  ((hash-ref prog 'setup-grid))

  (define ui (create-ui prog))
  (define runtime (create-runtime prog))

  (hash 'ui ui
        'runtime runtime))