---
id: ial2-axi-trimode-mdbook-coverage
title: AXI IAL2 tri-mode mdBook coverage
answers:
  - "where is the AXI IAL2 mdBook chapter?"
  - "which AXI examples document IAL2 guided more-control and raw/full-control modes?"
  - "what does the shipped .axi alias mean in the AXI IAL2 book coverage?"
  - "which raw/full-control AXI IAL2 example is documented?"
date: 2026-06-29
status: current
tags: [ial2, axi, mdbook, ppif, profile-alias, documentation]
evidence: docs/book/src/16a-ial2-axi.md; docs/book/src/SUMMARY.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg -n 'AXI IAL2 Examples|ppif/axi_aw_valid_ready\.ppif|ppif/axi_aw_valid_ready\.axi|axi_aw_valid_ready_monitor\.isf|axi_manager_capacity_status_id_family|axi_manager_capacity_status_transaction_envelope|dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat|ial2_profile_alias|fsmgen\.ial2\.protocol_intent\.axi_manager_capacity_status\.v1' docs/book/src/16a-ial2-axi.md docs/book/src/SUMMARY.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
---

`docs/book/src/16a-ial2-axi.md` is the AXI IAL2 mdBook chapter and is linked
from `docs/book/src/SUMMARY.md` under the IAL2 protocol/platform intent map.

The chapter documents guided mode with `ppif/axi_aw_valid_ready.ppif` and the
selected `ppif/axi_aw_valid_ready.axi` profile alias, more-control mode with
the manager capacity/status, ID-family, and transaction-envelope examples, and
raw/full-control mode with
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif`.

The `.axi` alias is documented as a selected profile alias over the same IAL2
model, not a separate layer and not a direct-lowering shortcut. The chapter
also records that the guided outdir path writes
`axi_aw_valid_ready_monitor.isf` and `axi_aw_valid_ready_monitor.fsm` review
artifacts.
