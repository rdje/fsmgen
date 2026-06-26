# IAL2 Protocol Generality Guardrail Public Surface Sync

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.527`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.527` synchronizes the public `.ppif`
surface with the IAL2 protocol/platform generality guardrail and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.528`, post-guardrail IAL2 next-slice
selection.

The public contract, downstream integration handoff, and capability-manifest
language-surface boundary now lead with these rules:

- `.ppif` is the generic Protocol/Platform Intent Format IAL2 container;
- AXI is the first shipped IAL2 profile/example, not the definition of IAL2;
- future protocol-specific suffixes such as `.axi`, `.chi`, `.ace`, `.ahb`,
  `.apb`, `.atb`, `.smbus`, or `.i2s` are profile aliases over IAL2 rather
  than separate layers;
- common IAL2 constructs stay small until compatible reuse is proven across
  multiple profiles; and
- every `.ppif` path lowers through generated `.isf` before generated `.fsm`.

The existing AXI manager capacity/status inventory remains profile-local
shipped coverage under that generic IAL2 container.

## Public Surface Changes

The sync updated:

- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`;
- `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`;
- `perl/FSM/Support/LanguageSurfaceSection.pm`; and
- `t/297-capability-manifest.t`.

The manifest test now checks that the `.ppif` boundary explicitly states AXI
is the first shipped IAL2 profile/example, protocol-specific suffixes are
future profile aliases over IAL2, and common IAL2 construct promotion remains
evidence-driven across multiple profiles.

## Non-Goals

This slice changes no parser behavior, generator behavior, PPIF sample,
support-accounting catalog, validation behavior, generated artifact,
schedule/check/semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI generated behavior, non-AXI generated behavior,
common construct promotion, profile-alias syntax, or VHDL behavior.

## Next Owner

`.528` should select the next roadmap-aligned IAL2 slice after this guardrail
cleanup. It should explicitly consider a protocol-neutral example/readiness
probe, non-AXI vocabulary exploration, profile-alias design audit, common IAL2
construct extraction, or an explicitly profile-local AXI implementation slice.
The selector must not treat AXI as the whole IAL2 roadmap.

## Validation

`.527` closes with:

```bash
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/297-capability-manifest.t
prove -Iperl t/297-capability-manifest.t
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is public-surface only: restore the previous public contract,
downstream handoff, capability-manifest boundary string and focused manifest
expectations; remove this document, its Knowledge Map fact, task-tree
advancement, README/ROADMAP_V2/mdBook sync, and Memory pointer. No generated
HDL or runtime artifact rollback is required.
