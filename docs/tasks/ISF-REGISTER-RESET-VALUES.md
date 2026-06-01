# ISF-REGISTER-RESET-VALUES: Arbitrary (Non-Zero) Register Reset Values

## Metadata

- Tree ID: `ISF-REGISTER-RESET-VALUES`
- Status: `active`
- Roadmap lane: `R14` (ISF — high-level language richness / HDL flow)
- Created: `2026-06-01`
- Last updated: `2026-06-01`
- Owner: repo-local workflow

## Goal

Let **any register reset to an author-chosen value**, not just all-zeros — on the
hardware reset (`areset`/`sreset`), so the value is the state the design powers up in.
This is especially useful for **register maps** (control/status registers that must
power up at a specified default — enables, mode fields, magic numbers, etc.).

**Default behavior is unchanged: when no reset value is specified, a register resets to
all-0s** (user constraint, 2026-06-01). Explicit non-zero reset values are opt-in and
fully backward-compatible.

This is distinct from `ISF-LOCAL-VARIABLES` `(init V)`: that is an ISF-level
*init-on-transaction-entry* (a transaction-local re-initialized each run, lowered as a
`set` state). This tree is the deeper **`.fsm` → HDL reset-value flow** — the value a
register holds out of hardware reset, emitted in the HDL reset block.

## Ground truth (investigated `2026-06-01`, deep trace through the stack)

The HDL backend **already consumes** a per-register reset value — the hard part is
done. The gap is the *carrier* (a `.fsm` syntax + AST population) and the ISF *surface*.
Precise findings:

- **HDL emission — DONE.** The data-flop reset is emitted in
  `FSM/Synthesis/EnableGraph/AssignmentSupport.pm` (~L974/L1014): it calls
  `normalize_reset_literal_for_width(get_reset_value_from_ast($lhs_ast), width)` and
  emits `<sig> <= <reset_value>` in the `always_ff` reset branch (verified: a data
  register `q` emits `q <= 8'h00`). `get_reset_value_from_ast`
  (`FSM/Synthesis/EnableGraph/SignalSupport.pm` ~L314) already reads a reset value from
  the LHS AST three ways: `$lhs_ast->reset_value()`, `$signal->get_attribute('reset_value')`,
  and `$signal->attributes->{reset_value}`, falling back to `get_reset_value` (which
  defaults to 0). `FSM/IR/LoweredRTLIRBuilder.pm` (~L182) records `reset_value` per
  signal. So a non-zero value flows all the way to HDL **if the signal carries it**.
- **CoreAST carrier — EXISTS.** `FSM::CoreAST` has `set_attribute`/`get_attribute`
  (~L64/L73), so a signal *can* carry a `reset_value` attribute; `signal_info` reserves
  a `reset_value` field (`FSM/HDL/FlattenedDT.pm` ~L100).
- **Missing — the `.fsm` text syntax + parser population.** There is **no** `.fsm`
  syntax for a register reset value today (the `+size` form is `(name width)`; the
  `.fsm` AST parser, `FSM/AST/`, does not populate `reset_value`). So the consumption
  path is currently *unfed*.
- **Net:** this is NOT a quick ISF desugar (unlike the loop-exit/procedures/locals
  constructs). It is a focused **multi-layer core slice**: (1) a `.fsm` carrier syntax
  (e.g. extend `+size` to `(name width reset_value)` or add a `+reset` block) + the
  `.fsm` AST parser calling `set_attribute('reset_value', V)` on the signal; (2) the ISF
  lowerer emitting that carrier from an ISF surface; (3) the HDL backend then emits it
  for free. Default unspecified stays all-0s (already the fallback).

## Design (initial — refine in `.1`)

- **`.fsm` IR + HDL backend (the core):** add an optional per-register reset value to
  the register/`+size` model (e.g. a `(+reset (NAME VALUE) ...)` block, or a reset-value
  attribute alongside the width). The HDL reset block assigns each register its reset
  value, defaulting to `0` when none is given. Width-check the value against the
  register width. This is the load-bearing change and must keep all existing
  reset-to-0 behavior byte-identical when no value is specified.
