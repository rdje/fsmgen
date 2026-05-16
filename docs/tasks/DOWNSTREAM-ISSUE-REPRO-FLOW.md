# DOWNSTREAM-ISSUE-REPRO-FLOW: Downstream Issue Reproduction Flow

## Metadata

- Tree ID: `DOWNSTREAM-ISSUE-REPRO-FLOW`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Publish a precise, format-agnostic downstream issue-reporting flow that lets
SPECFORGE or another producer report FSMGen-facing bugs with enough artifacts
for FSMGen maintainers to reproduce the failure locally.

## Non-Goals

- Do not change parser, scheduler, report, generated `.fsm`, or HDL behavior.
- Do not define a new public JSON schema.
- Do not require downstream tools to understand whether the root cause is
  `.fsm`, `.isf`, parser, lowering, HDL, or public API behavior before filing
  the report.
- Do not require downstream tools to expose proprietary upstream intent sources
  when the minimized FSMGen-facing artifact bundle is sufficient.

## Acceptance Criteria

- A single repo-local issue-reporting document defines required reproduction
  artifacts, command transcripts, expected/observed behavior, and privacy
  reduction rules without requiring downstream source-format classification.
- The ISF downstream handoff and mdBook point downstream consumers to the flow.
- The ISF public live-document path metadata advertises the flow.
- Focused validation passes.
- Live docs and roadmap/task-tree status are updated.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `DOWNSTREAM-ISSUE-REPRO-FLOW`
  Status: `done`
  Goal: `Publish a downstream reproducible issue-reporting flow`
  Children: `DOWNSTREAM-ISSUE-REPRO-FLOW.1`

- ID: `DOWNSTREAM-ISSUE-REPRO-FLOW.1`
  Status: `done`
  Goal: `Document required format-agnostic reproduction bundles for downstream bugs`
  Acceptance: `Docs and public live-document metadata tell SPECFORGE exactly what to provide so FSMGen can reproduce locally`
  Verification: `bash -n bin/fsmgen-issue-bundle`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1251-fsmgen-issue-bundle-helper.t t/1120-isf-public-live-document-path-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `DOWNSTREAM-ISSUE-REPRO-FLOW.1: publish issue bundle flow`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `_None_` | `_None_` | Tree closed |

## Decisions

- `2026-05-16`: Use one shared downstream issue-reporting document that treats
  FSMGen-facing inputs as opaque artifacts. SPECFORGE should provide exact
  files, invocation, stdout/stderr/exit status, machine-readable reports,
  generated artifacts where available, FSMGen revision, and expected versus
  observed behavior; FSMGen maintainers will classify the root cause locally.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `DOWNSTREAM-ISSUE-REPRO-FLOW.1` | `bash -n bin/fsmgen-issue-bundle`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1251-fsmgen-issue-bundle-helper.t t/1120-isf-public-live-document-path-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `DOWNSTREAM-ISSUE-REPRO-FLOW.1` | `DOWNSTREAM-ISSUE-REPRO-FLOW.1: publish issue bundle flow` | `pending commit` |

## Changelog

- `2026-05-16`: Created task tree for downstream reproducible issue-reporting flow.
- `2026-05-16`: Closed tree after publishing the format-agnostic issue-bundle
  protocol, helper script, public-doc links, and regression coverage.
