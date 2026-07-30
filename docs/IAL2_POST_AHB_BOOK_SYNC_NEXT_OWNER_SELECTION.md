# IAL2 Post-AHB-Book Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.841` selects proposed no-behavior
`FSMGEN-HIR-ROADMAP-FRONTIER.2` as the next exact owner.

The selected leaf must choose one source-facing FSMGEN HIR architecture
boundary under `docs/IR_POLICY.md` before any high-level frontend or builder
implementation. This selector does not activate or modify the child before its
own commit is clean.

## Reconciled Boundary

Clean Chapter 16c documentation commit `3fb84b23e` resolves the last preserved
AHB BUSY-count truth contradiction without changing product behavior or
332/373/56 split 28/28 accounting. Clean continuity commit `cedc662a6`
activates `.841` only.

The repository already has named internal `IntentHIR`, `LoweredRTLIR`, and
`StructuralRTLIR` phase boundaries plus a policy that requires exact owners,
producers, consumers, invariants, mutation rules, public/private status,
validation, and migration before another durable IR surface lands. What remains
unselected is the source-facing semantic boundary above IAL2 and IAL1.

## Candidate Comparison

| Candidate | Selection result | Evidence |
| --- | --- | --- |
| Source-facing FSMGEN HIR boundary | **selected** | `.2` is one documentation-only architecture selection governed by the existing IR policy; it chooses reuse/new/textual handoff, one first frontend or builder, and one golden fixture before implementation. |
| Host-language builder | waits on selected HIR | Its own durable contract says future activation must consult or follow the HIR boundary instead of assuming direct IAL emission. |
| HIAL/VIAL verification architecture | remains proposed | The dual-intent bridge, portable semantics, two verification backends, native extensions, simulator profiles, parity, migration, and scale decomposition are broader and independent. |
| End-to-end large-design scalability | remains proposed | Its workload methodology, correctness oracles, resource schema, budgets, graceful failure, and regression split form a separate foundational audit. |
| Beyond-read-only MCP | remains proposed | Crossing the read-only trust boundary is an independent safety/authorization decision and is not a prerequisite for source-facing HIR selection. |
| `t/1436` pre-existing failures | ineligible | Its task explicitly requires director prioritization. |
| IAL2 AXI mdBook coherence | ineligible | Its task is explicitly director-activated. |
| RAM-guard metric refinement | ineligible | Changing the safety guard requires director approval. |
| Decision `0020` transaction architecture | ineligible | It remains an explicit no-pivot North Star until director activation. |
| Project-document lifecycle review | ineligible | Decision `0025` keeps `.1` and both frozen status files inactive. |

## Selected Leaf Contract

After separate clean activation, `FSMGEN-HIR-ROADMAP-FRONTIER.2` must:

- audit `docs/IR_POLICY.md`, the prior FSMGen IR audit, current named forward
  IR owners, IAL1/IAL2 public sources, normalized semantic/report projections,
  and the proposed host-language builder boundary;
- choose exactly one first source-facing HIR shape: extend an existing
  `IntentHIR`-adjacent layer, create a new named surface, or retain a textual
  IAL handoff for one bounded prototype;
- record the required IR-policy name, phase, owner, producers, consumers,
  invariants, mutation policy, public/private status, diagnostics, validation,
  documentation, and migration/retirement boundary;
- select one first exact frontend or builder and one existing golden fixture,
  while preserving IAL1 and IAL2 as lowering targets;
- decompose any implementation into later exact leaves and change no parser,
  compiler, source, artifact, config, API, HDL/runtime, or public behavior.

## Validation And Rollback

Validation runs focused task/book/path audits, Knowledge Map, memory, mdBook,
diff, and doctrine gates from repository-local same-volume paths. It proves the
selected HIR child remains proposed and that no implementation-bearing file is
changed.

Selector closeout passes the feature-backlog status, live-book-path, and
relative-path audits with `Files=3, Tests=40`; Knowledge Map generation/check
passes at `1075` facts / `5539` question keys; memory architecture passes with
`MEMORY.md` at `46` lines; the 72-file mdBook HTML build passes and its exact
repository-local output is removed; diff hygiene passes.

Rollback removes this selector record/fact and restores `.841` to active. Every
candidate remains proposed or director-gated, and product behavior is unchanged.
