# INFERENCE-FIRST-SCALAR-AUTHORING: Inference-First Scalar Authoring

## Metadata

- Tree ID: `INFERENCE-FIRST-SCALAR-AUTHORING`
- Status: `done`
- Roadmap lane: `language ergonomics`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Make scalar declarations optional in additional source positions where FSMGen
can recover a safe scalar type and width from already-authored usage, without
weakening existing fail-closed diagnostics for ambiguous or unsafe values.

## Non-Goals

- Do not claim a global "never declare scalar types" guarantee in one slice.
- Do not broaden aggregate inference, struct lowering, or VHDL behavior under
  this tree.
- Do not infer widths from ambiguous runtime values without a reviewable proof
  source.
- Do not change public behavior before a bounded implementation leaf records
  its syntax, acceptance criteria, documentation targets, and validation plan.

## Acceptance Criteria

- The current scalar-inference boundary is audited against the codebase,
  corpus, mdBook, and live docs.
- Each implementation leaf names one bounded source position or diagnostic
  family before code changes begin.
- Shipped behavior is documented in the mdBook and live docs in the same slice
  as the implementation.
- Focused validation covers the changed source position and any affected
  regression corpus accounting.
- Broader validation runs when a leaf touches shared scalar inference or HDL
  generation paths.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `INFERENCE-FIRST-SCALAR-AUTHORING`
  Status: `done`
  Goal: `Broaden safe scalar width/type inference one reviewable surface at a time.`
  Children: `INFERENCE-FIRST-SCALAR-AUTHORING.1`,
    `INFERENCE-FIRST-SCALAR-AUTHORING.2`,
    `INFERENCE-FIRST-SCALAR-AUTHORING.3`

- ID: `INFERENCE-FIRST-SCALAR-AUTHORING.1`
  Status: `done`
  Goal: `Select the task tree and establish the first executable frontier.`
  Acceptance: `The active tree, roadmap status, live docs, and backlog owner stance name this tree, and the next leaf is limited to an audit/design boundary before behavior changes.`
  Verification: `passed: syntax check, live-book/spec index audits, mdBook build, and diff check`
  Commit: `INFERENCE-FIRST-SCALAR-AUTHORING.1: select scalar inference work`

- ID: `INFERENCE-FIRST-SCALAR-AUTHORING.2`
  Status: `done`
  Goal: `Audit the shipped scalar-inference boundary and choose the smallest safe implementation surface.`
  Acceptance: `The audit identifies current inference sources, expected-failure or deferred scalar declaration positions, relevant tests/docs, and one bounded next implementation leaf with explicit non-goals.`
  Verification: `passed: static code/doc/corpus audit, syntax check, mdBook build, and diff check`
  Commit: `INFERENCE-FIRST-SCALAR-AUTHORING.2: audit scalar inference frontier`

- ID: `INFERENCE-FIRST-SCALAR-AUTHORING.3`
  Status: `done`
  Goal: `Accept positive integer scalar width symbols inside declarative (bits WIDTH) type specs.`
  Acceptance: `Direct-root, composition-top, and package +types paths accept (bits WIDTH_SYMBOL) when WIDTH_SYMBOL resolves to a positive integer scalar constant or enum member in the same available symbol scope, including imported package symbols where the scope already supports imports; signed/two_state/four_state/list/record wrappers preserve the resolved width; non-positive, aggregate, unresolved, or cyclic width symbols fail closed with existing type-shape diagnostics or sharper width-symbol diagnostics; docs, manifest/support accounting, and focused tests are synchronized.`
  Verification: `passed: syntax checks; focused scalar type tests; corpus accounting and supported language-feature corpus; language-surface, capability-manifest, supported-corpus, normalized semantic JSON, aggregate-type, structural-type, mdBook, and diff checks`
  Commit: `INFERENCE-FIRST-SCALAR-AUTHORING.3: ship symbolic bits widths`

## Audit Findings

- Direct `.fsm` sources already infer or recover scalar widths from explicit
  `+size`, named scalar type aliases, positive integer scalar width symbols in
  `+size`, static slices and bit selects, selector/guard comparisons, direct
  partial-LHS writes, and whole-signal assignment reconciliation.
- Composition sources already infer top boundary widths from omitted/empty
  `?ports`, explicit wiring endpoints, same-name child endpoints, top
  expression slices, concat/repeat residual width, typed aggregate leaves, and
  positive integer scalar symbols in `?ports`.
