---
id: ial2-ahb-two-window-exact-four-generalized-range-claim-evidence
title: AHB two-window exact-four and generalized BUSY-range claims retain distinct evidence
answers:
  - "how are Chapter 14i two-window exact-four and generalized BUSY claims verified?"
  - "how is the two-window exact-four runtime tuple verified?"
  - "how is two-window exact-four profile-alias parity verified?"
  - "how is the canonical AHB busy-beats range 2 through 16 verified?"
  - "how are current AHB support totals verified?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, ahb, exact-four, two-window, busy, generalized-range, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm;
  perl/FSM/Support/LanguageSurfaceSection.pm;
  perl/FSM/Support/RegressionCorpus.pm;
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif;
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ahb;
  ppif/ahb_requester_busy_insert_four.ppif;
  t/1539-ial2-ahb-two-subordinate-exact-four-paired-busy-composition.t;
  t/1540-ial2-ahb-two-subordinate-exact-four-paired-busy-composition-profile-alias.t;
  t/1541-ial2-ahb-requester-generalized-busy-count-range.t;
  t/248-regression-corpus-accounting.t;
  t/297-capability-manifest.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 --
  prove -Iperl t/1539-ial2-ahb-two-subordinate-exact-four-paired-busy-composition.t
  t/1540-ial2-ahb-two-subordinate-exact-four-paired-busy-composition-profile-alias.t
  t/1541-ial2-ahb-requester-generalized-busy-count-range.t &&
  prove -Iperl t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`CLAIM-VERIFICATION-ADOPTION.5.4.11` reviews the exact 32 inventory
candidates on `docs/book/src/14i-ahb-and-integration.md` lines 1780 through
1895. Nine candidates state current numeric behavior and use derived gates.
The other 23 candidates are readiness or contract inputs, projected totals,
superseded activation states, or shipment/selector checkpoints and therefore
use reviewed-incidental dispositions.

The current candidates remain separated into four evidence families:

- two-window exact-four generic topology, artifacts, and runtime;
- two-window exact-four profile-alias parity;
- current protocol/strict/AHB-path support accounting; and
- canonical generalized requester `busy-beats` range, runtime, diagnostics,
  no-count-specific-fixture behavior, and unchanged support accounting.

The ordinary requester, subordinate, and interconnect builders rederive the
generic topology. Focused t1539 independently checks the exact six-field delta,
four-child topology, 4 IAL1/5 IAL0 artifacts, strict/report/semantic/read-only-
MCP/verifier surfaces, unmatched-neighbor diagnostics, and assertion-enabled
10/8/2/8/2 runtime with final `44332211`/`88776655` endpoint values. Focused
t1540 proves profile parity through 4 top-level subtests and 97 nested
assertions without a second simulation.

The requester builder now admits canonical decimal literals `2..16` while
absence remains exact-one. Focused t1541 checks minimum widths, numeric
reports/residue, semantic/MCP/verifier surfaces, seven assertion-enabled
5/8/16 runtime cases, and zero/one/17/noncanonical/symbolic/expression/
duplicate rejection. It proves the new counts remain unmatched by support
accounting and leave repository-local temporary workspaces empty.

The support producer and focused corpus/manifest oracles independently retain
332 protocol fixtures, 373 strict-supported fixtures, and 56 AHB paths split
28 `.ppif` / 28 `.ahb`. Pre-shipment 331/372/55 projections, superseded
literal `2..4` activation states, the 46-assertion patched-copy audit, and
selector-time repetitions remain structural or historical chronology rather
than current gates.

Key durable commits are `a5d162d60fcbfce80a46fd1598fdb8691261a36c`
(two-window readiness), `a62ddb70593bb667b7fa36485107c7fb5a445b5f`
(two-window generic), `3519cde33e35d6f84e65af33dd7fe5d010539ee6`
(two-window alias), `18f63a971f910ee17a00380cab3f4b7c08728842`
(generalized-range readiness), and
`2f64611ca41c8d78648358c0e7bdcf71ba7f6fe7` (generalized-range behavior).
