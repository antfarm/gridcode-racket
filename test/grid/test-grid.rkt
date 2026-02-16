#lang racket

(require rackunit
         gridcode/grid/grid)

(test-case "Grid initialization"
           (init! 10)
           (set-cell! 0 0 "test" "value")
           (check-equal? (get-cell 0 0 "test") "value"))

(test-case "Cell operations - set and get"
           (init! 10)
           (set-cell! 5 5 "state" "alive")
           (set-cell! 5 5 "age" 1)
           (check-equal? (get-cell 5 5 "state") "alive")
           (check-equal? (get-cell 5 5 "age") 1))

(test-case "Cell operations - default values"
           (init! 10)
           (check-false (get-cell 5 5 "missing"))
           (check-equal? (get-cell 5 5 "missing" 0) 0))

(test-case "get-any-cell finds cell with #f value"
           (init! 10)
           (set-cell! 5 5 "flag" #f)
           (check-equal? (get-any-cell "flag") '(5 5 #f)))

(test-case "get-all-cells finds cells with #f value"
           (init! 10)
           (set-cell! 3 3 "wall" #t)
           (set-cell! 7 7 "wall" #f)
           (check-equal? (get-all-cells "wall") '((3 3 #t) (7 7 #f))))

(test-case "delete-cell removes key"
           (init! 10)
           (set-cell! 5 5 "state" "alive")
           (delete-cell! 5 5 "state")
           (check-false (get-cell 5 5 "state")))

(test-case "clear! resets grid"
           (init! 10)
           (set-cell! 5 5 "state" "alive")
           (clear!)
           (check-false (get-cell 5 5 "state")))