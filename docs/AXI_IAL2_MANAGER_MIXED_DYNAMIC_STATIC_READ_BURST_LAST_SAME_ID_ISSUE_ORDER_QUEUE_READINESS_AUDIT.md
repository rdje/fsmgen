# AXI IAL2 Manager Mixed Dynamic/Static Read Burst-Last Same-ID Issue-Order Queue Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.508`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.508` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.509`, direct bounded implementation of
generated mixed dynamic/static read burst-last `RID && RLAST` same-ID
`issue-order-queue` behavior for exactly one dynamic read transaction and one
concrete static read transaction.

No parser, IAL1, IAL0, SystemVerilog, support-accounting, backend-language,
external converter, verification-output, or VHDL prerequisite is required
first. The current fail-closed boundary is local to the AXI manager
capacity/status generator's mixed read issue-order queue planner,
read response-demux normalization/report projection, mixed queue behavior
admission, report vocabulary, and focused tests.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, generated artifact, report JSON, test, HDL/runtime behavior, external
converter dependency, read-data behavior, raw `ARLEN`, runtime validation,
multi-beat output-bank behavior, arbitrary-cardinality queue behavior, direct
backend behavior, backend-language variant, verification-code output, or VHDL
behavior.

## Source Anchors

The selected implementation is the smallest adjacent owner after these shipped
records:

- `.506` generated the one-dynamic plus one-concrete-static mixed read
  single-beat `RID` issue-order queue;
- `.463` generated the two-dynamic read burst-last `RID && RLAST`
  issue-order queue, including final selected-match dequeue and
  non-final no-dequeue assertions;
- `.280` generated the one-dynamic plus one-concrete-static mixed read
  burst-last `RID && RLAST` response-demux shape without queue ownership;
- `.503` generated the mixed dynamic/static write issue-order queue model for
  a dynamic enqueue source plus a static concrete literal enqueue source; and
- the focused parser/generator/support tests already have adjacent assertion
  helpers for mixed read queues and all-dynamic read burst-last queues.

The parser syntax is already selected and stable:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))
```

The intended burst-last response surface is also already stable:

```lisp
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

## Probe Evidence

A temporary `/tmp` candidate was derived from
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue.ppif`
by changing the read response scope to `burst-last` and adding the one-bit
`axi0_rlast` last signal.

The first RAM-guarded run failed closed because process-tree inspection is not
available inside the sandbox. The approved RAM-guarded rerun monitored the
candidate and failed closed before generated artifacts were emitted:

```text
AXI manager capacity/status IAL2 contract response_demux.read dynamic-id-reuse issue-order-queue requires exactly two all-dynamic read transactions, exactly three all-dynamic read transactions with response_scope single-beat or burst-last, or exactly one dynamic plus one concrete static read transaction with response_scope single-beat, in this slice
```

That diagnostic is the intended current boundary. It proves the parser accepts
the candidate and that the rejected shape reaches
`_response_demux_dynamic_read_issue_order_queue_plan`, where the mixed
dynamic/static branch currently admits only `response_scope single-beat`.

## Local Implementation Surface

Direct implementation is ready as a narrow generator slice:

- admit exactly one dynamic read transaction and one concrete static read
  transaction when `response_demux.read.response_scope` is `burst-last` and
  `last-signal` is one bit wide;
- keep `read-max-pending >= 2`, read ID-family metadata, no read
  `auto_id_lifecycle`, and explicit
  `same-id-ordering.read (dynamic-id-reuse issue-order-queue)`;
- project the mixed read burst-last report with
  `bounded_mixed_dynamic_static_read_rid_rlast_issue_order_queue_demux_contract`;
- use a distinct last-beat completion source such as
  `generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`;
- use completion semantics
  `earliest_matching_captured_or_static_runtime_id_and_last_signal`;
- carry `last_signal: axi0_rlast` and `last_signal_width: 1` into the
  generated queue report;
- reuse compact runtime-ID issue-order slots, with `axi0_arid` stored for the
  dynamic transaction and the sized concrete literal such as `4'd3` stored for
  the static transaction;
- preserve queue-owned static/dynamic same-ID overlap by using
  `captured_or_static_request_id` and
  `mixed_dynamic_static_issue_order_earliest_matching_slot`;
- reuse the existing final selected-match dequeue logic and
  `nonlast_no_dequeue` assertion machinery for queue groups carrying a
  `last_signal`; and
- report a read-specific generated scope such as
  `read_rid_rlast_one_dynamic_one_static_transaction`.

The implementation should not reuse the mixed response-demux selected-ID/busy
state directly. It should not emit static-ID reservation or dynamic
not-static-ID exclusion assertions for this queue shape, because dynamic/static
same-ID overlap is the behavior being accepted and ordered by the queue.

## Expected Public Sample

The implementation owner should add a support-accounted public PPIF sample
with this intended shape:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue.ppif
```

The public source should have:

```text
read transactions: r0 dynamic, r1 concrete static value 3
id_families.read width: 4
request ID signal: axi0_arid
response ID signal: axi0_rid
last signal: axi0_rlast, width 1
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: generated burst-last RID && RLAST completion
submit-policy: try
read-max-pending: at least 2
queue depth: 2
```

The new sample should be registered in the support-accounting corpus and
covered by the focused parser/generator/dynamic-ID/support tests.

## Validation For `.509`

The implementation should run focused checks rather than broad unguarded
regression:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
perl -Iperl -c t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue.ppif
scripts/run_with_ram_guard.sh -- env FSMGEN_DYNAMIC_CASE_FILTER=mixed_dynamic_static_read_burst_last_same_id_issue_order_queue FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- prove -Iperl t/248-regression-corpus-accounting.t
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

If a broad focused test trips the RAM guard, the owner should record the
resource caveat and replace it with a smaller in-process probe, as `.506` did.

## Non-Goals

`.508` and the selected `.509` implementation leave these for future exact
owners:

- read-data over the mixed read queue;
- raw `ARLEN` burst-length capture over the mixed read queue;
- runtime beat-count/`RLAST` validation;
- multi-beat output banks;
- multi-static mixed queues;
- two-dynamic-plus-static mixed queues;
- scoreboards;
- arbitrary queue cardinality;
- same-cycle enqueue widening beyond onehot0;
- verification-code generation;
- direct backend behavior;
- backend-language variants;
- external converter dependency selection, including `sv2v`; and
- VHDL.

## Rollback

Rollback is this audit commit. Reverting it restores `.508` as pending and
removes the `.509` implementation selection without changing implementation
behavior.
