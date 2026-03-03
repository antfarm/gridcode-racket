#lang racket

(provide init!
         set-cell!
         get-cell
         cell-data
         cell-info
         delete-cell!
         delete-cells!
         set-grid!
         get-grid
         grid-data
         grid-info
         delete-grid!
         clear!
         copy-to!
         copy-by!
         move-by!
         move-to!
         all-coordinates
         has?
         has-at?
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
;; Storage: cells → (x y) → table → key → value

(define (cell-data x y)
  (hash-ref (hash-ref grid 'cells) (list x y) (make-hash)))

(define (cell-table x y table)
  (hash-ref (cell-data x y) table #f))

(define set-cell!
  (case-lambda
    [(x y table)
     (let* ([cells (hash-ref grid 'cells)]
            [cell  (or (hash-ref cells (list x y) #f)
                       (let ([h (make-hash)])
                         (hash-set! cells (list x y) h)
                         h))])
       (unless (hash-has-key? cell table)
         (hash-set! cell table (make-hash))))]
    [(x y table key value)
     (let* ([cells (hash-ref grid 'cells)]
            [cell  (or (hash-ref cells (list x y) #f)
                       (let ([h (make-hash)])
                         (hash-set! cells (list x y) h)
                         h))]
            [t     (or (hash-ref cell table #f)
                       (let ([h (make-hash)])
                         (hash-set! cell table h)
                         h))])
       (hash-set! t key value))]))

(define (get-cell x y table key)
  (let ([t (cell-table x y table)])
    (if t (hash-ref t key #f) #f)))

(define (cell-info x y)
  (format "(~a,~a) ~a" x y (cell-data x y)))

(define delete-cell!
  (case-lambda
    [(x y table)
     (let ([cell (hash-ref (hash-ref grid 'cells) (list x y) #f)])
       (when cell (hash-remove! cell table)))]
    [(x y table key)
     (let ([t (cell-table x y table)])
       (when t (hash-remove! t key)))]))

;; Movement

(define (snapshot-table table coords)
  (for/list ([coord (in-set coords)])
    (let* ([x (first coord)] [y (second coord)]
           [t (cell-table x y table)])
      (list x y (and t (hash-copy t))))))

(define (write-table! x y table t)
  (when t
    (let* ([cells (hash-ref grid 'cells)]
           [cell  (or (hash-ref cells (list x y) #f)
                      (let ([h (make-hash)])
                        (hash-set! cells (list x y) h)
                        h))])
      (hash-set! cell table t))))

(define (copy-by! coords table dx dy)
  (for ([s (snapshot-table table coords)])
    (write-table! (+ (first s) dx) (+ (second s) dy) table (third s))))

(define (copy-to! coords table tx ty)
  (for ([s (snapshot-table table coords)])
    (write-table! tx ty table (third s))))

(define (move-by! coords table dx dy)
  (define snaps (snapshot-table table coords))
  (for ([s snaps])
    (delete-cell! (first s) (second s) table))
  (for ([s snaps])
    (write-table! (+ (first s) dx) (+ (second s) dy) table (third s))))

(define (move-to! coords table tx ty)
  (define snaps (snapshot-table table coords))
  (for ([s snaps])
    (delete-cell! (first s) (second s) table))
  (for ([s snaps])
    (write-table! tx ty table (third s))))

(define has?
  (case-lambda
    [(x y table)
     (hash-has-key? (cell-data x y) table)]
    [(x y table key)
     (let ([t (cell-table x y table)])
       (and t (hash-has-key? t key) #t))]))

(define (has-at? coords x y)
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
;; Storage: data → table → key → value

(define (grid-data)
  (hash-ref grid 'data))

(define (set-grid! table key value)
  (let* ([data (grid-data)]
         [t    (or (hash-ref data table #f)
                   (let ([h (make-hash)])
                     (hash-set! data table h)
                     h))])
    (hash-set! t key value)))

(define (get-grid table key)
  (let ([t (hash-ref (grid-data) table #f)])
    (if t (hash-ref t key #f) #f)))

(define (grid-info)
  (format "~a" (grid-data)))

(define delete-grid!
  (case-lambda
    [(table)
     (hash-remove! (grid-data) table)]
    [(table key)
     (let ([t (hash-ref (grid-data) table #f)])
       (when t (hash-remove! t key)))]))

;; Grid-wide operations

(define (all-coordinates)
  (hash-ref grid 'coordinates))

(define (delete-cells! coords table)
  (for ([coord (in-set coords)])
    (delete-cell! (first coord) (second coord) table)))

(define (clear!)
  (hash-set! grid 'cells (make-hash))
  (hash-set! grid 'data (make-hash)))
