# IAL2 Post AXI Generality Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.542`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.542` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.543`, a public-surface historical wording
sync for the profile-alias chronology.

This audit changes no parser behavior, generator behavior, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, non-AXI behavior, common construct
promotion, profile-alias suffix syntax, direct backend lowering, or VHDL
behavior.

## Evidence Read

The current implementation surfaces are aligned:

- the capability manifest ships `.fsm`, `.isf`, `.ppif`, and `.axi`;
- `.axi` is described as a bounded profile-alias surface over IAL2, not as
  IAL2 itself;
- `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi`
  remain unsupported;
- support accounting includes `intent.axi_profile_alias_aw_valid_ready`,
  `intent.ppif_valid_ready_handshake`, and
  `intent.ppif_valid_ready_dual_channel_bundle`; and
- decisions `0015`, `0016`, and `0017` preserve profile aliases, the `.ppif`
  generic container, and reviewable generated `.isf`/`.fsm` bundle artifacts.

The current Knowledge Map routing is also aligned after `.541`: questions about
current `.axi` acceptance point to the `.540` behavior card, and the old
profile-alias readiness/inventory cards are historical.

The remaining risk is user-facing chronology in the mdBook. The feature backlog
still presents the `.537` and `.538` profile-alias sections with wording such
as "keeps `.ppif` as the only shipped IAL2 suffix" and keeps `.axi` in the
unsupported inventory. Those statements were true at `.537`/`.538`, but they
are no longer current after `.540`. The later `.axi` section is correct, yet a
reader scanning the book can still read the older paragraphs as current state.

## Selected `.543` Scope

`.543` should make the profile-alias chronology explicit in the mdBook, README,
ROADMAP_V2, task tree, Memory, and Knowledge Map where needed.

The sync should:

- mark the `.537` readiness and `.538` inventory sections as historical
  pre-`.540` state;
- keep the current `.540` `.axi` behavior and `.541`/`.542` follow-up text
  unchanged in meaning;
- preserve the fact that `.ppif` is the generic IAL2 container;
- preserve the fact that `.axi` is only the first profile-alias example over
  IAL2;
- preserve the remaining unsupported suffix list for `.chi`, `.ace`, `.ahb`,
  `.apb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi`; and
- make no parser, generator, sample, support-accounting, report, or HDL
  behavior changes.

`.543` should not select another behavior implementation. Its only job is to
remove the public-surface ambiguity before the next behavior owner is chosen.

## Deferred Alternatives

The following remain future exact-owner choices after the wording sync:

- another protocol-neutral/profile-neutral IAL2 follow-up;
- a non-AXI profile-alias readiness path;
- common IAL2 construct reuse only where cross-profile evidence proves it;
- an explicitly profile-local AXI continuation that remains framed as one
  profile vocabulary over IAL2; and
- backend-language or VHDL work only after the SystemVerilog-backed IAL path is
  feature-complete.

## Validation

Closeout for this audit is documentation-only:

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

Rollback is documentation-only: remove this audit, its Knowledge Map fact,
task-tree advancement, README/ROADMAP_V2/mdBook sync, and Memory pointer. No
parser, generator, sample, support-accounting, generated HDL, runtime, or
backend artifact rollback is required.
