# Project Document Lifecycle Policy Audit

## Scope And Decision Boundary

This audit closes `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`. It evaluates
four documents independently:

- `CHANGES.md`
- `DEVELOPMENT_NOTES.md`
- `ROADMAP_STATUS.md`
- `LIVE_ACHIEVEMENT_STATUS.md`

The evidence snapshot is repository `37eb6d8b50` on `2026-08-01`. The audit
selects each document's long-term role, but it does not migrate, rewrite, or
remove any reviewed document. Decision
[0046](decisions/0046-project-documents-use-two-bounded-ledgers-and-canonical-live-views.md)
records the selection. The existing containment leaves perform the schema and
migrations atomically after this audit commits.

## Later Director Refinement

On `2026-08-01`, before the bounded-ledger migration began, the director
reopened whether the changelog had any value independent of the now-enforced
task-tree/Git/Memory/mdBook architecture. The fresh `.4` audit found no content
consumer or distinct current question, and decision
[0047](decisions/0047-changes-history-is-task-trees-and-git.md) supersedes only
this audit's `CHANGES.md` retention clauses: the live changelog is retired,
task trees plus Git own change history, and the exact former object remains
retrievable. This does not decide the lifecycle of any other document.

The earlier `LIVE_ACHIEVEMENT_STATUS.md` selection below depended in part on a
retained changelog. Leaf `.11` must therefore audit that file independently and
ask the director whether its evidence shows unique value before implementing
any lifecycle change. No outcome may be inferred from the changelog decision.

## Evidence Method

The review used:

- current line, byte, heading, and SHA-256 measurements;
- complete path history and selected historical snapshots from Git;
- whole-repository reference searches, separated into executable consumers,
  current workflow/navigation consumers, and historical evidence mentions;
- direct inspection of current and initial content;
- comparison with the canonical roles assigned by `MEMORY_ARCHITECTURE.md`,
  `docs/TASK_TREE.md`, `ROADMAP_V2.md`, decisions, Knowledge Map facts, the
  mdBook, and Git;
- the lifecycle and pressure evidence already established by
  `docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md` and
  `docs/LIVE_DOCUMENT_UTILITY_RETIREMENT_AUDIT.md`.

Historical task files and changelog entries that mention a reviewed path are
evidence, not live consumers. They remain truthful when a later lifecycle
migration changes the working-tree representation.

## Measured History

| Document | Introduced | Initial size | 2026-04-01 snapshot | 2026-06-02 snapshot | Current size | Path commits | Last change |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| `CHANGES.md` | `2026-02-20` | 22 lines / 2,141 bytes | 5,317 / 688,002 | 30,413 / 2,576,509 | 32,299 / 2,695,316 | 3,130 | active, `2026-08-01` |
| `DEVELOPMENT_NOTES.md` | `2026-02-20` | 12 lines / 2,302 bytes | 7,371 / 755,773 | 34,255 / 2,479,167 | 34,507 / 2,494,480 | 3,023 | conditional use, `2026-07-31` |
| `ROADMAP_STATUS.md` | `2026-03-14` | 123 lines / 5,757 bytes | 1,589 / 208,635 | 15,039 / 1,638,574 | 15,039 / 1,638,574 | 2,760 | frozen, `2026-06-01` |
| `LIVE_ACHIEVEMENT_STATUS.md` | `2026-05-10` | 12 lines / 698 bytes | absent | 16,618 / 955,308 | 16,618 / 955,308 | 1,339 | frozen, `2026-06-01` |

`CHANGES.md` now has 174 level-two and about 2,983 level-three headings.
`DEVELOPMENT_NOTES.md` has about 2,843 level-two entries. The two status files
grew from 135 aggregate lines at introduction to 31,657 lines by `2026-06-01`.
That growth is accumulated work-unit narration rather than product-reference
scope.

The frozen identities remain:

- `ROADMAP_STATUS.md`:
  `0f8db932c57d883d97f1f92fec8a576795b5b367157d9846088501c52aeb22d8`
- `LIVE_ACHIEVEMENT_STATUS.md`:
  `46c3c8ad2a0b7375a02b0a111bcc65410f78e0dd1df97709aeabe5f97b735d18`

## Consumer And Authority Audit

The repository contains many literal references because historical tasks
record which live documents a past workflow updated. Current consumers are
much narrower.

