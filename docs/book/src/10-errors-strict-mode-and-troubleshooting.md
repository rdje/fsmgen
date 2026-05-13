# Errors, Strict Mode, and Troubleshooting

This chapter is about understanding failures quickly and safely.

## Common Failure Families

### Parser And Shape Errors

Typical causes:

- malformed root forms
- malformed child entries
- malformed `?ports` or `?toplink` tokens
- malformed `+system` or `:=` payloads
- `+size` expressions that reference unknown symbols or whole aggregate values
  where one scalar integer width is required
- `+size` arithmetic that cannot produce a valid positive integer width, such
  as division or modulo by zero
- `+size` operators outside the bounded supported set, such as `pow`
- `+size` operator forms with malformed arity, such as `(+ 8)`

These should now fail explicitly instead of falling through to vague behavior.

### Composition Planning Errors

Typical causes:

- unknown child source
- missing `.rtlif` metadata
- width mismatch
- direction mismatch
- duplicate drivers
- ambiguous connect-by-name
- blocked omitted-`?ports` inference
- incompatible declared type contracts
- unsupported explicit-link topology
- malformed `?ports`, `?toplink`, `?fsmc`, `?dtc`, `?rtl`, or `.rtlif`
  structure

Composition failures try to preserve artifact context. Depending on the failing
surface, non-quiet CLI output may include a lane, construct, child source file,
expected child source file, expected RTL metadata file, resolved RTL metadata
file, search roots, endpoint, actual source, top expression, child expression,
or blocked reason. That context is part of the public user experience: a
composition failure should identify the boundary that could not be planned
instead of emitting only a low-level parser or backend exception.

### Direct Generation Errors

Typical causes:

- illegal combinational self-dependency
- illegal D-input self-dependency in `<=` / `<=+`
- incompatible assignment widths
- undeclared internal operands
- unassigned internal operands

The pre-generation validation path exists specifically to catch these before
emission.

If a normal register update reads its previous value, prefer the Q/output-named
form, for example `(<- (COUNT (+ COUNT 1)))`. The D-input-named forms `<=` and
`<=+` are stricter: their RHS and assignment guard may not read the same LHS
name, because that would build a combinational loop on the next-value carrier.

## Failure Summaries

Non-quiet `bin/fsmgen` runs now try to keep useful local context in summaries,
for example:

- lane
- construct
- child or top endpoint
- top expression
- child expression
- actual source or endpoint

That is especially important in composition, where the failing surface is often
one declared link or one inferred boundary family.

## Diagnostic Documentation Hints

Runtime diagnostics now point at mdBook chapters for user-facing contract
boundaries:

- the broad supported-boundary hint points at the reference map, which routes
  readers to the owning chapter family
- strict-mode diagnostics point at this chapter
- package/import diagnostics point at the symbols/types and package chapters

`docs/USER_GUIDE.md` remains a migration reference while the split continues,
but diagnostics should not use it as the primary normative target for current
language, package, strict-mode, or composition boundaries.

## Strict Mode

Strict mode exists to narrow the language toward the supported intentional
surface.

Examples of what strict mode is already used for:

- narrowing legacy root aliases
- rejecting some compatibility residue
- preventing accidental dependence on older looser spellings
- preferring canonical assignment pairs such as `(= (OUT IN))` over infix
  compatibility spellings such as `(OUT = IN)`

Use strict mode when you want the tool to tell you whether a source already
fits the cleaner forward contract.

The regression corpus deliberately keeps paired default-compatible and
strict-rejected assets for compatibility residue such as infix assignments, so
the supported boundary is machine-checked instead of living only in examples.
Coverage buckets are also tied to their intended classifications, so supported
smoke, legacy compatibility, and expected-failure entries cannot accidentally
borrow one another's execution contracts.
Expected-failure entries record compiled diagnostic patterns, and strict
rejection entries must also record compiled migration-hint patterns, so the
failure side of the corpus checks both "this fails" and "the user is guided
toward the canonical form."
Expected-failure entries also carry stable `FSMGEN_*` diagnostic codes from
`FSM::Support::DiagnosticCodes`. Those codes are meant for downstream tools and
long-lived docs: wording can improve, but the code is the machine identity for
the failure family.
It also keeps positive acceptance markers for canonical supported surfaces.
Every `supported_smoke` entry must pass default pipeline and CLI generation.
The current supported protocol fixtures and supported direct language-feature
fixtures also carry `strict_supported`, so they must pass through both the
strict pipeline API and `bin/fsmgen --strict`. These success contracts are
checked at the catalog level even if a future entry belongs to a new fixture
family. Supported direct language-feature entries must also carry explicit
HDL-shape pattern metadata, so the corpus checks emitted semantics instead of
only proving that generation completed.

## Diagnostic Codes

Diagnostic codes are the bridge between human-friendly error messages and
machine-friendly integration. Today they are cataloged for the regression
corpus and the capability manifest:

