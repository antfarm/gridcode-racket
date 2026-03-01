# GridCode API Reference Guide

For code examples that illustrate how to use the API see [Usage Examples](#usage-examples) on this page and have a look at the [example programs](/examples).

---

## Reference

### Cell Data

| Signature | Description | Returns |
|---|---|---|
| `(set-cell! x y key)` | Mark cell as having key (presence) | void |
| `(set-cell! x y key value)` | Store a scalar value under key | void |
| `(set-cell! x y key property value)` | Set a property on key's dictionary | void |
| `(get-cell x y)` | All keys on a cell | hash |
| `(get-cell x y key)` | Value stored under key | dictionary \| value \| #t \| #f |
| `(get dictionary property)` | Read a property from a dictionary | value \| #f |
| `(delete-cell! x y key)` | Remove key from cell | void |
| `(delete-cell! x y key property)` | Remove one property from key's dictionary | void |
| `(delete-cells! coords key)` | Remove key from all cells in selector | void |

### Global Data

| Signature | Description | Returns |
|---|---|---|
| `(set-grid! key value)` | Store a program-level value | void |
| `(get-grid key)` | Read a program-level value | value \| #f |
| `(delete-grid! key)` | Remove a program-level value | void |

### Clear Operations

| Signature | Description |
|---|---|
| `(clear!)` | Reset all cell data and global data |
| `(clear-cells!)` | Reset all cell data, keep global data |
| `(clear-grid!)` | Reset all global data, keep cell data |

### Coordinate Selectors

| Signature | Description | Returns |
|---|---|---|
| `(select key)` | All cells that have key | set of coords |
| `(select key property)` | Cells where key has a given property | set of coords |
| `(select key property value)` | Cells where key's property equals value | set of coords |
| `(select-all)` | Every cell on the grid | set of coords |
| `(select-xy x y)` | A single cell | set of coords |
| `(select-row y)` | All cells in row y | set of coords |
| `(select-column x)` | All cells in column x | set of coords |
| `(select-neighbors x y neighborhood)` | Cells surrounding (x, y) | set of coords |
| `(select-neighbors x y neighborhood r)` | Cells within radius r of (x, y) | set of coords |
| `(select-at deltas x y)` | Cells at specific offsets from (x, y) | set of coords |

Neighborhoods: `'moore`, `'von-neumann`, `'horizontal`, `'vertical`. Default radius `r` = 1.

### Selector Modifiers

| Signature | Description | Returns |
|---|---|---|
| `(offset coords dx dy)` | Shift all coords by (dx, dy) | set of coords |
| `(union s1 s2 ...)` | Coords in any of the sets | set of coords |
| `(intersection s1 s2 ...)` | Coords in all of the sets | set of coords |
| `(difference s1 s2 ...)` | Coords in s1 but not in s2 | set of coords |
| `(one coords)` | Any single coord from the set | set of coords (0 or 1 element) |
| `(nearest x y coords)` | Closest coord to (x, y) | set of coords (0 or 1 element) |

### Spatial Queries

| Signature | Description | Returns |
|---|---|---|
| `(exists-at? coords x y)` | Check if (x, y) is in the selector | bool |
| `(bounds-of coords)` | Bounding box of the selector | (x-min x-max y-min y-max) \| #f |

### Movement

| Signature | Description | Returns |
|---|---|---|
| `(move-by! coords key dx dy)` | Move key's data from coords by (dx, dy) | void |
| `(move-to! coords key tx ty)` | Move key's data from coords to (tx, ty) | void |
| `(copy-by! coords key dx dy)` | Copy key's data from coords by (dx, dy), keep originals | void |
| `(copy-to! coords key tx ty)` | Copy key's data from coords to (tx, ty), keep originals | void |


### Color

| Signature | Description | Returns |
|---|---|---|
| `(color r g b)` | RGB color, fully opaque; each channel 0.0–1.0 | color vector |
| `(color r g b a)` | RGBA color with alpha | color vector |
| `(with-opacity color opacity)` | Return color with alpha replaced | color vector |

---

## Usage Examples

### Storing Data on Cells

Each cell can hold any number of named **keys**. A key can store a boolean presence marker, a scalar value, or a dictionary of named properties.

**Presence** — mark a cell as having a feature:

```racket
(set-cell! x y 'wall)
(get-cell  x y 'wall)      ; → #t | #f
(delete-cell! x y 'wall)
```

**Scalar** — store a single value under a key:

```racket
(set-cell! x y 'trail 0.8)
(get-cell  x y 'trail)     ; → value | #f
(delete-cell! x y 'trail)
```

**Dictionary** — store a named collection of properties under a key. Multiple `set-cell!` calls accumulate:

```racket
(set-cell! x y 'ball 'dx  1)
(set-cell! x y 'ball 'dy -1)
(define b (get-cell x y 'ball))    ; → dictionary | #f
(get b 'dx)                        ; → value | #f
(or (get b 'dx) 0)                 ; → value | default
(delete-cell! x y 'ball 'dx)       ; remove one property
(delete-cell! x y 'ball)           ; remove whole dictionary
```

A cell can hold multiple keys simultaneously:

```racket
(set-cell! x y 'wall)
(set-cell! x y 'ball 'dx 1)        ; same cell holds both
```

---

### Coordinate Selectors

A **selector** is a set of `(x y)` coordinate pairs. Selector functions describe *which cells* to work with; they don't read or write cell data.

**Select by key** — all cells that have a given key:

```racket
(select 'wall)                         ; all wall cells
(select 'ball 'dx)                     ; ball cells that have a 'dx property
(select 'ball 'dx 1)                   ; ball cells where dx = 1
(select 'ball 'dx '(-1 1))             ; ball cells where dx is -1 or 1
```

**Select by position** — geometric queries:

```racket
(select-all)                           ; every cell on the grid
(select-xy 5 3)                        ; a single cell
(select-row 0)                         ; entire top row
(select-column 0)                      ; entire left column
(select-neighbors 5 5 'moore)          ; 8 surrounding cells
(select-neighbors 5 5 'von-neumann)    ; 4 orthogonal cells
(select-neighbors 5 5 'horizontal 2)   ; 2 cells left and right
(select-neighbors 5 5 'vertical 2)     ; 2 cells above and below
```

---

### Selector Modifiers

**Selector modifiers** take one or more selectors and return a new selector. They let you build precise selections through composition.

**Set algebra** — combine or filter coordinate sets:

```racket
(union s1 s2)                          ; all coords in either
(intersection s1 s2)                   ; coords in both
(difference s1 s2)                     ; coords in s1 but not s2
```

**Spatial** — shift or reduce:

```racket
(offset coords dx dy)                  ; shift all coords by (dx, dy)
(one coords)                           ; any single coord from the set
(nearest x y coords)                   ; closest coord to (x, y)
```

**Example — collision preview**: check if moving the paddle right would hit a wall, without actually moving:

```racket
(set-empty? (intersection (offset (select 'paddle) 1 0) (select 'wall)))
```

---

### Iterating with `with`

`with` loops over a selector, executing the body once per coordinate with `x` and `y` bound:

```racket
(with (select 'wall) as (x y)
  (set-cell! x y 'wall 'dx 1))
```

When a selector contains exactly one cell (e.g. a single ball), `with` is used to unpack its position:

```racket
(with (select 'ball) as (ball-x ball-y)
  (define ball (get-cell ball-x ball-y 'ball))
  (define dx (get ball 'dx))
  ...)
```

`select-xy` always produces a single-cell selector and is useful for naming a computed position:

```racket
(with (select-xy (+ ball-x dx) (+ ball-y dy)) as (new-x new-y)
  ...)
```

---

### Spatial Queries

`exists-at?` checks whether a specific coordinate is in a selector:

```racket
(exists-at? (select 'wall) new-x new-y)    ; → #t | #f
```

`bounds-of` returns the bounding box of a selector:

```racket
(bounds-of (select 'paddle))    ; → (x-min x-max y-min y-max) | #f
```

---

### Moving Entities

Movement functions transfer the data stored under a key from a selector to a destination. Only the specified key is affected; other keys at the same cell are untouched.

**Move by offset** — shift selected cells by (dx, dy):

```racket
(move-by! (select 'paddle) 'paddle dx 0)
```

**Move to position** — teleport selected cells to an absolute coordinate:

```racket
(move-to! (select 'ball) 'ball new-x new-y)
```

Note: `move-to!` places all selected cells at the same destination. It makes sense when the selector has exactly one cell (a single entity). For multi-cell shapes, use `move-by!`.

Both functions use a **two-pass** approach (snapshot all source values, then write) to avoid aliasing bugs when source and destination overlap.

---

### Copying

`copy-by!` and `copy-to!` work like their `move-*` counterparts but leave the original cells intact:

```racket
(copy-by! (select 'trail) 'trail dx dy)
(copy-to! (select 'ball)  'ball  bx by)
```

---

### Global Data

Store values that belong to the program rather than any particular cell:

```racket
(set-grid! 'score 0)
(get-grid  'score)             ; → value | #f
(or (get-grid 'score) 0)       ; → value | default
(delete-grid! 'score)
```

---

### Clearing the Grid

```racket
(clear!)                       ; reset all cell data and all global data
(clear-cells!)                 ; reset all cell data, keep global data
(clear-cells! 'ball)           ; remove only the 'ball key from all cells
(clear-cells! '(ball paddle))  ; remove multiple keys from all cells
(clear-grid!)                  ; reset all global data, keep cells
(delete-grid! 'score)          ; remove one global key
```

---

### Colors

```racket
(color r g b)             ; RGB, each 0.0–1.0, fully opaque
(color r g b a)           ; RGBA with alpha
(with-opacity c opacity)  ; return copy of color c with new alpha
```

