# GridCode Selection Design Session
*February 2026*

## Starting Point: An Itch About Encapsulation

The session began with a concern about GridCode's current design: does the separation of data and behavior miss something essential? Systems like StarLogo and even Erlang have a tangible elegance that comes from encapsulating logic with data — the Breakout brick knowing how to behave when hit, agents carrying their own update and display functions.

The question was whether GridCode should move toward an agent-based model, closer to the original vision of an "agent construction kit."

## Two Approaches Considered

### Current Approach: Centralized Logic
The grid holds data. Top-level functions (`setup-grid`, `update-grid`, `color-for-cell`, `handle-...`) pattern-match on cell types and dispatch behavior. Logic lives outside the cell.

**Appeal:** Simple, uniform, functional. One place to look for all behavior. The grid is a pure data structure.

### Encapsulated Behavior: Agent Approach
Cells store their own update, display, and input-handler functions. Each entity is self-contained and composable.

**Appeal:** Expressive, tangible, closer to StarLogo and Scratch. Dropping a new entity type in doesn't require touching central dispatch logic.

## The Resolution: Behavior Registry / ECS

Rather than storing functions in cells, the cleaner path is storing a **type tag** in the cell dictionary and maintaining a **behavior registry** mapping tags to handler functions. This gives the *feel* of encapsulated behavior while keeping logic in visible, named, top-level definitions.

`update-grid` becomes a **conductor** — it decides update order, handles cross-entity interactions, and manages global state. Explicit update ordering is a feature, not a limitation: it's where the designer expresses how the world ticks.

## The Problem with the Current API

This discussion revealed a deeper issue: the current API was convoluted. `get-cell` and `set-cell!` were overloaded to handle presence, scalars, and dictionaries through argument count. Querying cells by property required manual loops. There was no clean way to express "all enemies with state active."

Furthermore, `move-cells!` operated on a key, moving all cells with that key together — fine for sprites, but breaking down for multiple independent instances of the same type (e.g. two balls with different velocities).

**Key insight:** `move-cells!` was designed to solve the *sprite* problem (rigid multi-cell shapes moving as a unit), not to be the general way of moving cells. These are genuinely different concepts and should be treated differently.

## Introducing the Descriptor / Selector

The central design innovation of this session: a **selector** (constructed by `select`) is a first-class value that *describes* a set of cells without immediately evaluating.
```racket
(select 'ball)                    ; all cells with key 'ball
(select 'ball 'team 1)            ; all balls where team = 1
(select 3 4)                      ; cell at coordinates 3,4
(select 3 4 'ball)                ; ball at 3,4
```

### Implementation
A selector is simply a function from the grid to a list of coordinates:
```racket
(select 'ball 'team 1)
; → (lambda (grid) (index-lookup grid 'ball 'team 1))
```

No macro needed — `select` is a plain higher-order function. The declarative feel comes from returning a lambda, not from compile-time magic.

### The Index
The index is the primary data structure for queries — not a cache, not an optimization, but the source of truth for property-based lookups. Every mutation (`set-cell!`, `update!`, `delete!`) maintains the index as a side effect. Selectors query the index exclusively. No scanning ever.

The index structure: `key → property → value → set of (x y)` coordinates. Completely invisible to the user — an implementation detail that makes the whole system fast and predictable.

### Selectors as First-Class Values
Because a selector is just a value, it can be named:
```racket
(define active-enemies (select 'enemy 'state 'active))
```

The name is documentation for free. And if criteria change, you update one place. This also teaches a fundamental programming concept: give names to things you refer to repeatedly.

## The `with` Construct

`with` is GridCode's primary iteration construct, bridging selectors to cell data:
```racket
(with (select 'ball) as (x y cell)
  (define dx (get cell 'dx))
  (define dy (get cell 'dy))
  ...)
```

### Key properties:
- Bindings are **explicitly named** by the user — no magic implicit variables
- Handles **all cardinalities** implicitly: one match executes once, many executes many times, none skips entirely
- Replaces `get-any-cell`, `get-all-cells`, `for-each`, and `map` for the common case
- Nesting is unambiguous because bindings are named:
```racket
(with (select 'ball) as (bx by ball-cell)
  (with (select 'brick) as (rx ry brick-cell)
    ...))
```

`with-any` remains for the case where only one match is needed, but the key insight is that with `with` handling all cardinalities, the distinction between single and multiple cells largely disappears.

## Three Levels of Selection

The API now has three distinct, orthogonal levels:

