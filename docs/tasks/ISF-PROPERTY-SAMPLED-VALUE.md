# ISF-PROPERTY-SAMPLED-VALUE: SV sampled-value functions in verification properties

## Metadata

- Tree ID: `ISF-PROPERTY-SAMPLED-VALUE`
- Status: `done`
- Roadmap lane: `R14` (ISF — high-level language richness)
- Created: `2026-06-04`
- Last updated: `2026-06-05`
- Owner: repo-local workflow

## Goal

Let `(assert/assume/cover …)` properties reference SystemVerilog **sampled-value
functions** — `(stable SIG)`, `(changed SIG)`, `(rose SIG)`, `(fell SIG)` — so the
common temporal obligations real verification needs ("data stable while valid",
"ack rises after req", "field unchanged through a phase") are expressible directly
in ISF instead of staying outside the property language.

Reads like:

```lisp
(assert (=> valid (stable data)))   ;; while valid, data must not change
(assert (=> (rose req) ack))        ;; on the req rising edge, ack same cycle
(assert (stable cfg) "cfg is constant after reset")
```

This is the natural completion of the property combinator set started by
`ISF-ASSERT-CONCURRENT` / `ISF-PROPERTY-IMPLICATION` / `ISF-TRIGGER-ANCHOR`
(`=>` / `next` / `within` / `after` / `monitor`). It also closes the `(stable sig)`
gap flagged to SPECFORGE in `docs/SPECFORGE_FEEDBACK_RESPONSE.md` (2026-06-04
addendum) — SPECFORGE mines exactly these stability/edge predicates.

## Ground truth (investigated `2026-06-04`)

- The property grammar lives in **`FSM::Adapter::FSMGenFull::Parser::parse_check_property`**
  (`perl/FSM/Adapter/FSMGenFull/Parser.pm` ~L706): it recognizes the combinators
  `=>` / `after` / `next` / `within` as tagged `{__property__=>1, op=>…}` structs,
  and falls through to the boolean expression builder for anything else.
- The SVA text is rendered by **`FSM::Pipeline::GeneratedModuleInfoBuilder::_render_check_condition_sv`**
  (`perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm` ~L77); the simulable-vs-formal
  checkability split is decided by `_property_is_formal_only` (~L112): a `##` delay
  (`next`/`within`) is formal-only, everything else is verilator-simulable.
- **`$rose` is already emitted** — by `(after SIG …)` → `$rose(SIG) |-> (CONS)` — on
  the verilator-**simulable** path. Strong evidence the sampled-value family lints and
  simulates fine in the generated clocked assertion context.
- **ISF needs no change.** `FSM::Scheduler::ISF::LoweringIR::_format_isf_expr` (~L7993)
  is a pure recursive serializer with NO operator whitelist, and `_ir_check` (~L7869)
  just serializes `COND` verbatim into the `+assert` carrier. So `(stable data)` flows
  through ISF untouched; all grammar + validation is at the `.fsm` re-parse layer.
- A signal referenced only by a check is kept alive as a port; the aliveness walk
  traverses the property tree, so it must include the new leaf's operand field.

## Design

- Add the four boolean sampled-value functions as **property leaves** in
  `parse_check_property`: `(stable SIG)` / `(changed SIG)` / `(rose SIG)` /
  `(fell SIG)` → `{__property__=>1, op=>'sampled_value', fn=>'$stable'|…, operand=>…}`,
  rendered to `$fn(<operand>)`. Each takes exactly one signal operand.
- They compose as property leaves: standalone (`(assert (stable data))`), as an
  antecedent (`(=> (rose req) ack)`), or as a consequent (`(=> valid (stable data))`).
  Note `(after req ack)` ≡ `(=> (rose req) ack)` — `after` is the convenience spelling,
  `(rose …)` the general leaf; both coexist.
- **Checkability**: a sampled-value leaf is not a `##` sequence, so it is
  verilator-**simulable** (`ifndef SYNTHESIS`); a property goes formal-only only when a
  `next`/`within` sits elsewhere in it. Confirm empirically with `--verify-hdl`
  (verilator lint + yosys), the same bar `next`/`within` were classified by.
- **Keep operand signals alive** as ports (extend the property-tree aliveness walk to
  the `sampled_value` operand).
- **Fail closed**: wrong arity (`(stable)` / `(stable a b)`), and the heads are
  property-only — used in a synthesizable expression context (control-flow guard, data
  RHS) they already fail closed because the expression builder does not know them.
- `(past SIG [N])` is **value-returning**, not boolean, so it only composes inside a
  comparison (`(== data (past data))`) — that needs expression-level support and is a
  later slice. `(stable SIG)` already covers the common "unchanged" case
  (`$stable(s)` ≡ `s == $past(s)`).

## Slice plan

- `.1` select (this doc) — scope, ground truth, design, slice plan. Task tree
  committed before any code change.
- `.2` the four boolean sampled-value predicates `stable` / `changed` / `rose` /
  `fell` — parser leaves + SVA render + operand aliveness + checkability; 13d docs with
  runnable examples; 13k feature-matrix row + `ISF_SPEC` focused-test index; tests;
  full suite.
