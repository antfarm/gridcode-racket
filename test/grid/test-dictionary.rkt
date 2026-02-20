#lang racket

(require rackunit
         gridcode/grid/dictionary)

;; dictionary (constructor)

(test-case "dictionary — creates a dictionary"
           (check-true (dictionary? (dictionary 'prop1 1))))

(test-case "dictionary — empty dictionary"
           (check-true (dictionary? (dictionary))))

(test-case "dictionary — multiple properties"
           (define d (dictionary 'prop1 1 'prop2 2))
           (check-equal? (dictionary-ref d 'prop1) 1)
           (check-equal? (dictionary-ref d 'prop2) 2))

;; dictionary?

(test-case "dictionary? — returns #t for a dictionary"
           (check-true (dictionary? (dictionary 'prop1 1))))

(test-case "dictionary? — returns #f for non-dictionary values"
           (check-false (dictionary? #f))
           (check-false (dictionary? #t))
           (check-false (dictionary? 42))
           (check-false (dictionary? "hello"))
           (check-false (dictionary? '(1 2 3))))

;; dictionary-ref

(test-case "dictionary-ref — reads a property"
           (define d (dictionary 'prop1 99))
           (check-equal? (dictionary-ref d 'prop1) 99))

(test-case "dictionary-ref — returns #f for missing property"
           (define d (dictionary 'prop1 1))
           (check-false (dictionary-ref d 'prop2)))

(test-case "dictionary-ref — value can be #f"
           (define d (dictionary 'prop1 #f))
           (check-false (dictionary-ref d 'prop1)))

;; dictionary-set

(test-case "dictionary-set — adds a new property"
           (define d (dictionary 'prop1 1))
           (define d2 (dictionary-set d 'prop2 2))
           (check-equal? (dictionary-ref d2 'prop1) 1)
           (check-equal? (dictionary-ref d2 'prop2) 2))

(test-case "dictionary-set — updates an existing property"
           (define d (dictionary 'prop1 1))
           (define d2 (dictionary-set d 'prop1 99))
           (check-equal? (dictionary-ref d2 'prop1) 99))

(test-case "dictionary-set — does not mutate the original"
           (define d (dictionary 'prop1 1))
           (dictionary-set d 'prop1 99)
           (check-equal? (dictionary-ref d 'prop1) 1))

(test-case "dictionary-set — chaining builds up properties"
           (define d (dictionary-set (dictionary-set (dictionary) 'prop1 1) 'prop2 2))
           (check-equal? (dictionary-ref d 'prop1) 1)
           (check-equal? (dictionary-ref d 'prop2) 2))

;; dictionary-remove

(test-case "dictionary-remove — removes a property"
           (define d (dictionary 'prop1 1 'prop2 2))
           (define d2 (dictionary-remove d 'prop1))
           (check-false (dictionary-ref d2 'prop1))
           (check-equal? (dictionary-ref d2 'prop2) 2))

(test-case "dictionary-remove — does not mutate the original"
           (define d (dictionary 'prop1 1))
           (dictionary-remove d 'prop1)
           (check-equal? (dictionary-ref d 'prop1) 1))

(test-case "dictionary-remove — safe when property is absent"
           (define d (dictionary 'prop1 1))
           (check-not-exn (lambda () (dictionary-remove d 'prop2))))
