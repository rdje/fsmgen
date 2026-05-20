# R8-PARTIAL-LHS-PULSE-BOUNDARY: Delayed-Pulse Partial-LHS Boundary

## Metadata

- Tree ID: `R8-PARTIAL-LHS-PULSE-BOUNDARY`
- Status: `done`
- Roadmap lane: `R8`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Make indexed or sliced delayed-pulse LHS targets fail closed at the language
contract boundary instead of reaching a lower-level generation-time 1-bit
target error.

## Non-Goals

- Do not add partial delayed-pulse semantics.
- Do not change scalar delayed-pulse `<N` behavior.
- Do not change the proven partial-LHS contract for `=`, `<-`, `<=`, `<-=`,
  `<=-`, or legacy `<=+`.
- Do not invent a vector-pulse feature.

## Acceptance Criteria

- Parser, pipeline, and CLI entry points reject indexed/sliced delayed-pulse
  LHS targets with a targeted language-contract diagnostic and no HDL output.
- Scalar delayed-pulse targets such as `(P <1 1)` and `(<1 (P 1))` remain
  accepted.
- The mdBook assignment chapter states that delayed-pulse `<N` is scalar-target
  only.
- Focused validation and the relevant language-contract tests pass.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R8-PARTIAL-LHS-PULSE-BOUNDARY`
  Status: `done`
  Goal: `Reject partial delayed-pulse LHS targets explicitly.`
  Children: `R8-PARTIAL-LHS-PULSE-BOUNDARY.1`

- ID: `R8-PARTIAL-LHS-PULSE-BOUNDARY.1`
  Status: `done`
  Goal: `Add the delayed-pulse partial-LHS fail-closed boundary.`
  Acceptance: `Indexed and sliced '<N' targets fail through parser, pipeline,
  and CLI entry points with a targeted diagnostic and no output, while scalar
  '<N' coverage remains accepted.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`;
  `perl -Iperl -c t/57-language-contract-pulse-boundary.t`;
  `perl -Iperl -c t/04-assignment-edge-cases.t`;
  `prove -Iperl t/57-language-contract-pulse-boundary.t
  t/04-assignment-edge-cases.t t/29-language-contract-core-forms.t`;
  `git diff --check`; `mdbook build docs/book`
  Commit: `R8-PARTIAL-LHS-PULSE-BOUNDARY.1: reject partial pulse targets`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
This tree is closed. Indexed and sliced delayed-pulse `<N` LHS targets now
fail at the language boundary before HDL generation.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R8-PARTIAL-LHS-PULSE-BOUNDARY.1` | `done` | Added the targeted fail-closed boundary and closed the tree. |

## Decisions

- `2026-05-20`: Created from
  `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.3`. A probe of indexed delayed-pulse
  LHS behavior showed that `(P[0] <1 1)` is not a supported partial-LHS pulse
  contract; it reaches a later generation-time "target must be 1-bit" error.
  The next slice should reject this shape deliberately at the language
  boundary instead of widening pulse semantics.
- `2026-05-20`: Vector-pulse semantics remain deferred. There is no current
  distinct vector-pulse source construct to specify in this tree.
- `2026-05-20`: Completed `.1` by adding a parser-owned delayed-pulse LHS
  target validator. Indexed, sliced, aggregate, and deconstruct `<N` targets
  now reject with a targeted diagnostic through parser, pipeline, and CLI
  entry points.

## Open Questions

- None for `.1`.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R8-PARTIAL-LHS-PULSE-BOUNDARY.1` | `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl -Iperl -c t/57-language-contract-pulse-boundary.t`; `perl -Iperl -c t/04-assignment-edge-cases.t`; `prove -Iperl t/57-language-contract-pulse-boundary.t t/04-assignment-edge-cases.t t/29-language-contract-core-forms.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R8-PARTIAL-LHS-PULSE-BOUNDARY.1` | `R8-PARTIAL-LHS-PULSE-BOUNDARY.1: reject partial pulse targets` | Adds parser/pipeline/CLI rejection for indexed and sliced delayed-pulse LHS targets. |

## Changelog

- `2026-05-20`: Created and activated the tree for the delayed-pulse
  partial-LHS fail-closed boundary.
- `2026-05-20`: Completed `.1` and closed the tree.
