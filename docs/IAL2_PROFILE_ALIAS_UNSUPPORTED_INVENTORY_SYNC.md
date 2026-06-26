# IAL2 Profile-Alias Unsupported Inventory Sync

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.538`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.538` synchronizes the public
language-surface unsupported-alias inventory with the IAL2 profile-alias
boundary prose.

The capability manifest now lists these unsupported first-slice aliases:

```text
.pif
.ppi
.axi
.chi
.ace
.ahb
.apb
.atb
.smbus
.i2s
```

`.pif` and `.ppi` remain unsupported generic-container candidates. `.axi`,
`.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` remain
unsupported future profile-alias candidates over IAL2.

## Behavior Boundary

No profile-alias suffix is accepted by this slice. The shipped source suffixes
remain:

```text
.fsm
.isf
.ppif
```

The CLI resolver, PPIF parser, PPIF samples, support-accounting catalog,
schedule/check/semantic JSON behavior outside the manifest inventory,
generated artifacts, HDL/runtime behavior, backend behavior, verification-output
generation, backend-language variants, AXI behavior, non-AXI behavior, common
construct promotion, direct backend lowering, and VHDL behavior remain
unchanged.

This slice changes only the public capability-manifest language-surface
inventory and focused manifest expectations.

## Rationale

`.537` found that the manifest prose already named `.smbus` and `.i2s` as
future profile aliases, but `unsupported_first_slice_aliases` omitted them. That
created an inventory drift inside the public manifest surface even though no
suffix behavior was shipped.

Synchronizing the unsupported inventory first keeps the public contract honest
before any future profile-alias implementation selects syntax, diagnostics,
source-path reporting, support accounting, or profile matching rules.

## Next Owner

`IAL2-FEATURE-COMPLETENESS-FRONTIER.539` should select the public contract for
the first IAL2 profile-alias suffix. It should decide:

- the exact first alias suffix, without treating that suffix as the whole of
  IAL2;
- whether the alias requires explicit `(profile ...)`, implies a profile, or
  requires both an implied suffix profile and an explicit matching profile;
- how unsupported alias, unknown suffix, missing profile, and profile mismatch
  diagnostics are reported;
- how authored alias source paths appear in schedule/check/semantic JSON and
  generated review artifact metadata;
- how support accounting names any first alias fixture; and
- how the mandatory `IAL2 -> IAL1 -> IAL0` lowering chain remains visible.

## Validation

The slice is covered by:

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

Rollback is public manifest and documentation only: remove `.smbus` and `.i2s`
from `unsupported_first_slice_aliases`, restore the focused manifest test
expectations, remove this document and its Knowledge Map fact, and restore the
task-tree/Memory/README/ROADMAP_V2/mdBook pointers. No parser, generator,
sample, support-accounting, generated HDL, runtime, or backend artifact rollback
is required.
