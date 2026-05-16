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
  Children: `ISF-TYPE-AGGREGATE-PARITY.1`, `ISF-TYPE-AGGREGATE-PARITY.2`, `ISF-TYPE-AGGREGATE-PARITY.3`, `ISF-TYPE-AGGREGATE-PARITY.4`, `ISF-TYPE-AGGREGATE-PARITY.5`, `ISF-TYPE-AGGREGATE-PARITY.6`, `ISF-TYPE-AGGREGATE-PARITY.7`, `ISF-TYPE-AGGREGATE-PARITY.8`, `ISF-TYPE-AGGREGATE-PARITY.9`, `ISF-TYPE-AGGREGATE-PARITY.10`, `ISF-TYPE-AGGREGATE-PARITY.11`, `ISF-TYPE-AGGREGATE-PARITY.12`, `ISF-TYPE-AGGREGATE-PARITY.13`, `ISF-TYPE-AGGREGATE-PARITY.14`, `ISF-TYPE-AGGREGATE-PARITY.15`, `ISF-TYPE-AGGREGATE-PARITY.16`, `ISF-TYPE-AGGREGATE-PARITY.17`, `ISF-TYPE-AGGREGATE-PARITY.18`, `ISF-TYPE-AGGREGATE-PARITY.19`, `ISF-TYPE-AGGREGATE-PARITY.20`, `ISF-TYPE-AGGREGATE-PARITY.21`, `ISF-TYPE-AGGREGATE-PARITY.22`, `ISF-TYPE-AGGREGATE-PARITY.23`, `ISF-TYPE-AGGREGATE-PARITY.24`, `ISF-TYPE-AGGREGATE-PARITY.25`, `ISF-TYPE-AGGREGATE-PARITY.26`, `ISF-TYPE-AGGREGATE-PARITY.27`, `ISF-TYPE-AGGREGATE-PARITY.28`, `ISF-TYPE-AGGREGATE-PARITY.29`, `ISF-TYPE-AGGREGATE-PARITY.30`, `ISF-TYPE-AGGREGATE-PARITY.31`, `ISF-TYPE-AGGREGATE-PARITY.32`, `ISF-TYPE-AGGREGATE-PARITY.33`, `ISF-TYPE-AGGREGATE-PARITY.34`, `ISF-TYPE-AGGREGATE-PARITY.35`, `ISF-TYPE-AGGREGATE-PARITY.36`, `ISF-TYPE-AGGREGATE-PARITY.37`, `ISF-TYPE-AGGREGATE-PARITY.38`, `ISF-TYPE-AGGREGATE-PARITY.39`, `ISF-TYPE-AGGREGATE-PARITY.40`, `ISF-TYPE-AGGREGATE-PARITY.41`, `ISF-TYPE-AGGREGATE-PARITY.42`, `ISF-TYPE-AGGREGATE-PARITY.43`, `ISF-TYPE-AGGREGATE-PARITY.44`, `ISF-TYPE-AGGREGATE-PARITY.45`, `ISF-TYPE-AGGREGATE-PARITY.46`

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
  Status: `done`
  Goal: `implement one declared aggregate leaf access context after storage carriers are stable`
  Acceptance: `one documented member/item access context resolves against the declared aggregate storage carrier shape, lowers through reviewable .fsm with diagnostics for unknown members or out-of-range indexes, and keeps partial aggregate writes deferred unless this leaf explicitly selects them`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.6: support aggregate leaf reads`

- ID: `ISF-TYPE-AGGREGATE-PARITY.7`
  Status: `done`
  Goal: `choose and implement the next aggregate update or value context after read-only leaf access`
  Acceptance: `direct transaction set target scalar aggregate leaf writes resolve against declared actor-owned aggregate storage carrier shape, lower through reviewable .fsm, reach CLI HDL generation, and keep subaggregate writes plus broader aggregate expression paths deferred`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.7: support aggregate leaf writes`

- ID: `ISF-TYPE-AGGREGATE-PARITY.8`
  Status: `done`
  Goal: `choose and implement the next enum or aggregate value/update context after scalar leaf writes`
  Acceptance: `transaction set RHS expressions accept scalar aggregate storage leaf operands with shape diagnostics and reviewable .fsm projection, while operator-position paths, subaggregate operands, and non-set expression contexts remain deferred`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.8: support aggregate expression reads`

- ID: `ISF-TYPE-AGGREGATE-PARITY.9`
  Status: `done`
  Goal: `choose and implement the next enum or aggregate value/update context after aggregate expression operands`
  Acceptance: `direct transaction set RHS scalar enum member values resolve through local and package enum sources, preserve authored tokens in reviewable .fsm, reach strict CLI HDL generation, and keep enum members in expressions, conditions, set targets, rules, drives, parameters, and other contexts deferred`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.9: support enum set values`

- ID: `ISF-TYPE-AGGREGATE-PARITY.10`
  Status: `done`
  Goal: `choose and implement the next enum or aggregate value/update context after direct enum set values`
  Acceptance: `transaction set RHS expressions accept scalar enum member operands with local/package resolution, reviewable .fsm projection, strict CLI HDL generation, and diagnostics for unknown enum members or enum members in expression operator position, while non-set enum contexts remain deferred`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.10: support enum expression operands`

- ID: `ISF-TYPE-AGGREGATE-PARITY.11`
  Status: `done`
  Goal: `choose and implement the next enum or aggregate value/update context after enum set expression operands`
  Acceptance: `transaction switch branch values accept local/package enum members with reviewable .fsm projection, strict CLI HDL generation, and diagnostics for unknown enum members, while switch selectors, conditions, targets, rules, drives, parameters, and other contexts remain deferred`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.11: support enum switch values`

- ID: `ISF-TYPE-AGGREGATE-PARITY.12`
  Status: `done`
  Goal: `support scalar enum member values in ISF drive body RHS positions`
  Acceptance: `drive body scalar RHS values accept local/package enum members with reviewable .fsm drive-DT projection, strict CLI HDL generation, and diagnostics for unknown enum members, while drive targets, drive call actuals, rules, conditions, parameters, and other contexts remain deferred`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.12: support enum drive values`

- ID: `ISF-TYPE-AGGREGATE-PARITY.13`
  Status: `done`
  Goal: `support scalar enum member values as named drive-call actuals`
  Acceptance: `named drive-call scalar actual values accept local/package enum members with reviewable .fsm drive-parameter projection, strict CLI HDL generation, and diagnostics for unknown enum members, while drive-call expression actuals, inline drive assignments, rules, conditions, parameters, and other contexts remain deferred`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.13: support enum drive call values`

- ID: `ISF-TYPE-AGGREGATE-PARITY.14`
  Status: `done`
  Goal: `support enum member operands inside named drive-call actual expressions`
  Acceptance: `named drive-call actual expressions accept local/package enum members as scalar operands with reviewable .fsm drive-parameter projection, strict CLI HDL generation, and diagnostics for unknown enum members or enum members in expression operator position, while inline drive assignments, rules, conditions, parameters, and other contexts remain deferred`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.14: support enum drive call expression values`

- ID: `ISF-TYPE-AGGREGATE-PARITY.15`
  Status: `done`
  Goal: `support scalar enum member values as actor parameter defaults`
  Acceptance: `actor-level scalar parameter defaults accept local/package enum members with reviewable .fsm +params projection, schedule-report value preservation, strict CLI HDL generation, and diagnostics for unknown enum members while aggregate/list enum leaves, transaction parameters, activation parameters, and other contexts remain deferred`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1253-isf-actor-param-report.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.15: support enum actor params`

- ID: `ISF-TYPE-AGGREGATE-PARITY.16`
  Status: `done`
  Goal: `support scalar enum member values as generated child transaction parameter defaults`
  Acceptance: `generated child transaction scalar parameter defaults accept local/package enum members with reviewable child .fsm +params projection, generated-composition schedule-report value preservation, strict CLI HDL generation, and diagnostics for unknown enum members while aggregate/list enum leaves, activation parameters, use-site overrides, and other contexts remain deferred`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1215-isf-spawn-parameter-binding.t t/1248-isf-rule-trigger-parameter-binding.t t/1249-isf-activation-parameter-constants.t t/1253-isf-actor-param-report.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.16: support enum transaction params`

- ID: `ISF-TYPE-AGGREGATE-PARITY.17`
  Status: `done`
  Goal: `support scalar enum member values in activation parameter overrides`
  Acceptance: `spawn, generated blocking do, and rule-trigger scalar parameter overrides accept local/package enum members, resolve to literal generated-top bindings, expose generated-composition binding values, and keep aggregate/list activation enum leaves plus other contexts fail-closed`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1271-isf-enum-member-activation-params.t t/1249-isf-activation-parameter-constants.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.17: support enum activation params`

