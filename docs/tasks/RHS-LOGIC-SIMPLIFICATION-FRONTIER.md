# RHS-LOGIC-SIMPLIFICATION-FRONTIER: Generated RHS Logic Simplification And Minimization

## Metadata

- Tree ID: `RHS-LOGIC-SIMPLIFICATION-FRONTIER`
- Status: `done`
- Roadmap lane: `HDL quality / expression minimization`
- Created: `2026-06-18`
- Last updated: `2026-06-18`
- Owner: repo-local workflow

## Goal

Ensure generated HDL RHS expressions pass through an explicit logic-equivalence
simplification/minimization step before emission so redundant terms are not left
in SystemVerilog or VHDL output.

## Non-Goals

- Do not change source-language semantics or accepted syntax.
- Do not perform width-unsafe algebraic rewrites; if width or four-state
  semantics cannot be proven safe for a rewrite, preserve the original
  expression rather than guessing.
- Do not replace later synthesis optimization; this is a readability and
  generated-code-quality pass.
- Do not advance the active IAL2 feature-completeness frontier.

## Acceptance Criteria

- Generated RHS expressions run through a shared deterministic simplifier that
  applies every width-safe logic equivalence implemented by the pass before HDL
  text emission.
- The committed passes cover constant folding, identity/annihilator,
  idempotence, complement, double-negation, De Morgan, absorption, and common
  consensus-style simplifications where the AST proves the rewrite safe.
- Vector/multi-bit bitwise RHS expressions apply the same equivalence families
  when operand widths and literal masks prove the rewrite preserves both value
  and expression width.
- The simplification is shared by generated SystemVerilog and VHDL RHS
  emission surfaces covered by the focused tests.
- Explicit expression output paths preserve semantics; tests prove simplified
  HDL no longer emits `B & 1'b1`-style redundant terms for the covered case.
- User-facing docs and task-tree/memory records describe the simplification
  contract and its bounded first slice.
- Focused code-generation checks plus documentation and memory gates pass.
- The completed slice is committed through `COMMIT.md`.

## Task Tree

- ID: `RHS-LOGIC-SIMPLIFICATION-FRONTIER`
  Status: `done`
  Goal: `Add a generated-RHS logic simplification/minimization frontier.`
  Children: `RHS-LOGIC-SIMPLIFICATION-FRONTIER.1`, `RHS-LOGIC-SIMPLIFICATION-FRONTIER.2`

- ID: `RHS-LOGIC-SIMPLIFICATION-FRONTIER.1`
  Status: `done`
  Goal: `Ship the first shared RHS simplification/minimization pass for proven logic equivalences.`
  Acceptance: `Generated SystemVerilog and VHDL RHS expressions covered by the focused tests simplify every implemented width-safe logic-equivalence class, docs and continuity records are synced, and focused checks pass.`
  Verification: `passed`
  Commit: `RHS-LOGIC-SIMPLIFICATION-FRONTIER.1: minimize generated RHS logic`

- ID: `RHS-LOGIC-SIMPLIFICATION-FRONTIER.2`
  Status: `done`
  Goal: `Extend generated RHS simplification to width-safe vector and multi-bit bitwise logic equivalences.`
  Acceptance: `Multi-bit generated RHS bitwise expressions simplify identity, annihilator, idempotence, complement, double-negation, absorption, and consensus cases when widths/literal masks prove safety; unsafe width-changing cases remain preserved; focused SV/VHDL/docs gates pass.`
  Verification: `passed`
  Commit: `RHS-LOGIC-SIMPLIFICATION-FRONTIER.2: simplify vector RHS logic`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `RHS-LOGIC-SIMPLIFICATION-FRONTIER.2` | `done` | Width-safe vector/multi-bit generated RHS bitwise simplification shipped; no remaining frontier in this tree. |

## Decisions

- `2026-06-18`: Treat RHS simplification as a generated-code-quality pass that
  must run before HDL text emission, not as a source-language syntax change.
