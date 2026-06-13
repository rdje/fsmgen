---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is AXI RLAST report alignment
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.54?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.53?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.52?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.51?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.50?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.49?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.47?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.48?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.46?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.45?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.44?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.43?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.42?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.41?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.40?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.39?"
  - "what comes after auto-ID lifecycle residue alignment?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.38?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.37?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.36?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.35?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.34?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.33?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.32?"
  - "is the full AXI manager implemented after Valid-Ready?"
  - "what must happen before the next AXI manager behavior?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, read-data, rdata, rresp, capture, metadata, behavior, selector, bursts, rlast, completion, interleaving, per-id, contract, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.55|AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION|report-only burst-last|generated burst/last-beat tracking|RLAST report' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

After the shipped Valid-Ready, bundle, capacity/status, ID-family metadata,
transaction-envelope metadata, transaction event dispatch, concrete
transaction ID assertion, auto-ID lifecycle metadata, bounded auto-ID
request-ID drive, write response-demux metadata, IAL1 rule-pulse action,
generated write `BID` response-demux behavior, auto-ID lifecycle
report-residue alignment, generated auto-ID same-ID avoidance, read
response-demux contract selection, read response-demux parser/report metadata,
read response-demux behavior readiness audit, bounded generated single-beat
read `RID` response-demux behavior, post-read-demux next-slice selection, and
read-data/burst readiness audit, read-data contract selection, read-data
parser/report metadata first slice, read-data capture readiness audit, and
generated read-data capture behavior first slice, post-read-data selector, and
AXI burst/`RLAST` readiness audit, burst-last contract selector,
parser/report metadata first slice, generated behavior readiness audit,
generated `RLAST` behavior first slice, and post-`RLAST` next-slice selector,
the next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.55`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.55` owns narrow AXI `RLAST` report
alignment. It must update generated schedule-report prose that still says
burst-last `RLAST` is report-only and still says generated burst/last-beat
tracking remains outside the capacity/status shell. The structured
`response_demux.read` report and generated artifacts are already behavior
bearing after `.53`; `.55` aligns the user-facing report text before larger
read-data reassembly or manager-behavior work resumes.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.47` shipped generated single-beat
`RDATA`/`RRESP` capture behavior for explicit `read-data` contracts. The next
selector, `IAL2-FEATURE-COMPLETENESS-FRONTIER.48`, selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.49`: AXI burst/`RLAST` completion
readiness. The next slice is an audit because the current public contract is
single-beat and has no selected last-beat/beat-count completion boundary for
multi-beat reassembly.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.49` audited that boundary and selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.50`: public AXI burst/`RLAST` completion
contract selection. The selector must decide `RLAST` signal ownership, burst
length or beat-count metadata, beat-valid versus transaction-complete
semantics, data/status capture granularity, diagnostics, generated artifact
boundaries, and report/residue movement before parser/report metadata or
generated behavior changes.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.50` selected additive read
`response-demux` syntax: `response-scope burst-last` plus one-bit
`last-signal`. It keeps generated transaction completion as the last-beat
pulse, publishes no per-transaction beat-valid output, uses `RLAST` rather
than `ARLEN`/beat-count metadata for this first boundary, and rejects the
current single-beat `read-data` contract when paired with burst-last response
demux.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.51` shipped parser/report metadata and
static validation for that contract. The parser accepts
`response-scope burst-last` with exactly one width-1 `last-signal`, reports
structural `response_demux.read` metadata with `generated_behavior: false` and
`generated_burst_last_read_demux` residue, rejects burst-last combined with
the current single-beat `read-data` contract, and keeps generated `.isf`,
`.fsm`, and HDL behavior unchanged.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.52` audited generated burst-last/`RLAST`
completion behavior readiness and found no new IAL1/IAL0/SystemVerilog
prerequisite. `IAL2-FEATURE-COMPLETENESS-FRONTIER.53` shipped generated
`RLAST` input, generated `RID` matching, last-beat transaction completion
pulse outputs/rules/assertions, report/residue movement, same-ID coverage
movement, and HDL reachability for the burst-last sample. The next active
slice was `IAL2-FEATURE-COMPLETENESS-FRONTIER.54`, the post-`RLAST`
selector.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.54` selected `.55` after finding report
drift in `enforced_static_rules` and `unsupported_residue`. Direct multi-beat
read-data reassembly is deferred because the current public `read-data`
contract remains single-beat and is still rejected when paired with
`response_demux.read.response_scope burst_last`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.32` aligned the emitted report for
explicit generated write response demux. At that point,
`auto_id_lifecycle.residue` was `[same_id_ordering]`, while samples without
generated demux kept their existing `response_demux` residue. The later `.35`
slice removed that covered same-ID residue from generated response-demux
samples.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.33` selected `.34` as the AXI same-ID
ordering readiness audit because `same_id_ordering` was then the common
remaining ID/auto-ID/write-demux residue after generated write `BID` demux
and auto-ID residue alignment.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.34` decided whether the first same-ID
ordering step should be static/report classification, generated assertions,
allocator constraints, per-ID issue-order queues/scoreboards, or a smaller
IAL1/IAL0/SystemVerilog prerequisite before behavior changes.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.34` selected the bounded generated
auto-ID same-ID avoidance path: pairwise active selected-ID assertions plus
machine-readable `same_id_ordering` report metadata. No new public syntax and
no IAL1/IAL0/SystemVerilog prerequisite are needed for that first
implementation.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.35` shipped that first implementation.
The response-demux sample now reports empty `auto_id_lifecycle.residue`,
`response_demux.residue: [read_response_demux, read_data_interleaving,
bursts]`, and `same_id_ordering.generated_behavior: true`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.36` selected read response-demux
readiness as the next exact slice. `IAL2-FEATURE-COMPLETENESS-FRONTIER.37`
audited whether bounded read `RID` response matching can be isolated safely.
It selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.38`, a public
contract-selection slice, because the first read demux contract must decide
single-beat/non-burst scope, `response-event` semantics, read metadata
requirements, diagnostics, report shape, and residue before parser/report
metadata or behavior changes.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.38` selected that public contract:
`(response-demux (read (response-event EVENT) (response-scope single-beat)
(transaction-completion generated)))`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.39` shipped parser/report metadata and
static validation for that read arm. It added
`ppif/axi_manager_capacity_status_read_response_demux.ppif`, support
accounting, check JSON/semantic JSON coverage, and structural
`response_demux.read` metadata with `generated_behavior: false` and
`generated_read_rid_demux` residue while keeping generated read `.isf`,
`.fsm`, and HDL behavior unchanged.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.40` audited generated read `RID`
response-demux behavior readiness and selected direct bounded single-beat
implementation. No new IAL1, IAL0, or SystemVerilog prerequisite was required.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.41` shipped generated read `RID`
response-demux behavior by making response-demux helpers family-aware, adding
`RID` as a generated input, emitting generated read completion pulse
outputs/rules/assertions, and keeping read capacity release plus auto-ID
release driven by those generated completion pulses.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.42` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.43` as a readiness audit for read-data
payload, burst/`RLAST`, and per-ID ordering/reassembly ownership after
generated read response demux. It selected an audit instead of direct
implementation because payload capture, last-beat semantics, different-ID
interleaving, and concrete-ID/per-ID ordering queues are coupled.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.43` audited that coupled read-side
cluster and selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.44`, a bounded
public read-data payload/status contract selector, before parser/report
metadata or generated behavior changes. The likely first scope is single-beat
`RDATA`/`RRESP` capture layered on shipped generated read `RID` demux, but the
public source syntax, report artifacts, target binding semantics, `RLAST`
ownership, and interleaving/burst residue policy must be selected first.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.44` selected explicit bounded
`(read-data (read ...))` syntax for single-beat `RDATA`/`RRESP` capture. The
contract requires `capture-scope single-beat`, `completion-source
response-demux`, a positive-width `data-signal`, a 2-bit `status-signal`,
`interleaving single-beat-by-rid`, and per-transaction generated data/status
outputs. It selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.45` for parser/report
metadata and static validation first, with generated data-capture behavior
unchanged.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.45` shipped parser/report metadata and
static validation for the bounded read-data contract. The public `.ppif`
parser accepts one `read-data` read arm, the generator reports structural
`read_data` metadata with `generated_behavior: false`, the checked-in
`ppif/axi_manager_capacity_status_read_data.ppif` sample is support-accounted,
and focused tests prove generated `.isf`, `.fsm`, and HDL behavior remains
unchanged from the read response-demux sample.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.46` audited generated single-beat
read-data capture behavior readiness after that metadata slice. It concluded
that generated `RDATA`/`RRESP` capture can be implemented directly with no new
IAL1, IAL0, or SystemVerilog prerequisite. Existing width-bearing IAL1
inputs/outputs and normal guarded rule assignments can hold captured
payload/status values under the generated read response-demux completion
pulse.

The full AXI manager is not implemented yet. Bounded single-beat read `RID`
demux and generated single-beat `RDATA`/`RRESP` capture are shipped. Per-ID
same-ID response queues, authored concrete-ID same-ID ordering, read-data
interleaving/reassembly, bursts, queued/blocking policy, profile aliases,
full-manager syntax, and VHDL remain future exact-owner work. The `.53`
behavior slice advanced to `.54`, the post-`RLAST` selector.
VHDL stays deferred until the SystemVerilog-backed IAL0/IAL1/IAL2 path is
feature-complete enough to reopen backend parity.
