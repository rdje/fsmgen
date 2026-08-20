# CLAIM-VERIFICATION-ADOPTION: Adopt Three-Leg Claim Verification

## Metadata

- Tree ID: `CLAIM-VERIFICATION-ADOPTION`
- Status: `active`
- Roadmap lane: `infra/evidence governance`
- Created: `2026-08-20`
- Last updated: `2026-08-20`
- Owner: repo-local workflow

## Goal

Adopt a project-owned claim-verification standard so every actionable
quantitative claim names dimensionally distinct re-derivation, falsification,
and durability evidence, and so missing evidence is visible instead of being
hidden behind repeated checks of the same kind.

## Non-Goals

- Do not claim that a structural tag or doctrine gate can prove human intent,
  semantic truth, or the independence of an oracle by itself.
- Do not convert dates, versions, task IDs, schema identifiers, HDL literals,
  example values, or transient command output into permanent claim records
  merely because they contain digits.
- Do not change FSMGen language, lowering, HDL, verification, or support
  behavior while adopting this evidence policy.
- Do not treat the originating PGEN copy as an automatically synchronized
  upstream after FSMGen adopts its own authoritative copy.

## Acceptance Criteria

- FSMGen owns an authoritative repository-root `CLAIM_VERIFICATION.md` with a
  fenced local adoption note and explicit discovery from the tool-neutral
  bootstrap and stable documentation routes.
- Actionable quantitative claims use a bounded record that names the claim,
  re-derivation, a separating falsification oracle or an explicit missing leg,
  and durable producer/watcher evidence or an explicit missing leg.
- A registered doctrine check validates the mechanically decidable record
  shape and its declared tracked paths, runs through the commit hook and CI
  doctrine driver, and has positive plus deliberately failing controls.
- Existing high-traffic current surfaces and repository-derived constants are
  inventoried; each actionable claim is migrated, derived/gated, or assigned a
  task-owned debt disposition without pretending the inventory proves truth.
- Focused validation and `scripts/check_doctrines.sh` pass for every slice;
  full CI remains reserved for the next push or a separately selected major
  boundary.
- The task index and bounded resume pointer remain synchronized, and each
  completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `CLAIM-VERIFICATION-ADOPTION`
  Status: `active`
  Goal: `Adopt and enforce dimensionally independent claim evidence.`
  Children: `CLAIM-VERIFICATION-ADOPTION.1, CLAIM-VERIFICATION-ADOPTION.2, CLAIM-VERIFICATION-ADOPTION.3, CLAIM-VERIFICATION-ADOPTION.4, CLAIM-VERIFICATION-ADOPTION.5, CLAIM-VERIFICATION-ADOPTION.6`

- ID: `CLAIM-VERIFICATION-ADOPTION.1`
  Status: `done`
  Goal: `Select FSMGen's local authority, scope, three-leg record, enforcement boundary, and migration sequence.`
  Acceptance: `Decision 0074 records the project-owned contract, the distinction between actionable claims and incidental numerals, the honest limit of structural enforcement, and the separately owned implementation leaves.`
  Verification: `PASS — scripts/check_task_tree_integrity.pl; scripts/check_docs_relative_paths.sh; git diff --check`
  Commit: `CLAIM-VERIFICATION-ADOPTION.1: select three-leg claim evidence`

- ID: `CLAIM-VERIFICATION-ADOPTION.2`
  Status: `done`
  Goal: `Install the project-owned standard and wire stable discovery surfaces.`
  Acceptance: `The root standard has a fenced FSMGen adoption note; AGENTS, README, doctrine architecture, commit guidance, and the book reference map point to the canonical copy without duplicating its body; containment owns every new live path.`
  Verification: `PASS — neutral-body SHA-256 identity; bootstrap syntax/invariants; README routing; live-document/reference authority; docs-relative-path tests; mdBook build; doctrine gate`
  Commit: `CLAIM-VERIFICATION-ADOPTION.2: install the authoritative claim standard`

- ID: `CLAIM-VERIFICATION-ADOPTION.3`
  Status: `done`
  Goal: `Implement the bounded claim-record checker and register it as a doctrine.`
  Acceptance: `A data-only bounded registry and deterministic checker validate claim IDs, source paths, exact record markers, all three named legs or explicit gaps, tracked producers/watchers, and path locality; positive fixtures pass and mutations that remove or alias a leg demonstrably fail RED.`
  Verification: `PASS — bounded registry/checker; 8 positive, gap, and RED subtests; bootstrap/Knowledge Map/live-document gates; mdBook; doctrine gate`
  Commit: `CLAIM-VERIFICATION-ADOPTION.3: gate bounded three-leg claim records`

