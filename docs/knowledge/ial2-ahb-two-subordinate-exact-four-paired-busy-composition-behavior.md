---
id: ial2-ahb-two-subordinate-exact-four-paired-busy-composition-behavior
title: Two-window exact-four paired AHB BUSY ships with assertion-enabled runtime
answers:
  - "does FSMGEN ship two-subordinate exact-four paired AHB BUSY?"
  - "what does t1539 prove?"
  - "what is the two-window exact-four AHB runtime result?"
  - "how many AHB IAL2 paths ship after two-window exact-four?"
  - "how does two-window exact-four appear in semantic JSON and MCP?"
  - "does the two-window exact-four AHB profile alias ship?"
  - "what does t1540 prove?"
  - "where do t1539 temporary files live?"
date: 2026-07-30
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-four, two-subordinate, runtime, semantics, mcp]
evidence: ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/Support/RegressionCorpus.pm; t/1539-ial2-ahb-two-subordinate-exact-four-paired-busy-composition.t; t/1540-ial2-ahb-two-subordinate-exact-four-paired-busy-composition-profile-alias.t; t/data/ahb_two_subordinate_exact_four_paired_busy_composition_tb.svt; docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; docs/tasks/IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; docs/book/src/16c-ial2-ahb.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove t/1540-ial2-ahb-two-subordinate-exact-four-paired-busy-composition-profile-alias.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

FSMGEN ships the generic topology-first source
`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif`
and its byte-identical `.ahb` profile alias.
It is the exact six-field identity/requester/cardinality transform of the
two-window exact-three source and reuses the existing requester, two
subordinate, and interconnect generators. It emits four IAL1 and five IAL0
artifacts under `ahb_tb` with root `top` and four children.

t1539 proves exact source/support/report/artifact behavior, normalized semantic
schema 1, real repo-relative read-only shell-disabled MCP, public verifier,
repository-local output, explicit unmatched-neighbor diagnostics, and
Verilator 5.046 `--timing`/`-j 1` with all assertions. Runtime is exactly 2
commands / 10 presentations / 8 beats / 2 BUSY episodes / 8 qualified BUSY
events / two `4 -> 3 -> 2 -> 1 -> 0` retirements / 2 resumed `SEQ` / status
`0x44332211` / control `0x88776655`.

Current accounting is 332 protocol / 373 supported+strict / 56 AHB paths split
28 `.ppif` / 28 `.ahb`. t1540 proves byte/parse/report/residue/strict/schedule/
artifact/semantic/read-only-MCP/repository-local-output/verifier parity without
a second simulation; t1539 remains the shared runtime. Counts above four,
broader BUSY semantics, generic priority, HIAL/VIAL, VHDL, verification generation,
portability, scale, and decision `0020` remain separate.

Clean behavior commit `a62ddb705` activates no-behavior parent selector
`.827`; current 331/372/55 behavior is unchanged while that selector chooses
one exact next roadmap owner.

Completed `.827` selected data-only alias implementation `.828` at projected
332/373/56 split 28/28. Completed `.828` now ships the alias and exact support
identity; t1540 owns parity and t1539 remains the shared assertion-enabled
runtime.

Clean selector commit `bc29c2e49` activates only `.828`; the alias remains
absent and current 331/372/55 behavior is unchanged during activation.

Clean behavior commit `3519cde33` activates parent selector `.829` without a
behavior change. Current 332/373/56 split 28/28 behavior remains fixed while
the selector chooses one exact next roadmap owner.
