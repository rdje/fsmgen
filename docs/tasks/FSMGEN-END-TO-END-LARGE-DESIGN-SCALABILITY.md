# FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY: Big-To-Really-Big End-To-End Designs

## Metadata

- Tree ID: `FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY`
- Status: `proposed`
- Roadmap lane: `performance/scalability / end-to-end design capacity`
- Created: `2026-07-29`
- Last updated: `2026-07-29`
- Owner: repo-local workflow

## Goal

Make FSMGen demonstrably capable of processing end-to-end big to really big
designs without losing correctness, bounded resource behavior, diagnostic
quality, artifact integrity, or workflow recoverability.

This is a parked product requirement, not an active priority change. A later
roadmap selector must activate it explicitly from a clean boundary.

Parent selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.829` keeps this requirement
proposed while selecting the smaller adjacent generalized literal AHB
BUSY-count readiness audit. That audit must still measure and bound its own
resource/verification cost; it does not claim or replace end-to-end big-to-
really-big qualification.

## Requirement

“Large-design support” means the complete user path, not a parser-only or
single-pass microbenchmark:

```text
source -> parse/normalize -> IAL lowering -> scheduling/analysis
       -> review artifacts -> HDL -> verification/tool handoff
```

The eventual contract must define evidence-backed `big` and `really_big`
profiles by structural dimensions such as source size, module/actor count,
composition depth and fanout, states/rules/transactions, signals/storage,
expressions/assertions, generated artifact size, and supported protocol
objects. It must measure peak descendant RSS, wall time, CPU time, output size,
and diagnostic behavior per stage while proving semantic/output correctness.

## Non-Goals

- Do not interrupt the active IAL2/AHB correctness frontier merely to start
  scalability work.
- Do not invent unsupported capacity numbers before a reproducible workload
  and measurement contract exist.
- Do not call one synthetic parser input “end-to-end” coverage.
- Do not trade correctness, assertion coverage, deterministic artifacts,
  diagnostics, same-volume locality, or recoverability for a benchmark score.
- Do not require every downstream third-party tool to scale identically; keep
  FSMGen-owned stages and explicitly bounded external-tool handoffs distinct.

## Acceptance Criteria

- Define reproducible `big` and `really_big` end-to-end workload profiles and
  explain why their structural dimensions represent meaningful designs.
- Generate or store workloads deterministically under repository-derived,
  same-volume paths with exact cleanup/residue rules.
- Establish per-stage correctness oracles and artifact/semantic parity, not
  performance measurements alone.
- Measure peak descendant RSS, wall/CPU time, input/output bytes, object counts,
  and diagnostics with repeatable machine/profile metadata.
- Identify asymptotic and constant-factor bottlenecks across parser,
  normalization, IAL2/IAL1/IAL0 lowering, scheduling, selector/assertion
  analysis, emitters, semantic exports, review artifacts, and verification
  handoff.
- Freeze explicit pass/fail budgets only after baseline evidence; document
  graceful failure behavior for inputs beyond supported capacity.
- Add focused performance-regression gates that are stable enough for local/CI
  use and a heavier opt-in qualification profile where warranted.
- Keep roadmap, task tree, mdBook, Knowledge Map, and user-facing capacity
  guidance synchronized with measured behavior.
- Commit every activated leaf through `COMMIT.md`.

## Task Tree

- ID: `FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY`
  Status: `proposed`
  Goal: `Prove and sustain end-to-end FSMGen capacity for big to really big designs.`
  Children: `FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY.1`

- ID: `FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY.1`
  Status: `pending`
  Goal: `Select the measurable large-design capacity contract and workload methodology before benchmarking or implementation.`
  Acceptance: `Activate only through a later clean-boundary roadmap selector. Audit existing performance/stress fixtures, pipeline stages, known materialization/copy hotspots, artifact and semantic surfaces, same-volume constraints, RAM measurement guidance, CI/local machine variability, and downstream-tool boundaries. Define proposed big/really_big structural profiles, deterministic workload construction, per-stage correctness oracles, measurement schema, warmup/repetition/noise policy, resource and timeout safety, cleanup, reporting, regression-gate split, implementation follow-on leaves, and rollback without changing product behavior or claiming capacity.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-29`: The director stated that FSMGen shall handle end-to-end big to
  really big designs. Record this as a foundational proposed requirement, but
  do not pivot from the selected AHB subordinate correctness audit.
- `2026-07-29`: Capacity claims require complete pipeline evidence and
  correctness oracles. Scale labels and budgets remain unselected until `.1`.
- `2026-07-30`: Shipping the bounded AHB requester literal `2..16` range is a
  correctness/expressiveness slice, not end-to-end scale evidence. The
  large-design tree remains proposed for independent comparison by parent
  selector `.830` after the generalized-count behavior commit.

## Open Questions

- Which real or representative design families should anchor `big` and
  `really_big` in addition to deterministic generated stress designs?
- Which stages should have always-on CI thresholds versus heavier scheduled or
  local qualification gates?
- What graceful degradation contract is appropriate beyond the qualified
  profile: bounded diagnostic refusal, streaming/spilling, or another model?

## Blockers

- None for durable capture. Activation awaits a later roadmap selector; the
  current AHB correctness frontier remains first.

## Capture Verification

- Requirement/task/fact/index/roadmap/mdBook/Memory are synchronized without
  activation or product behavior changes.
- Knowledge Map generation/check passes at 1,013 facts/5,151 question keys;
  mdBook builds; memory architecture, relative-doc paths, README entrypoint,
  project-data locality, diff, and all doctrine gates pass.
- The exact generated mdBook output contained 72 files/16,023,958 bytes, was
  removed, and residue is none.
- Capture commit:
  `FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY: park foundational requirement`.

## Rollback

Before activation, rollback removes this proposed task and its fact/index/book
references only. After activation, each leaf must define workload, measurement,
artifact, and budget rollback together.