- **ISF surface syntax:** a reset value on a declaration — e.g.
  `(local NAME (width N) (reset V))` for a local, and a way to set the reset value of
  an interface output / storage register / **register-map field**. For register maps
  specifically, scope a `(register-map ...)` / CSR declaration (or per-field reset
  values on an existing register-map construct if one exists) — investigate what ISF
  exposes for register maps today in `.1`.
- **Fail-closed:** a reset value wider than the register; a reset value on a signal that
  is not a register (e.g. a pure combinational wire / input port).

## Slice plan

- `.1` select (this doc) — ground truth (exact `.fsm`→HDL reset emission point; what
  ISF exposes for register maps today) + design + slice plan.
- `.2` `.fsm` **carrier**: a `.fsm` syntax for a register reset value (extend the
  `+size` entry to `(name width reset_value)` or add a `+reset` block) + the `.fsm` AST
  parser (`FSM/AST/`) calling `set_attribute('reset_value', V)` on the signal so the
  already-built HDL consumption path emits it. Golden HDL + verilator/yosys evidence;
  reset-to-0 byte-identical when unspecified. (The HDL reset-block emission is already
  implemented — see Ground truth — so `.2` is the carrier, not the emitter.)
- `.3` ISF surface syntax for a single register's reset value (e.g.
  `(local NAME (width N) (reset V))` and/or an interface/storage reset value).
- `.4` register-map application — reset values for register-map / CSR fields.
- `.5` thorough example-rich mdBook docs + feature-matrix/doc-truth/ISF_SPEC sync.

## Non-Goals

- Changing the default (unspecified → all-0s stays the default).
- Runtime-programmable reset values (the reset value is an elaboration-time constant).
- Reset of non-register signals.

## Acceptance Criteria

- A register can be declared with an explicit reset value and powers up at that value in
  the generated HDL (verilator/yosys evidence); unspecified reset values stay all-0s,
  byte-identical to today; over-width / non-register reset values fail closed; register
  maps can set per-field reset values; the mdBook documents it with runnable examples;
  audits pass. Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-REGISTER-RESET-VALUES`
  Status: `active`
  Goal: `Arbitrary (non-zero) per-register reset values through the .fsm -> HDL flow; default unspecified = all-0s; useful for register maps.`
  Children: `.1` (select), `.2` (.fsm/HDL backend), `.3` (ISF surface), `.4` (register maps), `.5` (docs)

- ID: `ISF-REGISTER-RESET-VALUES.1`
  Status: `done`
  Goal: `Select; scope arbitrary register reset values (default 0) + the two-layer (.fsm/HDL + ISF surface) design + slice plan.`
  Acceptance: `Task tree committed before any code change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `2701a7d0`

- ID: `ISF-REGISTER-RESET-VALUES.2`
  Status: `done`
  Goal: `.fsm carrier — a (reset V) marker on a +size register sets its hardware reset value; HDL backend (already done) emits it.`
  Acceptance: `FSMGenFull::Parser::parse_size_section accepts an optional (reset V) marker inside a +size entry's width field — (signal width (reset V)) — splits it out (unambiguous vs width expressions, whose head is an arithmetic/bitwise operator) and registers the signal with attributes => { reset_value => V }; the already-implemented HDL consumption (get_reset_value_from_ast -> attributes->{reset_value}) then emits <sig> <= V in the always_ff reset branch. Default unspecified stays all-0s, byte-identical. A non-integer reset value fails closed. Verified at the .fsm level (hand-written .fsm): (q 8 (reset 5)) -> q <= 5; (q 8) -> q <= 8'h00; verilator/yosys PASS. t/1392. The ISF surface (a (reset V) on an ISF declaration) is .3 — until then this carrier is internal, so no user-facing mdBook yet.`
  Verification: `Hand-written .fsm spike: (q 8 (reset 5)) emits q <= 5 (verilator_lint+yosys_synthesis PASS); (q 8) emits q <= 8'h00 (unchanged); non-integer reset fails closed. prove -Iperl t/1392 (3 subtests) PASS; perl -c; full ./bin/ci-regression full --no-book PASS (core parser change). NOTE: the FULL suite is the gate (core .fsm parser change), not the isf subset.`
  Commit: `ship commit (this slice)`

