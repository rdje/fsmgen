# ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING: Cross-Domain `(do)`/`(spawn)` Through a Declared Activation Crossing

## Metadata

- Tree ID: `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING`
- Status: `active`
- Roadmap lane: `R14` (ISF Multi-Clock And CDC Semantics — richer crossing primitives)
- Created: `2026-05-30`
- Last updated: `2026-05-30`
- Owner: repo-local workflow

## Goal

Allow a blocking cross-domain `(do child)` (and `(spawn child as inst)`) — where
`child` runs in a different clock domain than the calling transaction — to lower
through a **declared crossing** that owns the activation start/done handshake,
with correct CDC synchronization. Today this fails closed: `ISF clock-domain
violation: ... do target '<child>' references transaction in domain '<d>' from
domain '<o>' without a crossing primitive`.

User-selected direction (`2026-05-30`): "cross-domain activation via a declared
crossing", reusing the shipped acknowledged-event CDC child.

## Ground truth (investigated `2026-05-30`)

Crossing infrastructure that exists today (the `(crossings (event ...))`
primitive):
- Parse: `FSM/Adapter/ISF/Parser.pm` `_parse_crossings()` (~L6673),
  `_finalize_actor_crossings()` (~L5461). Record: `{kind=>'event', name,
  from=>{domain,signal}, to=>{domain,signal}, ready=>{signal,domain}}`.
- Lowering: `FSM/Scheduler/ISF.pm` partitions the actor into per-domain
  `<actor>__domain_<d>.fsm` modules, exposes crossing endpoints as domain ports
  (`_add_crossing_endpoint_ports` ~L227), and the `<actor>_top.fsm` instantiates
  a CDC child `<name>_cdc` (`<actor>__cdc_event_<name>`) wiring
  `request`/`ready`/`pulse` (`_emit_multi_domain_wiring` ~L334,
  `_emit_crossing_rtlif` ~L368). The CDC child RTL is emitted by
  `FSM/Composition/ISFEventCDCModuleEmitter.pm` (acknowledged single-bit,
  single-outstanding, no payload).
- The activation fail-closed: `_validate_same_domain_target()`
  (LoweringIR.pm ~L2572) hard-fails when target domain ≠ owner domain, with NO
  consultation of `$actor->{crossings}`. Called from
  `_validate_transaction_clause_domain_refs()` do/spawn branch (~L2481-2504).
- Same-domain activation wiring: `<instance>_start` (output) / `<instance>_done`
  (input) handoff ports created in the owner domain module
  (LoweringIR.pm ~L1338-1357).

## SAFETY CONSTRAINT (non-negotiable)

A blocking cross-domain `do` needs a **bidirectional** handshake: parent's
`<inst>_start` (source domain) must reach the child's start (dest domain), and
the child's `done` (dest domain) must return to the parent (source domain).
The shipped event crossing is **unidirectional** (source→dest pulse + source
ready-ack), so one event crossing is insufficient — two are needed (start
source→dest, done dest→source).

**Therefore a validator-only relaxation is forbidden:** accepting a cross-domain
activation without routing `<inst>_start`/`<inst>_done` through CDC
synchronizers would emit an unsynchronized cross-clock handoff — a metastability
bug, exactly what the fail-closed rule prevents. Validator acceptance and the
CDC routing **must ship in the same slice**.

## Design

Add a new crossing kind `(crossings (activation child (from SRC) (to DEST)))`
(child names a declared transaction in domain `DEST`; the calling transaction is
in `SRC`). Lowering auto-generates the activation's start/done handshake through
**two** acknowledged-event CDC children (reusing `ISFEventCDCModuleEmitter`):
- start: source `<inst>_start` request → CDC → dest child start pulse.
- done:  dest child `done` request → CDC → source `<inst>_done` pulse.
The validator accepts a cross-domain `(do child)`/`(spawn child)` exactly when an
`activation` crossing covering `(SRC → DEST, child)` is declared.

(Rejected alternative: requiring the author to hand-declare two raw `(event ...)`
crossings — the `<inst>_start`/`<inst>_done` signals are compiler-internal, so
authors cannot name them; the `activation` kind is the right abstraction.)

## Slice plan

- `.1` select: scope + the investigated ground truth + the safe design (this
  doc). No code.
- `.2` parser + declaration validation for `(crossings (activation ...))`: parse
  the new kind onto `$actor->{crossings}`; validate domains/child exist and
  SRC≠DEST; cross-domain `(do)`/`(spawn)` STILL fails closed at lowering (the
  declaration is parsed but not yet honored — "parser-acceptance ≠ support").
  Safe (fail-closed) and bounded.