- ID: `ISF-TYPE-AGGREGATE-PARITY.18`
  Status: `done`
  Goal: `support scalar enum member values in rule assignment RHS positions`
  Acceptance: `explicit (set port value) and shorthand (port value) rule assignments accept local/package enum members as direct scalar RHS values, preserve authored tokens in guarded scheduled .fsm rule DTs, pass strict CLI HDL generation, expose assignment provenance, and keep rule guards, targets, expression operands, and other enum contexts fail-closed`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Pipeline/SourceFrontend.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1272-isf-enum-member-rule-values.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1271-isf-enum-member-activation-params.t t/1221-isf-rule-expression-assignment.t t/1246-isf-setter-syntax.t t/295-strict-mode-infix-assignment-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.18: support enum rule values`

- ID: `ISF-TYPE-AGGREGATE-PARITY.19`
  Status: `done`
  Goal: `support enum member operands inside rule assignment RHS expressions`
  Acceptance: `explicit (set port expr) and shorthand (port expr) rule assignments accept local/package enum members as scalar operands inside RHS expressions, preserve authored expression tokens in guarded scheduled .fsm rule DTs, pass strict CLI HDL generation, expose assignment provenance, and keep expression operator-position enum members, rule guards, targets, and other contexts fail-closed`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1273-isf-enum-member-rule-expression-values.t t/1272-isf-enum-member-rule-values.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1271-isf-enum-member-activation-params.t t/1221-isf-rule-expression-assignment.t t/1246-isf-setter-syntax.t t/295-strict-mode-infix-assignment-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.19: support enum rule expression values`

- ID: `ISF-TYPE-AGGREGATE-PARITY.20`
  Status: `done`
  Goal: `support enum member operands inside rule guard expressions`
  Acceptance: `shorthand and long-form rule guard expressions accept local/package enum members as scalar operands, preserve authored guard expression tokens in scheduled .fsm rule DT headers, pass strict CLI HDL generation, preserve public when normalization, and keep standalone enum guards, expression operator-position enum members, rule targets, and other contexts fail-closed`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1274-isf-enum-member-rule-guard-values.t t/1273-isf-enum-member-rule-expression-values.t t/1272-isf-enum-member-rule-values.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1271-isf-enum-member-activation-params.t t/1233-isf-rule-expression-guards.t t/1221-isf-rule-expression-assignment.t t/1246-isf-setter-syntax.t t/295-strict-mode-infix-assignment-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.20: support enum rule guards`

- ID: `ISF-TYPE-AGGREGATE-PARITY.21`
  Status: `done`
  Goal: `support enum member operands inside transaction condition expressions`
  Acceptance: `transaction when/while/until condition expressions accept local/package enum members as scalar operands, preserve authored computed-test condition tokens in scheduled .fsm, pass strict CLI HDL generation, preserve computed-test parser boundaries, and keep standalone enum conditions plus expression operator-position enum members fail-closed`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/37-language-contract-computed-test-selector.t t/55-language-contract-computed-test-selector-boundary.t`; `prove -Iperl t/1275-isf-enum-member-condition-values.t t/1274-isf-enum-member-rule-guard-values.t t/1273-isf-enum-member-rule-expression-values.t t/1272-isf-enum-member-rule-values.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1271-isf-enum-member-activation-params.t t/1206-isf-when-clause-boundary.t t/1245-isf-transaction-loop-lowering.t t/1233-isf-rule-expression-guards.t t/1221-isf-rule-expression-assignment.t t/1246-isf-setter-syntax.t t/295-strict-mode-infix-assignment-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.21: support enum conditions`

- ID: `ISF-TYPE-AGGREGATE-PARITY.22`
  Status: `done`
  Goal: `support enum member leaves inside aggregate/list activation parameter overrides`
  Acceptance: `spawn, generated blocking do, and rule-trigger aggregate/list activation parameter overrides accept local/package enum members as scalar leaves, resolve them to literal generated-top and generated-composition report bindings, pass strict CLI HDL generation, reject unknown members, and keep reusable-library use-site enum overrides plus broader parameter aggregate/list enum leaves deferred`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1276-isf-enum-member-activation-aggregate-params.t t/1271-isf-enum-member-activation-params.t t/1270-isf-enum-member-transaction-params.t t/1269-isf-enum-member-actor-params.t t/1249-isf-activation-parameter-constants.t t/1215-isf-spawn-parameter-binding.t t/1248-isf-rule-trigger-parameter-binding.t t/1263-isf-enum-member-set-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1272-isf-enum-member-rule-values.t t/1274-isf-enum-member-rule-guard-values.t t/1275-isf-enum-member-condition-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.22: support enum activation aggregate leaves`

- ID: `ISF-TYPE-AGGREGATE-PARITY.23`
  Status: `done`
  Goal: `support enum member leaves inside actor aggregate/list parameter defaults`
  Acceptance: `actor-level aggregate/list parameter defaults accept local/package enum members as scalar leaves, preserve authored tokens in scheduled .fsm +params and actor_params[] reports, record resolved literal leaves internally, pass strict CLI HDL generation, reject unknown leaves, and keep generated child transaction aggregate/list parameter enum leaves plus reusable-library use-site enum overrides deferred`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1277-isf-enum-member-actor-aggregate-params.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1276-isf-enum-member-activation-aggregate-params.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.23: support enum actor aggregate params`

- ID: `ISF-TYPE-AGGREGATE-PARITY.24`
  Status: `done`
  Goal: `support enum member leaves inside generated child transaction aggregate/list parameter defaults`
  Acceptance: `generated child transaction aggregate/list parameter defaults accept local/package enum members as scalar leaves, preserve authored tokens in child .fsm +params, generated-composition child parameter summaries, and default instance bindings, record resolved literal leaves internally, pass strict CLI HDL generation, reject unknown leaves, and keep reusable-library use-site enum overrides deferred`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1278-isf-enum-member-transaction-aggregate-params.t t/1270-isf-enum-member-transaction-params.t t/1277-isf-enum-member-actor-aggregate-params.t t/1269-isf-enum-member-actor-params.t t/1276-isf-enum-member-activation-aggregate-params.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.24: support enum transaction aggregate params`

- ID: `ISF-TYPE-AGGREGATE-PARITY.25`
  Status: `done`
  Goal: `support enum member values in inline drive assignment RHS positions`
  Acceptance: `inline transaction drive assignment RHS scalar values accept local/package enum members with reviewable .fsm state-assignment projection, strict CLI HDL generation, diagnostics for unknown enum members, and fail-closed boundaries for inline drive targets and inline drive RHS expressions`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1279-isf-enum-member-inline-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1266-isf-enum-member-drive-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1263-isf-enum-member-set-values.t t/1265-isf-enum-member-switch-branch-values.t t/1272-isf-enum-member-rule-values.t t/1274-isf-enum-member-rule-guard-values.t t/1275-isf-enum-member-condition-values.t t/1193-isf-drive-call-arity-boundary.t t/1244-isf-wait-clause-lowering.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.25: support enum inline drive values`

- ID: `ISF-TYPE-AGGREGATE-PARITY.26`
  Status: `done`
  Goal: `support enum member operands inside inline drive assignment RHS expressions`
  Acceptance: `inline transaction drive assignment RHS expressions accept local/package enum members as scalar operands with reviewable .fsm state-assignment projection, strict CLI HDL generation, diagnostics for unknown enum members or enum members in expression operator position, and fail-closed boundaries for inline drive targets`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1280-isf-enum-member-inline-drive-expression-values.t t/1279-isf-enum-member-inline-drive-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1267-isf-enum-member-drive-call-values.t t/1266-isf-enum-member-drive-values.t t/1263-isf-enum-member-set-values.t t/1265-isf-enum-member-switch-branch-values.t t/1272-isf-enum-member-rule-values.t t/1274-isf-enum-member-rule-guard-values.t t/1275-isf-enum-member-condition-values.t t/1193-isf-drive-call-arity-boundary.t t/1244-isf-wait-clause-lowering.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.26: support enum inline drive expressions`

- ID: `ISF-TYPE-AGGREGATE-PARITY.27`
  Status: `done`
  Goal: `support enum member values and leaves in reusable-library use-site parameter overrides`
  Acceptance: `reusable-library use-site scalar and aggregate/list parameter overrides accept local/package enum members, resolve to literal generated-top bindings and library_uses[] report values, pass strict CLI HDL generation, reject unknown enum members, and keep plain symbolic use-site overrides fail-closed`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1281-isf-enum-member-library-use-params.t t/1280-isf-enum-member-inline-drive-expression-values.t t/1279-isf-enum-member-inline-drive-values.t t/1278-isf-enum-member-transaction-aggregate-params.t t/1277-isf-enum-member-actor-aggregate-params.t t/1276-isf-enum-member-activation-aggregate-params.t t/1271-isf-enum-member-activation-params.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1263-isf-enum-member-set-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1272-isf-enum-member-rule-values.t t/1274-isf-enum-member-rule-guard-values.t t/1275-isf-enum-member-condition-values.t t/1230-isf-library-import-resolution.t t/1231-isf-library-generated-top.t t/1237-isf-fifo-library-fixture.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.27: support enum library use params`

