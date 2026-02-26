#lang racket

(require rackunit
         racket/set
         gridcode/grid/grid
         gridcode/grid/select
         gridcode/lang/expander)

;; with

(test-case "with — iterates over all matching cells"
  (init! 10)
  (set-cell! 1 1 'foo)
  (set-cell! 2 3 'foo)
  (define visited (set))
  (with (select 'foo) as (x y)
    (set! visited (set-add visited (list x y))))
  (check-equal? visited (set '(1 1) '(2 3))))

(test-case "with — does nothing for empty set"
  (init! 10)
  (define count 0)
  (with (select 'foo) as (x y)
    (set! count (+ count 1)))
  (check-equal? count 0))

(test-case "with — x and y are bound correctly"
  (init! 10)
  (set-cell! 3 7 'foo)
  (define result #f)
  (with (select 'foo) as (x y)
    (set! result (list x y)))
  (check-equal? result '(3 7)))

(test-case "with — body can use define"
  (init! 10)
  (set-cell! 4 4 'foo 'val 99)
  (define found #f)
  (with (select 'foo) as (x y)
    (define cell (get-cell x y 'foo))
    (set! found (get cell 'val)))
  (check-equal? found 99))

;; with-any

(test-case "with-any — executes body for one matching cell"
  (init! 10)
  (set-cell! 3 4 'foo)
  (define found #f)
  (with-any (select 'foo) as (x y)
    (set! found (list x y)))
  (check-equal? found '(3 4)))

(test-case "with-any — does nothing for empty set"
  (init! 10)
  (define ran #f)
  (with-any (select 'foo) as (x y)
    (set! ran #t))
  (check-false ran))

(test-case "with-any — executes exactly once with multiple matches"
  (init! 10)
  (set-cell! 1 1 'foo)
  (set-cell! 2 2 'foo)
  (set-cell! 3 3 'foo)
  (define count 0)
  (with-any (select 'foo) as (x y)
    (set! count (+ count 1)))
  (check-equal? count 1))
