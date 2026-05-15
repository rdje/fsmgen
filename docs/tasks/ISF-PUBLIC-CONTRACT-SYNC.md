# ISF-PUBLIC-CONTRACT: Spec, Book, Manifest, And Contract Synchronization

## Metadata

- Tree ID: `ISF-PUBLIC-CONTRACT`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Keep the ISF written specification, mdBook chapters, public interface contract,
capability-manifest advertisement, tests, and live docs synchronized as
features ship, without restarting standalone public-interface audit work as the
primary R14 focus.

## Non-Goals

- Do not select standalone contract-audit expansion ahead of feature delivery
  unless a shipped feature requires it.
- Do not promise the whole schedule JSON schema as frozen; that belongs to
  `ISF-SCHEDULE-REPORTS`.
- Do not duplicate each feature tree's technical implementation details here.

## Acceptance Criteria

- Current ISF documentation/contract owners and required sync points are
  inventoried.
- A reusable feature-slice synchronization checklist exists and is referenced
  by ISF task trees.
- Feature-driven public contract changes update code, docs, manifest metadata,
  and tests in the same slice.
- Live docs record status transitions without duplicating full task trees.
- Any intentional public-contract deferral is listed in the feature backlog or
  owning task tree with consequence and unblock condition.

## Task Tree

- ID: `ISF-PUBLIC-CONTRACT`
  Status: `done`
  Goal: `Keep ISF specs, book, public contract, manifest, and tests synchronized.`
  Children: `ISF-PUBLIC-CONTRACT.1`, `ISF-PUBLIC-CONTRACT.2`,
  `ISF-PUBLIC-CONTRACT.3`, `ISF-PUBLIC-CONTRACT.4`,
  `ISF-PUBLIC-CONTRACT.5`, `ISF-PUBLIC-CONTRACT.6`,
  `ISF-PUBLIC-CONTRACT.7`

- ID: `ISF-PUBLIC-CONTRACT.1`
  Status: `done`
  Goal: `Inventory current ISF public documentation and contract owners.`
  Acceptance: `The task file lists ISF spec sections, mdBook chapters,
  manifest/contract modules, public tests, and live-doc touchpoints.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-PUBLIC-CONTRACT.1: inventory sync owners`

- ID: `ISF-PUBLIC-CONTRACT.2`
  Status: `done`
  Goal: `Define reusable ISF feature-slice synchronization checklist.`
  Acceptance: `The tree records what every ISF feature slice must inspect and
  update across spec, book, contract module, manifest, tests, roadmap, and live
  docs.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-PUBLIC-CONTRACT.2: define sync checklist`

- ID: `ISF-PUBLIC-CONTRACT.3`
  Status: `done`
  Goal: `Apply checklist to active ISF task trees.`
  Acceptance: `Active ISF trees reference or incorporate the synchronization
  checklist in their acceptance criteria without duplicating it excessively.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-PUBLIC-CONTRACT.3: apply sync checklist references`

- ID: `ISF-PUBLIC-CONTRACT.4`
  Status: `done`
  Goal: `Add or adjust tests/docs for feature-driven public contract changes.`
  Acceptance: `When a feature changes public ISF behavior, the matching public
  contract and manifest tests move in the same feature slice.`
  Verification: `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1142-isf-public-guidance-metadata-audit.t`; `prove -Iperl t/1142-isf-public-guidance-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-PUBLIC-CONTRACT.4: align feature contract guidance`

- ID: `ISF-PUBLIC-CONTRACT.5`
  Status: `done`
  Goal: `Record the construct shipping invariant.`
  Acceptance: `The ISF book, spec, and public contract state that every
  current or future construct needs an explicit source shape, lowering path,
  runtime semantic, diagnostics boundary, downstream visibility contract, and
  regression evidence before it is considered shipped.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-PUBLIC-CONTRACT.5: document construct semantics invariant`

