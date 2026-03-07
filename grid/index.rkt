#lang racket

(require racket/set)

(provide index-set-cell!
         index-delete-cell!
         index-write-table!
         index-clear!
         index-select)

;; Three indices maintained as the grid is mutated.
;;
;;   table-index  : table → mutable-set(coord)
;;   key-index    : table → key → mutable-set(coord)
;;   value-index  : table → key → value → mutable-set(coord)
;;
;; All three are updated by index-set-cell!, index-delete-cell!,
;; index-write-table!, and index-clear!, which mirror the grid's
;; mutation API exactly.

(define table-index (make-hash))
(define key-index   (make-hash))
(define value-index (make-hash))

;; ---- Internal helpers ----

(define (get-or-create-hash! parent-hash lookup-key)
  (or (hash-ref parent-hash lookup-key #f)
      (let ([new-hash (make-hash)])
        (hash-set! parent-hash lookup-key new-hash)
        new-hash)))

(define (get-or-create-set! parent-hash lookup-key)
  (or (hash-ref parent-hash lookup-key #f)
      (let ([new-set (mutable-set)])
        (hash-set! parent-hash lookup-key new-set)
        new-set)))

(define (add-coord-to-index! parent-hash lookup-key coord)
  (set-add! (get-or-create-set! parent-hash lookup-key) coord))

(define (remove-coord-from-index! parent-hash lookup-key coord)
  (let ([coord-set (hash-ref parent-hash lookup-key #f)])
    (when coord-set
      (set-remove! coord-set coord))))

;; Return an immutable copy of a mutable or immutable set.
(define (copy-as-immutable coord-set)
  (for/set ([coord (in-set coord-set)]) coord))

;; Remove all index entries for a (coord, table) pair.
;; old-table-hash is the table's key→value hash before deletion,
;; or #f if the table was a flag (no keys).
(define (remove-table-from-all-indices! coord table old-table-hash)
  (remove-coord-from-index! table-index table coord)
  (when old-table-hash
    (let ([key-index-for-table   (hash-ref key-index table #f)]
          [value-index-for-table (hash-ref value-index table #f)])
      (for ([(stored-key stored-value) (in-hash old-table-hash)])
        (when key-index-for-table
          (remove-coord-from-index! key-index-for-table stored-key coord))
        (let* ([value-index-for-key   (and value-index-for-table
                                           (hash-ref value-index-for-table stored-key #f))]
               [coord-set-for-value   (and value-index-for-key
                                           (hash-ref value-index-for-key stored-value #f))])
          (when coord-set-for-value
            (set-remove! coord-set-for-value coord)))))))

;; ---- Public API ----

;; Mirrors set-value! in grid.rkt:
;;   (index-set-cell! x y table)                        — flag form
;;   (index-set-cell! x y table key old-value new-value) — data form
;;
;; old-value is the value currently at (x y table key), or #f if absent.
(define index-set-cell!
  (case-lambda
    [(x y table)
     (add-coord-to-index! table-index table (list x y))]
    [(x y table key old-value new-value)
     (let ([coord (list x y)])
       (add-coord-to-index! table-index table coord)
       (add-coord-to-index! (get-or-create-hash! key-index table) key coord)
       ;; Remove coord from the old value's bucket in value-index
       (let* ([value-index-for-table (hash-ref value-index table #f)]
              [value-index-for-key   (and value-index-for-table
                                         (hash-ref value-index-for-table key #f))]
              [old-value-set         (and value-index-for-key
                                         (hash-ref value-index-for-key old-value #f))])
         (when old-value-set
           (set-remove! old-value-set coord)))
       ;; Add coord to the new value's bucket in value-index
       (add-coord-to-index!
        (get-or-create-hash! (get-or-create-hash! value-index table) key)
        new-value
        coord))]))

;; Mirrors delete-table!/delete-key! in grid.rkt:
;;   (index-delete-cell! x y table old-table-hash)   — whole table
;;   (index-delete-cell! x y table key old-value)    — single key
;;
;; old-table-hash: the table's hash (key→value) before deletion, or #f if flag-only.
;; old-value: the value stored at key before deletion.
(define index-delete-cell!
  (case-lambda
    [(x y table old-table-hash)
     (remove-table-from-all-indices! (list x y) table old-table-hash)]
    [(x y table key old-value)
     (let ([coord (list x y)])
       (let ([key-index-for-table (hash-ref key-index table #f)])
         (when key-index-for-table
           (remove-coord-from-index! key-index-for-table key coord)))
       (let* ([value-index-for-table (hash-ref value-index table #f)]
              [value-index-for-key   (and value-index-for-table
                                         (hash-ref value-index-for-table key #f))]
              [coord-set-for-value   (and value-index-for-key
                                         (hash-ref value-index-for-key old-value #f))])
         (when coord-set-for-value
           (set-remove! coord-set-for-value coord))))]))

;; Mirrors write-table! (used internally by move/copy operations).
;; old-table-hash: the table hash at (x y table) before the write, or #f if absent.
;; new-table-hash: the table hash being written (always non-#f when called).
(define (index-write-table! x y table old-table-hash new-table-hash)
  (remove-table-from-all-indices! (list x y) table old-table-hash)
  (let ([coord (list x y)])
    (add-coord-to-index! table-index table coord)
    (for ([(stored-key stored-value) (in-hash new-table-hash)])
      (add-coord-to-index! (get-or-create-hash! key-index table) stored-key coord)
      (add-coord-to-index!
       (get-or-create-hash! (get-or-create-hash! value-index table) stored-key)
       stored-value
       coord))))

;; Mirrors clear! / init! — resets all three indices.
(define (index-clear!)
  (set! table-index (make-hash))
  (set! key-index   (make-hash))
  (set! value-index (make-hash)))

;; ---- Queries — all return immutable coordinate sets ----

;; (index-select table)           — cells that have the table
;; (index-select table key)       — cells where table has the key
;; (index-select table key value) — cells where table's key equals value
(define index-select
  (case-lambda
    [(table)
     (copy-as-immutable (or (hash-ref table-index table #f) (set)))]
    [(table key)
     (let ([key-index-for-table (hash-ref key-index table #f)])
       (if key-index-for-table
           (copy-as-immutable (or (hash-ref key-index-for-table key #f) (set)))
           (set)))]
    [(table key value)
     (let* ([value-index-for-table (hash-ref value-index table #f)]
            [value-index-for-key   (and value-index-for-table
                                        (hash-ref value-index-for-table key #f))])
       (if value-index-for-key
           (copy-as-immutable (or (hash-ref value-index-for-key value #f) (set)))
           (set)))]))
