#lang racket

(require rackunit
         racket/set
         gridcode/grid/grid
         gridcode/grid/select)

;; select (key)

(test-case "select — returns coordinates of cells with key"
  (init! 10)
  (set-cell! 2 3 'wall)
  (set-cell! 5 7 'wall)
  (check-equal? (select 'wall) (set '(2 3) '(5 7))))

(test-case "select — returns empty set when no cells match"
  (init! 10)
  (check-equal? (select 'wall) (set)))

;; select (key property)

(test-case "select — filters cells with dictionary property present"
  (init! 10)
  (set-cell! 1 1 'enemy 'state 'active)
  (set-cell! 2 2 'enemy 'state 'frozen)
  (set-cell! 3 3 'wall)
  (check-equal? (select 'enemy 'state) (set '(1 1) '(2 2))))

(test-case "select — property filter excludes non-dictionary cells"
  (init! 10)
  (set-cell! 1 1 'wall)
  (check-equal? (select 'wall 'dx) (set)))

;; select (key property value)

(test-case "select — filters by exact property value"
  (init! 10)
  (set-cell! 1 1 'enemy 'state 'active)
  (set-cell! 2 2 'enemy 'state 'frozen)
  (check-equal? (select 'enemy 'state 'active) (set '(1 1))))

(test-case "select — returns empty set when value does not match"
  (init! 10)
  (set-cell! 1 1 'enemy 'state 'active)
  (check-equal? (select 'enemy 'state 'frozen) (set)))

(test-case "select — filters by list of values"
  (init! 10)
  (set-cell! 1 1 'enemy 'state 'active)
  (set-cell! 2 2 'enemy 'state 'frozen)
  (set-cell! 3 3 'enemy 'state 'dead)
  (check-equal? (select 'enemy 'state '(active frozen)) (set '(1 1) '(2 2))))

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
