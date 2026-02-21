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

## Introducing the Selector

The central design innovation of this session: a **selector** (constructed by `select`) is a first-class value that *describes* a set of cells without immediately evaluating.
```racket
(select 'ball)                    ; all cells with key 'ball
(select 'ball 'team 1)            ; all balls where team = 1
(select 3 4)                      ; cell at coordinates 3,4
(select 3 4 'ball)                ; ball at 3,4
```

### Implementation
A selector is simply a function from the grid to a **set** of coordinates:
```racket
(select 'ball 'team 1)
; → (lambda (grid) (index-lookup grid 'ball 'team 1))
```

No macro needed — `select` is a plain higher-order function. The declarative feel comes from returning a lambda, not from compile-time magic.

### The Index
The index is the primary data structure for queries — not a cache, not an optimization, but the source of truth for property-based lookups. Every mutation (`set-cell!`, `update!`, `delete!`) maintains the index as a side effect. Selectors query the index exclusively. No scanning ever.

The index structure: `key → property → value → set of (x y)` coordinates. Completely invisible to the user — an implementation detail that makes the whole system fast and predictable.

Because the index stores **sets** of coordinates natively, selector composition is efficient by default:
```racket
(define (select-union s1 s2)
  (lambda (grid)
    (set-union (s1 grid) (s2 grid))))

(define (select-intersection s1 s2)
  (lambda (grid)
    (set-intersection (s1 grid) (s2 grid))))
```

These are not GridCode features — they are plain Racket functions that work for free because selectors are functions returning sets. The capability is there without any additional API surface.

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

