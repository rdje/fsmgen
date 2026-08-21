---
id: vial-vhdl-osvvm-qualified-tier
title: OSVVM 2026.05 is a separately qualified advanced VHDL provider above the portable core
answers:
  - "is exact OSVVM 2026.05 installed for FSMGen?"
  - "how is the recursive OSVVM provider identity verified?"
  - "where is the OSVVM VHDL adapter gallery?"
  - "has OSVVM 2026.05 plus GHDL 6.0.0 been qualified?"
  - "how is exact OSVVM provider verification reused safely?"
date: 2026-08-21
status: current
tags: [hial, vial, vhdl, osvvm, ghdl, review-gallery, verification]
evidence: >-
  docs/decisions/0051-vial-vhdl-uses-a-provider-free-core-and-osvvm-qualified-tier.md;
  perl/FSM/VIAL/Backend/OSVVM2026_05Materialization.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVM2026_05.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVMStaticValidator.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVMGHDLQualification.pm;
  scripts/refresh_vial_vhdl_osvvm_gallery.pl;
  scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl;
  t/1598-vial-vhdl-osvvm-emission.t;
  t/1599-vial-vhdl-osvvm-ghdl-qualification.t;
  t/1642-vial-vhdl-osvvm-provider-evaluation.t;
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
  t/1642-vial-vhdl-osvvm-provider-evaluation.t &&
  perl scripts/refresh_vial_vhdl_osvvm_gallery.pl --check &&
  perl scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl --check
---

Decision `0051` keeps OSVVM a separately qualified advanced provider, never the
portable semantic core. Its exact 2026.05 graph locks 14 repositories, 13
gitlinks, 14 Apache-2.0 licence files, zero notices, clean identities, and the
Documentation repository's explicit metadata absence. Seven mappings add 13
maps, 12 checks, and six guards beside unchanged portable semantics.

The GHDL 6.0.0 tuple compiles 61 provider sources, analyzes seven generated
sources plus its probe, and double-runs both tops. Portable trace, result, and
19-path parity stay authoritative; provider random, coverage, scoreboard,
report, memory, and barrier evidence is supplementary.

One callback evaluation verifies the exact provider once and keeps its root and
result digest behind an opaque capability. Matching emissions receive defensive
copies; mismatched, forged, stale, or failure-retained handles return no
artifacts. Standalone emission still verifies independently and remains
byte-identical, so reuse changes neither qualification nor semantic authority.

Related: [[vial-vhdl-portable-profile]],
[[hial-vial-verification-fixture-architecture]].
