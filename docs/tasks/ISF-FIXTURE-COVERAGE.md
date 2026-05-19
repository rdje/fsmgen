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
  Acceptance: `The task file lists current ISF fixtures, 109x/11xx/12xx/13xx
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
| `isf/burst_reader.isf` | Burst read transaction with repeated await loop. | Dynamic repeat count, sampled aliases, await, watchdog, latency, completion pulse. | `t/1095-isf-scheduler-burst-reader.t`; `t/1310-isf-burst-fixture-coverage.t`. | Promoted as a bounded burst/wait-loop fixture with schedule-report, strict-mode, and HDL coverage. |
| `isf/full_featured.isf` | Broad parser/public-shell fixture. | Rules, triggers, priorities, resources, `do`, `spawn`, named drives, transaction ordering. | `t/1093`, `t/1157`, `t/1158`, `t/1166`, `t/1176`. | Good metadata/parser breadth; not a realistic protocol. |
| `isf/i2c_master.isf` | I2C-like serial transaction. | Parameterized drives, repeats, switch, shift-left, nested repeat in switch branches. | `t/1099-isf-repeat-data-ops.t`; `t/1309-isf-i2c-fixture-coverage.t`. | Promoted as a bounded I2C-like fixture with schedule-report, strict-mode, and HDL coverage. |
| `isf/spi_master.isf` | SPI-like mode-0 style serial transfer. | Parameterized drives, repeat, shift-left, sampled transmit byte, explicit serial bit drive, strict schedule/HDL path. | `t/1228-isf-spi-fixture-coverage.t` plus downstream `.fsm` shift-expression coverage in `t/271-systemverilog-shift-expression-generation.t`. | Covered as a bounded SPI-like mode-0 fixture, not as full SPI protocol compliance. |
| `isf/uart_tx.isf` | UART transmit byte flow. | Parameterized drives, repeat, shift-right. | `t/1099-isf-repeat-data-ops.t`; `t/1311-isf-uart-fixture-coverage.t`. | Promoted as a bounded UART-like transmit fixture with explicit serial-bit drive selection and strict schedule/HDL coverage. |
| `isf/spawn_parent.isf` | Parent/child generated-composition fixture. | Spawned child module, generated top, start/done handoff, named-drive handoff, outdir lowering. | `t/1097`, `t/1117`, `t/1122`, `t/1128`, `t/1153`, `t/1156`, `t/1216`, `t/1217`, `t/1315-isf-generated-composition-fixture-coverage.t`. | Promoted as a bounded generated-composition fixture with strict schedule-report, strict outdir, and top/parent/child HDL coverage. |
| `isf/rule_resource_arbiter.isf` | Rule/resource arbitration fixture. | Rule-over-transaction priority, `rule_slot` resource arbitration, lower-priority rule gating, delayed completion pulse behavior. | `t/1218-isf-rule-slot-resource-arbitration.t`; `t/1220-isf-arbitration-schedule-report.t`; `t/1316-isf-rule-resource-fixture-coverage.t`. | Promoted as a bounded rule/resource fixture with schedule-report, strict-mode, and HDL coverage. |
| `isf/stream_stage_contract.isf` | Ready/valid stage plus bounded temporal-contract fixture. | Sampled payload forwarding, ready/valid stage barrier, bounded eventual contract monitor, temporal monitor storage, SystemVerilog assertion projection, delayed completion pulse behavior. | `t/1223-isf-stage-lowering.t`; `t/1224-isf-contract-lowering.t`; `t/1225-isf-stage-contract-schedule-report.t`; `t/1254-isf-temporal-contract-storage-report.t`; `t/1317-isf-stage-contract-fixture-coverage.t`. | Promoted as a bounded stage/contract fixture with schedule-report, strict-mode, and HDL coverage. |
| `isf/switch_test.isf` | Simple switch dispatch fixture. | Sampled selector capture, explicit switch branches, default fallthrough, named-drive branch starts, delayed completion pulse behavior. | `t/1097`; `t/1103`; `t/1205`; `t/1313-isf-switch-fixture-coverage.t`. | Promoted as a bounded switch-dispatch fixture with schedule-report, strict-mode, and HDL coverage. |
| `isf/when_test.isf` | Simple conditional body fixture. | Entry drive setup, conditional decision states, multi-step true-body drives, false-path fallthrough, compatible named-drive fan-in, delayed completion pulse behavior. | `t/1097`; `t/1104`; `t/1107`; `t/1206`; `t/1314-isf-when-fixture-coverage.t`. | Promoted as a bounded `when` fixture with schedule-report, strict-mode, and HDL coverage. |
| `isf/phase_test.isf` | Transaction phase pass-through fixture. | Transaction phase metadata/pass-through states, delayed completion pulse behavior. | `t/1179-isf-phase-stage-boundary.t`; `t/1312-isf-phase-fixture-coverage.t`. | Promoted as a bounded phase-metadata fixture with schedule-report, strict-mode, and HDL coverage. |
| `isf/atl_trigger_batch_pipeline.isf` | ATL temporary trigger-batch fixture. | Static actor instances, task-scoped same-cycle trigger batch, generated parent trigger handoff pulses. | `t/1324-isf-atl-fixture-coverage.t`. | Promoted as a bounded ATL orchestration fixture with schedule-report, strict-mode, and HDL coverage; it deliberately avoids permanent `(group ...)` membership. |

Current ISF regression tier:

- `./bin/ci-regression isf` selects all files matching
  `t/109[1-9]-isf*.t`, `t/11[0-9][0-9]-isf*.t`, and
  `t/12[0-9][0-9]-isf*.t`, and `t/13[0-9][0-9]-isf*.t`, sorted with
  unmatched future bands ignored by `nullglob`.
- Current count: `224` ISF-tier tests: `9` in the `109x` band, `98` in the
  `11xx` band, `98` in the `12xx` band, and `19` in the `13xx` band.
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
- `t/1309-isf-i2c-fixture-coverage.t` proves strict schedule JSON parity and
  strict HDL generation for the bounded I2C-like fixture.
- `t/1310-isf-burst-fixture-coverage.t` proves strict schedule JSON parity
  and strict HDL generation for the bounded burst-reader fixture.
- `t/1311-isf-uart-fixture-coverage.t` proves strict schedule JSON parity and
  strict HDL generation for the bounded UART-like transmit fixture.
- `t/1312-isf-phase-fixture-coverage.t` proves strict schedule JSON parity
  and strict HDL generation for the bounded phase fixture.
- `t/1313-isf-switch-fixture-coverage.t` proves strict schedule JSON parity
  and strict HDL generation for the bounded switch fixture.
- `t/1314-isf-when-fixture-coverage.t` proves strict schedule JSON parity and
  strict HDL generation for the bounded `when` fixture.
- `t/1315-isf-generated-composition-fixture-coverage.t` proves strict
  schedule JSON parity, strict `--outdir` file emission, and strict HDL
  generation for the generated top, parent, and child artifacts of the
  bounded generated-composition fixture.
- `t/1316-isf-rule-resource-fixture-coverage.t` proves strict schedule JSON
  parity and strict HDL generation for the bounded rule/resource arbitration
  fixture.
- `t/1317-isf-stage-contract-fixture-coverage.t` proves strict schedule JSON
  parity and strict HDL generation for the bounded stage/contract fixture.
- `t/1319-isf-fifo-datapath-fixture-coverage.t` proves strict schedule JSON
  parity and strict HDL generation for the bounded FIFO datapath bank-access
  fixture.
- `t/1320-isf-fifo-controller-fixture-coverage.t` proves strict schedule JSON
  parity and strict HDL generation for the bounded FIFO controller fixture.
- `t/1321-isf-fifo-library-fixture-coverage.t` proves strict schedule JSON
  parity, strict `--outdir` file emission, and plain plus strict generated-top
  HDL generation for the bounded fixed FIFO reusable-library fixture.
- `t/1324-isf-atl-fixture-coverage.t` proves strict schedule JSON parity and
  plain plus strict HDL generation for the bounded ATL temporary
  trigger-batch fixture.

Remaining inventory gaps after `ISF-FIXTURES.5`:

- I2C, burst-reader, UART, phase, switch, when, generated composition,
  rule/resource arbitration, stage/contract, FIFO datapath, FIFO controller,
  FIFO library, and ATL temporary trigger-batch fixtures have
  post-closure file-backed schedule JSON, strict-mode, and generated HDL
  assertions.
- Quick/smoke currently exercises only APB for ISF; that is intentional for
  turnaround. The SPI-like, I2C-like, burst-reader, UART-like, phase, switch,
  when, generated-composition, rule/resource, stage/contract, FIFO datapath,
  FIFO controller, FIFO library, and ATL temporary trigger-batch fixtures stay
  in `isf`, not `quick`.
- Strict-mode accepted-source fixture coverage is APB plus the bounded
  SPI-like, I2C-like, burst-reader, UART-like, phase, switch, when,
  generated-composition, rule/resource, stage/contract, FIFO datapath, FIFO
  controller, FIFO library, and ATL temporary trigger-batch fixtures.
- No known fixture matrix candidate remains unpromoted. Future fixture work
  should open a new task tree when a shipped interaction needs a protocol-like
  owner.

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
| `isf/i2c_master.isf` | Second serial-protocol promotion target. | Parameterized drives, nested repeat, switch branches, shift-left, branch-specific serial behavior. | Transaction states, repeat counters, switch branch state coverage, storage width/role where known. | Generated HDL reachability and strict-mode acceptance after SPI proves the pattern. | `isf`; no quick promotion planned. | Promoted by [ISF-I2C-FIXTURE-PROMOTION](ISF-I2C-FIXTURE-PROMOTION.md) with bounded schedule/strict/HDL coverage. |
| `isf/burst_reader.isf` | Burst/wait-loop realism target. | Dynamic repeat count, sampled aliases, await, watchdog, latency, completion pulse. | Repeat/latency/watchdog storage roles, transaction state count/order, completion pulse storage. | Generated HDL reachability; strict mode only after the fixture is checked as forward-contract clean. | `isf`. | Promoted by [ISF-BURST-FIXTURE-PROMOTION](ISF-BURST-FIXTURE-PROMOTION.md) with bounded schedule/strict/HDL coverage. |
| `isf/uart_tx.isf` | Data-width and shift-right realism target. | Parameterized drives, repeat, explicit-width `shift_right`, serial transmit framing. | Data register width evidence, transaction states, repeat counter storage. | Generated HDL reachability; strict mode if the fixture is promoted as a forward-contract example. | `isf`. | Promoted by [ISF-UART-FIXTURE-PROMOTION](ISF-UART-FIXTURE-PROMOTION.md) with bounded schedule/strict/HDL coverage. |
| `isf/spawn_parent.isf` | Composition realism baseline. | Spawned child module, generated top, start/done handoff, named-drive handoff, parameter overrides, outdir lowering. | `generated_composition` summary, child/instance/link/binding keys, parent-only report scope, strict schedule JSON CLI parity. | Multi-file lower result, generated top reachability, strict `--outdir` behavior, strict generated top/parent/child HDL generation. | `isf`; not quick. | Promoted by [ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION](ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.md) with bounded strict/outdir/HDL coverage. |
| `isf/full_featured.isf` | Parser/public-shell breadth fixture, not a realism signoff fixture. | Rules, triggers, priorities, resources, `do`, `spawn`, named drives, ordering metadata. | Actor-shell metadata and parser-carried resource/priority/stage/phase surfaces. | No strict/HDL promotion requirement because the source intentionally exercises breadth, not protocol realism. | `isf` parser/public contract tests. | Keep for parser breadth; do not use as proof of protocol behavior. |
| `isf/rule_resource_arbiter.isf` | Rule/resource realism fixture. | Rule-over-transaction priority, multiple rules sharing a `rule_slot`, priority arbitration, lower-priority rule gating, delayed completion pulse behavior. | `priority_resolutions`, `resource_arbitration`, rule DT blocks, transaction state order, schedule JSON CLI parity. | File-backed scheduled `.fsm` structure, generated HDL reachability, strict-mode accepted-source path. | `isf`; not quick. | Promoted by [ISF-RULE-RESOURCE-FIXTURE-PROMOTION](ISF-RULE-RESOURCE-FIXTURE-PROMOTION.md) with bounded schedule/strict/HDL coverage. |
| `isf/stream_stage_contract.isf` | Stage/contract realism fixture. | Sampled payload forwarding, ready/valid transaction stage, bounded eventual contract monitor, reset policy, generated monitor storage, SystemVerilog assertion projection. | `transaction_stages`, `temporal_contracts`, monitor storage kind/role/width, strict schedule JSON CLI parity. | File-backed scheduled `.fsm` structure, generated HDL reachability, strict-mode accepted-source path. | `isf`; not quick. | Promoted by [ISF-STAGE-CONTRACT-FIXTURE-PROMOTION](ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.md) with bounded schedule/strict/HDL coverage. |
| `isf/fifo_controller.isf` | FIFO controller matrix fixture. | Depth-4 occupancy/full/empty update matrix, accepted push/pop pointer wrap, simultaneous push+pop controller behavior, no data-bank storage. | Actor-storage entries for pointers and occupancy, compatible fan-in groups, rule DT assignment counts, strict schedule JSON CLI parity. | File-backed scheduled `.fsm` structure, generated HDL reachability, strict-mode accepted-source path. | `isf`; not quick. | Promoted by [ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION](ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.md) with bounded schedule/strict/HDL coverage. |
| `isf/fifo_data_path.isf` | FIFO datapath bank-access fixture. | Actor-owned depth-4 bank store/load, pointer-selected accepted push/pop, scalarized storage entries, read-before-write same-cycle policy. | `bank_accesses`, actor-storage entries for `data_0` through `data_3`, rule DT assignment counts, strict schedule JSON CLI parity. | File-backed scheduled `.fsm` structure, generated HDL reachability, strict-mode accepted-source path. | `isf`; not quick. | Promoted by [ISF-FIFO-DATAPATH-FIXTURE-PROMOTION](ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.md) with bounded schedule/strict/HDL coverage. |
| `isf/fifo_library_use.isf` | Fixed FIFO reusable-library fixture. | Import/use binding for `common.fifo.fifo`, generated top wiring, fixed FIFO parameter overrides, scalarized child data entries, combined controller/datapath behavior. | `library_uses`, fixed parameter provenance, clock/reset/input/output bindings, strict schedule JSON CLI parity. | Importing actor, specialized child, and generated top scheduled `.fsm` artifacts; strict `--outdir`; plain and strict generated-top HDL reachability. | `isf`; not quick. | Promoted by [ISF-FIFO-LIBRARY-FIXTURE-PROMOTION](ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.md) with bounded schedule/strict/outdir/HDL coverage. |
| `isf/atl_trigger_batch_pipeline.isf` | ATL temporary trigger-batch fixture. | Static actor instances, task-scoped trigger association, same-cycle generated trigger pulses. | `actor_network.instances[]`, per-target `transaction_triggers[]`, canonical synthetic `run_trigger_batch` evidence in `association_schedules[]`, compatibility evidence in `group_schedules[]`, strict schedule JSON CLI parity. | File-backed scheduled `.fsm` structure, one trigger-batch state, generated HDL reachability, strict-mode accepted-source path. | `isf`; not quick. | Promoted by `ISF-ACTOR-NETWORK-ORCHESTRATION.8.2` and widened by `ISF-ACTOR-NETWORK-ORCHESTRATION.9.2` with bounded schedule/strict/HDL coverage. |
| `isf/atl_data_route_pipeline.isf` | ATL scalar data-route fixture. | Static actor instances, named drive-body actor-to-actor scalar movement, drive-call-cycle route lifetime. | `actor_network.instances[]`, one `data_movements[]` route with `route_lifetime` `drive_call_cycle` and `storage` `none`, empty `association_schedules[]` and `group_schedules[]`, strict schedule JSON CLI parity. | File-backed scheduled `.fsm` structure, generated parent source/sink handoff ports, generated HDL reachability, strict-mode accepted-source path. | `isf`; not quick. | Promoted by `ISF-ACTOR-NETWORK-ORCHESTRATION.9.4` with bounded schedule/strict/HDL coverage. |
| `isf/atl_pin_ingress_pipeline.isf` | ATL scalar pin-ingress fixture. | Static actor instance, top-level input pin source, named drive-body pin-to-actor scalar movement, drive-call-cycle route lifetime. | `actor_network.instances[]`, one `data_movements[]` route with kind `scalar_pin_to_actor_handoff`, source `top_level_pin`, sink `external_handoff`, empty `association_schedules[]` and `group_schedules[]`, strict schedule JSON CLI parity. | File-backed scheduled `.fsm` structure, existing top-level source pin, generated actor handoff output, generated HDL reachability, strict-mode accepted-source path. | `isf`; not quick. | Promoted by `ISF-ACTOR-NETWORK-ORCHESTRATION.9.6` with bounded schedule/strict/HDL coverage. |
| `isf/atl_pin_egress_pipeline.isf` | ATL scalar pin-egress fixture. | Static actor instance, generated actor source handoff, top-level output pin sink, named drive-body actor-to-pin scalar movement, drive-call-cycle route lifetime. | `actor_network.instances[]`, one `data_movements[]` route with kind `scalar_actor_to_pin_handoff`, source `external_handoff`, sink `top_level_pin`, empty `association_schedules[]` and `group_schedules[]`, strict schedule JSON CLI parity. | File-backed scheduled `.fsm` structure, generated actor source handoff input, existing top-level output sink, generated HDL reachability, strict-mode accepted-source path. | `isf`; not quick. | Promoted by `ISF-ACTOR-NETWORK-ORCHESTRATION.9.8` with bounded schedule/strict/HDL coverage. |
| `isf/atl_trigger_wait_pipeline.isf` | ATL trigger-wait orchestration fixture. | Static actor instance, one parent trigger handoff pulse, one parent event wait handoff, completion after the event wait. | `actor_network.instances[]`, one `transaction_triggers[]` entry, one `event_waits[]` entry, empty `association_schedules[]`, `group_schedules[]`, `groups[]`, and `data_movements[]`, strict schedule JSON CLI parity. | File-backed scheduled `.fsm` structure, generated trigger/event handoff ports, default await timeout state, generated HDL reachability, strict-mode accepted-source path. | `isf`; not quick. | Promoted by `ISF-ACTOR-NETWORK-ORCHESTRATION.9.10` with bounded schedule/strict/HDL coverage. |
| `isf/atl_trigger_batch_wait_pipeline.isf` | ATL trigger-batch wait orchestration fixture. | Static actor instances, one same-cycle temporary trigger batch, one parent event wait handoff, completion after the event wait. | `actor_network.instances[]`, per-target `transaction_triggers[]`, one `association_schedules[]` temporary-trigger-batch entry, one `group_schedules[]` compatibility entry, one `event_waits[]` entry, empty `groups[]` and `data_movements[]`, strict schedule JSON CLI parity. | File-backed scheduled `.fsm` structure, generated trigger/event handoff ports, default await timeout state, generated HDL reachability, strict-mode accepted-source path. | `isf`; not quick. | Promoted by `ISF-ACTOR-NETWORK-ORCHESTRATION.9.12` with bounded schedule/strict/HDL coverage. |
| `isf/atl_resolved_child_pin_ingress_pipeline.isf` | ATL resolved-child generated-top pin-ingress fixture. | One resolved library-qualified child instance, one top-level input pin, one named drive-body `(worker.payload pins.payload)` route, one trigger handoff, one event wait, matching parent/child clock and reset policy. | `actor_network.instances[]` resolved child metadata, one `transaction_triggers[]` entry, one `event_waits[]` entry, one `data_movements[]` route with kind `scalar_pin_to_actor_handoff`, one `generated_tops[]` entry, strict schedule JSON CLI parity. | Parent, child, and top `.fsm` artifacts; generated child `+interface` input role metadata for `payload`; generated top wires top `payload` to the parent, parent `worker_payload` to child `payload`, trigger/event links, and plain plus strict HDL generation. | `isf`; not quick. | Promoted by `ISF-ACTOR-NETWORK-ORCHESTRATION.9.30` with bounded schedule/strict/HDL coverage. |
| `isf/phase_test.isf` | Phase metadata/pass-through fixture. | Transaction phase pass-through states, delayed completion pulse behavior, no reusable `done` drive storage. | Transaction state order, completion-pulse storage, rdata drive storage, schedule JSON CLI parity. | File-backed scheduled `.fsm` structure, generated HDL reachability, strict-mode accepted-source path. | `isf`; not quick. | Promoted by [ISF-PHASE-FIXTURE-PROMOTION](ISF-PHASE-FIXTURE-PROMOTION.md) with bounded schedule/strict/HDL coverage. |
| `isf/switch_test.isf` | Switch dispatch fixture. | Sampled selector capture, explicit branch dispatch, default fallthrough, named-drive branch starts, delayed completion pulse behavior. | Transaction state order, sampled selector storage, named-drive DT blocks, schedule JSON CLI parity. | File-backed scheduled `.fsm` structure, generated HDL reachability, strict-mode accepted-source path. | `isf`; not quick. | Promoted by [ISF-SWITCH-FIXTURE-PROMOTION](ISF-SWITCH-FIXTURE-PROMOTION.md) with bounded schedule/strict/HDL coverage. |
| `isf/when_test.isf` | Conditional body fixture. | Entry drive setup, two conditional decision states, multi-step true-body drives, false-path fallthrough, compatible named-drive start fan-in, delayed completion pulse behavior. | Transaction state order, compatible fan-in group for `result_start`, result drive DT block, schedule JSON CLI parity. | File-backed scheduled `.fsm` structure, generated HDL reachability, strict-mode accepted-source path. | `isf`; not quick. | Promoted by [ISF-WHEN-FIXTURE-PROMOTION](ISF-WHEN-FIXTURE-PROMOTION.md) with bounded schedule/strict/HDL coverage. |

Closure state:

- `ISF-FIXTURES.5` closes this tree. The shipped realistic fixture surface is
  now APB as the quick/smoke baseline plus the SPI-like, I2C-like,
  burst-reader, UART-like, phase, switch, when, generated-composition,
  rule/resource, and stage/contract fixtures in the broader `isf` tier.
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

## Post-Closure I2C-Like Fixture Promotion

`ISF-I2C-FIXTURE-PROMOTION.1` promotes `isf/i2c_master.isf` after this matrix
tree closed. The fixture now has its own file-backed regression,
`t/1309-isf-i2c-fixture-coverage.t`, covering scheduled `.fsm` structure,
strict schedule JSON parity, plain HDL generation, strict HDL generation,
switch-branch repeats, read-data shifting, sampled write-data bit selection
from `data[7]`, and absence of an implicit `data_bit` input. It remains in the
`isf` regression tier, not `quick`, and is still a bounded I2C-like fixture
rather than a complete I2C protocol compliance suite.

## Post-Closure Burst-Reader Fixture Promotion

`ISF-BURST-FIXTURE-PROMOTION.1` promotes `isf/burst_reader.isf` after this
matrix tree closed. The fixture now has its own file-backed regression,
`t/1310-isf-burst-fixture-coverage.t`, covering scheduled `.fsm` structure,
strict schedule JSON parity, plain HDL generation, strict HDL generation,
dynamic repeat counter storage, watchdog and latency counter roles, sampled
aliases, and completion/timeout pulse fan-in. It remains in the `isf`
regression tier, not `quick`.

## Post-Closure UART-Like Fixture Promotion

`ISF-UART-FIXTURE-PROMOTION.1` promotes `isf/uart_tx.isf` after this matrix
tree closed. The fixture now drives the serial `tx` output from `byte_data[0]`
instead of the full sampled byte, so strict HDL generation no longer fails on
implicit truncation. The file-backed regression
`t/1311-isf-uart-fixture-coverage.t` covers scheduled `.fsm` structure, strict
schedule JSON parity, plain HDL generation, strict HDL generation,
known-width `shift_right`, repeat counter storage, busy drive sequencing, and
completion pulse behavior. It remains in the `isf` regression tier, not
`quick`, and is a bounded UART-like transmit fixture rather than a complete
UART protocol compliance suite.

## Post-Closure Phase Fixture Promotion

`ISF-PHASE-FIXTURE-PROMOTION.1` promotes `isf/phase_test.isf` after this
matrix tree closed. The fixture no longer defines a reusable `done` drive, so
`done` is owned only by the delayed completion pulse from `complete done`. The
file-backed regression `t/1312-isf-phase-fixture-coverage.t` covers scheduled
`.fsm` structure, strict schedule JSON parity, plain HDL generation, strict
HDL generation, transaction phase pass-through states, no reusable `done`
drive storage, and delayed completion pulse behavior. It remains in the `isf`
regression tier, not `quick`, and remains phase-metadata coverage rather than
executable actor-level phase scheduling.

## Post-Closure Switch Fixture Promotion

`ISF-SWITCH-FIXTURE-PROMOTION.1` promotes `isf/switch_test.isf` after this
matrix tree closed. The file-backed regression
`t/1313-isf-switch-fixture-coverage.t` covers scheduled `.fsm` structure,
strict schedule JSON parity, plain HDL generation, strict HDL generation,
sampled selector capture, explicit branch dispatch, default fallthrough to
completion, named-drive branch starts, and delayed completion pulse behavior.
It remains in the `isf` regression tier, not `quick`, and does not claim the
deferred nested child/await-sync switch branch body surface.

## Post-Closure When Fixture Promotion

`ISF-WHEN-FIXTURE-PROMOTION.1` promotes `isf/when_test.isf` after this matrix
tree closed. The file-backed regression `t/1314-isf-when-fixture-coverage.t`
covers scheduled `.fsm` structure, strict schedule JSON parity, plain HDL
generation, strict HDL generation, entry drive setup, two conditional decision
states, multi-step true-body drives, false-path fallthrough, compatible
named-drive start fan-in, and delayed completion pulse behavior. It remains in
the `isf` regression tier, not `quick`, and does not claim the deferred nested
child/await-sync `when` body surface.

## Post-Closure Generated-Composition Fixture Promotion

`ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.1` promotes
`isf/spawn_parent.isf` after this matrix tree closed. The file-backed
regression `t/1315-isf-generated-composition-fixture-coverage.t` covers
scheduled top/parent/child `.fsm` structure, strict schedule JSON parity,
strict `--outdir` file emission, generated top HDL wiring, parent HDL
start/await/data handoff behavior, and child HDL drive request/payload
handoffs. It remains in the `isf` regression tier, not `quick`, and remains a
bounded generated-child composition fixture rather than a protocol compliance
claim.

## Post-Closure Rule/Resource Fixture Promotion

`ISF-RULE-RESOURCE-FIXTURE-PROMOTION.1` adds and promotes
`isf/rule_resource_arbiter.isf` after this matrix tree closed. The file-backed
regression `t/1316-isf-rule-resource-fixture-coverage.t` covers scheduled
`.fsm` structure, strict schedule JSON parity, plain and strict HDL
generation, rule-over-transaction priority suppression, `rule_slot`/`priority`
resource metadata, lower-priority rule gating by a higher-priority rule, and
delayed completion pulse behavior. It remains in the `isf` regression tier,
not `quick`, and does not claim deferred resource kinds or arbiter families.

## Post-Closure Stage/Contract Fixture Promotion

`ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.1` adds and promotes
`isf/stream_stage_contract.isf` after this matrix tree closed. The
file-backed regression `t/1317-isf-stage-contract-fixture-coverage.t` covers
scheduled `.fsm` structure, strict schedule JSON parity, plain and strict HDL
generation, sampled payload forwarding, ready/valid barrier metadata, bounded
eventual contract metadata, temporal monitor storage roles, SystemVerilog
sticky-fail assertion projection, and delayed completion pulse behavior. It
remains in the `isf` regression tier, not `quick`, and does not claim nested
stages, nested contracts, stage-local compute, expression contracts, or
broader temporal operators.

## Post-Closure FIFO Datapath Fixture Promotion

`ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.1` promotes
`isf/fifo_data_path.isf` after this matrix tree closed. The file-backed
regression `t/1319-isf-fifo-datapath-fixture-coverage.t` covers scheduled
`.fsm` structure, strict schedule JSON parity, plain and strict HDL
generation, bounded `bank_accesses[]` metadata, scalarized `data_0` through
`data_3` bank storage, pointer-guarded accepted pushes, and pointer-guarded
accepted pops. It remains in the `isf` regression tier, not `quick`, and does
not claim general memory-array HDL emission, write-first collision behavior,
bypassing, or arbitrary-depth parameterized FIFOs.

## Post-Closure FIFO Controller Fixture Promotion

`ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.1` promotes
`isf/fifo_controller.isf` after this matrix tree closed. The file-backed
regression `t/1320-isf-fifo-controller-fixture-coverage.t` covers scheduled
`.fsm` structure, strict schedule JSON parity, plain and strict HDL
generation, compatible same-value fan-in metadata, idle cycles, push-only,
pop-only, simultaneous push+pop occupancy updates, actor-maintained full/empty
flags, and 2-bit pointer wrap.
It remains in the `isf` regression tier, not `quick`, and remains
controller-only: data-bank storage and `data_out` datapath transfer behavior
are owned by the datapath and reusable FIFO fixtures.

## Post-Closure FIFO Library Fixture Promotion

`ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.1` promotes
`isf/fifo_library_use.isf` after this matrix tree closed. The file-backed
regression `t/1321-isf-fifo-library-fixture-coverage.t` covers strict
schedule JSON parity, importer/child/generated-top scheduled `.fsm`
artifacts, strict `--outdir` file emission, fixed parameter overrides,
clock/reset/input/output binding provenance, scalarized FIFO data entries,
generated top wiring, and plain plus strict generated-top HDL generation.
It remains in the `isf` regression tier, not `quick`, and remains a fixed
`DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, `OCC_WIDTH=3` reusable-library
handoff rather than a claim for parameter-driven interface/storage
elaboration, nested imports, standalone transaction/drive exports,
arbitrary-depth generated FIFOs, memory-array backend emission, or automatic
non-zero reset values.

