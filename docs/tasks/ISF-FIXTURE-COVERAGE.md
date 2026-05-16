# ISF-FIXTURES: Realistic Fixture And Strict-Mode Coverage

## Metadata

- Tree ID: `ISF-FIXTURES`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Broaden ISF confidence from focused construct tests into realistic protocol
fixtures, strict-mode checks, scheduled `.fsm` review artifacts, schedule JSON,
and generated HDL paths that prove user-facing ISF features work together.

## Non-Goals

- Do not add large fixtures without clear feature coverage value.
- Do not snapshot full backend output when stable structural assertions are
  enough.
- Do not use fixtures as a substitute for focused malformed-boundary tests.

## Acceptance Criteria

- Existing ISF fixtures and test bands are inventoried.
- A fixture matrix maps realistic protocols to ISF feature families,
  schedule-report assertions, strict-mode checks, and HDL generation paths.
- New fixtures are added only when they cover a feature interaction or risk not
  already covered by focused tests.
- Quick/ISF/full regression tier impact is documented.
- ISF spec, public contract, mdBook, roadmap, and live docs reference fixture
  coverage only where it supports shipped behavior.

## Task Tree

- ID: `ISF-FIXTURES`
  Status: `done`
  Goal: `Expand realistic ISF fixture and strict-mode coverage.`
  Children: `ISF-FIXTURES.1`, `ISF-FIXTURES.2`, `ISF-FIXTURES.3`,
  `ISF-FIXTURES.4`, `ISF-FIXTURES.5`

- ID: `ISF-FIXTURES.1`
  Status: `done`
  Goal: `Inventory current ISF fixtures, tests, and regression tiers.`
  Acceptance: `The task file lists current ISF fixtures, 109x/11xx/12xx
  tests, quick/isf/full tier coverage, strict-mode checks, and gaps.`
  Verification: `./bin/ci-regression --list`; `prove -l t/1183-ci-regression-tier-selection.t t/1091-isf-parser-apb-requester.t t/1094-isf-scheduler-module-header.t t/1112-isf-public-interface-contract.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-FIXTURES.1: inventory fixture coverage`

- ID: `ISF-FIXTURES.2`
  Status: `done`
  Goal: `Define realistic fixture coverage matrix.`
  Acceptance: `The tree maps target fixtures to feature families, report
  assertions, generated HDL paths, and regression tier placement.`
  Verification: `prove -l t/1183-ci-regression-tier-selection.t`; `./bin/ci-regression --list`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-FIXTURES.2: define fixture coverage matrix`

- ID: `ISF-FIXTURES.3`
  Status: `done`
  Goal: `Add the next realistic fixture slice.`
  Acceptance: `One selected fixture exercises a documented feature
  interaction through scheduled `.fsm`, schedule JSON, strict mode where
  relevant, and HDL generation.`
  Verification: syntax checks for changed Perl modules and new tests; `prove -l t/271-systemverilog-shift-expression-generation.t t/1099-isf-repeat-data-ops.t t/1173-isf-shift-right-explicit-width.t t/1228-isf-spi-fixture-coverage.t t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-FIXTURES.3: cover SPI-like fixture path`

- ID: `ISF-FIXTURES.4`
  Status: `done`
  Goal: `Broaden regression-tier and support-accounting coverage where warranted.`
  Acceptance: `The selected fixture coverage is placed in the appropriate
  quick/isf/full tier without making fast turnaround noisy.`
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm t/1183-ci-regression-tier-selection.t t/1193-isf-drive-call-arity-boundary.t`; `prove -l t/1183-ci-regression-tier-selection.t t/1193-isf-drive-call-arity-boundary.t`; `./bin/ci-regression --list`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-FIXTURES.4: lock fixture tiers and expression actuals`

- ID: `ISF-FIXTURES.5`
  Status: `done`
  Goal: `Synchronize fixture documentation and close covered gaps.`
  Acceptance: `Docs and live status describe what realistic ISF behavior is
  fixture-backed and which feature interactions remain unclaimed.`
  Verification: `prove -l t/1183-ci-regression-tier-selection.t t/1193-isf-drive-call-arity-boundary.t`; `./bin/ci-regression --list`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-FIXTURES.5: close fixture coverage tree`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | All known fixture-coverage leaves are complete. Future fixture work should open or extend a task tree with a new executable leaf. |

## ISF-FIXTURES.1 Inventory

