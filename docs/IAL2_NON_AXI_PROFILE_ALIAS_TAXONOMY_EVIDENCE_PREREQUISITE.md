# IAL2 Non-AXI Profile-Alias Taxonomy Evidence Prerequisite

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.546`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.546` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.547`, a generic-container alias policy
selection for `.pif` and `.ppi`.

The taxonomy separates three different categories that were previously listed
together as unsupported suffix candidates:

- `.ppif` is the shipped generic IAL2 container.
- `.pif` and `.ppi` are generic-container spelling candidates, not protocol
  profile aliases.
- `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` are
  protocol-profile alias candidates over IAL2.

No parser behavior, generator behavior, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, non-AXI behavior, common construct
promotion, profile-alias suffix syntax, direct backend lowering, or VHDL
behavior changed.

## Evidence Read

Decision `0015` keeps IAL2 as one architectural layer and allows future
protocol-specific suffixes only as vocabulary/profile aliases over IAL2. It
also lists `.pif`, `.ppi`, and `.ppif` as generic protocol/platform container
candidates.

Decision `0016` selects `.ppif` as the first public generic IAL2 container.
It leaves `.pif` and `.ppi` as historical candidates, not accepted aliases in
the first public implementation unless a later exact owner selects them.

Decision `0017` selects aggregate Valid-Ready bundle reporting over generated
per-channel `.isf` and `.fsm` review artifacts. It does not create another
suffix.

The live CLI resolver currently knows `.pif`, `.ppi`, `.chi`, `.ace`, `.ahb`,
`.apb`, `.atb`, `.smbus`, and `.i2s`, but rejects all of them before PPIF
parsing with the known-unsupported-alias diagnostic. The PPIF pipeline still
dispatches only `.ppif` and `.axi`.

`FSM::Adapter::IAL2::PPIF` accepts readable `.ppif` and `.axi` files. Its only
profile-alias validation is `.axi`-specific: `.axi` requires an AXI-family
profile and rejects non-AXI profiles such as `valid-ready`.

`LanguageSurfaceSection` advertises shipped suffixes:

```text
.fsm
.isf
.ppif
.axi
```

The manifest boundary describes `.ppif` as generic IAL2, `.axi` as the first
profile-alias example, and the remaining suffixes as unsupported.

## Taxonomy

| Suffix or profile | Category | Evidence now present | Readiness |
| --- | --- | --- | --- |
| `.ppif` | Shipped generic IAL2 container | Parser, CLI dispatch, manifest, samples, support accounting, mdBook examples | Already shipped; not a profile alias. |
| `.axi` | Shipped protocol-profile alias | `.axi` sample, AXI-family profile validation, support accounting, manifest, mdBook examples | First profile-alias example only. |
| `(profile valid-ready)` under `.ppif` | Protocol-neutral/non-AXI IAL2 profile | One-channel and dual-channel `.ppif` samples, reports, support accounting, mdBook examples | Proves IAL2 is not AXI-only, but is not a suffix contract. |
| `.pif` | Generic-container spelling candidate | Decision `0016` historical candidate status and existing `.ppif` source shape | Needs policy selection before any alias behavior. |
| `.ppi` | Generic-container spelling candidate | Decision `0016` historical candidate status and existing `.ppif` source shape | Needs policy selection before any alias behavior. |
| `.chi` | Protocol-profile alias candidate | Name is reserved as unsupported; no repo source shape, profile rule, report, support accounting, or book example | Not ready for contract selection. |
| `.ace` | Protocol-profile alias candidate | Name is reserved as unsupported; no repo source shape, profile rule, report, support accounting, or book example | Not ready for contract selection. |
| `.ahb` | Protocol-profile alias candidate | Name is reserved as unsupported; no repo source shape, profile rule, report, support accounting, or book example | Not ready for contract selection. |
| `.apb` | Protocol-profile alias candidate | Name is reserved as unsupported; no repo source shape, profile rule, report, support accounting, or book example | Not ready for contract selection. |
| `.atb` | Protocol-profile alias candidate | Name is reserved as unsupported; no repo source shape, profile rule, report, support accounting, or book example | Not ready for contract selection. |
| `.smbus` | Protocol-profile alias candidate | Name is reserved as unsupported; no repo source shape, profile rule, report, support accounting, or book example | Not ready for contract selection. |
| `.i2s` | Protocol-profile alias candidate | Name is reserved as unsupported; no repo source shape, profile rule, report, support accounting, or book example | Not ready for contract selection. |

## Required Evidence Before Protocol Suffix Selection

A future non-AXI protocol-profile suffix owner needs evidence in the repo
before selecting implementation. The minimum prerequisite set is:

- an authored generic `.ppif` source shape or exact proposed alias source shape;
- the intended profile name or profile-name family;
- the suffix-to-profile matching rule and mismatch diagnostic;
- expected source-anchor and residue/report fields;
- generated `.isf` and `.fsm` review artifact expectations;
- support-accounting id, coverage key, and support tier;
- focused parser/CLI, report, support-accounting, and capability-manifest
  checks; and
- mdBook examples that show the runnable source and commands.

The current repository has those ingredients for `.ppif`, `.axi`, and the
protocol-neutral `valid-ready` profile under `.ppif`. It does not have them for
`.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, or `.i2s`.

## Selected `.547` Scope

`.547` should select the policy for `.pif` and `.ppi` as generic-container
candidates before any implementation owner accepts either suffix.

The selector should decide whether `.pif` and `.ppi` should:

- remain explicitly unsupported historical spellings;
- become documentation-only reserved names;
- select one future exact alias over the `.ppif` source shape; or
- require more generic-container evidence before a behavior contract.

`.547` must not accept `.pif`, `.ppi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`,
`.smbus`, or `.i2s`; must not extend `.axi`; must not add samples or
support-accounting entries; and must not change parser, generator, manifest,
schedule/check/semantic JSON, HDL, runtime, backend, verification-output, or
VHDL behavior.

## Validation

Closeout for this taxonomy prerequisite is documentation-only:

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

Rollback is documentation-only: remove this taxonomy document, its Knowledge
Map fact, task-tree advancement, README/ROADMAP_V2/mdBook sync, and Memory
pointer. No parser, generator, sample, support-accounting, generated HDL,
runtime, or backend artifact rollback is required.
