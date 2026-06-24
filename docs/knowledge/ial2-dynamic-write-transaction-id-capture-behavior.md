---
id: ial2-dynamic-write-transaction-id-capture-behavior
title: Dynamic write transaction-ID capture, BID matching, and same-cycle recapture ship for one response-demux.write transaction
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.223 ship?"
  - "does FSMGen generate dynamic write ID capture?"
  - "how does dynamic write BID matching work?"
  - "what sample covers dynamic write response demux?"
  - "does single-active dynamic write response demux recapture on same-cycle completion?"
  - "what remains unsupported for dynamic transaction IDs after .223?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif | rg 'bounded_dynamic_write_bid_demux_contract|generated_capture_matching|dynamic_capture|same_cycle_release_recapture_policy|axi0_w0_dynamic_id_release_recapture|axi0_w0_dynamic_request_idle_or_releasing'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.223` ships generated bounded dynamic write
transaction-ID capture and `BID` response matching for one dynamic write
transaction selected by explicit `response-demux.write`.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.365` extends that same public sample with
single-active same-cycle release-and-recapture.

The generated path captures the write request-ID source, for example
`axi0_awid`, at the admitted write request, stores it in generated selected-ID
state, tracks single-active ownership with generated busy state, matches raw
write responses with `BID == captured_id`, pulses the selected transaction
completion, releases busy from that completion, and recaptures a new `AWID` when
the generated completion occurs in the same cycle as a new admitted `w0`
request.

The public support-accounted sample is
`ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif`.

The report marks the covered transaction ID as
`implementation_status: generated_capture_matching` and reports
`response_demux.mode: bounded_dynamic_write_bid_demux_contract`, dynamic
capture state, generated demux rule, generated completion signal, and runtime
assertions. After `.365`, `dynamic_capture` also reports
`same_cycle_release_recapture_policy: single_active_dynamic_write` and
`release_recapture_rule: axi0_w0_dynamic_id_release_recapture`.

Metadata-only `(id dynamic)` remains supported when no behavior clause consumes
it. The single-active write sample remains supported, while later dynamic
leaves ship selected single-active dynamic read matching, selected dynamic
read-data shapes, bounded all-dynamic multiple write response-demux, and
bounded all-dynamic multiple read single-beat response-demux.
Mixed dynamic/static recapture, multiple dynamic write request widening,
multiple dynamic read burst-last/read-data widening, read `RID`/`RLAST`
recapture, dynamic same-ID queues, scoreboards, direct backend behavior, and
VHDL remain residue.
