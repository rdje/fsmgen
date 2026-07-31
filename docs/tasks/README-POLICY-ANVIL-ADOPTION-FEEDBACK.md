# README-POLICY-ANVIL-ADOPTION-FEEDBACK: Integrate Cross-Project Adoption Evidence

## Metadata

- Tree ID: `README-POLICY-ANVIL-ADOPTION-FEEDBACK`
- Status: `done`
- Roadmap lane: `infra/continuity / entry-point documentation`
- Created: `2026-07-31`
- Last updated: `2026-07-31`
- Owner: repo-local workflow
- Activation: director supplied ANVIL adoption feedback on `2026-07-31`.

## Goal

Refine the reusable README stability policy with evidence from ANVIL's
successful adoption while preserving a harness-neutral policy body and an
explicitly local authoritative adoption record.

## Non-Goals

- Do not copy ANVIL-specific project state into the neutral policy body.
- Do not make an external template an upstream or add automatic policy sync.
- Do not change FSMGen's README content, runtime, compiler, generated output,
  or product behavior.
- Do not modify any harness bootstrap file; those files discover doctrine but
  do not authorize it.

## Acceptance Criteria

- `README_POLICY.md` is explicitly project- and harness-neutral and requires
  authority citations by project owner/date plus the project-owned policy,
  never a vendor/harness bootstrap.
- The project-owned copy is authoritative after adoption; its origin is a
  template, not an upstream, and future changes are deliberate local reviews.
- Local adoption metadata is fenced above a neutral body that contains no
  FSMGen- or harness-specific authority tokens.
- Caps are derived from the audited trimmed README with modest headroom; the
  neutral checker example contains replace-before-use placeholders rather than
  attractive copyable defaults, and a concrete prose-density example explains
  why both line and byte caps are independent.
- The cleanup checklist requires proving content is truly duplicated before
  deletion/relocation and prefers delete-with-link when the canonical home is
  richer.
- Enforcement is explicitly whole-tree and runs on every commit/CI build even
  when README is absent from the changed-path set.
- FSMGen's local caps, decision/doctrine/fact/task/book/live-doc surfaces, and
  focused positive/negative checker evidence remain synchronized.
- The completed slice passes fresh implementation acceptance, all doctrines,
  and the commit workflow.

## Task Tree

- ID: `README-POLICY-ANVIL-ADOPTION-FEEDBACK`
  Status: `done`
  Goal: `Integrate cross-project README policy adoption evidence without diluting the neutral policy.`
  Children: `README-POLICY-ANVIL-ADOPTION-FEEDBACK.1`

- ID: `README-POLICY-ANVIL-ADOPTION-FEEDBACK.1`
  Status: `done`
  Goal: `Refine policy authority, locality, empirical cap calibration, duplicate verification, unconditional enforcement, and FSMGen adoption evidence.`
  Acceptance: `The policy, local guard, decision, doctrine, book, fact, task index, Memory, and changelog agree; focused line/byte/pass probes and broader doctrine/docs gates pass; README content and product behavior remain unchanged.`
  Verification: `Activated directly from director-provided ANVIL adoption evidence at clean commit 2109832f2. Root-cause and final verification are recorded below.`
  Commit: `README-POLICY-ANVIL-ADOPTION-FEEDBACK.1: integrate cross-project policy evidence`

## Decisions

- `2026-07-31`: Treat ANVIL's 89% README reduction and six adoption findings
  as empirical doctrine evidence, not as ANVIL-specific policy content.
- `2026-07-31`: Keep local adoption metadata outside the neutral policy body;
  after copying, the local repository owns its policy independently.
- `2026-07-31`: Recalibrate FSMGen's local limits from its current reviewed
  246-line/9,952-byte landing page to 275 lines and 12,288 bytes.
- `2026-07-31`: Decision `0038` makes the project-owned policy authoritative,
  the reusable body harness-neutral, the origin non-upstream, and the
  resulting-tree guard unconditional.

