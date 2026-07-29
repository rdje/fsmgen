---
id: ial2-post-exact-three-paired-alias-next-owner-selection
title: Two-subordinate exact-three paired AHB readiness is the next bounded IAL2 owner
answers:
  - "what comes after the exact-three paired AHB profile alias?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.819 select?"
  - "is two-subordinate exact-three paired AHB next?"
  - "why is two-subordinate exact-three audited before implementation?"
  - "what static evidence supports the two-window exact-three AHB audit?"
  - "does the post-paired-alias selector activate HIAL and VIAL?"
date: 2026-07-29
status: current
tags: [ial2, ahb, busy, exact-three, composition, two-subordinate, selector, readiness, hial, vial]
evidence: docs/IAL2_POST_EXACT_THREE_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif; t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t; t/1531-ial2-ahb-exact-three-paired-busy-composition.t; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.819|TWO-SUBORDINATE-EXACT-THREE|four IAL1|five IAL0|29 signals|6 qualified BUSY|325 protocol|366 supported|49 AHB|HIAL/VIAL' docs/IAL2_POST_EXACT_THREE_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md
---

After the one-subordinate exact-three generic/profile pair shipped at
324/365/48 split 24/24, parent selector `.819` selected proposed readiness
audit
`IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`.

A same-volume disposable 6,650-byte generic candidate strict-checks with zero
diagnostics at `ahb_tb`/four children/29 signals, emits exact 4 IAL1/5 IAL0
artifacts, preserves requester `before_beat=2`/`beats=3`, both subordinate and
propagated `parks_on=[busy]`, one-hot response ownership, normalized semantic
schema v1/root `top`, and passes `--verify-hdl`. It remains intentionally
unmatched by support accounting. The exact three-file/62,001,772-byte workspace
was removed with no residue.

The audit, not this selector, must prove real read-only shell-disabled MCP and
assertion-enabled two-command runtime at 10 presentations/8 beats/2 BUSY
episodes/6 qualified BUSY events/2 resumed `SEQ`/status `44332211`/control
`88776655`. If ready, a separate contract may project 325/366/49 split 25/24.
HIAL/VIAL remains proposed with portable-fast event-capable compiled Verilator
separate from full-language/SystemVerilog-UVM authority and separately
qualified VHDL/mixed-language profiles.

Clean selector commit `e2109a2ba` now activates only the selected audit `.1`;
no public source, support, test, artifact, HDL/runtime, or HIAL/VIAL behavior
changes in activation.

Completed audit `.1` directly proves real read-only shell-disabled MCP, public
`--verify-hdl`, and assertion-enabled two-command
10/8/2/6/2/`44332211`/`88776655` runtime. It selects proposed generic contract
`.2` at projected 325/366/49 split 25/24; `.2` remains inactive until the clean
audit commit and separate activation.