## Post-Closure ATL Temporary Trigger-Batch Fixture Promotion

`ISF-ACTOR-NETWORK-ORCHESTRATION.8.2` promotes
`isf/atl_trigger_batch_pipeline.isf` after this matrix tree closed. The
file-backed regression `t/1324-isf-atl-fixture-coverage.t` covers strict
schedule JSON parity, scheduled `.fsm` structure, one same-cycle
trigger-batch state, generated `reader_capture_start`,
`filter_process_start`, and `writer_emit_start` handoff pulses, static
actor-network report metadata, and plain plus strict HDL generation. It
remains in the `isf` regression tier, not `quick`, and remains a bounded
temporary association fixture: it deliberately avoids a permanent
`(group ...)` declaration and does not claim peer events, endpoint data
movement, generated ATL children, generated ATL tops, group endpoints, route
mux/storage, CDC, payloads, ready/backpressure, or trigger/data/event
coupling.

## Post-Closure ATL Scalar Data-Route Fixture Promotion

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.4` promotes
`isf/atl_data_route_pipeline.isf` after this matrix tree closed. The
file-backed regression `t/1325-isf-atl-data-route-fixture-coverage.t` covers
strict schedule JSON parity, scheduled `.fsm` structure, generated
`producer_payload` and `consumer_payload` parent handoff ports, the
`feed_consumer` drive request, one `actor_network.data_movements[]` entry,
empty association/group schedule arrays, and plain plus strict HDL generation.
It remains in the `isf` regression tier, not `quick`, and remains a bounded
scalar actor-to-actor handoff fixture: it does not claim generated ATL
children, generated ATL tops, route mux/storage, trigger/data coupling, wider
payloads, fan-in/fan-out, CDC, ready/backpressure, compact aliases, or
permanent actor grouping.

## Post-Closure ATL Scalar Pin-Ingress Fixture Promotion

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.6` promotes
`isf/atl_pin_ingress_pipeline.isf` after this matrix tree closed. The
file-backed regression `t/1326-isf-atl-pin-ingress-fixture-coverage.t` covers
strict schedule JSON parity, scheduled `.fsm` structure, existing top-level
source input `payload`, generated actor handoff output `consumer_payload`, the
`feed_consumer` drive request, one `actor_network.data_movements[]` entry,
empty association/group schedule arrays, and plain plus strict HDL generation.
It remains in the `isf` regression tier, not `quick`, and remains a bounded
scalar top-level input-pin to actor fixture: it does not claim generated ATL
children, generated ATL tops, actor-to-pin egress, bidirectional pin movement,
route mux/storage, trigger/data coupling, wider payloads, fan-in/fan-out, CDC,
ready/backpressure, compact aliases, or permanent actor grouping.

