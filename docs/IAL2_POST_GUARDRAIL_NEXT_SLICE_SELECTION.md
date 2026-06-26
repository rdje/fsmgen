# IAL2 Post-Guardrail Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.528`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.528` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.529`, readiness audit for a
protocol-neutral/non-AXI Valid-Ready `.ppif` example boundary.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, non-AXI behavior, common construct
promotion, profile-alias syntax, or VHDL behavior.

## Why This Is Next

The public guardrail is now explicit: AXI is the first shipped IAL2
profile/example, not the definition of IAL2. The next owner should exercise
that guardrail by auditing a small non-AXI/protocol-neutral path before
returning to another AXI behavior slice.

The smallest candidate is the existing Valid-Ready family, not a new full
protocol. Current `.ppif` coverage already advertises one-channel Valid-Ready
sources and multi-channel Valid-Ready bundles, while the first public sample
is AXI-shaped. A readiness audit can determine whether a protocol-neutral
Valid-Ready example can be admitted through existing source/profile/report
surfaces, or whether profile syntax, support-accounting, docs, or source
anchors need a separate owner first.

This is safer than immediately selecting `.axi`/`.chi`/`.apb` aliases because
profile-alias dispatch is a broader parser and source-identity design problem.
It is also safer than promoting AXI queue or same-ID vocabulary into common
IAL2 because compatible reuse evidence has not been established.

## Selected `.529` Scope

`.529` should audit:

- the current `.ppif` Valid-Ready parser/report/generator surface;
- the shipped AXI-shaped Valid-Ready sample and whether a protocol-neutral
  sample can be expressed without new syntax;
- source-anchor, profile, object, channel, role, support-accounting, and
  mdBook implications for a non-AXI Valid-Ready example;
- whether the next exact owner should be a public protocol-neutral sample,
  a profile/source vocabulary selector, a profile-alias design audit, or a
  return to explicitly profile-local AXI implementation; and
- preservation of all shipped AXI manager and existing Valid-Ready behavior.

`.529` must not implement parser/generator changes, add samples, alter
support accounting, promote common IAL2 constructs, or introduce profile-alias
syntax. It is a readiness audit only.

## Deferred Alternatives

The following remain future exact-owner work:

- protocol-specific profile aliases such as `.axi`, `.chi`, `.ace`, `.ahb`,
  `.apb`, `.atb`, `.smbus`, or `.i2s`;
- non-AXI full protocol behavior;
- common IAL2 queue/order/read-data construct promotion;
- additional AXI manager queue/read-data/cardinality behavior;
- direct backend behavior;
- verification-output generation for IAL2 profiles;
- backend-language variants; and
- VHDL.

## Validation

`.528` is documentation-only and closes with:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is documentation-only: remove this selector, its Knowledge Map fact,
task-tree advancement, README/ROADMAP_V2/mdBook sync, and Memory pointer. No
generated HDL or runtime artifact rollback is required.
