---
id: public-regression-promotion-policy-loads-a-tracked-seal
title: Public regression-promotion policy loads a tracked seal
answers: ["why does public regression-promotion policy derivation no longer authenticate the ignored calibration closure?", "where is the sealed regression-promotion policy a fresh checkout loads?", "does the tracked policy seal change the pinned policy identity?", "does a failed hosted gate become support or capacity?"]
date: 2026-09-23
status: current
refines: regression-promotion-uses-a-current-eleven-profile-corpus
reverify: rg -n 'regression-promotion-policy-v1.json' perl/FSM/VIAL/ArchitectureScaleRegressionPromotionPolicy.pm docs/book/src/16df-vial-architecture-scale-cap-closeout.md
---

# 0103 — Public regression-promotion policy loads a tracked seal

- Date: 2026-09-23
- Type: verification architecture / regression promotion
- Status: accepted
- Refines: [0096](0096-regression-promotion-uses-a-current-eleven-profile-corpus.md)
- Implementation owner: `HOSTED-VIAL-REGRESSION-GATE-RESULT.2`

## Context

Decision 0096 made `FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy` the
caller-sealed executable authority and required public derivation to
authenticate the immutable v1 closure before recomputing the eleven-profile
selection. That closure lives under ignored
`.artifacts/qualification/vial-scale/v1/calibration-closure-v1`. The first
hosted `vial-gate` command failed there, before any profile result, because a
fresh checkout does not carry the publication.

The policy object that derivation emits is already pinned. Qualification and
the tracked corpus bind
`regression-promotion-policy/19cf41056da86d95c266597e7db76eff3810ee29511a005e1051053009a65ece`.
Local derivation from the historical closure produces that same identity. The
current corpus and qualification already travel as a tracked evidence bundle.
The ignored closure does not, and committing it would republish historical
measurement bytes the public gate does not execute.

## Decision

1. Public `derive` loads one tracked canonical document at
   `vial/qualification/regression_promotion_policy/regression-promotion-policy-v1.json`.
   It requires the repository RAM guard, a regular same-volume file, canonical
   JSON, the existing policy validator, the pinned identity above, historical
   disposition, and current-performance ineligibility. Caller-injected evidence
   remains rejected.
2. The tracked document is the already-derived policy object. Its identity does
   not change. It is not the ignored closure publication and it is not a new
   measurement.
3. `_derive_from_report` remains the historical comparison used by local
   mutation tests when the ignored closure is present. Public derivation, the
   capture plan, and the gate contract do not call it and do not require that
   publication.
4. A failed or unavailable hosted run remains neither support nor capacity.
   This decision does not rewrite the local exact-pinned observation and does
   not invent a hosted pass. A fresh checkout can load the sealed policy; a
   hosted result still requires a hosted run.

## Consequences

- Decision 0096 item 9 and its re-derive leg described runtime authentication
  of the v1 publication. That runtime requirement is refined here. The
  eleven-profile selection, historical comparison figures, provider rule, and
  nonclaims in 0096 stay in force.
- The public gate can pass policy derivation on a checkout that has the tracked
  seal and the existing tracked corpus and qualification evidence.
- Historical closure mutation tests remain local-only. They are not the public
  command.

## Rollback

Remove the tracked seal, restore public derivation to the ignored publication,
and return `HOSTED-VIAL-REGRESSION-GATE-RESULT.2` to active. Do not treat that
rollback as a hosted result.
