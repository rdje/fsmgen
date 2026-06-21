# AXI IAL2 Manager Post Mixed Auto-ID Queue-Head Runtime-Validation Support Cleanup Next Slice Selection

Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.205`

Date: 2026-06-21

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.206`, a readiness audit for
generated mixed multi-beat output-bank behavior over the selected same-family
mixed auto-ID plus depth-2 concrete same-ID queue-head read burst-last
runtime-validation shape.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated-artifact, test, or HDL behavior.

## Evidence Read

- `.204` support cleanup:
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP.md`.
- `.203` selector:
  `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`.
- `.202` runtime-validation behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`.
- `.200` report-only raw-`ARLEN` burst-length behavior, `.197` mixed scalar
  read-data behavior, and `.194` mixed response-demux behavior.
- Multiple/mixed depth-3 precedent: `.187` -> `.188` cleanup, `.189`
  selector, `.190` multi-beat readiness audit, and `.191` implementation.
- Current implementation and test surfaces:
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`,
  `_read_data_response_demux_transaction_coverage`,
  `_read_data_generated_artifacts`,
  `t/1437-axi-ial2-manager-capacity-status-generator.t`, and
  `t/1436-ial2-ppif-parser-cli.t`.
- Public surfaces: README, ROADMAP_V2, mdBook, downstream integration spec,
  public interface contract, task tree, Memory, and Knowledge Map.

## Live Report State

The `.202` runtime sample:

```text
ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.ppif
```

reports generated runtime beat-count/`RLAST` validation and removes
`generated_beat_count_validation` residue. Its remaining `read_data.residue`
is:

```text
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
```

That is the same payload/output residue family that prior queue-head paths
cleared with bounded multi-beat output-bank support, but this shape combines
one auto-ID transaction with one depth-2 concrete same-ID queue-head group and
uses the mixed generated completion boundary. It should therefore be audited
before implementation.

## Selection Rationale

The direct next behavior-family candidate is mixed multi-beat read-data. The
public/static cleanup is complete, and the runtime sample now has only the
multi-beat payload/output/aggregation residue left in the read-data family.

The selected next leaf is an audit, not implementation, because `.206` must
confirm:

- whether the transaction-list-driven multi-beat artifact helpers already
  compose over the mixed auto-ID plus concrete queue-head transaction list;
- whether the current admission predicate fails closed only at the mixed
  multi-beat boundary;
- whether output-bank initialization, lane capture, valid-mask, length, and
  scalar `RRESP` aggregation expectations are identical to the adjacent
  queue-head precedents or need a smaller prerequisite;
- which exact public sample, support-accounting identity, and preservation
  probes would be safe for a later implementation leaf.

## Selected `.206` Boundary

`.206` should audit readiness for generated multi-beat output-bank behavior
over the `.202` mixed runtime-validation shape:

- read family;
- `response_scope burst-last`;
- same-family mixed auto-ID lifecycle plus one depth-2 concrete same-ID
  queue-head read group;
- one auto-ID read transaction and two concrete-ID read transactions;
- existing runtime-assertion raw-`ARLEN` burst-length metadata;
- multi-beat read-data capture with per-beat output-bank shape and
  worst-observed scalar `RRESP` aggregation.

The audit should not change parser, generator, PPIF sample,
support-accounting catalog, generated artifacts, validation, test, or HDL
behavior.

## Deferred Work

The following remain future exact-owner work unless `.206` explicitly selects
one:

- generated mixed multi-beat output-bank implementation;
- broader concrete same-ID queues beyond selected covered groups;
- group-local simultaneous enqueue widening;
- write-family read-data;
- packed burst-vector outputs;
- alternate full burst payload assembly;
- verification-output generation;
- direct backend lowering;
- VHDL/backend-language variants.

## Validation Gates For `.206`

The audit should use compact live probes where useful:

- schedule/check probes for `.202`, `.200`, `.197`, and `.194` preservation;
- a temporary mixed multi-beat PPIF mutation to locate the exact fail-closed
  diagnostic;
- comparison against one-depth-3, depth-2 multi-group, and multiple/mixed
  depth-3 multi-beat precedents;
- Knowledge Map, mdBook, docs path, memory architecture, README numbering, and
  diff hygiene gates before commit.

## Rollback Boundary

Rolling this selector back removes this note and the `.205` task-tree/live-doc
updates. It does not change parser, generator, PPIF sample,
support-accounting catalog, validation, generated artifacts, tests, or HDL.
