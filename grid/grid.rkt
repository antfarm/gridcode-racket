#lang racket

(require "dictionary.rkt")

(provide init!
         set-cell!
         get-cell
         cell-data
         cell-info
         get
         delete-cell!
         delete-cells!
         set-grid!
         get-grid
         grid-info
         delete-grid!
         clear!
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

(define (cell-data x y)
  (hash-ref (hash-ref grid 'cells) (list x y) (make-hash)))

(define get-cell
  (case-lambda
    [(x y key)
     (hash-ref (cell-data x y) key #f)]
    [(x y key property)
     (let ([dict (hash-ref (cell-data x y) key #f)])
       (if (dictionary? dict)
           (dictionary-ref dict property)
           #f))]))

(define (cell-info x y)
  (format "(~a,~a) ~a" x y (cell-data x y)))

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

(define set-grid!
  (case-lambda
    [(key)
     (hash-set! (hash-ref grid 'data) key #t)]
    [(key value)
     (hash-set! (hash-ref grid 'data) key value)]
    [(key property value)
     (let* ([data (hash-ref grid 'data)]
            [dict (hash-ref data key #f)]
            [new-dict (if (dictionary? dict)
                          (dictionary-set dict property value)
                          (dictionary property value))])
       (hash-set! data key new-dict))]))

(define (grid-data)
  (hash-ref grid 'data))

(define get-grid
  (case-lambda
    [(key)
     (hash-ref (grid-data) key #f)]
    [(key property)
     (let ([dict (hash-ref (grid-data) key #f)])
       (if (dictionary? dict)
           (dictionary-ref dict property)
           #f))]))

(define (grid-info)
  (format "~a" (grid-data)))

(define delete-grid!
  (case-lambda
    [(key)
     (hash-remove! (hash-ref grid 'data) key)]
    [(key property)
     (let* ([data (hash-ref grid 'data)]
            [dict (hash-ref data key #f)])
       (when (dictionary? dict)
         (hash-set! data key (dictionary-remove dict property))))]))

;; Grid-wide operations

(define (all-coordinates)
  (hash-ref grid 'coordinates))

(define (delete-cells! coords key)
  (for ([coord (in-set coords)])
    (delete-cell! (first coord) (second coord) key)))

(define (clear!)
  (hash-set! grid 'cells (make-hash))
  (hash-set! grid 'data (make-hash)))

