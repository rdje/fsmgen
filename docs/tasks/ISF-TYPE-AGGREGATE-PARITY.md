# ISF-TYPE-AGGREGATE-PARITY: ISF Enum, Type, And Aggregate Parity

## Metadata

- Tree ID: `ISF-TYPE-AGGREGATE-PARITY`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Let ISF reuse the enum, type-alias, and aggregate semantics already shipped for
`.fsm` direct roots, composition tops, and packages, without inventing a second
ISF-only type system.

## Non-Goals

- Do not create a parallel ISF type engine.
- Do not hide enum or aggregate meaning in backend-only structures that are
  absent from the lowered `.fsm` review artifacts.
- Do not ship broad inference-first aggregate growth before the declared-anchor
  and lowering contracts are explicit.
- Do not widen VHDL aggregate lowering in this tree.
- Do not treat schedule-report private parser/lowering internals as public API.

## Acceptance Criteria

- The ISF type/enum/aggregate source boundary is explicitly documented and
  synchronized across the spec, downstream handoff, mdBook, public contract
  notes, task tree, and live docs.
- ISF accepts only source forms whose meaning can be resolved through the
  existing `.fsm` package/type/symbol machinery or a documented adapter around
  that machinery.
- Accepted ISF enum/type/aggregate source lowers to reviewable scheduled `.fsm`
  text that uses the established `.fsm` declaration and aggregate semantics.
- Diagnostics reject unknown types, unresolved enum members, incompatible enum
  values, aggregate shape mismatches, and ambiguous partial updates before HDL
  generation.
- Schedule reports expose only bounded public summaries for any new accepted
  source, with public contract metadata and focused coverage updated in the
  same slice.
- Each completed leaf is validated, documented, and committed through
  [COMMIT.md](../../COMMIT.md).

## Task Tree

- ID: `ISF-TYPE-AGGREGATE-PARITY`
  Status: `active`
  Goal: `close the ISF enum/type/aggregate parity gap against the existing .fsm semantic machinery`
  Children: `ISF-TYPE-AGGREGATE-PARITY.1`, `ISF-TYPE-AGGREGATE-PARITY.2`, `ISF-TYPE-AGGREGATE-PARITY.3`, `ISF-TYPE-AGGREGATE-PARITY.4`, `ISF-TYPE-AGGREGATE-PARITY.5`, `ISF-TYPE-AGGREGATE-PARITY.6`

- ID: `ISF-TYPE-AGGREGATE-PARITY.1`
  Status: `done`
  Goal: `inventory current .fsm enum/type/aggregate support and the shipped ISF gap, then pin the first safe boundary`
  Acceptance: `task tree, spec, downstream handoff, mdBook backlog, public contract notes, and live docs state the current gap and first boundary without implying parser support that does not exist`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `087971d6 ISF-TYPE-AGGREGATE-PARITY.1: inventory parity boundary`

- ID: `ISF-TYPE-AGGREGATE-PARITY.2`
  Status: `done`
  Goal: `specify the ISF symbol-source contract for enum/type declarations and imports before parser widening`
  Acceptance: `source forms, import/source resolution, reuse of existing package/type machinery, diagnostics, lowered .fsm projection, schedule-report scope, and downstream impact are documented with focused acceptance tests identified`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `325bb9c9 ISF-TYPE-AGGREGATE-PARITY.2: specify type source contract`

- ID: `ISF-TYPE-AGGREGATE-PARITY.3`
  Status: `done`
  Goal: `implement the first scalar type-alias reference path for ISF width-bearing declarations`
  Acceptance: `the parser/lowerer can resolve a documented scalar type alias through the selected symbol source and emit reviewable .fsm that preserves the established .fsm type semantics; unknown or aggregate aliases fail closed in this scalar-only slice`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `prove -Iperl t/1257-isf-scalar-type-aliases.t`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `6dce0d9a ISF-TYPE-AGGREGATE-PARITY.3: ship scalar type aliases`

