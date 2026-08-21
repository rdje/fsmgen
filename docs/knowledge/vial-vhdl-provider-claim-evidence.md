---
id: vial-vhdl-provider-claim-evidence
title: Portable VHDL and OSVVM claims retain provider-qualified evidence
answers:
  - "how are the Chapter 16d portable VHDL and OSVVM claims verified?"
  - "how is the recursive OSVVM provider graph verified?"
  - "how are OSVVM licence and notice counts verified?"
  - "how is the 16-artifact OSVVM adapter graph verified?"
  - "how are 44 OSVVM and 17 Common sources verified?"
  - "how are the 42-record VHDL trace and 19 parity paths verified?"
  - "how is the exact GHDL 6.0.0 LLVM-JIT archive verified?"
  - "how are portable VHDL operation scenario fiber and model counts verified?"
  - "how are six VHDL sources 59 source maps and 24 mappings verified?"
  - "how is the inert 976-byte legacy VHDL package verified?"
  - "why is Decision 0043 not an extra VHDL capability gate?"
date: 2026-08-21
status: current
tags: [claim-verification, vial, vhdl, osvvm, ghdl, provider, qualification, parity, migration, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  perl/FSM/VIAL/Backend/OSVVM2026_05Materialization.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVM2026_05.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVMStaticValidator.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVMGHDLQualification.pm;
  perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm;
  perl/FSM/VIAL/Backend/VHDLPortableReviewClosure.pm;
  perl/FSM/VIAL/Backend/VHDLPortableGHDLQualification.pm;
  vial/qualification/vhdl_osvvm_ghdl/osvvm-2026.05-ghdl-6.0.0-qualification.json;
  vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services;
  vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics;
  t/1593-vial-vhdl-portable-semantics.t;
  t/1594-vial-vhdl-portable-matrix-review.t;
  t/1595-vial-vhdl-portable-ghdl-qualification.t;
  t/1598-vial-vhdl-osvvm-emission.t;
  t/1599-vial-vhdl-osvvm-ghdl-qualification.t;
  t/1638-claim-verification-dispositions.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 --
  prove -Iperl t/1593-vial-vhdl-portable-semantics.t
  t/1594-vial-vhdl-portable-matrix-review.t
  t/1595-vial-vhdl-portable-ghdl-qualification.t
  t/1598-vial-vhdl-osvvm-emission.t
  t/1599-vial-vhdl-osvvm-ghdl-qualification.t &&
  prove -Iperl t/1638-claim-verification-dispositions.t
  t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`CLAIM-VERIFICATION-ADOPTION.5.6.2` reviews the exact 16 inventory
candidates on `docs/book/src/16d-hial-vial-verification-architecture.md`
lines 932 through 1355. Fifteen candidates state current provider-free or
provider-qualified behavior and use derived gates. The Decision `0043`
version-selection sentence is structural chronology and uses one
reviewed-incidental disposition.

The OSVVM evidence remains factored by authority:

- recursive materialization verifies the superproject plus 13 gitlinks as 14
  clean repositories under the repository-derived same-volume root;
- the independent licence/notice census locks 14 Apache-2.0 licence files,
  zero notice files, and the pinned Documentation repository's explicit
  absence without inferring coverage;
- deterministic adapter emission produces 16 artifacts: seven VHDL sources
  and nine evidence artifacts, with seven provider mappings, 13 source-map
  entries, 12 static checks, and six semantic-preservation guards; and
- exact combined qualification reconstructs and executes 44 OSVVM core plus
  17 compatible Common sources, yielding 61 provider analysis commands. It
  double-runs the fixture and provider probe, preserves a closed 42-record
  trace, passing normalized result, nineteen applicable parity paths, and four
  supplementary provider reports.

The provider-free evidence is separately bounded:

- the exact 37,155,806-byte GHDL 6.0.0 macOS ARM64 LLVM-JIT archive, archive
  SHA-256, selected binary SHA-256, tool commit/backend identity, and
  repository-local provider root are checked before execution;
- exact qualification analyzes six gallery sources plus a timed four-state
  probe, double-runs both tops, and independently gates analysis, elaboration,
  runtime, trace, result, rerun, nineteen-path parity, and cleanup;
- VHDL metadata derives all 21 operation identities/ranks, two 256-cycle
  scenarios, four fibers, and two deterministic model instances;
- the review graph retains six VHDL sources, 59 source-map entries, 20 static
  checks, and a 24-row matrix split into 20 emitted responsibilities and four
  exact unsupported boundaries; and
- the migration proof freshly reproduces the inert legacy package at 976
  bytes plus its package/manifest digests, proves it is unconsumed, and keeps
  the HIAL successor byte-identical to the private handoff.

The guarded five-file exact collection passes at `Files=5, Tests=31`,
including installed provider/tool reruns and same-volume cleanup. The
support/disposition collection passes at `Files=3, Tests=7107`. The current
registry therefore closes 24 of 288 verification-architecture candidates:
21 gates and three reviewed outcomes across `.5.6.1` and `.5.6.2`.

Decision `0043` and the version-1 label identify the immutable architecture
selection. They are not a second support promise: current portable emission,
exact GHDL qualification, and bounded public execution have their own
executable gates.

Key durable commits are `4f350f29cd` (recursive OSVVM materialization),
`895ea33bd0` (combined provider/tool qualification), `a0e7149d57` (portable
GHDL qualification), `ab8b1af246` (portable semantic emission), `0074b369ed`
(portable review closure), and `ab3e73b729` (version-1 selection chronology).
