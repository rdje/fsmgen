# AXI IAL2 Manager Post Dynamic Read Burst-Last Same-ID Issue-Order Queue Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.464`

Date: 2026-06-25

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.464` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.465` as a readiness audit for read-data
routing over generated dynamic read same-ID `issue-order-queue` response-demux
pulses.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, or VHDL behavior.

## Context Read

The selector reads the current generated dynamic same-ID queue surface:

- `.455` generated bounded two-transaction all-dynamic write `BID` dynamic
  same-ID issue-order queue behavior.
- `.459` generated bounded two-transaction all-dynamic read single-beat `RID`
  dynamic same-ID issue-order queue behavior.
- `.463` generated bounded two-transaction all-dynamic read burst-last
  `RID && RLAST` dynamic same-ID issue-order queue behavior.
- The dynamic read-data lineage: single-active scalar read-data, multiple
  all-dynamic scalar read-data, raw `ARLEN` report/runtime validation, and
  multi-beat output-bank records.
- The concrete queue-head read-data lineage, which already proves that
  response-demux queue completions can become read-data validity when the exact
  queue contract is owned.

The current generated dynamic read queue reports expose:

```text
generated_dynamic_issue_order_queue_demux
generated_dynamic_issue_order_queue_demux_last_beat
```

as transaction completion sources. Existing dynamic read-data coverage accepts
generated dynamic read response-demux completion sources, but read-data over
generated dynamic read same-ID queues remains outside the owned behavior.

## Why This Next

The generated dynamic read queue path now has the missing response ownership
substrate:

- compact runtime-ID queue slots with slot-local `ARID`;
- generated per-transaction completion pulses;
- same-ID preserving earliest matching runtime-ID selection;
- same-cycle selected dequeue plus one enqueue;
- for burst-last queues, raw non-final `RID` ownership with final `RID &&
  RLAST` completion/dequeue.

Read-data over these completions is now the smallest user-visible gap after
the queue behavior itself. It is still risky enough to require an audit first,
because the audit must pin:

- whether the first behavior slice is single-beat only, burst-last only, or a
  paired scalar single-beat plus scalar last-beat owner;
- completion-validity vocabulary for generated dynamic issue-order queue
  pulses;
- transaction output coverage and fail-closed diagnostics;
- interaction with `read_data.read.capture_scope`;
- preservation of raw `ARLEN`, runtime beat-count validation, multi-beat
  output banks, queue recapture widening, broader queue cardinality, mixed
  dynamic/static queues, scoreboards, direct backend behavior,
  backend-language variants, and VHDL.

## Selected `.465` Acceptance

`.465` must audit read-data routing over generated dynamic read same-ID
`issue-order-queue` completions before behavior changes.

The audit must read `.463`, `.462`, `.459`, `.455`, generated dynamic
read-data behavior and contract records, multiple dynamic read-data records,
concrete queue-head read-data records, current read-data normalization and
coverage helpers, report/residue/static-rule prose, parser/CLI/generator
tests, support-accounting surfaces, README, ROADMAP_V2, mdBook, Memory, task
tree, and Knowledge Map.

The audit must decide one of:

- public contract selection for scalar single-beat read-data over generated
  dynamic read single-beat same-ID queues;
- public contract selection for scalar last-beat read-data over generated
  dynamic read burst-last same-ID queues;
- a paired but still bounded scalar single-beat plus scalar last-beat contract;
- a narrower report/static cleanup prerequisite;
- a lower-layer prerequisite;
- deferral in favor of another exact owner.

The audit must record public source shape, report keys, completion-validity
names, generated artifact boundaries, diagnostics, residue movement,
validation gates, rollback, docs, Knowledge Map impact, and non-goals.

## Explicit Non-Goals

`.465` must not change behavior unless it selects a later implementation leaf.
The following remain future exact owners until selected:

- read-data generation over dynamic queues;
- raw `ARLEN` capture over dynamic queues;
- runtime beat-count/`RLAST` validation over dynamic queues;
- multi-beat output banks over dynamic queues;
- queue recapture widening;
- broader dynamic queue cardinality;
- mixed dynamic/static queues;
- dynamic scoreboards;
- direct backend behavior;
- backend-language variants;
- VHDL.

## Validation Plan

Because `.464` is docs-only, closeout is documentation and continuity focused:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No syntax, parser, generator, PPIF, support-accounting, schedule/check/
semantic JSON, HDL, or runtime behavior validation is claimed for `.464`
because it changes no behavior.

## Rollback

Rollback removes this selector document and fact card, reverts the `.464` task
tree/memory/README/roadmap/mdBook updates, and returns the active frontier to
the post-`.463` selector state. No code or runtime behavior rollback is needed.
