---
id: ial2-axi-manager-capacity-status-claim-evidence
title: AXI manager capacity/status claims derive through eight executable families
answers:
  - "how are the Chapter 16aa AXI manager capacity status claims verified?"
  - "how are the 140 AXI manager capacity status sources counted?"
  - "where do the 44 46 72 and 142 AXI manager signal counts come from?"
  - "how are the concrete multi-group AXI queue counts verified?"
  - "how are mixed dynamic static AXI queue counts verified?"
  - "how are the 70-output and 42-rule AXI read-data counts derived?"
  - "why do depth-3 AXI read-data examples have 48 lanes and 12 assertions?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, axi, manager, capacity-status, queue, read-data, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  docs/book/src/16aa-ial2-axi-manager-capacity-status.md;
  perl/FSM/Adapter/IAL2/PPIF.pm;
  perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm;
  perl/FSM/Support/RegressionCorpus.pm;
  ppif/axi_manager_capacity_status.ppif;
  ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif;
  ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif;
  ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue.ppif;
  ppif/axi_manager_capacity_status_read_data_multi_beat.ppif;
  ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif;
  ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif;
  t/1436-ial2-ppif-parser-cli.t;
  t/1437-axi-ial2-manager-capacity-status-generator.t;
  t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t;
  t/248-regression-corpus-accounting.t;
  t/297-capability-manifest.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh -- prove -Iperl
  t/1437-axi-ial2-manager-capacity-status-generator.t
  t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t &&
  prove -Iperl t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`CLAIM-VERIFICATION-ADOPTION.5.4.16` reviews the exact 43 inventory
candidates on `docs/book/src/16aa-ial2-axi-manager-capacity-status.md`. All 43
state current generated, report, source-census, or support-accounting behavior
and therefore use derived-gate dispositions. They remain separated into eight
evidence families so a repeated number is shared only when it comes from the
same builder or census.

The public-source family is independently reproducible from the repository
root. There are 140 `axi_manager_capacity_status*.ppif` sources. Scanning their
top-level clauses yields 139 ID-family, 138 transaction, 17 auto-ID lifecycle,
78 same-ID ordering, 130 response-demux, 79 read-data, and 48 burst-length
members. These are overlapping composition counts. Regression-corpus and
capability-manifest gates separately require every public source and strict
support entry.

The six foundation sources pass strict check with exact signal counts
`44/44/46/72/142/44`: base, ID-family metadata, transaction envelope,
transaction event dispatch, auto-ID lifecycle, and dynamic-ID metadata. The
lowerer and focused generator oracle independently explain the differences:
ID-only and dynamic-only metadata do not add HDL ports, a concrete transaction
adds ID assertions, event dispatch adds transaction-local fan-in, and explicit
auto-ID lifecycle adds allocator state, guards, drive, release, and assertions.

The concrete write/read multi-group reports each contain two independent
depth-2 ID groups, four admitted-request pulses, eight slot signals, 24 queue
update rules, four completion outputs and demux rules, and seven demux
assertions. Their queue-assertion totals differ deliberately: 22 for BID and 24
for RID/RLAST. The compact mixed dynamic/static write fixture instead derives
one depth-2 captured-or-static runtime-ID queue with six slot signals, 18
update rules, 15 queue assertions, two demux rules/assertions, and two
completion outputs. Its report explicitly rejects generalized scoreboard
behavior.

Read-data cardinalities follow the authored transaction set and `max-beats`.
The two-transaction single- and last-beat fixtures each derive four outputs and
two capture rules. The two-transaction 16-beat fixture derives 32 RDATA lanes,
32 RRESP lanes, two masks, two lengths, two aggregate statuses, 32 capture
rules, four beat-count rules, and eight beat assertions: 70 outputs and 42
read-data rules in total. Feeding three concrete or three dynamic transactions
through the same bank builder yields 48 data lanes, 48 status lanes, 48 capture
rules, and 12 assertions; both focused suites require the terminal `r2`
artifacts so the shared totals cannot hide a missing third bank.
