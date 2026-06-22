---
id: ial2-dynamic-write-transaction-id-capture-behavior
title: Dynamic write transaction-ID capture and BID matching ships for one response-demux.write transaction
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.223 ship?"
  - "does FSMGen generate dynamic write ID capture?"
  - "how does dynamic write BID matching work?"
  - "what sample covers dynamic write response demux?"
  - "what remains unsupported for dynamic transaction IDs after .223?"
date: 2026-06-22
status: current
tags: [ial2, axi, manager, dynamic-id, response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif | rg 'bounded_dynamic_write_bid_demux_contract|generated_capture_matching|dynamic_capture|axi0_w0_dynamic_id_q|axi0_w0_dynamic_busy_q|axi0_w0_response_demux|axi0_w0_dynamic_request_not_busy'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.223` ships generated bounded dynamic write
transaction-ID capture and `BID` response matching for one dynamic write
transaction selected by explicit `response-demux.write`.

The generated path captures the write request-ID source, for example
`axi0_awid`, at the admitted write request, stores it in generated selected-ID
state, tracks single-active ownership with generated busy state, matches raw
write responses with `BID == captured_id`, pulses the selected transaction
completion, and releases busy from that completion.

The public support-accounted sample is
`ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif`.

The report marks the covered transaction ID as
`implementation_status: generated_capture_matching` and reports
`response_demux.mode: bounded_dynamic_write_bid_demux_contract`, dynamic
capture state, generated demux rule, generated completion signal, and runtime
assertions.

Metadata-only `(id dynamic)` remains supported when no behavior clause consumes
it. The single-active write sample remains supported, while later dynamic
leaves ship selected single-active dynamic read matching, selected dynamic
read-data shapes, and bounded all-dynamic multiple write response-demux.
Mixed dynamic/static response demux, multiple dynamic read demux, same-cycle
widening/recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, and VHDL remain residue.
