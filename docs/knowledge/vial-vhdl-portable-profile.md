---
id: vial-vhdl-portable-profile
title: Portable VIAL VHDL is a provider-free IEEE 1076-2008 profile qualified on exact GHDL 6.0.0
answers:
  - "has FSMGen started emitting native VIAL VHDL?"
  - "what portable VHDL semantics does vhdl_portable_ghdl emit?"
  - "how does portable VHDL preserve original std_logic symbols?"
  - "what is the portable VHDL inactive-edge scheduler?"
  - "how are VIAL scenarios fibers and models emitted in VHDL?"
  - "how are declared HIAL probes accessed from portable VHDL?"
  - "does portable VIAL VHDL emit scoreboards coverage faults and checks?"
  - "does portable VIAL VHDL emit a closed trace and normalized result projection?"
  - "where is the portable VHDL review gallery?"
  - "how do I regenerate or check the portable VHDL review gallery?"
  - "what does the portable VHDL selected mapping matrix contain?"
  - "how are portable VHDL review defects tracked?"
  - "how does portable VHDL prove legacy and HIAL separation?"
  - "is portable VHDL visually reviewed or qualified?"
  - "has the generated VIAL VHDL been analyzed or run?"
  - "which exact GHDL 6.0.0 backend is qualified?"
  - "how do I rerun the exact portable VHDL GHDL qualification?"
  - "why is GHDL LLVM AOT not qualified for portable VIAL?"
  - "does portable VIAL VHDL consume the legacy observation package?"
date: 2026-08-28
status: current
tags: [hial, vial, vhdl, ghdl, review-gallery, simulator-profile, verification]
evidence: >-
  docs/decisions/0051-vial-vhdl-uses-a-provider-free-core-and-osvvm-qualified-tier.md;
  perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm;
  perl/FSM/VIAL/Backend/VHDLPortableStaticValidator.pm;
  perl/FSM/VIAL/Backend/VHDLPortableReviewClosure.pm;
  perl/FSM/VIAL/Backend/VHDLPortableGHDLQualification.pm;
  perl/FSM/Support/VIALVHDLEmissionContract.pm;
  scripts/refresh_vial_vhdl_portable_gallery.pl;
  scripts/run_vial_vhdl_portable_ghdl_qualification.pl;
  t/1593-vial-vhdl-portable-semantics.t;
  t/1594-vial-vhdl-portable-matrix-review.t;
  t/1595-vial-vhdl-portable-ghdl-qualification.t;
  vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics/README.md;
  vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics/evidence/selected-mapping-matrix.json;
  vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics/evidence/review-workflow.json;
  vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics/evidence/migration-proof.json;
  vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  prove -Iperl t/1593-vial-vhdl-portable-semantics.t
  t/1594-vial-vhdl-portable-matrix-review.t
  t/1595-vial-vhdl-portable-ghdl-qualification.t &&
  perl scripts/refresh_vial_vhdl_portable_gallery.pl --check &&
  perl scripts/run_vial_vhdl_portable_ghdl_qualification.pl --check
---

Decision `0051` selects provider-free IEEE 1076-2008 as the portable VIAL VHDL
semantic core. The private provider-free VHDL emitter includes bounded
scoreboards, explicit coverage counters, substitution faults, procedural
checks, diagnostic records, closed trace framing, and a normalized-result
projection with all top-level manifest families, bounded stored diagnostic
details, and VHDL-native quote doubling. C-style JSON string escaping is
rejected structurally.

The closed provider-free profile has 17 artifacts: a 24-row matrix with 20
emitted and four exactly unsupported boundaries, a seven-stage deterministic
review/defect workflow, and exact inert-legacy/HIAL separation evidence
alongside its six sources, 59 maps, and 21 static checks. It is emitted and
structurally reviewed; visual review remains pending.

Completed `.15.1-.15.5` ship and qualify the profile. Its 17 artifacts retain
six sources, 59 maps, 21 checks, exact HIAL identity, typed `std_logic`
observation, one inactive-edge scheduler, bounded scenarios/models/checking,
declared-probe-only hierarchy, and closed results. Run `perl
scripts/refresh_vial_vhdl_portable_gallery.pl --check` for the byte-locked
gallery and the guarded qualification command in `reverify` for the exact
LLVM-JIT proof. Ordinary portable emission fetches no provider; the legacy
VHDL observation package remains unchanged and unconsumed.

The exact canonical fixture is separately qualified under repository-local
GHDL 6.0.0 LLVM-JIT through analysis, elaboration, bounded runtime, closed
trace, normalized result, timed `0/1/X/Z`, deterministic rerun, and nineteen
applicable portable-SV parity paths. Completed `.15.5` owns that exact
LLVM-JIT proof. The exact LLVM AOT build is not inferred because its
external-name adapter fails at runtime.

Complete VHDL breadth, PSL, UVVM, another simulator, mixed-language behavior,
general parity, and scale remain unclaimed.

Related: [[hial-vial-verification-fixture-architecture]],
[[vial-vhdl-osvvm-qualified-tier]], [[direct-vhdl-scaffold]].
