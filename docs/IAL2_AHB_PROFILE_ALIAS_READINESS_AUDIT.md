# IAL2 AHB Profile-Alias Readiness Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.698`
- Date: `2026-06-29`
- Status: selected
- Scope: no-behavior readiness audit for bounded AHB `.ahb` profile-alias work

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.698` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.699`, AHB `.ahb` public profile-alias
contract selection, as the next exact owner.

The selected next owner is still not implementation. It must write the public
file-surface contract before any `.ahb` parser, generator, sample, manifest,
support-accounting, check JSON, semantic JSON, HDL, verification-output,
backend, or runtime behavior changes.

No parser behavior, generator behavior, public source, support-accounting
catalog, capability-manifest behavior, test behavior, schedule/check/semantic
JSON behavior, generated artifact, HDL/runtime behavior, direct backend
lowering, verification-output generation, backend-language variant, AXI
behavior, APB behavior, broader AHB behavior, or VHDL behavior changed.

## Evidence Read

The AHB source-shape sequence is now coherent:

- `.695` selected generic AHB requester `.ppif` contract selection before any
  AHB behavior.
- `.696` selected the first bounded AHB requester source shape:
  `ppif/ahb_requester.ppif` with `(profile ahb)` and exactly one
  `(ahb-requester amba_requester ...)` object.
- `.697` shipped that generic `.ppif` behavior through generated
  `amba_requester.isf` before generated `amba_requester.fsm`, with HDL module
  `amba_requester`, report schema
  `fsmgen.ial2.protocol_intent.ahb_requester.v1`, and support-accounting entry
  `intent.ppif_ahb_requester` using `source_kind ppif`.

The live AHB `.ppif` probes confirm the shipped behavior:

- `--strict --check --json ppif/ahb_requester.ppif` succeeds and reports
  `module_name = amba_requester`, `entry_id = intent.ppif_ahb_requester`,
  `source_kind = ppif`, and coverage
  `ial2_ppif_ahb_requester_pipeline_cli`.
- `--emit-schedule-json ppif/ahb_requester.ppif` reports schema
  `fsmgen.ial2.protocol_intent.ahb_requester.v1`, target protocol profile
  `ahb`, object `ahb-requester`, mode `requester`, generated IAL1
  `amba_requester.isf`, generated IAL0 `amba_requester.fsm`, and residue id
  `ahb_profile_alias_deferred`.
- `--strict --emit-semantic-json ppif/ahb_requester.ppif` succeeds and reports
  generated semantic root kind `fsm` for module `amba_requester`.
- The same source copied to a temporary `.ahb` path fails closed with
  `source suffix '.ahb' is a known IAL2 alias candidate but is not supported in
  this slice`.

The code and manifest surfaces keep the same boundary:

- `bin/fsmgen` still includes `.ahb` in `unsupported_ial2_alias_suffix`, while
  the supported IAL2 parse path accepts `.ppif`, `.axi`, and `.apb`.
- `FSM::Adapter::IAL2::PPIF->parse_file` accepts `.ppif`, `.axi`, and `.apb`,
  not `.ahb`.
- `LanguageSurfaceSection` lists `.ahb` in
  `unsupported_first_slice_aliases`; shipped suffixes remain `.fsm`, `.isf`,
  `.ppif`, `.axi`, and `.apb`.
- The `.697` AHB report explicitly carries `ahb_profile_alias_deferred`
  residue.
- Decision `0015` allows protocol-specific suffixes such as `.ahb` only as
  profile aliases over IAL2, not separate layers and not direct-lowering
  shortcuts. Decision `0016` keeps `.ppif` as the first generic IAL2
  container.

## Readiness Finding

AHB is ready for `.ahb` public profile-alias contract selection, not direct
`.ahb` implementation in this slice.

The positive evidence is the shipped bounded AHB requester `.ppif` path. It
already exercises an AHB profile, AHB requester object vocabulary, source
anchors, report schema, support-accounted check/semantic identity, generated
`.isf` review artifacts, generated `.fsm` review artifacts, and generated HDL.
That is enough to write an alias contract without inventing alias behavior in
the same slice.

Direct `.ahb` implementation still needs a separate contract because the alias
surface must settle public file-surface details that generic `.ppif` does not
answer by itself:

- whether `.ahb` keeps explicit `(profile ahb)` or infers it from the suffix;
- how suffix/profile mismatch diagnostics differ from known unsupported alias
  and unknown suffix diagnostics;
- whether the first support identity mirrors `.axi`/`.apb` precedent with an
  alias-specific id such as `intent.ahb_profile_alias_requester`;
- whether support accounting uses `source_kind => 'ial2_profile_alias'`;
- how check JSON, semantic JSON, schedule JSON, diagnostics, reports, and
  generated review artifacts preserve the authored `.ahb` source path while
  still lowering through generated `.isf` before generated `.fsm`;
- how the capability manifest should move `.ahb` from
  `unsupported_first_slice_aliases` into shipped profile aliases after the
  future implementation; and
- which AHB object breadth remains fail-closed beyond the bounded requester.

Another AHB `.ppif` behavior slice is not required before contract selection.
AHB completers/subordinates, interconnect/decode, scoreboards, full-manager
behavior, direct backend behavior, verification-output generation,
backend-language variants, and VHDL remain real AHB residue, but none blocks
selecting the alias contract for the already shipped requester source.

## Selected `.699` Scope

`.699` should select the AHB `.ahb` public profile-alias contract before any
behavior change.

The contract-selection owner should define:

- `.ahb` as an IAL2 profile alias over the same `protocol-platform-intent`
  model, not a new layer and not an AHB-to-FSM shortcut.
- The first alias source shape for the bounded requester, expected to mirror
  `ppif/ahb_requester.ppif` at a future `.ahb` sample path.
- The explicit profile policy, with `(profile ahb)` preserved unless the
  contract deliberately selects and justifies profile inference.
- Equivalent `.ppif` and `.ahb` requester lowering through generated
  `amba_requester.isf` before generated `amba_requester.fsm`.
- Authored `.ahb` source-path identity in schedule/check/semantic JSON,
  diagnostics, reports, and support-accounting evidence.
- Alias support-accounting identity and `source_kind`, with `.axi` and `.apb`
  as the precedent for `ial2_profile_alias`.
- Capability-manifest wording for shipped suffixes and unsupported aliases
  after the future implementation.
- Distinct diagnostics for missing profile, suffix/profile mismatch,
  unsupported AHB object breadth, known unsupported aliases, unknown suffixes,
  and malformed AHB requester syntax.

`.699` must not accept `.ahb`, must not add `.ahb` samples, must not add
support-accounting entries, and must not change parser, generator, manifest,
schedule/check/semantic JSON, HDL, runtime, backend, verification-output, AXI,
APB, broader AHB behavior, direct backend lowering, or VHDL behavior.

## Validation

This audit closeout uses documentation and direct behavior probes:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ppif
cp ppif/ahb_requester.ppif /tmp/fsmgen-698-ahb-requester.ahb
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-698-ahb-requester.ahb
./bin/fsmgen --quiet --capability-manifest
rm -f /tmp/fsmgen-698-ahb-requester.ahb /tmp/fsmgen-698-ahb-requester.stderr
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

The `.ahb` probe is expected to fail closed with the known unsupported alias
diagnostic.

## Rollback

Rollback is documentation-only: remove this audit note, its Knowledge Map fact,
the `.699` task-tree owner, README/ROADMAP_V2/mdBook sync if present, and
Memory pointer. No parser, generator, sample, support-accounting catalog,
generated HDL, runtime behavior, or backend artifact rollback is required.