## Post-Closure ATL Scalar Pin-Egress Fixture Promotion

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.8` promotes
`isf/atl_pin_egress_pipeline.isf` after this matrix tree closed. The
file-backed regression `t/1327-isf-atl-pin-egress-fixture-coverage.t` covers
strict schedule JSON parity, scheduled `.fsm` structure, generated actor source
handoff input `producer_payload`, existing top-level output sink `result`, the
`publish_result` drive request, one `actor_network.data_movements[]` entry,
empty association/group schedule arrays, and plain plus strict HDL generation.
It remains in the `isf` regression tier, not `quick`, and remains a bounded
scalar actor-to-top-level output pin fixture: it does not claim generated ATL
children, generated ATL tops, bidirectional pin movement, route mux/storage,
trigger/data coupling, wider payloads, fan-in/fan-out, CDC, ready/backpressure,
compact aliases, or permanent actor grouping.

## Post-Closure ATL Trigger-Wait Fixture Promotion

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.10` promotes
`isf/atl_trigger_wait_pipeline.isf` after this matrix tree closed. The
file-backed regression `t/1328-isf-atl-trigger-wait-fixture-coverage.t`
covers strict schedule JSON parity, scheduled `.fsm` structure, generated
parent trigger output `worker_process_start`, generated parent event input
`worker_done`, one `actor_network.transaction_triggers[]` entry, one
`actor_network.event_waits[]` entry, empty association/group/data-movement
arrays, the default await timeout state, and plain plus strict HDL generation.
It remains in the `isf` regression tier, not `quick`, and remains a bounded
single-actor parent-handoff orchestration fixture: it does not claim generated
ATL children, generated ATL tops, actor type resolution, HDL child wiring,
temporary trigger-batch plus event coupling, data movement coupling,
fan-in/fan-out, CDC, ready/backpressure, compact aliases, or permanent actor
grouping.