Current checked-in ISF fixtures:

| Fixture | Current purpose | Covered feature families | Current direct coverage | Gaps / notes |
| --- | --- | --- | --- | --- |
| `isf/apb_requester.isf` | Primary realistic APB request/response actor. | Interface widths, async active-low reset, watchdog, named/parameterized drives, samples, await, complete pulse, latency, schedule report storage metadata, strict HDL generation. | `t/1091`, `t/1094`, `t/1096`, `t/1100`, `t/1105`, `t/1106`, `t/1112`, `t/1116`, `t/1121`, `t/1123`, `t/1124`, `t/1146`-`t/1155`, and several public contract audits. | Strong baseline fixture; not enough by itself for repeat/control-flow/composition realism. |
| `isf/burst_reader.isf` | Burst read transaction with repeated await loop. | Dynamic repeat count, sampled aliases, await, watchdog, latency, completion pulse. | `t/1095-isf-scheduler-burst-reader.t`. | Schedule-report and HDL assertions are narrow. |
| `isf/full_featured.isf` | Broad parser/public-shell fixture. | Rules, triggers, priorities, resources, `do`, `spawn`, named drives, transaction ordering. | `t/1093`, `t/1157`, `t/1158`, `t/1166`, `t/1176`. | Good metadata/parser breadth; not a realistic protocol. |
| `isf/i2c_master.isf` | I2C-like serial transaction. | Parameterized drives, repeats, switch, shift-left, nested repeat in switch branches. | `t/1099-isf-repeat-data-ops.t`. | Needs schedule-report/HDL/strict fixture assertions before it can be a realistic signoff fixture. |
| `isf/spi_master.isf` | SPI-like mode-0 style serial transfer. | Parameterized drives, repeat, shift-left, sampled transmit byte, explicit serial bit drive, strict schedule/HDL path. | `t/1228-isf-spi-fixture-coverage.t` plus downstream `.fsm` shift-expression coverage in `t/271-systemverilog-shift-expression-generation.t`. | Covered as a bounded SPI-like mode-0 fixture, not as full SPI protocol compliance. |
| `isf/uart_tx.isf` | UART transmit byte flow. | Parameterized drives, repeat, shift-right. | `t/1099-isf-repeat-data-ops.t`. | Needs explicit-width `shift_right` fixture refresh and explicit serial-bit drive selection before strict/HDL promotion. |
| `isf/spawn_parent.isf` | Parent/child generated-composition fixture. | Spawned child module, generated top, start/done handoff, named-drive handoff, outdir lowering. | `t/1097`, `t/1117`, `t/1122`, `t/1128`, `t/1153`, `t/1156`, `t/1216`, `t/1217`. | Strong composition fixture; realistic protocol semantics are intentionally small. |
| `isf/switch_test.isf` | Simple switch dispatch fixture. | `switch` branch lowering and implicit fallthrough smoke. | `t/1097`; richer switch behavior is covered by inline sources in `t/1103` and `t/1205`. | File-backed schedule/HDL assertions are minimal. |
| `isf/when_test.isf` | Simple conditional body fixture. | `when` body lowering and repeated `when` smoke. | `t/1097`; richer `when` behavior is covered by inline sources in `t/1104`, `t/1107`, and `t/1206`. | File-backed schedule/HDL assertions are minimal. |
| `isf/phase_test.isf` | Transaction phase pass-through fixture. | Transaction phase metadata/pass-through state. | No dedicated file-backed regression found; phase behavior is covered by inline sources in `t/1179`. | Candidate for either removal from "representative" docs or direct coverage if kept. |

Current ISF regression tier:

- `./bin/ci-regression isf` selects all files matching
  `t/109[1-9]-isf*.t`, `t/11[0-9][0-9]-isf*.t`, and
  `t/12[0-9][0-9]-isf*.t`, sorted with unmatched future bands ignored by
  `nullglob`.
- Current count: `137` ISF-tier tests: `9` in the `109x` band, `98` in the
  `11xx` band, and `30` in the `12xx` band.
- The tier covers parser/lowering smoke, public interface contract audits,
  malformed-boundary tests, feature-specific lowering/report tests, generated
  composition, arbitration, data widths, storage roles, and the explicit
  schedule-report freeze boundary.
- `t/1183-ci-regression-tier-selection.t` is outside the ISF-tier filename
  pattern but validates `quick`, `smoke`, `isf`, `full`, `--list`,
  `--dry-run`, and `--no-book` tier behavior.

