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

## Ground truth (to confirm in `.1`/`.2`)

- Today registers reset to **0**: the scheduled `.fsm` wires the reset *signal*
  (`(areset NAME)` / `(sreset NAME)` in the emitted module) but carries **no per-register
  reset value**; the downstream `.fsm` → HDL generator (the FSMGen core, `FSM/HDL/…`)
  emits the reset block that clears registers to 0. (Observed while building
  `ISF-LOCAL-VARIABLES.3`: only the reset signal is wired; there is no reset-value
  attribute on `+size` registers.)
- So this feature spans **two layers**: (a) the `.fsm` IR + HDL backend must learn a
  per-register reset value (the core change), and (b) ISF (and any other front end)
  needs surface syntax to specify it.

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
- `.2` `.fsm` IR + HDL backend: per-register reset value emitted in the HDL reset block
  (default 0 unchanged); golden HDL + verilator/yosys evidence; reset-to-0 unchanged
  when unspecified.
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
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this doc). |
| 2 | `.2` | `pending` | `.fsm` IR + HDL backend per-register reset value (default 0) — the load-bearing core change; everything else layers on it. |
| 3 | `.3`–`.5` | `pending` | ISF surface syntax; register-map reset values; docs. |

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

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-REGISTER-RESET-VALUES.1: select arbitrary register reset values` | `ship commit (this slice)` |

## Changelog

- `2026-06-01`: Created at the user's request — a task tree for resetting any register
  to an author-chosen value (not just 0), especially for register maps. Scoped as a
  two-layer feature (the `.fsm`→HDL reset-value flow is the core change; ISF surface
  syntax layers on top), with the default (unspecified) reset value remaining all-0s
  for full backward compatibility. Distinct from `ISF-LOCAL-VARIABLES` `(init V)`
  (init-on-entry). Slice plan: `.2` HDL backend, `.3` ISF surface, `.4` register maps,
  `.5` docs.
