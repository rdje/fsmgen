---
id: hial-vial-bridge-manifest-v1-contract
title: HIALVIALBridgeManifest v1 is produced only from reviewable HIAL routes
answers:
  - "what is the HIALVIALBridgeManifest v1 schema?"
  - "how is the HIAL VIAL bridge generated?"
  - "can PPIF feed the VIAL bridge directly?"
  - "how do IAL2 protocol facts enter the VIAL bridge?"
  - "what is the IAL1 verification-bridge annotation?"
  - "which bridge IDs bind the AHB VIAL fixture?"
  - "does the HIAL VIAL bridge expose hierarchy?"
  - "does the HIAL VIAL bridge bind VIAL yet?"
  - "what does core_single_unit_v1 mean?"
  - "how does the architecture scale bridge fanout generator work?"
  - "which bridge scale limits are reached exactly?"
  - "does bridge construction preserve HDL?"
  - "why does the AHB report hash change after lowering updates?"
date: 2026-10-25
status: current
tags: [hial, vial, bridge, manifest, ial0, ial1, ial2, review-route, provenance, ahb, scale]
evidence: docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md; docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md; docs/decisions/0035-hial-vial-bridge-is-produced-from-reviewable-hial-routes.md; docs/decisions/0060-vial-bridge-scale-uses-a-qualification-only-direct-ial1-profile.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md; docs/book/src/16d-hial-vial-verification-architecture.md
reverify: prove -Iperl t/1551-hial-vial-bridge-manifest.t t/1602-vial-architecture-scale-bridge-fanout.t && (scripts/decision_records.py read 0035 && cat perl/FSM/HIAL/VIALBridge/Builder.pm perl/FSM/VIAL/ArchitectureScaleBridgeFanout.pm perl/FSM/Support/HIALVIALBridgeContract.pm docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/book/src/16d-hial-vial-verification-architecture.md) | rg -n 'core_single_unit_v1|direct_ial2_to_verification|verification-bridge|architecture_scale_probe|transaction/ahb_write|probe/reg_data_q|semantic_path|shipped_private_in_process'
---

Decision `0035` selects `fsmgen.hial_vial_bridge_manifest.v1`, initially
`core_single_unit_v1`: sanitized JSON-safe HIAL-to-VIAL binding data, not raw
AST/IR, target HDL, an execution plan or runtime result.

Only routes: direct IAL0; direct IAL1 through generated IAL0; IAL2 through
generated IAL1 and IAL0. PPIF never feeds the bridge directly. Protocol/event/
probe facts enter deterministic generated-IAL1 `(verification-bridge ...)`
metadata, parsed, validated and reported by ordinary IAL1 before consumption.

AHB publishes `unit/ahb_lite_subordinate`, `domain/ahb_bus`, public endpoint IDs,
`transaction/ahb_write`, six lifecycle events and `probe/reg_data_q`, binding
the checked VIAL source. Public ports are portable; the probe remains
`verification_probe` with an equivalent-adapter requirement. No raw SV/VHDL
hierarchy path enters the manifest.

Every field has exact parser spans or semantic paths/null spans; IAL2 cites
PPIF/generated annotation. Completed `.5` ships
private Builder/Manifest/Report and t1551: no file/binding/backend/runtime/
parity/scale claim. Decision `0037` retains hardware carrier types;
the later binder proves directional VIAL relations.

Decision `0060` preserves exact AHB and selects a separate
`qualification_only` direct-IAL1 scale profile using ordinary parse/report/
lowering/builder authorities. Only private scale evidence; no protocol/
performance/capacity claims. Prior source-map/manifest caps remain.
Completed `.17.2.3.2` implements all 13 `bridge_fanout_v1` axes through source.
Default proof: frozen AHB and every gate axis. Explicit RAM-guarded proof:
qualification, exact boundaries and excess. Canonical manifests reach exactly
1 MiB, 4 MiB and 16 MiB. Source-map gate: 8,192 records; larger valid shapes
stop at the earlier 16-MiB manifest cap. Scale IAL2 bypass is rejected, direct
IAL1 retains `IAL1 -> IAL0`. Four generated-IAL0 provenance fields can vary:
source/artifact SHA, source byte/line counts. T1602 checks raw bytes
and freezes every other AHB report field.

T1551 compares HDL before/after bridge construction (only SV date normalized)
and IAL0 with/without its annotation. A changed storage reset must change both
HDL outputs/reset values. SV policy/VHDL typing repairs supersede old byte
locks; PUBLICATION-REGRESSION-REPAIRS.15 retains exact proofs and
interface/selector/type checks.