## Open Questions

- None. The feedback supplies direct evidence and the existing local doctrine
  provides exact integration loci.

## Blockers

- None.

## Acceptance Checklist (enforced) — `.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — declared signature family:
  `git log -S` exact-string provenance plus direct literal/measurement probes.
  Before any policy or checker edit, `rg` found `README_POLICY.md:3` describing
  only a `project-neutral` policy, `README_POLICY.md:51-52` publishing copyable
  `line_cap=300` / `byte_cap=16384` example defaults, and
  `scripts/check_readme_entrypoint.sh:28-29` using the same local defaults.
  `git log -S 'line_cap=300' -- README_POLICY.md` and
  `git log -S 'LINE_CAP="${README_LINE_CAP:-300}"' --
  scripts/check_readme_entrypoint.sh` both identify introducing commit
  `b03d7666e`; `wc -l -c README.md` measured the reviewed survivor at 246 lines
  / 9,952 bytes. The original reusable policy therefore omitted harness-neutral
  authority/upstream rules and made illustrative caps attractive defaults,
  while its cleanup/enforcement prose did not require duplicate proof or state
  that the whole-tree check is unconditional.
- [x] **ADDRESSED (verified)** — `scripts/check_readme_entrypoint.sh`
  passes the unchanged 246-line / 9,952-byte README against the locally
  derived 275-line / 12,288-byte defaults. Independent negative probes
  `README_LINE_CAP=245 scripts/check_readme_entrypoint.sh` and
  `README_BYTE_CAP=9951 scripts/check_readme_entrypoint.sh` each exit 1 on
  exactly the constrained dimension and emit canonical routing guidance.
  `rg -n 'README-ENTRYPOINT' scripts/check_doctrines.sh
  DOCTRINE_ENFORCEMENT.md` proves the driver still registers the guard
  unconditionally and the doctrine text names every resulting commit/CI tree.
- [x] **NO REGRESSION** — documentation/task truth reports
  `All tests successful` at `Files=4, Tests=305`; relative paths report
  `All tests successful` at `Files=1, Tests=2`; task-tree integrity passes at
  trees=2/nodes=868 after closeout; `knowledge-map: OK` holds at 1,092 facts /
  5,677 keys; `bash -n` accepts the checker/driver; all 37 mdBook chapters test
  and the repository-local 73-file / 17,060,655-byte build passes and is
  removed exactly. `README.md`, compiler/runtime behavior, generated product
  artifacts, and harness bootstrap files are unchanged. Staged acceptance
  identifies the owning task/root-cause/prove evidence and
  `[doctrine] all doctrine checks passed` closes all eight registered gates.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-07-31` | `.1` | pre-change literal/provenance/measurement audit; neutral policy/local adoption split; decision/fact/doctrine/book/live-doc sync; positive and independent line/byte negative probes; task/docs/paths/mdBook/Knowledge Map/Memory/diff/staged acceptance/doctrines; exact output cleanup | `passed`; decision 0038; local caps 275 lines/12,288 bytes from 246/9,952; Files=4/Tests=305 and paths Files=1/Tests=2; trees=2/nodes=868; 37 chapters; build 73 files/17,060,655 bytes; Knowledge Map 1,092 facts/5,677 keys; README and product behavior unchanged; output removed exactly |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `README-POLICY-ANVIL-ADOPTION-FEEDBACK.1: integrate cross-project policy evidence` | Refine the neutral policy and local adoption guard from empirical cross-project evidence. |

## Changelog

- `2026-07-31`: Director supplied ANVIL adoption feedback and activated `.1`
  from clean `.8` activation commit `2109832f2`; no policy/checker change had
  occurred before task-tree ownership existed.
- `2026-07-31`: `.1` integrates all six findings plus the fenced-local-note
  structure, accepts decision `0038`, recalibrates the local guard, and closes
  with the README and product behavior unchanged.
