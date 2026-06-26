# IAL2 Protocol Generality Guardrail Readiness Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.525`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.525` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.526`, readiness audit for the IAL2
protocol/platform generality guardrail after the first AXI-derived example has
grown deep enough to risk being mistaken for the whole IAL2 language.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated artifact, test, HDL/runtime behavior, backend
behavior, verification-output generation, backend-language variant, external
converter dependency, scoreboard, arbitrary cardinality, group-local
simultaneous enqueue behavior, read-data, raw-`ARLEN`, runtime-validation,
multi-beat, AXI manager behavior, non-AXI behavior, or VHDL behavior.

## Context Read

The selector read the current mixed queue chain and the older IAL2 architecture
records:

- `.524` generated one-dynamic plus two-concrete-static mixed dynamic/static
  write `BID` same-ID `issue-order-queue` behavior.
- `.523` readiness audit for that write multi-static queue boundary.
- `.520` generated mixed dynamic/static read burst-last same-ID queue
  read-data multi-beat behavior over the existing one-dynamic plus one-static
  read queue.
- `.521` public contract synchronization after `.520`.
- `.503` one-dynamic plus one-static mixed dynamic/static write `BID`
  same-ID queue behavior.
- Decision `0014`, which states that IAL2 is for protocol/platform intent
  across AXI, CHI, ACE, AHB, APB, ATB, and future protocols, and that AXI
  manager work is one IAL2 vocabulary candidate, not a language boundary.
- Decision `0015`, which permits future protocol-specific extensions only as
  vocabulary/profile aliases over the same IAL2 layer.
- The Knowledge Map fact for common-vs-profile factoring, which keeps common
  IAL2 constructs small and promotes profile-local vocabulary only after reuse
  is proven across multiple profiles.
- Current public contracts, README, ROADMAP_V2, mdBook, task tree, Memory, and
  Knowledge Map.

## Why This Is Next

AXI is the first worked IAL2 example, not the definition of IAL2. The current
frontier has spent many slices deepening AXI manager capacity/status behavior.
That work is useful and task-tree-owned, but continuing immediately into more
AXI queue cardinality would increase the risk that public docs, report
vocabulary, task names, and future abstractions imply that IAL2 is AXI-shaped.

The next smallest safe owner is a no-code readiness audit that reasserts the
architecture boundary:

- common IAL2 remains a protocol/platform-generic layer;
- AXI-specific clauses stay AXI-profile-local unless compatible reuse is proven
  by at least one other protocol/profile;
- profile aliases such as future `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`,
  `.atb`, `.smbus`, or `.i2s` are aliases over IAL2, not new layers;
- every IAL2 input still lowers through reviewable IAL1 before IAL0; and
- the user-facing mdBook must explain AXI as the first example, not as the
  entire IAL2 roadmap.

## Selected `.526` Scope

`.526` must audit the current IAL2 public surface and roadmap for AXI
overfitting risk before the next behavior implementation.

The audit must:

- inventory where public docs, mdBook, task-tree language, report vocabulary,
  tests, PPIF examples, and capability manifests describe IAL2 in AXI-specific
  terms;
- distinguish AXI-profile-local vocabulary from protocol/platform-generic IAL2
  constructs;
- identify any wording that could make users believe IAL2 is only AXI;
- decide whether the next exact owner should be a public-doc guardrail cleanup,
  a protocol-neutral example/readiness probe, a profile-alias design audit, a
  non-AXI vocabulary exploration, or a return to AXI-specific implementation
  with explicit profile-local labeling;
- record the preservation boundary for all shipped AXI PPIF behavior; and
- record the validation, rollback, docs/book, Knowledge Map, and non-goal
  requirements for whichever next owner is selected.

The audit may use AXI as evidence because AXI is the first shipped IAL2
profile. It must not implement new AXI behavior or select common IAL2
abstractions merely because AXI uses them.

## Explicit Non-Goals

`.525` and `.526` do not implement:

- parser/generator changes;
- PPIF or profile-alias syntax;
- non-AXI protocol behavior;
- AXI queue/read-data/cardinality behavior;
- common IAL2 construct promotion;
- generated artifacts, schedule/check/semantic JSON, HDL/runtime behavior,
  backend behavior, verification-output generation, backend-language variants,
  external converter dependencies, scoreboards, or VHDL.

## Validation

This `.525` selector closes with documentation and continuity gates only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No syntax, parser, generator, PPIF, support-accounting, schedule/check/
semantic JSON, HDL, runtime, backend, external-converter, verification-output,
or VHDL validation is claimed for `.525` because it changes no behavior.

## Rollback

Rollback is documentation-only: remove this selector document and its
Knowledge Map fact, revert the `.525` task-tree advancement,
README/ROADMAP_V2/mdBook sync, and Memory pointer, and return the active
frontier to `.525`. No generated HDL or runtime artifact rollback is required.
