# DYNAMIC-DIVISOR-SAFETY-FRONTIER: Dynamic Divisor Safety Proof Frontier

## Metadata

- Tree ID: `DYNAMIC-DIVISOR-SAFETY-FRONTIER`
- Status: `done`
- Roadmap lane: `language ergonomics`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Broaden divide/modulo safety beyond the currently shipped constant-expression
and ISF literal/actor-symbol checks by selecting and implementing one
reviewable proof surface at a time.

## Non-Goals

- Do not claim complete dynamic nonzero proof coverage in one task tree.
- Do not weaken existing constant-expression, ISF, or HDL-generation
  fail-closed behavior for known-zero divisors.
- Do not change expression scheduling or generated HDL before the audit leaf
  names a bounded implementation surface and proof source.
- Do not infer nonzero facts from runtime values unless the proof is explicit,
  stable, documented, and covered by focused validation.

## Acceptance Criteria

- The current divide/modulo safety boundary is audited across direct `.fsm`,
  composition, ISF lowering, tests, corpus accounting, mdBook, and live docs.
- Each behavior-bearing leaf names one bounded source position or proof family
  before code changes begin.
- Shipped behavior and remaining deferrals are documented in the mdBook and
  live docs in the same slice as implementation.
- Focused validation covers accepted, rejected, and still-deferred divisor
  cases for the changed surface.
- Broader validation runs when a leaf touches shared expression evaluation,
  scheduling, or HDL lowering paths.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `DYNAMIC-DIVISOR-SAFETY-FRONTIER`
  Status: `done`
  Goal: `Broaden divide/modulo safety proofs one reviewable surface at a time.`
  Children: `DYNAMIC-DIVISOR-SAFETY-FRONTIER.1`,
    `DYNAMIC-DIVISOR-SAFETY-FRONTIER.2`,
    `DYNAMIC-DIVISOR-SAFETY-FRONTIER.3`

- ID: `DYNAMIC-DIVISOR-SAFETY-FRONTIER.1`
  Status: `done`
  Goal: `Select the task tree and establish the first executable frontier.`
  Acceptance: `The active tree, roadmap status, live docs, and backlog owner stance name this tree, and the next leaf is limited to an audit/design boundary before behavior changes.`
  Verification: `passed: live-book/spec/backlog audits, mdBook build, and diff check`
  Commit: `336b8afd DYNAMIC-DIVISOR-SAFETY-FRONTIER.1: select divisor safety work`

- ID: `DYNAMIC-DIVISOR-SAFETY-FRONTIER.2`
  Status: `done`
  Goal: `Audit shipped divide/modulo safety and choose the smallest safe implementation surface.`
  Acceptance: `The audit identifies current proof sources, expected-failure or deferred runtime divisor positions, relevant tests/docs, and one bounded next implementation leaf with explicit non-goals.`
  Verification: `passed: expression-builder syntax, focused ISF/direct/corpus tests, mdBook build, and diff check`
  Commit: `ef64067c DYNAMIC-DIVISOR-SAFETY-FRONTIER.2: audit divisor safety frontier`

- ID: `DYNAMIC-DIVISOR-SAFETY-FRONTIER.3`
  Status: `done`
  Goal: `Reject literal-zero divisors in direct .fsm runtime expressions.`
  Acceptance: `Direct .fsm runtime expression parsing rejects numeric and exact-width literal-zero divisor operands for '/', '%', 'div', and 'mod' before HDL emission; nonzero literal divisors and dynamic signal divisors remain accepted; constant-expression and ISF behavior are unchanged except for shared documentation truth; focused tests, corpus/docs accounting, mdBook, and diff checks pass.`
  Verification: `passed: syntax, focused direct/ISF/corpus tests, public report/capability gates, language-surface gates, mdBook build, and diff check`
  Commit: `7c6503c2 DYNAMIC-DIVISOR-SAFETY-FRONTIER.3: ship direct runtime divisor guard`

## Audit Findings

- Direct `.fsm` constant-expression width domains already reject `/` and `%`
  by zero in `+size` before HDL emission through
  `FSM::Adapter::FSMGenFull::Parser::apply_constant_width_operator`.
- Direct `.fsm` aggregate `+params` expression folding already rejects leafwise
  `/` and `%` by zero through `FSM::ParameterValueSupport`.
