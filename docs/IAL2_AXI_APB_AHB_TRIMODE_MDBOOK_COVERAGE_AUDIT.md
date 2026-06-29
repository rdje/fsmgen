# IAL2 AXI/APB/AHB Tri-Mode mdBook Coverage Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.689`
- Date: `2026-06-29`
- Status: selected
- Scope: documentation contract and next executable leaves for IAL2 AXI, APB,
  and AHB mdBook coverage

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.689` selects four documentation-only
follow-on leaves:

- `.690`: scaffold a new mdBook IAL2 protocol/platform intent chapter and
  tri-mode navigation map.
- `.691`: add AXI tri-mode mdBook coverage.
- `.692`: add APB tri-mode mdBook coverage.
- `.693`: add AHB current-state and future IAL2 tri-mode boundary coverage.

This audit changes no parser behavior, generator behavior, public source,
support-accounting catalog entry, capability-manifest behavior, generated
artifact, check JSON, semantic JSON, schedule JSON, HDL/runtime behavior,
protocol behavior, suffix acceptance, direct backend behavior,
verification-output behavior, backend-language variant, AXI behavior, APB
behavior, AHB behavior, or VHDL behavior.

## Evidence Read

This audit read the current bootstrap and continuity surfaces (`README.md`,
`MEMORY.md`, `MEMORY_ARCHITECTURE.md`, `COMMIT.md`,
`DOCTRINE_ENFORCEMENT.md`, `TOOLBOX.md`), task-tree surfaces
(`docs/TASK_TREE.md`, `docs/TASK_TREE_README.md`, and the active
`IAL2-FEATURE-COMPLETENESS-FRONTIER` frontier), roadmap status in
`ROADMAP_V2.md`, the mdBook table of contents and IAL2-adjacent chapters
(`docs/book/src/SUMMARY.md`, `docs/book/src/14-feature-backlog.md`,
`docs/book/src/15-implementation-blueprint.md`,
`docs/book/src/15a-ial2-new-protocol-support.md`), relevant decisions
(`0003`, `0005`, `0006`, `0007`, `0014` through `0018`), Knowledge Map
routes and fact cards, the support-accounting catalog, public examples under
`ppif/`, the IAL2 parser and protocol-intent implementation entrypoints, and
the direct AMBA/AHB `.fsm` seed.

The exact implementation entrypoints audited were:

- `bin/fsmgen`
- `perl/FSM/Adapter/IAL2/PPIF.pm`
- `perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm`
- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm`
- `perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm`
- `perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm`
- `perl/FSM/Support/RegressionCorpus.pm`
- `perl/FSM/Support/LanguageSurfaceSection.pm`

## Current Shipped Boundary

IAL2 remains protocol/platform intent over the mandatory lowering chain:

```text
IAL2 source -> generated IAL1 .isf -> generated IAL0 .fsm -> HDL
```

The mdBook coverage must present source syntax, generated review artifacts,
reports, diagnostics, examples, and residue as backend-language-neutral public
contracts. Perl module names may appear only as current reference
implementation entrypoints.

### AXI

The shipped AXI IAL2 surface is substantial but still bounded. The checked-in
example inventory currently contains 142 `ppif/axi_*.ppif` examples and one
`.axi` profile alias, `ppif/axi_aw_valid_ready.axi`. The current AXI IAL2
implementation surfaces are:

- generic `.ppif` sources with explicit AXI-family profiles;
- the selected `.axi` profile alias for the AXI AW Valid-Ready first example;
- Valid-Ready channel and bundle reports;
- AXI manager capacity/status, ID-family, transaction, event-dispatch,
  auto-ID, response-demux, read-data, burst-length, runtime-validation,
  multi-beat, same-ID ordering, queue-head, dynamic ID, mixed dynamic/static,
  release-and-recapture, and issue-order queue families through bounded public
  samples;
- check JSON, semantic JSON, schedule JSON, `--outdir`, HDL, support-accounting,
  and focused regression coverage.

AXI is the first shipped IAL2 profile/example, not the definition of IAL2.
Full AXI manager behavior, arbitrary cardinalities, complete per-ID queues,
scoreboards, queued/blocking policy beyond selected queue families, direct
backend behavior, verification-output generation, backend-language variants,
and VHDL remain task-tree-owned residue.

### APB

