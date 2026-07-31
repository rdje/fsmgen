# External Review Disposition — Live-Document Size Containment

- Date: `2026-07-31`
- Owner: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`
- Status: accepted with bounded remediation
- Architecture decision: [0044](decisions/0044-external-live-document-review-corrections-precede-wider-reuse.md)
- Detailed review input: [external review packet](LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_PACKET.md)

This is the bounded current response to the independent PGEN and ANVIL
reviews. It records what FSMGen accepts, refines, rejects, or already proves.
The original packet remains detailed evidence; a later atomic leaf owns any
change to its lifecycle. Nothing in this disposition changes a checker,
registry value, threshold, document lifecycle, frozen identity, or product
behavior.

## Review Input Identity

The user supplied both reviews on `2026-07-31`. Their contents are represented
durably here rather than by machine-local source paths.

| Review | Lines | Bytes | SHA-256 |
| --- | ---: | ---: | --- |
| PGEN | 393 | 26,788 | `5057b147fbe173b3442edbe677f92eba5bb00d273a38130a962c369dedb70d26` |
| ANVIL | 334 | 44,242 | `9dac9f1f442ea4baa9afe1f1a56bd8bda3bb54bf2de0156c563ad0df85f61be2` |

Both verdicts are **accept with changes**. PGEN makes health-target semantics
and currency the publication blockers. ANVIL makes migration accounting and
verifier execution the adoption blockers. FSMGen accepts the underlying risks
and decomposes them below instead of choosing one reviewer's priority order.

## Corrected Headline Evidence

Measurements in this section use clean activation commit `3d83996d6`, before
the disposition itself added documentation bytes.

### Coverage is classification, not health

The common checker currently classifies all `2,780 / 2,780` tracked Markdown
paths into 20 surfaces. That proves no tracked Markdown path escapes the
declared graph. It does **not** prove that every surface is well sized, current,
useful, completely indexed, or verifier-executed.

Among the packet's named non-generated document candidates, the two frozen
status files plus the two deferred ledgers currently hold `7,775,451` of
`8,955,512` bytes (`86.8%`). This is pinned/deferred pressure, not completed
containment. Current peak pressure further distinguishes the states:

| Surface or group | Current evidence | Meaning |
| --- | --- | --- |
| `active_index` | 46.5% peak | migrated and normal |
| `task_evidence` | 74.0% peak | migrated and normal |
| `engineering_rationale` | 90.8% peak | deferred rollover debt |
| `change_history` | 91.9% peak | deferred rollover debt |
| `shipped_behavior` | 93.5% peak | retained user reference under rollover debt |
| `knowledge_cards` | 96.1% peak | retained canonical facts under rollover debt |
| two frozen status files | exact SHA identities | pinned, not sized or retired |

Future summaries must report path coverage and pressure/migration state as
different measurements.

### IAL2 retention products overlap; they are not a line partition

ANVIL correctly found that `85 + 5,914 != 21,726`. The packet presented those
numbers in a way that invited disjoint line arithmetic. That presentation was
wrong. The migration created three different retention products:

| Product | Lines | Bytes | Identity or purpose |
| --- | ---: | ---: | --- |
| exact former source object | 21,726 | 4,662,385 | SHA-256 `8cff8e7beab71c8ac6dd54b4910fc4835dd153c6b9ca93e15f71be5d4ee755f2` at revision `44b5f159789ba1c31b487c6b047097bb27a9770d` |
| current live front door | 85 | 36,886 | newly authored active root, frontier, and retrieval pointer |
| content-addressed node segment | 5,914 | 2,366,453 | all 844 authoritative terminal task nodes; digest is the filename |
| bounded segment manifest | 2 | 35,252 | one metadata record plus one segment record |

The complete former file remains byte-for-byte retrievable, so the review has
not demonstrated information loss. The segment independently proves that all
844 authoritative nodes remain in the checked task graph. The live file is a
new view and overlaps those facts; it is not a slice of the old line range.

The current working-tree representation is `2,438,591` bytes, a reduction of
`2,223,794` bytes (`47.7%`) from the former live file, while the exact former
object remains in Git. Similarly, the task index is now `40,180` live bytes
plus a 523-byte manifest instead of 167,249 live bytes, a `75.7%` working-set
reduction with exact version-object retrieval.

The remaining defect is durability and evidence shape: the packet omitted the
full-source identity from its migration table, and FSMGen has not declared the
Git-retention assumptions that make a version object a retention guarantee.
Leaf `.22` owns both corrections. A token sweep is mandatory when bytes are
actually discarded as duplicate; it is not a substitute for reporting an
exact complete source object that is still retained.

## Finding Dispositions

### PGEN findings

#### PGEN F1 — one field carries health target and quarantine ceiling

- **Disposition:** accept.
- **Local proof:** current debt rows use `budgets` as stop-growth ceilings while
  healthy rows use the same field as steady-state limits; the checker requires
  baseline plus growth to fit below that field.
- **Selected correction:** explicit `health_target` and inclusive
  `enforcement_ceiling`, no inert `hard_pct`, visible actual/target/ceiling
  output, a two-sided ceiling ratchet, and separate authority for increases.
- **Owner:** `.18`.

#### PGEN F2 — size and routing do not prove truth or currency

- **Disposition:** refine.
- **Accepted core:** bounded and current are independent; the doctrine must not
  imply semantic truth from size compliance.
- **Rejected mechanism:** no portable global distinct-date or newest-date rule.
  ANVIL measured legitimate roadmap closure dates and correctly frozen task
  dates that such a rule would misclassify.
- **Selected correction:** explicit lifecycle-scoped currency contracts and
  calibrated local verifiers only when a surface declares currency.
- **Owner:** `.20`.

#### PGEN F3 — undeclared author-routing hints can bypass the route graph

- **Disposition:** accept with typing.
- **Local proof:** `scripts/check_readme_entrypoint.sh` contains author-facing
  destination strings that are not themselves declared graph edges. Their
  destinations happen to be governed today, but no control proves that.
- **Selected correction:** inventory path-shaped routing candidates and classify
  `author_overflow` separately from `reader_navigation`; legitimate differences
  must be explicit rather than blindly unified.
- **Owner:** `.21`.

#### PGEN F4 — schema domains should prevent prose pressure

- **Disposition:** accept with defense in depth.
- **Selected correction:** bound record count, record bytes, scalar bytes, and
  array cardinality; use enums and validated identifiers wherever possible.
  Total registry bytes remain useful because owner/reason fields can require
  bounded free text.
- **Owner:** `.15`.

#### PGEN F5 — content-addressed files outlive unqualified version locators

- **Disposition:** refine.
- **Selected correction:** prefer in-repository content-addressed files for
  unrecoverable evidence. Permit `version_object` only with an explicit
  retention contract, full retrieval proof, and actionable shallow/rewrite
  failure. A version object is otherwise a locator, not a guarantee.
- **Owner:** `.22`.

#### PGEN F6 — verifier reachability must be mechanical

- **Disposition:** accept.
- **Local proof:** FSMGen's Knowledge Map verifier is currently run by the
  doctrine driver, but the common schema proves only executable presence and
  does not link that declaration to the driver row.
- **Selected correction:** execution mode plus proof, single-driver reachability,
  no re-enumerated CI list, and deletion/vacuity negative fixtures.
- **Owner:** `.19`.

#### PGEN F7 — a second formal JSON Schema would drift

- **Disposition:** accept; no formal schema will be added.
- **Current proof:** the strict executable parser and fail-closed fixture corpus
  already reject malformed, blank, missing, and unknown data.
- **Owner:** `.15` only for portable fixture/documentation improvements.

#### PGEN F8 — packet evidence paths are unchecked promises

- **Disposition:** accept.
- **Current proof:** all 17 paths resolve today; no mechanical packet-path check
  preserves that property.
- **Owner:** `.21`.

### ANVIL findings

#### ANVIL F1 — migration line arithmetic does not close

- **Disposition:** accept the evidence defect; refine the loss conclusion.
- **Root cause:** the table mixed a complete Git object, an overlapping node
  extraction, and a newly authored live view as if they were disjoint ranges.
- **Correction:** publish full-source identity, task-node completeness, live
  working-set reduction, retention assumptions, and any true dropped-content
  residue as separate dimensions.
- **Owner:** `.22`.

#### ANVIL F2 — 100% path coverage is not containment

- **Disposition:** accept.
- **Current measurement:** pinned/deferred families remain `86.8%` of the named
  non-generated candidate bytes; migrated task/index surfaces are normal.
- **Owner:** `.18` for output/accounting and `.16` for utility decisions.

#### ANVIL F3 — `hard_pct` is inert

- **Disposition:** accept. The absolute enforcement ceiling is inclusive;
  equality passes and overflow fails. `hard_pct` will be removed.
- **Owner:** `.18`.

#### ANVIL F4 — baseline is pinned against an editable ceiling

- **Disposition:** accept.
- **Selected correction:** increases require a distinct reviewed authority
  record; lowering is free; debt ceilings ratchet down as pressure falls.
- **Owner:** `.18`.

#### ANVIL F5 — presence is not execution

- **Disposition:** accept and rank as a blocker before wider reuse.
- **Owner:** `.19`.

#### ANVIL F6 — maximum line or record bytes are missing

- **Disposition:** accept.
- **Current measurement:** longest common surface record is 945 bytes; the IAL2
  manifest's longest record is 34,976 bytes. Both must be explicit, not inferred
  from whole-file lines/bytes.
- **Owner:** `.15`.

#### ANVIL F7 — utility needs `re-form`

- **Disposition:** accept. `re-form` means the role/capability survives while
  its representation is replaced, with semantic-coverage proof.
- **Owner:** `.16`.

#### ANVIL F8 — neutrality is asserted but untested

- **Disposition:** already satisfied for the neutral checker package.
- **Local proof:** `t/1554-live-document-size-doctrine.t` scans the neutral
  checker and contract for project, harness, bootstrap, and machine-local
  identities. The local adoption fence is intentionally exempt.

#### ANVIL F9 — the packet is itself an oversized live view

- **Disposition:** accept.
- **Selected correction:** this bounded response is the current disposition;
  `.22` will create a concise architecture front door and retain or seal the
  detailed packet only as evidence under an explicit lifecycle.
- **Owner:** `.22`.

## Question Disposition Matrix

- **Q1:** accept the invariant, amended to distinguish bounded, current, and
  useful; no size check claims semantic truth. Owners `.16`/`.20`.
- **Q2:** refine the seven classes with a separately selected maintained-product
  reference class rather than forcing unique prose into history-shaped rules.
  Owner `.23`.
- **Q3:** accept information role as the topology selector.
- **Q4:** route closure is necessary but insufficient; close undeclared author
  hints and unmeasured within-file axes. Owners `.15`/`.21`.
- **Q5:** retain JSONL. Named fields and typed nesting dominate TSV positional
  compactness for this control plane.
- **Q6:** require finite registry metadata and bounded value domains, not only a
  total byte cap. Owner `.15`.
- **Q7:** retain strict unknown-key rejection.
- **Q8:** retain one-root-list records only under an explicit maximum record-byte
  contract; do not add reconstruction complexity merely to create more lines.
- **Q9:** do not add a hand-maintained formal JSON Schema; publish executable
  parser semantics and negative fixtures.
- **Q10:** inclusive absolute ceiling: `actual <= ceiling` passes.
- **Q11:** remove `hard_pct`.
- **Q12:** add deterministic maximum line/record bytes. Do not add tokenizer-
  dependent token counts or environment-dependent render/parse measurements to
  the portable hard gate.
- **Q13:** current debt algebra is insufficient; separate target/ceiling,
  ratchet both directions, and authorize increases separately. Owner `.18`.
- **Q14:** derive rollover reserve from the reviewed survivor's binding axes and
  largest atomic update; do not standardize a universal ratio.
- **Q15:** version-object retrieval is conditional on declared retention and
  actionable failure; prefer a content-addressed file when loss is unrecoverable.
- **Q16:** current sealing proves the 844-node subtree, not the completeness or
  retention of every other former document section. Owner `.22`.
- **Q17:** keep completed task files directly browsable unless their only
  remaining consumer is an auditor.
- **Q18:** require full-source identity, semantic-graph closure, working-set
  dimensions, and a published token/consumer residue only for content actually
  discarded as duplicate.
- **Q19:** reject global date-count/newest-date gates; use lifecycle-scoped,
  opt-in currency contracts with local negative calibration. Owner `.20`.
- **Q20:** oversized ceilings, presence-only verifiers, incomplete collection
  indexes, and undeclared author routes can currently pass. Owners `.18`-`.21`.
- **Q21:** keep checks unconditional, run them on the staged/resulting tree, and
  invoke the single doctrine driver rather than copying its check list.
- **Q22:** close the neutral-core/adapter execution gap and require an auditable
  local classification rationale. Owners `.19`/`.23`.
- **Q23:** document a lightweight adoption rung: invariant, line+byte controls on
  mandatory reads, unconditional commit/CI execution, and governed destinations.
- **Q24:** the full architecture is proportional for a mature repository with
  recurrent regrowth; young repositories should start with the lightweight rung.
- **Q25:** accept with the named corrections in `.15`-`.23`.
- **Q26:** block wider reuse on truthful target/ceiling semantics, executed
  verifiers, and complete migration/retention evidence (`.18`, `.19`, `.22`).
- **Q27:** require a utility outcome before migration and add `re-form`.
- **Q28:** deletion requires an immediate whole-document unique-content probe,
  classified consumer census including source/check scripts, named replacement
  pointers, and a negative control proving the probe detects a planted orphan.
- **Q29:** `.24` supersedes the proved user-guide and book-plan waypoints after
  exact content, consumer, replacement, negative-control, and Git-retention
  checks; `.16` still audits both status files under their existing authority.
- **Q30:** retain human history only for non-derivable narrative, rejected
  alternatives, and rationale. Derivable “what changed” is a projection.
- **Q31:** trigger utility review on role/canonical-input/replacement/consumer
  changes. Size triggers containment, not an automatic preservation decision;
  periodic control-plane audits remain useful.

## Remediation Leaves

| Leaf | Atomic responsibility | Reviewer concerns |
| --- | --- | --- |
| `.15` | finite/reviewable JSONL control plane, bounded values and record/line bytes, portable negative fixtures | PGEN F4/F7; ANVIL F6 |
| `.16` | utility outcomes including `re-form`, family audit, deletion/retirement proof and role-change triggers | PGEN Q27-Q31; ANVIL F7/Q27-Q31 |
| `.18` | health targets, inclusive enforcement ceilings, downward ratchet, separate increase authority, pressure reporting | PGEN F1; ANVIL F2-F4 |
| `.19` | verifier execution mode, driver reachability, visible degradation, vacuity fixtures | PGEN F6; ANVIL F5 |
| `.20` | lifecycle-scoped currency contracts without global date heuristics | PGEN F2; ANVIL Q19 |
| `.21` | typed author/reader routes, index completeness, evidence-map integrity | PGEN F3/F8; ANVIL Q20 |
| `.22` | migration evidence, retention guarantees, actionable retrieval failure, bounded review front door | PGEN F5; ANVIL F1/F9 |
| `.23` | maintained-product-reference lifecycle and classification rationale | ANVIL Q2/Q22 |

Family migrations `.8`-`.10` and `.13` wait for utility and, where applicable,
maintained-reference selection. The four frozen/change/rationale documents keep
their existing separate lifecycle authority. No review comment authorizes a
deletion or a threshold increase by itself.

## Evidence map

The bounded disposition depends on these repository-relative authorities:

<!-- LIVE-DOCUMENT-DISPOSITION-EVIDENCE-MAP:BEGIN -->
| Concern | Evidence |
| --- | --- |
| Accepted correction authority | `docs/decisions/0044-external-live-document-review-corrections-precede-wider-reuse.md` |
| Detailed review input | `docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_PACKET.md` |
| Common checker implementation | `live-document-size/scripts/check_live_document_size.pl` |
| Local surface graph | `doctrine/live_document_size/surfaces.jsonl` |
| Owning remediation tree | `docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md` |
<!-- LIVE-DOCUMENT-DISPOSITION-EVIDENCE-MAP:END -->

## Reverification

The evidence used for this disposition is reproducible with:

```text
scripts/check_live_document_size.sh
scripts/check_task_tree_integrity.pl
scripts/check_doctrines.sh --list
prove -Iperl t/1549-task-tree-integrity-doctrine.t \
  t/1553-readme-routed-destination-pressure.t \
  t/1554-live-document-size-doctrine.t
git show 44b5f159789ba1c31b487c6b047097bb27a9770d:docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
```
