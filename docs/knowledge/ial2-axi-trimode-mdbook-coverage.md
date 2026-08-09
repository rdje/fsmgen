---
id: ial2-axi-trimode-mdbook-coverage
title: AXI IAL2 tri-mode mdBook coverage
answers:
  - "where is the AXI IAL2 mdBook chapter?"
  - "which AXI examples document IAL2 guided more-control and raw/full-control modes?"
  - "what does the shipped .axi alias mean in the AXI IAL2 book coverage?"
  - "where is the AXI AW W valid ready bundle documented?"
  - "which raw/full-control AXI IAL2 example is documented?"
date: 2026-08-09
status: current
tags: [ial2, axi, mdbook, ppif, profile-alias, documentation]
evidence: docs/book/src/16a-ial2-axi.md; ppif/axi_aw_w_valid_ready_bundle.ppif; docs/tasks/IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.md
reverify: rg -n 'AXI IAL2 Examples|axi_aw_valid_ready\.(ppif|axi)|axi_aw_w_valid_ready_bundle|axi_manager_capacity_status_(id_family|transaction_envelope|dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat)' docs/book/src/16a-ial2-axi.md
---

`docs/book/src/16a-ial2-axi.md` is the linked AXI IAL2 mdBook chapter.

The chapter documents guided mode with `ppif/axi_aw_valid_ready.ppif`, the
`.axi` profile alias, and `ppif/axi_aw_w_valid_ready_bundle.ppif`. The bundle
monitors AW and W independently and emits per-channel review artifacts plus an
aggregate wrapper/top `.fsm`; it does not drive or coordinate a transaction.

More-control mode uses capacity/status, ID-family, and transaction-envelope
examples. Raw/full-control mode uses
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif`.

The `.axi` alias is the same IAL2 model, not another layer or lowering shortcut.