- ID: `ISF-REGISTER-RESET-VALUES.3`
  Status: `done`
  Goal: `ISF surface — (local NAME (width N) (reset V)) sets a register's hardware reset value, emitting the .fsm (reset V) carrier.`
  Acceptance: `_parse_local_decl parses an optional (reset V) (non-negative integer fitting the width; orthogonal to (default V)/(init V)); the per-register reset value is threaded from _build_transaction (a %reset_values map, 10th return value) through both module builders (_build_child_ir/_build_parent_ir) into the module IR (reset_values), and Emitter/FSM.pm::_emit_size emits (NAME width (reset V)) in +size. The .2 carrier + HDL backend then power the register up at V. Unspecified resets to all-0s, byte-identical. An over-width or non-integer reset value fails closed. t/1397; 13m documents (reset V).`
  Verification: `(local acc (width 8) (reset 5)) -> +size (acc 8 (reset 5)) -> HDL acc <= 5 (verilator_lint+yosys_synthesis PASS); without (reset V) -> acc <= 8'b0 (unchanged); (reset 5)+(default 3) orthogonal (reset carrier + init-on-entry set); over-width/non-integer fail closed. prove -Iperl t/1397 (5 subtests) + doc gates PASS; full suite PASS; perl -c; mdbook build; git diff --check.`
  Commit: `this slice`

- ID: `ISF-REGISTER-RESET-VALUES.4`
  Status: `done`
  Goal: `Register maps — reset values on actor-owned storage var (CSR) fields: (storage (var NAME (width N) (reset V))).`
  Acceptance: `The ISF parser accepts an optional (reset V) on a storage var (non-negative integer fitting a literal width; preserved across the storage finalizer's signal rebuild via the entry); _declared_storage_reset_values collects them and both module builders merge them into the module IR reset_values, so _emit_size emits (NAME width (reset V)) for the storage signal. A per-element bank (reset V) and an over-width/non-integer reset value fail closed. Unspecified storage resets to all-0s. ISF has no dedicated register-map construct, so storage vars ARE the register-map representation. t/1398; 13a + 13k document it.`
  Verification: `(storage (var mode (width 8) (reset 1)) (var flags (width 8) (reset 255)) (var scratch (width 8))) -> +size (mode 8 (reset 1)) / (flags 8 (reset 255)) / (scratch 8); HDL mode <= 1, flags <= 255, scratch <= 0 (verilator_lint+yosys_synthesis PASS); bank (reset V) / over-width / non-integer fail closed. prove -Iperl t/1398 (3 subtests) + doc gates PASS; full suite PASS; perl -c; mdbook build; git diff --check.`
  Commit: `this slice`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this doc). |
| 2 | `.2` | `done` | `.fsm` **carrier** — `(signal width (reset V))` in `+size` sets the register's hardware reset value (carried as a signal attribute the HDL backend already consumes); default unspecified stays all-0s (byte-identical); non-integer fails closed. verilator/yosys PASS. `t/1392`. |
| 3 | `.3` | `done` | ISF surface — `(local NAME (width N) (reset V))` emits the `+size (reset V)` carrier (threaded module-IR `reset_values` → `_emit_size`); HDL powers up at V; unspecified → all-0s; over-width/non-integer fail closed. `t/1397`; `13m` docs. |
| 4 | `.4` | `done` | Register maps — `(storage (var NAME (width N) (reset V)))` CSR field reset values (ISF has no dedicated register-map construct, so storage vars are the representation); carried across the storage finalizer + merged into the module-IR `reset_values`. `t/1398`; `13a`/`13k` docs. |
| 5 | `.5` | `pending` | A complete runnable register-map example in the mdBook (gated) + final doc-truth sync. |