- ISF runtime expression contexts already reject numeric/exact-width
  literal-zero, actor-constant-zero, and actor-parameter-zero divisors before
  scheduled `.fsm` emission. The coverage is centralized in
  `t/1308-isf-dynamic-divisor-safety.t`.
- Direct `.fsm` runtime division/modulo was already a shipped supported
  surface through
  `feature.direct_runtime_div_mod`. It currently proves accepted dynamic
  divisors and expression grouping.
- The `.2` audit probe confirmed that, before `.3`, a direct `.fsm` runtime
  assignment such as `(= (OUT (/ A 0)))` parsed successfully. The `.3`
  implementation closes that hole for numeric and exact-width literal-zero
  direct runtime divisors.
- Broader dynamic nonzero proofs for runtime signals remain out of scope until
  FSMGen has explicit range/dataflow evidence to justify them.

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Direct runtime literal-zero divisor rejection shipped; broader dynamic dataflow/range proofs remain future work. |

## Decisions

- `2026-05-24`: The first executable follow-up is an audit/design leaf, not an
  implementation leaf. Divide/modulo safety spans constant evaluation,
  runtime expression handling, ISF lowering, and generated HDL, so a code
  slice must first identify one bounded proof source and preserve fail-closed
  behavior for known-zero divisors.
- `2026-05-24`: Select direct `.fsm` runtime literal-zero divisor rejection as
  the next implementation leaf. The proof source is local and static: a
  numeric or exact-width literal-zero divisor is known during expression
  parsing. Dynamic runtime scalar divisors, actor/symbol nonzero proofs outside
  ISF, and generated runtime guards remain out of scope.
- `2026-05-24`: Close this task tree after `.3`. The shipped surface is the
  bounded literal-zero runtime proof selected by the audit; every broader
  dynamic nonzero proof needs a future task tree with explicit range/dataflow
  evidence.

## Open Questions

- None for the selected direct runtime literal-zero implementation leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `DYNAMIC-DIVISOR-SAFETY-FRONTIER.1` | `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: Files=3, Tests=351` |
| `2026-05-24` | `DYNAMIC-DIVISOR-SAFETY-FRONTIER.2` | `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm`; `prove -Iperl t/1308-isf-dynamic-divisor-safety.t t/310-systemverilog-implicit-width-and-truthiness-hardening.t t/248-regression-corpus-accounting.t`; `mdbook build docs/book`; `git diff --check` | `passed: Files=3, Tests=3057` |
| `2026-05-24` | `DYNAMIC-DIVISOR-SAFETY-FRONTIER.3` | `perl -Iperl -c` for touched Perl/test files; `prove -Iperl t/1320-direct-runtime-divisor-safety.t t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t t/304-normalized-semantic-json-regression-corpus.t t/360-diagnostics-registry-runtime-audit.t`; `prove -Iperl t/297-capability-manifest.t t/359-support-accounting-corpus-runtime-audit.t t/372-support-accounting-catalog-path-audit.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/303-normalized-semantic-json-supported-corpus.t`; `prove -Iperl t/317-language-surface-contract.t t/363-language-surface-section-runtime-contract-audit.t`; `prove -Iperl t/1308-isf-dynamic-divisor-safety.t t/310-systemverilog-implicit-width-and-truthiness-hardening.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused/broader gates clean` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `DYNAMIC-DIVISOR-SAFETY-FRONTIER.1` | `336b8afd DYNAMIC-DIVISOR-SAFETY-FRONTIER.1: select divisor safety work` | `selection slice` |
| `DYNAMIC-DIVISOR-SAFETY-FRONTIER.2` | `ef64067c DYNAMIC-DIVISOR-SAFETY-FRONTIER.2: audit divisor safety frontier` | `audit/design slice` |
| `DYNAMIC-DIVISOR-SAFETY-FRONTIER.3` | `7c6503c2 DYNAMIC-DIVISOR-SAFETY-FRONTIER.3: ship direct runtime divisor guard` | `implementation slice` |

## Changelog

- `2026-05-24`: Created active task tree and selected the audit/design
  frontier.
- `2026-05-24`: Audited shipped divisor safety and selected direct runtime
  literal-zero divisor rejection as the next bounded implementation leaf.
- `2026-05-24`: Shipped direct `.fsm` runtime literal-zero divisor rejection
  and closed the task tree.