- ID: `CLAIM-VERIFICATION-ADOPTION.4`
  Status: `done`
  Goal: `Inventory existing actionable quantitative claims and derived constants on mandatory/current surfaces.`
  Acceptance: `The producer-derived sweep covers 73 current Markdown sources and 615 numeric doctrine constants; it partitions 10,666 numeric lines into 1,417 actionable candidates and four explicit incidental classes, reports producer/watcher state, and assigns every open candidate to CLAIM-VERIFICATION-ADOPTION.5 without representing the inventory as truth proof.`
  Verification: `PASS — independent git-grep census parity; canonical tracked inventory identity; Files=1, Tests=5 for drift, conservative-classifier, untracked-producer, and structural-partition RED controls; bootstrap/live-document gates`
  Commit: `CLAIM-VERIFICATION-ADOPTION.4: inventory current claims and constants`

- ID: `CLAIM-VERIFICATION-ADOPTION.5`
  Status: `active`
  Goal: `Migrate or gate the inventoried claims in bounded, surface-owned slices.`
  Acceptance: `Each claim is re-derived, falsified by a separating oracle where available, and made durable, or it names its missing leg and a task-owned repair; repository-derived constants are derived or input-identity gated rather than hand-carried.`
  Verification: `The current inventory partitions 1,416 candidates exactly into 71 root-document, 268 general-book, 557 protocol/profile/integration, 232 IAL2-AHB, and 288 HIAL/VIAL-verification candidates. Child .5.1 first gates review dispositions; .5.2-.5.6 then consume those five disjoint groups; .5.7 proves zero open migration owners and rechecks the governed doctrine constants.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5: partition claim migration frontier`
  Children: `CLAIM-VERIFICATION-ADOPTION.5.1, CLAIM-VERIFICATION-ADOPTION.5.2, CLAIM-VERIFICATION-ADOPTION.5.3, CLAIM-VERIFICATION-ADOPTION.5.4, CLAIM-VERIFICATION-ADOPTION.5.5, CLAIM-VERIFICATION-ADOPTION.5.6, CLAIM-VERIFICATION-ADOPTION.5.7`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.1`
  Status: `done`
  Goal: `Define and gate the bounded candidate-review disposition contract.`
  Acceptance: `The canonical bounded disposition and five-group registries join stable current candidate IDs to claim-record, derived-gate, reviewed-incidental, or explicitly owned-gap outcomes; outcome-specific evidence, tracked path locality, live gap owners, and group completion are gated while the deliberately empty first registry leaves all 1,417 candidates visibly open.`
  Verification: `PASS — disposition report reproduces 72 + 268 + 557 + 232 + 288 open candidates; Files=1, Tests=9 prove all four outcomes plus stale, duplicate, unknown, missing, aliased, incomplete, fabricated-source, and closed-gap-owner RED controls; 628-constant inventory, bootstrap, Knowledge Map, live-document, mdBook, and doctrine gates`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.1: gate candidate review dispositions`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.2`
  Status: `active`
  Goal: `Review and migrate the 71 current root-document claim candidates.`
  Acceptance: `Every root-document candidate receives an exact gated disposition; current policy constants and historical/rationale measurements are distinguished, published claims gain three-leg evidence or owned gaps, and incidental structure is reclassified only with a reviewable reason.`
  Verification: `After .5.2.1 repaired one stale README-policy sentence and regenerated the inventory, the root group partitions into 32 non-rationale policy/index/navigation candidates, 9 pre-bridge foundational rationale candidates, 18 bridge/execution rationale candidates, and 12 current checking-scale rationale candidates. Children .5.2.1-.5.2.4 own those disjoint sets; the parent closes only after their sum is 71 and root_documents becomes required-complete.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.2: partition root claim review`
  Children: `CLAIM-VERIFICATION-ADOPTION.5.2.1, CLAIM-VERIFICATION-ADOPTION.5.2.2, CLAIM-VERIFICATION-ADOPTION.5.2.3, CLAIM-VERIFICATION-ADOPTION.5.2.4`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.2.1`
  Status: `done`
  Goal: `Disposition the 32 current non-rationale root policy, index, route, and structural candidates.`
  Acceptance: `Every candidate outside DEVELOPMENT_NOTES.md is mapped to a real current policy/input gate, an exact archive or structural projection gate, a reviewed incidental identity/navigation reason, or a live owned repair without conflating declared policy with measured truth.`
  Verification: `PASS — stale README ceiling wording repaired; current inventory 1,416 candidates / 660 governed constants; exact root join 32 disposed / 39 open with 15 derived gates and 17 reviewed non-claims; archive, ledger, task, Knowledge Map, RAM, inventory, and disposition RED suites Files=8/Tests=88; bootstrap, docs paths, Memory, Knowledge Map, README/live-document/reference authority, mdBook test/build, and diff checks pass`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.2.1: disposition non-rationale root claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.2.2`
  Status: `active`
  Goal: `Disposition the 9 foundational rationale candidates before the bridge-scale entries.`
  Acceptance: `The rationale-ledger, book-partition, roadmap-archive, UVM-resource, and provider-profile measurements each name their exact producer, separating oracle, and durable watcher or an explicit live repair task; immutable historical context is not mistaken for current support.`
  Verification: `DEVELOPMENT_NOTES.md lines below 188 identity/count; exact archive/book/provider commands and RED controls; disposition join; doctrine gate`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.2.3`
  Status: `pending`
  Goal: `Disposition the 18 bridge and execution-scale rationale candidates.`
  Acceptance: `The bridge-byte/source-map, scenario-map, total/live-fiber, and execution-type measurements join exact current producers and separating limit/mutation oracles or live repairs without borrowing one scale axis as proof of another.`
  Verification: `DEVELOPMENT_NOTES.md lines 188..269 identity/count; bridge/execution gate reruns and adjacent/mutation RED controls; disposition join; doctrine gate`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.2.4`
  Status: `pending`
  Goal: `Disposition the 12 current checking-scale rationale candidates and close the root group.`
  Acceptance: `The owned-shape, model, scoreboard, coverage, fault, and random-scale measurements join exact current producers and independent reconstruction/mutation oracles or live repairs; all 71 current root candidates are dispositioned and root_documents becomes required-complete.`
  Verification: `DEVELOPMENT_NOTES.md lines 270 onward identity/count; checking-scale and adjacent/mutation RED controls; zero-open root group; docs/live-document/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.3`
  Status: `pending`
  Goal: `Review and migrate the 268 general language, control, tooling, and reference-book candidates.`
  Acceptance: `Every shipped-behavior candidate outside the named protocol, IAL2-AHB, and HIAL/VIAL-verification clusters receives an exact gated disposition without weakening examples or turning syntax literals and navigation identifiers into claims.`
  Verification: `general-book group identity/count, lowering-clean examples where touched, per-disposition RED controls, zero open group candidates, mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4`
  Status: `pending`
  Goal: `Review and migrate the 557 protocol-profile and integration-book candidates.`
  Acceptance: `Every candidate in 14f, 14g, 14h, 14i, 14j, 14l, 16a, 16aa, and 16b is dispositioned against executable protocol/profile/integration producers and separating oracles, or carries an exact owned gap; repeated measurements share evidence only when they are demonstrably the same claim.`
  Verification: `protocol-group identity/count, focused profile/integration gates and deliberate mutations, zero open group candidates, mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.5`
  Status: `pending`
  Goal: `Review and migrate the 232 IAL2-AHB execution-scale book candidates.`
  Acceptance: `Every 16c candidate is tied to its exact scale/gate producer and a separating excess or mutation oracle, reclassified as reviewed incidental, or assigned an explicit repair; historical observations are not promoted into current support claims.`
  Verification: `16c group identity/count, scale producer reruns and adjacent-excess RED controls, zero open group candidates, mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.6`
  Status: `pending`
  Goal: `Review and migrate the 288 HIAL/VIAL verification-architecture book candidates.`
  Acceptance: `Every 16d candidate is tied to exact architecture-scale, backend, runtime, result, or capability evidence with a separating oracle, reclassified with a reviewable incidental reason, or assigned an explicit repair without overstating provider or support coverage.`
  Verification: `16d group identity/count, exact architecture/runtime producer and RED controls, zero open group candidates, mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.7`
  Status: `pending`
  Goal: `Reconcile all migrated claims and governed constants into a zero-open-owner inventory.`
  Acceptance: `The regenerated inventory has no candidate still owned by CLAIM-VERIFICATION-ADOPTION.5, every claim/disposition identity is current and three-leg honest, all 615 originally inventoried numeric doctrine constants are still derived/watched or input-identity gated, and no migration artifact is off-volume or untracked.`
  Verification: `complete disposition/inventory join, zero-open-owner assertion, constant census parity and watcher/input RED controls, mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.6`
  Status: `pending`
  Goal: `Close adoption with a complete current-surface audit and recoverable handoff.`
  Acceptance: `The authoritative policy, discovery, registry, checker, migrated claims, explicit debt, task evidence, book, and resume pointer agree; no adoption artifact is off-volume, untracked, or reachable only from conversation.`
  Verification: `focused adoption suite, full doctrine gate, clean tracked/untracked census, and task integrity`
  Commit: `pending`

## Decisions

- `2026-08-20`: Decision `0074` selects re-derive, falsify, and durability as
  three distinct publication legs. Structural enforcement checks declared
  records and evidence plumbing; it never represents formatting as proof of a
  claim's semantic truth.
- `2026-08-20`: The external PGEN document is an adoption source, not a live
  dependency. FSMGen's repository-root copy becomes authoritative once leaf
  `.2` lands.
- `2026-08-20`: Adoption precedes the recorded HIAL backend-emission frontier
  because the director explicitly requested this missing policy and the
  repository was clean, making the pivot handoff-safe.
- `2026-08-20`: The inventory classifier has no incidental fallback. Numeric
  prose not proven to be structure, code/data, a watched generated projection,
  or an identifier remains actionable review debt owned by leaf `.5`.
- `2026-08-20`: The committed inventory places 1,345 of 1,417 candidates in
  the mdBook. Migration therefore uses one root-doc slice, one general-book
  slice, and three evidence-coherent book clusters rather than one oversized
  documentation rewrite; a separate first child installs disposition honesty.
- `2026-08-20`: A migration group remains `required_complete=false` until its
  owning slice has dispositioned every current candidate. The empty `.5.1`
  outcome registry therefore proves mechanism and reports debt; it does not
  misrepresent any of the 1,417 candidates as reviewed.
- `2026-08-20`: Root review is split by evidence family, not file count. The
  39 rationale-ledger candidates require three chronological semantic slices,
  while the other eight root files plus the rationale index form one bounded
  policy/structure slice.
- `2026-08-20`: Leaf `.5.2.1` found that `README_POLICY.md` still described
  its inclusive ceilings as pinned to the 246-line / 9,952-byte adoption
  survivor even though the governed values had correctly ratcheted to the
  smaller current README. The repaired policy distinguishes historical
  baseline, health target, and derived current ceiling; regeneration removes
  one stale candidate, so the current frontier is 1,416 total / 71 root / 32
  non-rationale root candidates. Earlier `.4` and `.5.1` verification rows
  retain their then-current 1,417-candidate results as historical evidence.

## Open Questions

- None blocking. The `.5.2.2` foundational rationale review is the sole
  active child after clean `.5.2.1` commit `1f0443b3a`.

## Blockers

- None.

## Acceptance Checklist (enforced for implementation changes)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'dispositions.jsonl' --oneline 979d5d416 -- doctrine scripts t docs/book/src KNOWLEDGE_MAP.md` returned no match: the complete inventory had no bounded join from a current candidate identity to a reviewed outcome and no enforced way for a completed migration group to reject residual open candidates.
- [x] **ADDRESSED (verified)** — `scripts/check_claim_verification_dispositions.pl --report` reported `candidates=1417`, `disposed=0`, `open=1417`, and exact group totals `268/232/557/72/288`; `prove -Iperl -v t/1638-claim-verification-dispositions.t` exercised all four outcome shapes and nine positive/RED subtests for stale, duplicate, unknown, missing, aliased, incomplete, fabricated-source, and closed-gap-owner cases.
- [x] **NO REGRESSION** — the focused disposition suite reported `All tests successful` and `Files=1, Tests=9`; claim inventory re-derived `628` governed constants without changing the `1,417` candidate frontier, Knowledge Map reported `1127` facts with query parity, live-document containment covered `3022/3022` paths, and the RAM-guarded mdBook plus all 12 registered doctrines pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'remain pinned to the adoption baseline' --oneline -- README_POLICY.md doctrine/live_document_size/surfaces.jsonl` identifies `9bd081935`, while pickaxes for the later 245-line / 9,931-byte registry values identify `3084d8c7b`: the policy sentence predated the downward ratchet and was never joined to the current control input; the unreviewed root candidates likewise had no disposition join.
- [x] **ADDRESSED (verified)** — the policy and Knowledge Map now distinguish historical adoption baseline, reviewed health target, and registry-derived current ceiling; regenerated inventory reports `candidates=1416`; the canonical disposition report joins all `32` current non-rationale root candidates as `15` derived gates plus `17` reviewed non-claims and leaves only the `39` separately owned rationale candidates open.
- [x] **NO REGRESSION** — the deliberately failing archive, ledger, task-tree, Knowledge Map width, RAM-trip, inventory, and disposition controls report `All tests successful` at `Files=8, Tests=88`; bootstrap, docs-relative paths, Memory, Knowledge Map parity, README/live-document/reference authority, mdBook test/build, and `git diff --check` pass; the ignored 19-MiB generated book directory was removed after verification.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-08-20` | `.1` | `scripts/check_task_tree_integrity.pl`; `scripts/check_docs_relative_paths.sh`; `git diff --check` | `PASS — 4 active trees / 954 nodes; 1 docs-relative-path file / 2 tests; clean diff whitespace` |
| `2026-08-20` | `.2` | neutral-body digest; bootstrap; README/live-document/reference authority; docs paths; RAM-guarded mdBook; doctrine gate | `PASS — authoritative body identity reproduced; discovery and bounded routes closed; book built` |
| `2026-08-20` | `.3` | claim checker; `t/1636`; bootstrap; Knowledge Map; live-document/reference authority; RAM-guarded mdBook; doctrine gate | `PASS — one bounded conformance record; Files=1, Tests=8; deliberate missing/alias/path RED controls; all registered doctrines` |
| `2026-08-20` | `.4` | claim inventory/report; `t/1637`; bootstrap; claim checker; live-document/reference authority; RAM-guarded mdBook; doctrine gate | `PASS — independent parity across 10,666 numeric lines; 1,417 owned candidates and 615 governed constants; Files=1, Tests=5; bounded canonical inventory` |
| `2026-08-20` | `.5` partition | committed-inventory path/classification aggregation; exact five-group sum; task integrity; docs paths; doctrine gate | `PASS — 72 + 268 + 557 + 232 + 288 = 1,417 with disjoint path ownership; .5.1 selected alone` |
| `2026-08-20` | `.5.1` | disposition checker/report; `t/1638`; inventory/constant census; bootstrap; Knowledge Map; live-document/reference authority; RAM-guarded mdBook; doctrine gate | `PASS — five exact groups, four bounded outcomes, all 1,417 debt records visibly open; Files=1, Tests=9; 628 governed constants; all registered doctrines` |
| `2026-08-20` | `.5.2` partition | committed inventory path/line aggregation; exact four-group sum; task integrity; docs paths; doctrine gate | `PASS — 33 + 9 + 18 + 12 = 72 with disjoint path/range ownership; .5.2.1 selected alone` |
| `2026-08-20` | `.5.2.1` | stale-policy root cause; inventory/disposition joins; `t/1549`, `t/1554`, `t/1565`, `t/1566`, `t/1567`, `t/1595`, `t/1637`, `t/1638`; bootstrap; docs paths; Memory; Knowledge Map; README/live-document/reference authority; RAM-guarded mdBook; diff check | `PASS — current frontier 1,416; root 32 disposed / 39 open; 15 gates / 17 reviewed; 660 governed constants; Files=8/Tests=88; 53 book chapters tested and built` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `CLAIM-VERIFICATION-ADOPTION.1: select three-leg claim evidence` | `Decision and executable adoption sequence only; no policy or product behavior change.` |
| `.2` | `CLAIM-VERIFICATION-ADOPTION.2: install the authoritative claim standard` | `Project-owned standard plus bounded discovery and book reference; no product behavior change.` |
| `.3` | `CLAIM-VERIFICATION-ADOPTION.3: gate bounded three-leg claim records` | `Bounded registry, exact record checker, positive/RED fixtures, doctrine registration, and durable retrieval card.` |
| `.4` | `CLAIM-VERIFICATION-ADOPTION.4: inventory current claims and constants` | `Producer-derived current-surface census, conservative partitions, governed constants, exact migration ownership, and independent RED controls.` |
| `.5` | `CLAIM-VERIFICATION-ADOPTION.5: partition claim migration frontier` | `Activates seven bounded children from the committed five-group candidate census; changes no claim, checker, product, or support behavior.` |
| `.5.1` | `CLAIM-VERIFICATION-ADOPTION.5.1: gate candidate review dispositions` | `Bounded outcome/group registries, exact inventory join, live owner and path checks, completion enforcement, RED controls, and durable retrieval route.` |
| `.5.2` | `CLAIM-VERIFICATION-ADOPTION.5.2: partition root claim review` | `Activates four evidence-coherent children from the exact root candidate census; changes no claim, disposition, policy, product, or support behavior.` |
| `.5.2.1` | `CLAIM-VERIFICATION-ADOPTION.5.2.1: disposition non-rationale root claims` | `Repairs stale README ceiling semantics and maps every current non-rationale root candidate to a live derived gate or an exact reviewed non-claim outcome.` |
