# AXI IAL2 Manager Dynamic Same-ID Policy Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.433`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.433` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.434`, public dynamic same-ID policy
contract selection before dynamic per-ID queues, scoreboards, parser/report
implementation, or generated behavior.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check or semantic JSON, HDL, or
runtime behavior changes in this audit.

## Inputs Read

The audit is based on:

- `.432`, which reopened dynamic same-ID issue-order readiness after bounded
  dynamic/mixed response-demux, read-data, multi-beat, and recapture behavior
  reached the two-dynamic-plus-one-static read burst-last boundary;
- `.431` two-dynamic-plus-one-static mixed read burst-last `RID && RLAST`
  release-and-recapture behavior and the `.430`/`.429` contract/audit that
  selected it;
- `.357` two-dynamic-plus-one-static mixed read burst-last multi-beat behavior,
  where the covered response-demux chain still left `same_id_ordering` as the
  remaining residue;
- `.362` and `.363`, which deliberately placed same-cycle widening and
  release-and-recapture before dynamic same-ID queues and scoreboards;
- `.216` through `.219`, where dynamic same-ID readiness first selected
  transaction-local `(id dynamic)` metadata before generated dynamic response
  matching existed;
- generated dynamic and mixed dynamic/static write/read response-demux,
  read-data, raw-`ARLEN`, runtime-validation, multi-beat, and recapture
  records after `.219`;
- concrete same-ID reuse policy, metadata-first issue-order queue, admitted
  request pulse, compact one-hot queue representation, queue-head demux, and
  bounded concrete queue-head behavior records;
- current PPIF parser syntax, AXI manager transaction normalization,
  `same_id_ordering` report construction, dynamic response-demux fail-closed
  diagnostics, support-accounting detail, README, ROADMAP_V2, mdBook, Memory,
  task tree, and Knowledge Map.

## Current Boundary

FSMGen now has generated bounded dynamic ID capture and response matching for
selected public response-demux/read-data/multi-beat/recapture shapes. Dynamic
transactions record request ID source, selected-ID state, active state, raw
response ID matching, final-beat completion pulses where required, completion
active assertions, and same-cycle release-and-recapture for the selected
single-active, multiple-dynamic, and mixed dynamic/static families.

Dynamic same-ID ordering remains a separate public-policy gap. The parser
accepts `(same-id-ordering (<family> (concrete-id-reuse reject)))` and
`(same-id-ordering (<family> (concrete-id-reuse issue-order-queue)))`.
That policy is intentionally named `concrete-id-reuse`; it does not define
what happens when two admitted dynamic transactions sample the same runtime ID.

Current generator diagnostics still reject combining dynamic transaction ID
metadata with same-ID ordering policy. Current dynamic/mixed response-demux
behavior instead keeps a no-active-same-ID request assertion stance for the
covered bounded shapes. That stance is correct for the generated behavior
already shipped, but it is not a public contract for accepting multiple
outstanding same-ID dynamic requests.

## Readiness Findings

The old prerequisite from `.216` is now substantially covered for bounded
public dynamic/mixed response-demux shapes: dynamic ID metadata, selected-ID
capture, response matching, read-data routing over selected demuxes,
burst-last completion ownership, multi-beat consumers, and same-cycle
release-and-recapture all have concrete generated records.

The next blocker is not an IAL1/IAL0/SystemVerilog primitive. Existing
generated behavior already uses scalar selected-ID storage, active bits,
guarded comparisons, onehot0 request assertions, uniqueness assertions,
completion-active assertions, and compact concrete queue-head slots. The
missing boundary is the public policy and report vocabulary that says whether
dynamic same-ID reuse is rejected, queued in issue order, or tracked by a
scoreboard.

Direct dynamic queue behavior is not selected. It would need to define same-ID
admission, request arbitration beyond the current sibling onehot0 stance,
per-ID ordering guarantees, queue capacity/overflow behavior, ambiguity
assertions, read/write symmetry, burst-last and raw non-final-beat handling,
report/residue movement, support accounting, and public examples in one slice.

