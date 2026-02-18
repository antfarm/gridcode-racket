#lang racket

(provide init!
         set-cell!
         get-cell
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
         move-cells!)

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

(define (set-cell! x y key [value #t])
  (let* ([cells (hash-ref grid 'cells)]
         [cell (hash-ref cells (list x y) (make-hash))])
    (hash-set! cell key value)
    (hash-set! cells (list x y) cell)))

(define get-cell
  (case-lambda
    [(x y)
     (let ([cells (hash-ref grid 'cells)])
       (hash-ref cells (list x y) (make-hash)))]
    [(x y key)
     (let* ([cells (hash-ref grid 'cells)]
            [cell (hash-ref cells (list x y) (make-hash))])
       (hash-ref cell key #f))]
    [(x y key default)
     (let* ([cells (hash-ref grid 'cells)]
            [cell (hash-ref cells (list x y) (make-hash))])
       (hash-ref cell key default))]))

(define (delete-cell! x y key)
  (let* ([cells (hash-ref grid 'cells)]
         [cell (hash-ref cells (list x y) #f)])
    (when cell
      (hash-remove! cell key))))

;; Get all cells with a given key, returns list of (x y data)
(define (get-all-cells key)
  (filter-map (lambda (coord)
                (let* ([x (first coord)]
                       [y (second coord)]
                       [cell (get-cell x y)])
                  (if (hash-has-key? cell key)
                      (list x y (hash-ref cell key))
                      #f)))
              (all-coordinates)))

;; Get any one cell with a given key, returns (x y data) or #f
(define (get-any-cell key)
  (let ([result (findf (lambda (coord)
                         (hash-has-key? (get-cell (first coord) (second coord)) key))
                       (all-coordinates))])
    (and result
         (list (first result)
               (second result)
               (get-cell (first result) (second result) key)))))

(define (move-cells! key dx dy)
  (define cells-to-move (get-all-cells key))
  (for ([cell cells-to-move])
    (match-define (list x y _data) cell)
    (delete-cell! x y key))
  (for ([cell cells-to-move])
    (match-define (list x y data) cell)
    (set-cell! (+ x dx) (+ y dy) key data)))

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
  (let ([data (hash-ref grid 'data)])
    (hash-set! data key value)))

(define (get-grid key [default #f])
  (let ([data (hash-ref grid 'data)])
    (hash-ref data key default)))

(define (delete-grid! key)
  (let ([data (hash-ref grid 'data)])
    (hash-remove! data key)))

;; Global operations

(define (all-coordinates)
  (hash-ref grid 'coordinates))

(define (delete-all! key)
  (for ([coord (all-coordinates)])
    (let ([x (first coord)]
          [y (second coord)])
      (delete-cell! x y key))))

(define clear!
  (case-lambda
    [()
     (hash-set! grid 'cells (make-hash))
     (hash-set! grid 'data (make-hash))]
    [(keys)
     (for ([k keys])
       (delete-all! k))]))