- ID: `ISF-TYPE-AGGREGATE-PARITY.4`
  Status: `done`
  Goal: `implement enum member references in one static scalar ISF value context`
  Acceptance: `one documented enum member reference context resolves through the selected symbol source, lowers to reviewable .fsm using established enum semantics, and rejects unknown enum families or members before generated artifacts are emitted`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1244-isf-wait-clause-lowering.t t/1249-isf-activation-parameter-constants.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.4: support enum constants`

- ID: `ISF-TYPE-AGGREGATE-PARITY.5`
  Status: `done`
  Goal: `extend the implemented path to one declared aggregate carrier only after scalar alias and enum resolution are stable`
  Acceptance: `one declared aggregate actor/interface or storage carrier lowers through reviewable .fsm with shape checks, focused tests, and bounded schedule-report visibility; partial aggregate updates remain deferred unless explicitly specified`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1259-isf-aggregate-storage-type-aliases.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1226-isf-data-width-storage-report.t t/1232-isf-actor-storage-declarations.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.5: ship aggregate storage carriers`

- ID: `ISF-TYPE-AGGREGATE-PARITY.6`
  Status: `pending`
  Goal: `implement one declared aggregate leaf access context after storage carriers are stable`
  Acceptance: `one documented member/item access context resolves against the declared aggregate storage carrier shape, lowers through reviewable .fsm with diagnostics for unknown members or out-of-range indexes, and keeps partial aggregate writes deferred unless this leaf explicitly selects them`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TYPE-AGGREGATE-PARITY.6` | `pending` | One aggregate leaf access context can start after actor-owned aggregate storage carriers are stable. |

## Decisions

- `2026-05-16`: The first committed slice is an inventory and boundary slice.
  Existing `.fsm` already ships package-backed constants, enum families,
  scalar type aliases, packed list/record aliases, declared aggregate signal
  access, partial aggregate LHS writes, and shape checks on the live
  SystemVerilog paths. Current ISF accepts scalar width evidence for ports and
  actor-owned storage, numeric/exact-width parameter values, actor-local
  constants for selected static specialization values, and compatible
  aggregate/list literal parameter values, but it does not yet accept enum or
  type declarations, typed width tokens, or typed aggregate carrier/update
  semantics. The next leaf must specify the symbol-source contract before
  implementation.
- `2026-05-16`: ISF parity must reuse existing `.fsm` semantic machinery or a
  documented adapter around it. A second ISF-only type system is rejected.
- `2026-05-16`: Lowered scheduled `.fsm` remains the review artifact and
  contract. Any accepted enum/type/aggregate ISF source must be visible there
  rather than only in private lowerer data.
- `2026-05-16`: The selected, not-yet-implemented source contract uses
  actor-local `(types ...)` and `(enums ...)` clauses whose payload shape maps
  directly to `.fsm` `+types` and `+enums`, plus `(imports (package name) ...)`
  entries for existing `.fsm` package roots. Package entries use one
  HDL-identifier-compatible package name, no alias, and no dotted namespace in
  the first contract so lowered scheduled `.fsm` can preserve the same
  `(+import name)` review artifact. ISF library imports keep their existing
  `(library name [as alias])` shape.
- `2026-05-16`: Type references in ISF width-bearing declarations will use an
  explicit `(type NAME)` option, mutually exclusive with `(width N)`. `NAME`
  may be a local type alias such as `byte` or a package-qualified alias such
  as `shared.byte`. The first implementation leaf accepts only scalar aliases;
  aggregate aliases fail closed until the aggregate-carrier leaf.
- `2026-05-16`: Local enum members keep the established `.fsm`
  `enum_name.MEMBER` spelling, and package members use
  `package_name.enum_name.MEMBER`. Enum value-use contexts are deliberately
  separate from scalar type-alias width references so the first implementation
  slice stays small.
- `2026-05-16`: Accepted declarations must be emitted into scheduled `.fsm`
  as `+types`, `+enums`, and `+import` blocks before HDL generation. Schedule
  reports may expose bounded name/count summaries later, but raw type-spec
  hashes and raw symbol tables remain private.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.3` ships the first scalar
  type-alias subset. ISF actor-local `(types ...)` declarations and
  `(imports (package NAME) ...)` now feed the existing `.fsm`
  package/type-symbol machinery; width-bearing interface ports,
  transaction-local ports, and actor-owned storage entries accept explicit
  `(type NAME)` scalar aliases; lowered scheduled `.fsm` preserves `+types`,
  `+import`, typed `+size`, and embedded imported package roots. Actor-local
  `(enums ...)` are accepted and preserved only as declaration artifacts.
  Enum member value references and typed aggregate carriers remain follow-on
  leaves.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.4` selects actor constants as the
  first static scalar enum-member value context. Actor constants now accept
  local `mode.MEMBER` and package-qualified `package.mode.MEMBER` values,
  preserve those authored tokens in scheduled `.fsm` `+constants` and
  schedule reports, and resolve them to non-negative integer values for
  existing static wait lowering and static activation-parameter override use.
  Other enum member expression/value contexts remain deferred.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.5` selects actor-owned storage
  variables as the first declared aggregate carrier. Storage variables now
  accept local and package `list`/`record` aliases, preserve the authored alias
  in scheduled `.fsm` `+size`, expose bounded `inferred_storage[].type` and
  `type_kind` report metadata, and reuse the existing `.fsm` package/type
  machinery for shape resolution and CLI HDL generation. Aggregate aliases on
  interface ports, transaction ports, storage banks, member/item paths, and
  partial aggregate updates remain deferred.

