# AXI IAL2 Manager Dynamic Same-ID Issue-Order Queue Recapture Report Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.475`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.475` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.476`, readiness audit for
identity-preserving same-transaction queue recapture ID refresh.

`.475` does not select a positive public same-cycle queue recapture report
field yet. The current generated queue report should remain literal:
`generated_update_rules` lists the update rules the generator actually emits,
and no `same_cycle_release_recapture_policy` or `release_recapture_*` field is
added to queue reports until the identity-preserving same-transaction case is
audited and either implemented or documented as unsupported.

This contract-selection slice changes no parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, or VHDL behavior.

## Inputs Read

The selector read:

- `.474` queue recapture readiness audit.
- Generated dynamic write, read single-beat, and read burst-last same-ID
  `issue-order-queue` behavior records.
- `.473`, `.471`, `.469`, and `.467` queue read-data behavior records.
- Classic single-active, multiple all-dynamic, and mixed dynamic/static
  release-and-recapture report records.
- Current queue transition builder, queue assignment helper, queue report
  projection, same-ID ordering report projection, response-demux report
  projection, static support/residue prose, parser/CLI report expectations,
  README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

The selector also used RAM-guarded schedule-report probes for the generated
dynamic read queue samples. Those reports list same-cycle dequeue-plus-enqueue
rules such as:

```text
axi0_read_dynamic_same_id_issue_order_r0_dequeue_enqueue_r1
axi0_read_dynamic_same_id_issue_order_r1_dequeue_enqueue_r0
axi0_read_dynamic_same_id_issue_order_r0_r1_dequeue_enqueue_r0
axi0_read_dynamic_same_id_issue_order_r1_r0_dequeue_enqueue_r1
```

They do not list identity-preserving one-entry rules such as:

```text
axi0_read_dynamic_same_id_issue_order_r0_dequeue_enqueue_r0
axi0_write_dynamic_same_id_issue_order_w0_dequeue_enqueue_w0
```

That absence matches the transition builder's current state-key skip: a
dequeue of `r0` followed by enqueue of `r0` from a one-entry `[r0]` queue has
the same transaction-identity state key before and after the transition, even
though the slot ID would need to update to the current request ID for a true
new transaction recapture.

## Selected Interim Report Contract

Until `.476` settles identity-preserving same-transaction queue recapture,
public reports should keep the existing literal contract:

- `same_id_ordering.dynamic_id_reuse_policy.{read,write}.generated_queues[]`
  remains the authoritative report location for dynamic issue-order queue
  storage, request/response ID sources, and generated update/assertion names.
- `response_demux.{read,write}` remains the response-demux summary location
  for mode, completion source, completion semantics, generated rules, generated
  completion signals, and queue behavior boundary.
- `same_cycle_release_recapture_policy`, `release_recapture_rule`,
  `release_recapture_source`, and `release_recapture_transaction` remain
  exclusive to classic dynamic response-demux capture state, because that path
  rewrites per-transaction busy/selected-ID registers rather than compact queue
  slots.
- `generated_update_rules` is a literal generated-rule list. Presence of
  `*_dequeue_enqueue_*` entries means the generator emits those queue
  transitions; it is not a complete public guarantee of every same-cycle
  recapture form.

If `.476` proves and selects full queue-owned same-cycle recapture support, the
future positive report field should live under each generated queue entry, not
under `response_demux`, because the behavior is owned by queue slot update
rules and slot ID capture. The future field should use queue terminology, not
classic response-demux release/recapture terminology.

## Selected `.476` Boundary

`.476` should audit the identity-preserving same-transaction recapture case
before any report/static alignment implementation. It should decide whether the
next implementation owner must:

- add state-key-preserving queue update rules that refresh the slot ID when the
  selected-dequeue transaction is admitted again in the same cycle;
- add an assertion or report boundary documenting that this exact case remains
  unsupported; or
- split behavior by queue state length, family, or read/write response scope.

The audit should inspect generated `.isf`/`.fsm` behavior for write, read
single-beat, read burst-last, and the queue read-data consumers, and it should
record whether same-transaction recapture from a one-entry queue preserves,
refreshes, or loses the new request ID.

## Documentation Correction

Earlier queue behavior docs correctly describe generated same-cycle
dequeue-plus-enqueue rules, but they use broader release-and-recapture wording.
`.475` narrows the public contract: generated rule names are the source of
truth until `.476` settles whether same-transaction recapture with unchanged
transaction identity refreshes the captured ID.

## Diagnostics

No parser diagnostic is selected in `.475`. The source shape is already
accepted for generated dynamic issue-order queues. The next owner must decide
whether any fail-closed diagnostic is needed if identity-preserving queue
recapture remains unsupported.

## Non-Goals

`.475` changes no behavior and does not add report keys. It leaves these to
future exact owners:

- queue report implementation;
- identity-preserving queue recapture behavior implementation;
- broader dynamic queue cardinality;
- mixed dynamic/static queues;
- scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation Plan

For `.475`, closeout is documentation and continuity focused:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback removes this contract-selection document, its Knowledge Map card, and
the README/ROADMAP/mdBook/task-tree/MEMORY updates. No generated behavior or
public source syntax changed in `.475`.