- **Coordinates** — where things are: `(select 'ball)` → `((x y) ...)`
- **Cells** — what's stored at a location: `(get-cell x y 'ball)` → dictionary/scalar/#t/#f
- **Values** — properties within a dictionary: `(get dict 'dx)` → value

Each level is simple on its own. `with` bridges coordinates to cell data naturally. `get` reads properties from dictionaries. These compose into the full picture.

## Encapsulation via `define-behavior`

Behavior attaches to a selector, not a hardcoded type name:
```racket
(define-behavior (select 'enemy 'state 'active)
  (update ...))

(define-behavior (select 'enemy 'state 'frozen)
  (update ...))
```

Different behaviors for the same entity type based on state — without conditionals inside the update function. The selector *is* the condition. This is analogous to pattern matching in function signatures in Elixir: behavior is a rule that applies to a description.

`update-grid` orchestrates behavior execution order explicitly, which remains a feature — the designer controls how the world ticks.

## Pattern Matching as a Teaching Concept

The selector syntax introduces pattern matching gradually and concretely:
```racket
(select 'enemy)                        ; match by presence
(select 'enemy 'state 'active)         ; match by value
(select 'enemy 'state _)               ; wildcard
(select 'enemy 'state '(active frozen)); match one of several
```

Each step introduces a more powerful matching concept, grounded in something the student can see spatially on the grid. A student who learns this will recognize pattern matching when they encounter it in Elixir, Haskell, or Racket's `match` — without ever having been intimidated by it.

## Pedagogical Design: Low Floor, High Ceiling

The separation of data and behavior is preserved and intentional. For beginners, it is clear that code operates on data and is different from it. The grid is a data structure; the program is a set of operations on it. This maps visually to the editor: grid panel = data, code panel = operations.

The teaching progression:
- **Beginner:** direct `set-cell!`/`get-cell` with coordinates, simple `with` loops
- **Intermediate:** named selectors, cell dictionaries, `update!`/`delete!`
- **Advanced:** `define-behavior` with pattern-matched selectors, indexed queries

Each level is genuinely useful on its own. Concepts build on each other honestly. A student learns encapsulation *after* understanding separation — the right order.

Crucially: **one way to do things**, with syntax that scales. No beginner API to unlearn later.

## The Grid as Center

The most important philosophical outcome of this session: GridCode is not a collection of agents that happen to live on a grid — it's **a grid that happens to have things on it**.

Coordinates are the universal currency. `select` returns coordinates. Mutations consume coordinates. Everything is anchored to the grid's topology. The visual representation is never just a display layer — it's a direct window into the actual data structure addressed by the same coordinates the code uses.

Going the StarLogo route would have had the opposite effect: the grid becomes background, a surface agents move over. GridCode's grid *is* the world.

## The Inspector / GOM

The current inspector is essentially hardcoded to `(select x y)` — the simplest possible selector. Generalizing it makes it a proper tool:

- Tap any selector in the code → matching cells highlight on the grid
- Works for any selector, from simple key presence to pattern-matched properties
- Makes abstract selector concepts concrete and visible
- Turns debugging into "tap the selector, see what matches"

This is the **Grid Object Model (GOM)** — analogous to the browser DOM inspector, but for GridCode programs. The selector API and the inspector reinforce each other: learning selectors is learning to query your world, and the inspector makes every query immediately visible.

## Updated API

### Selection
```racket
(select key)
(select key property)
(select key property value)
(select x y)
(select x y key)
```

### Iteration & Binding
```racket
(with selector as (x y cell) body ...)
(with-any selector as (x y cell) body ...)
```

### Cell Data
```racket
(get-cell x y key)          ; → dictionary | scalar | #t | #f
(get dict property)         ; → value | #f
```

### Mutation
```racket
(set-cell! x y key)
(set-cell! x y key value)
(set-cell! x y key property value)
(delete-cell! x y key)
(delete-cell! x y key property)
(update! selector property value)
(delete! selector)
```

### Global Data
```racket
(set-grid! key value)
(get-grid key)
(delete-grid! key)
```

### Grid-Wide
```racket
(clear!)
(clear! keys)
```

### Behavior
```racket
(define-behavior selector
  (update body ...))
```

### Movement & Collision
```racket
(move-cells! key dx dy)
(collides? key1 key2)
(collides-at? key dx dy other-key)
(bounds key)
```

## What Was Removed
Compared to the old API, the following are gone — replaced by `with` and selector-based mutation:
- `get-any-cell`
- `get-all-cells`
- `delete-all!`

The API is smaller, more orthogonal, and more composable. Four core concepts — `select`, `with`, `get`, mutate — cover everything the old API required many special-purpose functions to handle.