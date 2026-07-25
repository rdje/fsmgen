# README-ENTRYPOINT-APPEND-LOG-DRIFT: Entry-Point README Has Become A Per-Leaf Append Log

## Metadata

- Tree ID: `README-ENTRYPOINT-APPEND-LOG-DRIFT`
- Status: `active`
- Roadmap lane: `infra/continuity / entry-point documentation`
- Created: `2026-07-25`
- Last updated: `2026-07-25`
- Owner: repo-local workflow
- Activation: **activated by the director on 2026-07-25** — "README.md shall NOT
  be used as a per-leaf append log, please strictly follow the doctrine
  MEMORY_ARCHITECTURE.md advocates." That selects candidate shape 1 (trim to a
  real entry point) plus shape 3 (cap and enforce) as the follow-up, because
  §12 forbids re-narrating git history in prose and §9 holds that an unchecked
  rule is an unfollowed rule.

## Finding

`README.md` is the declared single entry point (`AGENTS.md` step 1,
`MEMORY_ARCHITECTURE.md` §7). It is now **9,911 lines / 928 KiB**, and its
`## Project objective` section alone spans **lines 74-7265 - 7,191 lines and
~507,000 characters, i.e. 73% of the whole file**. Inside that one section
there are **1,827 short-form leaf references** (`` `.NNN` ``) and **423 lines**
carrying `ships` / `shipped` / `selected` narration.

That section is no longer a project objective. It is a chronological, per-leaf
account of what each work-unit shipped - the same information git (layer D)
already holds and `git log --grep=<UNIT-ID>` already reconstructs.

## Why This Matters

This is the exact failure mode the repo's own memory standard was adopted to
kill, now recurring one file over:

- `MEMORY_ARCHITECTURE.md` §12 lists "Re-narrating git history into prose docs
  (duplication that goes stale)" and "One giant file you must read top-to-bottom
  to find 'what's next'" as anti-patterns.
- `MEMORY-ARCHITECTURE-ADOPTION` demoted `MEMORY.md` from 38,776 lines to a
  bounded 60-line pointer for this reason, and that cap is mechanically
  enforced. `README.md` carries no equivalent cap, so the growth moved here.
- The cost is paid on **every** session ramp-up in **every** harness, because
  the bootstrap chain routes every fresh agent to this file first. Reading the
  objective section in full is roughly 127k tokens before any work begins.
- Correctness risk: prose describing 800+ shipped leaves cannot be mechanically
  checked against the code, so it can drift silently. The task-trees and the
  mdBook are the surfaces that *are* checked.

## Non-Goals

- Not proposing deletion of any history. Everything in the section is already
  in git and recoverable.
- Not proposing changes to `MEMORY.md`, the task-trees, the decision store, or
  the Knowledge Map - those layers are working as designed.
- Not proposing an mdBook change; the book is user-facing product documentation
  and is a separate, healthy surface.
- Not proposing a mechanical README line cap in the same slice as any content
  move; a cap without an agreed target shape would just fail the build.

## Selected Shape

**Shape 1 (trim to a real entry point) + shape 3 (cap and enforce).** Director
instruction, `2026-07-25`.

Nothing is deleted from the project: `README.md` is tracked, so the removed
prose stays recoverable via `git log -p -- README.md`, exactly as
`MEMORY.md`'s own header records for its 38,776-line predecessor. This mirrors
the two established precedents in this repo:

- `MEMORY-ARCHITECTURE-ADOPTION` demoted `MEMORY.md` 38,776 → 24 lines.
- `docs/decisions/0007` FROZE the legacy prose blobs rather than deleting them.

Pre-trim evidence that no durable fact is lost — every non-chronological fact
in the section already has a canonical home:

| Fact in the objective section | Canonical home |
| --- | --- |
| Backend-language-neutral IAL contracts, Perl as reference/oracle | `docs/decisions/0018-ial-contracts-are-backend-language-neutral.md`, `docs/book/src/15-implementation-blueprint.md` |
| Read-only semantic-introspection / MCP profile detail | `docs/book/src/11-extensions-and-embedding.md` (30 MCP references), `docs/SEMANTIC_INTROSPECTION_MCP_FIRST_CLASS_SELECTION.md`, `docs/knowledge/semantic-introspection-mcp-frontier.md`, `docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md` |
| Per-leaf shipped-behavior chronology | git (layer D) + the owning task trees (layer B) |
| Corpus sample inventory | `docs/REGRESSION_CORPUS.md` + `perl/FSM/Support/RegressionCorpus.pm`, mechanically checked by `t/248-regression-corpus-accounting.t` |

Verified before the trim: no test or gate asserts `README.md` *content*.
`scripts/check_doctrine_bootstrap.sh` requires only that the file exists and
that bootstrap files point at it; `t/1134`, `t/1441`, `t/1447` use the path as
a wrong-extension fixture; `t/1251` and `bin/fsmgen-issue-bundle` refer to a
generated bundle README, not this one.

## Candidate Shapes (recorded at filing; shape 1 + 3 selected)

1. **Trim to a real entry point.** Keep objective, layout, navigation, and
   invariants; replace the per-leaf narration with pointers to
   `docs/TASK_TREE.md`, the owning trees, and `git log --grep`. Largest
   ramp-up saving; loses nothing recoverable.
2. **Split.** Keep `README.md` short and move the shipped-behavior narrative to
   a clearly-labelled `docs/SHIPPED_BEHAVIOR_LOG.md` that the bootstrap chain
   does *not* route agents through. Preserves the prose verbatim; halves the
   mandatory read.
