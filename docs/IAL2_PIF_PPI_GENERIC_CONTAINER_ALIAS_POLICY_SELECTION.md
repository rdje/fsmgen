# IAL2 PIF/PPI Generic-Container Alias Policy Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.547`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.547` keeps `.pif` and `.ppi` explicitly
unsupported historical generic-container spellings. They remain known
unsupported suffixes so users receive a deliberate IAL2-candidate diagnostic,
not an unknown-file-suffix diagnostic.

`.547` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.548`, an APB IAL2
source-shape readiness audit before any `.apb` suffix or APB `.ppif` contract.

No parser behavior, generator behavior, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, non-AXI behavior, common construct
promotion, profile-alias suffix syntax, generic-container alias syntax, direct
backend lowering, or VHDL behavior changed.

## Policy

`.ppif` remains the only shipped generic IAL2 container. `.pif` and `.ppi` are
not accepted aliases, not documentation-only reserved names, and not selected
for a future behavior contract in this slice.

This policy follows decision `0016`: `.ppif` was selected because Protocol/
Platform Intent Format names both protocol and platform intent while still
making clear that this is a file format. `.pif` and `.ppi` remain historical
candidates.

Accepting `.pif` or `.ppi` now would multiply the public file surface without
adding IAL2 capability. It would require duplicate source-path behavior,
capability-manifest entries, check/semantic JSON examples, support-accounting
identity, mdBook examples, and diagnostics for a spelling alias over the same
source shape.

If a future owner ever reopens `.pif` or `.ppi`, that owner must select exactly
one policy before implementation:

- synonym alias over `.ppif`, including source-path and report identity rules;
- reserved-but-unsupported spelling with more explicit diagnostics; or
- permanent rejection/deprecation.

## Evidence Read

Decision `0015` treats `.pif`, `.ppi`, and `.ppif` as generic
protocol/platform container candidates and treats protocol-specific suffixes
as profile aliases over the same IAL2 model.

Decision `0016` selects `.ppif` as the first public generic container and
states that `.pif` and `.ppi` are not accepted in the first implementation
unless a later exact owner selects them.

Decision `0017` adds the Valid-Ready bundle report contract under `.ppif`; it
does not create another suffix.

The live CLI currently:

- recognizes `.pif` and `.ppi` as known source suffixes;
- rejects them before PPIF parsing through the known unsupported IAL2 alias
  diagnostic;
- advertises `.ppif` and `.axi` in help, not `.pif` or `.ppi`; and
- dispatches IAL2 lowering only for `.ppif` and `.axi`.

`LanguageSurfaceSection` ships only `.fsm`, `.isf`, `.ppif`, and `.axi`.
It keeps `.pif` and `.ppi` in the unsupported first-slice alias inventory.

## Next Non-AXI Direction

The next useful non-AXI step is not another spelling alias. It is an APB IAL2
source-shape readiness audit.

The repository already has APB lower-layer evidence:

- `isf/apb_requester.isf` is the primary realistic ISF APB requester fixture.
- `fsm/apb_requester.fsm` models a bounded APB requester.
- `fsm/apb_completer.fsm` models a bounded APB completer.
- `fsm/apb_tb.fsm` composes requester and completer through APB bus wiring.
- The mdBook documents APB ISF examples and APB/C4 generated-FSM composition
  behavior.

That evidence is not yet an IAL2 source shape. It is enough to justify an
audit that asks whether APB should first get:

- a generic `.ppif` `(profile apb)` source-shape contract;
- lower-layer public contract cleanup before IAL2;
- report/support-accounting prerequisites; or
- continued deferral.

## Selected `.548` Scope

`.548` should audit APB IAL2 source-shape readiness without changing behavior.

The audit should read `.547`, `.546`, decisions `0015`/`0016`/`0017`, APB ISF
and FSM fixtures, APB mdBook sections, current suffix/manifest/help surfaces,
README, ROADMAP_V2, task tree, Memory, and Knowledge Map. It should decide the
next exact owner: APB `.ppif` source-shape contract selection, APB lower-layer
prerequisite, report/support-accounting prerequisite, or deferral.

`.548` must not accept `.apb`, `.pif`, `.ppi`, or any other new suffix; must
not add an APB `.ppif` sample; must not change parser, generator, manifest,
support-accounting, JSON, HDL, runtime, backend, verification-output, or VHDL
behavior; and must not extend `.axi`.

## Validation

Closeout for this selector is documentation-only:

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
parser, generator, sample, support-accounting, generated HDL, runtime, or
backend artifact rollback is required.
