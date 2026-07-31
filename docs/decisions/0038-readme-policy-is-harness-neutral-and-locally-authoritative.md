# 0038 — README policy is harness-neutral and locally authoritative

- Date: 2026-07-31
- Type: convention/feedback
- Status: accepted
- Refines: [0024](0024-readme-is-a-nearly-static-landing-page.md)
- Refined by: [0040](0040-readme-routing-must-close-destination-pressure.md)
- Evidence owner: `README-POLICY-ANVIL-ADOPTION-FEEDBACK.1`

## Context

ANVIL adopted FSMGen's reusable README Stability Policy verbatim and reduced
its README from 1,771 lines / 122,767 bytes to 159 lines / 10,375 bytes—an 89%
reduction without information loss. Its adoption exposed six gaps in the
otherwise successful policy:

- harness bootstrap files could be mistaken for policy authority;
- the originating template was not explicitly disclaimed as an upstream;
- illustrative caps invited copying instead of post-trim calibration;
- line and byte limits looked redundant despite materially different prose
  density;
- apparent duplication needed proof before deletion or relocation; and
- a changed-path-scoped guard could miss an over-budget merge or revert.

ANVIL also demonstrated a clean structural answer: keep local adoption facts
in a fenced note above a project- and harness-neutral reusable body.

FSMGen's reviewed README currently measures 246 lines / 9,952 bytes. Decision
0024's original 300-line / 16,384-byte limits leave substantially more
regrowth room than this empirical survivor needs.

## Decision

1. The reusable policy is explicitly project- and harness-neutral. Authority
   is cited by adopting-project owner/date and the project-owned
   `README_POLICY.md`, never by an agent or harness bootstrap file.
2. After adoption, the project-owned copy is authoritative. The originating
   file is a template, not an upstream; there is no automatic synchronization.
   Later revisions are deliberate local decisions.
3. Local owner/date, decision, independence, and derived-cap metadata stays in
   a fenced adoption note above the neutral body.
4. Line and byte caps are derived from the audited trimmed survivor with modest
   explicit headroom. The reusable example uses replace-before-use
   placeholders, not attractive numeric defaults.
5. Both budgets remain mandatory because line count and prose density are
   independent. ANVIL's retained 141-line form was already 10,297 bytes, with
   roughly 118 bytes/line for a numbered list versus 57 for a path list.
6. Cleanup first proves apparent duplication. When the canonical home is
   richer, the README copy is deleted and replaced by one link; only unique
   maintained content is relocated.
7. The landing-page check runs unconditionally on every commit and CI build,
   independent of changed-path scope.
8. FSMGen recalibrates its local defaults to 275 lines and 12,288 bytes from
   the reviewed 246-line / 9,952-byte survivor. This refines decision 0024's
   original limits without changing `README.md` content.

## Consequences

- README doctrine belongs to the repository and applies equally to human and
  automated authors, regardless of their entry harness.
- Local evolution is intentional and auditable; template provenance cannot
  silently overwrite a project's adopted policy.
- Limits resist regrowth while leaving measured, explicit maintenance
  headroom.
- Merge, revert, and unrelated-path commits cannot evade the size invariant.
- Cross-project evidence improves the reusable text without contaminating it
  with project-specific state.
