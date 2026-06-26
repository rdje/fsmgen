# IAL2 Profile-Alias Public Chronology Sync

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.543`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.543` makes the post-`.axi` public
profile-alias chronology explicit.

The synchronized surfaces now distinguish:

- the historical pre-`.540` state, where `.ppif` was the only shipped IAL2
  suffix and `.axi` was still part of the unsupported first-slice alias
  inventory; from
- the current post-`.540` state, where `.axi` is accepted only for the selected
  AXI AW Valid-Ready profile-alias sample and the other alias candidates remain
  unsupported.

No parser behavior, generator behavior, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, non-AXI behavior, common construct
promotion, profile-alias suffix syntax, direct backend lowering, or VHDL
behavior changed.

## Public Surface Updates

The sync updates:

- `README.md`;
- `ROADMAP_V2.md`;
- `docs/book/src/14-feature-backlog.md`;
- this task tree;
- `MEMORY.md`; and
- the Knowledge Map fact surface.

The mdBook now labels the `.537` profile-alias readiness audit and `.538`
unsupported inventory sync as historical pre-`.540` entries. The current `.540`
`.axi` behavior section remains the source of current user-facing `.axi`
behavior.

## Selected `.544` Scope

`IAL2-FEATURE-COMPLETENESS-FRONTIER.543` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.544`, next exact IAL2 owner selection after
the public chronology sync.

`.544` should choose the next owner from the now-aligned state. It should
consider protocol-neutral/profile-neutral follow-up, non-AXI profile-alias
readiness, common IAL2 construct reuse only with cross-profile evidence, or an
explicitly profile-local AXI continuation framed as one IAL2 profile. It must
not implement behavior.

## Validation

Closeout for this sync is documentation-only:

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

Rollback is documentation-only: remove this sync record, its Knowledge Map
fact, the public wording edits, task-tree advancement, README/ROADMAP_V2/mdBook
sync, and Memory pointer. No parser, generator, sample, support-accounting,
generated HDL, runtime, or backend artifact rollback is required.