The shipped APB IAL2 surface is broad and example-heavy. The checked-in
example inventory currently contains 57 `ppif/apb_*.ppif` examples and 57
byte-identical `.apb` profile aliases. The current APB IAL2 implementation
surfaces are:

- generic `.ppif` sources with explicit `(profile apb)`;
- selected `.apb` profile aliases over the same IAL2 layer;
- requester transfer, busy/status outputs, sideband `PPROT`/`PSTRB`,
  sideband data16, completer generation, multi-register decode,
  register-local protection policy, fixed requester/completer composition,
  generated multi-peripheral interconnect/decode, and selected back-to-back
  timing families;
- bounded generalized `reg0..regN` register-set multi-peripheral timing up to
  the selected five-register and six-register slices;
- check JSON, semantic JSON, schedule JSON, `--outdir`, HDL, support-accounting,
  capability/language-surface advertising, and focused APB regression coverage.

APB remains protocol-specific. Its generated interconnect/decode logic must not
be documented as shared with AXI or AHB. More-than-six-register families,
more-than-two peripheral completers, broader protection/data-width matrices,
bus matrices, scoreboards, direct backend behavior, verification-output
generation, backend-language variants, AXI, AHB, and VHDL remain deferred.

### AHB

AHB has a support-accounted direct `.fsm` protocol seed at
`fsm/amba_requester.fsm` under corpus identity `protocol.amba_requester`.
That source is an IAL0/direct FSMGen fixture for a bounded AMBA AHB
requester/master model.

AHB does not currently have an IAL2 protocol-intent implementation:

- no `ppif/*ahb*` or `*.ahb` public examples are checked in;
- no `FSM::IAL2::ProtocolIntent::Ahb*` module exists;
- `.ahb` is a known future alias suffix in `bin/fsmgen`, but
  `unsupported_ial2_alias_suffix` rejects it today;
- no generated IAL1 `.isf` or generated IAL0 `.fsm` review-artifact chain is
  selected for AHB IAL2.

The mdBook must therefore document AHB honestly as current direct `.fsm` AMBA
requester coverage plus future IAL2 work. It must not imply that `.ahb`,
AHB `.ppif`, AHB profile aliases, AHB generated IAL1, AHB generated IAL0, AHB
interconnect/decode, AHB scoreboards, or AHB full-manager behavior are shipped.

## Tri-Mode Documentation Contract

The follow-on mdBook work must explain each protocol through the same three
modes without inventing behavior:

- User-friendly guided mode: the smallest runnable public source shape for a
  new user, with the generated review artifacts and one or two canonical
  commands shown before optional knobs.
- More-control mode: the selected public clauses that expose meaningful knobs,
  static validation, report fields, or bounded policy choices while staying
  inside shipped examples.
- Raw/full-control mode: the deepest shipped explicit IAL2 source surface for
  that protocol, including reports, generated artifacts, and residue. This is
  still IAL2 through generated IAL1 and IAL0; it is not raw HDL authoring and
  does not bypass review artifacts.

The exact mdBook target shape selected by `.689` is:

- `docs/book/src/16-ial2-protocol-platform-intent.md`
- `docs/book/src/16a-ial2-axi.md`
- `docs/book/src/16b-ial2-apb.md`
- `docs/book/src/16c-ial2-ahb.md`
- `docs/book/src/SUMMARY.md`

The chapter scaffold must link back to
`docs/book/src/15a-ial2-new-protocol-support.md` for the implementation
workflow, but the new chapter is user-facing protocol documentation, not an
implementation-only blueprint.

## Example Families

The follow-on AXI chapter should use checked-in examples as its source of
truth:

- guided: `ppif/axi_aw_valid_ready.ppif` and
  `ppif/axi_aw_valid_ready.axi`;
- more-control: small manager capacity/status examples such as
  `ppif/axi_manager_capacity_status.ppif`,
  `ppif/axi_manager_capacity_status_id_family.ppif`, and
  `ppif/axi_manager_capacity_status_transaction_envelope.ppif`;
- raw/full-control: selected bounded deep examples from response-demux,
  dynamic IDs, same-ID queues, burst-last read-data, burst-length runtime
  validation, and multi-beat output-bank families.

The follow-on APB chapter should use checked-in examples as its source of
truth:

