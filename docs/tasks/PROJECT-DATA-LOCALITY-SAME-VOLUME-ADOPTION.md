# PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION: Keep Project Data On The Repository Volume

## Metadata

- Tree ID: `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION`
- Status: `active`
- Roadmap lane: `infra/continuity / project data locality`
- Created: `2026-07-29`
- Last updated: `2026-07-29`
- Owner: repo-local workflow

## Goal

Adopt and mechanically enforce the director-approved project-data locality
policy: every project-owned generated output, build artifact, cache, package or
dependency store, log, runtime-created test fixture, and temporary workspace
must live on the repository filesystem volume; persisted project paths remain
relative to the repository root; unavoidable cross-volume reads are explicit,
bounded, and documented; and provably project-owned off-volume residue is
migrated or removed through copy/verify/use/delete evidence.

## Non-Goals

- Do not delete ambiguous shared operating-system, language, package-manager,
  or user caches.
- Do not forbid required read-only operating-system or toolchain dependencies;
  record those as explicit external dependencies instead.
- Do not rewrite frozen legacy prose blobs (`CHANGES.md`,
  `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`, or
  `LIVE_ACHIEVEMENT_STATUS.md`).
- Do not combine unrelated IAL0, IAL1, IAL2, backend, protocol, or generated-HDL
  feature work with this infrastructure adoption.
- Do not silently rewrite historical commands in completed task-tree audit
  trails when they are preserved evidence rather than active instructions.

## Acceptance Criteria

- A durable decision and root policy define repository-root derivation,
  project-local artifact/cache/log/temp roots, explicit-output containment,
  external read-only exceptions, and copy/verify/use/delete migration evidence.
- A registered doctrine check rejects new live defaults or active instructions
  that route project-owned data to `/tmp`, `/private/tmp`, user-home caches, or
  other off-volume locations.
- The CLI, in-process lowering path, doctrine/Knowledge Map tooling, standard
  test entrypoints, and other live project-owned temporary workspaces derive
  their storage from the repository root on the same volume.
- Public README, toolbox, mdBook, and live Knowledge Map reverify commands use
  repository-relative project-local output paths and explain explicit caller
  path responsibility.
- Existing off-volume residue is censused; only exact, provably project-owned
  residue is migrated or removed, with counts/bytes/hashes when material and a
  final residue census. Ambiguous shared caches remain untouched.
- Focused runtime, doctrine, Knowledge Map, mdBook, and broader relevant gates
  pass.
- Each completed leaf is committed through `COMMIT.md` before the next leaf.

## Task Tree

- ID: `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION`
  Status: `active`
  Goal: `Adopt and enforce repository-volume locality for all project-owned data.`
  Children: `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.1`, `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.2`, `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.3`

- ID: `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.1`
  Status: `done`
  Goal: `Define the durable policy, census live violations, and register a fail-closed doctrine check.`
  Acceptance: `Decision 0022 and the root locality policy define exact rules and exception evidence; the doctrine registry includes a deterministic locality check with focused tests; roadmap, task-tree, Knowledge Map, and bounded resume pointer identify the active adoption; pre-existing adjacent startup alignment findings are routed to proposed task-tree owners rather than left in chat.`
  Verification: `scripts/check_project_data_locality.sh`; `scripts/check_doctrines.sh --list`; `scripts/check_doctrines.sh`; `mdbook build docs/book`; `git diff --check` (all pass, 2026-07-29)
  Commit: `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.1: adopt same-volume data doctrine`