- ID: `ISF-TYPE-AGGREGATE-PARITY.28`
  Status: `done`
  Goal: `support enum member operands inside named drive body RHS expressions`
  Acceptance: `named drive body RHS expressions accept local/package enum members as scalar operands with reviewable .fsm drive-DT projection, strict CLI HDL generation, diagnostics for unknown enum members or enum members in expression operator position, recursive drive-parameter substitution inside body expressions, and fail-closed boundaries for drive targets`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1282-isf-enum-member-drive-expression-values.t t/1194-isf-drive-body-boundary.t t/1266-isf-enum-member-drive-values.t t/1280-isf-enum-member-inline-drive-expression-values.t t/1279-isf-enum-member-inline-drive-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1267-isf-enum-member-drive-call-values.t t/1263-isf-enum-member-set-values.t t/1265-isf-enum-member-switch-branch-values.t t/1272-isf-enum-member-rule-values.t t/1274-isf-enum-member-rule-guard-values.t t/1275-isf-enum-member-condition-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.28: support enum drive expressions`

- ID: `ISF-TYPE-AGGREGATE-PARITY.29`
  Status: `done`
  Goal: `support scalar aggregate storage leaf reads as rule assignment RHS values`
  Acceptance: `explicit and shorthand rule assignment scalar RHS values accept local/package aggregate storage member/item leaves with shape diagnostics, reviewable .fsm rule-DT projection, assignment provenance, strict CLI HDL generation, and fail-closed boundaries for rule assignment targets and RHS expression operands`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1221-isf-rule-expression-assignment.t t/1272-isf-enum-member-rule-values.t t/1273-isf-enum-member-rule-expression-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.29: support aggregate rule values`

- ID: `ISF-TYPE-AGGREGATE-PARITY.30`
  Status: `done`
  Goal: `support scalar aggregate storage leaf operands inside rule assignment RHS expressions`
  Acceptance: `explicit and shorthand rule assignment RHS expressions accept local/package aggregate storage member/item leaves as scalar operands with shape diagnostics, reviewable .fsm rule-DT projection, assignment provenance, strict CLI HDL generation, and fail-closed diagnostics for operator-position aggregate paths and subaggregate operands`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1221-isf-rule-expression-assignment.t t/1272-isf-enum-member-rule-values.t t/1273-isf-enum-member-rule-expression-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.30: support aggregate rule expressions`

- ID: `ISF-TYPE-AGGREGATE-PARITY.31`
  Status: `done`
  Goal: `support scalar aggregate storage leaf operands inside rule guard expressions`
  Acceptance: `shorthand and long-form rule guard expressions accept local/package aggregate storage member/item leaves as scalar operands with shape diagnostics, public when normalization, reviewable .fsm rule-DT header projection, strict CLI HDL generation, and fail-closed diagnostics for standalone aggregate guards, operator-position aggregate paths, and subaggregate operands`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1233-isf-rule-expression-guards.t t/1274-isf-enum-member-rule-guard-values.t t/1272-isf-enum-member-rule-values.t t/1273-isf-enum-member-rule-expression-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.31: support aggregate rule guards`

- ID: `ISF-TYPE-AGGREGATE-PARITY.32`
  Status: `done`
  Goal: `support scalar aggregate storage leaf operands inside transaction condition expressions`
  Acceptance: `transaction when/while/until condition expressions accept local/package aggregate storage member/item leaves as scalar operands with shape diagnostics, reviewable .fsm computed-test projection, strict CLI HDL generation, and fail-closed diagnostics for standalone aggregate conditions, operator-position aggregate paths, and subaggregate operands`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1275-isf-enum-member-condition-values.t t/1233-isf-rule-expression-guards.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.32: support aggregate conditions`

- ID: `ISF-TYPE-AGGREGATE-PARITY.33`
  Status: `done`
  Goal: `support scalar aggregate storage leaf reads as named drive body RHS values`
  Acceptance: `named drive body scalar RHS values accept local/package aggregate storage member/item leaves with shape diagnostics, reviewable .fsm drive-DT projection, strict CLI HDL generation, and fail-closed diagnostics for drive targets, RHS expression operands, and subaggregate RHS values`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1266-isf-enum-member-drive-values.t t/1282-isf-enum-member-drive-expression-values.t t/1194-isf-drive-body-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.33: support aggregate drive values`

- ID: `ISF-TYPE-AGGREGATE-PARITY.34`
  Status: `done`
  Goal: `support scalar aggregate storage leaf operands inside named drive body RHS expressions`
  Acceptance: `named drive body RHS expressions accept local/package aggregate storage member/item leaves as scalar operands with shape diagnostics, reviewable .fsm drive-DT projection, strict CLI HDL generation, and fail-closed diagnostics for operator-position aggregate paths and subaggregate operands`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1288-isf-aggregate-drive-expression-values.t t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1282-isf-enum-member-drive-expression-values.t t/1266-isf-enum-member-drive-values.t t/1194-isf-drive-body-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.34: support aggregate drive expressions`

- ID: `ISF-TYPE-AGGREGATE-PARITY.35`
  Status: `done`
  Goal: `support scalar aggregate storage leaf reads as named drive-call actual values`
  Acceptance: `named drive-call scalar actual values accept local/package aggregate storage member/item leaves with shape diagnostics, reviewable .fsm drive-parameter projection, strict CLI HDL generation, and fail-closed diagnostics for initially deferred actual expressions, inline drive assignment aggregate contexts, and subaggregate actual values`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1289-isf-aggregate-drive-call-values.t t/1288-isf-aggregate-drive-expression-values.t t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1193-isf-drive-call-arity-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.35: support aggregate drive-call values`

- ID: `ISF-TYPE-AGGREGATE-PARITY.36`
  Status: `done`
  Goal: `support scalar aggregate storage leaf operands inside named drive-call actual expressions`
  Acceptance: `named drive-call actual expressions accept local/package aggregate storage member/item leaves as scalar operands with shape diagnostics, reviewable .fsm drive-parameter projection, strict CLI HDL generation, and fail-closed diagnostics for operator-position aggregate paths and subaggregate operands`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1290-isf-aggregate-drive-call-expression-values.t t/1289-isf-aggregate-drive-call-values.t t/1288-isf-aggregate-drive-expression-values.t t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1268-isf-enum-member-drive-call-expression-values.t t/1267-isf-enum-member-drive-call-values.t t/1193-isf-drive-call-arity-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.36: support aggregate drive-call expressions`

- ID: `ISF-TYPE-AGGREGATE-PARITY.37`
  Status: `done`
  Goal: `support scalar aggregate storage leaf reads as inline drive assignment RHS values`
  Acceptance: `inline transaction drive assignment scalar RHS values accept local/package aggregate storage member/item leaves with shape diagnostics, reviewable .fsm state-assignment projection, strict CLI HDL generation, and fail-closed diagnostics for inline drive targets, initially deferred RHS expressions, and subaggregate RHS values`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1291-isf-aggregate-inline-drive-values.t t/1290-isf-aggregate-drive-call-expression-values.t t/1289-isf-aggregate-drive-call-values.t t/1288-isf-aggregate-drive-expression-values.t t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1279-isf-enum-member-inline-drive-values.t t/1280-isf-enum-member-inline-drive-expression-values.t t/1193-isf-drive-call-arity-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.37: support aggregate inline drive values`

- ID: `ISF-TYPE-AGGREGATE-PARITY.38`
  Status: `done`
  Goal: `support scalar aggregate storage leaf operands inside inline drive assignment RHS expressions`
  Acceptance: `inline transaction drive assignment RHS expressions accept local/package aggregate storage member/item leaves as scalar operands with shape diagnostics, reviewable .fsm state-assignment projection, strict CLI HDL generation, and fail-closed diagnostics for inline drive targets, expression operator-position aggregate paths, and subaggregate operands`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1292-isf-aggregate-inline-drive-expression-values.t t/1291-isf-aggregate-inline-drive-values.t t/1290-isf-aggregate-drive-call-expression-values.t t/1289-isf-aggregate-drive-call-values.t t/1288-isf-aggregate-drive-expression-values.t t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1280-isf-enum-member-inline-drive-expression-values.t t/1279-isf-enum-member-inline-drive-values.t t/1193-isf-drive-call-arity-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.38: support aggregate inline drive expressions`

- ID: `ISF-TYPE-AGGREGATE-PARITY.39`
  Status: `done`
  Goal: `support scalar aggregate storage leaf reads as transaction switch branch values`
  Acceptance: `transaction switch branch scalar values accept local/package aggregate storage member/item leaves with shape diagnostics, reviewable .fsm switch projection, strict CLI HDL generation, and fail-closed diagnostics for switch selectors and subaggregate branch values`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1293-isf-aggregate-switch-branch-values.t t/1292-isf-aggregate-inline-drive-expression-values.t t/1291-isf-aggregate-inline-drive-values.t t/1290-isf-aggregate-drive-call-expression-values.t t/1289-isf-aggregate-drive-call-values.t t/1288-isf-aggregate-drive-expression-values.t t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1265-isf-enum-member-switch-branch-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.39: support aggregate switch values`