- guided: `ppif/apb_requester_transfer.ppif`,
  `ppif/apb_completer.ppif`, and `ppif/apb_composition.ppif`, plus their
  `.apb` aliases where selected;
- more-control: busy/status, sideband, data16, protection, multi-register,
  and multi-peripheral examples;
- raw/full-control: selected generalized multi-peripheral multi-register
  back-to-back examples, including the latest six-register no-policy family.

The follow-on AHB chapter should use current direct `.fsm` coverage as its
truth source:

- guided: `fsm/amba_requester.fsm` as a direct FSMGen AHB requester seed, not
  an IAL2 source;
- more-control: document which requester knobs are present in that `.fsm`
  fixture and which are not part of IAL2;
- raw/full-control: document that `.ahb`/AHB `.ppif` IAL2 behavior is not
  shipped and must remain future task-tree-owned work.

## Validation Strategy

For each follow-on chapter, examples should be validated from checked-in files
instead of temporary snippets wherever possible. The selected command families
are:

- `./bin/fsmgen --quiet --strict --check --json EXAMPLE`
- `./bin/fsmgen --quiet --emit-schedule-json EXAMPLE`
- `./bin/fsmgen --quiet --strict --emit-semantic-json EXAMPLE`
- `./bin/fsmgen --quiet --outdir /tmp/fsmgen-doc-example EXAMPLE`
- focused protocol tests where the slice touches exact protocol examples:
  `t/1436-ial2-ppif-parser-cli.t`,
  `t/1437-axi-ial2-manager-capacity-status-generator.t`,
  `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`,
  `t/1470-ial2-apb-profile-alias.t`,
  `t/1472-ial2-apb-composition.t`,
  `t/248-regression-corpus-accounting.t`, and
  `t/297-capability-manifest.t` as warranted;
- `mdbook build docs/book`;
- Knowledge Map generation/check;
- docs relative-path audit;
- memory/doctrine gates.

Broad or expensive Perl/fsmgen runs must keep using
`scripts/run_with_ram_guard.sh` or equivalent monitoring.

## Selected Follow-On Leaves

### `.690` mdBook IAL2 protocol scaffold

Create the new mdBook top-level IAL2 chapter and `SUMMARY.md` entries. Define
the three documentation modes, shared lowering/review-artifact rules, public
source/report/diagnostic expectations, protocol matrix, and current
shipped/deferred summary for AXI, APB, and AHB. This leaf may include only
small representative commands and links; detailed protocol examples belong to
`.691`, `.692`, and `.693`.

### `.691` AXI tri-mode coverage

Populate `16a-ial2-axi.md` with runnable AXI examples across guided,
more-control, and raw/full-control modes, using checked-in examples and
validation commands. Keep AXI framed as the first profile/example over IAL2,
not the IAL2 language boundary.

### `.692` APB tri-mode coverage

Populate `16b-ial2-apb.md` with runnable APB examples across guided,
more-control, and raw/full-control modes, using checked-in examples and
validation commands. Keep APB interconnect/decode documented as APB-specific.

### `.693` AHB current-state and future IAL2 boundary

Populate `16c-ial2-ahb.md` with honest AHB coverage: the direct
`fsm/amba_requester.fsm` seed, the unsupported `.ahb` IAL2 alias boundary, and
the future task-tree prerequisites for any AHB IAL2 user-friendly,
more-control, or raw/full-control mode.

## Deferred Boundaries

This audit does not select:

- broad mdBook chapter rewrites;
- new examples or source fixtures;
- parser/generator/support-accounting changes;
- changes to `.ppif`, `.axi`, `.apb`, or `.ahb` suffix behavior;
- AHB IAL2 behavior;
- AXI or APB behavior widening;
- direct backend lowering;
- verification-output generation;
- backend-language variants;
- VHDL behavior.

## Validation

This leaf is documentation-planning only. Closeout validation should include:

- Knowledge Map generation/check;
- mdBook build;
- docs relative-path audit;
- memory architecture check;
- whitespace diff check;
- fact-card reverify search;
- `scripts/check_doctrines.sh`.

## Rollback

Rollback removes this audit note, its Knowledge Map fact card, README,
ROADMAP_V2, task-tree, Memory, and generated Knowledge Map updates. No parser,
generator, public source, support-accounting, generated-artifact, HDL/runtime,
AXI, APB, AHB, or VHDL behavior changes are part of this selector.
