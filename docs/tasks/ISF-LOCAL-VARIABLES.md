# ISF-LOCAL-VARIABLES: `(local ...)` Declared Internal Variables (and `(let ...)`)

## Metadata

- Tree ID: `ISF-LOCAL-VARIABLES`
- Status: `active`
- Roadmap lane: `R14` (ISF — high-level language richness)
- Created: `2026-06-01`
- Last updated: `2026-06-01`
- Owner: repo-local workflow

## Goal

Give ISF an explicit **local variable** — `(local NAME (width N) [(init V)])` — a
named internal register with an author-chosen width and optional reset value, plus a
`(let NAME EXPR)` named intermediate value. This is the *variables* half of the
high-level-language pair (the *functions* half shipped as `ISF-PROCEDURES`): together
with procedures it lets an author "program in ISF" with named state and reusable
blocks. It is an **ISF (IAL1)** construct — `(local ...)` desugars to a declared
internal signal, `(let ...)` to substitution/sampling — neither raises the abstraction
level (see the `isf-abstraction-layering` memory).

Reads like:

```lisp
(transaction main
  (on start)
  (local sum (width 12) (init 0))   ;; an explicit 12-bit accumulator, reset to 0
  (sample din as s)
  (set sum (+ sum s))
  (complete done))
```

## Ground truth (investigated `2026-06-01`)

- ISF **already** supports *implicit* internal scalars: `(set tmp expr)` /
  `(update tmp expr)` with an undeclared `tmp` lowers — `tmp` is used as a signal
  whose width is **inferred from usage**, and it is NOT emitted in the module `+size`
  block with an explicit width (verified: `(set tmp (+ s 1))` lowers, `tmp` appears in
  assignments but not in `+size`). So the **gap** is an *explicit* declaration that
  pins the width (avoiding inference ambiguity / accidental narrowing) and gives a
  reset/init value and a clear name — not the existence of internal state.
- There is **no** internal-signal declaration keyword today: the actor-clause dispatch
  in `FSM::Adapter::ISF::Parser::_build_actor` handles `clock`/`interface`/`params`/
  `storage`/`constants`/`transaction`/`proc`/… but nothing for a scalar local. Widths
  reach `+size` through the interface/storage finalizers and the lowerer's width
  inference.

## Design

- `(local NAME (width N) [(init V)])` — declares an internal register `NAME` of width
  `N`, optionally reset to `V`. Allowed at the **transaction body** level (and later,
  if useful, at actor level for an actor-wide local). Desugars to a declared internal
  signal: the parser records `{name, width, init}`; the lowerer emits `NAME` in
  `+size` with width `N` and (if `init`) a reset assignment. The transaction body then
  reads/writes `NAME` like any signal (`set`/`update`/expression reads), with the
  width now pinned by the declaration instead of inferred.
- `(let NAME EXPR)` — names an intermediate value. Two clean lowerings: (a) a
  combinational alias — substitute `NAME` → `EXPR` at expansion time (no register), or
  (b) a sampled register — materialize `NAME` as a register assigned `EXPR` once.
  Start with the substitution form (a) (pure desugar, like a one-line inline proc);
  the register form can follow if needed. (`.4`.)
- Fail-closed: a `(local)` whose name collides with an interface port / declared
  signal; a `(set/update)` to a `(local)` outside its scope; an over-width `(init V)`.

## Slice plan

- `.1` select (this doc) — ground truth + design + slice plan.
- `.2` `(local NAME (width N))` declaration (no init) — parse + emit the internal
  register at the declared width; body reads/writes it; golden `.fsm` (`NAME` in
  `+size` at width N) + HDL; collision fail-closed.
- `.3` `(init V)` reset values.
- `.4` `(let NAME EXPR)` named intermediate (substitution form).
- `.5` thorough example-rich mdBook docs (a dedicated section/chapter; per the
  thorough-docs directive) + feature-matrix/doc-truth/ISF_SPEC sync.

## Non-Goals

- Dynamic/resizable arrays (fixed-width registers only; banks are `(storage ...)`).
- Pointers / aliasing beyond `(let ...)` substitution.
- Cross-transaction scope leakage (a transaction-body `(local)` is private to it).

## Acceptance Criteria

- `(local NAME (width N) [(init V)])` declares an internal register at the explicit
  width (emitted in `+size`), readable/writable in the transaction body, with golden
  `.fsm` + HDL evidence; collisions and out-of-range inits fail closed; `(let ...)`
  names an intermediate value; the mdBook documents both with many runnable examples;
  audits pass. Each leaf committed via `COMMIT.md`, shipping its own runnable
  example(s).

## Task Tree

- ID: `ISF-LOCAL-VARIABLES`
  Status: `active`
  Goal: `(local NAME (width N) [(init V)]) declared internal variables + (let NAME EXPR) named intermediates.`
  Children: `.1` (select), `.2` (local decl), `.3` (init), `.4` (let), `.5` (docs)

