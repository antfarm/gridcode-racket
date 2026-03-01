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

(test-case "clear! — resets all cells and grid data"
           (init! 10)
           (set-cell! 5 5 'key1)
           (set-grid! 'key1 1)
           (clear!)
           (check-false (get-cell 5 5 'key1))
           (check-false (get-grid 'key1)))

(test-case "clear-cells! — resets all cell data, leaves grid data"
           (init! 10)
           (set-cell! 5 5 'key1)
           (set-grid! 'key1 1)
           (clear-cells!)
           (check-false (get-cell 5 5 'key1))
           (check-equal? (get-grid 'key1) 1))

(test-case "clear-cells! with single key — removes only that key"
           (init! 10)
           (set-cell! 5 5 'key1)
           (set-cell! 5 5 'key2)
           (clear-cells! 'key1)
           (check-false (get-cell 5 5 'key1))
           (check-true  (get-cell 5 5 'key2)))

(test-case "clear-cells! with key list — removes only listed keys"
           (init! 10)
           (set-cell! 5 5 'key1)
           (set-cell! 5 5 'key2)
           (set-cell! 5 5 'key3)
           (clear-cells! '(key1 key2))
           (check-false (get-cell 5 5 'key1))
           (check-false (get-cell 5 5 'key2))
           (check-true  (get-cell 5 5 'key3)))

(test-case "clear-grid! — resets all grid data, leaves cell data"
           (init! 10)
           (set-cell! 5 5 'key1)
           (set-grid! 'key1 1)
           (clear-grid!)
           (check-true  (get-cell 5 5 'key1))
           (check-false (get-grid 'key1)))


;; copy-by!

(test-case "copy-by! — copies a cell without removing the original"
           (init! 10)
           (set-cell! 2 2 'foo)
           (copy-by! (select 'foo) 'foo 1 0)
           (check-true (get-cell 2 2 'foo))
           (check-true (get-cell 3 2 'foo)))

(test-case "copy-by! — preserves scalar value"
           (init! 10)
           (set-cell! 2 2 'foo 42)
           (copy-by! (select 'foo) 'foo 0 1)
           (check-equal? (get-cell 2 3 'foo) 42))

(test-case "copy-by! — preserves dictionary data"
           (init! 10)
           (set-cell! 2 2 'ball 'dx 1)
           (set-cell! 2 2 'ball 'dy -1)
           (copy-by! (select 'ball) 'ball 1 1)
           (check-equal? (get (get-cell 3 3 'ball) 'dx) 1)
           (check-equal? (get (get-cell 3 3 'ball) 'dy) -1))

(test-case "copy-by! — only copies specified key, leaves others"
           (init! 10)
           (set-cell! 2 2 'foo)
           (set-cell! 2 2 'bar)
           (copy-by! (select 'foo) 'foo 1 0)
           (check-true  (get-cell 2 2 'foo))
           (check-true  (get-cell 2 2 'bar))
           (check-true  (get-cell 3 2 'foo))
           (check-false (get-cell 3 2 'bar)))

(test-case "copy-by! — does nothing for empty selector"
           (init! 10)
           (check-not-exn (lambda () (copy-by! (select 'foo) 'foo 1 0))))

;; copy-to!

(test-case "copy-to! — copies a cell without removing the original"
           (init! 10)
           (set-cell! 1 1 'foo)
           (copy-to! (select 'foo) 'foo 7 8)
           (check-true (get-cell 1 1 'foo))
           (check-true (get-cell 7 8 'foo)))

(test-case "copy-to! — preserves scalar value"
           (init! 10)
           (set-cell! 1 1 'foo 99)
           (copy-to! (select 'foo) 'foo 5 5)
           (check-equal? (get-cell 5 5 'foo) 99))

(test-case "copy-to! — only copies specified key, leaves others"
           (init! 10)
           (set-cell! 1 1 'foo)
           (set-cell! 1 1 'bar)
           (copy-to! (select 'foo) 'foo 7 8)
           (check-true  (get-cell 1 1 'foo))
           (check-true  (get-cell 1 1 'bar))
           (check-true  (get-cell 7 8 'foo))
           (check-false (get-cell 7 8 'bar)))

(test-case "copy-to! — does nothing for empty selector"
           (init! 10)
           (check-not-exn (lambda () (copy-to! (select 'foo) 'foo 5 5))))

;; move-by!

(test-case "move-by! — moves a single cell by dx dy"
           (init! 10)
           (set-cell! 2 2 'foo)
           (move-by! (select 'foo) 'foo 1 0)
           (check-false (get-cell 2 2 'foo))
           (check-true  (get-cell 3 2 'foo)))

(test-case "move-by! — preserves scalar value"
           (init! 10)
           (set-cell! 2 2 'foo 42)
           (move-by! (select 'foo) 'foo 0 1)
           (check-equal? (get-cell 2 3 'foo) 42))

(test-case "move-by! — preserves dictionary data"
           (init! 10)
           (set-cell! 2 2 'ball 'dx 1)
           (set-cell! 2 2 'ball 'dy -1)
           (move-by! (select 'ball) 'ball 1 1)
           (check-equal? (get (get-cell 3 3 'ball) 'dx) 1)
           (check-equal? (get (get-cell 3 3 'ball) 'dy) -1))

(test-case "move-by! — moves multiple cells"
           (init! 10)
           (set-cell! 1 1 'foo)
           (set-cell! 2 2 'foo)
           (move-by! (select 'foo) 'foo 1 0)
           (check-false (get-cell 1 1 'foo))
           (check-false (get-cell 2 2 'foo))
           (check-true  (get-cell 2 1 'foo))
           (check-true  (get-cell 3 2 'foo)))

(test-case "move-by! — only moves specified key, leaves others"
           (init! 10)
           (set-cell! 2 2 'foo)
           (set-cell! 2 2 'bar)
           (move-by! (select 'foo) 'foo 1 0)
           (check-false (get-cell 2 2 'foo))
           (check-true  (get-cell 2 2 'bar))
           (check-true  (get-cell 3 2 'foo))
           (check-false (get-cell 3 2 'bar)))

(test-case "move-by! — does nothing for empty selector"
           (init! 10)
           (check-not-exn (lambda () (move-by! (select 'foo) 'foo 1 0))))

;; move-to!

(test-case "move-to! — moves a single cell to absolute position"
           (init! 10)
           (set-cell! 1 1 'foo)
           (move-to! (select 'foo) 'foo 7 8)
           (check-false (get-cell 1 1 'foo))
           (check-true  (get-cell 7 8 'foo)))

(test-case "move-to! — preserves scalar value"
           (init! 10)
           (set-cell! 1 1 'foo 99)
           (move-to! (select 'foo) 'foo 5 5)
           (check-equal? (get-cell 5 5 'foo) 99))

(test-case "move-to! — only moves specified key, leaves others"
           (init! 10)
           (set-cell! 1 1 'foo)
           (set-cell! 1 1 'bar)
           (move-to! (select 'foo) 'foo 7 8)
           (check-false (get-cell 1 1 'foo))
           (check-true  (get-cell 1 1 'bar))
           (check-true  (get-cell 7 8 'foo))
           (check-false (get-cell 7 8 'bar)))

(test-case "move-to! — does nothing for empty selector"
           (init! 10)
           (check-not-exn (lambda () (move-to! (select 'foo) 'foo 5 5))))

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
