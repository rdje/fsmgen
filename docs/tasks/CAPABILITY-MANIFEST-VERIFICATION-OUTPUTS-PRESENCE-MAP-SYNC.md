# CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC: Verification-output discovery keys

## Metadata

- Tree ID: `CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC`
- Status: `proposed`
- Roadmap lane: `test integrity / capability-manifest discovery`
- Created: `2026-07-31`
- Last updated: `2026-07-31`
- Owner: repo-local workflow

## Goal

Reconcile the capability manifest's advertised top-level
`verification_outputs` presence-key family with the exact section payload and
lock the alignment through the existing section-discovery audit.

## Non-Goals

- Do not change verification-output generation, artifacts, CLI behavior,
  UVM/VHDL claims, or HIAL/VIAL bridge semantics.
- Do not execute this repair while the active HIAL/VIAL `.5` worktree is dirty.

## Acceptance Criteria

- Root-cause whether the two live payload-only keys belong in the grouped
  discovery map or must be removed from the section contract.
- `capability_manifest_verification_outputs_keys()` and
  `FSM::Support::VerificationOutputsSection` expose exactly the same sorted
  top-level keys in-process and through both public CLI spellings.
- `t/370-capability-manifest-section-discovery-audit.t` and adjacent
  contract/defensive-copy/JSON round-trip audits pass.
- Live docs, Knowledge Map, bounded Memory, changelog, staged acceptance, and
  doctrine gates agree before the implementation leaf commits.

## Task Tree

- ID: `CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC`
  Status: `proposed`
  Goal: `Restore exact verification-output section/discovery-map alignment without changing generated verification behavior.`
  Children: `CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.1`

- ID: `CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.1`
  Status: `pending`
  Goal: `Audit and repair the stale verification_outputs presence-key family.`
  Acceptance: `On clean activation, prove the HEAD mismatch, select the canonical owner for guidance and json_safe_when_embedded_in_public_manifest, align the grouped map and all contract projections, and pass t370 plus adjacent exact-schema/round-trip/defensive-copy gates without changing verification artifacts or behavior.`
  Verification: `Pending. Discovery evidence while HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.5 was dirty: t/370 fails because the live VerificationOutputsSection contains guidance and json_safe_when_embedded_in_public_manifest while capability_manifest_verification_outputs_keys() omits them. Both mismatched owners are byte-identical to HEAD and outside the HIAL/VIAL diff, proving a pre-existing contract drift rather than a bridge regression.`
  Commit: `pending activation`

## Decisions

- `2026-07-31`: Park the independently reproducible exact-schema drift; do not
  widen the dirty HIAL/VIAL bridge implementation slice to repair it.

## Blockers

- Clean activation is required after the current active task-tree slice commits.

## Acceptance Checklist (enforced for implementation changes)

- [ ] **ROOT CAUSE (WHY + WHERE)** — Reproduce the two-key HEAD mismatch and
  identify the canonical contract owner.
- [ ] **ADDRESSED (verified)** — Make t370 pass in-process and through both CLI
  spellings.
- [ ] **NO REGRESSION** — Pass adjacent capability-manifest and verification-
  output schema, round-trip, defensive-copy, and artifact-behavior gates.
