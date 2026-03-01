#lang racket

(require "dictionary.rkt")

(provide init!
         set-cell!
         get-cell
         get
         delete-cell!
         set-grid!
         get-grid
         delete-grid!
         clear!
         clear-cells!
         clear-grid!
         copy-to!
         copy-by!
         move-by!
         move-to!
         all-coordinates
         exists-at?
         bounds-of)

;; Internal grid state

(define grid (make-hash))

(define (init! size)
  (set! grid (make-hash))
  (hash-set! grid 'cells (make-hash))
  (hash-set! grid 'data (make-hash))
  (hash-set! grid 'size size)
  (hash-set! grid 'coordinates
             (for*/list ([x (in-range size)]
                         [y (in-range size)])
               (list x y))))

;; Cell data

(define set-cell!
  (case-lambda
    [(x y key)
     (cell-set! x y key #t)]
    [(x y key value)
     (cell-set! x y key value)]
    [(x y key property value)
     (let* ([cells (hash-ref grid 'cells)]
            [cell  (hash-ref cells (list x y) (make-hash))]
            [dict  (hash-ref cell key #f)]
            [new-dict (if (dictionary? dict)
                          (dictionary-set dict property value)
                          (dictionary property value))])
       (hash-set! cell key new-dict)
       (hash-set! cells (list x y) cell))]))

(define (cell-set! x y key value)
  (let* ([cells (hash-ref grid 'cells)]
         [cell  (hash-ref cells (list x y) (make-hash))])
    (hash-set! cell key value)
    (hash-set! cells (list x y) cell)))

(define get-cell
  (case-lambda
    [(x y)
     (hash-ref (hash-ref grid 'cells) (list x y) (make-hash))]
    [(x y key)
     (let ([cell (hash-ref (hash-ref grid 'cells) (list x y) (make-hash))])
       (hash-ref cell key #f))]))

(define (get dict property)
  (if (dictionary? dict)
      (dictionary-ref dict property)
      #f))

(define delete-cell!
  (case-lambda
    [(x y key)
     (let* ([cells (hash-ref grid 'cells)]
            [cell  (hash-ref cells (list x y) #f)])
       (when cell
         (hash-remove! cell key)))]
    [(x y key property)
     (let* ([cells (hash-ref grid 'cells)]
            [cell  (hash-ref cells (list x y) #f)])
       (when cell
         (let ([dict (hash-ref cell key #f)])
           (when (dictionary? dict)
             (hash-set! cell key (dictionary-remove dict property))))))]))

;; Movement

(define (snapshot-coords key coords)
  (for/list ([coord (in-set coords)])
    (list (first coord) (second coord) (get-cell (first coord) (second coord) key))))

(define (copy-by! coords key dx dy)
  (define snaps (snapshot-coords key coords))
  (for ([s snaps])
    (cell-set! (+ (first s) dx) (+ (second s) dy) key (third s))))

(define (copy-to! coords key tx ty)
  (define snaps (snapshot-coords key coords))
  (for ([s snaps])
    (cell-set! tx ty key (third s))))

(define (move-by! coords key dx dy)
  (define snaps (snapshot-coords key coords))
  (for ([s snaps])
    (delete-cell! (first s) (second s) key))
  (for ([s snaps])
    (cell-set! (+ (first s) dx) (+ (second s) dy) key (third s))))

(define (move-to! coords key tx ty)
  (define snaps (snapshot-coords key coords))
  (for ([s snaps])
    (delete-cell! (first s) (second s) key))
  (for ([s snaps])
    (cell-set! tx ty key (third s))))

(define (exists-at? coords x y)
  (set-member? coords (list x y)))

(define (bounds-of coords)
  (if (set-empty? coords)
      #f
      (let* ([coord-list (set->list coords)]
             [xs (map first coord-list)]
             [ys (map second coord-list)])
        (list (apply min xs) (apply max xs)
              (apply min ys) (apply max ys)))))

;; Grid (global) data

(define (set-grid! key value)
  (hash-set! (hash-ref grid 'data) key value))

(define (get-grid key)
  (hash-ref (hash-ref grid 'data) key #f))

(define (delete-grid! key)
  (hash-remove! (hash-ref grid 'data) key))

;; Grid-wide operations

(define (all-coordinates)
  (hash-ref grid 'coordinates))

(define (normalize-keys key-or-keys)
  (if (list? key-or-keys) key-or-keys (list key-or-keys)))

(define clear-cells!
  (case-lambda
    [()
     (hash-set! grid 'cells (make-hash))]
    [(key-or-keys)
     (for ([k (normalize-keys key-or-keys)])
       (for ([coord (all-coordinates)])
         (delete-cell! (first coord) (second coord) k)))]))

(define (clear-grid!)
  (hash-set! grid 'data (make-hash)))

(define (clear!)
  (clear-cells!)
  (clear-grid!))
