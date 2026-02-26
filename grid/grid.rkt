#lang racket

(require "dictionary.rkt")

(provide init!
         set-cell!
         get-cell
         get
         delete-cell!
         get-all-cells
         get-any-cell
         set-grid!
         get-grid
         delete-grid!
         delete-all!
         clear!
         bounds
         collides?
         collides-at?
         move-cells!
         move-by!
         move-to!
         all-coordinates)

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

;; Get all cells with a given key, returns list of (x y value)

(define (get-all-cells key)
  (filter-map (lambda (coord)
                (let* ([x (first coord)]
                       [y (second coord)]
                       [cell (get-cell x y)])
                  (if (hash-has-key? cell key)
                      (list x y (hash-ref cell key))
                      #f)))
              (all-coordinates)))

;; Get any one cell with a given key, returns (x y value) or #f

(define (get-any-cell key)
  (let ([result (findf (lambda (coord)
                         (hash-has-key? (get-cell (first coord) (second coord)) key))
                       (all-coordinates))])
    (and result
         (list (first result)
               (second result)
               (get-cell (first result) (second result) key)))))

;; Movement & collision

(define (move-by! coords dx dy)
  (define moves
    (for/list ([coord (in-set coords)])
      (list (first coord) (second coord) (hash-copy (get-cell (first coord) (second coord))))))
  (for ([move moves])
    (for ([key (hash-keys (third move))])
      (delete-cell! (first move) (second move) key)))
  (for ([move moves])
    (for ([(key val) (in-hash (third move))])
      (cell-set! (+ (first move) dx) (+ (second move) dy) key val))))

(define (move-to! coords tx ty)
  (define moves
    (for/list ([coord (in-set coords)])
      (list (first coord) (second coord) (hash-copy (get-cell (first coord) (second coord))))))
  (for ([move moves])
    (for ([key (hash-keys (third move))])
      (delete-cell! (first move) (second move) key)))
  (for ([move moves])
    (for ([(key val) (in-hash (third move))])
      (cell-set! tx ty key val))))

(define (move-cells! key dx dy)
  (define cells-to-move (get-all-cells key))
  (for ([cell cells-to-move])
    (match-define (list x y _data) cell)
    (delete-cell! x y key))
  (for ([cell cells-to-move])
    (match-define (list x y data) cell)
    (cell-set! (+ x dx) (+ y dy) key data)))

(define (bounds key)
  (define cells (get-all-cells key))
  (if (empty? cells)
      #f
      (let ([xs (map first cells)]
            [ys (map second cells)])
        (list (apply min xs) (apply max xs)
              (apply min ys) (apply max ys)))))

(define (get-coords key)
  (map (lambda (cell) (list (first cell) (second cell)))
       (get-all-cells key)))

(define (collides? key1 key2)
  (define coords1 (list->set (get-coords key1)))
  (define coords2 (list->set (get-coords key2)))
  (not (set-empty? (set-intersect coords1 coords2))))

(define (collides-at? key dx dy other-key)
  (define moved-coords (list->set
                        (map (lambda (cell)
                               (list (+ (first cell) dx)
                                     (+ (second cell) dy)))
                             (get-all-cells key))))
  (define other-coords (list->set (get-coords other-key)))
  (not (set-empty? (set-intersect moved-coords other-coords))))

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

(define (delete-all! key)
  (for ([coord (all-coordinates)])
    (delete-cell! (first coord) (second coord) key)))

(define clear!
  (case-lambda
    [()
     (hash-set! grid 'cells (make-hash))
     (hash-set! grid 'data (make-hash))]
    [(keys)
     (for ([k keys])
       (delete-all! k))]))
