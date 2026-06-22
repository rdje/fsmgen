# AXI IAL2 Manager Post Dynamic Transaction-ID Metadata Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.220` on 2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.220`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.221`, readiness audit for generated
dynamic transaction-ID capture and response matching.

`.219` deliberately shipped a metadata-only dynamic-ID boundary. Public PPIF
now accepts transaction-local `(id dynamic)` and reports the selected
user-supplied request/response ID metadata, but same-family behavior clauses
that need dynamic capture, response matching, queues, scoreboards, read-data
routing, or HDL behavior still fail closed.

The next safe owner is therefore not a direct generator implementation. It is
an audit that decides the smallest generated behavior or prerequisite after
metadata: when to sample the user request ID, how to retain outstanding
transaction identity, which response ID signal completes which transaction,
what first bounded read or write shape can be supported, and whether existing
IAL1/IAL0/SystemVerilog substrate is sufficient before parser/report or HDL
behavior changes.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated artifact, test, or HDL behavior.

## Evidence Read

The selector read:

- `.219` dynamic transaction-ID metadata behavior:
  `docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md`.
- `.218` metadata readiness audit, `.217` public dynamic-ID contract
  selection, and `.216` dynamic same-ID issue-order readiness audit.
- Counted request evaluation/report context from `.214` and the current
  dynamic unsupported-residue boundaries.
- Current PPIF dynamic sample and support-accounting entry:
  `ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif` and
  `intent.ppif_axi_manager_capacity_status_dynamic_transaction_id`.
- PPIF transaction-ID parsing, AXI manager transaction-ID normalization/report
  code, fail-closed behavior interactions, support-detail text, and focused
  generator/PPIF tests.
- README, `ROADMAP_V2.md`, mdBook backlog, task tree, Memory, and Knowledge
  Map fact cards.

## Current Boundary

The shipped dynamic-ID behavior is metadata-only:

```text
PPIF spelling:        transaction-local (id dynamic)
ID source:            family request-ID signal at the admitted request point
Response identity:    family response-ID signal
Ownership:            user_supplied
Implementation:       selected_not_generated
Generated behavior:   none for dynamic capture, matching, queues, read-data, or HDL
Fail-closed clauses:  same-family auto-id-lifecycle, response-demux,
                      same-id-ordering-policy, read-data.read
```

Existing auto-ID lifecycle, concrete-ID assertions, counted concrete
queue-head behavior, generated response demux, read-data, burst, runtime
validation, and HDL behavior remain unchanged.

## Candidate Comparison

A parser/report cleanup is not selected first. `.219` already records the
public spelling, report vocabulary, fail-closed dynamic behavior interactions,
support-accounted sample, strict check/semantic coverage, mdBook text, roadmap
text, and Knowledge Map cards.

Direct dynamic same-ID queue generation is not selected first. Dynamic IDs
turn the queue key into sampled runtime data rather than an enumerated concrete
transaction value, so the implementation needs an owned answer for capture
timing, outstanding storage, response matching, same-ID policy, read-data
routing, and scoreboard assertions before it can safely generate queues.

Direct read-data routing is not selected first. Read-data capture depends on a
matched dynamic transaction identity and, for burst paths, on last-beat and
beat-count behavior. It should follow the first response-matching contract or
a narrower readiness audit selection.

Packed burst-vector outputs, alternate full burst payload assembly, direct
backend lowering, verification-output generation, VHDL, backend language
variants, public `.pif`/`.ppi`/`.axi` aliases, and full AXI manager behavior
remain separate roadmap/task-tree boundaries.

## Selected `.221` Audit Boundary

`.221` must audit generated dynamic transaction-ID capture and response
matching. The audit should decide:

- the first bounded behavior or prerequisite after metadata-only `(id dynamic)`;
- whether the first generated shape should be write `BID` response matching,
  read single-beat `RID` response matching, a report/static contract split, or
  a lower-layer prerequisite;
- the exact capture point for the family request-ID signal relative to admitted
  request pulses and capacity/ordering gates;
- the outstanding-state lifetime, response-match condition, completion pulse,
  and runtime assertion contract;
- how dynamic capture interacts with existing auto-ID lifecycle, concrete
  transaction IDs, counted request-set capacity, same-ID queue-head groups, and
  selected-not-generated same-ID policy metadata;
- what public syntax and report fields can remain unchanged and what additive
  metadata would be needed if behavior is selected later;
- the generated `.isf`, `.fsm`, SystemVerilog, strict check JSON, semantic
  JSON, schedule-report, support-accounting, and mdBook validation gates;
- rollback boundaries and explicit residue for same-ID ordering, queues,
  scoreboards, read-data routing, bursts, direct backend behavior, HDL shapes
  not selected by the audit, and VHDL.

No parser, generator, PPIF sample, support-accounting catalog, validation,
generated artifact, test, or HDL behavior belongs in `.221` unless that audit
first selects a later implementation or prerequisite leaf.

## Preservation Matrix

`.221` must preserve:

- metadata-only `(id dynamic)` parser/report support from `.219`;
- fail-closed dynamic interactions for same-family `auto-id-lifecycle`,
  `response-demux`, `same-id-ordering-policy`, and `read-data.read`;
- all existing auto-ID lifecycle, concrete-ID assertion, counted queue-head,
  response-demux, read-data, burst, runtime-validation, multi-beat, strict
  check JSON, semantic JSON, and HDL behavior;
- support-accounting identities and public sample behavior;
- direct backend deferral, verification-output deferral, VHDL deferral, and
  backend-language neutrality.

## Non-Goals

- Do not implement dynamic ID capture, response matching, queues,
  scoreboards, read-data routing, or HDL behavior in `.220`.
- Do not change PPIF syntax, public samples, support accounting, tests,
  generated artifacts, validation, or HDL behavior in `.220`.
- Do not infer dynamic queue generation from metadata-only `(id dynamic)`.
- Do not add packed burst-vector outputs or alternate full burst payload
  assembly.
- Do not change direct backend, verification-output generation, VHDL, or
  backend-language variant behavior.
- Do not bypass the `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering path.

## Validation Gates

For `.220`, the required gates are documentation and continuity gates:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

Any broad `prove` or supported-corpus gate remains RAM-guarded.

## Rollback Boundary

Rollback for `.220` is limited to this selector record, task-tree frontier
movement, Memory, README, roadmap, mdBook, and Knowledge Map/fact-card
updates. No parser, generator, public sample, support-accounting catalog,
generated artifact, test, validation, or HDL behavior is part of this slice.