- `2026-06-18`: Keep the first slice width-safe: remove identity and
  annihilator constants only when the replacement has the same value meaning
  in the generated expression context.
- `2026-06-18`: Broadened `.1` after user clarification: the pass must pursue
  minimal generated RHS expressions by applying all width-safe logic
  equivalences implemented by the simplifier, not just identity constants.
- `2026-06-18`: Selected `.2` for width-aware vector/multi-bit bitwise logic
  simplification after confirming `BUS1 & 1'b1` must remain unsimplified while
  same-width all-one/all-zero mask cases should simplify.
- `2026-06-18`: Completed `.2` with width-proven vector/multi-bit bitwise
  identity, annihilator, idempotence, complement, double-negation, absorption,
  and consensus simplification, plus captured RHS metadata routing through the
  same AST simplifier.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-18` | `.1` | `env -u PERL5LIB perl -Iperl -c perl/FSM/Synthesis/EnableGraph/ASTSupport.pm`; `env -u PERL5LIB perl -Iperl -c perl/FSM/IR/StructuralRTLIRBuilder.pm`; `env -u PERL5LIB prove -Iperl t/208-enable-graph-ast-support.t t/206-enable-graph-enable-support.t t/1333-direct-structural-rtl-ir-projection.t t/163-forward-structural-rtl-ir-surface.t t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t`; `env -u PERL5LIB prove -Iperl t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t`; `env -u PERL5LIB prove -Iperl t/297-capability-manifest.t t/498-structural-rtl-ir-accessor-defensive-copy-boundary-audit.t t/1420-vhdl-direct-backend-scaffold.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `git diff --check`; `./bin/ci-regression quick` | passed |
| `2026-06-18` | `.2` | `env -u PERL5LIB perl -Iperl -c perl/FSM/Synthesis/EnableGraph/ASTSupport.pm`; `env -u PERL5LIB perl -Iperl -c perl/FSM/Synthesis/EnableGraph/CaptureSupport.pm`; `env -u PERL5LIB prove -Iperl t/208-enable-graph-ast-support.t t/207-enable-graph-capture-support.t`; `env -u PERL5LIB prove -Iperl t/206-enable-graph-enable-support.t t/1333-direct-structural-rtl-ir-projection.t t/163-forward-structural-rtl-ir-surface.t t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t`; `env -u PERL5LIB prove -Iperl t/1401-isf-bit-ops.t t/1402-isf-bit-test.t`; `env -u PERL5LIB prove -Iperl t/1420-vhdl-direct-backend-scaffold.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `git diff --check`; `./bin/ci-regression quick` | passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `RHS-LOGIC-SIMPLIFICATION-FRONTIER.1: minimize generated RHS logic` | First shared AST-level generated RHS simplification pass. |
| `.2` | `RHS-LOGIC-SIMPLIFICATION-FRONTIER.2: simplify vector RHS logic` | Width-safe vector/multi-bit bitwise simplification and capture RHS metadata routing. |

## Changelog

- `2026-06-18`: Created active tree and selected `.1` for the first generated
  RHS logic-simplification pass.
- `2026-06-18`: Broadened `.1` to cover a real deterministic logic
  simplification/minimization pass rather than a single identity-term cleanup.
- `2026-06-18`: Completed `.1`: generated RHS ASTs now simplify before HDL
  rendering, direct StructuralRTLIR assignment records store the simplified
  RHS AST, and focused SV/VHDL/docs/knowledge/memory gates pass.
- `2026-06-18`: Activated `.2` for width-safe vector/multi-bit bitwise RHS
  simplification.
- `2026-06-18`: Completed `.2`: vector/multi-bit generated RHS bitwise
  expressions now simplify width-proven identities and related equivalences,
  unsafe width-changing masks remain preserved, captured RHS metadata uses the
  shared simplifier, and focused SV/VHDL/docs/knowledge/memory/quick-regression
  gates pass.
