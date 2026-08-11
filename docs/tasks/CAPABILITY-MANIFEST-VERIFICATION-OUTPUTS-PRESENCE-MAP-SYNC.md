# CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC: Verification-output discovery keys

## Metadata

- Tree ID: `CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC`
- Status: `superseded`
- Roadmap lane: `test integrity / capability-manifest discovery`
- Created: `2026-07-31`
- Last updated: `2026-08-11`
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
  Status: `superseded`
  Goal: `Restore exact verification-output section/discovery-map alignment without changing generated verification behavior.`
  Children: `CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.1`

- ID: `CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.1`
  Status: `superseded`
  Goal: `Audit and repair the stale verification_outputs presence-key family.`
  Acceptance: `On clean activation, prove the HEAD mismatch, select the canonical owner for guidance and json_safe_when_embedded_in_public_manifest, align the grouped map and all contract projections, and pass t370 plus adjacent exact-schema/round-trip/defensive-copy gates without changing verification artifacts or behavior.`
  Verification: `Discovery evidence while HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.5 was dirty: t/370 fails because the live VerificationOutputsSection contains guidance and json_safe_when_embedded_in_public_manifest while capability_manifest_verification_outputs_keys() omits them. Hosted job 93788675553 independently reproduces the mismatch. Ownership transfers to active recovery leaf GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.2 so one tree owns the repair.`
  Commit: `this commit (superseded into hosted recovery)`

## Decisions

- `2026-07-31`: Park the independently reproducible exact-schema drift; do not
  widen the dirty HIAL/VIAL bridge implementation slice to repair it.

## Blockers

- Superseded by `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.2`.

## Acceptance Checklist (enforced for implementation changes)

- [ ] **ROOT CAUSE (WHY + WHERE)** — Reproduce the two-key HEAD mismatch and
  identify the canonical contract owner.
- [ ] **ADDRESSED (verified)** — Make t370 pass in-process and through both CLI
  spellings.
- [ ] **NO REGRESSION** — Pass adjacent capability-manifest and verification-
  output schema, round-trip, defensive-copy, and artifact-behavior gates.
