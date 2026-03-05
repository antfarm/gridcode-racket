#lang racket

(require rackunit
         racket/set
         gridcode/grid/index)

;; Each test calls index-clear! to start from a clean state.

;; ---- index-set-cell! flag form ----

(test-case "index-set-cell! flag — cell appears in table index"
  (index-clear!)
  (index-set-cell! 3 4 'wall)
  (check-true (set-member? (index-select 'wall) '(3 4))))

(test-case "index-set-cell! flag — only affects named table"
  (index-clear!)
  (index-set-cell! 3 4 'wall)
  (check-false (set-member? (index-select 'ball) '(3 4))))

(test-case "index-set-cell! flag — multiple cells in same table"
  (index-clear!)
  (index-set-cell! 1 1 'wall)
  (index-set-cell! 2 3 'wall)
  (check-equal? (index-select 'wall) (set '(1 1) '(2 3))))

(test-case "index-set-cell! flag — repeated call is idempotent"
  (index-clear!)
  (index-set-cell! 5 5 'wall)
  (index-set-cell! 5 5 'wall)
  (check-equal? (index-select 'wall) (set '(5 5))))

;; ---- index-set-cell! data form ----

(test-case "index-set-cell! data — cell appears in all three indices"
  (index-clear!)
  (index-set-cell! 1 2 'ball 'dx #f 1)
  (check-true (set-member? (index-select 'ball)       '(1 2)))
  (check-true (set-member? (index-select 'ball 'dx)   '(1 2)))
  (check-true (set-member? (index-select 'ball 'dx 1) '(1 2))))

(test-case "index-set-cell! data — different keys are indexed independently"
  (index-clear!)
  (index-set-cell! 5 5 'ball 'dx #f  1)
  (index-set-cell! 5 5 'ball 'dy #f -1)
  (check-true (set-member? (index-select 'ball 'dx)    '(5 5)))
  (check-true (set-member? (index-select 'ball 'dy)    '(5 5)))
  (check-true (set-member? (index-select 'ball 'dx 1)  '(5 5)))
  (check-true (set-member? (index-select 'ball 'dy -1) '(5 5))))

(test-case "index-set-cell! data — updating value removes coord from old value bucket"
  (index-clear!)
  (index-set-cell! 5 5 'ball 'dx #f 1)
  (index-set-cell! 5 5 'ball 'dx 1  2)  ; old-value = 1, new-value = 2
  (check-false (set-member? (index-select 'ball 'dx 1) '(5 5)))
  (check-true  (set-member? (index-select 'ball 'dx 2) '(5 5))))

(test-case "index-set-cell! data — updating value keeps coord in table and key index"
  (index-clear!)
  (index-set-cell! 5 5 'ball 'dx #f 1)
  (index-set-cell! 5 5 'ball 'dx 1  2)
  (check-true (set-member? (index-select 'ball)     '(5 5)))
  (check-true (set-member? (index-select 'ball 'dx) '(5 5))))

(test-case "index-set-cell! data — multiple coords in same value bucket"
  (index-clear!)
  (index-set-cell! 1 1 'enemy 'state #f 'active)
  (index-set-cell! 2 2 'enemy 'state #f 'active)
  (index-set-cell! 3 3 'enemy 'state #f 'inactive)
  (check-equal? (index-select 'enemy 'state 'active)
                (set '(1 1) '(2 2)))
  (check-equal? (index-select 'enemy 'state 'inactive)
                (set '(3 3))))

;; ---- index-select returns empty set when nothing matches ----

(test-case "index-select — returns empty set for unknown table"
  (index-clear!)
  (check-equal? (index-select 'ghost) (set)))

(test-case "index-select — returns empty set for unknown key"
  (index-clear!)
  (index-set-cell! 1 1 'ball 'dx #f 1)
  (check-equal? (index-select 'ball 'dy) (set)))

(test-case "index-select — returns empty set for unknown value"
  (index-clear!)
  (index-set-cell! 1 1 'ball 'dx #f 1)
  (check-equal? (index-select 'ball 'dx 99) (set)))

;; ---- index-delete-cell! whole table ----

(test-case "index-delete-cell! table — removes coord from table index"
  (index-clear!)
  (index-set-cell! 5 5 'wall 'strength #f 3)
  (let ([old-table (hash 'strength 3)])
    (index-delete-cell! 5 5 'wall old-table))
  (check-false (set-member? (index-select 'wall) '(5 5))))

(test-case "index-delete-cell! table — removes coord from key index"
  (index-clear!)
  (index-set-cell! 5 5 'wall 'strength #f 3)
  (let ([old-table (hash 'strength 3)])
    (index-delete-cell! 5 5 'wall old-table))
  (check-false (set-member? (index-select 'wall 'strength) '(5 5))))

(test-case "index-delete-cell! table — removes coord from value index"
  (index-clear!)
  (index-set-cell! 5 5 'wall 'strength #f 3)
  (let ([old-table (hash 'strength 3)])
    (index-delete-cell! 5 5 'wall old-table))
  (check-false (set-member? (index-select 'wall 'strength 3) '(5 5))))

(test-case "index-delete-cell! table — flag-only (empty table hash)"
  (index-clear!)
  (index-set-cell! 5 5 'marker)
  (index-delete-cell! 5 5 'marker (make-hash))
  (check-false (set-member? (index-select 'marker) '(5 5))))

(test-case "index-delete-cell! table — other coords in same table are unaffected"
  (index-clear!)
  (index-set-cell! 1 1 'wall 'strength #f 3)
  (index-set-cell! 2 2 'wall 'strength #f 3)
  (index-delete-cell! 1 1 'wall (hash 'strength 3))
  (check-false (set-member? (index-select 'wall) '(1 1)))
  (check-true  (set-member? (index-select 'wall) '(2 2))))

;; ---- index-delete-cell! single key ----

(test-case "index-delete-cell! key — removes coord from key index"
  (index-clear!)
  (index-set-cell! 5 5 'ball 'dx #f 1)
  (index-set-cell! 5 5 'ball 'dy #f -1)
  (index-delete-cell! 5 5 'ball 'dx 1)
  (check-false (set-member? (index-select 'ball 'dx) '(5 5)))
  (check-true  (set-member? (index-select 'ball 'dy) '(5 5))))

(test-case "index-delete-cell! key — removes coord from value index"
  (index-clear!)
  (index-set-cell! 5 5 'ball 'dx #f 1)
  (index-delete-cell! 5 5 'ball 'dx 1)
  (check-false (set-member? (index-select 'ball 'dx 1) '(5 5))))

(test-case "index-delete-cell! key — keeps coord in table index"
  (index-clear!)
  (index-set-cell! 5 5 'ball 'dx #f 1)
  (index-set-cell! 5 5 'ball 'dy #f -1)
  (index-delete-cell! 5 5 'ball 'dx 1)
  (check-true (set-member? (index-select 'ball) '(5 5))))

;; ---- index-write-table! ----

(test-case "index-write-table! — adds coord to all three indices for new keys"
  (index-clear!)
  (index-write-table! 3 3 'ball #f (hash 'dx 1 'dy -1))
  (check-true (set-member? (index-select 'ball)        '(3 3)))
  (check-true (set-member? (index-select 'ball 'dx)    '(3 3)))
  (check-true (set-member? (index-select 'ball 'dx 1)  '(3 3)))
  (check-true (set-member? (index-select 'ball 'dy)    '(3 3)))
  (check-true (set-member? (index-select 'ball 'dy -1) '(3 3))))

(test-case "index-write-table! — replaces old table entries"
  (index-clear!)
  (index-set-cell! 3 3 'ball 'dx #f 1)
  (index-write-table! 3 3 'ball (hash 'dx 1) (hash 'dx 2))
  (check-false (set-member? (index-select 'ball 'dx 1) '(3 3)))
  (check-true  (set-member? (index-select 'ball 'dx 2) '(3 3))))

(test-case "index-write-table! — removes old keys not present in new table"
  (index-clear!)
  (index-set-cell! 3 3 'ball 'dx #f 1)
  (index-set-cell! 3 3 'ball 'dy #f -1)
  (index-write-table! 3 3 'ball (hash 'dx 1 'dy -1) (hash 'dx 2))
  (check-false (set-member? (index-select 'ball 'dy) '(3 3)))
  (check-true  (set-member? (index-select 'ball 'dx) '(3 3))))

;; ---- index-clear! ----

(test-case "index-clear! — removes all entries from all indices"
  (index-clear!)
  (index-set-cell! 1 1 'wall 'strength #f 3)
  (index-set-cell! 2 2 'ball 'dx #f 1)
  (index-clear!)
  (check-equal? (index-select 'wall)            (set))
  (check-equal? (index-select 'wall 'strength)  (set))
  (check-equal? (index-select 'wall 'strength 3)(set))
  (check-equal? (index-select 'ball)            (set))
  (check-equal? (index-select 'ball 'dx)        (set))
  (check-equal? (index-select 'ball 'dx 1)      (set)))