- ID: `ISF-TYPE-AGGREGATE-PARITY.40`
  Status: `done`
  Goal: `support scalar aggregate storage leaf reads as transaction switch selectors`
  Acceptance: `transaction switch selectors accept local/package aggregate storage member/item leaves with shape diagnostics, computed .fsm selector review artifacts, strict CLI HDL generation, and fail-closed diagnostics for unknown members and subaggregate selectors`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1294-isf-aggregate-switch-selector-values.t t/1293-isf-aggregate-switch-branch-values.t t/1292-isf-aggregate-inline-drive-expression-values.t t/1291-isf-aggregate-inline-drive-values.t t/1290-isf-aggregate-drive-call-expression-values.t t/1289-isf-aggregate-drive-call-values.t t/1288-isf-aggregate-drive-expression-values.t t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1265-isf-enum-member-switch-branch-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/37-language-contract-computed-test-selector.t t/55-language-contract-computed-test-selector-boundary.t t/1205-isf-switch-clause-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.40: support aggregate switch selectors`

- ID: `ISF-TYPE-AGGREGATE-PARITY.41`
  Status: `done`
  Goal: `support enum member values as transaction switch selectors`
  Acceptance: `transaction switch selectors accept local/package enum members with computed .fsm selector review artifacts, strict CLI HDL generation, diagnostics for unknown enum members, and fail-closed boundaries for standalone enum conditions`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1295-isf-enum-member-switch-selector-values.t t/1265-isf-enum-member-switch-branch-values.t t/1294-isf-aggregate-switch-selector-values.t t/1293-isf-aggregate-switch-branch-values.t t/1275-isf-enum-member-condition-values.t t/1263-isf-enum-member-set-values.t t/1266-isf-enum-member-drive-values.t t/1272-isf-enum-member-rule-values.t t/1274-isf-enum-member-rule-guard-values.t t/1279-isf-enum-member-inline-drive-values.t t/37-language-contract-computed-test-selector.t t/55-language-contract-computed-test-selector-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.41: support enum switch selectors`

- ID: `ISF-TYPE-AGGREGATE-PARITY.42`
  Status: `done`
  Goal: `support scalar aggregate storage leaf writes as rule assignment targets`
  Acceptance: `explicit and shorthand rule assignment targets accept local/package aggregate storage member/item leaves with shape diagnostics, guarded rule-DT review artifacts, assignment provenance, strict CLI HDL generation, and fail-closed diagnostics for unknown members and subaggregate targets`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1296-isf-aggregate-rule-target-values.t t/1283-isf-aggregate-rule-values.t t/1284-isf-aggregate-rule-expression-values.t t/1285-isf-aggregate-rule-guard-values.t t/1261-isf-aggregate-storage-leaf-writes.t t/1272-isf-enum-member-rule-values.t t/1287-isf-aggregate-drive-values.t t/1291-isf-aggregate-inline-drive-values.t t/1246-isf-setter-syntax.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.42: support aggregate rule targets`

- ID: `ISF-TYPE-AGGREGATE-PARITY.43`
  Status: `done`
  Goal: `support scalar aggregate storage leaf writes as named drive body targets`
  Acceptance: `named drive body targets accept local/package aggregate storage member/item leaves with shape diagnostics, drive-DT review artifacts, assignment provenance, strict CLI HDL generation, and fail-closed diagnostics for unknown members and subaggregate targets`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1297-isf-aggregate-drive-target-values.t t/1287-isf-aggregate-drive-values.t t/1288-isf-aggregate-drive-expression-values.t t/1296-isf-aggregate-rule-target-values.t t/1291-isf-aggregate-inline-drive-values.t t/1261-isf-aggregate-storage-leaf-writes.t t/1285-isf-aggregate-rule-guard-values.t t/1286-isf-aggregate-condition-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.43: support aggregate drive targets`

- ID: `ISF-TYPE-AGGREGATE-PARITY.44`
  Status: `done`
  Goal: `support scalar aggregate storage leaf writes as inline drive targets`
  Acceptance: `inline transaction drive assignment targets accept local/package aggregate storage member/item leaves with shape diagnostics, state-assignment review artifacts, assignment provenance, strict CLI HDL generation, and fail-closed diagnostics for unknown members and subaggregate targets`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1298-isf-aggregate-inline-drive-target-values.t t/1291-isf-aggregate-inline-drive-values.t t/1292-isf-aggregate-inline-drive-expression-values.t t/1297-isf-aggregate-drive-target-values.t t/1261-isf-aggregate-storage-leaf-writes.t t/1285-isf-aggregate-rule-guard-values.t t/1286-isf-aggregate-condition-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.44: support aggregate inline drive targets`

- ID: `ISF-TYPE-AGGREGATE-PARITY.45`
  Status: `done`
  Goal: `support scalar aggregate storage leaf reads as standalone transaction conditions`
  Acceptance: `transaction when/while/until scalar conditions accept local/package aggregate storage member/item leaves with shape diagnostics, computed .fsm selector review artifacts, strict CLI HDL generation, and fail-closed diagnostics for unknown members and subaggregate conditions`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1299-isf-aggregate-standalone-condition-values.t t/1286-isf-aggregate-condition-values.t t/1261-isf-aggregate-storage-leaf-writes.t t/1285-isf-aggregate-rule-guard-values.t t/1298-isf-aggregate-inline-drive-target-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TYPE-AGGREGATE-PARITY.45: support aggregate standalone conditions`

- ID: `ISF-TYPE-AGGREGATE-PARITY.46`
  Status: `pending`
  Goal: `choose the next remaining enum or aggregate value/update context after aggregate standalone transaction conditions`
  Acceptance: `one documented enum or aggregate value/update context ships with diagnostics and reviewable .fsm projection, or the tree records exhaustion/closure with explicit remaining deferrals`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TYPE-AGGREGATE-PARITY.46` | `pending` | The next enum or aggregate value/update context can be selected after aggregate standalone transaction conditions are stable. |

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
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.6` selects direct transaction
  `set` RHS values as the first aggregate leaf read context. Scalar record
  members and list items now resolve against actor-owned aggregate storage
  carrier shape before lowering, preserve the authored path in scheduled
  `.fsm`, and reach CLI HDL generation through the existing typed aggregate
  `.fsm` path machinery. Partial aggregate writes, aggregate paths inside
  broader expressions, and other value contexts remain deferred.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.7` selects direct transaction
  `set` targets as the first aggregate update context. Scalar record members
  and list items on actor-owned aggregate storage now resolve before lowering,
  preserve the authored LHS path in scheduled `.fsm`, and reach CLI HDL
  generation through the existing typed aggregate `.fsm` partial-LHS path
  machinery. Subaggregate writes, aggregate paths inside broader expressions,
  aggregate carriers outside actor-owned storage variables, and enum member
  value contexts outside actor constants remain deferred.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.8` selects transaction `set` RHS
  expressions as the next aggregate value context. Scalar aggregate leaf paths
  are now accepted as expression operands and validated with the same declared
  storage shape resolver used by direct reads. Aggregate paths in expression
  operator position, subaggregate operands, non-`set` expression contexts, and
  enum member value contexts outside actor constants remain deferred.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.9` selects direct transaction
  `set` RHS scalar values as the next enum member context. Local and
  package-qualified enum member tokens now resolve before lowering and are
  preserved in the scheduled `.fsm` review artifact. Enum members inside
  expressions, conditions, set targets, rules, drives, parameters, and other
  non-direct-set RHS scalar contexts remain deferred.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.10` selects transaction `set` RHS
  expressions as the next enum member value context. Local and
  package-qualified enum members are now accepted as scalar operands inside
  those expressions, preserving authored expression tokens in scheduled
  `.fsm`. Enum members in expression operator position, conditions, set
  targets, rules, drives, parameters, and other contexts remain deferred.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.11` selects transaction `switch`
  branch values as the next enum member value context. Local and
  package-qualified enum branch values now resolve before lowering and are
  preserved in scheduled `.fsm` selector branches. Switch selectors,
  conditions, set targets, rules, drives, parameters, and other enum contexts
  remain deferred.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.12` selects scalar drive body RHS
  values as the next enum member value context because named drive body DTs
  already preserve authored scalar RHS tokens and reach strict CLI HDL
  generation. Local and package-qualified enum members now resolve before
  lowering and are preserved in the generated drive DT. Drive targets,
  drive-call actuals, rules, conditions, switch selectors, set targets,
  parameters, and other enum contexts remain deferred.