## Post-Closure ATL Trigger-Batch Wait Fixture Promotion

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.12` promotes
`isf/atl_trigger_batch_wait_pipeline.isf` after this matrix tree closed. The
file-backed regression
`t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t` covers strict schedule
JSON parity, scheduled `.fsm` structure, generated reader/filter/writer
trigger outputs, generated event input `writer_done`,
`actor_network.association_schedules[]` temporary-association evidence,
`actor_network.group_schedules[]` compatibility evidence, one
`actor_network.event_waits[]` entry, empty data movement, the default await
timeout state, and plain plus strict HDL generation. It remains in the `isf`
regression tier, not `quick`, and remains a bounded parent-handoff
orchestration fixture: it does not claim generated ATL children, generated ATL
tops, actor type resolution, HDL child wiring, multi-event fan-in, data
movement coupling, CDC, ready/backpressure, compact aliases, or permanent
actor grouping.

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
- Spawned-child composition has generated-top, multi-file handoff,
  strict-outdir, strict schedule JSON, and generated top/parent/child HDL
  coverage, but it is not treated as a realistic protocol fixture.
- Rule/resource arbitration has bounded file-backed strict schedule/HDL
  coverage for `rule_slot` plus `priority` arbitration, but deferred resource
  kinds and arbiters remain unclaimed.
- `full_featured.isf` remains parser/public-shell breadth coverage, not
  protocol signoff coverage.

The following interactions remain unclaimed by a realistic fixture:

- Stage/contract protocol-like realism fixtures.
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
- `2026-05-16`: Recorded post-closure generated-composition fixture promotion
  through strict schedule JSON, strict `--outdir`, and generated
  top/parent/child HDL coverage.
- `2026-05-16`: Recorded post-closure rule/resource fixture promotion through
  strict schedule JSON, scheduled `.fsm`, and plain/strict HDL coverage for
  the shipped `rule_slot`/`priority` subset.
- `2026-05-16`: Recorded post-closure stage/contract fixture promotion
  through strict schedule JSON, scheduled `.fsm`, and plain/strict HDL
  coverage for the shipped top-level ready/valid stage plus bounded eventual
  contract subset.
- `2026-05-16`: Recorded post-closure FIFO datapath fixture promotion through
  strict schedule JSON, scheduled `.fsm`, and plain/strict HDL coverage for
  the shipped scalarized bank store/load subset.
- `2026-05-16`: Recorded post-closure FIFO controller fixture promotion
  through strict schedule JSON, scheduled `.fsm`, and plain/strict HDL
  coverage for the shipped depth-4 controller matrix subset.
- `2026-05-16`: Recorded post-closure FIFO library fixture promotion through
  strict schedule JSON, strict `--outdir`, generated importer/child/top
  scheduled `.fsm`, and plain/strict generated-top HDL coverage for the
  shipped fixed reusable FIFO subset.
- `2026-05-19`: Recorded post-closure ATL temporary trigger-batch fixture
  promotion through strict schedule JSON, scheduled `.fsm`, and plain/strict
  HDL coverage for task-scoped actor trigger associations without permanent
  `(group ...)` membership.
- `2026-05-19`: Recorded post-closure ATL scalar data-route fixture promotion
  through strict schedule JSON, scheduled `.fsm`, generated parent handoff
  ports, data-movement report metadata, and plain/strict HDL coverage.
- `2026-05-19`: Recorded post-closure ATL scalar pin-ingress fixture
  promotion through strict schedule JSON, scheduled `.fsm`, existing
  top-level source pin, generated actor handoff output, data-movement report
  metadata, and plain/strict HDL coverage.
- `2026-05-19`: Recorded post-closure ATL scalar pin-egress fixture
  promotion through strict schedule JSON, scheduled `.fsm`, generated actor
  source handoff input, existing top-level output sink, data-movement report
  metadata, and plain/strict HDL coverage.