| Document | Current consumers | Automated consumer | Canonical overlap |
| --- | --- | --- | --- |
| `CHANGES.md` | `README.md`, `AGENTS.md`, `COMMIT.md`, `TOOLBOX.md`, task workflow, mdBook reference map, README route registry, size registry | pressure/routing doctrine and `t/1553` fixtures | exact changes and evidence live in task trees and Git; the concise editorial summary is distinct |
| `DEVELOPMENT_NOTES.md` | the same workflow surfaces, but only on a conditional trigger | pressure/routing doctrine | cross-cutting decisions belong in ADRs, durable facts in cards, task evidence in task trees, product behavior in the book; local implementation rationale can still be distinct |
| `ROADMAP_STATUS.md` | interim frozen-file references, one stale composition-note link, and historical mentions | `t/1332-isf-atl-doc-status-audit.t` opens it only to assert absence of `Active R14 ATL axis` | direction is `ROADMAP_V2.md`; live state is `docs/TASK_TREE.md`; resume state is `MEMORY.md`; history is Git |
| `LIVE_ACHIEVEMENT_STATUS.md` | interim frozen-file references and historical mentions | no product/runtime consumer found; only generic lifecycle/doctrine checks | concise accomplishments are in `CHANGES.md`; exact completion/evidence is in task trees and Git |

The `t/1332` dependency is a migration hazard, not a useful status contract.
Its positive ATL truth already comes from the feature backlog and design
proposal. Leaf `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11` must replace the
negative scan of a frozen file with a current canonical assertion before the
file is removed from the working tree. The same leaf must redirect the stale
`docs/COMPOSITION_LEGACY_MAPPING.md` current-source link and every current
workflow, book, README-route, and registry consumer. Historical evidence
mentions are not rewritten.

## Audience And Distinct Questions

| Document | Useful audience | Distinct question after canonical routing? |
| --- | --- | --- |
| `CHANGES.md` | formerly maintainers and reviewers seeking a curated work-unit summary | no: the owning task node and work-unit Git commit answer the question more exactly |
| `DEVELOPMENT_NOTES.md` | maintainers investigating non-obvious local engineering rationale | yes, but only when the rationale is not a decision, fact, task proof, user contract, or self-evident commit |
| `ROADMAP_STATUS.md` | formerly maintainers seeking direction plus live status | no: its two questions now have separate, fresher canonical homes |
| `LIVE_ACHIEVEMENT_STATUS.md` | formerly maintainers seeking the latest completed slice | no: its content duplicates the retained changelog and stronger exact evidence |

## Options Compared

### `CHANGES.md`

| Option | Authority/cadence | Recovery and automation | Burden and drift risk | Outcome |
| --- | --- | --- | --- | --- |
| Keep the monolith | one editorial entry per completed slice | simple append; poor bounded retrieval | guaranteed unbounded growth | reject |
| Generate from Git/task trees | generated per commit or release | reproducible, but loses the deliberately curated “what changed” summary | generation logic must infer significance and wording | reject |
| Retire | Git/task trees only | exact recovery remains through the declared version object | removes a duplicate editorial view, not a unique content consumer | **select under 0047** |
| Re-form as a bounded ledger | one concise editorial entry per completed slice; task/Git remain exact authority | automate whole-entry segmentation, digest, order, reconstruction, and retrieval | continuing editorial duplication and drift risk without a distinct reader question | superseded by `0047` |

The selected current view is the owning task node plus the work-unit-bearing
Git commit. The exact former monolith remains version-retrievable under a
retention contract; no replacement changelog or generated projection is
created.

### `DEVELOPMENT_NOTES.md`

| Option | Authority/cadence | Recovery and automation | Burden and drift risk | Outcome |
| --- | --- | --- | --- | --- |
| Restore per-slice notes | hand-written every slice | simple append | duplicates decisions, task evidence, book, and Git; high growth | reject |
| Merge everything into decisions/facts | only ADR/card updates | strong for cross-cutting facts | forces local implementation rationale into the wrong semantic layer | reject |
| Retire after content migration | other layers only | possible only after entry-level uniqueness proof | high migration cost and risk to early unique rationale | defer, not selected |
| Re-form as a conditional bounded rationale ledger | write only non-obvious local rationale with no better home | automate whole-entry segmentation, digest, order, reconstruction, and retrieval | low prospective growth; clear author decision remains | **select** |

The entry trigger is semantic, not per-commit: add a note only when a future
maintainer would otherwise have to rediscover a useful constraint or local
tradeoff and no decision, fact card, task evidence, user document, source
comment, or commit message owns it better. An omitted note is correct when
those layers already explain the work.

### `ROADMAP_STATUS.md`

| Option | Authority/cadence | Recovery and automation | Burden and drift risk | Outcome |
| --- | --- | --- | --- | --- |
| Reactivate a bounded board | manual synchronization with roadmap/task state | current view possible | creates a second live authority and recurrent contradiction risk | reject |
| Generate a status view | derive from roadmap/task/Memory | feasible | adds a redundant checked-in projection with no distinct audience question | reject |
| Merge with achievement/changelog | manual combined narrative | retains chronology | recreates the same mixed status/history blob | reject |
| Supersede and archive | canonical views answer direction/state; exact frozen object remains retrievable | cheap, deterministic, no content loss | current consumers must migrate once | **select** |