- `2026-05-16`: Rule assignment enum RHS support is deliberately not bundled
  into `ISF-TYPE-AGGREGATE-PARITY.12`. A local probe found a separate
  strict-mode generated `.fsm` boundary for guarded rule assignments, so rule
  enum values need a dedicated lowering/strictness slice before they should be
  advertised as public.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.13` selects named drive-call
  scalar actual values as the next enum member value context because the
  existing drive-parameter handoff path already preserves authored scalar
  actuals in scheduled `.fsm` assignments and reaches strict CLI HDL
  generation. Enum members inside drive-call expression actuals, inline drive
  assignments, rules, conditions, parameters, and other contexts remain
  deferred.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.14` selects enum members as
  scalar operands inside named drive-call actual expressions because the
  drive-parameter handoff path already preserves authored expression payloads
  in scheduled `.fsm` assignments and reaches strict CLI HDL generation.
  Expression operator-position enum members remain rejected so authored
  expression heads stay ordinary operators. Inline drive assignments, rules,
  conditions, switch selectors, set targets, parameters, and other contexts
  remain deferred.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.15` selects actor-level scalar
  parameter defaults as the next enum member value context because scheduled
  `.fsm` already has strict-safe enum-backed `+params` support and
  `actor_params[]` already preserves authored parameter defaults. This slice
  deliberately stays actor-scalar-only: aggregate/list parameter leaves,
  transaction-local parameter defaults, activation parameter overrides,
  reusable-library use-site overrides, and parameter-derived wait/storage
  semantics remain separate contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.16` selects generated child
  transaction scalar parameter defaults as the next enum member value context
  because generated child `.fsm` artifacts already project transaction
  defaults as strict-safe `+params`, and generated-composition schedule
  reports already expose child defaults plus default instance bindings. This
  slice deliberately stays transaction-scalar-only: aggregate/list parameter
  enum leaves, activation parameter overrides, reusable-library use-site
  overrides, and parameter-derived wait/storage semantics remain separate
  contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.17` selects scalar activation
  parameter overrides as the next enum member value context because generated
  activation sites already statically specialize child instances and the
  generated top must receive literal `?fsmc` parameter bindings. This slice
  deliberately stays scalar-only: aggregate/list activation override enum
  leaves, reusable-library use-site overrides, direct `(on ...)` activation
  overrides, and parameter-derived wait/storage semantics remain separate
  contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.18` selects scalar rule
  assignment RHS values as the next enum member value context because guarded
  rule DTs already preserve authored assignment RHS tokens, and the separate
  strict-mode guarded-DT boundary is now covered. This slice deliberately
  stays direct-scalar-only: rule guard enum members, rule target enum members,
  enum operands inside rule assignment expressions, and other rule enum
  contexts remain separate contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.19` widens rule assignment RHS enum
  support from direct scalar values to scalar operands inside rule assignment
  RHS expressions. This reuses the existing expression-valued rule assignment
  lowering/provenance path while keeping enum members in expression operator
  position rejected so authored expression heads remain ordinary operators.
  Rule guards, rule targets, and other rule enum contexts remain separate
  contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.20` widens rule enum support to
  scalar operands inside rule guard expressions because expression-valued rule
  guards already lower directly into scheduled `.fsm` rule DT headers and reach
  strict HDL generation. This slice deliberately stays operand-only:
  standalone enum member guards, expression operator-position enum members,
  rule targets, and broader condition/selector contexts remain separate
  contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.21` widens enum support to scalar
  operands inside transaction `when`/`while`/`until` condition expressions
  because those conditions already lower into scheduled `.fsm` computed-test
  selectors and strict HDL generation can preserve the authored expression.
  This slice also tightens the direct `.fsm` computed-test parser so comparison
  heads such as `==` are treated as selector expressions rather than malformed
  branch markers. Standalone enum member conditions, transaction condition
  expression operator-position enum members, switch selectors, and assignment
  targets remain separate contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.22` widens generated activation
  parameter overrides from scalar enum values to enum member leaves inside
  aggregate/list override values. Generated activation sites already resolve
  actor constants leaf-by-leaf and require literal generated-top `?fsmc`
  bindings, so enum leaves now follow that same static specialization path.
  Reusable-library use-site enum overrides, aggregate/list parameter-default
  enum leaves, direct `(on ...)` activation parameter forms, and broader
  parameter-derived semantics remain separate contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.23` widens actor parameter
  defaults from scalar enum values to enum member leaves inside actor-level
  aggregate/list defaults. Scheduled `.fsm` `+params` and `actor_params[]`
  reports preserve authored enum tokens, while parser/lowerer metadata records
  resolved literal leaves for validation. Generated child transaction
  aggregate/list parameter defaults and reusable-library use-site enum
  overrides remain separate contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.24` widens generated child
  transaction parameter defaults from scalar enum values to enum member leaves
  inside aggregate/list defaults. Generated child `.fsm` `+params`,
  generated-composition child parameter summaries, and default instance
  bindings preserve authored enum tokens, while lowerer metadata records
  resolved literal leaves for validation. Reusable-library use-site enum
  overrides remain a separate library-instantiation contract.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.25` selects inline transaction
  drive assignment RHS scalar values as the next enum member value context
  because labeled inline drive clauses already lower to reviewable scheduled
  `.fsm` state assignments and strict HDL generation can preserve authored enum
  RHS tokens. This slice keeps inline drive targets and inline drive RHS
  expressions closed so assignment ownership and expression-operand behavior
  can remain separate contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.26` widens inline drive RHS enum
  support from direct scalar values to scalar operands inside inline drive RHS
  expressions. This mirrors the transaction set, rule assignment, and
  drive-call expression-operand policy while keeping enum members in expression
  operator position rejected so authored expression heads stay ordinary
  operators.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.27` selects reusable-library
  use-site parameter overrides as the next static specialization enum context.
  Use-site scalar values and aggregate/list leaves now accept local or package
  enum members, resolve those members to literal generated-top `?fsmc`
  parameter bindings, and publish the same literal values in `library_uses[]`
  schedule reports. Plain symbolic use-site values remain rejected.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.28` widens named drive body RHS enum
  support from direct scalar values to expression operands. The lowerer formats
  the body expression and substitutes drive formals recursively, while parser
  validation keeps enum members out of expression operator position.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.29` selects direct rule assignment
  RHS aggregate leaves because guarded rule DTs and assignment provenance
  already preserve authored scalar RHS tokens. Rule targets and aggregate RHS
  expressions remain separate contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.30` widens aggregate rule assignment
  RHS support from direct scalar values to scalar expression operands. The
  parser walks the RHS expression tree, validates only scalar aggregate leaves,
  and keeps aggregate paths in expression operator position rejected.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.31` selects rule guard expression
  aggregate operands because rule guards already preserve authored expression
  text in scheduled `.fsm` DT headers and strict HDL generation can consume
  scalar aggregate leaf operands. Standalone aggregate guards, rule guard
  operator-position aggregate paths, and subaggregate operands remain separate
  contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.32` selects transaction condition
  expression aggregate operands because transaction `when`/`while`/`until`
  conditions already preserve authored expression text in scheduled `.fsm`
  computed-test selectors. Standalone aggregate conditions, condition
  operator-position aggregate paths, and subaggregate operands remain separate
  contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.33` selects named drive body RHS
  aggregate values because drive DT assignments already preserve authored
  scalar RHS tokens and reach strict HDL generation. This slice deliberately
  stays direct-scalar-only: drive targets, aggregate operands inside drive body
  RHS expressions, and subaggregate RHS values remain separate contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.34` widens named drive body RHS
  aggregate support from direct scalar values to scalar operands inside drive
  body RHS expressions. This mirrors the rule assignment and transaction set
  expression-operand policy while keeping aggregate paths in expression
  operator position rejected.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.35` selects named drive-call scalar
  actual aggregate values because the drive-parameter handoff path already
  preserves authored actual tokens in scheduled `.fsm` assignments. This slice
  deliberately stays direct-scalar-only: aggregate drive-call actual
  expressions and inline drive assignment aggregate contexts remain separate
  contracts.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.36` widens named drive-call
  aggregate support from direct scalar actual values to scalar operands inside
  drive-call actual expressions. This mirrors the enum drive-call expression
  and aggregate drive-body expression policies while keeping aggregate paths in
  expression operator position rejected.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.37` selects inline drive assignment
  RHS aggregate values because labeled inline drive clauses already preserve
  authored state-assignment RHS tokens in scheduled `.fsm` and reach strict HDL
  generation. This slice stays direct-scalar-only: inline drive targets,
  aggregate operands inside inline drive RHS expressions, and subaggregate RHS
  values remain separate contracts until the follow-on expression slice.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.38` widens inline drive aggregate
  support from direct scalar RHS values to scalar operands inside inline drive
  RHS expressions. This mirrors the enum inline drive expression and aggregate
  drive-body expression policies while keeping inline drive targets,
  operator-position aggregate paths, and subaggregate operands rejected.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.39` selects transaction `switch`
  branch aggregate leaf values because branch values are scalar scheduled
  `.fsm` review tokens like the earlier enum switch branch slice. This keeps
  switch selectors and subaggregate branch values closed while allowing
  declared actor-owned aggregate storage leaves to participate in explicit
  switch cases.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.40` selects transaction `switch`
  aggregate leaf selectors because the prior branch-value slice left selector
  reads as the adjacent switch context. Non-HDL-identifier selector paths lower
  through computed `.fsm` selector syntax, preserving reviewability while
  keeping enum switch selectors closed until `.41` and subaggregate selectors
  or branch values closed.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.41` selects transaction `switch`
  enum selectors because enum branch values and aggregate selectors are now
  stable on the same switch lowering path. Dotted enum selectors lower through
  computed `.fsm` selector syntax, while standalone enum conditions and other
  enum target/operator contexts remain closed.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.42` selects rule assignment
  aggregate targets because transaction aggregate leaf writes and rule
  aggregate RHS reads are already stable on the guarded rule-DT path. Explicit
  `(set frame.mode value)` and shorthand `(frame.mode value)` targets now
  resolve against declared actor-owned aggregate storage, while subaggregate
  rule targets and enum rule targets remain closed.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.43` selects named drive body
  aggregate targets because named drive DT assignments already preserve LHS
  tokens, assignment provenance, and strict HDL generation for scalar target
  writes. Scalar aggregate storage leaves such as `frame.mode` and `lanes[1]`
  now resolve as drive body targets, while subaggregate drive targets and
  inline drive targets remain closed.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.44` selects inline drive aggregate
  targets because inline drive state assignments already preserve LHS tokens,
  assignment provenance, and strict HDL generation for scalar target writes.
  Scalar aggregate storage leaves now resolve as inline drive targets, while
  subaggregate inline drive targets remain closed.
