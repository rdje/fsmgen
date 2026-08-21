---
id: ial2-axi-example-claim-evidence
title: Chapter 16a AXI examples retain source-specific public and runtime evidence
answers:
  - "how are the Chapter 16a AXI IAL2 example claims verified?"
  - "which tests prove the AXI AW W B AR and R public examples?"
  - "how are single-beat and fixed-four AXI compositions distinguished?"
  - "why are the 304 306 308 protocol fixture totals historical?"
  - "how is the current 140-source AXI manager family count derived?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, axi, examples, composition, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  docs/book/src/16a-ial2-axi.md;
  perl/FSM/IAL2/ProtocolIntent;
  ppif/axi_aw_driver.ppif;
  ppif/axi_w_driver.ppif;
  ppif/axi_w_burst4_driver.ppif;
  ppif/axi_b_response_acceptor.ppif;
  ppif/axi_ar_driver.ppif;
  ppif/axi_r_beat_acceptor.ppif;
  ppif/axi_write_request_composition.ppif;
  ppif/axi_write_burst4_request_composition.ppif;
  ppif/axi_write_transaction_composition.ppif;
  ppif/axi_read_transaction_composition.ppif;
  ppif/axi_read_burst4_transaction_composition.ppif;
  t/1499-ial2-axi-aw-driver.t;
  t/1500-ial2-axi-w-driver.t;
  t/1501-ial2-axi-b-response-acceptor.t;
  t/1502-ial2-axi-write-request-composition.t;
  t/1503-ial2-axi-write-transaction-composition.t;
  t/1504-ial2-axi-ar-driver.t;
  t/1505-ial2-axi-r-beat-acceptor.t;
  t/1506-ial2-axi-read-transaction-composition.t;
  t/1507-ial2-axi-read-burst4-transaction-composition.t;
  t/1508-ial2-axi-w-burst4-driver.t;
  t/1509-ial2-axi-write-burst4-request-composition.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh -- prove -Iperl
  t/1468-ial2-ppif-neutral-valid-ready-bundle.t
  t/1499-ial2-axi-aw-driver.t t/1500-ial2-axi-w-driver.t
  t/1501-ial2-axi-b-response-acceptor.t
  t/1502-ial2-axi-write-request-composition.t
  t/1503-ial2-axi-write-transaction-composition.t
  t/1504-ial2-axi-ar-driver.t t/1505-ial2-axi-r-beat-acceptor.t
  t/1506-ial2-axi-read-transaction-composition.t
  t/1507-ial2-axi-read-burst4-transaction-composition.t
  t/1508-ial2-axi-w-burst4-driver.t
  t/1509-ial2-axi-write-burst4-request-composition.t
---

`CLAIM-VERIFICATION-ADOPTION.5.4.15` reviews the exact 46 inventory
candidates on `docs/book/src/16a-ial2-axi.md`. Forty-two state current
behavior and use derived gates. Four support-accounting fragments preserve
the time-local `304/345`, `306/347`, and `308/349` shipment checkpoints and
remain reviewed historical measurements rather than current totals.

The current initiator catalog contains six channel primitives and five bounded
compositions. Each public PPIF source retains its own lowerer and focused
oracle. Those tests inspect grammar, reports, schedules, semantic/topology
output, generated artifacts, fail-closed neighbors, Verilator/Yosys results,
and compiled handshake behavior instead of accepting repeated prose widths or
counts as self-validating.

The evidence keeps materially different boundaries separate: AW and W request
acceptance, B and R response ownership, single-beat request completion, full
write response retirement, fixed-four W progression, and fixed-one/fixed-four
read completion. Address alignment and 4-KiB controls, zero strobes, WLAST,
RID/BID and RLAST mismatches, stalls, busy commands, and reset recovery act as
separating controls for their owning source family.

The Chapter 16aa cross-reference is current: an independent repository glob
derives exactly 140 `ppif/axi_manager_capacity_status*.ppif` sources, while
the corpus-accounting oracle watches their support identities. This live
family count is distinct from the three historical whole-corpus checkpoints.