- `.3` (deferred / optional) value-returning `(past SIG [N])` via expression-level
  composition (`(== data (past data N))`).

## Task Tree

- ID: `ISF-PROPERTY-SAMPLED-VALUE`
  Status: `done`
  Goal: `SV sampled-value functions (stable/changed/rose/fell[/past]) inside assert/assume/cover properties.`
  Children: `.1` (select), `.2` (four boolean predicates), `.3` (deferred close: past)

- ID: `ISF-PROPERTY-SAMPLED-VALUE.1`
  Status: `done`
  Goal: `Select; record ground truth (property grammar in FSMGenFull parser; ISF pass-through; $rose already simulable) + design + slice plan.`
  Acceptance: `Task tree committed before any code change; TASK_TREE.md index row added.`
  Verification: `scripts/check_memory_architecture.sh; git diff --check`
  Commit: `2b90c42b`

- ID: `ISF-PROPERTY-SAMPLED-VALUE.2`
  Status: `done`
  Goal: `(stable/changed/rose/fell SIG) property leaves render to $stable/$changed/$rose/$fell(SIG) inside assert/assume/cover.`
  Acceptance: `parse_check_property accepts the four heads as one-operand sampled_value leaves; _render_check_condition_sv emits $fn(operand); they are verilator-simulable (not formal-only) and --verify-hdl passes; operand signals are kept alive as ports; (assert (stable data)), (assert (=> (rose req) ack)), (assert (=> valid (stable data))) lower + generate HDL; malformed arity fails closed; the heads stay property-only (fail closed in synthesizable expression position). 13d documents them with runnable examples; 13k row + ISF_SPEC focused-test index updated; a new t/ test locks it; full suite green.`
  Verification: `prove -j4 -Iperl t/<new> t/1376 t/1305 t/1250; --check-json + --verify-hdl on a sampled-value actor; perl -c; mdbook build; full prove -j4 -Iperl t/; git diff --check`
  Commit: `6700fbb4`
  Done: `parse_check_property gains a one-op sampled_value leaf for stable/changed/rose/fell -> $fn(SIG); _render_check_condition_sv renders $fn(operand); aliveness (_analyze_check_condition_references) + checkability (_property_is_formal_only) already recurse into operand, so simulable + signal-alive came free. Spike: all four + (=> valid (stable data)) + (=> (rose req) ack) generate SV and PASS verilator lint + yosys. New t/1417 (5 subtests: rendering+simulable, implication compose, operand kept alive, arity fail-closed, property-only fail-closed in a when guard). 13d "Sampled-value predicates" subsection + runnable example; 13k row 59 (Form + Behavior); ISF_SPEC focused-test index t/1417. No ISF-layer change (pass-through _format_isf_expr).`

- ID: `ISF-PROPERTY-SAMPLED-VALUE.3`
  Status: `done`
  Goal: `Close value-returning (past SIG [N]) as deferred/prerequisite-bound.`
  Acceptance: `No implementation was selected in this narrower tree: (past ...) is value-returning, not a boolean property leaf, and needed expression-level property composition (for example (== data (past data))) before it could ship. At this tree's closure, the mdBook, feature matrix, and ISF_SPEC stated the non-claim; future work was routed through a new exact owner under the broad temporal/property frontier (ISF-REMAINING-BROAD-FRONTIER.9).`
  Verification: `passed: sampled-value docs/spec audit, t/1417, book example lowering audit, feature matrix audit, memory architecture, Knowledge Map, mdBook build, relative-path audit, and diff checks`
  Commit: `ISF-PROPERTY-SAMPLED-VALUE.3: close value-returning past deferral`

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this doc); task tree committed before code. |
| 2 | `.2` | `done` | `(stable/changed/rose/fell SIG)` → `$stable/$changed/$rose/$fell(SIG)` property leaves; verilator-simulable; operand kept alive; property-only fail-closed; verilator+yosys PASS. `t/1417`; 13d/13k/ISF_SPEC synced. |
| 3 | `.3` | `done` | Value-returning `(past SIG [N])` closed as deferred/prerequisite-bound in this tree: it needed expression-level property composition and was routed to a future exact owner. |
| 4 | `closed` | `done` | Tree complete; later `(past ...)` work is owned by `ISF-REMAINING-BROAD-FRONTIER.9.1`. |

## Decisions

- `2026-06-04`: implement the four sampled-value functions as **property leaves** in the
  `.fsm` property parser (not the shared expression builder), keeping them strictly
  property-only — they are undefined outside a clocked assertion and must fail closed in
  synthesizable expression position.
- `2026-06-04`: one `op => 'sampled_value'` struct with an `fn` field, not four ops —
  one render branch, one checkability consideration.
- `2026-06-04`: scope `.2` to the boolean four; defer value-returning `(past …)` because
  it composes only inside a comparison (expression-level work), and `(stable)` already
  expresses the dominant "unchanged" use.
