---
id: ial2-dynamic-write-same-cycle-recapture-behavior
title: Single-active dynamic write same-cycle release-and-recapture is generated
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.365 ship?"
  - "does dynamic write response demux recapture AWID on same-cycle BID completion?"
  - "what is same_cycle_release_recapture_policy for dynamic write?"
  - "what assertion replaced dynamic write request_not_busy?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, write, same-cycle, recapture, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif | rg 'same_cycle_release_recapture_policy|axi0_w0_dynamic_id_release_recapture|axi0_w0_dynamic_request_idle_or_releasing|bounded_dynamic_write_bid_demux_contract'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.365` ships generated same-cycle
release-and-recapture for the existing support-accounted
`ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif` sample.
No new PPIF source syntax or support-accounting entry is required.

The generated response-demux rule still matches the raw `BID` response against
the pre-update selected dynamic ID. When the generated `axi0_w0_complete` pulse
and a new admitted `axi0_w0_request` occur in the same cycle, FSMGen emits
`axi0_w0_dynamic_id_release_recapture` to capture the new `axi0_awid` and keep
`axi0_w0_dynamic_busy_q` asserted.

The report keeps `bounded_dynamic_write_bid_demux_contract`, adds
`same_cycle_release_recapture_policy: single_active_dynamic_write` under
`dynamic_capture`, and replaces `axi0_w0_dynamic_request_not_busy` with
`axi0_w0_dynamic_request_idle_or_releasing`. Multiple dynamic write request
widening, mixed dynamic/static recapture, read recapture, read-data payload
capture, dynamic same-ID queues, direct backend variants, and VHDL remain future
exact-owner work.
