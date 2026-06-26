# IAL2 Post Neutral Valid-Ready Bundle Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.536`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.536` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.537`, readiness audit for the IAL2
profile-alias file-surface contract.

The selector changes no parser behavior, generator behavior, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, non-AXI behavior, common construct
promotion, profile-alias suffix syntax, or VHDL behavior.

## Evidence Read

`.535` shipped `ppif/valid_ready_dual_channel_bundle.ppif` as the first
support-accounted protocol-neutral/non-AXI dual-channel Valid-Ready `.ppif`
bundle. The sample kept the generic `.ppif` container, explicit
`(profile valid-ready)`, mandatory `IAL2 -> IAL1 -> IAL0` lowering, generic
aggregate residue, and AXI AW/W residue preservation.

`.531` previously shipped `ppif/valid_ready_handshake.ppif` as the first
protocol-neutral/non-AXI one-channel Valid-Ready `.ppif` sample.

`.527` synchronized the public `.ppif` guardrail:

- `.ppif` is the generic Protocol/Platform Intent Format IAL2 container;
- AXI is the first shipped IAL2 profile/example, not the definition of IAL2;
- future protocol-specific suffixes such as `.axi`, `.chi`, `.ace`, `.ahb`,
  `.apb`, `.atb`, `.smbus`, or `.i2s` are profile aliases over IAL2 rather
  than separate layers;
- common IAL2 constructs stay small until compatible reuse is proven across
  multiple profiles; and
- every `.ppif` path lowers through generated `.isf` before generated `.fsm`.

Decision `0015` records profile-specific extensions as future vocabulary
aliases over the same IAL2 model. Decision `0016` selects `.ppif` as the first
public generic IAL2 container. Decision `0017` keeps multi-channel
Valid-Ready bundles reviewable through per-channel generated `.isf`/`.fsm`
artifacts and an aggregate bundle report.

The current file-surface implementation still accepts `.ppif` as the only
public IAL2 suffix. The capability manifest advertises
`unsupported_first_slice_aliases` including `.pif`, `.ppi`, `.axi`, `.chi`,
`.ace`, `.ahb`, `.apb`, and `.atb`, and the current boundary prose names
`.smbus` and `.i2s` as future profile aliases.

## Candidate Next Owners

Considered candidates:

- another protocol-neutral Valid-Ready example;
- common IAL2 construct promotion;
- returning to an AXI manager profile-local implementation slice;
- profile-alias readiness for future protocol-specific file suffixes.

The profile-alias readiness audit is the smallest next owner because the
public surface now repeatedly promises that profile-specific suffixes are
aliases over IAL2, but no exact audit has checked the CLI suffix resolver,
manifest surface, support-accounting identity, source-path reporting, and
lowering invariants for such aliases after both neutral `.ppif` examples
shipped.

This is not an `.axi` implementation selection. `.537` must audit the alias
contract generically before any suffix syntax or behavior changes.

## Selected `.537` Scope

`.537` should audit readiness for future IAL2 profile-alias file suffixes.
The audit should answer:

- which suffixes are in the first candidate set and which remain out of scope;
- whether the alias source should imply a profile, require an explicit
  `(profile ...)`, or support both under a compatibility rule;
- whether alias inputs preserve the same report schemas, support accounting,
  generated review artifacts, and source-path reporting as equivalent `.ppif`
  inputs;
- how manifest `unsupported_first_slice_aliases` should evolve if an alias
  becomes supported;
- how parser diagnostics should distinguish unknown suffix, unsupported alias,
  missing profile, and profile/source mismatch;
- how the mandatory `IAL2 -> IAL1 -> IAL0` chain remains enforced; and
- whether a future implementation should begin with one alias, an alias
  contract record, or another prerequisite.

The audit must not implement a suffix alias. It must not treat `.axi` as the
definition of IAL2, and it must not promote common queue/order/read-data
constructs without cross-profile evidence.

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

Rollback is documentation-only: remove this selection, its Knowledge Map fact,
task-tree advancement, README/ROADMAP_V2/mdBook sync, and Memory pointer. No
parser, generator, sample, support-accounting, runtime, generated HDL, or
backend artifact rollback is required.