Scoreboard behavior is not selected. A scoreboard policy would still need a
public source spelling and report contract before generated behavior can be
reviewed. It also has a different completion-tracking promise from an
issue-order queue and should not be inferred from the concrete-ID policy.

Report/static cleanup alone is not selected. The current reports and support
detail are honest: dynamic response-demux/read-data/recapture behavior is
generated for selected bounded shapes, while dynamic same-ID ordering,
queues, scoreboards, and broader HDL behavior remain future exact owners.

A narrower write-only or read-only audit is not selected first. The public
policy name and report shape should be family-local and symmetric enough to
cover both read and write before a later owner chooses the first behavior
subset.

## Selected `.434` Boundary

`.434` should select the public dynamic same-ID policy contract before any
parser or generator behavior changes. It should decide:

- the exact PPIF spelling, likely as an additive family-local clause under
  `(same-id-ordering ...)` that is distinct from `concrete-id-reuse`;
- the allowed first policy values, including whether `reject`,
  `issue-order-queue`, and `scoreboard` are all source-level names or whether
  only a smaller subset is selected initially;
- normalized report fields for dynamic same-ID policy, implementation status,
  accepted same-ID reuse, enforcement boundary, generated behavior, and
  residue;
- whether parser/report metadata should first accept selected-not-generated
  dynamic policy values, or whether the first accepted spelling must be
  fail-closed except for explicit `reject`;
- how dynamic policy coexists with concrete-ID queue-head behavior,
  generated auto-ID same-ID avoidance, generated dynamic no-active-same-ID
  assertions, and mixed dynamic/static static-ID reservation checks;
- diagnostics for attempts to treat `concrete-id-reuse` as covering dynamic
  transaction IDs;
- validation gates, rollback, docs, mdBook examples, support-accounting
  impact, and Knowledge Map facts for the later implementation owner.

The first later behavior owner, if selected after the contract is settled,
should remain bounded. Candidate first behavior subsets are dynamic same-ID
`reject` static validation/reporting, selected-not-generated
`issue-order-queue` metadata, or a readiness audit for one read or write
dynamic issue-order queue shape. `.434` should choose that ordering explicitly
instead of allowing behavior to follow implicitly.

## Preservation Matrix

`.434` must preserve:

- transaction-local `(id dynamic)` semantics and report vocabulary;
- generated dynamic and mixed response-demux/read-data/raw-`ARLEN`/
  runtime-validation/multi-beat/recapture behavior already selected;
- current no-active-same-ID assertions for generated bounded dynamic/mixed
  response-demux shapes until a later owner explicitly replaces them;
- concrete-ID `concrete-id-reuse` policy, generated concrete queue-head
  behavior, counted request-set capacity-fit guards, and group-local
  assertions;
- auto-ID allocation and generated auto-ID same-ID avoidance behavior;
- public sample identities, support-accounting identities, check JSON,
  semantic JSON, schedule JSON, generated artifacts, and HDL behavior;
- direct backend deferral, verification-output deferral, VHDL deferral, and
  backend-language neutrality.

## Non-Goals

- Do not implement parser/report behavior in `.433`.
- Do not implement dynamic same-ID queues, scoreboards, request arbitration,
  overflow handling, ambiguity assertions, or generated HDL behavior in
  `.433` or `.434` unless `.434` selects a later exact implementation owner.
- Do not widen PPIF samples, support accounting, schedule/check/semantic JSON,
  generated artifacts, tests, or HDL behavior in `.433`.
- Do not reinterpret `concrete-id-reuse` as applying to dynamic transaction
  IDs.
- Do not change direct backend behavior, verification-output generation,
  VHDL, or backend-language variants.

## Validation For This Audit

Audit closeout requires:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

No behavior-bearing command is required for `.433`. Any future broad Perl,
supported-corpus, `fsmgen`, `prove`, or HDL verification command remains
subject to the repository RAM guard.

## Rollback

Rollback is this docs-only audit commit. Reverting it removes only the `.434`
selection record, fact card, task-tree advancement, live-doc updates, and
resume pointer update; generated behavior remains at `.431`.
