---
id: capability-manifest-verification-outputs-presence-map-drift
title: Verification-output section discovery omits two live contract keys
answers:
  - "why does t370 capability manifest section discovery fail?"
  - "is the verification outputs presence key map aligned?"
  - "which verification output discovery keys are stale?"
date: 2026-07-31
status: current
tags: [capability-manifest, verification-output, contract, discovery, test-drift]
evidence: t/370-capability-manifest-section-discovery-audit.t; perl/FSM/Support/CapabilityManifestContract.pm; perl/FSM/Support/VerificationOutputsContract.pm; perl/FSM/Support/VerificationOutputsSection.pm; docs/tasks/CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.md
reverify: prove -Iperl t/370-capability-manifest-section-discovery-audit.t
---

The live `FSM::Support::VerificationOutputsSection` includes the complete
verification-output contract, whose top level contains `guidance` and
`json_safe_when_embedded_in_public_manifest`. The grouped
`capability_manifest_verification_outputs_keys()` discovery list omits those
two keys. Consequently t370 reports exact in-process and public-CLI section-map
drift.

Both owners are unchanged from HEAD while the HIAL/VIAL bridge slice is dirty,
so this is a pre-existing independent contract mismatch rather than a bridge
regression. Proposed
`CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.1` owns root-cause,
selection, repair, and adjacent schema/round-trip/defensive-copy evidence after
a separate clean activation. No verification-output generator, artifact, CLI,
UVM/VHDL claim, or HIAL/VIAL behavior is changed by parking the finding.