Current quick/smoke tier:

```text
t/01-regression.t
t/03-assignment-intent-metadata.t
t/13-composition-source-classification.t
t/29-language-contract-core-forms.t
t/84-composition-external-fsm-child-sources.t
t/1091-isf-parser-apb-requester.t
t/1094-isf-scheduler-module-header.t
t/1112-isf-public-interface-contract.t
```

The quick tier gives fast ISF coverage for APB parsing, APB scheduled `.fsm`
header generation, and the public ISF contract. It does not cover realistic
repeat/control-flow/composition fixture behavior.

Current strict-mode ISF coverage:

- `t/1124-isf-public-cli-strict-mode-audit.t` proves
  `./bin/fsmgen --strict file.isf` is accepted for APB HDL generation, keeps
  stderr clean, and writes the requested HDL.
- `t/1155-isf-public-cli-strict-success-metadata-audit.t` proves strict CLI
  success metadata and the APB strict HDL path.
- `t/1228-isf-spi-fixture-coverage.t` proves strict schedule JSON parity and
  strict HDL generation for the SPI-like fixture.
- No current strict-mode fixture regression targets I2C, UART, burst,
  switch/when, phase, or generated-composition sources.

Remaining inventory gaps after `ISF-FIXTURES.5`:

- I2C and UART are covered through repeat/data-op lowering but not through
  schedule JSON, strict mode, or generated HDL assertions.
- `phase_test.isf` is listed as a fixture but lacks direct file-backed
  coverage; inline tests cover the semantics.
- Quick/smoke currently exercises only APB for ISF; that is intentional for
  turnaround. The SPI-like fixture stays in `isf`, not `quick`.
- Strict-mode accepted-source fixture coverage is APB plus the bounded
  SPI-like serial-transfer fixture.
- I2C, UART, burst, rule/resource arbitration, and stage/contract realism
  fixtures remain future coverage candidates when those interactions need a
  protocol-like owner.

## ISF-FIXTURES.2 Realistic Fixture Matrix

Matrix rules:

- Quick/smoke stays intentionally small. It keeps APB parse, APB scheduled
  `.fsm` header, and the public ISF contract unless a future fixture gives
  high signal with negligible runtime cost.
- The `isf` tier owns realistic fixture coverage. A fixture moves there when
  it proves interaction among constructs, reports, generated `.fsm`, strict
  mode when relevant, or HDL handoff. A protocol-named fixture is still only a
  bounded authored fixture, not a claim of complete external protocol
  compliance.
- Do not snapshot full generated HDL or full schedule JSON when stable
  structural assertions are enough.
- A fixture is a forward-contract example only when strict mode accepts it or
  the task records why strict coverage is deliberately deferred.

