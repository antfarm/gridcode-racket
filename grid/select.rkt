#lang racket

(require racket/set
         "grid.rkt"
         "dictionary.rkt")

(provide select
         select-all
         select-xy
         select-neighbors
         select-at
         offset
         one
         nearest)

(define select
  (case-lambda
    [(key)
     (list->set
      (map (lambda (c) (list (first c) (second c)))
           (cells-with-key key)))]
    [(key property)
     (list->set
      (filter-map (lambda (c)
                    (define val (third c))
                    (and (dictionary? val)
                         (dictionary-ref val property)
                         (list (first c) (second c))))
                  (cells-with-key key)))]
    [(key property value)
     (list->set
      (filter-map (lambda (c)
                    (define val   (third c))
                    (define pval  (and (dictionary? val)
                                       (dictionary-ref val property)))
                    (and pval
                         (if (list? value)
                             (member pval value)
                             (equal? pval value))
                         (list (first c) (second c))))
                  (cells-with-key key)))]))

(define (cells-with-key key)
  (filter-map (lambda (coord)
                (let* ([x (first coord)]
                       [y (second coord)]
                       [cell (get-cell x y)])
                  (if (hash-has-key? cell key)
                      (list x y (hash-ref cell key))
                      #f)))
              (all-coordinates)))

(define (select-all)
  (list->set (all-coordinates)))

(define (select-xy x y)
  (set (list x y)))

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
