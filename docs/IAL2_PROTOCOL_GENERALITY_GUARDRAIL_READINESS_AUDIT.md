# IAL2 Protocol Generality Guardrail Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.526`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.526` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.527`, public-surface cleanup for the IAL2
protocol/platform generality guardrail.

The next slice should update the downstream/public contract wording,
capability-manifest boundary text, README, ROADMAP_V2, mdBook, Memory, task
tree, and Knowledge Map so they consistently say:

- AXI is the first shipped IAL2 profile/example, not the definition of IAL2;
- `.ppif` is the first generic protocol/platform IAL2 container;
- protocol-specific aliases such as future `.axi`, `.chi`, `.ace`, `.ahb`,
  `.apb`, `.atb`, `.smbus`, or `.i2s` are profile aliases over IAL2, not
  separate layers;
- common IAL2 constructs stay small and are promoted only after compatible
  reuse is proven across multiple profiles; and
- all IAL2 inputs still lower through reviewable IAL1 before IAL0.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated artifact, test, schedule/check/semantic JSON,
HDL/runtime behavior, backend behavior, verification-output generation,
backend-language variant, external converter dependency, scoreboard, AXI
behavior, non-AXI behavior, common construct promotion, profile-alias syntax,
or VHDL behavior.

## Evidence Read

The audit read:

- `.525` selector;
- decisions `0014`, `0015`, and `0016`;
- Knowledge Map facts for protocol/platform lowering, profile aliases, and
  common-vs-profile factoring;
- the protocol/platform and profile-extension task trees;
- `.524` mixed write multi-static queue behavior and `.523` audit;
- `.520` mixed queue multi-beat behavior and `.521` public sync;
- public interface/downstream contracts;
- the language-surface capability manifest boundary;
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map.

## Inventory

The architecture records are correct. Decision `0014` explicitly says IAL2
must apply across AXI, CHI, ACE, AHB, APB, ATB, and future protocols rather
than become an AXI-only language surface. Decision `0015` permits future
protocol-specific extensions only as vocabulary/profile aliases over the same
IAL2 layer. Decision `0016` selects `.ppif` as the first public generic IAL2
container and keeps direct `.ppif` to `.fsm` lowering forbidden.

The mdBook already contains some correct guardrails around the early IAL2
surface: it says the generic file surface remains protocol/platform-generic,
profile aliases are future vocabulary aliases, and the common-vs-profile split
requires compatible reuse across multiple profiles.

The current risk is in the highly visible shipped-surface summaries. The
public interface contract, downstream integration spec, and language-surface
manifest boundary enumerate a long AXI manager capacity/status surface under
the `.ppif` suffix. They are accurate about shipped AXI behavior, but they do
not lead with the guardrail that AXI is only the first shipped profile/example.
That is the wording most likely to be consumed by users and downstream tooling.

README, ROADMAP_V2, and the mdBook now have a short `.525` guardrail note, but
the public contract/capability-manifest boundary remains the authoritative
place to fix the drift because it is the machine-readable and downstream-facing
surface.

## Selected `.527` Scope

`.527` should perform public-surface cleanup only. It should:

- add explicit IAL2 generality wording to
  `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`;
- add matching downstream-handoff wording to
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`;
- update `perl/FSM/Support/LanguageSurfaceSection.pm` so the capability
  manifest boundary itself carries the same guardrail;
- update `t/297-capability-manifest.t` if the expected boundary regex needs
  to match the new wording;
- keep README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map in
  sync; and
- avoid behavior, parser, PPIF sample, support-accounting, generated-artifact,
  schedule/check/semantic JSON, HDL/runtime, backend, non-AXI, common
  construct promotion, or profile-alias syntax changes.

The cleanup should not introduce a new generic IAL2 abstraction. It should
only make the existing public truth explicit and hard to misread.

## Deferred Alternatives

The following remain future exact-owner work:

- non-AXI protocol vocabulary exploration;
- profile-alias syntax or extension dispatch;
- promotion of any AXI vocabulary into common IAL2;
- further AXI queue/read-data/cardinality behavior;
- direct backend behavior;
- verification-output generation for IAL2 profiles;
- backend-language variants; and
- VHDL.

## Validation

`.526` is documentation-only and closes with:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

`.527` should additionally run the syntax check for
`perl/FSM/Support/LanguageSurfaceSection.pm` and the focused capability
manifest test if it changes that boundary string.

## Rollback

Rollback for `.526` is documentation-only: remove this audit, its Knowledge
Map fact, task-tree advancement, README/ROADMAP_V2/mdBook sync, and Memory
pointer. No generated HDL or runtime artifact rollback is required.
