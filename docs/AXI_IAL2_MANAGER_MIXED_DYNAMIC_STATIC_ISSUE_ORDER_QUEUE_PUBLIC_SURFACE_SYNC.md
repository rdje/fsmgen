# AXI IAL2 Manager Mixed Dynamic/Static Issue-Order Queue Public Surface Sync

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.511`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.511` synchronizes the public `.ppif`
downstream-contract, capability-manifest, and mdBook surfaces after generated
mixed dynamic/static same-ID issue-order queue behavior shipped through
`.503`, `.506`, and `.509`.

The synchronized public boundary now advertises generated one-dynamic plus
one-concrete-static mixed dynamic/static same-ID issue-order queue behavior
for:

- write `BID`;
- read single-beat `RID`;
- read burst-last `RID && RLAST`.

This is a public-surface synchronization only. Parser/generator behavior,
PPIF samples, support-accounting catalog entries, generated artifacts,
schedule/check/semantic JSON, HDL/runtime behavior, backend behavior, external
converter behavior, verification output, and VHDL behavior are unchanged.

## Updated Surfaces

Updated human-facing downstream surfaces:

- `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`
- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`
- `docs/book/src/11-extensions-and-embedding.md`

Updated machine-readable discovery surface:

- `perl/FSM/Support/LanguageSurfaceSection.pm`
  `language_surface.file_surfaces` `.ppif` `current_boundary`

Updated focused manifest test:

- `t/297-capability-manifest.t`

The downstream integration document version is now `2026-06-26`.

## Public Boundary

The synchronized `.ppif` boundary keeps the broad AXI manager coverage text
bounded while naming the current generated same-ID queue families:

- generated all-dynamic same-ID issue-order queues for selected write `BID`,
  read single-beat `RID`, and read burst-last `RID && RLAST` depth-2/depth-3
  shapes;
- selected read-data, raw-`ARLEN`, runtime-validation, and multi-beat
  output-bank behavior over generated all-dynamic read burst-last issue-order
  queues;
- generated mixed dynamic/static response-demux families;
- generated one-dynamic plus one-concrete-static mixed dynamic/static same-ID
  issue-order queue behavior for write `BID`, read single-beat `RID`, and read
  burst-last `RID && RLAST`.

## Deferred

Mixed read-data, raw `ARLEN`, runtime validation, and multi-beat output banks
over generated mixed dynamic/static issue-order queues remain deferred. Broader
mixed issue-order queue cardinality, scoreboards, group-local simultaneous
enqueue widening, packed burst-vector outputs, alternate full burst payload
assembly, aliases, platform clauses, full AXI manager behavior, direct backend
lowering, verification-output generation, backend-language variants, external
converter dependencies such as `sv2v`, and VHDL also remain future exact-owner
work.