| Fixture / target | Matrix role | Feature families to own | Schedule-report assertions | Scheduled `.fsm` / HDL assertions | Tier placement | Next action |
| --- | --- | --- | --- | --- | --- | --- |
| `isf/apb_requester.isf` | Current baseline realistic fixture. | Interface widths, async active-low reset metadata, watchdog, named/parameterized drives, samples, await, latency, complete pulse, storage roles. | Reset shape, transaction order/states/counts, DT kinds/counts, inferred storage kind/role/width where available, schedule JSON CLI parity. | Scheduled module header, plain HDL generation, strict HDL generation, clean stderr. | `quick` for parse/header/contract only; broader APB assertions in `isf`. | Maintain as baseline; do not add more APB-only quick tests unless a new public contract needs it. |
| `isf/spi_master.isf` | Compact SPI-like mode-0 serial-transfer fixture. | Parameterized drives, active-low `cs`, `sclk` toggling, explicit `mosi` bit-select drive, `miso` sampling, fixed 8-cycle repeat loop, sampled transmit byte, shift-left data movement. | Transaction state list/count, repeat counter storage, data-register storage/width, DT kind coverage for drive blocks, compatible request fan-in for repeated drive starts. | File-backed scheduled `.fsm` structure, generated HDL reachability, strict-mode accepted-source path, direct shift-expression HDL support. | `isf`; not `quick` initially. | Covered by `ISF-FIXTURES.3`; maintain as bounded SPI-like fixture, not full SPI compliance. |
| `isf/i2c_master.isf` | Second serial-protocol promotion target. | Parameterized drives, nested repeat, switch branches, shift-left, branch-specific serial behavior. | Transaction states, repeat counters, switch branch state coverage, storage width/role where known. | Generated HDL reachability and strict-mode acceptance after SPI proves the pattern. | `isf`; no quick promotion planned. | Follow SPI with a narrower I2C schedule/HDL slice if runtime cost stays acceptable. |
| `isf/burst_reader.isf` | Burst/wait-loop realism target. | Dynamic repeat count, sampled aliases, await, watchdog, latency, completion pulse. | Repeat/latency/watchdog storage roles, transaction state count/order, completion pulse storage. | Generated HDL reachability; strict mode only after the fixture is checked as forward-contract clean. | `isf`. | Refresh after serial fixtures to improve wait-loop/report assertions. |
| `isf/uart_tx.isf` | Data-width and shift-right realism target. | Parameterized drives, repeat, explicit-width `shift_right`, serial transmit framing. | Data register width evidence, transaction states, repeat counter storage. | Generated HDL reachability; strict mode if the fixture is promoted as a forward-contract example. | `isf`. | Use only if it adds width/shift-right signal beyond existing focused tests; it needs explicit serial-bit drive selection before strict/HDL promotion. |
| `isf/spawn_parent.isf` | Composition realism baseline. | Spawned child module, generated top, start/done handoff, named-drive handoff, parameter overrides, outdir lowering. | `generated_composition` summary, child/instance/link/binding keys, parent-only report scope. | Multi-file lower result, generated top reachability, `--outdir` behavior. | `isf`; not quick. | Maintain existing coverage; expand only when generated-child public surface widens. |
| `isf/full_featured.isf` | Parser/public-shell breadth fixture, not a realism signoff fixture. | Rules, triggers, priorities, resources, `do`, `spawn`, named drives, ordering metadata. | Actor-shell metadata and parser-carried resource/priority/stage/phase surfaces. | No strict/HDL promotion requirement because the source intentionally exercises breadth, not protocol realism. | `isf` parser/public contract tests. | Keep for parser breadth; do not use as proof of protocol behavior. |
| Future `isf/rule_resource_arbiter.isf` | Future rule/resource realism fixture. | Multiple rules sharing a `rule_slot`, priority arbitration, rule-trigger fan-in, conflict suppression. | `priority_resolutions`, `resource_arbitration`, compatible fan-in groups, compile-issue absence on the accepted path. | Generated HDL reachability for grant-gated rule DTs. | `isf`; no quick promotion. | Add only after a concrete protocol-like owner exists; focused tests already own mechanics. |
| Future `isf/stream_stage_contract.isf` | Future stage/contract realism fixture. | Ready/valid transaction stage, bounded eventual contract monitor, reset policy, generated monitor storage. | `transaction_stages`, `temporal_contracts`, monitor storage kind/role/width where available. | Generated HDL reachability for stage and monitor states/DTs. | `isf`; no quick promotion. | Add after stage/contract syntax stabilizes enough to be a user-facing example. |
| `isf/switch_test.isf`, `isf/when_test.isf`, `isf/phase_test.isf` | Small construct smoke fixtures. | Switch, when, and transaction-phase pass-through behavior. | Minimal unless promoted or merged into a realistic fixture. | No dedicated strict/HDL requirement today. | `isf` focused/smoke only. | Keep small; promote only if a realistic fixture needs the construct in context. |

Closure state:

- `ISF-FIXTURES.5` closes this tree. The shipped realistic fixture surface is
  now APB as the quick/smoke baseline plus the SPI-like serial-transfer fixture
  in the broader `isf` tier.
- Future fixture work should be opened as a new leaf under the relevant
  feature tree, or as a new fixture-focused tree if it cuts across several
  feature families.

## ISF-FIXTURES.3 SPI-Like Fixture Coverage

`ISF-FIXTURES.3` promotes `isf/spi_master.isf` into a file-backed
SPI-like mode-0 serial-transfer regression without claiming complete SPI
protocol compliance.

Implementation notes:

- `spi_master.isf` now drives one-bit `mosi` from `tx_byte[7]` before shifting
  `tx_byte` left. The previous full-byte drive was not width-aligned and the
  backend correctly rejected it as implicit truncation.
