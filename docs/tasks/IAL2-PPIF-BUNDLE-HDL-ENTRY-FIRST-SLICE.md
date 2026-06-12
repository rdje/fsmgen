# IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE: Ship PPIF Bundle HDL Entry

## Metadata

- Tree ID: `IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Implement the first bounded HDL entry for multi-channel `.ppif` Valid-Ready
bundles by generating an aggregate wrapper/top review artifact and routing HDL
generation through the existing `.ppif -> .isf -> .fsm -> HDL` chain.

## Non-Goals

- Do not implement full AXI manager behavior, transaction IDs, ordering,
  outstanding windows, bursts, response matching, or cross-channel dependency
  enforcement.
- Do not add protocol-profile aliases such as `.axi`, `.pif`, or `.ppi`.
- Do not add non-Valid-Ready PPIF object kinds.
- Do not bypass generated IAL1 and IAL0 review artifacts with direct HDL
  emission.
- Do not broaden VHDL bundle support unless the existing SystemVerilog path
  proves that broader lane safely.

## Acceptance Criteria

- Multi-channel `.ppif` Valid-Ready bundles expose an aggregate wrapper/top
  IAL0 artifact named from the top-level `protocol-platform-intent`.
- The bundle report's `generated_artifacts.hdl_entry` selects the aggregate
  wrapper/top artifact and keeps per-channel artifacts listed.
- Default SystemVerilog HDL generation and `--verify-hdl` use the aggregate
  wrapper/top instead of failing closed for the tracked bundle sample.
- `--outdir` materializes per-channel generated `.isf`/`.fsm` files plus the
  aggregate wrapper/top `.fsm` review artifact.
- `--emit-schedule-json`, `--check --json`, and `--emit-semantic-json` remain
  stable non-HDL modes.
- The mdBook and live docs describe the shipped behavior and the remaining
  monitor-only boundary.
- Focused PPIF, capability/support-accounting, docs, Knowledge Map, memory,
  and diff gates pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE`
  Status: `done`
  Goal: `Ship the first aggregate HDL entry for PPIF Valid-Ready bundles.`
  Children: `IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE.1`

- ID: `IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE.1`
  Status: `done`
  Goal: `Generate and use a bounded aggregate wrapper/top for the existing PPIF Valid-Ready bundle sample.`
  Acceptance: `The tracked AW/W PPIF bundle produces aggregate wrapper/top review artifacts and SystemVerilog HDL through the normal composition pipeline, while non-HDL bundle modes stay stable.`
  Verification: `pass`
  Commit: `pending commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE.1` | `done` | The bounded wrapper/top implementation is complete; continue PNT from `docs/TASK_TREE.md` after commit. |

## Decisions

- `2026-06-12`: Implement only the existing Valid-Ready bundle shape using an
  aggregate `.fsm` composition top and embedded per-channel generated monitor
  roots. This keeps HDL generation on the existing composition pipeline and
  preserves reviewable IAL0 artifacts.

## Open Questions

- None for the first bounded implementation slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE.1` | `perl -c bin/fsmgen`; `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm`; `perl -Iperl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticProtocolIntentBundleContract.pm`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t t/1411-isf-assert-emit.t t/1412-isf-property-implication.t`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t`; `./bin/fsmgen --quiet -o /tmp/fsmgen-ppif-single-verify.sv --verify-hdl ppif/axi_aw_valid_ready.ppif`; `./bin/fsmgen --quiet --outdir /tmp/fsmgen-ppif-bundle-verify-actual/out -o /tmp/fsmgen-ppif-bundle-verify-actual/bundle.sv --verify-hdl ppif/axi_aw_w_valid_ready_bundle.ppif`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE.1` | `pending commit` | `pending commit` |

## Changelog

- `2026-06-12`: Created task tree and selected the bounded PPIF bundle HDL
  entry implementation leaf.
- `2026-06-12`: Implemented aggregate wrapper/top `.fsm` generation for the
  tracked AW/W PPIF bundle, routed default HDL and `--verify-hdl` through that
  entry, pruned sampled-value helper chains from combinational HDL assigns,
  and synchronized tests, mdBook, live docs, facts, and memory.
