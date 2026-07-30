---
id: ial2-post-exact-four-paired-alias-next-owner-selection
title: Two-subordinate exact-four paired AHB readiness is the next bounded IAL2 owner
answers:
  - "what follows the exact-four paired AHB profile alias?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.826 select?"
  - "is two-subordinate exact-four paired AHB next?"
  - "why audit two-window exact-four before implementation?"
  - "what static evidence supports two-window exact-four AHB readiness?"
  - "does the post-exact-four paired selector activate HIAL and VIAL?"
date: 2026-07-30
status: current
tags: [ial2, ahb, busy, exact-four, composition, two-subordinate, selector, readiness, hial, vial]
evidence: docs/IAL2_POST_EXACT_FOUR_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif; t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t; t/1537-ial2-ahb-exact-four-paired-busy-composition.t; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.826|TWO-SUBORDINATE-EXACT-FOUR|2,180,377|331 protocol|372 supported|55 AHB|8 qualified BUSY|event-capable compiled' docs/IAL2_POST_EXACT_FOUR_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md
---

After the one-window exact-four paired generic/profile pair shipped at
330/371/54 split 27/27, parent selector `.826` selected proposed readiness
audit
`IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`.

A same-volume disposable 6,645-byte generic candidate strict-checks with zero
diagnostics at `ahb_tb`/four children/29 signals and unmatched support, emits
exact 4 IAL1/5 IAL0 artifacts, preserves width-three requester load four,
`before_beat=2`/`beats=4`, two status/control windows, both child/propagated
`parks_on=[busy]`, and one-hot response ownership. Normalized semantic schema
v1, real repo-relative read-only shell-disabled MCP, and public `--verify-hdl`
all pass. The exact 11-file/2,180,377-byte workspace was removed without
residue, leaving only the pre-existing 491-byte `xcrun_db` cache.

The audit, not this selector, must prove assertion-enabled two-command runtime
at 10 presentations/8 beats/2 BUSY episodes/8 qualified BUSY events/2 resumed
`SEQ`/status `44332211`/control `88776655`. If ready, a separate contract may
project 331/372/55 split 28 `.ppif`/27 `.ahb`.

Counts above four, new policy/status/burst/signal behavior, generic priority,
HIAL/VIAL, verification generation, VHDL, and scale remain separate. HIAL/VIAL
retains event-capable compiled Verilator as the portable-fast supported-subset
profile, separate from full-language/SystemVerilog-UVM authority and
independently qualified VHDL/mixed-language profiles.

Clean selector commit `4abb0a357` activates only readiness audit `.1`; the
public 330/371/54 boundary remains unchanged during activation.

Completed audit `.1` directly proves real read-only shell-disabled MCP,
public `--verify-hdl`, and assertion-enabled two-command
10/8/2/8/2/`44332211`/`88776655` runtime. It selects pending generic contract
`.2` at projected 331/372/55 split 28 `.ppif`/27 `.ahb`.

Clean audit commit `a5d162d60` plus activation `93a7f2089` satisfy the contract
boundary. `.2` froze the exact source/support/t1539/testbench contract, and
completed `.3` now ships it at 331/372/55 split 28 `.ppif`/27 `.ahb` with the
selected assertion-enabled runtime.

Clean child behavior commit `a62ddb705` activates no-behavior parent selector
`.827`; the `.826` handoff is complete and public behavior remains 331/372/55
while `.827` owns the next exact selection.

Completed `.827` selects pending `.828`, the byte-identical matching
two-window exact-four `.ahb` alias. Future t1540 owns parity without a second
runtime; t1539 remains the shared assertion-enabled authority.