- The downstream `.fsm` expression pipeline now accepts raw `<<`, `>>`,
  `<<<`, and `>>>` plus `shl`, `shr`, `sal`, and `sar` aliases as binary
  expression operators through SystemVerilog generation. This closes the bug
  where ISF `shift_left` produced scheduled `.fsm` text that the HDL path then
  rejected.
- `t/1228-isf-spi-fixture-coverage.t` proves schedule JSON, scheduled `.fsm`
  structure, strict schedule JSON parity, plain HDL generation, and strict HDL
  generation for the SPI-like fixture.
- `t/271-systemverilog-shift-expression-generation.t` proves the underlying
  `.fsm` shift-expression contract directly, including targeted rejection of
  malformed n-ary shift expressions.

The fixture remains in the `isf` regression tier, not `quick`, so fast
turnaround remains APB-centered.

## ISF-FIXTURES.4 Regression Tier Placement

`ISF-FIXTURES.4` keeps the SPI-like fixture in the `isf` regression tier and
out of the curated quick/smoke tier.

Decision:

- `quick` stays limited to fast APB parse/header/contract coverage plus the
  existing direct/composition smoke set.
- `t/1228-isf-spi-fixture-coverage.t` belongs in `isf` because it runs
  schedule JSON, scheduled `.fsm`, plain HDL, and strict HDL checks for a
  realistic fixture.
- Named drive call actuals now preserve composed expression forms instead of
  stringifying nested list actuals as Perl array references. That keeps
  argument-level composition available where ISF authors naturally need it.
- The direct `.fsm` shift-expression regression,
  `t/271-systemverilog-shift-expression-generation.t`, belongs to the full
  suite rather than the ISF tier because it is a downstream expression/backend
  contract, not an ISF parser/scheduler test.
- No additional support-accounting corpus entry is warranted in this slice:
  the accepted SPI-like path is already covered by the ISF public
  `tested_by` provenance and by the `isf` regression tier. Future
  support-accounting expansion should happen only when the machine-readable
  support corpus needs to advertise this specific fixture as a public source
  capability example.

Fixture authoring policy:

- Realistic fixtures must be written with documented ISF constructs, not test
  hacks.
- If a fixture needs an awkward workaround, treat that as a language
  expressiveness signal: either rewrite the fixture using a documented
  construct, or add a backlog/task-tree item for the missing construct.
- Explicit bit selection such as `tx_byte[7]` is acceptable because it is a
  documented `.fsm` expression surface used directly in an ISF drive actual.
  Silent truncation from `tx_byte` to a 1-bit serial line is not acceptable.
- Because ISF is Lisp-like, composed argument expressions such as
  `(& tx_byte[7] shift_enable)` should be supported directly when the target
  construct accepts an expression-valued actual.
- Variadic forms are appropriate when they model natural list-like or
  associative hardware intent and have an unambiguous lowering. Examples
  include logical expression forms and future list-style coordination
  constructs. Exact arity remains the correct contract for forms with fixed
  semantic roles, such as `(sample port as name)`, `(complete port)`,
  `(spawn child as instance)`, and known drive calls whose formal list defines
  their positional contract.
- A new variadic surface is not accepted just because the syntax can parse an
  arbitrary list. It needs deterministic lowering, malformed-boundary
  diagnostics, fixture or focused coverage, and public documentation in the
  same slice.

## ISF-FIXTURES.5 Final Synchronization

The fixture tree closes with these current fixture-backed claims:

- APB remains the fast-turnaround ISF baseline through parser, scheduled
  `.fsm` header, public-contract, schedule-report, strict CLI, and HDL
  generation coverage.
- `isf/spi_master.isf` is a bounded SPI-like mode-0 serial-transfer fixture
  with file-backed schedule JSON, scheduled `.fsm`, plain HDL, and strict HDL
  coverage.
- Spawned-child composition has generated-top and multi-file handoff coverage,
  but it is not treated as a realistic protocol fixture.
- `full_featured.isf` remains parser/public-shell breadth coverage, not
  protocol signoff coverage.

The following interactions remain unclaimed by a realistic fixture:

- I2C and UART schedule JSON, strict mode, and generated HDL fixture paths.
- Burst/wait-loop strict-mode and generated-HDL fixture paths beyond the
  current focused burst scheduler coverage.
- Direct file-backed `phase_test.isf` coverage, if that fixture remains a
  representative public fixture.
- Rule/resource arbitration and stage/contract protocol-like realism fixtures.
- Any future resource-sharing or conflict-runtime verification fixture whose
  semantics need more than focused tests.

