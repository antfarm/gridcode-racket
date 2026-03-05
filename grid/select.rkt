#lang racket

(require racket/set
         "grid.rkt"
         "index.rkt")

(provide select
         select-all
         select-xy
         select-column
         select-row
         select-rectangle
         select-neighbors
         select-at
         offset
         one
         nearest
         union
         intersection
         difference
         with)

(define-syntax with
  (syntax-rules (as)
    [(with selector as (x y) body ...)
     (for ([coord (in-set selector)])
       (let ([x (first coord)]
             [y (second coord)])
         body ...))]))

(define select
  (case-lambda
    [(table)
     (index-select table)]
    [(table key)
     (index-select table key)]
    [(table key value)
     (if (list? value)
         (foldl set-union (set) (map (lambda (v) (index-select table key v)) value))
         (index-select table key value))]))

(define (select-all)
  (list->set (all-coordinates)))

(define (select-xy x y)
  (set (list x y)))

(define (select-column x)
  (list->set
   (filter (lambda (coord) (= (first coord) x))
           (all-coordinates))))

(define (select-row y)
  (list->set
   (filter (lambda (coord) (= (second coord) y))
           (all-coordinates))))

(define (select-rectangle x y width height)
  (list->set
   (filter (lambda (coord)
             (and (>= (first coord) x)  (< (first coord) (+ x width))
                  (>= (second coord) y) (< (second coord) (+ y height))))
           (all-coordinates))))

(define (select-at deltas x y)
  (list->set
   (map (lambda (d) (list (+ x (first d)) (+ y (second d))))
        deltas)))

(define (select-neighbors x y neighborhood [r 1])
  (select-at (neighborhood->deltas neighborhood r) x y))

(define (neighborhood->deltas neighborhood r)
  (case neighborhood
    [(moore)
     (filter (lambda (d) (not (equal? d '(0 0))))
             (for*/list ([dx (in-range (- r) (+ r 1))]
                         [dy (in-range (- r) (+ r 1))])
               (list dx dy)))]
    [(von-neumann)
     (filter (lambda (d) (and (not (equal? d '(0 0)))
                              (<= (+ (abs (first d)) (abs (second d))) r)))
             (for*/list ([dx (in-range (- r) (+ r 1))]
                         [dy (in-range (- r) (+ r 1))])
               (list dx dy)))]
    [(horizontal)
     (append (for/list ([i (in-range 1 (+ r 1))]) (list (- i) 0))
             (for/list ([i (in-range 1 (+ r 1))]) (list i 0)))]
    [(vertical)
     (append (for/list ([i (in-range 1 (+ r 1))]) (list 0 (- i)))
             (for/list ([i (in-range 1 (+ r 1))]) (list 0 i)))]))

(define (offset coords dx dy)
  (list->set
   (set-map coords (lambda (c) (list (+ (first c) dx) (+ (second c) dy))))))

(define (one coords)
  (if (set-empty? coords)
      (set)
      (set (set-first coords))))

(define (union . sets)
  (apply set-union sets))

(define (intersection . sets)
  (apply set-intersect sets))

(define (difference s . sets)
  (apply set-subtract s sets))

(define (nearest x y coords)
  (if (set-empty? coords)
      (set)
      (let* ([coord-list (set->list coords)]
             [closest (argmin (lambda (c)
                                (let ([dx (- (first c) x)]
                                      [dy (- (second c) y)])
                                  (+ (* dx dx) (* dy dy))))
                              coord-list)])
        (set closest))))
