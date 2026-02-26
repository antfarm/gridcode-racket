#lang racket

(require rackunit
         gridcode/grid/grid
         gridcode/grid/select)

;; Cell data

(test-case "set-cell!/get-cell — presence (3 args)"
           (init! 10)
           (set-cell! 5 5 'key1)
           (check-equal? (get-cell 5 5 'key1) #t))

(test-case "set-cell!/get-cell — flat value (4 args)"
           (init! 10)
           (set-cell! 5 5 'key1 42)
           (check-equal? (get-cell 5 5 'key1) 42))

(test-case "set-cell!/get-cell — dictionary (5 args)"
           (init! 10)
           (set-cell! 5 5 'key1 'prop1 100)
           (check-equal? (get (get-cell 5 5 'key1) 'prop1) 100))

(test-case "set-cell! — multiple properties accumulate in dictionary"
           (init! 10)
           (set-cell! 5 5 'key1 'prop1 1)
           (set-cell! 5 5 'key1 'prop2 2)
           (define d (get-cell 5 5 'key1))
           (check-equal? (get d 'prop1) 1)
           (check-equal? (get d 'prop2) 2))

(test-case "set-cell! — overwrites existing property"
           (init! 10)
           (set-cell! 5 5 'key1 'prop1 1)
           (set-cell! 5 5 'key1 'prop1 99)
           (check-equal? (get (get-cell 5 5 'key1) 'prop1) 99))

(test-case "set-cell! — multiple keys in same cell are independent"
           (init! 10)
           (set-cell! 3 3 'key1 'prop1 10)
           (set-cell! 3 3 'key2 'prop1 20)
           (check-equal? (get (get-cell 3 3 'key1) 'prop1) 10)
           (check-equal? (get (get-cell 3 3 'key2) 'prop1) 20))

(test-case "get-cell — returns #f for missing key"
           (init! 10)
           (check-false (get-cell 5 5 'key1)))

(test-case "get — returns property value from dictionary"
           (init! 10)
           (set-cell! 5 5 'key1 'prop1 99)
           (check-equal? (get (get-cell 5 5 'key1) 'prop1) 99))

(test-case "get — returns #f for missing property"
           (init! 10)
           (set-cell! 5 5 'key1 'prop1 1)
           (check-false (get (get-cell 5 5 'key1) 'prop2)))

(test-case "get — returns #f when passed #f"
           (check-false (get #f 'prop1)))

(test-case "delete-cell! — removes key"
           (init! 10)
           (set-cell! 5 5 'key1)
           (delete-cell! 5 5 'key1)
           (check-false (get-cell 5 5 'key1)))

(test-case "delete-cell! — leaves other keys intact"
           (init! 10)
           (set-cell! 5 5 'key1)
           (set-cell! 5 5 'key2)
           (delete-cell! 5 5 'key1)
           (check-false (get-cell 5 5 'key1))
           (check-true (get-cell 5 5 'key2)))

(test-case "delete-cell! — safe when key is absent"
           (init! 10)
           (check-not-exn (lambda () (delete-cell! 5 5 'key1))))

(test-case "delete-cell! — removes a single property from dictionary"
           (init! 10)
           (set-cell! 5 5 'key1 'prop1 1)
           (set-cell! 5 5 'key1 'prop2 2)
           (delete-cell! 5 5 'key1 'prop1)
           (check-false (get (get-cell 5 5 'key1) 'prop1))
           (check-equal? (get (get-cell 5 5 'key1) 'prop2) 2))

(test-case "delete-cell! — leaves key intact after property removal"
           (init! 10)
           (set-cell! 5 5 'key1 'prop1 1)
           (delete-cell! 5 5 'key1 'prop1)
           (check-true (hash-has-key? (get-cell 5 5) 'key1)))

(test-case "delete-cell! — safe when property is absent"
           (init! 10)
           (set-cell! 5 5 'key1 'prop1 1)
           (check-not-exn (lambda () (delete-cell! 5 5 'key1 'prop2))))

;; Multi-cell queries

(test-case "get-all-cells — returns all cells with key"
           (init! 10)
           (set-cell! 2 3 'key1)
           (set-cell! 7 8 'key1)
           (check-equal? (length (get-all-cells 'key1)) 2))

(test-case "get-all-cells — empty when no cells match"
           (init! 10)
           (check-equal? (get-all-cells 'key1) '()))

(test-case "get-all-cells — finds cells with #f value"
           (init! 10)
           (set-cell! 3 3 'key1 #f)
           (check-equal? (get-all-cells 'key1) '((3 3 #f))))

(test-case "get-all-cells — returns dictionary as third element"
           (init! 10)
           (set-cell! 5 5 'key1 'prop1 7)
           (define result (get-all-cells 'key1))
           (check-equal? (get (third (first result)) 'prop1) 7))

(test-case "get-any-cell — returns cell with key"
           (init! 10)
           (set-cell! 4 4 'key1 'prop1 7)
           (define result (get-any-cell 'key1))
           (check-equal? (first result) 4)
           (check-equal? (second result) 4)
           (check-equal? (get (third result) 'prop1) 7))

(test-case "get-any-cell — returns #f when no cells match"
           (init! 10)
           (check-false (get-any-cell 'key1)))

(test-case "get-any-cell — finds cell with #f value"
           (init! 10)
           (set-cell! 5 5 'key1 #f)
           (check-equal? (get-any-cell 'key1) '(5 5 #f)))

;; Movement & collision

(test-case "move-cells! — moves all cells with key"
           (init! 10)
           (set-cell! 2 2 'key1)
           (move-cells! 'key1 1 0)
           (check-false (get-cell 2 2 'key1))
           (check-true (get-cell 3 2 'key1)))

(test-case "move-cells! — preserves dictionary data"
           (init! 10)
           (set-cell! 2 2 'key1 'prop1 55)
           (move-cells! 'key1 1 1)
           (check-equal? (get (get-cell 3 3 'key1) 'prop1) 55))

(test-case "move-cells! — leaves other keys intact"
           (init! 10)
           (set-cell! 2 2 'key1)
           (set-cell! 2 2 'key2)
           (move-cells! 'key1 1 0)
           (check-true (get-cell 2 2 'key2)))

(test-case "bounds — returns bounding box"
           (init! 10)
           (set-cell! 2 3 'key1)
           (set-cell! 5 1 'key1)
           (check-equal? (bounds 'key1) '(2 5 1 3)))

(test-case "bounds — returns #f when no cells match"
           (init! 10)
           (check-false (bounds 'key1)))

(test-case "collides? — detects overlap"
           (init! 10)
           (set-cell! 3 3 'key1)
           (set-cell! 3 3 'key2)
           (check-true (collides? 'key1 'key2)))

(test-case "collides? — returns #f when no overlap"
           (init! 10)
           (set-cell! 1 1 'key1)
           (set-cell! 5 5 'key2)
           (check-false (collides? 'key1 'key2)))

(test-case "collides-at? — detects hypothetical collision"
           (init! 10)
           (set-cell! 2 2 'key1)
           (set-cell! 3 2 'key2)
           (check-true (collides-at? 'key1 1 0 'key2)))

(test-case "collides-at? — returns #f when move is clear"
           (init! 10)
           (set-cell! 2 2 'key1)
           (set-cell! 9 9 'key2)
           (check-false (collides-at? 'key1 1 0 'key2)))

;; Grid (global) data

(test-case "set-grid!/get-grid — set and retrieve value"
           (init! 10)
           (set-grid! 'key1 42)
           (check-equal? (get-grid 'key1) 42))

(test-case "get-grid — returns #f for missing key"
           (init! 10)
           (check-false (get-grid 'key1)))


(test-case "delete-grid! — removes key"
           (init! 10)
           (set-grid! 'key1 42)
           (delete-grid! 'key1)
           (check-false (get-grid 'key1)))

;; Grid-wide operations

(test-case "delete-all! — removes all cells with key"
           (init! 10)
           (set-cell! 1 1 'key1)
           (set-cell! 2 2 'key1)
           (delete-all! 'key1)
           (check-equal? (get-all-cells 'key1) '()))

(test-case "delete-all! — leaves other keys intact"
           (init! 10)
           (set-cell! 1 1 'key1)
           (set-cell! 1 1 'key2)
           (delete-all! 'key1)
           (check-false (get-cell 1 1 'key1))
           (check-true (get-cell 1 1 'key2)))

(test-case "clear! — resets all cells and grid data"
           (init! 10)
           (set-cell! 5 5 'key1)
           (set-grid! 'key1 1)
           (clear!)
           (check-false (get-cell 5 5 'key1))
           (check-false (get-grid 'key1)))

(test-case "clear! with keys — removes only specified keys"
           (init! 10)
           (set-cell! 5 5 'key1)
           (set-cell! 5 5 'key2)
           (clear! '(key1))
           (check-false (get-cell 5 5 'key1))
           (check-true (get-cell 5 5 'key2)))

;; move-by!

(test-case "move-by! — moves a single cell by dx dy"
  (init! 10)
  (set-cell! 2 2 'foo)
  (move-by! (select 'foo) 1 0)
  (check-false (get-cell 2 2 'foo))
  (check-true  (get-cell 3 2 'foo)))

(test-case "move-by! — preserves scalar value"
  (init! 10)
  (set-cell! 2 2 'foo 42)
  (move-by! (select 'foo) 0 1)
  (check-equal? (get-cell 2 3 'foo) 42))

(test-case "move-by! — preserves dictionary data"
  (init! 10)
  (set-cell! 2 2 'ball 'dx 1)
  (set-cell! 2 2 'ball 'dy -1)
  (move-by! (select 'ball) 1 1)
  (check-equal? (get (get-cell 3 3 'ball) 'dx) 1)
  (check-equal? (get (get-cell 3 3 'ball) 'dy) -1))

(test-case "move-by! — moves multiple cells"
  (init! 10)
  (set-cell! 1 1 'foo)
  (set-cell! 2 2 'foo)
  (move-by! (select 'foo) 1 0)
  (check-false (get-cell 1 1 'foo))
  (check-false (get-cell 2 2 'foo))
  (check-true  (get-cell 2 1 'foo))
  (check-true  (get-cell 3 2 'foo)))

(test-case "move-by! — moves all keys at selected cells"
  (init! 10)
  (set-cell! 2 2 'foo)
  (set-cell! 2 2 'bar)
  (move-by! (select 'foo) 1 0)
  (check-false (get-cell 2 2 'foo))
  (check-false (get-cell 2 2 'bar))
  (check-true  (get-cell 3 2 'foo))
  (check-true  (get-cell 3 2 'bar)))

(test-case "move-by! — does nothing for empty selector"
  (init! 10)
  (check-not-exn (lambda () (move-by! (select 'foo) 1 0))))

;; move-to!

(test-case "move-to! — moves a single cell to absolute position"
  (init! 10)
  (set-cell! 1 1 'foo)
  (move-to! (select 'foo) 7 8)
  (check-false (get-cell 1 1 'foo))
  (check-true  (get-cell 7 8 'foo)))

(test-case "move-to! — preserves scalar value"
  (init! 10)
  (set-cell! 1 1 'foo 99)
  (move-to! (select 'foo) 5 5)
  (check-equal? (get-cell 5 5 'foo) 99))

(test-case "move-to! — does nothing for empty selector"
  (init! 10)
  (check-not-exn (lambda () (move-to! (select 'foo) 5 5))))

;; exists-at?

(test-case "exists-at? — returns #t when selector contains (x y)"
  (init! 10)
  (set-cell! 3 4 'foo)
  (check-true (exists-at? (select 'foo) 3 4)))

(test-case "exists-at? — returns #f when (x y) is not in selector"
  (init! 10)
  (set-cell! 3 4 'foo)
  (check-false (exists-at? (select 'foo) 5 5)))

(test-case "exists-at? — returns #f for empty selector"
  (init! 10)
  (check-false (exists-at? (select 'foo) 3 4)))

;; bounds-of

(test-case "bounds-of — returns bounding box"
  (init! 10)
  (set-cell! 2 3 'foo)
  (set-cell! 5 1 'foo)
  (check-equal? (bounds-of (select 'foo)) '(2 5 1 3)))

(test-case "bounds-of — returns #f for empty selector"
  (init! 10)
  (check-false (bounds-of (select 'foo))))

(test-case "bounds-of — single cell returns equal min and max"
  (init! 10)
  (set-cell! 4 7 'foo)
  (check-equal? (bounds-of (select 'foo)) '(4 4 7 7)))
