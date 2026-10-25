# ISF-SPEC-TEST-INDEX-SYNC: ISF Spec Focused-Test Index Sync

## Metadata

- Tree ID: `ISF-SPEC-TEST-INDEX-SYNC`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-10-25`
- Owner: repo-local workflow

## Goal

Keep the focused test index in `docs/isf-spec/04-reports-fixtures-deferrals.md`,
reachable from `docs/ISF_SPEC.md`, synchronized with `t/*-isf-*.t`.

## Non-Goals

- Do not change parser, scheduler, report, generated `.fsm`, or HDL behavior.
- Do not reorganize the broader regression suite.
- Do not expand or freeze the whole schedule-report schema.

## Acceptance Criteria

- `docs/isf-spec/04-reports-fixtures-deferrals.md` lists every current `t/*-isf-*.t` regression.
- A focused audit prevents future ISF tests from being added without updating
  the spec's focused-test index.
- Focused validation passes.
- Live docs and roadmap/task-tree status are updated.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-SPEC-TEST-INDEX-SYNC`
  Status: `active`
  Goal: `Synchronize and audit the ISF spec focused-test index`
  Children: `ISF-SPEC-TEST-INDEX-SYNC.1, ISF-SPEC-TEST-INDEX-SYNC.2, ISF-SPEC-TEST-INDEX-SYNC.3, ISF-SPEC-TEST-INDEX-SYNC.4`

- ID: `ISF-SPEC-TEST-INDEX-SYNC.1`
  Status: `done`
  Goal: `List missing ISF tests in the spec and add a drift audit`
  Acceptance: `Spec index includes all current ISF tests and the new audit fails if the index drifts`
  Verification: `prove -Iperl t/1207-isf-assignment-provenance-inventory.t t/1208-isf-compatible-fanin-classification.t t/1248-isf-rule-trigger-parameter-binding.t t/1249-isf-activation-parameter-constants.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-SPEC-TEST-INDEX-SYNC.1: audit spec test index`

- ID: `ISF-SPEC-TEST-INDEX-SYNC.2`
  Status: `done`
  Goal: `Repair focused-test index drift after ATL doc-status audit coverage`
  Acceptance: `Spec index includes t/1332-isf-atl-doc-status-audit.t and the focused audit passes`
  Verification: `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t; mdbook build docs/book; git diff --check`
  Commit: `ISF-SPEC-TEST-INDEX-SYNC.2: sync ATL doc-status audit index`

- ID: `ISF-SPEC-TEST-INDEX-SYNC.3`
  Status: `active`
  Goal: `Repair focused-test index drift after published timing-claim coverage`
  Acceptance: `Record the exact introducing change; add only t/1639-isf-published-timing-claims.t at the lexicographically correct authoritative mdBook source location; register that intentional post-partition addition as an exact archived-source transformation; prove the index has no missing or extra paths and activation-content equality holds; retain the audits unchanged; pass focused, book, doctrine, and complete guarded-CI gates before the pending 300-commit push.`
  Verification: `Pre-fix guarded ./bin/ci-regression reaches one t/1250 mismatch: listed index 332 has no element where expected index 332 is t/1639-isf-published-timing-claims.t; the independently executed t/1639 passes. Git identifies 8b2a6697905bf6f6b66dad0306b4e4c9576af470 as adding t/1639 without changing the authoritative focused-test source. The post-fix complete run passes t/1250, then t/1569 independently falsifies an incomplete repair because the bounded part differs from its sealed activation source at docs/isf-spec/04-reports-fixtures-deferrals.md:1267. The same run exposes a t/1558 runtime timeout and later exits 137 only when host occupied memory reaches the authorized 88% cutoff during t/296; the active FSMGEN child remains far below its separate 4,096-MiB descendant ceiling. No t/296 checkpoint was configured, so the completed batches are not durable and the retry must activate the repository-local checkpoint contract. Exact repository-local interrupted-run residue is removed only after proving the process tree and open-file set empty. The committed post-repair ordered and independent set oracles proved 333 listed/expected with zero missing/extra; focused reference tests, exact activation-content equality, all mdBook chapters, maintained-reference authority, containment, and zero-ceiling-increase gates passed as recorded below. Complete guarded CI remains pending after the repair commit.`
  Commit: `f3e7f94dc333fc624fb0d05a0227bd8fdf489460; exact-transformation repair committed, complete-CI qualification pending`
  Children: `ISF-SPEC-TEST-INDEX-SYNC.3.1, ISF-SPEC-TEST-INDEX-SYNC.3.2`

- ID: `ISF-SPEC-TEST-INDEX-SYNC.3.1`
  Status: `done`
  Goal: `Reconcile the already committed exact-transformation repair with the live frontier.`
  Acceptance: `Verify the actual introducing and repair commits against the current counted rewrite and focused-test source; replace obsolete uncommitted/implementation-next pointers with the exact committed repair and remaining complete-CI blocker. Do not change source, assertions, qualification requirements, runtime behavior or the pending HIAL endpoint decision. Validate the source identity and documentation gates, then commit this continuity repair.`
  Verification: `Git ancestry and current-versus-commit byte comparison verify the exact-transformation repair at f3e7f94dc333fc624fb0d05a0227bd8fdf489460. The manifest, authoritative focused-test source, t/1250 and t/1639 equal that commit. The initial whole-file identity assertion failed for t/1569; exact diff and history attribute its sole later delta to the VIAL v2 contract fixture-list member in c43e158e8fba263fbc0e43902bd5198f6f75b51e, with all other bytes and assertions unchanged. The original introducing commit 8b2a6697905bf6f6b66dad0306b4e4c9576af470 added t/1639 without its index link. Fresh guarded exact activation-content verification and t/1250/t/1569 pass (Files=2, Tests=8). Evidence is retained under .artifacts/logs/isf-frontier-reconciliation-20260907/: initial-identity-failure.txt, source-identity.json and focused-checks.log. The current task/index now name the committed repair and remaining qualification blocker. The first staged doctrine run rejected the container status and Commit-field delimiter; the corrected tree retains an active parent and assigns remaining qualification to blocked leaf .3.2. The corrected staged doctrine driver passes every registered check, with the docs-only task-acceptance exemption explicitly reported; logs retain both staged-doctrines.log and corrected-staged-doctrines.log. No source, assertion, book behavior or endpoint prerequisite changes are made.`
  Commit: `ISF-SPEC-TEST-INDEX-SYNC.3.1: reconcile committed repair frontier`

- ID: `ISF-SPEC-TEST-INDEX-SYNC.3.2`
  Status: `pending`
  Goal: `Consume complete guarded-CI qualification under the director publication order.`
  Acceptance: `Preserve prior failures and normal resource cutoffs. SEMANTIC-INTROSPECTION-MCP-FRONTIER.69.3 now owns the director-ordered qualified push and hosted CI before macOS relevance review, superseding the old blanket startup hold for that workflow. After current index repair .4, explicitly enable FSMGEN_T296_CHECKPOINT at a safe .artifacts/t296/<safe-name>.json path, run complete guarded CI from clean committed inputs, own every failure and consume the exact-SHA hosted result. Historical causality is not inferred from a later pass.`
  Verification: `The f3e7f94dc repair and earlier failure history retain. At bff84006b the live catalog has since evolved and T1250 fails; .4 owns current synchronization. Primary local-full-ci-2 was administratively stopped after known failures, without the required t296 checkpoint; guard status143 and the incomplete output are retained. All owned descendants are verified absent. No completed full-CI or push qualification is claimed. Next qualifying run must use the documented checkpoint; publication remains owned by SEM .69.3.`
  Commit: `pending complete-CI qualification`

- ID: `ISF-SPEC-TEST-INDEX-SYNC.4`
  Status: `done`
  Goal: `Refresh the evolved focused-test catalog without losing annotations or archived source.`
  Acceptance: `Before editing the catalog, retain the bff84006b T1250 failure and enumerate current paths, missing/extra entries, duplicates and order independently. Reorder complete existing entry blocks with their annotations and insert every missing current t/*-isf-*.t member in exact lexical order. Preserve all noncatalog bytes, tests, runtime, source behavior and sealed activation records. Current T1569 separates bounded live edits from exact historical fixture reconstruction (eb2b8f2a1); follow that established contract rather than rewriting history. Add the matching-test/index focused check to the existing reusable ISF synchronization checklist, refresh bounded maintained-reference authority with no ceiling increase, and route catalog/current-publication facts through the existing Knowledge Map card while preserving every old question. The prior card reverify --current freezes whole Oct5 cards and rejects this intended extension; preserve its original historical proof and select normal current containment/catalog checks for live facts. Compact wording inside the unchanged card allowance; qualify current catalog, adverse controls, source/reference/book and staged/normal gates. Commit this narrow repair before the separate .3.2 full-CI qualification; keep primary runtime/test inputs unchanged during its ongoing census.`
  Verification: `Prepared in the isolated worktree. docs/audits/isf-focused-index-refresh-20261025 retains the exact bff84006b failure prefix and complete before/after membership/block identities. Every existing annotation block and all noncatalog bytes are preserved; no test, runtime or sealed manifest changes. Guarded adjacent T1120/T1250/T1414/T1569 pass (All tests successful, Files=4 Tests=17); Knowledge Map validation/direct new-question routing and the hashed source reader pass. Actual omission/duplicate/order controls reject through T1250; reader controls reject changed annotation and noncatalog bytes even after whole-source hash covariation, then restore exact source/receipt. checks.json names distinct re-derivation, falsification and durability legs and limits. The reusable ISF checklist now selects T1250 for matching-test additions/renames/removals. Current native publication ownership is routed accurately without closing historical causality. Primary full2 was administratively stopped after verified failures, with no checkpoint or suite completion; status143, exact termination ownership and absent-descendant census retain in push-readiness-20261025/local-full-ci-2*. publication-followups.json schedules every observed follow-up and corrects the CI-policy attribution. Exact preparation bytes transferred to primary after termination and compare equal. Native mdBook/POD/source-index and exact built source-byte checks pass in the isolated worktree; the first sandbox guard refusal and successful process-access retry both retain under push-readiness-20261025/index-book-preflight*. Primary guarded adjacent tests, preservation reader, native mdBook/POD, exact built source bytes and source index repeat successfully in index-primary-validation.json. The first staged gate rejects knowledge-card debt; wording is compacted without changing its allowance or dropping questions/facts. The old card --current reader also rejects intended live evolution; its historical default passes, and current normal containment/catalog checks now supplement that proof. First failures retain. Task transition allowance is remeasured after final owner text. Staged/normal gates are required before this commit; the linked-worktree .git-file gate defect is not bypassed.`
  Commit: `ISF-SPEC-TEST-INDEX-SYNC.4: preserve annotations while refreshing focused catalog`
  - [x] **ROOT CAUSE (WHY + WHERE)** — The retained bff84006b diagnostic says at t/1250-isf-spec-focused-test-index-audit.t line 32: index292 is t/2043 where current domain requires t/1397. The before-source catalog diverges from independent glob/rg and Git test populations. derivation.json records exact missing paths/order and annotation-block identities; current T1569/eb2b8f2a1 permits bounded live evolution independently of immutable activation reconstruction.
  - [x] **ADDRESSED (verified)** — Exact current lexical membership is restored by moving complete existing blocks and inserting missing members. The hashed verify.py re-derives exact before/after source/domain, old annotations, noncatalog bytes and unchanged manifest. Actual omitted/duplicate/order controls fail T1250; independent altered-annotation/noncatalog controls still fail after whole-source hash covariation. All controls restore exact bytes. Existing synchronization checklist and Knowledge Map now route the focused audit without dropping old questions or raising ceilings.
  - [x] **NO REGRESSION** — All tests successful for guarded T1120/T1250/T1414/T1569; knowledge-map: OK and direct new-question routing preserve the existing card. Native mdBook/POD, built source-byte and source-index checks pass in preparation; primary checks also pass after exact transfer. Staged/normal scripts/check_doctrines.sh remain mandatory before commit. Full CI remains .3.2 and is not claimed by these focused checks.

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-SPEC-TEST-INDEX-SYNC.3.2` | `pending` | Current catalog repair .4 is verified; resolve SEM .69.3 publication follow-ups, then qualify complete guarded CI with the documented t296 checkpoint and exact-SHA hosted result. |

## Decisions

- `2026-05-16`: Add a regression audit rather than a one-off prose edit,
  because the ISF spec is a live downstream reference and its focused-test
  index must not drift as new `t/*-isf-*.t` files are added.
- `2026-08-25`: Reopen the exact synchronization tree rather than weaken t/1250 or absorb its failure into HIAL/VIAL runtime measurement. Commit `8b2a66979` added one matching ISF test without the authoritative mdBook source link; `.3` owns only that drift and the complete-gate retry.
- `2026-08-25`: Preserve the sealed pre-partition source identity. Register the new t/1639 list entry through the existing bounded rewrite mechanism instead of replacing the archived source, weakening exact-content verification, or teaching the checker a one-off exception.

- `2026-10-25`: Current live reference edits follow eb2b8f2a1: ordinary checks allow bounded evolution; exact activation equality is proved in an isolated historical fixture. Current catalog repair .4 preserves annotations and sealed manifests. Director publication ordering supersedes the old blanket hold, not checkpoint/resource or result qualification.

## Open Questions

- None.

## Blockers

- Current T1250 catalog drift is owned by .4. The director's publication-before-macOS-review order is recorded by SEM .69.3; the former blanket startup hold no longer controls this workflow. Complete guarded CI, the repository-local t296 checkpoint and exact-SHA hosted qualification remain required. The uncheckpointed current failing census provides no reconstructable t296 batch credit. Historical native causality and original failures remain separately owned.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-SPEC-TEST-INDEX-SYNC.1` | `prove -Iperl t/1207-isf-assignment-provenance-inventory.t t/1208-isf-compatible-fanin-classification.t t/1248-isf-rule-trigger-parameter-binding.t t/1249-isf-activation-parameter-constants.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |
| `2026-05-21` | `ISF-SPEC-TEST-INDEX-SYNC.2` | `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |
| `2026-08-25` | `ISF-SPEC-TEST-INDEX-SYNC.3` activation | Knowledge Map query; exact t/1250 source/spec comparison; `git show 8b2a66979`; guarded full CI; PID/resource/residue census; `git status --short` | `active`; root cause is one omitted authoritative source link. The broad run independently passes t/1639, reaches final strict-CLI corpus work, then the host guard terminates the tree at 88.1% occupied memory. Descendant ceiling does not trip; exact 4-file/1.8-MiB repository-local residue is removed and both temp roots are absent. |
| `2026-08-25` | `ISF-SPEC-TEST-INDEX-SYNC.3` focused repair | `git log -S'published_wait_16'`; ordered t/1250 plus independent set comparison; t/1120/t/1250/t/1303/t/1414/t/1639; ISF partition, mdBook test/build, render census/cleanup, maintained-reference, containment, ceiling, diff, and doctrine gates | `pass`; one link restores 333/333 with zero missing/extra, focused regression reports `All tests successful`, `Files=5, Tests=37`, all 56 book chapters pass, the exact 91-file render is removed, and +1 line/+85 bytes has fresh authority with zero ceiling increase. Complete guarded CI remains pending. |
| `2026-08-25` | `ISF-SPEC-TEST-INDEX-SYNC.3` complete-gate falsification | guarded `./bin/ci-regression`; t/1569 isolated reproduction; t/296 environment/checkpoint census; PID and artifact census | `active`; t/1250 passes, but t/1569 proves the new maintained line lacks its required archived-source rewrite at part line 1267. The run also exposes a separate t/1558 first-run timeout and reaches t/296 before the host guard terminates at 88.0%. No t/296 checkpoint environment was active; `.artifacts/t296` is empty, the process census is empty, and interrupted completed batches are not durable. |
| `2026-08-25` | `ISF-SPEC-TEST-INDEX-SYNC.3` exact-transformation repair | exact activation-content checker; t/1120/t/1250/t/1303/t/1414/t/1554/t/1569/t/1639; claim-inventory re-derivation and disposition join; live-document doctrine; guarded mdBook test/build; exact render census and cleanup | `pass`; the counted rewrite re-derives the maintained t/1544+t/1639 list tail from the sealed source, t/1569 supplies the RED/green falsification, and the tracked manifest plus regenerated claim inventory provide durability. Focused regression reports `Files=7, Tests=61`; all 56 book chapters pass; the exact 91-file generated book is removed after an empty open-file census. |
| `2026-09-07` | `ISF-SPEC-TEST-INDEX-SYNC.3.1` | Git ancestry, exact source identity, subsequent t/1569 delta attribution; guarded exact activation-content checker and t/1250/t/1569 | `pass`; the initial overly broad t/1569 byte-identity assertion is retained and explained by the later fixture-list addition. The transformation and focused audits pass; corrected staged doctrines pass after preserving and repairing the container-status/delimiter failures. Full CI remains unqualified. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SPEC-TEST-INDEX-SYNC.1` | `ISF-SPEC-TEST-INDEX-SYNC.1: audit spec test index` | `committed` |
| `ISF-SPEC-TEST-INDEX-SYNC.2` | `ISF-SPEC-TEST-INDEX-SYNC.2: sync ATL doc-status audit index` | `committed` |
| `ISF-SPEC-TEST-INDEX-SYNC.3` | `e9e4c63c3` activation; `6b04c795e` focused repair; `f3e7f94dc333fc624fb0d05a0227bd8fdf489460` exact-transformation repair | `repair committed; complete-CI qualification remains blocked` |
| `ISF-SPEC-TEST-INDEX-SYNC.3.1` | `ISF-SPEC-TEST-INDEX-SYNC.3.1: reconcile committed repair frontier` | `continuity reconciliation verified; complete-CI frontier preserved on .3.2` |

## Acceptance Checklist — `.3` (enforced before completion)

- [x] **ROOT CAUSE (WHY + WHERE)** — Pre-fix t/1250 emits the exact Perl diagnostic `at t/1250-isf-spec-focused-test-index-audit.t line 32`: listed index 332 is absent where expected index 332 is t/1639. `git log -S'published_wait_16'` identifies introducing commit `8b2a66979`, which adds t/1639 but not the authoritative link. After the link repair, t/1569 pinpoints the second cause at maintained part line 1267: the sealed activation segment still ends at t/1544 because `doctrine/live_document_size/isf_reference_partitions.jsonl` lacks a registered post-partition t/1639 transformation.
- [x] **ADDRESSED (verified)** — The manifest registers an exact, single-occurrence rewrite from the sealed t/1544 list tail to the maintained t/1544+t/1639 tail. The activation-content checker, t/1250, and t/1569 pass without changes to either audit; t/1569 is the distinct falsification leg and the tracked manifest/inventory are the durability leg.
- [x] **NO REGRESSION** — The adjacent reference set reports `All tests successful`, `Files=7, Tests=61`; claim-inventory/disposition, live-document containment, guarded tests for all 56 mdBook chapters, guarded build, exact render cleanup, and staged doctrine driver are required. Complete guarded CI remains required before tree closure and push.

## Changelog

- `2026-05-16`: Created task tree for ISF spec focused-test index sync.
- `2026-05-16`: Closed tree after listing missing focused ISF tests and
  adding a drift audit.
- `2026-05-21`: Repaired focused-test index drift found by hosted CI after
  `t/1332-isf-atl-doc-status-audit.t` was added.
- `2026-08-25`: Reopened `.3` after the mandatory full-CI gate found the t/1639 authoritative-list omission, then implemented the exact link and fresh maintained-reference authority; retained the audit, ceilings, and normal RAM cutoffs unchanged.
- `2026-08-25`: The post-repair complete gate proved the maintained part had drifted from its sealed activation projection. Reopened the acceptance boxes to register and verify the missing exact transformation before any task-tree pivot.
