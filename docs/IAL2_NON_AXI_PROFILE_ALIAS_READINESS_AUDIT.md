# IAL2 Non-AXI Profile-Alias Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.545`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.545` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.546`, a non-AXI profile-alias taxonomy and
evidence prerequisite.

The audit does not select a direct `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`,
`.smbus`, or `.i2s` implementation. None of those suffixes has a settled
source shape, profile-matching rule, support-accounting entry, report contract,
or mdBook example yet.

No parser behavior, generator behavior, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, non-AXI behavior, common construct
promotion, profile-alias suffix syntax, direct backend lowering, or VHDL
behavior changed.

## Evidence Read

The live suffix resolver knows the non-AXI profile-alias candidates but rejects
them before PPIF parsing:

```text
.chi
.ace
.ahb
.apb
.atb
.smbus
.i2s
```

`bin/fsmgen` currently treats `.pif` and `.ppi` as known unsupported generic
container candidates, not protocol-profile aliases. The PPIF dispatch path only
enters IAL2 lowering for `.ppif` and the first shipped `.axi` profile alias.

`FSM::Adapter::IAL2::PPIF` currently accepts readable `.ppif` or `.axi` files.
Its profile-alias contract validation is `.axi`-specific: `.axi` requires an
explicit AXI-family profile (`axi`, `axi3`, `axi4`, or `axi5`) and rejects
non-AXI profiles such as `valid-ready`.

`LanguageSurfaceSection` advertises shipped suffixes:

```text
.fsm
.isf
.ppif
.axi
```

It also records `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, `.i2s`,
`.pif`, and `.ppi` as unsupported. `RegressionCorpus` support-accounts the
first `.axi` profile-alias sample as `intent.axi_profile_alias_aw_valid_ready`,
but there is no non-AXI profile-alias support-accounted fixture.

Existing non-AXI IAL2 evidence is real but not a protocol suffix contract:

- `.531` ships the protocol-neutral/non-AXI `(profile valid-ready)`
  one-channel `.ppif` sample.
- `.535` ships the protocol-neutral/non-AXI `(profile valid-ready)`
  dual-channel `.ppif` bundle.
- Those samples prove that IAL2 is not AXI-only, but they do not define a
  `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, or `.i2s` source shape.

## Readiness Finding

The next non-AXI work must classify candidates before selecting an alias
contract. Choosing a protocol suffix now would be a blind implementation
selection because the repository has no source-shape evidence, profile-name
rule, expected diagnostics, report/support-accounting identity, or runnable
book example for any non-AXI protocol alias.

The generic candidates `.pif` and `.ppi` also need to stay separate from
protocol aliases. They are broad container candidates, while `.chi`, `.ace`,
`.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` are protocol-profile alias
candidates over IAL2.

## Selected `.546` Scope

`.546` should create a non-AXI profile-alias taxonomy and evidence prerequisite
before any non-AXI alias contract selection.

The prerequisite should:

- separate generic-container candidates `.pif` and `.ppi` from protocol-profile
  aliases;
- classify `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` by
  evidence currently present in the repo;
- identify which candidate, if any, has enough source-shape and report evidence
  to become a future public contract selection;
- record missing prerequisites for candidates without evidence;
- keep `.ppif` as the generic IAL2 container and `.axi` as only the first
  shipped profile-alias example; and
- avoid parser/generator/sample/support-accounting changes.

`.546` must not accept any new suffix, extend `.axi`, add a sample, alter the
capability manifest, add support-accounting entries, change JSON behavior, or
promote common IAL2 constructs.

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
