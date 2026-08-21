---
id: ial2-extended-axi-mixed-cardinality-claim-evidence
title: Extended AXI mixed-demux cardinalities derive from transactions and beat lanes
answers:
  - "how are the extended AXI mixed dynamic static demux lane counts verified?"
  - "why does the three-transaction mixed AXI example emit 48 RDATA and RRESP lanes?"
  - "why does the four-transaction mixed AXI example emit 64 RDATA and RRESP lanes?"
  - "how is one ARLEN capture rule per mixed AXI transaction verified?"
  - "are one-bit RLAST values independent capability claims?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, axi, mixed-demux, read-data, cardinality, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  docs/book/src/14j-extended-axi.md;
  perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm;
  ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length.ppif;
  ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat.ppif;
  ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat.ppif;
  t/1437-axi-ial2-manager-capacity-status-generator.t;
  t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh -- prove -Iperl
  t/1437-axi-ial2-manager-capacity-status-generator.t
  t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t &&
  prove -Iperl t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`CLAIM-VERIFICATION-ADOPTION.5.4.13` reviews the exact six inventory
candidates on `docs/book/src/14j-extended-axi.md`. Four candidates state
current generated behavior and use derived gates. The two one-bit RLAST
references are selector-contract inputs and therefore use reviewed-incidental
dispositions rather than pretending that a signal width is a separate
capability measurement.

The report-only burst-length fixture contains one dynamic and two static read
transactions, `r0`, `r1`, and `r2`. The ordinary lowerer iterates that exact
transaction set and emits one eight-bit raw-ARLEN store plus one request-
guarded capture rule for each transaction. The public-sample oracle separately
iterates all three names and checks the stores, rules, report identities,
scheduled FSM, and SystemVerilog. This is stronger than accepting the visible
`axi0_r2_arlen_q` endpoint as proof of the whole family.

The multi-beat lowerer emits 16 RDATA lanes, 16 RRESP lanes, one 16-bit valid
mask, one five-bit length, and one scalar worst-RRESP aggregate for every read
transaction. The one-dynamic/two-static fixture therefore derives 3 x 16 = 48
RDATA and 48 RRESP lanes plus three companion output sets. The one-dynamic/
three-static fixture derives 4 x 16 = 64 lanes of each kind plus four companion
sets. Focused tests check the first and terminal lanes, the last static RID/
RLAST guard, request-time clearing, matched-beat capture, worse-status
aggregation, generated reports, scheduled FSM, and SystemVerilog.

The `.347` and `.50` one-bit last-signal values remain exact contract
chronology at commits `89069607a` and `c52053d90`. They select a response-scope
burst-last input; later behavior gates establish what the generator actually
does with RID/RLAST.