- ID: `ISF-LOCAL-VARIABLES.1`
  Status: `done`
  Goal: `Select; record ground truth (implicit internals exist; no explicit decl) + design + slice plan.`
  Acceptance: `Task tree committed before any code change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `5a552ef5`

- ID: `ISF-LOCAL-VARIABLES.2`
  Status: `done`
  Goal: `(local NAME (width N)) declares an internal register at an explicit width.`
  Acceptance: `local added to the transaction clause-context allow-list; _build_transaction handles (local NAME (width N)) by registering $ct{NAME}=N (the same width map that feeds +size), so NAME is emitted in +size at the declared width and read/written in the body like any signal (vs. an implicit internal scalar whose width is inferred and omitted from +size). _parse_local_decl validates the width and fails closed on a missing/non-positive width or a collision with an interface port (or an already-declared transaction signal). --check-json + verilator/yosys PASS (same-width arithmetic; the WIDTHEXPAND lint on mixed-width adds is general ISF behavior, not local-specific). 13b gains a declared-internal-variables section + runnable example; 13k row; ISF_SPEC registers t/1391.`
  Verification: `Spike: (local acc (width 8)) -> acc in +size at width 8, set/read works; (local wide (width 12)) keeps 12-bit; collision/missing/zero-width fail closed; --check-json SUCCESS; --verify-hdl verilator_lint+yosys_synthesis PASS. prove -Iperl t/1391 (3 subtests) t/1376 t/1250 t/1305 t/1303 PASS; full ./bin/ci-regression isf --no-book PASS; perl -c; mdbook build; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this doc). |
| 2 | `.2` | `done` | `(local NAME (width N))` declaration — registers the explicit width in the transaction signal map (emitted in `+size`); body reads/writes it; collision/missing/zero-width fail closed. `--check-json` + verilator/yosys PASS. `t/1391`. |
| 3 | `.3` | `pending` | `(init V)` reset values for `(local)`. |
| 4 | `.4`–`.5` | `pending` | `(let NAME EXPR)` named intermediates; thorough docs chapter/section. |

## Decisions

- `2026-06-01`: the *variables* companion to `ISF-PROCEDURES` (functions). Scoped to
  the concrete gap — explicit width/init for internal registers — since *implicit*
  internal scalars already work; `(local)` pins the width and adds a reset value and a
  clear declaration site. `(let ...)` (named intermediates) follows. ISF/IAL1
  (desugars to declared signals / substitution).

## Open Questions

- `.2`: the cleanest place to record + emit the declared width — a parser-level
  internal-signal registry consumed by the lowerer's `+size` emission, vs. seeding the
  existing width-inference map with the declared width. Resolve in `.2`.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-01` | `.1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-06-01` | `.2` | Spike: `(local acc (width 8))` emits `(acc 8)` in `+size`, read/write works; 12-bit local keeps width; collision/missing/zero-width fail closed; `--check-json` + verilator/yosys PASS. `prove -Iperl t/1391` (3 subtests) `t/1376 t/1250 t/1305 t/1303` PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-LOCAL-VARIABLES.1: select declared local variables` | `5a552ef5` |
| `.2` | `ISF-LOCAL-VARIABLES.2: (local NAME (width N)) declared internal register` | `ship commit (this slice)` |

## Changelog

- `2026-06-01`: Created as the *variables* companion to `ISF-PROCEDURES`. Ground
  truth: implicit internal scalars already lower (width inferred, not in `+size`); the
  gap is an explicit `(local NAME (width N) [(init V)])` declaration that pins the
  width + adds a reset value, plus `(let NAME EXPR)` named intermediates. Slice plan:
  `.2` local declaration, `.3` init, `.4` let, `.5` docs.
- `2026-06-01`: `.2` shipped — `(local NAME (width N))` declares an internal register
  at an explicit width. Added `local` to the `transaction` clause-context allow-list;
  `_build_transaction` handles the clause by registering `$ct{NAME}=N` in the same
  width map that feeds the module `+size` block (`_parse_local_decl` validates the
  `(width N)` and fails closed on a missing/non-positive width or a collision with an
  interface port / already-declared signal). The local is then emitted in `+size` at
  the declared width and read/written in the body like any signal — pinning the width
  instead of relying on the inference that an implicit `(set tmp expr)` gets (and which
  is omitted from `+size`). Verified `(local acc (width 8))` → `(acc 8)` in `+size`
  with read/write; a 12-bit local keeps its width; `--check-json` SUCCEEDS and
  `--verify-hdl` passes (verilator_lint + yosys_synthesis) for same-width arithmetic
  (the WIDTHEXPAND lint on mixed-width adds is general ISF behavior, not
  local-specific). Book: `13b` gains a declared-internal-variables section with a
  runnable accumulator example; `13k` row; `docs/ISF_SPEC.md` registers `t/1391`.