```text
FSMGEN_STRICT_INFIX_ASSIGNMENT
FSMGEN_STRICT_LEGACY_FSM_ROOT
FSMGEN_LANGUAGE_BAD_SIZE_ENTRY
FSMGEN_COMPOSITION_MISSING_RTLIF
```

Each code has severity, stability, family, and summary metadata.
`./bin/fsmgen --capability-manifest` exposes the registry, and the bounded
check-only JSON path emits those codes on matched expected failures:

```bash
./bin/fsmgen --strict --check --json path/to/file.fsm
```

That command writes no HDL. Unknown failure families still get JSON, but their
code is `null` until FSMGen deliberately promotes that family into the stable
diagnostic registry. Matched failures also include a nested
`support_accounting` object that points back to the matched corpus entry,
coverage bucket, classification, corpus family, diagnostic code, and
migration-hint availability. The classifier prefers the most specific matching
expected-error pattern so broad fallback patterns do not shadow narrower stable
codes.

The same check-only path is also regression-locked on the success side. Every
current `supported_smoke` corpus entry must succeed through `--check-json`, and
every current `strict_supported` entry must succeed through
`--strict --check-json`, while emitting success JSON and no HDL file. Those
corpus-backed successes also expose a report-level `support_accounting` object
with the matched catalog entry id, family, coverage bucket, classification,
source kind, and `strict_supported` marker. Successful files outside the corpus
keep the same object shape but report `matched: false`.

## Backend Expectations

Current backend truth:

- SystemVerilog: primary live backend
- Verilog: supported through the existing path
- VHDL: recognized by the CLI, but explicitly not implemented as a full backend

So a VHDL request currently failing is not a mystery bug. It is the honest
current boundary.

## Explicitly Out Of Active Support

FSMGen should fail closed when a source uses syntax outside the active
contract. Current out-of-support examples include:

- non-conventional `+system` sections, including alternate clock names,
  duplicate clock/reset entries, malformed reset identifiers, and incomplete
  system declarations
- unsupported top-level directive sections such as `(+clock clk)`,
  `(+areset rst_n)`, or `(+bogus ...)`
- unsupported tagged wrappers such as `?define:legacy_template` and other
  template roots outside the active `?fsm`, `?dt`, `?mod`, `?module`, and
  `?top` families
- bare top-level FSM content without a supported source root
- bare condition suffixes such as `(A <= B start)` and `(-> busy full)`
- empty guarded blocks such as `(<req)` or malformed action-only forms such as
  `(BROKEN)`
- malformed state/DT blocks that carry no real body, such as `(idle)` or
  `(-misc)`
- malformed selector branches without actions, such as `(?MODE (=0))`
- bare selector labels such as `(?MODE (BUSY ...))` or `(?MODE (0 ...))`
- computed test nodes without a selector expression or without branches, such
  as `(? (=0 ...))` or `(?(| A B))`
- unsupported expression operators, malformed operator arity, or guard-only
  tokens in ordinary RHS expression position
- legacy composition/template forms such as `?&...`, nested `?top`, nested
  `?ports` mapping directives, nested `?toplink`, multi-source `?fsmc`,
  placeholder selectors, repeat macros, and placeholder tokens
- composition requests with no child instances, malformed child payloads,
  duplicate child names, unsupported child kinds, or external RTL metadata that
  is missing, non-flat, empty, duplicated, wrongly typed, or system-output
  directed

This list is not a replacement for the exact diagnostic text. It is the book
home for the active rejection policy: unsupported syntax should be rejected
with local context instead of being interpreted opportunistically.

## Practical Debug Checklist

1. Re-run with trace enabled.
2. Confirm the active root kind.
3. Confirm imported packages and search roots.
4. Confirm port widths and directions.
5. Confirm named type compatibility when aliases are involved.
6. Inspect generated HDL or structural IR if planning succeeded.

## Regression Guidance

Before landing behavior changes, run the local regression suite:

```bash
./bin/ci-regression quick
./bin/ci-regression isf
./bin/ci-regression
```

Use `quick` for a small smoke set when you need fast feedback on basic direct
`.fsm`, composition, and ISF functionality. Use `isf` for the current
ISF-focused band. With no mode argument, `./bin/ci-regression` runs the full
Perl suite and remains the pre-push gate.

For focused work, run the nearby targeted `prove` suites first, then the
smallest `ci-regression` tier that covers the changed surface. The gate builds
the mdBook by default, so generated docs and runtime behavior stay under the
same local quality check. Use `--list` to inspect the concrete quick/ISF test
sets and `--no-book` only for a deliberately code-only turnaround check.
GitHub Actions is intentionally parked right now under
[.github/workflows-disabled/README.md](.github/workflows-disabled/README.md),
so this local repo-owned gate is the currently active regression entrypoint.

## Current Boundary

The project is trying to move toward:

- early failure
- local diagnostics
- regression-locked contracts

If a failure feels vague or misleading, that is still a product-quality gap,
not something users should simply accept.
