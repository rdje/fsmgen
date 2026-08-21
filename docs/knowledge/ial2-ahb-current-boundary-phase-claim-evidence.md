---
id: ial2-ahb-current-boundary-phase-claim-evidence
title: AHB current-boundary and phase-pipeline claims close the Chapter 16c review
answers:
  - "how are the final Chapter 16c AHB claims verified?"
  - "how is the current AHB generalized BUSY residue verified?"
  - "how is exact-three AHB requester runtime verified?"
  - "how are boundary-free generated AHB address phases verified?"
  - "how is direct AHB Q-named completion-edge retention verified?"
  - "is the Chapter 16c claim-verification group complete?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, ahb, current-boundary, residue, exact-three, phase-pipeline, direct-seed, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  doctrine/claim_verification/disposition_groups.jsonl;
  fsm/ahb_lite_subordinate.fsm;
  perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm;
  perl/FSM/Support/LanguageSurfaceSection.pm;
  perl/FSM/Support/RegressionCorpus.pm;
  ppif/ahb_requester_busy_insert_three.ppif;
  ppif/ahb_requester_busy_insert_four.ppif;
  t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t;
  t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t;
  t/1513-ial2-ahb-paired-busy-composition.t;
  t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t;
  t/1518-ial2-ahb-mdbook-current-surface-truthfulness.t;
  t/1519-ial2-ahb-pipelined-active-transfer-audit.t;
  t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t;
  t/1528-ial2-ahb-requester-three-busy-insert.t;
  t/1541-ial2-ahb-requester-generalized-busy-count-range.t;
  t/248-regression-corpus-accounting.t;
  t/297-capability-manifest.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 --
  prove -Iperl t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t
  t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t
  t/1513-ial2-ahb-paired-busy-composition.t
  t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t
  t/1518-ial2-ahb-mdbook-current-surface-truthfulness.t
  t/1519-ial2-ahb-pipelined-active-transfer-audit.t
  t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
  t/1528-ial2-ahb-requester-three-busy-insert.t
  t/1541-ial2-ahb-requester-generalized-busy-count-range.t &&
  prove -Iperl t/1638-claim-verification-dispositions.t
  t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`CLAIM-VERIFICATION-ADOPTION.5.5.6` reviews the exact 22 inventory
candidates on `docs/book/src/16c-ial2-ahb.md` lines 2641 through 3227. Four
candidates state current behavior and use derived gates. The other 18
candidates are shipment-time support totals, readiness or contract inputs,
superseded exact-three bounds, or test-path locators and therefore use
reviewed-incidental dispositions.

The four current gates remain independent:

- the requester builder, generalized-range oracle, and support oracles retain
  canonical decimal `busy-beats` values `2..16`, absence as exact-one, values
  above 16 and malformed neighbors as rejected, and no fixture per count;
- the exact-three public source and t1528 retain `3 -> 2 -> 1 -> 0` through
  continuous and 32-clock ready/grant stalls, with exact-two as an adjacent
  watcher;
- the generated requester/subordinate/interconnect builders and t1519 retain
  two boundary-free acceptances, captures, and completions plus distinct
  final-ERROR active-continuation and IDLE-cancel outcomes; and
- the direct subordinate seed and t1520 retain its capacity-one Q-named
  completion-edge NONSEQ/SEQ dispatch without pending/relaunch state.

The guarded exact collection passes all nine focused files at `Files=9,
Tests=36`. It also keeps current aggregate HBURST generic/profile behavior,
one-/two-window paired behavior, and current-book truthfulness executable.
The support/disposition collection independently passes `Files=3,
Tests=7107`.

The reviewed records preserve exact chronology without turning obsolete
milestones into live support promises. They include 317/358/41 through
322/363/46 exact-two/exact-three shipment checkpoints, the original exact-three
`2..3` contract and its `0/1/4+` rejection boundary, disposable 32-clock
readiness runs, the selected one-word HBURST contract, and the 293/334 and
295/336 endpoint/aggregate support records. The t1513/t1515/t1520-only lines
are evidence locators rather than additional measurements.

All six Chapter 16c children now close exactly 232 candidates as 55 derived
gates plus 177 reviewed outcomes. The `ial2_ahb` disposition group is
required-complete at 232/232 with zero open candidates; only the separate
288-candidate verification-architecture group remains open in the adoption
frontier.

Key durable commits are `2f64611ca41c8d78648358c0e7bdcf71ba7f6fe7`
(generalized range), `325f21267de0a2a0caa8ec1bc96c4c9d26bacc4c`
(exact-three requester), `3e1dcc9301c17355357e4760d71d5e16f5f84596`
(generated phase pipeline), and
`75d1070833b61cf7824b750a22c1ff091b9d1db4` (direct Q-named repair).
