#lang racket

(require rackunit
         gridcode/grid/grid
         gridcode/grid/select)

;; Cell data

(test-case "set-value! — flag form marks cell as having table"
           (init! 10)
           (set-value! 5 5 'wall)
           (check-true (has-table? 5 5 'wall)))

(test-case "set-value! — flag form does not overwrite existing table data"
           (init! 10)
           (set-value! 5 5 'wall 'strength 3)
           (set-value! 5 5 'wall)
           (check-equal? (get-value 5 5 'wall 'strength) 3))

(test-case "set-value! — flag and data forms compose"
           (init! 10)
           (set-value! 5 5 'wall)
           (set-value! 5 5 'wall 'strength 5)
           (check-true (has-table? 5 5 'wall))
           (check-equal? (get-value 5 5 'wall 'strength) 5))

(test-case "set-value!/get-value — store and retrieve value"
           (init! 10)
           (set-value! 5 5 'ball 'dx 1)
           (check-equal? (get-value 5 5 'ball 'dx) 1))

(test-case "set-value! — multiple keys accumulate in table"
           (init! 10)
           (set-value! 5 5 'ball 'dx 1)
           (set-value! 5 5 'ball 'dy -1)
           (check-equal? (get-value 5 5 'ball 'dx) 1)
           (check-equal? (get-value 5 5 'ball 'dy) -1))

(test-case "set-value! — overwrites existing key"
           (init! 10)
           (set-value! 5 5 'ball 'dx 1)
           (set-value! 5 5 'ball 'dx 99)
           (check-equal? (get-value 5 5 'ball 'dx) 99))

(test-case "set-value! — multiple tables in same cell are independent"
           (init! 10)
           (set-value! 3 3 'ball 'dx 1)
           (set-value! 3 3 'wall 'strength 5)
           (check-equal? (get-value 3 3 'ball 'dx) 1)
           (check-equal? (get-value 3 3 'wall 'strength) 5))

(test-case "get-value — returns #f for missing table"
           (init! 10)
           (check-false (get-value 5 5 'ball 'dx)))

(test-case "get-value — returns #f for missing key in existing table"
           (init! 10)
           (set-value! 5 5 'ball 'dx 1)
           (check-false (get-value 5 5 'ball 'dy)))

(test-case "delete-table! — removes entire table"
           (init! 10)
           (set-value! 5 5 'ball 'dx 1)
           (delete-table! 5 5 'ball)
           (check-false (get-value 5 5 'ball 'dx)))

(test-case "delete-key! — removes single key from table"
           (init! 10)
           (set-value! 5 5 'ball 'dx 1)
           (set-value! 5 5 'ball 'dy -1)
           (delete-key! 5 5 'ball 'dx)
           (check-false (get-value 5 5 'ball 'dx))
           (check-equal? (get-value 5 5 'ball 'dy) -1))

(test-case "delete-table! — leaves other tables intact"
           (init! 10)
           (set-value! 5 5 'ball 'dx 1)
           (set-value! 5 5 'wall 'strength 5)
           (delete-table! 5 5 'ball)
           (check-false (get-value 5 5 'ball 'dx))
           (check-equal? (get-value 5 5 'wall 'strength) 5))

(test-case "delete-table! — safe when table is absent"
           (init! 10)
           (check-not-exn (lambda () (delete-table! 5 5 'ball))))

(test-case "delete-key! — safe when key is absent"
           (init! 10)
           (set-value! 5 5 'ball 'dx 1)
           (check-not-exn (lambda () (delete-key! 5 5 'ball 'dy))))

;; Grid (global) data

(test-case "set-value!/get-value — store and retrieve value"
           (init! 10)
           (set-value! 'player 'score 100)
           (check-equal? (get-value 'player 'score) 100))

(test-case "set-value! — multiple keys accumulate in table"
           (init! 10)
           (set-value! 'player 'score 100)
           (set-value! 'player 'lives 3)
           (check-equal? (get-value 'player 'score) 100)
           (check-equal? (get-value 'player 'lives) 3))

(test-case "get-value — returns #f for missing table"
           (init! 10)
           (check-false (get-value 'player 'score)))

(test-case "get-value — returns #f for missing key in existing table"
           (init! 10)
           (set-value! 'player 'score 100)
           (check-false (get-value 'player 'lives)))

(test-case "delete-table! — removes entire table"
           (init! 10)
           (set-value! 'player 'score 100)
           (delete-table! 'player)
           (check-false (get-value 'player 'score)))

(test-case "delete-key! — removes single key from table"
           (init! 10)
           (set-value! 'player 'score 100)
           (set-value! 'player 'lives 3)
           (delete-key! 'player 'score)
           (check-false (get-value 'player 'score))
           (check-equal? (get-value 'player 'lives) 3))

;; Grid-wide operations

(test-case "clear! — resets all cell data and global data"
           (init! 10)
           (set-value! 5 5 'ball 'dx 1)
           (set-value! 'player 'score 1)
           (clear!)
           (check-false (get-value 5 5 'ball 'dx))
           (check-false (get-value 'player 'score)))

;; delete-cells!

(test-case "delete-cells! — removes table from all selected cells"
           (init! 10)
           (set-value! 1 1 'foo 'x 1)
           (set-value! 2 2 'foo 'x 2)
           (delete-cells! (select 'foo) 'foo)
           (check-false (get-value 1 1 'foo 'x))
           (check-false (get-value 2 2 'foo 'x)))

(test-case "delete-cells! — leaves other tables intact"
           (init! 10)
           (set-value! 5 5 'foo 'x 1)
           (set-value! 5 5 'bar 'x 1)
           (delete-cells! (select 'foo) 'foo)
           (check-false (get-value 5 5 'foo 'x))
           (check-equal? (get-value 5 5 'bar 'x) 1))

(test-case "delete-cells! — does nothing for empty selector"
           (init! 10)
           (check-not-exn (lambda () (delete-cells! (select 'foo) 'foo))))

;; copy-by!

(test-case "copy-by! — copies table without removing original"
           (init! 10)
           (set-value! 2 2 'foo 'v 1)
           (copy-by! (select 'foo) 'foo 1 0)
           (check-equal? (get-value 2 2 'foo 'v) 1)
           (check-equal? (get-value 3 2 'foo 'v) 1))

(test-case "copy-by! — preserves all keys in table"
           (init! 10)
           (set-value! 2 2 'ball 'dx 1)
           (set-value! 2 2 'ball 'dy -1)
           (copy-by! (select 'ball) 'ball 1 1)
           (check-equal? (get-value 3 3 'ball 'dx) 1)
           (check-equal? (get-value 3 3 'ball 'dy) -1))

(test-case "copy-by! — only copies specified table, leaves others"
           (init! 10)
           (set-value! 2 2 'foo 'v 1)
           (set-value! 2 2 'bar 'v 1)
           (copy-by! (select 'foo) 'foo 1 0)
           (check-equal? (get-value 2 2 'foo 'v) 1)
           (check-equal? (get-value 2 2 'bar 'v) 1)
           (check-equal? (get-value 3 2 'foo 'v) 1)
           (check-false  (get-value 3 2 'bar 'v)))

(test-case "copy-by! — does nothing for empty selector"
           (init! 10)
           (check-not-exn (lambda () (copy-by! (select 'foo) 'foo 1 0))))

;; copy-to!

(test-case "copy-to! — copies table without removing original"
           (init! 10)
           (set-value! 1 1 'foo 'v 1)
           (copy-to! (select 'foo) 'foo 7 8)
           (check-equal? (get-value 1 1 'foo 'v) 1)
           (check-equal? (get-value 7 8 'foo 'v) 1))

(test-case "copy-to! — only copies specified table, leaves others"
           (init! 10)
           (set-value! 1 1 'foo 'v 1)
           (set-value! 1 1 'bar 'v 1)
           (copy-to! (select 'foo) 'foo 7 8)
           (check-equal? (get-value 1 1 'foo 'v) 1)
           (check-equal? (get-value 1 1 'bar 'v) 1)
           (check-equal? (get-value 7 8 'foo 'v) 1)
           (check-false  (get-value 7 8 'bar 'v)))

(test-case "copy-to! — does nothing for empty selector"
           (init! 10)
           (check-not-exn (lambda () (copy-to! (select 'foo) 'foo 5 5))))

;; move-by!

(test-case "move-by! — moves table by dx dy"
           (init! 10)
           (set-value! 2 2 'foo 'v 1)
           (move-by! (select 'foo) 'foo 1 0)
           (check-false (get-value 2 2 'foo 'v))
           (check-equal? (get-value 3 2 'foo 'v) 1))

(test-case "move-by! — preserves all keys in table"
           (init! 10)
           (set-value! 2 2 'ball 'dx 1)
           (set-value! 2 2 'ball 'dy -1)
           (move-by! (select 'ball) 'ball 1 1)
           (check-equal? (get-value 3 3 'ball 'dx) 1)
           (check-equal? (get-value 3 3 'ball 'dy) -1))

(test-case "move-by! — moves multiple tables"
           (init! 10)
           (set-value! 1 1 'foo 'v 1)
           (set-value! 2 2 'foo 'v 1)
           (move-by! (select 'foo) 'foo 1 0)
           (check-false (get-value 1 1 'foo 'v))
           (check-false (get-value 2 2 'foo 'v))
           (check-equal? (get-value 2 1 'foo 'v) 1)
           (check-equal? (get-value 3 2 'foo 'v) 1))

(test-case "move-by! — only moves specified table, leaves others"
           (init! 10)
           (set-value! 2 2 'foo 'v 1)
           (set-value! 2 2 'bar 'v 1)
           (move-by! (select 'foo) 'foo 1 0)
           (check-false (get-value 2 2 'foo 'v))
           (check-equal? (get-value 2 2 'bar 'v) 1)
           (check-equal? (get-value 3 2 'foo 'v) 1)
           (check-false  (get-value 3 2 'bar 'v)))

(test-case "move-by! — does nothing for empty selector"
           (init! 10)
           (check-not-exn (lambda () (move-by! (select 'foo) 'foo 1 0))))

;; move-to!

(test-case "move-to! — moves table to absolute position"
           (init! 10)
           (set-value! 1 1 'foo 'v 1)
           (move-to! (select 'foo) 'foo 7 8)
           (check-false (get-value 1 1 'foo 'v))
           (check-equal? (get-value 7 8 'foo 'v) 1))

(test-case "move-to! — only moves specified table, leaves others"
           (init! 10)
           (set-value! 1 1 'foo 'v 1)
           (set-value! 1 1 'bar 'v 1)
           (move-to! (select 'foo) 'foo 7 8)
           (check-false (get-value 1 1 'foo 'v))
           (check-equal? (get-value 1 1 'bar 'v) 1)
           (check-equal? (get-value 7 8 'foo 'v) 1)
           (check-false  (get-value 7 8 'bar 'v)))

(test-case "move-to! — does nothing for empty selector"
           (init! 10)
           (check-not-exn (lambda () (move-to! (select 'foo) 'foo 5 5))))

;; single-cell forms

(test-case "move-to! — single-cell form moves table to absolute position"
           (init! 10)
           (set-value! 2 3 'ant 'dx 1)
           (move-to! 2 3 'ant 7 8)
           (check-false (get-value 2 3 'ant 'dx))
           (check-equal? (get-value 7 8 'ant 'dx) 1))

(test-case "move-by! — single-cell form moves table by offset"
           (init! 10)
           (set-value! 2 3 'ant 'dx 1)
           (move-by! 2 3 'ant 1 0)
           (check-false (get-value 2 3 'ant 'dx))
           (check-equal? (get-value 3 3 'ant 'dx) 1))

(test-case "copy-to! — single-cell form copies table to absolute position"
           (init! 10)
           (set-value! 2 3 'foo 'v 1)
           (copy-to! 2 3 'foo 7 8)
           (check-equal? (get-value 2 3 'foo 'v) 1)
           (check-equal? (get-value 7 8 'foo 'v) 1))

(test-case "copy-by! — single-cell form copies table by offset"
           (init! 10)
           (set-value! 2 3 'foo 'v 1)
           (copy-by! 2 3 'foo 1 0)
           (check-equal? (get-value 2 3 'foo 'v) 1)
           (check-equal? (get-value 3 3 'foo 'v) 1))

;; has-table? / has-key?

(test-case "has-table? — returns #t when cell has table"
           (init! 10)
           (set-value! 5 5 'ball 'dx 1)
           (check-true (has-table? 5 5 'ball)))

(test-case "has-table? — returns #f when cell does not have table"
           (init! 10)
           (check-false (has-table? 5 5 'ball)))

(test-case "has-key? — returns #t when table has key"
           (init! 10)
           (set-value! 5 5 'ball 'dx 1)
           (check-true (has-key? 5 5 'ball 'dx)))

(test-case "has-key? — returns #f when table does not have key"
           (init! 10)
           (set-value! 5 5 'ball 'dx 1)
           (check-false (has-key? 5 5 'ball 'dy)))

(test-case "has-key? — returns #f when table is absent (key form)"
           (init! 10)
           (check-false (has-key? 5 5 'ball 'dx)))

;; has-at?

(test-case "has-at? — returns #t when selector contains (x y)"
           (init! 10)
           (set-value! 3 4 'foo 'v 1)
           (check-true (has-at? (select 'foo) 3 4)))

(test-case "has-at? — returns #f when (x y) is not in selector"
           (init! 10)
           (set-value! 3 4 'foo 'v 1)
           (check-false (has-at? (select 'foo) 5 5)))

(test-case "has-at? — returns #f for empty selector"
           (init! 10)
           (check-false (has-at? (select 'foo) 3 4)))

;; bounds-of

(test-case "bounds-of — returns bounding box"
           (init! 10)
           (set-value! 2 3 'foo 'v 1)
           (set-value! 5 1 'foo 'v 1)
           (check-equal? (bounds-of (select 'foo)) '(2 5 1 3)))

(test-case "bounds-of — returns #f for empty selector"
           (init! 10)
           (check-false (bounds-of (select 'foo))))

(test-case "bounds-of — single cell returns equal min and max"
           (init! 10)
           (set-value! 4 7 'foo 'v 1)
           (check-equal? (bounds-of (select 'foo)) '(4 4 7 7)))

;; select

(test-case "select — by table: returns cells with the table"
           (init! 10)
           (set-value! 1 1 'ball 'dx 1)
           (set-value! 2 2 'ball 'dx -1)
           (check-true (has-at? (select 'ball) 1 1))
           (check-true (has-at? (select 'ball) 2 2))
           (check-false (has-at? (select 'ball) 3 3)))

(test-case "select — by table key: returns cells where table has key"
           (init! 10)
           (set-value! 1 1 'ball 'dx 1)
           (set-value! 2 2 'ball 'dy -1)
           (check-true  (has-at? (select 'ball 'dx) 1 1))
           (check-false (has-at? (select 'ball 'dx) 2 2)))

(test-case "select — by table key value: returns cells where value matches"
           (init! 10)
           (set-value! 1 1 'ball 'dx 1)
           (set-value! 2 2 'ball 'dx -1)
           (check-true  (has-at? (select 'ball 'dx 1)  1 1))
           (check-false (has-at? (select 'ball 'dx 1)  2 2))
           (check-true  (has-at? (select 'ball 'dx -1) 2 2)))

(test-case "select — by value list: returns cells where value is in list"
           (init! 10)
           (set-value! 1 1 'ball 'dx  1)
           (set-value! 2 2 'ball 'dx -1)
           (set-value! 3 3 'ball 'dx  0)
           (check-true  (has-at? (select 'ball 'dx '(1 -1)) 1 1))
           (check-true  (has-at? (select 'ball 'dx '(1 -1)) 2 2))
           (check-false (has-at? (select 'ball 'dx '(1 -1)) 3 3)))
