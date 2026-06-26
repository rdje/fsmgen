# IAL2 APB Profile-Alias Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.553`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.553` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.554`, direct bounded implementation of the
first APB `.apb` profile-alias suffix.

The selected alias is:

```text
.apb
```

This is a bounded APB profile alias over IAL2. It is not a separate language,
not an APB-to-FSM shortcut, not a direct backend path, and not a broader APB
behavior expansion.

This selector changes no parser behavior, generator behavior, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, APB behavior, non-AXI behavior, common
construct promotion, generic-container alias syntax, direct backend lowering,
or VHDL behavior.

## Selected Contract

The first `.apb` alias sample should mirror the shipped APB `.ppif`
requester-transfer sample:

```text
ppif/apb_requester_transfer.ppif
```

The new alias fixture path should be:

```text
ppif/apb_requester_transfer.apb
```

The source content must remain the same IAL2 `protocol-platform-intent` form
with an explicit APB profile clause:

```text
(profile apb)
```

The first `.apb` implementation must not infer the profile from the suffix.
Keeping the explicit `(profile apb)` clause preserves the `.axi` precedent,
keeps authored profile intent reviewable, and gives suffix/profile mismatch
diagnostics a precise source location. A missing `(profile ...)` remains an
error, and any non-APB profile such as `(profile axi4)` or
`(profile valid-ready)` must be rejected as a `.apb` suffix/profile mismatch.

The first supported object is exactly one APB requester-transfer object:

```text
(apb-requester apb_requester ...)
```

The object body, local signals, APB bus bindings, transfer phase semantics,
latency bounds, generated `apb_requester.isf`, generated
`apb_requester.fsm`, APB report schema, generated HDL module, and unsupported
residue remain equivalent to the shipped `.ppif` source.

## Required `.554` Implementation Boundaries

`.554` should implement only the `.apb` alias for the selected APB
requester-transfer fixture. It should:

- recognize `.apb` in bare-name resolution and path dispatch without changing
  `.fsm`, `.isf`, `.ppif`, or `.axi` behavior;
- route `.apb` sources through the same IAL2 PPIF lowering stack;
- allow `FSM::Adapter::IAL2::PPIF->parse_file` to read `.apb` only as an APB
  profile alias, with explicit `apb` profile validation;
- keep `.apb` lowering through generated `.isf` before generated `.fsm`;
- keep the generated review artifacts equivalent to the `.ppif` sample:
  `apb_requester.isf` and `apb_requester.fsm`;
- keep the generated HDL module `apb_requester`;
- keep the APB IAL2 report schema
  `fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`;
- keep authored source paths visible as the `.apb` path in check JSON,
  semantic JSON, diagnostics, and support-accounting evidence;
- update help text and direct-FSM basename stripping for `.apb`;
- add `.apb` as a shipped bounded profile-alias file surface in the capability
  manifest;
- remove `.apb` from `unsupported_first_slice_aliases` while leaving `.pif`,
  `.ppi`, `.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`, and `.i2s` unsupported;
- support-account the alias fixture as
  `intent.apb_profile_alias_requester_transfer`;
- use coverage key `ial2_apb_profile_alias_requester_transfer_pipeline_cli`;
- use `source_kind => 'ial2_profile_alias'`; and
- add focused parser/CLI/manifest/support-accounting/docs tests and direct
  schedule/check/semantic/outdir probes for the alias.

The selected focused implementation test file is:

```text
t/1470-ial2-apb-profile-alias.t
```

The existing broad APB `.ppif` coverage in `t/1436-ial2-ppif-parser-cli.t`
should keep locking the generic `.ppif` behavior and known unsupported aliases
that remain unsupported. The focused `.apb` test should mirror the `.axi`
profile-alias test style: adapter equivalence, profile-mismatch rejection,
check JSON source identity, semantic JSON source identity, schedule JSON, and
outdir review-artifact materialization.

## Diagnostics

`.554` should keep diagnostics distinct:

- unknown suffix: a suffix that is not a known source suffix;
- unsupported known alias: known but still unsupported aliases such as `.chi`,
  `.ace`, `.ahb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi`;
- missing profile: `.apb` source has no `(profile ...)` clause;
- suffix/profile mismatch: `.apb` source declares any profile other than
  `apb`;
- unsupported `.apb` object breadth: `.apb` source requests Valid-Ready,
  AXI manager, bundle, APB completer, interconnect, mixed objects, or more than
  one APB requester-transfer object; and
- malformed APB requester-transfer syntax: the selected APB object exists but
  violates the APB requester-transfer source-shape contract.

The first implementation may use focused error-text assertions instead of
stabilizing a new diagnostic-code family if the current CLI/report contracts do
not yet expose stable suffix-alias diagnostic codes.

## Public Contract

The `.apb` alias is a public file-surface convenience over the same IAL2
semantics as the generic `.ppif` source. Equivalent `.ppif` and `.apb`
requester-transfer inputs must preserve the same APB behavior and review
artifacts, while still reporting the authored source path of the file the user
ran.

The mandatory lowering chain remains:

```text
.apb / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

Direct `.apb -> .fsm`, direct `.apb -> HDL`, direct IAL2-to-IAL0 lowering,
and direct backend lowering remain forbidden.

## Non-Goals

This contract selection does not implement `.apb` and does not accept any new
source suffix. It does not add `.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`,
`.i2s`, `.pif`, or `.ppi`. It does not extend `.axi`, infer APB profiles from
the suffix, add APB completer/interconnect generation, add APB sidebands, add
alternate widths, add multi-peripheral decode, add back-to-back transfer
policy, change `.ppif` APB behavior, change AXI behavior, change parser
behavior, change generator behavior, change support accounting, change
schedule/check/semantic JSON behavior, change generated artifacts, change
HDL/runtime behavior, change backend behavior, change verification-output
generation, change backend-language variants, promote common constructs, allow
direct backend lowering, or change VHDL behavior.

## Validation

Closeout for this selector is documentation-only plus direct APB behavior
reverification:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_requester_transfer.ppif
cp ppif/apb_requester_transfer.ppif /tmp/fsmgen-apb-requester-transfer.apb
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-apb-requester-transfer.apb
rm -f /tmp/fsmgen-apb-requester-transfer.apb
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

The `.apb` probe is expected to fail closed until `.554` implements the
contract.

## Rollback

Rollback is documentation-only: remove this contract-selection document, its
Knowledge Map fact, task-tree advancement, README/ROADMAP_V2/mdBook sync, and
Memory pointer. No parser, manifest, generator, sample, support-accounting,
generated HDL, runtime, or backend artifact rollback is required.
