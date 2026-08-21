---
id: vial-vhdl-osvvm-qualified-tier
title: OSVVM 2026.05 is a separately qualified advanced VHDL provider above the portable core
answers:
  - "is exact OSVVM 2026.05 installed for FSMGen?"
  - "how is the recursive OSVVM provider identity verified?"
  - "where is the OSVVM VHDL adapter gallery?"
  - "has OSVVM 2026.05 plus GHDL 6.0.0 been qualified?"
  - "how is exact OSVVM provider verification reused safely?"
  - "how are portable VHDL source maps preserved in the OSVVM wrapper?"
date: 2026-08-21
status: current
tags: [hial, vial, vhdl, osvvm, ghdl, review-gallery, verification]
evidence: >-
  docs/decisions/0051-vial-vhdl-uses-a-provider-free-core-and-osvvm-qualified-tier.md;
  docs/decisions/0075-backend-emission-scale-uses-profile-specific-anchored-routes.md;
  perl/FSM/VIAL/Backend/OSVVM2026_05Materialization.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVM2026_05.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVMStaticValidator.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVMGHDLQualification.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmission/OSVVM.pm;
  perl/FSM/VIAL/BackendEmissionAuthority.pm; perl/FSM/Support/VIALVHDLEmissionContract.pm;
  scripts/refresh_vial_vhdl_osvvm_gallery.pl;
  scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl;
  t/1598-vial-vhdl-osvvm-emission.t;
  t/1599-vial-vhdl-osvvm-ghdl-qualification.t;
  t/1642-vial-vhdl-osvvm-provider-evaluation.t; t/1644-vial-backend-emission-authority-alignment.t;
  t/1648-vial-architecture-scale-backend-emission-osvvm.t;
  vial/qualification/vhdl_osvvm_ghdl/osvvm-2026.05-ghdl-6.0.0-qualification.json;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/README.md;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/provider-materialization.json;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/advanced-mapping-matrix.json;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/semantic-preservation.json;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/qualification-reference.json;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  prove -Iperl t/1598-vial-vhdl-osvvm-emission.t
  t/1599-vial-vhdl-osvvm-ghdl-qualification.t
  t/1642-vial-vhdl-osvvm-provider-evaluation.t
  t/1644-vial-backend-emission-authority-alignment.t
  t/1648-vial-architecture-scale-backend-emission-osvvm.t &&
  perl scripts/refresh_vial_vhdl_osvvm_gallery.pl --check &&
  perl scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl --check
---

Decision `0051` keeps OSVVM a separately qualified advanced provider, never the
portable semantic core. Its exact 2026.05 graph locks 14 repositories, 13
gitlinks, 14 Apache-2.0 licence files, zero notices, clean identities, and the
Documentation repository's explicit metadata absence. Seven adapter mappings
precede all 59 portable entries translated to wrapper paths and identities, so
the exact graph has 66 maps, 12 checks, and six guards beside unchanged
portable semantics. Schema, artifact-digest, identity, span, or coverage drift
fails before the wrapper publishes an artifact graph.

The GHDL 6.0.0 tuple compiles 61 provider sources, analyzes seven generated
sources plus its probe, and double-runs both tops. Portable trace, result, and
19-path parity stay authoritative; provider random, coverage, scoreboard,
report, memory, and barrier evidence is supplementary.

One callback evaluation verifies the exact provider once and keeps its root and
result digest behind an opaque capability. Matching emissions receive defensive
copies; mismatched, forged, stale, or failure-retained handles return no
artifacts. Standalone emission still verifies independently and remains
byte-identical, so reuse changes neither qualification nor semantic authority.

Catalog and capability discovery now consume one closed shared authority. It
separates six portable sources, one fixed 4,351-byte wrapper adapter, seven
total sources, and provider materialization; the 16-MiB boundary applies only
to the portable six-source foundation. Reference discovery reports 16 total
artifacts, 66 maps, twelve wrapper checks, and twenty prerequisite portable
checks. Unknown, missing, stale, or contradictory fields fail closed.

The caller-sealed architecture-scale profile owns T=21/128/512/29,508 plus
adjacent portable-foundation T=29,509 rejection. One provider verification is
reused only inside its callback for two defensive emissions. Accepted source
totals are 120,911/179,280/391,248/16,781,090 bytes with
66/173/557/29,553 complete maps; every wrapper map, provider/source identity,
mapping status, semantic guard, and evidence encoding is checked before the
content-addressed report is accepted. The adjacent excess publishes no
partial provider evidence or graph. This generator proof executes no external
compiler or runtime and adds no product support, performance, or capacity
claim.

Related: [[vial-vhdl-portable-profile]],
[[hial-vial-verification-fixture-architecture]].