- `2026-06-05` (`.3` close): close `(past SIG [N])` as deferred rather than widening
  this tree. `(past ...)` is value-returning and needed expression-level property
  composition before implementation; at closure time the book/feature matrix/spec stated
  the non-claim, and future work routed to `ISF-REMAINING-BROAD-FRONTIER.9` or another
  exact temporal/property owner.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-04` | `.1` | `scripts/check_memory_architecture.sh`; `git diff --check` | `PASS` |
| `2026-06-04` | `.2` | `prove -Iperl t/1417 t/1376 (61 fixtures) t/1305 t/1250` PASS; `--check-json` + `--verify-hdl` (verilator lint + yosys) PASS on a sampled-value actor; `perl -c`; `mdbook build`; full `prove -j4 -Iperl t/`; `git diff --check` | `PASS` |
| `2026-06-05` | `.3` | `rg -n 'sampled-value|sampled value|stable|changed|rose|fell|past|\$stable|\$changed|\$rose|\$fell|value-returning' docs/book/src/13d-control-flow.md docs/book/src/13k-isf-feature-support-matrix.md docs/ISF_SPEC.md t/1417-isf-property-sampled-value.t docs/tasks/ISF-PROPERTY-SAMPLED-VALUE.md docs/tasks/ISF-REMAINING-BROAD-FRONTIER.md`; `prove -Iperl t/1417-isf-property-sampled-value.t t/1376-isf-book-example-lowering-audit.t t/1305-isf-book-feature-matrix-audit.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-PROPERTY-SAMPLED-VALUE.1: select — SV sampled-value functions in properties (task tree)` | `2b90c42b` |
| `.2` | `ISF-PROPERTY-SAMPLED-VALUE.2: (stable/changed/rose/fell SIG) sampled-value predicates in assert/assume/cover` | `6700fbb4` |
| `.3` | `ISF-PROPERTY-SAMPLED-VALUE.3: close value-returning past deferral` | `close-out slice` |

## Changelog

- `2026-06-04`: Created. Selected adding the SystemVerilog sampled-value functions
  (`stable`/`changed`/`rose`/`fell`, with value-returning `past` deferred) to the ISF
  verification property language, completing the combinator set and closing the
  `(stable sig)` gap flagged to SPECFORGE. Recorded ground truth (property grammar in
  `FSMGenFull::Parser::parse_check_property`; SVA render + checkability in
  `GeneratedModuleInfoBuilder`; ISF passes `COND` through verbatim via the pass-through
  `_format_isf_expr`; `$rose` already emitted simulably by `(after …)`) and the slice
  plan.
- `2026-06-04`: `.2` shipped — `(stable SIG)` / `(changed SIG)` / `(rose SIG)` /
  `(fell SIG)` now render to `$stable(SIG)` / `$changed(SIG)` / `$rose(SIG)` /
  `$fell(SIG)` inside `(assert/assume/cover …)`. Added a single `op => 'sampled_value'`
  leaf (with an `fn` field) to `FSMGenFull::Parser::parse_check_property` and a render
  branch to `GeneratedModuleInfoBuilder::_render_check_condition_sv`. Because the
  aliveness walk (`SignalAnalyzer::_analyze_check_condition_references`) and the
  checkability test (`_property_is_formal_only`) already recurse into the `operand`
  field, kept-alive-as-a-port and verilator-simulable came for free — no extra code.
  They compose as `=>`/`after` operands (`(=> valid (stable data))` → `(valid) |->
  ($stable(data))`; `(=> (rose req) ack)` ≡ `(after req ack)`), stay under
  `` `ifndef SYNTHESIS `` (not a `##` sequence), keep their operand signal alive, and
  are **property-only** — a sampled-value head in a `when` guard / data RHS fails closed.
  Verified end-to-end: a five-check actor generates SV and passes verilator lint +
  yosys synthesis. `t/1417` (5 subtests). Docs synced: `13d` gains a "Sampled-value
  predicates" subsection with a runnable example; `13k` row 59 (Form + Behavior);
  `ISF_SPEC` focused-test index. No ISF-layer change (the pass-through `_format_isf_expr`
  carries the new forms verbatim). Value-returning `(past …)` stayed deferred in this
  narrower tree (`.3`).
- `2026-06-05`: `.3` closed value-returning `(past SIG [N])` without code. It remains
  deferred because it is not a boolean property leaf and needs expression-level property
  composition. At closure time, 13d, 13k, and ISF_SPEC explicitly stated that
  `(past ...)` was not part of the shipped sampled-value surface.
- `2026-06-05`: Post-tree note: `ISF-REMAINING-BROAD-FRONTIER.9.1` later shipped
  property-expression support for value-returning `(past SIG [N])`. The `.3` evidence
  above remains historical closure for this narrower tree; current public behavior is
  recorded in `docs/tasks/ISF-REMAINING-BROAD-FRONTIER.md`, `docs/book/src/13d-control-flow.md`,
  `docs/book/src/13k-isf-feature-support-matrix.md`, and `docs/knowledge/isf-sampled-value-predicates.md`.
