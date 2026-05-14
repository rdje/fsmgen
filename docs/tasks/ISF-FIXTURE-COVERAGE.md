# ISF-FIXTURES: Realistic Fixture And Strict-Mode Coverage

## Metadata

- Tree ID: `ISF-FIXTURES`
- Status: `active`
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
  Status: `active`
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
  Status: `pending`
  Goal: `Define realistic fixture coverage matrix.`
  Acceptance: `The tree maps target fixtures to feature families, report
  assertions, generated HDL paths, and regression tier placement.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-FIXTURES.3`
  Status: `pending`
  Goal: `Add the next realistic fixture slice.`
  Acceptance: `One selected fixture exercises a documented feature
  interaction through scheduled `.fsm`, schedule JSON, strict mode where
  relevant, and HDL generation.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-FIXTURES.4`
  Status: `pending`
  Goal: `Broaden regression-tier and support-accounting coverage where warranted.`
  Acceptance: `The selected fixture coverage is placed in the appropriate
  quick/isf/full tier without making fast turnaround noisy.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-FIXTURES.5`
  Status: `pending`
  Goal: `Synchronize fixture documentation and close covered gaps.`
  Acceptance: `Docs and live status describe what realistic ISF behavior is
  fixture-backed and which feature interactions remain unclaimed.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-FIXTURES.2` | `pending` | Existing fixture and regression-tier coverage is inventoried; the next step is the realistic fixture coverage matrix. |

## ISF-FIXTURES.1 Inventory

Current checked-in ISF fixtures:

| Fixture | Current purpose | Covered feature families | Current direct coverage | Gaps / notes |
| --- | --- | --- | --- | --- |
| `isf/apb_requester.isf` | Primary realistic APB request/response actor. | Interface widths, async active-low reset, watchdog, named/parameterized drives, samples, await, complete pulse, latency, schedule report storage metadata, strict HDL generation. | `t/1091`, `t/1094`, `t/1096`, `t/1100`, `t/1105`, `t/1106`, `t/1112`, `t/1116`, `t/1121`, `t/1123`, `t/1124`, `t/1146`-`t/1155`, and several public contract audits. | Strong baseline fixture; not enough by itself for repeat/control-flow/composition realism. |
| `isf/burst_reader.isf` | Burst read transaction with repeated await loop. | Dynamic repeat count, sampled aliases, await, watchdog, latency, completion pulse. | `t/1095-isf-scheduler-burst-reader.t`. | Schedule-report and HDL assertions are narrow. |
| `isf/full_featured.isf` | Broad parser/public-shell fixture. | Rules, triggers, priorities, resources, `do`, `spawn`, named drives, transaction ordering. | `t/1093`, `t/1157`, `t/1158`, `t/1166`, `t/1176`. | Good metadata/parser breadth; not a realistic protocol. |
| `isf/i2c_master.isf` | I2C-like serial transaction. | Parameterized drives, repeats, switch, shift-left, nested repeat in switch branches. | `t/1099-isf-repeat-data-ops.t`. | Needs schedule-report/HDL/strict fixture assertions before it can be a realistic signoff fixture. |
| `isf/spi_master.isf` | SPI mode-0 style serial transfer. | Parameterized drives, repeat, shift-left, sampled transmit byte. | No dedicated file-backed ISF regression found in the current inventory. | Candidate for next realistic fixture slice. |
| `isf/uart_tx.isf` | UART transmit byte flow. | Parameterized drives, repeat, shift-right. | `t/1099-isf-repeat-data-ops.t`. | Needs explicit-width `shift_right` fixture refresh or strict/HDL coverage if promoted. |
| `isf/spawn_parent.isf` | Parent/child generated-composition fixture. | Spawned child module, generated top, start/done handoff, named-drive handoff, outdir lowering. | `t/1097`, `t/1117`, `t/1122`, `t/1128`, `t/1153`, `t/1156`, `t/1216`, `t/1217`. | Strong composition fixture; realistic protocol semantics are intentionally small. |
| `isf/switch_test.isf` | Simple switch dispatch fixture. | `switch` branch lowering and implicit fallthrough smoke. | `t/1097`; richer switch behavior is covered by inline sources in `t/1103` and `t/1205`. | File-backed schedule/HDL assertions are minimal. |
| `isf/when_test.isf` | Simple conditional body fixture. | `when` body lowering and repeated `when` smoke. | `t/1097`; richer `when` behavior is covered by inline sources in `t/1104`, `t/1107`, and `t/1206`. | File-backed schedule/HDL assertions are minimal. |
| `isf/phase_test.isf` | Transaction phase pass-through fixture. | Transaction phase metadata/pass-through state. | No dedicated file-backed regression found; phase behavior is covered by inline sources in `t/1179`. | Candidate for either removal from "representative" docs or direct coverage if kept. |

Current ISF regression tier:

- `./bin/ci-regression isf` selects all files matching
  `t/109[1-9]-isf*.t`, `t/11[0-9][0-9]-isf*.t`, and
  `t/12[0-9][0-9]-isf*.t`, sorted with unmatched future bands ignored by
  `nullglob`.
- Current count: `135` ISF-tier tests: `9` in the `109x` band, `98` in the
  `11xx` band, and `28` in the `12xx` band.
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
- No current strict-mode fixture regression targets I2C, SPI, UART, burst,
  switch/when, phase, or generated-composition sources.

Inventory gaps to feed `ISF-FIXTURES.2`:

- SPI has no dedicated file-backed ISF regression despite being a realistic
  protocol-style fixture.
- I2C and UART are covered through repeat/data-op lowering but not through
  schedule JSON, strict mode, or generated HDL assertions.
- `phase_test.isf` is listed as a fixture but lacks direct file-backed
  coverage; inline tests cover the semantics.
- Quick/smoke currently exercises only APB for ISF; that is intentional for
  turnaround, but the matrix should decide whether one additional compact
  fixture belongs there.
- Strict-mode accepted-source coverage is APB-only.
- No fixture matrix currently records which realistic protocols own coverage
  for storage roles, conflict/fan-in reports, rule/resource arbitration, or
  stage/contract features.

## Decisions

- `2026-05-14`: Fixture expansion is tracked separately so feature trees can
  stay focused while this tree owns cross-feature realism and regression-tier
  placement.

## Open Questions

- Which protocol fixture should be next after the existing APB/I2C coverage?
- Which fixtures belong in the quick `isf` tier versus broader gates?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-FIXTURES` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-FIXTURES` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |

## Changelog

- `2026-05-14`: Created the active ISF fixture-coverage task tree.
