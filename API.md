 # Public Grid API

(for use in GridCode programs)

---

## Cell Data

### Presence

Mark a cell as occupied. The value is always `#t`.

```
(set-cell! x y 'wall)              ; mark
(get-cell  x y 'wall)              ; → #t | #f
(delete-cell! x y 'wall)           ; unmark
```

### Scalar

Store a single named value on a cell.

```
(set-cell! x y 'state 'alive)      ; write
(get-cell  x y 'state)             ; → value | #f
(delete-cell! x y 'state)          ; remove
```

### Dictionary

Store a named collection of properties on a cell.

```
(set-cell! x y 'ball 'dx  1)       ; write property
(set-cell! x y 'ball 'dy -1)       ; write another property
(get-cell  x y 'ball)              ; → dictionary | #f
(get dict 'dx)                     ; read property      → value | #f
(or (get dict 'dx) 0)              ; read with default
(delete-cell! x y 'ball 'dx)       ; remove one property
(delete-cell! x y 'ball)           ; remove whole dictionary
```

A cell can hold multiple keys at once:

```
(set-cell! x y 'wall)              ; presence
(set-cell! x y 'ball 'dx 1)        ; dictionary on the same cell
```

---

## Multi-Cell Queries

Find cells by key across the whole grid.

```
(get-any-cell 'ball)               ; → (x y value) | #f
(get-all-cells 'wall)              ; → ((x y value) ...)
```

The value in the result is whatever was stored — `#t`, a scalar, or a dictionary.
Use `define-list` to unpack the result:

```
(define cell (get-any-cell 'ball))
(when cell
  (define-list (x y ball) cell)
  (define dx (get ball 'dx)))
```

---

## Movement & Collision

Move all cells with a given key by an offset:

```
(move-cells! 'paddle 1 0)          ; move right by 1
```

Check if two groups of cells currently overlap:

```
(collides? 'ball 'wall)            ; → #t | #f
```

Check if moving a group would cause a collision, without actually moving:

```
(collides-at? 'paddle 1 0 'wall)   ; → #t | #f
```

Get the bounding box of all cells with a key:

```
(bounds 'paddle)                   ; → (x-min x-max y-min y-max) | #f
```

---

## Global Data

Store values that belong to the program, not to any cell.

```
(set-grid! 'score 0)               ; write
(get-grid  'score)                 ; → value | #f
(or (get-grid 'score) 0)           ; → value | default
(delete-grid! 'score)              ; remove
```

---

## Grid-Wide Operations

```
(delete-all! 'wall)                ; remove all cells with key
(clear!)                           ; reset entire grid
(clear! '(ball paddle))            ; reset only listed keys
```

---

# Reference

## Cell Read / Write

`(set-cell! x y key)`                           → void

`(set-cell! x y key value)`                     → void

`(set-cell! x y key property value)`            → void

`(get-cell x y)`                                → hash

`(get-cell x y key)`                            → dictionary | value | #t | #f

`(get dictionary property)`                      → value | #f

`(delete-cell! x y key)`                        → void

`(delete-cell! x y key property)`               → void

## Multi-Cell Queries

`(get-any-cell key)`                            → (x y value) | #f

`(get-all-cells key)`                           → ((x y value) ...)

## Movement & Collision

`(move-cells! key dx dy)`                       → void

`(bounds key)`                                  → (x-min x-max y-min y-max) | #f

`(collides? key1 key2)`                         → bool

`(collides-at? key dx dy other-key)`            → bool

## Global Data

`(set-grid! key value)`                         → void

`(get-grid key)`                                 → value | #f

`(delete-grid! key)`                            → void

## Grid-Wide Operations

`(delete-all! key)`                             → void

`(clear!)`                                      → void

`(clear! keys)`                                 → void


# Framework Internal Functions

## Initialization

`(init! size)`                                  → void


# Grid Internal Functions

(not exported)

## Helpers

`(get-coords key)`                              → ((x y) ...)

`(all-coordinates)`                             → ((x y) ...)