- ID: `ISF-PUBLIC-CONTRACT.6`
  Status: `done`
  Goal: `Record IAL0/IAL1 terminology and IAL2 criteria.`
  Acceptance: `The ISF book, spec, public contract, and backlog state that
  .fsm is IAL0, current .isf is IAL1, and any possible IAL2 requires a real
  protocol/platform semantic level rather than aliases, macros, or syntax
  sugar without a distinct runtime model.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-PUBLIC-CONTRACT.6: document intent abstraction layers`

- ID: `ISF-PUBLIC-CONTRACT.7`
  Status: `done`
  Goal: `Clarify the transaction-port authoring boundary in the book.`
  Acceptance: `The mdBook explains that transaction-port connectivity is an
  ergonomic ISF authoring surface that lowers into explicit scheduled .fsm
  handoff wiring, not a request for authors to write generated payload wires
  or generated-top bridge nets directly; companion spec/contract wording is
  kept aligned with the shipped port-binding surface.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-PUBLIC-CONTRACT.7: clarify port binding authoring boundary`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| - | `closed` | `done` | `ISF-PUBLIC-CONTRACT.4` completed the tree. |

## Current Inventory

`ISF-PUBLIC-CONTRACT.1` owns this inventory. Keep it current whenever a future
ISF slice adds or removes public docs, contract owners, manifest fields, or
public audit families.

### Written Documentation Owners

- `README.md`: startup index for active/completed ISF task trees, public ISF
  docs, ISF parser/scheduler modules, support-contract owners, and regression
  gate names.
- `docs/ISF_SPEC.md`: canonical shipped `.isf` source syntax, lowering
  semantics, diagnostics boundaries, public-report semantics, and explicit
  deferrals.
- `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`: single self-contained human
  downstream integration and handoff contract for SPECFORGE-style consumers.
  It must stay truthful with respect to the live spec, mdBook, public
  contract, manifest metadata, tests, and implementation behavior.
- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`: downstream public parser/scheduler
  facade contract and `embedding.isf_public_interface` prose companion.
- `docs/ISF_LIBRARY_CATALOG.md`: shipped reusable ISF library catalog that the
  public contract advertises by path.
- `docs/TASK_TREE.md`: active/proposed/completed ISF task-tree routing and R14
  objective ownership map.
- `docs/tasks/*.md`: feature-local status and acceptance records for ISF
  parser, scheduler, report, contract, and fixture slices.

### mdBook Owners

- `docs/book/src/13-intent-scheduling.md`: ISF overview, public contract
  discovery, schedule-report shell, resource catalog, and IAL framing.
- `docs/book/src/13a-actor-interface.md`: actor interface, clock/reset, params,
  constants, and storage vocabulary.
- `docs/book/src/13b-transactions.md`: transaction clauses, waits, loops,
  activation, stages, and completion timing.
- `docs/book/src/13c-drive-blocks.md`: drive declaration/call semantics.
- `docs/book/src/13d-control-flow.md`: control-flow authoring references that
  overlap transaction wait/loop behavior.
- `docs/book/src/13e-data-manipulation.md`: data-operation width and storage
  report semantics.
- `docs/book/src/13f-composition.md`: generated child composition, reusable
  libraries, and generated-top handoff behavior.
- `docs/book/src/13g-rules.md`: rule syntax, resource catalog, conflict, and
  arbitration semantics.
- `docs/book/src/13h-lowering-reference.md`: reviewable `.fsm` lowering
  patterns and schedule-report examples.
- `docs/book/src/13i-downstream-integration.md`: mdBook view of the canonical
  downstream integration spec, included from
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` rather than maintained as a
  divergent copy.
- `docs/book/src/14-feature-backlog.md`: explicit ISF deferrals and public
  schema-stability boundary.
- `docs/book/src/90-reference-map.md` and `docs/book/src/SUMMARY.md`: public
  navigation to the ISF spec/contract/book chapters.

### Contract And Manifest Code Owners

- `perl/FSM/Support/ISFPublicInterfaceContract.pm`: source of truth for
  parser/scheduler facade metadata, schedule-report key/value families,
  tested-by provenance, live-doc paths, and public stability flags. Its
  `live_document_paths` list must include the downstream integration spec so
  machine consumers can discover the handoff document.
- `perl/FSM/Support/CapabilityManifest.pm`: embeds the ISF public contract at
  `embedding.isf_public_interface` for CLI and in-process manifest consumers.
- `perl/FSM/Support/CapabilityManifestContract.pm`: owns manifest shell
  contract metadata that must keep the ISF embedding discoverable.
- `perl/FSM/Support/ISFResourceCatalog.pm`: shared resource-kind registry used
  by the parser and public contract.
- `perl/FSM/Support/LanguageSurfaceContract.pm` and
  `perl/FSM/Support/LanguageSurfaceSection.pm`: language-surface metadata
  referenced by the book/manifest for expression and guard families.

### Parser, Scheduler, And Emitter Owners

- `perl/FSM/Adapter/ISF.pm`,
  `perl/FSM/Adapter/ISF/LispishAdapter.pm`, and
  `perl/FSM/Adapter/ISF/Parser.pm`: public parser facade and source-shape
  normalizer for `.isf` actors.
- `perl/FSM/Scheduler/ISF.pm`: public lowering/report facade.
- `perl/FSM/Scheduler/ISF/LoweringIR.pm`: lowering semantics, diagnostics, and
  schedule-report source metadata.
- `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`: scheduled `.fsm` review artifact.
- `perl/FSM/Scheduler/ISF/Emitter/JSON.pm`: schedule JSON report artifact.
- `perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm` and
  `perl/FSM/Scheduler/ISF/ModuleEmitter.pm`: generated-top and module output
  surfaces that affect public lowering artifacts.

### Public Test Families

- `t/1112` through `t/1167`: ISF public contract, manifest embedding, facade,
  CLI, live-doc, actor-shell, schedule-report, metadata, and provenance audits.
- `t/1172`, `t/1212`, `t/1213`, `t/1217`, `t/1220`, `t/1225`, `t/1227`,
  `t/1239`, and `t/1243`: feature-owned schedule-report and contract coverage
  that widens public report semantics.
- `t/297`, `t/316`, `t/369`, `t/370`, and the `t/84x`/`t/85x`/`t/99x`/`t/100x`
  capability-manifest audits: manifest shell and embedding regression coverage
  that can catch ISF embedding drift.
- `./bin/ci-regression isf --no-book`: aggregate ISF public/feature regression
  gate for parser, scheduler, report, and HDL handoff behavior.

### Live-Doc Touchpoints

- `ROADMAP_STATUS.md`: active R14 frontier and shipped/remaining ISF behavior.
- `docs/TASK_TREE.md`: PNT-eligible active task tree and completed/proposed
  tree routing.
- `MEMORY.md`: recovery-oriented latest behavior and frontier notes.
- `CHANGES.md`: persistent technical change history.
- `DEVELOPMENT_NOTES.md`: rationale and design constraints.
- `LIVE_ACHIEVEMENT_STATUS.md`: latest completed roadmap-aligned slice.
- `docs/BIN_FSMGEN_IMPORT_TREE.md`: session-bootstrap import-tree snapshot
  when startup analysis detects stale ownership or reachability information.

## Reusable Feature-Slice Synchronization Checklist

`ISF-PUBLIC-CONTRACT.2` owns this checklist. Every ISF feature slice must
inspect it before commit. A slice does not need to edit every owner, but the
owning task file, live-doc update, or commit body must make the selected scope
clear enough that a later recovery pass can see which public surfaces were
intentionally unchanged.

### 1. Classify The Public Surface

- Name the owning task-tree leaf and the shipped behavior, diagnostic, report,
  contract, or documentation-only change.
- Identify whether the slice changes any of these public surfaces: `.isf`
  source syntax, accepted aliases, lowering/runtime timing, generated `.fsm`,
  generated HDL/top handoff, schedule JSON, capability-manifest metadata,
  reusable-library catalog entries, diagnostics, or public docs.
- Record any deliberate deferral in the feature backlog or owning task tree
  with consequence and unblock condition.

### 2. Synchronize Written Docs And Book

- Update `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` for every
  downstream-visible ISF source syntax, diagnostic, lowering, public facade,
  lower-result, schedule-report, generated-artifact, fixture, or deferral
  change. This handoff document is not optional and must stay truthful with
  respect to code, tests, live docs, the book, and manifest metadata.
- Update `docs/ISF_SPEC.md` when source syntax, accepted values, lowering
  semantics, diagnostics, report shape, or explicit deferrals change.
- Update the relevant `docs/book/src/13*.md` chapter when a user-visible ISF
  behavior, generated artifact, or review workflow changes.
- Update `docs/book/src/13i-downstream-integration.md` only to keep its include
  wrapper valid; the actual downstream integration content lives in
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`.
- Update `docs/book/src/13h-lowering-reference.md` when emitted `.fsm` or
  schedule-report examples need to show the new behavior.
- Update `docs/book/src/14-feature-backlog.md` when behavior remains
  intentionally unsupported after the slice.
- Update `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` when parser/scheduler facade,
  manifest embedding, schedule-report metadata, public stability flags, or
  tested-by provenance changes.
- Update `docs/ISF_LIBRARY_CATALOG.md` when reusable library names, source
  paths, ports, bindings, or advertised library semantics change.

### 3. Synchronize Code Contracts

- Keep parser/adaptor changes aligned with `perl/FSM/Adapter/ISF.pm`,
  `perl/FSM/Adapter/ISF/LispishAdapter.pm`, and
  `perl/FSM/Adapter/ISF/Parser.pm` when source grammar or normalization
  changes.
- Keep lowering and artifact semantics aligned across
  `perl/FSM/Scheduler/ISF.pm`, `perl/FSM/Scheduler/ISF/LoweringIR.pm`, and
  the relevant emitter modules when behavior, timing, generated `.fsm`, JSON,
  generated-top, or HDL handoff changes.
- Keep `perl/FSM/Support/ISFPublicInterfaceContract.pm` and
  `perl/FSM/Support/CapabilityManifest.pm` aligned when downstream-visible
  key families, value families, live-doc paths, stability flags, or tested-by
  metadata change.
- Update `ISFResourceCatalog`, `LanguageSurfaceContract`, or
  `LanguageSurfaceSection` only when a slice changes resource-kind or language
  surface registries that the public contract advertises.

### 4. Select Verification Gates

- Run focused parser, scheduler, emitter, report, or diagnostic tests for the
  code path changed by the slice.
- Run public contract and capability-manifest audit tests when the public
  contract module, manifest embedding, key/value families, stability flags, or
  tested-by metadata changes.
- Run schedule-report tests when JSON fields, value families, provenance, or
  nullability semantics change.
- Run `./bin/ci-regression isf --no-book` for non-trivial parser, scheduler,
  lowering, report, or HDL-handoff behavior changes.
- Run `mdbook build docs/book` for any book change and for documentation-only
  ISF synchronization slices.
- Always run `git diff --check` before the commit workflow.

### 5. Update Live Docs

- Update the owning `docs/tasks/*.md` leaf status, verification, commit
  subject, decisions, blockers, and changelog.
- Update `docs/TASK_TREE.md` when the active frontier, proposed tree set, or
  completed tree set changes.
- Update `ROADMAP_STATUS.md`, `MEMORY.md`, `CHANGES.md`,
  `DEVELOPMENT_NOTES.md`, and `LIVE_ACHIEVEMENT_STATUS.md` after every
  completed slice.
- Update `README.md` when the startup document index, active/completed tree
  list, public owner list, or mandatory workflow entry points change.
- Refresh `docs/BIN_FSMGEN_IMPORT_TREE.md` only when startup import-tree
  analysis detects changed reachability or ownership worth recording.

### 6. Commit And Recovery Hygiene

- Commit exactly one completed leaf before selecting another PNT leaf.
- Use a commit subject that names the completed leaf ID.
- Write the commit message through `git_message_brief.txt`, run the commit,
  clear the file to zero bytes, and verify the post-commit status before
  continuing.

## Checklist Application References

`ISF-PUBLIC-CONTRACT.3` applies the checklist by reference:

- `docs/TASK_TREE.md` requires every ISF leaf to inspect this checklist before
  implementation and to record any selected public sync scope in the owning
  task file or recovery docs.
- `docs/book/src/90-reference-map.md` points maintainers to
  `docs/TASK_TREE.md` and this task file as focused workflow references.
- Future active ISF feature trees should reference this checklist from their
  acceptance criteria or decisions when they ship public behavior, diagnostics,
  report, contract, or documentation changes.

## Decisions

- `2026-05-14`: This tree is cross-cutting and feature-driven. It should not
  displace public-facing ISF feature work unless the selected feature changes a
  public surface.
- `2026-05-14`: Parser acceptance is not a support claim for ISF. A construct
  is shipped only when source shape, lowering, runtime semantics, diagnostics,
  downstream visibility, and regression evidence are all explicit.
- `2026-05-14`: FSMGen uses IAL terminology for intent levels: `.fsm` is
  IAL0, current `.isf` is IAL1, and IAL2 remains an exploration topic only for
  real protocol/platform semantics above transactions.
- `2026-05-15`: The reusable synchronization checklist is canonical in this
  task tree. The public contract document should describe downstream-visible
  guarantees, not internal workflow, unless a future public surface needs that
  wording.
- `2026-05-15`: Checklist inspection is required for every ISF feature slice,
  but the selected gates remain scope-sensitive. Documentation-only slices can
  close with book/diff checks; behavior or contract slices must run focused
  tests and the broader ISF gate when warranted.
- `2026-05-15`: Active-tree application is by reference. `docs/TASK_TREE.md`
  carries the mandatory workflow hook, while individual feature trees avoid
  copying the full checklist unless a local acceptance criterion needs a
  narrower checklist item.
- `2026-05-15`: The manifest-advertised public contract guidance now states
  that feature-driven public ISF changes must move matching public contract and
  manifest audit tests in the same implementation slice. The exact guidance
  audit is the enforcement point for that public metadata.
- `2026-05-16`: The self-contained downstream integration spec is now a
  required synchronization target for every downstream-visible ISF behavior or
  contract change. It is included into the mdBook to avoid divergent book and
  handoff-document truth.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-PUBLIC-CONTRACT` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-PUBLIC-CONTRACT.5` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-PUBLIC-CONTRACT.5` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-PUBLIC-CONTRACT.6` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-PUBLIC-CONTRACT.6` | `git diff --check` | `passed` |
| `2026-05-15` | `ISF-PUBLIC-CONTRACT.7` | `mdbook build docs/book` | `passed` |
| `2026-05-15` | `ISF-PUBLIC-CONTRACT.7` | `git diff --check` | `passed` |
| `2026-05-15` | `ISF-PUBLIC-CONTRACT.1` | `mdbook build docs/book` | `passed` |
| `2026-05-15` | `ISF-PUBLIC-CONTRACT.1` | `git diff --check` | `passed` |
| `2026-05-15` | `ISF-PUBLIC-CONTRACT.2` | `mdbook build docs/book` | `passed` |
| `2026-05-15` | `ISF-PUBLIC-CONTRACT.2` | `git diff --check` | `passed` |
| `2026-05-15` | `ISF-PUBLIC-CONTRACT.3` | `mdbook build docs/book` | `passed` |
| `2026-05-15` | `ISF-PUBLIC-CONTRACT.3` | `git diff --check` | `passed` |
| `2026-05-15` | `ISF-PUBLIC-CONTRACT.4` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1142-isf-public-guidance-metadata-audit.t`; `prove -Iperl t/1142-isf-public-guidance-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-PUBLIC-CONTRACT` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |
| `ISF-PUBLIC-CONTRACT.5` | `ISF-PUBLIC-CONTRACT.5: document construct semantics invariant` | Records that every shipped ISF construct must have explicit source, lowering, runtime, diagnostic, visibility, and regression semantics. |
| `ISF-PUBLIC-CONTRACT.6` | `ISF-PUBLIC-CONTRACT.6: document intent abstraction layers` | Records `.fsm` as IAL0, current `.isf` as IAL1, and the criteria/backlog for possible IAL2 exploration. |
| `ISF-PUBLIC-CONTRACT.7` | `ISF-PUBLIC-CONTRACT.7: clarify port binding authoring boundary` | Records that transaction-port connectivity is authored in ISF and lowered to reviewable `.fsm` handoff wiring. |
| `ISF-PUBLIC-CONTRACT.1` | `ISF-PUBLIC-CONTRACT.1: inventory sync owners` | Inventories public ISF docs, contract/manifest owners, test families, and live-doc touchpoints before checklist work. |
| `ISF-PUBLIC-CONTRACT.2` | `ISF-PUBLIC-CONTRACT.2: define sync checklist` | Defines the reusable per-feature synchronization checklist for public ISF docs, contracts, manifests, tests, live docs, and commit hygiene. |
| `ISF-PUBLIC-CONTRACT.3` | `ISF-PUBLIC-CONTRACT.3: apply sync checklist references` | Applies the checklist by reference from the active ISF task-tree workflow and the book reference map. |
| `ISF-PUBLIC-CONTRACT.4` | `ISF-PUBLIC-CONTRACT.4: align feature contract guidance` | Adds manifest-advertised public guidance and exact audit coverage for same-slice public contract/manifest test movement, then closes the tree. |

## Changelog

- `2026-05-14`: Created the active ISF public-contract synchronization task tree.
- `2026-05-14`: Completed `ISF-PUBLIC-CONTRACT.5` as a documentation-only
  invariant; current frontier remains `ISF-PUBLIC-CONTRACT.1`.
- `2026-05-14`: Completed `ISF-PUBLIC-CONTRACT.6` as a documentation-only
  terminology/backlog slice; current frontier remains `ISF-PUBLIC-CONTRACT.1`.
- `2026-05-15`: Completed `ISF-PUBLIC-CONTRACT.7` as a documentation-only
  port-binding authoring-boundary clarification; current frontier remains
  `ISF-PUBLIC-CONTRACT.1`.
- `2026-05-15`: Completed `ISF-PUBLIC-CONTRACT.1` as a documentation-only
  inventory of ISF public docs, contract/manifest owners, public tests, and
  live-doc touchpoints; current frontier advances to `ISF-PUBLIC-CONTRACT.2`.
- `2026-05-15`: Completed `ISF-PUBLIC-CONTRACT.2` as a documentation-only
  reusable feature-slice synchronization checklist; current frontier advances
  to `ISF-PUBLIC-CONTRACT.3`.
- `2026-05-15`: Completed `ISF-PUBLIC-CONTRACT.3` as a documentation-only
  active-tree checklist reference slice; current frontier advances to
  `ISF-PUBLIC-CONTRACT.4`.
- `2026-05-15`: Completed `ISF-PUBLIC-CONTRACT.4` by adding exact public
  guidance that feature-driven public ISF changes move matching contract and
  manifest audit tests in the same implementation slice; tree is closed.
