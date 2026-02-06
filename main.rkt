#lang racket

(require gridcode/runtime 
         gridcode/ui)

(provide run)

(define (run prog)
  (define runtime (create-runtime prog))
  ((hash-ref runtime 'setup))

  (define ui (create-ui prog))

  (hash 'ui ui
        'runtime runtime))