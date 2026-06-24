# AXI IAL2 Manager Single-Active Dynamic Same-ID Reject Mapping Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.440`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.440` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.441`, public contract selection for
single-active dynamic same-ID reject mapping over existing generated
single-active response-demux assertions.

The audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, runtime behavior, direct backend behavior, backend-language
variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The audit read:

- `.439` post `.438` selector;
- `.438` generated dynamic same-ID reject enforcement mapping behavior;
- `.437` generated reject mapping readiness audit;
- `.436` metadata-first `(dynamic-id-reuse reject)` parser/report behavior;
- `.434` public dynamic same-ID policy contract;
- `.365`, `.368`, and `.372` single-active dynamic write, read single-beat,
  and read burst-last release-and-recapture behavior records;
- current `AxiManagerCapacityStatus` single-active dynamic response-demux
  builders, assertion specs, and report projection;
- focused `t/1436`, `t/1437`, and `t/1438` expectation surfaces;
- public single-active dynamic response-demux samples;
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

## Current Generated Surface

Guarded compact schedule probes read:

```text
ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif
ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif
ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif
```

Those samples report the following existing generated surfaces:

| Family | Mode | Ownership | Generated assertions |
| --- | --- | --- | --- |
| write `BID` | `bounded_dynamic_write_bid_demux_contract` | `single_active_dynamic_write` | `axi0_w0_dynamic_request_idle_or_releasing`, `axi0_write_dynamic_response_active_match`, `axi0_w0_dynamic_completion_active` |
| read `RID` | `bounded_dynamic_read_rid_demux_contract` | `single_active_dynamic_read` | `axi0_r0_dynamic_request_idle_or_releasing`, `axi0_read_dynamic_response_active_match`, `axi0_r0_dynamic_completion_active` |
| read `RID && RLAST` | `bounded_dynamic_read_rid_rlast_demux_contract` | `single_active_dynamic_read` | `axi0_r0_dynamic_request_idle_or_releasing`, `axi0_read_dynamic_response_active_match`, `axi0_r0_dynamic_completion_active` |

The write sample keeps `same_id_ordering` in `response_demux.residue`
alongside unrelated read residues. The read samples keep `same_id_ordering`
alongside `read_data_interleaving` and `bursts`.

## Current Fail-Closed Boundary

Temporary guarded probes inserted:

```lisp
(same-id-ordering
  (write (dynamic-id-reuse reject)))
```

or:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse reject)))
```

into the single-active public samples. All three currently fail closed with
the expected `.438` diagnostic:

```text
AXI manager capacity/status IAL2 contract response_demux.<family> dynamic-id-reuse reject generated enforcement requires generated multi-active dynamic response-demux no-active-same-ID assertions in this slice
```

That boundary is correct until a later owner defines a single-active-specific
report contract.

## Readiness Finding

Single-active dynamic response-demux is ready for a public contract selection,
not for direct behavior change in this audit.

The existing generated `*_dynamic_request_idle_or_releasing` assertion is
stronger than same-ID-only rejection for the single-active family: it prevents a
new accepted dynamic request while the single dynamic transaction is active,
except for the already generated same-cycle completion release case. With only
one dynamic transaction in the family, this excludes any concurrent active
dynamic transaction with the same runtime ID.

However, it is not the same evidence model as `.438`. The multi-active mapping
credits generated `*_dynamic_request_no_active_same_id` assertions and pairwise
`*_dynamic_active_id_unique` assertions. Single-active shapes have neither,
because there is no sibling dynamic transaction to compare. Reusing the `.438`
report fields would overclaim the assertion surface.

## Selected `.441` Boundary

`.441` should select the public report contract for single-active dynamic
same-ID reject mapping before implementation. It should decide exact field
names and values for:

- implementation status, such as a single-active-specific generated reject
  status rather than `generated_no_active_same_id_reject`;
- enforcement, such as generated idle-or-releasing assertions;
- assertion enforcement as runtime assertions;
- response-demux coverage and response-demux mode/source metadata;
- covered dynamic transaction names;
- generated idle-or-releasing assertion names;
- generated active-match and completion-active assertion names;
- family-local residue movement for `same_id_ordering` and
  `dynamic_id_same_id_ordering`.

The contract should preserve:

```text
accepted_same_id_reuse: false
generated_queue_behavior: false
generated_scoreboard_behavior: false
```

and should decide whether `request_conflict_policy` remains
`no_active_same_id` or moves to a more precise single-active spelling.

## Deferred Work

The following remain outside `.440` and `.441` unless a later task-tree owner
selects them:

- direct acceptance/report implementation;
- one-dynamic mixed dynamic/static reject mapping;
- dynamic `issue-order-queue` and dynamic `scoreboard` source policy values;
- dynamic per-ID queues, scoreboards, request arbitration, overflow handling,
  ambiguity tracking, or same-cycle request widening;
- new generated rules, storage, assertions, HDL, runtime behavior, direct
  backend behavior, backend-language variants, or VHDL.

## Validation

Validation for `.440` included:

- guarded compact schedule probes for the three single-active response-demux
  public samples;
- guarded temporary fail-closed probes for adding `dynamic-id-reuse reject` to
  the three single-active public samples;
- Knowledge Map generation/check;
- mdBook build;
- docs path audit;
- memory architecture check;
- diff check;
- doctrine gate.

## Rollback

Rollback for `.440` is this docs-only audit commit. Reverting it removes the
`.441` selection, fact card, task-tree advancement, live-doc updates, and
resume pointer update without changing generated behavior.
