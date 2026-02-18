 # Public Grid API

(for use in GridCode programs)

## Global Data

`(set-grid! key value)`                         → void

`(get-grid key [default #f])`                   → value | default

`(delete-grid! key)`                            → void

## Cell Read / Write

`(set-cell! x y key [value #t])`                → void

`(get-cell x y)`                                → hash

`(get-cell x y key [default #f])`               → value | default

`(delete-cell! x y key)`                        → void

## Multi-Cell Queries

`(get-any-cell key)`                            → (x y data) | #f

`(get-all-cells key)`                           → ((x y data) ...)

## Movement & Collision

`(move-cells! key dx dy)`                       → void

`(bounds key)`                                  → (x-min x-max y-min y-max) | #f

`(collides? key1 key2)`                         → bool

`(collides-at? key dx dy other-key)`            → bool

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
