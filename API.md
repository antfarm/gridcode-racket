# GridCode Reference Guide


## Overview

**GridCode** is a grid-based programming environment ...

See the [example programs](/examples) for working simulations, and [Usage Examples](#usage-examples) below for detailed API usage.

### Writing a Program

**GridCode** programs use the Racket dialect `#lang gridcode`. 

The `program` macro takes a name as an argument and expects a set of definitions of values and functions in its body:

| Name | Type | Description | Purpose |
|---|---|---|---|
| `grid-size` | `number` |  Number of cells per column and row | Defines the size of the grid |
| `frame-rate` | `number` | Number of `update-grid` calls per second | Specifies how fast the program runs |
| `(setup-grid)` | `function` | Called once at startup | Initializes the data stored in the grid |
| `(update-grid)` | `function` | Called every frame | Advances the simulation by mutating the data stored in the grid |
| `(color-for-cell x y)` | `function` | Called for every cell every frame | Changes the cell color |
| `(info-for-cell x y)` | `function` | Called when a cell is inspected | Describes the cell data in text |
| `(handle-cell-tapped x y)` | `function` | Called when the user clicks cell `(x, y)` | Reacts on cell click |
| `(handle-key-pressed key)` | `function` | Called when the user presses a key | Reacts on key press |


## API Reference

### Cell Data

Each cell can store several named symbol tables that map from keys to values.
A cell is addressed by its (x y) coordinates, a stored value by the tuple (x y table key).

| Function | Description | Returns |
|---|---|---|
| `(set-cell! x y table)` | Set a flag on the cell | `void` |
| `(set-cell! x y table key value)` | Store value in table at key | `void` |
| `(get-cell x y table key)` | Read value in table at key | `value` \| `#f` |
| `(delete-cell! x y table key)` | Remove key from table | `void` |
| `(delete-cell! x y table)` | Remove entire table from cell | `void` |
| `(has? x y table)` | Check if cell has a table with that name | `bool` |
| `(has? x y table key)` | Check if the table has a given key | `bool` |
| `(cell-info x y)` | String representation of a cell | `string` |

### Global Data

The grid itself can store data in the same fashion as a cell, this is useful for storing global data.

| Function | Description | Returns |
|---|---|---|
| `(set-grid! table key value)` | Store value in table at key | void |
| `(get-grid table key)` | Read value in table at key | value \| #f |
| `(delete-grid! table key)` | Remove key from table | void |
| `(delete-grid! table)` | Remove entire table | void |
| `(grid-info)` | String representation of global data | string |

### Reset

| Function | Description | Returns |
|---|---|---|
| `(clear!)` | Reset all cell data and global data | void |

### Operations on Multiple Cells

These functions perform actions on multiple cells. The cells are passed via the `coords` parameter as a set of coordinate pairs `(x y)`. See  [Selecting Cells](#selecting-cells) for how to specify conditions to query the grid for cells.

#### Spatial Queries

| Function | Description | Returns |
|---|---|---|
| `(has-at? coords x y)` | Check if (x, y) is in the coordinate set | bool |
| `(bounds-of coords)` | Bounding box of the coordinate set | (x-min x-max y-min y-max) \| #f |

#### Movement

Multiple cells are moved or copied simultaneously, so overlapping source and destination positions are handled correctly.

| Function | Description | Returns |
|---|---|---|
| `(move-by! coords table dx dy)` | Move the table's data from coordinates by (dx, dy) | void |
| `(move-to! coords table tx ty)` | Move the table's data from coordinates to (tx, ty) | void |
| `(copy-by! coords table dx dy)` | Copy the table's data from coordinates by (dx, dy), keep originals | void |
| `(copy-to! coords table tx ty)` | Copy the table's data from coordinates to (tx, ty), keep originals | void |
| `(delete-cells! coords table)` | Remove the table from all cells with coordinates | void |

### Selecting Cells

#### Coordinate Selectors

Selectors are functions that query the grid for cells that satisfy certain conditions and return a set of (x y) coordinate pairs. They describe which cells to work with, and can be passed to with for iteration or to any operation in [Operations on Multiple Cells](#operations-on-multiple-cells).

| Function | Description | Returns |
|---|---|---|
| `(select table)` | All cells that have a table with that name | set of coords |
| `(select table key)` | Cells where the table has a given key | set of coords |
| `(select table key value)` | Cells where the table's key equals value | set of coords |
| `(select-all)` | Every cell on the grid | set of coords |
| `(select-xy x y)` | A single cell | set of coords |
| `(select-row y)` | All cells in row y | set of coords |
| `(select-column x)` | All cells in column x | set of coords |
| `(select-neighbors x y neighborhood)` | Cells surrounding (x, y) | set of coords |
| `(select-neighbors x y neighborhood r)` | Cells within radius r of (x, y) | set of coords |
| `(select-at deltas x y)` | Cells at specific offsets from (x, y) | set of coords |

Neighborhoods: `'moore`, `'von-neumann`, `'horizontal`, `'vertical`. Default radius `r` = 1.

#### Selector Modifiers

Modifiers take one or more selectors and return a new selector, letting you combine, shift, or narrow coordinate sets through composition.

| Function | Description | Returns |
|---|---|---|
| `(offset coords dx dy)` | Shift all coords by (dx, dy) | set of coords |
| `(union s1 s2 ...)` | Coords in any of the sets | set of coords |
| `(intersection s1 s2 ...)` | Coords in all of the sets | set of coords |
| `(difference s1 s2 ...)` | Coords in s1 but not in s2 | set of coords |
| `(one coords)` | Any single coord from the set | set of coords (0 or 1 element) |
| `(nearest x y coords)` | Closest coord to (x, y) | set of coords (0 or 1 element) |

### Color

Colors are RGBA values with each channel in the range 0.0–1.0. Alpha is optional and defaults to fully opaque.

| Function | Description | Returns |
|---|---|---|
| `(color r g b)` | RGB color, fully opaque; each channel 0.0–1.0 | color vector |
| `(color r g b a)` | RGBA color with alpha | color vector |
| `(with-opacity color opacity)` | Return color with alpha replaced | color vector |

---

## Usage Examples

### Storing Data on Cells

Each cell can hold any number of named **tables**. A table maps keys to values. Multiple `set-cell!` calls accumulate:

```racket
(set-cell! x y 'ball 'dx  1)
(set-cell! x y 'ball 'dy -1)
(get-cell x y 'ball 'dx)           ; → value | #f
(delete-cell! x y 'ball 'dx)       ; remove one key
(delete-cell! x y 'ball)           ; remove whole table
```

A cell can hold multiple tables simultaneously:

```racket
(set-cell! x y 'wall 'strength 1)
(set-cell! x y 'ball 'dx 1)        ; same cell holds both tables
```

---

### Coordinate Selectors

A **selector** is a set of `(x y)` coordinate pairs. Selector functions describe *which cells* to work with; they don't read or write cell data.

**Select by table name** — all cells that have a table with that name:

```racket
(select 'wall)                         ; all wall cells
(select 'ball 'dx)                     ; ball cells that have a 'dx key
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
  (define dx (get-cell ball-x ball-y 'ball 'dx))
  ...)
```

`select-xy` always produces a single-cell selector and is useful for naming a computed position:

```racket
(with (select-xy (+ ball-x dx) (+ ball-y dy)) as (new-x new-y)
  ...)
```

---

### Spatial Queries

`has-at?` checks whether a specific coordinate is in a selector:

```racket
(has-at? (select 'wall) new-x new-y)    ; → #t | #f
```

`bounds-of` returns the bounding box of a selector:

```racket
(bounds-of (select 'paddle))    ; → (x-min x-max y-min y-max) | #f
```

---

### Moving Entities

Movement functions transfer the data stored in a table from a selector to a destination. Only the specified table is affected; other tables at the same cell are untouched.

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
(set-grid! 'player 'score 0)
(get-grid  'player 'score)     ; → value | #f
(delete-grid! 'player 'score)  ; remove one key
(delete-grid! 'player)         ; remove entire table
```

---

### Clearing the Grid

```racket
(clear!)                       ; reset all cell data and global data
(delete-grid! 'player 'score)  ; remove one key from table
(delete-grid! 'player)         ; remove entire table
```

---

### Colors

```racket
(color r g b)             ; RGB, each 0.0–1.0, fully opaque
(color r g b a)           ; RGBA with alpha
(with-opacity c opacity)  ; return copy of color c with new alpha
```