- `2026-05-16`: `ISF-TYPE-AGGREGATE-PARITY.45` selects standalone aggregate
  transaction conditions because condition expression operands were already
  stable. Scalar aggregate leaves such as `frame.flag` and `lanes[0]` now
  resolve as direct `when`/`while`/`until` conditions and lower through
  computed `.fsm` selectors, while subaggregate conditions remain closed.

## Open Questions

- Which bounded schedule-report summary keys should advertise accepted
  enum/type declarations? This remains deferred because
  `ISF-TYPE-AGGREGATE-PARITY.3` deliberately shipped with generated `.fsm`
  review artifacts and focused parser/lowering tests rather than schedule
  JSON expansion.
- Which enum member expression/value contexts beyond actor constants, actor
  parameter scalar values or aggregate/list default leaves, generated child
  transaction parameter scalar values or aggregate/list default leaves,
  activation parameter scalar values and aggregate/list override leaves,
  reusable-library use-site parameter override values or leaves,
  transaction `set` RHS scalar
  values/expression operands, transaction `when`/`while`/`until` condition
  expression operands, transaction `switch` branch values, rule guard
  expression operands, rule assignment RHS scalar values/expression operands,
  drive body RHS scalar values/expression operands, inline drive assignment
  RHS scalar values/expression operands, and drive-call scalar actual
  values/expression operands should ship next? This remains deferred beyond
  `ISF-TYPE-AGGREGATE-PARITY.32`.
- Which enum or aggregate value/update context should ship after aggregate
  switch selectors? `ISF-TYPE-AGGREGATE-PARITY.41` shipped enum switch
  selectors.
- Which enum or aggregate value/update context should ship after enum switch
  selectors? `ISF-TYPE-AGGREGATE-PARITY.42` shipped aggregate rule assignment
  targets.
- Which enum or aggregate value/update context should ship after aggregate
  rule targets? `ISF-TYPE-AGGREGATE-PARITY.43` shipped named drive body
  aggregate targets.
- Which enum or aggregate value/update context should ship after aggregate
  named drive targets? `ISF-TYPE-AGGREGATE-PARITY.44` shipped inline drive
  aggregate targets.
- Which enum or aggregate value/update context should ship after aggregate
  inline drive targets? `ISF-TYPE-AGGREGATE-PARITY.45` shipped standalone
  aggregate transaction conditions.
