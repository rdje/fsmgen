# ISF-FIELD-STRUCTURED-STORAGE-FRONTIER: ISF Declarative Field-Structured Storage

## Metadata

- Tree ID: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER`
- Status: `active`
- Roadmap lane: `R14 / ISF storage metadata`
- Created: `2026-06-22`
- Last updated: `2026-06-22`
- Owner: repo-local workflow

## Goal

Select and implement a checked ISF surface for declarative named bit-fields
on storage/register-like scalar words and, if selected later, packet or
structure layouts.

## Non-Goals

- Do not change parser, scheduler, lowerer, generated `.fsm`, HDL,
  schedule JSON, semantic JSON, support accounting, tests, docs, or public
  contracts before an exact leaf owns that slice.
- Do not use runtime operations (`set-field`, `when-field`, `extract`,
  `assemble`) as a substitute for static field-map declarations.
- Do not infer undocumented reserved fields, access semantics, reset behavior,
  enum/type relationships, packet layouts, generated verification output, or
  HDL register models without an exact owner and regression-backed contract.
- Do not edit the SPECFORGE repository.

## Acceptance Criteria

- The first leaf audits the current ISF storage, aggregate, field-operation,
  reset, report, semantic JSON, support-accounting, mdBook, and downstream
  contract surfaces and selects the first implementation boundary.
- The selected first behavior slice, if any, records exact syntax,
  validation rules, normalized report/semantic projection, residue, tests,
  docs, and rollback before code changes.
- Any implementation leaf is checked metadata or generated behavior only as
  explicitly selected by the prior leaf.
- mdBook, downstream handoff docs, README, task-tree state, Memory, and
  Knowledge Map stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER`
  Status: `active`
  Goal: `Make ISF capable of carrying checked declarative named bit-field maps for storage/register-like words.`
  Children: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1, ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.2, ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.3`

- ID: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1`
  Status: `done`
  Goal: `Audit readiness and select the first declarative field-structured storage contract.`
  Acceptance: `Read SPECFORGE's 2026-06-22 field-structured storage request; current ISF storage parser/scheduler/lowerer/report/semantic surfaces; actor-owned scalar and aggregate storage docs/tests; register reset values; runtime field operations set-field/when-field/extract/assemble; support-accounting fixtures; mdBook and downstream integration docs. Decide whether the first slice should be metadata-only scalar storage fields, reset-composition validation, enum/access metadata, aggregate/packet layout generalization, or a prerequisite cleanup. Record exact syntax, fail-closed validation, report and semantic JSON shape, docs/tests, explicit residue, and rollback before any behavior change.`
  Verification: `passed: audited SPECFORGE request; README/MEMORY/TASK_TREE/task owner; docs/decisions/0001, 0002, 0006, 0007, 0018; Knowledge Map field-storage fact; docs/ISF_SPEC.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md; docs/book/src/13a-actor-interface.md, 13-intent-scheduling.md, 13j-type-enum-aggregate.md, 13k-isf-feature-support-matrix.md, 14-feature-backlog.md; parser storage path in perl/FSM/Adapter/ISF/Parser.pm; scheduler storage/report paths in perl/FSM/Scheduler/ISF/LoweringIR.pm and Emitter/JSON.pm; public contract metadata in perl/FSM/Support/ISFPublicInterfaceContract.pm; focused storage/reset/report tests t/1232, t/1397, t/1398, t/1148, t/1226, t/1255; selected docs/ISF_FIELD_STRUCTURED_STORAGE_CONTRACT_SELECTION.md`
  Commit: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1: select storage field contract`

- ID: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.2`
  Status: `done`
  Goal: `Implement metadata-only declarative fields on scalar actor-owned storage variables.`
  Acceptance: `Parser accepts '(fields (field NAME (bits HI LO) ...))' only on scalar '(var ...)'/'(variable ...)' storage entries; validates identifier names, duplicate field names, literal bit ranges inside resolved parent width, no overlaps, optional access vocabulary, optional field reset cross-checked against parent '(reset V)', inline enum names/values fitting field width, and fail-closed malformed shapes; scheduler IR preserves field metadata; schedule JSON exposes optional inferred_storage[].fields; existing '.fsm'/HDL behavior remains byte-equivalent for sources without fields; public contract metadata, docs/ISF_SPEC.md, downstream spec, mdBook, Knowledge Map, and task state are synchronized; focused positive/fail-closed tests pass.`
  Verification: `passed: t/1453-isf-storage-field-metadata.t; t/1148-isf-public-storage-metadata-audit.t; t/1144-isf-public-tested-by-metadata-audit.t; t/1112-isf-public-interface-contract.t; t/1113-isf-public-interface-contract-json-roundtrip-audit.t; t/1255-isf-schedule-report-golden-matrix.t; t/1250-isf-spec-focused-test-index-audit.t; t/1305-isf-book-feature-matrix-audit.t; t/1376-isf-book-example-lowering-audit.t; mdbook build docs/book; bash knowledge-map/scripts/gen_knowledge_map.sh; bash knowledge-map/scripts/check_knowledge_map.sh; git --no-pager diff --check; scripts/check_memory_architecture.sh; scripts/check_doctrines.sh`
  Commit: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.2: ship scalar storage fields`

- ID: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.3`
  Status: `pending`
  Goal: `Select the next field-structured storage residual or close the frontier after the scalar metadata slice.`
  Acceptance: `Audit the remaining explicitly deferred field-structured storage directions after '.2': parent reset derivation, actor '(enums ...)' references, access-policy behavior, generated assertions/register-model output, typed storage and aggregate carriers, banks, packet/flit layouts, semantic JSON projection, support accounting, and downstream integration expectations. Select one bounded next implementation slice, explicitly defer the rest, or close the frontier if no safe next slice is warranted. No code/test/source/config change occurs before this selector completes.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1` | `done` | Selected the first implementation boundary as metadata-only scalar storage fields with checked ranges/access/resets/enums and report projection. |
