# IAL2 Non-AXI Profile-Alias Readiness Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.544`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.544` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.545`, a non-AXI profile-alias readiness
audit after the public profile-alias chronology sync.

This selection is deliberately not another AXI implementation. `.axi` remains
the first shipped IAL2 profile-alias example, not the definition or full scope
of IAL2.

No parser behavior, generator behavior, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, non-AXI behavior, common construct
promotion, profile-alias suffix syntax, direct backend lowering, or VHDL
behavior changed.

## Evidence Read

The post-`.axi` public surface is now aligned:

- `.543` marks `.537` and `.538` wording as historical pre-`.540` state.
- `.540` ships only the bounded AXI AW Valid-Ready `.axi` alias.
- `.541` and `.542` keep current `.axi` lookup routed to the `.540` behavior
  fact and require a generality-aware owner before another behavior change.
- `.531` and `.535` already prove that IAL2 has protocol-neutral/non-AXI
  Valid-Ready `.ppif` samples outside AXI.
- Decision `0015` allows protocol-specific suffixes only as vocabulary/profile
  aliases over IAL2.
- Decision `0016` keeps `.ppif` as the first generic public IAL2 container.
- Decision `0017` keeps aggregate Valid-Ready bundles reviewable through
  generated `.isf` and `.fsm` artifacts before HDL.

The remaining unsupported profile-alias candidates are:

```text
.chi
.ace
.ahb
.apb
.atb
.smbus
.i2s
.pif
.ppi
```

The next safe step is not to choose one blindly. The next owner should audit
which non-AXI alias, if any, has enough source-shape, profile, report,
diagnostic, manifest, support-accounting, and mdBook evidence to become a
bounded contract candidate.

## Selected `.545` Scope

`.545` should audit non-AXI profile-alias readiness without accepting any new
suffix and without changing parser or generator behavior.

The audit should read the current suffix resolver/help/dispatch surfaces,
`FSM::Adapter::IAL2::PPIF` profile validation, `LanguageSurfaceSection`,
`RegressionCorpus`, existing `.ppif` neutral samples, current `.axi` alias
behavior, README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and
decisions `0015`, `0016`, and `0017`.

It should decide whether the next exact owner should be:

- a non-AXI profile-alias public contract selection;
- a generic profile-alias taxonomy or manifest prerequisite;
- a support-accounting/report prerequisite for non-AXI aliases;
- another protocol-neutral/profile-neutral `.ppif` prerequisite; or
- no non-AXI alias yet, with explicit evidence and a different bounded owner.

`.545` must not implement `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`,
`.i2s`, `.pif`, or `.ppi`; must not extend `.axi`; and must not promote common
IAL2 constructs without cross-profile evidence.

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