- **Coordinates** — where things are: `(select 'ball)` → set of `(x y)`
- **Cells** — what's stored at a location: `(get-cell x y 'ball)` → dictionary/scalar/#t/#f
- **Values** — properties within a dictionary: `(get dict 'dx)` → value

Each level is simple on its own. `with` bridges coordinates to cell data naturally. `get` reads properties from dictionaries. These compose into the full picture.

## Pattern Matching via Selectors
```racket
(select 'enemy)                         ; match by presence
(select 'enemy 'state)                  ; match by property presence
(select 'enemy 'state 'active)          ; match by value
(select 'enemy 'state '(active frozen)) ; match by one of several values
```

Each line is a natural refinement of the previous — no wildcards, no special syntax, just increasing specificity. The fourth form is the only one introducing new syntax, and it reads intuitively: "state is one of active or frozen."

This is pattern matching introduced gradually and concretely, grounded in something the student can see on the grid. A student who learns this will recognize pattern matching when they encounter it later in Elixir, Haskell, or Racket's own `match` — without ever having been intimidated by it.

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

### Multiple Behaviors Per Entity

A cell can match multiple selectors simultaneously:
```racket
(define-behavior (select 'paddle)
  (update ...))                        ; common to all paddles

(define-behavior (select 'paddle 'player 1)
  (update ...))                        ; player 1 specific

(define-behavior (select 'paddle 'powerup 'sticky)
  (update ...))                        ; fires if paddle has sticky powerup
```

All three behaviors fire for a paddle belonging to player 1 with a sticky powerup. There is no ambiguity — behaviors don't override each other, they compose by all executing in the order `update-grid` declares. This is what multiple inheritance tries to achieve but fails at cleanly. Here it requires no special language machinery — it is just multiple selectors matching the same cell.

Adding a new capability to an entity is just adding a property to its dictionary and defining a behavior for the matching selector. No class restructuring, no inheritance chain to reason about.

## GridCode-Flavored ECS

This design is essentially ECS without the jargon:

- **Entity** — a cell at a position, identified by coordinates
- **Component** — the key and its dictionary properties
- **System** — a `define-behavior` attached to a selector

The difference from classical ECS: grid position *is* the entity identity, rather than a generated ID. A meaningful simplification that keeps coordinates at the center.

Unlike OOP, data and behavior remain separate. The paddle doesn't *have* a behavior, it *matches* a behavior. The grid remains a pure data structure; the behavior registry is a separate layer.

## Neighborhood Queries and Game of Life

The selector model extends naturally to neighborhood queries — looping over coordinate deltas using the same coordinate currency:
```racket
(select-neighbors x y)              ; all 8 surrounding cells
(select-neighbors x y 'wall)        ; surrounding cells with 'wall
(select-neighbors x y 4)            ; 4-directional only
```

Inside a `with` loop, these compose naturally:
```racket
(with (select 'cell) as (x y cell)
  (with (select-neighbors x y 'alive) as (nx ny ncell)
    ...))
```

The outer loop gives each cell, the inner loop gives its living neighbors — Game of Life in two nested `with` constructs. The coordinate currency flows naturally from outer to inner.

A more general form:
```racket
(select-at deltas x y)              ; apply a set of coordinate deltas
(select-at deltas x y 'wall)        ; filtered
```

Where `deltas` could be a named constant like `neighbors-8`, `neighbors-4`, or a custom shape.

## User-Defined Selectors

Because a selector is just a function returning a set of coordinates, users can write their own:
```racket
(define (select-column x)
  (lambda (grid)
    (list->set (map (lambda (y) (list x y))
                    (range (grid-height grid))))))

(define (select-row y)
  (lambda (grid)
    (list->set (map (lambda (x) (list x y))
                    (range (grid-width grid))))))
```

Used indistinguishably from built-in selectors:
```racket
(with (select-column 0) as (x y cell)
  (set-cell! x y 'wall))
```

The built-in selectors are not a complete vocabulary — they are a starter kit of the most common patterns. The user extends them naturally using the same Racket they are already learning. The Pong wall example above is a natural first exercise in writing a custom selector.

This is where the user stops being a consumer of the API and starts being a designer of their own abstractions — entirely within the "coordinates as currency" model, composing with everything else for free.

## The Grid as Center

The most important philosophical outcome of this session: GridCode is not a collection of agents that happen to live on a grid — it's **a grid that happens to have things on it**.

Coordinates are the universal currency. `select` returns coordinates. Mutations consume coordinates. Neighborhood queries pass coordinates from outer to inner loops. User-defined selectors produce coordinates. Everything is anchored to the grid's topology.

The visual representation is never just a display layer — it's a direct window into the actual data structure, addressed by the same coordinates the code uses. What you see on the grid *is* the program's state.

Going the StarLogo route would have had the opposite effect: the grid becomes background, a surface agents move over. GridCode's grid *is* the world.

## The Inspector / GOM

The current inspector is essentially hardcoded to `(select x y)` — the simplest possible selector. Generalizing it makes it a proper tool for understanding program state at any moment:

- `(select 3 4)` — highlight a single cell, show its data
- `(select 'ball)` — highlight all balls
- `(select 'enemy 'state 'active)` — highlight active enemies, showing the effect of a pattern match
- `(select 'enemy 'state)` — highlight all enemies regardless of state

Tapping a selector in the iPad editor highlights the matching cells on the grid in real time. This closes the loop between code and visual representation in a way that is rare in programming tools. The student writes `(select 'enemy 'state 'active)` and the grid lights up showing exactly which enemies are active.

Debugging becomes intuitive: "why isn't my behavior firing?" becomes "tap the selector and see what it matches."

This is the **Grid Object Model (GOM)** — analogous to the browser DOM inspector, but for GridCode programs. The selector API and the inspector reinforce each other: learning selectors is learning to query your world, and the inspector makes every query immediately visible.

## Pedagogical Design: Low Floor, High Ceiling

The separation of data and behavior is preserved and intentional. For beginners, it is clear that code operates on data and is different from it. The grid is a data structure; the program is a set of operations on it.

The teaching progression:

- **Beginner:** direct `set-cell!`/`get-cell` with coordinates, simple `with` loops
- **Intermediate:** named selectors, cell dictionaries, `update!`/`delete!`, `with` for iteration
- **Advanced:** `define-behavior` with pattern-matched selectors, user-defined selectors, composition

Each level is genuinely useful on its own. Concepts build on each other honestly. A student learns encapsulation *after* understanding separation — the right order.

One way to do things, with syntax that scales. No beginner API to unlearn later.

## Updated API

### Selection
```racket
(select key)
(select key property)
(select key property value)
(select key property '(value ...))
(select x y)
(select x y key)
(select-neighbors x y)
(select-neighbors x y key)
(select-neighbors x y 4)
(select-at deltas x y)
(select-at deltas x y key)
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

## Emergence Over Engineering

The most telling sign that this design is genuinely coherent is how it arrived at its conclusions.

The session began with a specific goal: encapsulated behavior, entities that know how to act, the Breakout brick that knows what to do when hit. This was consciously set aside to preserve GridCode's identity — the grid as the world, coordinates as the universal currency, data and behavior separated for clarity and teachability.

The selector redesign that followed was motivated by completely independent concerns: a cleaner API, orthogonality, removing overloaded functions, making multi-cell queries first-class. The index was introduced for performance and completeness. `with` emerged to handle iteration and binding cleanly. None of these decisions were made in service of encapsulation.

And yet, at the end, `define-behavior` arrived — attaching behavior to selectors, composing multiple behaviors on a single entity, solving the multiple inheritance problem without inheritance machinery, giving entities the ability to "know how to act" based on what they are and what properties they carry. Exactly what was wanted at the start, but as an emergent property of the design rather than an engineered feature.

This is the difference between a feature and an emergent property. A feature is bolted on to solve a problem. An emergent property falls out of a design that is right for other reasons.

`define-behavior` itself is almost nothing — likely just a macro that registers a selector-function pair in a table that `update-grid` iterates. The heavy lifting is done entirely by `select` and the index. The behavior system is nearly free.

This gives the design a kind of integrity that can be trusted: every part is justified on its own terms, and they happen to compose into something greater. The grid as coordinate-centered world, the index as the query engine, `select` as the universal descriptor, `with` as the iteration primitive, and `define-behavior` as the emergent encapsulation layer — none of these were designed to serve the others, yet together they form a coherent whole.