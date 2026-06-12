# NORMALIZED-SEMANTIC-PROTOCOL-BUNDLE-CONTRACT-DRIFT: Protocol Bundle Contract Test Drift

## Metadata

- Tree ID: `NORMALIZED-SEMANTIC-PROTOCOL-BUNDLE-CONTRACT-DRIFT`
- Status: `done`
- Roadmap lane: `Embedding And Public APIs / IAL2`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Repair stale normalized semantic payload/report contract test expectations for
the already-shipped `semantic.protocol_intent_bundle` optional child so the
broader normalized semantic contract gate can run cleanly.

## Ground Truth

- `IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE.1` shipped
  `semantic.protocol_intent_bundle` and
  `FSM::Support::NormalizedSemanticProtocolIntentBundleContract`.
- `perl/FSM/Support/NormalizedSemanticPayloadContract.pm` already advertises
  `protocol_intent_bundle` in `optional_child_presence_keys`,
  `nested_contract_source_map`, `nested_presence_key_map`, and grouped
  presence-key families.
- `t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t`
  already proves the protocol-bundle key families defensively.
- While validating `R11-DIRECT-BACKEND-COORDINATION-FRONTIER.2`, the broader
  command
  `prove -Iperl t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/163-forward-structural-rtl-ir-surface.t`
  failed only because `t/330` and `t/311` still expected optional semantic
  child lists without `protocol_intent_bundle`.

## Non-Goals

- Do not change normalized semantic JSON runtime behavior.
- Do not change `.ppif` parsing, lowering, reports, or generated artifacts.
- Do not broaden the protocol-intent bundle contract beyond the already-shipped
  payload/report contract surface.

## Acceptance Criteria

- `t/330-normalized-semantic-payload-contract.t` expects
  `protocol_intent_bundle` in the optional child list and nested contract map.
- `t/311-normalized-semantic-report-contract.t` expects direct semantic JSON to
  omit optional `protocol_intent_bundle` when no bundle is present while still
  advertising it in the optional semantic child list.
- Focused normalized semantic contract gates pass.
- Memory and task-tree state are updated and the completed leaf is committed
  through `COMMIT.md`.

## Task Tree

- ID: `NORMALIZED-SEMANTIC-PROTOCOL-BUNDLE-CONTRACT-DRIFT`
  Status: `done`
  Goal: `Repair stale normalized semantic protocol-bundle contract test expectations.`
  Children: `NORMALIZED-SEMANTIC-PROTOCOL-BUNDLE-CONTRACT-DRIFT.1`

- ID: `NORMALIZED-SEMANTIC-PROTOCOL-BUNDLE-CONTRACT-DRIFT.1`
  Status: `done`
  Goal: `Update payload/report contract tests for the existing protocol_intent_bundle child.`
  Acceptance: `The focused tests assert protocol_intent_bundle as an advertised optional semantic child and nested contract owner, while direct non-bundle semantic JSON still omits the optional child payload.`
  Verification: `passed`
  Commit: `NORMALIZED-SEMANTIC-PROTOCOL-BUNDLE-CONTRACT-DRIFT.1: repair protocol bundle contract tests`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `NORMALIZED-SEMANTIC-PROTOCOL-BUNDLE-CONTRACT-DRIFT.1` | `done` | Repaired stale test expectations for an already-shipped optional semantic child; no active next leaf remains in this tree. |

## Decisions

- `2026-06-12`: Keep this as a test/contract drift repair. The runtime contract
  code and book already name `semantic.protocol_intent_bundle`; the stale
  expectations are isolated to `t/330` and `t/311`.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `NORMALIZED-SEMANTIC-PROTOCOL-BUNDLE-CONTRACT-DRIFT.1` | `perl -Iperl -c t/330-normalized-semantic-payload-contract.t`; `perl -Iperl -c t/311-normalized-semantic-report-contract.t`; `prove -Iperl t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t`; `prove -Iperl t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/163-forward-structural-rtl-ir-surface.t`; `prove -Iperl t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `NORMALIZED-SEMANTIC-PROTOCOL-BUNDLE-CONTRACT-DRIFT.1` | `NORMALIZED-SEMANTIC-PROTOCOL-BUNDLE-CONTRACT-DRIFT.1: repair protocol bundle contract tests` | Test/contract drift repair. |

## Changelog

- `2026-06-12`: Created after the broader normalized semantic contract gate
  exposed stale protocol-bundle optional-child expectations during the R11
  direct structural net slice validation.
- `2026-06-12`: Completed `.1`; payload/report contract tests now expect
  `protocol_intent_bundle` in advertised optional semantic child lists while
  proving direct non-bundle semantic JSON still omits the optional payload.
