# AXI IAL2 Manager Post Mixed Dynamic/Static Issue-Order Queue Public Surface Sync Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.512`

Date: 2026-06-26

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.512` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.513`, readiness audit for scalar
read-data routing over generated mixed dynamic/static read same-ID
`issue-order-queue` completion pulses.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, generated artifact, schedule/check/semantic JSON, test, HDL/runtime
behavior, backend behavior, backend-language variant, external converter
dependency, verification-output, or VHDL behavior.

## Context Read

The selector read the current mixed dynamic/static queue surface:

- `.503` generated mixed dynamic/static write `BID` same-ID
  `issue-order-queue` behavior for one dynamic write transaction and one
  concrete static write transaction.
- `.506` generated mixed dynamic/static read single-beat `RID` same-ID
  `issue-order-queue` behavior for one dynamic read transaction and one
  concrete static read transaction.
- `.509` generated mixed dynamic/static read burst-last `RID && RLAST`
  same-ID `issue-order-queue` behavior for the same one-dynamic plus
  one-static read boundary.
- `.511` public `.ppif` downstream-contract, capability-manifest, and mdBook
  synchronization, which now advertises the generated mixed dynamic/static
  same-ID issue-order queue chain and leaves mixed queue read-data, raw
  `ARLEN`, runtime validation, and multi-beat output banks deferred.
- The all-dynamic queue read-data lineage, especially `.465` through `.467`,
  which first audited and then selected paired scalar read-data over generated
  dynamic read queue completion pulses.
- The older mixed dynamic/static response-demux read-data lineage, especially
  `.282` through `.284`, which proved scalar read-data over generated mixed
  read response-demux completions before raw `ARLEN`, runtime validation, and
  multi-beat output-bank owners.

The current generated mixed read queue reports expose queue-owned completion
sources:

```text
generated_mixed_dynamic_static_issue_order_queue_demux
generated_mixed_dynamic_static_issue_order_queue_demux_last_beat
```

Existing mixed read-data support accepts ordinary generated mixed
dynamic/static read response-demux sources:

```text
generated_mixed_dynamic_static_read_demux
generated_mixed_dynamic_static_read_demux_last_beat
```

but read-data over the generated mixed dynamic/static same-ID queue completion
sources remains outside the owned behavior.

## Why This Is Next

After `.511`, public surfaces are synchronized and the closest remaining
user-visible gap is local to read-data consumption of the already generated
mixed read queue completion pulses.

Selecting raw `ARLEN`, runtime validation, multi-beat output banks, broader
mixed cardinality, scoreboards, backend behavior, verification-code
generation, external converter dependencies such as `sv2v`, or VHDL first
would skip the existing ladder used by both prior families:

- ordinary mixed dynamic/static read response-demux shipped scalar read-data
  before raw `ARLEN`, runtime validation, and multi-beat output banks; and
- generated all-dynamic read queues shipped scalar read-data over queue
  completions before raw `ARLEN`, runtime validation, and multi-beat output
  banks over those queue completions.

The mixed queue read-data owner is still risky enough to require an audit
first. The audit must pin whether the first behavior should be a paired
single-beat plus burst-last scalar owner, a narrower single-beat-only or
last-beat-only owner, a contract-selection prerequisite, a lower-layer
prerequisite, or deferral.

## Selected `.513` Scope

`.513` must audit scalar read-data routing over generated mixed
dynamic/static read same-ID `issue-order-queue` completions before behavior
changes.

The audit must read `.512`, `.511`, `.510`, `.509`, `.506`, `.503`, the
generated dynamic queue read-data audit/contract/behavior records, the mixed
dynamic/static response-demux read-data audit/contract/behavior records, raw
`ARLEN`, runtime-validation, and multi-beat records for both dynamic queues
and mixed response-demux, current read-data normalization and coverage
helpers, report/residue/static-rule prose, parser/CLI and generator tests,
support-accounting surfaces, RAM-guard caveats, README, ROADMAP_V2, mdBook,
Memory, task tree, and Knowledge Map.

The audit must decide one of:

- public contract selection for paired scalar single-beat plus scalar
  last-beat read-data over generated mixed dynamic/static read same-ID queues;
- direct bounded implementation if the public contract is already fully
  determined by existing syntax and report vocabulary;
- a narrower single-beat-only or last-beat-only scalar read-data owner;
- a report/static cleanup prerequisite;
- a lower parser/generator/report/support-accounting prerequisite; or
- deferral in favor of another exact owner.

The expected candidate public sample stems, subject to audit confirmation, are:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue_read_data.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data.ppif
```

The audit must record source shape, report keys, completion-validity
vocabulary, diagnostics, generated artifact boundaries, support-accounting
identity expectations, validation gates, RAM-guard handling, rollback,
docs/book impact, Knowledge Map updates, and residue before any behavior
change.

## Explicit Non-Goals

`.512` and `.513` must not implement behavior unless `.513` selects a later
implementation leaf. The following remain future exact owners until selected:

- read-data generation over generated mixed dynamic/static issue-order queues;
- raw `ARLEN` capture over those mixed queues;
- runtime beat-count/`RLAST` validation over those mixed queues;
- multi-beat output banks over those mixed queues;
- multi-static or two-dynamic mixed queues;
- scoreboards;
- arbitrary cardinality;
- same-cycle widening beyond shipped onehot0/queue boundaries;
- direct backend behavior;
- backend-language variants;
- verification-code generation;
- external converter dependency selection such as `sv2v`; and
- VHDL.

## Validation Gates For `.512`

Because `.512` is docs-only, closeout is documentation and continuity
focused:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No syntax, parser, generator, PPIF, support-accounting, schedule/check/
semantic JSON, HDL, runtime, backend, external-converter, verification-output,
or VHDL validation is claimed for `.512` because it changes no behavior.

## Rollback

Rollback removes this selector document and its Knowledge Map fact card,
reverts the `.512` task tree, README, ROADMAP_V2, mdBook, and Memory updates,
and returns the active frontier to `.512`. No code or runtime behavior
rollback is needed.
