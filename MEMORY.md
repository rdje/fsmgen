# MEMORY
This is the live continuity document for fast session recovery after crashes, restarts, or agent handoffs.
## 2026-04-18: language_surface now has an explicit bounded contract owner too
- Added
  [perl/FSM/Support/LanguageSurfaceContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/LanguageSurfaceContract.pm)
  as the explicit owner for the bounded public contract over the manifest's
  `language_surface` section: public top-level keys plus the first nested
  strict/default/assignments/system/expression/declaration/composition key
  lists.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  now advertises that contract under `language_surface.surface_contract`, and
  [t/297-capability-manifest.t](/Users/richarddje/Documents/github/fsmgen/t/297-capability-manifest.t)
  now also locks the manifest-facing owner plus the advertised bounded
  top-level and strict-mode key lists.
- [t/317-language-surface-contract.t](/Users/richarddje/Documents/github/fsmgen/t/317-language-surface-contract.t)
  now regression-locks the public language-surface promise directly for both
  in-process manifest construction and CLI `--capability-manifest` JSON.
- The reachable `bin/fsmgen` support surface now includes that contract owner
  too, moving the measured import-tree totals to `138` project files /
  `137` `.pm` packages with `Support => 16`.

## 2026-04-18: capability-manifest shell now has an explicit bounded contract owner too
- Added
  [perl/FSM/Support/CapabilityManifestContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifestContract.pm)
  as the explicit owner for the bounded public contract over the top-level
  capability-manifest shell: top-level manifest keys plus the first nested
  producer/diagnostics/semantic-export/backend-validation/embedding/language-surface/documentation keys.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  now advertises that contract under top-level `manifest_contract`, and
  [t/297-capability-manifest.t](/Users/richarddje/Documents/github/fsmgen/t/297-capability-manifest.t)
  now also locks the manifest-shell contract owner plus the advertised
  top-level/producer/section key lists.
- [t/316-capability-manifest-contract.t](/Users/richarddje/Documents/github/fsmgen/t/316-capability-manifest-contract.t)
  now regression-locks the public capability-manifest shell promise directly
  for both in-process manifest construction and CLI `--capability-manifest`
  JSON.
- The reachable `bin/fsmgen` support surface now includes that contract owner
  too, moving the measured import-tree totals to `137` project files /
  `136` `.pm` packages with `Support => 15`.

## 2026-04-18: stable diagnostic-code registry now has an explicit bounded contract owner too
- Added
  [perl/FSM/Support/DiagnosticCodeRegistryContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DiagnosticCodeRegistryContract.pm)
  as the explicit owner for the bounded public contract over the manifest-facing
  stable diagnostic-code registry: public diagnostics sibling keys, stable-code
  entry keys, bounded diagnostic families, and defensive-copy expectations.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  already exposed the stable registry through `diagnostics`, and
  [t/297-capability-manifest.t](/Users/richarddje/Documents/github/fsmgen/t/297-capability-manifest.t)
  now also locks the manifest-facing registry contract owner plus the advertised
  bounded sibling and entry key lists.
- [t/315-diagnostic-code-registry-contract.t](/Users/richarddje/Documents/github/fsmgen/t/315-diagnostic-code-registry-contract.t)
  now regression-locks the public stable-registry promise directly for both
  in-process manifest construction and CLI `--capability-manifest` JSON.
- The reachable `bin/fsmgen` support surface now includes that contract owner
  too, moving the measured import-tree totals to `136` project files /
  `135` `.pm` packages with `Support => 14`.

## 2026-04-18: support accounting now has an explicit bounded contract owner too
- Added
  [perl/FSM/Support/SupportAccountingContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/SupportAccountingContract.pm)
  as the explicit owner for the bounded public contract over the manifest's
  `support_accounting` section: top-level keys, bucket keys, id-list keys, and
  sanitized catalog-entry keys.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  now advertises that contract directly instead of leaving the
  `support_accounting` section as an inline public payload, and
  [t/297-capability-manifest.t](/Users/richarddje/Documents/github/fsmgen/t/297-capability-manifest.t)
  now locks that manifest-facing owner plus the advertised bounded key lists.
- [t/314-support-accounting-contract.t](/Users/richarddje/Documents/github/fsmgen/t/314-support-accounting-contract.t)
  now regression-locks the public support-accounting promise directly for both
  in-process manifest construction and CLI `--capability-manifest` JSON.
- The reachable `bin/fsmgen` support surface now includes that contract owner
  too, moving the measured import-tree totals to `135` project files /
  `134` `.pm` packages with `Support => 13`.

## 2026-04-18: external HDL validation now has an explicit bounded contract owner too
- Added
  [perl/FSM/Support/HDLExternalValidationContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLExternalValidationContract.pm)
  as the explicit owner for the bounded external validation promise: command
  shape, tool identities, stage names, bounded success top-level keys, and
  bounded step keys/order.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  now advertises that contract directly instead of describing the external
  validation lane inline, and
  [t/297-capability-manifest.t](/Users/richarddje/Documents/github/fsmgen/t/297-capability-manifest.t)
  now locks that manifest-facing owner plus the advertised bounded key lists.
- [t/313-hdl-external-validation-contract.t](/Users/richarddje/Documents/github/fsmgen/t/313-hdl-external-validation-contract.t)
  now regression-locks the public external validation promise directly for the
  in-process success result on a minimal temporary SystemVerilog module when
  Verilator and Yosys are installed.
- The reachable `bin/fsmgen` support surface now includes that contract owner
  too, moving the measured import-tree totals to `134` project files /
  `133` `.pm` packages with `Support => 12`.

## 2026-04-18: check JSON now has an explicit bounded contract owner too
- Added
  [perl/FSM/Support/CheckDiagnosticsContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CheckDiagnosticsContract.pm)
  as the explicit owner for the bounded `--check --json` public promise:
  common top-level keys, success-only top-level keys, bounded success-result
  keys, bounded success support-accounting keys, and bounded failure-diagnostic
  keys.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  now advertises that contract directly instead of describing the check-JSON
  surface inline, and
  [t/297-capability-manifest.t](/Users/richarddje/Documents/github/fsmgen/t/297-capability-manifest.t)
  now locks that manifest-facing owner plus the advertised bounded key lists.
- [t/312-check-diagnostics-contract.t](/Users/richarddje/Documents/github/fsmgen/t/312-check-diagnostics-contract.t)
  now regression-locks the public check-JSON promise directly for ad-hoc
  success, corpus-backed composition success, and matched failure diagnostics.
- The reachable `bin/fsmgen` support surface now includes that contract owner
  too, moving the measured import-tree totals to `133` project files /
  `132` `.pm` packages with `Support => 11`.

## 2026-04-18: normalized semantic JSON now has an explicit bounded contract owner
- Added
  [perl/FSM/Support/NormalizedSemanticReportContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticReportContract.pm)
  as the explicit owner for the bounded normalized semantic JSON key-presence
  contract.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  now advertises that contract directly instead of only describing the semantic
  export surface inline, and
  [t/297-capability-manifest.t](/Users/richarddje/Documents/github/fsmgen/t/297-capability-manifest.t)
  now locks that manifest-facing owner plus the advertised bounded key lists.
- [t/311-normalized-semantic-report-contract.t](/Users/richarddje/Documents/github/fsmgen/t/311-normalized-semantic-report-contract.t)
  now regression-locks the public normalized semantic JSON promise directly:
  top-level key presence, bounded nested success key presence, bounded
  composition key presence, and the rule that rejected reports expose no
  partial `semantic` payload.
- The reachable `bin/fsmgen` support surface now includes that contract owner
  too, moving the measured import-tree totals to `132` project files /
  `131` `.pm` packages with `Support => 10`.

## 2026-04-18: README bootstrap pass refreshed the saved import-tree measurements
- Re-executed the [README.md](/Users/richarddje/Documents/github/fsmgen/README.md) /
  [SESSION_BOOTSTRAP.md](/Users/richarddje/Documents/github/fsmgen/SESSION_BOOTSTRAP.md)
  startup ritual and re-checked the current [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen)
  runtime spine against [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md).
- The qualitative architecture picture and the static reachable totals remain
  unchanged at `131` project files / `130` reachable `.pm` packages, with the
  same unique family counts recorded in the note (`Composition 35`, `HDL 32`,
  `Package 14`, `Support 9`, `Synthesis 10`, `IR 7`, `Adapter 5`, `Pipeline 5`,
  `Extension 3`, `Backend 3`, `AST 1` plus the singleton surfaces).
- The saved measured line counts for a few high-traffic files had drifted, so
  [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md)
  now reflects the current `288`-line
  [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm),
  `178`-line
  [perl/FSM/Support/HDLExternalValidation.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLExternalValidation.pm),
  `685`-line
  [perl/FSM/Support/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/RegressionCorpus.pm),
  `3455`-line
  [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm),
  `2208`-line [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm),
  and `1827`-line
  [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm).

## 2026-04-18: agent workflow copy is now a thin pointer, not a second policy copy
- [.agents/workflows/commit.md](/Users/richarddje/Documents/github/fsmgen/.agents/workflows/commit.md)
  no longer repeats the full commit workflow. It now explicitly says that
  [COMMIT.md](/Users/richarddje/Documents/github/fsmgen/COMMIT.md) is the only
  authoritative source and that the agent-side file is just a thin wrapper.
- [COMMIT.md](/Users/richarddje/Documents/github/fsmgen/COMMIT.md) now also
  names that relationship directly so future sessions do not accidentally let
  the helper copy drift into an independent policy source.

## 2026-04-18: commit workflow is now reinforced as a hard recovery invariant
- [README.md](/Users/richarddje/Documents/github/fsmgen/README.md),
  [COMMIT.md](/Users/richarddje/Documents/github/fsmgen/COMMIT.md),
  [SESSION_BOOTSTRAP.md](/Users/richarddje/Documents/github/fsmgen/SESSION_BOOTSTRAP.md),
  and [.agents/workflows/commit.md](/Users/richarddje/Documents/github/fsmgen/.agents/workflows/commit.md)
  now all say the same thing explicitly: one completed task/activity must be
  closed with the full commit workflow before any new slice starts.
- The rationale is now stated in the docs, not left implicit: task-scoped
  commits are the repository's crash-recovery and handoff mechanism, so
  skipping the workflow is a project-safety failure rather than a minor
  process lapse.
- The docs also now tell future sessions what to do if the rule is violated:
  stop new work, recover the mixed state into the smallest honest validated
  commits, and only then resume implementation.

## 2026-04-18: commit workflow no longer conflicts with the no-trailer policy
- [COMMIT.md](/Users/richarddje/Documents/github/fsmgen/COMMIT.md)
  no longer carries the stale contradictory rule that AI-created commits must
  include a co-author trailer. The workflow now explicitly matches the live
  repository policy: no `Co-Authored-By` or similar attribution trailer unless
  the user explicitly asks for one.

## 2026-04-18: user docs now show concrete composition intent-literal actuals
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md)
  now includes one explicit `?toplink` example showing intent-sized literal
  direct actuals and concat actuals together, including `/=5'23/.../`,
  `/=8'-0xA/.../`, and `/=5'23,=8'-10,=20'x1/.../`, plus pointers to the
  maintained corpus fixtures that lock those spellings.
- [docs/book/src/06-composition-advanced.md](/Users/richarddje/Documents/github/fsmgen/docs/book/src/06-composition-advanced.md)
  now mirrors that example in the book so composition users can discover the
  feature from the narrative docs instead of only from tests or release notes.

## 2026-04-18: intent-sized literals are now part of the maintained support corpus
- [perl/FSM/Support/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/RegressionCorpus.pm)
  now promotes intent-level integer literal support into the named supported
  corpus on both direct and composition paths:
  `feature.direct_intent_integer_literals` points at
  [t/corpus/direct_intent_integer_literals.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_intent_integer_literals.fsm),
  and `feature.composition_intent_integer_literals` points at
  [t/corpus/composition_intent_integer_literals.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/composition_intent_integer_literals.fsm).
- [t/261-regression-corpus-supported-language-features.t](/Users/richarddje/Documents/github/fsmgen/t/261-regression-corpus-supported-language-features.t)
  now runs both direct and composition `language_feature_fixture`
  `supported_smoke` entries through pipeline and CLI, including composition
  plan assertions where applicable, and also re-runs the same maintained
  feature family through strict pipeline and strict CLI when the entry is
  `strict_supported`.
- [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
  now expects sixteen supported-smoke entries and sixteen strict-supported
  entries, while allowing self-contained composition fixtures to record an
  empty `expected_child_modules` array when the supported surface is a wrapper
  over embedded `?rtlif` rather than a generated child module.

## 2026-04-18: composition intent-sized actuals now have pipeline/CLI coverage too
- [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t)
  now drives intent-sized exact-width direct actuals such as `=5'23`,
  `=8'-10`, `=8'-0b1010`, `=8'-0xA`, and `=20'x1` through the real
  composition pipeline and CLI, locking both top-output assignments and child
  input bindings.
- [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t)
  now drives those same intent-sized exact-width literal families through the
  concat-operand lane end to end, proving declared-width preservation,
  two-complement lowering, and zero synthetic-carrier emission on the C3 path.

## 2026-04-18: composition actuals now accept intent-sized exact-width literals
- [perl/FSM/Composition/ActualLiteralSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ActualLiteralSupport.pm)
  now accepts FSMGen intent-sized exact-width literal spellings on both direct
  actual and concat-operand lanes, reusing the shared integer-literal frontend
  for forms such as `=5'23`, `=8'-10`, `=8'-0xA`, `=8'-0b1010`, and `=20'x1`.
- This is intentionally implemented as a fallback after the existing
  composition-only exact-width SV forms, so current `=8'b...` / `=8'sd...`
  validation behavior stays intact while the intent-level spellings gain the
  same checked structural lowering.
- [t/286-composition-actual-literal-support.t](/Users/richarddje/Documents/github/fsmgen/t/286-composition-actual-literal-support.t)
  now locks direct and concat coverage for those intent-sized exact-width
  composition actuals.

## 2026-04-18: composition actual literals now share the ambiguous-bitstring guard
- [perl/FSM/Composition/ActualLiteralSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ActualLiteralSupport.pm)
  now reuses the shared literal frontend detector from
  [perl/FSM/Package/IntegerLiteralSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Package/IntegerLiteralSupport.pm)
  so composition direct actuals and concat literal operands reject obviously
  bitstring-like bare `0/1` payloads such as `=00001110` or `=10000000`
  instead of silently classifying them as decimal.
- [perl/FSM/Composition/SourceExpressionSpecSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/SourceExpressionSpecSupport.pm)
  and [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm)
  now thread composition source context through those literal parses so the
  diagnostics stay precise on both direct actual and concat-operand paths.
- Regression coverage:
  [t/286-composition-actual-literal-support.t](/Users/richarddje/Documents/github/fsmgen/t/286-composition-actual-literal-support.t),
  [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t),
  and
  [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t)
  now lock the targeted remediation messages.

## 2026-04-18: trial_1 is explicit again and now sits in the external SV smoke
- [fsm/trial_1.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/trial_1.fsm)
  no longer uses ambiguous bare bitstring-looking value literals for `ob`.
  The four historical values now use explicit `0b...` spellings, which matches
  the new frontend contract that refuses to guess bare `00001110` / `10000000`
  style tokens in value lanes.
- `./bin/fsmgen --quiet --verify-hdl -o /tmp/fsmgen_trial_1_verified.sv fsm/trial_1.fsm`
  now succeeds locally with Verilator and ABC-free Yosys installed.
- [t/308-systemverilog-external-validation.t](/Users/richarddje/Documents/github/fsmgen/t/308-systemverilog-external-validation.t)
  now includes `fsm/trial_1.fsm` in the focused external validation smoke so
  regressions in this historical direct sample stop being catchable only by
  visual inspection or ad hoc manual runs.

## 2026-04-18: value-lane literal frontend now rejects obvious bare bitstrings
- [perl/FSM/Package/IntegerLiteralSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Package/IntegerLiteralSupport.pm)
  now exposes one shared detector for obviously bitstring-like bare value
  literals: multi-digit all-`0/1` tokens with leading zeroes such as
  `00001110`, or dense all-`0/1` tokens of four or more digits such as
  `10000000`.
- That hardening is now enforced before AST/codegen in direct RHS/value lanes:
  [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm)
  rejects ambiguous direct expression literals,
  [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm)
  rejects ambiguous `+constants` / `+enums` scalar values, and
  [perl/FSM/ParameterValueSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ParameterValueSupport.pm)
  rejects the same ambiguous forms in `+params`, `.rtlif` parameter/generic
  defaults, and instance override scalar values.
- The rule is intentionally narrower than positive-width parsing: width slots
  such as `(+size (DATA 10))` still keep existing decimal compatibility, but
  value-bearing lanes no longer guess whether `00001110` or `10000000` meant
  decimal or binary. Authors must now spell those explicitly as `0b...`,
  `N'b...`, or `0d...`.
- Regression coverage:
  [t/40-language-contract-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/40-language-contract-expression-boundary.t),
  [t/51-language-contract-symbol-definition-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/51-language-contract-symbol-definition-boundary.t),
  and
  [t/309-intent-integer-literal-normalization.t](/Users/richarddje/Documents/github/fsmgen/t/309-intent-integer-literal-normalization.t)
  now lock the detector plus the direct-RHS / symbol-value diagnostics.

## 2026-04-18: negated n-ary expression operators now land as valid internal AST/helpers
- [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm)
  now accepts `!&`, `!|`, and `!^` in direct RHS expressions, with word aliases
  `nand`, `nor`, and `xnor`. The frontend lowers them as ordinary AST
  composition: unary `!` over the existing `&`, `|`, or `^` family, rather
  than relying on a late renderer special case.
- The direct backend now treats assignment RHS expressions as first-class
  live-usage and pre-generation-validation inputs:
  [perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm),
  [perl/FSM/Synthesis/EnableGraph/FactorizationPolicySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/FactorizationPolicySupport.pm),
  [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalFilterPolicySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalFilterPolicySupport.pm),
  and
  [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/OperandContractValidationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/OperandContractValidationSupport.pm)
  now keep parser-created helpers when a final RHS still references them and
  fail pre-generation validation if a RHS references an internal helper that is
  declared but never assigned.
- [perl/FSM/IR/IntentHIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIRBuilder.pm)
  now skips intermediate carriers when building generated-child port analysis,
  so parser-created helpers no longer leak into composition wrapper interfaces.
- Regression coverage:
  [t/40-language-contract-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/40-language-contract-expression-boundary.t)
  locks the new operator surface and emitted helper declarations,
  and
  [t/269-systemverilog-operand-contract-validation-support.t](/Users/richarddje/Documents/github/fsmgen/t/269-systemverilog-operand-contract-validation-support.t)
  now proves RHS-only internal-helper holes are rejected before emission.
- `fsm/trial_1.fsm` is no longer blocked on unsupported `!&`; it now generates
  through that expression path. It is not yet ready for
  [t/308-systemverilog-external-validation.t](/Users/richarddje/Documents/github/fsmgen/t/308-systemverilog-external-validation.t),
  because Verilator still reports historical width-truncation warnings on that
  fixture's bare binary-looking literals such as `10000000` / `00001110`
  driving undeclared `ob`.

## 2026-04-18: late selector evidence now widens earlier whole-signal assignments
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm)
  now runs a bounded post-parse fixpoint over simple whole-signal assignment
  edges before interface generation. This lets later exact width evidence from
  selectors/guards flow back to earlier authored assignments.
- Concrete fixed case:
  [fsm/mipicsi2_tester_ctrl.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/mipicsi2_tester_ctrl.fsm)
  used `cnt <- cnt_wait` in `s0`, then later refined `cnt` to 8 bits through
  `?cnt` selectors in `s1`. Previously `cnt_wait` stayed a 1-bit top-level
  input; it now widens to 8 bits before SignalAnalyzer emits the interface.
- [t/310-systemverilog-implicit-width-and-truthiness-hardening.t](/Users/richarddje/Documents/github/fsmgen/t/310-systemverilog-implicit-width-and-truthiness-hardening.t)
  locks the generated HDL shape, and
  [t/308-systemverilog-external-validation.t](/Users/richarddje/Documents/github/fsmgen/t/308-systemverilog-external-validation.t)
  now includes `mipicsi2_tester_ctrl` in the focused Verilator/Yosys smoke.
- Remaining known all-`fsm/` external-validation blockers are now the APB
  composition top, unsupported historical `?define`, malformed/legacy
  composition samples, and `trial_1`'s historical bare binary-looking literal
  width warnings.

## 2026-04-18: enable-graph CoreAST slices stay intact through SV rendering
- [perl/FSM/Synthesis/EnableGraph/ASTSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/ASTSupport.pm)
  now renders `FSM::CoreAST::SignalRef` through its own SystemVerilog method
  before falling back to base-name extraction. This fixes the packet FIFO case
  where `cnt[2:1] != 2'd2` was emitted as `cnt != 2'd2`, creating a false
  Verilator width warning.
- The same owner now classifies explicit CoreAST slice widths for one-bit
  logical operator selection and multibit truthiness lowering, so sliced
  operands stay width-aware before the final HDL text stage.
- [t/208-enable-graph-ast-support.t](/Users/richarddje/Documents/github/fsmgen/t/208-enable-graph-ast-support.t)
  locks direct slice rendering, [t/310-systemverilog-implicit-width-and-truthiness-hardening.t](/Users/richarddje/Documents/github/fsmgen/t/310-systemverilog-implicit-width-and-truthiness-hardening.t)
  locks the generated `fsm/mipicsi2_pkt_nx4B_fifo.fsm` guard, and
  [t/308-systemverilog-external-validation.t](/Users/richarddje/Documents/github/fsmgen/t/308-systemverilog-external-validation.t)
  now includes that MIPI packet FIFO in the focused Verilator/Yosys smoke.
- Remaining all-`fsm/` external-validation blockers still include the APB
  composition top, unsupported historical `?define`, malformed/legacy
  composition samples, `trial_1`'s historical bare binary-looking literal
  width warnings, and the remaining
  MIPI tester-control width cleanup.

## 2026-04-18: Yosys external validation stays ABC-free
- [perl/FSM/Support/HDLExternalValidation.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLExternalValidation.pm)
  now treats Verilator and Yosys as two distinct post-emission gates:
  Verilator checks generated SystemVerilog validity/lint cleanliness, while
  Yosys checks that the same SV can be lowered into structural logic.
- The Yosys script is deliberately `read_verilog -sv -noautowire; synth
  -noabc -top <top>; stat`. Do not add ABC/ABC9 to this lane until a future
  dedicated hardening pass explicitly tackles ABC-specific timeout and mapping
  edge cases.
- [t/308-systemverilog-external-validation.t](/Users/richarddje/Documents/github/fsmgen/t/308-systemverilog-external-validation.t)
  now asserts that the Yosys command includes `synth -noabc` and does not run
  a standalone `abc` / `abc9` pass. The capability manifest also advertises
  `yosys_abc_enabled => false`.

## 2026-04-18: direct protocol external validation is corpus-backed
- [t/308-systemverilog-external-validation.t](/Users/richarddje/Documents/github/fsmgen/t/308-systemverilog-external-validation.t)
  now derives supported direct protocol actors from
  [perl/FSM/Support/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/RegressionCorpus.pm)
  and validates APB requester, APB completer, and AMBA requester with
  Verilator/Yosys when those tools are installed.
- Local all-`fsm/` reconnaissance on 2026-04-18 found these direct passes:
  `amba_requester`, `apb_completer`, `apb_requester`, `lte_dif_pmaster`, most
  MIPI direct samples, and `trial_0`.
- Do not claim the whole `fsm/` tree is external-warning-clean yet. Current
  blockers include `apb_tb` missing generated instance pins,
  `generic_fifo`'s unsupported historical `?define` root,
  malformed/legacy composition samples in `lte_digital_rf` and `trial_2`,
  and `trial_1`'s historical bare binary-looking literal width warnings.

## 2026-04-18: intent scheduling brainstorm log started
- Created [docs/INTENT_SCHEDULING_BRAINSTORM.md](/Users/richarddje/Documents/github/fsmgen/docs/INTENT_SCHEDULING_BRAINSTORM.md)
  as the living git-tracked discussion log for a possible layer above
  cycle-authored `?fsm`.
- The core idea to preserve is that cycles cannot disappear from generated
  SV/VHDL semantics, but cycle choice could become an inferred/scheduled and
  reviewable compiler result rather than the user's primary authoring unit.
- The note preserves the initial Q/A verbatim and tracks early directions such
  as transaction-level intent, handshake/channel semantics, guarded rules,
  latency-insensitive blocks, temporal contracts, explicit schedule reports,
  and the still-open 3-letter extension question.
- Future brainstorming on this topic should append dated sections there rather
  than disappearing into chat history.

## 2026-04-18: AMBA requester now passes external SV validation
- The AMBA `UNOPTFLAT` issue was not a backend rendering quirk. The source was
  using D-input-named `<=` assignments for Q-named state/storage signals, so the
  generated AST/HDL legitimately built next-value feedback loops.
- [fsm/amba_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/amba_requester.fsm)
  now uses `<-` for those Q-named registers. `./bin/fsmgen --quiet
  --verify-hdl -o /tmp/fsmgen_amba_requester_fixed.sv fsm/amba_requester.fsm`
  passes locally with Verilator/Yosys installed.
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm)
  now rejects D-input self-dependency for `<=` / `<=+` when the RHS or guard
  reads the same LHS name. Use `<-` for ordinary Q/output feedback, or `<=+`
  with the generated `_r` mirror when dual D/Q visibility is intentional.
- [t/02-combinational-self-dependency.t](/Users/richarddje/Documents/github/fsmgen/t/02-combinational-self-dependency.t)
  locks the pre-generation guard, [t/308-systemverilog-external-validation.t](/Users/richarddje/Documents/github/fsmgen/t/308-systemverilog-external-validation.t)
  now includes AMBA in the optional Verilator/Yosys smoke, and
  [t/310-systemverilog-implicit-width-and-truthiness-hardening.t](/Users/richarddje/Documents/github/fsmgen/t/310-systemverilog-implicit-width-and-truthiness-hardening.t)
  now checks the Q-style `_next` helper text for AMBA arithmetic grouping.

## 2026-04-18: CoreAST/SV arithmetic grouping is preserved
- Fixed a generated-SystemVerilog arithmetic rendering bug where right-nested
  same-precedence expressions could be flattened into different target
  semantics. The concrete AMBA case was `(% addr_q (* beats_total_q
  addr_step_q))`, which must emit as `addr_q % (beats_total_q * addr_step_q)`,
  not `addr_q % beats_total_q * addr_step_q`.
- [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm)
  now registers symbolic arithmetic operators with precedence/associativity
  metadata, treats BinaryOp precedence as optional for public calls, and only
  forwards precedence to nested BinaryOp children.
- [perl/FSM/Synthesis/EnableGraph/ASTSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/ASTSupport.pm)
  now applies the same right-child grouping rule on the enable-graph rendering
  path.
- [t/208-enable-graph-ast-support.t](/Users/richarddje/Documents/github/fsmgen/t/208-enable-graph-ast-support.t)
  locks direct renderer behavior, and
  [t/310-systemverilog-implicit-width-and-truthiness-hardening.t](/Users/richarddje/Documents/github/fsmgen/t/310-systemverilog-implicit-width-and-truthiness-hardening.t)
  locks the generated AMBA text.
- `./bin/fsmgen --quiet --verify-hdl -o /tmp/fsmgen_amba_requester_pnt_coreassoc4.sv fsm/amba_requester.fsm`
  no longer reports the previous `WIDTHEXPAND` modulo/division warnings. The
  later Q-named register-source fix above also removes the remaining
  `UNOPTFLAT` feedback warnings and adds AMBA to the warning-clean external
  validation smoke set.

## 2026-04-18: generated SV width/truthiness hardening widened external validation
- Direct parsing now infers missing widths from exact authored evidence:
  static slices/indexes, explicit-width guard comparisons, and explicit test
  selectors. This fixed `fsm/mipicsi2_byteserial.fsm` (`fifout[31:24]`,
  `bytept=2'...`) and `fsm/mipicsi2_txtimer.fsm` (`20'x1` timer guards)
  without requiring manual `+size` clutter in those legacy examples.
- Flattened one-bit enable expressions now render multibit truthiness as
  reduction predicates, for example `(|COUNT)` and `(~|bytept)`, instead of
  relying on warning-prone `COUNT` / `!bytept` inside bitwise enable trees.
- Pure `FSM::AST` arithmetic intermediate widths now recover operand widths
  from assignment analysis. The AMBA requester now declares
  `addr_q_plus_addr_step_q` as `wire [31:0]` instead of `wire`.
- [t/310-systemverilog-implicit-width-and-truthiness-hardening.t](/Users/richarddje/Documents/github/fsmgen/t/310-systemverilog-implicit-width-and-truthiness-hardening.t)
  locks the direct HDL text contract, and
  [t/308-systemverilog-external-validation.t](/Users/richarddje/Documents/github/fsmgen/t/308-systemverilog-external-validation.t)
  now validates `lte_dif_pmaster`, `mipicsi2_byteserial`,
  `mipicsi2_pkt_nx4B_fifo`, `mipicsi2_tester_ctrl`, and `mipicsi2_txtimer`
  with Verilator/Yosys when installed.
- Remaining known hardening:
  - Broader all-`fsm/` external validation is still not claimed, but
    `fsm/amba_requester.fsm` itself is now covered by the focused external
    validation smoke.

## 2026-04-18: intent-level sized integer literals normalize before SV emission
- [perl/FSM/Package/IntegerLiteralSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Package/IntegerLiteralSupport.pm)
  now accepts `.fsm` intent-level sized values such as `5'23`, `8'-10`,
  `8'-0xA`, `8'-0b1010`, and `20'x1`.
- Those forms are not emitted verbatim. They normalize to legal target-HDL
  literals before SystemVerilog generation, for example `5'd23`, `8'd246`,
  `8'hF6`, `8'b11110110`, and `20'h1`.
- The negative spelling decision is `8'-10` rather than `-8'10`, because the
  width is part of the value in `.fsm`; the backend lowers negative sized values
  as checked two's-complement bit patterns.
- [t/309-intent-integer-literal-normalization.t](/Users/richarddje/Documents/github/fsmgen/t/309-intent-integer-literal-normalization.t)
  and [t/corpus/direct_intent_integer_literals.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_intent_integer_literals.fsm)
  lock parser/helper/expression/generation coverage.
- Continuity note:
  - keep the invariant crisp: `.fsm` may be intent-level and friendlier than
    SV/VHDL, but generated HDL must be valid target language text or generation
    must fail before acceptance.

## 2026-04-18: Verilator/Yosys SystemVerilog validation lane landed
- Added [perl/FSM/Support/HDLExternalValidation.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLExternalValidation.pm)
  and wired `bin/fsmgen --verify-hdl` / `--validate-hdl` for generated
  SystemVerilog.
- The CLI writes the `.sv` file first, then runs Verilator
  `--lint-only --sv` and ABC-free Yosys structural synthesis through the
  support module.
- The first external probe on `fsm/lte_dif_pmaster.fsm` caught implicit enable
  wires and multi-bit reset assignments using `1'b0`; the backend now declares
  generated enable nets explicitly and sizes common reset literals to the LHS
  width before emitting flop resets.
- [t/308-systemverilog-external-validation.t](/Users/richarddje/Documents/github/fsmgen/t/308-systemverilog-external-validation.t)
  validates `lte_dif_pmaster`, `mipicsi2_byteserial`,
  `mipicsi2_pkt_nx4B_fifo`, `mipicsi2_tester_ctrl`, and `mipicsi2_txtimer`
  with both external tools when installed and skips otherwise.
- Broader local reconnaissance over active `fsm/*.fsm` samples found additional
  follow-up backend issues in some legacy/sample generated files. The malformed
  sized-literal syntax family (`2'3` / `20'x1`) is now normalized before
  emission, MIPI missing-width/truthiness issues are fixed, and one AMBA
  arithmetic intermediate width-loss issue is fixed. The AMBA modulo/product
  grouping issue and Q-named register feedback issue are fixed too, so AMBA is
  now in the focused external gate. Keep the current external gate documented as
  a focused smoke until the remaining historical/sample families are audited.
- Continuity note:
  - keep Verilator/Yosys as post-emission backend gates; do not weaken or
    replace FSMGen's internal semantic/pre-generation validation with external
    lint/synthesis checks.
  - VHDL/GHDL validation should wait until the VHDL backend exists.

## 2026-04-18: composition report contract is serializable through semantic JSON
- Continued `R13` public embedding/API stabilization by adding
  [perl/FSM/Support/CompositionReportContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CompositionReportContract.pm).
- The new contract is intentionally bounded:
  - raw `HDLGenerator` composition results may still contain live
    `composition_plan` objects and raw `composition_report` branches,
  - raw `composition_report` is not promised JSON-safe,
  - the sanitized public fragment is exported as
    `semantic.composition.provenance_report` through normalized semantic JSON,
  - and nested report content remains deliberately narrower than a frozen full
    plan API.
- [t/307-composition-report-contract.t](/Users/richarddje/Documents/github/fsmgen/t/307-composition-report-contract.t)
  now proves the raw APB composition report fails normal JSON encoding, the
  sanitized report has only declared top-level report keys, and
  `--emit-semantic-json` exposes the sanitized report fragment.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  now exposes this contract under `embedding.composition_report`.
- Continuity note:
  - future composition plan/report widening should promote explicit
    scalar/list/hash report facts instead of exposing live plan objects.

## 2026-04-17: typed extension contract is manifest-backed
- Continued `R13` public embedding/API stabilization by adding
  [perl/FSM/Support/ExtensionContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ExtensionContract.pm).
- The new contract is intentionally bounded:
  - extension loading is explicit through `extensions => [ $object ]`,
    `extension_modules => [ "Module::Name" ]`, `extension_config_files => [ ... ]`,
    `--extension-module`, or `--extension-config`,
  - the current shipped hooks are `after_parse_source($context)` and
    `after_generate_result($context)`,
  - the stable context accessor names are `stage`, `pipeline`, `source_path`,
    `target_language`, `source_info`, `raw_ast`, and `result`,
  - and legacy `.plg` discovery, automatic directory discovery, and `AUTOLOAD`
    hook dispatch remain explicitly out of the contract.
- [t/306-extension-contract.t](/Users/richarddje/Documents/github/fsmgen/t/306-extension-contract.t)
  now verifies the contract module, implementation-class hook/accessor
  availability, and live direct/composition hook contexts.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  now exposes this contract under `embedding.typed_extensions`.
- Continuity note:
  - future hook widening should add a new support-backed contract slice only
    after the target pipeline seam is stable enough to regression-lock.

## 2026-04-17: HDLGenerator result contract is manifest-backed
- Continued `R13` public embedding/API stabilization by adding
  [perl/FSM/Support/HDLGeneratorResultContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLGeneratorResultContract.pm).
- The new contract is intentionally bounded:
  - `FSM::Pipeline::HDLGenerator->generate_hdl_from_file(...)` has a stable
    top-level result-key presence contract,
  - the whole result hash is not promised JSON-safe,
  - nested content is not fully frozen,
  - and live/raw/unsanitized keys such as `fsm_module`, `raw_ast`,
    `composition_plan`, `composition_spec`, `composition_report`,
    `statistics`, `module_info`, `intent_hir`, and `source_info` are explicitly
    classified.
- [t/305-hdl-generator-result-contract.t](/Users/richarddje/Documents/github/fsmgen/t/305-hdl-generator-result-contract.t)
  now verifies direct-root and composition-root result shapes, fails on
  undeclared top-level keys, and checks the expected public projection mirrors.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  now exposes this result contract under `embedding.hdl_generator_result`.
- Continuity note:
  - embedders can use `HDLGenerator` for in-process integration, but JSON
    consumers should use bounded normalized semantic JSON rather than
    serializing raw pipeline results.

## 2026-04-17: normalized semantic JSON expected-failure coverage landed
- Continued `R13` semantic export stabilization by adding
  [t/304-normalized-semantic-json-regression-corpus.t](/Users/richarddje/Documents/github/fsmgen/t/304-normalized-semantic-json-regression-corpus.t).
- Every current `expected_failure` entry in
  [perl/FSM/Support/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/RegressionCorpus.pm)
  now has `--emit-semantic-json` failure coverage: the command must reject,
  emit decodable failure JSON, keep stderr clean, write no HDL even with `-o`,
  omit partial `semantic`, `hdl_code`, and `raw_ast` payloads, and report the
  exact stable diagnostic code plus matched support-accounting entry promised
  by the corpus.
- The semantic failure test mirrors the check-JSON strict/default routing rules
  from [t/300-check-json-regression-corpus.t](/Users/richarddje/Documents/github/fsmgen/t/300-check-json-regression-corpus.t),
  so strict-rejection buckets run with `--strict` and non-strict language /
  composition expected-failure buckets run in default mode.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  now advertises supported-smoke, strict-supported, and expected-failure corpus
  coverage for the bounded normalized semantic JSON surface.

## 2026-04-17: normalized semantic JSON supported corpus coverage landed
- Continued `R13` semantic export stabilization by adding
  [t/303-normalized-semantic-json-supported-corpus.t](/Users/richarddje/Documents/github/fsmgen/t/303-normalized-semantic-json-supported-corpus.t).
- Every current `supported_smoke` entry in
  [perl/FSM/Support/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/RegressionCorpus.pm)
  now has default `--emit-semantic-json` CLI coverage: the command must
  succeed, emit decodable semantic JSON, keep stderr clean, write no HDL even
  with `-o`, preserve matched support-accounting identity, and expose the
  expected module/top identity through `semantic.module`, `intent_hir`, and
  `structural_rtl_ir`.
- Every current `strict_supported` entry now has matching
  `--strict --emit-semantic-json` coverage.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  now advertises supported-smoke and strict-supported corpus coverage for the
  bounded normalized semantic JSON surface.
- Continuity note:
  - the semantic export remains bounded; future widening should add explicit,
    sanitized, support-accounted fields rather than dumping private runtime
    structures.

## 2026-04-17: bounded normalized semantic JSON export landed
- Continued the `R13` public embedding/API lane by adding
  [perl/FSM/Support/NormalizedSemanticReport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticReport.pm).
- [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now accepts
  `--emit-semantic-json` / `--semantic-json` and emits
  `normalized_semantic_schema_version: 1` JSON without writing HDL, even when
  `-o` is present.
- Successful reports expose a bounded `semantic` payload with module/root
  metadata, system/reset contract metadata, sanitized signal analysis,
  `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir`. The sanitizer strips
  private live Perl objects such as `FSM::CoreAST::Signal`, and the report does
  not expose raw ASTs or generated HDL text.
- Failed semantic exports reuse the stable diagnostic/support-accounting bridge
  from check JSON and do not expose partial semantics.
- [t/302-normalized-semantic-json.t](/Users/richarddje/Documents/github/fsmgen/t/302-normalized-semantic-json.t)
  locks ad-hoc success, alias success, strict rejected-source diagnostics,
  no-HDL emission, direct corpus support accounting, and composition corpus
  support accounting.
- Continuity note:
  - keep future semantic JSON widening tied to fields that are sanitized,
    regression-backed, and support-accounted; do not dump private Perl runtime
    structures as a shortcut.

## 2026-04-17: check JSON success support-accounting bridge landed
- Continued `R13` check-JSON stabilization by adding a report-level
  `support_accounting` object to successful check reports.
- [perl/FSM/Support/CheckDiagnostics.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CheckDiagnostics.pm)
  now matches successful sources by resolved path against non-failure entries
  from [perl/FSM/Support/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/RegressionCorpus.pm).
- [t/301-check-json-supported-corpus.t](/Users/richarddje/Documents/github/fsmgen/t/301-check-json-supported-corpus.t)
  now proves every current supported-smoke / strict-supported success reports
  the exact matched entry id, family, coverage, classification, source kind,
  and `strict_supported` marker.
- [t/299-check-json-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/299-check-json-diagnostics.t)
  keeps the ad-hoc success contract honest by requiring `matched: false`.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  now advertises the success support-accounting object and path-based success
  match policy.

## 2026-04-17: check JSON supported corpus coverage landed
- Continued `R13` check-diagnostic stabilization by adding
  [t/301-check-json-supported-corpus.t](/Users/richarddje/Documents/github/fsmgen/t/301-check-json-supported-corpus.t).
- Every current `supported_smoke` entry in
  [perl/FSM/Support/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/RegressionCorpus.pm)
  now has default `--check-json` CLI coverage: the command must succeed, emit
  decodable success JSON, keep stderr clean, write no HDL even with `-o`, and
  report the expected module/top identity.
- Every current `strict_supported` entry now has matching
  `--strict --check-json` coverage.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  now advertises supported-smoke, strict-supported, and expected-failure
  check-JSON corpus coverage in the bounded `diagnostics.check_json` contract.

## 2026-04-17: check JSON expected-failure corpus coverage landed
- Continued `R13` check-diagnostic stabilization by adding
  [t/300-check-json-regression-corpus.t](/Users/richarddje/Documents/github/fsmgen/t/300-check-json-regression-corpus.t).
- Every current `expected_failure` entry in
  [perl/FSM/Support/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/RegressionCorpus.pm)
  now has check-JSON CLI coverage: the command must reject, emit decodable JSON,
  write no HDL, and report the exact stable code plus matched corpus entry.
- [perl/FSM/Support/CheckDiagnostics.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CheckDiagnostics.pm)
  now prefers the most specific matching expected-failure regex, fixing the
  broad-pattern shadowing issue where generic `+size` or legacy-root patterns
  could claim a failure that had a narrower stable code.
- Failed check-JSON diagnostics now include a nested `support_accounting` object
  for matched failures. This is the preferred machine-readable bridge back to
  corpus truth; keep future check JSON widening tied to fields that can be
  support-accounted and regression-locked.

## 2026-04-17: bounded check JSON diagnostics shipped
- Continued the SPECFORGE-facing `R13` bridge by adding
  [perl/FSM/Support/CheckDiagnostics.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CheckDiagnostics.pm).
- [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now accepts
  `--check --json` and `--check-json`, runs the full pipeline without writing
  HDL, emits schema-versioned JSON to stdout, and exits non-zero on failed
  checks.
- Matched expected-failure diagnostics carry stable `FSMGEN_*` code metadata
  from [perl/FSM/Support/DiagnosticCodes.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DiagnosticCodes.pm)
  plus the matched support-accounting entry. Unclassified failures keep a
  `null` code until their family is deliberately promoted.
- Added [t/299-check-json-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/299-check-json-diagnostics.t)
  and widened [t/297-capability-manifest.t](/Users/richarddje/Documents/github/fsmgen/t/297-capability-manifest.t)
  so the command contract is locked and advertised in the capability manifest.
- Continuity note:
  - future check JSON widening still must be backed by support-accounting truth,
  - normalized semantic JSON is a separate surface; the first bounded slice has
    since shipped and should widen only through sanitized public projections.

## 2026-04-17: stable diagnostic-code registry shipped
- Continued the SPECFORGE-facing `R13` bridge by adding
  [perl/FSM/Support/DiagnosticCodes.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DiagnosticCodes.pm).
- Every current `expected_failure` support-accounting entry now carries a
  stable `FSMGEN_*` code, and
  [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
  verifies that each code is known and has stable error-severity metadata.
- [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  now exposes the registry plus entry-level diagnostic codes. Bounded
  check-only JSON diagnostic emission has since shipped and is now
  corpus-covered.
- Added [t/298-diagnostic-code-registry.t](/Users/richarddje/Documents/github/fsmgen/t/298-diagnostic-code-registry.t)
  to lock registry shape and defensive-copy behavior.
- Continuity note:
  - bounded check-only JSON diagnostics have since shipped and emit these
    stable codes when a failure matches the expected-failure corpus,
  - do not make downstream tools scrape human CLI wording when the code registry
    already provides the stable identity layer.

## 2026-04-17: bounded capability manifest shipped
- Continued the SPECFORGE-aligned `R12` / `R13` bridge by implementing
  `bin/fsmgen --capability-manifest`.
- Added
  [perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
  to build schema-versioned JSON for downstream tools.
- Moved the catalog owner to
  [perl/FSM/Support/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/RegressionCorpus.pm)
  so both the manifest and regression tests consume production support
  accounting; [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
  remains as a compatibility wrapper only.
- Added [t/297-capability-manifest.t](/Users/richarddje/Documents/github/fsmgen/t/297-capability-manifest.t)
  to lock manifest shape and CLI JSON emission.
- Continuity note:
  - stable diagnostic-code ownership and bounded check-only JSON diagnostics
    have since shipped,
  - do not treat the manifest as normalized semantic export; it is currently a
    conservative support/capability surface.

## 2026-04-17: SPECFORGE feedback response is now tracked
- Paused FSMGen implementation to read
  `/Users/richarddje/Documents/github/specforge/docs/FSMGEN_FEEDBACK.md`.
- Added
  [docs/SPECFORGE_FEEDBACK_RESPONSE.md](/Users/richarddje/Documents/github/fsmgen/docs/SPECFORGE_FEEDBACK_RESPONSE.md)
  as the FSMGen-side response and alignment record.
- Accepted direction:
  - strict mode should be the generated-`.fsm` target,
  - compatibility syntax remains residue,
  - capability manifest should come first and should be generated from
    support-accounting truth,
  - stable diagnostic codes should precede JSON diagnostics,
  - check-only JSON and normalized semantic JSON export belong to `R13`,
  - stronger reset/clock metadata is a high-value language/tooling seam,
  - actor/channel/role/temporal/provenance metadata should wait until it can be
    parsed, validated, normalized, documented, and support-accounted.
- Continuity note:
  - when resuming implementation, do not jump straight into broad new syntax.
    The capability manifest, stable diagnostic-code registry, and bounded
    check-only JSON diagnostics have since shipped; the next safest bridge is
    schema stabilization/widening from support-accounting truth.

## 2026-04-17: corpus coverage buckets match classifications
- Continued `R12` by making the catalog's coverage/classification relationship
  explicit.
- [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
  now maps each coverage bucket to exactly one intended classification:
  - direct/composition pipeline+CLI success buckets map to `supported_smoke`,
  - default-compatible legacy buckets map to `legacy_out_of_scope`,
  - strict, language-contract, direct-generation, and composition rejection
    buckets map to `expected_failure`.
- Continuity note:
  - when adding a future catalog entry, pick the coverage bucket from the same
    classification family as the entry. The accounting test now rejects mixed
    contracts before behavior tests consume them.

## 2026-04-17: expected failures have typed diagnostic metadata
- Continued `R12` by hardening the failure side of the catalog metadata.
- [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
  now requires:
  - every `expected_failure` entry to carry a compiled
    `expected_error_pattern`,
  - every strict-rejection coverage entry to carry a compiled
    `expected_hint_pattern`.
- Continuity note:
  - when adding future `expected_failure` entries, use compiled regex metadata,
    not strings. If the failure is a strict-mode compatibility cut, include a
    migration-hint pattern too so the regression locks an actionable user path,
    not only the fact that strict mode rejected the input.

## 2026-04-17: supported language-feature evidence is mandatory
- Continued `R12` by tightening the catalog-accounting test rather than adding
  another ad hoc fixture-family gate.
- [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
  now requires:
  - every `expected_hdl_patterns` value to be an array of compiled regexes,
  - every supported direct language-feature corpus entry to carry at least one
    HDL-shape pattern.
- Continuity note:
  - when adding a future `language_feature_fixture` / `supported_smoke` /
    `direct_root_pipeline_cli` entry, do not rely on compile success alone.
    Record the emitted semantic shape the feature is promising, because
    [t/296-regression-corpus-supported-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/296-regression-corpus-supported-behavior.t)
    will execute those patterns through pipeline/CLI and strict paths when
    applicable.

## 2026-04-17: supported success now has one behavior owner
- Continued `R12` by expanding
  [t/296-regression-corpus-supported-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/296-regression-corpus-supported-behavior.t).
- The test treats `supported_smoke` and `strict_supported` as catalog-level
  executable contracts:
  - every `supported_smoke` entry is run through default pipeline and CLI,
  - every marked `strict_supported` entry is run through strict pipeline,
  - every marked `strict_supported` entry is run through `bin/fsmgen --strict`,
  - direct-root entries must emit their recorded module name,
  - composition entries must emit their recorded top and child modules,
  - and entries with `expected_hdl_patterns` must keep those patterns in both
    applicable paths.
- Continuity note:
  - when future corpus entries add `supported_smoke`, this test should catch
    missing default support even if no family-specific smoke test was updated.
    When they also add `strict_supported => 1`, it should catch missing strict
    support too. Keep family-specific tests for richer domain assertions, but
    treat this file as the generic supported-success behavior owner.

## 2026-04-17: protocol fixtures are strict-supported
- Continued `R12` positive support accounting on the protocol smoke slice:
  - [fsm/apb_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_requester.fsm),
    [fsm/apb_completer.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_completer.fsm),
    and [fsm/amba_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/amba_requester.fsm)
    now use canonical `(areset rst_n)`, canonical `(:= (signal value))`, and
    canonical assignment-pair body forms,
  - [fsm/apb_tb.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_tb.fsm)
    now exposes `rst_n` so the APB top auto-wires the generated protocol
    children without reset-name residue,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    tags all four protocol fixtures as `strict_supported`,
  - [t/247-protocol-fixture-regression-smoke.t](/Users/richarddje/Documents/github/fsmgen/t/247-protocol-fixture-regression-smoke.t)
    now verifies both direct protocol actors and the APB composition top
    through strict pipeline and strict CLI,
  - and [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now records fourteen strict-supported entries total.
- Continuity note:
  - `strict_supported` is no longer limited to tiny direct language-feature
    examples. It may also tag maintained protocol/composition smoke fixtures
    when the complete fixture is forward-contract clean and has a strict
    pipeline/CLI owner test.

## 2026-04-17: all supported direct language-feature fixtures are strict-supported
- Continued `R12` by making the whole supported direct language-feature corpus
  strict-clean:
  - partial indexed/sliced LHS fixtures now use canonical `(sreset reset)` and
    canonical assignment-pair syntax,
  - direct RHS concat/cat, direct LHS concat/cat deconstruct, expression-backed
    width, and runtime div/mod fixtures now use canonical assignment-pair
    syntax,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    now tags all ten current supported direct language-feature fixtures as
    `strict_supported`,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now records ten strict-supported entries and requires every supported
    direct language-feature fixture to carry the marker,
  - and [t/261-regression-corpus-supported-language-features.t](/Users/richarddje/Documents/github/fsmgen/t/261-regression-corpus-supported-language-features.t)
    verifies the whole family through strict pipeline and strict CLI.
- Continuity note:
  - new `language_feature_fixture` / `supported_smoke` / `direct_root_pipeline_cli`
    corpus entries are now expected to be strict-supported too unless the
    author intentionally records why that fixture must remain compatibility
    residue instead of forward-contract syntax.

## 2026-04-17: strict-supported markers now cover canonical reset and init
- Continued `R12` positive strict-mode support accounting:
  - [t/corpus/direct_sreset_active_high.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_sreset_active_high.fsm),
    [t/corpus/direct_areset_active_low.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_areset_active_low.fsm),
    and [t/corpus/direct_canonical_init_directive.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_canonical_init_directive.fsm)
    are now tagged `strict_supported`,
  - those fixtures' body assignments were migrated from infix compatibility
    syntax to canonical pair syntax after the strict-supported test exposed the
    residue,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now records four strict-supported direct-root FSM fixtures,
  - and [t/261-regression-corpus-supported-language-features.t](/Users/richarddje/Documents/github/fsmgen/t/261-regression-corpus-supported-language-features.t)
    verifies canonical reset, canonical init/default, and canonical assignment
    surfaces through strict pipeline and strict CLI.
- Continuity note:
  - `strict_supported` should continue to mean the complete fixture is
    forward-contract clean. If a future fixture has one canonical feature but
    still carries compatibility syntax elsewhere, migrate the residue or do not
    tag it yet.

## 2026-04-16: strict-supported corpus marker proves canonical pair acceptance
- Continued `R12` with a positive strict-mode support-accounting marker:
  - [t/corpus/direct_assignment_pair_form.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_assignment_pair_form.fsm)
    is now tagged `strict_supported` in the regression corpus,
  - [t/261-regression-corpus-supported-language-features.t](/Users/richarddje/Documents/github/fsmgen/t/261-regression-corpus-supported-language-features.t)
    now reruns marked supported fixtures through both `strict_mode => 1` and
    `bin/fsmgen --strict`,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now checks that strict-supported markers stay on supported direct-root FSM
    assets and currently records one marker,
  - and [docs/REGRESSION_CORPUS.md](/Users/richarddje/Documents/github/fsmgen/docs/REGRESSION_CORPUS.md)
    documents that `strict_supported` is a positive acceptance marker rather
    than a replacement coverage bucket.
- Continuity note:
  - strict mode now has corpus-backed symmetry for the assignment surface:
    infix compatibility forms are rejected, while canonical pair forms are
    explicitly accepted through strict pipeline and CLI paths.

## 2026-04-16: direct SV assembly now locks stage preparation before declarations
- Continued the lower-level direct-backend coordination lane:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm)
    now has an explicit `prepare_consolidated_intermediate_stage(...)` method,
  - that method documents why the consolidated intermediate stage must be
    prepared before internal declarations are emitted,
  - final HDL text order is unchanged because the prepared stage text is still
    appended after enable conditions,
  - and [t/293-systemverilog-post-flattening-assembly-support.t](/Users/richarddje/Documents/github/fsmgen/t/293-systemverilog-post-flattening-assembly-support.t)
    now has fake-owner coverage that proves stage preparation precedes
    declaration emission.
- This protects the declaration-before-use contract for helper wires discovered
  by prescan/factorization and keeps the direct backend’s odd-looking ordering
  intentional rather than accidental.

## 2026-04-16: README bootstrap refreshed the bin/fsmgen import-tree snapshot
- Re-executed the README/session-bootstrap ramp-up:
  - read the README-linked steering docs at heading/active-section level,
  - inspected [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen),
  - reran the static project-owned `FSM::...` import walk,
  - and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md).
- Current measured closure:
  - `122` reachable project files,
  - `121` reachable `.pm` packages,
  - `FSM::Package::*` now counts `14` reachable packages because
    [perl/FSM/Package/IntegerLiteralSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Package/IntegerLiteralSupport.pm)
    is live on the scalar-width / direct `+size` expression path.
- Runtime-spine conclusion stayed stable:
  - [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) is still
    presentation/reporting glue around [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the orchestrator family remains the real dispatch spine,
  - and the next honest seam remains lower-level direct-backend coordination
    plus large parser/CoreAST/expression-surface hardening, not top-level
    facade work.

## 2026-04-16: corpus now accounts for infix assignment compatibility residue
- Continued the strict assignment-pair lane by moving infix assignment residue
  into the maintained regression corpus:
  - [t/corpus/legacy_infix_assignment.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_infix_assignment.fsm)
    is the paired default-compatible / strict-rejected fixture,
  - `legacy.infix_assignment.default_compat` must compile in default mode
    through both pipeline and CLI,
  - `legacy.infix_assignment.strict_rejection` must fail in strict mode with
    the canonical assignment-pair migration hint,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now expects `53` catalog entries, `8` legacy-out-of-scope entries, and
    `31` expected-failure entries,
  - and [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
    now drives the new strict assignment-rejection bucket through pipeline and
    CLI.

## 2026-04-16: strict mode rejects infix assignment compatibility
- Continued the canonical assignment-pair work by widening strict mode:
  - default mode still accepts infix assignments such as `(OUT = IN)` and
    `(Q <- D)` as compatibility spellings,
  - strict mode now rejects those infix spellings and points to canonical
    pairs such as `(= (OUT IN))`,
  - canonical pair assignments remain accepted in strict mode,
  - the check lives in [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm)
    so direct roots and generated child sources share the same support-tier
    boundary,
  - and [t/295-strict-mode-infix-assignment-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/295-strict-mode-infix-assignment-boundary.t)
    locks default compatibility, strict pair acceptance, direct strict
    rejection, CLI no-output behavior, and external child-source rejection.

## 2026-04-16: canonical assignment pair form is active syntax
- Implemented the canonical assignment surface:
  `(assign-op (lhs rhs))` plus optional guard form
  `(assign-op (lhs rhs) <cond)`.
- Important continuity note:
  - book coverage now lives in [docs/book/src/02-language-basics.md](/Users/richarddje/Documents/github/fsmgen/docs/book/src/02-language-basics.md)
    under canonical pair form,
  - live contract/roadmap steering now lives in [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md),
    [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md),
    and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md),
  - this is active parser syntax for `=`, `<-`, `<=`, `<-=`, `<=+`, and
    delayed-pulse `<N`,
  - current infix assignment forms remain compatibility spellings and both
    syntaxes normalize into the same assignment AST/IR,
  - `<cond>` is assignment-level guard metadata, not part of the RHS.
- Regression coverage:
  - [t/29-language-contract-core-forms.t](/Users/richarddje/Documents/github/fsmgen/t/29-language-contract-core-forms.t)
    locks parser/CoreAST/HDL behavior for simple, guarded, nested-RHS,
    sequential, pulse, and LHS-deconstruct pair assignments,
  - [t/corpus/direct_assignment_pair_form.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_assignment_pair_form.fsm)
    is the named supported-smoke corpus fixture for pipeline and CLI coverage.

## 2026-04-16: corpus now covers runtime division and modulus expressions
- Continued `R12` by adding the named supported-smoke sibling for runtime RHS
  integer division and modulus support. Focused language-contract tests already
  covered `/` and `%`; this slice makes the support claim visible in the
  maintained corpus.
- Important continuity note:
  - [t/corpus/direct_runtime_div_mod.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_runtime_div_mod.fsm)
    uses `/`, `%`, `div`, and `mod` in ordinary direct RHS assignments,
    including three-operand forms,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    records it as `feature.direct_runtime_div_mod` under
    `direct_root_pipeline_cli`,
  - [t/261-regression-corpus-supported-language-features.t](/Users/richarddje/Documents/github/fsmgen/t/261-regression-corpus-supported-language-features.t)
    checks that pipeline and CLI emit `A / B`, `A % B`, `A / B / C`, and
    `A % B % C`, and
  - [docs/book/src/02-language-basics.md](/Users/richarddje/Documents/github/fsmgen/docs/book/src/02-language-basics.md)
    now includes a visible runtime div/mod example beside the semantic
    boundary that dynamic runtime divisors are not yet statically proven
    nonzero.

## 2026-04-16: book is the user-facing FSMGen surface
- User reinforced that all aspects of `.fsm` files, composition, and every
  other user-facing surface should be extensively documented in the mdBook with
  many examples because the book is what users see first.
- Captured the principle in [docs/BOOK_PLAN.md](/Users/richarddje/Documents/github/fsmgen/docs/BOOK_PLAN.md),
  [docs/book/src/00-introduction.md](/Users/richarddje/Documents/github/fsmgen/docs/book/src/00-introduction.md),
  and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md):
  live continuity docs are for session-loss/crash recovery, while maintainer
  continuity files more broadly are not substitutes for
  public chapter coverage. Each visible syntax/composition/type/package/CLI/
  diagnostic/generated-HDL/support-boundary behavior needs a clear book home
  with rationale, boundaries, and realistic examples.
- Follow-up clarification: both surfaces are important. The book is the public
  user-facing learning/reference surface; live continuity docs preserve the
  engineering thread across crashes, handoffs, and long implementation arcs.

## 2026-04-16: book quick expressions now name div/mod semantics
- User asked whether the `/` and `%` support details are already part of the
  mdBook. They mostly were: chapters 4, 6, and 10 already covered
  constant-expression and aggregate divide/modulo-by-zero behavior.
- Tightened [docs/book/src/02-language-basics.md](/Users/richarddje/Documents/github/fsmgen/docs/book/src/02-language-basics.md)
  so the quick expression overview also names `div` / `mod`, documents the
  left-associative n-ary behavior of `/` and `%`, and states the current
  boundary: folded constant-expression domains reject divide/modulo by zero
  before HDL generation, while runtime dynamic divisors are not yet proven
  nonzero by compile-time analysis.

## 2026-04-16: corpus now rejects modulo-by-zero +size arithmetic
- Continued `R12` by adding the modulo sibling for direct `+size` arithmetic:
  divide-by-zero was already accounted, and `%`/`mod` has its own evaluator
  rejection branch that also needs corpus evidence.
- Important continuity note:
  - [t/corpus/direct_size_expression_modulo_by_zero.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_modulo_by_zero.fsm)
    uses `(% 8 0)` as the authored `+size` width expression,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    records it as `contract.direct_size_expression_modulo_by_zero` under
    `language_contract_rejection_pipeline_cli`,
  - [docs/book/src/04-symbols-types-and-imports.md](/Users/richarddje/Documents/github/fsmgen/docs/book/src/04-symbols-types-and-imports.md)
    and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md)
    now name both divide-by-zero and modulo-by-zero as explicit `+size`
    arithmetic failures, and
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
    proves both pipeline and CLI reject the source without emitting HDL.

## 2026-04-16: corpus now rejects malformed +size operator arity
- Continued `R12` by adding the named arity sibling for direct `+size`
  expressions: supported width operators still need a valid operand shape
  before generation.
- Important continuity note:
  - [t/corpus/direct_size_expression_bad_arity.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_bad_arity.fsm)
    uses `(+ 8)` as a supported operator with too few operands,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    records it as `contract.direct_size_expression_bad_arity` under
    `language_contract_rejection_pipeline_cli`,
  - [docs/book/src/04-symbols-types-and-imports.md](/Users/richarddje/Documents/github/fsmgen/docs/book/src/04-symbols-types-and-imports.md)
    and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md)
    now name malformed operator arity as an explicit `+size` contract failure,
    and
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
    proves both pipeline and CLI reject the source without emitting HDL.

## 2026-04-16: corpus now rejects unsupported +size operators
- Continued `R12` by adding the named operator-family sibling for direct
  `+size` expressions: only the bounded arithmetic/bitwise width operators are
  accepted before generation.
- Important continuity note:
  - [t/corpus/direct_size_expression_unsupported_operator.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_unsupported_operator.fsm)
    uses `(pow 2 3)` as an unsupported authored width operator,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    records it as `contract.direct_size_expression_unsupported_operator` under
    `language_contract_rejection_pipeline_cli`,
  - [docs/book/src/04-symbols-types-and-imports.md](/Users/richarddje/Documents/github/fsmgen/docs/book/src/04-symbols-types-and-imports.md)
    and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md)
    now name unsupported width operators as explicit `+size` contract
    failures, and
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
    proves both pipeline and CLI reject the source without emitting HDL.

## 2026-04-16: corpus now rejects divide-by-zero +size arithmetic
- Continued `R12` by adding the named arithmetic-failure sibling for direct
  `+size` expressions: supported width operators still have to fold to one
  valid positive integer before generation.
- Important continuity note:
  - [t/corpus/direct_size_expression_divide_by_zero.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_divide_by_zero.fsm)
    uses `(/ 8 0)` as the authored `+size` width expression,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    records it as `contract.direct_size_expression_divide_by_zero` under
    `language_contract_rejection_pipeline_cli`,
  - [docs/book/src/04-symbols-types-and-imports.md](/Users/richarddje/Documents/github/fsmgen/docs/book/src/04-symbols-types-and-imports.md)
    and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md)
    now state that invalid width arithmetic is rejected before HDL generation,
    and
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
    proves both pipeline and CLI reject the source without emitting HDL.

## 2026-04-16: corpus now rejects aggregate +size expression roots
- Continued `R12` by adding the named non-scalar sibling for direct `+size`
  expressions: aggregate scalar leaves may drive widths, but whole aggregate
  roots cannot stand in for one scalar integer width.
- Important continuity note:
  - [t/corpus/direct_size_expression_aggregate_symbol.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_aggregate_symbol.fsm)
    uses `WIDTHS` as a whole list aggregate root in `(+size (OUT WIDTHS))`,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    records it as `contract.direct_size_expression_aggregate_symbol` under
    `language_contract_rejection_pipeline_cli`,
  - [docs/book/src/04-symbols-types-and-imports.md](/Users/richarddje/Documents/github/fsmgen/docs/book/src/04-symbols-types-and-imports.md)
    and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md)
    now state that scalar aggregate leaves are valid width ingredients while
    whole aggregate roots are not raw scalar widths, and
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
    proves both pipeline and CLI reject the source without emitting HDL.

## 2026-04-16: corpus now rejects unresolved +size expression symbols
- Continued `R12` by adding the missing named expected-failure side for a
  direct `+size` expression that references an undeclared scalar symbol.
- Important continuity note:
  - [t/corpus/direct_size_expression_unknown_symbol.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_unknown_symbol.fsm)
    uses `(+ BASE_W MISSING_W)` so one leaf resolves and one leaf stays
    undeclared,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    records it as `contract.direct_size_expression_unknown_symbol` under
    `language_contract_rejection_pipeline_cli`,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now expects `25` expected-failure entries, and
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
    proves both pipeline and CLI reject the source without emitting HDL.

## 2026-04-16: corpus now rejects non-positive +size expressions
- Continued `R12` by adding a named language-contract expected-failure corpus
  entry for direct `+size` expressions that resolve to a non-positive width.
- Important continuity note:
  - [t/corpus/direct_size_expression_non_positive.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_non_positive.fsm)
    folds `(- BASE_W DEC_W)` to zero through constants and `0d` syntax,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    records it as `contract.direct_size_expression_non_positive` under
    `language_contract_rejection_pipeline_cli`,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now expects `24` expected-failure entries, and
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
    proves both pipeline and CLI reject the source without emitting HDL.

## 2026-04-16: corpus now covers shared literal width expressions
- Continued `R12` by widening the existing supported-smoke
  `feature.direct_size_expression_widths` corpus entry instead of leaving the
  newly shared integer-literal behavior only in focused helper tests.
- Important continuity note:
  - [t/corpus/direct_size_expression_widths.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_widths.fsm)
    now includes `0d` decimal width terms, signed SystemVerilog based negative
    terms, and unsized based literals in direct `+size` expressions,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    now checks the generated widths for the added `F`, `G`, and `H` signals
    through both pipeline and CLI via the existing supported-feature harness,
  - [t/261-regression-corpus-supported-language-features.t](/Users/richarddje/Documents/github/fsmgen/t/261-regression-corpus-supported-language-features.t)
    is the primary locking test for this corpus slice, and
  - catalog counts do not change because the slice strengthens an existing
    supported feature entry rather than adding a new entry.

## 2026-04-16: integer literal parsing now has one width-expression owner
- Continued the `R8` language-contract hardening lane by extracting common
  integer literal to `Math::BigInt` parsing into
  [perl/FSM/Package/IntegerLiteralSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Package/IntegerLiteralSupport.pm).
- Important continuity note:
  - [perl/FSM/Package/ScalarWidthSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Package/ScalarWidthSupport.pm)
    now delegates positive width-symbol parsing to that shared helper instead
    of owning a second parser,
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm)
    now uses the same helper for `+size` constant-expression literals,
  - the direct `+size` expression tokenizer now treats signed literals as
    operands only where an operand is expected, so compact forms like `1+2`
    still parse as binary arithmetic while `3+-2` remains a valid signed
    literal term,
  - [t/294-scalar-width-support.t](/Users/richarddje/Documents/github/fsmgen/t/294-scalar-width-support.t)
    locks the helper and tokenizer boundary, and
  - [t/50-language-contract-size-section-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/50-language-contract-size-section-boundary.t)
    now proves `+size` expressions resolve `0d`, signed based negative terms,
    and unsized SystemVerilog literals through the shared path.

## 2026-04-16: scalar width symbols share common integer literal support
- Continued the `R8` language-contract hardening lane by removing a literal
  dialect split between scalar constants, scalar width symbols, and expression
  parsing.
- Important continuity note:
  - [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm)
    now parses common integer spellings such as `0xA5`, `0b1010`, `0o10`,
    unsized SystemVerilog-style based literals like `'hA5`, and
    underscore-separated digits,
  - direct, composition, and package symbol canonicalization now preserve octal
    literals as octal instead of falling back to decimal text,
  - [perl/FSM/Package/ScalarWidthSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Package/ScalarWidthSupport.pm)
    resolves those same scalar spellings when they are used as positive integer
    width symbols for direct `+size` or composition `?ports`,
  - [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm)
    now renders octal literals as Verilog-family `'o` literals, and
  - [t/294-scalar-width-support.t](/Users/richarddje/Documents/github/fsmgen/t/294-scalar-width-support.t)
    plus the composition scalar-width subtest in
    [t/279-declarative-scalar-types.t](/Users/richarddje/Documents/github/fsmgen/t/279-declarative-scalar-types.t)
    lock the helper and pipeline/CLI behavior.

## 2026-04-16: canonical init and expression-backed +size slots shipped
- Continued `R8`/`R12` by making canonical top-level init/reset metadata use
  the strict-safe Lisp-ish pair form `(:= (signal value))` while keeping legacy
  compact `(:= signal=value)` as default-mode compatibility residue.
- Important continuity note:
  - canonical `:=` values are now expression slots, so nested Lisp-ish
    arithmetic/bitwise expressions may use constants, enum members, params, and
    aggregate scalar leaves,
  - `+size` width entries are now constant-expression slots too; params are
    resolved before size parsing so widths may use constants/enums/params and
    nested operators when they fold to one positive integer,
  - [perl/FSM/Synthesis/EnableGraph/SignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/SignalSupport.pm)
    now reads reset metadata from the LHS signal object, so internal flops
    driven by `<=` preserve explicit `:=` reset values even when the internal
    signal is not a module port,
  - [t/corpus/direct_canonical_init_directive.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_canonical_init_directive.fsm)
    and [t/corpus/direct_size_expression_widths.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_widths.fsm)
    are named supported-smoke corpus fixtures, and
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now expects `42` catalog entries and `12` supported-smoke entries.

## 2026-04-16: corpus now covers compact init strict cut
- Continued `R12` by adding the compact top-level `(:= signal=value)` strict
  compatibility-boundary contract to the named corpus.
- Important continuity note:
  - [t/corpus/legacy_compact_init_directive.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_compact_init_directive.fsm)
    is cataloged twice: `legacy.compact_init_directive.default_compat` and
    `legacy.compact_init_directive.strict_rejection`,
  - default mode must still compile the fixture through pipeline and CLI,
  - strict mode must reject it through pipeline and CLI with the explicit
    canonical `(:= (signal value))` migration hint for the compact `:=`
    surface,
  - and [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now expects `42` catalog entries, `7` legacy-out-of-scope entries, `23`
    expected-failure entries, and `12` supported-smoke entries.

## 2026-04-15: corpus now covers legacy reset strict cuts
- Continued `R12` by adding the strict-mode compatibility-boundary side of the
  reset contract to the named corpus.
- Important continuity note:
  - [t/corpus/legacy_asreset_rstn.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_asreset_rstn.fsm)
    is cataloged twice: `legacy.asreset_rstn.default_compat` and
    `legacy.asreset_rstn.strict_rejection`,
  - [t/corpus/legacy_sreset_rstn.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_sreset_rstn.fsm)
    is cataloged twice: `legacy.sreset_rstn.default_compat` and
    `legacy.sreset_rstn.strict_rejection`,
  - default mode must still compile both compatibility fixtures through
    pipeline and CLI,
  - strict mode must reject both fixtures through pipeline and CLI with the
    canonical reset migration hint toward `(sreset reset)` or `(areset rst_n)`,
  - and [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now expects `38` catalog entries, `6` legacy-out-of-scope entries, and
    `22` expected-failure entries.

## 2026-04-14: GitHub Actions CI is intentionally disabled
- The repository was close to exhausting the account's included GitHub Actions
  minutes, so the active regression workflow is intentionally parked outside
  `.github/workflows/`.
- Important continuity note:
  - [.github/workflows-disabled/regression.yml](/Users/richarddje/Documents/github/fsmgen/.github/workflows-disabled/regression.yml)
    is the former `.github/workflows/regression.yml` workflow,
  - GitHub will not auto-run it while it stays outside `.github/workflows/`,
  - [.github/workflows-disabled/README.md](/Users/richarddje/Documents/github/fsmgen/.github/workflows-disabled/README.md)
    records the `git mv` command needed to re-enable CI later,
  - and future tasks should not re-enable the workflow unless the user asks.

## 2026-04-13: corpus now covers canonical reset policies
- Continued `R12` by promoting the canonical direct reset semantics into the
  named supported corpus.
- Important continuity note:
  - [t/corpus/direct_sreset_active_high.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_sreset_active_high.fsm)
    is now a named supported fixture for `(+system (clock clk) (sreset reset))`,
  - [t/corpus/direct_areset_active_low.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_areset_active_low.fsm)
    is now a named supported fixture for `(+system (clock clk) (areset rst_n))`,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    records them as `feature.direct_sreset_active_high` and
    `feature.direct_areset_active_low`,
  - [t/261-regression-corpus-supported-language-features.t](/Users/richarddje/Documents/github/fsmgen/t/261-regression-corpus-supported-language-features.t)
    now checks through both pipeline and CLI that `sreset reset` emits
    clock-only `always_ff @(posedge clk)` plus `if (reset)`, while `areset
    rst_n` emits `always_ff @(posedge clk or negedge rst_n)` plus `if
    (!rst_n)`,
  - and [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now expects `34` catalog entries and `10` supported-smoke entries.

## 2026-04-13: corpus now covers width-equal aggregate shape rejection
- Continued `R12` by adding another direct-generation expected-failure corpus
  asset, this time for a semantic aggregate contract mismatch where packed
  width alone would be insufficient.
- Important continuity note:
  - [t/corpus/direct_aggregate_contract_mismatch.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_aggregate_contract_mismatch.fsm)
    is now a named expected-failure fixture for `(OUT = FRAME)` where `FRAME`
    is inferred as a record aggregate and `OUT` is declared as a list aggregate
    of the same packed width,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    records it as `contract.direct_aggregate_contract_mismatch` under
    `direct_generation_contract_rejection_pipeline_cli`,
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
    now checks the failure through the existing direct-generation
    expected-failure harness, including source-file context and the
    aggregate-contract diagnostic through both pipeline and CLI,
  - and [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now expects `32` catalog entries and `20` expected-failure entries.

## 2026-04-13: corpus now covers LHS deconstruct width rejection
- Continued `R12` by adding a second language-contract expected-failure corpus
  asset for the shipped LHS deconstruct surface.
- Important continuity note:
  - [t/corpus/direct_lhs_deconstruct_width_mismatch.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_lhs_deconstruct_width_mismatch.fsm)
    is now a named expected-failure fixture for an LHS `(concat HI LO)`
    deconstruct whose total target width is `8` while the RHS `DATA` width is
    `7`,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    records it as `contract.direct_lhs_deconstruct_width_mismatch` under
    `language_contract_rejection_pipeline_cli`,
  - this classification is deliberate because the active frontend rejects that
    malformed authored LHS form before HDL generation,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now expects `31` catalog entries and `19` expected-failure entries,
  - and the direct-generation contract bucket remains reserved for failures
    like the RHS concat assignment-width case that parse successfully but abort
    before emission.

## 2026-04-13: corpus now covers direct RHS concat width rejection
- Continued `R12` by promoting one parsed-but-rejected direct-generation
  assignment contract into the named expected-failure corpus.
- Important continuity note:
  - [t/corpus/direct_rhs_concat_width_mismatch.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_rhs_concat_width_mismatch.fsm)
    is now a named expected-failure fixture for a direct RHS `(concat HI LO)`
    assignment whose total RHS width is too small for `BUS`,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    records it as `contract.direct_rhs_concat_width_mismatch` under the new
    `direct_generation_contract_rejection_pipeline_cli` coverage bucket,
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
    now checks the source-file context plus direct assignment-width diagnostic
    through both pipeline and CLI,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now expects `30` catalog entries and `18` expected-failure entries,
  - and this keeps pre-generation direct contract failures support-accounted
    separately from parser-only language-contract failures.

## 2026-04-13: supported corpus now includes direct LHS deconstruct
- Continued the `R12` support-accounting lane by promoting the sibling
  deconstruct half of the pack/deconstruct assignment surface into the named
  corpus.
- Important continuity note:
  - [t/corpus/direct_lhs_deconstruct_pack.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_lhs_deconstruct_pack.fsm)
    is now a named supported direct-root fixture for static LHS `(concat ...)`
    and `(cat ...)` deconstruct assignments,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    records it as `feature.direct_lhs_deconstruct_pack`,
  - [t/261-regression-corpus-supported-language-features.t](/Users/richarddje/Documents/github/fsmgen/t/261-regression-corpus-supported-language-features.t)
    now checks whole-signal high-to-low splitting, the `cat` alias, and
    same-base sliced-fragment rejoining through both pipeline and CLI,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now expects `29` catalog entries and `8` named supported-smoke entries,
  - and the unrelated untracked [fx](/Users/richarddje/Documents/github/fsmgen/fx)
    path remains untouched.

## 2026-04-13: supported corpus now includes direct RHS concat/cat
- Continued the visible `R12` support-accounting lane after the direct-backend
  cleanup slices by promoting one more shipped language feature into the
  machine-checked corpus.
- Important continuity note:
  - [t/corpus/direct_rhs_concat_pack.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_rhs_concat_pack.fsm)
    is now a named supported direct-root fixture for direct RHS `(concat ...)`
    and `(cat ...)` pack expressions,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
    records it as `feature.direct_rhs_concat_pack`,
  - [t/261-regression-corpus-supported-language-features.t](/Users/richarddje/Documents/github/fsmgen/t/261-regression-corpus-supported-language-features.t)
    now checks flat concat, `cat` alias, and nested concat SystemVerilog shape
    through both pipeline and CLI,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now expects `28` catalog entries and `7` named supported-smoke entries,
  - and [docs/REGRESSION_CORPUS.md](/Users/richarddje/Documents/github/fsmgen/docs/REGRESSION_CORPUS.md)
    lists the new supported feature asset beside the partial-LHS fixtures.

## 2026-04-13: generation pipeline shell is now a pure delegate too
- Continued the active `R11` lower-level direct-backend convergence lane by
  removing the remaining fallback construction from the older direct
  SystemVerilog generation-pipeline compatibility shell.
- Important continuity note:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm)
    now delegates directly to the live
    [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm)
    owner with no implicit construction fallback,
  - [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t)
    now includes a spy-owner contract proving that the shell only requires and
    calls the live post-flattening assembly owner,
  - focused generation-pipeline shell coverage and the focused direct-backend
    sweep passed after the change (`Files=8, Tests=523`),
  - and no import-tree package count changed.

## 2026-04-13: consolidated intermediate shells are now pure delegates
- Continued the active `R11` lower-level direct-backend convergence lane by
  removing the remaining duplicated fallback implementations from the older
  direct SystemVerilog consolidated-intermediate compatibility shells.
- Important continuity note:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm)
    now delegates directly to the live
    [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm)
    owner with no detached collection/planning/projection fallback,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm)
    now delegates directly to the live
    [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm)
    owner with no duplicate declaration/assignment rendering fallback,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm)
    now delegates directly to the live
    [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm)
    owner with no duplicate stage-preparation / validation / rendering
    fallback,
  - [t/200-systemverilog-consolidated-intermediate-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/200-systemverilog-consolidated-intermediate-emitter.t),
    [t/219-systemverilog-consolidated-intermediate-block-support.t](/Users/richarddje/Documents/github/fsmgen/t/219-systemverilog-consolidated-intermediate-block-support.t),
    and [t/224-systemverilog-consolidated-intermediate-generation-support.t](/Users/richarddje/Documents/github/fsmgen/t/224-systemverilog-consolidated-intermediate-generation-support.t)
    now include spy-owner contracts proving those shells require only their
    live owner,
  - focused shell tests and the full regression passed after the change
    (`Files=288, Tests=2372`),
  - and no import-tree package count changed.

## 2026-04-13: consolidated intermediate emitter test now anchors on rendering owner
- Continued the active `R11` lower-level direct-backend convergence lane.
- Important continuity note:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm)
    already delegated prepared-block rendering to the live
    [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm)
    owner when present; its POD now names that rendering owner correctly,
  - [t/200-systemverilog-consolidated-intermediate-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/200-systemverilog-consolidated-intermediate-emitter.t)
    now locks the compatibility shell against the live rendering owner instead
    of rebuilding a wider scaffold/declaration/prefix path manually,
  - the broader direct module assembly coverage remains in the live
    post-flattening assembly and generated-module tests,
  - the focused consolidated-intermediate suite passed after the retargeting,
  - and no import-tree package count changed.

## 2026-04-13: consolidated intermediate block shell delegates to stage preparation
- Continued the active `R11` lower-level direct-backend convergence lane.
- Important continuity note:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm)
    now delegates prepared-block reconstruction to the live
    [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm)
    owner when that owner is present, instead of duplicating the collection /
    planning / prepared-block projection sequence,
  - the older explicit composition remains only as a fallback for detached
    compatibility contexts,
  - [t/219-systemverilog-consolidated-intermediate-block-support.t](/Users/richarddje/Documents/github/fsmgen/t/219-systemverilog-consolidated-intermediate-block-support.t)
    now locks that the compatibility shell matches the live stage-preparation
    owner,
  - the focused prepared-block/stage/assembly suite passed after the change,
  - and no import-tree package count changed.

## 2026-04-13: direct SystemVerilog contract tests now hit the live assembly owner
- Continued the active `R11` direct-backend convergence lane with a regression
  proof-boundary hardening slice.
- Important continuity note:
  - [t/269-systemverilog-operand-contract-validation-support.t](/Users/richarddje/Documents/github/fsmgen/t/269-systemverilog-operand-contract-validation-support.t)
    now drives final-emission operand-contract failures through the live
    [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm)
    owner instead of instantiating the older generation-pipeline compatibility
    shell,
  - [t/270-systemverilog-assignment-width-contract-validation.t](/Users/richarddje/Documents/github/fsmgen/t/270-systemverilog-assignment-width-contract-validation.t)
    now does the same for direct RHS concat width mismatches, scalar width
    mismatches, and aggregate-contract mismatch diagnostics,
  - [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t)
    remains the intentional compatibility-shell regression anchor for
    [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm),
  - the focused validation/assembly suite passed after the retargeting, and
  - this is a proof-boundary hardening slice only; no generated HDL behavior or
    import-tree package count changed.

## 2026-04-13: post-flattening SystemVerilog assembly owner shipped
- Continued the active `R11` direct-backend convergence lane.
- Important continuity note:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm)
    is now the live direct SystemVerilog post-flattening assembly owner,
    composing scaffold/header/state/register emission, internal declarations,
    enable-condition emission, the prescan-aware consolidated intermediate
    stage, and tail closeout,
  - [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm)
    now stops at per-run reset, module attachment, decision-tree flattening,
    and final handoff to that owner,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm)
    remains a compatibility shell, but now delegates to the live
    post-flattening assembly owner instead of duplicating the assembly
    sequence,
  - [t/293-systemverilog-post-flattening-assembly-support.t](/Users/richarddje/Documents/github/fsmgen/t/293-systemverilog-post-flattening-assembly-support.t)
    locks the new owner directly, while [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t)
    locks the compatibility wrapper against it,
  - focused direct-backend tests passed: [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t),
    [t/231-systemverilog-consolidated-intermediate-stage-support.t](/Users/richarddje/Documents/github/fsmgen/t/231-systemverilog-consolidated-intermediate-stage-support.t),
    [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t),
    [t/234-systemverilog-generation-tail-support.t](/Users/richarddje/Documents/github/fsmgen/t/234-systemverilog-generation-tail-support.t),
    [t/238-systemverilog-generation-prescan-preparation-support.t](/Users/richarddje/Documents/github/fsmgen/t/238-systemverilog-generation-prescan-preparation-support.t),
    [t/269-systemverilog-operand-contract-validation-support.t](/Users/richarddje/Documents/github/fsmgen/t/269-systemverilog-operand-contract-validation-support.t),
    [t/270-systemverilog-assignment-width-contract-validation.t](/Users/richarddje/Documents/github/fsmgen/t/270-systemverilog-assignment-width-contract-validation.t),
    and [t/293-systemverilog-post-flattening-assembly-support.t](/Users/richarddje/Documents/github/fsmgen/t/293-systemverilog-post-flattening-assembly-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md)
    now records the measured `121` reachable project files and `120`
    reachable `.pm` packages snapshot.

## 2026-04-13: consolidated-intermediate stage prescan handoff shipped
- Continued the active `R11` direct-backend convergence lane.
- Important continuity note:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm)
    now owns the whole live consolidated-intermediate handoff over prescan,
    prepared-block reconstruction, pre-generation operand-contract validation,
    and rendering,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPrescanPreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPrescanPreparationSupport.pm)
    is now idempotent per generation run through the
    `backend_sv_enable_prescan_prepared` guard,
  - [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm)
    resets that guard and no longer calls prescan directly,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm)
    also delegates prescan to the stage owner,
  - focused tests covering the stage, pipeline compatibility, tail, prescan,
    validator, and assignment-width paths passed after the change,
  - and the next honest seam remains direct backend stage/tail convergence and
    broader `FlattenedDT` simplification rather than orchestrator-level prescan
    glue.

## 2026-04-13: consolidated-intermediate stage validation handoff shipped
- Executed the README / SESSION_BOOTSTRAP ramp-up pass and then continued the
  active `R11` direct-backend convergence lane.
- Important continuity note:
  - the live import-tree closure still measures `120` reachable project files
    and `119` reachable `.pm` packages,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm)
    now owns consolidated-intermediate prepared-block reconstruction,
    pre-generation operand-contract validation, and rendering as one stage
    handoff,
  - [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm)
    and the compatibility
    [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm)
    now request the consolidated-intermediate HDL from that owner instead of
    hand-composing prepared-block validation/rendering,
  - [t/231-systemverilog-consolidated-intermediate-stage-support.t](/Users/richarddje/Documents/github/fsmgen/t/231-systemverilog-consolidated-intermediate-stage-support.t)
    now locks that stage-level validation failure path,
  - and the next honest seam remains lower-level direct-backend
    planning/stage/tail coordination plus broader `FlattenedDT` convergence.

## 2026-04-12: aggregate parameter/generic leafwise arithmetic shipped
- Saved the bounded aggregate arithmetic widening slice.
- Important continuity note:
  - [perl/FSM/ParameterValueSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ParameterValueSupport.pm)
    now accepts matching-shape aggregate expressions using leafwise `+`, `-`,
    `*`, `/`, `%`, `&`, `|`, `^`, plus aliases `add`, `sub`, `mul`, `div`,
    `mod`, `and`, `or`, and `xor`,
  - operands must all resolve to matching list/record aggregate semantic
    values,
  - arithmetic leaves are unsigned fixed-width folds; leaf widths must match,
    divide/modulo by zero is rejected, and overflow/underflow outside the leaf
    width aborts before HDL emission,
  - the folded aggregate payload still lowers before backend generation rather
    than passing raw HDL expressions downstream,
  - this is covered across direct `+params`, `.rtlif` defaults, external `?rtl`
    overrides, and generated `?fsmc` / `?dtc` overrides,
  - and richer aggregate operator families beyond this leafwise numeric/bitwise
    slice remain future typed work rather than raw HDL passthrough.

## 2026-04-12: generated-child source-shape diagnostic tests refreshed
- During the full regression pass for the aggregate-expression work, the only
  failures were stale generated-child diagnostic expectations in
  [t/130-composition-generated-child-source-shape-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/130-composition-generated-child-source-shape-diagnostics.t)
  and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t).
- Important continuity note:
  - generated `?fsmc` / `?dtc` children now legitimately accept nested
    semantic `(params (NAME value) ...)` payload blocks,
  - unsupported nested child payloads should therefore report the
    `composition generated-child source shape` boundary and the targeted
    “nested payloads accept only `(params ...)` semantic blocks” reason,
  - the older flat-source-only source-shape expectation remains wrong for this
    payload family, while source-count failures still keep the source-count
    contract.

## 2026-04-12: README bootstrap import tree refreshed
- Executed the README / SESSION_BOOTSTRAP ramp-up pass for this session and
  refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md)
  to the current `120` reachable project files and `119` reachable `.pm`
  packages snapshot.
- Important continuity note:
  - [perl/FSM/ParameterValueSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ParameterValueSupport.pm)
    is now documented as a singleton semantic-value owner in the import tree,
    not hidden inside `Composition`,
  - it owns scalar/aggregate parameter/generic values, bounded scalar
    expressions, and matching-shape aggregate expression folding across direct
    `+params`, `.rtlif` defaults, external `?rtl` overrides, and generated
    `?fsmc` / `?dtc` overrides,
  - [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md)
    and [docs/COMPOSITION_LEGACY_MAPPING.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_LEGACY_MAPPING.md)
    now distinguish the shipped expression slices from future VHDL generic-map
    lowering and richer expression domains,
  - no production-code changes were needed for this bootstrap/documentation
    pass.

## 2026-04-12: aggregate parameter/generic bitwise expressions shipped
- Saved the first bounded aggregate operator-expression slice.
- Important continuity note:
  - [perl/FSM/ParameterValueSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ParameterValueSupport.pm)
    now accepts aggregate bitwise expressions using `&`, `|`, `^`, `and`,
    `or`, or `xor`,
  - operands must all resolve to matching list/record aggregate semantic
    values,
  - the normalizer folds each scalar leaf into a new aggregate payload before
    backend lowering,
  - this is covered across direct `+params`, `.rtlif` defaults, external `?rtl`
    overrides, and generated `?fsmc` / `?dtc` overrides,
  - mixed scalar/aggregate operands, mismatched aggregate shapes, and non-bitwise
    aggregate operators still abort before generation,
  - and richer aggregate operator families remain future typed work rather than
    raw HDL passthrough.

## 2026-04-12: bounded scalar parameter/generic expressions shipped
- Saved the bounded `R11` scalar expression-valued parameter/generic slice.
- Important continuity note:
  - [perl/FSM/ParameterValueSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ParameterValueSupport.pm)
    now accepts operator-first scalar parameter/generic expressions such as
    `(+ WIDTH 1)`, `(* LANES 2)`, or `(and MASK 8'hF0)`,
  - this applies to direct-root `+params`, `.rtlif` parameter/generic defaults,
    external `?rtl` instance overrides, and generated `?fsmc` / `?dtc`
    overrides,
  - operands resolve through the semantic scalar value path, including
    same-root direct params where applicable and composition top/package symbols
    where those scopes are already valid,
  - scalar leaves inside list/record aggregates are valid operands, including
    nested leaves and aggregate parameter default leaves such as `P_LIST[0]`,
  - whole aggregate roots and aggregate subtrees remain blocked only as operands
    in this scalar-expression slice; aggregate operands belong to the separate
    aggregate-expression slice or to future typed aggregate-operator slices,
  - this must not be read as a scalar-only parameter/generic model: parameters
    and generics may be scalar or aggregate semantic values; the first aggregate
    expression slice now exists, while richer aggregate operator expressions should
    be accepted only when the operator is defined for the operand aggregate
    types/shapes,
  - width inference remains conservative for scalar expressions,
  - and this is intentionally semantic pre-generation normalization, not raw HDL
    expression passthrough.

## 2026-04-12: advanced DT enable control means activation regions
- Saved the clarification that the future authored DT enable-control feature is
  not merely syntax on a classic FSM. A single-initial-state, one-active-state
  FSM is the conservative subset; the broader model treats state/DT blocks as
  activation regions.
- Important continuity note:
  - a region's activity may come from normal FSM state decode, the current
    default `dt_enable = 1`, an external actor, or a validated logical
    expression,
  - the feature should permit multiple active state-like regions and external
    activation/deactivation outside the strict transition graph,
  - it must also report hazards explicitly: same-target drives, conflicting
    assignment families, merge/priority policy, assertion hooks, and debug
    reporting,
  - this remains a future advanced/power-user feature with intent-level
    semantics and pre-generation validation, not hidden backend-only HDL magic,
  - [docs/book/src/03-decision-trees-and-fsms.md](/Users/richarddje/Documents/github/fsmgen/docs/book/src/03-decision-trees-and-fsms.md)
    now carries the richer book explanation, while
    [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md)
    carries the short user-facing note.

## 2026-04-12: future authored DT enable control is recorded
- Captured the user steering around the hidden DT/state activity input.
- Important continuity note:
  - current `.fsm` authoring effectively treats each normal DT/state block's conceptual `dt_enable` as tied to `1` once its surrounding root/state context is active,
  - this should become an advanced semantic feature later: an authored DT/state enable expression that defaults to `1`, can be driven by an input signal or bounded logical expression such as an OR of several conditions, and is checked before generation,
  - the feature should support independently activatable DT/state regions, including designs that behave like they have multiple initial/entry states,
  - this must be represented in frontend AST/IR and validation rather than patched into generated HDL late,
  - [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/book/src/03-decision-trees-and-fsms.md](/Users/richarddje/Documents/github/fsmgen/docs/book/src/03-decision-trees-and-fsms.md), and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) now carry the steering note.

## 2026-04-12: direct `+params` now resolve sibling parameter defaults safely
- Saved the bounded `R11` direct param-to-param default slice.
- Important continuity note:
  - direct-root `+params` blocks are now collected and resolved as one dependency graph before direct behavior blocks are parsed,
  - same-root direct parameter defaults may reuse other direct params, including forward references and aggregate parameter aliases,
  - dependency order is no longer user-visible when the graph is acyclic, while duplicate parameter names and cycles fail before generation with targeted diagnostics,
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm)
    now parses `+define` before resolving collected `+params`, then parses behavior after parameter metadata is available,
  - [perl/FSM/Adapter/FSMGenFull/SignalManager.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalManager.pm)
    can expose resolved parameter payloads through the parameter/generic value resolver,
  - [t/30-language-contract-symbol-definitions.t](/Users/richarddje/Documents/github/fsmgen/t/30-language-contract-symbol-definitions.t),
    [t/51-language-contract-symbol-definition-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/51-language-contract-symbol-definition-boundary.t),
    and [t/76-language-contract-symbol-definition-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/76-language-contract-symbol-definition-entrypoints.t)
    lock sibling/forward references, aggregate parameter aliases, cycle diagnostics, and no-output CLI behavior.

## 2026-04-12: generated-child parameter overrides now target child `+params`
- Saved the bounded `R11` generated-child parameter/generic override slice.
- Important continuity note:
  - `?fsmc` and `?dtc` instances may now carry one semantic `(params (NAME value) ...)` block, including the defaulted-source form on named children,
  - [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm)
    shares the parameter override parser across external `?rtl` and generated-child instances while preserving `origin_kind => generated_child_parameter_override`,
  - [perl/FSM/Composition/ParameterOverrideResolver.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ParameterOverrideResolver.pm)
    now resolves deferred composition-top and imported-package symbols for every instance that carries overrides, not only `?rtl`,
  - [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm)
    validates override names against the realized child's direct `(+params ...)` declarations and validates aggregate override shape against the child default's inferred aggregate type,
  - valid generated-child overrides now preserve through realized instances, Intent HIR, structural RTL IR, and current SystemVerilog `#(...)` generated-child instance emission,
  - [t/292-composition-generated-child-parameter-overrides.t](/Users/richarddje/Documents/github/fsmgen/t/292-composition-generated-child-parameter-overrides.t)
    locks success, undeclared-override rejection, aggregate-shape rejection, and CLI no-output failures,
  - and the remaining parameter/generic follow-ups are now VHDL generic-map lowering plus richer non-literal semantic values, not the generated-child SV path.

## 2026-04-11: direct `+params` now preserve parameter references through SV emission
- Saved the bounded `R11` direct-parameter reference-preservation slice.
- Important continuity note:
  - [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm)
    now has `FSM::CoreAST::ParameterRef` for named HDL parameter leaves,
  - [perl/FSM/Adapter/FSMGenFull/SignalManager.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalManager.pm)
    resolves direct-root parameter symbols to `ParameterRef` nodes instead of
    literal clones of their defaults,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm)
    emits direct generated-module `#(...)` parameter declarations from semantic
    module metadata,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/OperandContractValidationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/OperandContractValidationSupport.pm)
    now treats semantic module parameter names as valid non-signal operands
    during pre-generation operand validation,
  - unsized scalar parameter defaults remain width-implicit as references, while
    explicitly sized defaults and packed aggregate defaults can provide exact
    width where pre-generation width contracts need it,
  - [t/30-language-contract-symbol-definitions.t](/Users/richarddje/Documents/github/fsmgen/t/30-language-contract-symbol-definitions.t)
    now proves `ParameterRef` AST preservation plus generated SV references
    such as `C = P0` and `W = P_LIST`,
  - and that follow-up is now covered by the 2026-04-12 generated-child
    override slice above, which targets these real child-module parameters
    rather than fake literal-substituted internals.

## 2026-04-11: `.rtlif` declaration defaults can reuse imported package symbols
- Saved the bounded `R11` package-backed `.rtlif` default-value slice.
- Important continuity note:
  - `.rtlif` `(params (NAME default_value) ...)` defaults may now use
    package-qualified symbols from packages imported by the consuming
    composition source, such as `param_pkg.DEFAULT_WIDTH`,
    `param_pkg.DEFAULT_LANES`, or `param_pkg.frame_mode.RUN`,
  - [perl/FSM/Composition/RTLChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLChildRealizer.pm)
    passes the post-import top symbol table into
    [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm),
  - the loader resolves only package-qualified names whose first segment is an
    imported package, so sidecar metadata does not silently depend on
    unqualified top-local constants or enums,
  - unresolved package-qualified defaults still fail before planning or HDL
    emission,
  - [t/91-composition-multi-rtl-children.t](/Users/richarddje/Documents/github/fsmgen/t/91-composition-multi-rtl-children.t)
    now locks package-backed scalar/list/record `.rtlif` defaults plus the
    unresolved-default no-output failure,
  - and VHDL generic-map lowering remains an explicit future contract, while
    generated-child parameterization is covered by the 2026-04-12 slice above.

## 2026-04-11: external `?rtl` parameter overrides can reuse top/package symbols
- Saved the bounded `R11` external-RTL symbolic override-value slice.
- Important continuity note:
  - `?rtl` `(params (NAME value) ...)` override values may now reuse
    composition-top `+constants`, `+enums`, whole aggregate roots, and imported
    package symbols such as `param_pkg.RESET_A5` or `param_pkg.LANES`,
  - [perl/FSM/Composition/ParameterOverrideResolver.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ParameterOverrideResolver.pm)
    resolves deferred symbolic override values after
    [perl/FSM/Composition/PackageImportResolver.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/PackageImportResolver.pm)
    loads packages into `TopSymbols`,
  - unresolved override value names still fail before planning or HDL emission,
  - [t/91-composition-multi-rtl-children.t](/Users/richarddje/Documents/github/fsmgen/t/91-composition-multi-rtl-children.t)
    now locks local constants, package constants, aggregate roots, enum-backed
    aggregate leaves, SV `#(...)` emission, and unresolved-symbol no-output
    failure,
  - [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md)
    now records the updated `120` / `119` import-tree snapshot and the new
    parameter-override resolver owner in the composition spine,
  - `.rtlif` parameter/generic declaration defaults are now superseded by the
    later package-backed default-value slice above,
  - and VHDL generic-map lowering remains explicit future work, while
    generated-child parameterization is covered by the 2026-04-12 slice above.

## 2026-04-11: direct `+params` can reuse named semantic values
- Saved the bounded `R11` direct-parameter symbol-reuse slice.
- Important continuity note:
  - direct-root `(+params ...)` values can now point at resolved `+constants`,
    enum members such as `mode.BUSY`, whole aggregate constant roots, and
    already-parsed direct `+define` literals,
  - [perl/FSM/ParameterValueSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ParameterValueSupport.pm)
    remains the neutral normalization owner and now accepts an optional symbol
    payload resolver for this use case,
  - [perl/FSM/Adapter/FSMGenFull/SignalManager.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalManager.pm)
    owns the direct-root parameter-value symbol lookup,
  - the earlier no-param-to-param boundary is now superseded by the 2026-04-12
    direct param-to-param dependency-graph slice above,
  - [t/30-language-contract-symbol-definitions.t](/Users/richarddje/Documents/github/fsmgen/t/30-language-contract-symbol-definitions.t)
    now proves constant-backed, enum-backed, and aggregate-backed params lower
    to the expected semantic literal payloads and remain visible in Intent HIR,
  - and VHDL generic-map lowering remains an explicit future contract, while
    generated-child parameterization is covered by the 2026-04-12 slice above.

## 2026-04-11: direct `+params` now share parameter/generic value normalization
- Saved the bounded `R11` direct-parameter normalization slice.
- Important continuity note:
  - [perl/FSM/ParameterValueSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ParameterValueSupport.pm)
    is now the neutral owner for bounded scalar and aggregate parameter/generic
    value normalization,
  - [perl/FSM/Composition/ParameterValueSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ParameterValueSupport.pm)
    remains as a compatibility shim rather than the semantic owner,
  - direct-root `(+params ...)` now accepts scalar integer forms such as `8`,
    `8'hA5`, `'hA5`, `0xA5`, `0b1010`, and `0o77`, plus bounded literal
    aggregate payloads that lower to one packed literal,
  - direct parameter metadata is now recorded on the semantic module so Intent
    HIR exposes `parameter_names` for direct roots,
  - malformed direct `+params` entries still fail through the parser-fronted
    targeted diagnostics before HDL emission,
  - and the explicit source-level override binding follow-up is now covered by
    the 2026-04-12 generated-child override slice above.

## 2026-04-11: external `?rtl` parameter/generic overrides now have a first semantic slice
- Saved the bounded `R11` external-RTL parameter/generic override slice.
- Important continuity note:
  - `.rtlif` roots may now include one `(params (NAME default_value) ...)`
    block beside declaration-ordered port tokens,
  - `?rtl` instances may now include semantic `(params (NAME value) ...)`
    override blocks, either with flat alias syntax such as
    `(?rtl:u_uart uart_tx (params (WIDTH 16)))` or nested module syntax such
    as `(?rtl:u_uart (module uart_tx) (params (WIDTH 16)))`,
  - override/default values currently accept bounded scalar integer literals
    such as `8`, `8'hA5`, `'hA5`, `0xA5`, `0b1010`, and `0o77`, plus bounded
    literal aggregate payloads such as `(8'hA5 8'h3C)` and
    `((mode 2'b10) (flag 1))`,
  - [perl/FSM/ParameterValueSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ParameterValueSupport.pm)
    owns that normalization policy and preserves inferred list/record type
    shape while lowering aggregate values to one packed literal for the current
    Verilog-family backend,
  - override names are validated against the loaded `.rtlif` declaration
    contract before structural generation, and aggregate overrides must match
    the aggregate shape inferred from the `.rtlif` default value,
  - validated overrides now flow through
    [perl/FSM/Composition/Instance.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Instance.pm),
    [perl/FSM/Composition/RealizedInstance.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RealizedInstance.pm),
    structural RTL IR, and the current Verilog-family backend,
  - [perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm)
    lowers the shipped slice to SystemVerilog `#(...)` instance parameters,
  - and VHDL generic-map lowering plus richer non-literal semantic override
    values remain follow-up work; the generated-child SV override path is now
    covered by the 2026-04-12 slice above.

## 2026-04-11: `?rtl` aliases now reuse one `.rtlif` contract
- Saved the bounded `R11` external-RTL reuse slice.
- Important continuity note:
  - [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm)
    now parses `(?rtl:instance_name module_name)` as an explicit instance
    alias while keeping `(?rtl:module_name)` as shorthand,
  - [t/14-composition-parser.t](/Users/richarddje/Documents/github/fsmgen/t/14-composition-parser.t)
    locks parser-level shorthand and alias behavior,
  - [t/91-composition-multi-rtl-children.t](/Users/richarddje/Documents/github/fsmgen/t/91-composition-multi-rtl-children.t)
    locks the end-to-end case where `u_uart_a` and `u_uart_b` both reuse the
    `uart_tx` `.rtlif` contract,
  - [t/291-composition-rtl-child-source-shape-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/291-composition-rtl-child-source-shape-diagnostics.t)
    now locks rejection of unsupported nested `?rtl` payloads and multi-module alias payloads
    through both pipeline and CLI,
  - and the parameter/generic override seam that was noted here is now
    superseded by the later 2026-04-11 semantic override slice above.

## 2026-04-11: root/structure `.rtlif` failures are now in the corpus
- Saved the bounded `R12` support-accounting follow-up for missing `.rtlif`
  roots, empty roots, nested sidecar structures, and duplicate embedded roots.
- Important continuity note:
  - `contract.missing_rtlif_root`,
    `contract.empty_rtlif_port_declaration`,
    `contract.nested_rtlif_port_declaration`, and
    `contract.duplicate_embedded_rtlif_root` are now classified as
    `expected_failure` under `composition_contract_rejection_pipeline_cli`,
  - the static fixture set is `missing_rtlif_root_top.fsm` /
    `missing_root_uart_tx.rtlif`, `empty_rtlif_port_top.fsm` /
    `empty_port_uart_tx.rtlif`, `nested_rtlif_port_top.fsm` /
    `nested_port_uart_tx.rtlif`, plus the same-source
    `duplicate_embedded_rtlif_top.fsm` embedded-root fixture,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    now expects `27` catalog entries and `17` explicit expected-failure
    entries,
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
    proves all four reject through both pipeline and CLI with their respective
    `RTL interface metadata structure`, `RTL interface metadata port presence`,
    `RTL interface metadata flatness`, and
    `RTL interface metadata embedded-root uniqueness` boundaries,
  - and the focused diagnostics remain separately locked in
    [t/118-composition-rtlif-root-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/118-composition-rtlif-root-diagnostics.t),
    [t/123-composition-rtlif-empty-port-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/123-composition-rtlif-empty-port-diagnostics.t),
    [t/124-composition-rtlif-flatness-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/124-composition-rtlif-flatness-diagnostics.t),
    and [t/125-composition-embedded-rtlif-duplicate-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/125-composition-embedded-rtlif-duplicate-diagnostics.t).

## 2026-04-11: token-scoped `.rtlif` failures are now in the corpus
- Saved the bounded `R12` support-accounting follow-up for unsupported
  `.rtlif` port types, invalid `.rtlif` port tokens, and non-positive `.rtlif`
  port widths.
- Important continuity note:
  - `contract.invalid_rtlif_port_type`, `contract.invalid_rtlif_port_token`,
    and `contract.invalid_rtlif_port_width` are now classified as
    `expected_failure` under `composition_contract_rejection_pipeline_cli`,
  - the static fixture pairs are `invalid_rtlif_port_type_top.fsm` /
    `invalid_type_uart_tx.rtlif`, `invalid_rtlif_port_token_top.fsm` /
    `invalid_token_uart_tx.rtlif`, and `invalid_rtlif_port_width_top.fsm` /
    `invalid_width_uart_tx.rtlif`,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    then expected `23` catalog entries and `13` explicit expected-failure
    entries before the later root/structure `.rtlif` corpus slice raised the
    current counts to `27` and `17`,
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
    proves all three reject through both pipeline and CLI with their respective
    `RTL interface metadata port typing`, `RTL interface metadata token shape`,
    and `RTL interface metadata port sizing` boundaries,
  - and the focused diagnostics remain separately locked in
    [t/119-composition-rtlif-type-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/119-composition-rtlif-type-diagnostics.t),
    [t/120-composition-rtlif-token-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/120-composition-rtlif-token-diagnostics.t),
    and [t/121-composition-rtlif-width-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/121-composition-rtlif-width-diagnostics.t).

## 2026-04-11: duplicate `.rtlif` port declarations are now in the corpus
- Saved the bounded `R12` support-accounting follow-up for the `.rtlif`
  duplicate-port declaration contract.
- Important continuity note:
  - [t/corpus/duplicate_rtlif_port_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/duplicate_rtlif_port_top.fsm)
    and [t/corpus/duplicate_port_uart_tx.rtlif](/Users/richarddje/Documents/github/fsmgen/t/corpus/duplicate_port_uart_tx.rtlif)
    now form the static expected-failure fixture,
  - `contract.duplicate_rtlif_port_declaration` is classified as
    `expected_failure` under `composition_contract_rejection_pipeline_cli`,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    then expected `20` catalog entries and `10` explicit expected-failure
    entries before the later token-scoped `.rtlif` corpus slice raised the
    current counts to `23` and `13`,
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
    proves the fixture rejects through both pipeline and CLI with the blocked
    `RTL interface metadata port declaration uniqueness` boundary,
  - and the fixture deliberately uses `duplicate_port_uart_tx` so the older
    `uart_tx` sidecar tests keep their exact diagnostic focus.

## 2026-04-11: invalid `.rtlif` system-role direction is now in the corpus
- Saved the bounded `R12` support-accounting follow-up for the recently hardened
  `.rtlif` system-role direction contract.
- Important continuity note:
  - [t/corpus/invalid_rtl_system_direction_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/invalid_rtl_system_direction_top.fsm)
    and [t/corpus/invalid_sysdir_uart_tx.rtlif](/Users/richarddje/Documents/github/fsmgen/t/corpus/invalid_sysdir_uart_tx.rtlif)
    now form the static expected-failure fixture,
  - `contract.invalid_rtl_system_port_direction` is classified as
    `expected_failure` under `composition_contract_rejection_pipeline_cli`,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
    then expected `19` catalog entries and `9` explicit expected-failure
    entries before the later duplicate-port corpus slice raised that snapshot
    to `20` and `10`, and the later token-scoped `.rtlif` slice raised the
    current counts to `23` and `13`,
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
    proves the fixture rejects through both pipeline and CLI with the blocked
    `RTL interface metadata system-port direction` boundary,
  - and the fixture deliberately uses `invalid_sysdir_uart_tx` so the older
    `uart_tx` missing-sidecar corpus entry remains a true missing-metadata
    test.

## 2026-04-11: `.rtlif` system-port direction summaries are now locked
- Saved the bounded `R11` failure-summary hardening follow-up for the new
  `.rtlif` system-role direction diagnostic.
- Important continuity note:
  - [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t)
    now covers both pipeline and CLI summaries for
    `core_clk>:clock`-style failures,
  - those summaries keep the resolved `RTL metadata file`, token context,
    blocked `RTL interface metadata system-port direction` boundary, and
    concise reason,
  - [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm)
    did not need a production-code change because its existing extraction
    rules already handled the new diagnostic shape,
  - and future `.rtlif` contract diagnostics should continue to get both raw
    validator coverage and short-summary coverage when they introduce a new
    blocked boundary.

## 2026-04-11: `.rtlif` clock/reset categories are now system-input-only
- Saved the bounded `R11` `.rtlif` contract-hardening slice.
- Important continuity note:
  - [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm)
    now rejects typed `.rtlif` output-direction system-role tokens such as
    `core_clk>:clock` and `rst_async_n>:reset`,
  - the accepted meaning is that `clock` and `reset` are interface-role
    annotations for external RTL system inputs, not HDL data types and not
    child-driven system outputs,
  - ordinary `data` outputs remain valid, for example `txd>:data`,
  - [t/88-rtlif-typed-port-contract.t](/Users/richarddje/Documents/github/fsmgen/t/88-rtlif-typed-port-contract.t)
    locks direct loader rejection, pipeline diagnostic context, and CLI
    failure-without-output behavior,
  - docs now record the same rule in the user guide, mdBook composition
    chapter, composition scope, and legacy mapping note,
  - and the next honest `.rtlif` contract seam remains a stronger
    interface-source layer above the current flat metadata mini-contract, not
    loosening the current system-role categories.

## 2026-04-11: aggregate top-expression inference sees declared and inferred roots
- Saved the next bounded `R11` aggregate top-expression inference slice.
- Important continuity note:
  - [perl/FSM/Composition/TopPortInferenceBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/TopPortInferenceBuilder.pm)
    now treats declared or already inferred aggregate top-port paths such as
    `in_frame.tag` as exact-width operands while inferring one remaining
    omitted whole top-port operand in explicit-toplink concat/repeat inference,
  - this mirrors the planner's existing fallback for ambiguous two-part tokens:
    if `in_frame` is a declared or inferred top port with an aggregate
    contract, `in_frame.tag` is a top aggregate path rather than a missing
    child endpoint,
  - expression width annotation is intentionally deferred until after
    whole-root top-port inference scans the current `?toplink` block, so the
    accepted inferred-root behavior is order-independent within that block,
  - aggregate roots needed by explicit top expressions may now also be inferred
    from an unlinked same-name child input when that child input has one uniform
    record/list declared-type contract; this lets `in_frame.tag` work when
    `consumer.in_frame` is already a typed same-name child input,
  - the same-name child-input compatibility checks for width, interface type,
    and declared type contract are now centralized inside
    `TopPortInferenceBuilder`, so future type-core widening has one place to
    update for this inference family,
  - undeclared aggregate roots still do not autovivify broadly; they now fail
    with a user-facing diagnostic that says the root top port needs a declared
    aggregate type before member/item access can guide inference,
  - [t/288-composition-aggregate-top-expression-inference.t](/Users/richarddje/Documents/github/fsmgen/t/288-composition-aggregate-top-expression-inference.t)
    locks the accepted `/in_frame.tag,payload/sink.data_in/` case for both
    declared roots, explicit same-block inferred roots, and same-name typed
    child-input inferred roots, plus the blocked undeclared-root diagnostic,
  - and the next honest aggregate-inference seam remains broader
    autovivification only when the frontend can recover one safe shape and the
    backend can lower it honestly.

## 2026-04-11: composition source-expression parsing now has one owner
- Saved the `R11` composition source-expression spec extraction slice.
- Important continuity note:
  - [perl/FSM/Composition/SourceExpressionSpecSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/SourceExpressionSpecSupport.pm)
    now owns bounded explicit-toplink source-expression parsing for top/child
    bit-selects, slices, aggregate paths, concat groups, repeat groups,
    literal operands, top-symbol payload lookup, and inference/child-base
    collection,
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm)
    now delegates that parser/spec surface while keeping endpoint resolution,
    aggregate compatibility, carrier allocation, binding preservation, and the
    rich composition diagnostics,
  - [t/287-composition-source-expression-spec-support.t](/Users/richarddje/Documents/github/fsmgen/t/287-composition-source-expression-spec-support.t)
    locks the support owner directly,
  - existing composition expression coverage in [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t),
    [t/267-composition-top-expression-top-outputs.t](/Users/richarddje/Documents/github/fsmgen/t/267-composition-top-expression-top-outputs.t),
    and [t/275-composition-top-aggregate-values.t](/Users/richarddje/Documents/github/fsmgen/t/275-composition-top-aggregate-values.t)
    stays green through the delegated path,
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm)
    now measures `1824` lines after the extraction,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md)
    now records the updated `118` reachable project files and `117`
    reachable `.pm` packages snapshot.

## 2026-04-11: composition actual literal policy now has one owner
- Saved the `R11` composition actual-literal extraction slice.
- Important continuity note:
  - [perl/FSM/Composition/ActualLiteralSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ActualLiteralSupport.pm)
    now owns composition open/numeric actual endpoint parsing, exact-width
    literal lowering, intrinsic-width concat-operand literal lowering,
    target-width direct-actual widening and overflow rejection, and actual
    binding type-contract construction,
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm)
    now delegates actual literal policy while keeping explicit-link planning,
    symbol lookup, aggregate compatibility checks, carrier allocation, and the
    rich composition diagnostics,
  - [t/286-composition-actual-literal-support.t](/Users/richarddje/Documents/github/fsmgen/t/286-composition-actual-literal-support.t)
    locks the support owner directly,
  - existing end-to-end coverage in [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t),
    [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t),
    and [t/267-composition-top-expression-top-outputs.t](/Users/richarddje/Documents/github/fsmgen/t/267-composition-top-expression-top-outputs.t)
    stays green against the delegated path,
  - the static import closure from [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen)
    measured `117` reachable project files and `116` reachable `.pm`
    packages before the later same-day source-expression support extraction
    superseded that count,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md)
    now records the new post-extraction hotspot shape: [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm)
    is again the largest reachable file, while [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm)
    remains a major `R11` composition-planning seam instead of owning actual
    literal mechanics inline.

## 2026-04-11: session bootstrap refreshed the `bin/fsmgen` import-tree snapshot
- Saved the README/session-bootstrap execution pass.
- Important continuity note:
  - [README.md](/Users/richarddje/Documents/github/fsmgen/README.md) remains the single entry point,
  - [SESSION_BOOTSTRAP.md](/Users/richarddje/Documents/github/fsmgen/SESSION_BOOTSTRAP.md) still asks a new session to read the README-linked docs, analyze [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) plus its project-owned import tree, refresh [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) if stale, and then continue against [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md),
  - the bootstrap-time static import closure from [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) measured `116` reachable project files and `115` reachable `.pm` packages before the later same-day actual-literal extraction superseded that count,
  - the new measurement makes the semantic `FSM::Package::*` family visible as a first-class live spine under direct and composition paths,
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) was then the largest reachable file in the static closure because explicit-link actuals, source expressions, aggregate checks, and binding type contracts had accumulated there,
  - [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) is now refreshed to the `2026-04-11` import-tree snapshot,
  - and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) pointed future sessions at the `116` / `115` measured snapshot instead of the stale `97` / `96` one before the later same-day `117` / `116` and then `118` / `117` refreshes.

## 2026-04-10: reset policy now matches sreset/areset intent
- Saved the reset-contract correction slice.
- Important continuity note:
  - canonical `(sreset reset)` is synchronous active-high,
  - canonical `(areset rst_n)` is asynchronous active-low,
  - default mode still accepts legacy `(asreset rstn)` and misleading
    `(sreset rstn)` compatibility forms,
  - strict mode now rejects `(asreset rstn)` and active-low-looking `sreset`
    names such as `(sreset rstn)`,
  - `FSM::Synthesis::EnableGraph::ModulePlanningSupport` now owns reset-aware
    SystemVerilog event-control and reset-condition helpers,
  - direct SystemVerilog state registers, flop muxes, and delayed-pulse logic
    now consume those helpers,
  - lifted composition shared-datapath registers now recover reset policy
    from participating generated children and reject incompatible child
    policies instead of hardcoding active-low asynchronous reset,
  - the legacy template-backed SystemVerilog backend now honors the same reset
    policy metadata and has a regression in
    [t/282-legacy-systemverilog-backend-reset-policy.t](/Users/richarddje/Documents/github/fsmgen/t/282-legacy-systemverilog-backend-reset-policy.t),
  - and docs/book examples now teach active-high synchronous reset names like
    `reset` and active-low asynchronous reset names like `rst_n`.

## 2026-04-10: direct RHS concat pack now has a first shipped slice
- Saved one bounded pack/deconstruct-lane implementation step.
- Important continuity note:
  - [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm)
    now accepts direct RHS `(concat ...)` and `(cat ...)` forms and preserves
    them as `FSM::CoreAST::Concatenation`,
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm)
    now records exact summed concat RHS widths in assignment width contracts,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/OperandContractValidationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/OperandContractValidationSupport.pm)
    now prefers the authored RHS rendering in width-contract diagnostics, so
    mismatch errors name `{HI, LO}` instead of a failed internal padded AST,
  - and [t/29-language-contract-core-forms.t](/Users/richarddje/Documents/github/fsmgen/t/29-language-contract-core-forms.t)
    plus [t/270-systemverilog-assignment-width-contract-validation.t](/Users/richarddje/Documents/github/fsmgen/t/270-systemverilog-assignment-width-contract-validation.t)
    lock parsing, emitted SV concat text, and pre-generation width rejection.
- LHS deconstruction is still future work; do not imply it shipped with this
  RHS pack slice.

## 2026-04-10: partial aggregate LHS validation now keeps leaf contracts
- Saved one pre-generation validation hardening slice for aggregate
  assignments.
- Important continuity note:
  - [perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm)
    now preserves per-assignment aggregate source/target contract entries
    while partial LHS writes are normalized into full base-signal mux inputs,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/OperandContractValidationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/OperandContractValidationSupport.pm)
    now validates whole aggregate RHS values against the actual aggregate leaf
    target contract, such as `OUT.payload`, instead of the normalized base
    signal contract, and delegates fallback target-contract extraction back to
    the assignment-support owner,
  - and [t/270-systemverilog-assignment-width-contract-validation.t](/Users/richarddje/Documents/github/fsmgen/t/270-systemverilog-assignment-width-contract-validation.t)
    locks both compatible aggregate leaf writes and incompatible width-equal
    shape failures before emission, while [t/276-direct-local-aggregate-values.t](/Users/richarddje/Documents/github/fsmgen/t/276-direct-local-aggregate-values.t)
    now locks the same behavior end to end through pipeline and CLI runs.

## 2026-04-10: aggregate path traversal now has one package-level owner
- Saved the follow-up hardening slice after composition aggregate path
  traversal was centralized.
- Important continuity note:
  - [perl/FSM/Package/AggregatePathSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Package/AggregatePathSupport.pm)
    now owns declared aggregate path traversal at the type/package layer,
  - [perl/FSM/Composition/AggregatePathSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/AggregatePathSupport.pm)
    now wraps the package-level path segments into structural connection
    expressions for composition,
  - [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm)
    now consumes that same resolver for direct-root typed aggregate AST refs,
  - [perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm)
    now consumes the same package-level helper for packed base-signal range
    mapping on partial aggregate LHS writes,
  - and [t/284-package-aggregate-path-support.t](/Users/richarddje/Documents/github/fsmgen/t/284-package-aggregate-path-support.t)
    locks the frontend-neutral path segment, packed-range, and failure-code
    contract.

## 2026-04-10: composition aggregate path support now has one wrapper
- Saved one internal hardening slice for aggregate source-expression work.
- Important continuity note:
  - [perl/FSM/Composition/AggregatePathSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/AggregatePathSupport.pm)
    introduced the shared composition-side aggregate member/item path support
    wrapper,
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm)
    keeps the rich explicit-link diagnostics on top of that shared wrapper,
  - [perl/FSM/Composition/ProvenanceReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ProvenanceReportBuilder.pm)
    uses the same support surface for leaf width/type reporting,
  - and [t/283-composition-aggregate-path-support.t](/Users/richarddje/Documents/github/fsmgen/t/283-composition-aggregate-path-support.t)
    locks the helper's success and stable failure-code surface.

## 2026-04-10: composition aggregate source provenance now resolves leaf facts
- Saved one hardening slice for the aggregate source-expression lane.
- Important continuity note:
  - `FSM::Composition::ProvenanceReportBuilder->endpoint_context` now resolves
    declared aggregate top-port and generated-child source paths against the
    preserved declared type spec,
  - metadata for expressions like `in_frame.tag`, `in_frame.payload[1]`, and
    `producer.OUT_FRAME.payload[1]` now reports the leaf width/type instead of
    the whole base endpoint width or a generic bit-like default,
  - and base top-port / child-endpoint contexts now carry
    `declared_type_name` / `declared_type_spec` when available for embedding
    consumers.

## 2026-04-10: composition links can now source typed aggregate members/items
- Saved the next typed aggregate composition slice.
- Important continuity note:
  - `?toplink` source-side expressions now accept declared aggregate top-port
    paths such as `in_frame.tag` and `in_frame.payload[1]`,
  - they also accept declared aggregate generated-child output paths such as
    `producer.OUT_FRAME.tag` and `producer.OUT_FRAME.payload[1]`,
  - child-output aggregate projections reuse the existing child-source carrier
    rule, preserving the child output's declared aggregate type on the carrier
    before applying member/item access,
  - authored list indexes still lower through the packed typedef field
    convention such as `.item_1`,
  - and [t/282-composition-aggregate-source-expression-contracts.t](/Users/richarddje/Documents/github/fsmgen/t/282-composition-aggregate-source-expression-contracts.t) now locks both top-port and child-output aggregate member/item source bindings through pipeline and CLI generated HDL.

## 2026-04-10: future pack/deconstruct assignment syntax is only steering for now
- Saved one future aggregate assignment idea for later implementation.
- Important continuity note:
  - RHS packing and LHS deconstruction/destructuring look reasonable for
    FSMGen if they stay intent-level rather than becoming a verbatim clone of
    SV/VHDL syntax,
  - a future RHS pack would combine static-width expressions into one target,
    while a future LHS deconstruct would split one RHS across legal static
    lvalues,
  - authored left-to-right should map high-to-low in the packed value,
  - pre-generation checks must enforce declared/assigned operand legality,
    exact total-width compatibility, no accidental overlapping or duplicated
    LHS ranges, and coherent assignment-family semantics,
  - and generation should receive normalized AST/IR assignments rather than
    rediscovering pack/deconstruct semantics while rendering HDL.

## 2026-04-09: direct aggregate-typed signal access is now first-class AST
- Saved the next direct typed aggregate expression slice after direct
  aggregate typedef emission.
- Important continuity note:
  - direct-root `+size` signals with declared aggregate aliases now parse
    `FRAME.member` and `FRAME.list_member[1]`-style access into
    `FSM::CoreAST::AggregateRef` instead of silently collapsing the expression
    to the base signal,
  - the aggregate ref carries resolved path/type/width metadata and renders SV
    list indexes through the generated packed typedef field convention such as
    `.item_1`,
  - partial aggregate LHS writes now map back to the correct packed
    base-signal bit ranges during assignment analysis,
  - and [t/280-declarative-aggregate-types.t](/Users/richarddje/Documents/github/fsmgen/t/280-declarative-aggregate-types.t) now locks RHS aggregate member/list access plus partial aggregate LHS packing in generated SV.

## 2026-04-09: direct aggregate aliases now emit SV typedefs too
- Saved the matching direct generated-module aggregate-lowering slice after
  composition typedef emission landed.
- Important continuity note:
  - direct `?fsm` / `?dt` SystemVerilog module/internal declaration planning
    now preserves aggregate declared type metadata into emitted packed
    typedefs instead of flattening those declarations back to raw vectors,
  - module-header aggregate typedefs are emitted before the module when typed
    ports need them, while internal/helper aggregate typedefs are emitted
    inside the module before the declarations that use them,
  - and both direct generated modules and structural composition emission now
    share [perl/FSM/Backend/VerilogFamily/TypeDeclarationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/VerilogFamily/TypeDeclarationSupport.pm) for record/list typedef lowering.

## 2026-04-09: composition aggregate aliases now reach emitted SV typedefs
- Saved the next typed aggregate-lowering slice after structural type identity
  already survived planning and structural export.
- Important continuity note:
  - composition-top structural SystemVerilog emission now creates backend-owned
    local packed typedefs for declared aggregate aliases instead of flattening
    typed top ports and typed structural nets all the way back to raw vectors,
  - record aliases keep authored member names, list aliases become stable
    packed structs with `item_N` members,
  - and imported package-qualified alias names are sanitized into valid local
    emitted typedef identifiers.

## 2026-04-09: lifted shared-datapath carriers now exist as real structural nets
- Saved the next typed shared-datapath-runtime slice after typed candidate
  discovery and raw contributor nets landed.
- Important continuity note:
  - lifted runtime carriers such as `*_shared_q`, `*_shared_next`, and
    `*_shared_comb` are now explicit composition/structural nets instead of
    existing only as declaration text in `auxiliary_assignments`,
  - those lifted nets preserve an explicit declaration kind so the structural
    emitter can still emit `logic` declarations without duplicate `wire`
    declarations,
  - and uniform typed shared-datapath families now carry their declared type
    contract onto those lifted runtime nets too.

## 2026-04-09: do not confuse the public book with continuity notes
- Saved one documentation-boundary rule for future sessions.
- Important continuity note:
  - `docs/book/` is the public-facing user documentation surface and should
    carry every user-visible feature with real explanation and examples,
  - files like `DEVELOPMENT_NOTES.md`, `MEMORY.md`, `ROADMAP_STATUS.md`,
    `ROADMAP_V2.md`, and `CHANGES.md` are continuity artifacts for maintainer
    recovery and implementation steering,
  - and continuity coverage does not count as complete user documentation.

## 2026-04-09: shared-datapath typing now refuses incompatible typed families
- Saved the next typed shared-datapath slice after structural binding
  contracts became explicit.
- Important continuity note:
  - shared-datapath candidate discovery no longer merges one family when
    width-equal typed child outputs preserve incompatible declared type
    contracts,
  - uniform typed contributor families now preserve one candidate-level
    declared type contract in exported metadata,
  - typed contributor entries keep their own declared type identity too,
  - and private raw contributor nets synthesized during shared-datapath
    lifting now preserve contributor-side declared type identity in the
    structural export instead of flattening those carriers back to width-only
    metadata.

## 2026-04-09: typed composition bindings now preserve source contracts too
- Saved the next typed structural-handoff slice after direct typed gates were
  already landed.
- Important continuity note:
  - normalized structural bindings now preserve `connection_type_name` plus
    canonical `connection_type_spec` whenever the planner already knows one
    typed source contract,
  - that now covers plain typed signal bindings, inferred top/child expression
    bindings, whole aggregate actual bindings, and child-output carrier
    rebindings on both `composition_plan` instances and exported
    `structural_rtl_ir`,
  - and downstream lowering/reporting/embedder work should consume those
    preserved binding contracts directly instead of reconstructing aggregate
    meaning from width alone.

## 2026-04-09: `?ports` should behave more like an override surface than required boilerplate
- Saved one composition authoring rule for future sessions.
- Important continuity note:
  - the preferred direction is that `?ports` stays optional whenever the top
    boundary can be inferred safely,
  - future omitted-`?ports` widening should keep aiming at inference-first
    public boundaries,
  - and `?ports` should mainly be used to disambiguate, rename, freeze, or
    explicitly constrain the public interface rather than being required on
    every honest composition.

## 2026-04-09: typed aggregate direct targets now also check source expressions
- Saved the next typed aggregate slice after whole aggregate actuals and direct
  whole aggregate assignments became declared-type-aware.
- Important continuity note:
  - source-side top expressions and child expressions now preserve one inferred
    typed expression contract on the explicit-link path,
  - whole typed signal refs keep declared aggregate identity, bit/slice forms
    become scalar `bit` / `bits[N]`, and bounded concat/repeat forms become
    ordered `list<...>` contracts,
  - and width-equal but aggregate-shape-incompatible expression bindings into
    typed aggregate direct targets are now rejected explicitly instead of
    slipping through on packed width alone.

## 2026-04-09: direct whole aggregate RHS assignments now honor typed aggregate targets
- Saved the matching direct-root aggregate-typing slice after composition whole
  aggregate actuals became declared-type-aware.
- Important continuity note:
  - direct-root assignments now preserve whole aggregate RHS provenance for
    raw aggregate roots such as `FRAME` and `shared.FRAME`,
  - pre-generation operand-contract validation now rejects width-equal but
    aggregate-shape-incompatible direct assignments into typed aggregate
    `+size` targets,
  - and this keeps direct-root aggregate typing aligned with the now-shipped
    composition actual contract instead of leaving a width-only direct-path
    escape hatch.

## 2026-04-09: whole aggregate actual roots now honor typed direct-target contracts
- Saved the next typed explicit-actual slice after typed carrier nets landed.
- Important continuity note:
  - whole named aggregate actual roots such as `=FRAME` and `=shared.FRAME`
    now infer one canonical aggregate shape on the bounded direct actual path,
  - when those whole aggregate actuals bind directly to typed aggregate top
    outputs or typed aggregate child inputs, width-equal but
    aggregate-shape-incompatible targets are now rejected explicitly,
  - concat remains bit-oriented here, and scalar literal actuals still stay on
    the existing value-oriented literal path.

## 2026-04-09: the docs split now has a concrete plan artifact
- Saved the next documentation follow-through step after deciding the guide is
  already large enough to justify planning the split.
- Important continuity note:
  - the concrete migration plan now lives in
    [docs/BOOK_PLAN.md](/Users/richarddje/Documents/github/fsmgen/docs/BOOK_PLAN.md),
  - `docs/USER_GUIDE.md` is intended to become the landing page / table of
    contents,
  - the future `docs/book/` set should carry the progressive chapter flow,
  - and focused precision references like
    [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md)
    should stay separate.

## 2026-04-09: user docs should eventually become a book-like set
- Saved one explicit docs-architecture rule for future sessions.
- Important continuity note:
  - when `docs/USER_GUIDE.md` grows too large, split it into a book-like set
    with one Markdown file per major topic/chapter,
  - keep `docs/USER_GUIDE.md` as the landing page / table of contents,
  - organize chapters from beginner to advanced so users can learn FSMGen
    incrementally,
  - and keep realistic examples spread across that doc set so the surface
    stays approachable.

## 2026-04-08: inferred composition carrier nets now preserve declared type identity
- Saved the next typed structural handoff slice after explicit `?toplink`
  compatibility became declared-type-aware.
- Important continuity note:
  - inferred internal carrier nets now preserve `declared_type_name` plus
    canonical `declared_type_spec` when they are driven by one typed
    child-output family,
  - the live `composition_plan->nets` objects carry that metadata directly,
  - and exported `structural_rtl_ir->{nets}` now preserves the same typed net
    identity instead of flattening internal carriers to width-only metadata.

## 2026-04-08: explicit plain `?toplink` bindings are now declared-type-aware too
- Saved the next typed-composition compatibility slice after same-name
  convention and undeclared top-port inference were hardened.
- Important continuity note:
  - explicit plain port-to-port `?toplink` bindings now reject width-equal
    endpoints when both sides preserve incompatible `declared_type_spec`
    contracts,
  - the blocked failure-summary surface now keeps child-endpoint or top-port
    context for those explicit-link declared-type mismatches,
  - and expression/literal actual sources still stay on the existing typed
    structural path instead of pretending they are declared-type-preserving
    plain ports.

## 2026-04-08: same-name composition matching is now declared-type-aware
- Saved the next typed-composition slice after declared type identity survived
  the structural boundary.
- Important continuity note:
  - same-name undeclared top-input inference now rejects width-equal child
    input families when their preserved `declared_type_spec` contracts differ,
  - plain explicit top-port same-name convention, declared `=name`
    connect-by-name, and inferred internal-carrier re-export now consume that
    same declared-type boundary too,
  - and inferred undeclared top ports now preserve one shared
    `declared_type_name` / canonical `declared_type_spec` when the child-side
    evidence is uniform.

## 2026-04-08: declared type identity now survives through structural boundary metadata
- Saved the next honest typed-boundary slice after packed aggregate aliases
  landed.
- Important continuity note:
  - direct-root `+size` entries that resolve through named type aliases now
    preserve `declared_type_name` plus canonical `declared_type_spec` on live
    signals,
  - composition `?ports` now preserve that same metadata on top-port objects
    when their width tokens came from named type aliases,
  - realized generated-child interface ports now preserve the child source's
    declared type identity when that interface was declared through named
    aliases,
  - and `structural_rtl_ir` plus mirrored `module_info` now export that
    metadata on direct module ports, composition top ports, and realized child
    interface ports instead of flattening everything down to width, signedness,
    and state-model alone.

## 2026-04-08: user-facing docs must ship with the feature
- Saved one explicit product-level rule for future sessions:
  documentation quality is part of feature completion, not a later polish
  phase.
- Important continuity note:
  - every shipped user-facing language or CLI feature should be documented in
    the live user docs, not only in `CHANGES.md`,
  - docs should explain intent and supported boundaries plainly,
  - examples should be realistic and copyable so users feel invited to use the
    tool rather than intimidated by it,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md)
    plus [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md)
    are the primary user-facing owners for that contract.

## 2026-04-08: packed aggregate type aliases now ride the live `+types` lane
- Saved the next honest widening after scalar width/signed/state-model aliases
  landed cleanly.
- Important continuity note:
  - direct roots, composition tops, and semantic packages now accept packed
    `(list ...)` and `(record (field TYPE) ...)` aliases through one shared
    type canonicalization owner in
    [perl/FSM/Package/DeclarativeTypeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Package/DeclarativeTypeSupport.pm),
  - those aggregate aliases resolve without declaration-order dependence
    through the same declarative type scope as scalar aliases,
  - direct-root `+size` and composition `?ports` may now use those aggregate
    aliases on the live width path,
  - local composition aggregate aliases may now also contain imported package
    type members because deferred nested imported refs are preserved until
    semantic package import finalization,
  - exported `symbol_contract` / mirrored `module_info` now preserve
    aggregate type shape and authored `member_order`,
  - and the current live backend still lowers those aggregate aliases to one
    packed vector width instead of pretending portable record/typedef
    lowering is already complete.

## 2026-04-08: positive integer scalar symbols now feed the live width-token paths
- Saved the next bounded width-lane widening after imported/local scalar type
  alias support landed cleanly.
- Important continuity note:
  - direct-root `+size` entries may now use local or imported positive
    integer scalar symbols such as `BYTE_W` or `shared_cfg.BYTE_W`,
  - composition `?ports` width tokens may now use those same local/imported
    positive integer scalar symbols,
  - one shared helper in
    [perl/FSM/Package/ScalarWidthSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Package/ScalarWidthSupport.pm)
    now owns “does this scalar payload mean one positive integer width?” so
    the direct and composition width paths stay aligned,
  - and the next honest type-lane seam is no longer “shared numeric widths,”
    but richer semantic properties beyond raw width such as signedness and
    2-state versus 4-state intent.

## 2026-04-08: composition local type aliases may now target imported package scalar types
- Saved the next bounded follow-on slice after direct package-qualified
  imported composition width tokens landed.
- Important continuity note:
  - composition `+types` may now declare local aliases such as
    `(type byte_t shared_types.byte)` and then use those aliases on the
    `?ports` width path,
  - unresolved imported package type refs now lower first into one bounded
    deferred imported-alias marker inside
    [perl/FSM/Composition/TopSymbols.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/TopSymbols.pm),
  - [perl/FSM/Composition/PackageImportResolver.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/PackageImportResolver.pm)
    now finalizes those local aliases after semantic package imports land,
  - that also means dependent local aliases like `alias_t -> byte_t ->
    shared_types.byte` stay honest without reintroducing parser-order rules,
  - and the next honest `+types` seam is no longer “local aliases to imported
    package scalar types,” but broader semantic type properties beyond width.

## 2026-04-08: composition `?ports` imported scalar type aliases now ship on the live width path
- Saved the next honest follow-on slice after the first bounded scalar
  `+types` lane landed.
- Important continuity note:
  - composition `?ports` may now use direct package-qualified imported scalar
    type aliases such as `out_data>shared_types.byte` and
    `out_flag>shared_types.flag`,
  - authored width tokens now survive parsing on
    [perl/FSM/Composition/Port.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Port.pm)
    so imported width aliases can resolve after semantic package imports land,
  - [perl/FSM/Composition/PackageImportResolver.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/PackageImportResolver.pm)
    now also rebinds those deferred imported widths before planning,
  - [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm)
    now resolves composition package imports before `after_parse_source`
    extensions run so callers see the same fully resolved composition spec,
  - and the immediately following shipped slice now also covers local aliases
    that themselves point at imported package scalar types.

## 2026-04-08: future semantic types should carry backend-neutral meaning first
- Saved one more steering note for the richer future `+types` lane.
- Important continuity note:
  - the authored `.fsm` surface should stay intent-level rather than exposing
    raw backend spellings like SV `logic signed` or VHDL
    `std_logic_vector` as the main contract,
  - the internal type model should eventually carry width, signedness,
    2-state versus 4-state behavior, and role/category as semantic meaning,
  - backend lowering should choose concrete carriers late from that meaning,
    for example SV `bit` / `logic` plus signedness or VHDL
    `std_logic_vector` / `signed` / `unsigned`,
  - and explicit source-level type spellings should remain overrides or
    anchors when inference is not enough, not the default authoring style.

## 2026-04-08: bounded scalar `+types` now ship through one declarative resolver
- Saved the first real `+types` slice after the declaration-scope and
  symbol-contract groundwork landed.
- Important continuity note:
  - direct `?fsm` / `?dt` roots, composition `?top` roots, and `?pkg:name`
    packages now accept bounded scalar type aliases for `bit`, `(bits N)`, and
    named scalar aliases,
  - direct-root `+size` and local composition `?ports` widths may now use
    those aliases regardless of declaration order,
  - explicit type cycles now fail clearly,
  - imported package scalar types now feed the direct-root width path through
    the normal package projection lane,
  - composition `?ports` initially shipped as local-only in that first slice,
    but the live contract now also covers direct package-qualified imported
    scalar type aliases on the `?ports` width path,
  - and forward `symbol_contract` / mirrored `module_info` now preserve local
    type names/counts plus canonical scalar type specs for both direct and
    composition results.

## 2026-04-08: whole map aggregate roots now ship on the packed literal path
- Saved the next aggregate/type slice after declarative symbol scope landed.
- Important continuity note:
  - direct `?fsm` / `?dt` roots now accept whole map/hash-like aggregate
    roots such as `FRAME` and `shared.FRAME` in assignment RHS expressions
    and guard equality conditions,
  - bounded composition actual/concat positions now accept those same whole
    roots such as `=FRAME` and `=shared.FRAME`,
  - canonical aggregate payloads now preserve authored `member_order`,
  - whole hash-like roots now pack members left to right in declaration order
    when every nested leaf still lowers to one scalar literal,
  - and duplicate member names now fail explicitly instead of silently
    overwriting earlier members.

## 2026-04-08: declarative symbol scope now ships for constants and enums
- Saved the follow-through after the declaration-scope steering note.
- Important continuity note:
  - direct roots, composition tops, and `?pkg:name` packages now resolve
    `+constants` / `+enums` through one shared declarative resolver instead of
    parser order,
  - aggregate values may now reuse same-scope constants, enum members, and
    whole list-valued roots regardless of declaration order,
  - explicit dependency cycles now fail clearly on those same lanes,
  - and the next honest continuation is future `+types` on that same semantic
    resolution path rather than any return to parser-order behavior.

## 2026-04-08: later aggregate values now reuse earlier named scalar ingredients
- Saved the next bounded aggregate-authoring slice after whole-list aggregate
  roots landed.
- Important continuity note:
  - direct-root, composition-top, and `?pkg:name` aggregate values may now
    reuse same-scope constants, enum members, and whole list-valued roots such
    as `(HEADER (mode.BUSY RESET_BYTE))` and `(PACKET (HEADER mode.IDLE))`
    regardless of declaration order,
  - one shared symbol-projection helper now owns how canonical symbol payloads
    are fed back into scalar-expression parsing across direct roots,
    composition tops, packages, and imported package projection,
  - and the boundary stays honest: this is named-ingredient reuse, not a full
    typed aggregate system by itself.

## 2026-04-07: whole list aggregate roots now lower on the live direct/composition paths
- Saved the next aggregate/type groundwork slice after composition-top
  `symbol_contract` export landed.
- Important continuity note:
  - direct `?fsm` / `?dt` roots now accept whole list-valued aggregate roots
    such as `BYTES`, `TAIL`, or `shared.BYTES` in assignment RHS expressions
    and guard equality conditions,
  - bounded composition actual/concat positions now accept those same whole
    list-valued roots such as `=HEADER`, `=TAIL`, or `=shared.HEADER`,
  - one shared payload-lowering helper now owns that flattening rule,
  - and whole hash-like aggregate roots such as `FRAME` or `shared.FRAME`
    still fail explicitly until record field-order/type semantics are made
    real.

## 2026-04-07: composition-top symbol contracts now survive into forward IR and module_info
- Saved the next aggregate/type groundwork slice after direct-root
  `symbol_contract` export landed.
- Important continuity note:
  - composition `?top` results now preserve one bounded `symbol_contract`
    through composition-top `intent_hir` and mirrored `module_info`,
  - that surface now matches the direct-root contract shape for local
    constant/enum names and counts, canonical constant payloads, scalar-leaf
    convenience payloads, aggregate-root path summaries, and imported package
    names/counts,
  - composition-top aggregate constants now also serialize scalar leaves in the
    same wrapped payload form used by direct roots,
  - and future whole-aggregate/type work no longer has to rediscover the
    composition-top symbol layer from raw-spec residue.

## 2026-04-06: direct-root symbol contracts now survive into forward IR and module_info
- Saved the next aggregate/type groundwork slice after local direct-root
  aggregate constants landed.
- Important continuity note:
  - direct `?fsm` / `?dt` roots now preserve one bounded `symbol_contract`
    through `intent_hir` and mirrored `module_info`,
  - that surface currently includes local constant/enum names and counts,
    canonical constant payloads, scalar-leaf convenience payloads,
    aggregate-root path summaries, and imported package names/counts,
  - it does not claim whole-aggregate assignment/type flow is shipped yet,
  - but it gives future whole-aggregate/type work and future embedding/API work
    one explicit semantic handoff instead of forcing reparsing.

## 2026-04-06: local direct-root aggregate constants now work on scalar-leaf expression paths
- Saved the next direct-root aggregate symmetry slice after packages and
  composition-top locals landed.
- Important continuity note:
  - direct `?fsm` / `?dt` `(+constants ...)` entries may now be scalar
    literals, non-empty lists, or nested hash-like aggregates,
  - local direct-root references such as `BYTES[1]`, `FRAME.flag`, and
    `NEST.header.nibble` now resolve as literals in assignment RHS expressions
    and guard equality conditions,
  - unresolved whole aggregates such as `FRAME` now fail explicitly instead of
    degrading into generic signal names,
  - mixed local aggregate shapes are rejected explicitly at the direct-root
    parser boundary,
  - and whole-aggregate local-symbol flow/types remain future work.

## 2026-04-06: local composition-top aggregate constants now work on scalar-leaf actual paths
- Saved the next bounded composition symbol slice after package aggregate
  leaves landed.
- Important continuity note:
  - composition-top `(+constants ...)` entries may now be scalar literals,
    non-empty lists, or nested hash-like aggregates,
  - local top-root references such as `BYTES[1]`, `FRAME.flag`, and
    `NEST.header.nibble` now resolve on explicit `?toplink` direct-actual and
    concat-operand positions,
  - mixed local aggregate shapes are rejected explicitly at the composition
    parser boundary,
  - and whole-aggregate local-symbol flow/types remain future work.

## 2026-04-06: SV aggregates should be packed-first and VHDL aggregate promises should stay narrower
- Saved one more portability rule for the future aggregate/type lane.
- Important continuity note:
  - inferred frontend record/struct types should lower as packed structs by
    default in SystemVerilog,
  - looser unpacked-struct tool behavior should not become the portable
    frontend promise,
  - future VHDL nested record/array support should be promised only for the
    subset the backend can lower and regression-lock as synthesizable,
  - and richer inferred aggregate shapes must still fail explicitly on a
    backend that cannot represent them honestly.

## 2026-04-06: future aggregate types should autovivify from usage too
- Saved one more steering rule for the future typed aggregate lane.
- Important continuity note:
  - aggregate variables should infer by default from member/index/LHS/RHS
    usage,
  - member access should grow record/struct shape and index access should
    grow list/array shape,
  - nested list/record/list structure should autovivify when one safe shape
    is recoverable from authored usage,
  - and the backend must either lower that inferred shape honestly or fail
    explicitly if the chosen HDL target cannot represent it safely.

## 2026-04-06: future `.fsm` authoring should feel dynamic, with hard semantic recovery behind it
- Saved one more language-surface steering rule for future type/literal work.
- Important continuity note:
  - authored `.fsm` should feel closer to a dynamic script surface than to a
    declaration-heavy HDL frontend,
  - scalar types should infer by default where one safe answer exists,
  - mixed integer spellings should be accepted whenever the engine can
    normalize them onto one safe semantic meaning,
  - the engine should do the hard recovery and validation work behind the
    scenes,
  - and ambiguity or unsafe recovery should still fail explicitly instead of
    being guessed.

## 2026-04-06: future typed declarations should stay inference-first and fail-safe
- Saved one more steering rule for the future `(+types ...)` lane.
- Important continuity note:
  - scalar names should not require explicit type declarations when one safe
    answer can be inferred from authored usage,
  - aggregate shapes should infer conservatively from member/index/LHS/RHS
    usage where possible,
  - ambiguous or underconstrained type situations should fail explicitly
    rather than being guessed,
  - and explicit declarations should remain available mainly as overrides,
    ambiguity anchors, and interface-stability controls.

## 2026-04-06: semantic packages now ship bounded aggregate leaf access
- Saved the next package-lane slice after direct-root imports landed.
- Important continuity note:
  - package `(+constants ...)` entries may now be scalar literals, non-empty
    lists, or nested hash-like aggregates,
  - imported package scalar leaves such as `shared.BYTES[1]`,
    `shared.FRAME.flag`, and `shared.NEST.header.nibble` now resolve as
    literals on direct-root RHS/guard paths and bounded composition actual /
    concat positions,
  - unresolved whole-aggregate references such as `shared.FRAME` now fail
    explicitly instead of degrading into generic signal names,
  - mixed aggregate shapes such as `((mode 3) 0)` are now rejected at package
    parse time,
  - and `FSM::Composition::LinkedPlanBuilder` now prefers typed top-expression
    parsing for concat/repeat source tokens even when they begin with an
    actual operand, which keeps package-backed concat actuals on the intended
    typed structural path.

## 2026-04-06: first semantic package/import slice now ships for composition named actuals
- Saved the first real shipped package behavior, not just roadmap steering.
- Important continuity note:
  - `?pkg:name` roots now parse as reusable declaration containers for shared named scalar values and enum families,
  - `?top` roots may now use bounded `(+import pkg_name ...)` blocks,
  - imported package sources may be embedded in the same composition file or resolved externally through the normal search-path contract,
  - package symbols stay namespaced by default, so actuals use forms like `=shared.RESET_BYTE` and `=shared.mode.BUSY`,
  - those imported package symbols now feed the same bounded structural literal path as local top-root named actuals on direct bindings and concat operands,
  - and direct `?pkg:name` entrypoints now fail explicitly as non-generating package roots.

## 2026-04-06: shared declaration surface should stay compact and package-oriented
- Saved one more steering decision about the future declaration model.
- Important continuity note:
  - the long-term intent-level declaration surface should center on `+constants`, `+enums`, and future `+types`,
  - `+define` should not be promoted as a separate long-term semantic family unless it remains purely compatibility residue,
  - `+params` should stay tied to true per-instance generic/configuration behavior rather than becoming a second shared-value mechanism,
  - future package-like authored objects should be able to export named scalar values and named aggregate values as well as enum families and future named types,
  - and those shared aggregates should stay semantic/frontend-checkable rather than devolving into raw text fragments.

## 2026-04-06: future shared declarations should use semantic packages, not include-style text reuse
- Saved one more future-lane steering decision for reusable declarations across `.fsm` files.
- Important continuity note:
  - future shared scalar values, aggregate values, enum families, and named types should live in first-class package-like authored objects rather than in textual include fragments,
  - those packages should be imported explicitly and stay namespaced by default,
  - the intended long-term semantic surface is `+constants`, `+enums`, and future `+types`, with aggregate values living through that same semantic package lane rather than through raw text tricks,
  - and per-instance parameterization should stay separate unless a later deliberate contract says a subset truly belongs in global/package scope.

## 2026-04-06: composition-top named literal actuals now close the first no-magic-number gap in explicit toplinks
- Stayed in the active `R11` lane and widened the explicit-toplink literal surface in a bounded way instead of pretending the future full type lane is already here.
- Important continuity note:
  - [perl/FSM/Composition/TopSymbols.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/TopSymbols.pm) now preserves composition-root `+constants` and `+enums` as canonical literal payloads on `?top` roots,
  - [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) now accepts those two symbol sections directly under `?top` and rejects malformed or non-literal entries at the parser boundary with composition-scoped wording,
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now resolves named actuals such as `=RESET_BYTE` and `=mode.BUSY` through that top-root symbol table,
  - those named literal actuals now work on direct realized-child-input bindings, direct declared-top-output bindings, and bounded concat operands,
  - and this stays intentionally bounded to literal-actual positions only rather than opening a broader typed/source-expression contract ahead of the future `(+types ...)` lane.

## 2026-04-05: intrinsic-width unsized signed decimal concat actuals now share the bounded structural literal family
- Stayed in the active `R11` lane and widened concat one more bounded step without weakening the direct-vs-concat width contract.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now accepts unsized signed decimal concat operands such as `=-1`, `=0d-1`, and `='sd-1`,
  - those operands now use the minimum signed width required by the numeric value rather than borrowing width from the child-input target,
  - that means `=-1` lowers as `1'b1`, `=0d-2` lowers as `2'b10`, and `='sd-3` lowers as `3'b101` on the typed structural path,
  - [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t) now locks linked-plan plus pipeline/CLI success for that intrinsic-width signed-decimal concat family,
  - and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) keeps the blocked concat-operand wording aligned with the widened family.

## 2026-04-05: SV unsized signed based actual spellings now alias the bounded structural literal family too
- Stayed in the active `R11` lane and widened the signed literal surface without opening a separate signed-only parser or AST path.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now accepts unsized signed SV-style based spellings such as `='sb1010`, `='so645`, and `='shA5` on explicit `?toplink` actuals,
  - direct realized-child-input and declared-top-output bindings now interpret those spellings as intrinsic-width signed payloads that sign-extend to the direct target width when the signed value fits,
  - bounded concat operands now also accept intrinsic-width `='sb...`, `='so...`, and `='sh...` forms on the same typed literal path,
  - no new AST node was added; those spellings normalize onto the existing structural bit-vector literal contract,
  - [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t) now locks direct sign-extension behavior plus blocked signed-width overflow,
  - [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t) now locks intrinsic-width signed-based concat success,
  - and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) keeps the concise blocked wording aligned with the widened signed-based alias family.

## 2026-04-05: standard unsized SV actual spellings now alias the bounded structural literal family
- Stayed in the active `R11` lane and widened the literal surface one more bounded step without creating a second literal contract.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now accepts unsized SV-style based spellings such as `='b10100101`, `='d170`, `='sd-1`, `='o245`, and `='hA5` on explicit `?toplink` actuals,
  - direct realized-child-input and declared-top-output bindings treat `='b...`, `='d...`, `='o...`, and `='h...` exactly like the existing unsized binary/decimal/octal/hex direct-actual families, while `='sd...` aliases the existing unsized signed-decimal direct-binding lane,
  - bounded concat operands now also accept intrinsic-width `='b...`, `='d...`, `='o...`, and `='h...` forms on the same typed literal path,
  - no new AST node was added; those spellings normalize onto the existing unsized literal families,
  - [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t) now locks direct linked-plan plus pipeline/CLI success for the new SV-style direct actual aliases,
  - [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t) now locks intrinsic-width SV-style concat alias success,
  - and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) keeps the concise blocked wording aligned with the widened alias family.

## 2026-04-05: signed based structural actuals now share the bounded literal path too
- Stayed in the active `R11` lane and widened the exact-width literal family one more bounded step instead of introducing a signed-only parser or renderer branch.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now accepts exact-width signed binary/octal/hex actuals such as `=8'sb10100101`, `=8'so245`, and `=8'shA5` on direct realized child-input and declared top-output bindings,
  - those same exact-width signed based forms now also work inside bounded source-side concat operands,
  - they lower through the same exact-width `bit_vector_literal_expr` path already used by the unsigned exact-width literal family, so this widening stays on one backend-neutral structural-literal contract,
  - payloads whose width exceeds the declared size now fail explicitly instead of truncating,
  - [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t) now locks direct linked-plan plus pipeline/CLI success for signed binary/octal/hex literals together with blocked signed-hex overflow,
  - [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t) now also locks exact-width signed binary/octal/hex literal success inside bounded concat,
  - and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) keeps the concise actual-family and concat-family wording aligned with the widened signed-based literal slice.

## 2026-04-05: signed decimal structural actuals now share the bounded literal path too
- Stayed in the active `R11` lane and widened the existing numeric actual family one more bounded step instead of inventing a signed-only lowering path.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now accepts unsized signed decimal direct actuals such as `=-1` and `=0d-1` on realized child inputs and declared top outputs,
  - those direct signed-decimal actuals now widen only when the numeric value fits the signed range of the direct binding target width, and then lower through the same exact-width two's-complement `bit_vector_literal_expr` path used by the existing structural literal families,
  - the same bounded literal path now also accepts exact-width signed decimal actuals such as `=8'sd-1` on direct bindings and bounded concat operands,
  - exact-width signed decimal payloads that exceed the declared signed range now fail explicitly instead of truncating or silently wrapping,
  - [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t) now locks direct linked-plan plus pipeline/CLI success for unsized and exact-width signed decimal direct actuals together with blocked overflow cases,
  - [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t) now also locks exact-width signed decimal literal success inside bounded concat,
  - and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) keeps the concise actual-family wording aligned with the widened signed-decimal slice.

## 2026-04-05: bounded toplink repeat groups now share the typed top-expression path too
- Stayed in the active `R11` lane and widened the same typed source-expression family instead of inventing a renderer-only shortcut for replication syntax.
- Important continuity note:
  - [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) now provides first-class `repeat_expr(...)` nodes with recursive dependency recovery and backend rendering, so bounded replication groups survive as structural AST instead of raw text,
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now accepts source-side repeat groups such as `{3{status_bus[0]}}` and `{2{producer.serial_lo}}` through the same explicit `?toplink` path used by the existing top expressions,
  - those repeat groups now work on direct child-input bindings, direct top-output assignments, and nested concat membership, and repeated child-output operands reuse the existing deterministic base carrier family instead of inventing repeat-only helper nets,
  - [perl/FSM/Composition/TopPortInferenceBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/TopPortInferenceBuilder.pm) now also infers one undeclared repeated whole-port operand when the child-target remainder width divides evenly across the repeat count, while uneven repeat-width splits fail explicitly,
  - [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) now locks helper/rendering support for `repeat_expr`,
  - [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t) now locks linked-plan plus pipeline/CLI success for top-only and child-output repeat groups,
  - [t/177-composition-top-port-inference-builder.t](/Users/richarddje/Documents/github/fsmgen/t/177-composition-top-port-inference-builder.t) and [t/101-composition-explicit-link-implicit-ports.t](/Users/richarddje/Documents/github/fsmgen/t/101-composition-explicit-link-implicit-ports.t) now lock repeat-aware omitted-port inference,
  - and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now keeps `Top expression '...'` context for blocked repeat-width inference failures.

## 2026-04-04: child-output concat operands now share the bounded top-expression path too
- Stayed in the active `R11` lane and landed the next honest source-expression widening on top of that same typed concat path.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now accepts child-output concat operands such as `producer.payload`, `producer.payload[7:4]`, and `producer.payload[0]` beside the existing top-port and literal operand families,
  - those child-output concat operands now reuse one deterministic base carrier per referenced child output and lower into the same typed `concat_expr` path for realized child inputs and declared top outputs,
  - [perl/FSM/Composition/TopPortInferenceBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/TopPortInferenceBuilder.pm) now ignores those child-output concat operands for omitted/empty-`?ports` top inference while still inferring real top operands from the same concat source,
  - [perl/FSM/Composition/ProvenanceReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ProvenanceReportBuilder.pm) now also treats those concat uses as first-class explicit child-output consumption,
  - [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t) now locks linked-plan plus pipeline/CLI success for child-output concat operands on child-input and top-output targets,
  - [t/177-composition-top-port-inference-builder.t](/Users/richarddje/Documents/github/fsmgen/t/177-composition-top-port-inference-builder.t) now locks that omitted-port inference still derives only undeclared top operands from mixed top-plus-child concat sources,
  - and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now keeps `Child expression '...'` summary context on blocked out-of-range child concat operands.

## 2026-04-04: intrinsic-width unsized decimal concat actuals now share the bounded top-expression path too
- Stayed in the active `R11` lane and widened concat one more step without weakening the direct-vs-concat width boundary.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now accepts unsized decimal concat operands such as `=170` and `=0d170`,
  - those operands now lower through the same typed `bit_vector_literal_expr` concat path as the other intrinsic-width unsized families,
  - their width now comes from the minimum number of bits required by the numeric value, so concat stays self-width-aware rather than target-width-aware,
  - direct bindings still keep their separate numeric widening contract, so this does not backslide into one implicit width rule for every numeric source,
  - [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t) now locks linked-plan plus pipeline/CLI success for bare and `0d` decimal concat operands,
  - and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now keeps the blocked-operand wording aligned with the widened concat family.

## 2026-04-04: nested brace-group toplink concat sources now survive the full source frontend
- Stayed in the active `R11` lane and fixed the real source-boundary quality bug instead of papering over it in lowering.
- Important continuity note:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now preserves brace-grouped slash-token text while reading `.fsm` files, so `{...}` inside `?toplink` source expressions survives raw parsing instead of being flattened by the Lispish reader before composition parsing,
  - that means nested bounded concat sources such as `header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}` now stay intact through raw AST, typed composition parsing, child-input bindings, direct top-output assignments, and omitted/empty-`?ports` inference,
  - [t/197-pipeline-source-frontend.t](/Users/richarddje/Documents/github/fsmgen/t/197-pipeline-source-frontend.t) now locks the raw-token preservation boundary explicitly,
  - [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t) now also locks end-to-end nested child-input concat preservation,
  - [t/267-composition-top-expression-top-outputs.t](/Users/richarddje/Documents/github/fsmgen/t/267-composition-top-expression-top-outputs.t) now also locks nested direct top-output assignment from that same source expression family,
  - and [t/101-composition-explicit-link-implicit-ports.t](/Users/richarddje/Documents/github/fsmgen/t/101-composition-explicit-link-implicit-ports.t) now also locks omitted/empty-`?ports` inference through nested concat groups.

## 2026-04-04: intrinsic-width unsized binary/octal/hex concat actuals now use the bounded top-expression path
- Stayed in the active `R11` lane and widened the concat side carefully instead of weakening the direct-vs-concat distinction.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now accepts intrinsic-width unsized binary/octal/hex concat operands such as `=0b1_0`, `=0o2`, `=0xA`, and `=A`,
  - those operands now become typed `bit_vector_literal_expr` concat members whose width comes from their digits rather than from the child-input target,
  - that initial intrinsic-width concat family later widened further to include unsized decimal spellings such as `=170` and `=0d170`,
  - [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t) now locks linked-plan plus pipeline/CLI success for that initial concat family, which then became the base for the later unsized-decimal widening too,
  - and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now keeps the concise concat-operand wording aligned with the widened intrinsic-width family.

## 2026-04-04: prefixed unsized direct actuals now share the widened direct-binding family
- Stayed in the active `R11` lane and carried the direct-actual family forward one more bounded step instead of opening concat or sized-literal coercion.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now accepts prefixed unsized direct actuals such as `=0b10100101`, `=0d170`, and `=0xA5` on realized child inputs and declared top outputs, widening them to the direct binding target width as numeric values and failing explicitly on overflow,
  - those prefixed forms now share the same direct-binding contract as the earlier bare unsized decimal/hex forms instead of remaining parser-shape rejects,
  - bounded concat operands still stay stricter than direct bindings, so prefixed unsized numeric widening does not silently appear inside concat,
  - [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t) now locks direct linked-plan plus pipeline/CLI success for those prefixed direct actuals together with blocked unsupported-shape and binary-overflow cases,
  - [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t) now also keeps prefixed unsized concat operands blocked,
  - and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) keeps the widened structural-actual family wording aligned with the shipped direct-binding contract.

## 2026-04-04: future structured HDL mode should branch at the backend, with flattened staying default
- Recorded one future-steering note for generated-module emission.
- Important continuity note:
  - a second selectable HDL generation route that preserves FSM/DT control structure now looks architecturally plausible,
  - flattened generation should stay the default mode and current debug-first path,
  - the clean future branch point is [perl/FSM/Backend/GeneratedModuleEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/GeneratedModuleEmitter.pm), with [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) carrying one future generation-style option,
  - and the semantic frontend, validations, provenance, and forward IR layers should stay shared so the two modes differ in HDL shape, not in accepted semantics.

## 2026-04-04: unsized decimal and hex direct actuals now widen on direct bindings
- Stayed in the active `R11` lane and carried through the next real direct-binding widening instead of switching away from feature work.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now accepts unsized positive decimal and hex direct actuals such as `=170` and `=A5` on realized child inputs and declared top outputs, widening them to the direct binding target width as numeric values and failing explicitly on overflow,
  - exact-width forms such as `=8'd165` and `=8'hA5` remain exact-width contracts instead of being widened again,
  - bounded concat operands still stay stricter than direct bindings, so unsized numeric widening does not silently appear inside concat,
  - [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t) now locks direct linked-plan plus pipeline/CLI success for unsized decimal/hex direct actuals together with blocked unsupported-shape and overflow cases,
  - [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t) now keeps concat honest by locking that unsized numeric operands still fail there,
  - and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) continues to keep the widened family wording and blocked summary surface aligned with the shipped contract.

## 2026-04-04: next likely structural-actual widening is unsized decimal/hex direct bindings, not looser exact-width coercion
- Recorded one steering decision for the next `R11` sibling after the shipped scalar `=0` / `=1` widening.
- Important continuity note:
  - unsized positive decimal and hex direct actuals now look like the next honest widening for [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm): treat them as numeric values, widen them to the direct binding target width, and fail explicitly on overflow,
  - exact-width forms such as `=8'd5` and `=8'hA5` should remain exact-width contracts instead of being silently widened again,
  - and bounded concat operands should stay stricter than direct bindings unless a later slice opens a separate concat-numeric inference contract on purpose.

## 2026-04-04: direct scalar `=0` and `=1` actuals now widen to direct binding targets
- Stayed in the active `R11` lane and kept this as the next honest structural-actual refinement instead of switching away from feature work while the planner path was already localized.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now treats direct explicit-actual sources `=0` and `=1` as scalar numeric zero/one sources that widen to the realized child-input or declared top-output target width instead of behaving like accidental one-bit-only direct bindings,
  - bounded concat operands still keep `=0` / `=1` as one-bit operands unless the author spells an exact-width literal there, so the widening stays on the direct-binding path rather than silently changing concat semantics too,
  - [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t) now locks widened scalar direct actuals on child inputs and declared top outputs,
  - [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now keeps the family wording honest by saying the shipped structural-actual slice covers `=open`, scalar `=0` / `=1`, and exact-width binary/decimal/hex literal actuals,
  - and `=open` remains the only child-input-only sibling in that family because “unconnected” is still not honest top-output wiring.

## 2026-04-04: direct literal actuals may now drive declared top outputs too
- Stayed in the active `R11` lane and kept this as the next honest sibling after the shipped top-expression/top-output slice instead of switching back to hardening-only work.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now emits direct top-output assignments for literal actual sources such as `=0`, `=1`, `=8'b10100101`, `=8'd165`, and `=8'hA5` instead of limiting those direct actual tokens to realized child-input bindings,
  - that means direct literal actuals and bounded concat operands now both reach declared top outputs through the same typed structural-expression/rendering path rather than splitting into “concat can, direct actual cannot,”
  - [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t) now locks direct linked-plan plus pipeline/CLI success for literal-actual top-output assignments,
  - [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now keeps the still-blocked sibling honest by locking `=open`-to-top-output as the remaining explicit-actual source-role failure,
  - `=open` remains child-input-only on purpose because a declared top output still needs a concrete driven expression,
  - and the next honest sibling after this slice is no longer “actual-source to top-output” in general, but rather whether any broader non-literal explicit-actual family is worth opening at all.

## 2026-04-04: source-side top expressions may now drive top outputs directly too
- Stayed in the active `R11` lane and kept this as another expression/top-boundary feature slice rather than widening actual-source rules at the same time.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now emits direct top-output assignments from source-side top-port bit/slice and bounded concat expressions instead of blocking those expressions at the top boundary,
  - sibling child-input consumers may still reuse those same typed expressions in the same top without synthetic carrier nets, so direct child-input and direct top-output expression uses now share one planner path,
  - [t/263-composition-toplink-top-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/263-composition-toplink-top-expressions.t) and [t/267-composition-top-expression-top-outputs.t](/Users/richarddje/Documents/github/fsmgen/t/267-composition-top-expression-top-outputs.t) now lock the linked-plan plus pipeline/CLI contract for that widened top-boundary expression slice,
  - the old “direct actual-source to top-output” sibling is now partially closed by the later literal-actual slice, with `=open` still intentionally excluded there,
  - and the next honest sibling beyond these top-boundary expression/actual slices is now likely another structural-actual or shared-boundary widening rather than more top-expression hardening.

## 2026-04-04: declared top inputs may now fan out directly to top outputs too
- Stayed in the active `R11` lane and kept this as another feature slice instead of circling back into summary-only or hardening-only work.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now allows one declared top input to drive one or more top outputs directly through explicit top-output assignments while sibling child-input consumers reuse that same top input without a synthetic helper carrier,
  - [perl/FSM/Composition/SharedDatapathSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/SharedDatapathSupport.pm) now preserves those preexisting auxiliary assignments when shared-datapath runtime rewriting is also active instead of overwriting them later,
  - [t/176-composition-linked-plan-builder.t](/Users/richarddje/Documents/github/fsmgen/t/176-composition-linked-plan-builder.t) and [t/266-composition-top-input-top-output-fanout.t](/Users/richarddje/Documents/github/fsmgen/t/266-composition-top-input-top-output-fanout.t) now lock the direct linked-plan and mixed-runtime pipeline/CLI contract for that widened topology,
  - [t/109-composition-explicit-link-topology-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/109-composition-explicit-link-topology-diagnostics.t) and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) no longer expect the old blocked top-input-to-top-output failure family,
  - the remaining blocked sibling in this narrower topology family is still source-side top-expression directly to top-output, not plain declared top-input fanout,
  - and the full regression stayed green after the slice (`Files=261`, `Tests=1978`, `PASS`).

## 2026-04-04: one child source may now fan out to multiple top outputs in explicit-link tops
- Stayed in the active `R11` lane and kept this as another real composition-feature widening before returning to hardening-only work.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now realizes one child output source driving multiple top outputs through one deterministic shared carrier net plus explicit top-output assignments instead of blocking that topology,
  - sibling child-input consumers in the same explicit-link top now reuse that same carrier net instead of forcing one public top output to double as the internal carrier,
  - [t/176-composition-linked-plan-builder.t](/Users/richarddje/Documents/github/fsmgen/t/176-composition-linked-plan-builder.t) and [t/265-composition-multi-top-output-fanout.t](/Users/richarddje/Documents/github/fsmgen/t/265-composition-multi-top-output-fanout.t) now lock the linked-plan and end-to-end pipeline/CLI contract for that widened topology,
  - [t/109-composition-explicit-link-topology-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/109-composition-explicit-link-topology-diagnostics.t) and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) no longer expect the old blocked multi-top-output failure family,
  - and the still-blocked explicit-link topology sibling remains top-input directly to top-output, not child-output fanout.

## 2026-04-04: exact-width decimal actuals now ride the same structural literal path
- Stayed in the active `R11` lane and kept this as another bounded structural-actual widening rather than introducing a new connection-expression family.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now accepts exact-width decimal literal actuals such as `=8'd165` beside the existing binary and hex forms, normalizing them into the same `bit_vector_literal_expr` payload used throughout the structural binding path,
  - the same exact-width decimal literal family now also works inside bounded source-side concat operands, so direct child-input actuals and concat-literal operands still share one backend-neutral literal contract,
  - unsized decimal-like spellings still fail explicitly, and decimal payloads whose numeric value exceeds the declared width now fail explicitly instead of truncating,
  - [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t), [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t), and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now lock the widened direct/concat/summary contract,
  - and the full regression stayed green after the slice (`Files=259`, `Tests=1980`, `PASS`).

## 2026-04-02: explicit-actual failure summaries now keep the actual token context too
- Stayed in the active `R11` lane, but kept this as a follow-on contract-hardening slice rather than a new runtime-capability widening.
- Important continuity note:
  - [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm) now recognizes the shipped structural-actual diagnostic wording directly, so blocked `?toplink` failures that say `uses actual source '...'` or `uses actual endpoint '...'` surface bounded `Actual source '...'` or `Actual endpoint '...'` context lines in the non-quiet composition failure summary,
  - [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks both the pipeline and CLI summary shape for blocked literal-source role failures and blocked actual-endpoint target failures on that explicit-toplink path,
  - this does not widen runtime support beyond the already-shipped `=open` / `=0` / `=1` / exact-width `=N'b...` child-input binding slice,
  - and the full regression stayed green after the summary-only follow-up (`Files=257`, `Tests=1959`, `PASS`).

## 2026-04-02: README quick-start and import-tree note now match the live runtime again
- Stayed on a documentation-honesty slice instead of changing roadmap state after executing the current README workflow end-to-end.
- Important continuity note:
  - [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), and [WARP.md](/Users/richarddje/Documents/github/fsmgen/WARP.md) now point their debug/known-good example commands at [fsm/lte_dif_pmaster.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/lte_dif_pmaster.fsm) instead of the stale [fsm/trial_1.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/trial_1.fsm) quick-start reference,
  - the trigger for that refresh was a live README execution pass: the first two `trial_0` commands still succeeded, but the old `trial_1` debug example now fails on unsupported `!&` operator residue while the documented support boundary no longer claims that operator,
  - [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) is now refreshed against the current 2026-04-02 static import walk, keeping the measured reachable set at `97` project files / `96` packages while updating the stale line-count snapshot (`bin/fsmgen` now `820`, [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm) now `152`, [perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm) now `1320`, and related entries),
  - and the documented local regression entrypoint still finished green after this doc-only slice (`Files=256`, `Tests=1950`, `PASS`), so the continuity update is about documentation/runtime alignment rather than a new behavior change.

## 2026-04-02: strict mode now narrows the direct module-root alias family too
- Switched back into `R9` after the recent `R10` diagnostics slice so the support-tier lane keeps moving alongside the visible diagnostics work.
- Important continuity note:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now rejects the long direct-root alias `?module:` in strict mode and points users to canonical `?mod:module_name`,
  - default mode still accepts `?module:` on the current shared single-module path as a compatibility alias,
  - this does not collapse module roots into `?dt:` and does not reopen the broader module-root semantics you clarified earlier; it only narrows one alias family in the strict lane,
  - and [t/240-strict-mode-standalone-dt-alias-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/240-strict-mode-standalone-dt-alias-boundary.t) now locks the split through shared-frontend, pipeline, and CLI coverage while keeping the earlier `?dtc` child-root strict boundary intact.

## 2026-04-02: missing composition lookup failures now keep explicit search-root context too
- Switched back into a visible `R10` slice after the recent `R12` corpus widening so the diagnostics lane keeps moving in a user-facing way.
- Important continuity note:
  - [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) now promotes missing external `?fsmc` / `?dtc` lookup details into explicit `Search roots:` and `Searched locations:` lines alongside the earlier `Source file:` and `Expected child source file:` labels,
  - [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) now does the same for missing external `.rtlif` lookup through an explicit `Search roots:` line beside `Source file:` and `Expected RTL metadata file:`,
  - [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm) plus [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now surface that same `Search roots:` context inside the non-quiet composition failure summary without displacing the earlier artifact or child-context lines,
  - and [t/115-composition-child-source-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/115-composition-child-source-diagnostics.t), [t/117-composition-rtlif-metadata-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/117-composition-rtlif-metadata-diagnostics.t), [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t), [t/255-composition-missing-rtl-metadata-diagnostic-context.t](/Users/richarddje/Documents/github/fsmgen/t/255-composition-missing-rtl-metadata-diagnostic-context.t), and [t/256-composition-missing-child-source-artifact-context.t](/Users/richarddje/Documents/github/fsmgen/t/256-composition-missing-child-source-artifact-context.t) now lock both the raw and summarized shape.

## 2026-04-02: regression corpus now counts partial-write support as named supported features
- Switched lanes deliberately into `R12` so the new partial indexed/sliced LHS support does not live only in focused contract tests.
- Important continuity note:
  - [t/corpus/partial_lhs_with_size.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/partial_lhs_with_size.fsm) and [t/corpus/partial_lhs_inferred_width.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/partial_lhs_inferred_width.fsm) now exist as stable corpus fixtures for the supported partial-write surface,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm) now records them as `feature.partial_lhs_with_size` and `feature.partial_lhs_inferred_width` under `supported_smoke`,
  - [t/261-regression-corpus-supported-language-features.t](/Users/richarddje/Documents/github/fsmgen/t/261-regression-corpus-supported-language-features.t) now checks those entries through both pipeline and CLI while also locking key HDL-shape expectations,
  - and this means the supported side of `R12` is no longer only imported protocol seeds; it now also includes shipped language features with explicit semantic-output checks.

## 2026-04-02: static numeric partial LHS writes now lower correctly through the direct backend
- Continued with a visible language/correctness slice instead of more backend-only decomposition.
- Important continuity note:
  - the parser had already accepted static numeric indexed/sliced LHS targets such as `SIG[3]` and `SIG[7:0]`, but the direct enable/mux path had still been collapsing those writes onto the base signal name too early,
  - [perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm) now normalizes same-context partial writes into one full-width effective assignment family before RHS grouping, WEN/EN shaping, and mux emission,
  - that means same-context piecewise combinational writes now assemble into one full-width mux input, and same-context piecewise `<-` / `<=` writes now assemble into one full-width sequential mux input too,
  - partial sequential writes that leave some bits untouched now retain those bits through the right feedback source (`Q` for `<-`, `_q` for `<=`) instead of replacing the whole signal,
  - [t/258-partial-lhs-assignment-lowering.t](/Users/richarddje/Documents/github/fsmgen/t/258-partial-lhs-assignment-lowering.t) now locks the shipped contract for `=`, `<-`, and `<=`,
  - and the full suite stayed green after the fix (`Files=253`, `Tests=1928`, `PASS`), so this is now real supported behavior rather than only parsed syntax.

## 2026-04-02: partial dual-output writes now keep full-width auxiliary outputs too
- Continued the same visible language/correctness lane because the first partial-LHS fix still left `<-=` / `<=+` auxiliary outputs narrowed to the fragment width in the emitted module ports.
- Important continuity note:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now derives a base-signal width for indexed/sliced LHS targets from the registered signal width plus the slice/index bounds,
  - that base width is now fed back into the signal registry itself and into the dual-output auxiliary ports for `<-=` and `<=+`,
  - so partial writes such as `(ROD[3:2] <-= HI)` and `(RID[3:2] <=+ HI)` now keep `next_ROD` and `RID_r` at the full base-signal width instead of narrowing them to the fragment width,
  - [t/259-partial-dual-output-lhs-lowering.t](/Users/richarddje/Documents/github/fsmgen/t/259-partial-dual-output-lhs-lowering.t) now locks that contract for both `+size`-before-state and `+size`-after-state ordering,
  - and this closes the honest support gap that was still left after the earlier `=`, `<-`, `<=` partial-write slice.

## 2026-04-02: partial target width inference is now regression-backed without +size too
- Continued with one small contract-hardening follow-up instead of leaving the new partial-write support dependent on a one-off manual HDL probe.
- Important continuity note:
  - [t/260-partial-target-width-inference.t](/Users/richarddje/Documents/github/fsmgen/t/260-partial-target-width-inference.t) now locks the no-`+size` case where the base signal width must come only from the static slice/index bounds,
  - that regression covers slice-only partial targets such as `OUT[3:2]` and index-only partial targets such as `IDXOUT[4]`,
  - and it explicitly keeps full-width internal declarations plus full-width `next_*` / `*_r` auxiliary outputs regression-backed in those inference-only cases too.

## 2026-04-02: strict mode now rejects the compact top-level `:=` directive too
- Continued the visible `R9` lane by widening strict mode into another section-level compatibility cut instead of staying only on root families and `+system` residue.
- Important continuity note:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now rejects the legacy compact top-level `(:= signal=value)` directive in strict mode on the current `?fsm:` / `?dt:` direct-root path while leaving default-mode compatibility unchanged,
  - that check lives in the shared direct-root strict owner, so it reaches those direct roots and generated child sources through the same semantic-module path while still leaving top-level `?mod:` / `?module:` roots unchanged,
  - [t/257-strict-mode-compact-init-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/257-strict-mode-compact-init-boundary.t) now locks the boundary through the shared frontend plus pipeline and CLI entry points for both direct roots and external `?dtc` child sources,
  - and strict mode now points users at the canonical pair replacement
    `(:= (signal value))` for the compact compatibility `:=` form.

## 2026-04-01: the corpus now counts missing generated-child lookup as composition-contract behavior too
- Continued the visible `R12` lane by widening the composition-contract bucket beyond missing `.rtlif` sidecars into missing external generated-child source lookup too.
- Important continuity note:
  - [t/corpus/missing_fsm_child_source_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/missing_fsm_child_source_top.fsm) and [t/corpus/missing_dt_child_source_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/missing_dt_child_source_top.fsm) now exist as static composition-top expected-failure corpus assets,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm) now records `contract.missing_fsm_child_source` and `contract.missing_dt_child_source` under the existing `composition_contract_rejection_pipeline_cli` coverage bucket,
  - those entries lock the normal unresolved external `?fsmc` / `?dtc` composition boundary through the new `Expected child source file:` diagnostic family rather than leaving that behavior only in focused diagnostics tests,
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t) now exercises those missing-child composition rejection paths through both pipeline and CLI,
  - and [docs/REGRESSION_CORPUS.md](/Users/richarddje/Documents/github/fsmgen/docs/REGRESSION_CORPUS.md) now records that the composition-contract rejection bucket spans both missing external child-source lookup and missing external `.rtlif` sidecars.

## 2026-04-01: missing external child failures now name the expected child artifact
- Continued the visible `R10` lane by tightening unresolved external `?fsmc` / `?dtc` lookup instead of leaving missing child-source resolution slightly less actionable than wrong-kind child failures or missing `.rtlif` sidecars.
- Important continuity note:
  - [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) now wraps unresolved external child lookup with `Source file: '...'`, `Expected child source file: 'source_name.fsm'`, and `Generated child source: '?fsmc/?dtc' 'source_name'`,
  - that means missing child lookup no longer stops at only the containing composition path plus generated-child identity while still avoiding a fake resolved `Child source file:` artifact,
  - [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm) now also extracts that expected-child filename, so non-quiet composition failure summaries can show the missing external `.fsm` target directly,
  - [t/256-composition-missing-child-source-artifact-context.t](/Users/richarddje/Documents/github/fsmgen/t/256-composition-missing-child-source-artifact-context.t) now locks the raw pipeline and CLI diagnostic shape for both missing `?fsmc` and missing `?dtc` lookup,
  - and the missing-child summary subtests in [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now lock the new `Expected child source file:` summary artifact too.

## 2026-04-01: the corpus now includes a composition-contract expected-failure asset
- Continued the visible `R12` lane by widening support accounting beyond strict-mode and direct language-contract rejection into one real composition-contract rejection family.
- Important continuity note:
  - [t/corpus/missing_rtl_metadata_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/missing_rtl_metadata_top.fsm) now exists as the first static composition-top expected-failure corpus asset,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm) now records `contract.missing_rtl_metadata_sidecar` under the new `composition_contract_rejection_pipeline_cli` coverage bucket,
  - that entry locks the normal missing-`.rtlif` composition boundary with the new `Expected RTL metadata file:` artifact label rather than treating it as only a focused diagnostics test,
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t) now exercises that composition rejection path through both pipeline and CLI,
  - and [docs/REGRESSION_CORPUS.md](/Users/richarddje/Documents/github/fsmgen/docs/REGRESSION_CORPUS.md) now records the new coverage bucket beside the earlier strict and language-contract rejection buckets.

## 2026-04-01: missing external `.rtlif` failures now name the expected sidecar artifact
- Continued the visible `R10` lane by tightening one remaining `?rtl` diagnostics gap instead of dropping back into backend-only cleanup.
- Important continuity note:
  - [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) now wraps unresolved external `.rtlif` lookup failures with `Source file: '...'`, `Expected RTL metadata file: 'module.rtlif'`, and `RTL child module: '?rtl' 'module_name'`,
  - that means missing sidecar metadata no longer falls back to only the raw search-root/search-location prose while still avoiding a fake resolved `RTL metadata file:` artifact,
  - [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm) now also extracts that expected-artifact label, so non-quiet composition failure summaries can show the missing sidecar target directly,
  - [t/255-composition-missing-rtl-metadata-diagnostic-context.t](/Users/richarddje/Documents/github/fsmgen/t/255-composition-missing-rtl-metadata-diagnostic-context.t) now locks the raw pipeline and CLI diagnostic shape,
  - and the missing-rtlif subtests in [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now lock the new `Expected RTL metadata file:` summary artifact too.

## 2026-04-01: strict mode now rejects explicit `(asreset rstn)` too
- Continued the visible `R9` lane by widening strict mode beyond the first root-family and empty-`(+size)` cuts into another explicit section-level compatibility-residue rule.
- Important continuity note:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now rejects the legacy explicit `(asreset rstn)` `+system` spelling in strict mode while leaving default-mode compatibility intact,
  - that check lives in the same shared direct-root strict owner as the earlier empty-`(+size)` rule, so it reaches both top-level direct roots and generated child sources,
  - [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm) now passes `raw_ast` into the shared top-level strict hook too, so section-level strict cuts fire consistently at the file-orchestration boundary,
  - and [t/254-strict-mode-asreset-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/254-strict-mode-asreset-boundary.t) now locks the new boundary through the shared frontend plus pipeline and CLI entry points for both direct roots and external `?fsmc` child sources.

## 2026-04-01: the corpus now accounts for child-root compatibility residue too
- Continued the visible `R12` lane by widening support accounting into generated-child source-root residue instead of stopping at direct-root and section-level legacy cases.
- Important continuity note:
  - [t/corpus/legacy_fsm_child_root_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_fsm_child_root_top.fsm) plus [t/corpus/legacy_fsm_child_root_src.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_fsm_child_root_src.fsm) now exist as the first explicit `?fsmc` child-root compatibility corpus pair,
  - [t/corpus/legacy_dt_child_root_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_dt_child_root_top.fsm) plus [t/corpus/legacy_dt_child_root_src.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_dt_child_root_src.fsm) now exist as the matching `?dtc` child-root compatibility corpus pair,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm) now records both default-mode compatibility and strict-mode expected-rejection contracts for those child-root fixtures, including explicit `search_path_relpaths`,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t) now locks the new child-root coverage buckets plus the existence of per-entry search roots,
  - and [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t) now knows how to exercise composition entries with explicit search-path realization through both pipeline and CLI.

## 2026-04-01: typed extension loading failures now keep artifact labels too
- Continued the visible `R10` lane by widening the same diagnostics family one step earlier, into extension loading and pipeline construction.
- Important continuity note:
  - [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm) now annotates malformed config-file failures with `Extension config file: '...'` and module-load / constructor failures with `Extension module: '...'`,
  - [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now wraps `HDLGenerator->new(...)` in the cleaned CLI error path, so constructor failures no longer dump a raw `bin/fsmgen` script line,
  - [t/253-extension-loader-diagnostic-context.t](/Users/richarddje/Documents/github/fsmgen/t/253-extension-loader-diagnostic-context.t) now locks both pipeline and CLI behavior for malformed extension config input and constructor-failing extension modules,
  - and [t/lib/FSM/TestExtension/BadNew.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/TestExtension/BadNew.pm) now exists as the dedicated regression helper for constructor-failure coverage.

## 2026-04-01: the corpus now accounts for section-level compatibility residue too
- Continued the visible `R12` lane by turning the empty-`(+size)` strict/default split into an explicit dual-contract corpus asset instead of leaving it only as an isolated strict-mode regression.
- Important continuity note:
  - [t/corpus/legacy_empty_size_noop.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_empty_size_noop.fsm) now exists as the first section-level compatibility-residue corpus asset,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm) now records both `legacy.empty_size_noop.default_compat` and `legacy.empty_size_noop.strict_rejection` for the same file,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t) now knows the new `legacy_section_default_pipeline_cli` and `strict_section_rejection_pipeline_cli` coverage buckets,
  - and [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t) now treats strict support-tier expected failures as a broader family instead of only the earlier root-family case.

## 2026-04-01: typed extension hook failures now keep source-local context too
- Continued the visible `R10` lane by widening the same artifact-label pattern into typed extension hook failures instead of letting those failures fall back to raw hook text.
- Important continuity note:
  - [perl/FSM/Extension/Registry.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Registry.pm) now annotates ordinary extension-hook failures with `Extension module: '...'` and `Extension stage: '...'`,
  - [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm) now runs `after_parse_source` and `after_generate_result` under the same `Source file: '...'` wrapper used by the earlier top-level diagnostic slices,
  - [t/252-extension-diagnostic-context.t](/Users/richarddje/Documents/github/fsmgen/t/252-extension-diagnostic-context.t) now locks that full `Source file` + `Extension module` + `Extension stage` shape through both pipeline and CLI entry points,
  - and [t/lib/FSM/TestExtension/Exploding.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/TestExtension/Exploding.pm) now exists as the dedicated regression helper for extension-hook failure-shape coverage.

## 2026-04-01: strict mode now rejects the legacy empty `(+size)` no-op
- Continued the visible `R9` lane by making the first section-level compatibility-residue cut instead of only tightening root-family boundaries.
- Important continuity note:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now rejects the legacy empty `(+size)` no-op section in strict mode while leaving default-mode compatibility intact,
  - that check lives in the shared direct-root strict owner, so it reaches top-level sources and generated child sources through the same semantic-module path,
  - [t/251-strict-mode-empty-size-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/251-strict-mode-empty-size-boundary.t) now locks the boundary through the shared frontend plus pipeline and CLI entry points,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states the correct split explicitly: default mode still tolerates empty `(+size)` as compatibility residue, while strict mode requires explicit width entries or no `+size` section at all.

## 2026-04-01: CLI entrypoint failures now keep requested-source and output-file context
- Switched back to the visible `R10` lane after the recent `R12` streak and widened the CLI error shape one step earlier in the flow.
- Important continuity note:
  - [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now prefixes unresolved source-lookup failures with `Requested source: '...'` instead of surfacing only the raw search failure body,
  - output-open failures now also keep `Source file: '...'` plus `Output file: '...'` before the underlying `Cannot write to output file:` diagnostic,
  - [t/250-cli-entrypoint-file-context.t](/Users/richarddje/Documents/github/fsmgen/t/250-cli-entrypoint-file-context.t) now locks both pre-pipeline CLI failure families,
  - and this is explicitly a pre-pipeline artifact-context slice, not a claim that deeper parse/generation provenance is complete.

## 2026-04-01: the corpus now includes a static malformed-language expected-failure asset
- Widened the `R12` catalog again so `expected_failure` no longer means only “strict-mode legacy root rejection.”
- Important continuity note:
  - [t/corpus/language_contract_bad_size_entry.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/language_contract_bad_size_entry.fsm) is now the first static malformed-language corpus asset,
  - `contract.language_contract_bad_size_entry` in [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm) is classified as `expected_failure` with the normal `Malformed '+size' entry` boundary,
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t) now checks that ordinary pipeline and CLI rejection path in addition to the earlier strict `+fsm` rejection path,
  - and [docs/REGRESSION_CORPUS.md](/Users/richarddje/Documents/github/fsmgen/docs/REGRESSION_CORPUS.md) now carries the `language_contract_rejection_pipeline_cli` coverage bucket beside the earlier legacy/strict buckets.

## 2026-04-01: the first corpus catalog now carries explicit non-supported classifications too
- Widened the new `R12` catalog beyond `supported_smoke` so the support story now includes one explicit compatibility-retained entry and one explicit expected rejection.
- Important continuity note:
  - [fsm/mipicsi2_txccore_ulp.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/mipicsi2_txccore_ulp.fsm) is now used as the first real dual-contract asset in [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm),
  - `legacy.mipicsi2_txccore_ulp.default_compat` is classified as `legacy_out_of_scope` and must still compile through pipeline and CLI in default mode,
  - `legacy.mipicsi2_txccore_ulp.strict_rejection` is classified as `expected_failure` and must keep the strict `+fsm` rejection boundary through pipeline and CLI,
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t) now locks those two first non-supported contracts,
  - and [docs/REGRESSION_CORPUS.md](/Users/richarddje/Documents/github/fsmgen/docs/REGRESSION_CORPUS.md) now explains that corpus entries are contracts, so the same file may appear more than once when the supported behavior differs by mode.

## 2026-04-01: first protocol corpus slice now has explicit catalog/accounting structure
- Strengthened the first `R12` slice so it is not just one hardcoded smoke test anymore.
- Important continuity note:
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm) now records the first named corpus entries and their classification / coverage buckets in one machine-checked place,
  - [t/247-protocol-fixture-regression-smoke.t](/Users/richarddje/Documents/github/fsmgen/t/247-protocol-fixture-regression-smoke.t) now compiles the first protocol fixtures from that catalog instead of embedding the list inline,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t) now checks uniqueness, known classifications, known coverage buckets, and real asset existence,
  - [docs/REGRESSION_CORPUS.md](/Users/richarddje/Documents/github/fsmgen/docs/REGRESSION_CORPUS.md) is now the human-readable companion note for the same slice,
  - and the saved `R12` growth rule is now “add a classified catalog entry and matching automated checks,” not “point at an example file and assume it counts.”

## 2026-04-01: protocol fixture smoke now starts the regression corpus lane
- Started `R12` for real by turning the imported protocol fixtures into live regression-backed corpus entries instead of leaving them as uncounted examples only.
- Important continuity note:
  - [t/247-protocol-fixture-regression-smoke.t](/Users/richarddje/Documents/github/fsmgen/t/247-protocol-fixture-regression-smoke.t) now locks direct-root smoke for [fsm/apb_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_requester.fsm), [fsm/apb_completer.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_completer.fsm), and [fsm/amba_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/amba_requester.fsm),
  - that same test also locks the composed protocol harness [fsm/apb_tb.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_tb.fsm) through both pipeline and CLI, so the first `R12` slice covers a real generated-child / explicit-link path,
  - and the saved rule is now explicit: imported/example assets only count toward support claims once they are regression-backed.

## 2026-04-01: CLI failure output now suppresses raw Perl stack traces
- Continued the active `R10` diagnostics lane by cleaning the last-mile CLI presentation of the source-local diagnostics we already shipped.
- Important continuity note:
  - [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now normalizes ordinary string errors before printing them so the CLI keeps the actual diagnostic text and context lines but drops raw Perl `confess` stack frames,
  - top-level parse failures and generated-child failures still keep their earlier `Source file:` / `Parent composition source:` / `Generated child source:` framing,
  - [t/246-cli-error-output-cleanup.t](/Users/richarddje/Documents/github/fsmgen/t/246-cli-error-output-cleanup.t) locks the cleaned CLI output for both a top-level parse failure and a generated-child failure,
  - and the saved `R10` story is now “source-local context first, then cleaner CLI presentation”.

## 2026-04-01: strict mode now requires canonical `?fsm:` roots under `?fsmc`
- Continued the active `R9` lane by making the FSM-child side of the strict child-root contract explicit instead of leaving it to the broader top-level `+fsm` rejection wording.
- Important continuity note:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now rejects legacy `+fsm` specifically when it is used as the root of a `?fsmc` child source and points users to canonical `?fsm:source_name`,
  - [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) already applies that helper before semantic realization, so the child-specific migration hint now reaches pipeline and CLI entry points with the same generated-child source context as other child failures,
  - [t/245-strict-mode-fsm-child-root-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/245-strict-mode-fsm-child-root-boundary.t) locks that updated boundary through both pipeline and CLI for external flattened and nested legacy `+fsm` child roots,
  - and the saved `R9` story is now “top-level `+fsm`, then `?dtc` canonical `?dt`, then `?fsmc` canonical `?fsm`”.

## 2026-04-01: generated-child resolution failures now keep the same source-local framing
- Continued the active `R10` diagnostics lane by widening the generated-child context helper into the two adjacent external-child failure families that were still surfacing only raw search or wrong-kind text.
- Important continuity note:
  - [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) now routes unresolved external child and wrong-kind external child failures through `_with_generated_child_source_context(...)`,
  - wrong-kind external child failures now keep `Source file: 'child_source.fsm'`, `Parent composition source: 'top_source.fsm'`, and `Generated child source: '?fsmc/?dtc' 'source_name'`,
  - unresolved external child failures now keep `Source file: 'top_source.fsm'` plus the same generated-child identity line without inventing a missing child-file artifact,
  - [t/244-composition-child-resolution-diagnostic-context.t](/Users/richarddje/Documents/github/fsmgen/t/244-composition-child-resolution-diagnostic-context.t) locks both failure families through pipeline and CLI,
  - and the saved `R10` story is now “top-level failures, then generated-child parse/semantic failures, then generated-child resolution/wrong-kind failures, then RTL-child metadata failures”.

## 2026-04-01: strict mode now requires canonical `?dt:` roots under `?dtc`
- Continued the active `R9` lane by tightening the standalone-DT child-source contract without collapsing top-level module roots.
- Important continuity note:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now owns a child-specific strict helper in addition to the earlier top-level `+fsm` root-family boundary,
  - [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) now applies that helper so strict mode rejects `?mod:` / `?module:` when they are used as `?dtc` child roots and points users to canonical `?dt:source_name`,
  - top-level `?mod:` / `?module:` roots remain accepted in strict mode,
  - and [t/240-strict-mode-standalone-dt-alias-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/240-strict-mode-standalone-dt-alias-boundary.t) now locks the updated child-root boundary through both pipeline and CLI for embedded and external child sources.

## 2026-04-01: RTL child metadata failures now keep metadata-file and parent-source context
- Continued the active `R10` diagnostics lane by teaching [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) to prepend stable context around blocked sidecar or embedded `.rtlif` metadata loading.
- Important continuity note:
  - sidecar `.rtlif` failures now keep `RTL metadata file: 'module.rtlif'`, `Parent composition source: 'top_source.fsm'`, and `RTL child module: '?rtl' 'module_name'`,
  - embedded `?rtlif` failures now keep `Source file: 'top_source.fsm'` plus the same RTL-child identity line,
  - [t/243-composition-rtl-child-diagnostic-context.t](/Users/richarddje/Documents/github/fsmgen/t/243-composition-rtl-child-diagnostic-context.t) locks both the external-sidecar and embedded-metadata failure families through pipeline and CLI,
  - and the saved `R10` story is now “top-level failures, then generated-child failures, then RTL-child metadata failures”.

## 2026-03-31: generated-child failures now keep child-source and parent-source context
- Continued the active `R10` diagnostics lane by teaching [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) to prepend stable source-local context around generated-child parse/semantic-generation failures.
- Important continuity note:
  - external child failures now keep `Source file: 'child_source.fsm'`, `Parent composition source: 'top_source.fsm'`, and `Generated child source: '?fsmc/?dtc' 'source_name'`,
  - embedded child failures now keep `Source file: 'top_source.fsm'` plus `Generated child source: '?fsmc/?dtc' 'source_name'`,
  - [t/242-composition-child-source-file-diagnostic-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/242-composition-child-source-file-diagnostic-boundary.t) locks that error shape through both pipeline and CLI,
  - and the saved `R10` story is now “top-level failures first, then generated-child failures” rather than only the initial top-level boundary.

## 2026-03-31: top-level pipeline and CLI failures now keep `Source file:` context
- Started the first dedicated `R10` slice by teaching [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm) to prepend `Source file: '...'` when top-level parse/generation work raises a normal string error.
- Important continuity note:
  - this is intentionally a top-level orchestration boundary, not a claim that fine-grained line/construct provenance is finished,
  - the same source-file context now appears for ordinary top-level parser/adapter failures and for strict-mode support-tier failures,
  - [t/241-top-level-source-file-diagnostic-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/241-top-level-source-file-diagnostic-boundary.t) locks the new error shape through both pipeline and CLI entry points,
  - and `R10` should now be treated as active rather than untouched.

## 2026-03-31: AXI intent-capture case study and executable-PDF target are now frozen in repo memory
- Reviewed the full external AXI workspace under `/Users/richarddje/Documents/livework/protocols/arm/axi/` and preserved the detailed method/conclusions in [docs/INTENT_CAPTURE_AXI_CASE_STUDY.md](/Users/richarddje/Documents/github/fsmgen/docs/INTENT_CAPTURE_AXI_CASE_STUDY.md).
- The saved durable direction is:
  - use normalized `Markdown`, not raw `PDF`, as the working textual surface,
  - work actor-first rather than protocol-as-a-monolith,
  - define phases before final FSM states,
  - justify persistent state from protocol rules,
  - keep source facts, derived machine rules, local design decisions, and explicit abstractions separate,
  - recover invariants/contracts/gates/assertions before `.fsm` emission,
  - and treat reusable transport micro-actors plus explicit interconnect actors as first-class capture outputs rather than implementation details.
- The saved long-term target is now stronger too:
  - future intent capture should aim toward an almost-fully-staged automated “executable PDF” flow that can emit `.fsm` sets, harness/testbench surfaces, scenario/test intent, verification plans, functional-coverage plans, and an honesty-preserving capture report.
- The saved process constraint is that every stage should have explicit gates:
  - normalization,
  - dossier/section mapping,
  - actor discovery,
  - interface/phase extraction,
  - invariant/contract/gate/assertion capture,
  - abstraction logging,
  - decomposition,
  - emission,
  - verification-asset generation,
  - and back-annotation/residue reporting.

## 2026-03-31: strict mode no longer collapses `?mod:` / `?module:` into `?dt:`
- Corrected shipped behavior:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) still owns the shared strict-mode root-family boundary,
  - [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm) and [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) still carry strict-mode enforcement through direct-root semantic module creation and generated child realization,
  - but strict mode no longer rejects `?mod:` / `?module:` or suggests migrating them to `?dt:`,
  - and [t/240-strict-mode-standalone-dt-alias-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/240-strict-mode-standalone-dt-alias-boundary.t) now locks strict-mode acceptance for top-level `?dt:` / `?mod:` / `?module:` roots plus `?dtc` child realization through `?mod:` / `?module:`.
- Important continuity note:
  - `?dt` means one decision tree,
  - `?mod:` / `?module:` remain distinct module/entity-architecture roots in the intended language model,
  - the current implementation may still route those roots through shared direct single-module machinery,
  - but docs and strict mode should not describe them as semantic aliases of `?dt:`,
  - and the live strict-mode root-family boundary is currently only the legacy `+fsm` family.

## 2026-03-31: strict mode now exists and its first shipped boundary rejects legacy `+fsm` roots
- Saved shipped behavior:
  - updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so the CLI now accepts `--strict`,
  - updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the public pipeline facade now accepts `strict_mode => 1`,
  - updated [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm) so strict mode now rejects the legacy `+fsm` root family with a targeted migration hint toward `?fsm:module_name`,
  - added [t/239-strict-mode-legacy-fsm-root-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/239-strict-mode-legacy-fsm-root-boundary.t),
  - and updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) plus the roadmap/continuity set so the first strict-mode boundary is explicit.
- Important continuity note:
  - `R9` is no longer purely hypothetical; the first enforcement slice is live,
  - the current strict-mode surface is intentionally narrow and should be widened in bounded high-signal cuts,
  - and the next strict-mode candidate should be another compatibility-vs-supported boundary that is already well documented in `R8`.

## 2026-03-31: execution cadence now alternates cleanup and feature work more deliberately
- Saved continuity rule:
  - do not let long uninterrupted consolidation-only streaks become the default working pattern,
  - after a cleanup/debt-reduction slice, the next honest move should usually be a visibly user-facing capability slice,
  - and repeated cleanup slices are still allowed, but only when they are the clear blocker for the next feature/contract/diagnostic step.
- Important continuity note:
  - future sessions should treat this as an execution-policy rule rather than a one-off preference,
  - and roadmap steering should now rebalance more often between internal architecture work and externally visible capability progress.

## 2026-03-31: live direct backend no longer instantiates the generation-structural-prelude shell
- Saved shipped behavior:
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the live direct backend no longer instantiates `backend_sv_generation_structural_prelude_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so the live backend now reaches scaffold/header/module/state/internal-declaration assembly directly before enable-condition generation,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationStructuralPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationStructuralPreludeSupport.pm) so it now survives only as a compatibility shell outside the live backend path,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm) and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm) so the older compatibility shells now rebuild their structural prefix directly over the scaffold and internal-declaration owners,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t), [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t), [t/233-systemverilog-generation-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/233-systemverilog-generation-prelude-support.t), [t/234-systemverilog-generation-tail-support.t](/Users/richarddje/Documents/github/fsmgen/t/234-systemverilog-generation-tail-support.t), and [t/237-systemverilog-generation-structural-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/237-systemverilog-generation-structural-prelude-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `97` reachable project files and `96` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live generation-structural-prelude shell itself,
  - it is the remaining lower-level coordination across the extracted prescan-preparation owner, consolidated-intermediate planning/stage owners, extracted tail owner, and the still-central top-level sequencing in [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm),
  - and future sessions should read the live direct backend assembly path as “flatten first, build scaffold/header/module/state/internal declarations directly, emit enable conditions, run the dedicated prescan owner, generate the consolidated intermediate stage, then let the tail owner close out the module.”

## 2026-03-31: live direct backend no longer instantiates the generation-enable-preparation shell
- Saved shipped behavior:
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the live direct backend no longer instantiates `backend_sv_generation_enable_preparation_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so the live backend now emits enable conditions and runs the extracted prescan-preparation owner directly after the structural prelude,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm) so it now survives only as a compatibility shell outside the live backend path,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm) and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm) so the older compatibility shells now rebuild their pre-stage flow over direct enable-condition generation plus the extracted prescan owner,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t), [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t), [t/233-systemverilog-generation-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/233-systemverilog-generation-prelude-support.t), [t/234-systemverilog-generation-tail-support.t](/Users/richarddje/Documents/github/fsmgen/t/234-systemverilog-generation-tail-support.t), and [t/236-systemverilog-generation-enable-preparation-support.t](/Users/richarddje/Documents/github/fsmgen/t/236-systemverilog-generation-enable-preparation-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `98` reachable project files and `97` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live generation-enable-preparation shell itself,
  - it is the remaining lower-level coordination across the extracted structural-prelude owner, prescan-preparation owner, consolidated-intermediate planning/stage owners, extracted tail owner, and the still-central top-level direct backend sequencing in [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm),
  - and future sessions should read the live direct backend assembly path as “flatten first, build the structural prelude, emit enable conditions directly, run the dedicated prescan owner, generate the consolidated intermediate stage, then let the tail owner close out the module.”

## 2026-03-31: live direct backend no longer instantiates the generation-pipeline shell
- Saved shipped behavior:
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the live direct backend no longer instantiates `backend_sv_generation_pipeline_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so the live backend now composes structural-prelude generation, enable-oriented preparation, consolidated intermediate stage generation, and tail closeout directly after flattening,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm) so it now survives only as a compatibility shell outside the live backend path,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) and [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `99` reachable project files and `98` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live generation-pipeline shell itself,
  - it is the remaining lower-level coordination across the extracted structural-prelude owner, prescan-preparation owner, narrowed enable-preparation owner, consolidated-intermediate planning/stage owners, extracted tail owner, and the still-central top-level direct backend sequencing in [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm),
  - and future sessions should read the live direct backend assembly path as “flatten first, then let `Orchestrator` compose structural prelude, enable preparation, consolidated intermediate stage, and tail closeout directly.”

## 2026-03-31: live direct backend no longer instantiates the generation-prelude shell
- Saved shipped behavior:
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the live direct backend no longer instantiates `backend_sv_generation_prelude_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm) so the live pipeline now composes [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationStructuralPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationStructuralPreludeSupport.pm) plus [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm) directly before the consolidated stage and tail owners,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm) so it now survives only as a compatibility shell outside the live backend path,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t), [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t), [t/233-systemverilog-generation-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/233-systemverilog-generation-prelude-support.t), and [t/234-systemverilog-generation-tail-support.t](/Users/richarddje/Documents/github/fsmgen/t/234-systemverilog-generation-tail-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `100` reachable project files and `99` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live generation-prelude shell itself,
  - it is the remaining lower-level coordination across the extracted structural-prelude owner, prescan-preparation owner, narrowed enable-preparation owner, consolidated-intermediate planning/stage owners, extracted tail owner, narrowed generation pipeline owner, and broader direct-backend convergence,
  - and future sessions should read the live direct backend assembly path as “flatten first, build the dedicated structural prelude, emit enable conditions, run the dedicated prescan-preparation owner, generate the consolidated intermediate stage, then let the tail owner emit WEN/EN, assignments, and module closeout.”

## 2026-03-31: live direct backend prescan preparation now has a dedicated owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPrescanPreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPrescanPreparationSupport.pm) as the live owner of logical-operation counting plus WEN/EN prescan after enable-condition emission and before consolidated intermediate generation,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_generation_prescan_preparation_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm) so it now keeps enable-condition emission plus composition of that extracted prescan owner instead of keeping logical-op counting and WEN/EN prescan inline,
  - added [t/238-systemverilog-generation-prescan-preparation-support.t](/Users/richarddje/Documents/github/fsmgen/t/238-systemverilog-generation-prescan-preparation-support.t), retargeted [t/236-systemverilog-generation-enable-preparation-support.t](/Users/richarddje/Documents/github/fsmgen/t/236-systemverilog-generation-enable-preparation-support.t) and [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `101` reachable project files and `100` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the logical-op counting / WEN-EN prescan pocket inside `GenerationEnablePreparationSupport`,
  - it is the remaining lower-level coordination across the extracted structural-prelude owner, the new prescan-preparation owner, the narrowed enable-preparation owner, consolidated-intermediate planning/stage owners, the extracted tail owner, the narrowed generation pipeline owner, and broader direct-backend convergence,
  - and future sessions should read the direct backend assembly path as “flatten first, build the dedicated structural prelude, emit enable conditions, run the dedicated prescan-preparation owner, generate the consolidated intermediate stage, then let the tail owner emit WEN/EN, assignments, and module closeout.”

## 2026-03-31: live direct backend structural pre-stage prelude now has a dedicated owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationStructuralPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationStructuralPreludeSupport.pm) as the live owner of scaffold rendering plus internal declaration rendering before enable-oriented pre-stage preparation,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_generation_structural_prelude_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm) so it now keeps structural-prelude plus enable-preparation composition instead of keeping the structural prefix inline,
  - added [t/237-systemverilog-generation-structural-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/237-systemverilog-generation-structural-prelude-support.t), retargeted [t/233-systemverilog-generation-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/233-systemverilog-generation-prelude-support.t) and [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `100` reachable project files and `99` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the structural header/module/state/internal-declaration prefix inside `GenerationPreludeSupport`,
  - it is the remaining lower-level coordination across the extracted structural-prelude owner, enable-preparation owner, consolidated-intermediate planning/stage owners, the extracted tail owner, the narrowed generation pipeline owner, and broader direct-backend convergence,
  - and future sessions should read the direct backend assembly path as “flatten first, build the dedicated structural prelude, run the dedicated enable-preparation owner, generate the consolidated intermediate stage, then let the tail owner emit WEN/EN, assignments, and module closeout.”

## 2026-03-31: live direct backend enable-oriented pre-stage preparation now has a dedicated owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm) as the live owner of enable-condition generation, logical-operation counting, and WEN/EN prescan before consolidated intermediate generation,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_generation_enable_preparation_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm) so it now keeps scaffold/declaration composition plus delegation to that extracted owner instead of keeping the enable/prescan cluster inline,
  - added [t/236-systemverilog-generation-enable-preparation-support.t](/Users/richarddje/Documents/github/fsmgen/t/236-systemverilog-generation-enable-preparation-support.t), retargeted [t/233-systemverilog-generation-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/233-systemverilog-generation-prelude-support.t) and [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `99` reachable project files and `98` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live enable-condition / logical-op-counting / WEN-EN prescan cluster inside `GenerationPreludeSupport`,
  - it is the remaining lower-level coordination across the extracted prelude owner, the new enable-preparation owner, consolidated-intermediate planning/stage owners, the extracted tail owner, the narrowed generation pipeline owner, and broader direct-backend convergence,
  - and future sessions should read the direct backend assembly path as “flatten first, build the structural prelude, run the dedicated enable-preparation owner, generate the consolidated intermediate stage, then let the tail owner emit WEN/EN, assignments, and module closeout.”

## 2026-03-31: live direct backend recursive decision-tree flattening now has a dedicated owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/DecisionTreeFlatteningSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/DecisionTreeFlatteningSupport.pm) as the live owner of recursive regular-state and standalone-DT flattening plus the final unified assignment-analysis handoff,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `decision_tree_flattening_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so `flatten_all_decision_trees(...)` and `flatten_decision_tree(...)` now delegate to that owner instead of keeping the recursive traversal inline,
  - added [t/235-flatteneddt-decision-tree-flattening-support.t](/Users/richarddje/Documents/github/fsmgen/t/235-flatteneddt-decision-tree-flattening-support.t), retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `98` reachable project files and `97` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the raw recursive decision-tree flattening cluster in `Orchestrator`,
  - it is the remaining lower-level coordination across the extracted prelude/stage/tail/pipeline owners plus broader direct-backend convergence around the now-thinner top-level generation sequence,
  - and future sessions should read the direct backend path as “reset state, attach module context, flatten through the dedicated flattening owner, then assemble HDL through the extracted generation owners.”

## 2026-03-31: live direct backend post-stage SystemVerilog tail now has a dedicated owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationTailSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationTailSupport.pm) as the live owner of unified WEN/EN emission, signal-assignment emission, and final `endmodule` closeout after consolidated intermediate generation,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_generation_tail_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm) so it now composes the extracted tail owner instead of owning WEN/EN emission, assignment emission, and module closeout inline,
  - added [t/234-systemverilog-generation-tail-support.t](/Users/richarddje/Documents/github/fsmgen/t/234-systemverilog-generation-tail-support.t), retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) and [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `97` reachable project files and `96` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live direct backend post-stage WEN/EN/assignment/endmodule sequence inside `GenerationPipelineSupport`,
  - it is the remaining lower-level coordination across the extracted prelude owner, consolidated-intermediate planning/stage composition, the extracted tail owner, the narrowed generation pipeline owner, and broader direct-backend convergence,
  - and future sessions should read the direct backend assembly path as “flatten first, build the prelude, generate the consolidated intermediate stage, then let the tail owner emit WEN/EN, assignments, and module closeout.”

## 2026-03-31: live direct backend pre-stage SystemVerilog prelude now has a dedicated owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm) as the live owner of scaffold/declaration/enable/factorization-policy/prescan preparation before consolidated intermediate generation,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_generation_prelude_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm) so it now composes the extracted prelude owner plus the existing stage/WEN-EN/assignment/closeout steps,
  - added [t/233-systemverilog-generation-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/233-systemverilog-generation-prelude-support.t), retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) and [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `96` reachable project files and `95` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live direct backend pre-stage scaffold/declaration/enable/prescan sequence inside `GenerationPipelineSupport`,
  - it is the remaining lower-level coordination across the extracted prelude owner, consolidated-intermediate planning/stage composition, the narrowed generation pipeline owner, and broader direct-backend convergence,
  - and future sessions should read the direct backend assembly path as “flatten first, build the prelude, generate the consolidated intermediate stage, then emit WEN/EN, assignments, and module closeout.”

## 2026-03-31: live direct backend post-flattening SystemVerilog assembly now has a dedicated pipeline owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm) as the live owner of the full step-2-through-step-7 post-flattening SystemVerilog assembly sequence,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_generation_pipeline_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so it now keeps reset/module-attachment/flattening while delegating post-flattening HDL assembly,
  - added [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t), retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `95` reachable project files and `94` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the whole post-flattening SystemVerilog assembly sequence in `Orchestrator`,
  - it is the remaining lower-level coordination across consolidated-intermediate planning, stage preparation, live stage generation, the new generation pipeline owner, and broader direct-backend convergence,
  - and future sessions should read the direct backend split as “flatten first, then let the generation-pipeline owner assemble the module,” with `Orchestrator` now only bridging per-run state, flattening, and final pipeline handoff.

## 2026-03-31: live direct backend stage 6 now has its own explicit consolidated stage owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm) as the live owner of full consolidated intermediate stage generation over stage preparation plus rendering,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_consolidated_intermediate_stage_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so live stage 6 now delegates through that owner instead of hand-composing stage preparation plus rendering inline,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) so the compatibility shell now delegates to the real live stage owner when it exists,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) and [t/224-systemverilog-consolidated-intermediate-generation-support.t](/Users/richarddje/Documents/github/fsmgen/t/224-systemverilog-consolidated-intermediate-generation-support.t), added [t/231-systemverilog-consolidated-intermediate-stage-support.t](/Users/richarddje/Documents/github/fsmgen/t/231-systemverilog-consolidated-intermediate-stage-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `94` reachable project files and `93` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the raw live stage-6 handoff in `Orchestrator`,
  - it is the remaining lower-level coordination across consolidated-intermediate planning, stage preparation, the new live stage owner, and broader direct-backend sequencing/convergence,
  - and future sessions should read the direct backend stage as “collect, normalize, classify, rescue/select, dependency-map/order, plan, project the prepared block, prepare the stage block, generate the live stage block, and then continue with WEN/EN plus assignment emission,” with the older generation, block, emitter, and intermediate dispatcher shells all remaining outside the live runtime spine.

## 2026-03-30: live direct backend no longer instantiates the consolidated intermediate generation compatibility shell
- Saved shipped behavior:
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend no longer instantiates `backend_sv_consolidated_intermediate_generation_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so live stage 6 now composes [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm) plus [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm) directly,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) so it now survives only as a compatibility-shell test surface outside the live backend path,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) and [t/224-systemverilog-consolidated-intermediate-generation-support.t](/Users/richarddje/Documents/github/fsmgen/t/224-systemverilog-consolidated-intermediate-generation-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `93` reachable project files and `92` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live consolidated generation wrapper,
  - it is the remaining lower-level coordination across consolidated-intermediate planning, stage preparation, rendering, and direct orchestrator sequencing,
  - and future sessions should read the live direct backend stage as “collect, normalize, classify, rescue/select, dependency-map/order, plan, project the prepared block, prepare the stage block, render it, and sequence that directly from the orchestrator,” with the old generation, block, emitter, and intermediate dispatcher shells all outside the live runtime spine.

## 2026-03-30: live consolidated intermediate prepared-block rendering now has a dedicated backend owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm) as the live owner of prepared-block rendering over the extracted declaration and assignment owners,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_consolidated_intermediate_rendering_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) so the live stage is now only the wrapper that composes stage preparation plus the rendering owner,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) so the compatibility shell delegates to the new live rendering owner when that owner exists,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) and [t/224-systemverilog-consolidated-intermediate-generation-support.t](/Users/richarddje/Documents/github/fsmgen/t/224-systemverilog-consolidated-intermediate-generation-support.t), and added [t/230-systemverilog-consolidated-intermediate-rendering-support.t](/Users/richarddje/Documents/github/fsmgen/t/230-systemverilog-consolidated-intermediate-rendering-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `94` reachable project files and `93` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer final prepared-block rendering inside the live generation owner,
  - it is the remaining stage-level coordination across stage preparation, prepared-block rendering, and the narrowed generation wrapper,
  - and future sessions should read the direct backend stage as “collect, normalize, classify, rescue/select, dependency-map/order, plan, project the prepared block, prepare the stage block, render the prepared block, and hand that stage through the wrapper,” with the older block and emitter shells both outside the live runtime spine.

## 2026-03-30: live consolidated intermediate stage preparation now has a dedicated backend owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm) as the live owner of prepared-block reconstruction from the extracted collection, planning, and prepared-block projection owners,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_consolidated_intermediate_stage_preparation_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) so the live stage now composes stage preparation plus final prepared-block rendering instead of rebuilding the prepared block inline,
  - kept [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm) as a compatibility-shell test surface outside the live backend path with corrected POD about the new live owner,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) and [t/224-systemverilog-consolidated-intermediate-generation-support.t](/Users/richarddje/Documents/github/fsmgen/t/224-systemverilog-consolidated-intermediate-generation-support.t), and added [t/229-systemverilog-consolidated-intermediate-stage-preparation-support.t](/Users/richarddje/Documents/github/fsmgen/t/229-systemverilog-consolidated-intermediate-stage-preparation-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `93` reachable project files and `92` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer live prepared-block reconstruction inside generation support,
  - it is the remaining lower-level coordination across consolidated-intermediate planning, prepared-block projection, stage preparation, and final generation/rendering,
  - and future sessions should read the direct backend stage as “collect, normalize, classify, rescue/select, dependency-map/order, plan, project the prepared block, prepare the live stage block, and render,” with the old block and emitter shells both outside the runtime spine.

## 2026-03-30: live direct backend no longer instantiates the consolidated emitter compatibility shell
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) no longer instantiates `backend_sv_consolidated_intermediate`,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) now owns final prepared-block rendering directly in addition to collection/planning/prepared-block stage handoff,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) now survives only as a compatibility-shell test surface outside the live backend path,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `92` reachable project files and `91` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the old consolidated emitter shell,
  - it is the remaining lower-level coordination across consolidated-intermediate planning, prepared-block projection, and live generation support,
  - and future sessions should read the live direct backend path as “collect, normalize, classify, rescue/select, dependency-map/order, plan, project the prepared block, and render,” with the old emitter shell outside the runtime spine.

## 2026-03-30: future `.fsm` hierarchy should be authored bottom-up but compiled from the top
- Saved direction:
  - whole `.fsm` designs should eventually behave like authored bottom-up N-level hierarchies with non-leaf composition nodes and leaf implementation nodes,
  - `fsmgen top.fsm` should remain the public UX and recursively realize child nodes level by level until the full top is emitted,
  - internal non-leaf reusable composition modules should eventually become first-class authored artifacts instead of composition remaining only a one-top shell over leaf children,
  - interface and semantic summaries should flow upward from children while binding/wiring is resolved at each parent level,
  - and the important implementation distinction is authored tree vs elaborated instance tree: source reuse may make the authored graph a DAG, while elaboration still produces a hierarchical instance tree.
- Important continuity note:
  - this was logged from explicit brainstorming as future architecture steering, not as a command to widen the current composition contract immediately,
  - future sessions should treat it as guidance for the reusable-source/composition lane under `R11`,
  - and the intended user experience stays simple even if the implementation becomes recursive: build leaves first, invoke only the top.

## 2026-03-30: actor-first protocol extraction guidance and first imported APB/AMBA fixtures are now saved
- Saved direction:
  - reviewed the external protocol-extraction references under `/Users/richarddje/Documents/livework/protocols/arm/amba/`,
  - the useful working method there is strongly aligned with the saved `H4` direction: start from normalized `Markdown`, work actor-first instead of protocol-as-a-monolith, and keep source facts, derived machine rules, local design decisions, and explicit abstractions separate,
  - the method artifacts worth preserving are: protocol dossier, actor catalog, actor sheet per actor, assertion ledger, abstraction/boundedness log, FSM mapping sheet, and validation log,
  - actor interfaces plus invariants/contracts/gates should be captured in plain English before `.fsm` emission,
  - and the repo now has first imported protocol fixtures in [fsm/apb_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_requester.fsm), [fsm/apb_completer.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_completer.fsm), [fsm/apb_tb.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_tb.fsm), and [fsm/amba_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/amba_requester.fsm).
- Important continuity note:
  - the imported APB top now resolves against prefixed child source names `apb_requester` and `apb_completer` so the dataset fits cleanly inside the repo-wide `fsm/` corpus,
  - all four imported fixtures were validated through the live `bin/fsmgen` entrypoint,
  - and this is dataset seeding plus method capture, not a roadmap lane switch away from active `R11`.

## 2026-03-30: protocol/TRM spec-to-`.fsm` intent capture is now saved as a separate future direction
- Saved direction:
  - treat future `PDF` / TRM / protocol-`Markdown` to `.fsm` work as a separate intent-capture lane rather than as HDL import under another name,
  - prefer the term `intent capture` over `intent synthesis` when the source is prose/specification text, because the output should stay honest about ambiguity and human confirmation,
  - model the likely pipeline as `PDF -> .md -> normalized spec IR -> recovered roles/transactions/timing rules/invariants -> .fsm + capture report`,
  - expect bounded outputs such as requester/initiator roles, completer/target roles, checker/monitor assets, reusable assertions/invariants, and optional `.fsm` composition/testbench harnesses for protocols like `APB`, `AMBA`, `AXI`, `I2C`, and `I2S`,
  - and treat this as assisted capture with explicit confidence/heuristic/ambiguity residue reporting, not as magical one-shot conversion.
- Important continuity note:
  - this was logged from explicit brainstorming and strong user agreement, not as an instruction to leave the active `R11` lane,
  - future sessions should treat it as a real long-term roadmap direction worth design/probe work,
  - and it should stay distinct from HDL import / intent recovery even if both directions eventually share middle-layer IRs.

## 2026-03-30: reusable library, semantic parameters, and phased intent-recovery start are now saved guidance
- Saved direction:
  - future reusable-library work should start as ordinary reusable `.fsm` assets flowing through the normal parser/IR/emitter path,
  - that library should begin with a small curated gold set rather than a broad primitive zoo or magical builtins,
  - future parameterization should use explicit semantic parameters plus explicit override binding that survives into IR rather than text/template preprocessing,
  - and HDL import / intent recovery can start with design/probe work plus bounded round-trip experiments, but serious implementation should stay behind the active forward/backend cleanup and language-contract hardening.
- Important continuity note:
  - this was logged from explicit brainstorming and is saved as guidance, not as an immediate lane switch,
  - future sessions should treat it as roadmap steering for when those lanes open, not as a command to stop `R11`.

## 2026-03-30: live direct backend no longer instantiates the consolidated block compatibility shell
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) no longer instantiates `backend_sv_consolidated_intermediate_block_support`,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) now composes collection, planning, prepared-block projection, and final rendering directly,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm) now survives only as a directly testable compatibility shell outside the live backend path,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `93` reachable project files and `92` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the old consolidated block shell,
  - it is the remaining lower-level coordination across planning, prepared-block projection, stage generation, and final emission,
  - and future sessions should read the direct consolidated-intermediate path as “collect, normalize, classify, rescue/select, dependency-map/order, plan, project the prepared block, and render,” with the old block shell outside the live runtime spine.

## 2026-03-29: prepared consolidated intermediate block projection now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm) now owns prepared block-contract projection for the direct consolidated intermediate path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm) is now narrowed to collection-plus-planning handoff into that prepared-block owner,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `94` reachable project files and `93` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer prepared block-contract projection inside the direct consolidated intermediate path,
  - it is the remaining lower-level coordination across block handoff, stage generation, and final emission,
  - and future sessions should now read that backend stage as “collect, normalize, classify, rescue/select, dependency-map/order, plan, hand off the block, project the prepared contract, and render.”

## 2026-03-29: consolidated intermediate dependency mechanics now have a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm) now owns dependency-map construction plus dependency-safe ordering for the direct consolidated intermediate path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm) is now narrowed to overall plan composition over the extracted selection and dependency owners,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `93` reachable project files and `92` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the dependency-map or ordering split inside the direct consolidated intermediate path,
  - it is the remaining lower-level coordination across plan composition, block preparation, and final emission,
  - and future sessions should now read that backend stage as “collect, normalize, classify, rescue/select, dependency-map/order, plan, prepare, and render.”

## 2026-03-28: consolidated intermediate classification now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm) now owns the initial AST-first keep/filter partition for the direct consolidated intermediate path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm) is now narrowed to dependency-aware rescue plus final kept/filtered summary projection,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `92` reachable project files and `91` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the first-pass classification split inside the direct consolidated intermediate path,
  - it is the remaining lower-level coordination across selection, planning, block preparation, and final emission,
  - and future sessions should read that backend stage as “collect, normalize, classify, rescue/select, plan, prepare, and render.”

## 2026-03-28: consolidated intermediate normalization now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm) now owns runtime AST, width, dependency, rendered-expression, and live-usage normalization over the merged direct consolidated intermediate set,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm) is now narrowed to trace plus merged-signal collection,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `91` reachable project files and `90` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the collection-vs-normalization split inside the direct consolidated intermediate path,
  - it is the remaining lower-level coordination across selection, planning, block preparation, and final emission,
  - and future sessions should read that backend stage as “collect, normalize, select, plan, prepare, and render,” with collection and normalization now named as separate owners.

## 2026-03-28: consolidated intermediate stage generation now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) now owns the full direct consolidated-intermediate stage handoff for one FSM module,
  - [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) no longer coordinates that stage inline,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `90` reachable project files and `89` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the stage handoff from `Orchestrator`,
  - it is the remaining lower-level coordination inside the selection/planning/block/emitter cluster,
  - and the live import-tree note should now be read as “the direct consolidated-intermediate path has explicit owners for preparation, selection, planning, block prep, assignment emission, declaration rendering, stage generation, and final block composition.”

## 2026-03-28: consolidated intermediate declaration rendering now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm) now owns prepared consolidated wire declarations on the direct backend path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) is now narrowed to final block composition over declaration and assignment owners,
  - and [t/223-systemverilog-consolidated-intermediate-declaration-support.t](/Users/richarddje/Documents/github/fsmgen/t/223-systemverilog-consolidated-intermediate-declaration-support.t) plus the tightened owner checks now lock that split directly.
- Important continuity note:
  - the next likely seam is no longer “who owns prepared consolidated wire declarations,”
  - it is the remaining coordination between selection, planning, block preparation, and the narrowed emitter,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct consolidated intermediate path is split into preparation, selection, planning, block preparation, assignment emission, declaration rendering, and final block composition.”

## 2026-03-28: live direct backend no longer instantiates the intermediate dispatcher shell
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm) now owns the live AST-first consolidated keep/filter dispatch directly by combining the recovery and filter-policy owners,
  - [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) no longer instantiates `backend_sv_intermediate_support`,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm) now survives only as a compatibility-shell package for direct owner tests,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `88` reachable project files and `87` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the old intermediate dispatcher shell,
  - it is the remaining coordination across selection, planning, block preparation, and the narrowed consolidated emitter,
  - and future sessions should read the direct consolidated-intermediate path as “collection, live selection, planning, block preparation, assignment emission, and final block/declaration emission,” with the old dispatcher shell outside the runtime spine.

## 2026-03-28: consolidated intermediate assignment emission now has a dedicated owner
- Saved shipped behavior:
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm) now owns prepared consolidated assign emission on the direct backend path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) is now narrowed to block composition plus consolidated wire-declaration rendering,
  - and [t/222-systemverilog-consolidated-intermediate-assignment-support.t](/Users/richarddje/Documents/github/fsmgen/t/222-systemverilog-consolidated-intermediate-assignment-support.t) plus the tightened owner checks now lock that split directly.
- Important continuity note:
  - the next likely seam is no longer “who owns prepared consolidated assign emission,”
  - it is the remaining coordination between prepared block composition, declaration rendering, and the narrowed emitter shell,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct consolidated intermediate path is split into preparation, selection, planning, block preparation, assignment emission, and block/declaration emission.”

## 2026-03-28: consolidated intermediate selection now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm) now owns dependency-aware keep/filter/rescue selection over the normalized consolidated intermediate set on the direct backend path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm) is now narrowed to dependency-map construction, dependency-safe ordering, and overall plan composition,
  - and [t/221-systemverilog-consolidated-intermediate-selection-support.t](/Users/richarddje/Documents/github/fsmgen/t/221-systemverilog-consolidated-intermediate-selection-support.t) plus the tightened planning/owner checks now lock that split directly.
- Important continuity note:
  - the next likely seam is no longer “who owns set-level keep/filter/rescue selection” in the direct consolidated intermediate path,
  - it is the remaining coordination between normalized collection, selection, planning, block preparation, and final emission,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct consolidated intermediate path is split into preparation, selection, planning, block preparation, and emission.”

## 2026-03-28: new-session bootstrap is now a dedicated root document
- Saved shipped behavior:
  - [SESSION_BOOTSTRAP.md](/Users/richarddje/Documents/github/fsmgen/SESSION_BOOTSTRAP.md) now exists as the canonical first-task file for a normal new engineering session,
  - it tells a new agent to read [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), read the README-linked Markdown set, analyze [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) and its import tree, refresh [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) if needed, and then continue against [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md),
  - and [README.md](/Users/richarddje/Documents/github/fsmgen/README.md) now points to that file explicitly in fast ramp-up, the documentation index, and a fresh-session shortcut note.
- Important continuity note:
  - for future sessions, the shortest reliable startup instruction is now:
    - `Read SESSION_BOOTSTRAP.md and start from there.`
  - this is meant to be the default engineering-session ritual, not a ban on narrower one-off tasks when the user explicitly wants something else.

## 2026-03-28: refreshed `bin/fsmgen` import-tree measurement snapshot
- Saved current analysis:
  - [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes measured package-family counts, thin-coordinator line counts, and the current largest reachable files by line count,
  - the saved static trace still lands at `87` project files / `86` `.pm` packages reachable from [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen),
  - and the saved interpretation is explicit: `HDLGenerator` is now honestly thin, while the remaining active `R11` gravity is still lower in the direct backend/support stack and a few large composition/reporting builders.
- Important continuity note:
  - future sessions should treat the measured hotspot list as context, not as an automatic refactor order,
  - the next roadmap slice should still be chosen by architectural leverage, not by raw file size alone.

## 2026-03-28: direct intermediate width normalization now has a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm) now owns direct intermediate width normalization and recursive width inference,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm) is now narrowed to runtime-AST lookup, rendered-expression recovery, and dependency recovery,
  - and [t/220-systemverilog-intermediate-signal-width-support.t](/Users/richarddje/Documents/github/fsmgen/t/220-systemverilog-intermediate-signal-width-support.t) now locks the extracted width owner directly.
- Important continuity note:
  - the next likely seam is no longer “who owns intermediate width normalization,”
  - it is the remaining direct-backend coordination around consolidated intermediate rendering/filter/ordering and any still-muddied handoff between the neighboring intermediate owners,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct intermediate path is split into recovery, width, filter heuristics, filter dispatch, consolidated preparation, consolidated planning, block preparation, and final emission.”

## 2026-03-28: consolidated intermediate block preparation now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm) now owns the collection-plus-planning handoff for one prepared consolidated intermediate block on the direct backend path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) is now narrowed to pure rendering from that prepared block contract,
  - and [t/219-systemverilog-consolidated-intermediate-block-support.t](/Users/richarddje/Documents/github/fsmgen/t/219-systemverilog-consolidated-intermediate-block-support.t) now locks the extracted owner directly.
- Important continuity note:
  - the next likely seam is no longer collection-plus-planning handoff inside the direct consolidated emitter,
  - it is the remaining direct rendering/sequence coordination around the consolidated intermediate path and the neighboring intermediate recovery/filter owners,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct consolidated intermediate path is split into support, planning, block preparation, and rendering.”

## 2026-03-28: fixpoint loop state now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm) now owns aggregate loop-state creation, accepted-pass outcome application, and final termination/result normalization for the iterative post-substitution factorization path,
  - [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) is now narrowed further to pass scheduling and top-level coordination,
  - and [t/218-factorization-fixpoint-loop-state-support.t](/Users/richarddje/Documents/github/fsmgen/t/218-factorization-fixpoint-loop-state-support.t) now locks the extracted owner directly against continue, terminate, terminate-after-accept, and pass-cap finalization paths.
- Important continuity note:
  - the next likely seam is no longer the fixpoint aggregate loop-state contract,
  - it is the remaining direct-backend dispatcher/planning/emission coordination around the consolidated intermediate path,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct fixpoint path is split into pass scheduling, loop state, pass execution, and pass helpers.”

## 2026-03-28: fixpoint pass execution now has a dedicated factorization owner
- Saved shipped behavior:
  - [perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm) now owns one-pass factorizer construction, repeated-signature short-circuit detection, and per-pass substitution/update execution,
  - [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) is now narrowed further to the outer loop, pass-cap, and aggregate-result contract,
  - and [t/217-factorization-fixpoint-pass-execution-support.t](/Users/richarddje/Documents/github/fsmgen/t/217-factorization-fixpoint-pass-execution-support.t) now locks the extracted owner directly against the prepared no-new-candidate and repeated-signature paths.
- Important continuity note:
  - the next likely seam is no longer “who owns one prepared second-pass execution,”
  - it is the remaining aggregate termination/policy gravity in [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) plus the downstream direct-backend planning/emission convergence,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct fixpoint path is split into outer loop, pass execution, and pass helpers.”

## 2026-03-28: direct intermediate filter heuristics now have a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalFilterPolicySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalFilterPolicySupport.pm) now owns AST-aware keep/filter heuristics, runtime-AST-miss live-usage fallback, and the small AST-shape predicates for the direct intermediate-signal path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm) is now narrowed to consolidated-signal filter dispatch over recovery lookup plus that extracted policy owner,
  - and [t/216-systemverilog-intermediate-signal-filter-policy-support.t](/Users/richarddje/Documents/github/fsmgen/t/216-systemverilog-intermediate-signal-filter-policy-support.t) plus the tightened [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) now lock that backend split directly.
- Important continuity note:
  - the next likely seam is no longer “who owns the AST-vs-runtime filter heuristics,”
  - it is the remaining post-factorization loop/planning/emission gravity around [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm), and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm),
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct intermediate path is split into recovery, filter heuristics, filter dispatch, consolidated preparation, consolidated planning, and final emission.”

## 2026-03-28: consolidated intermediate planning now has a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm) now owns dependency-map construction, dependency-aware rescue/filter planning, and dependency-safe emission ordering for consolidated intermediates,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) is now narrowed to final wire/assign emission from that extracted plan,
  - and [t/215-systemverilog-consolidated-intermediate-planning-support.t](/Users/richarddje/Documents/github/fsmgen/t/215-systemverilog-consolidated-intermediate-planning-support.t) now locks that owner directly.
- Important continuity note:
  - the next likely seam is no longer “who owns consolidated rescue/order planning,”
  - it is the remaining post-factorization/filter-policy gravity in [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm),
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct consolidated intermediate path is split into preparation, planning, and emission.”

## 2026-03-28: fixpoint pass support now has a dedicated factorization owner
- Saved shipped behavior:
  - [perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm) now owns the iterative second-pass helper family: primary intermediate lookup, deterministic pass signatures, second-pass name-collision recovery, and new-signal projection/debugging,
  - [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) is now narrowed to the loop, termination, and aggregate-result contract,
  - and [t/214-factorization-fixpoint-pass-support.t](/Users/richarddje/Documents/github/fsmgen/t/214-factorization-fixpoint-pass-support.t) now locks that extracted owner directly.
- Important continuity note:
  - the next likely seam is no longer “who owns the fixpoint pass helpers,”
  - it is the remaining post-factorization policy/termination gravity in [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) plus the downstream direct-backend filter/order/recovery owners,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct factorization path is split into first-pass owner, fixpoint loop owner, and per-pass helper owner.”

## 2026-03-28: direct SystemVerilog global factorization now has a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm) now owns the direct first-pass AST-factorization pipeline: factorizer construction, substitution, original-AST refresh, fixpoint delegation, and factorizer persistence,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) now asks that owner directly for first-pass factorization,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm) is now narrowed to substituted-AST lookup plus the legacy direct intermediate-signal rendering helper,
  - and [t/211-systemverilog-global-factorization-support.t](/Users/richarddje/Documents/github/fsmgen/t/211-systemverilog-global-factorization-support.t) plus the tightened [t/201-systemverilog-ast-factorization-support.t](/Users/richarddje/Documents/github/fsmgen/t/201-systemverilog-ast-factorization-support.t) and [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) now lock that split directly.
- Important continuity note:
  - the next likely seam is no longer “who owns the first factorization pass,”
  - it is the remaining post-factorization/fixpoint gravity around [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm), and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm).

## 2026-03-27: EnableGraph factorization support now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm) now owns the synthesis-side factorization-analysis and substitution/live-usage evidence family: logical-operation counting, factorizer feed preparation, second-pass feed selection, substitution synchronization, signal-reference checks, and live-usage derivation for factorized intermediates,
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm), and [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) now ask that owner directly,
  - and [t/203-enable-graph-factorization-support.t](/Users/richarddje/Documents/github/fsmgen/t/203-enable-graph-factorization-support.t) plus [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) now lock the extracted owner boundary.
- Important continuity note:
  - this is the second real owner pulled out of the larger `EnableGraph` gravity well, so the remaining pressure is now even more clearly broader planning/policy plus fixpoint iteration,
  - the direct owner test also records an honest nuance we should preserve: in the prepared backend context, a factorized signal like `A_or_B` can be live by substitution evidence only rather than by final owner-side expression presence,
  - and the next likely seam is broader cleanup in [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) or narrower iterative-factorization policy cleanup in [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm).

## 2026-03-27: EnableGraph intermediate-signal support now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm) now owns normalized intermediate-signal registry access, native defining-AST lookup, compatibility-expression parsing, rendered-expression recovery, signal-name dependency AST recovery, and referenced-intermediate declaration tracking for the synthesis side,
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm), and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) now ask that owner directly,
  - and [t/202-enable-graph-intermediate-signal-support.t](/Users/richarddje/Documents/github/fsmgen/t/202-enable-graph-intermediate-signal-support.t) plus [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) now lock the extracted owner boundary.
- Important continuity note:
  - this is the first real owner pulled out of the larger `EnableGraph` synthesis gravity well, not another direct SystemVerilog package split,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “remaining backend pressure is broader `EnableGraph` planning plus `Fixpoint`, with intermediate-signal support already separated,”
  - and the next likely seam is deeper cleanup in [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) or [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm), not another intermediate-signal extraction.

## 2026-03-27: direct SystemVerilog AST factorization support now has a dedicated backend owner and the old backend package is retired
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm) now owns direct generated-module AST factorization, post-substitution fixpoint delegation, substituted-AST lookup, and the legacy direct intermediate-signal rendering helper,
  - the live direct backend owners now ask that package directly instead of routing through [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm),
  - and [t/201-systemverilog-ast-factorization-support.t](/Users/richarddje/Documents/github/fsmgen/t/201-systemverilog-ast-factorization-support.t) now locks the extracted owner directly against a realistic shared-expression factorization fixture.
- Important continuity note:
  - this retires the last live direct SystemVerilog monolith instead of keeping a fake compatibility shell,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “direct backend gravity lives in explicit owners plus `EnableGraph` / fixpoint support,”
  - and the next likely seam is deeper cleanup in [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) or [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm), not more SystemVerilog package splitting.

## 2026-03-27: direct SystemVerilog consolidated intermediate emission now has a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) now owns direct generated-module consolidated intermediate-signal emission from the prepared AST-factorization plus pre-scan context,
  - [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) now asks that owner directly for the consolidated wire/assign block before unified WEN/EN generation,
  - and [t/200-systemverilog-consolidated-intermediate-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/200-systemverilog-consolidated-intermediate-emitter.t) now locks the extracted owner directly against the emitted backend prefix for a realistic shared-expression direct-root fixture.
- Important continuity note:
  - this is another real backend split under the older direct generated-module path, not more pipeline work,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes the new consolidated-intermediate owner explicitly,
  - and the next likely seam is deeper cleanup inside the remaining AST-factorization/substitution side of [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) or the planning surface in [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm).

## 2026-03-27: direct SystemVerilog intermediate-signal support now has a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm) now owns direct generated-module runtime AST recovery, rendered-expression caching, dependency recovery, width inference, and AST-aware filtering for consolidated intermediate signals,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) now asks that owner directly during consolidated intermediate-signal generation,
  - and [t/07-runtime-ast-miss-dependency-recovery.t](/Users/richarddje/Documents/github/fsmgen/t/07-runtime-ast-miss-dependency-recovery.t) plus [t/08-driving-ast-canonicalization.t](/Users/richarddje/Documents/github/fsmgen/t/08-driving-ast-canonicalization.t) now lock the extracted owner directly.
- Important continuity note:
  - this is another real backend split under the older direct generated-module path, not pipeline work,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes the new intermediate-signal support owner explicitly,
  - and the next likely seam is deeper cleanup inside the remaining consolidated intermediate-signal emission/factorization core in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) or the planning surface in [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm).

## 2026-03-27: direct SystemVerilog internal declaration rendering now has a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm) now owns direct generated-module internal storage and helper-register declaration rendering,
  - [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) now asks that owner directly for the declaration block after scaffold rendering,
  - and [t/199-systemverilog-internal-declaration-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/199-systemverilog-internal-declaration-emitter.t) now locks the extracted owner against the emitted backend prefix for a realistic declaration-heavy direct-root fixture.
- Important continuity note:
  - this is another real backend split under the older direct generated-module path, not pipeline work,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes the new declaration owner explicitly,
  - and the next likely seam is deeper cleanup inside the remaining [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) intermediate-signal/consolidation core or the planning surface in [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm).

## 2026-03-26: direct SystemVerilog scaffold rendering now has a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm) now owns direct generated-module header, module declaration, state encoding, and state register rendering,
  - [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) now asks that owner directly for the top-of-module scaffold family,
  - and [t/198-systemverilog-scaffold-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/198-systemverilog-scaffold-emitter.t) now locks the extracted owner against the emitted backend prefix for both regular-state and standalone-DT roots.
- Important continuity note:
  - this is a real backend split under the older direct generated-module path, not more pipeline facade cleanup,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes the new scaffold owner explicitly,
  - and the next likely seam is deeper cleanup inside the remaining [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) / [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) core.

## 2026-03-26: old source-frontend wrapper residue is now gone from the pipeline facade
- Saved shipped behavior:
  - the remaining regression callers now ask [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) directly for parse/classify/composition-parse/semantic-module creation,
  - [t/197-pipeline-source-frontend.t](/Users/richarddje/Documents/github/fsmgen/t/197-pipeline-source-frontend.t) now locks `SourceFrontend` against the real pipeline result surface rather than the removed facade wrappers,
  - and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) no longer carries any frontend pass-through methods.
- Important continuity note:
  - `HDLGenerator` is now effectively the public entry facade plus shared config only,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “orchestrators plus explicit owners do the work; `HDLGenerator` just starts it,”
  - and the next likely seam is now deeper cleanup under the older direct backend family rather than more facade trimming.

## 2026-03-26: old direct generated-module helper residue is now gone from the pipeline facade
- Saved shipped behavior:
  - [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm), [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm), and [perl/FSM/Composition/GenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GenerationOrchestrator.pm) now ask the explicit direct-root/generated-module owner packages directly instead of routing through `HDLGenerator` wrappers,
  - the direct-owner coverage in [t/191-forward-intent-hir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/191-forward-intent-hir-builder-direct-root.t), [t/192-forward-lowered-rtl-ir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/192-forward-lowered-rtl-ir-builder-direct-root.t), [t/193-forward-structural-rtl-ir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/193-forward-structural-rtl-ir-builder-direct-root.t), [t/194-generated-module-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/194-generated-module-emitter.t), [t/196-generated-module-info-builder.t](/Users/richarddje/Documents/github/fsmgen/t/196-generated-module-info-builder.t), [t/182-composition-result-metadata-builder.t](/Users/richarddje/Documents/github/fsmgen/t/182-composition-result-metadata-builder.t), and [t/189-composition-generation-orchestrator.t](/Users/richarddje/Documents/github/fsmgen/t/189-composition-generation-orchestrator.t) now points at those real owners too,
  - and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) no longer carries the old direct helper family for direct-root IR building, generated-module metadata helpers, backend glue, or statistics seed access.
- Important continuity note:
  - `HDLGenerator` is now much closer to the intended thin facade shape,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “orchestrator family is the hub, `HDLGenerator` is the public facade” rather than the older monolith reading,
  - and the next likely seam is now the small remaining public source-frontend facade or deeper cleanup under the older direct backend family.

## 2026-03-26: old composition reporting helper residue is now gone from the pipeline facade
- Saved shipped behavior:
  - [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) no longer owns the old composition failure-summary and provenance/override/block label helper family,
  - [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now asks [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm) and [perl/FSM/Composition/ProvenanceReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ProvenanceReportBuilder.pm) for those reporting surfaces directly,
  - and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now anchors direct failure-summary coverage to the failure-report builder owner instead of the pipeline facade.
- Important continuity note:
  - this is another real `HDLGenerator` thinning step, not just a docs rename,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now reflects that `bin/fsmgen` directly imports those builder owners,
  - and the next likely seam remains the thinner remaining `HDLGenerator` facade/helper residue or deeper cleanup under the older direct generated-module backend family.

## 2026-03-26: bounded source parsing and semantic-module creation now live in a dedicated frontend package
- Saved shipped behavior:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now owns bounded source parsing, source-kind classification, typed composition parsing, and semantic FSM/DT module creation,
  - the top-level source orchestrator, direct-root orchestrator, composition generation orchestrator, and generated-child realizer now call that owner directly,
  - and [t/197-pipeline-source-frontend.t](/Users/richarddje/Documents/github/fsmgen/t/197-pipeline-source-frontend.t) now locks the extracted owner directly against the pipeline facade surface.
- Important continuity note:
  - `HDLGenerator` no longer keeps that frontend family inline,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `SourceFrontend` explicitly in the pipeline/frontend layer,
  - and the next likely seam is now the thinner remaining `HDLGenerator` facade/helper residue or deeper cleanup under the older direct generated-module backend family.

## 2026-03-26: bounded generated-module module_info construction now lives in a dedicated pipeline builder
- Saved shipped behavior:
  - [perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm) now owns bounded generated-module `module_info` construction from semantic FSM/DT modules plus their intent HIR,
  - that package now also owns lowered generated-analysis enrichment and the normalized query surface over output-drive families and grouped standalone-DT multi-drive targets,
  - and [t/196-generated-module-info-builder.t](/Users/richarddje/Documents/github/fsmgen/t/196-generated-module-info-builder.t) now locks the extracted owner directly against the pipeline result surface.
- Important continuity note:
  - `DirectGenerationOrchestrator` and `GeneratedChildRealizer` no longer keep that generated-module metadata family inline,
  - `HDLGenerator` now only keeps thin delegations for the same family,
  - [t/194-generated-module-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/194-generated-module-emitter.t) was also tightened to ignore non-semantic intermediate declaration ordering,
  - and the next likely seam is now the thinner remaining `HDLGenerator` facade/helper residue or deeper cleanup under the older `FlattenedDT` / `EnableGraph` backend family.

## 2026-03-26: top-level source/file dispatch now lives in a dedicated pipeline orchestrator
- Saved shipped behavior:
  - [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm) now owns top-level source-file orchestration,
  - that package now parses one source file, classifies the root kind, dispatches into the direct-root or composition orchestrator, and drives the surrounding extension-hook/final-result boundary,
  - and [t/195-pipeline-source-generation-orchestrator.t](/Users/richarddje/Documents/github/fsmgen/t/195-pipeline-source-generation-orchestrator.t) now locks the extracted owner directly across direct-root, composition, and extension-hook paths.
- Important continuity note:
  - `HDLGenerator` no longer keeps the top-level parse/classify/dispatch/finalization cluster inline,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `SourceGenerationOrchestrator` explicitly in the pipeline hub family,
  - and the next likely seam is now the thinner remaining `HDLGenerator` facade residue or deeper cleanup under the older `FlattenedDT` / `EnableGraph` backend family.

## 2026-03-26: bounded direct generated-module backend execution now lives in a dedicated backend package
- Saved shipped behavior:
  - [perl/FSM/Backend/GeneratedModuleEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/GeneratedModuleEmitter.pm) now owns bounded direct generated-module backend execution for direct FSM/DT roots and realized generated children,
  - that package now also owns backend-method selection, backend statistics collection, and standalone-DT assertion postprocessing around the existing `FlattenedDT` backend family,
  - and [t/194-generated-module-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/194-generated-module-emitter.t) now locks the extracted backend owner directly against the full pipeline result surface.
- Important continuity note:
  - `HDLGenerator`, `DirectGenerationOrchestrator`, and `GeneratedChildRealizer` no longer keep that bounded direct backend family inline,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `GeneratedModuleEmitter` explicitly in the direct single-module backend family,
  - and the next likely seam is now broader `HDLGenerator` facade/coordinator cleanup or deeper cleanup under the older `FlattenedDT` / `EnableGraph` backend family.

## 2026-03-26: direct-root StructuralRTLIR construction now lives in the IR builder package
- Saved shipped behavior:
  - [perl/FSM/IR/StructuralRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIRBuilder.pm) now owns bounded direct-root structural-IR construction from generated-module analysis,
  - that package now also owns direct-root module-boundary port assembly and implicit-system-port structural projection,
  - and [t/193-forward-structural-rtl-ir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/193-forward-structural-rtl-ir-builder-direct-root.t) now locks the extracted direct-root owner directly against the pipeline result surface.
- Important continuity note:
  - `HDLGenerator` no longer owns those direct-root structural helper families inline,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now describes `StructuralRTLIRBuilder` as a direct-root plus composition-top structural builder,
  - and the next likely seam is now the remaining direct-path backend residue or a broader `HDLGenerator` facade split.

## 2026-03-26: direct-root LoweredRTLIR construction now lives in the IR builder package
- Saved shipped behavior:
  - [perl/FSM/IR/LoweredRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/LoweredRTLIRBuilder.pm) now owns bounded direct-root lowered-IR construction from generated-module analysis plus direct backend analysis state,
  - that package now also owns direct-root output-drive-family analysis, standalone-DT lowered-target assembly, and onehot-style multi-drive assertion metadata,
  - and [t/192-forward-lowered-rtl-ir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/192-forward-lowered-rtl-ir-builder-direct-root.t) now locks the extracted direct-root owner directly against the pipeline result surface.
- Important continuity note:
  - `HDLGenerator` no longer owns those direct-root lowered helper families inline,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now describes `LoweredRTLIRBuilder` as a direct-root plus composition-top lowered builder,
  - and the next likely seam is now the remaining direct-path structural builder residue or a broader `HDLGenerator` facade split.

## 2026-03-26: direct-root IntentHIR construction now lives in the IR builder package
- Saved shipped behavior:
  - [perl/FSM/IR/IntentHIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIRBuilder.pm) now owns bounded direct-root semantic-HIR construction from a semantic FSM/DT module,
  - that package now also owns direct-root signal-analysis grouping, direction inference, and standalone-DT enable-family assembly,
  - and [t/191-forward-intent-hir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/191-forward-intent-hir-builder-direct-root.t) now locks the extracted direct-root owner directly against the pipeline result surface.
- Important continuity note:
  - `HDLGenerator` no longer owns those direct-root semantic helper families inline,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now describes `IntentHIRBuilder` as a direct-root plus composition-top semantic builder,
  - and the next likely seam is now the remaining direct-path lowered/structural builder residue or a broader `HDLGenerator` facade split.

## 2026-03-26: direct-root generation orchestration now lives in a dedicated pipeline package
- Saved shipped behavior:
  - [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm) now owns bounded non-composition source-to-result orchestration,
  - that package now coordinates semantic module creation, forward-IR extraction, direct HDL generation, module-info enrichment, structural IR export, and statistics collection,
  - and [t/190-pipeline-direct-generation-orchestrator.t](/Users/richarddje/Documents/github/fsmgen/t/190-pipeline-direct-generation-orchestrator.t) now locks the new owner directly against the pipeline result surface.
- Important continuity note:
  - this removes the last obvious direct-root result-assembly cluster from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `DirectGenerationOrchestrator` in the pipeline/orchestration layer,
  - and the next likely seam is now direct-path builder/backend residue or a broader `HDLGenerator` facade split rather than one more result-assembly extraction.

## 2026-03-26: composition generation orchestration now lives in a dedicated composition package
- Saved shipped behavior:
  - [perl/FSM/Composition/GenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GenerationOrchestrator.pm) now owns bounded composition source-to-result orchestration,
  - that package now coordinates plan construction, child-export projection, composition-top forward-IR assembly, structural top emission, and result-metadata/statistics assembly,
  - and [t/189-composition-generation-orchestrator.t](/Users/richarddje/Documents/github/fsmgen/t/189-composition-generation-orchestrator.t) now locks the new owner directly against the pipeline result surface.
- Important continuity note:
  - this removes the last obvious composition-top result-assembly cluster from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `GenerationOrchestrator` in the composition layer,
  - and the next likely seam is now the broader non-composition/direct-root coordinator path rather than one more composition-top helper extraction.

## 2026-03-26: composition-top LoweredRTLIR construction now lives in a dedicated IR builder package
- Saved shipped behavior:
  - [perl/FSM/IR/LoweredRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/LoweredRTLIRBuilder.pm) now owns bounded composition-top `LoweredRTLIR` construction,
  - that package now builds the lowered top surface from an already-built composition plan plus structural, semantic, and shared-datapath inputs,
  - and [t/188-composition-lowered-rtl-ir-builder.t](/Users/richarddje/Documents/github/fsmgen/t/188-composition-lowered-rtl-ir-builder.t) now locks the new owner directly against the pipeline result surface.
- Important continuity note:
  - this removes another real forward-IR assembly seam from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `LoweredRTLIRBuilder` in the forward-IR layer,
  - and the next likely seam is now a broader direct-root/orchestrator split or another remaining coordinator pocket rather than one more inline composition-top IR builder.

## 2026-03-25: composition-top IntentHIR construction now lives in a dedicated IR builder package
- Saved shipped behavior:
  - [perl/FSM/IR/IntentHIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIRBuilder.pm) now owns bounded composition-top `IntentHIR` construction,
  - that package now builds the semantic top surface from an already-built composition plan plus structural and child-export inputs,
  - and [t/187-composition-intent-hir-builder.t](/Users/richarddje/Documents/github/fsmgen/t/187-composition-intent-hir-builder.t) now locks the new owner directly against the pipeline result surface.
- Important continuity note:
  - this removes another real forward-IR assembly seam from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `IntentHIRBuilder` in the forward-IR layer,
  - and the next likely seam is the matching lowered-IR builder split or a broader direct-root/orchestrator split.

## 2026-03-25: composition plan orchestration now lives in a dedicated builder package
- Saved shipped behavior:
  - [perl/FSM/Composition/PlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/PlanBuilder.pm) now owns the bounded composition-plan orchestration family,
  - that package now handles child realization dispatch, `?ports` shape gating, top-port inference handoff, lane selection, and shared-datapath plan augmentation,
  - and [t/186-composition-plan-builder.t](/Users/richarddje/Documents/github/fsmgen/t/186-composition-plan-builder.t) now locks the new owner directly across bounded `C1`, `C3`, and `C4` rebuilds.
- Important continuity note:
  - this removes one of the last obvious composition-shape coordination clusters from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `PlanBuilder` in the composition-builder layer,
  - and the next likely seam is another remaining result/orchestration pocket or a direct-root/orchestrator split.

## 2026-03-25: rtl child realization now lives in a dedicated composition package
- Saved shipped behavior:
  - [perl/FSM/Composition/RTLChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLChildRealizer.pm) now owns the bounded `?rtl` child realization family,
  - that package now turns already-loaded embedded or sidecar `.rtlif` metadata into normalized realized-child carriers,
  - and [t/185-composition-rtl-child-realizer.t](/Users/richarddje/Documents/github/fsmgen/t/185-composition-rtl-child-realizer.t) now locks the new owner directly across both embedded-root and sidecar metadata paths.
- Important continuity note:
  - this removes another real child/source-orchestration pocket from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) still owns `.rtlif` metadata loading and validation while `RTLChildRealizer` owns projection into `FSM::Composition::RealizedInstance`,
  - and the next likely seam is another remaining composition-shape coordination cluster or result/orchestration pocket.

## 2026-03-25: generated-child realization now lives in a dedicated composition package
- Saved shipped behavior:
  - [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) now owns the `?fsmc` / `?dtc` realization family,
  - that package now covers embedded/external generated-child source loading, wrong-kind source validation, child compilation, shared-datapath export augmentation for realized `?fsmc` children, and normalized realized-child construction,
  - and [t/184-composition-generated-child-realizer.t](/Users/richarddje/Documents/github/fsmgen/t/184-composition-generated-child-realizer.t) now locks the new owner directly while the older child-source/default-source/shared-datapath tests keep the surrounding contract honest.
- Important continuity note:
  - this removes another real child/source-orchestration pocket from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes this package in the composition-builder layer,
  - and the next likely seam is another remaining child/source owner such as the `?rtl` realization pocket or the next composition-shape coordination cluster.

## 2026-03-25: shared-datapath candidate assembly now lives in a dedicated builder package
- Saved shipped behavior:
  - [perl/FSM/Composition/SharedDatapathCandidateBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/SharedDatapathCandidateBuilder.pm) now owns the shared-datapath candidate family,
  - that package now builds candidate discovery plus normalized contributor, peer-read, drive-intent, and aggregate-enable metadata from structural bindings and lowered child drive families,
  - and [t/183-composition-shared-datapath-candidate-builder.t](/Users/richarddje/Documents/github/fsmgen/t/183-composition-shared-datapath-candidate-builder.t) now locks the new owner directly while [t/168-structural-binding-leaf-consumers.t](/Users/richarddje/Documents/github/fsmgen/t/168-structural-binding-leaf-consumers.t) points its direct leaf-binding contract at that builder.
- Important continuity note:
  - this removes another real composition metadata family from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes this package in the composition-builder layer,
  - and the next likely seam is another monolith-breakdown slice such as generated-child realization/source-loading.

## 2026-03-25: composition result metadata now lives in a dedicated builder package
- Saved shipped behavior:
  - [perl/FSM/Composition/ResultMetadataBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ResultMetadataBuilder.pm) now owns the success-path composition result-metadata family,
  - that package now builds `module_info` and `statistics` once composition planning, provenance, child exports, and forward IR layers already exist,
  - and [t/182-composition-result-metadata-builder.t](/Users/richarddje/Documents/github/fsmgen/t/182-composition-result-metadata-builder.t) now locks the new owner directly.
- Important continuity note:
  - this removes another real result-assembly family from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes this package in the composition-builder layer,
  - and the next likely seam is another monolith-breakdown slice such as shared-datapath candidate assembly or the generated-child realization/source-loading family.

## 2026-03-25: composition failure summaries now live in a dedicated builder package
- Saved shipped behavior:
  - [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm) now owns the bounded failed-run composition summary family,
  - that package now builds blocked-boundary, construct, artifact, context, and concise-reason summary data from raised composition diagnostics,
  - and [t/181-composition-failure-report-builder.t](/Users/richarddje/Documents/github/fsmgen/t/181-composition-failure-report-builder.t) now locks the new owner directly.
- Important continuity note:
  - this removes another real reporting/result-assembly family from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes this package in the composition-builder layer,
  - and the next likely seam is another monolith-breakdown slice such as another remaining result-assembly or reporting pocket.

## 2026-03-25: composition child exports now live in a dedicated builder package
- Saved shipped behavior:
  - [perl/FSM/Composition/ChildExportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ChildExportBuilder.pm) now owns the composition child-export family,
  - that package now builds the unified realized-child export surface plus the narrower generated-child and standalone-DT child export views,
  - and [t/180-composition-child-export-builder.t](/Users/richarddje/Documents/github/fsmgen/t/180-composition-child-export-builder.t) now locks the new owner directly.
- Important continuity note:
  - this removes another real result-assembly family from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now also includes this package in the composition-builder layer,
  - and the next likely seam is another monolith-breakdown slice such as the failure-summary family or another remaining result-assembly pocket.

## 2026-03-25: the `bin/fsmgen` import-tree analysis now lives in its own dedicated architecture note
- Saved continuity rule:
  - the current deep analysis of [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) and its transitive project-owned import tree now lives in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md),
  - that file is intentionally a live document and should be updated at the start of a later session when the entrypoint/runtime spine or hotspot picture has materially changed,
  - and future sessions should treat it as the current architecture map for the CLI entrypoint rather than trying to reconstruct the tree from scattered conversation history.
- Important continuity note:
  - this is especially relevant while `R11` keeps changing package ownership under [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the document is meant to stay honest about which layers are clean, which are transitional, and where the current hotspots still are.

## 2026-03-24: inferred same-name composition link planning now lives in a composition builder package
- Saved shipped behavior:
  - `FSM::Composition::SameNameLinkBuilder` now owns the bounded inferred same-name convention link family used by the active `C2` and `C3` lanes,
  - that package now handles inferred top-input fanout, inferred top-output selection, inferred internal same-name carrier links, and the shared candidate-grouping / explicit-child-endpoint exclusion rules behind those bounded conventions,
  - and the extracted builder now has a direct contract test beside the existing end-to-end same-name convention coverage.
- Important continuity note:
  - this removes another real composition-planning family from `HDLGenerator`,
  - it gives the future linked-plan split a cleaner separation between generic linked-plan assembly and bounded same-name convention inference,
  - and the next likely seam is another bounded lane/inference builder or a broader linked-plan extraction step.

## 2026-03-24: keep the product name, defer the internal namespace rename
- Saved direction:
  - keep `fsmgen` as the product/tool identity for historical reasons,
  - treat the internal `FSM::...` umbrella namespace as a likely late-roadmap cleanup target instead,
  - and do not spend current roadmap energy on that rename while package boundaries are still moving.
- Important continuity note:
  - this is a deferred naming cleanup, not an active implementation task,
  - the rename should be revisited only when the roadmap is much closer to complete and the package split is largely settled.

## 2026-03-24: active forward-ir packages now carry explicit pod contracts
- Saved shipped behavior:
  - active forward-IR packages, builders, and the first structural backend emitter now carry package-level POD near the top of the file,
  - those same packages now also carry routine-level POD for the functions they own,
  - and the saved rule is that new extracted packages in this lane should ship with POD instead of waiting for a later cleanup pass.
- Important continuity note:
  - this is an architecture-clarity move, not just cosmetic editing,
  - it keeps the active three-layer forward-IR plan reviewable while the package split is still in motion,
  - and the monolith split should inherit the same documentation standard as more responsibilities leave `HDLGenerator`.

## 2026-03-24: declared connect-by-name link planning now lives in a composition builder package
- Saved shipped behavior:
  - `FSM::Composition::DeclaredByNameLinkBuilder` now owns the bounded `C4` declared connect-by-name link family,
  - that package now handles system-port exclusion, same-name endpoint matching, input fanout, unique-output selection, and direction/width validation for `=port` top declarations,
  - and the extracted builder now has a direct contract test beside the existing end-to-end connect-by-name coverage.
- Important continuity note:
  - this removes another real composition-planning family from `HDLGenerator`,
  - it gives the future linked-plan split a cleaner separation between lane-specific declared-by-name logic and generic linked-plan assembly,
  - and the next likely seam is another bounded lane/inference builder or one of the remaining implicit-link helpers.

## 2026-03-24: c1 passthrough plan building now lives in a composition builder package
- Saved shipped behavior:
  - `FSM::Composition::C1PlanBuilder` now owns the bounded single-child passthrough `C1` lane,
  - that package now handles explicit passthrough exposure validation, implicit top-port inference from one realized child interface, and direct passthrough link/binding assembly,
  - and the extracted builder now has a direct contract test beside the existing end-to-end `C1` coverage.
- Important continuity note:
  - this is the first real composition-lane planner split, not just another helper move,
  - it gives the future composition-plan breakdown a concrete lane package to grow from,
  - and the next likely seam is another bounded composition-lane extraction or one of the remaining top-port/link inference helpers.

## 2026-03-24: realized-child interface port planning now lives in a composition builder package
- Saved shipped behavior:
  - `FSM::Composition::InterfacePortBuilder` now owns realized generated-child interface port construction from `module_info`,
  - that same package now also owns the shared interface-type normalization and system-port ordering rules used by composition planning,
  - and the direct interface helper tests now call that package directly instead of asking `HDLGenerator` to build realized-child boundary ports.
- Important continuity note:
  - this removes another real builder/planning pocket from the pipeline monolith,
  - it gives the future composition-plan split a cleaner seam because child-interface projection now has an explicit owner,
  - and the next likely seam is another composition builder extraction or a deeper orchestrator breakdown step.

## 2026-03-24: composition-top StructuralRTLIR building now lives in a builder package
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIRBuilder` now owns composition-top structural IR construction from `FSM::Composition::Plan`,
  - that same package now also owns structural hash/object coercion for later pipeline/reporting consumers,
  - and structural tests now call the builder package directly instead of asking `HDLGenerator` to manufacture the structural object.
- Important continuity note:
  - this is the matching pipeline-side split to the new backend-emitter extraction,
  - it removes one real structural assembly pocket from the coordinator monolith,
  - and the next likely seam is another builder extraction, especially on the direct-root side, or another backend-emitter ownership move.

## 2026-03-24: composition-top structural text emission now lives in a backend emitter
- Saved shipped behavior:
  - `FSM::Backend::VerilogFamily::StructuralRTLIREmitter` now owns composition-top structural HDL text emission for the current Verilog-family lane,
  - `HDLGenerator` now assembles composition results around that backend package instead of owning the direct top-module text-rendering method itself,
  - and the structural emitter tests now call the backend package directly.
- Important continuity note:
  - this is the first concrete backend-emitter split slice, not just another helper extraction,
  - it moves one real text-rendering responsibility out of the pipeline coordinator,
  - and the next likely seam is another backend-emitter ownership move or the matching orchestrator/builder extraction on the pipeline side.

## 2026-03-24: no compatibility excuse should preserve the current HDLGenerator shape
- Saved architecture clarification:
  - FSMGen does not yet have a published public compatibility contract that would justify preserving `HDLGenerator` as a monolith,
  - the target remains a split orchestrator/compiler side that builds `IntentHIR`, `LoweredRTLIR`, and `StructuralRTLIR`,
  - and a separate backend-emitter side that mostly walks `StructuralRTLIR` to emit HDL text.
- Important continuity note:
  - internal shims are acceptable only when they are clearly temporary migration aids,
  - they are not a reason to keep accidental monolithic ownership alive,
  - and future extraction choices should optimize for the strongest architecture rather than for compatibility theater.

## 2026-03-24: composition-top port metadata now lives in StructuralRTLIR
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR` now owns `port_metadata` and `port_metadata_from_input`,
  - composition-top `IntentHIR` now consumes that helper for `signal_names` and grouped port signal-analysis summaries,
  - and composition-top `module_info->{signals}` now consumes that same helper instead of rebuilding a local top-port summary map.
- Important continuity note:
  - this removes another small structural-boundary projection from `HDLGenerator`,
  - it keeps top-level boundary metadata closer to the IR layer that already owns explicit ports and top-port lookups,
  - and the next likely seam is still another structural owner handoff or a real module breakdown step for the combined pipeline/emitter layer.

## 2026-03-24: keep the forward-ir target separate from the current HDLGenerator reality
- Saved architecture clarification:
  - the intended forward spine is still `IntentHIR -> LoweredRTLIR -> StructuralRTLIR -> backend emission`,
  - `StructuralRTLIR` remains the intended last IR before HDL text,
  - and the current direct `IntentHIR` / `LoweredRTLIR` queries in `FSM::Pipeline::HDLGenerator` are transitional coordinator cleanup, not the desired long-term emitter boundary.
- Important continuity note:
  - `HDLGenerator` still currently acts as compiler driver, lowering coordinator, and emitter at the same time,
  - so it is acceptable for that combined module to touch earlier IR owners while we keep extracting responsibilities out of local ad hoc code,
  - but the future breakdown should leave orchestration free to see all three forward IR layers while the pure HDL emitter mostly walks `StructuralRTLIR`.

## 2026-03-23: structural top-port and resolved-link queries now live in StructuralRTLIR
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR` now owns `top_port` and `resolved_links_touching`,
  - composition provenance endpoint resolution now consumes `top_port` instead of rebuilding a local top-port lookup table,
  - and explicit-toplink override reporting now consumes `resolved_links_touching` instead of grepping resolved links locally for each top port.
- Important continuity note:
  - this removes another pair of small but real structural-query pockets from `HDLGenerator`,
  - it keeps more top/child connectivity lookup behavior with the structural layer that owns the ports and links,
  - and the next likely seam is still another structural query/helper ownership move or the next bounded structural-AST widening.

## 2026-03-23: structural endpoint-query helpers now live in StructuralRTLIR
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR` now owns `interface_endpoint`, `interface_signal_endpoints`, and `interface_signal_endpoint_groups`,
  - composition provenance endpoint resolution now consumes those structural queries instead of grepping structural instances/ports locally,
  - and override/block reporting plus signal-family context discovery now consume that same structural endpoint-query surface instead of rebuilding nested-loop endpoint groups.
- Important continuity note:
  - this removes another real connectivity-query pocket from `HDLGenerator`,
  - it makes `StructuralRTLIR` a clearer owner of explicit child-interface endpoint lookup instead of leaving that logic spread across reporting consumers,
  - and the next likely seam is still another structural query/helper ownership move or the next bounded structural-AST widening.

## 2026-03-23: structural binding-summary indexing now lives in the structural helper layer
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now owns `binding_signal_summaries_by_port`, the reusable rule for turning one binding list into a normalized per-port summary index,
  - composition system-signal inference now consumes that helper instead of rebuilding a local per-port summary map,
  - and shared-datapath candidate assembly now consumes that same helper instead of rebuilding the same map again in a second pipeline seam.
- Important continuity note:
  - this removes another small but real binding-list indexing pocket from `HDLGenerator`,
  - it keeps binding-list to summary-index semantics together with the structural helper layer that already owns summary construction and export rules,
  - and the next likely seam is still either another real consumer handoff or one more bounded `connection_expr` widening.

## 2026-03-23: structural summary metadata export now lives in the structural helper layer
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now owns `binding_signal_summary_metadata`, the reusable rule for normalized cloned summary-export payloads,
  - shared-datapath contributor metadata now consumes that helper instead of hand-copying `bound_signal` / `bound_signals` / `bound_connection_expr`,
  - and shared peer-read endpoint metadata now consumes that same helper instead of keeping a second local copy of the same projection.
- Important continuity note:
  - this removes another small but real summary-payload ownership pocket from `HDLGenerator`,
  - it keeps exported summary payload semantics together with the structural helper layer that already owns summary construction, leaf selection, and rendering,
  - and the next likely seam is still either another real consumer handoff or one more bounded `connection_expr` widening.

## 2026-03-23: structural summary text rendering now lives in the structural helper layer
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now owns `binding_signal_summary_text`, the reusable rule for rendering summary entries from typed binding expressions first and then falling back to flat/dependency mirrors,
  - `bin/fsmgen` now consumes that helper for shared-datapath summary rendering instead of keeping its own local summary-rendering copy,
  - and the helper now also normalizes the current short CLI target-language aliases such as `sv` and `v`.
- Important continuity note:
  - this removes another small but real structural-summary rule from the CLI edge,
  - it keeps summary-entry rendering semantics together with the structural summary helpers that already own the underlying data contract,
  - and the next likely seam is still either another real consumer handoff or one more bounded `connection_expr` widening.

## 2026-03-23: structural summary leaf-carrier lookup now lives in the structural helper layer
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now owns `binding_signal_summary_leaf_signal`, the reusable rule for “typed summary entry to true flat leaf carrier,”
  - shared-datapath planning now consumes that structural helper instead of keeping the same leaf-carrier rule as a pipeline-local method,
  - and the shared-datapath leaf-binding tests now point at the structural owner directly.
- Important continuity note:
  - this removes another small but real binding-semantics pocket from `HDLGenerator`,
  - it keeps typed-summary leaf-carrier rules together with the structural summary helpers that produce those entries,
  - and the next likely seam is still either another real consumer handoff or one more bounded `connection_expr` widening.

## 2026-03-23: structural binding signal summaries now live in the structural helper layer
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now owns one `binding_signal_summary` helper over flat leaf carrier name, broader dependency names, and cloned typed binding expression payload,
  - composition system-signal inference now consumes that structural summary instead of rebuilding the same projection locally,
  - and shared-datapath candidate metadata now consumes that same structural summary instead of carrying another pipeline-local copy of the rule.
- Important continuity note:
  - this is another ownership move toward the structural layer rather than a new syntax feature,
  - it gives later structural consumers one stable signal-summary contract instead of repeating `bound_signal` / `bound_signals` / cloned-expression assembly in `HDLGenerator`,
  - and the next likely seam is still either another real consumer handoff or one more bounded `connection_expr` widening.

## 2026-03-23: shared-datapath cli summaries now render typed contributor bindings too
- Saved shipped behavior:
  - non-quiet `bin/fsmgen` shared-datapath candidate summary lines now also render contributor binding text from `bound_connection_expr`,
  - flat `signal_ref` contributor bindings now print as lines like `left.status_bus <= left_status`,
  - and the CLI keeps the richer contributor line aligned with the same structural AST surface already used for peer-read summaries.
- Important continuity note:
  - this makes the top candidate line itself a real structural-expression consumer instead of leaving typed bindings only in detail lines,
  - it keeps contributor summaries from collapsing back to endpoint-only reporting at the first line of the shared-datapath section,
  - and the next likely seam is still either another real consumer handoff or one more bounded `connection_expr` widening.

## 2026-03-23: shared-datapath cli summaries now render typed peer-read bindings
- Saved shipped behavior:
  - non-quiet `bin/fsmgen` shared-datapath summaries now render peer-read binding text from `bound_connection_expr`,
  - flat `signal_ref` peer-read bindings now print as lines like `consumer.status_bus <= left_status`,
  - and the CLI falls back to older summary fields only when no typed binding expression is available.
- Important continuity note:
  - this is a real downstream consumer of the structural AST rather than passive metadata carriage,
  - it keeps the CLI from collapsing back to endpoint-only summaries at the reporting boundary,
  - and the next likely seam is still either another real consumer handoff or one more bounded `connection_expr` widening.

## 2026-03-23: structural bit-vector literals now render honestly for vhdl too
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now renders bounded `bit_vector_literal` nodes through the current VHDL helper path too,
  - multi-bit literals now render as VHDL bit-string style `"1010"` forms,
  - and single-bit literals now render as VHDL character literals like `'1'`.
- Important continuity note:
  - this closes another obvious “portable on paper but not in rendering” gap in the structural AST,
  - it keeps constant actual connections backend-neutral without forcing a separate VHDL-only literal family,
  - and the next likely seam is still either one more bounded `connection_expr` widening or another consumer moving further off compatibility mirrors.

## 2026-03-23: shared-datapath planning now prefers typed binding expressions
- Saved shipped behavior:
  - shared-datapath planning now derives flat carrier names from `bound_connection_expr` first,
  - the older `bound_signal` field is now only a compatibility fallback for that specific leaf-carrier decision,
  - and stale mirrors no longer win over the typed structural binding AST when the two disagree.
- Important continuity note:
  - this is a real consumer handoff onto the structural layer rather than just more metadata,
  - it makes carrier/top-output/peer-input planning depend less on compatibility mirrors,
  - and the next likely seam is still either another consumer moving onto typed binding expressions or one more bounded `connection_expr` widening.

## 2026-03-23: shared-datapath metadata now preserves typed binding expressions
- Saved shipped behavior:
  - shared-datapath contributor metadata now preserves `bound_connection_expr` beside `bound_signal` and `bound_signals`,
  - peer-read endpoint metadata now preserves that same typed binding expression too,
  - and richer bindings such as `member_access` now stay visible as actual structural AST nodes instead of collapsing to names-only summaries.
- Important continuity note:
  - this is a real structural handoff, not just more reporting,
  - it gives later planning/reporting consumers the actual bound expression without having to reconstruct it from the plan again,
  - and the next likely seam is still either another consumer moving onto those typed binding expressions or one more bounded `connection_expr` widening.

## 2026-03-23: structural slice and concat expressions now render honestly for vhdl too
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now renders bounded `bit_select`, `slice`, and `concat` nodes through the current VHDL helper path,
  - descending and ascending slice bounds now preserve `downto` versus `to` direction honestly,
  - and nested concatenations now render as VHDL `&` chains instead of failing as unsupported.
- Important continuity note:
  - this strengthens the existing structural AST without inventing another node family,
  - it makes the current bounded connectivity shapes more honestly cross-backend,
  - and the next likely seam is still either one more bounded `connection_expr` widening or another consumer moving further off compatibility mirrors.

## 2026-03-23: structural leaf-signal consumers now distinguish flat carriers from richer dependencies
- Saved shipped behavior:
  - composition system-signal inference now requires a true flat leaf binding before it accepts a clock/reset carrier name,
  - shared-datapath contributor and peer-input metadata now keep `bound_signal` reserved for that true flat leaf case,
  - and `bound_signals` continues to carry the broader dependency list for richer expressions such as `member_access` and `index_access`.
- Important continuity note:
  - this keeps the new structural expression forms honest in real downstream consumers,
  - it prevents “depends on one base signal” from being silently misread as “is bound directly to one flat carrier,”
  - and the next likely seam is still either another structural consumer moving onto the typed distinction or one more bounded `connection_expr` widening.

## 2026-03-23: structural connection expressions now cover bounded fixed-size index access
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now also owns a bounded `index_access` actual-connection node,
  - helper rendering supports that node for SystemVerilog, Verilog, and VHDL, with VHDL using parenthesized index syntax,
  - recursive dependency discovery now follows the base source signal through that node,
  - and the composition structural emitter now walks the typed index-access node directly.
- Important continuity note:
  - this starts the roadmap’s fixed-size array/index-access lane in the structural AST without collapsing into raw HDL strings,
  - it keeps indexed connectivity as real typed structure rather than a flat compatibility mirror,
  - and the next likely seam is still either one bounded `connection_expr` widening or another consumer moving further off compatibility mirrors.

## 2026-03-23: structural connection expressions now cover bounded member access
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now also owns a bounded `member_access` actual-connection node,
  - helper rendering supports that node for SystemVerilog and VHDL while failing explicitly for plain Verilog,
  - recursive dependency discovery now follows the base source signal through that node,
  - and the composition structural emitter now walks the typed member-access node directly.
- Important continuity note:
  - this starts the roadmap’s member/field-access lane in the structural AST without collapsing into raw HDL strings,
  - it keeps aggregate/member connectivity as real typed structure rather than a flat compatibility mirror,
  - and the next likely seam is still either one bounded `connection_expr` widening or another consumer moving further off compatibility mirrors.

## 2026-03-23: structural connection expressions now cover explicit open actuals
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now also owns an explicit backend-neutral `open` actual-connection node,
  - helper rendering already maps that node to Verilog-family empty actuals and to the VHDL `open` keyword,
  - and the composition structural emitter now walks that typed node directly.
- Important continuity note:
  - this keeps “intentionally unconnected formal” as real structural semantics instead of a backend-specific text trick,
  - it makes the structural binding AST more honest for richer top/child connectivity,
  - and the next likely seam is still either one bounded `connection_expr` widening or another consumer moving further off compatibility mirrors.

## 2026-03-23: structural binding-list mutation now lives in the structural helper module too
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now also owns the first bounded signal-ref binding-list ensure/set operations,
  - `HDLGenerator` now uses those helpers when deciding whether to reuse, append, or rebind structural instance port bindings,
  - and the current bounded signal-ref binding behavior stays stable.
- Important continuity note:
  - this removes another low-level binding-ownership pocket from `HDLGenerator`,
  - it makes the structural helper module a more complete owner of the first bounded binding family,
  - and the next likely seam is still either one bounded `connection_expr` widening or another higher-level wiring consumer moving further off compatibility mirrors.

## 2026-03-23: structural binding normalization now lives in the structural helper module too
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now also owns normalized binding cloning/backfilling for the current bounded binding contract,
  - `RealizedInstance` now uses that helper instead of carrying its own private binding-normalization logic,
  - `HDLGenerator` now also uses the same helper while serializing structural instance bindings,
  - and the current `signal_ref` structural behavior stays stable.
- Important continuity note:
  - this removes another duplicated binding-semantics pocket from the runtime/pipeline boundary,
  - it makes the structural helper module the clearer owner of the first bounded binding contract,
  - and the next likely seam is still either one bounded `connection_expr` widening or another consumer moving further off compatibility mirrors.

## 2026-03-23: structural signal-ref binding construction now lives in the structural helper module too
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now also owns the first bounded `signal_ref` binding constructor and in-place rebinding helpers,
  - `HDLGenerator` now uses those helpers when building `C1` passthrough bindings, broader composition planned child bindings, and structural rebinding paths,
  - and the existing bounded `signal_ref` structural surface stays stable.
- Important continuity note:
  - this removes another repeated `signal_name` / `connection_expr` pairing rule from the pipeline,
  - it keeps the first bounded actual-connection family together in one helper surface,
  - and the next likely seam is still either one bounded `connection_expr` widening or another consumer moving fully off the compatibility mirror.

## 2026-03-23: structural binding-expression fallback now lives in the structural helper module too
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now also owns the effective binding-expression fallback for bindings that only still carry the compatibility `signal_name` mirror,
  - `HDLGenerator` now uses that structural helper during structural instance-binding serialization instead of rebuilding `signal_ref` nodes locally,
  - and the current bounded `signal_ref` structural surface stays stable.
- Important continuity note:
  - this removes one more small piece of connection semantics from pipeline-only code,
  - it makes structural serialization a cleaner consumer of the structural layer,
  - and the next likely seam is still either one bounded `connection_expr` widening or another consumer moving fully off the compatibility mirror.

## 2026-03-23: structural connection-expression helpers now live in the structural ir layer
- Saved shipped behavior:
  - new `FSM::IR::StructuralRTLIR::ConnectionExpr` now owns the current bounded `signal_ref` constructor plus signal-name recovery and backend-neutral text rendering for structural binding expressions,
  - `HDLGenerator` now consumes those structural helpers instead of keeping local connection-expression helper subs,
  - `RealizedInstance` now uses that same structural helper module while normalizing plan-side child bindings,
  - and the existing bounded `signal_ref` structural behavior stays stable.
- Important continuity note:
  - this moves the first actual-connection helper semantics onto the structural layer that owns them,
  - it gives later `connection_expr` widening one cleaner place to extend,
  - and the next likely seam is either another structural consumer moving fully onto `connection_expr` or one bounded portable widening beyond plain `signal_ref`.

## 2026-03-23: composition bookkeeping now mirrors the explicit ir layers more directly
- Saved shipped behavior:
  - composition-top `module_info` now derives internal-net names/counts, instance names/counts, auxiliary-assignment count, and composition lane from `lowered_rtl_ir` / `intent_hir`,
  - composition `statistics` now also derives composition lane and shared-datapath candidate count from `intent_hir` / `lowered_rtl_ir`,
  - and the compatible bookkeeping surface stays stable.
- Important continuity note:
  - this keeps the top-level result mirrors aligned with the extracted forward IRs,
  - it removes another small class of raw bookkeeping fallback from `HDLGenerator`,
  - and the next likely seam is another bounded helper that still rebuilds composition state instead of consuming `IntentHIR`, `LoweredRTLIR`, or `StructuralRTLIR` first.

## 2026-03-23: structural rtl ir now carries declared toplinks too
- Saved shipped behavior:
  - composition-top `structural_rtl_ir` now preserves declared explicit-toplink connectivity separately through `declared_links`,
  - block-event reasoning for explicit child links now consumes that structural declared-link surface instead of rereading declared toplinks directly from plan internals,
  - and the existing resolved-link structural surface stays intact.
- Important continuity note:
  - this makes the structural layer a more honest source of truth for explicit top/child wiring intent,
  - it removes another plan-only connectivity read from `HDLGenerator`,
  - and the next likely seam is another bounded helper that still rebuilds composition state instead of consuming `IntentHIR`, `LoweredRTLIR`, or `StructuralRTLIR` first.

## 2026-03-23: unified composition child exports now derive from the structural child layer
- Saved shipped behavior:
  - `composition_children` now derives child identity and order from `structural_rtl_ir->{instances}` instead of rereading realized child identity directly from plan instances,
  - the narrower `composition_generated_children` and `composition_standalone_dt_children` sibling exports now reuse that same computed child surface in the top-generation path instead of rebuilding it again,
  - and the existing unified child export shape stays stable.
- Important continuity note:
  - this makes the semantic child export line up more honestly with the structural source of truth it already feeds,
  - it removes another duplicated plan walk from `HDLGenerator`,
  - and the next likely seam is another bounded helper that still rebuilds composition state instead of consuming `IntentHIR`, `LoweredRTLIR`, or `StructuralRTLIR` first.

## 2026-03-23: reusable standalone-DT child exports now derive from the unified composition child semantic layer
- Saved shipped behavior:
  - `composition_standalone_dt_children` now derives from the broader semantic `composition_children` export instead of rebuilding `?dtc` child identity separately from plan instances,
  - child standalone-DT names and enable-family summaries now come from each child `intent_hir`,
  - grouped standalone-DT multi-drive targets now come from each child `lowered_rtl_ir`,
  - and the existing reusable standalone-DT export shape stays stable.
- Important continuity note:
  - this keeps the reusable standalone-DT sibling aligned with the already-shipped generated-child narrowing step,
  - it removes one more ad hoc plan-instance walk from `HDLGenerator`,
  - and the next likely seam is another remaining plan-shaped export/report helper that should consume `IntentHIR`, `LoweredRTLIR`, or `StructuralRTLIR` first.

## 2026-03-22: standalone-dt multi-drive targets now emit guard assertions
- Saved shipped behavior:
  - grouped standalone-DT multi-drive targets now carry onehot0 assertion metadata over the DT-specific driver-enable signals,
  - direct SystemVerilog `?dt` roots now emit bounded non-synthesis guard assertions from that metadata,
  - realized `?dtc` children now emit those same grouped-target guard assertions inside generated composition HDL,
  - and Verilog output keeps that assertion emission disabled.
- Important continuity note:
  - this turns the reusable standalone-DT arbitration lane into real emitted behavior instead of metadata only,
  - it keeps the backend boundary honest by not leaking SystemVerilog assertion syntax into Verilog output,
  - and the next likely seam is a fuller reusable-module/interface/export contract rather than more passive standalone-DT metadata.

## 2026-03-22: combinational shared-datapath lifting now covers the public-only fanout sibling
- Saved shipped behavior:
  - bounded combinational shared families can now lift even when they have no peer-read child inputs,
  - generated tops now emit one shared top-facing combinational carrier for that public-only sibling,
  - contributor outputs are rebound to private raw nets,
  - and preserved public top outputs are fanned back out from the lifted carrier.
- Important continuity note:
  - this widens the combinational shared-target ownership lane beyond the earlier peer-read-only slices,
  - it makes the combinational public-output contract more concrete instead of leaving it as roadmap prose,
  - and the next likely seam is broader automatic-lift/default-visibility policy rather than another missing combinational sibling.

## 2026-03-22: registered shared-datapath lifting now covers the public-only fanout sibling
- Saved shipped behavior:
  - bounded registered shared families can now lift even when they have no peer-read child inputs,
  - generated tops now emit one shared top-level register plus next-value logic for that public-only sibling,
  - contributor outputs are rebound to private raw nets,
  - and preserved public top outputs are fanned back out from the lifted register.
- Important continuity note:
  - this widens the registered shared-target ownership lane beyond the earlier peer-read-only slices,
  - it starts making the public re-export/default-visibility contract concrete instead of purely roadmap prose,
  - and the next likely seam is broader automatic-lift policy for registered families or further widening of the combinational sibling lane.

## 2026-03-22: systemverilog composition tops now emit shared-datapath guard assertions
- Saved shipped behavior:
  - SystemVerilog composition tops now emit non-synthesis same-value and whole-target shared-datapath guard assertions in the generated top,
  - those assertions are driven from the already-shipped deterministic conflict wires and onehot0 metadata,
  - and Verilog targets keep that assertion emission disabled.
- Important continuity note:
  - this turns the shared-datapath assertion lane into real emitted HDL instead of planning/reporting only,
  - it keeps the backend boundary honest by not leaking SystemVerilog assertion syntax into Verilog output,
  - and the next likely seam is still broader lifted shared-target ownership/visibility behavior rather than more assertion naming work.

## 2026-03-22: combinational shared-datapath peer-read families now also cover the internal-only top-local sibling
- Saved shipped behavior:
  - bounded combinational peer-read shared families can now lift even when no public top output from that family is preserved,
  - generated tops now emit one shared top-local combinational carrier for that internal-only case,
  - peer-read child inputs are rebound to that carrier, contributor outputs are rebound to private raw nets, and no public top re-export assignments are invented,
  - and the peer-read policy surface now distinguishes `top_output_only` from the new `top_local_only` sibling.
- Important continuity note:
  - this closes the most obvious missing sibling in the combinational shared-carrier lane,
  - it also makes the combinational ownership/runtime surface more honest for internal-only peer-read families,
  - and the next likely seam is broader combinational widening or default-visibility policy beyond the now-shipped public-preserving/internal-only pair.

## 2026-03-22: combinational shared-datapath peer-read families now have a first top-facing runtime slice
- Saved shipped behavior:
  - the bounded combinational peer-read public-preserving case now emits one shared top-facing combinational carrier in the generated top,
  - peer-read child inputs are rebound to that carrier, preserved public outputs are re-exported from it, and contributor outputs move to private raw nets,
  - and candidate peer-read endpoints are now filtered to inputs actually bound to contributor carriers before that runtime is planned.
- Important continuity note:
  - this turns the combinational peer-read lane into real emitted behavior instead of policy metadata only,
  - it also keeps the peer-read metadata surface honest for later ownership work,
  - and the next likely seam is how far the combinational top-facing lane should widen beyond the bounded public-preserving case.

## 2026-03-22: shared-datapath lifting now covers mixed public/internal registered peer-read families
- Saved shipped behavior:
  - the bounded registered public-preserving lift path now also works when one contributor preserves a public top output while sibling contributors in the same shared family are consumed only internally,
  - candidate peer-read endpoints are now filtered to inputs actually bound to contributor carriers before lift planning/runtime,
  - and the lifted runtime still preserves only the actual public top re-exports instead of inventing new public assignments for internal carriers.
- Important continuity note:
  - this closes the mixed-boundary sibling of the first registered shared-datapath runtime lane,
  - it also makes peer-read metadata more honest for later ownership work,
  - and the next likely seam is broader ownership/default-visibility policy beyond the now-shipped public-preserving, mixed-boundary, and internal-only trio.

## 2026-03-22: shared-datapath lifting now covers the internal-only registered peer-read sibling
- Saved shipped behavior:
  - the bounded registered loopback lift path no longer requires planned public re-exports before it activates,
  - generated tops now still emit one lifted shared register plus next-value logic when the shared family is only consumed internally,
  - contributor outputs are rebound to private raw nets and peer-read child inputs are rebound to that lifted register,
  - and non-quiet `bin/fsmgen` runs now distinguish the internal-only lifted runtime from the earlier public re-export runtime.
- Important continuity note:
  - this closes the most obvious sibling gap in the first lifted shared-target behavior,
  - it keeps the bounded registered lifting lane honest as an ownership/runtime feature instead of a public re-export special case only,
  - and the next likely seam is broader ownership policy beyond the now-shipped explicit-reexport/internal-only pair.

## 2026-03-21: shared-datapath candidates now surface planned conflict-bit names
- Saved shipped behavior:
  - each aggregate value family now carries one deterministic `P_Q_multi_src_conflict`-style name,
  - each whole target now carries one deterministic `P_multi_value_conflict`-style name,
  - and non-quiet `bin/fsmgen` runs now print those planned conflict names under each shared-datapath candidate.
- Important continuity note:
  - this is the first shipped explicit conflict-naming slice in the shared-datapath lane,
  - it makes the same-value versus different-value split concrete in runtime metadata,
  - and it still does not generate lifted shared-datapath HDL or assertion logic yet.

## 2026-03-21: shared-datapath candidates now surface aggregate enable families
- Saved shipped behavior:
  - generated-child `output_drive_families` now preserve per-RHS family metadata,
  - shared-datapath candidates now also expose one deterministic whole-target aggregate enable plus per-value aggregate enable families,
  - and those aggregate value families now explicitly list the child-local family enables they aggregate.
- Important continuity note:
  - this is the first shipped slice of the roadmap’s shared aggregate-enable lane,
  - it gives later onehot/conflict/assertion work one stable target/value-family metadata surface,
  - and it still does not lift those families into generated shared-datapath HDL yet.

## 2026-03-21: shared-datapath candidates now carry per-child drive intent
- Saved shipped behavior:
  - generated roots and realized generated children now surface `output_drive_family_count` and `output_drive_families` in `module_info`,
  - shared-datapath candidate contributors now also carry one bounded `drive_intent` summary with mux type, driver blocks, RHS families, and enable-signal families,
  - and non-quiet `bin/fsmgen` runs now print one concise per-child drive-intent line under each shared-datapath candidate.
- Important continuity note:
  - this is the first real shipped slice of the roadmap’s per-child drive-intent aggregation lane,
  - it still does not lift those families into a shared synthesized block yet,
  - and it gives later shared-datapath ownership/export work one honest child-owned metadata surface to build on.

## 2026-03-21: composition tops now surface first shared-datapath candidate metadata
- Saved shipped behavior:
  - composition-top `module_info` now reports shared-datapath candidate families through `composition_shared_datapath_candidate_count` and `composition_shared_datapath_candidates`,
  - those candidates are currently bounded to same-name output families across multiple realized `?fsmc` children that agree on width and interface type,
  - and each candidate now carries contributor instance/module/endpoint identity plus any current top-output bindings.
- Important continuity note:
  - this is the first real shared-datapath `R11` feature slice, not just another roadmap note,
  - it still does not lift or rewrite ownership into a shared datapath block yet,
  - and it gives later shared-datapath extraction work one stable discovery/reporting surface to build on.

## 2026-03-21: composition tops now aggregate reusable standalone-DT child exports
- Saved shipped behavior:
  - composition-top `module_info` now aggregates realized `?dtc` child exports through `composition_standalone_dt_child_count`, `composition_standalone_dt_block_count`, `composition_standalone_dt_multi_drive_target_count`, and `composition_standalone_dt_children`,
  - each exported child summary now carries instance/module/source identity plus the already-shipped standalone-DT enable-family and grouped shared-target metadata,
  - and non-quiet `bin/fsmgen` composition runs now print one concise reusable standalone-DT child summary section from that same top-level export surface.
- Important continuity note:
  - this is real `R11` feature growth in the reusable-module lane,
  - it retires the immediate “composition-facing exposure” gap for the already-shipped standalone-DT metadata slices,
  - and it still leaves broader reusable-module interface/export rules for a later deliberate contract pass.

## 2026-03-21: standalone-DT roots now surface grouped multi-drive target metadata
- Saved shipped behavior:
  - direct standalone-DT generation now reports grouped multi-drive target families through `module_info`,
  - those grouped families now carry target name, contributing standalone-DT block names, RHS families, DT-specific enable names, and grouped LHS enable names,
  - and realized `?dtc` children now preserve that same grouped multi-drive metadata through composition.
- Important continuity note:
  - this is real `R11` feature growth in the reusable-module lane,
  - it gives future assertion/shared-datapath work one honest grouped summary for same-target standalone-DT behavior,
  - and it still leaves child interface/export widening for a later deliberate contract slice.

## 2026-03-21: standalone-DT roots now surface stable block-enable family metadata
- Saved shipped behavior:
  - direct standalone-DT generation now reports plain-scalar block names and stable per-block enable-signal families through `module_info`,
  - realized `?dtc` children now preserve that same standalone-DT enable metadata through composition,
  - and `module_info` now also groups those block enable signals into one module-level family summary.
- Important continuity note:
  - this is real `R11` feature growth in the reusable-module lane,
  - it gives future composition/shared-datapath work one honest metadata surface for standalone-DT block enables,
  - and it keeps child interfaces unchanged for now instead of widening them before the reusable-module export contract is settled.

## 2026-03-20: named generated children now default their source name locally in composition
- Saved shipped behavior:
  - named `?fsmc:name` and `?dtc:name` children may now omit the explicit child-source token and default it to `name`,
  - the defaulted source then goes through the same embedded/sibling/`--path`/`FSMLIB` lookup order as before,
  - and unnamed generated children still keep the explicit missing-source failure path.
- Important continuity note:
  - this is real `R11` feature growth in the reusable-root/reference lane,
  - it retires the old named zero-source parser-failure contract,
  - and it gives composition one bounded shorthand for reusable child references without reopening legacy implicit hierarchy.

## 2026-03-20: standalone-DT roots now also accept the conventional explicit `+system` contract
- Saved shipped behavior:
  - standalone-DT roots may now use the same conventional explicit `(+system (clock clk) (sreset rstn))` / `(+system (clock clk) (asreset rstn))` section already accepted by `?fsm:name`,
  - direct standalone-DT generation now preserves that explicit `clk` / `rstn` contract,
  - and composition-facing `?dtc` children now expose and auto-wire those explicit system ports too.
- Important continuity note:
  - this is real `R11` feature growth in the reusable-module lane,
  - it does not replace the existing implicit `clk` / `rst_n` fallback for sequential standalone-DT roots,
  - and it gives reusable standalone-DT modules one deliberate interface-stability knob without reopening broad implicit hierarchy.

## 2026-03-20: standalone-DT roots now also accept `?mod:name` and `?module:name`
- Saved shipped behavior:
  - `?mod:name` and `?module:name` became accepted on the same live direct single-module path as `?dt:name`,
  - and composition `?dtc` children may now realize embedded or external standalone-DT sources rooted at any of those three spellings.
- Important continuity note:
  - later continuity corrected the semantic interpretation: this shared path should not be read as proving that `?mod:` / `?module:` mean the same thing as `?dt:`,
  - this is real `R11` feature growth, not just hardening,
  - it keeps the semantic root family unified under the existing `dt` runtime path,
  - and it retires the old roadmap question about whether those aliases should exist at all.

## 2026-03-20: composition override/block summaries now keep one example subject per kind
- Saved shipped behavior:
  - `composition_report` now keeps one concise example subject for each shipped override kind and block kind,
  - and non-quiet `bin/fsmgen` runs now print those examples inline with the existing `Convention Overrides` and `Convention Blocks` summaries.
- Important continuity note:
  - this slice does not widen planning or convention behavior,
  - it only promotes already-known override/block event structure into more actionable reporting,
  - and it closes the old counts-only reporting gap that was still left on the `R11` board.

## 2026-03-20: active CLI help now names `bin/fsmgen` honestly
- Saved shipped behavior:
  - the built-in help and missing-argument usage now name `./bin/fsmgen` instead of the old `generate_fsm_hdl.pl` wrapper,
  - the built-in examples now use the active CLI entrypoint consistently,
  - and the help text now describes the default output location as the current working directory, which matches the shipped runtime.
- Important continuity note:
  - this slice does not change parsing, planning, or HDL emission behavior,
  - it retires a small user-facing `R11` hotspot the roadmap had already called out explicitly,
  - and [t/132-cli-help-wording.t](/Users/richarddje/Documents/github/fsmgen/t/132-cli-help-wording.t) now locks both the `--help` surface and the missing-argument usage branch.

## 2026-03-20: top-level composition lane and `?ports` shape gates now summarize cleanly
- Saved shipped behavior:
  - failed composition summaries now keep clean top-level gate handling: no-child tops stay construct-free with the blocked `lane entry` summary, and blocked multiple-`?ports`, omitted-`?ports`, and empty-`?ports` tops now keep `Construct: ?ports` plus the shorter `shape` reason.
- Important continuity note:
  - this slice did widen extractor behavior slightly and narrowed concise-reason text slightly,
  - but only at the failed-run summary layer,
  - and it fixes a real misclassification where top-level `?ports` shape gates could previously show up as `?toplink` because the raw diagnostic mentioned the explicit-link `C2/C3` inference exception.

## 2026-03-20: named generated-child parser summaries are now symmetric across count and shape failures
- Saved shipped behavior:
  - named generated-child parser summaries now have explicit regression coverage across both parser boundaries, so named `?fsmc` and named `?dtc` failures both keep child context through count and shape branches.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens the already-shipped named-child summary path,
  - and it closes the remaining symmetry gap in the named generated-child parser family.

## 2026-03-20: blocked nested `?ports` and `?toplink` items now keep child context in CLI summaries
- Saved shipped behavior:
  - failed composition summaries now keep `Child '?ports'` for blocked nested `?ports` items and `Child '?toplink'` for blocked nested `?toplink` items.
- Important continuity note:
  - this slice did widen extractor behavior slightly,
  - but only at the failed-run summary layer,
  - and it closes the remaining context-thin pocket in the parser flatness family without changing parser behavior.

## 2026-03-20: blocked empty child entries and non-string child headers now keep child-entry context in CLI summaries
- Saved shipped behavior:
  - failed composition summaries now keep `Child entry 'missing header'` for blocked empty child entries and `Child entry 'non-string header'` for blocked non-string child headers.
- Important continuity note:
  - this slice did widen extractor behavior slightly,
  - but only at the failed-run summary layer,
  - and it closes the remaining context-free pocket in the top-level child-structure parser family without inventing a fake construct line.

## 2026-03-19: unnamed generated-child parser summaries are now symmetric across count and shape failures
- Saved shipped behavior:
  - unnamed generated-child parser summaries now have explicit regression coverage across both parser boundaries, so unnamed `?fsmc` and unnamed `?dtc` failures both keep child context through count and shape branches.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens the already-shipped unnamed-child summary path,
  - and it closes the remaining symmetry gap in the unnamed generated-child parser family.

## 2026-03-19: blocked unnamed generated-child parser failures now keep child context in CLI summaries
- Saved shipped behavior:
  - failed composition summaries now recognize blocked unnamed `?fsmc` / `?dtc` parser diagnostics as child context, so these runs can keep `Child '?fsmc'` / `Child '?dtc'` instead of losing child identity in the short summary.
- Important continuity note:
  - this slice did widen extractor behavior slightly,
  - but only at the failed-run summary layer,
  - and it keeps unnamed generated-child parser failures aligned with the already improved named-child generated-source summary family.

## 2026-03-19: blocked explicit-link duplicate-driver failures now keep target context in CLI summaries
- Saved shipped behavior:
  - failed composition summaries now recognize duplicate-driver blocked diagnostics as target context, so the conflicted target `result_data` stays visible in the summary.
- Important continuity note:
  - this slice did widen extractor behavior slightly,
  - but only at the failed-run summary layer,
  - and it keeps duplicate-driver conflicts aligned with the already improved direction-mismatch family instead of leaving their target only in the raw exception text.

## 2026-03-19: blocked explicit-link top-port role mismatches are now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for blocked explicit-link top-port role mismatches, including `Top port 'result_data'` context and the concise top-port role reason.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped explicit-link summary family at the CLI boundary,
  - and it keeps top-port role mismatches aligned with the previously locked child-endpoint direction mismatch, missing-child-endpoint, missing-top-endpoint, existing-instance missing-port, and unsupported explicit-endpoint families.

## 2026-03-19: blocked explicit-link direction mismatches now keep child-endpoint context in CLI summaries
- Saved shipped behavior:
  - failed composition summaries now recognize blocked `uses child endpoint '...'` diagnostics as `Child endpoint` context, so explicit-link direction mismatches keep `uart_tx.txd` visible in the summary.
- Important continuity note:
  - this slice did widen extractor behavior slightly,
  - but only at the failed-run summary layer,
  - and it keeps direction-mismatch failures aligned with the already locked missing-child-endpoint, missing-top-endpoint, existing-instance missing-port, and unsupported explicit-endpoint families.

## 2026-03-19: blocked existing-instance missing-port explicit-link summaries are now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for blocked explicit-link endpoint-resolution failures where the child instance exists but the named child port does not, including `Child endpoint 'uart_tx.missing_port'` context and the concise missing-port reason.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped explicit-link summary family at the CLI boundary,
  - and it keeps existing-instance missing-port failures aligned with the previously locked missing child-endpoint, missing top-endpoint, and unsupported explicit-endpoint summary families.

## 2026-03-19: blocked missing top-level explicit-link endpoint summaries are now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for blocked missing top-level explicit-link endpoint failures, including `Top endpoint` context and the concise `'?ports' declares no top port with that name` reason.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped explicit-link summary family at the CLI boundary,
  - and it keeps missing top-level endpoint failures aligned with the previously locked missing child-endpoint and unsupported explicit-endpoint summary families.

## 2026-03-19: blocked unsupported explicit-endpoint syntax is now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for blocked unsupported explicit-endpoint syntax, including the offending endpoint token and concise unsupported-syntax reason.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped explicit-link summary family at the CLI boundary,
  - and it keeps unsupported explicit-endpoint syntax aligned with the previously locked missing-endpoint and declared connect-by-name summary families.

## 2026-03-19: blocked shared-system-port `=port` summaries are now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for blocked shared-system-port declared connect-by-name failures, including the concise dedicated-system-input-contract reason and top-port context.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped `=port` summary family at the CLI boundary,
  - and it keeps the shared-system-port path aligned with the previously locked ambiguity, width-mismatch, incompatible-direction, missing-endpoint, and `C1` / `C2` / `C3` summary families.

## 2026-03-19: blocked incompatible-direction `C4` declared connect-by-name summaries now keep endpoint sets at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for a reachable blocked incompatible-direction `C4` declared connect-by-name failure, including the conflicting same-name endpoint set in the concise `Reason:` line.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped `C4` summary family at the CLI boundary,
  - and it keeps incompatible-direction, width-mismatch, ambiguity, missing-endpoint, and the previously locked `C1` / `C2` / `C3` summary families aligned under the same reporting contract.

## 2026-03-19: blocked width-mismatch `C4` declared connect-by-name summaries now keep endpoint sets at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for a reachable blocked width-mismatch `C4` declared connect-by-name failure, including the conflicting same-name endpoint set in the concise `Reason:` line.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped `C4` summary family at the CLI boundary,
  - and it keeps width-mismatch, ambiguity, missing-endpoint, and the previously locked `C1` / `C2` / `C3` summary families aligned under the same reporting contract.

## 2026-03-19: blocked ambiguous `C4` declared connect-by-name summaries now keep candidate lists at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for a reachable blocked ambiguous `C4` declared connect-by-name failure, including the compatible-child-endpoint list in the concise `Reason:` line.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped `C4` summary family at the CLI boundary,
  - and it keeps ambiguity, missing-endpoint, and the previously locked `C1` / `C2` / `C3` summary families aligned under the same reporting contract.

## 2026-03-19: blocked `C4` declared connect-by-name summaries are now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for a reachable blocked `C4` declared connect-by-name failure through the existing `Lane: C4`, `Construct: =port`, and `Top port` context lines.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens an already-shipped `C4` summary family at the CLI boundary,
  - and it keeps the reachable declared connect-by-name path aligned with the previously locked `C1`, `C2`, and `C3` failed-run summary coverage.

## 2026-03-19: blocked `C2` lane-selection summaries are now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for blocked `C2` lane-selection failures through the existing `Lane: C2` line and concise blocked-lane reason.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens an already-shipped lane-summary family at the CLI boundary,
  - and it keeps the reachable `C2` path aligned with the previously locked `C1` / `C3` failed-run summary coverage.

## 2026-03-19: blocked `C1` exposure summaries are now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for blocked `C1` top-port mismatch and blocked `C1` omitted-child-port exposure failures through the existing `Top port` / `Child port` context lines.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens already-shipped failure-summary behavior at the CLI boundary,
  - and it keeps the reachable `C1` exposure families aligned across pipeline extraction and user-visible summary output.

## 2026-03-19: future syntax-power guidance is now saved
- Saved future note:
  - the current highest-leverage language-growth candidates are aggregate types with inference, interface bundles, enum-first case/match capture, small alias/default forms, bounded replication, intent helpers, assertions, and stronger explain/report mode.
- Important continuity note:
  - the saved rule is still “bounded semantic power, not a general macro system”,
  - and the follow-up nuance is preserved too: a later list-oriented meta-programming lane can exist only if it stays semantic, elaboration-bounded, and 100% RTL/synthesis-focused.

## 2026-03-19: `.rtlif` width/type failures are now explicitly locked through the token-summary path
- Saved shipped behavior:
  - failed composition summaries now have explicit regression coverage for blocked `.rtlif` port-sizing and port-typing failures through the same `RTL metadata file:` plus `Context: Token '...'` pairing used by the token-shape family.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens the already-shipped token-scoped summary contract,
  - and it keeps the invalid-token / non-positive-width / unsupported-type trio aligned under one tested `Token` summary family.

## 2026-03-19: Rust FSMGen repo strategy is now saved
- Saved future note:
  - the existing `H1` Rust FSMGen horizon now carries an explicit initial repo recommendation,
  - namely: start a future Rust implementation in this same repository beside the Perl reference implementation instead of beginning with a separate repository plus Perl submodule split.
- Important continuity note:
  - the saved rationale is shared contract/corpus/differential-test leverage and avoidance of submodule drift while semantic parity is still being proven,
  - and a later repository split is still allowed if release cadence, packaging, or ownership eventually diverge enough to justify it.
## 2026-03-19: flatness `.rtlif` failures are now explicitly locked through the RTL-root summary path
- Saved shipped behavior:
  - failed composition summaries now have explicit regression coverage for blocked `.rtlif` flatness failures through the same `RTL metadata file:` plus `Context: RTL root '?rtlif:...'` pairing used by the other file-based root-scoped families.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens the already-shipped root-scoped summary contract,
  - and it keeps the missing-root / empty-port / flatness trio aligned under one tested `RTL root` summary family.

## 2026-03-19: file-based `.rtlif` root failures now keep RTL root context in failed-run summaries
- Saved shipped behavior:
  - failed composition summaries can now keep `Context: RTL root '?rtlif:...'` for file-based root-scoped `.rtlif` failures such as missing-root and empty-port cases,
  - while still preserving the resolved `.rtlif` path as the separate `RTL metadata file:` artifact line.
- Important continuity note:
  - this is a narrow reporting refinement only,
  - it relies on the existing blocked diagnostic already naming the active `?rtlif:<module>` token,
  - and it keeps the failed-run summary model consistent across embedded and file-based `.rtlif` root families.

## 2026-03-19: embedded `.rtlif` duplicate-root failures now keep RTL root context in failed-run summaries
- Saved shipped behavior:
  - failed composition summaries can now keep `Context: RTL root '?rtlif:...'` for blocked embedded `.rtlif` duplicate-root failures,
  - and those same summaries still avoid inventing an `RTL metadata file:` artifact line because the metadata lives in the composition source itself.
- Important continuity note:
  - this is a narrow reporting refinement only,
  - it relies on the existing blocked diagnostic already naming the repeated embedded root token,
  - and it keeps the current failed-run summary lane moving by surfacing stable context instead of inventing parallel reporting logic.

## 2026-03-19: duplicate-port `.rtlif` failures now keep repeated RTL port context in failed-run summaries
- Saved shipped behavior:
  - failed composition summaries can now keep `Context: RTL port '...'` for blocked duplicate-port `.rtlif` declaration failures,
  - while still preserving the resolved `.rtlif` path as the separate `RTL metadata file:` artifact line.
- Important continuity note:
  - this is a narrow reporting refinement only,
  - it relies on the existing blocked diagnostic already naming the repeated port,
  - and it keeps the current failed-run summary lane moving by surfacing stable context rather than inventing parallel summary logic.

## 2026-03-18: non-quiet failed composition runs now print a first bounded failure summary
- Saved shipped behavior:
  - the pipeline can now derive a small composition failure report from blocked composition diagnostics,
  - and the CLI now prints a bounded composition-failure summary during non-quiet failed composition runs when the raised diagnostic exposes a blocked composition boundary, including a `Lane:` line when that diagnostic already names the active `C1` / `C2` / `C3` / `C4` lane, a `Construct:` line when that same diagnostic points clearly at one active syntax construct such as `?ports`, `?toplink`, `?rtl`, `?fsmc`, `?dtc`, or `=port`, a `Child source file:` line when a blocked generated-child realization failure already names the resolved external `.fsm` file, an `RTL metadata file:` line when a blocked `.rtlif` structure, token, sizing, typing, flatness, or declaration failure already names the resolved metadata file, a concise context line for the offending child/top-port/explicit-endpoint/metadata/token when that context can be separated honestly from longer follow-up detail, plus a concise blocked-reason line.
- Important continuity note:
  - quiet-mode failure behavior stays unchanged,
  - the original exception text still surfaces after the summary,
  - and this is the first deliberate move from pure exception text into richer failed-run composition reporting.

## 2026-03-18: malformed generated-child source payloads now say source shape/count is blocked
- Saved shipped behavior:
  - composition parser diagnostics now say blocked generated-child source-shape failures for nested `?fsmc` / `?dtc` payloads,
  - and blocked generated-child source-count failures when those same payloads declare zero or multiple flat source names instead of exactly one.
- Important continuity note:
  - this closes another older-wording pocket on a real generated-child parser boundary,
  - it keeps the one-source-per-generated-child contract unchanged,
  - and it adds focused direct parser plus pipeline and CLI coverage for both `?fsmc` and `?dtc`.

## 2026-03-18: unsupported composition child kinds now say child-kind support is blocked
- Saved shipped behavior:
  - composition parser diagnostics now say explicitly when composition child-kind support is blocked because a child header falls outside the active `?fsmc` / `?dtc` / `?rtl` / `?ports` / `?toplink` family.
- Important continuity note:
  - this closes another older-wording pocket on a real composition parser family boundary,
  - it keeps the child-kind contract unchanged,
  - and it adds focused direct parser plus pipeline and CLI coverage instead of relying on incidental raw “unsupported child” wording.

## 2026-03-18: malformed composition child entries now say child structure is blocked
- Saved shipped behavior:
  - composition parser diagnostics now say blocked child-structure failures for empty child entries, blocked child-header-shape failures for non-string child headers, and blocked child item-list-shape failures for dotted-pair child payloads.
- Important continuity note:
  - this closes another older-wording pocket on real malformed composition parser input,
  - it keeps the child-kind contract unchanged,
  - and it removes the older undef-header warning path while adding focused pipeline plus CLI coverage.

## 2026-03-18: `?toplink` naming cleanup is now tracked as future syntax work
- Saved future note:
  - `?toplink` is acceptable but not ideal as composition wiring syntax,
  - a future syntax-cleanup pass may later decide whether it stays canonical or gains a clearer preferred alias such as `?wiring`,
  - and compatibility should be preferred over abrupt source breakage if that future lane is taken.

## 2026-03-18: legacy `?ports` mapping directives now say port declaration mode is blocked
- Saved shipped behavior:
  - composition parser diagnostics now say explicitly when composition port declaration mode is blocked because `?ports` contains a legacy mapping directive like `/foo/bar/` instead of explicit top-port declarations.
- Important continuity note:
  - this closes another older-wording pocket on a real composition parser boundary,
  - it keeps the parser contract unchanged,
  - and it adds focused pipeline plus CLI coverage on top of the existing direct parser check.

## 2026-03-18: malformed `?ports` and `?toplink` parser items now say parser token boundaries are blocked
- Saved shipped behavior:
  - composition parser diagnostics now say blocked token-boundary failures for nested `?ports`, invalid `?ports` tokens, non-positive `?ports` widths, nested `?toplink` items, and unsupported `?toplink` tokens.
- Important continuity note:
  - this closes another older-wording pocket on real composition parser boundaries,
  - it keeps the parser token contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental parser exceptions.

## 2026-03-18: duplicate embedded `.rtlif` roots now say embedded-root uniqueness is blocked
- Saved shipped behavior:
  - embedded RTL metadata now says explicitly when RTL interface metadata embedded-root uniqueness is blocked because the same composition source contains multiple embedded `?rtlif:<module>` roots for one external RTL child.
- Important continuity note:
  - this closes another older-wording pocket on a real embedded-RTL metadata-contract boundary,
  - it keeps the embedded-root precedence/uniqueness contract unchanged,
  - and it adds focused pipeline plus CLI coverage on top of the existing direct-loader check.

## 2026-03-18: nested external `.rtlif` metadata now says flatness is blocked
- Saved shipped behavior:
  - reachable external RTL metadata now says explicitly when RTL interface metadata flatness is blocked because a `.rtlif` file contains nested structure under the required `?rtlif:<module>` root.
- Important continuity note:
  - this closes another older-wording pocket on a real external-RTL interface-contract boundary,
  - it keeps the `.rtlif` flat-token contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental nested-metadata failures.

## 2026-03-18: empty external `.rtlif` interfaces now say metadata port presence is blocked
- Saved shipped behavior:
  - reachable external RTL metadata now says explicitly when RTL interface metadata port presence is blocked because a `.rtlif` file declares no ports under the required `?rtlif:<module>` root.
- Important continuity note:
  - this closes another older-wording pocket on a real external-RTL interface-contract boundary,
  - it keeps the `.rtlif` port-presence contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental empty-interface failures.

## 2026-03-18: duplicate external `.rtlif` ports now say declaration uniqueness is blocked
- Saved shipped behavior:
  - reachable external RTL metadata now says explicitly when RTL interface metadata port declaration uniqueness is blocked because a `.rtlif` file repeats the same port name.
- Important continuity note:
  - this closes another older-wording pocket on a real external-RTL declaration-contract boundary,
  - it keeps the `.rtlif` declaration contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental duplicate-port failures.

## 2026-03-18: non-positive external `.rtlif` widths now say metadata port sizing is blocked
- Saved shipped behavior:
  - reachable external RTL metadata now says explicitly when RTL interface metadata port sizing is blocked because a `.rtlif` token declares a non-positive explicit width.
- Important continuity note:
  - this closes another older-wording pocket on a real external-RTL token-contract boundary,
  - it keeps the `.rtlif` width contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental non-positive-width failures.

## 2026-03-18: invalid external `.rtlif` port tokens now say metadata token shape is blocked
- Saved shipped behavior:
  - reachable external RTL metadata now says explicitly when RTL interface metadata token shape is blocked because a `.rtlif` token is syntactically invalid for the current flat port-token contract.
- Important continuity note:
  - this closes another older-wording pocket on a real external-RTL token-contract boundary,
  - it keeps the `.rtlif` contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental invalid-token failures.

## 2026-03-17: unsupported external `.rtlif` port types now say metadata typing is blocked
- Saved shipped behavior:
  - reachable external RTL metadata now says explicitly when RTL interface metadata port typing is blocked because a `.rtlif` token resolves to an unsupported explicit type outside the current `data|clock|reset` contract.
- Important continuity note:
  - this closes another older-wording pocket on a real external-RTL token-contract boundary,
  - it keeps the `.rtlif` contract unchanged,
  - and it adds focused pipeline plus CLI coverage while keeping the older direct loader coverage meaningful.

## 2026-03-17: wrong-root external `.rtlif` metadata now says structure is blocked
- Saved shipped behavior:
  - reachable external RTL metadata now says explicitly when RTL interface metadata structure is blocked because the `.rtlif` file does not contain the required `?rtlif:<module>` root for that `?rtl` child.
- Important continuity note:
  - this closes another older-wording pocket on a real external-RTL interface-source boundary,
  - it keeps the `.rtlif` contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental wrong-root failures.

## 2026-03-17: missing external `.rtlif` metadata now says resolution is blocked
- Saved shipped behavior:
  - missing external RTL metadata now says explicitly when RTL interface metadata resolution is blocked because no declared `.rtlif` metadata can be found for a `?rtl` child.
- Important continuity note:
  - this closes another older-wording pocket on a real mixed-composition integration boundary,
  - it keeps the external-RTL contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental metadata lookup failures.
## 2026-03-17: blocked `C2` lane selection now says so explicitly
- Saved shipped behavior:
  - one-generated-child explicit-link tops now say explicitly when `C2` lane selection is blocked because the active `C2` lane requires at least two generated children.
- Important continuity note:
  - this closes another older-wording pocket on a real explicit-link composition path,
  - it keeps the `C2` planner behavior unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental lane-selection fallout.
## 2026-03-17: generated child-source failures now say resolution or realization is blocked
- Saved shipped behavior:
  - external `?fsmc` / `?dtc` lookup failures now say explicitly when child-source resolution is blocked because no active child source can be found,
  - and wrong-kind resolved child files now say explicitly when child-source realization is blocked because the resolved source is rooted under the wrong active source kind.
  - wrong-kind `?fsmc` failures now point users to `?dtc`,
  - and wrong-kind `?dtc` failures now point users to `?fsmc`.
- Important continuity note:
  - this closes another older-wording pocket on a real reusable-module integration boundary,
  - it fixes an outdated note that still described standalone-DT child realization as future work,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental child-load failures.
## 2026-03-17: unsupported composition backend targets now say target support is blocked
- Saved shipped behavior:
  - valid composition sources now say explicitly when composition target support is blocked because the current composition lanes only emit SystemVerilog/Verilog tops,
  - and the diagnostic still names the unsupported requested target language directly.
- Important continuity note:
  - this closes another older-wording pocket on a real composition CLI boundary,
  - it keeps backend behavior unchanged,
  - and it adds focused pipeline and CLI coverage instead of relying on incidental target-selection failures.
## 2026-03-17: endpoint-shape diagnostics now say when binding is blocked
- Saved shipped behavior:
  - reserved-system `=name` declarations now say explicitly when declared connect-by-name is blocked because shared system ports already use the dedicated system-input contract,
  - and unsupported explicit endpoint syntax now says explicitly when explicit link endpoint resolution is blocked because only top-port names and `instance.port` child endpoints are supported.
- Important continuity note:
  - this closes another older-wording pocket on the public composition endpoint surface,
  - it keeps binding behavior unchanged,
  - and it adds focused coverage instead of relying on incidental endpoint-shape failures.
## 2026-03-17: duplicate composition declarations now say when shape is blocked
- Saved shipped behavior:
  - duplicate top-port declarations now say explicitly when composition shape is blocked because top port names must be unique,
  - and duplicate realized child instance names now say explicitly when composition shape is blocked because child instance names must be unique.
- Important continuity note:
  - this closes another older-wording pocket in public composition-shape diagnostics,
  - it keeps planning behavior unchanged,
  - and it adds focused coverage instead of relying on incidental duplicate-declaration failures.
## 2026-03-17: `C1` passthrough exposure failures now say when exposure is blocked
- Saved shipped behavior:
  - `C1` passthrough exposure now says explicitly when it is blocked because explicit top exposure omitted a realized child port,
  - and it now says the same thing when an explicitly declared top port disagrees with the realized child interface on existence, width, or direction.
- Important continuity note:
  - this closes another older-wording pocket in the public single-child composition path,
  - it keeps the planner behavior unchanged,
  - and it adds focused regression coverage instead of relying only on existing `C1` success tests.
## 2026-03-17: top-level composition lane and shape gates now say they are blocked
- Saved shipped behavior:
  - top-level composition lane entry now says explicitly when it is blocked because no child instances exist,
  - and top-level composition shape now says explicitly when it is blocked because `?ports` multiplicity is invalid or omitted/empty `?ports` appears outside the bounded inference cases.
- Important continuity note:
  - this extends the blocked-wording surface from explicit-link execution into the top-level composition gates,
  - it updates the existing no-child coverage and adds focused shape-gate coverage,
  - and it keeps the planner behavior unchanged.
## 2026-03-17: explicit-link lane-entry and topology failures now say they are blocked
- Saved shipped behavior:
  - explicit-link lane entry now says explicitly when it is blocked because `C2`/`C3` was entered without any `?toplink`,
  - and explicit-link topology now says explicitly when it is blocked because a top input tries to drive a top output directly or one source tries to drive multiple top outputs.
- Important continuity note:
  - this closes another older-wording pocket in the explicit-link family,
  - it adds focused coverage instead of widening planner behavior,
  - and it keeps the same endpoint/source detail in the exception text.
## 2026-03-17: explicit-link unwired-port failures now say wiring is blocked
- Saved shipped behavior:
  - explicit-link top-port failures now say explicitly when top wiring is blocked because a declared non-system top port remains unused,
  - and explicit-link child-port failures now say explicitly when realized child wiring is blocked because a realized child port remains unconnected.
- Important continuity note:
  - this closes the remaining unwired-port wording pocket in the explicit-link family,
  - it adds focused regression coverage instead of widening planner behavior,
  - and it keeps the same top-port and child-port detail in the exception text.
## 2026-03-17: explicit toplink validation failures now say when the declared link is blocked
- Saved shipped behavior:
  - explicit `?toplink` endpoint resolution failures now say explicitly when the declared link is blocked by a missing endpoint,
  - and explicit `?toplink` validation now says the declared link is blocked when direction, duplicate-drive, or width evidence prevents it from applying.
- Important continuity note:
  - this broadens the blocked-wording surface into the core explicit-link validation family,
  - it reuses the existing composition-error coverage rather than widening planner behavior,
  - and it keeps the detailed endpoint evidence intact in the exception text.
## 2026-03-17: explicit top-output re-export mismatches now say when re-export is blocked
- Saved shipped behavior:
  - explicit top-output re-export mismatches for inferred same-name internal carriers now say explicitly when that bounded re-export path is blocked,
  - and the width/type mismatch branches still keep the resolved child-side width/type detail in the exception text.
- Important continuity note:
  - this closes the remaining older-wording pocket in the internal-carrier re-export branch,
  - it reuses the existing local-override rule instead of widening planner behavior,
  - and it adds focused coverage for both width and type mismatch wording in [t/100-composition-internal-carrier-top-reexport.t](/Users/richarddje/Documents/github/fsmgen/t/100-composition-internal-carrier-top-reexport.t).
## 2026-03-17: declared connect-by-name failures now say when the declared match is blocked
- Saved shipped behavior:
  - declared `=name` connect-by-name failures now say explicitly when the declared match is blocked,
  - and the mixed-direction, width-mismatch, ambiguity, and missing-endpoint branches all keep their same-name endpoint evidence in the exception text.
- Important continuity note:
  - this broadens the blocked-wording diagnostics into the `C4` declared connect-by-name family,
  - it reuses existing focused coverage instead of widening planner behavior,
  - and the next diagnostics seam is now broader failure-path wording beyond these major composition families.
- Updated [t/24-composition-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/24-composition-connect-by-name.t) and [t/95-composition-connect-by-name-input-fanout.t](/Users/richarddje/Documents/github/fsmgen/t/95-composition-connect-by-name-input-fanout.t) to lock the broadened blocked-wording surface for declared connect-by-name.
## 2026-03-17: explicit-toplink top-port inference failures now say when inference is blocked
- Saved shipped behavior:
  - explicit-toplink-driven undeclared top-port inference failures now say explicitly when that inference path is blocked,
  - and the mixed-role, width-mismatch, and type-mismatch branches all keep their explicit-link evidence in the exception text.
- Important continuity note:
  - this broadens the blocked-wording diagnostics into the explicit-toplink inference family,
  - it also closes previously untested width/type wording branches there,
  - and the next diagnostics seam is now broader failure-path wording beyond these major convention-over-configuration inference paths.
- Updated [t/101-composition-explicit-link-implicit-ports.t](/Users/richarddje/Documents/github/fsmgen/t/101-composition-explicit-link-implicit-ports.t) to lock the broadened blocked-wording surface for explicit-toplink-driven undeclared top-port inference.
## 2026-03-17: undeclared inference failure diagnostics now say when convention is blocked
- Saved shipped behavior:
  - undeclared top-input inference failures now say explicitly when that convention-first path is blocked,
  - undeclared top-output inference failures now say explicitly when that convention-first path is blocked,
  - and undeclared same-name internal-carrier inference failures now do the same.
- Important continuity note:
  - this broadens the earlier blocked-wording slice beyond plain explicit top ports,
  - it keeps the concrete child-endpoint detail intact,
  - and the next diagnostics seam is now broader failure-path wording outside these main convention-first composition families.
- Updated [t/97-composition-implicit-multi-child-inputs.t](/Users/richarddje/Documents/github/fsmgen/t/97-composition-implicit-multi-child-inputs.t), [t/98-composition-implicit-multi-child-outputs.t](/Users/richarddje/Documents/github/fsmgen/t/98-composition-implicit-multi-child-outputs.t), and [t/99-composition-implicit-internal-carriers.t](/Users/richarddje/Documents/github/fsmgen/t/99-composition-implicit-internal-carriers.t) to lock the broadened blocked-wording failure surface.
## 2026-03-17: plain explicit top-port failure diagnostics now say when convention is blocked
- Saved shipped behavior:
  - plain explicit top-port same-name convention failures now say explicitly when that convention is blocked,
  - and they still list the conflicting child endpoints instead of collapsing into generic ambiguity text.
- Important continuity note:
  - this is the first bounded failure-path blocked-wording slice,
  - it lines up the exception surface with the already-shipped successful-run `Convention Blocks` reporting,
  - and the next diagnostics seam is now broader failure-path wording beyond these plain explicit top-port cases.
- [t/107-composition-blocked-failure-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/107-composition-blocked-failure-diagnostics.t) locks the new blocked-wording failure surface.
## 2026-03-17: composition provenance now reports blocked convention cases too
- Saved shipped behavior:
  - `composition_report` now includes the first surfaced blocked-event family,
  - non-quiet `bin/fsmgen` runs now print a `Convention Blocks` summary when those events are present,
  - and composition `module_info` / `statistics` now carry the block count too.
- Important continuity note:
  - the currently shipped blocked events are bounded to explicit child links blocking undeclared top-input/top-output inference and inferred internal carriers staying internal by default,
  - this closes the first successful-run “blocked” visibility gap,
  - and the next reporting/diagnostics seam is now broader failure-path wording rather than more successful-run hidden behavior.
- [t/106-composition-blocked-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/106-composition-blocked-reporting.t) locks the new blocked-report surface.
## 2026-03-17: composition provenance now reports local override events too
- Saved shipped behavior:
  - `composition_report` now includes the first surfaced override-event family,
  - non-quiet `bin/fsmgen` runs now print a `Convention Overrides` summary when those events are present,
  - and composition `module_info` / `statistics` now carry the override count too.
- Important continuity note:
  - the currently shipped override events are bounded to explicit toplinks overriding same-name top-input/top-output convention and explicit top-output re-export of inferred internal carriers,
  - this closes the first “overridden” visibility gap,
  - and the next reporting/diagnostics gap is now mostly “blocked” cases rather than more successful-run override visibility.
- [t/105-composition-override-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/105-composition-override-reporting.t) locks the new override-report surface.
## 2026-03-17: composition provenance now reaches the result hash and CLI summary
- Saved shipped behavior:
  - composition runs now return `composition_report`,
  - that report summarizes top-port and resolved-link provenance from the earlier `origin_kind` / `resolved_links` metadata,
  - and non-quiet `bin/fsmgen` runs now print the same composition provenance summary directly.
- Important continuity note:
  - this is the first user-facing reporting layer on top of the earlier typed provenance metadata,
  - it also populates composition-side resolved-link counts in `module_info` and `statistics`,
  - and the next remaining diagnostics lane is broader failure/report wording for “blocked” / “overridden” cases, not another hidden inference jump.
- [t/104-composition-provenance-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/104-composition-provenance-reporting.t) locks the new report surface.
## 2026-03-17: typed composition plans now expose provenance metadata
- Saved shipped behavior:
  - top ports now carry `origin_kind`,
  - links now carry `origin_kind`,
  - and composition plans now carry `resolved_links` as the full planned-link set instead of exposing only the original `links` input.
- Important continuity note:
  - this is additive, not a replacement of the older `links` field,
  - the current metadata now distinguishes declared explicit ports/links, declared `=name`, inferred passthrough ports/links, explicit-toplink inferred ports, plain-explicit-port convention links, internal-carrier links/re-exports, and auto system-port links,
  - and this is the first bounded step toward the roadmap goal of explaining whether a port/link was inferred, blocked, or overridden.
- [t/103-composition-provenance-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/103-composition-provenance-metadata.t) locks the new provenance surface.
## 2026-03-17: explicit-link `C2` / `C3` plain explicit top ports now reuse same-name convention
- Saved shipped behavior:
  - plain explicit top inputs in explicit-link `C2` / `C3` may now fan out by same name when compatible child inputs still keep one direction plus exact width/type agreement,
  - plain explicit top outputs in explicit-link `C2` / `C3` may now adopt one unique same-name top-facing child output when that child-side evidence stays exact,
  - and explicit top-boundary links still override that convention locally instead of forcing whole-interface restatement.
- Important continuity note:
  - this slice is intentionally separate from `=name` `C4`,
  - mixed input/output same-name families still rely on the already-shipped internal-carrier rule,
  - mixed-direction plain-input families now fail explicitly,
  - and ambiguous plain-output same-name families now fail explicitly too.
- [t/102-composition-explicit-port-convention.t](/Users/richarddje/Documents/github/fsmgen/t/102-composition-explicit-port-convention.t) locks generated-child `C2` success, mixed generated-plus-`?rtl` `C3` success, mixed-direction rejection for plain explicit top inputs, and ambiguity rejection for plain explicit top outputs.
## 2026-03-17: architecture hotspot snapshot saved for future refactor work
- Saved the latest architecture read-through from [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) down the active imported `FSM::*` tree into the continuity docs and roadmap.
- The recorded future seams are:
  - [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) still owning too much composition orchestration/policy/planning,
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) remaining the main synthesis gravity well,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) still carrying enough planning/normalization logic that the backend boundary is not purely rendering-oriented,
  - the still-implicit bridge between [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) and the `FSM::AST::*` family,
  - [perl/FSM/ExpressionNamer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ExpressionNamer.pm) still needing an eventual “live surface vs residue” decision,
  - stale compatibility wording still present in [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen),
  - and global debug state in [perl/FSM/Debug.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Debug.pm) that should be revisited before deeper embedding/API work.
- Continuity note:
  - this is now explicit roadmap work, not just one-session analysis,
  - and the intended follow-up is bounded seam-by-seam retirement while `R11` is still actively shaping composition/type contracts.
## 2026-03-17: explicit-link `C2` / `C3` now infer top ports directly from explicit `?toplink`
- Saved shipped behavior:
  - explicit-link multi-child tops may now omit `?ports` entirely, or use an empty `(?ports)`,
  - and the top boundary is now realized directly from explicit `?toplink` endpoints when those undeclared top endpoints imply one consistent direction plus exact width/type agreement.
- Important continuity note:
  - same-name explicit top-input links now infer the top port declaration without duplicating the already-declared explicit bindings,
  - renamed top endpoints are now supported through explicit `?toplink` evidence instead of requiring an explicit top-port declaration,
  - and undeclared top endpoints still fail explicitly when they are used as both inputs and outputs.
- [t/101-composition-explicit-link-implicit-ports.t](/Users/richarddje/Documents/github/fsmgen/t/101-composition-explicit-link-implicit-ports.t) locks generated-child renamed-endpoint success, RTL-backed renamed-endpoint success, and mixed-role undeclared-endpoint rejection.

## 2026-03-17: explicit-link `C2` / `C3` now re-export inferred same-name internal carriers through explicit top outputs
- Saved shipped behavior:
  - explicit-link tops may still infer same-name internal child-to-child carriers conventionally,
  - those carriers still stay internal by default,
  - but an explicit same-name top output may now adopt and re-export one of those inferred carriers when direction, width, and type metadata still match.
- Important continuity note:
  - explicit links touching that family still suppress the inference locally,
  - several same-name child outputs still fail through the dedicated internal-carrier ambiguity diagnostic,
  - and type-mismatched explicit top-output re-export requests now fail explicitly instead of silently riding the old width-only link path.
- [t/100-composition-internal-carrier-top-reexport.t](/Users/richarddje/Documents/github/fsmgen/t/100-composition-internal-carrier-top-reexport.t) locks generated-child success, mixed generated-plus-`?rtl` success, ambiguity rejection, and top-output type-mismatch rejection for the shipped re-export slice.

## 2026-03-17: explicit-link `C2` / `C3` now infer same-name internal carriers
- Saved shipped behavior:
  - explicit-link tops may now infer internal same-name child-to-child carriers when exactly one same-name child output and one or more same-name child inputs remain available,
  - and the inferred carrier uses the shared signal name and stays internal by default.
- Important continuity note:
  - any explicit top port or explicit link touching that name family suppresses the inference locally,
  - several same-name child outputs now fail through a dedicated internal-carrier diagnostic,
  - and that follow-up question is now answered by the newer shipped explicit top-output re-export slice recorded above.
- [t/99-composition-implicit-internal-carriers.t](/Users/richarddje/Documents/github/fsmgen/t/99-composition-implicit-internal-carriers.t) locks generated-child fanout success, mixed generated-plus-`?rtl` success, and several-output ambiguity rejection.

## 2026-03-17: explicit-link `C2` / `C3` now infer undeclared unique top outputs
- Saved shipped behavior:
  - explicit-link tops may now infer undeclared top outputs when exactly one same-name child output remains top-facing,
  - and that inferred top output binds directly back to the unique child output.
- Important continuity note:
  - child outputs already consumed by explicit child-to-child links are not re-inferred as top outputs,
  - several same-name top-facing child outputs now fail through a dedicated inference diagnostic,
  - and that top-output slice is now complemented by a separate shipped internal-carrier slice for same-name producer-to-consumer families.
- [t/98-composition-implicit-multi-child-outputs.t](/Users/richarddje/Documents/github/fsmgen/t/98-composition-implicit-multi-child-outputs.t) locks generated-child success, single-`?rtl` explicit-link success, and same-name output ambiguity rejection.

## 2026-03-17: future `R11` now carries a convention-first, local-override composition rule
- Saved future direction:
  - convention should stay the default integration path wherever child/top wiring is unambiguous,
  - explicit port/link declarations should override inference locally instead of forcing whole-interface restatement,
  - and configuration should stay elegant and expressive rather than verbose duplicate wiring.
- Important continuity note:
  - ambiguity should still fail instead of being guessed through,
  - and future diagnostics should explain whether a connection was inferred, blocked, or overridden.

## 2026-03-17: explicit-link `C2` / `C3` now infer undeclared top inputs
- Saved shipped behavior:
  - explicit-link multi-child tops may now infer undeclared top inputs when same-name child inputs remain top-facing,
  - and the inference requires exact agreement on direction, width, and type metadata.
- Important continuity note:
  - child inputs already consumed by explicit child-to-child links are not re-inferred as top ports,
  - this slice still does not infer undeclared top outputs,
  - and it still does not create internal same-name producer-to-consumer carriers automatically.
- [t/97-composition-implicit-multi-child-inputs.t](/Users/richarddje/Documents/github/fsmgen/t/97-composition-implicit-multi-child-inputs.t) locks shared-input success and width-mismatch rejection.

## 2026-03-17: single-child `C1` now infers top ports when `?ports` is omitted or empty
- Saved shipped behavior:
  - `C1` single-child passthrough now accepts no `?ports` block or an empty `(?ports)` block,
  - and in that bounded case the generated top interface is inferred directly from the lone realized child interface.
- Important continuity note:
  - this is deliberately not broad multi-child inference yet,
  - it works because both generated children and external `?rtl` children already realize typed interfaces,
  - and the next convention-over-configuration question is whether undeclared inference should widen beyond this simple passthrough slice.
- [t/96-composition-implicit-single-child-ports.t](/Users/richarddje/Documents/github/fsmgen/t/96-composition-implicit-single-child-ports.t) locks omitted-`?ports` `?fsmc` passthrough inference and empty-`?ports` `?rtl` passthrough inference.

## 2026-03-17: future `R11` now includes a portable synthesizable-type and inference-first lane
- Saved future direction:
  - `R11` now explicitly includes portable synthesizable scalar/aggregate types as a concrete sub-lane instead of relying on conversation memory,
  - the saved portable type core is bits/vectors, enums, records, fixed arrays, arrays of records, and aliases/subtypes,
  - and the preferred user workflow is inference-first: infer scalar versus aggregate signal/port types from LHS/RHS/member/index usage whenever that is honest.
- Important continuity note:
  - explicit type declarations are still part of the future design, but mainly as overrides, ambiguity anchors, and interface-stability controls rather than as mandatory boilerplate,
  - and the future frontend contract should not promise SystemVerilog-only packed-casting convenience that would make a later VHDL backend dishonest.
- [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) now records proposed `(+types ...)` syntax plus phased implementation boundaries for that lane, and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) tracks it under `R11 Left`.

## 2026-03-17: declared top-input `=name` now fans out across matching child inputs
- Saved shipped behavior:
  - `=name` top outputs still stay exact-one-match against child outputs,
  - `=name` top inputs now fan out to all matching child inputs with the same name and width.
- Important continuity note:
  - mixed-direction or width-mismatched same-name candidates now fail explicitly instead of being silently filtered,
  - so the current boundary is more integration-friendly without becoming broad undeclared inference.
- [t/95-composition-connect-by-name-input-fanout.t](/Users/richarddje/Documents/github/fsmgen/t/95-composition-connect-by-name-input-fanout.t) locks the new fanout behavior plus mixed-direction rejection.

## 2026-03-17: declared connect-by-name `C4` now covers multi-generated-plus-`?rtl` tops too
- Saved shipped behavior:
  - `C4` declared connect-by-name still uses the same exact same-name, same-direction, same-width rule,
  - and it now also works when multiple generated children participate beside one or more external `?rtl` children.
- Important continuity note:
  - this slice still did not add hidden inference or a new lane; it just lets the already-general by-name linker admit the broader mixed topology honestly.
- [t/94-composition-multi-generated-plus-rtl-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/94-composition-multi-generated-plus-rtl-connect-by-name.t) locks the first multi-generated-plus-`?rtl` `C4` success path.

## 2026-03-17: explicit-link `C3` now covers multi-generated-plus-`?rtl` tops too
- Saved shipped behavior:
  - `C3` explicit-link composition still requires at least one external `?rtl` child,
  - and it now also works when multiple generated children participate beside those external RTL children.
- Important continuity note:
  - this slice still did not invent a new lane or hidden inference; it just lets the already-general explicit-link planner admit the broader mixed topology honestly.
- [t/93-composition-multi-generated-plus-rtl-children.t](/Users/richarddje/Documents/github/fsmgen/t/93-composition-multi-generated-plus-rtl-children.t) locks the first multi-generated-plus-`?rtl` `C3` success path.

## 2026-03-17: declared connect-by-name `C4` now covers multi-`?rtl` tops too
- Saved shipped behavior:
  - `C4` declared connect-by-name now works for multiple external `?rtl` children,
  - and `C4` now also works for exactly one generated child plus multiple external `?rtl` children.
- Important continuity note:
  - this slice stayed on the same exact-match rule as the earlier by-name work; it did not add hidden inference or arbitration, it only lifted the old one-RTL guard.
- [t/92-composition-multi-rtl-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/92-composition-multi-rtl-connect-by-name.t) locks the first multi-RTL and generated-plus-multi-RTL `C4` success paths plus ambiguity rejection.

## 2026-03-16: explicit-link `C3` now covers multi-`?rtl` tops too
- Saved shipped behavior:
  - `C3` explicit-link composition now works for multiple external `?rtl` children,
  - and `C3` now also works for exactly one generated child plus multiple external `?rtl` children.
- Important continuity note:
  - this slice did not add a new lane or hidden inference; it only widened the already-shipped explicit-link `C3` guard to match what the planner/emitter already handled structurally.
- [t/91-composition-multi-rtl-children.t](/Users/richarddje/Documents/github/fsmgen/t/91-composition-multi-rtl-children.t) locks the first all-RTL and generated-plus-multi-RTL `C3` success paths.

## 2026-03-16: single external `?rtl` child composition now has a first shipped `R11` slice
- Saved shipped behavior:
  - a lone `?rtl` child now works in `C1` passthrough tops,
  - a lone `?rtl` child now works in `C3` explicit-toplink tops,
  - and a lone `?rtl` child now works in `C4` declared connect-by-name tops.
- Important continuity note:
  - the broadened planner rules do not invent a new lane or new syntax; they reuse the already-shipped C1/C3/C4 wiring contracts for a smaller child set.
- [t/90-composition-single-rtl-child.t](/Users/richarddje/Documents/github/fsmgen/t/90-composition-single-rtl-child.t) locks those single-RTL success paths, and [t/13-composition-source-classification.t](/Users/richarddje/Documents/github/fsmgen/t/13-composition-source-classification.t) now names `?rtl` honestly in the no-child boundary.

## 2026-03-16: embedded `?rtlif` roots now have a first shipped `R11` slice
- Saved shipped behavior:
  - `?top:name` sources may now carry embedded `(?rtlif:module_name ...)` companion roots for external RTL children,
  - embedded same-file interface roots take precedence over sidecar `<module>.rtlif` files,
  - and mixed generated-child plus `?rtl` composition can now succeed without a separate sidecar file when the interface contract is declared locally.
- Important continuity note:
  - duplicate embedded `?rtlif` roots for the same RTL module name are rejected explicitly, so local precedence does not silently collapse into ambiguous metadata selection.
- [t/89-composition-embedded-rtlif-roots.t](/Users/richarddje/Documents/github/fsmgen/t/89-composition-embedded-rtlif-roots.t) locks embedded-root precedence, no-sidecar mixed composition success, and duplicate embedded-root rejection.

## 2026-03-16: typed `.rtlif` ports now have a first deliberate `R11` contract slice
- Saved shipped `.rtlif` contract:
  - one flat `(?rtlif:module_name ...)` root,
  - declaration-ordered port tokens,
  - compact tokens such as `clk`, `data_in<8`, and `txd>`,
  - typed tokens such as `core_clk:clock`, `rst_async_n:reset`, and `data_in<8:data`,
  - and explicit type annotations currently limited to `data`, `clock`, and `reset`.
- Important runtime consequence:
  - mixed generated-child plus `?rtl` composition can now auto-wire custom-named RTL system ports honestly through typed `.rtlif` metadata instead of depending on literal `clk` / `rst_n` naming.
- [t/88-rtlif-typed-port-contract.t](/Users/richarddje/Documents/github/fsmgen/t/88-rtlif-typed-port-contract.t) locks direct typed-token parsing, custom-system-port auto-wiring, and rejection of unsupported explicit type names.

## 2026-03-16: mixed generated-child plus external RTL declared connect-by-name now has a first shipped `R11` slice
- `?top:name` now has regression-backed declared `=name` support for the mixed one-generated-child plus one-`?rtl` lane too.
- Saved shipped behavior:
  - mixed tops may combine explicit child-to-child `?toplink` wiring with by-name top exposure,
  - mixed `?fsmc` + `?rtl` and mixed `?dtc` + `?rtl` declared connect-by-name both work,
  - and cross-kind same-name ambiguity still fails explicitly.
- Important bug fix continuity:
  - composition-facing standalone-DT child interfaces now trust semantic `signal_role` before the old name-based heuristic,
  - so RHS-only DT signals like `payload_in` no longer get misclassified as outputs just because they start with `p`.
- [t/87-composition-mixed-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/87-composition-mixed-connect-by-name.t) locks the mixed-lane success and ambiguity cases.

## 2026-03-16: single-child declared connect-by-name now has a first shipped `R11` slice
- `?top:name` now accepts declared `=name` connect-by-name with exactly one generated child (`?fsmc` or `?dtc`) instead of starting only beyond the single-child passthrough case.
- The bounded rule stays the same:
  - exactly one same-named child endpoint,
  - same direction,
  - same width.
- Purely combinational standalone-DT children still keep an honest non-system interface in that single-child by-name lane.
- [t/86-composition-single-child-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/86-composition-single-child-connect-by-name.t) locks the first single-child `?fsmc` and `?dtc` by-name success paths.

## 2026-03-16: composition-facing standalone-DT children now have a first shipped `R11` slice
- Saved shipped behavior:
  - composition now accepts `?dtc:instance child_source` beside `?fsmc`,
  - `?dtc` child sources can be embedded `?dt:name` roots or external searchable `.fsm` standalone-DT sources,
  - and the current generated-child composition lanes now cover standalone-DT child realization too.
- Important continuity note:
  - purely combinational `?dtc` children keep an honest non-system interface in composition,
  - sequential `?dtc` children still expose implicit `clk` / `rst_n` when the standalone `?dt:name` contract requires them.
- [t/85-composition-standalone-dt-children.t](/Users/richarddje/Documents/github/fsmgen/t/85-composition-standalone-dt-children.t) locks the first success-path slice for `?dtc`.
## 2026-03-16: external composition child FSM reuse now has a first shipped `R11` slice
- Saved shipped behavior:
  - `?top:name` can now realize `?fsmc` children from embedded child FSM sources or from external searchable `.fsm` child sources,
  - external child-source lookup checks beside the composition source first, then repeated `--path DIR` roots, then `FSMLIB`, then the current directory,
  - and that broader reusable-root/reference slice now covers live composition child reuse instead of stopping at bare input lookup and `.rtlif` lookup.
- [t/84-composition-external-fsm-child-sources.t](/Users/richarddje/Documents/github/fsmgen/t/84-composition-external-fsm-child-sources.t) locks sibling external child realization, `--path`-driven child realization, and `--path` precedence over `FSMLIB` for `?fsmc` child lookup.
## 2026-03-16: reusable-source lookup now has a first shipped `R11` slice
- Saved shipped behavior:
  - the CLI now accepts repeatable `--path DIR` roots,
  - bare `.fsm` input lookup searches explicit `--path` roots before `FSMLIB`,
  - and current external `.rtlif` metadata lookup also uses those explicit roots before `FSMLIB`.
- [perl/FSM/SourcePathResolver.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/SourcePathResolver.pm) now centralizes that root ordering so we do not duplicate it again in the CLI and metadata loader.
- [t/83-reusable-source-path-resolution.t](/Users/richarddje/Documents/github/fsmgen/t/83-reusable-source-path-resolution.t) locks the bare-input lookup, precedence, and `.rtlif` lookup parts of that slice.
## 2026-03-16: first `R11` standalone `?dt:name` slice is now shipped
- `R11` is no longer purely future-note territory. The first reusable standalone-DT slice is now live.
- Saved shipped contract:
  - `?dt:name` is now a classified/generating source root,
  - top-level `?dt:name` content currently supports `(+size ...)`, `(+constants ...)`, `(+enums ...)`, `(+define ...)`, `(+params ...)`, compact `(:= signal=value)` directives, and general DT blocks such as `(-foo ...)`,
  - explicit `+system` is rejected inside `?dt:name`,
  - purely combinational `?dt:name` modules expose no implicit `clk` / `rst_n`,
  - sequential `?dt:name` modules expose implicit `clk` / `rst_n`,
  - driven non-intermediate targets in `?dt:name` become module outputs by default,
  - and `?dt:name` generation does not synthesize `current_state` / `next_state`.
- [t/82-standalone-dt-root-support.t](/Users/richarddje/Documents/github/fsmgen/t/82-standalone-dt-root-support.t) locks both the combinational and sequential success paths.
## 2026-03-16: malformed `:=` directive shapes now have explicit end-to-end coverage
- [t/81-language-contract-init-directive-shape-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/81-language-contract-init-directive-shape-boundary.t) now locks:
  - malformed non-scalar payloads such as `(:= (tester_reset=1 extra))`,
  - malformed compact directives such as `(:= BROKEN)`,
  - and parser, pipeline, and CLI no-output behavior for the malformed-shape side of the active `:=` family.
## 2026-03-16: reset naming now distinguishes current `?fsm` residue from future/default convention
- Saved wording split:
  - current shipped explicit `(?fsm:name ... (+system ...))` compatibility residue still uses `rstn`,
  - but the forward/default async-reset convention remains `rst_n`,
  - including the implicit no-`+system` path and the planned `?top:name` / sequential `?dt:name` lanes.
## 2026-03-16: non-conventional `+system` reset names now have full coverage
- [t/80-language-contract-system-reset-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/80-language-contract-system-reset-name-boundary.t) now locks:
  - `(sreset reset)`,
  - and `(asreset reset_async_n)`.
- Those malformed reset-name cases are now covered through direct parser checks plus pipeline and CLI no-output behavior, so the conventional `+system` family is no longer fully explicit only on clock names while leaving reset names as docs-only claims.
- Wording note preserved:
  - the synchronous rejected example now uses `reset` instead of `reset_n`,
  - because `_n` implies active-low naming and was misleading in the synchronous case.
## 2026-03-16: malformed `+system` entry structures now have full coverage
- [t/79-language-contract-system-section-structure-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/79-language-contract-system-section-structure-boundary.t) now locks:
  - scalar entries like `BROKEN` inside `(+system ...)`,
  - and wrong-arity entries like `(clock clk extra)`.
- Those malformed `+system` structures are now covered through direct parser checks plus pipeline and CLI no-output behavior, so the conventional `+system` family is no longer fully explicit only on names/directives/incompleteness/duplicates.
## 2026-03-16: malformed symbol-definition token cases now have full coverage
- [t/78-language-contract-symbol-definition-token-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/78-language-contract-symbol-definition-token-boundary.t) now locks:
  - bad identifiers in `+constants`, `+define`, and `+params`,
  - and non-scalar member values in `+enums`.
- Those token-validity failures are now covered through direct parser checks plus pipeline and CLI no-output behavior, so the symbol-definition family is no longer fully end-to-end only on the malformed-shape side.
## 2026-03-16: malformed ordinary RHS expression forms now have full entrypoint coverage
- [t/77-language-contract-expression-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/77-language-contract-expression-entrypoints.t) now locks pipeline and CLI no-output behavior for malformed ordinary RHS expressions:
  - unsupported operators such as `(bogus B C)`,
  - malformed active-operator arity such as `(== B)`,
  - and guard-only tokens such as `<start` in ordinary RHS expression position.
- This closes the remaining end-to-end gap for the malformed ordinary-expression family that was already explicit at direct parser level.
## 2026-03-16: malformed symbol-definition sections now have full entrypoint coverage
- [t/76-language-contract-symbol-definition-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/76-language-contract-symbol-definition-entrypoints.t) now locks pipeline and CLI no-output behavior for malformed:
  - `+constants`,
  - `+define`,
  - and `+params`.
- This closes the remaining end-to-end gap inside the malformed symbol-definition family, which previously had deeper entrypoint coverage only for malformed `+enums`.
## 2026-03-16: inline compound modifiers now have an explicit active boundary
- The active assignment family now also records:
  - bare inline `(+=)` and `(-=)` forms are supported as delta-`1` variants,
  - malformed inline modifier payloads such as `(+= 2 3)` no longer truncate silently,
  - duplicate inline modifiers such as `(+= 2) (-= 1)` no longer fall through a bare-suffix error,
  - and [t/75-language-contract-inline-compound-modifier-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/75-language-contract-inline-compound-modifier-boundary.t) now locks parser, pipeline, and CLI behavior for that family.
## 2026-03-16: future `R11` conflict-detection note now records the naming split too
- The saved future shared-drive direction now also records:
  - per-value-source overlap signals such as `P_Q_multi_src_conflict`,
  - and whole-target overlap signals such as `P_multi_value_conflict`.
## 2026-03-16: future `R11` shared-drive notes now prefer assertion bits over default arbitration
- The future shared-datapath lane now records:
  - no default auto-resolution or auto-priority for same-target conflicts,
  - per-`(P, Q)` onehot0-style assertion bits over source enables such as `A_P_Q_en`, `B_P_Q_en`, and `C_P_Q_en`,
  - and whole-target `P` assertion bits that detect multiple value families becoming active in the same cycle.
## 2026-03-16: future `R11` reusable-DT and shared-drive notes were refined again
- The future reusable standalone-DT lane now also records:
  - `?dt:name` may contain any number of internal general DT blocks such as `(-foo ...)`,
  - `?fsm:name` always implicitly declares `clk` / `rst_n`,
  - `?dt:name` implicitly declares `clk` / `rst_n` only when at least one sequential assignment exists,
  - and standalone DT arbitration should be expressed through generated enable families rather than a blanket structural conflict ban.
- The future shared-datapath lane now also records:
  - same-target/same-value aggregation is a separate case from same-target/different-value conflict,
  - and multiple FSMs must not drive different values to the same target `P` in the same cycle unless a later explicit priority contract is introduced.
## 2026-03-16: future `R11` now also includes a reusable standalone-DT/module-library lane
- [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) now records a second concrete future `R11` composition direction beyond shared datapath extraction.
- Saved direction:
  - add `?dt:name` as the smallest standalone module description,
  - allow `?dt:name` to mix combinational outputs and sequential outputs in the same standalone DT module,
  - keep the semantic split from `?fsm:name` about control model rather than output kind,
  - keep `?top:name` as the explicit composition-root concept unless a later family-level decision introduces aliases such as `?mod:name` or `?module:name`,
  - and grow reusable-source lookup through existing `FSMLIB` semantics plus repeatable per-invocation `--path DIR` roots.
- Open questions intentionally preserved in the roadmap/design notes:
  - whether unnamed reusable DT roots such as `?dt:` should exist at all,
  - how standalone DT interfaces are declared/exposed,
  - and how lookup precedence/diagnostics work across explicit paths, `--path`, `FSMLIB`, and local files.
## 2026-03-16: implicit no-`+system` generation now defaults to `clk` / `rst_n`
- The effective system contract is now centralized at module level instead of being hardcoded separately in multiple generation paths.
- Saved rule:
  - if explicit conventional `+system` is present, generation keeps the declared `clk` / `rstn` pair,
  - if `+system` is absent, generation defaults to implicit `clk` / asynchronous active-low `rst_n`.
- The sweep updated:
  - [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) for the shared effective-system accessor,
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) for emitted HDL/reset naming,
  - and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition child interfaces and auto-wiring follow the effective child system ports too.
- [t/74-language-contract-implicit-system-defaults.t](/Users/richarddje/Documents/github/fsmgen/t/74-language-contract-implicit-system-defaults.t) now locks the standalone implicit-default path, explicit `+system` override path, and single-child composition realization path.
## 2026-03-16: duplicate `+system` declarations are now locked explicitly
- [t/73-language-contract-system-section-duplicate-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/73-language-contract-system-section-duplicate-boundary.t) now locks the duplicate-declaration side of the conventional `+system` family:
  - duplicate `(clock clk)` entries are rejected,
  - duplicate reset declarations are rejected,
  - and mixed `(sreset rstn)` plus `(asreset rstn)` is also rejected as a duplicate reset declaration.
- This is mostly a regression/doc slice: parser behavior was already correct, but the contract now says plainly that `+system` means exactly one clock declaration plus exactly one reset declaration.
## 2026-03-16: future `R11` now includes a concrete shared-datapath composition lane
- [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) now treats the previously discussed multi-FSM shared-datapath idea as a concrete future `R11` sub-lane instead of an informal architecture note.
- The saved direction is:
  - one generated top may be built from one `.fsm` source or several `.fsm` sources,
  - some child outputs remain directly child-owned,
  - only outputs assigned in at least two child FSMs are candidates to be lifted into one shared datapath block instantiated by the generated top,
  - outputs assigned in only one child FSM are not shared and stay directly child-owned,
  - outputs from child FSMs or the shared datapath block are top-level outputs by default,
  - peer-read registered outputs become top-internal by default unless the user explicitly asks to re-export them,
  - per-child drive-intent enables should be surfaced deterministically (for example `A_P_Q_en`) and aggregated in the shared block/top,
  - lifted registered outputs may loop back into child FSM inputs,
  - and combinational outputs must not become peer-FSM read sources.
- [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) now reflects that `R11` deliverable/left/exit shape explicitly, and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) now records the same design rules in narrative form.
## 2026-03-15: malformed `+system` boundaries are now locked across entry points
- [t/72-language-contract-system-section-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/72-language-contract-system-section-entrypoints.t) now locks pipeline and CLI no-output behavior for:
  - non-conventional `+system` clock names like `(clock core_clk)`,
  - unsupported `+system` entries like `(areset rstn)`,
  - and incomplete `+system` sections.
- This is a regression-only hardening slice: parser behavior was already correct, but the malformed side of the conventional `+system` family is now covered end to end instead of only at direct parser level.
## 2026-03-15: legacy generic/template placeholder boundaries are now locked across entry points
- [t/71-language-contract-generic-placeholder-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/71-language-contract-generic-placeholder-entrypoints.t) now locks pipeline and CLI no-output behavior for:
  - legacy placeholder selectors such as `?[READ]`,
  - legacy repeat macros such as `?repeat:[MAX_COUNT]`,
  - and legacy placeholder tokens such as `[DATAIN]`.
- This is a regression-only hardening slice: parser behavior was already correct, but the legacy generic/template placeholder family is now covered end to end instead of only at direct parser level.
## 2026-03-15: unsupported top-level `+...` directive boundaries are now locked across entry points
- [t/70-language-contract-top-level-directive-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/70-language-contract-top-level-directive-entrypoints.t) now locks pipeline and CLI no-output behavior for:
  - unknown top-level `+` directives like `(+bogus ...)`,
  - and unsupported future-style top-level directives like `(+clock clk)`.
- This is a regression-only hardening slice: parser behavior was already correct, but the unsupported top-level `+...` directive family is now covered end to end instead of only at direct parser level.
## 2026-03-15: malformed test-selector boundaries are now locked across entry points
- [t/69-language-contract-test-selector-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/69-language-contract-test-selector-entrypoints.t) now locks pipeline and CLI no-output behavior for:
  - bare symbolic test selectors like `(BUSY ...)`,
  - and bare numeric test selectors like `(0 ...)`.
- This is a regression-only hardening slice: parser behavior was already correct, but the malformed test-selector family is now covered end to end instead of only at direct parser level.
## 2026-03-15: malformed test-branch boundaries are now locked across entry points
- [t/68-language-contract-test-branch-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/68-language-contract-test-branch-entrypoints.t) now locks pipeline and CLI no-output behavior for:
  - empty test-node branches like `(?MODE (=0))`,
  - and single malformed test-branch bodies that still omit a nested action.
- This is a regression-only hardening slice: parser behavior was already correct, but the malformed test-branch family is now covered end to end instead of only at direct parser level.
## 2026-03-15: bare condition-suffix boundaries are now locked across entry points
- [t/67-language-contract-condition-suffix-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/67-language-contract-condition-suffix-entrypoints.t) now locks pipeline and CLI no-output behavior for:
  - bare assignment condition suffixes like `(A <= B start)`,
  - and bare transition condition suffixes like `(-> busy full)`.
- This is a regression-only hardening slice: parser behavior was already correct, but the malformed bare-suffix family is now covered end to end instead of only at direct parser level.
## 2026-03-15: malformed action-family boundaries are now locked across entry points
- [t/66-language-contract-malformed-action-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/66-language-contract-malformed-action-entrypoints.t) now locks pipeline and CLI no-output behavior for:
  - single-token malformed DT actions like `(BROKEN)`,
  - and empty guarded blocks like `(<req)`.
- This is a regression-only hardening slice: parser behavior was already correct, but the malformed-action family is now covered end to end instead of only at direct parser level.
## 2026-03-15: malformed legacy `+fsm` root bodies are now locked explicitly
- [t/65-language-contract-plus-fsm-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/65-language-contract-plus-fsm-body-boundary.t) now locks the malformed-body side of the legacy `+fsm` root family directly:
  - empty `(+fsm plus_empty)` roots are rejected,
  - scalar body items like `(+fsm plus_scalar BROKEN)` are rejected,
  - and pipeline/CLI do not emit HDL for those malformed legacy roots.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that legacy `+fsm` roots must carry real sibling or nested body content instead of an empty or scalar payload.
## 2026-03-15: malformed structured `?fsm` root bodies now fail early through an explicit boundary
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now requires structured `?fsm:name` roots to carry a non-empty top-level item list and rejects scalar top-level body items explicitly.
- [t/64-language-contract-fsm-root-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/64-language-contract-fsm-root-body-boundary.t) now locks:
  - explicit rejection of `(?fsm:empty_root)`,
  - explicit rejection of `(?fsm:scalar_root BROKEN)`,
  - and pipeline/CLI no-output behavior for malformed structured root bodies.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that structured `?fsm:name` roots must contain a real top-level item list rather than an empty or scalar payload.
## 2026-03-15: bare top-level FSM content now fails early through an explicit source-root boundary
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now turns unwrapped top-level FSM content into a dedicated source-root diagnostic instead of the old generic “expected `?fsm:name` or `+fsm`” parser error.
- [t/63-language-contract-source-root-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/63-language-contract-source-root-boundary.t) now locks:
  - explicit rejection of bare top-level forms like `(+system ...)` and `(idle ...)`,
  - classifier truth for files that remain outside active source kinds,
  - and pipeline/CLI no-output behavior for those malformed roots.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that files must wrap FSM content in `?fsm:module_name` or the legacy `+fsm` root family instead of starting directly with sections or state/DT blocks.
## 2026-03-15: malformed update-shorthand tails now fail early through an explicit boundary
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now turns stray extra positional update-shorthand tails into a dedicated user-facing diagnostic instead of letting them fall through the generic suffix-guard boundary.
- [t/62-language-contract-update-shorthand-tail-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/62-language-contract-update-shorthand-tail-boundary.t) now locks:
  - continued support for guarded forms like `(+= counter 4 <start)`,
  - explicit rejection of malformed tails like `(+= counter 4 3)` and `(+= counter 4 3 2)`,
  - and pipeline/CLI no-output behavior for those malformed forms.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that update shorthand accepts only an optional delta plus an explicit guard suffix after that.
## 2026-03-15: malformed update-shorthand targets now fail early instead of disappearing silently
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now turns malformed update-shorthand targets into a dedicated user-facing diagnostic instead of returning `undef` for recognized update-shorthand forms.
- [t/61-language-contract-update-shorthand-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/61-language-contract-update-shorthand-boundary.t) now locks:
  - malformed targets such as `(++ (counter))` and `(+= (byte_count) 4)`,
  - and pipeline/CLI no-output behavior for malformed update-shorthand forms.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that update shorthand must target a scalar signal name and that malformed nested targets are rejected explicitly.
## 2026-03-15: alternate update-shorthand spellings are now explicitly documented and regression-backed
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the full active update-shorthand family more honestly:
  - `(++ sig)` / `(-- sig)`,
  - `(+= sig)` / `(-= sig)`,
  - `(+=N sig)` / `(-=N sig)`,
  - `(+= sig N)` / `(-= sig N)`.
- [t/60-language-contract-update-shorthand-variants.t](/Users/richarddje/Documents/github/fsmgen/t/60-language-contract-update-shorthand-variants.t) now locks the separated delta-`1` and separated delta-carrying variants directly, including HDL generation through the active backend.
- [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) now records those alternate spellings as part of the active `R8` update-shorthand contract instead of leaving them as undocumented parser behavior.
## 2026-03-15: unsupported assignment operators now fail early through an explicit boundary
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now turns unsupported assignment operators into a dedicated user-facing assignment-operator diagnostic instead of a raw internal parser `confess`.
- [t/59-language-contract-assignment-operator-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/59-language-contract-assignment-operator-boundary.t) now locks:
  - unsupported operators such as `?=` and `=>`,
  - and pipeline/CLI no-output behavior for malformed assignment forms.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states the active assignment-operator family explicitly and documents rejection of unsupported operators.
## 2026-03-15: malformed guard shorthand and inline comparison tokens now fail early through explicit boundaries
- [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) now turns malformed guard shorthand payloads and malformed inline comparison tokens into their dedicated contract diagnostics instead of generic unsupported-expression-token errors.
- [t/58-language-contract-condition-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/58-language-contract-condition-expression-boundary.t) now locks:
  - malformed guard shorthand payloads such as `mode=` and `==3`,
  - malformed inline comparison tokens such as `cnt[2:1]!=` and `=3`,
  - and pipeline/CLI no-output behavior for both malformed families.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents both malformed boundaries explicitly in the active contract section.

## 2026-03-15: malformed delayed-pulse RHS values now fail early through a contract boundary
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now turns malformed delayed-pulse `<N` RHS values into a clean user-facing contract diagnostic instead of raw internal parser messages.
- [t/57-language-contract-pulse-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/57-language-contract-pulse-boundary.t) now locks:
  - malformed delayed-pulse RHS values such as `B` and `2'0`,
  - and pipeline/CLI no-output behavior for malformed delayed-pulse assignments.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that malformed delayed-pulse RHS values are rejected explicitly.
## Purpose
- Preserve the minimum complete context needed to resume work immediately.
- Capture key technical decisions and current implementation status.
- Reference canonical docs for deeper details instead of duplicating everything.
- Use `ROADMAP_STATUS.md` as the canonical live board for what is done versus what is left.
## Non-negotiable workflow (user requirement)
After each completed task, always do this in order:
1. Update `MEMORY.md` with new state and next actionable direction.
2. Update `ROADMAP_STATUS.md` if the completed task changes roadmap status, roadmap deliverables, remaining work, or the current active lane.
3. If live status changed, log that status change in `CHANGES.md`.
4. Update other live docs as needed (`DEVELOPMENT_NOTES.md`, and any user-facing docs impacted by the change).
5. Display the current live status snapshot in the user-facing close-out every time the commit workflow runs.
6. If live status changed, explicitly state how the completed task changed the snapshot; if it did not change, explicitly state that the snapshot is unchanged for this task.
7. In that snapshot, show every `Rj` with at least `Status` + brief `Description`; add brief sub-bullets for the active lane or changed lane when helpful.
8. Run validation for the task scope (syntax checks + regression tests when applicable).
9. Run commit workflow:
   - write `git_message_brief.txt`
   - commit with `git commit -F git_message_brief.txt`
   - do not include attribution trailers unless the user explicitly asks for them
   - clear `git_message_brief.txt` after commit (`truncate -s 0 git_message_brief.txt`)
## 2026-03-15: plain `?SIG` test-node names now fail early if malformed
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates the signal name in plain `?SIG` test nodes explicitly,
  - [t/54-language-contract-test-signal-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/54-language-contract-test-signal-name-boundary.t) now locks valid plain-`?SIG` behavior plus malformed-name rejection through parser, pipeline, and CLI,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the distinction between plain `?SIG` and computed `?(expr)` explicitly.
- Scope of the landed contract slice:
  - explicit support remains for plain `?SIG` with HDL-identifier-compatible signal names,
  - explicit support remains for computed selectors `?(expr)`,
  - explicit rejection now covers malformed plain test-node signal names like `?bad-name` and `?0`.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more test-node family boundary as fully bucketed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep aligning every accepted construct with an explicit source-level contract.
## 2026-03-15: transition targets now fail early if malformed or undeclared
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates transition target spelling while parsing `->` and validates declared-target membership after the FSM is fully parsed,
  - [t/53-language-contract-transition-target-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/53-language-contract-transition-target-boundary.t) now locks valid forward-reference transitions plus malformed/unknown target rejection through parser, pipeline, and CLI entry points,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the transition-target rule directly.
- Scope of the landed contract slice:
  - explicit support remains for transitions to declared regular FSM-state DT blocks,
  - explicit rejection now covers malformed target names like `bad-name`,
  - explicit rejection now covers non-state targets like `-comb`,
  - explicit rejection now covers undeclared targets like `missing_state`.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more control-flow construct family as fully bucketed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep moving validation closer to the source-level construct boundary.
## 2026-03-15: state and DT block names now fail early if malformed
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates regular FSM-state DT names and general/combinational DT names explicitly,
  - [t/52-language-contract-state-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/52-language-contract-state-name-boundary.t) now locks valid-name success plus malformed-name rejection through parser, pipeline, and CLI entry points,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the naming rule directly.
- Scope of the landed contract slice:
  - explicit support remains for regular FSM-state DT names like `state_0`,
  - explicit support remains for general/combinational DT names like `-comb_1`,
  - explicit rejection now covers malformed names like `bad-name`, `-bad-name`, and `--bad`.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more source-visible construct family as fully bucketed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep failing malformed constructs at the language boundary instead of later in HDL generation.
## 2026-03-15: malformed symbol-definition sections now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates `+constants`, `+define`, `+params`, and `+enums` explicitly instead of relying on loose list unpacking,
  - [t/51-language-contract-symbol-definition-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/51-language-contract-symbol-definition-boundary.t) now locks empty-section rejection, malformed entry/member rejection, and pipeline/CLI rejection without HDL output,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the section/entry shapes and malformed-boundary rules explicitly.
- Scope of the landed contract slice:
  - explicit support remains for the already documented symbol-definition family,
  - explicit rejection now covers empty sections and malformed payloads for `+constants`, `+define`, `+params`, and `+enums`,
  - and this family no longer relies on incidental AST/list-shape fallout to fail.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more family as fully bucketed across both happy-path support and malformed-boundary rejection.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep turning accidental parser tolerance into either explicit support or explicit rejection.
## 2026-03-15: `+size` now has an explicit contract
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now parses `+size` through an explicit helper,
  - the legacy empty form `(+size)` remains supported as a no-op,
  - [t/50-language-contract-size-section-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/50-language-contract-size-section-boundary.t) now locks explicit rejection of malformed payloads, malformed entries, and non-positive widths,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the `+size` boundary explicitly.
- Scope of the landed contract slice:
  - explicit support now includes the legacy empty `(+size)` no-op because it exists in the shipped corpus,
  - explicit support still includes regular `(signal width)` declarations,
  - explicit rejection now covers malformed `+size` payloads and malformed/non-positive entries.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more directive-family boundary as explicitly documented and regression-backed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep turning silent tolerated legacy no-ops into explicit support or explicit rejection.
## 2026-03-15: state/DT blocks now need a real body
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects empty state/DT blocks instead of building empty pseudo-states,
  - [t/49-language-contract-state-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/49-language-contract-state-body-boundary.t) now locks parser, pipeline, and CLI behavior for empty FSM-state DT blocks and empty general DT blocks,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that state/DT blocks must contain a real body.
- Scope of the landed contract slice:
  - explicit support still includes FSM-state DT blocks and general/combinational DT blocks,
  - explicit rejection now covers empty blocks like `(idle)` and `(-misc)`,
  - and malformed empty pseudo-states no longer drift through to later runtime stages.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more parser-visible block-shape boundary as explicitly documented and regression-backed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep replacing silent fallthrough behavior with explicit contract diagnostics.
## 2026-03-15: general/combinational DT blocks now carry explicit standalone classification
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) now exposes `is_standalone_dt` on `FSM::CoreAST::State` and treats general/combinational DTs as an explicit state-role family,
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now classifies hyphen-prefixed non-reset DT blocks as `state_type => standalone_dt`,
  - [t/48-language-contract-standalone-dt-classification.t](/Users/richarddje/Documents/github/fsmgen/t/48-language-contract-standalone-dt-classification.t) now locks AST classification plus non-encoding/DT-enable behavior,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states the standalone DT role explicitly.
- Scope of the landed contract slice:
  - explicit support now includes a real AST/runtime distinction between FSM-state DTs and general/combinational standalone DT blocks,
  - standalone DT blocks now stay out of the encoded-state plan by explicit role classification, not only by name heuristics,
  - and they continue to use DT-style enables instead of joining the `current_state` family.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more formerly implicit DT-role boundary as explicitly documented and regression-backed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep replacing naming-heuristic behavior with explicit construct-role contracts where the language model already expects them.
## 2026-03-15: tagged source-name boundary is now explicit
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates top-level `?fsm:module_name` roots as a whole,
  - [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) now validates top-level `?top:top_name` roots and embedded `?fsm:source_name` child sources as a whole,
  - [t/47-language-contract-source-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/47-language-contract-source-name-boundary.t) now locks the malformed-name boundary for all three paths,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that tagged source names must be HDL-identifier-compatible.
- Scope of the landed contract slice:
  - explicit support now includes whole-name validation for tagged FSM/composition roots,
  - explicit rejection now covers malformed tagged names like `?fsm:bad-name` and `?top:bad-name`,
  - and malformed embedded composition child source names no longer truncate silently.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more source-boundary family as explicitly documented and regression-backed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep replacing implicit parser truncation/fallthrough behavior with explicit contract boundaries.
## 2026-03-15: legacy `+fsm` root contract is now explicit
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates the legacy `+fsm` source family before decoding the module name,
  - [t/46-language-contract-flat-plus-fsm-root.t](/Users/richarddje/Documents/github/fsmgen/t/46-language-contract-flat-plus-fsm-root.t) now locks both shipped legacy `+fsm` layouts plus explicit rejection of malformed `+fsm` roots,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states the two active legacy layouts truthfully.
- Scope of the landed contract slice:
  - explicit support now includes the real shipped legacy `+fsm` family as a regression-backed active source kind,
  - explicit rejection now covers malformed `+fsm` roots that omit the scalar module name.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more documented legacy source form as an explicit supported-or-rejected contract boundary.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep replacing under-validated legacy compatibility paths with explicit contract checks.
## 2026-03-15: DT-versus-state wording is now clarified
- Current worktree is a terminology-only follow-up:
  - [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now says both syntaxes are decision trees,
  - a regular named block like `(aState ...)` is an FSM-state DT,
  - and a hyphen-prefixed top-level block like `(-foobar ...)` is a general/combinational DT block.
- Scope of the clarification:
  - no runtime behavior changed,
  - the goal is to keep user-facing wording aligned with the intended language model.
- Roadmap board update:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Immediate next direction after commit:
  - keep `R8` active,
  - keep tightening the language contract,
  - and keep the terminology in the docs as precise as the behavior.
## 2026-03-15: reset-state spelling and classification contract is now live
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) now preserves `state_type` on `FSM::CoreAST::State` and exposes `state_type`, `is_reset_state`, and `is_regular_state`,
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now treats `-syncrst` / `-syncreset` and `-asyncrst` / `-asyncreset` as the same two reset-state families,
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm), and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now keep reset-state blocks out of the regular encoded-state set and treat them as DT-like blocks,
  - [t/45-language-contract-reset-state-spellings.t](/Users/richarddje/Documents/github/fsmgen/t/45-language-contract-reset-state-spellings.t) now locks spelling normalization, non-encoding of reset blocks, and DT-style enable emission,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the reset-state family as a real supported contract.
- Scope of the landed contract slice:
  - explicit support now includes both short and long reset-state spellings,
  - reset-state blocks now normalize to shared internal identities (`syncreset` / `asyncreset`),
  - and reset-state blocks are no longer treated as ordinary encoded `current_state` states.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more formerly accidental parser/runtime edge as an explicit supported construct family.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep converting accidental behavior into either regression-backed support or explicit rejection.
## 2026-03-15: n-ary relational operator contract is now executable
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) now supports n-ary relational chains such as `(< low mid high)` and `(== a b c d)`, relational aliases such as `eq`, `ne`, `lt`, `le`, `gt`, and `ge`, and unary alias `not`,
  - [perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm) now walks the driving AST of parser-created intermediate expression signals during signal-role analysis, so underlying source inputs stay live in generated module interfaces,
  - [t/44-language-contract-relational-operators.t](/Users/richarddje/Documents/github/fsmgen/t/44-language-contract-relational-operators.t) now locks the new relational/operator contract slice end to end,
  - [t/40-language-contract-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/40-language-contract-expression-boundary.t) now keeps malformed-arity rejection aligned with the broader operator contract by rejecting `(== a)`,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the broader operator family truthfully.
- Scope of the landed contract slice:
  - explicit support now includes chained adjacent-pair relational lowering for `==`, `!=`, `<`, `<=`, `>`, and `>=`,
  - explicit support now includes word aliases `not`, `eq`, `ne`, `lt`, `le`, `gt`, `ge`, `add`, `sub`, `mul`, `div`, `mod`, `and`, `or`, and `xor`,
  - explicit rejection now covers malformed supported-operator arity against that broader contract instead of pretending chained comparisons are unsupported.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more adopted operator family as regression-backed and normatively documented.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and either promote them with focused regressions or reject them explicitly.
## 2026-03-15: unsupported top-level bare forms now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects unsupported top-level bare forms inside `(?fsm:name ...)` instead of skipping them silently,
  - [t/43-language-contract-top-level-form-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/43-language-contract-top-level-form-boundary.t) now locks parser, pipeline, and CLI behavior for future-looking bare init syntax like `(tester_reset := 1)` and malformed bare scalar forms like `(BROKEN 1)`,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents those forms as explicitly out of active support.
- Scope of the landed contract slice:
  - explicit support remains limited to directive sections, `:=` init/reset directives, and state/DT blocks at the top level of `(?fsm:name ...)`
  - explicit rejection now covers unsupported bare top-level forms such as `(tester_reset := 1)` and `(BROKEN foo)`
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more silently-skipped legacy/malformed family as explicitly rejected instead.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep converting silent skips/fallbacks into explicit supported-or-rejected boundaries.
## 2026-03-15: test-node selectors now require explicit operator prefixes
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates test-branch selectors explicitly and rejects bare selectors like `BUSY` or `0`,
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) now enforces the same explicit-selector rule during runtime lowering,
  - [t/42-language-contract-test-selector-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/42-language-contract-test-selector-boundary.t) now locks parser/runtime support for explicit operator-prefixed selectors and rejection of malformed bare selectors,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents that active test-node selectors must be operator-prefixed tokens.
- Scope of the landed contract slice:
  - explicit support remains for selectors like `=0`, `=OTHER`, `!=8'0`, and `>8'3`
  - explicit rejection now covers bare selectors like `BUSY` and `0`
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more selector-boundary family as explicitly documented and regression-backed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep tightening the contract where legacy permissiveness still leaks through.
## 2026-03-15: unsupported tagged top-level sources now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects unsupported tagged top-level source kinds such as `?define:legacy_template` before any nested `?fsm` fallback can fire,
  - [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now rejects the same boundary in the active pipeline and CLI path,
  - [t/41-language-contract-top-level-source-kind-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/41-language-contract-top-level-source-kind-boundary.t) now locks classifier, adapter, pipeline, and CLI behavior for that boundary,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents unsupported tagged top-level source roots explicitly.
- Scope of the landed contract slice:
  - explicit support remains limited to `?fsm:name`, `+fsm`, and `?top:name`
  - explicit rejection now covers unsupported tagged roots such as `?define:...`
  - nested live `?fsm` content inside an unsupported tagged root no longer makes that root parseable
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more top-level legacy wrapper family as explicitly rejected instead of ambiguously accepted.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep tightening the contract at the root/source and construct-family boundaries.
## 2026-03-15: unsupported expression forms now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) now parses real inline scalar comparison tokens such as `cnt[2:1]!=2'2` explicitly while rejecting unsupported expression operators, malformed active-operator arity, empty expression lists, unsupported payload types, and guard-only tokens in ordinary RHS expression position,
  - [t/40-language-contract-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/40-language-contract-expression-boundary.t) now locks that rejection boundary directly,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents unsupported/malformed expression forms explicitly in the out-of-support bucket.
- Scope of the landed contract slice:
  - explicit support for inline scalar comparison tokens such as `cnt[2:1]!=2'2`
  - explicit rejection of unsupported RHS operators such as `(bogus B C)`
  - explicit rejection of malformed active-operator arity such as `(== B C D)`
  - explicit rejection of guard-only tokens such as `<start` when used in ordinary expression position
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more parser-visible legacy/fallthrough boundary as explicitly rejected instead of implicit.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing the remaining parser/runtime-visible language edges,
  - and keep making the current support boundary explicit construct family by construct family.
## 2026-03-15: shorthand guard comparisons are now part of the active contract
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) now lowers the shorthand guard family explicitly for both guarded blocks and suffix guards,
  - [t/39-language-contract-guard-shorthand.t](/Users/richarddje/Documents/github/fsmgen/t/39-language-contract-guard-shorthand.t) now locks that family directly,
  - [t/29-language-contract-core-forms.t](/Users/richarddje/Documents/github/fsmgen/t/29-language-contract-core-forms.t) now expects explicit comparison ASTs for the simple `<foo` / `<!foo` cases,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the shorthand family as part of the active contract instead of keeping it future-only.
- Scope of the landed contract slice:
  - explicit support for `(<foo ...)` as `foo != 0`
  - explicit support for `(<!foo ...)` as `foo == 0`
  - explicit support for inline comparison shorthand such as `(<foo==3 ...)`, `(<foo!=0 ...)`, and `(<foo<=3 ...)`
  - explicit support for the same shorthand family in suffix-guard position
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more saved design agreement as actively supported and regression-backed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible legacy forms,
  - and keep promoting or rejecting each construct family explicitly with focused regressions.
## 2026-03-15: future placeholder syntax direction is now preserved
- Current task was design-history only, not a support-boundary change:
  - [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) now records the preferred future placeholder direction for any later generic/template lane.
- Saved conclusion from the discussion:
  - do not revive legacy `[VAR]` as the canonical placeholder form,
  - do not use `<VAR>` because `<...` is already core guard syntax,
  - prefer `$(VAR)` as the future canonical placeholder form,
  - and treat `$VAR` only as possible sugar over `$(VAR)` if a real generic/template lane ever exists.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - and there is no active-contract expansion from this note alone.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible legacy forms,
  - and keep separating active contract truth from future language-design ideas.
## 2026-03-15: legacy generic/template placeholders now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects placeholder selectors like `?[READ]` and repeat macros like `?repeat:[MAX_COUNT]` with targeted diagnostics,
  - [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) now rejects placeholder scalar tokens like `[DATAIN]` explicitly instead of registering them as ordinary signals,
  - [t/38-language-contract-generic-placeholder-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/38-language-contract-generic-placeholder-boundary.t) now locks that boundary,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the whole placeholder/generic family as explicitly out of active support.
- Scope of the landed contract slice:
  - explicit rejection of placeholder selectors such as `?[READ]`
  - explicit rejection of legacy repeat-expansion macros such as `?repeat:[MAX_COUNT]`
  - explicit rejection of placeholder tokens such as `[DATAIN]` and `[?size: ...]`
- Design context preserved in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md):
  - user clarified that `[READ]`-style forms act like generics to be populated later,
  - so they belong to a future generic/template lane, not the active `R8` support boundary.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more parser-visible legacy family as explicitly rejected instead of ambiguously parser-visible.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm`
  - `perl -I perl -c t/38-language-contract-generic-placeholder-boundary.t`
  - `prove -I perl t/38-language-contract-generic-placeholder-boundary.t`
  - `prove -I perl t`
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing the remaining parser/runtime-visible legacy forms,
  - and keep classifying each one into supported or explicitly rejected buckets.
## 2026-03-15: computed test selectors now synthesize real intermediate wires end to end
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm) now analyzes `?(expr)` selector-driving ASTs so selector source signals remain live in the generated interface,
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) now treats parser-created computed-selector signals marked as intermediate as real intermediates during dependency/filtering analysis,
  - [t/37-language-contract-computed-test-selector.t](/Users/richarddje/Documents/github/fsmgen/t/37-language-contract-computed-test-selector.t) now locks that end-to-end behavior,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents `?(expr)` as part of the active test-node contract.
- Scope of the landed contract slice:
  - explicit support for computed-selector test nodes such as `(?(| A B) (=0 ...) (=1 ...))`
  - explicit emission of the synthesized intermediate selector wire in generated HDL
  - explicit preservation of the computed selector's source signals as live interface inputs
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more real parser/runtime-visible test-node family as fully documented and regression-backed.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm`
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c t/37-language-contract-computed-test-selector.t`
  - `prove -I perl t/12-enablegraph-capture-registry.t t/37-language-contract-computed-test-selector.t`
  - `prove -I perl t`
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible legacy constructs,
  - and keep promoting or rejecting each construct family explicitly with focused regressions.
## 2026-03-15: `:=` init/reset directives are now explicit, and malformed DT actions fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now treats top-level `:=` as an explicit init/reset directive,
  - records reset/default metadata for the target signal,
  - and rejects malformed DT actions and empty guarded blocks instead of silently dropping them,
  - [t/34-language-contract-malformed-actions.t](/Users/richarddje/Documents/github/fsmgen/t/34-language-contract-malformed-actions.t) now locks that boundary,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents both the active `:=` contract and the malformed-form rejection boundary explicitly.
- Scope of the landed contract slice:
  - explicit support for top-level compact init/reset directives such as `(:= tester_reset=1)`
  - explicit rejection of malformed single-token DT actions such as `(BROKEN)`
  - explicit rejection of empty guarded blocks such as `(<req)`
  - saved future-syntax note in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md):
    - possible canonical future form `(:= (lhs value))`
    - and possible sugar form `(lhs := value)`
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records that the active contract includes top-level `:=` and one less silent parser-drop behavior in the DT action family.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c t/34-language-contract-malformed-actions.t`
  - `prove -I perl t/34-language-contract-malformed-actions.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser-visible implicit fallthroughs,
  - and keep turning them into either supported or explicitly rejected behavior.
## 2026-03-15: malformed empty test-node branches now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now emits a targeted malformed-test-branch diagnostic for empty `?sig` branches,
  - [t/35-language-contract-test-branch-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/35-language-contract-test-branch-boundary.t) now locks that boundary,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now says explicitly that each test-node branch needs a selector plus at least one nested action.
- Scope of the landed contract slice:
  - explicit rejection of empty test branches such as `(?MODE (=0))`
  - explicit rejection of mixed test nodes where one branch is valid and another branch is empty
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one less generic parser-failure path in the test-node family.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c t/35-language-contract-test-branch-boundary.t`
  - `prove -I perl t/35-language-contract-test-branch-boundary.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser-visible legacy constructs,
  - and keep replacing generic parser artifacts with supported or explicitly rejected behavior.
## 2026-03-15: relational test-node selectors are now explicit and regression-backed
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) now lowers relational `?sig` selectors using their actual operators instead of collapsing them to equality,
  - [t/36-language-contract-test-branch-selectors.t](/Users/richarddje/Documents/github/fsmgen/t/36-language-contract-test-branch-selectors.t) now locks captured AST and emitted-HDL behavior for `!=`, `>`, and `<=`,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the broader active selector family explicitly.
- Scope of the landed contract slice:
  - explicit support for exact and relational `?sig` selectors such as `=0`, `!=8'0`, `>8'3`, and `<=8'3`
  - removal of the incorrect equality-only lowering in the active generation path
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more parser/runtime-visible language family as regression-backed and truthfully documented.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c t/36-language-contract-test-branch-selectors.t`
  - `prove -I perl t/36-language-contract-test-branch-selectors.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser-visible legacy constructs and underspecified live behavior,
  - and keep promoting or rejecting each family explicitly.
## 2026-03-15: bare condition suffixes now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects bare suffix tails in assignment/transition suffix positions,
  - [t/33-language-contract-condition-suffix-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/33-language-contract-condition-suffix-boundary.t) now locks that boundary,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that suffix guards must use explicit `<...` / `<!...` forms.
- Scope of the landed contract slice:
  - explicit rejection of malformed bare suffixes such as `(A <= B start)`
  - explicit rejection of malformed bare transition tails such as `(-> busy full)`
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one less implicit parser-accepted legacy path in the guard family.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c t/33-language-contract-condition-suffix-boundary.t`
  - `prove -I perl t/33-language-contract-condition-suffix-boundary.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing the remaining non-directive parser-visible legacy constructs,
  - and keep shrinking implicit acceptance paths into either supported or explicitly rejected behavior.
## 2026-03-15: unsupported top-level `+...` directives now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects unsupported top-level `+...` directive sections explicitly instead of parsing them as fake states,
  - [t/32-language-contract-top-level-directive-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/32-language-contract-top-level-directive-boundary.t) now locks that boundary,
  - and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) now preserves the syntax-namespace rationale from the latest language-design discussion.
- Scope of the landed contract slice:
  - explicit rejection of unknown top-level directive sections such as `(+bogus ...)`
  - explicit rejection of future-looking but currently unsupported directive spellings such as `(+clock clk)`
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` and `ROADMAP_V2.md` now record that unsupported top-level `+...` directives are no longer in an ambiguous parser-accepted bucket.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c t/32-language-contract-top-level-directive-boundary.t`
  - `prove -I perl t/32-language-contract-top-level-directive-boundary.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - audit the remaining non-directive parser-visible legacy constructs that still lack a clean support-tier bucket,
  - then continue tightening the normative reference and regressions family by family.
## 2026-03-15: conventional `+system` contract slice is landed under `R8`
- Current worktree is the next `R8` implementation slice:
  - [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now treats the conventional `+system` declaration as fully supported and documents its normative contract,
  - [t/31-language-contract-system-section.t](/Users/richarddje/Documents/github/fsmgen/t/31-language-contract-system-section.t) now locks the active accepted/rejected boundary,
  - and [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates `+system` explicitly instead of silently ignoring it.
- Scope of the landed contract slice:
  - accepted conventional shared-system declaration:
    - `(+system (clock clk) (sreset rstn))`
    - `(+system (clock clk) (asreset rstn))`
  - explicit rejection of:
    - alternative clock names,
    - unsupported system directives,
    - and incomplete `+system` sections
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` and `ROADMAP_V2.md` now record that the conventional `+system` boundary moved into the supported, regression-backed contract.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c t/31-language-contract-system-section.t`
  - `prove -I perl t/31-language-contract-system-section.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - audit the remaining parser-visible legacy constructs that still lack a clean support-tier bucket,
  - then continue tightening the normative reference and regressions family by family.
## 2026-03-15: symbol-definition contract slice is landed under `R8`
- Current worktree is the second real `R8` implementation slice:
  - [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now treats the symbol-definition families as fully supported and documents their current normative contract,
  - [t/30-language-contract-symbol-definitions.t](/Users/richarddje/Documents/github/fsmgen/t/30-language-contract-symbol-definitions.t) now locks the active behavior,
  - and [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now unwraps packed scalar tokens correctly for symbol-definition parsing.
- Scope of the landed contract slice:
  - `(+constants ...)`
  - `(+enums ...)`
  - `(+define ...)`
  - `(+params ...)`
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` and `ROADMAP_V2.md` now record that symbol-definition sections moved into the supported, regression-backed contract.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c t/30-language-contract-symbol-definitions.t`
  - `prove -I perl t/30-language-contract-symbol-definitions.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - resolve the remaining `(+system ...)` semantics beyond the conventional `clk` / `rstn` path,
  - then continue bucketing any remaining parser-visible legacy constructs with focused regressions.
## 2026-03-14: first `R8` contract-hardening slice is landed
- Current worktree is the first real `R8` implementation slice:
  - the first draft normative language-contract section is now live in [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md),
  - focused regression coverage exists in [t/29-language-contract-core-forms.t](/Users/richarddje/Documents/github/fsmgen/t/29-language-contract-core-forms.t),
  - and two small warning-noise fixes landed in [perl/FSM/ExpressionNamer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ExpressionNamer.pm) and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm).
- Scope of the landed contract slice:
  - nested guarded blocks,
  - condition suffixes,
  - compound update shorthand and inline compound modifiers,
  - and the currently regression-backed broader operator-expression families.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` and `ROADMAP_V2.md` now record that the first normative-contract/regression slice is complete.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/ExpressionNamer.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/29-language-contract-core-forms.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - resolve the remaining gray-zone families around `(+system ...)` and symbol-definition sections,
  - then continue contract-hardening regressions family by family.
## 2026-03-14: long-term horizon goals added to roadmap v2
- Current worktree is a doc-only roadmap-continuity slice adding explicit long-term horizon goals without changing the active priority order.
- Scope of this slice:
  - extended [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) with:
    - `H1` Rust FSMGen,
    - `H2` a beautiful, dynamic public project website,
  - recorded the gating rule that these are long-term goals only after FSMGen is first made state-of-the-art, rock solid, and really stable,
  - updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) to mention that horizon goals exist but are intentionally outside the active `R8`..`R14` lanes.
- Roadmap board update:
  - no roadmap status/deliverable/active-lane change for this slice,
  - the live roadmap snapshot remains unchanged.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - keep `R8` as the active lane,
  - treat the Rust implementation and public website as horizon goals, not near-term execution lanes.
## 2026-03-14: roadmap v2 is now active
- Current worktree is the roadmap-opening slice that turns the previously saved post-roadmap ideas into an actual second roadmap generation.
- Scope of this slice:
  - added [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) as the detailed companion roadmap for the post-`R0`..`R7` workstreams,
  - refreshed [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so `v2` is now the active roadmap generation,
  - opened `R8` as the current active lane,
  - defined `R9` through `R14` as explicit follow-on workstreams,
  - updated [README.md](/Users/richarddje/Documents/github/fsmgen/README.md) so onboarding points to the new roadmap companion directly.
- Roadmap board update:
  - the active lane moved from `none` to `R8`,
  - `R8` is now `in progress`,
  - `R9` through `R14` now exist explicitly on the board and are `not started`.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - continue on `R8`,
  - first turn the saved guarded-block / suffix-guard / update-shorthand / operator-arity agreements into a draft normative language-reference section,
  - then classify the remaining unresolved `(+system ...)` and symbol-definition families.
## 2026-03-14: operator-form RHS design direction preserved
- Current worktree is a doc-only design-continuity slice saving the working direction for `(6)` operator-form RHS expressions.
- Scope of this slice:
  - saved in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) that combinational and sequential assignments should share one RHS expression grammar,
  - saved that operator aliases should lower to canonical operators,
  - saved the broader agreement that infix-style operator families should be treated as unlimited-ary whenever their semantics can be defined deterministically,
  - saved natural unlimited-ary fold semantics for `+`, `*`, `&`, `|`, and `^`,
  - saved unary semantics for `!`,
  - saved left-associative unlimited-ary semantics for `-`, `/`, and `%`,
  - saved chained relational semantics as adjacent-pair conjunction, for example `(< a b c)` => `((a < b) && (b < c))`,
  - and saved the meta-rule that any allowed operator form must have an explicit unambiguous interpretation with examples.
- Roadmap board update:
  - no roadmap status/deliverable/active-lane change for this slice,
  - the live roadmap snapshot remains unchanged.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - no roadmap lane is active,
  - the next natural discussion is whether the operator-family contract above should be fully adopted as-is or narrowed before becoming normative.
## 2026-03-14: guarded-block and suffix-guard design agreements preserved
- Current worktree is a doc-only design-continuity slice saving the agreed semantics for future language-contract hardening.
- Scope of this slice:
  - saved in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) that guarded blocks `(3)` are first-class,
  - saved that guarded-block nesting is unlimited and composes by logical `AND`,
  - saved the sugar and shorthand rules:
    - `(<foo ...)` => `foo != 0`
    - `(<!foo ...)` => `foo == 0`
    - `(<foo==3 ...)` => guarded relational shorthand
  - saved that condition suffixes `(4)` have exactly the same semantics as guarded blocks and desugar to a guarded block around a single action,
  - saved the agreed increment/decrement semantics for update shorthand `(5)`.
- Roadmap board update:
  - no roadmap status/deliverable/active-lane change for this slice,
  - the live roadmap snapshot remains unchanged.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - no roadmap lane is active,
  - the next natural discussion is whether `(6)` broader arithmetic/operator forms should get an equally explicit semantic contract or be intentionally narrowed first.
## 2026-03-14: post-roadmap improvement priorities preserved for later roadmap work
- Current worktree is a doc-only continuity slice to save the suggested post-`R0`..`R7` improvement order before any new roadmap is opened.
- Scope of this slice:
  - saved the recommended next-workstream order in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md),
  - preserved the specific gray-zone cluster that should be resolved first in any future language-contract hardening work,
  - kept those notes as future recommendations rather than reopening the closed current roadmap.
- Roadmap board update:
  - no roadmap status/deliverable/active-lane change for this slice,
  - the live roadmap snapshot remains unchanged.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - no roadmap lane is active,
  - the natural follow-up is discussion/brainstorming on the gray-zone constructs before deciding whether to open a new explicit roadmap.
## 2026-03-14: user-guide support boundary clarified for current `.fsm` language
- Current worktree is a doc-only clarification pass driven by the need to state the real active `.fsm` support boundary precisely.
- Scope of this slice:
  - expanded [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) with a live supported-constructs section,
  - separated:
    - fully supported constructs,
    - implemented-but-not-fully-regression-backed constructs,
    - and explicitly unsupported constructs,
  - clarified that standalone decision-tree blocks like `(-alpha_dt ...)`, `(-misc ...)`, and `(-mycombit ...)` are part of the active supported surface,
  - clarified the current runtime consequence of DT-only inputs: no state-register plan is synthesized when only standalone DT blocks are present,
  - tightened the guide wording so composition is described as a deliberately narrow shipped model instead of as merely "partially implemented".
- Roadmap board update:
  - no roadmap status/deliverable/active-lane change for this slice,
  - the live roadmap snapshot remains unchanged.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - no roadmap lane is active,
  - if follow-up work is wanted from this clarification, the most natural next slice is turning the same support boundary into a more formal language-reference table or opening a new explicit roadmap workstream.
## 2026-03-14: `R7` closed with the shipped source-frontier hook
- Current worktree finishes the bounded `R7` lane by adding the next small typed hook boundary instead of growing the loading surface further.
- Scope of this slice:
  - extended [perl/FSM/Extension/Context.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Context.pm) so hook contexts now carry `stage` and `raw_ast` where appropriate,
  - extended [perl/FSM/Extension/Registry.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Registry.pm) so the shipped typed hook set now includes `after_parse_source($context)` in addition to `after_generate_result($context)`,
  - updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the new hook runs after parsing/classification and after composition IR parsing for top-level composition sources,
  - updated [t/26-extension-mechanism.t](/Users/richarddje/Documents/github/fsmgen/t/26-extension-mechanism.t), [t/lib/FSM/TestExtension/Marker.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/TestExtension/Marker.pm), and [t/27-extension-loading.t](/Users/richarddje/Documents/github/fsmgen/t/27-extension-loading.t) to lock the new hook boundary across direct, module-loaded, and CLI-loaded extension paths.
- Roadmap board update:
  - [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) now moves `R7` from `mostly done` to `done`,
  - the current active lane is now `none` because all currently defined roadmap workstreams `R0` through `R7` are complete,
  - any future continuation should open a new explicit workstream instead of stretching the closed current roadmap.
- Validation is green for this slice:
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Context.pm`
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Registry.pm`
  - `perl -I perl -I t/lib -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -I t/lib -c t/26-extension-mechanism.t`
  - `prove -I perl -I t/lib t/26-extension-mechanism.t t/27-extension-loading.t t/28-extension-config-loading.t`
  - `git diff --check`
- Immediate next direction after commit:
  - no blocking roadmap lane remains,
  - future work should start from a newly defined workstream if the project adds another objective beyond the closed `R0`..`R7` plan.
## 2026-03-14: `R7` shipped explicit extension-config loading
- Current worktree continues `R7` by adding the explicit config-file layer that was still left open after the object/module loading slices.
- Scope of this slice:
  - extended [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm) so it can parse explicit extension-config files and report malformed lines with file/line context,
  - updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so callers may pass `extension_config_files => [ ... ]`,
  - updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so repeated `--extension-config <file>` flags can load typed extensions from explicit config files,
  - added [t/28-extension-config-loading.t](/Users/richarddje/Documents/github/fsmgen/t/28-extension-config-loading.t) to lock loader, pipeline, and CLI config-file loading plus malformed-config diagnostics.
- Roadmap board update:
  - [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) now moves `R7` from `in progress` to `mostly done`,
  - the active lane remains `R7`,
  - the next decision point is now the next typed hook boundary, with constructor/config-parameter richness left as a later follow-up rather than a blocker on the current loading stack.
- Validation is green for this slice:
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Loader.pm`
  - `perl -I perl -I t/lib -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -I t/lib -c bin/fsmgen`
  - `perl -I perl -I t/lib -c t/28-extension-config-loading.t`
  - `prove -I perl -I t/lib t/27-extension-loading.t t/28-extension-config-loading.t`
  - `git diff --check`
- Immediate next direction after commit:
  - continue `R7`,
  - choose the next small typed hook boundary in the active architecture,
  - keep any future loading/config growth explicit rather than drifting toward `.plg`-style discovery.
## 2026-03-14: `R7` shipped explicit typed extension loading
- Current worktree continues `R7` by widening the first typed extension seam from programmatic object injection into an explicit module-loading path that still stays well clear of `.plg` discovery.
- Scope of this slice:
  - added [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm) to validate explicit module names, require them, instantiate them through `new()`, and reject non-object returns,
  - updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so callers may pass `extension_modules => [ ... ]` in addition to direct extension objects,
  - updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so repeated `--extension-module Module::Name` flags now load typed extensions explicitly from `@INC`,
  - added [t/lib/FSM/TestExtension/Marker.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/TestExtension/Marker.pm) and [t/27-extension-loading.t](/Users/richarddje/Documents/github/fsmgen/t/27-extension-loading.t) to lock loader, pipeline, and CLI behavior plus targeted missing-module diagnostics.
- Roadmap board update:
  - no phase status changed,
  - [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) still keeps `R7` at `in progress`,
  - `R7` `Done` / `Left` moved forward because explicit loading is no longer programmatic-only,
  - the next decision point is now whether to stay at programmatic-plus-CLI loading or add a config-file layer, and which typed hook boundary comes next.
- Validation is green for this slice:
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Loader.pm`
  - `perl -I perl -I t/lib -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -I t/lib -c bin/fsmgen`
  - `perl -I perl -I t/lib -c t/27-extension-loading.t`
  - `prove -I perl -I t/lib t/26-extension-mechanism.t t/27-extension-loading.t`
  - `git diff --check`
- Immediate next direction after commit:
  - continue `R7`,
  - decide whether explicit loading needs a config-file layer beyond direct CLI/programmatic module names,
  - then add the next small typed hook boundary.
## 2026-03-14: typed-extension docs clarified with concrete examples
- Current worktree is a doc-only follow-up to the first shipped `R7` typed extension seam.
- Scope of this slice:
  - expanded [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) with a user-facing explanation of what a typed extension is,
  - added concrete examples for result annotation and telemetry collection through the shipped `after_generate_result($context)` hook,
  - clarified in [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md) what "typed" means in this project: explicit object + method + context, not `.plg` scanning plus string-dispatch.
- Roadmap board update:
  - no roadmap status/deliverable/active-lane change for this slice,
  - the live roadmap snapshot remains unchanged.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - continue `R7`,
  - decide whether extension loading stays programmatic-only for now or gains an explicit config/CLI path,
  - then land the next small typed hook boundary.
## 2026-03-14: `R7` started with the first typed extension seam
- Current worktree starts the active `R7` lane with one real typed hook in the live pipeline instead of a broad speculative plugin rewrite.
- Scope of this slice:
  - added [perl/FSM/Extension/Registry.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Registry.pm) and [perl/FSM/Extension/Context.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Context.pm) as the first typed extension primitives,
  - updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so callers can pass `extensions => [ ... ]` and receive a live `after_generate_result($context)` callback for both FSM and composition generation paths,
  - added [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md) to define the first modern replacement boundary and its deliberate non-goals,
  - added [t/26-extension-mechanism.t](/Users/richarddje/Documents/github/fsmgen/t/26-extension-mechanism.t) to lock registry validation plus live hook dispatch across both supported source kinds.
- Roadmap board update:
  - [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) now moves `R7` from `not started` to `in progress`,
  - the active lane remains `R7`,
  - the next decision point is now whether the next extension step stays programmatic-only or adds an explicit config/CLI loading path, and which typed hook boundary should come next.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Extension/Context.pm`
  - `perl -I perl -c perl/FSM/Extension/Registry.pm`
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c t/26-extension-mechanism.t`
  - `prove -I perl t/26-extension-mechanism.t`
  - `git diff --check`
- Immediate next direction after commit:
  - continue `R7`,
  - decide whether to keep extension loading programmatic-only for now or add an explicit config/CLI path,
  - then land the next small typed hook boundary without reopening `.plg` / `PPlugin` semantics.
## 2026-03-14: `R6` shipped `C6` and closed the scoped composition lane
- Current worktree finishes the last bounded `R6` acceptance slice by making the remaining out-of-scope legacy composition shapes fail explicitly and consistently.
- Scope of this slice:
  - tightened `FSM::Composition::Parser` boundary messages for legacy macro/plugin children and the remaining reachable out-of-scope legacy parser shapes,
  - added `t/25-composition-legacy-scope-errors.t` to lock parser/pipeline/CLI behavior for those scope-boundary failures.
- Roadmap board update:
  - `ROADMAP_STATUS.md` now moves `R6` from `mostly done` to `done`,
  - the active lane moves from `R6` to `R7`,
  - the `.rtlif` follow-up remains recorded as a future refinement note, not an `R6` blocker.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Composition/Parser.pm`
  - `perl -I perl -c t/25-composition-legacy-scope-errors.t`
  - `prove -I perl t/25-composition-legacy-scope-errors.t`
  - `prove -I perl t/14-composition-parser.t t/13-composition-source-classification.t`
  - `prove -I perl t`
- Immediate next direction after commit:
  - continue on `R7`,
  - define the replacement typed hook/extension mechanism without reviving `.plg` / `PPlugin`.
## 2026-03-14: `R6` shipped `C5` width-mismatch diagnostics
- Current worktree tightens the composition diagnostic boundary rather than widening the language surface again.
- Scope of this slice:
  - explicit `?toplink` width mismatches are now locked by focused regression,
  - declared connect-by-name width mismatches now name both endpoints and both widths directly.
- Roadmap board update:
  - `ROADMAP_STATUS.md` now moves `R6` from `in progress` to `mostly done`,
  - the active lane remains `R6`,
  - the current next decision point is now `C6` explicit failure for out-of-scope legacy composition constructs,
  - the `.rtlif` follow-up remains recorded explicitly on the roadmap board.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c t/23-composition-errors.t`
  - `perl -I perl -c t/24-composition-connect-by-name.t`
  - `prove -I perl t/23-composition-errors.t t/24-composition-connect-by-name.t`
  - `prove -I perl t`
- Immediate next direction after commit:
  - continue `R6` with `C6`,
  - make remaining out-of-scope legacy composition constructs fail explicitly and consistently.
## 2026-03-14: user-guide clarification for realistic `=name` usage
- Current worktree is a doc-only follow-up to the shipped `C4` lane.
- Scope of this slice:
  - expanded `docs/USER_GUIDE.md` with realistic `=name` patterns rather than only a synthetic minimal example,
  - added one child-FSM output passthrough example, one child-input passthrough example, and one external-RTL output passthrough example,
  - added practical guidance about when to prefer `=name` versus explicit `?toplink`.
- Roadmap board update:
  - no roadmap status/deliverable/active-lane change for this slice,
  - the live roadmap snapshot remains unchanged.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - continue the active `R6` lane at `C5`,
  - tighten width-mismatch diagnostics across explicit and declared-by-name endpoints.
## 2026-03-14: `R6` first shipped `C4` declared connect-by-name lane
- Current worktree widens the shipped composition runtime from explicit-link-only lanes into the first declared connect-by-name slice.
- Scope of this slice:
  - typed composition ports now preserve explicit connect-by-name intent via `=name` declarations inside `?ports`,
  - `FSM::Pipeline::HDLGenerator` now recognizes a dedicated `C4` lane and synthesizes by-name links from those declarations,
  - the first shipped `C4` behavior is top-port only and requires exactly one same-named child endpoint with the same direction and width.
- Regression coverage update:
  - tightened `t/14-composition-parser.t` so `=port` parser shape and `binding_mode` preservation are now locked,
  - added `t/24-composition-connect-by-name.t` for the shipped `C4` success path plus ambiguous-match and no-match failures.
- Roadmap board update:
  - `ROADMAP_STATUS.md` still keeps `R6` at `in progress`,
  - `R6` `Done` now includes the first shipped `C4` declared connect-by-name slice,
  - the current next decision point is now `C5` width-mismatch diagnostics,
  - and the `.rtlif` follow-up is now recorded explicitly in the board so we do not forget to document exact grammar and revisit the stronger interface-source contract question later.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Composition/Port.pm`
  - `perl -I perl -c perl/FSM/Composition/Parser.pm`
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c t/14-composition-parser.t`
  - `perl -I perl -c t/24-composition-connect-by-name.t`
  - `prove -I perl t/14-composition-parser.t t/20-composition-single-fsm-top.t t/21-composition-two-fsm-linking.t t/22-composition-fsm-plus-rtl.t t/23-composition-errors.t t/24-composition-connect-by-name.t`
  - `prove -I perl t`
- Immediate next direction after commit:
  - move to `C5`,
  - tighten width-mismatch diagnostics across explicit and declared-by-name endpoints.
## 2026-03-14: `R6` first shipped `C3` mixed FSM-plus-RTL lane
- Current worktree widens the shipped composition runtime from FSM-only linking into the first mixed external-RTL lane.
- Scope of this slice:
  - added `FSM::Composition::RTLInterfaceLoader` as the first modern external-RTL interface loader,
  - external RTL interface metadata now comes from a sidecar `<module>.rtlif` artifact searched beside the composition source and through existing `FSMLIB` roots,
  - updated `FSM::Pipeline::HDLGenerator` so `?rtl` children are realized instead of rejected and mixed `?fsmc` + `?rtl` tops plan through a dedicated `C3` lane,
  - kept the composition boundary truthful by instantiating the external RTL child without regenerating its internals.
- Regression coverage update:
  - added `t/22-composition-fsm-plus-rtl.t` for the shipped `C3` success path and CLI generation,
  - extended `t/23-composition-errors.t` so mixed composition now locks unknown external-port and direction-mismatch diagnostics as well as duplicate-driver rejection.
- Roadmap board update:
  - `ROADMAP_STATUS.md` still keeps `R6` at `in progress`,
  - `R6` `Done` now includes the first shipped `C3` mixed external-RTL lane,
  - the current next decision point is now `C4` declared connect-by-name, not more external-interface loading groundwork.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Composition/RTLInterfaceLoader.pm`
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c t/22-composition-fsm-plus-rtl.t`
  - `perl -I perl -c t/23-composition-errors.t`
  - `prove -I perl t/20-composition-single-fsm-top.t t/21-composition-two-fsm-linking.t t/22-composition-fsm-plus-rtl.t t/23-composition-errors.t`
  - `prove -I perl t`
- Immediate next direction after commit:
  - move to `C4`,
  - define the first narrow declared connect-by-name rule beyond the current explicit-link-only composition lanes.
## 2026-03-14: `R6` first shipped `C2` FSM-linking lane
- Current worktree widens the shipped composition runtime from single-child passthrough into the first explicit multi-child FSM-linking lane.
- Scope of this slice:
  - added `FSM::Composition::Net` and extended the typed runtime plan so multi-child tops can carry deterministic internal-net and binding data,
  - updated `FSM::Pipeline::HDLGenerator` to choose between `C1` and `C2` planning lanes,
  - shipped `C2` support for multiple embedded `?fsmc` children with explicit `?toplink` endpoint resolution using top-port names and `instance.port` child endpoints,
  - added exact source/target role checks, exact width checks, deterministic internal-net naming, deterministic instance order preservation, and duplicate-driver rejection,
  - kept the active child-interface contract truthful by continuing to auto-wire only the shared `clk` / `rstn` system inputs and requiring explicit wiring for other child ports.
- Regression coverage update:
  - tightened `t/14-composition-parser.t` so dotted `instance.port` endpoints in `?toplink` are now locked explicitly,
  - added `t/21-composition-two-fsm-linking.t` for the shipped `C2` success path and CLI generation,
  - added `t/23-composition-errors.t` for duplicate-driver diagnostics.
- Roadmap board update:
  - `ROADMAP_STATUS.md` still keeps `R6` at `in progress`,
  - `R6` `Done` now includes the first shipped `C2` FSM-only linking lane,
  - the current next decision point is now `C3` mixed `?fsmc` + `?rtl` realization, not more FSM-only multi-child groundwork.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Composition/Net.pm`
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c t/21-composition-two-fsm-linking.t`
  - `perl -I perl -c t/23-composition-errors.t`
  - `prove -I perl t/13-composition-source-classification.t t/14-composition-parser.t t/20-composition-single-fsm-top.t t/21-composition-two-fsm-linking.t t/23-composition-errors.t` (`Files=5`, `Tests=120`, `PASS`)
  - `prove -I perl t`
- Immediate next direction after commit:
  - move to `C3`,
  - add `?rtl` child realization with declared interface metadata and mixed `?fsmc` + `?rtl` planning/emission.
## 2026-03-14: `R6` first shipped `C1` composition lane
- Current worktree moves `R6` from parser/planning groundwork into the first real shipped composition runtime slice.
- Scope of this slice:
  - added typed composition planning/runtime packages: `Port`, `Link`, `Plan`, and `RealizedInstance`,
  - updated `FSM::Composition::Parser` so `?ports` and `?toplink` payloads are now stored as typed port/link objects instead of raw payloads,
  - updated `FSM::Pipeline::HDLGenerator` so `?top:name` can now realize one embedded `?fsmc` child, build a typed `C1` plan, validate explicit top-port exposure, and emit a generated top module,
  - captured the realized child interface as typed ports,
  - matched the active child-generator contract truthfully by treating `clk` / `rstn` as implicit system inputs and requiring user-facing child ports to be explicitly exposed by the child FSM itself.
- Regression coverage update:
  - added `t/20-composition-single-fsm-top.t` to lock the first end-to-end composition acceptance slice through pipeline, plan, HDL text, and CLI output,
  - the fixture was tightened so the child FSM explicitly exposes `output_data` as an output, which matches the current active FSM pipeline contract instead of inventing a looser composition rule.
- Roadmap board update:
  - `ROADMAP_STATUS.md` still keeps `R6` at `in progress`,
  - `R6` `Done` now includes the first shipped `C1` realization/top-emission lane,
  - the current next decision point is now `C2`-style multi-child planning plus typed `?toplink`/net resolution, not more single-child boundary work.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Composition/RealizedInstance.pm`
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c t/20-composition-single-fsm-top.t`
  - `prove -I perl t/13-composition-source-classification.t t/14-composition-parser.t t/20-composition-single-fsm-top.t` (`Files=3`, `Tests=79`, `PASS`)
  - `prove -I perl t`
- Immediate next direction after commit:
  - widen from shipped `C1` to `C2`,
  - add multi-child top planning, typed explicit `?toplink`/net resolution, deterministic instance ordering, and duplicate-driver diagnostics.
## 2026-03-14: `R6` legacy mapping note plus first typed `?top` parser/IR slice
- Current worktree continues `R6` by turning the composition boundary into a real typed parser seam instead of only a classifier/error seam.
- Scope of this slice:
  - added `docs/COMPOSITION_LEGACY_MAPPING.md` to capture the obsolete `fx/bin/fsmgen` composition call tree (`start_from_file` -> `fsm_initialize` -> `top_exec`) and map legacy concepts onto the active architecture,
  - documented the main historical lesson: keep `?top`, `?fsmc`, `?rtl`, `?ports`, and `?toplink` as language ideas, but do not revive the old `AUTOLOAD` / `PPlugin` / `.plg` mechanism,
  - added typed composition packages under `perl/FSM/Composition/` for the first active parser boundary: `Spec`, `Top`, `Instance`, `PortsBlock`, `TopLink`, and `Parser`,
  - `FSM::Pipeline::HDLGenerator` now parses `?top:name` through `FSM::Composition::Parser` before failing at the still-unimplemented realization/emission stage,
  - the parser now recognizes typed child-block structure for `?fsmc`, `?rtl`, `?ports`, and `?toplink`,
  - explicit unsupported legacy residue is now called out truthfully:
    - inline top-port shorthand under `?top:name`,
    - multi-source `?fsmc`,
    - nested `?top`,
    - and unknown child kinds.
- Regression coverage update:
  - `t/13-composition-source-classification.t` now proves the pipeline boundary happens after typed composition parsing and points at both composition docs,
  - added `t/14-composition-parser.t` to lock typed parsing of real and synthetic `?top` inputs plus explicit rejection of unsupported legacy residue.
- Roadmap board update:
  - `ROADMAP_STATUS.md` still keeps `R6` at `in progress`,
  - `R6` `Done` now includes the first typed composition parser/IR slice and the legacy-to-modern mapping note,
  - the current next decision point is now the first child-realization/top-planning lane for `C1`, not another parser-only slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Composition/Spec.pm`
  - `perl -I perl -c perl/FSM/Composition/Top.pm`
  - `perl -I perl -c perl/FSM/Composition/Instance.pm`
  - `perl -I perl -c perl/FSM/Composition/PortsBlock.pm`
  - `perl -I perl -c perl/FSM/Composition/TopLink.pm`
  - `perl -I perl -c perl/FSM/Composition/Parser.pm`
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c t/14-composition-parser.t`
  - `prove -I perl t/13-composition-source-classification.t t/14-composition-parser.t` (`Files=2`, `Tests=38`, `PASS`)
- Immediate next direction after commit:
  - define typed parsing/planning for explicit `?ports` / `?toplink` payloads instead of storing them as raw items,
  - then implement the first `C1` realization path: one `?top:name`, one `?fsmc` child, explicit top-port exposure, and deterministic top planning.
## 2026-03-14: `R6` composition source-classification boundary slice
- Current worktree lands the first executable composition-aware code path in the active architecture without claiming full composition support yet.
- Scope of this slice:
  - added `perl/FSM/SourceClassifier.pm` as the shared top-level source-kind classifier for raw Lispish ASTs,
  - `perl/FSM/Pipeline/HDLGenerator.pm` now classifies source kind before adapter parsing and rejects `?top:name` with an explicit composition-boundary diagnostic,
  - `perl/FSM/Adapter/FSMGenFull/Parser.pm` now also rejects `?top:name` with a composition-specific FSM-only-parser error for direct callers,
  - added `t/13-composition-source-classification.t` to lock classification of `?fsm:name` vs `?top:name` and the user-facing failure mode through pipeline, adapter, and CLI,
  - tightened `t/01-regression.t` so the broad sample compile sweep now covers only active FSM-root sources and no longer treats composition-shaped fixtures as supported single-FSM inputs,
  - retargeted `t/09-ast-first-intermediate-registry.t` and `t/10-ast-first-enable-structure.t` from the legacy composition sample `fsm/trial_1.fsm` to the real FSM-root sample `fsm/lte_dif_pmaster.fsm`.
- Roadmap board update:
  - `ROADMAP_STATUS.md` still keeps `R6` at `in progress`,
  - `R6` `Done` now includes explicit top-level source classification plus deliberate composition-boundary failure,
  - the current `R6` next decision point is now the first typed composition parser/IR slice for `?top:name` contents (`?ports`, `?fsmc`, `?rtl`, `?toplink`).
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/SourceClassifier.pm`
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c t/01-regression.t`
  - `prove -I perl t/01-regression.t`
  - `prove -I perl t/13-composition-source-classification.t` (`Files=1`, `Tests=14`, `PASS`)
- Immediate next direction after commit:
  - build the first typed composition parser/IR objects for `?top:name` contents rather than only classifying the root,
  - start the first executable acceptance slice from `docs/COMPOSITION_SCOPE.md`, likely `C1` around a single `?fsmc` child and explicit top-port exposure.
## 2026-03-14: Roadmap phase transition (`R2` done, active lane -> `R3`)
- Current worktree is a roadmap-state update driven by an ownership-boundary audit, not by another code move.
- Audit result:
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` no longer directly owns `assignment_analysis` / `lhs_assignments` mutation or analysis,
  - the remaining backend pocket is runtime AST recovery/filtering, dependency rescue/topological ordering, and emitted-signal rendering flow,
  - that matches the `R2` deliverables currently stated in `ROADMAP_STATUS.md`.
- Roadmap transition recorded in `ROADMAP_STATUS.md`:
  - `R2` moved from `in progress` to `done`,
  - the current active lane switched to `R3` (`AST/CoreAST-first runtime convergence`),
  - `R3` next decision point is now the remaining runtime-AST-miss / compatibility-parse fallback residue in `Backend::SystemVerilog`.
- Validation is green for this slice:
  - `git diff --check`
  - `rg -n "resolve_intermediate_signal_runtime_ast|should_filter_ast_based|should_filter_runtime_ast_miss|topologically_sort_signals|generate_consolidated_intermediate_signals" perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - backend audit confirms no remaining `assignment_analysis` / `lhs_assignments` matches in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
- Immediate next direction after commit:
  - follow `R3` and re-audit the remaining compatibility/runtime-AST-miss fallback paths,
  - remove them where they are no longer justified, or keep them explicitly as deliberate residue if they still serve a necessary boundary.
## 2026-03-14: Roadmap phase transition (`R3` done, active lane -> `R6`)
- Current worktree closes the `R3` runtime-convergence lane after removing the last implicit stored-expression runtime-AST promotion path from normal backend resolution.
- Audit result:
  - `resolve_intermediate_signal_runtime_ast(...)` no longer parses stored expressions directly,
  - the only remaining string reconstruction in this area is explicit miss-recovery parsing in `recover_runtime_ast_from_dependency_expression(...)` plus the owner-side compatibility parser in `EnableGraph` for legacy registry/global-expression entries,
  - that matches the `R3` exit criteria because compatibility residue is now narrow, explicit, and justified rather than being part of the default runtime path.
- Roadmap transition recorded in `ROADMAP_STATUS.md`:
  - `R3` moved from `mostly done` to `done`,
  - the current active lane switched to `R6` (`Composition-oriented language / architecture work`),
  - `R6` next decision point is now to define concrete active-architecture scope and acceptance tests before implementation.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` (`Files=1`, `Tests=21`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=413`, `PASS`)
- Immediate next direction after commit:
  - start `R6` with a scope-definition slice grounded in the active `bin/fsmgen` architecture,
  - write acceptance tests and developer-facing scope notes before implementing composition behavior.
## 2026-03-14: Composition scope-definition slice (`R6` enters `in progress`)
- Current worktree starts the first concrete `R6` slice by defining composition scope for the active architecture instead of leaving it as roadmap shorthand.
- Scope of this slice:
  - added `docs/COMPOSITION_SCOPE.md` as the normative scope and acceptance-boundary document for the first composition lane,
  - grounded the scope in the active pipeline boundary: `bin/fsmgen` -> `FSM::Pipeline::HDLGenerator` -> `FSM::Adapter::FSMGenFull::Parser`, which currently only supports `?fsm:name` / `+fsm`,
  - defined the first supported composition source model around `?top:name`, `?fsmc`, `?rtl`, `?ports`, and `?toplink`,
  - defined the first executable acceptance matrix (`C1`..`C6`) plus the planned focused composition test-file split.
- Roadmap board update:
  - `ROADMAP_STATUS.md` now marks `R6` as `in progress`,
  - `R6` deliverables now explicitly include acceptance-matrix definition as a tracked sub-deliverable,
  - the active-lane next step is now implementation of the first typed composition classifier/parser slice rather than more scope discovery.
- Validation is green for this slice:
  - `git diff --check`
  - `rg -n "COMPOSITION_SCOPE\\.md|\\?top:name|\\?fsmc|\\?rtl|\\?ports|\\?toplink|R6.*in progress|Composition-oriented language" README.md docs/USER_GUIDE.md docs/COMPOSITION_SCOPE.md ROADMAP_STATUS.md MEMORY.md CHANGES.md DEVELOPMENT_NOTES.md`
- Immediate next direction after commit:
  - implement the first typed composition source classifier above the existing FSM-only parser,
  - then add the first executable composition acceptance tests from `docs/COMPOSITION_SCOPE.md`.
## 2026-03-14: AST/CoreAST convergence micro-slice (remove render-time late hydration)
- Current worktree continues the `R3` runtime convergence lane and narrows one compatibility behavior inside `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Scope of this slice:
  - removed the render-time “late hydration” retry from `render_intermediate_signal_expression(...)`, so an initial `no_ast_source` miss no longer silently promotes `runtime_ast` during plain expression rendering,
  - kept the explicit runtime-AST-miss dependency-recovery path intact, so cleaned compatibility expressions can still recover dependencies when that fallback is intentionally invoked,
  - fixed `resolve_intermediate_signal_width(...)` so the explicit recovery path can call it with the shorter live form used by the backend.
- Regression coverage update:
  - `t/07-runtime-ast-miss-dependency-recovery.t` now proves that render-time expression fallback preserves the original `no_ast_source` miss state and does not silently hydrate `runtime_ast`,
  - the same test now proves that explicit dependency recovery can still promote `runtime_ast` from a cleaned compatibility expression and records that source as `dependency_cleaned_rendered_expression_ast`.
- Roadmap board update:
  - `ROADMAP_STATUS.md` still keeps `R3` at `mostly done`,
  - `R3` `Done` / `Left` now reflect that late hydration is gone and the remaining residue is the direct raw/cleaned expression parsing inside runtime-AST resolution and dependency recovery.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` (`Files=1`, `Tests=17`, `PASS`)
- Immediate next direction after commit:
  - re-audit the remaining direct compatibility parsing inside `resolve_intermediate_signal_runtime_ast(...)` and `recover_runtime_ast_from_dependency_expression(...)`,
  - decide whether that residue can be removed, replaced with native AST/CoreAST data, or kept explicitly as the final compatibility boundary.
## 2026-03-14: AST/CoreAST convergence micro-slice (remove direct stored-expression runtime parse)
- Current worktree continues the `R3` runtime convergence lane and removes the direct stored-expression compatibility parse from normal backend runtime-AST resolution.
- Scope of this slice:
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm::resolve_intermediate_signal_runtime_ast(...)` no longer parses `signal_info->{expression}` directly,
  - stored-expression-only runtime-AST resolution now records `no_ast_source` and leaves recovery to the explicit runtime-AST-miss path instead of synthesizing `parsed_expression_ast` / `cleaned_expression_ast`,
  - `t/07-runtime-ast-miss-dependency-recovery.t` now proves the removed implicit path and keeps explicit cleaned-expression recovery covered.
- Roadmap board update:
  - this slice closes the remaining `R3` ambiguity around implicit runtime string parsing,
  - `ROADMAP_STATUS.md` now marks `R3` as `done` and pivots the active lane to `R6`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` (`Files=1`, `Tests=21`, `PASS`)
- Immediate next direction after commit:
  - move to `R6` and define the composition-oriented scope and acceptance boundary before implementation.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph live-usage evidence ownership)
- Current worktree continues the `R2` live ownership lane and moves intermediate-signal live-usage evidence derivation under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `ast_contains_signal(...)`,
  - `EnableGraph` now also owns `is_signal_referenced_in_substitutions(...)`, `is_signal_actually_used_in_final_expressions(...)`, and `resolve_intermediate_signal_live_usage(...)`,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now consumes that owner-provided live-usage metadata directly during consolidated intermediate-signal filtering and no longer exposes the owner-side evidence helpers itself.
- Regression coverage update:
  - `t/10-ast-first-enable-structure.t` now asserts that the backend stays free of the former live-usage evidence helper pocket,
  - the same test now asserts that `EnableGraph` owns AST signal-reference inspection, substituted-expression/final-expression usage evidence, and cached live-usage metadata derivation on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=176`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=400`, `PASS`)
- Immediate next direction after commit:
  - re-audit the remaining backend filtering decision logic around consolidated intermediate-signal emission,
  - move only the pieces that are truly synthesis/analysis ownership, not backend-local factorization or rendering.
## 2026-03-14: Live status visibility hardening
- Current worktree tightens the roadmap-status workflow so status changes are both persistent and visible at close-out time.
- Scope of this slice:
  - `ROADMAP_STATUS.md` now explicitly requires three actions whenever any workstream status or the active lane changes: refresh the board, log the change in `CHANGES.md`, and display the current live status snapshot in the user-facing close-out,
  - `COMMIT.md` and `.agents/workflows/commit.md` now treat status-transition logging plus close-out display as part of the standard post-task workflow,
  - `MEMORY.md` now records this as a non-negotiable workflow rule for future sessions.
- Validation is green for this slice:
  - `git diff --check`
  - `rg -n "live status|status snapshot|ROADMAP_STATUS\\.md|CHANGES\\.md" ROADMAP_STATUS.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md`
- Immediate next direction after commit:
  - whenever a workstream status or active lane changes, refresh `ROADMAP_STATUS.md`, record the transition in `CHANGES.md`, and show the current live snapshot in the close-out,
  - continue using `ROADMAP_STATUS.md` as the canonical current-state board and `CHANGES.md` as the historical log of status transitions.
## 2026-03-14: Roadmap deliverables hardening
- Current worktree tightens the roadmap board so each `Rx` phase has explicit deliverables, not just status labels.
- Scope of this slice:
  - `ROADMAP_STATUS.md` now requires each workstream to state `Deliverables`, `Status`, `Done`, `Left`, and `Exit criteria`,
  - the status-scale definitions are now tied directly to deliverable completion, so `done` means all listed deliverables are complete and the exit criteria are met,
  - each current `R0`..`R7` workstream now has concrete deliverables written out in the board itself.
- Validation is green for this slice:
  - `git diff --check`
  - `rg -n "^Deliverables:|roadmap deliverables|All listed `Deliverables`" ROADMAP_STATUS.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md`
- Immediate next direction after commit:
  - keep workstream deliverables explicit and current whenever the roadmap interpretation changes,
  - use those deliverables, not narrative intuition, when deciding whether a phase is `done`, `mostly done`, `in progress`, or `not started`.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph substitution synchronization ownership)
- Current worktree continues the `R2` live ownership lane and moves substitution-era AST rewrite/debug passes under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `count_unary_negations_in_original_expressions(...)`,
  - `EnableGraph` now also owns `update_original_asts_with_substituted_versions(...)` and `update_original_asts_with_second_pass_substitutions(...)`, plus a shared context-to-AST map helper for the two update passes,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now routes first-pass substitution synchronization and the surrounding unary-negation debug scans through `enable_graph`,
  - `perl/FSM/HDL/Factorization/Fixpoint.pm` now routes second-pass substitution synchronization through `enable_graph` instead of the backend.
- Regression coverage update:
  - `t/10-ast-first-enable-structure.t` now asserts that the backend stays free of the former substitution-update/debug helper pocket,
  - the same test now asserts that `EnableGraph` owns the unary-negation debug scan plus first-pass and second-pass substitution synchronization on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=168`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=392`, `PASS`)
- Immediate next direction after commit:
  - re-audit the remaining backend-side filtering and live-usage checks around consolidated intermediate-signal emission,
  - move only the pieces that are truly synthesis/analysis ownership, not backend-local factorization or rendering.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph factorization AST-feed ownership)
- Current worktree continues the `R2` live ownership lane and moves factorization input feeding under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `feed_asts_to_factorizer(...)`,
  - `EnableGraph` now also owns `feed_current_asts_to_second_pass(...)` plus the second-pass intermediate-signal eligibility helpers `ast_contains_intermediate_signals(...)` and `ast_has_intermediate_signals_recursive(...)`,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now calls `enable_graph->feed_asts_to_factorizer(...)` during primary factorization and no longer exposes those feeders/helpers itself,
  - `perl/FSM/HDL/Factorization/Fixpoint.pm` now routes second-pass AST collection through `enable_graph` instead of the backend.
- Regression coverage update:
  - `t/10-ast-first-enable-structure.t` now asserts that the backend stays free of the former factorization-feed helper pocket,
  - the same test now asserts that `EnableGraph` owns first-pass AST feeding, second-pass AST feeding, and second-pass intermediate-signal eligibility checks on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=162`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=386`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether the remaining substitution-update/debug passes over `assignment_analysis` and captured condition ASTs still belong in the backend,
  - move only the pieces that are truly synthesis/analysis ownership, not backend-local factorization or rendering.
## 2026-03-14: Roadmap tracking infrastructure hardening
- Current worktree establishes a canonical live roadmap board so status can be checked precisely at any time without reconstructing it from narrative history.
- Scope of this slice:
  - added `ROADMAP_STATUS.md` as the canonical four-state board (`done`, `mostly done`, `in progress`, `not started`),
  - recorded the current baseline workstreams, current active lane, and exact “done vs left” summaries there,
  - updated `README.md`, `MEMORY.md`, `COMMIT.md`, and `.agents/workflows/commit.md` so this board is part of the normal repo workflow rather than optional documentation.
- Validation is green for this slice:
  - `git diff --check`
  - `rg -n "ROADMAP_STATUS\.md" README.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md`
- Immediate next direction after commit:
  - keep `ROADMAP_STATUS.md` updated before every commit whenever a task changes status, remaining work, or the active lane,
  - continue using it as the primary answer source for “how much is done?” instead of reconstructing status ad hoc from `CHANGES.md` / `DEVELOPMENT_NOTES.md`.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph logical-op counting ownership)
- Current worktree continues the live ownership lane and moves binary logical-operation counting under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `count_binary_logical_operation_occurrences(...)`,
  - the same owner now also holds the supporting AST collection and traversal helpers used by that pass (`collect_all_wen_en_ast_expressions(...)`, `_count_logical_ops_in_ast(...)`, `_is_factorizable_sub_expression(...)`),
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` now routes step 4 directly through `enable_graph`,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now relies on `enable_graph` for the fallback recount inside global AST factorization and no longer exposes the former counting entrypoints.
- Regression coverage update:
  - `t/10-ast-first-enable-structure.t` now asserts that the backend stays free of the logical-op counting helper pocket,
  - the same test now asserts that `EnableGraph` owns binary logical-operation counting on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=155`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=379`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether any remaining backend stage still analyzes `assignment_analysis` or other `EnableGraph`-owned enable structures instead of doing backend-local factorization/rendering,
  - if that lane is now exhausted, pivot to the next truthful runtime seam rather than continuing owner-churn on the same edge.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph WEN/EN prescan ownership)
- Current worktree continues the live ownership lane and moves WEN/EN intermediate-signal prescan under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `prescan_wen_en_for_intermediate_signals(...)`,
  - the prescan now walks `EnableGraph`-owned `assignment_analysis` and the AST-backed DT/LHS enable structures from the same owner that already owns `track_ast_intermediate_signals(...)`,
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` now routes step 5 directly through `enable_graph`,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` no longer exposes the former backend-side prescan entrypoint.
- Regression coverage update:
  - `t/10-ast-first-enable-structure.t` now asserts that the backend stays free of `prescan_wen_en_for_intermediate_signals(...)`,
  - the same test now asserts that `EnableGraph` owns WEN/EN intermediate-signal prescan on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=150`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=374`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether any remaining backend stage still performs live analysis over `assignment_analysis` or other synthesis-owned enable structures instead of rendering or backend-local factorization work,
  - if that lane is exhausted, pivot to the next truthful runtime seam instead of continuing owner-churn.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph state register planning)
- Current worktree continues the same live synthesis ownership lane and moves state-structure planning under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `build_state_register_plan(...)`,
  - that plan now decides whether state registers exist at all, the regular-state encoding order, state-bit width, and the reset-state localparam name,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now renders state encoding and state-register HDL from that owner-provided plan instead of recomputing regular-state structure locally,
  - `build_internal_signal_declaration_plan(...)` and `get_fsm_reset_state(...)` now also reuse the same state plan instead of maintaining separate regular-state scans.
- Regression coverage update:
  - `t/11-flatteneddt-generation-reset.t` now inspects the state plan for standalone-DT-only FSMs and locks that reused generators keep state-register planning disabled there,
  - `t/12-enablegraph-capture-registry.t` now inspects the state plan for a regular-state FSM and locks reset-state selection plus encoding order,
  - `t/10-ast-first-enable-structure.t` now asserts that `EnableGraph` owns state register planning on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t t/11-flatteneddt-generation-reset.t t/12-enablegraph-capture-registry.t` (`PASS`)
  - `prove -I perl t` (`PASS`)
- Immediate next direction after commit:
  - re-audit whether any remaining backend stage still computes synthesis-domain structure instead of rendering an owner-provided plan,
  - if the planning/rendering lane is now thin, pivot to the next truthful live runtime seam instead of stretching it artificially.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph module declaration planning)
- Current worktree continues the same live synthesis ownership lane and moves module/interface declaration planning under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `build_module_declaration_plan(...)`,
  - that plan now decides live interface-port shape from synthesis-owned signal classification, including base ports, input vs output direction, `reg` vs `wire` storage, signal widths, and the derived `declared_port_signals` / `port_directions` registries,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now only renders the returned plan instead of re-deriving interface decisions from synthesis metadata locally.
- Regression coverage update:
  - `t/03-assignment-intent-metadata.t` now inspects the live module declaration plan directly and locks representative input/output ownership for `B`, `D`, `G`, `J`, `L`, `next_I`, and `K_r`,
  - `t/05-assignment-hdl-snapshots.t` stayed green after restoring the exact legacy `output reg  ...` port-spacing contract in the backend renderer,
  - `t/10-ast-first-enable-structure.t` now asserts that `EnableGraph` owns module declaration planning on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/05-assignment-hdl-snapshots.t` (`Files=1`, `Tests=12`, `PASS`)
  - `prove -I perl t/03-assignment-intent-metadata.t t/10-ast-first-enable-structure.t` (`Files=2`, `Tests=242`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=364`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether any remaining backend emission stage still mixes synthesis-domain planning with rendering,
  - if this declaration-planning seam is now exhausted, pivot to the next truthful live runtime seam instead of forcing another interface-only move.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph internal declaration planning)
- Current worktree pivots from wrapper-only convergence to the next real live synthesis seam: internal declaration planning.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `build_internal_signal_declaration_plan(...)`,
  - that plan now decides, from live `assignment_analysis`, which internal regs and aux helper regs must exist (`I_next`, `K_q`, pulse-delay pipes, etc.),
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now only renders the returned plan instead of re-deriving declaration decisions itself from synthesis metadata.
- Regression coverage update:
  - `t/03-assignment-intent-metadata.t` now inspects the live declaration plan directly and locks the expected helper declarations for dual-output and pulse-delay families,
  - `t/10-ast-first-enable-structure.t` now asserts that `EnableGraph` owns internal declaration planning on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/03-assignment-intent-metadata.t t/10-ast-first-enable-structure.t` (`Files=2`, `Tests=224`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=346`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether any other backend emission steps still make synthesis-domain planning decisions that now belong in `EnableGraph`,
  - if not, pivot to the next truthful live runtime seam instead of continuing declaration-planning convergence.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph unified WEN/EN emission)
- Current worktree continues the same enable-synthesis ownership lane and removes the remaining stage-7 backend wrapper around unified WEN/EN emission.
- Scope of this slice:
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` now calls `enable_graph->generate_unified_wen_en_signals(...)` directly in step 7,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` no longer exposes the wrapper-only `generate_wen_en_signals(...)` entrypoint,
  - the live emission owner is now consistent with the existing implementation owner in `perl/FSM/Synthesis/EnableGraph.pm`.
- Architecture guard update in `t/10-ast-first-enable-structure.t`:
  - the backend is now asserted to stay free of `generate_wen_en_signals(...)`,
  - the live `EnableGraph` object is asserted to own `generate_unified_wen_en_signals(...)`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=145`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=337`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether any other active generation stage is still only a routing wrapper around `EnableGraph` ownership,
  - if that lane is now exhausted, pivot to the next truthful live runtime seam instead of continuing wrapper-only convergence.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph top-level enable emission)
- Current worktree continues the same enable-synthesis lane and moves top-level state/DT enable emission under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `generate_enable_conditions(...)`,
  - that method emits the top-level `state_enables` / `dt_enables` registries that `EnableGraph` already initializes and now stores as AST-backed conditions,
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` now calls `enable_graph->generate_enable_conditions(...)`,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` no longer exposes the old top-level enable-emission entrypoint.
- Architecture guard update in `t/10-ast-first-enable-structure.t`:
  - the live backend is now asserted to stay free of `generate_enable_conditions(...)`,
  - the live `EnableGraph` object is asserted to own that emission entrypoint.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t t/12-enablegraph-capture-registry.t` (`Files=2`, `Tests=164`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=335`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether any other live top-level enable/declaration emission still sits on the backend side while the owning synthesis semantics already live in `EnableGraph`,
  - if that lane is now exhausted, pivot to the next truthful live runtime seam instead of stretching enable-emission ownership further.
## 2026-03-13: FlattenedDT AST-first live micro-slice (AST-backed top-level enable registries)
- Current worktree pivots slightly away from the shrinking `Orchestrator` seam and hardens the next real live AST/CoreAST-first boundary: top-level `state_enables` / `dt_enables`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `build_state_enable_condition_ast(...)` and `build_dt_enable_condition_ast(...)`,
  - `initialize_state_and_dt_enable_conditions(...)` now stores AST-backed enable conditions in the live top-level registries instead of plain strings,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now renders those top-level enable conditions from AST objects when emitting the `*_en` assigns.
- Regression coverage update:
  - `t/10-ast-first-enable-structure.t` now asserts the top-level `state_enables` / `dt_enables` registries are populated with AST-backed conditions,
  - `t/11-flatteneddt-generation-reset.t` now asserts reused generators keep standalone DT enable entries AST-backed across runs and still render as `1'b1`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t t/11-flatteneddt-generation-reset.t` (`Files=2`, `Tests=158`, `PASS`)
  - `prove -I perl t/12-enablegraph-capture-registry.t` (`Files=1`, `Tests=21`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=333`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether any other live top-level enable/declaration registries are still string-backed without a real semantic reason,
  - if not, pivot away from registry-shape work and choose the next truthful live runtime seam elsewhere in the active generation flow.
## 2026-03-13: FlattenedDT live ownership micro-slice (EnableGraph test-condition AST ownership)
- Current worktree continues the same live `Orchestrator` / `EnableGraph` seam and moves the remaining test-node condition AST construction under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `build_test_condition_ast(...)`,
  - that helper now centralizes `signal == value` AST construction for `FSM::CoreAST::TestNode` branches by combining the test signal ref with the already-owner-local `convert_test_value_to_ast(...)` path,
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` no longer constructs test-branch equality ASTs inline inside `flatten_decision_tree(...)`.
- Regression coverage update in `t/12-enablegraph-capture-registry.t`:
  - the fixture now exercises a real `?MODE` test node,
  - capture-registry assertions inspect the pre-factorization phase immediately after `flatten_all_decision_trees(...)`,
  - the test now locks that both assignment and transition capture preserve the expected `MODE == 1'b1` condition AST before later factorization rewrites it into an intermediate signal ref during full generation.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t/12-enablegraph-capture-registry.t` (`Files=1`, `Tests=21`, `PASS`)
  - `prove -I perl t/10-ast-first-enable-structure.t t/12-enablegraph-capture-registry.t` (`Files=2`, `Tests=160`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=327`, `PASS`)
- Immediate next direction after commit:
  - re-audit the remaining `Orchestrator` / `EnableGraph` seam one more time for any similarly small live ownership move around condition-stack preparation,
  - if that seam is now exhausted, pivot to the next truthful live runtime seam elsewhere in the active generation flow instead of inventing more wrapper work.
## 2026-03-13: FlattenedDT live ownership micro-slice (EnableGraph capture-entrypoint ownership)
- Current worktree continues the same live assignment-capture seam and now moves the capture entrypoints themselves under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `capture_assignment_from_ast(...)` and `capture_transition_from_ast(...)`,
  - these methods now assemble capture condition ASTs, perform capture-time debug logging, and delegate into the already-owner-local capture registration helpers,
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` no longer exposes local `record_assignment_from_ast(...)` / `record_transition_from_ast(...)` methods and now delegates directly from `flatten_decision_tree(...)`.
- Architecture guard update:
  - `t/10-ast-first-enable-structure.t` now asserts that the live `Orchestrator` object no longer exposes `record_assignment_from_ast` or `record_transition_from_ast`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t t/12-enablegraph-capture-registry.t` (`Files=2`, `Tests=157`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=324`, `PASS`)
- Immediate next direction after commit:
  - continue on the live `Orchestrator` / `EnableGraph` seam only if there is still a coherent runtime ownership move left,
  - otherwise re-audit the broader active flow and choose the next truthful slice outside capture-entrypoint convergence.
## 2026-03-13: FlattenedDT live ownership micro-slice (EnableGraph assignment-metadata normalization)
- Current worktree continues on the same live assignment-capture seam.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns assignment operator/intent/provenance normalization through `extract_assignment_capture_metadata(...)`,
  - that helper now centralizes `assignment_intent` copy, operator resolution, pulse-operator derivation from `pulse_cycles`, strict operator validation, and `source_provenance` / `output_exposure` capture,
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` still performs traversal, condition assembly, and RHS extraction, but no longer keeps local operator/intent extraction logic inside `record_assignment_from_ast(...)`.
- Regression coverage added in `t/03-assignment-intent-metadata.t`:
  - after live generation, captured assignment registry entries are now checked for preserved operator/intent/provenance data on representative assignment families (`A`, `G`, `I`, `P1`).
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t/03-assignment-intent-metadata.t t/12-enablegraph-capture-registry.t` (`Files=2`, `Tests=88`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=322`, `PASS`)
- Immediate next direction after commit:
  - continue on the live phase-1 seam rather than reopening cleanup-only work,
  - the next likely move is to narrow `Orchestrator`’s remaining direct dependence on assignment-node traversal semantics, if any final capture preparation can move under `EnableGraph` without making the flow less clear.
## 2026-03-13: FlattenedDT live ownership micro-slice (EnableGraph capture-shape normalization)
- Current worktree continues the same live phase-1 ownership seam after capture-registry mutation moved under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now also owns the remaining capture-shape normalization used by assignment capture,
  - `extract_signal_name_from_ast(...)` is broadened to recover the leading identifier from AST renderings like indexed references,
  - new `extract_rhs_capture_value(...)` owns the recursive RHS-to-captured-text normalization for literals, signal refs, binary ops, and concatenations,
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` now calls those owner-local helpers and no longer keeps local `extract_lhs_name_from_ast(...)` / `extract_rhs_from_expression(...)` helpers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t/12-enablegraph-capture-registry.t t/11-flatteneddt-generation-reset.t` (`Files=2`, `Tests=31`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=314`, `PASS`)
- Immediate next direction after commit:
  - continue on the live phase-1 seam rather than reopening wrapper cleanup,
  - the next likely move is to narrow `Orchestrator`’s remaining direct knowledge of assignment-node capture semantics, especially operator/intent extraction if that can be moved without widening risk.
## 2026-03-13: FlattenedDT live ownership micro-slice (EnableGraph capture-registry ownership)
- Current worktree continues on the live `Orchestrator` / `EnableGraph` seam instead of returning to cleanup-only work.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns mutation of the captured assignment/transition registries through `register_assignment_capture(...)` and `register_transition_capture(...)`,
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` still performs traversal, AST condition assembly, RHS extraction, and operator validation,
  - but the actual writes into `lhs_assignments`, `all_lhs`, and `lhs_ast_map` now go through `EnableGraph`, which is the module that later consumes those registries to build `assignment_analysis`.
- New regression coverage:
  - `t/12-enablegraph-capture-registry.t` generates a small two-state FSM and asserts that:
    - ordinary captured assignments remain AST-backed,
    - `next_state` transition capture is still registered with `state_transition` metadata,
    - synthetic `next_state` AST registration still occurs,
    - and generated HDL still emits the expected state-enable and assignment-enable logic.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t/12-enablegraph-capture-registry.t` (`Files=1`, `Tests=18`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=314`, `PASS`)
- Immediate next direction after commit:
  - continue along the live phase-1 ownership seam instead of revisiting facade cleanup,
  - the next likely move is to narrow the remaining direct `Orchestrator` dependency on capture-shape details such as local LHS/RHS extraction or condition-stack-to-capture assembly.
## 2026-03-13: FlattenedDT live-state reset micro-slice (per-run generation reset + enable-registry ownership)
- Current worktree moves back onto a live ownership seam instead of more facade cleanup.
- Scope of this slice:
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` now resets per-run generation state at the start of `generate_systemverilog(...)`,
  - the reset clears stale run-local registries (`state_enables`, `dt_enables`, `lhs_assignments`, `all_lhs`, `lhs_ast_map`, `assignment_analysis`, `intermediate_signals`, `referenced_intermediate_signals`, `global_expressions`, `expression_usage`, `declared_port_signals`, `port_directions`) and drops transient scratch (`binary_logical_op_counts`, `ast_factorizer`, cached `fsm_module`),
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns state/DT enable-registry initialization via `initialize_state_and_dt_enable_conditions(...)`,
  - `Orchestrator::flatten_all_decision_trees(...)` now relies on `EnableGraph` for enable-registry seeding and only performs traversal/recording.
- New regression coverage:
  - `t/11-flatteneddt-generation-reset.t` reuses one `FSM::HDL::FlattenedDT` object across two distinct FSMs and asserts the second run does not leak first-run DT enables, assignment captures, assignment analysis, or HDL signal names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `prove -I perl t/11-flatteneddt-generation-reset.t` (`Files=1`, `Tests=13`, `PASS`)
  - `prove -I perl t` (`Files=11`, `Tests=296`, `PASS`)
- Immediate next direction after commit:
  - keep the cleanup lane closed unless a future audit finds new genuinely dead supported surface,
  - continue on the next live AST/CoreAST-first seam inside the remaining `Orchestrator` / `EnableGraph` / backend data flow, most likely around assignment-capture or enable-structure state ownership.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire residual analysis/declaration facade delegates)
- Current worktree removes the last residual analysis/declaration helper pocket from the `FlattenedDT` facade.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `generate_internal_signal_declarations(...)`, `get_lhs_width_from_analysis(...)`, `is_register(...)`, `fallback_register_analysis_from_assignments(...)`, `generate_intermediate_signals(...)`, `get_pulse_delay_cycles_for_lhs(...)`, `get_pulse_active_level_for_lhs(...)`, and `get_signal_info(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching methods remain live on `EnableGraph` or `Backend::SystemVerilog`, and the active flow already reaches them directly there,
  - `get_signal_assignment_type(...)` stays on the facade because `t/03-assignment-intent-metadata.t` still exercises it as part of the tested public surface,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose those analysis/declaration helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=137`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=283`, `PASS`)
- Immediate next direction after commit:
  - treat the wrapper-pruning lane as effectively exhausted unless a future audit finds a new genuinely dead supported surface,
  - pivot back to the next live AST/CoreAST-first ownership seam from the remaining active `Orchestrator` / `EnableGraph` / backend interactions.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead backend factorization/substitution facade delegates)
- Current worktree removes a dead backend factorization/substitution helper pocket from the `FlattenedDT` facade.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `prescan_wen_en_for_intermediate_signals(...)`, `feed_asts_to_factorizer(...)`, `count_unary_negations_in_original_expressions(...)`, `ast_contains_signal(...)`, `update_original_asts_with_substituted_versions(...)`, `run_second_pass_factorization(...)`, `feed_current_asts_to_second_pass(...)`, `ast_contains_intermediate_signals(...)`, `ast_has_intermediate_signals_recursive(...)`, `update_original_asts_with_second_pass_substitutions(...)`, `get_substituted_ast_for_signal(...)`, `is_signal_referenced_in_substitutions(...)`, and `topologically_sort_signals(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching methods remain live in `Backend::SystemVerilog`, and the active path already reaches them directly from `Orchestrator`, `FSM::HDL::Factorization::Fixpoint`, or backend-local calls,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose those backend-owned factorization/substitution helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=129`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=275`, `PASS`)
- Immediate next direction after commit:
  - rerun the remaining facade audit and confirm whether any `FlattenedDT` wrappers still form a coherent dead pocket,
  - if not, stop the cleanup lane and pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead utility/rendering facade delegates)
- Current worktree removes a dead `EnableGraph` utility/rendering helper pocket from the `FlattenedDT` facade.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `generate_ast_based_signal_name(...)`, `extract_signal_name_from_ast(...)`, `map_operator_to_name(...)`, `is_arithmetic_operation(...)`, `is_logical_operation(...)`, `should_factor_logical_operation(...)`, `contains_frequently_used_operations(...)`, `get_driven_signals(...)`, `track_ast_intermediate_signals(...)`, `is_intermediate_signal(...)`, `is_signal_ast_based_intermediate(...)`, `_ast_contains_factorizable_operators(...)`, `_signal_name_indicates_ast_operators(...)`, `ast_to_systemverilog(...)`, `_ast_to_systemverilog_internal(...)`, `_render_binary_op(...)`, `_render_unary_op(...)`, `_choose_operator_symbol(...)`, `_operand_is_single_bit(...)`, `_signal_is_single_bit(...)`, `_get_operator_precedence(...)`, `_needs_parentheses(...)`, `_map_binary_operator(...)`, `_map_unary_operator(...)`, `_operand_needs_parens_for_negation(...)`, and `get_intermediate_signal_expression(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching methods remain live in `EnableGraph`, so the facade delegates were dead compatibility surface rather than a real ownership seam,
  - `get_signal_assignment_type(...)` stays on the facade because `t/03-assignment-intent-metadata.t` still exercises it as part of the tested public surface,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose those utility/rendering helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/03-assignment-intent-metadata.t` (`Files=1`, `Tests=62`, `PASS`)
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=116`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=262`, `PASS`)
- Immediate next direction after commit:
  - re-run the remaining facade audit and confirm whether any wrappers are still truly dead rather than just thin compatibility veneers,
  - if the cleanup lane is no longer yielding coherent dead pockets, pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead orchestrator/backend facade pocket)
- Current worktree removes a dead orchestrator/backend helper pocket from the `FlattenedDT` facade.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `flatten_all_decision_trees(...)`, `extract_lhs_name_from_ast(...)`, `flatten_decision_tree(...)`, `generate_header(...)`, `generate_module_declaration(...)`, `generate_state_encoding(...)`, `generate_state_register(...)`, `generate_enable_conditions(...)`, `generate_consolidated_intermediate_signals(...)`, `generate_wen_en_signals(...)`, `record_assignment_from_ast(...)`, `record_transition_from_ast(...)`, and `extract_rhs_from_expression(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching orchestrator/backend methods are still live and are now reached directly from `Orchestrator` or `backend_sv`, so the facade delegates were dead compatibility surface rather than a real ownership seam,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose those orchestrator/backend-owned helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=90`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=236`, `PASS`)
- Immediate next direction after commit:
  - rerun the facade audit; if the remaining wrappers are only legacy utility veneers and no longer form a compelling dead pocket, stop the cleanup lane,
  - pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead EnableGraph facade delegates)
- Current worktree removes a dead `EnableGraph`-owned helper pocket from the `FlattenedDT` facade.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `normalize_rhs_logic_level(...)`, `get_reset_value(...)`, `get_fsm_reset_state(...)`, `get_explicit_reset_value(...)`, `set_fsm_module_reference(...)`, `get_default_value_from_ast(...)`, `get_reset_value_from_ast(...)`, `get_default_value(...)`, `convert_condition_to_ast(...)`, and `convert_test_value_to_ast(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching `EnableGraph` methods are still live and are now reached directly from `EnableGraph` itself or from `Orchestrator`, so the facade delegates were dead compatibility surface rather than a real ownership seam,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose those `EnableGraph`-owned helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=77`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=223`, `PASS`)
- Immediate next direction after commit:
  - rerun the remaining facade audit one last time; if it is finally empty, stop the cleanup lane,
  - pivot back to the next live AST/CoreAST-first ownership seam rather than continuing wrapper pruning.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead logical-op facade delegates)
- Current worktree removes a dead logical-operation helper pocket from the `FlattenedDT` facade.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `run_global_ast_factorization(...)`, `collect_all_wen_en_ast_expressions(...)`, `count_binary_logical_operation_occurrences(...)`, `_count_logical_ops_in_ast(...)`, and `_is_factorizable_sub_expression(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching backend methods are still live and still used internally by `Backend::SystemVerilog` and `Orchestrator`, so the facade delegates were dead compatibility surface rather than a real ownership seam,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose those backend-internal logical-op helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=67`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=213`, `PASS`)
- Immediate next direction after commit:
  - re-run the remaining facade audit one last time to confirm whether any meaningful dead delegates still remain,
  - if not, stop the cleanup lane and pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead filtering facade delegates)
- Current worktree removes a dead facade-only filtering helper pocket from `perl/FSM/HDL/FlattenedDT.pm`.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `should_filter_consolidated_signal(...)`, `should_filter_ast_based(...)`, `is_simple_negation(...)`, `is_simple_comparison(...)`, and `is_signal_actually_used_in_final_expressions(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching backend methods are still live, but only as backend-internal helpers, so keeping the `FlattenedDT` delegates exposed a dead compatibility surface rather than a real ownership seam,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose those backend-internal helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=62`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=208`, `PASS`)
- Immediate next direction after commit:
  - re-run the remaining `FlattenedDT` facade / backend audit one last time to see whether any final dead delegates remain,
  - if the facade audit is now empty, pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT/backend cleanup micro-slice (retire dead mux/simple helper pocket)
- Current worktree removes a dead backend-wrapper pocket from `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `is_simple_ast_expression(...)`, `generate_comb_mux(...)`, and `generate_flop_mux(...)` had no remaining callers anywhere in the active tree,
  - the two mux helpers still referenced long-retired `lhs_to_enable_value_pairs` state, which confirmed they were stranded compatibility residue rather than dormant live behavior,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` and backend `SystemVerilog` objects no longer expose those dead helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=57`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=203`, `PASS`)
- Immediate next direction after commit:
  - run one more narrow audit on the remaining `FlattenedDT` facade / backend delegate edge for any final dead wrapper residue,
  - if that audit comes up empty, pivot back to the next live AST/CoreAST-first ownership seam instead of stretching the cleanup lane further.
## 2026-03-13: FlattenedDT/EnableGraph cleanup micro-slice (retire dead AST helper pocket)
- Current worktree removes a dead AST helper pocket from `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `get_or_create_ast_signal_name(...)`, `canonicalize_expression(...)`, `is_complex_ast(...)`, `should_factor_ast(...)`, `analyze_ast_complexity(...)`, and `_traverse_ast_for_complexity(...)` had no remaining callers anywhere in the active tree,
  - `is_complex_ast(...)` and `_traverse_ast_for_complexity(...)` were only still alive through dead owner-local callers inside that same pocket, so removing the whole pocket together is safer than leaving a partially stranded cluster,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` and `EnableGraph` objects no longer expose those dead helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=51`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=197`, `PASS`)
- Immediate next direction after commit:
  - continue the narrow dead-surface audit on the remaining `FlattenedDT` facade / backend delegate edge, especially small backend-owned wrappers like dead mux/factorization helpers,
  - if that audit comes up empty, switch back to the next live AST/CoreAST-first ownership seam instead of forcing more cleanup-only slices.
## 2026-03-13: FlattenedDT/backend cleanup micro-slice (retire dead sub-expression analysis helpers)
- Current worktree removes a small dead sub-expression analysis pocket from `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `analyze_ast_sub_expressions(...)` had no remaining callers anywhere in the active tree,
  - that method was the only caller of `find_all_ast_sub_expressions(...)`, so the pair formed a self-contained dead helper island rather than a live backend seam,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` and backend `SystemVerilog` objects no longer expose those dead helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=185`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=185`, `PASS`)
- Immediate next direction after commit:
  - run one more narrow audit on the remaining `FlattenedDT` facade / backend delegate edge for any final provably dead residue,
  - if that audit comes up empty, switch back to the next live AST/CoreAST-first ownership seam instead of forcing more cleanup-only pruning.
## 2026-03-13: EnableGraph cleanup micro-slice (retire dead owner-only helper pocket)
- Current worktree removes a small owner-only dead helper pocket from `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `get_or_create_global_expression(...)`, `should_factor_condition(...)`, `needs_parentheses(...)`, and `signal_uses_register_assignment(...)` had no remaining callers anywhere in the active tree,
  - these names were no longer mirrored by live `FlattenedDT` delegates and no longer described an active ownership boundary, so leaving them in `EnableGraph` only preserved uncalled compatibility residue,
  - `t/10-ast-first-enable-structure.t` now asserts that live `EnableGraph` objects no longer expose that dead owner-only helper surface.
- Validation is green so far for this slice:
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=35`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=181`, `PASS`)
- Immediate next direction after commit:
  - re-audit the remaining `FlattenedDT` / `EnableGraph` edge one more time to decide whether the dead-surface cleanup lane is actually exhausted,
  - if no more dead residue remains, switch back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead orphan helper pocket)
- Current worktree removes a small dead helper pocket from both `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `create_condition_expression_signal_name(...)`, `set_explicit_reset_values(...)`, `parentheses_are_redundant(...)`, and `generate_expression_from_signal_name(...)` had no remaining callers anywhere in the active tree,
  - the matching `FlattenedDT` compatibility delegates and `EnableGraph` owner methods are gone together, rather than leaving dead definitions stranded on one side,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` and `EnableGraph` objects no longer expose that dead helper surface.
- Validation is green so far for this slice:
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=31`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=177`, `PASS`)
- Immediate next direction after commit:
  - continue re-auditing the remaining `FlattenedDT` / `EnableGraph` compatibility edge for any last dead helper residue,
  - if the dead-surface lane is now exhausted, switch back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead unified helper delegates)
- Current worktree removes a dead unified-analysis / unified-emission helper delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed the live phase-1/2/3 path now runs directly through `Orchestrator -> EnableGraph` and no longer uses the matching `FlattenedDT` facade delegates,
  - removed dead facade wrappers for `build_unified_assignment_analysis(...)`, `group_assignments_by_rhs(...)`, `generate_complete_enable_structure(...)`, `build_multiplexer_config(...)`, `generate_unified_wen_en_signals(...)`, `generate_dt_enables_from_analysis(...)`, `generate_lhs_enables_from_analysis(...)`, `generate_signal_assignments(...)`, `generate_unified_flop_mux(...)`, `generate_unified_pulse_delay_logic(...)`, `signal_uses_register_assignment(...)`, and `generate_unified_comb_mux(...)`,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose that dead unified helper surface.
- Validation is green so far for this slice:
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=23`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=169`, `PASS`)
- Immediate next direction after commit:
  - continue re-auditing the remaining `FlattenedDT` facade delegates for any final dead surface that only mirrors direct `EnableGraph` / backend ownership,
  - if the dead-surface audit is exhausted, pivot back to the next smallest live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead signal-AST facade helper)
- Current worktree removes the dead `get_signal_ast_node(...)` helper from `perl/FSM/HDL/FlattenedDT.pm` and drops the now-unused `FSM::GlobalASTManager`, `FSM::AST::Node`, and `FSM::CoreAST` imports from the same facade.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `get_signal_ast_node(...)` had no callers anywhere in the active tree,
  - the helper depended on a stale `fsm_module` slot that is not part of the live AST/CoreAST generation path,
  - `t/10-ast-first-enable-structure.t` now asserts that live generation no longer exposes that dead helper on the `FlattenedDT` facade.
- Validation is green so far for this slice:
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=11`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=157`, `PASS`)
- Immediate next direction after commit:
  - continue re-auditing the remaining `FlattenedDT` facade for truly dead delegates or stale state assumptions before taking more cleanup-only slices,
  - if that dead-surface audit runs dry, return to the next smallest live AST/CoreAST-first ownership seam instead of forcing more facade-only pruning.
## 2026-03-11: Backend convergence micro-slice (EnableGraph/SystemVerilog defining-AST metadata for consolidated filtering)
- Current worktree carries native defining-AST metadata forward on the live consolidated intermediate filtering path.
- Scope remains a small behavior-preserving AST-first slice:
  - `track_ast_intermediate_signals()` now stores `reference_ast` separately and records a native `defining_ast` when one already exists,
  - the backend now resolves defining ASTs through `resolve_intermediate_signal_defining_ast()` before reparsing expressions,
  - prescan-referenced intermediate entries are merged into consolidated generation with cached defining-AST metadata.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue targeting the remaining expression-only compatibility cases on the consolidated path where AST-derived metadata is still absent,
  - keep prioritizing slices that remove live reparsing pressure over nearby but less active helper or registry cleanup.
## 2026-03-11: Backend convergence micro-slice (EnableGraph/SystemVerilog AST-first intermediate dependency extraction)
- Current worktree converts the live consolidated intermediate-signal dependency-discovery path from rendered-string scanning toward AST traversal.
- Scope remains a small behavior-preserving AST-first slice:
  - `EnableGraph` now exposes `extract_intermediate_signals_from_ast()` for recursive intermediate-reference recovery from ASTs,
  - consolidated dependency-map construction in `Backend/SystemVerilog` now uses defining ASTs when available instead of scanning rendered expressions first,
  - substituted-AST debug tracing now extracts referenced intermediates directly from the substituted AST,
  - pre-scan referenced signals are now seeded with defining ASTs through `get_intermediate_signal_ast()` when that AST is available,
  - string-based intermediate extraction remains only as a compatibility fallback after parse failure.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue targeting the remaining expression-only compatibility entries on the consolidated filtering path so runtime dependency/filtering logic sees native ASTs more consistently,
  - keep re-evaluating `get_or_create_global_expression()` against live call paths rather than assuming it is the next best seam from locality alone.
## 2026-03-11: Backend convergence micro-slice (EnableGraph AST-backed intermediate-signal registry metadata)
- Current worktree converts the live intermediate-signal registry/count/render path from string-backed ownership toward AST-backed metadata in `perl/FSM/Synthesis/EnableGraph.pm` and `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Scope remains a small behavior-preserving AST-first slice:
  - `get_or_create_ast_signal_name()` and `get_or_create_global_expression()` now record structured intermediate-signal registry entries with `ast`, `expression`, `name`, and `source` when an AST is available,
  - `is_signal_ast_based_intermediate()` and `get_intermediate_signal_ast()` now prefer native AST sources on the live path instead of reparsing `global_expressions` or raw registry strings first,
  - `get_intermediate_signal_expression()` no longer falls back to reconstructing logic from signal-name patterns,
  - `count_binary_logical_operation_occurrences()` now resolves native intermediate-signal ASTs through `EnableGraph` instead of reparsing stored registry strings.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - keep targeting live semantic compatibility fallbacks around intermediate-signal registration and lookup, especially places where `get_or_create_global_expression()` still seeds names from string parsing when no AST seed is present,
  - continue treating the older `FlattenedDT.pm` condition/value helpers as secondary until a slice can eliminate a live string dependency instead of only relocating it.
## 2026-03-11: Backend convergence micro-slice (EnableGraph AST-first logical-operation factor detection)
- Current worktree replaces a live string-based factorization-decision path in `perl/FSM/Synthesis/EnableGraph.pm` with AST-first traversal.
- Scope remains a small behavior-preserving AST-first slice:
  - `contains_frequently_used_operations()` now walks AST nodes and resolved intermediate-signal ASTs instead of scanning rendered expressions for operator substrings,
  - `get_intermediate_signal_ast()` now resolves defining ASTs from the AST factorizer and FSM-module signal metadata before falling back to compatibility parsing of string registries,
  - `get_intermediate_signal_expression()` now prefers rendering from a defining AST when one exists.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - keep targeting live algorithmic string dependencies rather than dormant helper residue,
  - likely next seams are the remaining compatibility fallbacks around intermediate-signal expression reconstruction and the older `FlattenedDT.pm` condition/value helpers only when they can be replaced by AST/CoreAST-native behavior instead of merely moved.
## 2026-03-11: Backend convergence micro-slice (EnableGraph redundant-parentheses helper ownership)
- Current worktree finishes the in-flight legacy string-expression parenthesis cleanup by moving `parentheses_are_redundant()` from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small helper-ownership reduction step:
  - `parentheses_are_redundant()` now lives in `EnableGraph`,
  - `FlattenedDT` keeps a compatibility delegate for the helper,
  - no public backend entrypoint or active HDL emission call path changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Important architectural direction from the user:
  - this slice completes an already-started string-compatibility helper lane, but future convergence work should preferentially eliminate string-based algorithmic handling instead of continuing string-helper relocation by default,
  - target state is full AST/CoreAST-first algorithms with an AST/CoreAST representation that is complete, flexible, general, extensible, elegant, and robust.
- Immediate next direction after commit:
  - update the roadmap plan so AST/CoreAST-first convergence is explicit,
  - re-scan `FlattenedDT.pm` for the next truthful AST/CoreAST-native slice, especially remaining string-based algorithmic helpers such as `extract_condition_string()` and adjacent formatting/condition paths only when they can be replaced by AST/CoreAST-native behavior rather than merely moved.
## 2026-03-11: Backend convergence micro-slice (EnableGraph expression sanitation helper ownership)
- Current worktree moves the legacy string-expression sanitation helper from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small helper-ownership reduction step:
  - `clean_intermediate_expression()` now lives in `EnableGraph`,
  - `FlattenedDT` keeps a compatibility delegate for the helper,
  - no public backend entrypoint or active HDL emission call path changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the remaining residual helper pockets in `FlattenedDT.pm` now that the nearby string-formatting lane has been reduced again,
  - treat `parentheses_are_redundant()` and the older condition-formatting helpers as possible next candidates only if they still form a similarly coherent ownership move,
  - keep preferring truthful ownership reduction over broad dormant cleanup.
## 2026-03-11: Backend convergence micro-slice (EnableGraph string parenthesis helper ownership)
- Current worktree moves the legacy string-expression parenthesis helper from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small helper-ownership reduction step:
  - `needs_parentheses()` now lives in `EnableGraph`,
  - `FlattenedDT` keeps a compatibility delegate for the helper,
  - no public backend entrypoint or active HDL emission call path changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the remaining nearby string-formatting helpers in `FlattenedDT.pm`,
  - treat `clean_intermediate_expression()` and the older `format_condition()` / `format_signal_expression()` lane as possible next candidates only if they still form a similarly coherent, truthful ownership reduction,
  - keep preferring small real boundary reductions over paper moves in dormant helper pockets.
## 2026-03-11: Backend convergence micro-slice (EnableGraph AST factorization-analysis helper ownership)
- Current worktree moves the AST factorization-analysis helper pair from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small helper-ownership reduction step:
  - `is_complex_ast()` now lives in `EnableGraph`,
  - `should_factor_ast()` now lives in `EnableGraph`,
  - `FlattenedDT` keeps compatibility delegates for both helper names,
  - no public backend entrypoint or active HDL emission call path changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - keep re-scanning the remaining nearby legacy expression-formatting helpers in `FlattenedDT.pm`, with `needs_parentheses()` now the most plausible next lane,
  - consider adjacent formatting cleanup such as `clean_intermediate_expression()` only if it forms a similarly small coherent ownership move,
  - keep preferring small coherent ownership reductions over broad dormant cleanup.
## 2026-03-11: Backend convergence micro-slice (EnableGraph legacy condition-factorization helper ownership)
- Current worktree moves the legacy condition-factorization helper trio from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small helper-ownership reduction step:
  - `should_factor_condition()` now lives in `EnableGraph`,
  - `analyze_ast_complexity()` now lives in `EnableGraph`,
  - `_traverse_ast_for_complexity()` now lives in `EnableGraph`,
  - `FlattenedDT` keeps compatibility delegates for the same helper names,
  - no public backend entrypoint or active HDL emission call path changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - keep re-scanning the remaining nearby legacy expression/factorization helpers in `FlattenedDT.pm`, with `needs_parentheses()` and adjacent formatting helpers still the most plausible next lane,
  - keep preferring small coherent ownership reductions over broad dormant cleanup.
## 2026-03-10: Backend convergence micro-slice (EnableGraph global-expression registry helper ownership)
- Current worktree moves the adjacent global-expression registry helper pair from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small helper-ownership reduction step:
  - `get_or_create_global_expression()` now lives in `EnableGraph`,
  - `canonicalize_expression()` now lives in `EnableGraph`,
  - `FlattenedDT` keeps compatibility delegates for both helper names,
  - no public backend entrypoint or active HDL emission call path changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - keep re-scanning the remaining non-delegate utility pockets in `FlattenedDT.pm`, with adjacent legacy expression/factorization helpers still the most plausible next ownership lane,
  - keep preferring small coherent ownership reductions over speculative dormant cleanup.
## 2026-03-10: Backend convergence micro-slice (EnableGraph AST signal-naming helper ownership)
- Current worktree moves the AST signal-naming helper cluster from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small helper-ownership reduction step:
  - `create_condition_expression_signal_name()`, `get_or_create_ast_signal_name()`, `generate_ast_based_signal_name()`, and `map_operator_to_name()` now live in `EnableGraph`,
  - `FlattenedDT` keeps compatibility delegates for the same helper names,
  - no public backend entrypoint or active HDL emission call path changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the remaining non-delegate utility pockets in `FlattenedDT.pm` for the next small coherent owner, with nearby AST-support / legacy factorization helpers as the most plausible lane,
  - keep preferring truthful ownership reduction over speculative dormant cleanup that does not improve the active boundary.
## 2026-03-10: Backend convergence micro-slice (Verilog backend SystemVerilog-entry callsite convergence)
- Current worktree localizes the live `generate_systemverilog()` call in `perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm` away from the `FlattenedDT` facade to direct `orchestrator` ownership.
- Scope remains a single orchestrator-boundary callsite convergence step:
  - `Backend::Verilog::generate_verilog()` now obtains SystemVerilog through `$ctx->{orchestrator}->generate_systemverilog(...)`,
  - the `FlattenedDT::generate_systemverilog()` compatibility delegate remains unchanged for non-local callers,
  - no Verilog conversion semantics or orchestrator ownership changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the broader orchestrator/facade boundary now that the obvious `Backend::Verilog` round-trip is localized,
  - keep preferring live round-trip convergence over dormant compatibility delegate cleanup in `FlattenedDT.pm`.
## 2026-03-10: Backend convergence micro-slice (Fixpoint second-pass update callsite convergence)
- Current worktree localizes the live `update_original_asts_with_second_pass_substitutions()` call in `perl/FSM/HDL/Factorization/Fixpoint.pm` away from the `FlattenedDT` facade to direct `backend_sv` ownership.
- Scope remains a single second-pass factorization callsite convergence step:
  - `run_post_substitution_factorization()` now applies second-pass AST updates through `$ctx->{backend_sv}->update_original_asts_with_second_pass_substitutions(...)`,
  - the `FlattenedDT::update_original_asts_with_second_pass_substitutions()` compatibility delegate remains unchanged for any non-local callers,
  - the direct `Fixpoint` second-pass callsite lane now appears exhausted.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the broader factorization/backend facade boundaries now that the direct `Fixpoint` second-pass lane is exhausted,
  - keep preferring live round-trip convergence over dormant compatibility delegate cleanup in `FlattenedDT.pm`.
## 2026-03-10: Backend convergence micro-slice (Fixpoint second-pass feed callsite convergence)
- Current worktree localizes the live `feed_current_asts_to_second_pass()` call in `perl/FSM/HDL/Factorization/Fixpoint.pm` away from the `FlattenedDT` facade to direct `backend_sv` ownership.
- Scope remains a single second-pass factorization callsite convergence step:
  - `run_post_substitution_factorization()` now feeds post-substitution ASTs through `$ctx->{backend_sv}->feed_current_asts_to_second_pass(...)`,
  - the `FlattenedDT::feed_current_asts_to_second_pass()` compatibility delegate remains unchanged for any non-local callers,
  - no second-pass update or render ownership changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - localize the matching live `update_original_asts_with_second_pass_substitutions(...)` call in `Fixpoint.pm`, which is now the obvious adjacent second-pass round-trip still routed through `FlattenedDT`,
  - keep `FlattenedDT` as the compatibility shell while continuing one callsite at a time.
## 2026-03-10: Backend convergence micro-slice (SystemVerilog prescan intermediate-tracking callsite convergence)
- Current worktree localizes the two live `track_ast_intermediate_signals()` callsites in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` away from the `FlattenedDT` facade to direct `EnableGraph` ownership.
- Scope remains a single backend-prescan callsite convergence step:
  - DT-specific enable pre-scan tracking now goes through `$ctx->{enable_graph}->track_ast_intermediate_signals(...)`,
  - LHS-level enable pre-scan tracking now goes through the same direct `EnableGraph` entry,
  - `FlattenedDT` helper/delegate ownership is unchanged in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan `perl/FSM/HDL/Factorization/Fixpoint.pm` for the remaining live second-pass helper round-trips through `FlattenedDT`, especially `feed_current_asts_to_second_pass(...)` and `update_original_asts_with_second_pass_substitutions(...)`,
  - keep `FlattenedDT` as the compatibility shell while continuing behavior-preserving live callsite convergence before dormant cleanup.
## 2026-03-10: Backend convergence micro-slice (Factorization Fixpoint AST-to-SV callsite convergence)
- Current worktree localizes the remaining non-local `ast_to_systemverilog()` callsites in `perl/FSM/HDL/Factorization/Fixpoint.pm` away from the `FlattenedDT` facade to direct `EnableGraph` entry ownership.
- Scope remains a single render/factorization callsite convergence step:
  - pass-level debug rendering of new second-pass intermediate signals now goes through `$ctx->{enable_graph}->ast_to_systemverilog(...)`,
  - `_build_expression_signature()` now uses the same `EnableGraph` render entry for pass-signature construction,
  - `FlattenedDT` helper/delegate ownership is unchanged in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm`
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the remaining render/factorization callsites that still round-trip through `FlattenedDT`, with `find_substituted_ast()` and adjacent canonical-expression matching inside `FlattenedDT.pm` as the most obvious surviving AST-to-SV seam,
  - keep `FlattenedDT` as the compatibility shell while continuing behavior-preserving callsite convergence before broader delegate cleanup.
## 2026-03-09: Backend convergence micro-slice (EnableGraph binary operator-selection helper ownership)
- Current worktree moves `_choose_operator_symbol()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single binary-support helper convergence step:
  - `FlattenedDT::_choose_operator_symbol()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns the full binary operator-selection lane on top of already-local precedence, operand-width, and operator-mapping helpers,
  - the binary-support helper ownership lane under the render cluster is now exhausted, while `FlattenedDT` remains the compatibility facade.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the remaining render-cluster / facade-boundary seams now that binary-support helper ownership is fully localized in `EnableGraph`,
  - keep `FlattenedDT` as the compatibility shell while choosing the next smallest truthful non-binary-support slice.
## 2026-03-09: Backend convergence micro-slice (EnableGraph binary operand-width helper ownership)
- Current worktree moves `_operand_is_single_bit()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single binary-support helper convergence step:
  - `FlattenedDT::_operand_is_single_bit()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns recursive operand single-bit classification on top of the already-local `_signal_is_single_bit()` helper,
  - `_choose_operator_symbol()` is now the next remaining binary-support helper on the operator-selection path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-evaluate `_choose_operator_symbol()` as the next truthful binary-support seam now that operand-width analysis is local,
  - keep `FlattenedDT` as the compatibility facade while the final binary operator-selection helper is localized.
## 2026-03-09: Backend convergence micro-slice (EnableGraph binary signal-width helper ownership)
- Current worktree moves `_signal_is_single_bit()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single binary-support helper convergence step:
  - `FlattenedDT::_signal_is_single_bit()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns single-bit signal classification, including FSM-module metadata access retargeted through `$self->{flattened_dt}`,
  - `_operand_is_single_bit()` and `_choose_operator_symbol()` remain as the next binary-support helpers on the heavier operand-analysis/operator-selection path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - move `_operand_is_single_bit()` as the next truthful binary-support seam now that its `_signal_is_single_bit()` dependency is local,
  - then re-evaluate `_choose_operator_symbol()` once operand-width analysis is fully localized.
## 2026-03-09: Backend convergence micro-slice (EnableGraph binary AST-to-SV render helper ownership)
- Current worktree moves `_render_binary_op()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single binary-render helper convergence step:
  - `FlattenedDT::_render_binary_op()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns binary AST rendering,
  - narrow compatibility delegates for `_get_operator_precedence()`, `_choose_operator_symbol()`, `_needs_parentheses()`, and `_operand_is_single_bit()` preserve behavior while the deeper binary-support helpers remain in `FlattenedDT`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the smallest isolated binary-support helpers, most likely `_get_operator_precedence()` and/or `_needs_parentheses()` before the larger `_choose_operator_symbol()` path,
  - keep the compatibility facade in `FlattenedDT` intact until the binary-render cluster converges further.
## 2026-03-09: Backend convergence micro-slice (EnableGraph unary negation parenthesization helper ownership)
- Current worktree moves `_operand_needs_parens_for_negation()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single unary-support helper convergence step:
  - `FlattenedDT::_operand_needs_parens_for_negation()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns the full unary-render support lane,
  - no binary-render helper ownership changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - unary-support delegates are now exhausted,
  - re-scan the larger binary-render cluster starting at `_render_binary_op()` and its adjacent precedence/operator helpers for the next truthful micro-slice.
## 2026-03-09: Backend convergence micro-slice (EnableGraph unary operator mapping helper ownership)
- Current worktree moves `_map_unary_operator()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single unary-support helper convergence step:
  - `FlattenedDT::_map_unary_operator()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns unary operator symbol mapping,
  - `_operand_needs_parens_for_negation()` remains the last isolated unary-support delegate before the larger binary-render cluster.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - move `_operand_needs_parens_for_negation()` as the remaining unary-support helper seam,
  - then re-evaluate the larger `_render_binary_op()` cluster for the next truthful micro-slice.
## 2026-03-09: Backend convergence micro-slice (EnableGraph unary AST-to-SV render helper ownership)
- Current worktree moves `_render_unary_op()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single render-helper convergence step:
  - `FlattenedDT::_render_unary_op()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns unary AST rendering,
  - narrow compatibility delegates for `_map_unary_operator()` and `_operand_needs_parens_for_negation()` preserve behavior while those unary-support helpers still live in `FlattenedDT`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the smallest remaining unary-support helper delegates, most likely `_map_unary_operator()` before `_operand_needs_parens_for_negation()`,
  - keep deferring the broader `_render_binary_op()` cluster until the smaller unary-adjacent seams are exhausted.
## 2026-03-09: Backend convergence micro-slice (EnableGraph AST-to-SV internal helper ownership)
- Current worktree moves `_ast_to_systemverilog_internal()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single render-boundary helper convergence step:
  - `FlattenedDT::_ast_to_systemverilog_internal()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns the recursive AST-to-SystemVerilog dispatcher,
  - temporary compatibility delegates for `_render_binary_op()` and `_render_unary_op()` keep the deeper render cluster behavior-preserving for now.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the smallest adjacent render helper still round-tripping through `FlattenedDT`, most likely `_render_unary_op()` before the larger `_render_binary_op()` path,
  - keep the compatibility facade in `FlattenedDT` intact until the render cluster converges further.
## 2026-03-09: Backend convergence micro-slice (EnableGraph AST-to-SV internal delegate callsite convergence)
- Current worktree localizes the `ast_to_systemverilog()` render-internal callsite in `perl/FSM/Synthesis/EnableGraph.pm` away from a direct `FlattenedDT` object method reach-in.
- Scope remains a single active runtime callsite convergence step:
  - `ast_to_systemverilog()` now routes through `$self->_ast_to_systemverilog_internal(...)`,
  - the new `EnableGraph` compatibility delegate still forwards to `FlattenedDT`'s `_ast_to_systemverilog_internal(...)`,
  - deeper render-helper ownership remains unchanged for this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - if this render-boundary lane continues, the next truthful seam is the heavier `_ast_to_systemverilog_internal()` helper family itself together with the adjacent render/precedence/operator helpers it depends on,
  - keep preferring behavior-preserving slices over broad render-cluster moves.
## 2026-03-09: Backend convergence micro-slice (EnableGraph LHS-enable intermediate tracking callsite convergence)
- Current worktree localizes the `track_ast_intermediate_signals()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Scope remains a single active runtime callsite convergence step:
  - `generate_lhs_enables_from_analysis()` now tracks intermediate signals through `$self->track_ast_intermediate_signals(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - the same-pattern direct self-owned round-trips inside `EnableGraph.pm` now appear exhausted,
  - re-scan for the next smallest behavior-preserving seam, with the remaining direct `EnableGraph` -> `FlattenedDT` method dependency currently narrowed to `ast_to_systemverilog()` calling `_ast_to_systemverilog_internal(...)`.
## 2026-03-09: Backend convergence micro-slice (EnableGraph mux-config callsite convergence)
- Current worktree localizes the phase-1 `build_multiplexer_config()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Scope remains a single active phase-1 analysis callsite convergence step:
  - `build_unified_assignment_analysis()` now assembles multiplexer config through `$self->build_multiplexer_config(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next smallest remaining direct self-owned round-trip in `EnableGraph`, currently the `track_ast_intermediate_signals()` callsite in `generate_lhs_enables_from_analysis()`,
  - keep prioritizing live helper-family self-localization over dormant compatibility cleanup.
## 2026-03-09: Backend convergence micro-slice (EnableGraph enable-structure callsite convergence)
- Current worktree localizes the phase-1 `generate_complete_enable_structure()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Scope remains a single active phase-1 analysis callsite convergence step:
  - `build_unified_assignment_analysis()` now generates enable structures through `$self->generate_complete_enable_structure(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the adjacent phase-1 analysis round-trip, most likely the `build_multiplexer_config()` callsite in `build_unified_assignment_analysis()`,
  - keep prioritizing live helper-family self-localization over dormant compatibility cleanup.
## 2026-03-09: Backend convergence micro-slice (EnableGraph RHS-grouping callsite convergence)
- Current worktree localizes the phase-1 `group_assignments_by_rhs()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Scope remains a single active phase-1 analysis callsite convergence step:
  - `build_unified_assignment_analysis()` now groups RHS assignments through `$self->group_assignments_by_rhs(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the adjacent phase-1 analysis round-trip, most likely the `generate_complete_enable_structure()` callsite in `build_unified_assignment_analysis()`,
  - keep prioritizing live helper-family self-localization over dormant compatibility cleanup.
## 2026-03-08: Local CI entrypoint + workflow unification
- Current worktree routes `.github/workflows/regression.yml` through a shared repo script, `bin/ci-regression`, so the same CI logic can be run locally before push without depending on GitHub-hosted execution.
- Scope of this slice:
  - added `bin/ci-regression`, which resolves the repository root itself and runs `prove -I perl t`,
  - removed the discarded Rust-specific `check-rust-include-paths` guard after confirming this repository’s active CI path is Perl-only,
  - updated `.github/workflows/regression.yml` to call the shared script instead of inlining a narrower one-test command,
  - documented the local pre-push entrypoint in `README.md`.
- Validation is green for this slice:
  - `bash -lc 'cd /tmp && /Users/richarddje/Documents/github/fsmgen/bin/ci-regression'`
  - result: full regression passed (`Files=6`, `Tests=125`, `PASS`)
  - audited tracked `.github`, `bin`, `perl`, `t`, `README.md`, and `docs` content for active references to untracked `fx/`, `plugin/`, `specs/`, or machine-specific `/Users/...` paths and found none.
- Important current-state note:
  - `bin/ci-regression` is the only new active CI file that needed to be brought under git control,
  - the remaining untracked `fx/` tree is not referenced by the active workflow/runtime/test path and is therefore not a current GitHub CI dependency.
- Immediate next direction after commit:
  - if more CI automation is added later, keep routing it through repo-owned scripts so local and GitHub execution stay aligned,
  - keep re-checking active tracked workflow/runtime/test references whenever new untracked trees or helper scripts are introduced.
## 2026-03-08: Backend convergence micro-slice (Orchestrator signal-assignment callsite convergence)
- Current worktree localizes the stage-8 `generate_signal_assignments()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Scope remains a single active stage-level callsite convergence step:
  - `generate_systemverilog()` now emits final signal assignments through `$ctx->{enable_graph}->generate_signal_assignments(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the remaining live `FlattenedDT` facade round-trips now that the active `generate_systemverilog()` stage chain is fully localized,
  - prioritize the next smallest behavior-preserving runtime seam rather than removing dormant compatibility delegates.
## 2026-03-08: Backend convergence micro-slice (Orchestrator WEN/EN-signal callsite convergence)
- Current worktree localizes the stage-7 `generate_wen_en_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now emits WEN/EN signals through `$ctx->{backend_sv}->generate_wen_en_signals(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next active Orchestrator round-trip, most likely the stage-8 `generate_signal_assignments()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator consolidated-intermediate-signals callsite convergence)
- Current worktree localizes the stage-6 `generate_consolidated_intermediate_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now emits consolidated intermediate signals through `$ctx->{backend_sv}->generate_consolidated_intermediate_signals(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-7 `generate_wen_en_signals()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Repository tracking change (plugin/ and specs/ now versioned)
- Added the existing `plugin/` and `specs/` trees to git so the repository now carries the legacy `.plg` plugin assets and spec/reference files directly.
- Scope is repository tracking only:
  - no content changes were made inside `plugin/` or `specs/`,
  - no intended HDL generation or runtime behavior changes were introduced by tracking these files.
- Validation for this scope:
  - post-commit `git --no-pager status --short` should leave only `?? fx/`
- Immediate next direction after commit:
  - keep `fx/` untracked for now,
  - resume backend convergence at the next live Orchestrator/backend seam, most likely stage-6 `generate_consolidated_intermediate_signals()`.
## 2026-03-08: Backend convergence micro-slice (Orchestrator WEN/EN prescan callsite convergence)
- Current worktree localizes the stage-5 `prescan_wen_en_for_intermediate_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-analysis callsite convergence step:
  - `generate_systemverilog()` now performs the post-count pre-scan through `$ctx->{backend_sv}->prescan_wen_en_for_intermediate_signals()`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-6 `generate_consolidated_intermediate_signals()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator logical-op-count callsite convergence)
- Current worktree localizes the stage-4 `count_binary_logical_operation_occurrences()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-analysis callsite convergence step:
  - `generate_systemverilog()` now performs the pre-prescan logical-op counting through `$ctx->{backend_sv}->count_binary_logical_operation_occurrences()`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-5 `prescan_wen_en_for_intermediate_signals()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator generate-enable-conditions callsite convergence)
- Current worktree localizes the stage-3 `generate_enable_conditions()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now emits enable conditions through `$ctx->{backend_sv}->generate_enable_conditions(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-4 `count_binary_logical_operation_occurrences()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator generate-internal-signal-declarations callsite convergence)
- Current worktree localizes the stage-2 `generate_internal_signal_declarations()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now appends internal signal declarations through `$ctx->{backend_sv}->generate_internal_signal_declarations(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-3 `generate_enable_conditions()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator generate-state-register callsite convergence)
- Current worktree localizes the stage-2 `generate_state_register()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now appends state-register emission through `$ctx->{backend_sv}->generate_state_register(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining stage-2 backend-emission Orchestrator round-trips in `generate_systemverilog()`, most likely `generate_internal_signal_declarations()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator generate-state-encoding callsite convergence)
- Current worktree localizes the stage-2 `generate_state_encoding()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now appends state encoding through `$ctx->{backend_sv}->generate_state_encoding(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining stage-2 backend-emission Orchestrator round-trips in `generate_systemverilog()`, most likely `generate_state_register()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator generate-module-declaration callsite convergence)
- Current worktree localizes the stage-2 `generate_module_declaration()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now appends the module declaration through `$ctx->{backend_sv}->generate_module_declaration(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining stage-2 backend-emission Orchestrator round-trips in `generate_systemverilog()`, most likely `generate_state_encoding()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator generate-header callsite convergence)
- Current worktree localizes the stage-2 `generate_header()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now starts HDL assembly through `$ctx->{backend_sv}->generate_header(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining stage-2 backend-emission Orchestrator round-trips in `generate_systemverilog()`, most likely `generate_module_declaration()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator unified-assignment-analysis callsite convergence)
- Current worktree localizes the unified phase-1 `build_unified_assignment_analysis()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Scope remains a single active stage-level callsite convergence step:
  - `flatten_all_decision_trees()` now invokes `$ctx->{enable_graph}->build_unified_assignment_analysis(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining active stage-level Orchestrator round-trips in `generate_systemverilog()`, likely starting with the earliest backend-emission callsites,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator stage-0 FSM-module-reference callsite convergence)
- Current worktree localizes the stage-0 `set_fsm_module_reference()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Scope remains a single active callsite convergence step:
  - `generate_systemverilog()` now stores the FSM module reference through `$ctx->{enable_graph}->set_fsm_module_reference(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next stage-level Orchestrator round-trip, most likely `build_unified_assignment_analysis()` in `flatten_all_decision_trees()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator condition-helper callsite convergence)
- Current worktree localizes the active Orchestrator condition-helper round-trips from `FlattenedDT` facade delegates to direct `EnableGraph` ownership.
- Updated runtime callsites in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`:
  - `convert_condition_to_ast()` for conditional-branch traversal,
  - `convert_test_value_to_ast()` for test-node branch construction,
  - `create_condition_expression()` for assignment capture and transition capture.
- Scope remains callsite convergence only:
  - helper ownership stays in `perl/FSM/Synthesis/EnableGraph.pm`,
  - `FlattenedDT` compatibility delegates remain for non-local or dormant callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining active stage-level Orchestrator round-trips, most likely `build_unified_assignment_analysis()` or `set_fsm_module_reference()`,
  - keep treating dormant validation helpers and legacy code as lower priority than live callsite convergence.
## 2026-03-08: Backend convergence micro-slice (actual LHS/RHS tracking orchestration ownership)
- Current worktree moves `track_actual_lhs_rhs()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- This slice follows the now-orchestrator-owned assignment/transition capture flow:
  - `record_assignment_from_ast()` and `record_transition_from_ast()` now both keep actual-pair validation tracking local to the orchestrator instead of round-tripping through the facade,
  - the adjacent `track_expected_lhs_rhs()` / raw-AST completeness helpers remain in `FlattenedDT` for now because they are dormant validation support rather than part of the active runtime path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the remaining live Orchestrator/backend call surface for the next smallest active ownership seam now that actual-pair tracking is local,
  - continue deferring the dormant expected/raw-AST validation family until it becomes worth extracting as a cohesive support block.
## 2026-03-08: Living architecture note added (frontend parser/input-format decoupling)
- Added a living design note in `DEVELOPMENT_NOTES.md` describing the desired boundary between source-format parsing and the FSMGen semantic core.
- Current validated read captured there:
  - the pipeline already has a partial separation because `FSM::Pipeline::HDLGenerator` parses source first, then lowers into `FSM::CoreAST::FSMModule`, and downstream analysis/backend code mostly consumes semantic CoreAST objects,
  - the remaining hard coupling is still at the frontend boundary because `HDLGenerator` directly calls `Lispish`, and `FSM::Adapter::FSMGenFull::*` still decodes the current `.fsm` / Lispish surface syntax directly.
- Architectural rule now recorded:
  - `FSM::CoreAST` is the canonical semantic contract,
  - parser-specific raw ASTs and syntax tokens should stop at the frontend/lowering boundary rather than leaking into synthesis/backend layers.
- Immediate next direction:
  - treat any future non-Lispish format as another frontend that lowers into `FSM::CoreAST`, not as a reason to branch backend behavior by input format,
  - when implementation work begins, isolate the direct `Lispish` dependency behind a dedicated frontend boundary first.
## 2026-03-08: Backend convergence micro-slice (assignment-capture orchestration ownership)
- Current worktree moves `extract_lhs_name_from_ast()`, `record_assignment_from_ast()`, and `extract_rhs_from_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`, while keeping `FlattenedDT` as compatibility delegates.
- This slice completes the active assignment-capture trio on the live recursive flattener path:
  - `flatten_decision_tree()` now routes assignment capture locally through orchestrator-owned helpers instead of round-tripping through the facade,
  - the RHS extraction helper moved with the assignment recorder to avoid leaving that recursion split across facade/orchestrator ownership,
  - the LHS-name helper moved too because its only live callers are now the orchestrator-owned assignment traversal/capture path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue on the remaining shared tracking helper seam now adjacent to the orchestrator-owned assignment/transition capture path, most likely `track_actual_lhs_rhs()`,
  - keep deferring dormant legacy helpers such as `extract_condition_string()` until they become part of an active ownership path again.
## 2026-03-08: Backend convergence micro-slice (state-transition capture orchestration ownership)
- Current worktree moves `record_transition_from_ast()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- This slice is the next smallest active seam in the post-flattener AST-capture family: `record_transition_from_ast()` now has a single live caller inside the orchestrator-owned recursive flattener and is materially smaller than the adjacent assignment-capture path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue on the adjacent assignment-capture path (`record_assignment_from_ast()` together with `extract_rhs_from_expression()` and any tightly coupled support),
  - keep deferring dormant legacy factorization helpers until they matter to the active path again.
## 2026-03-08: Backend convergence micro-slice (recursive flattener orchestration ownership)
- Current worktree moves `flatten_decision_tree()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- This slice extends the immediately adjacent orchestration move from `flatten_all_decision_trees()`: the orchestrator now owns both the live entrypoint and its recursive traversal body, while still calling back into `FlattenedDT` for the unmoved AST-capture helpers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue on the adjacent live AST-capture helper family used by the recursive flattener (`record_assignment_from_ast()`, `record_transition_from_ast()`, `extract_rhs_from_expression()`, and any tightly coupled helpers),
  - keep ignoring dormant legacy factorization code until it becomes part of the active generation path again.
## 2026-03-08: Backend convergence micro-slice (flatten-all-decision-trees orchestration ownership)
- Current worktree moves `flatten_all_decision_trees()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- This slice follows the recent live-path focus: the moved entrypoint is exercised directly by `generate_systemverilog()` and is a smaller truthful orchestration seam than the adjacent deeper flattener helper family.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue scanning the live flattening/orchestration path for the next smallest helper family adjacent to this entrypoint,
  - keep deprioritizing dormant legacy factorization helpers until they become operationally relevant again.
## 2026-03-08: Backend convergence micro-slice (AST condition-helper ownership)
- Current worktree moves `create_condition_expression()`, `convert_condition_to_ast()`, and `convert_test_value_to_ast()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`, while keeping `FlattenedDT` as compatibility delegates.
- This slice targets the next smallest still-live helper family after confirming the nearby legacy factorization and AST naming helpers are mostly dormant, while the moved trio is exercised directly during branch/test flattening and assignment/transition condition construction.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Important note:
  - explicit `use FSM::AST::Utils;` in `EnableGraph` is currently unsafe in this repo because it exposes an incompatible helper load path; the moved methods work when left on the existing runtime path without that import.
- Immediate next direction after commit:
  - continue scanning for the next smallest active helper or entrypoint still exercised by the live flattening/orchestration/backend path,
  - keep deprioritizing dormant legacy helper blocks until they become operationally relevant.
## 2026-03-07: Backend convergence micro-slice (WEN/EN prescan entrypoint ownership)
- Current worktree moves `prescan_wen_en_for_intermediate_signals()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- This slice picks the smallest still-live helper on the active SystemVerilog generation path after confirming the nearby AST-based naming helpers are mostly idle compatibility code.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining active helper/ownership seams in `FlattenedDT`,
  - prioritize another behavior-preserving seam that is still exercised by the live Orchestrator/backend path rather than the mostly idle legacy naming utilities.
## 2026-03-07: Backend convergence micro-slice (AST sub-expression analysis helper ownership)
- Current worktree moves `analyze_ast_sub_expressions()`, `find_all_ast_sub_expressions()`, and `is_simple_ast_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, while keeping `FlattenedDT` as compatibility delegates.
- This slice localizes a small cohesive AST-analysis trio from the adjacent factorization helper cluster without pulling in the larger legacy string-based factorization family.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining adjacent factorization/helper cluster in `FlattenedDT`,
  - prioritize the next smallest cohesive family that reduces `FlattenedDT` ownership without behavior change.
## 2026-03-07: Backend convergence micro-slice (intermediate-signal generation entrypoint ownership)
- Current worktree moves `generate_intermediate_signals()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- The moved entrypoint is a clean backend-facing seam because its active dependency, `run_global_ast_factorization()`, is already backend-owned.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue shrinking the adjacent legacy factorization/helper cluster around intermediate-signal generation in `FlattenedDT`,
  - prioritize the next smallest backend-owned entrypoint or helper family that can move without changing behavior.
## 2026-03-07: Backend convergence micro-slice (logical-op-count helper-pair ownership)
- Current worktree moves `_count_logical_ops_in_ast()` and `_is_factorizable_sub_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, while keeping `FlattenedDT` as compatibility delegates.
- The backend logical-op-count family is now locally self-contained for the active counting flow:
  - `count_binary_logical_operation_occurrences()`
  - `collect_all_wen_en_ast_expressions()`
  - `_count_logical_ops_in_ast()`
  - `_is_factorizable_sub_expression()`
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Roadmap decision update:
  - roadmap item 5 now assumes retiring legacy `.plg` / `PPlugin.pm` support in favor of a more standard typed-hook mechanism rather than preserving plugin compatibility.
- Immediate next direction after commit:
  - re-scan `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` for the next smallest backend/facade ownership seam beyond the now-local logical-op-count family,
  - keep the same one-slice, regression-first cadence.
## 2026-03-07: Backend convergence micro-slice (logical-op-count collector ownership)
- Current worktree moves `collect_all_wen_en_ast_expressions()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- The backend logical-op-count flow now calls `$self->collect_all_wen_en_ast_expressions()` locally; the remaining direct backend `FlattenedDT` helper round-trip inside this family is `_count_logical_ops_in_ast()`, which still relies on `_is_factorizable_sub_expression()`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - move `_count_logical_ops_in_ast()` ownership into backend together with the coupled `_is_factorizable_sub_expression()` policy helper,
  - then re-scan the logical-op-count family for any remaining backend/facade round-trips.
## 2026-03-07: Backend convergence micro-slice (logical-op-count entrypoint ownership)
- Current worktree moves `count_binary_logical_operation_occurrences()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- The backend entrypoint now owns the counting flow directly; remaining direct backend `FlattenedDT` helper calls inside this family are:
  - `collect_all_wen_en_ast_expressions()`
  - `_count_logical_ops_in_ast()`
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue shrinking the logical-op-count family by localizing the remaining backend helper round-trips,
  - likely start with `collect_all_wen_en_ast_expressions()` before the deeper `_count_logical_ops_in_ast()` / `_is_factorizable_sub_expression()` pair.
## 2026-03-07: Backend convergence micro-slice (logical-op-count wrapper callsite)
- Current worktree localizes the remaining direct `run_global_ast_factorization` backend method-call round-trip in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by routing `count_binary_logical_operation_occurrences()` through a backend-local helper instead of calling `FlattenedDT` directly from the factorization flow.
- The slice adds a backend-local `count_binary_logical_operation_occurrences()` helper and switches the `run_global_ast_factorization` fallback callsite to `$self->count_binary_logical_operation_occurrences()`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - move the logical-op-count implementation family itself into backend ownership so the new backend-local helper stops delegating through `FlattenedDT`,
  - then re-scan for the next smallest backend/helper ownership seam.
## 2026-03-07: Backend convergence micro-slice (bare intermediate-signal trace render callsite)
- Current worktree localizes one remaining backend render/helper round-trip in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from a `FlattenedDT` method call (`$ctx->ast_to_clean_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the bare `FSM::HDL::IntermediateSignalRef` trace render in `ast_contains_intermediate_signals`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - direct backend `$ctx->method(...)` round-trips in `Backend/SystemVerilog.pm` are now reduced to one,
  - prioritize the remaining `count_binary_logical_operation_occurrences()` callsite in `run_global_ast_factorization`.
## 2026-03-07: Backend convergence micro-slice (factorizer substituted-AST trace render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the factorizer substituted-AST trace render in `get_substituted_ast_for_signal`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - exact backend `$ctx->ast_to_systemverilog(...)` pass-throughs in `perl/FSM/HDL/FlattenedDT/Backend` are now exhausted,
  - re-scan for the next smallest remaining backend ownership seam beyond this exact render-pass-through pattern.
## 2026-03-07: Backend convergence micro-slice (assignment-condition second-pass substituted-AST debug render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the assignment-condition substituted-AST debug render in `update_original_asts_with_second_pass_substitutions`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the later factorizer substituted-AST trace render callsite in `get_substituted_ast_for_signal`.
## 2026-03-07: Backend convergence micro-slice (assignment-condition second-pass original-AST debug render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the assignment-condition original-AST debug render in `update_original_asts_with_second_pass_substitutions`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the adjacent assignment-condition substituted-AST debug render callsite and then the later factorizer substituted-AST trace render.
## 2026-03-07: Backend convergence micro-slice (LHS-level second-pass substituted-AST debug render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the LHS-level substituted-AST debug render in `update_original_asts_with_second_pass_substitutions`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the assignment-condition second-pass original/substituted debug render callsites and then the later factorizer substituted-AST trace render.
## 2026-03-07: Backend convergence micro-slice (LHS-level second-pass original-AST debug render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the LHS-level original-AST debug render in `update_original_asts_with_second_pass_substitutions`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the adjacent LHS-level substituted-AST debug render and then the assignment-condition second-pass debug render callsites with the same one-callsite cadence.
## 2026-03-07: Backend convergence micro-slice (DT-specific second-pass substituted-AST debug render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the DT-specific substituted-AST debug render in `update_original_asts_with_second_pass_substitutions`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the adjacent LHS-level and assignment-condition second-pass debug render callsites with the same one-callsite cadence.
## 2026-03-07: Backend convergence micro-slice (original-AST consolidated fallback render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the original-AST fallback branch of consolidated intermediate-signal assign generation (`generate_consolidated_intermediate_signals`).
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the remaining second-pass update render callsites with the same one-callsite cadence.
## 2026-03-07: Backend convergence micro-slice (substituted-AST consolidated render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the substituted-AST branch of consolidated intermediate-signal assign generation (`generate_consolidated_intermediate_signals`).
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the adjacent original-AST fallback in consolidated assign generation or the later second-pass update paths with the same one-callsite cadence.
## 2026-03-06: Backend convergence micro-slice (final-filtered debug AST render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is in the final-filtered debug listing inside consolidated intermediate-signal generation (`generate_consolidated_intermediate_signals`).
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the consolidated-intermediate substituted-AST render path or the later second-pass update paths with the same one-callsite cadence.
## 2026-03-06: Backend convergence micro-slice (rescued-signal debug AST render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is in the rescued-signal debug listing inside consolidated intermediate-signal generation (`generate_consolidated_intermediate_signals`).
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the adjacent final-filtered debug render or the later substituted-AST render/update paths with the same one-callsite cadence.
## 2026-03-06: Backend convergence micro-slice (initial-filtering AST render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is in the initial filtering pass inside consolidated intermediate-signal generation (`generate_consolidated_intermediate_signals`).
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - keep the same one-callsite micro-slice cadence with full validation and commit workflow.
## 2026-03-06: README onboarding hub update
- `README.md` was restructured to serve as the single entry point to the project.
- README now includes:
  - explicit project objective,
  - full markdown index for fast ramp-up (`README.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md`, `MEMORY.md`, `COMMIT.md`, `WARP.md`, `docs/USER_GUIDE.md`, `.agents/workflows/commit.md`),
  - key project file/path map for core entrypoints and supporting directories,
  - README maintenance policy clarifying update cadence (when it materially affects onboarding).
- `README.md` remains tracked in git; change is prepared for commit workflow completion.
## Current technical status (updated 2026-02-27)
- Assignment families are implemented and stabilized: `c`, `r`, `m`, `rm`, `mr`, `pN`.
- `pN` semantics are authoritative and must not regress:
  - `<N` means exact delay to cycle `Q+N` (not duration).
  - one-cycle pulse only.
  - `<N 1`: positive pulse (`0->1->0`), `<N 0`: negative pulse (`1->0->1`).
- Regression baseline is currently green:
  - `prove -I perl t`
  - `Files=6, Tests=125, PASS`.
- FlattenedDT decomposition direction is now explicitly two-track:
  - `Orchestrator` (pipeline sequencing ownership),
  - `Backend` (render/emitter ownership).
- `EnableGraph` remains a synthesis helper module (`FSM::Synthesis::EnableGraph`) used by `FlattenedDT`, not a direct submodule in the `FlattenedDT` breakdown.
- First orchestrator decomposition slice is complete:
  - `generate_systemverilog` orchestration has been moved into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`,
  - `FlattenedDT` now delegates this entrypoint through a compatibility facade.
- First backend decomposition slice is complete:
  - module declaration emission (`generate_module_declaration`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Second backend decomposition slice is complete:
  - state-encoding emission (`generate_state_encoding`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Third backend decomposition slice is complete:
  - state-register emission (`generate_state_register`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Fourth backend decomposition slice is complete:
  - enable-conditions emission (`generate_enable_conditions`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Fifth backend decomposition slice is complete:
  - header emission (`generate_header`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Sixth backend decomposition slice is complete:
  - internal-signal declaration emission (`generate_internal_signal_declarations`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Seventh backend decomposition slice is complete:
  - Verilog generation ownership (`generate_verilog`, `convert_systemverilog_to_verilog`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm`,
  - `FlattenedDT` now delegates these Verilog backend entrypoints through a compatibility facade.
- Eighth backend decomposition slice is complete:
  - WEN/EN emission entrypoint ownership (`generate_wen_en_signals`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Ninth backend decomposition slice is complete:
  - intermediate-signal declaration emission ownership (`generate_intermediate_signal_declarations`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Tenth backend decomposition slice is complete:
  - combinational-mux emission ownership (`generate_comb_mux`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Eleventh backend decomposition slice is complete:
  - flop-mux emission ownership (`generate_flop_mux`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Twelfth backend decomposition slice is complete:
  - consolidated intermediate-signal emission ownership (`generate_consolidated_intermediate_signals`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Thirteenth backend decomposition slice is complete:
  - global AST-factorization orchestration ownership (`run_global_ast_factorization`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Fourteenth backend decomposition slice is complete:
  - AST-factorizer input feeding ownership (`feed_asts_to_factorizer`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Fifteenth backend decomposition slice is complete:
  - unary-negation counting helper ownership (`count_unary_negations_in_original_expressions`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Sixteenth backend decomposition slice is complete:
  - AST substitution-backpropagation helper ownership (`update_original_asts_with_substituted_versions`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Seventeenth backend decomposition slice is complete:
  - second-pass factorization orchestration ownership (`run_second_pass_factorization`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Eighteenth backend decomposition slice is complete:
  - created shared backend-neutral factorization package `perl/FSM/HDL/Factorization/Fixpoint.pm`,
  - moved iterative post-substitution factorization loop ownership into `FSM::HDL::Factorization::Fixpoint`,
  - `Backend::SystemVerilog` now delegates `run_second_pass_factorization` to the shared package via compatibility entrypoint.
- Nineteenth backend decomposition slice is complete:
  - second-pass AST feeding ownership (`feed_current_asts_to_second_pass`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Twentieth backend decomposition slice is complete:
  - second-pass AST substitution update ownership (`update_original_asts_with_second_pass_substitutions`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Twenty-first backend decomposition slice is complete:
  - second-pass intermediate-expression filter ownership (`ast_contains_intermediate_signals`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Twenty-second backend decomposition slice is complete:
  - recursive intermediate-signal detection helper ownership (`ast_has_intermediate_signals_recursive`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Twenty-third backend decomposition slice is complete:
  - substituted-intermediate AST resolver ownership (`get_substituted_ast_for_signal`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Post-substitution factorization behavior now uses iterative convergence until stable with deterministic termination guards:
  - stops on no factorizable expressions, no new candidates, repeated expression signature, no substitution progress, or max-pass cap.
- Commit workflow documentation is now explicit and tracked:
  - added `COMMIT.md` as the canonical workflow reference for future AI handoff,
  - includes involved files, exact execution order, and run frequency (after each completed task/activity).
- First-class tracing is now integrated into FSMGen runtime surfaces:
  - canonical trace verbosity names are supported: `none`, `low`, `medium`, `high`, `debug` (mapped to levels `0..4`),
  - numeric debug compatibility remains supported through `--debug[=N]` with bare `--debug` mapped to level `4`,
  - CLI now supports trace controls: `--trace-verbosity`, `--trace-log[=FILE]`, `--trace-emojis`/`--notrace-emojis`,
  - when trace-file routing is enabled, trace output is routed to `trace.log` (or configured file) instead of stdout,
  - trace records include source metadata (`file`, `function`, `line`) and structured kinds (`topic`, `enter`, `exit`, `decision`) with indentation-aware formatting.
- Trace instrumentation was integrated in key pipeline/parser facades:
  - `perl/FSM/Pipeline/HDLGenerator.pm`,
  - `perl/FSM/Adapter/FSMGenFull.pm`,
  - `perl/FSM/Adapter/FSMGenFull/Parser.pm`.
- User-facing and regression coverage for tracing were updated:
  - docs updated in `README.md` and `docs/USER_GUIDE.md`,
  - new trace regression `t/06-tracing-system.t` added and passing.
## EnableGraph extraction status
Behavior-preserving extraction from `FlattenedDT` into `EnableGraph` is active and working.
### Already moved into `perl/FSM/Synthesis/EnableGraph.pm`
- `build_unified_assignment_analysis`
- `group_assignments_by_rhs`
- `generate_complete_enable_structure`
- `build_multiplexer_config`
- `generate_unified_wen_en_signals`
- `generate_dt_enables_from_analysis`
- `generate_lhs_enables_from_analysis`
- `generate_signal_assignments`
- `generate_unified_comb_mux`
- `generate_unified_flop_mux`
- `generate_unified_pulse_delay_logic`
- `get_pulse_delay_cycles_for_lhs`
- `get_pulse_active_level_for_lhs`
- `normalize_rhs_logic_level`
- `clean_signal_name`
- `generate_rhs_based_enable_name`
- `signal_uses_register_assignment`
- `get_signal_assignment_type`
- `get_driven_signals`
- `get_reset_value`
- `get_default_value`
- `get_signal_info`
- `get_explicit_reset_value`
- `get_fsm_reset_state`
- `get_reset_value_from_ast`
- `get_default_value_from_ast`
- `set_explicit_reset_values`
- `set_fsm_module_reference`
- `is_register`
- `fallback_register_analysis_from_assignments`
- `extract_signal_name_from_ast`
- `get_lhs_width_from_analysis`
- `track_ast_intermediate_signals`
- `is_intermediate_signal`
- `is_signal_ast_based_intermediate`
- `_ast_contains_factorizable_operators`
- `is_arithmetic_operation`
- `is_logical_operation`
- `should_factor_logical_operation`
- `contains_frequently_used_operations`
- `get_intermediate_signal_expression`
- `generate_expression_from_signal_name`
- `_signal_name_indicates_ast_operators`
- `ast_to_systemverilog`
### Still strong candidates for next slices
- the direct EnableGraph-to-FlattenedDT helper seam is now essentially exhausted for this extraction lane; any further moves would be deeper AST-render internals.
- broader decomposition remains the next architectural lever:
  - continue `EnableGraph` helper ownership where clear,
  - extract backend emitters into dedicated modules,
  - keep `FlattenedDT` as thin facade/compatibility shell.
## Recent milestone commits (most recent first)
- `WORKTREE (pending commit)` Continue backend decomposition by extracting `get_substituted_ast_for_signal` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `7c44abc` Extract AST substitution-backpropagation helper into SV backend
- `586a2f8` Extract unary-negation counter helper into SV backend
- `f2c4422` Extract AST factorizer input feeding into SV backend
- `c9db9e2` Extract global AST factorization orchestration into SV backend
- `07329fb` Extract consolidated intermediate signal emission into SV backend
- `c2dfaaf` Add first-class multi-level tracing with structured metadata, trace.log routing, CLI controls, parser/pipeline hooks, and regression coverage
- `886b5f1` Add canonical `COMMIT.md` with precise commit workflow definition for AI handoff continuity
- `3adf1f8` Continue backend decomposition by extracting `generate_flop_mux` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `ebf90f2` Continue backend decomposition by extracting `generate_comb_mux` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `a89fa9c` Continue backend decomposition by extracting `generate_intermediate_signal_declarations` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `b9c81dc` Continue backend decomposition by extracting `generate_wen_en_signals` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `5de2f44` Add dedicated `FlattenedDT::Backend::Verilog` and move `generate_verilog`/`convert_systemverilog_to_verilog` ownership there with compatibility delegation in `FlattenedDT`
- `1f0b44b` Continue backend decomposition by extracting `generate_internal_signal_declarations` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `0313969` Continue backend decomposition by extracting `generate_header` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `0d80108` Continue backend decomposition by extracting `generate_enable_conditions` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `637678f` Continue backend decomposition by extracting `generate_state_register` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `7dc5461` Continue backend decomposition by extracting `generate_state_encoding` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `082eab2` Start backend decomposition by extracting `generate_module_declaration` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `dd82368` Start explicit `FlattenedDT` decomposition by extracting `generate_systemverilog` pipeline sequencing into `FlattenedDT::Orchestrator` with compatibility delegation in `FlattenedDT`
- `1b1036a` Delegate AST-to-SystemVerilog rendering helper ownership to `EnableGraph` (`ast_to_systemverilog`) with compatibility delegation in `FlattenedDT`
- `4840580` Delegate AST-based intermediate-name metadata helper ownership to `EnableGraph`
- `ac9b39e` Delegate intermediate-signal expression synthesis helper ownership to `EnableGraph`
- `4fec56e` Delegate intermediate-signal expression resolver ownership to `EnableGraph`
- `4a0cd02` Delegate frequent-logical-usage helper ownership to `EnableGraph`
- `0a4dd6e` Delegate logical-factorization policy helper ownership to `EnableGraph`
- `b3f5f73` Delegate logical-operation helper ownership to `EnableGraph`
- `7b1f2b8` Delegate arithmetic-operation helper ownership to `EnableGraph`
- `ddaaabe` Delegate AST factorization operator helper ownership to `EnableGraph`
- `eb1de0d` Delegate AST-based intermediate classification helper ownership to `EnableGraph`
- `8c5f23b` Delegate intermediate-signal classification helper ownership to `EnableGraph`
- `9bb41eb` Delegate intermediate-signal AST tracker ownership to `EnableGraph`
- `fe6360c` Delegate LHS-width analysis helper ownership to `EnableGraph`
- `e087dac` Delegate AST signal-name extraction helper ownership to `EnableGraph`
- `01312fa` Delegate register-classification helper ownership to `EnableGraph`
- `9ebea2f` Delegate FSM module-reference setter ownership to `EnableGraph`
- `250a55f` Delegate explicit-reset config setter ownership to `EnableGraph`
- `30d21cc` Delegate AST default-value helper ownership to `EnableGraph`
- `c3dcf04` Delegate AST reset-value helper ownership to `EnableGraph`
- `7705725` Delegate FSM reset-state helper ownership to `EnableGraph`
- `0465b90` Delegate explicit-reset helper ownership to `EnableGraph`
- `0aeb0fc` Delegate signal-info helper ownership to `EnableGraph`
- `2ee1c64` Delegate default-value helper ownership to `EnableGraph`
- `820481c` Delegate reset-value helper ownership to `EnableGraph`
- `dfc92dd` Delegate driven-signal classification to `EnableGraph`
- `c18c35b` Delegate assignment-type helper ownership to EnableGraph
- `a82d5cd` Delegate enable naming helper ownership to EnableGraph
- `59a86d3` Delegate pulse helper analysis ownership to EnableGraph
- `d65e86a` Delegate unified pulse-delay emission to EnableGraph
- `a2725c9` Add live MEMORY.md continuity document and update workflow policy
- `0bf08d4` Delegate unified flop mux emission to EnableGraph
- `1f29750` Delegate unified combinational mux emission to EnableGraph
- `d4dc317` Delegate unified phase-3 assignment orchestration to EnableGraph
- `32892d4` Delegate unified phase-2 WEN/EN emission to EnableGraph
- `f62d6fe` Extract unified assignment-analysis orchestration into EnableGraph
- `6bb94d4` Extract multiplexer config assembly into EnableGraph synthesis layer
- `36a574f` Extract RHS grouping orchestration into EnableGraph synthesis layer
- `2a05831` Add assignment edge/snapshot regressions and extract initial EnableGraph layer
- `fe1cc3c` Implement c/r/m/rm/mr/pN assignment semantics and document pN as Q+N delay
## Quick resume checklist
1. Read `MEMORY.md` first.
2. Read latest entries in `CHANGES.md` and `DEVELOPMENT_NOTES.md`.
3. Check repo state: `git --no-pager status --short`.
4. Run baseline regression: `prove -I perl t`.
5. Continue the next extraction slice with behavior-preserving delegation.
6. Before committing, update `MEMORY.md` and related live docs again.
## Live document references
- `CHANGES.md`: persistent technical change history.
- `DEVELOPMENT_NOTES.md`: rationale, architecture, and policy-level technical knowledge.
- `docs/USER_GUIDE.md`: user-facing usage guidance.
- `README.md`: project overview and quickstart.
## AST/CoreAST convergence status (March 11, 2026)
- Live declaration path confirmation:
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` calls `generate_consolidated_intermediate_signals(...)` on the active SystemVerilog runtime path,
  - `generate_intermediate_signal_declarations(...)` is currently compatibility-only and was intentionally left out of this slice.
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - consolidated intermediate-signal widths are now normalized across AST-factorization, prescan-reference, and FSMGen-native sources,
  - width resolution now prefers `EnableGraph::get_signal_info(...)` and defining ASTs,
  - parsed expression re-entry remains only as a narrow compatibility fallback,
  - substituted factorizer AST nodes (`FSM::HDL::IntermediateSignalRef`, `FSM::HDL::SubstitutedUnaryOp`, `FSM::HDL::SubstitutedBinaryOp`) are handled in the live backend width resolver so emitted wire widths are no longer driven by placeholder `1` values.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before this slice:
  - `e853005` `SystemVerilog: cache defining ASTs for filtering`
  - `82809ac` `SystemVerilog: use AST traversal for intermediate deps`
  - `ec61da7` `EnableGraph: store AST-backed intermediate registry metadata`
- Highest-value next seam after this slice:
  - continue removing expression-only compatibility fallbacks from consolidated intermediate handling,
  - only spend cleanup effort on dormant declaration helpers when they are either reactivated on the runtime path or can be retired outright.
## AST/CoreAST convergence update (March 11, 2026, later slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - consolidated intermediate handling now normalizes a runtime AST per signal before dependency analysis, filtering, and assign emission,
  - runtime AST resolution prefers substituted factorizer ASTs first, then defining ASTs, and parses stored expressions only as compatibility fallback,
  - the active consolidated path now renders/debugs/emits from that runtime AST-first view instead of maintaining separate raw-expression branches in each phase.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `0d91234` `SystemVerilog: derive consolidated intermediate widths from AST`
  - `e853005` `SystemVerilog: cache defining ASTs for filtering`
  - `82809ac` `SystemVerilog: use AST traversal for intermediate deps`
- Highest-value next seam after this slice:
  - narrow or eliminate the remaining compatibility-only misses where runtime-AST resolution still falls back to `extract_intermediate_signals_from_expression(...)` or `should_filter_string_based(...)`,
  - keep ignoring dormant standalone declaration helpers unless they become live again or are being retired outright.
## AST/CoreAST convergence update (March 11, 2026, dependency slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - consolidated intermediate dependencies are now normalized and cached per signal before dependency-aware filtering,
  - dependency metadata is resolved from runtime AST traversal first,
  - expression-based dependency extraction remains only as the compatibility fallback inside `resolve_intermediate_signal_dependencies(...)`.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `5ea13ab` `SystemVerilog: normalize consolidated intermediate runtime ASTs`
  - `0d91234` `SystemVerilog: derive consolidated intermediate widths from AST`
  - `e853005` `SystemVerilog: cache defining ASTs for filtering`
- Highest-value next seam after this slice:
  - narrow or eliminate the remaining compatibility-only runtime-AST misses that still fall through to `extract_intermediate_signals_from_expression(...)` or `should_filter_string_based(...)`,
  - keep deferring dormant standalone declaration-helper cleanup unless it becomes live or can be removed outright.
## AST/CoreAST convergence update (March 11, 2026, render slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - consolidated rendered-expression metadata is now normalized and cached per signal before the live dependency/filter/emit phases run,
  - prescan merge no longer eagerly stores `expression` text for entries that already have runtime AST coverage,
  - expression text remains merge-time/live-time compatibility metadata only for runtime-AST misses.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `2480832` `SystemVerilog: cache consolidated intermediate dependencies`
  - `5ea13ab` `SystemVerilog: normalize consolidated intermediate runtime ASTs`
  - `0d91234` `SystemVerilog: derive consolidated intermediate widths from AST`
- Highest-value next seam after this slice:
  - narrow the remaining compatibility-only runtime-AST miss path itself, especially the cases that still fall through to `extract_intermediate_signals_from_expression(...)` or `should_filter_string_based(...)`,
  - keep deferring dormant standalone declaration-helper cleanup unless it becomes live or is being removed outright.
## AST/CoreAST convergence update (March 11, 2026, miss-state slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - consolidated runtime-AST miss state is now cached per signal,
  - signals now carry explicit runtime-AST resolution state (`resolved` or `missing`) plus a miss reason,
  - later live-path helpers reuse that cached miss state instead of retrying the same AST recovery path repeatedly.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `548ca11` `SystemVerilog: cache consolidated rendered expressions`
  - `2480832` `SystemVerilog: cache consolidated intermediate dependencies`
  - `5ea13ab` `SystemVerilog: normalize consolidated intermediate runtime ASTs`
- Highest-value next seam after this slice:
  - narrow the compatibility behavior that still hangs off explicit runtime-AST misses, especially `extract_intermediate_signals_from_expression(...)` and the legacy-named filter fallback,
  - keep deferring dormant standalone declaration-helper cleanup unless it becomes live or is being removed outright.
## AST/CoreAST convergence update (March 11, 2026, recovery slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - late expression hydration can now recover runtime ASTs for signals whose earlier miss was only `no_ast_source`,
  - dependency extraction now renders first and then re-checks runtime AST availability, so recovered ASTs are used in the same consolidated pass,
  - this reduces the population of true compatibility-only misses without touching dormant helper paths.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `e4af447` `SystemVerilog: cache runtime AST miss state`
  - `548ca11` `SystemVerilog: cache consolidated rendered expressions`
  - `2480832` `SystemVerilog: cache consolidated intermediate dependencies`
- Highest-value next seam after this slice:
  - narrow the remaining hard compatibility misses where runtime-AST recovery still cannot succeed, especially expression-parse failures and the fallback helper path that still carries the old string-era name,
  - keep deferring dormant standalone declaration-helper cleanup unless it becomes live or is being removed outright.
## AST/CoreAST convergence update (March 12, 2026, dependency-miss recovery slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - explicit runtime-AST misses during dependency extraction now flow through `extract_intermediate_signals_from_runtime_ast_miss(...)`,
  - the live path skips re-parsing the same stored expression after a known `expression_parse_failed` miss,
  - dependency extraction now probes alternate known expressions from `EnableGraph` before dropping to identifier scanning,
  - when one of those alternate expressions parses, the backend caches the recovered runtime AST and refreshes width metadata so later live-path phases can reuse the AST-backed signal.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `85aa70d` `SystemVerilog: recover runtime ASTs after late expressions`
  - `e4af447` `SystemVerilog: cache runtime AST miss state`
  - `548ca11` `SystemVerilog: cache consolidated rendered expressions`
- Highest-value next seam after this slice:
  - narrow the remaining explicit-miss filtering residue, especially the legacy-named `should_filter_string_based(...)` path,
  - after that, reduce or retire the final identifier-scan compatibility fallback if no additional AST-backed recovery source remains.
## AST/CoreAST convergence update (March 12, 2026, live-usage filtering slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - the live consolidated path now caches AST-derived live-usage metadata per intermediate signal,
  - AST-backed filtering and explicit runtime-AST-miss filtering both consume that normalized metadata,
  - explicit misses now flow through `should_filter_runtime_ast_miss(...)` while `should_filter_string_based(...)` remains only as a compatibility wrapper.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `8342857` `SystemVerilog: recover runtime ASTs in dependency fallback`
  - `85aa70d` `SystemVerilog: recover runtime ASTs after late expressions`
  - `e4af447` `SystemVerilog: cache runtime AST miss state`
- Highest-value next seam after this slice:
  - retire or bypass the remaining legacy-named filtering wrapper entirely once no live path needs it,
  - then tighten the last identifier-scan compatibility fallback in dependency extraction if another AST-backed recovery source can replace it.
## AST/CoreAST convergence update (March 12, 2026, unresolved-miss cleanup slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and `t/07-runtime-ast-miss-dependency-recovery.t`:
  - removed the final `scan_intermediate_signal_names_in_expression(...)` regex fallback from runtime-AST-miss dependency recovery,
  - explicit hard misses now stop at AST-backed recovery sources and record `runtime_ast_miss_unresolved` instead of inferring dependencies from opaque invalid strings,
  - the focused regression now proves opaque invalid expressions like `mid @@ aux` no longer recover `mid`/`aux` through identifier mining.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` => `Files=1`, `Tests=8`, `PASS`
  - `prove -I perl t` => `Files=8`, `Tests=143`, `PASS`
- Additional audit completed for this slice:
  - read-only instrumentation on known-good fixtures (`fsm/trial_0.fsm`, `fsm/trial_1.fsm`, `fsm/trial_2.fsm`, `fsm/mipicsi2_tester_ctrl.fsm`) reported zero live hits on the identifier-scan fallback before removal.
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `9a3e386` `EnableGraph: recover legacy signal-name deps via AST`
  - `621da16` `CoreAST: canonicalize driving AST storage`
  - `3243d00` `SystemVerilog: recover deps from signal-name ASTs`
- Highest-value next seam after this slice:
  - characterize which remaining opaque `legacy_string_registry` producers still fail to provide native defining AST or typed dependency metadata,
  - keep shrinking or retiring other dormant string-era compatibility helpers once they are proven dead in the live path.
## AST/CoreAST convergence update (March 13, 2026, dead-LHS/RHS-tracking cleanup slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT.pm`, `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`, and `t/10-ast-first-enable-structure.t`:
  - removed the dormant LHS/RHS completeness-tracking family from `FlattenedDT`, including the legacy `expected_lhs_rhs` / `actual_lhs_rhs` / `missing_lhs_rhs` state and the raw-AST walker/formatter helpers that only existed to feed that validation lane,
  - removed the assignment/transition capture instrumentation in `Orchestrator` that still wrote `actual_lhs_rhs` entries even though no live path consumed them,
  - extended the AST-first enable-structure regression to assert that live generation leaves no legacy LHS/RHS tracking state behind.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` => `Files=1`, `Tests=9`, `PASS`
  - `prove -I perl t` => `Files=10`, `Tests=155`, `PASS`
- Additional audit completed for this slice:
  - repo-wide reference checks showed the retired LHS/RHS tracking helpers and state names remained only in docs and the new regression assertions,
  - the only live writes into that lane had been the `Orchestrator` assignment/transition capture hooks, and no runtime/backend path read the resulting hashes.
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `0aa9a84` `FlattenedDT: retire dead string-era condition and WEN helpers`
  - `918a2ca` `FlattenedDT: retire dead string-era factorization helpers`
  - `45d3320` `SystemVerilog: retire identifier-scan dependency fallback`
- Highest-value next seam after this slice:
  - re-audit the remaining unreferenced `FlattenedDT` helper pockets, especially declaration-scheduling and substituted-AST matching helpers, to find the next dead surface that can be retired without perturbing the live AST/CoreAST path,
  - keep preferring slices that delete provably dead compatibility state over widening live backend/orchestrator behavior.
## AST/CoreAST convergence update (March 13, 2026, dead-standalone-declaration-helper cleanup slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT.pm`, `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and `t/10-ast-first-enable-structure.t`:
  - removed the dead standalone intermediate-declaration helper lane from `FlattenedDT`, including `schedule_intermediate_signal_for_declaration(...)`, the compatibility-only `generate_intermediate_signal_declarations(...)` delegate, and the adjacent unreferenced `get_combinational_lhs_signals(...)` helper,
  - removed the backend-side `generate_intermediate_signal_declarations(...)` implementation that no live call path used once consolidated intermediate emission became authoritative,
  - extended the AST-first enable-structure regression to assert that live generation leaves no legacy `intermediate_signals_to_declare` scratch state behind.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` => `Files=1`, `Tests=10`, `PASS`
  - `prove -I perl t` => `Files=10`, `Tests=156`, `PASS`
- Additional audit completed for this slice:
  - repo-wide reference checks showed the retired declaration helper names had no remaining code callers and only the new regression assertion mentions the retired scratch-state name,
  - the live declaration path already emits intermediate wires through consolidated emission/internal declarations rather than the old standalone helper lane.
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `413d6cb` `FlattenedDT: retire dead LHS/RHS tracking`
  - `0aa9a84` `FlattenedDT: retire dead string-era condition and WEN helpers`
  - `918a2ca` `FlattenedDT: retire dead string-era factorization helpers`
- Highest-value next seam after this slice:
  - re-audit the remaining substituted-AST matching helper pocket in `FlattenedDT` (`find_substituted_ast`, `ast_contains_intermediate_signal_references`, `expressions_are_equivalent`, `extract_expression_structure`, `ast_structures_match`) to confirm whether it is now fully dead,
  - keep deleting provably dead compatibility helpers before considering larger live-path ownership moves.
## AST/CoreAST convergence update (March 13, 2026, dead-substituted-AST-matching-helper cleanup slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT.pm`:
  - removed the dead substituted-AST matching helper pocket, including `signal_name_matches_operation(...)`, `find_substituted_ast(...)`, `ast_contains_intermediate_signal_references(...)`, `expressions_are_equivalent(...)`, `extract_expression_structure(...)`, and `ast_structures_match(...)`,
  - removed the now-unused `Data::Dumper`, `Scalar::Util qw(blessed)`, and `List::Util qw(min max)` imports that only supported that dead helper lane.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` => `Files=10`, `Tests=156`, `PASS`
- Additional audit completed for this slice:
  - repo-wide reference checks showed the retired helper names had no remaining code callers and only historical docs still mention the old pocket,
  - the active substitution/factorization flow already routes through backend-owned helpers such as `update_original_asts_with_substituted_versions(...)`, `get_substituted_ast_for_signal(...)`, and `is_signal_referenced_in_substitutions(...)`.
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `ce1d9b9` `FlattenedDT: retire dead declaration helpers`
  - `413d6cb` `FlattenedDT: retire dead LHS/RHS tracking`
  - `0aa9a84` `FlattenedDT: retire dead string-era condition and WEN helpers`
- Highest-value next seam after this slice:
  - re-audit the remaining substitution-era helper surface in `FlattenedDT` and `Backend/SystemVerilog` to identify the next truly dead residue versus the still-live backend-owned helpers,
  - if no more dead pockets remain nearby, shift back to the next smallest live AST/CoreAST-first ownership seam rather than forcing more facade cleanup.
## AST/CoreAST convergence update (March 12, 2026, dead-condition-and-wen-helper cleanup slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT.pm` and `t/10-ast-first-enable-structure.t`:
  - removed the dormant string-era condition/WEN helper island that still exposed a parallel string-based path for assignment recording, condition formatting, raw condition-string extraction, and DT-specific/LHS-level WEN generation,
  - removed the delegator helpers that only existed to support that dead path (`clean_signal_name`, `generate_rhs_based_enable_name`, `is_complex_expression`, `get_or_create_global_expression`, `should_factor_condition`, `needs_parentheses`),
  - added a focused regression proving that live enable synthesis stores AST-backed DT/LHS enable metadata inside `assignment_analysis->{rhs_groups}` and does not repopulate the old top-level `dt_specific_enables` / `lhs_to_enable_value_pairs` state.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/09-ast-first-intermediate-registry.t t/10-ast-first-enable-structure.t` => `Files=2`, `Tests=9`, `PASS`
  - `prove -I perl t` => `Files=10`, `Tests=152`, `PASS`
- Additional audit completed for this slice:
  - repo-wide reference checks showed the retired helper names remained only in `DEVELOPMENT_NOTES.md` and `MEMORY.md`,
  - the live path already records assignments/transitions through `FlattenedDT::Orchestrator` and synthesizes DT/LHS enable metadata inside `EnableGraph`-owned `assignment_analysis->{rhs_groups}`.
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `918a2ca` `FlattenedDT: retire dead string-era factorization helpers`
  - `45d3320` `SystemVerilog: retire identifier-scan dependency fallback`
  - `9a3e386` `EnableGraph: recover legacy signal-name deps via AST`
- Highest-value next seam after this slice:
  - re-audit the remaining `FlattenedDT` compatibility/helper surface to find the next dead string-era island or delegation round-trip that can be removed without touching the live AST/CoreAST path,
  - keep validating against the AST-backed `assignment_analysis->{rhs_groups}` enable structure instead of reintroducing top-level compatibility state.
## AST/CoreAST convergence update (March 12, 2026, dead-factorization-cluster cleanup slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT.pm` and `t/09-ast-first-intermediate-registry.t`:
  - removed the dormant string-era factorization/helper cluster that still wrote plain-string `intermediate_signals` entries in the old `FlattenedDT` facade,
  - updated the remaining `intermediate_signals` comment/contract to reflect metadata-hash storage rather than raw expression-string storage,
  - added a focused regression proving that live generation leaves no plain-string or `legacy_string_registry` intermediate entries behind.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/09-ast-first-intermediate-registry.t` => `Files=1`, `Tests=3`, `PASS`
  - `prove -I perl t` => `Files=9`, `Tests=146`, `PASS`
- Additional audit completed for this slice:
  - read-only runs on known-good fixtures (`fsm/trial_0.fsm`, `fsm/trial_1.fsm`, `fsm/trial_2.fsm`, `fsm/mipicsi2_tester_ctrl.fsm`) showed the live generator already finishing with an empty `intermediate_signals` registry, confirming the removed helpers were dead compatibility residue.
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `45d3320` `SystemVerilog: retire identifier-scan dependency fallback`
  - `9a3e386` `EnableGraph: recover legacy signal-name deps via AST`
  - `621da16` `CoreAST: canonicalize driving AST storage`
- Highest-value next seam after this slice:
  - audit and retire the remaining dead string-era `FlattenedDT.pm` condition / DT-specific WEN helper cluster if it is still unreferenced,
  - otherwise keep moving source-side compatibility producers onto native AST/CoreAST metadata instead of rebuilding fallback logic downstream.
## AST/CoreAST convergence update (March 12, 2026, wrapper-retirement slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and `perl/FSM/HDL/FlattenedDT.pm`:
  - removed the unused legacy-named wrapper entrypoints `should_filter_string_based(...)` and `extract_intermediate_signals_from_expression(...)`,
  - the repo surface now exposes only the runtime-shape helpers that are still semantically meaningful on this lane (`should_filter_runtime_ast_miss(...)`, `extract_intermediate_signals_from_runtime_ast_miss(...)`).
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `8467c9f` `SystemVerilog: cache live usage for miss filtering`
  - `8342857` `SystemVerilog: recover runtime ASTs in dependency fallback`
  - `85aa70d` `SystemVerilog: recover runtime ASTs after late expressions`
- Highest-value next seam after this slice:
  - tighten or replace the final identifier-scan compatibility fallback in `extract_intermediate_signals_from_runtime_ast_miss(...)`,
  - keep ignoring dormant standalone declaration helpers unless they become live or can be retired outright.
## AST/CoreAST convergence update (March 12, 2026, cleaned-dependency-recovery slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - `extract_intermediate_signals_from_runtime_ast_miss(...)` now tries cleaned-expression AST recovery before dropping to identifier scanning,
  - cleaned compatibility parse success is cached back onto runtime-AST metadata,
  - the slice preserves already-rendered expression text when the recovered AST came from the cleaned variant.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `12df12b` `SystemVerilog: retire dead string-era wrapper helpers`
  - `8467c9f` `SystemVerilog: cache live usage for miss filtering`
  - `8342857` `SystemVerilog: recover runtime ASTs in dependency fallback`
- Highest-value next seam after this slice:
  - reduce or replace the remaining identifier-scan fallback itself inside `extract_intermediate_signals_from_runtime_ast_miss(...)`,
  - keep ignoring dormant standalone declaration helpers unless they become live or can be retired outright.
## AST/CoreAST convergence update (March 12, 2026, signal-name-dependency-AST slice)
- Latest completed slice in `perl/FSM/Synthesis/EnableGraph.pm` and `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - `EnableGraph` can now recover a dependency-oriented AST from AST-generated intermediate signal names when factorizer/global-expression metadata says the name came from AST naming,
  - that recovery keeps direct intermediate operands as leaf refs instead of expanding them transitively,
  - explicit runtime-AST misses now use this signal-name AST path before the final regex identifier scan.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=7`, `Tests=130`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `8c445bf` `SystemVerilog: recover runtime ASTs before dep scan`
  - `d9a12dd` `SystemVerilog: recover deps from cleaned expressions`
  - `12df12b` `SystemVerilog: retire dead string-era wrapper helpers`
- Highest-value next seam after this slice:
  - shrink or replace the last regex identifier scan for legacy/non-AST-named hard misses,
  - keep ignoring dormant standalone declaration helpers unless they become live or can be retired outright.
## AST/CoreAST convergence update (March 12, 2026, canonical-driving-ast slice)
- Latest completed slice in `perl/FSM/CoreAST.pm`, `perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm`, and `perl/FSM/Adapter/FSMGenFull/Parser.pm`:
  - `FSM::CoreAST::Signal` now canonicalizes `set_attribute('driving_ast', ...)` onto the real `driving_ast` field and returns that canonical value through `get_attribute('driving_ast')`,
  - active frontend intermediate-signal creation now uses `set_driving_ast(...)` directly,
  - backend runtime-AST normalization can therefore recover those parser-created intermediates through the native defining-AST path instead of depending on downstream compatibility recovery.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/CoreAST.pm`
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm`
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `prove -I perl t` => `Files=8`, `Tests=140`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `3243d00` `SystemVerilog: recover deps from signal-name ASTs`
  - `8c445bf` `SystemVerilog: recover runtime ASTs before dep scan`
  - `d9a12dd` `SystemVerilog: recover deps from cleaned expressions`
- Highest-value next seam after this slice:
  - re-audit the remaining regex identifier scan after this upstream native-AST fix and remove any now-dead compatibility residue,
  - keep ignoring dormant standalone declaration helpers unless they become live or can be retired outright.
## AST/CoreAST convergence update (March 12, 2026, conservative-legacy-signal-name slice)
- Latest completed slice in `perl/FSM/Synthesis/EnableGraph.pm` and `t/07-runtime-ast-miss-dependency-recovery.t`:
  - conservative `legacy_string_registry` names can now use the same signal-name AST dependency recovery path as AST-generated names,
  - systematic legacy names now recover dependencies through AST construction/traversal,
  - only opaque legacy names still fall through to the final regex identifier scan.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `prove -I perl t` => `Files=8`, `Tests=143`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `621da16` `CoreAST: canonicalize driving AST storage`
  - `3243d00` `SystemVerilog: recover deps from signal-name ASTs`
  - `8c445bf` `SystemVerilog: recover runtime ASTs before dep scan`
- Highest-value next seam after this slice:
  - inspect whether any live callers still need the final regex identifier scan at all once opaque legacy names are characterized,
  - keep ignoring dormant standalone declaration helpers unless they become live or can be retired outright.
## AST/CoreAST convergence update (March 12, 2026, earlier-cleaned-runtime-AST slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - `resolve_intermediate_signal_runtime_ast(...)` now attempts cleaned-expression parsing after a stored-expression parse miss,
  - cleaned-expression success is cached as runtime-AST metadata,
  - `render_intermediate_signal_expression(...)` preserves the original stored expression text when the recovered runtime AST came from a cleaned compatibility expression.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `d9a12dd` `SystemVerilog: recover deps from cleaned expressions`
  - `12df12b` `SystemVerilog: retire dead string-era wrapper helpers`
  - `8467c9f` `SystemVerilog: cache live usage for miss filtering`
- Highest-value next seam after this slice:
  - reduce or replace the remaining identifier-scan fallback itself inside `extract_intermediate_signals_from_runtime_ast_miss(...)`,
  - keep ignoring dormant standalone declaration helpers unless they become live or can be retired outright.
## 2026-03-15: malformed `:=` RHS values now fail early through the directive contract
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now turns malformed `:=` RHS values into the dedicated init/reset-contract diagnostic instead of leaking raw expression-parser failures.
- [t/56-language-contract-init-directive-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/56-language-contract-init-directive-boundary.t) now locks:
  - unsupported RHS values such as `[DATAIN]` and `<start`,
  - and pipeline/CLI no-output behavior for malformed `:=` RHS values.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the malformed-RHS side of the active `:=` boundary explicitly.

## 2026-03-15: computed test-selector malformed forms now fail early
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects malformed `?(expr)` forms explicitly instead of letting them fall into incidental expression/parser errors.
- [t/55-language-contract-computed-test-selector-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/55-language-contract-computed-test-selector-boundary.t) now locks:
  - missing-expression computed selectors like `(? (=0 ...))`,
  - branchless computed selectors like `(?(| A B))`,
  - and pipeline/CLI no-output behavior for those malformed forms.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states the malformed boundary explicitly next to the supported `?(expr)` form.

## 2026-03-19: duplicate-driver failed summaries now keep child-target context too
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now explicitly locks both blocked explicit-link duplicate-driver target families:
  - top-boundary targets keep `Context: Top port '...'`
  - child-input targets keep `Context: Child endpoint 'instance.port'`
- Runtime behavior was already extractor-based from the raised diagnostic; this slice makes the child-target side provable and keeps the concise reason focused on the earlier explicit link that already reserved the target.

## 2026-03-19: explicit-link width-mismatch failed summaries now keep target context
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now recognizes the existing blocked explicit-link width-mismatch diagnostic shape (`links '...' (width ...) to '...' (width ...)`) as target context.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the reachable child-target width-mismatch summary shape so non-quiet failed runs keep:
  - `Construct: ?toplink`
  - `Context: Child endpoint 'consumer.input_data'`
  - `Blocked boundary: explicit link`
  - `Reason: the current active composition lanes require exact width agreement`

## 2026-03-19: explicit-link width-mismatch summary coverage now locks the top-port side too
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now also locks the sibling explicit-link width-mismatch family where the blocked target is the declared top output.
- Non-quiet failed runs are now explicitly regression-backed to keep:
  - `Context: Top port 'result_data'`
  - `Blocked boundary: explicit link`
  - `Reason: the current active composition lanes require exact width agreement`

## 2026-03-19: explicit-link multi-top-output summaries now keep source context
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now recognizes the existing blocked explicit-link topology diagnostic shape `drives multiple top outputs from '...'` as structured context.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the reachable summary shape so non-quiet failed runs keep:
  - `Lane: C2`
  - `Construct: ?toplink`
  - `Context: Child endpoint 'producer.output_data'`
  - `Blocked boundary: explicit-link topology`
  - `Reason: the current active C2 lane supports at most one top-output target per resolved source`

## 2026-03-19: explicit-link top-to-top summaries now keep top-port source context
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now recognizes the sibling blocked topology diagnostic shape `links top input '...' directly to top output '...'` as structured context.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the reachable summary shape so non-quiet failed runs keep:
  - `Lane: C2`
  - `Construct: ?toplink`
  - `Context: Top port 'start'`
  - `Blocked boundary: explicit-link topology`
  - `Reason: the current active C2 lane only supports top inputs driving child inputs`

## 2026-03-19: explicit-link lane-entry summaries now explicitly avoid fabricated context
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the missing-`?toplink` explicit-link lane-entry family so non-quiet failed runs keep:
  - `Lane: C2`
  - `Construct: ?toplink`
  - `Blocked boundary: explicit-link lane entry`
  - `Reason: the current active C2 lane requires explicit '?toplink' wiring`
  - and no `Context:` line
- Runtime behavior was already correct here; this slice makes the no-invented-context contract provable.

## 2026-03-19: duplicate-declaration summaries now keep duplicate-name context
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now recognizes duplicate top-port and duplicate child-instance declaration diagnostics as structured failed-run summary context.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the reachable summary shapes so non-quiet failed runs keep:
  - `Construct: ?ports` plus `Context: Top port 'output_data'` for duplicate top-port declarations
  - `Context: Child 'dup'` for duplicate child-instance declarations
  - `Blocked boundary: shape` plus the existing uniqueness reason for both families
- This is a small extractor/classification improvement only; planner behavior is unchanged.

## 2026-03-19: explicit-link role-mismatch summaries now cover the remaining sibling families too
- [t/23-composition-errors.t](/Users/richarddje/Documents/github/fsmgen/t/23-composition-errors.t) now locks the direct blocked diagnostics for:
  - child-endpoint sources used as explicit-link sources when that child port is input instead of output
  - top-port targets used as explicit-link targets when that top port is input instead of output
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shapes so non-quiet runs keep:
  - `Context: Child endpoint 'consumer.input_data'`
  - `Context: Top port 'start'`
  - the blocked `explicit link` boundary and the existing concise role-mismatch reasons
- Runtime behavior was already correct here; this slice makes the sibling role-mismatch summary contract explicit.

## 2026-03-19: missing generated-child source-resolution summaries now cover both constructs
- [t/115-composition-child-source-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/115-composition-child-source-diagnostics.t) now also locks the direct blocked missing-`?dtc` source-resolution diagnostic beside the earlier missing-`?fsmc` one.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shapes so non-quiet runs keep:
  - `Construct: ?fsmc` plus `Context: Child 'missing_src'`
  - `Construct: ?dtc` plus `Context: Child 'missing_dt_src'`
  - the blocked `child-source resolution` boundary and the existing concise missing-source reason
  - and no invented `Child source file:` artifact when no external file was resolved
- Runtime behavior was already correct here; this slice makes the unresolved-source summary contract explicit for both generated-child constructs.

## 2026-03-19: wrong-kind generated-child realization summaries now cover both constructs
- [t/115-composition-child-source-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/115-composition-child-source-diagnostics.t) now also locks the direct CLI diagnostic for wrong-kind external `?dtc` children beside the earlier wrong-kind `?fsmc` one.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shapes so non-quiet runs keep:
  - `Construct: ?fsmc` plus `Child source file` and `Context: Child 'route_src'`
  - `Construct: ?dtc` plus `Child source file` and `Context: Child 'child_src'`
  - the blocked `child-source realization` boundary and the existing concise wrong-kind reason
- Runtime behavior was already correct here; this slice makes the wrong-kind realization summary contract explicit for both generated-child constructs.

## 2026-03-19: parser-boundary summaries now cover mapping directives and malformed top-link tokens
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now recognizes `mapping directive '...'` diagnostics as structured failed-run summary context.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shapes so non-quiet runs keep:
  - `Construct: ?ports` plus `Context: Mapping directive '/foo/bar/'`
  - `Construct: ?toplink` plus `Context: Token 'child.result_data->result_data'`
  - the blocked parser-boundary labels and the existing concise parser reasons
- Parser behavior was already correct here; this slice improves only the failed-run summary surface for the `?ports` mapping-directive family and makes both parser-boundary summary contracts explicit.

## 2026-03-19: the remaining ?ports token-family summaries now have explicit contracts
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now also locks the matching failed-run summary shapes so non-quiet runs keep:
  - `Construct: ?ports` plus `Context: Token 'bad-name>8'` for invalid explicit top-port tokens
  - `Construct: ?ports` plus `Context: Token 'data_in<0'` for non-positive width tokens
  - the blocked parser-boundary labels and the existing concise parser reasons for both siblings
- Runtime behavior was already correct here; this slice makes the remaining `?ports` parser-token summary contracts explicit.

## 2026-03-19: malformed generated-child parser summaries now keep child context too
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now recognizes blocked `contains '?fsmc' child '...'` / `contains '?dtc' child '...'` parser diagnostics as structured child context in failed-run summaries.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shapes so non-quiet runs keep:
  - `Construct: ?fsmc` plus `Context: Child 'child'` for blocked source-count failures
  - `Construct: ?dtc` plus `Context: Child 'child'` for blocked source-shape failures
  - the blocked child-source boundary labels and the existing concise parser reasons for both families
- Parser behavior is unchanged here; this slice improves only the failed-run summary surface for malformed generated-child declarations.

## 2026-03-19: malformed child item-list parser summaries now keep construct context too
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now recognizes known child headers like `?fsmc:child` inside blocked `contains child '...'` parser diagnostics as construct-scoped failed-run summaries too.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shape so non-quiet runs keep:
  - `Construct: ?fsmc`
  - `Context: Child '?fsmc:child'`
  - the blocked `child item-list shape` boundary and the existing concise dotted-pair-contract reason
- Parser behavior is unchanged here; this slice improves only the failed-run summary surface for malformed child item-list payloads.

## 2026-03-19: the dotted-pair child-item summary contract now covers ?toplink too
- [t/128-composition-child-structure-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/128-composition-child-structure-diagnostics.t) now also locks the direct blocked dotted-pair `?toplink:wiring` diagnostic beside the earlier `?fsmc:child` case.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shape so non-quiet runs keep:
  - `Construct: ?toplink`
  - `Context: Child '?toplink:wiring'`
  - the blocked `child item-list shape` boundary and the existing concise dotted-pair-contract reason
- Runtime behavior was already correct here; this slice makes the `?toplink` child-item summary contract explicit too.

## 2026-03-19: the dotted-pair child-item summary contract now covers ?ports too
- [t/128-composition-child-structure-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/128-composition-child-structure-diagnostics.t) now also locks the direct blocked dotted-pair `?ports` diagnostic beside the earlier `?fsmc:child` and `?toplink:wiring` cases.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shape so non-quiet runs keep:
  - `Construct: ?ports`
  - `Context: Child '?ports'`
  - the blocked `child item-list shape` boundary and the existing concise dotted-pair-contract reason
- Runtime behavior was already correct here; this slice makes the `?ports` child-item summary contract explicit too.

## 2026-03-19: the dotted-pair child-item summary contract now covers ?dtc too
- [t/128-composition-child-structure-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/128-composition-child-structure-diagnostics.t) now also locks the direct blocked dotted-pair `?dtc:child` diagnostic beside the earlier `?fsmc:child`, `?toplink:wiring`, and `?ports` cases.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shape so non-quiet runs keep:
  - `Construct: ?dtc`
  - `Context: Child '?dtc:child'`
  - the blocked `child item-list shape` boundary and the existing concise dotted-pair-contract reason
- Runtime behavior was already correct here; this slice makes the `?dtc` child-item summary contract explicit too.

## 2026-03-19: the dotted-pair child-item summary contract now covers ?rtl too
- [t/128-composition-child-structure-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/128-composition-child-structure-diagnostics.t) now also locks the direct blocked dotted-pair `?rtl:uart_tx` diagnostic beside the earlier `?fsmc:child`, `?toplink:wiring`, `?ports`, and `?dtc:child` cases.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shape so non-quiet runs keep:
  - `Construct: ?rtl`
  - `Context: Child '?rtl:uart_tx'`
  - the blocked `child item-list shape` boundary and the existing concise dotted-pair-contract reason
- Runtime behavior was already correct here; this slice makes the `?rtl` child-item summary contract explicit too.

## 2026-03-21: shared-datapath candidates now expose source-enable aliases and onehot0 assertion metadata
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now extends shared-datapath candidate metadata with:
  - deterministic per-child `source_enable_signal` aliases on aggregate value-family contributors,
  - `same_value_assertion` onehot0 metadata over those source-enable aliases,
  - and `multi_value_assertion` onehot0 metadata over the aggregate value-enable families.
- [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now prints those planned multi-value and same-value onehot0 inputs in non-quiet `Shared-Datapath Candidates` summaries.
- [t/142-composition-shared-datapath-assertion-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/142-composition-shared-datapath-assertion-metadata.t) locks the new assertion-planning metadata directly, while [t/139-composition-shared-datapath-candidate-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/139-composition-shared-datapath-candidate-metadata.t), [t/140-composition-shared-datapath-drive-intent-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/140-composition-shared-datapath-drive-intent-metadata.t), and [t/141-composition-shared-datapath-aggregate-enable-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/141-composition-shared-datapath-aggregate-enable-metadata.t) now also include the new nested metadata surface.
- This is still planning/export metadata, not lifted shared-datapath HDL emission, but it makes the assertion side of the contract explicit enough for later lifting work.

## 2026-03-21: shared-datapath candidates now expose lifted-ownership planning metadata
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now extends shared-datapath candidate metadata with:
  - `storage_class`,
  - `peer_input_count`,
  - `peer_input_endpoints`,
  - `default_lifted_visibility`,
  - `planned_reexport_top_output_signals`,
  - and `loopback_allowed`.
- [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now prints those planned storage/visibility/re-export/loopback decisions in non-quiet `Shared-Datapath Candidates` summaries.
- [t/143-composition-shared-datapath-visibility-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/143-composition-shared-datapath-visibility-metadata.t) locks the bounded registered peer-read case directly, while [t/139-composition-shared-datapath-candidate-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/139-composition-shared-datapath-candidate-metadata.t), [t/140-composition-shared-datapath-drive-intent-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/140-composition-shared-datapath-drive-intent-metadata.t), and [t/141-composition-shared-datapath-aggregate-enable-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/141-composition-shared-datapath-aggregate-enable-metadata.t) now include the new default top-output case too.
- This is still planning/export metadata rather than emitted lifted shared-datapath HDL, but it makes the registered peer-read internalization rule concrete enough for later lifting work.

## 2026-03-21: logged long-term HDL import / intent recovery direction
- [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) now tracks a new long-term horizon goal for HDL-to-`.fsm` work.
- The saved guidance is explicit:
  - treat this as bounded HDL import / intent recovery rather than exact reverse compilation,
  - start with `fsmgen`-generated `SystemVerilog` as the first honest round-trip/import target,
  - keep synthesizable RTL as the real import boundary,
  - then only later widen into bounded handwritten `SystemVerilog` / `VHDL` recovery,
  - and always surface what was recognized, heuristically recovered, or left unsupported.
- This is a logged design direction only; no runtime behavior changed.

## 2026-03-21: refined the HDL-import horizon note around synthesizable RTL and recovery scope
- The saved HDL-import direction now also records the stronger follow-up refinement:
  - “start with simpler recognizable hierarchy” is sequencing guidance, not a permanent ceiling,
  - richer hierarchy, generate-heavy RTL, macro/preprocessor-heavy RTL, and some optimized logic are still valid later targets,
  - parser support alone is not enough and the note now explicitly calls for preprocessing/elaboration plus a typed canonical RTL IR with provenance,
  - and `.fsm` is allowed to grow new first-class semantic constructs if repeated honest recovery work shows that the current design-intent vocabulary is too small.
- The saved honesty rule is also explicit now:
  - recover real intent where the evidence is strong,
  - and keep ambiguity or opaque logic visible as residue instead of forcing a fake high-level reconstruction.

## 2026-03-21: clarified that HDL import still needs frontend semantic compilation before elaboration
- The saved HDL-import direction now also distinguishes “no full backend compile needed” from “no compilation work needed,” because those are not the same.
- The saved clarification is:
  - no synthesis/backend compile is required for the import lane itself,
  - but elaboration still depends on real frontend semantic compilation work after preprocessing,
  - so the expected importer shape is now explicitly `preprocess -> parse -> semantic resolution -> elaboration -> canonical RTL IR -> intent recovery -> recovery report`.
- `R11` shared-datapath planning now also exposes a bounded combinational peer-read policy surface: shared combinational output families that feed peer child inputs stay top-output-only, report a block reason, and print that rule in non-quiet `bin/fsmgen` summaries.
- `R11` shared-datapath now has a first real runtime HDL slice on top of the earlier metadata: realized `?fsmc` children export hidden per-value enable ports, composition tops bind those exports into deterministic source-enable alias nets, and the top now emits aggregate/conflict helper wires from that surface.
- `R11` shared-datapath now also has its first actual lifted registered ownership/runtime slice:
  - bounded registered peer-read families with explicit public re-exports now surface reset-aware lifted-runtime metadata,
  - generated tops emit one shared lifted register plus next-value logic for that case,
  - peer-read child inputs are rebound to that lifted shared register,
  - contributor outputs are rebound to private raw nets,
  - and the kept public top outputs are re-exported from the lifted shared register rather than directly from one child.

## 2026-03-22: logged the planned shared IR architecture for forward compilation and HDL recovery
- The saved long-term HDL-import note now also records the IR split more explicitly:
  - forward `.fsm -> HDL` should converge toward `AST -> semantic Intent HIR -> Lowered RTL IR -> Structural RTL IR / Connectivity IR -> backend`,
  - reverse `HDL -> .fsm` should converge toward `HDL CST/AST -> semantic HDL HIR -> elaborated RTL IR -> Flat IR -> recovered Intent IR -> .fsm + recovery report`,
  - and the reverse path should not call its early layer a “non-semantic HIR” because the non-semantic layer is just the parsed HDL tree.
- The saved architecture rule is now:
  - keep surface trees separate,
  - keep early HDL-specific semantic work separate,
  - but share the semantic middle where possible through `Intent HIR`, `Lowered RTL IR`, one future `Structural RTL IR` / connectivity layer, and maybe a shared `Flat IR`/provenance model later.

## 2026-03-22: forward IR focus now explicitly includes a structural connectivity layer
- We clarified that the current extracted `Lowered RTL IR` is still a lowered summary layer, not yet the full explicit connectivity graph of the emitted HDL.
- Saved direction:
  - keep pushing on `Intent HIR`,
  - keep pushing on `Lowered RTL IR`,
  - and plan for one explicit `Structural RTL IR` / connectivity layer that behaves like an AST/netlist for ports, nets, instances, pin bindings, and auxiliary connectivity so the backend can walk full top/child wiring directly.
- Structural-layer refinement now also saved:
  - `Structural RTL IR` should stay backend-neutral and extensible rather than becoming a raw SystemVerilog/VHDL syntax dump,
  - child actual-pin bindings should eventually be represented through typed structural connection expressions / actual-connection AST nodes,
  - those connection expressions should be able to grow toward durable connectivity forms such as references, literals, slices/part-selects, concatenations, member/index access, and bounded open/default associations,
  - and backend-specific or inelegant connection shapes should instead normalize earlier into helper nets or auxiliary assignments before the structural binding boundary.

## 2026-03-22: started the first active forward IR extraction slice under `R11`
- The first live forward `.fsm -> HDL` IR extraction is now in tree:
  - `FSM::IR::IntentHIR` exists as an explicit forward semantic summary,
  - direct generation results now expose `intent_hir`,
  - realized generated children now preserve that same summary through `module_info`,
  - and the active compiler now derives `module_info` from that extracted intent layer instead of only from ad hoc raw-module inspection.
- This is intentionally the first bounded slice only:
  - `Intent HIR` is started,
  - `Lowered RTL IR` was still left for later extraction at that point,
  - and the forward IR work is now an active `R11` implementation seam rather than just an `H3` horizon note.
- The next forward IR seam is now also live:
  - `FSM::IR::LoweredRTLIR` exists as the first explicit forward lowered summary,
  - direct generation results now expose `lowered_rtl_ir`,
  - realized generated children now preserve that same lowered summary through `module_info`,
  - and some composition/export consumers now prefer `lowered_rtl_ir` when present instead of only rereading legacy module-info fields.
- The first composition-export widening step is now also live:
  - aggregated `composition_standalone_dt_children` entries preserve child `intent_hir`,
  - and those same exports now also preserve child `lowered_rtl_ir`.
  - that same reusable standalone-DT child export now also lives inside composition-top `intent_hir`.
- The broader generated-child composition export is now also live:
  - top-level `composition_generated_children` covers realized `?fsmc` and `?dtc` children together,
  - and those exported child summaries preserve both `intent_hir` and `lowered_rtl_ir`.
- The shared-datapath candidate surface now preserves that same forward child context too:
  - candidate contributors keep `intent_hir`,
  - keep `lowered_rtl_ir`,
  - now also keep the exact selected contributor `output_drive_family` from child `lowered_rtl_ir`,
  - and keep the bounded `drive_intent` summary as a derived compatibility shape from that extracted family,
  - and also keep stable generated-child identity through `kind` and `source_name`.
- Composition tops themselves now preserve the same forward-IR story too:
  - direct `?top` results expose serialized top-level `intent_hir`,
  - direct `?top` results also expose serialized top-level `lowered_rtl_ir`,
  - that same composition-top `intent_hir` now also carries the broader generated-child export instead of leaving it only as a separate top-level compatibility summary,
  - and composition `module_info` mirrors those same serialized forward layers with bounded top-port, lane, internal-net, instance, auxiliary-assignment, and shared-datapath-candidate summaries.
- The first structural/connectivity extraction slice is now also live:
  - `FSM::IR::StructuralRTLIR` exists as the first explicit AST/netlist-like connectivity summary,
  - direct `?top` results now expose `structural_rtl_ir`,
  - composition-top `module_info` mirrors the same structural surface,
  - and the active composition-top emitter now walks that structural layer for top-module dumping.
- The next structural widening step is also live:
  - direct generated `?fsm` / `?dt` results now expose a bounded structural module-interface slice through `structural_rtl_ir`,
  - and realized generated-child export surfaces now preserve that same child `structural_rtl_ir` beside `intent_hir` and `lowered_rtl_ir`.
- The next structural-consumption step is also live:
  - realized generated-child interface planning now consumes `structural_rtl_ir` as its first boundary source of truth,
  - with low-level declaration types like `wire` / `logic` normalized back to plain semantic data ports on the way into composition interface planning.
- The next IR-to-IR handoff step is also live:
  - composition-top `lowered_rtl_ir` now consumes `structural_rtl_ir` for internal-net names, realized-instance names, and auxiliary-assignment counts instead of rebuilding that bounded connectivity slice directly from the plan.
- The next structural-consumption step is also live:
  - composition-top `module_info` and `statistics` now consume `structural_rtl_ir` for child, top-port, and internal-net counts instead of rereading those bounded accounting fields directly from plan internals.
- The next structural-consumption step is also live through composition provenance:
  - `composition_report` now consumes `structural_rtl_ir` for top-port metadata and resolved-link endpoint lookup instead of rereading those bounded boundary/interface details directly from plan internals.
- The next structural-consumption step is also live through override/block reporting:
  - composition override/block event grouping and candidate-context lookup now consume `structural_rtl_ir` for top-port and child-interface metadata instead of rereading those same interface families directly from plan internals.
- The next IR-to-IR handoff step is also live through composition-top semantic summaries:
  - composition-top `intent_hir` now consumes `structural_rtl_ir` for top-port names, counts, and grouped input/output signal-analysis families,
  - and compatible top-level `module_info` signal metadata now mirrors that same structural top-port boundary instead of rebuilding it separately from plan internals.
- The next structural widening step is also live through explicit resolved connectivity:
  - composition-top `structural_rtl_ir` now preserves resolved links as first-class structural connectivity entries,
  - `composition_report` now derives its resolved-link identity/origin list from that structural layer instead of rereading plan-only link state,
  - and compatible top-level resolved-link counts now stay aligned with `structural_rtl_ir`.
- The next structural widening step is also live through typed actual-connection nodes:
  - composition-top `structural_rtl_ir` instance pin bindings now preserve a backend-neutral `connection_expr` node beside the compatibility `signal_name` mirror,
  - that first actual-connection shape is intentionally bounded to `signal_ref`,
  - realized composition-plan instances now also preserve that same typed `signal_ref` node before structural serialization,
  - and that earlier binding normalization now lives in `FSM::Composition::RealizedInstance` itself so the runtime child-binding carrier owns the `signal_name` / `connection_expr` alignment contract directly,
  - the active composition-top emitter now walks that typed node when rendering instance actual connections,
  - and shared-datapath candidate discovery now also reads structural binding signal names through that same typed node instead of depending only on a flat binding string.
- The next structural-consumption step is also live through override/block resolved-link handling:
  - composition override events now take their explicit-toplink and inferred-reexport connectivity from `structural_rtl_ir->{resolved_links}`,
  - and the kept-internal internal-carrier block path now also derives its family detection from that same structural resolved-link surface instead of rereading resolved links from the plan.
- The next forward semantic widening step is also live through one unified composition child export:
  - composition-top `intent_hir` now carries `composition_child_count` plus one ordered `composition_children` export across realized `?fsmc`, `?dtc`, and `?rtl` children,
  - compatible top-level `module_info` now mirrors that same unified child semantic surface,
  - those child entries preserve stable identity plus child `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` summaries when present,
  - and composition provenance / override / block endpoint lookup now consumes that same unified child semantic surface instead of rereading realized child identity only from plan instances.
- The next narrowing step is also live through the generated-child export path:
  - the narrower `composition_generated_children` export now derives from the broader semantic `composition_children` layer,
  - so generated-child export identity is no longer rebuilt separately from plan instances,
  - while the existing generated-child forward IR surface remains stable.
- The next lowering step is also live through shared-datapath candidate discovery:
  - shared-datapath candidate discovery now consumes `structural_rtl_ir` for top-output / child-interface connectivity,
  - contributor identity and lowered contributor context now come from the unified semantic `composition_children` export,
  - and the existing candidate surface remains stable while depending less on ad hoc plan crawling inside `HDLGenerator`.
- The composition provenance/reporting surface now preserves that same forward context too:
  - resolved-link entries keep source/target endpoint context,
  - generated-child endpoint contexts keep `intent_hir`,
  - generated-child endpoint contexts keep `lowered_rtl_ir`,
  - and top-port / resolved-link provenance kinds now keep one stable example subject for non-quiet CLI reporting.
- The composition override/block reporting surface now preserves that same forward context too:
  - override and block events keep structured top-port / child-endpoint context,
  - generated-child endpoint contexts keep `intent_hir`,
  - generated-child endpoint contexts keep `lowered_rtl_ir`,
  - and override/block example lines now use richer link/endpoint subjects instead of plain count-plus-name examples.
2026-03-23
- StructuralRTLIR `connection_expr` now supports bounded indexed and sliced
  signal forms in addition to plain `signal_ref`.
- The current renderer is still intentionally narrow: those richer forms render
  through the current Verilog-family backend only, and fail explicitly for
  backends like VHDL until that emitter surface is implemented deliberately.
- StructuralRTLIR `connection_expr` now also supports bounded concat nodes over
  nested operands, with the same deliberate renderer boundary: current
  Verilog-family backend only, explicit failure elsewhere.
- StructuralRTLIR `connection_expr` now also exposes recursive referenced-signal
  discovery, and shared-datapath contributor metadata preserves `bound_signals`
  beside the older scalar compatibility field.
- StructuralRTLIR `connection_expr` now also supports bounded bit-vector
  literal actuals, rendered through the current Verilog-family backend only.
- StructuralRTLIR `connection_expr` now also supports explicit backend-neutral
  `open` actuals, rendered as empty named actuals for the Verilog family and
  as `open` through the current VHDL helper-rendering path.
- StructuralRTLIR `connection_expr` now also supports bounded `member_access`
  actuals, rendered through the current SystemVerilog and VHDL helper paths
  while failing explicitly for plain Verilog.
- StructuralRTLIR `connection_expr` now also supports bounded `index_access`
  actuals, rendered through the current SystemVerilog, Verilog, and VHDL
  helper paths.
- Downstream structural consumers now also distinguish flat leaf carriers from
  broader dependency lists, so `bound_signal` stays leaf-only while
  `bound_signals` stays dependency-oriented.
- IntentHIR now also owns semantic composition-child lookup by instance
  through `composition_children_by_instance` and `composition_child`, so
  provenance/shared-datapath consumers no longer need to rebuild that same
  semantic child index locally in `HDLGenerator`.
- LoweredRTLIR now also owns normalized output-drive-family lookup by signal
  through `output_drive_families_from_input`, `output_drive_families_by_signal`,
  and `output_drive_family`, so shared-datapath and module-output-drive
  consumers no longer need to rebuild that same lowered signal map locally in
  `HDLGenerator`.
- LoweredRTLIR now also owns grouped standalone-DT multi-drive target lookup
  through `standalone_dt_multi_drive_targets_from_input`,
  `standalone_dt_multi_drive_targets_by_signal`, and
  `standalone_dt_multi_drive_target`, so standalone-DT assertion/export
  consumers no longer need to reread that same lowered target surface locally
  in `HDLGenerator`.
- IntentHIR now also owns semantic system-contract and signal-analysis
  boundary lookup through `system_contract_from_input` and
  `signal_analysis_entries_from_input`, so realized-child interface fallback
  no longer needs to reread that same semantic boundary data directly from raw
  `module_info` fields in `HDLGenerator`.
- Generic explicit-link linked-plan assembly for the active `C2`/`C3`/`C4`
  lanes now also lives in `FSM::Composition::LinkedPlanBuilder`, so
  `HDLGenerator` no longer owns that family’s system auto-wiring, endpoint
  resolution, role/width validation, deterministic carrier-net allocation, or
  realized-child rebinding logic directly.
- Inferred multi-child top-port projection now also lives in
  `FSM::Composition::TopPortInferenceBuilder`, so `HDLGenerator` no longer
  owns explicit-toplink top-port inference or undeclared same-name top-input
  and top-output inference directly.
- Shared-datapath support now also lives in
  `FSM::Composition::SharedDatapathSupport`, so `HDLGenerator` no longer owns
  shared-datapath helper-signal naming, generated-child source-export
  metadata, assertion metadata/rendering, or runtime plan augmentation
  directly.
- Composition provenance reporting now also lives in
  `FSM::Composition::ProvenanceReportBuilder`, so `HDLGenerator` no longer
  owns the bounded provenance report / override event / block event /
  endpoint-context projection family directly.
- EnableGraph module/state/declaration planning now also lives in
  `FSM::Synthesis::EnableGraph::ModulePlanningSupport`, so `EnableGraph` no
  longer owns effective system-contract lookup, effective clock/reset lookup,
  state-register planning, module-boundary port planning, or internal signal
  declaration planning directly.
- EnableGraph assignment analysis and assignment emission now also live in
  `FSM::Synthesis::EnableGraph::AssignmentSupport`, so `EnableGraph` no
  longer owns unified assignment analysis, RHS grouping, mux-plan
  construction, driven-signal discovery, reset/default/width recovery, or
  delayed-pulse / flop / combinational assignment emission directly.
- EnableGraph top-level enable initialization and WEN/EN support now also
  live in `FSM::Synthesis::EnableGraph::EnableSupport`, so `EnableGraph` no
  longer owns top-level state/DT enable initialization, WEN/EN prescan
  tracking, top-level enable emission, or unified DT/LHS WEN/EN emission
  directly.
- EnableGraph AST capture and condition/test conversion now also live in
  `FSM::Synthesis::EnableGraph::CaptureSupport`, so `EnableGraph` no longer
  owns condition-stack normalization, assignment/transition capture,
  test-selector conversion, capture-time RHS rendering, or AST signal-name
  extraction directly.
- EnableGraph AST rendering and operator classification now also live in
  `FSM::Synthesis::EnableGraph::ASTSupport`, so `EnableGraph` no longer owns
  AST-to-SystemVerilog rendering, operand-width-aware logical-versus-bitwise
  operator selection, factorizable-operator discovery, or
  arithmetic/logical/factorization classification directly.
- EnableGraph signal/intermediate support now also lives in
  `FSM::Synthesis::EnableGraph::SignalSupport`, so `EnableGraph` no longer
  owns AST-based intermediate naming, reset/default lookup, direct
  intermediate-dependency extraction, signal/intermediate classification,
  backend-safe signal-name cleanup, or RHS-based enable naming directly.
- EnableGraph factorization policy now also lives in
  `FSM::Synthesis::EnableGraph::FactorizationPolicySupport`, so
  `FSM::Synthesis::EnableGraph::FactorizationSupport` no longer owns
  logical-operation counting, first-pass AST feed preparation, second-pass
  AST feed eligibility, or high-count logical-operation policy directly.
- Direct consolidated intermediate preparation/normalization now also lives
  in `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport`,
  so the older `ConsolidatedIntermediateEmitter` no longer owns AST-
  factorized, prescanned, and FSMGen-parsed intermediate collection or
  runtime metadata normalization directly.
- The paired direct `ConsolidatedIntermediateEmitter` now narrows to
  dependency-aware filtering, topological ordering, and final wire/assign
  emission for that prepared consolidated signal set.
- Direct intermediate runtime recovery and metadata normalization now also
  live in `FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport`,
  so `IntermediateSignalSupport` no longer owns runtime AST lookup,
  rendered-expression caching, dependency recovery, or width inference
  directly.
- The paired direct `IntermediateSignalSupport` now narrows to filter policy
  over normalized intermediate metadata instead of mixing recovery and filter
  responsibilities together.
- Explicit `?toplink` wiring now has a first real structural-actual slice:
  `=open`, `=0`, `=1`, and exact-width `=N'b...` sources may now bind
  directly into realized child input ports.
- `FSM::Composition::LinkedPlanBuilder` now preserves those actuals as typed
  `connection_expr` bindings instead of inventing carrier nets, and
  top-port inference / provenance block detection now treat those child
  inputs as already explicitly linked.
- Explicit `?toplink` wiring may now also use declared top-port bit/slice
  expressions such as `payload_bus[15:8]` and `status_bus[0]` on the source
  side when the target is a realized child input.
- `FSM::Composition::LinkedPlanBuilder` now resolves those source-side
  top-port expressions into typed `bit_select_expr` / `slice_expr` bindings
  directly, and top-port inference / provenance block detection now treat
  those child inputs as already explicitly linked instead of inventing helper
  nets or undeclared same-name top ports.
- Omitted/empty `?ports` explicit-link tops may now also infer undeclared
  base top inputs directly from those source-side top expressions.
- `FSM::Composition::TopPortInferenceBuilder` now derives the inferred
  base-port width from the highest referenced bit while still rejecting
  incompatible exact-width full-port evidence instead of guessing one width
  contract silently.
- Explicit `?toplink` wiring may now also use the bounded flat comma-separated
  source-side concat form inside one `/source/target/` token, for example
  `header_bus,status_bus[0],=1,payload_bus[3:0]`, when the target is a
  realized child input.
- `FSM::Composition::LinkedPlanBuilder` now lowers those concat sources into
  typed structural `concat_expr` bindings directly instead of inventing
  carrier nets, and blocked unsupported concat operands keep the existing
  `Top expression '...'` summary context.
- Omitted/empty `?ports` explicit-link tops may now also see inferable
  `name[index]` / `name[msb:lsb]` operands inside those bounded concat
  sources, and one remaining undeclared whole-port concat operand may now
  also be sized exactly from the child-input target remainder width while
  several still-unsized whole-port operands continue to fail explicitly
  instead of guessing several widths at once.
- The same bounded structural-actual literal family now also covers exact-
  width hex forms such as `=8'hA5` for both direct actual sources and concat
  operands, with those literals normalized into the same structural
  bit-vector form instead of introducing a second backend-specific literal
  node.
- The same bounded structural-actual literal family now also covers octal:
  unsized direct `=0o245` now widens to direct child-input or top-output
  target width, exact-width `=8'o245` now works on direct bindings and
  bounded concat operands, and both forms lower into the same structural
  bit-vector literal node instead of introducing an octal-specific escape
  hatch.
- Those same direct and exact-width structural actual families now also
  accept underscore-separated digit spellings such as `=0b1010_0101`,
  `=1_70`, `=0o2_45`, `=A_5`, `=8'd1_65`, and `=8'hA_5`, while keeping the
  same normalized numeric value and the same direct-vs-concat support
  boundary.
- Explicit `?toplink` wiring may now also use source-side child-output
  bit/slice expressions such as `producer.payload[7:4]` and
  `producer.payload[0]` when the target is a realized child input or a
  declared top output.
- `FSM::Composition::LinkedPlanBuilder` now groups those projected child
  sources by one deterministic base child-output carrier and then binds typed
  `bit_select_expr` / `slice_expr` projections off that shared carrier for
  sibling child-input consumers and direct top-output assignments instead of
  inventing per-projection helper nets.
- `FSM::Composition::TopPortInferenceBuilder`,
  `FSM::Composition::ProvenanceReportBuilder`, and
  `FSM::Composition::FailureReportBuilder` now also treat those source-side
  child expressions as first-class explicit links, so omitted-port same-name
  inference no longer duplicates them and blocked range failures keep concise
  `Child expression '...'` summary context.
- Direct generated roots may now also use bounded semantic package imports:
  direct `?fsm` / `?dt` roots accept `(+import pkg_name ...)`, shared
  `?pkg:name` roots may be embedded or resolved from external searchable
  `.fsm` package sources, and namespaced package symbols such as
  `shared.RESET_BYTE` and `shared.mode.BUSY` now resolve as literals in
  assignment RHS expressions and guard equality conditions on that same
  direct-root path.
- `FSM::Package::ImportResolver` is now the shared package search/parse owner
  for both composition-top and direct-root package imports, so the repo no
  longer keeps separate import-resolution logic on those two paths.
- Generated child sources realized through the direct-root pipeline may now
  use the same bounded package-import contract too, which keeps package
  semantics aligned between standalone direct roots and generated-child reuse
  instead of leaving composition children on a weaker import surface.
- The first semantic scalar-type-property widening beyond raw width is now
  shipped too: bounded `+types` now covers signed scalar aliases through
  `(signed bit)` and `(signed (bits N))`, direct-root `+size` and
  composition `?ports` preserve that signedness into emitted SystemVerilog
  declarations, and canonical `symbol_contract` type specs now preserve the
  `signed` flag beside `width`.
- Deferred imported composition aliases must not inject a default
  `signed => 0` placeholder, because that would overwrite imported signed
  types during finalization; signed override only becomes real when the
  author explicitly asked for it.
- Direct internal/helper declaration planning cannot rely only on
  `fsm_module->signals` for signedness, because some live direct LHS signals
  survive only on assignment-analysis `lhs_ast` signal refs; that signedness
  now has to be recovered from the analyzed LHS path too.
- The next semantic scalar-type-property widening beyond raw width and
  signedness is now shipped too: bounded `+types` now also accepts
  explicit `(two_state ...)` and `(four_state ...)` wrappers across direct
  roots, composition tops, and semantic packages, direct-root `+size` and
  composition `?ports` preserve that state-model into emitted SystemVerilog
  declarations, and canonical `symbol_contract` type specs now preserve
  `state_model` beside `width` and `signed`.
- Deferred imported composition aliases must preserve explicit
  `state_model` overrides during finalization the same way they now preserve
  explicit signed overrides, because local wrappers like
  `(type byte_t (four_state shared.byte))` are part of the honest semantic
  surface and should not disappear once the imported package type resolves.
- The bounded lowering rule for this first state-model slice is explicit and
  compatibility-friendly: only explicit state-model aliases lower to
  concrete SystemVerilog carriers (`two_state -> bit`, `four_state -> logic`),
  while bare `bit` / `(bits N)` keep the current compatibility surface until
  the broader semantic type lane is ready to tighten defaults on purpose.
- The docs split is now active in-tree instead of being only a roadmap note:
  the repo has a real mdBook source tree under `docs/book/` with a working
  `book.toml`, `src/SUMMARY.md`, and the first shipped chapter set.
- The book should now be treated as the progressive learning surface, while
  `docs/USER_GUIDE.md` remains the broad live reference during the migration
  and focused docs such as `docs/COMPOSITION_SCOPE.md` remain the precise
  support-boundary companions.
- The book is also now explicitly a live project artifact: shipped user-facing
  changes are expected to update the relevant chapter material, and stale book
  examples/support wording should be treated as real documentation defects.
- Local mdBook output lives under `docs/book/book/` and should stay ignored;
  doc validation should build the book but must not leave generated HTML as a
  tracked repo change.
