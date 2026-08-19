# 0070 — A transition allowance carries one declared step of headroom and a live owner

- Date: 2026-08-19
- Type: infra/continuity governance
- Status: selected by `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.2`
- Refines: [0064](0064-live-document-growth-is-declared-measurement-with-paired-decisions.md), [0069](0069-live-document-target-pairs-are-swept-not-fixed-under-pressure.md)
- Implementation owner: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.2`

## Context

Decision `0069` swept the health-target pairs. It did not answer the other way
containment obstructs an ordinary write: a surface in transition debt is bounded
by `actual <= baseline + transition.max_growth`, and that allowance is a
hand-declared number nobody was auditing.

The audit finds fourteen of twenty enforced debt dimensions at five units of
headroom or fewer, and three collections closed outright because the `files`
enforcement ceiling equals the current member count. The block is real, not
theoretical: creating one ordinary `docs/*.md` file and rerunning
`scripts/check_live_document_size.sh` fails three invariants at once —

```text
surface focused_documents files is 1008 (> inclusive enforcement ceiling 1007)
surface focused_documents transition debt exceeded its owned allowance: files is 1008 (> baseline 1005 + growth 2)
surface focused_documents transition debt exceeded its owned allowance: total lines is 201900 (> baseline 199211 + growth 2687)
```

Two mechanisms produce this. First, the local procedure says to raise the
allowance "to the new measured actual", which by construction leaves zero
headroom, so the *next* write fails again — the declaration is a toll booth
rather than a budget. Second, nothing checks that an allowance is still owned:
`focused_documents` named `GITHUB-PUSH-OUTCOME-ASSURANCE.6.1` and
`ancillary_documents` named `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.18.2`, both
`done` leaves in a tree that is not in the active index. The doctrine requires
transition debt to carry "a named remediation owner"; a completed leaf satisfies
the string and not the requirement.

## Decision

1. **An allowance is re-declared to the measured actual plus one declared
   step, not to the measured actual.** The step is the surface's own
   `transition.ratchet_step` for that dimension, which is already the registry's
   statement of one bounded move on that surface. This stays a declared
   measurement under `0064` — `scripts/check_live_document_ceiling_authority.pl`
   still reports zero increases — while leaving the next ordinary write a budget
   instead of a rejection.
2. **The allowance is still clamped by the enforcement ceiling.** Where
   `baseline + step` would exceed the ceiling, the allowance stops at the
   ceiling and the ceiling is the finding. Widening an allowance may never
   become a way to reach past a quarantine boundary.
3. **A transition-debt owner must be a live node.** A `done` leaf, or a leaf in
   a tree absent from the active index, is not a remediation owner. Where the
   remediation is a standing migration rather than one slice, name the active
   tree, which is what `readme_entrypoint` and `shipped_behavior` already do.
4. **A rollover-debt surface is not widened.** `ancillary_documents` is at 100%
   of its reviewed `files` target, so its allowance stays where it is and the
   remedy is the declared rollover, not more room. Applying rule 1 there would
   convert a rollover signal into ordinary growth.
5. **A zero allowance may be deliberate and must say so.** `readme_entrypoint`
   is pinned at its baseline by the README policy, so its zero allowance is the
   intended contract and is recorded as such rather than corrected.

## Consequences

- `focused_documents` gains exactly one ratchet step on each of its five
  non-`files` dimensions: 100 lines and 16,384 bytes per file, 65 content-line
  bytes, 100 aggregate lines, and 16,384 aggregate bytes. The ceiling authority
  guard still reports zero increases, proving the move was a measurement.
- Two debt surfaces regain a live remediation owner.
- The three closed collections are not fixed here. `files` at
  `focused_documents` (1007), `root_documents` (18), and `ancillary_documents`
  (16) each equals the current member count, and
  `knowledge_cards.line_bytes_each` sits at exactly 80.0% of its target with
  zero headroom. Those are bounds pinned at the current actual rather than
  derived from the retained surface, and
  `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.3` owns reopening them.
- The doctrine's failure list already rejects "a missing owner"; it does not
  reject a stale one. That gap is recorded here and is a candidate check, not a
  claim that one exists.

## Containment

One bounded rationale record under the existing decision collection limits. The
allowance procedure in the local adoption note of
`LIVE_DOCUMENT_SIZE_CONTAINMENT.md` is corrected in place so a future author
reads the plus-one-step rule where the toll-booth rule used to be.
