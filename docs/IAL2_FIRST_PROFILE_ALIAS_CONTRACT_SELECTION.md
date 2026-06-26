# IAL2 First Profile-Alias Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.539`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.539` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.540`, direct bounded implementation of the
first IAL2 profile-alias suffix.

The first alias suffix is:

```text
.axi
```

This is a first profile-alias example only. It does not make AXI the definition
of IAL2, it does not select `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`,
or `.i2s`, and it does not grant direct IAL2-to-IAL0 lowering.

## Selected Contract

The first `.axi` alias sample should mirror the already shipped first AXI
profile `.ppif` sample:

```text
ppif/axi_aw_valid_ready.ppif
```

The new alias fixture path should be:

```text
ppif/axi_aw_valid_ready.axi
```

The source content should remain a generic IAL2 `protocol-platform-intent` form
with an explicit AXI-family profile clause. The first sample keeps:

```text
(profile axi4)
```

The `.axi` suffix is therefore a profile-alias file surface over IAL2, not a
separate parser language. A `.axi` source must still declare a profile. The
accepted `.axi` profile family is the existing AXI profile family recognized by
the Valid-Ready IAL2 generator:

```text
axi
axi3
axi4
axi5
```

For the first implementation, a missing `(profile ...)` remains an error, and a
non-AXI-family profile such as `(profile valid-ready)` must be rejected as a
suffix/profile mismatch.

## Required `.540` Implementation Boundaries

`.540` should implement only the `.axi` alias for the selected AXI AW
Valid-Ready fixture. It should:

- recognize `.axi` in bare-name resolution and path dispatch without changing
  `.fsm`, `.isf`, or `.ppif` behavior;
- route `.axi` sources through the same IAL2 PPIF lowering stack;
- allow `FSM::Adapter::IAL2::PPIF->parse_file` to read `.axi` only as an AXI
  profile alias, with explicit AXI-family profile validation;
- keep `.axi` lowering through generated `.isf` before generated `.fsm`;
- keep report schemas and generated artifacts equivalent to the `.ppif` sample;
- keep authored source paths visible as the `.axi` path in CLI/report shells;
- update help text and direct-FSM basename stripping for `.axi`;
- add `.axi` as a shipped profile-alias file surface in the capability manifest;
- remove `.axi` from `unsupported_first_slice_aliases` while leaving `.pif`,
  `.ppi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s`
  unsupported;
- support-account the alias fixture as `intent.axi_profile_alias_aw_valid_ready`;
- use coverage key `ial2_axi_profile_alias_aw_valid_ready_pipeline_cli`;
- use `source_kind => 'ial2_profile_alias'`; and
- add focused parser/CLI/manifest/support-accounting/docs tests and direct
  schedule/check/semantic probes for the alias.

The alias fixture should continue to generate the same monitor module:

```text
axi_aw_valid_ready_monitor
```

## Diagnostics

`.540` should keep diagnostics distinct:

- unknown suffix: not a known source suffix;
- unsupported known alias: known but not accepted in this slice;
- missing profile: `.axi` source has no `(profile ...)` clause;
- suffix/profile mismatch: `.axi` source declares a non-AXI-family profile; and
- unsupported AXI behavior: syntax is accepted but requested behavior remains
  outside the existing AXI Valid-Ready subset.

The first implementation may use focused error-text assertions instead of
stabilizing a new diagnostic-code family if the existing CLI/report contracts do
not yet expose one for suffix aliases.

## Non-Goals

This contract selection does not implement `.axi` and does not accept any new
source suffix. It does not add `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`,
`.smbus`, `.i2s`, `.pif`, or `.ppi`. It does not change parser behavior,
generator behavior, PPIF samples, support accounting, schedule/check/semantic
JSON behavior, generated artifacts, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variants, common construct
promotion, AXI generated behavior, non-AXI behavior, direct backend lowering, or
VHDL behavior.

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

Rollback is documentation-only: remove this contract-selection document, its
Knowledge Map fact, task-tree advancement, README/ROADMAP_V2/mdBook sync, and
Memory pointer. No parser, manifest, generator, sample, support-accounting,
generated HDL, runtime, or backend artifact rollback is required.