This is a closure of the known fixture-coverage tree, not a promise that no
additional fixtures are needed. New ISF features should add a fixture when a
focused regression would not prove the construct working in realistic
composition.

## Decisions

- `2026-05-14`: Fixture expansion is tracked separately so feature trees can
  stay focused while this tree owns cross-feature realism and regression-tier
  placement.
- `2026-05-14`: The first matrix-selected implementation fixture is
  `isf/spi_master.isf`, because it is compact, protocol-like, and currently
  lacks dedicated file-backed schedule/HDL/strict coverage.
- `2026-05-14`: `isf/spi_master.isf` is not treated as proof of full SPI
  protocol compliance. SPI behavior is device- and mode-specific, so this
  fixture is scoped to the authored mode-0-style serial transfer behavior in
  the file.
- `2026-05-14`: ISF shift operations are an end-to-end support claim only when
  the generated `.fsm` shift expressions also pass the downstream HDL path.
  Raw and aliased shift operators are now accepted by `.fsm` expression
  parsing and SystemVerilog generation as binary operators.
- `2026-05-14`: Realistic fixtures are allowed to expose missing ISF
  expressiveness. Workarounds should not be normalized in tests; they should
  be converted into documented constructs or tracked as missing language
  features.
- `2026-05-14`: ISF may use variadic forms for constructs whose semantics are
  naturally list-like or associative, provided the lowering path, diagnostics,
  tests, and public documentation are shipped with the construct. Constructs
  with fixed hardware roles should keep exact arity.

## Open Questions

- Whether any fixture beyond APB should ever join `quick`; the current answer
  is no until one proves high signal with negligible runtime.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-FIXTURES` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-FIXTURES.2` | `prove -l t/1183-ci-regression-tier-selection.t`; `./bin/ci-regression --list`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-FIXTURES.3` | Syntax checks for changed Perl modules and new tests; `prove -l t/271-systemverilog-shift-expression-generation.t t/1099-isf-repeat-data-ops.t t/1173-isf-shift-right-explicit-width.t t/1228-isf-spi-fixture-coverage.t t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t`; `./bin/ci-regression isf --no-book` (`136` files, `464` tests); `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-FIXTURES.4` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm t/1183-ci-regression-tier-selection.t t/1193-isf-drive-call-arity-boundary.t`; `prove -l t/1183-ci-regression-tier-selection.t t/1193-isf-drive-call-arity-boundary.t`; `./bin/ci-regression --list`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-FIXTURES.5` | `prove -l t/1183-ci-regression-tier-selection.t t/1193-isf-drive-call-arity-boundary.t`; `./bin/ci-regression --list`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-FIXTURES` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |
| `ISF-FIXTURES.1` | `ISF-FIXTURES.1: inventory fixture coverage` | Inventory of current fixtures, tiers, strict coverage, and gaps. |
| `ISF-FIXTURES.2` | `ISF-FIXTURES.2: define fixture coverage matrix` | Matrix defining fixture ownership, tier placement, and SPI-like mode-0 target scope. |
| `ISF-FIXTURES.3` | `ISF-FIXTURES.3: cover SPI-like fixture path` | SPI-like fixture coverage plus downstream `.fsm` shift-expression HDL support. |
| `ISF-FIXTURES.4` | `ISF-FIXTURES.4: lock fixture tiers and expression actuals` | SPI-like fixture stays in `isf`, not quick; drive actuals preserve composed expressions; no support-accounting corpus expansion yet. |
| `ISF-FIXTURES.5` | `ISF-FIXTURES.5: close fixture coverage tree` | Final fixture matrix sync, remaining unclaimed interactions, and ISF variadic expressiveness policy. |

## Changelog

- `2026-05-14`: Created the active ISF fixture-coverage task tree.
- `2026-05-14`: Added the realistic fixture coverage matrix and selected SPI
  as the next implementation fixture.
- `2026-05-14`: Added SPI-like fixture coverage and closed the downstream
  shift-expression HDL generation gap exposed by that fixture.
- `2026-05-14`: Locked the SPI-like fixture into the `isf` tier, left it out
  of quick, recorded the fixture-authoring expressiveness policy, and fixed
  composed drive-call actual lowering.
- `2026-05-14`: Closed the fixture tree with synchronized shipped/remaining
  fixture claims and the ISF arity policy for future variadic constructs.
