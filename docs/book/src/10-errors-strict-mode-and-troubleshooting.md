# Errors, Strict Mode, and Troubleshooting

This chapter is about understanding failures quickly and safely.

## Common Failure Families

### Parser And Shape Errors

Typical causes:

- malformed root forms
- malformed child entries
- malformed `?ports` or `?wiring` tokens
- malformed `+system` or `:=` payloads
- `+size` expressions that reference unknown symbols or whole aggregate values
  where one scalar integer width is required
- `+size` arithmetic that cannot produce a valid positive integer width, such
  as division or modulo by zero
- `+size` operators outside the bounded supported set, such as `pow`
- `+size` operator forms with malformed arity, such as `(+ 8)`

These should now fail explicitly instead of falling through to vague behavior.

`FSMGEN_LANGUAGE_SYSTEM_RESET_POLARITY` identifies an invalid explicit reset
polarity, for example `(sreset reset active_middle)` or
`(sreset reset (active_low))`. Use a literal `active_high` or `active_low` as
the optional final operand of `sreset` or `areset`. The diagnostic and authored
source are preserved in check/semantic JSON and MCP. Extra operands, duplicate
resets, malformed declarations and extended `asreset` forms are also rejected;
the polarity code does not classify every structural error. See
[explicit reset polarity](03-decision-trees-and-fsms.md#explicit-reset-polarity).

An empty source file is a source-read failure, not a Lisp parser failure. FSMGen
reports the source path, says that the file is empty, and tells the user to
provide a non-empty FSMGen source file. The pipeline, CLI, check JSON, and
normalized semantic JSON surfaces all use that targeted message instead of
leaking raw Lispish fallback text or Perl stack frames.

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
- malformed `?ports`, `?wiring`, `?fsmc`, `?dtc`, `?rtl`, or `.rtlif`
  structure

Composition failures try to preserve artifact context. Depending on the failing
surface, non-quiet CLI output may include a lane, construct, child source file,
expected child source file, expected RTL metadata file, resolved RTL metadata
file, search roots, endpoint, actual source, top expression, child expression,
or blocked reason. That context is part of the public user experience: a
composition failure should identify the boundary that could not be planned
instead of emitting only a low-level parser or backend exception.

### Direct Generation Errors

ISF rule guards and read operands are checked against declared actor symbols
before lowering. `FSMGEN_LANGUAGE_ISF_UNDECLARED_RULE_OPERAND` identifies the
actor, missing operand and reading rules in check/semantic JSON and MCP.
Declare or correct the operand; see [Rules and Priorities](13g-rules.md).

`FSMGEN_LANGUAGE_ISF_STORAGE_IDENTIFIER` rejects an actor storage variable
whose name is an HDL keyword, such as `cell`. The diagnostic identifies the
actor, variable and reserving target before lowering. Rename the variable and
its references; see [Actor-Owned Storage](13a-actor-interface.md#actor-owned-storage).
Check and semantic JSON preserve this classified failure through MCP.
Schedule preview retains its existing message-only failure contract.

Typical causes:

- illegal combinational self-dependency
- illegal D-input self-dependency in `<=` / `<=-` / legacy `<=+`
- incompatible assignment widths
- undeclared internal operands
- unassigned internal operands

The pre-generation validation path exists specifically to catch these before
emission.

For an ISF rule assigning an explicitly declared eight-bit `VALID` input to a
one-bit `B` output, the operand failure identifies `B`, `VALID`, both widths,
and the need for an explicit width-aligned expression. It names the authored
`.isf` in `source.resolved_path`, `diagnostics[].source_file`, and the message,
even when the error arose in a generated domain child. The same source-origin
projection applies to PPIF lowering and to explicitly retained `--outdir`
files. Actual external child sources and unresolved lookup targets retain
their own paths. Rechecking a retained `.fsm` directly reports that `.fsm`.

The CLI, check/semantic JSON, and their API/MCP queries retain the operand
reason without the validator's Perl module or method names. MCP projects
repository paths to relative paths and preserves the complete failure report.
A width error may still have an unclassified diagnostic code; use the report's
failure status and reason, rather than assuming every width error has a stable
code. Source-origin projection does not provide a source line or column.

Illegal combinational self-dependency failures are reported as source-local
diagnostics before HDL emission. The CLI, `--check-json`, and
`--emit-semantic-json` surfaces keep the source context, the rejected `=`
assignment family, the discovered dependency path, and the remediation hint to
use `<-` or rewrite the expression; they do not expose parser implementation
filenames, parser routine names, or Perl call-stack frames.

If a normal register update reads its previous value, prefer the Q/output-named
form, for example `(<- (COUNT (+ COUNT 1)))`. The D-input-named forms `<=` and
`<=-` are stricter: their RHS and assignment guard may not read the same LHS
name, because that would build a combinational loop on the next-value carrier.

D-input self-dependency diagnostics are also source-local before HDL emission.
The CLI, `--check-json`, and `--emit-semantic-json` surfaces identify the
rejected operator, whether the RHS or guard expression caused the failure, the
self-dependent signal, and the two intended fixes: use `<-` for Q/output-named
feedback, or read the generated `<signal>_r` Q mirror when same-cycle D-input
visibility is required. Those surfaces do not expose parser implementation
filenames, parser routine names, or Perl call-stack frames.

In default mode, legacy `<=+` is accepted as an alias for `<=-` and follows the
same self-dependency rule. In strict mode, `<=+` is rejected as compatibility
residue; write the preferred `<=-` pair form instead.

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

The book summary, reference map, and owning chapters are the canonical targets
for current language, package, strict-mode, and composition diagnostics.

## Strict Mode

Strict mode exists to narrow the language toward the supported intentional
surface.

Examples of what strict mode is already used for:

- narrowing legacy root aliases
- rejecting some compatibility residue
- preventing accidental dependence on older looser spellings
- preferring canonical assignment pairs such as `(= (OUT IN))` over infix
  compatibility spellings such as `(OUT = IN)`
- preferring the D-input dual-output spelling `(<=- (D_IN NEXT_VALUE))` over
  the legacy `<=+` alias
- preferring canonical composition wiring entries such as `(child.out top_out)`
  or `(connect child.out top_out)` over legacy `/child.out/top_out/` slash-link
  tokens

Use strict mode when you want the tool to tell you whether a source already
fits the cleaner forward contract.

The regression corpus deliberately keeps paired default-compatible and
strict-rejected assets for compatibility residue such as infix assignments, so
the supported boundary is machine-checked instead of living only in examples.
That paired accounting now includes legacy composition `?wiring` slash-link
tokens: default mode still compiles `/source/target/`, while strict mode
rejects it with a diagnostic that names both canonical list-form replacements.

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

The composition-contract expected-failure catalog includes `fsm/trial_2.fsm` as
a historical legacy `?ports` mapping sample. Its first stable boundary is the
`FSMGEN_COMPOSITION_PORT_DECLARATION_MODE` diagnostic for the
`/data_o/{tasu_timestamp, tasu_pl_data}/` mapping directive inside `?ports`.
It also includes `fsm/lte_digital_rf.fsm`, whose first stable boundary is the
`FSMGEN_COMPOSITION_RTL_CHILD_SOURCE_COUNT` diagnostic for the
`?rtl:lte_dif_iosocket` child carrying 36 flat RTL module references.

The language-contract expected-failure catalog includes `fsm/generic_fifo.fsm`
as a historical template sample. Its first stable boundary is the
`FSMGEN_LANGUAGE_UNSUPPORTED_TOP_LEVEL_SOURCE` diagnostic for the
`?define:generic_fifo` root; the later `?&generic_fifo` macro instances,
bracket placeholders, and `?repeat` forms remain outside active support too.

The maintained language-contract expected-failure corpus now includes named
entries for unsupported top-level source wrappers, unsupported top-level
directives, unsupported top-level FSM body forms, legacy generic/template
placeholders, and bare condition suffixes. It also includes malformed
top-level source roots, malformed action/guard forms, malformed test branches,
malformed bare test selectors, duplicate default test selectors, and malformed
`+system` sections. It also carries source-shape and name/reference boundary
entries for malformed direct `?fsm:name` roots, empty structured `?fsm` roots
such as `(?fsm:empty_root_body)`, scalar top-level body items such as
`(?fsm:scalar_root_body BROKEN)`, malformed `?top:name` composition roots,
malformed state or standalone-DT names, malformed transition targets, and
unknown transition targets. State-body entries cover empty regular state blocks
such as `(idle)` and empty standalone-DT blocks such as `(-misc)`.
RHS-expression entries cover unsupported expression operators such as
`(bogus B C)`, malformed operator arity such as `(== B)`, and guard-only
tokens such as `<start` in ordinary value position.
Condition-expression entries cover malformed guard shorthand payloads such as
`<mode=` and `<==3`, plus malformed inline comparison tokens such as
`cnt[2:1]!=` and `=3`.
Assignment-boundary entries cover malformed delayed-pulse RHS values, mixed
combinational/sequential assignment families, mixed pulse and non-pulse
sequential writes, multiple pulse delays for one signal, combinational
self-dependency, and D-input self-dependency. Authored operator/directive
entries cover unsupported assignment operators such as `?=` and `=>`, plus
unsupported compact `:=` reset values such as `[DATAIN]` and `<start`.
Init-directive shape entries cover malformed `:=` payloads such as
`(:= (tester_reset=1 extra))` and `(:= (tester_reset))`, plus unsupported
compact `:=` directives such as `(:= BROKEN)`.
Empty symbol-section entries cover empty `+constants`, `+define`, `+params`,
and `+enums` forms that have no symbol declarations.
Malformed symbol-entry entries cover malformed `+constants`, `+define`,
`+params`, and `+enums` member payloads that do not match their required
entry shapes.
Symbol-value entries cover unresolved `+params` value names and ambiguous bare
bitstring-like `+constants` / `+params` values that must be written with an
explicit numeric base or width.
Parameter dependency entries cover cyclic `+params` dependency graphs and
duplicate `+params` declarations.
Aggregate parameter-expression entries cover mixed aggregate/scalar operands,
shape mismatches, arithmetic overflow, arithmetic underflow, and divide-by-zero
inside aggregate `+params` expressions.
Symbol-token entries cover malformed `+constants`, `+define`, and `+params`
identifiers plus non-scalar `+enums` member values.
Legacy `+fsm` body entries cover empty legacy `+fsm` roots and scalar nested
body items such as `(+fsm plus_scalar BROKEN)`.
Test-selector entries cover malformed plain `?SIG` signal names and computed
test selectors that omit their selector expression. Those entries are not only
prose examples. Inline-modifier entries cover malformed compound modifier
payloads such as `(+= 2 3)` and duplicate modifier clauses such as
`(+= 2) (-= 1)`. Update-shorthand entries cover nested targets such as
`(++ (counter))` or `(+= (byte_count) 4)`, plus malformed positional tails such
as `(+= counter 4 3)`. Pipeline, CLI, check JSON, and normalized semantic JSON
regression tests all classify these failures through the same support-accounting
path.

It also keeps positive acceptance markers for canonical supported surfaces.

Every `supported_smoke` entry must pass default pipeline and CLI generation.

The current supported protocol fixtures and supported direct language-feature
fixtures also carry `strict_supported`, so they must pass through both the
strict pipeline API and `bin/fsmgen --strict`. These success contracts are
checked at the catalog level even if a future entry belongs to a new fixture
family. Supported direct language-feature entries must also carry explicit
HDL-shape pattern metadata, so the corpus checks emitted semantics instead of
only proving that generation completed. Current supported direct
language-feature coverage includes direct-root `+system` contracts with
HDL-compatible authored clock names such as `core_clk`, using canonical
active-high synchronous reset spelling `(sreset reset)`, plus direct
omitted-`+system` defaults that lower to `clk`, async active-low `rst_n`, and
`!rst_n` reset tests. It also includes canonical assignment pairs and
update-shorthand `+=` / `-=` variants with implicit and explicit deltas, plus
compound update variants such as `++`, `--`, compact `+=N` / `-=N`, and inline
`(+= N)` / `(-= N)` modifiers. It also includes
arithmetic and XOR operator variants such as n-ary `+`, `-`, `*`, `add`, `^`,
and `xor`. It also includes
RHS expression variants such as inline scalar comparisons and negated n-ary
bitwise forms `!&`, `!|`, and `xnor`. It also includes legacy reset-state
alias DTs such as `-syncrst` and `-asyncreset`, which must lower as non-state
DT-style `syncreset`/`asyncreset` enable regions rather than encoded FSM
states. It also includes regular-state header
DTE guards that must keep state-enable and DTE
boundary-gating HDL shapes. It also includes standalone DT guards for
non-state `(-name ...)` blocks, including always-on DT enables, scalar guards,
negated guards, inline comparison guards, expression guards, and guarded
output-enable boundaries. Guard shorthand such as `<req`, `<!full`,
`<mode==3`, and suffix guards is covered with emitted HDL-shape checks for
truthiness, negated truthiness, comparisons, and multibit reduction. Nested
guarded blocks and compound list-form guards such as `<(& req start !full)`
are also covered for nested enable composition, assignment suffixes, and
transition suffixes. Relational
operator chains and word aliases such as `eq`, `ge`, and `not` are also
covered as supported-smoke entries with emitted comparison-shape checks.
Computed test selectors using `?(expr)` are covered as a positive supported
entry that must emit and reuse the computed selector intermediate, including
comparison-expression selectors such as `?(== A B)`. Plain HDL-compatible
`?SIG` test-node names are covered for equality branches, and symbolic
selectors plus `default` / `_` fallback selectors are covered for named
equality, explicit fallback negation, and fallback-alias branch enables.
Relational `?SIG` branch selectors such as `!=`, `>`, and `<=` are also
covered with width-safe reduction and comparison-enable HDL-shape checks.
Composition language-feature coverage includes implicit generated-child
system-port auto-wiring, where child FSMs that omit `+system` expose implicit
`clk` and `rst_n` ports and the generated top binds both children with
`.clk(clk)` and `.rst_n(rst_n)`.
Direct standalone `?dt` roots with explicit `+system` metadata are also
covered as supported-smoke entries with `dt` source-kind accounting, explicit
system-port HDL-shape checks, and a no-encoded-`current_state` expectation.
The paired generated-child path is covered too: `?dtc` composition entries
with explicit standalone-DT system metadata must emit the child module and bind
`.clk(clk)` / `.rst_n(rst_n)` at the generated top.

## Diagnostic Codes

Diagnostic codes are the bridge between human-friendly error messages and
machine-friendly integration. Today they are cataloged for the regression
corpus and the capability manifest:

```text
FSMGEN_STRICT_INFIX_ASSIGNMENT
FSMGEN_STRICT_LEGACY_FSM_ROOT
FSMGEN_LANGUAGE_BAD_SIZE_ENTRY
FSMGEN_LANGUAGE_UNSUPPORTED_TOP_LEVEL_DIRECTIVE
FSMGEN_LANGUAGE_UNSUPPORTED_TOP_LEVEL_FORM
FSMGEN_LANGUAGE_GENERIC_PLACEHOLDER_TOKEN
FSMGEN_LANGUAGE_BARE_CONDITION_SUFFIX
FSMGEN_LANGUAGE_UNSUPPORTED_ACTION_FORM
FSMGEN_LANGUAGE_MALFORMED_TEST_SELECTOR
FSMGEN_LANGUAGE_DUPLICATE_DEFAULT_TEST_SELECTOR
FSMGEN_LANGUAGE_INCOMPLETE_SYSTEM_SECTION
FSMGEN_LANGUAGE_DUPLICATE_SYSTEM_RESET
FSMGEN_LANGUAGE_MALFORMED_FSM_ROOT_BODY
FSMGEN_LANGUAGE_MALFORMED_FSM_ROOT_BODY_ITEM
FSMGEN_LANGUAGE_MALFORMED_STATE_NAME
FSMGEN_LANGUAGE_MALFORMED_STATE_DT_BLOCK
FSMGEN_LANGUAGE_UNKNOWN_TRANSITION_TARGET
FSMGEN_LANGUAGE_UNSUPPORTED_RHS_EXPRESSION_OPERATOR
FSMGEN_LANGUAGE_MALFORMED_RHS_EXPRESSION_ARITY
FSMGEN_LANGUAGE_UNSUPPORTED_RHS_EXPRESSION_TOKEN
FSMGEN_LANGUAGE_MALFORMED_GUARD_CONDITION_PAYLOAD
FSMGEN_LANGUAGE_MALFORMED_INLINE_COMPARISON_EXPRESSION
FSMGEN_LANGUAGE_DELAYED_PULSE_RHS
FSMGEN_LANGUAGE_DELAYED_PULSE_LHS_TARGET
FSMGEN_LANGUAGE_D_INPUT_SELF_DEPENDENCY
FSMGEN_LANGUAGE_UNSUPPORTED_ASSIGNMENT_OPERATOR
FSMGEN_LANGUAGE_UNSUPPORTED_INIT_RESET_VALUE
FSMGEN_LANGUAGE_MALFORMED_INIT_DIRECTIVE_PAYLOAD
FSMGEN_LANGUAGE_UNSUPPORTED_INIT_DIRECTIVE
FSMGEN_LANGUAGE_EMPTY_CONSTANTS_SECTION
FSMGEN_LANGUAGE_EMPTY_DEFINE_DIRECTIVE
FSMGEN_LANGUAGE_EMPTY_PARAMS_SECTION
FSMGEN_LANGUAGE_EMPTY_ENUMS_SECTION
FSMGEN_LANGUAGE_MALFORMED_CONSTANTS_ENTRY
FSMGEN_LANGUAGE_MALFORMED_DEFINE_ENTRY
FSMGEN_LANGUAGE_MALFORMED_PARAMS_ENTRY
FSMGEN_LANGUAGE_MALFORMED_ENUMS_MEMBER
FSMGEN_LANGUAGE_MALFORMED_TEST_SIGNAL
FSMGEN_LANGUAGE_MALFORMED_COMPUTED_TEST_SELECTOR
FSMGEN_LANGUAGE_MALFORMED_INLINE_MODIFIER
FSMGEN_LANGUAGE_DUPLICATE_INLINE_MODIFIER
FSMGEN_LANGUAGE_MALFORMED_UPDATE_SHORTHAND_TARGET
FSMGEN_LANGUAGE_MALFORMED_UPDATE_SHORTHAND_TAIL
FSMGEN_COMPOSITION_MISSING_RTLIF
```

Each code has severity, stability, family, and summary metadata.

`./bin/fsmgen --capability-manifest` exposes the registry, and the bounded
check-only JSON path emits those codes on matched expected failures:

```bash
./bin/fsmgen --strict --check --json path/to/file.fsm
```

That command writes no HDL. Unknown failure families still get JSON, including
`.isf` parser, lowering, schedule-report, and semantic check failures, but
their code is `null` until FSMGen deliberately promotes that family into the
stable diagnostic registry. Matched failures also include a nested
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

For public sources that lower through generated `.fsm` intermediates, such as
`.isf` and `.ppif`, successful check JSON and normalized semantic JSON keep
`source.resolved_path` on the original resolved public input path and match
support accounting against that public path. The normalized semantic payload
still describes the generated `.fsm` semantic root. The generated `.fsm`
remains an internal review/lowering artifact unless the command explicitly
writes it through `--outdir`.

## Backend Expectations

Current backend truth:

- SystemVerilog: primary live backend
- Verilog: supported through the existing path
- VHDL: bounded direct single-FSM and exact composition subsets are shipped;
  full-backend parity and external compiler qualification remain backlog

For a supported root, `--language vhdl` routes through the live VHDL backend.
Unsupported expressions, declarations, generic maps, aggregate shapes,
packages, or composition forms fail closed instead of silently falling back to
SystemVerilog. Text generation alone is not external qualification: this
environment has no GHDL or equivalent VHDL compiler lane. The exact shipped
matrix and remaining full-backend work are canonical under
[Backends And Validation](14-feature-backlog.md#backends-and-validation).

Composition VHDL is intentionally exact rather than general. The shipped
families cover the documented C1 standalone-DT, C2 generated-FSM, C3 external-
RTL, and APB/C4 generated-FSM fixtures; other composition shapes are rejected
before HDL emission with an explicit target-support diagnostic.

## Explicitly Out Of Active Support

FSMGen should fail closed when a source uses syntax outside the active
contract. Current out-of-support examples include:

- malformed `+system` sections, including duplicate clock/reset entries,
  malformed clock/reset identifiers, and missing clock declarations
- unsupported top-level directive sections such as `(+clock clk)`,
  `(+areset rst_n)`, or `(+bogus ...)`
- unsupported tagged wrappers such as `?define:legacy_template` and other
  template roots outside the active `?fsm`, `?dt`, `?mod`, `?module`, and
  `?top` families
- historical template files such as `fsm/generic_fifo.fsm`, whose
  `?define:generic_fifo` root, `?&generic_fifo` macro instantiations, bracket
  placeholders, and `?repeat` forms remain outside the active parser contract
- bare top-level FSM content without a supported source root
- unsupported top-level FSM body forms inside a supported root, such as
  `(tester_reset := 1)` or `(BROKEN 1)`
- bare condition suffixes such as `(A <= B start)` and `(-> busy full)`
- empty guarded blocks such as `(<req)` or malformed action-only forms such as
  `(BROKEN)`
- malformed state/DT blocks that carry no real body, such as `(idle)` or
  `(-misc)`
- malformed selector branches without actions, such as `(?MODE (=0))`
- bare selector labels such as `(?MODE (BUSY ...))` or `(?MODE (0 ...))`
- duplicate default selector branches in the same selector node, such as
  `(default ...)` together with `(_ ...)`
- computed test nodes without a selector expression or without branches, such
  as `(? (=0 ...))` or `(?(| A B))`
- unsupported expression operators, malformed operator arity, or guard-only
  tokens in ordinary RHS expression position
- malformed delayed-pulse assignments with non-literal RHS values or
  unsupported indexed, sliced, aggregate, or deconstruct LHS targets
- legacy composition/template forms such as `?&...`, nested `?top`, nested
  `?ports` mapping directives, nested `?wiring`, multi-source `?fsmc`,
  placeholder selectors, repeat macros, and placeholder tokens
- composition requests with no child instances, empty child entries,
  non-string child headers, dotted-pair child payloads, duplicate child names,
  duplicate top ports, unsupported child kinds, legacy `?ports` mapping
  directives, multiple `?ports` blocks, omitted or empty `?ports` outside
  inferable lanes, missing explicit `?wiring` for explicit-link topologies,
  C1 passthrough missing exposure, unknown top-port, width mismatch, or
  direction mismatch failures,
  declared same-name on shared system ports, aggregate-member child endpoints
  without declared aggregate types,
  malformed verbose `?ports` declarations, invalid `?ports` tokens,
  non-positive `?ports` widths, malformed `?wiring` list-form endpoints,
  unsupported `?wiring` tokens, strict-mode legacy `?wiring`
  `/source/target/` slash-link tokens, malformed composition-top symbol names, or
  non-literal composition-top enum values,
  missing external generated child sources, wrong-kind external generated-child
  roots such as `?fsmc` resolving to `?dt:name` or `?dtc` resolving to
  `?fsm:name`, malformed `?fsmc` / `?dtc` source counts, unsupported nested
  `?fsmc` / `?dtc` payload blocks, malformed `?rtl`
  module-reference counts, unsupported nested `?rtl` payload blocks, or
  external RTL metadata that is missing, non-flat, empty, duplicated, wrongly
  typed, or system-output directed

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
./bin/ci-regression smoke
./bin/ci-regression isf
./bin/ci-regression vial-gate
./bin/ci-regression
```

Use `quick` for a small smoke set when you need fast feedback on basic direct
`.fsm`, composition, and ISF functionality. `smoke` is an alias for the same
tier. Use `isf` for the current ISF-focused 109x, 11xx, 12xx, and 13xx
numbered bands. Use `vial-gate` only for the selected authenticated architecture-
scale gate. With no mode argument, `./bin/ci-regression` runs the full Perl suite,
then that VIAL gate, and remains the unsharded pre-push gate.

For focused work, run the nearby targeted `prove` suites first, then the
smallest `ci-regression` tier that covers the changed surface. The gate builds
the mdBook by default, so generated docs and runtime behavior stay under the
same local quality check. Use `--list` to inspect the concrete quick/ISF test
sets and `--no-book` only for a deliberately code-only turnaround check.

GitHub Actions is active under `.github/workflows/`. The hosted regression
workflow runs the same `./bin/ci-regression` entrypoint on pushes to `main`,
pull requests targeting `main`, and manual runs. Hosted execution uses 16
disjoint ordinary-file shards, five dedicated long/provider-dependent tests,
16 entry shards for each of four supported-corpus audits, and one isolated job
for each of the 68 cases in the large dynamic transaction-ID focused test. All
four Perl matrices continue after individual failures. A final required result
succeeds only when every shard, doctrine enforcement, the separate mdBook
build, and one unsharded VIAL regression-promotion gate succeed. Exactly the
dedicated `t/1598`, `t/1648`, and `t/1650`
coordinates materialize exact OSVVM 2026.05 beneath their isolated repository-
local caches; only `t/1436` receives its pinned HDL tools. Hosted shards do not
inherit the local VIAL gate lifecycle. The ordinary local `./bin/ci-regression`
command remains unsharded and includes both that lifecycle and the book build.
The separate hosted gate pins Ubuntu 24.04 and Perl 5.32, rejects ambient
Verilator or the fixed GHDL coordinates, materializes exact OSVVM 2026.05,
calls `./bin/ci-regression vial-gate --no-book`, and independently authenticates
the expected eight-informational/three-unavailable latest result before an
always-running cleanup removes its owned evidence, provider, result, and stage.
This is configured CI coverage; independent execution closeout remains a
separate step and no hosted performance or support claim follows from it.
The GitHub Pages workflow builds this mdBook from `docs/book` and publishes the
generated `docs/book/book` artifact when Pages is configured to use GitHub
Actions.

Hosted regression uses a minimal Perl setup. Ordinary runtime paths should not
depend on undeclared local CPAN modules, and CLI report modes that are tested
for clean stderr must remain compatible with the hosted Perl version.

## Decision-store diagnostics

Maintainers can audit decision identities and consumer references at a fixed
source revision without moving records or changing their authority:

```bash
scripts/run_with_ram_guard.sh -- python3 -B scripts/audit_decision_identity_capacity.py \
  --revision 25c01f0127144922ade78951b91439e1d9221c08 \
  > .artifacts/decision-identity-capacity.json
```

The JSON names its source revision, exact index destinations, record digests,
sealed-reader comparisons, root dimensions and scoped consumer candidates.
It runs the captured reader in a repository-local temporary fixture. Basename
and literal-fragment searches include tracked provenance; generic code-path
candidates are listed separately. This is historical evidence, with explicit
limits for dynamic and external consumers. It does not move decision records
or replace their current [discovery index](../../../docs/decisions/INDEX.md).

The decision rollover also has separately qualified catalog and authenticated
store preparation modules. Maintainers can exercise their literal future-store
fixtures:

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/2000-decision-catalog-preparation.t t/2001-decision-store-navigation.t
```

These controls check source/original identity, semantic routes, copied metadata,
record bytes and unsafe or missing files. Store controls also authenticate the
transition source and original index, preserve compatibility headings, and
check complete root/part navigation against selected bytes. The published
reader still handles the existing sealed cohort; preparation does not move
records or admit new authority paths. Source rollout remains tracked work.

The published reader also handles explicitly supplied authenticated stores.
Such a store requires `--root`, `--source-sha256` and `--index-sha256`; the
digests must come from independent trusted source/index evidence. The current
repository has not installed the live catalog rollover yet. Without a catalog,
ordinary `check` and sealed `read` retain their existing behavior.

| Operation | Selected product |
| --- | --- |
| `read IDs` | Captured original bytes when available; current bytes for fresh uncaptured IDs. |
| `read-original IDs` | Captured originals; an uncaptured fresh ID refuses. |
| `read-current IDs` | Current canonical bodies in an authenticated store; sealed-only IDs refuse. |
| `resolve CANONICAL_PATH` | Exact authenticated canonical ID/path/source/content binding; this grants no new authority. |

Requests validate completely before any record output. Current owned status or
first-time fact-index changes preserve immutable original products. Malformed
schema kinds, missing or altered store products and unavailable IDs refuse.
Exercise the actual CLI controls with:

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl t/2002-decision-reader-stores.t
```

Selected Git access and prior/current catalog continuity also have independent
controls:

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl t/2003-decision-store-git-continuity.t
```

They pin selected object IDs rather than borrowing later index/worktree data,
and reject deletion/reuse of decision identities or loss of previously published
fact/question keys. The gate integration must enforce this comparison on every
catalog change before live source rollout; standalone current validation cannot
infer records born after its fixed source census.

The published operations can select `--snapshot index`, `HEAD`, `HEAD^` or an
exact Git commit; omitted selection uses the working files. Selected reads use
the captured regular blobs and complete root inventory throughout, including
legacy sealed-record checks. Later working edits cannot supply missing selected
bytes or replace selected navigation.

`check-continuity` additionally requires `--prior-snapshot HEAD`, `HEAD^` or an
exact commit. It returns one bounded JSON product after authenticating both
selected stores. Optional canonical path arguments return exact bindings,
current text and `fresh_identity`, which is relative to the selected predecessor.
A record born after the transition is fresh once; a later check against its
published predecessor returns false. This binding alone grants no ceiling
increase. For an explicitly trusted fixture store:

```bash
scripts/decision_records.py --root "$store_root" \
  --source-sha256 "$trusted_source_sha256" --index-sha256 "$trusted_index_sha256" \
  --snapshot index --prior-snapshot HEAD check-continuity
```

The fingerprints must come from independent trusted evidence. Supplying them
for the reader's own repository is refused, including when production pins are
installed. First catalog adoption must match the exact predecessor commit,
complete root identity population, original index and original bodies. Catalog
removal, lost prior IDs or question/fact keys, invalid requests and oversized
change products refuse without partial output. With neither snapshot containing
a catalog, the change product reports `catalog: false`; it makes no sealed-reader
qualification claim. The Perl ceiling-authority gate now consumes the same
atomic product whenever either selected snapshot has a catalog.

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl t/2004-decision-reader-snapshots.t
```

The ceiling-authority gate selects staged, working or committed changes from
the controlled decision store and reader inputs as well as registry/authority
files. Ordinary catalog growth or updates receive prior-current continuity
checks even when no ceiling increases. Existing flat historical authorities
remain append-only, and no-catalog controls retain their legacy behavior.

Canonical authority additionally requires a fresh decision ID, a canonical file
absent from the selected predecessor, and the four exact authority markers
outside fenced examples. A relocated transition record or a previously
published birth cannot authorize a new increase. Mixed staged/working controlled
files, malformed stores, lost identities and mismatched control-file bytes refuse.
The reader's optional `--bind-file PATH` arguments expose selected prior/current
SHA-256 bindings; the gate uses these to compare its registry and authority bytes
with the same captured reader inventory. Output and diagnostics are bounded.

The actual gate accepts independently trusted fixture fingerprints only with
an explicit other `--root`. They cannot override production authority at its
own repository root. Boolean schema versions refuse in both registry metadata
and authority rows. Production catalog delivery and pins remain a separate
atomic rollover; this integration does not raise a ceiling.

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl t/2005-decision-ceiling-stores.t
```

Post-transition facts also have an independent mode matrix. Its complete current
snapshots pass standalone authentication and navigation before the actual prior
comparison rejects identity/path/type recycling, lost facts/questions and reused
earlier ID gaps. Additive owned content/status/summary/question changes pass.

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl t/2006-decision-identity-modes.t
```

Malformed source/original/catalog products, missing navigation rows, altered
compatibility pages and unsafe files refuse in every selected gate mode.
Orphan, reused, borrowed and misrouted authority also refuses. Installed default
mode additionally preserves the published sealed originals; fixture pins cannot
replace that authority. Supplied fingerprints must have the required lowercase
hexadecimal form even when neither selected snapshot has a catalog. A valid
no-catalog request retains its explicit non-catalog result.

The controlled reader-dispatch tests also plant oversized output and diagnostics,
malformed JSON products and signal failure after valid output. Each refuses:

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl t/2007-decision-hostile-boundaries.t
```

## Current Boundary

The project is trying to move toward:

- early failure
- local diagnostics
- regression-locked contracts

If a failure feels vague or misleading, that is still a product-quality gap,
not something users should simply accept.
