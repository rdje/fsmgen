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
  Commit: `5a4388fb`

- ID: `ISF-LOCAL-VARIABLES.3`
  Status: `done`
  Goal: `(local NAME (width N) (default V)) initial values.`
  Acceptance: `_parse_local_decl parses an optional (default V) / (init V) (a non-negative integer literal that fits in the width; out-of-range or non-integer fails closed); the local handler in _build_transaction materializes the init as a set-to-V state on transaction entry (a transaction-local is re-initialized each run, like a software local). --check-json + verilator/yosys PASS. 13b gains an init example; 13k row updated; t/1391 gains init + init-fail-closed subtests.`
  Verification: `Spike: (local acc (width 8) (default 0)) emits (acc 0) set on entry; init-too-wide / non-int fail closed; --check-json SUCCESS; --verify-hdl PASS. prove -Iperl t/1391 (5 subtests) t/1376 t/1305 PASS; full ./bin/ci-regression isf --no-book PASS; perl -c; mdbook build; git diff --check`
  Commit: `ship commit (.3)`

- ID: `ISF-LOCAL-VARIABLES.4`
  Status: `done`
  Goal: `(let NAME EXPR) named intermediate values (pure substitution).`
  Acceptance: `A parse-time pass (_expand_let_bindings in FSM::Adapter::ISF::Parser, run BEFORE procedure expansion so let-bound names reach (call) actuals already substituted) substitutes NAME -> EXPR in the rest of the enclosing body; nested bodies (when/switch/while/until/repeat) inherit the scope and may shadow it; the (let) clause emits nothing (no register, no cycle). Reuses the proc substitution helper (_substitute_proc_body). Fails closed on redefining an already-bound name or a name colliding with an interface port. --check-json + verilator/yosys PASS. 13b gains a (let) section; 13k row; t/1391 gains a (let) positive subtest + redefine/port-collision fail-closed subtests.`
  Verification: `Spike: (let sum (+ av bv)) substitutes into (update result (+ sum 1)) -> (+ (+ av bv) 1) with NO sum register; redefine + port-collision fail closed; --check-json SUCCESS; --verify-hdl PASS. prove -Iperl t/1391 (7 subtests) t/1376 t/1305 PASS; full ./bin/ci-regression isf --no-book PASS; perl -c; mdbook build; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this doc). |
| 2 | `.2` | `done` | `(local NAME (width N))` declaration — registers the explicit width in the transaction signal map (emitted in `+size`); body reads/writes it; collision/missing/zero-width fail closed. `--check-json` + verilator/yosys PASS. `t/1391`. |
| 3 | `.3` | `done` | `(default V)` initial values (synonym `(init V)`) — a transaction-local is re-initialized each run (init-on-entry set); out-of-range/non-integer init fails closed. `--check-json`+verilator/yosys PASS. `t/1391`. |
| 4 | `.4` | `done` | `(let NAME EXPR)` named intermediates — pure substitution (NAME→EXPR in the rest of the scoped body; no register), redefine/port-collision fail closed. `--check-json`+verilator/yosys PASS. `t/1391`. |
| 5 | `.5` | `pending` | thorough docs chapter/section. |

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
| `2026-06-01` | `.3` | Spike: `(local acc (width 8) (default 0))` emits `(acc 0)` set on entry; init-too-wide / non-int fail closed; `--check-json` + verilator/yosys PASS. `prove -Iperl t/1391` (5 subtests) `t/1376 t/1305` PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |
| `2026-06-01` | `.2` | Spike: `(local acc (width 8))` emits `(acc 8)` in `+size`, read/write works; 12-bit local keeps width; collision/missing/zero-width fail closed; `--check-json` + verilator/yosys PASS. `prove -Iperl t/1391` (3 subtests) `t/1376 t/1250 t/1305 t/1303` PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-LOCAL-VARIABLES.1: select declared local variables` | `5a552ef5` |
| `.2` | `ISF-LOCAL-VARIABLES.2: (local NAME (width N)) declared internal register` | `5a4388fb` |
| `.3` | `ISF-LOCAL-VARIABLES.3: (local ... (init V)) initial values` | `ship commit (this slice)` |

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
- `2026-06-01`: `.3` shipped — `(local NAME (width N) (default V))` initial values.
  `_parse_local_decl` parses an optional `(default V)` / `(init V)` (a non-negative integer literal
  that must fit in the width; an out-of-range or non-integer init fails closed), and
  the `local` handler in `_build_transaction` materializes it as a set-to-`V` state on
  transaction entry — a transaction-local is re-initialized each time the transaction
  runs (like a software local variable). NOTE: this is an ISF-level init-on-entry, not
  a hardware reset value; arbitrary *hardware reset* values (registers resetting to a
  non-zero value on areset, e.g. for register maps) are a separate, deeper
  `.fsm`→HDL-flow feature tracked by `ISF-REGISTER-RESET-VALUES`. Verified
  `(local acc (width 8) (default 0))` emits the entry set; `--check-json` SUCCEEDS and
  `--verify-hdl` passes (verilator_lint + yosys_synthesis). Book: `13b` gains an init
  example; `13k` row updated; `t/1391` gains init + init-fail-closed subtests (5
  subtests).
- `2026-06-01`: `.4` shipped — `(let NAME EXPR)` named intermediates. A parse-time pass
  `_expand_let_bindings` (`FSM::Adapter::ISF::Parser`, run BEFORE procedure expansion so
  a let-bound name reaches `(call ...)` actuals already substituted) substitutes
  `NAME` → `EXPR` in the rest of the enclosing body; nested bodies
  (`when`/`switch`/`while`/`until`/`repeat`) inherit the let scope and may shadow it,
  and the `(let)` clause itself emits nothing — a pure desugar with no register and no
  extra cycle (it reuses the procedure substitution helper `_substitute_proc_body`).
  Fails closed on redefining an already-bound name or a name that collides with an
  interface port. Verified `(let sum (+ av bv))` substitutes into
  `(update result (+ sum 1))` → `(+ (+ av bv) 1)` with no `sum` register; `--check-json`
  SUCCEEDS and `--verify-hdl` passes (verilator_lint + yosys_synthesis). Book: `13b`
  gains a `(let ...)` section; `13k` row updated; `t/1391` gains a `(let)` positive
  subtest plus redefine and port-collision fail-closed subtests (7 subtests).