- Which enum or aggregate value/update context should ship after aggregate
  standalone transaction conditions? The current frontier selects this for
  `ISF-TYPE-AGGREGATE-PARITY.46`.

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
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.6` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.7` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.8` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.9` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.10` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.11` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.12` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.13` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.14` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.15` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1253-isf-actor-param-report.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.16` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `prove -Iperl t/1257-isf-scalar-type-aliases.t t/1258-isf-enum-member-constants.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1215-isf-spawn-parameter-binding.t t/1248-isf-rule-trigger-parameter-binding.t t/1249-isf-activation-parameter-constants.t t/1253-isf-actor-param-report.t t/1255-isf-schedule-report-golden-matrix.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.17` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1271-isf-enum-member-activation-params.t t/1249-isf-activation-parameter-constants.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.18` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Pipeline/SourceFrontend.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1272-isf-enum-member-rule-values.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1271-isf-enum-member-activation-params.t t/1221-isf-rule-expression-assignment.t t/1246-isf-setter-syntax.t t/295-strict-mode-infix-assignment-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.19` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1273-isf-enum-member-rule-expression-values.t t/1272-isf-enum-member-rule-values.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1271-isf-enum-member-activation-params.t t/1221-isf-rule-expression-assignment.t t/1246-isf-setter-syntax.t t/295-strict-mode-infix-assignment-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.20` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1274-isf-enum-member-rule-guard-values.t t/1273-isf-enum-member-rule-expression-values.t t/1272-isf-enum-member-rule-values.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1271-isf-enum-member-activation-params.t t/1233-isf-rule-expression-guards.t t/1221-isf-rule-expression-assignment.t t/1246-isf-setter-syntax.t t/295-strict-mode-infix-assignment-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.21` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/37-language-contract-computed-test-selector.t t/55-language-contract-computed-test-selector-boundary.t`; `prove -Iperl t/1275-isf-enum-member-condition-values.t t/1274-isf-enum-member-rule-guard-values.t t/1273-isf-enum-member-rule-expression-values.t t/1272-isf-enum-member-rule-values.t t/1263-isf-enum-member-set-values.t t/1264-isf-enum-member-set-expression-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1271-isf-enum-member-activation-params.t t/1206-isf-when-clause-boundary.t t/1245-isf-transaction-loop-lowering.t t/1233-isf-rule-expression-guards.t t/1221-isf-rule-expression-assignment.t t/1246-isf-setter-syntax.t t/295-strict-mode-infix-assignment-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.22` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1276-isf-enum-member-activation-aggregate-params.t t/1271-isf-enum-member-activation-params.t t/1270-isf-enum-member-transaction-params.t t/1269-isf-enum-member-actor-params.t t/1249-isf-activation-parameter-constants.t t/1215-isf-spawn-parameter-binding.t t/1248-isf-rule-trigger-parameter-binding.t t/1263-isf-enum-member-set-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1272-isf-enum-member-rule-values.t t/1274-isf-enum-member-rule-guard-values.t t/1275-isf-enum-member-condition-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.23` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1277-isf-enum-member-actor-aggregate-params.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1276-isf-enum-member-activation-aggregate-params.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.24` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1278-isf-enum-member-transaction-aggregate-params.t t/1270-isf-enum-member-transaction-params.t t/1277-isf-enum-member-actor-aggregate-params.t t/1269-isf-enum-member-actor-params.t t/1276-isf-enum-member-activation-aggregate-params.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.25` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1279-isf-enum-member-inline-drive-values.t t/1267-isf-enum-member-drive-call-values.t t/1266-isf-enum-member-drive-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1263-isf-enum-member-set-values.t t/1265-isf-enum-member-switch-branch-values.t t/1272-isf-enum-member-rule-values.t t/1274-isf-enum-member-rule-guard-values.t t/1275-isf-enum-member-condition-values.t t/1193-isf-drive-call-arity-boundary.t t/1244-isf-wait-clause-lowering.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.26` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1280-isf-enum-member-inline-drive-expression-values.t t/1279-isf-enum-member-inline-drive-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1267-isf-enum-member-drive-call-values.t t/1266-isf-enum-member-drive-values.t t/1263-isf-enum-member-set-values.t t/1265-isf-enum-member-switch-branch-values.t t/1272-isf-enum-member-rule-values.t t/1274-isf-enum-member-rule-guard-values.t t/1275-isf-enum-member-condition-values.t t/1193-isf-drive-call-arity-boundary.t t/1244-isf-wait-clause-lowering.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.27` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1281-isf-enum-member-library-use-params.t t/1280-isf-enum-member-inline-drive-expression-values.t t/1279-isf-enum-member-inline-drive-values.t t/1278-isf-enum-member-transaction-aggregate-params.t t/1277-isf-enum-member-actor-aggregate-params.t t/1276-isf-enum-member-activation-aggregate-params.t t/1271-isf-enum-member-activation-params.t t/1269-isf-enum-member-actor-params.t t/1270-isf-enum-member-transaction-params.t t/1263-isf-enum-member-set-values.t t/1265-isf-enum-member-switch-branch-values.t t/1266-isf-enum-member-drive-values.t t/1272-isf-enum-member-rule-values.t t/1274-isf-enum-member-rule-guard-values.t t/1275-isf-enum-member-condition-values.t t/1230-isf-library-import-resolution.t t/1231-isf-library-generated-top.t t/1237-isf-fifo-library-fixture.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.28` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1282-isf-enum-member-drive-expression-values.t t/1194-isf-drive-body-boundary.t t/1266-isf-enum-member-drive-values.t t/1280-isf-enum-member-inline-drive-expression-values.t t/1279-isf-enum-member-inline-drive-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1267-isf-enum-member-drive-call-values.t t/1263-isf-enum-member-set-values.t t/1265-isf-enum-member-switch-branch-values.t t/1272-isf-enum-member-rule-values.t t/1274-isf-enum-member-rule-guard-values.t t/1275-isf-enum-member-condition-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.29` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1221-isf-rule-expression-assignment.t t/1272-isf-enum-member-rule-values.t t/1273-isf-enum-member-rule-expression-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.30` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1221-isf-rule-expression-assignment.t t/1272-isf-enum-member-rule-values.t t/1273-isf-enum-member-rule-expression-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.31` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1233-isf-rule-expression-guards.t t/1274-isf-enum-member-rule-guard-values.t t/1272-isf-enum-member-rule-values.t t/1273-isf-enum-member-rule-expression-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.32` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1275-isf-enum-member-condition-values.t t/1233-isf-rule-expression-guards.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.33` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1266-isf-enum-member-drive-values.t t/1282-isf-enum-member-drive-expression-values.t t/1194-isf-drive-body-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.34` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1288-isf-aggregate-drive-expression-values.t t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1282-isf-enum-member-drive-expression-values.t t/1266-isf-enum-member-drive-values.t t/1194-isf-drive-body-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.35` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1289-isf-aggregate-drive-call-values.t t/1288-isf-aggregate-drive-expression-values.t t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1267-isf-enum-member-drive-call-values.t t/1268-isf-enum-member-drive-call-expression-values.t t/1193-isf-drive-call-arity-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.36` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1290-isf-aggregate-drive-call-expression-values.t t/1289-isf-aggregate-drive-call-values.t t/1288-isf-aggregate-drive-expression-values.t t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1268-isf-enum-member-drive-call-expression-values.t t/1267-isf-enum-member-drive-call-values.t t/1193-isf-drive-call-arity-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.37` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1291-isf-aggregate-inline-drive-values.t t/1290-isf-aggregate-drive-call-expression-values.t t/1289-isf-aggregate-drive-call-values.t t/1288-isf-aggregate-drive-expression-values.t t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1279-isf-enum-member-inline-drive-values.t t/1280-isf-enum-member-inline-drive-expression-values.t t/1193-isf-drive-call-arity-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.38` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1292-isf-aggregate-inline-drive-expression-values.t t/1291-isf-aggregate-inline-drive-values.t t/1290-isf-aggregate-drive-call-expression-values.t t/1289-isf-aggregate-drive-call-values.t t/1288-isf-aggregate-drive-expression-values.t t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1280-isf-enum-member-inline-drive-expression-values.t t/1279-isf-enum-member-inline-drive-values.t t/1193-isf-drive-call-arity-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.39` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1293-isf-aggregate-switch-branch-values.t t/1292-isf-aggregate-inline-drive-expression-values.t t/1291-isf-aggregate-inline-drive-values.t t/1290-isf-aggregate-drive-call-expression-values.t t/1289-isf-aggregate-drive-call-values.t t/1288-isf-aggregate-drive-expression-values.t t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1265-isf-enum-member-switch-branch-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.40` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1294-isf-aggregate-switch-selector-values.t t/1293-isf-aggregate-switch-branch-values.t t/1292-isf-aggregate-inline-drive-expression-values.t t/1291-isf-aggregate-inline-drive-values.t t/1290-isf-aggregate-drive-call-expression-values.t t/1289-isf-aggregate-drive-call-values.t t/1288-isf-aggregate-drive-expression-values.t t/1287-isf-aggregate-drive-values.t t/1286-isf-aggregate-condition-values.t t/1285-isf-aggregate-rule-guard-values.t t/1284-isf-aggregate-rule-expression-values.t t/1283-isf-aggregate-rule-values.t t/1265-isf-enum-member-switch-branch-values.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t t/37-language-contract-computed-test-selector.t t/55-language-contract-computed-test-selector-boundary.t t/1205-isf-switch-clause-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.41` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1295-isf-enum-member-switch-selector-values.t t/1265-isf-enum-member-switch-branch-values.t t/1294-isf-aggregate-switch-selector-values.t t/1293-isf-aggregate-switch-branch-values.t t/1275-isf-enum-member-condition-values.t t/1263-isf-enum-member-set-values.t t/1266-isf-enum-member-drive-values.t t/1272-isf-enum-member-rule-values.t t/1274-isf-enum-member-rule-guard-values.t t/1279-isf-enum-member-inline-drive-values.t t/37-language-contract-computed-test-selector.t t/55-language-contract-computed-test-selector-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.42` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1296-isf-aggregate-rule-target-values.t t/1283-isf-aggregate-rule-values.t t/1284-isf-aggregate-rule-expression-values.t t/1285-isf-aggregate-rule-guard-values.t t/1261-isf-aggregate-storage-leaf-writes.t t/1272-isf-enum-member-rule-values.t t/1287-isf-aggregate-drive-values.t t/1291-isf-aggregate-inline-drive-values.t t/1246-isf-setter-syntax.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.43` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1297-isf-aggregate-drive-target-values.t t/1287-isf-aggregate-drive-values.t t/1288-isf-aggregate-drive-expression-values.t t/1296-isf-aggregate-rule-target-values.t t/1291-isf-aggregate-inline-drive-values.t t/1261-isf-aggregate-storage-leaf-writes.t t/1285-isf-aggregate-rule-guard-values.t t/1286-isf-aggregate-condition-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.44` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1298-isf-aggregate-inline-drive-target-values.t t/1291-isf-aggregate-inline-drive-values.t t/1292-isf-aggregate-inline-drive-expression-values.t t/1297-isf-aggregate-drive-target-values.t t/1261-isf-aggregate-storage-leaf-writes.t t/1285-isf-aggregate-rule-guard-values.t t/1286-isf-aggregate-condition-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.45` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1299-isf-aggregate-standalone-condition-values.t t/1286-isf-aggregate-condition-values.t t/1261-isf-aggregate-storage-leaf-writes.t t/1285-isf-aggregate-rule-guard-values.t t/1298-isf-aggregate-inline-drive-target-values.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TYPE-AGGREGATE-PARITY.1` | `ISF-TYPE-AGGREGATE-PARITY.1: inventory parity boundary` | `Inventory and first-boundary documentation slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.2` | `ISF-TYPE-AGGREGATE-PARITY.2: specify type source contract` | `Symbol-source and first type-reference contract slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.3` | `ISF-TYPE-AGGREGATE-PARITY.3: ship scalar type aliases` | `Scalar type-alias parser/lowering implementation slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.4` | `ISF-TYPE-AGGREGATE-PARITY.4: support enum constants` | `Actor-constant enum member parser/lowering implementation slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.5` | `ISF-TYPE-AGGREGATE-PARITY.5: ship aggregate storage carriers` | `Actor-owned aggregate storage carrier parser/lowering/report slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.6` | `ISF-TYPE-AGGREGATE-PARITY.6: support aggregate leaf reads` | `Transaction set RHS aggregate leaf read parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.7` | `ISF-TYPE-AGGREGATE-PARITY.7: support aggregate leaf writes` | `Transaction set target aggregate leaf write parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.8` | `ISF-TYPE-AGGREGATE-PARITY.8: support aggregate expression reads` | `Transaction set RHS aggregate leaf expression operand parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.9` | `ISF-TYPE-AGGREGATE-PARITY.9: support enum set values` | `Transaction set RHS scalar enum member parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.10` | `ISF-TYPE-AGGREGATE-PARITY.10: support enum expression operands` | `Transaction set RHS enum member expression operand parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.11` | `ISF-TYPE-AGGREGATE-PARITY.11: support enum switch values` | `Transaction switch branch enum member parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.12` | `ISF-TYPE-AGGREGATE-PARITY.12: support enum drive values` | `Drive body RHS enum member parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.13` | `ISF-TYPE-AGGREGATE-PARITY.13: support enum drive call values` | `Named drive-call scalar actual enum member parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.14` | `ISF-TYPE-AGGREGATE-PARITY.14: support enum drive call expression values` | `Named drive-call actual expression enum member operand parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.15` | `ISF-TYPE-AGGREGATE-PARITY.15: support enum actor params` | `Actor scalar parameter default enum member parser/lowering/report slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.16` | `ISF-TYPE-AGGREGATE-PARITY.16: support enum transaction params` | `Generated child transaction scalar parameter default enum member parser/lowering/report slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.17` | `ISF-TYPE-AGGREGATE-PARITY.17: support enum activation params` | `Scalar activation parameter override enum member parser/lowering/report slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.18` | `ISF-TYPE-AGGREGATE-PARITY.18: support enum rule values` | `Rule assignment RHS scalar enum member parser/lowering/strictness slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.19` | `ISF-TYPE-AGGREGATE-PARITY.19: support enum rule expression values` | `Rule assignment RHS expression enum member operand parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.20` | `ISF-TYPE-AGGREGATE-PARITY.20: support enum rule guards` | `Rule guard expression enum member operand parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.21` | `ISF-TYPE-AGGREGATE-PARITY.21: support enum conditions` | `Transaction condition expression enum member operand parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.22` | `ISF-TYPE-AGGREGATE-PARITY.22: support enum activation aggregate leaves` | `Activation aggregate/list override enum member leaf parser/lowering/report slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.23` | `ISF-TYPE-AGGREGATE-PARITY.23: support enum actor aggregate params` | `Actor aggregate/list parameter default enum member leaf parser/lowering/report slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.24` | `ISF-TYPE-AGGREGATE-PARITY.24: support enum transaction aggregate params` | `Generated child transaction aggregate/list parameter default enum member leaf parser/lowering/report slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.25` | `ISF-TYPE-AGGREGATE-PARITY.25: support enum inline drive values` | `Inline drive assignment RHS scalar enum member parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.26` | `ISF-TYPE-AGGREGATE-PARITY.26: support enum inline drive expressions` | `Inline drive RHS expression enum member operand parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.27` | `ISF-TYPE-AGGREGATE-PARITY.27: support enum library use params` | `Reusable-library use-site parameter override enum member parser/lowering/report slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.28` | `ISF-TYPE-AGGREGATE-PARITY.28: support enum drive expressions` | `Named drive body RHS expression enum member operand parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.29` | `ISF-TYPE-AGGREGATE-PARITY.29: support aggregate rule values` | `Rule assignment RHS aggregate leaf parser/lowering/provenance slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.30` | `ISF-TYPE-AGGREGATE-PARITY.30: support aggregate rule expressions` | `Rule assignment RHS expression aggregate leaf operand parser/lowering/provenance slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.31` | `ISF-TYPE-AGGREGATE-PARITY.31: support aggregate rule guards` | `Rule guard expression aggregate leaf operand parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.32` | `ISF-TYPE-AGGREGATE-PARITY.32: support aggregate conditions` | `Transaction condition expression aggregate leaf operand parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.33` | `ISF-TYPE-AGGREGATE-PARITY.33: support aggregate drive values` | `Named drive body RHS aggregate leaf parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.34` | `ISF-TYPE-AGGREGATE-PARITY.34: support aggregate drive expressions` | `Named drive body RHS expression aggregate leaf operand parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.35` | `ISF-TYPE-AGGREGATE-PARITY.35: support aggregate drive-call values` | `Named drive-call actual aggregate leaf parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.36` | `ISF-TYPE-AGGREGATE-PARITY.36: support aggregate drive-call expressions` | `Named drive-call actual expression aggregate leaf operand parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.37` | `ISF-TYPE-AGGREGATE-PARITY.37: support aggregate inline drive values` | `Inline drive assignment RHS aggregate leaf parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.38` | `ISF-TYPE-AGGREGATE-PARITY.38: support aggregate inline drive expressions` | `Inline drive RHS expression aggregate leaf operand parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.39` | `ISF-TYPE-AGGREGATE-PARITY.39: support aggregate switch values` | `Transaction switch branch aggregate leaf parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.40` | `ISF-TYPE-AGGREGATE-PARITY.40: support aggregate switch selectors` | `Transaction switch selector aggregate leaf parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.41` | `ISF-TYPE-AGGREGATE-PARITY.41: support enum switch selectors` | `Transaction switch selector enum member parser/lowering slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.42` | `ISF-TYPE-AGGREGATE-PARITY.42: support aggregate rule targets` | `Rule assignment target aggregate leaf parser/lowering/provenance slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.43` | `ISF-TYPE-AGGREGATE-PARITY.43: support aggregate drive targets` | `Named drive body target aggregate leaf parser/lowering/provenance slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.44` | `ISF-TYPE-AGGREGATE-PARITY.44: support aggregate inline drive targets` | `Inline drive target aggregate leaf parser/lowering/provenance slice.` |
| `ISF-TYPE-AGGREGATE-PARITY.45` | `ISF-TYPE-AGGREGATE-PARITY.45: support aggregate standalone conditions` | `Standalone transaction condition aggregate leaf parser/lowering slice.` |

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
- `2026-05-16`: Shipped transaction `set` RHS aggregate leaf reads for
  `ISF-TYPE-AGGREGATE-PARITY.6` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.7`.
- `2026-05-16`: Shipped transaction `set` target aggregate leaf writes for
  `ISF-TYPE-AGGREGATE-PARITY.7` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.8`.