- `.3` lowering + validator acceptance (the correctness-critical slice): partition
  parent/child across domains; auto-generate + wire the two event CDC children
  for the activation start/done; teach `_validate_same_domain_target` (via the
  do/spawn call site) to accept a cross-domain activation covered by an
  `activation` crossing. Ship validator-accept + CDC routing together. Golden
  `.fsm` + composition + HDL (Verilator `--verify-hdl` where available) evidence
  that the handoff routes through the CDC children.
- `.4` docs (13a crossing section + 13d control-flow + downstream/contract/
  SPECFORGE response) + runnable book example.

## Non-Goals

- No data-payload crossing (separate primitive).
- No auto-generation of the crossing without an explicit declaration (per the
  "fail closed unless a declared crossing owns the path" principle).

## Acceptance Criteria

- `(crossings (activation child (from SRC)(to DEST)))` parses and validates.
- A cross-domain `(do child)` covered by such a crossing lowers, partitions
  across domains, and routes `<inst>_start`/`<inst>_done` through two event CDC
  children in the `_top`; HDL emits (and passes Verilator lint where available).
- Cross-domain activation WITHOUT a covering activation crossing still fails
  closed.
- New `t/138x` golden(s); docs synced; audits + broad regression pass.
- Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING`
  Status: `active`
  Goal: `Cross-domain (do)/(spawn) through a declared (crossings (activation ...)) with CDC-synchronized start/done.`
  Children: `.1` (select), `.2` (parse+declare-validate, fail-closed), `.3` (lowering+accept), `.4` (docs+example)

- ID: `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.1`
  Status: `done`
  Goal: `Select; record investigated ground truth + safe design + slice plan.`
  Acceptance: `Task tree committed before any code change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `dbbe6bce`

- ID: `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.2`
  Status: `done`
  Goal: `Parse + structurally validate (crossings (activation child (from SRC)(to DEST))); lowering fails closed (not yet supported).`
  Acceptance: `Construct parses + validates; malformed rejected at parse; well-formed fails closed at lower; event crossings unaffected.`
  Verification: `prove -Iperl t/1386 t/1247 t/1372; broad clock-domain/crossing regression; mdbook build docs/book; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design commit `dbbe6bce`. |
| 2 | `.2` | `done` | Parser + structural validation shipped; lowering fail-closed (`t/1386`). |
| 3 | `.3` | `pending` | Lowering + CDC routing + validator acceptance (ships together; correctness-critical). |
| 4 | `.4` | `pending` | Docs + runnable book example. |

## Decisions

- `2026-05-30`: New `(crossings (activation ...))` kind (not hand-declared raw
  event pairs) because activation start/done signals are compiler-internal.
- `2026-05-30`: Validator acceptance and CDC routing MUST ship together (`.3`)
  to avoid emitting an unsynchronized cross-domain handoff. `.2` is safe because
  lowering stays fail-closed until `.3`.

## Open Questions

- `.3` design detail: one `activation` crossing auto-generating two event CDC
  children, vs. two CDC children declared/instantiated explicitly. Lean toward
  auto-generating two within the single `activation` crossing for author
  ergonomics; finalize in `.3` against the existing CDC-child emit path.

## Blockers

- None for `.1`/`.2`. `.3` is the substantial correctness-critical slice.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-30` | `.1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-05-30` | `.2` | `prove -Iperl t/1386 t/1247 t/1372` (Files=3, Tests=19, PASS); broad clock-domain/crossing/parser regression (12 files, 147) PASS; `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.1: select cross-domain activation via crossing` | `dbbe6bce` |
| `.2` | `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.2: parse + validate activation crossing (lowering fail-closed)` | `ship commit (this slice)` |

## Changelog

- `2026-05-30`: Created. User-selected CDC lane direction (cross-domain
  activation via a declared crossing). Recorded the investigated infrastructure,
  the bidirectional-handshake safety constraint (validator+lowering ship
  together), the `(crossings (activation ...))` design, and the slice plan.
- `2026-05-30`: `.1` selection/design committed (`dbbe6bce`).
- `2026-05-30`: `.2` shipped. Parser (`_parse_crossings` dispatch +
  `_parse_activation_crossing`) accepts `(crossings (activation child (from SRC)
  (to DEST)))`; `_finalize_actor_crossings` validates domains declared, SRC≠DEST,
  and child is a declared transaction. Lowering fails closed for any actor
  declaring an activation crossing ("cross-domain activation lowering is not yet
  supported") — parser-acceptance ≠ support; CDC routing ships in `.3`. Event
  crossings unaffected. Locked by `t/1386`; regression PASS.