## Open Questions

- Which bounded schedule-report summary keys should advertise accepted
  enum/type declarations? This remains deferred because
  `ISF-TYPE-AGGREGATE-PARITY.3` deliberately shipped with generated `.fsm`
  review artifacts and focused parser/lowering tests rather than schedule
  JSON expansion.
- Which non-constant enum member expression/value context should ship next?
  This remains deferred beyond `ISF-TYPE-AGGREGATE-PARITY.4`.
- Which aggregate leaf access context should ship first after declared storage
  carriers? The current frontier selects this for `ISF-TYPE-AGGREGATE-PARITY.6`.

## Blockers

- None for the current frontier.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.2` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.3` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `prove -Iperl t/1257-isf-scalar-type-aliases.t`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.4` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1244-isf-wait-clause-lowering.t t/1249-isf-activation-parameter-constants.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.5` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1259-isf-aggregate-storage-type-aliases.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1226-isf-data-width-storage-report.t t/1232-isf-actor-storage-declarations.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TYPE-AGGREGATE-PARITY.1` | `ISF-TYPE-AGGREGATE-PARITY.1: inventory parity boundary` | `Inventory and first-boundary documentation slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.2` | `ISF-TYPE-AGGREGATE-PARITY.2: specify type source contract` | `Symbol-source and first type-reference contract slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.3` | `ISF-TYPE-AGGREGATE-PARITY.3: ship scalar type aliases` | `Scalar type-alias parser/lowering implementation slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.4` | `ISF-TYPE-AGGREGATE-PARITY.4: support enum constants` | `Actor-constant enum member parser/lowering implementation slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.5` | `ISF-TYPE-AGGREGATE-PARITY.5: ship aggregate storage carriers` | `Actor-owned aggregate storage carrier parser/lowering/report slice.` |

## Changelog

- `2026-05-16`: Created the active task tree and completed the inventory
  content for `ISF-TYPE-AGGREGATE-PARITY.1`.
- `2026-05-16`: Selected the source contract for
  `ISF-TYPE-AGGREGATE-PARITY.2` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.3`.
- `2026-05-16`: Shipped scalar type-alias parser/lowering support for
  `ISF-TYPE-AGGREGATE-PARITY.3` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.4`.
- `2026-05-16`: Shipped actor-constant enum member references for
  `ISF-TYPE-AGGREGATE-PARITY.4` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.5`.
- `2026-05-16`: Shipped actor-owned aggregate storage variable carriers for
  `ISF-TYPE-AGGREGATE-PARITY.5` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.6`.