## Decisions

- `2026-06-01` (user request): log this as its own tree because it is a deeper
  `.fsm`→HDL-flow feature (the value a register holds out of hardware reset), distinct
  from the ISF-level `(init V)` init-on-entry shipped by `ISF-LOCAL-VARIABLES.3`. The
  motivating use case is **register maps** (CSRs with specified power-up defaults).
- `2026-06-01` (user constraint): the **default reset value is all-0s** when
  unspecified — the feature must be fully backward-compatible (existing designs
  unchanged) and only apply an explicit value when given.

## Open Questions

- `.1`/`.2`: the exact point in the `.fsm` → HDL generator where the reset block is
  emitted, and the cleanest `.fsm` IR carrier for a per-register reset value (a
  `(+reset ...)` block vs. a reset-value field on the register model).
- `.3`/`.4`: what ISF exposes for register maps today, and the surface syntax for a
  reset value on an interface output / storage register / register-map field.

## Blockers

- None (independent of the in-flight ISF construct work).

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-01` | `.1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-06-01` | `.2` | Hand-written `.fsm`: `(q 8 (reset 5))` -> `q <= 5` (verilator_lint+yosys_synthesis PASS); `(q 8)` -> `q <= 8'h00` (unchanged); non-integer reset fails closed. `prove -Iperl t/1392` (3 subtests) PASS; `perl -c`; full `./bin/ci-regression full --no-book` PASS | `PASS` |
| `2026-06-01` | `.3` | ISF `(local acc (width 8) (reset 5))` -> `+size (acc 8 (reset 5))` -> HDL `acc <= 5` (verilator_lint+yosys_synthesis PASS); no `(reset V)` -> `acc <= 8'b0` (unchanged); `(reset 5)`+`(default 3)` orthogonal; over-width/non-integer fail closed. `prove -Iperl t/1397` (5 subtests) + doc gates PASS; full suite PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |
| `2026-06-01` | `.4` | `(storage (var mode (width 8) (reset 1)) (var flags (width 8) (reset 255)) (var scratch (width 8)))` -> `+size` carriers -> HDL `mode <= 1`, `flags <= 255`, `scratch <= 0` (verilator_lint+yosys_synthesis PASS); bank `(reset V)` / over-width / non-integer fail closed. `prove -Iperl t/1398` (3 subtests) + doc gates PASS; full suite PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-REGISTER-RESET-VALUES.1: select arbitrary register reset values` | `2701a7d0` |
| `.2` | `ISF-REGISTER-RESET-VALUES.2: .fsm (reset V) carrier for per-register reset values` | committed |
| `.3` | `ISF-REGISTER-RESET-VALUES.3: ISF (local … (reset V)) surface for register reset values` | committed |
| `.4` | `ISF-REGISTER-RESET-VALUES.4: storage var (reset V) for register-map / CSR fields` | this slice |

## Changelog

- `2026-06-01`: Created at the user's request — a task tree for resetting any register
  to an author-chosen value (not just 0), especially for register maps. Scoped as a
  two-layer feature (the `.fsm`→HDL reset-value flow is the core change; ISF surface
  syntax layers on top), with the default (unspecified) reset value remaining all-0s
  for full backward compatibility. Distinct from `ISF-LOCAL-VARIABLES` `(init V)`
  (init-on-entry). Slice plan: `.2` HDL backend, `.3` ISF surface, `.4` register maps,
  `.5` docs.
- `2026-06-01`: deep-traced the stack before implementing `.2`. Key finding — the HDL
  backend **already consumes** a per-register reset value end-to-end
  (`AssignmentSupport.pm` emits `<sig> <= <reset_value>` via
  `get_reset_value_from_ast`, `SignalSupport.pm`; `LoweredRTLIRBuilder` records it;
  `CoreAST` has `set_attribute`/`get_attribute`; `signal_info` reserves `reset_value`).
  The only gap is the **carrier**: there is no `.fsm` text syntax for a register reset
  value and the `.fsm` AST parser does not populate the `reset_value` attribute, so the
  consumption path is unfed. So `.2` is a focused **multi-layer core slice** (`.fsm`
  carrier syntax + AST-parser population + ISF emission) rather than a quick desugar;
  the HDL emission comes for free once the signal carries the value. Default unspecified
  stays all-0s (the existing fallback). Updated `.2` scope accordingly.
- `2026-06-01`: `.2` shipped — the `.fsm` carrier. `FSMGenFull::Parser::parse_size_section`
  now accepts an optional `(reset V)` marker inside a `+size` entry's width field —
  `(signal width (reset V))` — splits it out (unambiguous against width expressions,
  whose head is always an arithmetic/bitwise operator, never `reset`), and registers
  the signal with `attributes => { reset_value => V }`. The already-implemented HDL
  consumption path (`get_reset_value_from_ast` → `attributes->{reset_value}`) then emits
  `<sig> <= V` in the `always_ff` reset branch. Verified at the `.fsm` level:
  `(q 8 (reset 5))` → `q <= 5` (verilator_lint + yosys_synthesis PASS); a plain `(q 8)`
  → `q <= 8'h00` byte-identical (fully backward-compatible); a non-integer reset value
  fails closed. `t/1392` locks it. Because this changes the **core** `.fsm` parser
  (affecting all `.fsm` files, not just ISF), the FULL `ci-regression` suite is the gate
  (not the `isf` subset). The ISF surface (a `(reset V)` on an ISF declaration, e.g.
  `(local NAME (width N) (reset V))`) is `.3`; until then the carrier is internal, so no
  user-facing mdBook yet.
