#lang racket

(require "index.rkt")

(provide init!
         set-value!
         get-value
         cell-data
         cell-info
         delete-table!
         delete-key!
         delete-cells!
         grid-data
         grid-info
         clear!
         copy-to!
         copy-by!
         move-by!
         move-to!
         all-coordinates
         has-table?
         has-key?
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
               (list x y)))
  (index-clear!))

;; Cell data
;; Storage: cells → (x y) → table → key → value

(define (cell-data x y)
  (hash-ref (hash-ref grid 'cells) (list x y) (make-hash)))

(define (cell-table x y table)
  (hash-ref (cell-data x y) table #f))

(define set-value!
  (case-lambda
    [(a b c)
     (if (number? a)
         ;; cell flag form: (set-value! x y table)
         (let* ([cells (hash-ref grid 'cells)]
                [cell  (or (hash-ref cells (list a b) #f)
                           (let ([new-cell (make-hash)])
                             (hash-set! cells (list a b) new-cell)
                             new-cell))])
           (unless (hash-has-key? cell c)
             (hash-set! cell c (make-hash))
             (index-set-cell! a b c)))
         ;; global form: (set-value! table key value)
         (let* ([data (grid-data)]
                [t    (or (hash-ref data a #f)
                          (let ([h (make-hash)])
                            (hash-set! data a h)
                            h))])
           (hash-set! t b c)))]
    [(x y table key value)
     ;; cell data form: (set-value! x y table key value)
     (let* ([cells (hash-ref grid 'cells)]
            [cell  (or (hash-ref cells (list x y) #f)
                       (let ([new-cell (make-hash)])
                         (hash-set! cells (list x y) new-cell)
                         new-cell))]
            [t     (or (hash-ref cell table #f)
                       (let ([new-table (make-hash)])
                         (hash-set! cell table new-table)
                         new-table))]
            [old-value (hash-ref t key #f)])
       (index-set-cell! x y table key old-value value)
       (hash-set! t key value))]))

(define get-value
  (case-lambda
    [(table key)
     ;; global form: (get-value table key)
     (let ([t (hash-ref (grid-data) table #f)])
       (if t (hash-ref t key #f) #f))]
    [(x y table key)
     ;; cell form: (get-value x y table key)
     (let ([t (cell-table x y table)])
       (if t (hash-ref t key #f) #f))]))

(define (cell-info x y)
  (define data (cell-data x y))
  (define sorted-tables (sort (hash-keys data) symbol<?))
  (string-join
   (cons (format "(~a,~a)" x y)
         (for*/list ([table sorted-tables]
                     [line  (let ([keys (sort (hash-keys (hash-ref data table)) symbol<?)])
                              (if (null? keys)
                                  (list (format " ~a" table))
                                  (for/list ([key keys])
                                    (format " ~a.~a: ~a" table key (hash-ref (hash-ref data table) key)))))])
           line))
   "\n"))

(define delete-table!
  (case-lambda
    [(table)
     ;; global form: (delete-table! table)
     (hash-remove! (grid-data) table)]
    [(x y table)
     ;; cell form: (delete-table! x y table)
     (let ([cell (hash-ref (hash-ref grid 'cells) (list x y) #f)])
       (when cell
         (let ([old-table (hash-ref cell table #f)])
           (when old-table
             (index-delete-cell! x y table old-table)))
         (hash-remove! cell table)))]))

(define delete-key!
  (case-lambda
    [(table key)
     ;; global form: (delete-key! table key)
     (let ([t (hash-ref (grid-data) table #f)])
       (when t (hash-remove! t key)))]
    [(x y table key)
     ;; cell form: (delete-key! x y table key)
     (let ([table-hash (cell-table x y table)])
       (when table-hash
         (when (hash-has-key? table-hash key)
           (index-delete-cell! x y table key (hash-ref table-hash key #f)))
         (hash-remove! table-hash key)))]))

;; Movement

(define (snapshot-table table coords)
  (for/list ([coord (in-set coords)])
    (let* ([x (first coord)] [y (second coord)]
                             [t (cell-table x y table)])
      (list x y (and t (hash-copy t))))))

(define (write-table! x y table new-table)
  (when new-table
    (let* ([cells     (hash-ref grid 'cells)]
           [cell      (or (hash-ref cells (list x y) #f)
                          (let ([new-cell (make-hash)])
                            (hash-set! cells (list x y) new-cell)
                            new-cell))]
           [old-table (hash-ref cell table #f)])
      (index-write-table! x y table old-table new-table)
      (hash-set! cell table new-table))))

(define copy-by!
  (case-lambda
    [(coords table dx dy)
     (for ([s (snapshot-table table coords)])
       (write-table! (+ (first s) dx) (+ (second s) dy) table (third s)))]
    [(x y table dx dy)
     (copy-by! (set (list x y)) table dx dy)]))

(define copy-to!
  (case-lambda
    [(coords table tx ty)
     (for ([s (snapshot-table table coords)])
       (write-table! tx ty table (third s)))]
    [(x y table tx ty)
     (copy-to! (set (list x y)) table tx ty)]))

(define move-by!
  (case-lambda
    [(coords table dx dy)
     (define snaps (snapshot-table table coords))
     (for ([s snaps])
       (delete-table! (first s) (second s) table))
     (for ([s snaps])
       (write-table! (+ (first s) dx) (+ (second s) dy) table (third s)))]
    [(x y table dx dy)
     (move-by! (set (list x y)) table dx dy)]))

(define move-to!
  (case-lambda
    [(coords table tx ty)
     (define snaps (snapshot-table table coords))
     (for ([s snaps])
       (delete-table! (first s) (second s) table))
     (for ([s snaps])
       (write-table! tx ty table (third s)))]
    [(x y table tx ty)
     (move-to! (set (list x y)) table tx ty)]))

(define (has-table? x y table)
  (hash-has-key? (cell-data x y) table))

(define (has-key? x y table key)
  (let ([t (cell-table x y table)])
    (and t (hash-has-key? t key) #t)))

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

(define (grid-info)
  (format "~a" (grid-data)))

;; Grid-wide operations

(define (all-coordinates)
  (hash-ref grid 'coordinates))

(define (delete-cells! coords table)
  (for ([coord (in-set coords)])
    (delete-table! (first coord) (second coord) table)))

(define (clear!)
  (hash-set! grid 'cells (make-hash))
  (hash-set! grid 'data (make-hash))
  (index-clear!))