- ISF lowering already emits scheduled `.fsm` `+size` entries from actor
  interface/storage declarations, inferred scheduler counters, data-operation
  width evidence, actor constants, and actor scalar parameters on the shipped
  ISF surfaces.
- The narrowest code-backed gap found in this audit is declarative scalar type
  width syntax: `FSM::Package::DeclarativeTypeSupport` accepts `(bits N)` only
  when `N` is a raw positive integer token, while the mdBook already shows the
  intended authoring shape `(type byte (bits BYTE_W))` near the width-symbol
  guidance.
- The next leaf should not add arbitrary type-width expressions, aggregate
  leaf paths, runtime signals, parameter-specialization values, broad scalar
  autodeclaration, or aggregate autovivification. It should only let
  declarative type specs reuse positive integer scalar width symbols that are
  already available in the same semantic symbol scope.

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `INFERENCE-FIRST-SCALAR-AUTHORING.3` | `done` | Shipped the bounded symbolic scalar type width surface and closed this task tree. |

## Decisions

- `2026-05-24`: The first executable leaf is an audit/design slice, not an
  implementation slice. Scalar inference is shared language infrastructure, so
  the next code change must name one narrow source position and preserve
  fail-closed behavior for ambiguous cases.
- `2026-05-24`: The selected implementation surface is symbolic width tokens
  inside `(bits ...)` type specs. This is narrower than arbitrary type-width
  expressions and aligns the code with the existing width-symbol authoring
  direction documented in the mdBook.
- `2026-05-24`: `INFERENCE-FIRST-SCALAR-AUTHORING.3` deliberately uses a
  type-width-symbol resolver that is narrower than `+size` width expressions:
  positive integer scalar constants and enum members are accepted, while
  aggregate scalar leaves, parameters, runtime signals, and arbitrary
  expressions remain outside the declarative `(bits WIDTH_SYMBOL)` surface.

## Open Questions

- Whether type-width symbol resolution should include params remains
  deliberately out of scope for `INFERENCE-FIRST-SCALAR-AUTHORING.3`.
  Parameter/generic values are specialization defaults, while the selected leaf
  is limited to stable positive integer scalar constants and enum members.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `INFERENCE-FIRST-SCALAR-AUTHORING.1` | `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: Files=3, Tests=351` |
| `2026-05-24` | `INFERENCE-FIRST-SCALAR-AUTHORING.2` | `perl -Iperl -c t/279-declarative-scalar-types.t`; `prove -Iperl t/279-declarative-scalar-types.t t/310-systemverilog-implicit-width-and-truthiness-hardening.t t/248-regression-corpus-accounting.t`; `mdbook build docs/book`; `git diff --check` | `passed: Files=3, Tests=3036` |
| `2026-05-24` | `INFERENCE-FIRST-SCALAR-AUTHORING.3` | `perl -Iperl -c` for touched parser/support/test files; `prove -Iperl t/279-declarative-scalar-types.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/317-language-surface-contract.t t/363-language-surface-section-runtime-contract-audit.t t/297-capability-manifest.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/303-normalized-semantic-json-supported-corpus.t`; `prove -Iperl t/280-declarative-aggregate-types.t t/281-structural-declared-type-contracts.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused/broader gates clean` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `INFERENCE-FIRST-SCALAR-AUTHORING.1` | `INFERENCE-FIRST-SCALAR-AUTHORING.1: select scalar inference work` | Selection leaf complete. |
| `INFERENCE-FIRST-SCALAR-AUTHORING.2` | `INFERENCE-FIRST-SCALAR-AUTHORING.2: audit scalar inference frontier` | Audit leaf complete. |
| `INFERENCE-FIRST-SCALAR-AUTHORING.3` | `INFERENCE-FIRST-SCALAR-AUTHORING.3: ship symbolic bits widths` | Implementation leaf complete. |

## Changelog

- `2026-05-24`: Created active task tree and selected the audit/design
  frontier.
- `2026-05-24`: Audited the current scalar-inference boundary and selected
  symbolic `(bits WIDTH_SYMBOL)` type-spec widths as the next bounded
  implementation leaf.
- `2026-05-24`: Shipped symbolic `(bits WIDTH_SYMBOL)` type-spec widths for
  direct-root, package, and composition-top `+types` paths and closed the task
  tree.