| 2 | `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.2` | `done` | Shipped the selected checked scalar metadata contract without changing scheduled `.fsm`/HDL behavior. |
| 3 | `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.3` | `pending` | Decide the next residual boundary after the scalar metadata slice, or close/defer the remaining field-structured storage work explicitly. |

## Decisions

- `2026-06-22`: FSMGen accepts declarative field-structured storage as a
  directionally valid ISF feature request, but not as shipped behavior.
  Existing runtime field operations remain behavior, not static field-map
  metadata.
- `2026-06-22`: The first executable step is a readiness/contract audit. It
  must settle whether the first implementation is metadata-only, whether
  complete tiling is required or explicit reserved/gap metadata is allowed,
  how field resets relate to `(var ... (reset V))`, how enum/access metadata
  is represented, and how report/semantic JSON surfaces publish the result.
- `2026-06-22`: `.1` selected metadata-only scalar storage fields as the
  first slice. `fields` applies only to scalar `var`/`variable` storage,
  leaves gaps legal without inference, rejects overlaps and out-of-range
  ranges, keeps reset derivation out of scope while cross-checking field reset
  metadata against an explicit parent reset, uses inline enum metadata only,
  and publishes fields through optional `inferred_storage[].fields`.
- `2026-06-22`: `.2` shipped that first slice. Parser validation accepts
  checked `(fields (field NAME (bits HI LO) ...))` metadata only on
  width-based scalar actor-owned storage variables, scheduler IR carries the
  metadata, schedule JSON reports optional `inferred_storage[].fields`, and
  scheduled `.fsm`/HDL behavior remains unchanged by field metadata.

## Open Questions

- Later leaves must decide whether complete field maps may derive parent
  storage reset values, whether actor `(enums ...)` references participate in
  field metadata, and how to generalize from scalar registers to packet,
  structure, bank, or aggregate layouts.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-06-22` | `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1` | `read SPECFORGE request, active task owner, relevant decisions, Knowledge Map, ISF spec/public/downstream/mdBook docs, parser/lowerer/report/contract/test surfaces; wrote docs/ISF_FIELD_STRUCTURED_STORAGE_CONTRACT_SELECTION.md; git diff --check; scripts/check_memory_architecture.sh; scripts/check_doctrines.sh` | `passed` |
| `2026-06-22` | `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.2` | `prove -Iperl t/1453-isf-storage-field-metadata.t; prove -Iperl t/1148-isf-public-storage-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1113-isf-public-interface-contract-json-roundtrip-audit.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1376-isf-book-example-lowering-audit.t; mdbook build docs/book; bash knowledge-map/scripts/gen_knowledge_map.sh; bash knowledge-map/scripts/check_knowledge_map.sh; git --no-pager diff --check; scripts/check_memory_architecture.sh; scripts/check_doctrines.sh` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1` | `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1: select storage field contract` | `metadata-only scalar storage field contract selected` |
| `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.2` | `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.2: ship scalar storage fields` | `metadata-only scalar storage fields shipped for width-based actor-owned storage variables` |
| `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.3` | `pending` | `pending` |

## Changelog

- `2026-06-22`: Created the implementation frontier selected by
  `ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.2`.
- `2026-06-22`: Completed the readiness audit and selected
  `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.2` to implement metadata-only
  declarative fields on scalar actor-owned storage variables.
- `2026-06-22`: Completed `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.2`: scalar
  actor-owned width-based storage variables now accept checked report-only
  field metadata and expose it through optional `inferred_storage[].fields`;
  `.3` owns the next residual selection or frontier closeout.
