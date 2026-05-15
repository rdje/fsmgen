# ISF-ACTIVATION-BIND-EXPRESSIONS: Expression-Valued Activation Input Bindings

## Metadata

- Tree ID: `ISF-ACTIVATION-BIND-EXPRESSIONS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-15`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Allow ISF activation input bindings to pass expression-valued runtime payloads
without forcing authors to create temporary actor variables solely to wire a
transaction port.

## Non-Goals

- Do not add rule-trigger output bindings.
- Do not add expression-valued transaction output binding targets; output
  bindings still target scalar writable actor-side signals.
- Do not add general activation-site parameter overrides beyond the already
  shipped spawn and generated blocking-`do` parameter surface.
- Do not freeze private `LoweringIR` fields as public API.

## Acceptance Criteria

- `(bind (input port expr) ...)` accepts scalar signals, numeric/exact-width
  literals, and non-empty list expressions on shipped activation sites.
- Expression input bindings lower through the same reviewable scheduled `.fsm`
  assignments as scalar bindings and reach SystemVerilog generation.
- Input binding expressions reject unknown actor-side scalar references and
  actor output readback where the lowerer can identify those references.
- Width mismatches still fail closed when the expression width is known.
- Output bindings remain scalar writable endpoints.
- Schedule reports expose bounded provenance for expression-valued bindings.
- Focused validation passes, and broader ISF validation runs if the changed
  contract or lowerer surface warrants it.
- Live docs, the mdBook, task tree, and roadmap status are updated.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ACTIVATION-BIND-EXPRESSIONS`
  Status: `done`
  Goal: `Ship expression-valued activation input bindings with docs and report provenance.`
  Children: `ISF-ACTIVATION-BIND-EXPRESSIONS.1`

- ID: `ISF-ACTIVATION-BIND-EXPRESSIONS.1`
  Status: `done`
  Goal: `Implement and document expression-valued activation input bindings.`
  Acceptance: `Input binding expressions lower for local do, generated do/spawn, and rule trigger sites; malformed expressions fail closed; report contract documents actor_expression.`
  Verification: `perl syntax checks; focused binding/report/parameter tests; public contract audits; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `ISF-ACTIVATION-BIND-EXPRESSIONS.1: ship binding expressions`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-ACTIVATION-BIND-EXPRESSIONS.1` completed. |

## Decisions

- `2026-05-15`: Input bindings carry runtime data/control, so expression-valued
  input bindings are an IAL1 expressiveness feature, not a parameter
  specialization feature.
- `2026-05-15`: Output bindings remain scalar-only because they name the
  actor-side destination that receives transaction output data.
- `2026-05-15`: The schedule report keeps the legacy `actor_signal` field for
  scalar endpoints and adds `actor_expression` for the formatted actor-side
  source/target expression. For expression-valued input bindings,
  `actor_signal` is JSON null.

## Open Questions

- Full expression width inference for every `.fsm` expression operator remains
  outside this leaf; unknown expression widths continue into the downstream
  `.fsm` validation and HDL generation path.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-ACTIVATION-BIND-EXPRESSIONS.1` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `prove -Iperl t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1181-isf-rule-action-boundary.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTIVATION-BIND-EXPRESSIONS.1` | `ISF-ACTIVATION-BIND-EXPRESSIONS.1: ship binding expressions` | `pending commit workflow` |

## Changelog

- `2026-05-15`: Created task tree and started the first implementation leaf.
- `2026-05-15`: Completed `ISF-ACTIVATION-BIND-EXPRESSIONS.1` and closed the tree.