- ID: `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.2`
  Status: `done`
  Goal: `Move live runtime, lowering, doctrine-tool, and standard test temporary storage onto repository-derived roots.`
  Acceptance: `CLI and in-process IAL1/IAL2 lowering use repository-local temporary workspaces; Knowledge Map checks create scratch files there; standard test/gate launchers export a repository-local temporary root before any fixture creation; explicit output-path behavior is bounded and regression-locked; the mdBook commands and option descriptions affected by that behavior change in the same slice; focused and broader runtime gates pass.`
  Verification: `perl -Iperl -c perl/FSM/ProjectDataLocality.pm`; `perl -Iperl -c bin/fsmgen`; `perl -Iperl -c perl/FSM/Pipeline/HDLGenerator.pm`; `bash -n` over changed shell entrypoints; `prove t/1527-project-data-locality.t t/1463-cli-generated-hdl-artifact-placement.t` (26 tests); 17 changed-path/runtime tests through `t/1305` passed in the RAM-guarded extended set; `prove t/1444-semantic-introspection-mcp-support-queries.t t/1464-isf-verification-output-uvm-passive-monitor.t t/1465-isf-verification-output-vhdl-observation-package.t` (10 tests); `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_project_data_locality.sh`; `scripts/check_doctrines.sh`; `mdbook build docs/book`; `scripts/check_memory_architecture.sh`; `git diff --check` (all pass, 2026-07-29). The extended set then reached the already-tracked stale APB expectation in `IAL2-T1436-PREEXISTING-FAILURES`; the guard stopped that run at 94.0% host usage. A confirmatory quick gate was also stopped immediately at 97.9% while an unrelated `/Volumes/SSD/Documents/github/pgen` rustc process held 9,123,344 KiB RSS; no unguarded broad rerun was substituted, and leaf `.3` retains the final broader-gate opportunity.`
  Commit: `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.2: localize runtime and test storage`

- ID: `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.3`
  Status: `active`
  Goal: `Synchronize active public instructions and fact-card reverification, perform exact residue migration/cleanup, and close the adoption.`
  Acceptance: `README, TOOLBOX, active fact-card reverify commands, generated Knowledge Map, and remaining relevant live references use repository-relative local storage; off-volume project-owned residue census/migration/removal evidence is recorded; no ambiguous shared cache is deleted; all focused, doctrine, Knowledge Map, mdBook, memory, diff, and warranted broader gates pass; the tree closes cleanly and PNT returns to a roadmap-aligned owner.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.1` | `done` | Decision 0022, the root policy, exact pre-adoption debt signatures, doctrine registration, Knowledge Map fact, and adjacent startup-drift owners are in place. |
| 2 | `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.2` | `done` | Runtime/lowering storage, Knowledge Map scratch, test/gate environment, output containment, focused regressions, and affected mdBook behavior are repository-local. |
| 3 | `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.3` | `active` | Synchronize remaining public/fact-card commands, prove residue cleanup, retire the final migration signature, and close the adoption. |

## Decisions

- `2026-07-29`: The director explicitly authorized keeping the legacy blobs
  frozen, activating this same-volume policy tree, committing the policy work,
  and resuming roadmap PNT afterward.
- `2026-07-29`: The startup audit measured a clean baseline at `2efd79375` and
  found live off-volume defaults in CLI/in-process temporary lowering,
  Knowledge Map scratch creation, standard test fixtures, and active public
  commands. Historical task-tree evidence and ambiguous shared caches require
  classification rather than blind replacement or deletion.
- `2026-07-29`: Leaf `.1` pins exact content signatures for runtime temporary
  calls, public off-volume commands, explicit test paths, the File::Temp test
  set, and legacy machine-local configuration. Leaves `.2` and `.3` must
  shrink and finally retire those migration signatures; changing debt without
  task-tree classification fails the doctrine gate.
- `2026-07-29`: Leaf `.2` owns the mdBook command and option updates directly
  affected by its CLI output-containment change. Leaf `.3` retains the README,
  toolbox, fact-card, Knowledge Map, residue, and remaining live-reference
  closeout so no committed runtime behavior is temporarily misdocumented.
- `2026-07-29`: `FSM::ProjectDataLocality` is the shared runtime containment
  boundary. CLI output, review, verification, and trace destinations must
  resolve inside the repository; external source inputs remain explicit
  read-only inputs. Implicit IAL1/IAL2 handoff files use typed
  `.artifacts/tmp/` workspaces, while standard `prove` and repo launchers set
  repository-local temp/cache environment before creating fixtures.
- `2026-07-29`: The extended `.2` regression encountered the exact stale APB
  diagnostic already owned by proposed tree `IAL2-T1436-PREEXISTING-FAILURES`;
  `git show HEAD` proves the expectation and expanded implementation message
  both predate this slice. The guarded run stopped later under real external
  memory pressure from a separate `pgen` rustc process. No unrelated fix or
  unsafe unguarded broad rerun was mixed into `.2`.

## Open Questions

- None. The director supplied the policy and authorized this adoption.

## Blockers

- None.