- `2026-05-16`: Shipped transaction `set` RHS aggregate leaf expression
  operands for `ISF-TYPE-AGGREGATE-PARITY.8` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.9`.
- `2026-05-16`: Shipped direct transaction `set` RHS scalar enum member
  values for `ISF-TYPE-AGGREGATE-PARITY.9` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.10`.
- `2026-05-16`: Shipped transaction `set` RHS enum member expression operands
  for `ISF-TYPE-AGGREGATE-PARITY.10` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.11`.
- `2026-05-16`: Shipped transaction `switch` branch enum member values for
  `ISF-TYPE-AGGREGATE-PARITY.11` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.12`.
- `2026-05-16`: Shipped scalar drive body RHS enum member values for
  `ISF-TYPE-AGGREGATE-PARITY.12` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.13`.
- `2026-05-16`: Shipped named drive-call scalar actual enum member values for
  `ISF-TYPE-AGGREGATE-PARITY.13` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.14`.
- `2026-05-16`: Shipped named drive-call actual expression enum member
  operands for `ISF-TYPE-AGGREGATE-PARITY.14` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.15`.
- `2026-05-16`: Shipped actor scalar parameter default enum member values for
  `ISF-TYPE-AGGREGATE-PARITY.15` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.16`.
- `2026-05-16`: Shipped generated child transaction scalar parameter default
  enum member values for `ISF-TYPE-AGGREGATE-PARITY.16` and advanced the
  frontier to `ISF-TYPE-AGGREGATE-PARITY.17`.
- `2026-05-16`: Shipped scalar activation parameter override enum member values
  for `ISF-TYPE-AGGREGATE-PARITY.17` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.18`.
- `2026-05-16`: Shipped scalar rule assignment RHS enum member values for
  `ISF-TYPE-AGGREGATE-PARITY.18` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.19`.
- `2026-05-16`: Shipped rule assignment RHS enum member expression operands for
  `ISF-TYPE-AGGREGATE-PARITY.19` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.20`.
- `2026-05-16`: Shipped rule guard expression enum member operands for
  `ISF-TYPE-AGGREGATE-PARITY.20` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.21`.
- `2026-05-16`: Shipped transaction condition expression enum member operands
  for `ISF-TYPE-AGGREGATE-PARITY.21` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.22`.
- `2026-05-16`: Shipped activation aggregate/list override enum member leaves
  for `ISF-TYPE-AGGREGATE-PARITY.22` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.23`.
- `2026-05-16`: Shipped actor aggregate/list parameter default enum member
  leaves for `ISF-TYPE-AGGREGATE-PARITY.23` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.24`.
- `2026-05-16`: Shipped generated child transaction aggregate/list parameter
  default enum member leaves for `ISF-TYPE-AGGREGATE-PARITY.24` and advanced
  the frontier to `ISF-TYPE-AGGREGATE-PARITY.25`.
- `2026-05-16`: Shipped inline transaction drive assignment RHS scalar enum
  member values for `ISF-TYPE-AGGREGATE-PARITY.25` and advanced the frontier
  to `ISF-TYPE-AGGREGATE-PARITY.26`.
- `2026-05-16`: Shipped inline drive RHS expression enum member operands for
  `ISF-TYPE-AGGREGATE-PARITY.26` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.27`.
- `2026-05-16`: Shipped reusable-library use-site parameter override enum
  member values and leaves for `ISF-TYPE-AGGREGATE-PARITY.27` and advanced the
  frontier to `ISF-TYPE-AGGREGATE-PARITY.28`.
- `2026-05-16`: Shipped named drive body RHS expression enum member operands
  for `ISF-TYPE-AGGREGATE-PARITY.28` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.29`.
- `2026-05-16`: Shipped rule assignment RHS aggregate leaf values for
  `ISF-TYPE-AGGREGATE-PARITY.29` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.30`.
- `2026-05-16`: Shipped rule assignment RHS expression aggregate leaf operands
  for `ISF-TYPE-AGGREGATE-PARITY.30` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.31`.
- `2026-05-16`: Shipped rule guard expression aggregate leaf operands for
  `ISF-TYPE-AGGREGATE-PARITY.31` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.32`.
- `2026-05-16`: Shipped transaction condition expression aggregate leaf
  operands for `ISF-TYPE-AGGREGATE-PARITY.32` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.33`.
- `2026-05-16`: Shipped named drive body RHS aggregate leaf values for
  `ISF-TYPE-AGGREGATE-PARITY.33` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.34`.
- `2026-05-16`: Shipped named drive body RHS expression aggregate leaf operands
  for `ISF-TYPE-AGGREGATE-PARITY.34` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.35`.
- `2026-05-16`: Shipped named drive-call actual aggregate leaf values for
  `ISF-TYPE-AGGREGATE-PARITY.35` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.36`.
- `2026-05-16`: Shipped named drive-call actual expression aggregate leaf
  operands for `ISF-TYPE-AGGREGATE-PARITY.36` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.37`.
- `2026-05-16`: Shipped inline drive assignment RHS aggregate leaf values for
  `ISF-TYPE-AGGREGATE-PARITY.37` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.38`.
- `2026-05-16`: Shipped inline drive RHS expression aggregate leaf operands
  for `ISF-TYPE-AGGREGATE-PARITY.38` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.39`.
- `2026-05-16`: Shipped transaction `switch` branch aggregate leaf values for
  `ISF-TYPE-AGGREGATE-PARITY.39` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.40`.
- `2026-05-16`: Shipped transaction `switch` selector aggregate leaf values
  for `ISF-TYPE-AGGREGATE-PARITY.40` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.41`.
- `2026-05-16`: Shipped transaction `switch` selector enum member values for
  `ISF-TYPE-AGGREGATE-PARITY.41` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.42`.
- `2026-05-16`: Shipped rule assignment target aggregate leaf writes for
  `ISF-TYPE-AGGREGATE-PARITY.42` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.43`.
- `2026-05-16`: Shipped named drive body target aggregate leaf writes for
  `ISF-TYPE-AGGREGATE-PARITY.43` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.44`.
- `2026-05-16`: Shipped inline drive target aggregate leaf writes for
  `ISF-TYPE-AGGREGATE-PARITY.44` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.45`.
- `2026-05-16`: Shipped standalone transaction condition aggregate leaf values
  for `ISF-TYPE-AGGREGATE-PARITY.45` and advanced the frontier to
  `ISF-TYPE-AGGREGATE-PARITY.46`.
