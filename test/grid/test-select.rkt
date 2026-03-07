#lang racket

(require rackunit
         racket/set
         gridcode/grid/grid
         gridcode/grid/select)

;; with

(test-case "with — iterates over all matching cells"
           (init! 10)
           (set-value! 1 1 'foo 'v 1)
           (set-value! 2 3 'foo 'v 1)
           (define visited (set))
           (with (select 'foo) as (x y)
                 (set! visited (set-add visited (list x y))))
           (check-equal? visited (set '(1 1) '(2 3))))

(test-case "with — executes once per matching cell"
           (init! 10)
           (set-value! 1 1 'foo 'v 1)
           (set-value! 2 2 'foo 'v 1)
           (set-value! 3 3 'foo 'v 1)
           (define count 0)
           (with (select 'foo) as (_x _y)
                 (set! count (+ count 1)))
           (check-equal? count 3))

(test-case "with — does nothing for empty set"
           (init! 10)
           (define count 0)
           (with (select 'foo) as (_x _y)
                 (set! count (+ count 1)))
           (check-equal? count 0))

(test-case "with — x and y are bound correctly"
           (init! 10)
           (set-value! 3 7 'foo 'v 1)
           (define result #f)
           (with (select 'foo) as (x y)
                 (set! result (list x y)))
           (check-equal? result '(3 7)))

(test-case "with — body can read cell data"
           (init! 10)
           (set-value! 4 4 'foo 'val 99)
           (define found #f)
           (with (select 'foo) as (x y)
                 (set! found (get-value x y 'foo 'val)))
           (check-equal? found 99))

(test-case "with (one ...) — executes exactly once with multiple matches"
           (init! 10)
           (set-value! 1 1 'foo 'v 1)
           (set-value! 2 2 'foo 'v 1)
           (set-value! 3 3 'foo 'v 1)
           (define count 0)
           (with (one (select 'foo)) as (_x _y)
                 (set! count (+ count 1)))
           (check-equal? count 1))

;; select (key)

(test-case "select — returns coordinates of cells with table"
  (init! 10)
  (set-value! 2 3 'wall 'v 1)
  (set-value! 5 7 'wall 'v 1)
  (check-equal? (select 'wall) (set '(2 3) '(5 7))))

(test-case "select — returns empty set when no cells match"
  (init! 10)
  (check-equal? (select 'wall) (set)))

(test-case "select — finds cells with table present"
  (init! 10)
  (set-value! 3 3 'foo 'v 0)
  (check-equal? (select 'foo) (set '(3 3))))

(test-case "select — finds cells set with flag form (no keys)"
  (init! 10)
  (set-value! 4 6 'wall)
  (check-equal? (select 'wall) (set '(4 6))))

;; select (table key)

(test-case "select — filters cells where table has key"
  (init! 10)
  (set-value! 1 1 'enemy 'state 1)
  (set-value! 2 2 'enemy 'state 2)
  (set-value! 3 3 'wall 'v 1)
  (check-equal? (select 'enemy 'state) (set '(1 1) '(2 2))))

(test-case "select — key filter excludes cells without that key"
  (init! 10)
  (set-value! 1 1 'wall 'v 1)
  (check-equal? (select 'wall 'dx) (set)))

;; select (key property value)

(test-case "select — filters by exact key value"
  (init! 10)
  (set-value! 1 1 'enemy 'state 1)
  (set-value! 2 2 'enemy 'state 2)
  (check-equal? (select 'enemy 'state 1) (set '(1 1))))

(test-case "select — returns empty set when value does not match"
  (init! 10)
  (set-value! 1 1 'enemy 'state 1)
  (check-equal? (select 'enemy 'state 2) (set)))

(test-case "select — filters by list of values"
  (init! 10)
  (set-value! 1 1 'enemy 'state 1)
  (set-value! 2 2 'enemy 'state 2)
  (set-value! 3 3 'enemy 'state 3)
  (check-equal? (select 'enemy 'state '(1 2)) (set '(1 1) '(2 2))))

;; select-all

(test-case "select-all — returns all coordinates"
  (init! 2)
  (check-equal? (select-all) (set '(0 0) '(0 1) '(1 0) '(1 1))))

(test-case "select-all — count equals grid-size squared"
  (init! 8)
  (check-equal? (set-count (select-all)) 64))

;; select-xy

(test-case "select-xy — returns set with single coordinate"
  (check-equal? (select-xy 3 5) (set '(3 5))))

;; select-column / select-row

(test-case "select-column — returns all cells in column"
  (init! 3)
  (check-equal? (select-column 1) (set '(1 0) '(1 1) '(1 2))))

(test-case "select-row — returns all cells in row"
  (init! 3)
  (check-equal? (select-row 2) (set '(0 2) '(1 2) '(2 2))))

;; select-rectangle

(test-case "select-rectangle — returns correct cells"
  (init! 10)
  (check-equal? (select-rectangle 1 2 3 2)
                (set '(1 2) '(2 2) '(3 2) '(1 3) '(2 3) '(3 3))))

(test-case "select-rectangle — width 1 height 1 returns single cell"
  (init! 10)
  (check-equal? (select-rectangle 4 5 1 1) (set '(4 5))))

(test-case "select-rectangle — count equals width times height"
  (init! 10)
  (check-equal? (set-count (select-rectangle 0 0 4 3)) 12))

;; select-neighbors (moore)

(test-case "select-neighbors — moore r=1 returns 8 cells"
  (check-equal? (set-count (select-neighbors 5 5 'moore)) 8))

(test-case "select-neighbors — moore r=2 returns 24 cells"
  (check-equal? (set-count (select-neighbors 5 5 'moore 2)) 24))

(test-case "select-neighbors — moore does not include origin"
  (check-false (set-member? (select-neighbors 5 5 'moore) '(5 5))))

;; select-neighbors (von-neumann)

(test-case "select-neighbors — von-neumann r=1 returns 4 cells"
  (check-equal? (set-count (select-neighbors 5 5 'von-neumann)) 4))

(test-case "select-neighbors — von-neumann contains cardinal directions"
  (define n (select-neighbors 5 5 'von-neumann))
  (check-true (set-member? n '(5 4)))
  (check-true (set-member? n '(5 6)))
  (check-true (set-member? n '(4 5)))
  (check-true (set-member? n '(6 5))))

(test-case "select-neighbors — von-neumann r=2 returns 12 cells"
  (check-equal? (set-count (select-neighbors 5 5 'von-neumann 2)) 12))

;; select-neighbors (horizontal/vertical)

(test-case "select-neighbors — horizontal r=2 returns 4 cells"
  (check-equal? (select-neighbors 5 5 'horizontal 2)
                (set '(3 5) '(4 5) '(6 5) '(7 5))))

(test-case "select-neighbors — vertical r=1 returns 2 cells"
  (check-equal? (select-neighbors 5 5 'vertical 1)
                (set '(5 4) '(5 6))))

;; select-at

(test-case "select-at — applies deltas to position"
  (check-equal? (select-at '((-1 0) (1 0)) 5 5)
                (set '(4 5) '(6 5))))

(test-case "select-at — empty deltas returns empty set"
  (check-equal? (select-at '() 5 5) (set)))

;; offset

(test-case "offset — shifts all coordinates by dx dy"
  (check-equal? (offset (set '(1 2) '(3 4)) 1 0)
                (set '(2 2) '(4 4))))

(test-case "offset — zero offset is identity"
  (define coords (set '(1 1) '(2 3)))
  (check-equal? (offset coords 0 0) coords))

(test-case "offset — empty set returns empty set"
  (check-equal? (offset (set) 1 1) (set)))

;; union / intersection / difference

(test-case "union — combines two sets"
  (check-equal? (union (set '(1 1)) (set '(2 2)))
                (set '(1 1) '(2 2))))

(test-case "union — deduplicates overlapping elements"
  (check-equal? (union (set '(1 1) '(2 2)) (set '(2 2) '(3 3)))
                (set '(1 1) '(2 2) '(3 3))))

(test-case "intersection — returns common elements"
  (check-equal? (intersection (set '(1 1) '(2 2)) (set '(2 2) '(3 3)))
                (set '(2 2))))

(test-case "intersection — returns empty set when no overlap"
  (check-equal? (intersection (set '(1 1)) (set '(2 2)))
                (set)))

(test-case "difference — subtracts second from first"
  (check-equal? (difference (set '(1 1) '(2 2)) (set '(2 2)))
                (set '(1 1))))

(test-case "difference — no change when sets are disjoint"
  (check-equal? (difference (set '(1 1)) (set '(2 2)))
                (set '(1 1))))

;; one

(test-case "one — empty set returns empty set"
  (check-equal? (one (set)) (set)))

(test-case "one — single element returns that element"
  (check-equal? (one (set '(3 4))) (set '(3 4))))

(test-case "one — multiple elements returns exactly one"
  (check-equal? (set-count (one (set '(1 1) '(2 2) '(3 3)))) 1))

;; nearest

(test-case "nearest — empty set returns empty set"
  (check-equal? (nearest 5 5 (set)) (set)))

(test-case "nearest — single element returns that element"
  (check-equal? (nearest 5 5 (set '(5 5))) (set '(5 5))))

(test-case "nearest — returns closest coordinate"
  (check-equal? (nearest 0 0 (set '(1 0) '(5 0) '(10 0))) (set '(1 0))))

(test-case "nearest — uses euclidean distance"
  (check-equal? (nearest 0 0 (set '(3 0) '(2 2))) (set '(2 2))))

(test-case "nearest — returns exactly one element"
  (check-equal? (set-count (nearest 5 5 (set '(3 5) '(8 5)))) 1))