- `2026-06-01`: `.3` shipped — the **ISF surface**. `(local NAME (width N) (reset V))`
  sets a register's hardware reset value. `_parse_local_decl` parses an optional
  `(reset V)` (non-negative integer fitting the width; orthogonal to the init-on-entry
  `(default V)`/`(init V)`); the per-register reset value is threaded from
  `_build_transaction` (a `%reset_values` map, added as the 10th return value) through both
  module builders (`_build_child_ir`, `_build_parent_ir`) into the module IR
  (`reset_values`), and `Emitter/FSM.pm::_emit_size` emits `(NAME width (reset V))` in
  `+size`. The `.2` carrier + the already-built HDL backend then power the register up at V.
  Verified end-to-end: `(local acc (width 8) (reset 5))` → `+size (acc 8 (reset 5))` → HDL
  `acc <= 5` (verilator + yosys PASS); without `(reset V)` → `acc <= 8'b0` byte-identical;
  `(reset 5)` + `(default 3)` are orthogonal (power-up value + init-on-entry set); an
  over-width or non-integer reset value fails closed. `t/1397`; `13m` documents `(reset V)`.
  `.4` (register-map / CSR field reset values) and `.5` (thorough docs) remain.
- `2026-06-01`: `.4` shipped — **register maps**. ISF has no dedicated register-map/CSR
  construct, so actor-owned storage `var`s ARE the register-map representation; a `var` now
  takes an optional `(reset V)`: `(storage (var ctrl (width 8) (reset 1)) …)`. The ISF
  parser parses `(reset V)` (non-negative integer fitting a literal width; rejecting a
  per-element bank reset), stores it on the storage entry, and preserves it across the
  storage finalizer's var-signal rebuild; `_declared_storage_reset_values` collects the
  storage resets and both module builders merge them into the module IR `reset_values`, so
  `_emit_size` emits `(NAME width (reset V))`. Verified end-to-end: a three-register CSR
  block → `+size` carriers → HDL `ctrl <= 1` / `flags <= 255` / `scratch <= 0`
  (verilator + yosys PASS); a bank `(reset V)`, an over-width, and a non-integer reset value
  fail closed. `t/1398`; `13a` gains a "Storage reset values — register maps / CSRs" section
  and `13k` updates the storage row. `.5` (a complete runnable register-map example in the
  book + final doc-truth sync) remains.
