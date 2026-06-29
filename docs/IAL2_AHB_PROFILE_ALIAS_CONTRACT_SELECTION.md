# IAL2 AHB Profile-Alias Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.699`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.699` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.700`, bounded implementation of the first
AHB `.ahb` profile-alias suffix.

The selected alias is:

```text
.ahb
```

This is a bounded AHB profile alias over IAL2. It is not a separate language,
not an AHB-to-FSM shortcut, not a direct backend path, and not a broader AHB
behavior expansion.

This selector changes no parser behavior, generator behavior, public sample,
support-accounting catalog, capability-manifest behavior, schedule/check/
semantic JSON behavior, generated artifact, HDL/runtime behavior, backend
behavior, verification-output generation, backend-language variant, AXI
behavior, APB behavior, broader AHB behavior, direct backend lowering, or VHDL
behavior.

## Selected Contract

The first `.ahb` alias sample should mirror the shipped AHB `.ppif` requester
sample:

```text
ppif/ahb_requester.ppif
```

The new alias fixture path should be:

```text
ppif/ahb_requester.ahb
```

The source content must remain the same IAL2 `protocol-platform-intent` form
with an explicit AHB profile clause:

```text
(profile ahb)
```

The first `.ahb` implementation must not infer the profile from the suffix.
Keeping the explicit `(profile ahb)` clause preserves the `.axi` and `.apb`
precedent, keeps authored profile intent reviewable, and gives suffix/profile
mismatch diagnostics a precise source location. A missing `(profile ...)`
remains an error, and any non-AHB profile such as `(profile apb)`,
`(profile axi4)`, or `(profile valid-ready)` must be rejected as a `.ahb`
suffix/profile mismatch.

The first supported object is exactly one bounded AHB requester object:

```text
(ahb-requester amba_requester ...)
```

The object body, local command/status signals, AHB bus bindings, burst and
transfer semantics, response handling, generated `amba_requester.isf`,
generated `amba_requester.fsm`, AHB report schema, generated HDL module, and
unsupported residue remain equivalent to the shipped `.ppif` source.

## Required `.700` Implementation Boundaries

`.700` should implement only the `.ahb` alias for the selected AHB requester
fixture. It should:

- recognize `.ahb` in bare-name resolution and path dispatch without changing
  `.fsm`, `.isf`, `.ppif`, `.axi`, or `.apb` behavior;
- route `.ahb` sources through the same IAL2 PPIF lowering stack;
- allow `FSM::Adapter::IAL2::PPIF->parse_file` to read `.ahb` only as an AHB
  profile alias, with explicit `ahb` profile validation;
- keep `.ahb` lowering through generated `.isf` before generated `.fsm`;
- keep the generated review artifacts equivalent to the `.ppif` sample:
  `amba_requester.isf` and `amba_requester.fsm`;
- keep the generated HDL module `amba_requester`;
- keep the AHB IAL2 report schema
  `fsmgen.ial2.protocol_intent.ahb_requester.v1`;
- keep authored source paths visible as the `.ahb` path in check JSON,
  semantic JSON, schedule JSON, diagnostics, reports, and support-accounting
  evidence;
- update help text and direct-FSM basename stripping for `.ahb`;
- add `.ahb` as a shipped bounded profile-alias file surface in the capability
  manifest;
- remove `.ahb` from `unsupported_first_slice_aliases` while leaving `.pif`,
  `.ppi`, `.chi`, `.ace`, `.atb`, `.smbus`, and `.i2s` unsupported;
- support-account the alias fixture as `intent.ahb_profile_alias_requester`;
- use coverage key `ial2_ahb_profile_alias_requester_pipeline_cli`;
- use `source_kind => 'ial2_profile_alias'`; and
- add focused parser/CLI/manifest/support-accounting/docs tests and direct
  schedule/check/semantic/outdir probes for the alias.

The selected focused implementation test file is:

```text
t/1474-ial2-ahb-profile-alias.t
```

The existing focused AHB `.ppif` coverage in `t/1473-ial2-ahb-requester.t`
should keep locking the generic `.ppif` behavior and known unsupported aliases
that remain unsupported. The focused `.ahb` test should mirror the `.axi` and
`.apb` profile-alias test style: adapter equivalence, profile-mismatch
rejection, check JSON source identity, semantic JSON source identity, schedule
JSON source identity, support-accounting identity, capability-manifest
movement, and outdir review-artifact materialization.

## Diagnostics

`.700` should keep diagnostics distinct:

- unknown suffix: a suffix that is not a known source suffix;
- unsupported known alias: known but still unsupported aliases such as `.chi`,
  `.ace`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi`;
- missing profile: `.ahb` source has no `(profile ...)` clause;
- suffix/profile mismatch: `.ahb` source declares any profile other than
  `ahb`;
- unsupported `.ahb` object breadth: `.ahb` source requests Valid-Ready, AXI
  manager, APB requester/completer/composition, AHB completer/subordinate,
  AHB interconnect/decode, mixed objects, or more than one AHB requester
  object; and
- malformed AHB requester syntax: the selected AHB requester object exists but
  violates the AHB requester source-shape contract.

The first implementation may use focused error-text assertions instead of
stabilizing a new diagnostic-code family if the current CLI/report contracts do
not yet expose stable suffix-alias diagnostic codes.

## Public Contract

The `.ahb` alias is a public file-surface convenience over the same IAL2
semantics as the generic `.ppif` source. Equivalent `.ppif` and `.ahb`
requester inputs must preserve the same AHB behavior and review artifacts,
while still reporting the authored source path of the file the user ran.

The mandatory lowering chain remains:

```text
.ahb / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

Direct `.ahb -> .fsm`, direct `.ahb -> HDL`, direct IAL2-to-IAL0 lowering,
and direct backend lowering remain forbidden.

## Non-Goals

This contract selection does not implement `.ahb` and does not accept any new
source suffix. It does not add `.chi`, `.ace`, `.atb`, `.smbus`, `.i2s`,
`.pif`, or `.ppi`. It does not extend `.axi` or `.apb`, infer AHB profiles from
the suffix, add AHB completer/subordinate generation, add AHB interconnect or
decode generation, add AHB scoreboards, add full AHB manager behavior, add
alternate AHB widths, add alternate response policies, change `.ppif` AHB
behavior, change parser behavior, change generator behavior, change support
accounting, change schedule/check/semantic JSON behavior, change generated
artifacts, change HDL/runtime behavior, change backend behavior, change
verification-output generation, change backend-language variants, promote
common constructs, allow direct backend lowering, or change VHDL behavior.

## Validation

Closeout for this selector is documentation-only plus direct AHB behavior
reverification:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ppif
cp ppif/ahb_requester.ppif /tmp/fsmgen-699-ahb-requester.ahb
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-699-ahb-requester.ahb
./bin/fsmgen --quiet --capability-manifest
rm -f /tmp/fsmgen-699-ahb-requester.ahb
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

The `.ahb` probe is expected to fail closed until `.700` implements the
contract.

## Rollback

Rollback is documentation-only: remove this contract-selection document, its
Knowledge Map fact, task-tree advancement, README/ROADMAP_V2/mdBook sync, and
Memory pointer. No parser, manifest, generator, sample, support-accounting,
generated HDL, runtime, or backend artifact rollback is required.