3. **Cap and enforce.** Add a `README` size doctrine check under
   `scripts/check_doctrines.sh` after either 1 or 2, so the regrowth that
   produced this finding cannot recur silently. Only meaningful as a follow-up.
4. **Accept as-is.** Explicitly record that the entry point is intentionally an
   append log, and amend `MEMORY_ARCHITECTURE.md` §12 so doctrine and practice
   stop contradicting each other. Cheapest; keeps the ramp-up cost.

## Acceptance Criteria (if activated)

- A shape is selected and recorded as a decision record under `docs/decisions/`.
- No information is lost that is not already recoverable from git.
- The bootstrap chain (`AGENTS.md`, `CLAUDE.md`, `.cursorrules`,
  `GEMINI.md`, `.windsurfrules`, `.github/copilot-instructions.md`) still routes
  a fresh agent to a coherent system of record.
- `scripts/check_doctrines.sh` passes, including `DOCTRINE-BOOTSTRAP`, which
  asserts the bootstrap pointers.
- Committed through `COMMIT.md` with the leaf id in the subject.

## Task Tree

- ID: `README-ENTRYPOINT-APPEND-LOG-DRIFT`
  Status: `active`
  Goal: `Restore README.md to a bounded discovery entry point and make the per-leaf-append-log regression mechanically impossible.`
  Children: `README-ENTRYPOINT-APPEND-LOG-DRIFT.1, README-ENTRYPOINT-APPEND-LOG-DRIFT.2, README-ENTRYPOINT-APPEND-LOG-DRIFT.3, README-ENTRYPOINT-APPEND-LOG-DRIFT.4`

- ID: `README-ENTRYPOINT-APPEND-LOG-DRIFT.1`
  Status: `done`
  Goal: `Record the selected shape as a decision record (layer C) so the rule outlives this session.`
  Acceptance: `A dated docs/decisions/NNNN record states that README.md is a bounded discovery entry point and must not re-narrate git history; docs/decisions/INDEX.md lists it; the doctrine driver passes.`
  Verification: `docs/decisions/0021-readme-is-a-bounded-discovery-entrypoint.md written as an explicit extension of 0007, with the measured evidence (9,911 lines / 928 KiB; objective section 7,191 lines / 73% / 1,827 leaf refs) and the four-part rule; docs/decisions/INDEX.md row added after 0020; scripts/check_doctrines.sh all PASS.`
  Commit: `README-ENTRYPOINT-APPEND-LOG-DRIFT.1: record bounded-entrypoint decision`

- ID: `README-ENTRYPOINT-APPEND-LOG-DRIFT.2`
  Status: `done`
  Goal: `Trim ## Project objective from 7,191 lines of per-leaf chronology to a real objective section that states what FSMGen is and points at the canonical layers.`
  Acceptance: `The section states objective, the IAL0/IAL1/IAL2 layer model, and the backend-neutrality contract, and routes current state to the task-trees, decisions, mdBook, and Knowledge Map; no per-leaf chronology remains; every fact in the pre-trim evidence table is still reachable from its canonical home; scripts/check_doctrines.sh passes.`
  Verification: `README.md 9,911 -> 2,803 lines and 928 KiB -> 440 KiB; the objective section is 7,191 -> 83 lines with zero per-leaf references. New section carries objective, the IAL2/IAL1/IAL0 layer table with the strict lowering order and the forbidden direct IAL2-to-IAL0 path (0014/0015/0016), backend neutrality (0018 + blueprint chapter), the read-only MCP profile pointer (book ch. 11), and a "where current state lives" routing table naming layers A-D plus the book, corpus, Knowledge Map, toolbox, and doctrine registry. All 8 link targets verified to exist. scripts/check_doctrines.sh all PASS including DOCTRINE-BOOTSTRAP (all 7 bootstrap files still point at README.md). prove -Iperl t/1134 t/1441 t/1447 t/1251 t/1414: 5 files, 12 tests, all PASS.`
  Commit: `README-ENTRYPOINT-APPEND-LOG-DRIFT.2: trim objective section to a real entry point`

- ID: `README-ENTRYPOINT-APPEND-LOG-DRIFT.3`
  Status: `pending`
  Goal: `De-narrate ## Documentation index entries so each is a one-line statement of what the file is, not a per-leaf changelog of it.`
  Acceptance: `Index entries carry purpose, not leaf chronology; the ~99 corpus-sample rows route to docs/REGRESSION_CORPUS.md instead of duplicating the mechanically-checked catalog; no tracked .md file loses its index entry; scripts/check_doctrines.sh passes.`
  Verification: `pending`
  Commit: `pending`

- ID: `README-ENTRYPOINT-APPEND-LOG-DRIFT.4`
  Status: `pending`
  Goal: `Register a deterministic README doctrine check so the regrowth that produced this finding fails the build instead of recurring silently.`
  Acceptance: `An executable check enforces a README size cap and a per-leaf-chronology heuristic, is registered in the scripts/check_doctrines.sh DOCTRINES registry, is documented in DOCTRINE_ENFORCEMENT.md and TOOLBOX.md, is proven to bite on a seeded violation, and passes on the trimmed file.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-25`: Filed as `proposed` and explicitly **not** PNT-eligible. The
  entry point is the system of record for every harness; changing its shape is
  the director's call, not an autonomous slice.
- `2026-07-25`: Measurements recorded here rather than left in a session
  transcript, so the finding survives session loss per
  `MEMORY_ARCHITECTURE.md` §4.

## Open Questions

- Which candidate shape does the director want? This blocks `.1` and nothing
  else; no active work depends on it.

## Blockers

- Awaiting director selection. Not blocking any other tree.