The file's own header still calls it the canonical live board, while its
frozen top reports no active task despite active task trees. It is therefore
actively misleading as a current view. Leaf `.11` will preserve its exact
identity in the declared archive/revision contract and remove it from current
navigation and the working tree only after consumer and retrieval proof.

### `LIVE_ACHIEVEMENT_STATUS.md`

| Option | Authority/cadence | Recovery and automation | Burden and drift risk | Outcome |
| --- | --- | --- | --- | --- |
| Reactivate a bounded latest-achievement view | manual per-slice update | easy | duplicates `CHANGES.md`, task closure, and Memory | reject |
| Generate from completed task nodes | derivable | feasible | still duplicates the retained changelog without serving a distinct decision | reject |
| Merge into `CHANGES.md` | editorial changelog | no new data needed | its historical content already overlaps; merging would duplicate entries | reject |
| Supersede and archive | `CHANGES.md` for human summary; task/Git for exact evidence | cheap, deterministic, no content loss | current consumers must migrate once | **select** |

This prior selection is reopened because its comparison assumed a retained
changelog. Leaf `.11` must preserve the exact frozen identity while it performs
a fresh value/consumer/replacement audit and obtains the director's independent
lifecycle choice. It may retire the live path only if that later choice and the
required proof authorize retirement.

## Selected Cross-Cutting Policy

1. Retire `CHANGES.md`; task-tree evidence plus the work-unit Git commit are the
   current and exact change-history authorities, and the exact former object
   remains deterministically retrievable.
2. Retain `DEVELOPMENT_NOTES.md` as a conditional engineering-rationale
   rolling ledger under the existing “no better canonical home” trigger, with
   a bounded current/index view over sealed whole-entry history.
3. Supersede `ROADMAP_STATUS.md` as a current source with `ROADMAP_V2.md`,
   `docs/TASK_TREE.md`, and `MEMORY.md`; preserve its exact frozen content
   through an archive/revision retrieval contract, then retire the live path.
4. Keep `LIVE_ACHIEVEMENT_STATUS.md` frozen until `.11` independently audits
   its unique value and the director selects its lifecycle; do not infer that
   choice from the retired changelog.
5. Do not generate or merge a replacement status blob. Each current question
   routes directly to its one canonical layer.
6. Decision `0047` governs change history. Decision `0025` remains the
   operational transition policy for the other reviewed documents until their
   owned migrations land. Selection alone does not authorize a write to either
   frozen file.

## Implementation Decomposition

| Order | Owner | Exact responsibility |
| ---: | --- | --- |
| 1 | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3` | implement and prove the neutral bounded-ledger/sealed-range/archive-descriptor schema without migrating either ledger |
| 2 | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4` | retire the duplicate changelog; prove exact identity/retrieval, consumer closure, planted negatives, and live-path absence |
| 3 | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.5` | migrate `DEVELOPMENT_NOTES.md` at whole-entry boundaries; prove the same integrity properties and preserve the conditional trigger |
| 4 | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11` | independently audit both frozen status documents, ask the director to select each lifecycle, then implement only the selected outcomes with consumer and retrieval proof |
| 5 | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.12` | remeasure steady state and replace transition ceilings with derived retained-surface budgets |

Each migration is a separate commit-workflow slice. A failure in one document
does not authorize changing another document's selected outcome.

## Reverification

From the repository root:

```bash
wc -l -c CHANGES.md DEVELOPMENT_NOTES.md ROADMAP_STATUS.md LIVE_ACHIEVEMENT_STATUS.md
sha256sum ROADMAP_STATUS.md LIVE_ACHIEVEMENT_STATUS.md
git log --follow --reverse --format='%H %ad %s' --date=short -- CHANGES.md
git log --follow --reverse --format='%H %ad %s' --date=short -- DEVELOPMENT_NOTES.md
git log --follow --reverse --format='%H %ad %s' --date=short -- ROADMAP_STATUS.md
git log --follow --reverse --format='%H %ad %s' --date=short -- LIVE_ACHIEVEMENT_STATUS.md
rg -n 'ROADMAP_STATUS\.md|LIVE_ACHIEVEMENT_STATUS\.md|CHANGES\.md|DEVELOPMENT_NOTES\.md' AGENTS.md COMMIT.md README.md TOOLBOX.md doctrine scripts t docs
sed -n '1,90p' t/1332-isf-atl-doc-status-audit.t
```
