# IAL2 Post AXI Profile-Alias Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.541`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.541` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.542`, a post-`.axi` IAL2 generality
readiness audit.

This selector changes no parser behavior, generator behavior, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, non-AXI behavior, common construct
promotion, profile-alias suffix syntax, direct backend lowering, or VHDL
behavior.

## Evidence Read

`.540` shipped `ppif/axi_aw_valid_ready.axi` as the first bounded IAL2
profile-alias suffix. The alias uses the same `protocol-platform-intent`
source shape as `.ppif`, requires an explicit AXI-family profile, preserves
`IAL2 -> IAL1 -> IAL0 -> HDL` lowering, reports the authored `.axi` source
path, and support-accounts `intent.axi_profile_alias_aw_valid_ready`.

`.539` selected `.axi` only as the first profile-alias contract. It explicitly
kept AXI as an example over IAL2, not the definition of IAL2.

`.538` synchronized the pre-implementation unsupported-alias inventory. After
`.540`, the old `.537`/`.538` Knowledge Map cards still carried current-looking
questions that implied `.axi` remained unsupported. `.541` corrects that
retrieval surface: the historical cards now describe the pre-`.540` state, and
the current `.axi` behavior card owns current questions about `.axi`
acceptance.

The generality evidence before `.axi` still matters:

- `.531` shipped the first protocol-neutral/non-AXI one-channel Valid-Ready
  `.ppif` sample.
- `.535` shipped the protocol-neutral/non-AXI dual-channel Valid-Ready `.ppif`
  bundle.
- Decisions `0015` and `0016` keep profile-specific suffixes as aliases over
  the same IAL2 layer and keep `.ppif` as the first generic IAL2 container.
- Decision `0017` keeps Valid-Ready bundles reviewable through generated
  `.isf` and `.fsm` artifacts before HDL.

## Why This Is Next

The immediate post-`.axi` risk is drift: future lookup must not route current
questions to pre-implementation facts, and the next IAL2 slice must not slide
back into treating AXI as the whole layer.

The next owner should therefore audit the post-`.axi` frontier from the
generality side before selecting another behavior implementation. The audit
should decide whether the next safe step is:

- another protocol-neutral/profile-neutral IAL2 follow-up;
- a non-AXI profile-alias readiness path;
- a common IAL2 construct only where the neutral Valid-Ready and AXI-profile
  evidence already proves reuse;
- a small documentation/manifest/support-accounting prerequisite; or
- an explicitly profile-local AXI continuation, if and only if it remains
  clearly framed as one profile vocabulary over IAL2.

## Selected `.542` Scope

`.542` should read `.541`, `.540`, `.539`, `.538`, the neutral `.ppif`
behavior from `.531` and `.535`, decisions `0015`, `0016`, and `0017`, current
public `.ppif`/`.axi` surfaces, capability manifest boundaries, support
accounting, README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map.

It should then select the next exact IAL2 owner from the post-`.axi` state,
recording source anchors, report/schema expectations, generated review artifact
boundaries, diagnostics, validation gates, rollback, and explicit residue before
any behavior changes.

`.542` must not implement parser/generator changes, add samples, alter support
accounting, promote common constructs, accept another suffix alias, change
schedule/check/semantic JSON behavior, change HDL/runtime behavior, or reopen
VHDL/backend-language work.

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
the historical fact-card question routing updates, task-tree advancement,
README/ROADMAP_V2/mdBook sync, and Memory pointer. No parser, generator,
sample, support-accounting, generated HDL, runtime, or backend artifact
rollback is required.
