# Protocol Profiles and APB Backlog

IAL2 protocol generality guardrail selector:
[IAL2_PROTOCOL_GENERALITY_GUARDRAIL_READINESS_SELECTION](../../IAL2_PROTOCOL_GENERALITY_GUARDRAIL_READINESS_SELECTION.md)
selects `.526`, readiness audit for the IAL2 protocol/platform generality
guardrail before more profile-specific implementation. AXI is the first
shipped IAL2 profile/example, not the definition of IAL2. Common IAL2
constructs remain protocol/platform-generic and AXI-specific vocabulary stays
profile-local unless compatible reuse is proven across multiple profiles.

IAL2 protocol generality guardrail readiness audit:
[IAL2_PROTOCOL_GENERALITY_GUARDRAIL_READINESS_AUDIT](../../IAL2_PROTOCOL_GENERALITY_GUARDRAIL_READINESS_AUDIT.md)
selects `.527`, public-surface cleanup for the IAL2 protocol/platform
generality guardrail. The audit found the architecture records correct and
the remaining risk in downstream/public capability boundary wording: public
`.ppif` surfaces should lead with AXI as the first shipped IAL2
profile/example, not the IAL2 definition.

IAL2 protocol generality guardrail public-surface sync:
[IAL2_PROTOCOL_GENERALITY_GUARDRAIL_PUBLIC_SURFACE_SYNC](../../IAL2_PROTOCOL_GENERALITY_GUARDRAIL_PUBLIC_SURFACE_SYNC.md)
synchronizes the public `.ppif` contract, downstream handoff, and
capability-manifest language-surface boundary with the guardrail and selects
`.528`, post-guardrail IAL2 next-slice selection. Public `.ppif` surfaces now
lead with AXI as the first shipped IAL2 profile/example, not the IAL2
definition; future protocol-specific suffixes are profile aliases over IAL2;
and common IAL2 constructs stay small until compatible reuse is proven across
profiles.

IAL2 post-guardrail next-slice selector:
[IAL2_POST_GUARDRAIL_NEXT_SLICE_SELECTION](../../IAL2_POST_GUARDRAIL_NEXT_SLICE_SELECTION.md)
selects `.529`, readiness audit for a protocol-neutral/non-AXI Valid-Ready
`.ppif` example boundary. The selector deliberately does not return to
another AXI behavior slice before auditing the existing Valid-Ready family as
the next small IAL2 generality exercise.

IAL2 protocol-neutral Valid-Ready PPIF readiness audit:
[IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_READINESS_AUDIT](../../IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_READINESS_AUDIT.md)
selects `.530`, public contract selection for a protocol-neutral/non-AXI
Valid-Ready `.ppif` profile and source-vocabulary boundary. `.ppif` is the
generic IAL2 container, and AXI is only the first shipped profile/example, but
the current Valid-Ready implementation path still requires a profile clause
and accepts only AXI protocol names plus AXI channel families. A non-AXI or
protocol-neutral Valid-Ready sample therefore needs public vocabulary
selection before parser, generator, sample, support-accounting, or report
changes.

IAL2 protocol-neutral Valid-Ready PPIF contract:
[IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_CONTRACT_SELECTION](../../IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_CONTRACT_SELECTION.md)
selects `.531`, direct bounded implementation of the first
protocol-neutral/non-AXI Valid-Ready `.ppif` sample. The selected source keeps
`(profile valid-ready)` explicit and required, keeps no-profile input
unsupported, uses `ppif/valid_ready_handshake.ppif` with support identity
`intent.ppif_valid_ready_handshake`, treats `(channel data_link)` as an
authored logical channel identifier rather than an AXI family, selects
`producer-to-consumer` as the first neutral role, and introduces no `.axi` or
other suffix alias.

IAL2 protocol-neutral Valid-Ready PPIF behavior:
[IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_BEHAVIOR](../../IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_BEHAVIOR.md)
ships `ppif/valid_ready_handshake.ppif` as the first protocol-neutral/non-AXI
Valid-Ready `.ppif` sample. It lowers through generated
`data_link_valid_ready_monitor.isf` and `data_link_valid_ready_monitor.fsm`,
reports `target_channel.protocol = "valid-ready"`,
`target_channel.family = "data_link"`, and
`target_channel.role = "producer-to-consumer"`, and is support-accounted as
`intent.ppif_valid_ready_handshake`. Existing AXI Valid-Ready, AXI AW/W
bundle, AXI manager capacity/status, unsupported suffix aliases, direct
backend, verification-output, backend-language variant, and VHDL boundaries
remain unchanged.

Post neutral Valid-Ready PPIF selector:
[IAL2_POST_NEUTRAL_VALID_READY_PPIF_NEXT_SLICE_SELECTION](../../IAL2_POST_NEUTRAL_VALID_READY_PPIF_NEXT_SLICE_SELECTION.md)
selects `.533`, readiness audit for protocol-neutral/non-AXI Valid-Ready
`.ppif` bundles. The selector keeps `.ppif` generic, keeps AXI profile-local,
and does not change behavior; the audit is next because `(profile valid-ready)`
multi-channel bundles remain fail-closed while the shipped aggregate bundle
path is proven through the AXI AW/W profile sample.

IAL2 protocol-neutral Valid-Ready bundle readiness audit:
[IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_READINESS_AUDIT](../../IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_READINESS_AUDIT.md)
selects `.534`, public contract selection for a bounded protocol-neutral/non-AXI
Valid-Ready `.ppif` bundle. The audit found the aggregate wrapper/top substrate
close enough to reuse, but direct implementation still needs an exact public
contract for the neutral sample/support identity, both neutral roles,
source-anchor inheritance, generic aggregate residue, docs/manifest wording,
and RAM-guard-friendly validation. No parser, generator, sample,
support-accounting, report, HDL, backend, profile-alias, common-construct, or
VHDL behavior changes in `.533`.

IAL2 protocol-neutral Valid-Ready bundle contract:
[IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_CONTRACT_SELECTION](../../IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_CONTRACT_SELECTION.md)
selects `.535`, direct bounded implementation of
`ppif/valid_ready_dual_channel_bundle.ppif`. The contract keeps explicit
`(profile valid-ready)`, selects support identity
`intent.ppif_valid_ready_dual_channel_bundle`, exercises both neutral roles,
preserves the aggregate `valid_ready_bundle.v1` schema, requires generic
neutral aggregate residue instead of AXI manager residue, and preserves the
AXI AW/W bundle boundary. No parser, generator, sample, support-accounting,
report, HDL, backend, profile-alias, common-construct, or VHDL behavior changes
in `.534`.

IAL2 protocol-neutral Valid-Ready bundle behavior:
[IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_BEHAVIOR](../../IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_BEHAVIOR.md)
ships `ppif/valid_ready_dual_channel_bundle.ppif` as the first
protocol-neutral/non-AXI dual-channel Valid-Ready `.ppif` bundle. It generates
`data_downstream_valid_ready_monitor.isf`,
`status_upstream_valid_ready_monitor.isf`, their generated `.fsm` monitors,
and the aggregate wrapper/top `valid_ready_dual_channel_bundle.fsm`; reports
support identity `intent.ppif_valid_ready_dual_channel_bundle`, both neutral
roles, one inherited channel source, and generic aggregate residue; and
preserves the AXI AW/W bundle's AXI-profile residue boundary.

Post neutral Valid-Ready bundle selector:
[IAL2_POST_NEUTRAL_VALID_READY_BUNDLE_NEXT_SLICE_SELECTION](../../IAL2_POST_NEUTRAL_VALID_READY_BUNDLE_NEXT_SLICE_SELECTION.md)
selects `.537`, readiness audit for future IAL2 profile-alias file suffixes.
The selector is not an `.axi` implementation selection; it audits how future
suffixes such as `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, or
`.i2s` can remain aliases over the same IAL2 model while preserving `.ppif`
behavior, support accounting, reports, source paths, and mandatory
`IAL2 -> IAL1 -> IAL0` lowering.

Historical IAL2 profile-alias suffix readiness audit (pre-.540):
[IAL2_PROFILE_ALIAS_SUFFIX_READINESS_AUDIT](../../IAL2_PROFILE_ALIAS_SUFFIX_READINESS_AUDIT.md)
selects `.538`, public unsupported-alias inventory synchronization before any
profile-alias suffix implementation. At that pre-`.540` point, `.ppif` was the
only shipped IAL2 suffix and the audit recorded that future profile-alias
candidates such as
`.axi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` remain
aliases over IAL2, not separate layers or AXI-only scope.

Historical IAL2 profile-alias unsupported inventory sync (pre-.540):
[IAL2_PROFILE_ALIAS_UNSUPPORTED_INVENTORY_SYNC](../../IAL2_PROFILE_ALIAS_UNSUPPORTED_INVENTORY_SYNC.md)
kept `.pif`, `.ppi`, `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`,
`.smbus`, and `.i2s` listed as unsupported first-slice aliases in the
capability manifest at `.538`. At that point, shipped source suffixes were
`.fsm`, `.isf`, and `.ppif`, and `.539` selected the public contract for the
first IAL2 profile-alias suffix before `.540` implemented `.axi`.

IAL2 first profile-alias contract:
[IAL2_FIRST_PROFILE_ALIAS_CONTRACT_SELECTION](../../IAL2_FIRST_PROFILE_ALIAS_CONTRACT_SELECTION.md)
selects `.540`, direct bounded implementation of `.axi` as the first IAL2
profile-alias suffix. The selected `.axi` alias mirrors the existing
`ppif/axi_aw_valid_ready.ppif` sample at `ppif/axi_aw_valid_ready.axi`, requires
an explicit AXI-family profile such as `(profile axi4)`, and stays on the
mandatory `IAL2 -> IAL1 -> IAL0` lowering chain. AXI remains a first
profile-alias example, not the definition of IAL2.

IAL2 AXI profile-alias behavior:
[IAL2_AXI_PROFILE_ALIAS_BEHAVIOR](../../IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md)
ships `.axi` as the first bounded IAL2 profile-alias suffix. The runnable
`ppif/axi_aw_valid_ready.axi` source keeps the generic
`protocol-platform-intent` shape, requires an explicit AXI-family profile
(`axi`, `axi3`, `axi4`, or `axi5`), writes reviewable generated `.isf` and
`.fsm` artifacts before HDL generation, and support-accounts
`intent.axi_profile_alias_aw_valid_ready` with source kind
`ial2_profile_alias`. `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, `.i2s`,
`.pif`, and `.ppi` remain unsupported; AXI is still only the first profile
alias over IAL2.

Post-.axi profile-alias selector:
[IAL2_POST_AXI_PROFILE_ALIAS_NEXT_SLICE_SELECTION](../../IAL2_POST_AXI_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md)
selects `.542`, a post-`.axi` IAL2 generality readiness audit before another
behavior implementation. Current `.axi` acceptance questions route to the
shipped `.540` behavior fact; older profile-alias readiness and
unsupported-inventory facts are historical pre-implementation facts. The next owner must
choose from neutral/profile-generic evidence and must not treat AXI as the
whole IAL2 layer.

Post-.axi generality readiness audit:
[IAL2_POST_AXI_GENERALITY_READINESS_AUDIT](../../IAL2_POST_AXI_GENERALITY_READINESS_AUDIT.md)
selects `.543`, public-surface historical wording sync before another behavior
owner. The code, manifest, support-accounting, and Knowledge Map routing are
current after `.540`/`.541`; the remaining public prerequisite is to make
pre-`.540` profile-alias chronology explicit in the book.

IAL2 profile-alias public chronology sync:
[IAL2_PROFILE_ALIAS_PUBLIC_CHRONOLOGY_SYNC](../../IAL2_PROFILE_ALIAS_PUBLIC_CHRONOLOGY_SYNC.md)
marks the `.537` readiness audit and `.538` unsupported-inventory sync as
historical pre-`.540` public state, then keeps current `.axi` behavior anchored
to the `.540` bounded AXI AW Valid-Ready profile-alias sample. `.axi` is the
first shipped profile-alias example over IAL2; it is not the definition or full
scope of IAL2, and the other profile-alias candidates remain unsupported.

IAL2 non-AXI profile-alias readiness selector:
[IAL2_NON_AXI_PROFILE_ALIAS_READINESS_SELECTION](../../IAL2_NON_AXI_PROFILE_ALIAS_READINESS_SELECTION.md)
selects `.545`, a non-AXI profile-alias readiness audit after the public
chronology sync. The selected next owner is not another AXI implementation; it
must audit `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, `.i2s`, `.pif`,
and `.ppi` readiness or prerequisites without accepting a new suffix or
changing behavior.

IAL2 non-AXI profile-alias readiness audit:
[IAL2_NON_AXI_PROFILE_ALIAS_READINESS_AUDIT](../../IAL2_NON_AXI_PROFILE_ALIAS_READINESS_AUDIT.md)
selects `.546`, a taxonomy and evidence prerequisite before any non-AXI alias
contract. `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` do not
yet have source-shape, profile-matching, report, support-accounting, or book
evidence; `.pif` and `.ppi` remain generic-container candidates rather than
protocol aliases.

IAL2 non-AXI profile-alias taxonomy/evidence prerequisite:
[IAL2_NON_AXI_PROFILE_ALIAS_TAXONOMY_EVIDENCE_PREREQUISITE](../../IAL2_NON_AXI_PROFILE_ALIAS_TAXONOMY_EVIDENCE_PREREQUISITE.md)
selects `.547`, a generic-container alias policy selection for `.pif` and
`.ppi`. `.ppif` remains the shipped generic IAL2 container; `.pif` and `.ppi`
are generic-container spelling candidates, not protocol aliases; and `.chi`,
`.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` remain protocol-profile
alias candidates without contract evidence. `(profile valid-ready)` under
`.ppif` is the current protocol-neutral/non-AXI IAL2 evidence and does not
define a protocol suffix.

IAL2 PIF/PPI generic-container alias policy:
[IAL2_PIF_PPI_GENERIC_CONTAINER_ALIAS_POLICY_SELECTION](../../IAL2_PIF_PPI_GENERIC_CONTAINER_ALIAS_POLICY_SELECTION.md)
keeps `.pif` and `.ppi` explicitly unsupported historical generic-container
spellings and selects `.548`, an APB IAL2 source-shape readiness audit. The
next owner must audit the existing APB lower-layer fixtures before selecting
any APB `.ppif` contract or `.apb` suffix behavior.

IAL2 APB source-shape readiness audit:
[IAL2_APB_SOURCE_SHAPE_READINESS_AUDIT](../../IAL2_APB_SOURCE_SHAPE_READINESS_AUDIT.md)
selects `.549`, APB `.ppif` source-shape public contract selection. The audit
finds enough APB lower-layer evidence in the shipped ISF requester,
requester/completer FSMs, composition top, mdBook examples, and support
catalog to select the public IAL2 source-shape contract before implementation.
It does not accept `.apb`, add an APB `.ppif` sample, or change parser,
generator, manifest, support-accounting, JSON, HDL, backend, AXI, or VHDL
behavior.

IAL2 APB `.ppif` source-shape contract:
[IAL2_APB_PPIF_SOURCE_SHAPE_CONTRACT_SELECTION](../../IAL2_APB_PPIF_SOURCE_SHAPE_CONTRACT_SELECTION.md)
selects `(profile apb)` plus one `(apb-requester apb_requester ...)` object as
the first APB `.ppif` source shape and selects `.550` for direct bounded
implementation. The future sample path is
`ppif/apb_requester_transfer.ppif`, the support identity is
`intent.ppif_apb_requester_transfer`, generated review artifacts are
`apb_requester.isf` and `apb_requester.fsm`, and the report schema is
`fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`. `.apb` and all other
new suffixes remain unsupported.

IAL2 APB `.ppif` requester-transfer behavior:
[IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR](../../IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md)
ships that first APB `.ppif` source shape through the existing IAL2 -> IAL1 ->
IAL0 -> HDL path. The shipped sample is
`ppif/apb_requester_transfer.ppif`; it uses `(profile apb)` with one
`(apb-requester apb_requester ...)` object, emits report schema
`fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`, materializes
review artifacts `apb_requester.isf` and `apb_requester.fsm`, and
support-accounts `intent.ppif_apb_requester_transfer`. APB support here is a
`.ppif` profile behavior, not a `.apb` suffix and not an AXI extension.

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_requester_transfer.ppif
./bin/fsmgen --strict --check --json ppif/apb_requester_transfer.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --outdir .artifacts/ial2/fsmgen-apb-ppif \
  --output .artifacts/ial2/fsmgen-apb-ppif/apb_requester.sv \
  ppif/apb_requester_transfer.ppif
```

At `.550` closeout, the `.apb` suffix remained a known unsupported alias
candidate even when the file contents matched the APB `.ppif` source. The
later `.554` slice ships the bounded `.apb` alias documented below.

Post APB requester-transfer selector:
[IAL2_POST_APB_REQUESTER_TRANSFER_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_REQUESTER_TRANSFER_NEXT_SLICE_SELECTION.md)
selects `.552`, an APB `.apb` profile-alias readiness audit. The selector
records that the shipped APB `.ppif` requester-transfer behavior is enough
evidence to audit `.apb` alias readiness, but not enough to accept `.apb`
without a separate public file-surface contract for explicit profile matching,
source-path/report identity, support accounting, manifest wording,
diagnostics, and generated `.isf` review artifacts before generated `.fsm`.
No suffix behavior changes in `.551`.

IAL2 APB `.apb` profile-alias readiness audit:
[IAL2_APB_PROFILE_ALIAS_READINESS_AUDIT](../../IAL2_APB_PROFILE_ALIAS_READINESS_AUDIT.md)
selects `.553`, APB `.apb` public profile-alias contract selection. The audit
finds that the shipped APB `.ppif` requester-transfer path has enough evidence
to write a bounded `.apb` alias contract: explicit `(profile apb)`, one
`(apb-requester apb_requester ...)` object, generated
`apb_requester.isf`, generated `apb_requester.fsm`, APB report schema, strict
check JSON, semantic JSON, and support accounting. `.apb` is still a known
unsupported suffix; the next owner must settle explicit profile policy,
authored `.apb` source identity, support-accounting identity/source kind,
manifest wording, diagnostics, and mandatory generated `.isf` review
preservation before implementation.

IAL2 APB `.apb` profile-alias contract:
[IAL2_APB_PROFILE_ALIAS_CONTRACT_SELECTION](../../IAL2_APB_PROFILE_ALIAS_CONTRACT_SELECTION.md)
selects `.554`, direct bounded implementation of the first APB `.apb`
profile-alias suffix. The selected contract mirrors
`ppif/apb_requester_transfer.ppif` at future path
`ppif/apb_requester_transfer.apb`, keeps explicit `(profile apb)` with no
suffix inference, preserves generated `apb_requester.isf` before generated
`apb_requester.fsm`, and support-accounts the alias as
`intent.apb_profile_alias_requester_transfer` with source kind
`ial2_profile_alias`. At `.553` closeout, `.apb` remained unsupported until
`.554` implemented the contract.

IAL2 APB `.apb` profile-alias behavior:
[IAL2_APB_PROFILE_ALIAS_BEHAVIOR](../../IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md)
ships `.apb` as the bounded APB requester-transfer, APB completer, and fixed
APB requester/completer composition IAL2 profile alias. The aliases keep
explicit `(profile apb)` with no suffix inference, lower through generated
`.isf` before generated `.fsm` review artifacts, preserve authored `.apb`
source paths in check JSON and semantic JSON, and support-account as
`intent.apb_profile_alias_requester_transfer`,
`intent.apb_profile_alias_completer`, and
`intent.apb_profile_alias_composition` with source kind
`ial2_profile_alias`.

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_requester_transfer.apb
./bin/fsmgen --emit-schedule-json ppif/apb_completer.apb
./bin/fsmgen --emit-schedule-json ppif/apb_composition.apb
./bin/fsmgen --strict --check --json ppif/apb_requester_transfer.apb
./bin/fsmgen --strict --check --json ppif/apb_completer.apb
./bin/fsmgen --strict --check --json ppif/apb_composition.apb
./bin/fsmgen --strict --emit-semantic-json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --outdir .artifacts/ial2/fsmgen-apb-alias \
  --output .artifacts/ial2/fsmgen-apb-alias/apb_requester.sv \
  ppif/apb_requester_transfer.apb
```

Remaining unsupported aliases are `.chi`, `.ace`, `.atb`, `.smbus`, `.i2s`,
`.pif`, and `.ppi`. `.ahb` is a separate shipped AHB requester and subordinate profile alias
after `.700`. APB requester busy/status, multi-register decode,
sidebands, alternate widths, multi-peripheral decode, back-to-back policy,
implicit profile inference, direct backend lowering, verification-output
generation, backend-language variants, and VHDL remain deferred.

Post APB profile-alias selector:
[IAL2_POST_APB_PROFILE_ALIAS_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md)
selects `.556`, a no-behavior public-surface sync after APB `.apb`
profile-alias support shipped. The next owner must make current `.axi`
behavior/fact wording stop listing `.apb` as unsupported after `.554`, while
preserving historical pre-`.554` closeout wording and keeping `.chi`, `.ace`,
`.ahb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` unsupported at that
pre-`.700` closeout date.

Post APB profile-alias public-surface sync:
[IAL2_POST_APB_PROFILE_ALIAS_PUBLIC_SURFACE_SYNC](../../IAL2_POST_APB_PROFILE_ALIAS_PUBLIC_SURFACE_SYNC.md)
completes that sync. After `.700`, current profile-alias surfaces list `.axi`,
`.apb`, and `.ahb` as shipped bounded aliases, keep `.chi`, `.ace`, `.atb`,
`.smbus`, `.i2s`, `.pif`, and `.ppi` unsupported, and preserve pre-`.554`
`.apb`-unsupported plus pre-`.700` `.ahb`-unsupported wording only as dated
history. No behavior changes in `.556`; it selects `.557`, the next exact IAL2
owner selector after the sync.


## Continued APB Expansion

Post APB surface-sync selector:
[IAL2_POST_APB_SURFACE_SYNC_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_SURFACE_SYNC_NEXT_SLICE_SELECTION.md)
selects `.558`, a no-behavior readiness audit for APB completer/interconnect
generation. The selector reverified the supported APB completer fixture, the
APB requester-to-completer composition top, and the current `.apb`
requester-transfer schedule/check path, then chose the explicit
`apb_completer_and_interconnect_generation_deferred` residue for audit before
any APB expansion behavior.

APB completer/interconnect readiness audit:
[IAL2_APB_COMPLETER_INTERCONNECT_READINESS_AUDIT](../../IAL2_APB_COMPLETER_INTERCONNECT_READINESS_AUDIT.md)
selects `.559`, APB completer/interconnect public contract selection. The
audit finds enough lower-layer evidence for a public contract selector:
`fsm/apb_completer.fsm` is a supported APB target/completer fixture,
`fsm/apb_tb.fsm` wires requester and completer through the APB bus, and the
current `.apb` requester-transfer report keeps
`apb_completer_and_interconnect_generation_deferred` explicit. Direct behavior
is still deferred until source vocabulary, completer/interconnect split policy,
mandatory generated `.isf` before `.fsm` artifacts, aggregate top shape,
report/support identities, diagnostics, and `.ppif` versus `.apb` exposure are
selected.

APB completer/interconnect contract selection:
[IAL2_APB_COMPLETER_INTERCONNECT_CONTRACT_SELECTION](../../IAL2_APB_COMPLETER_INTERCONNECT_CONTRACT_SELECTION.md)
selects `.560`, APB completer generated-IAL1 substrate audit. The contract
splits the combined APB completer/interconnect residue. The first selected
public shape is `.ppif` APB completer generation with future sample
`ppif/apb_completer.ppif`, object `(apb-completer apb_completer ...)`,
generated `apb_completer.isf` before `apb_completer.fsm`, report schema
`fsmgen.ial2.protocol_intent.apb_completer.v1`, and future support identity
`intent.ppif_apb_completer`. APB interconnect/composition and `.apb`
completer alias exposure remain deferred.

APB completer generated-IAL1 substrate audit:
[IAL2_APB_COMPLETER_GENERATED_IAL1_SUBSTRATE_AUDIT](../../IAL2_APB_COMPLETER_GENERATED_IAL1_SUBSTRATE_AUDIT.md)
selects `.561`, IAL1 expression entry-activation guard rendering repair before
APB completer behavior. Runtime `wait_cycles`, storage reset/update,
no-public-done target transactions, address-dependent read/write state,
`PSLVERR`, and generated report/artifact structure are viable substrate
pieces.

IAL1 expression entry-guard rendering behavior:
[IAL1_EXPRESSION_ENTRY_GUARD_RENDERING_BEHAVIOR](../../IAL1_EXPRESSION_ENTRY_GUARD_RENDERING_BEHAVIOR.md)
ships `.561`, so first-clause `(when EXPR (sample ...))` entry guards now
render valid generated `.fsm` expression guard text on sample enables and entry
transitions. The APB-shaped `PSEL && !PENABLE` setup detector now lowers
through IAL1 without `ARRAY(...)` guard suffixes. Direct APB `.ppif`
completer parser/generator/sample/support behavior remains deferred to the
next task-tree owner.

APB `.ppif` completer behavior:
[IAL2_APB_PPIF_COMPLETER_BEHAVIOR](../../IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md)
ships `.562`, the first generated APB completer source under the generic
`.ppif` IAL2 container. The sample `ppif/apb_completer.ppif` uses explicit
`(profile apb)` with one `(apb-completer apb_completer ...)` object, emits
report schema `fsmgen.ial2.protocol_intent.apb_completer.v1`, materializes
`apb_completer.isf` before `apb_completer.fsm`, reaches HDL module
`apb_completer`, and support-accounts `intent.ppif_apb_completer`.

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_completer.ppif
./bin/fsmgen --strict --check --json ppif/apb_completer.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/apb_completer.ppif
./bin/fsmgen --quiet --outdir .artifacts/ial2/fsmgen-apb-completer \
  --output .artifacts/ial2/fsmgen-apb-completer/apb_completer.sv \
  ppif/apb_completer.ppif
```

The bounded subset covers setup detection `PSEL && !PENABLE`, runtime
`wait_cycles`, one address-0 32-bit register, mapped read/write behavior, and
`PSLVERR` for unmapped addresses. The generated IAL1 uses an internal
`apb_complete_done_q` terminal bit rather than adding a public APB `done` port.
At `.562` closeout `.apb` remained requester-transfer only; `.569` later
exposes the same bounded completer through `ppif/apb_completer.apb`. APB
interconnect/composition, sidebands, alternate widths, multi-register decode,
back-to-back policy, direct backend lowering, verification-output generation,
backend-language variants, AXI behavior, and VHDL remain deferred.

Post APB completer selector:
[IAL2_POST_APB_COMPLETER_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_COMPLETER_NEXT_SLICE_SELECTION.md)
selects `.564`, a no-behavior APB interconnect/composition readiness audit.
The selector reverified the generated APB completer `.ppif`, APB requester
`.ppif`, APB requester `.apb`, lower-layer completer, and lower-layer APB
composition surfaces, then chose `apb_interconnect_generation_deferred` as the
next residue to audit now that both generated endpoint paths exist.

APB interconnect/composition readiness audit:
[IAL2_APB_INTERCONNECT_COMPOSITION_READINESS_AUDIT](../../IAL2_APB_INTERCONNECT_COMPOSITION_READINESS_AUDIT.md)
selects `.565`, APB interconnect/composition public contract selection. The
audit finds contract selection is justified because generated APB requester and
completer `.ppif` endpoint paths now exist, and the strict-supported
`fsm/apb_tb.fsm` target already wires `apb_requester` to `apb_completer`
through the APB bus. Direct interconnect implementation remains deferred until
that public contract is selected.

APB interconnect/composition contract selection:
[IAL2_APB_INTERCONNECT_COMPOSITION_CONTRACT_SELECTION](../../IAL2_APB_INTERCONNECT_COMPOSITION_CONTRACT_SELECTION.md)
selects `.566`, direct bounded APB `.ppif` composition implementation. The
selected first contract is `ppif/apb_composition.ppif` with top-level intent
`apb_composition`, one embedded APB requester endpoint, one embedded APB
completer endpoint, and one explicit `(apb-composition apb_tb ...)` object.
The selected generated review chain is `apb_requester.isf`,
`apb_requester.fsm`, `apb_completer.isf`, `apb_completer.fsm`, and
`apb_tb.fsm`, with report schema
`fsmgen.ial2.protocol_intent.apb_composition.v1` and support identity
`intent.ppif_apb_composition`. Requester `busy` exposure and wider APB
interconnect/decode remain deferred.

APB `.ppif` composition behavior:
[IAL2_APB_PPIF_COMPOSITION_BEHAVIOR](../../IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md)
ships `.566`, the first fixed one-requester/one-completer APB composition
source under the generic `.ppif` IAL2 container. The sample
`ppif/apb_composition.ppif` uses explicit `(profile apb)` with one requester,
one completer, and one `(apb-composition apb_tb ...)` object, emits report
schema `fsmgen.ial2.protocol_intent.apb_composition.v1`, materializes
`apb_requester.isf`, `apb_completer.isf`, `apb_requester.fsm`,
`apb_completer.fsm`, and `apb_tb.fsm`, selects `apb_tb.fsm` as the HDL entry,
and support-accounts `intent.ppif_apb_composition`.

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_composition.ppif
./bin/fsmgen --strict --check --json ppif/apb_composition.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/apb_composition.ppif
./bin/fsmgen --quiet --outdir .artifacts/ial2/fsmgen-apb-composition \
  --output .artifacts/ial2/fsmgen-apb-composition/apb_tb.sv \
  ppif/apb_composition.ppif
```

The generated top exposes `clk`, `rst_n`, `start`, `req_write`, `req_addr`,
`req_wdata`, `wait_cycles`, `done`, `last_error`, and `last_read_data`.
Requester `busy`, multi-peripheral interconnect/decode, sidebands/strobes,
alternate widths, back-to-back policy, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, and
VHDL remain deferred. The later `.569` slice exposes the completer and fixed
composition through `.apb`; `.567` was the no-behavior selector for the next
APB surface after requester, completer, and fixed composition `.ppif` paths
shipped.

Post APB composition selector:
[IAL2_POST_APB_COMPOSITION_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_COMPOSITION_NEXT_SLICE_SELECTION.md)
selects `.568`, APB `.apb` profile-alias public contract selection for the
now-shipped APB completer and fixed requester/completer composition shapes.
The selector confirms requester-transfer `.apb`, completer `.ppif`, and
composition `.ppif` pass, while temporary completer/composition `.apb` copies
still failed closed with the requester-transfer-only alias diagnostic at
`.567` closeout. No behavior changes in `.567`; `.568` selected exact `.apb`
sample paths, support identities, source-kind behavior, diagnostics,
validation, and rollback before `.569` implemented the alias widening.

APB `.apb` completer/composition contract:
[IAL2_APB_PROFILE_ALIAS_COMPLETER_COMPOSITION_CONTRACT_SELECTION](../../IAL2_APB_PROFILE_ALIAS_COMPLETER_COMPOSITION_CONTRACT_SELECTION.md)
selects `.569`, direct bounded implementation of APB `.apb` profile-alias
widening for the shipped APB completer and fixed APB requester/completer
composition shapes. The selected future samples are `ppif/apb_completer.apb`
and `ppif/apb_composition.apb`; both keep explicit `(profile apb)`, preserve
the generated `.isf`/`.fsm` review artifacts from the generic `.ppif`
behaviors, and keep authored `.apb` source paths in check JSON and semantic
JSON. The selected support identities are
`intent.apb_profile_alias_completer` and
`intent.apb_profile_alias_composition`, both with source kind
`ial2_profile_alias`.

The completer alias keeps report schema
`fsmgen.ial2.protocol_intent.apb_completer.v1`, generated
`apb_completer.isf` and `apb_completer.fsm`, HDL module `apb_completer`, and
semantic root kind `fsm`. The composition alias keeps report schema
`fsmgen.ial2.protocol_intent.apb_composition.v1`, generated
`apb_requester.isf`, `apb_completer.isf`, `apb_requester.fsm`,
`apb_completer.fsm`, and `apb_tb.fsm`, HDL entry `apb_tb.fsm`, expected top
`apb_tb`, children `apb_requester` and `apb_completer`, and semantic root kind
`top`. No behavior changes in `.568`; `.569` implements the selected widening.
Multi-peripheral interconnect/decode, requester `busy`/status exposure,
multi-register decode, sidebands/strobes, alternate widths, back-to-back
policy, direct backend lowering, verification-output generation,
backend-language variants, AXI behavior, and VHDL remain deferred.

APB `.apb` completer/composition behavior:
[IAL2_APB_PROFILE_ALIAS_BEHAVIOR](../../IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md)
now includes `.569`, the bounded APB profile-alias widening for shipped
completer and fixed composition sources. The public aliases
`ppif/apb_completer.apb` and `ppif/apb_composition.apb` mirror
`ppif/apb_completer.ppif` and `ppif/apb_composition.ppif`, preserve authored
`.apb` source paths in check JSON and semantic JSON, lower through the same
generated `.isf` and `.fsm` review artifacts, and support-account as
`intent.apb_profile_alias_completer` and
`intent.apb_profile_alias_composition` with source kind `ial2_profile_alias`.

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_completer.apb
./bin/fsmgen --emit-schedule-json ppif/apb_composition.apb
./bin/fsmgen --strict --check --json ppif/apb_completer.apb
./bin/fsmgen --strict --check --json ppif/apb_composition.apb
./bin/fsmgen --strict --emit-semantic-json ppif/apb_completer.apb
./bin/fsmgen --strict --emit-semantic-json ppif/apb_composition.apb
```

The `.apb` suffix now accepts exactly requester-transfer, completer, and fixed
one-requester/one-completer composition APB shapes. Missing profile, non-APB
profile, Valid-Ready or AXI objects, and implicit mixed requester/completer
sources without explicit `(apb-composition ...)` still fail closed. `.569`
selects `.570`, a no-behavior selector for the next APB surface after
requester/completer/composition `.apb` alias coverage shipped.

Post APB alias-widening selector:
[IAL2_POST_APB_ALIAS_WIDENING_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_ALIAS_WIDENING_NEXT_SLICE_SELECTION.md)
selects `.571`, APB requester busy/status public contract selection. The
selector changes no behavior. The current generated requester and fixed
composition IAL2 reports expose `done`, `last_error`, and `last_read_data`
while carrying `apb_requester_busy_status_deferred`; lower-layer
hand-authored `fsm/apb_requester.fsm` and `fsm/apb_tb.fsm` already expose
`busy`. The next owner must settle exact source syntax, whether the first
widening exposes only `busy` or also a named status field, generated review
artifacts, fixed composition top-port propagation, support/report/residue
updates, diagnostics, validation, and rollback before behavior changes.

APB requester busy/status contract:
[IAL2_APB_REQUESTER_BUSY_STATUS_CONTRACT_SELECTION](../../IAL2_APB_REQUESTER_BUSY_STATUS_CONTRACT_SELECTION.md)
selects `.572`, additive busy-only APB requester status exposure. Existing APB
requester-transfer and fixed-composition samples remain unchanged. The new
selected busy-capable samples are `ppif/apb_requester_transfer_busy.ppif`,
`ppif/apb_requester_transfer_busy.apb`, `ppif/apb_composition_busy.ppif`, and
`ppif/apb_composition_busy.apb`. The source syntax adds optional
`(busy busy)` inside the APB requester `(response ...)` block. Named status
fields remain deferred through `apb_requester_status_field_deferred`.

APB requester busy output behavior:
[IAL2_APB_REQUESTER_BUSY_OUTPUT_BEHAVIOR](../../IAL2_APB_REQUESTER_BUSY_OUTPUT_BEHAVIOR.md)
ships `.572`, the additive busy-only APB requester output contract. The busy
requester-transfer samples generate `apb_requester.isf`,
`apb_requester.fsm`, and HDL module `apb_requester` with public `busy`. The
busy fixed-composition samples also generate `apb_tb.fsm` and expose
top-level `busy`. Check/semantic JSON support-account the new samples as
`intent.ppif_apb_requester_transfer_busy`,
`intent.apb_profile_alias_requester_transfer_busy`,
`intent.ppif_apb_composition_busy`, and
`intent.apb_profile_alias_composition_busy`. Existing no-busy APB samples keep
`apb_requester_busy_status_deferred`; busy-capable reports keep
`apb_requester_status_field_deferred` for future named status fields.

Post APB busy-output selector:
[IAL2_POST_APB_BUSY_OUTPUT_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_BUSY_OUTPUT_NEXT_SLICE_SELECTION.md)
selects `.574`, a no-behavior public-surface and `bin/fsmgen` import-tree
synchronization slice before any further behavior work. At `.573` selection
time, the live import probe reported `213` project files total and `212`
reachable `FSM::...` `.pm` packages, including the APB IAL2 requester,
completer, and composition owners, while the import-tree note/fact and mdBook
language-surface prose still needed sync.

APB public-surface/import-tree sync:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.574` completes that no-behavior sync.
`docs/BIN_FSMGEN_IMPORT_TREE.md` and the import-tree fact record the live
`213` total / `212` reachable `FSM::...` `.pm` package closure with APB IAL2
requester, completer, and fixed composition owners reachable. At that time,
the mdBook language-surface and intent-scheduling chapters described `.ppif`
as the generic IAL2 container, `.axi` and `.apb` as bounded shipped profile
aliases, and kept `.pif`, `.ppi`, `.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`,
and `.i2s` unsupported. Later `.700` shipped `.ahb` as the bounded AHB
requester profile alias, so current public-surface summaries list `.ahb` with
the shipped aliases and keep only `.pif`, `.ppi`, `.chi`, `.ace`, `.atb`,
`.smbus`, and `.i2s` unsupported. `.575` later selected the next exact IAL2
slice recorded below.

Post APB public-surface sync selector:
[IAL2_POST_APB_PUBLIC_SYNC_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_PUBLIC_SYNC_NEXT_SLICE_SELECTION.md)
selects `.576`, APB requester named status-field public contract selection,
without changing behavior. Busy-capable APB requester-transfer and
fixed-composition reports keep `apb_requester_status_field_deferred`, making
named status fields the next smallest direct APB follow-on. Multi-peripheral
decode, multi-register decode, sidebands/strobes, alternate widths,
back-to-back policy, direct backend, verification-output, backend-language
variants, AXI follow-on, and VHDL remain deferred.

APB requester status-field contract:
[IAL2_APB_REQUESTER_STATUS_FIELD_CONTRACT_SELECTION](../../IAL2_APB_REQUESTER_STATUS_FIELD_CONTRACT_SELECTION.md)
selects `.577`, direct bounded implementation of additive 2-bit APB requester
named status-field exposure, without changing behavior. The selected source
shape adds `(status status width 2)` only in busy-capable APB requester
response blocks that also contain `(busy busy)`. The selected code is
`0 idle`, `1 busy`, `2 done_ok`, and `3 done_error`. Status-capable requester
and fixed-composition `.ppif`/`.apb` samples will be additive; existing no-busy
and busy-only APB samples remain unchanged. Status-only samples, enum/custom
encodings, sticky status registers, APB decode/storage/sideband/width work,
back-to-back policy, direct backend, verification-output, backend-language
variants, AXI follow-on, and VHDL remain deferred.

APB requester status-field behavior:
[IAL2_APB_REQUESTER_STATUS_FIELD_BEHAVIOR](../../IAL2_APB_REQUESTER_STATUS_FIELD_BEHAVIOR.md)
ships `.577`, the additive busy-plus-status APB requester output contract. The
new requester-transfer samples are `ppif/apb_requester_transfer_status.ppif`
and `ppif/apb_requester_transfer_status.apb`; the new fixed-composition
samples are `ppif/apb_composition_status.ppif` and
`ppif/apb_composition_status.apb`. The accepted response shape keeps
`(busy busy)` and adds `(status status width 2)`. Generated requester artifacts
expose public `busy` and `status[1:0]`, drive status `0 idle`, `1 busy`, and
publish `2 done_ok` / `3 done_error` with `(concat 1'b1 slverr)` after sampling
`PSLVERR`. Status-capable composition sources propagate `status<2>` to the
generated `apb_tb` top. Check/semantic JSON support-account the new samples as
`intent.ppif_apb_requester_transfer_status`,
`intent.apb_profile_alias_requester_transfer_status`,
`intent.ppif_apb_composition_status`, and
`intent.apb_profile_alias_composition_status`. Status-capable reports remove
both `apb_requester_status_field_deferred` and
`apb_requester_busy_status_deferred`; existing no-busy and busy-only APB
samples keep their prior residue. Status-only samples, enum/custom encodings,
sticky status registers, APB decode/storage/sideband/width work, back-to-back
policy, direct backend, verification-output, backend-language variants, AXI
follow-on, and VHDL remain deferred.

Post APB status-field selector:
[IAL2_POST_APB_STATUS_FIELD_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_STATUS_FIELD_NEXT_SLICE_SELECTION.md)
selects `.579`, APB multi-register decode readiness audit, without changing
behavior. The selector chooses multi-register readiness because status-capable
APB requester-transfer and fixed-composition reports now remove the requester
busy/status residues, while APB completer/composition reports still expose the
single-register boundary through `apb_multi_register_decode_deferred`. `.579`
must decide whether the next owner is public contract selection,
lower-layer/storage prerequisite work, parser/report/static-validation
readiness, direct implementation, or explicit deferral. Multi-peripheral APB
topology, sidebands/strobes, alternate widths, back-to-back policy, direct
backend, verification-output, backend-language variants, AXI follow-on, and
VHDL remain deferred.

APB multi-register decode readiness audit:
[IAL2_APB_MULTI_REGISTER_DECODE_READINESS_AUDIT](../../IAL2_APB_MULTI_REGISTER_DECODE_READINESS_AUDIT.md)
selects `.580`, public APB multi-register completer decode contract selection,
without changing behavior. The parser already scans repeated `(register ...)`
clauses, but the current source contract, normalized model, reports, generated
ISF/FSM, samples, lower-layer fixture, and focused tests are still singular.
Direct implementation is not ready until `.580` selects public source syntax,
deterministic ordering, address uniqueness/diagnostics, report migration,
generated storage naming, sample/support/test scope, and deferred boundaries.

APB multi-register decode contract:
[IAL2_APB_MULTI_REGISTER_DECODE_CONTRACT_SELECTION](../../IAL2_APB_MULTI_REGISTER_DECODE_CONTRACT_SELECTION.md)
selects `.581`, direct bounded APB multi-register completer decode
implementation, without changing behavior. The selected syntax is repeated
`(register ...)` clauses under `(storage ...)`, in source order. The first
implementation keeps unique decimal 32-bit 4-byte-aligned addresses, 32-bit
register data, reset 0, existing register read/write policy, and
unmapped-address error behavior. Existing one-register reports remain
unchanged; multi-register reports add `bindings.storage.registers[]` and
`transfer.registers[]`. New standalone completer and status-capable
fixed-composition `.ppif`/`.apb` samples are selected for `.581`.

APB multi-register decode behavior:
[IAL2_APB_MULTI_REGISTER_DECODE_BEHAVIOR](../../IAL2_APB_MULTI_REGISTER_DECODE_BEHAVIOR.md)
ships `.581`, additive APB multi-register completer decode for generated
completer and status-capable fixed-composition sources. The shipped samples
are `ppif/apb_completer_multi_register.ppif`,
`ppif/apb_completer_multi_register.apb`,
`ppif/apb_composition_multi_register.ppif`, and
`ppif/apb_composition_multi_register.apb`. Repeated `(register ...)` clauses
under `(storage ...)` decode source-order 32-bit aligned register addresses;
the shipped samples map address `0` to `reg0_data_q` and address `4` to
`reg1_data_q`. Existing one-register APB samples keep their singular report
fields and `apb_multi_register_decode_deferred` residue. Multi-register
reports use `bindings.storage.registers[]` and `transfer.registers[]` and
remove `apb_multi_register_decode_deferred` while keeping multi-peripheral
topology, sidebands/strobes, alternate widths, and back-to-back policy
deferred.

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_completer_multi_register.ppif
./bin/fsmgen --strict --check --json ppif/apb_completer_multi_register.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/apb_completer_multi_register.ppif
./bin/fsmgen --emit-schedule-json ppif/apb_completer_multi_register.apb
./bin/fsmgen --strict --check --json ppif/apb_completer_multi_register.apb
./bin/fsmgen --strict --emit-semantic-json ppif/apb_completer_multi_register.apb
./bin/fsmgen --emit-schedule-json ppif/apb_composition_multi_register.ppif
./bin/fsmgen --strict --check --json ppif/apb_composition_multi_register.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/apb_composition_multi_register.ppif
./bin/fsmgen --emit-schedule-json ppif/apb_composition_multi_register.apb
./bin/fsmgen --strict --check --json ppif/apb_composition_multi_register.apb
./bin/fsmgen --strict --emit-semantic-json ppif/apb_composition_multi_register.apb
```

Post APB multi-register selector:
[IAL2_POST_APB_MULTI_REGISTER_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_MULTI_REGISTER_NEXT_SLICE_SELECTION.md)
selects `.583`, APB multi-peripheral interconnect/decode readiness audit,
without changing behavior. The selector follows live schedule evidence that
multi-register APB composition has removed the register-local residue while
the APB requester/completer/composition surfaces still expose
multi-peripheral topology residues. Sidebands/strobes, alternate widths,
back-to-back policy, direct backend, verification-output, backend-language
variants, AXI follow-on, and VHDL remain deferred.

APB multi-peripheral interconnect/decode readiness audit:
[IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_READINESS_AUDIT](../../IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_READINESS_AUDIT.md)
selects `.584`, APB multi-peripheral interconnect/decode public contract
selection, before behavior work. Current APB source and reports remain fixed
to one requester, one completer, and one composition object. The next contract
must select peripheral-list syntax, address-map bindings, decode priority,
response mux behavior, diagnostics, report fields, samples, support entries,
and validation gates. The selected reusable direction is APB-specific: IAL2
topology/address-map intent lowers into a generated reusable APB IAL1 review
artifact before generated IAL0 `.fsm` and HDL. AXI and AHB require separate
protocol-specific future owners and cannot share APB interconnect/decode
implementation logic.

APB multi-peripheral interconnect/decode contract selection:
[IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_CONTRACT_SELECTION](../../IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_CONTRACT_SELECTION.md)
selects `.585`, direct bounded implementation, before behavior work. The
selected public source remains `(apb-composition ...)`, adds repeated
`(peripheral INSTANCE OBJECT)` APB completer children, an `(address-map ...)`
with static parameter/generic-like base/size defaults, and `(decode (overlap
reject) (priority source-order) (unmapped-address error))`. Lowering must
generate reusable APB-specific `apb_interconnect.isf` and
`apb_interconnect.fsm` review artifacts before `apb_tb.fsm`, add
`ppif/apb_composition_multi_peripheral.ppif` and `.apb`, report additive
peripheral/address-map/response-mux fields, and preserve all current APB
samples.

APB multi-peripheral interconnect/decode behavior:
[IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_BEHAVIOR](../../IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_BEHAVIOR.md)
ships bounded generated APB composition behavior through
`ppif/apb_composition_multi_peripheral.ppif` and
`ppif/apb_composition_multi_peripheral.apb`. The parser accepts repeated
`(peripheral INSTANCE OBJECT)` APB completer children, static non-overlapping
address windows, and reject/source-order/unmapped-error decode policy.
Lowering emits `apb_interconnect.isf`, `apb_interconnect.fsm`, endpoint FSMs,
and `apb_tb.fsm`; the interconnect fans out decoded `PSEL`, translates local
`PADDR`, muxes selected responses, and returns `PSLVERR` for active unmapped
accesses. Reports preserve authored peripheral names and expose generated
collision-free instance names such as `status_peripheral`.

Post APB multi-peripheral selector:
[IAL2_POST_APB_MULTI_PERIPHERAL_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_MULTI_PERIPHERAL_NEXT_SLICE_SELECTION.md)
selects `.587`, APB sidebands/strobes/byte-lane readiness audit, without
changing behavior. The selector follows live schedule probes through the
public `unsupported_residue` field: top-level multi-peripheral composition no
longer reports the top-level multi-peripheral decode residue, while APB
sideband/strobe, alternate-width, and back-to-back residues remain explicit.
The audit must decide whether `PPROT`, `PSTRB`, byte-lane write semantics,
composition/interconnect propagation, diagnostics, report fields, samples,
support-accounting, and validation should proceed through a public contract,
a lower-layer prerequisite, an alternate-width prerequisite, or explicit
deferral before any APB behavior change.

APB sideband/strobe readiness audit:
[IAL2_APB_SIDEBAND_STROBE_READINESS_AUDIT](../../IAL2_APB_SIDEBAND_STROBE_READINESS_AUDIT.md)
selects `.588`, public APB sideband/strobe contract selection, without
changing behavior. APB `PPROT` and `PSTRB` are not accepted today; authored
`(strobe ...)` and `(protection ...)` bus clauses fail closed. The audit finds
contract selection is ready because the generated IAL1/IAL0 path already has
fixed-width ports, bitwise operations, shifts, concatenation, and masked
field-update support, but the public source syntax, byte-enable semantics,
report migration, support-accounting, diagnostics, samples, and
composition/interconnect propagation still need to be selected before
implementation.

APB sideband/strobe contract selection:
[IAL2_APB_SIDEBAND_STROBE_CONTRACT_SELECTION](../../IAL2_APB_SIDEBAND_STROBE_CONTRACT_SELECTION.md)
selects `.589`, direct bounded implementation, without changing behavior. The
selected source syntax adds requester-side `(protection req_prot width 3)` and
`(write-strobe req_wstrb width 4)` fields plus bus-side `(protection PPROT
width 3)` and `(strobe PSTRB width 4)` on requester, completer, and
composition bus/wiring blocks. The selected 32-bit byte-lane policy maps
`PSTRB[0]` to `PWDATA[7:0]`, `PSTRB[1]` to `PWDATA[15:8]`, `PSTRB[2]` to
`PWDATA[23:16]`, and `PSTRB[3]` to `PWDATA[31:24]`; `PPROT` is propagated and
sampled while protection access-control effects remain deferred.

APB sideband/strobe behavior:
[IAL2_APB_SIDEBAND_STROBE_BEHAVIOR](../../IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md)
ships bounded `PPROT`/`PSTRB` behavior through sideband-aware requester,
multi-register completer, fixed multi-register composition, and
multi-peripheral composition `.ppif` and `.apb` samples. Requesters sample
`req_prot` and `req_wstrb`, drive `PPROT` from the sampled value, drive
`PSTRB` from the sampled strobe only for writes, and clear both sidebands in
the terminal phase. Completers sample `PPROT/PSTRB` during setup detection and
use `PSTRB` as little-endian byte enables for mapped register writes while
preserving unselected bytes. Fixed composition wires the sidebands directly;
multi-peripheral composition fans them out through `apb_interconnect` to each
peripheral-side bus while preserving decoded `PSEL`, local `PADDR`
translation, response muxing, and unmapped active-access `PSLVERR`. Sideband
reports now replace `apb_protection_and_strobes_deferred` with
`apb_protection_policy_effects_deferred`; alternate widths, PPROT
access-control effects, and back-to-back transfer policy remain deferred.

Post APB sideband/strobe selector:
[IAL2_POST_APB_SIDEBAND_STROBE_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_SIDEBAND_STROBE_NEXT_SLICE_SELECTION.md)
selects `.591`, APB public-surface/report-static cleanup, without changing
behavior in `.590`. Focused live report probes confirm sideband-aware APB
reports now carry `apb_protection_policy_effects_deferred`,
`apb_alternate_widths_deferred`, and `apb_back_to_back_policy_deferred`, while
the generic `.ppif` language-surface manifest still has stale APB sideband
deferral wording. The cleanup owner must align public/static prose before APB
alternate widths, PPROT access-control effects, back-to-back policy,
additional APB topology work, AXI/AHB return, direct backend,
verification-output, backend-language variants, or VHDL.

APB public-surface/report-static sync:
[IAL2_APB_PUBLIC_SURFACE_REPORT_STATIC_SYNC](../../IAL2_APB_PUBLIC_SURFACE_REPORT_STATIC_SYNC.md)
synchronizes the generic `.ppif` and `.apb` public manifest wording after
bounded APB sideband/strobe behavior. The generic `.ppif` surface now names
sideband-aware APB requester-transfer, multi-register completer, fixed
multi-register composition, and multi-peripheral composition coverage; the
`.apb` mirror paragraph names the matching profile-alias fixtures. The old
broad "APB sidebands" deferral is gone from the generic `.ppif` boundary.
APB alternate widths, PPROT access-control effects, and back-to-back policy
remain explicit deferred residues. `.592` now owns APB alternate-width
readiness audit.

APB alternate-width readiness:
[IAL2_APB_ALTERNATE_WIDTH_READINESS_AUDIT](../../IAL2_APB_ALTERNATE_WIDTH_READINESS_AUDIT.md)
selects `.593`, public APB alternate-width contract selection, without
changing behavior. Parser syntax already preserves APB width tokens, but
validators and generated behavior still pin the APB slice to 32-bit
address/data/register/address-map widths, 4-bit wait controls, 3-bit `PPROT`,
and 4-bit `PSTRB`. Requester `PSTRB` drive, completer `strb_q`, byte-lane
masks, and address-map width remain hard-coded to the 32-bit/4-strobe shape.
Existing generated IAL1/IAL0 width-bearing ports, bitwise operations,
concatenation, `when-bit`, and masked read-modify-write expressions are enough
for bounded static-width contract selection, so `.593` must settle the public
width matrix before behavior work.

APB alternate-width contract:
[IAL2_APB_ALTERNATE_WIDTH_CONTRACT_SELECTION](../../IAL2_APB_ALTERNATE_WIDTH_CONTRACT_SELECTION.md)
selects `.594`, direct bounded implementation of sideband-aware 16-bit APB
data/strobe variants, without changing behavior. The selected contract keeps
address width and address-map parameter width at 32, completer wait-count
width at 4, `PPROT` at 3, and requester status at 2. New `data16` requester,
multi-register completer, fixed multi-register composition, and
multi-peripheral composition sample pairs will use 16-bit
write/read/register data and 2-bit `PSTRB`/write-strobe, with register and
address-map window alignment tied to the 2-byte data beat. Selected 16-bit
reports replace `apb_alternate_widths_deferred` with narrower
remaining-width residue; `PPROT` policy effects and back-to-back policy remain
deferred.

APB sideband data16 behavior:
[IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR](../../IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md)
ships `.594`, the selected sideband-aware 16-bit APB data/strobe contract.
New `.ppif` and matching `.apb` samples now cover requester-transfer,
multi-register completer, fixed multi-register composition, and
multi-peripheral composition variants with 16-bit `PWDATA`/`PRDATA`/register
data and 2-bit `PSTRB`/write-strobe. Existing 32-bit APB samples remain
unchanged. The data16 completer maps `PSTRB[0]` to `[7:0]` and `PSTRB[1]` to
`[15:8]`; fixed composition decodes the second register at byte address `2`;
multi-peripheral composition accepts 2-byte-aligned 32-bit address-map windows
and ships a `258`-byte status/control split. Data16 reports add
`width_policy` metadata and replace `apb_alternate_widths_deferred` with
`apb_remaining_widths_deferred`; 8-bit/64-bit/non-byte widths, alternate
address or wait-count widths, PPROT effects, and back-to-back policy remain
deferred.

APB PPROT effects readiness:
[IAL2_APB_PPROT_EFFECTS_READINESS_AUDIT](../../IAL2_APB_PPROT_EFFECTS_READINESS_AUDIT.md)
selects `.596`, public APB `PPROT` access-control effects contract selection,
without changing behavior. The current sideband-aware APB paths already
propagate requester `PPROT` through bus, fixed-composition, and
multi-peripheral interconnect wiring, and completers already sample `PPROT`
during setup. Reports still use `apb_protection_policy_effects_deferred`;
the next contract must settle policy vocabulary, denial behavior, `PSTRB`
interaction, composition/interconnect effects, reports, support identities,
diagnostics, validation, and rollback.

APB PPROT effects contract:
[IAL2_APB_PPROT_EFFECTS_CONTRACT_SELECTION](../../IAL2_APB_PPROT_EFFECTS_CONTRACT_SELECTION.md)
selects `.597`, direct bounded implementation of the first APB `PPROT`
access-control effects contract, without changing behavior. The selected
source syntax adds register-local `(access-policy ...)` clauses to
sideband-aware 32-bit APB completer storage registers. The first local
predicate is `(privileged VALUE)`, defined as sampled `PPROT[0] == VALUE`.
Denied mapped accesses complete with normal APB response timing,
`PREADY=1`, and `PSLVERR=1`; denied reads drive `PRDATA=0`, and denied
writes are side-effect-free, including `PSTRB=0`. Fixed and multi-peripheral
composition only propagate `PPROT` and mux the selected response; selected
completers own register-local enforcement. Selected reports will replace
`apb_protection_policy_effects_deferred` with
`apb_additional_protection_policies_deferred`. At that point, data16 policy
effects, additional `PPROT` predicates, global/window/peripheral policies,
interconnect-owned enforcement, back-to-back policy, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.

APB PPROT access-policy behavior:
[IAL2_APB_PPROT_EFFECTS_BEHAVIOR](../../IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md)
ships `.597`, the selected bounded APB `PPROT` access-control behavior. New
sideband-aware 32-bit completer, fixed-composition, and multi-peripheral
composition `.ppif`/`.apb` samples accept register-local `(access-policy ...)`
clauses on completer storage registers. The first public predicate is
`(privileged VALUE)`, defined as sampled `PPROT[0] == VALUE`. Completers
evaluate the selected register's policy at the normal response point: allowed
reads/writes keep existing sideband behavior, denied reads return
`PREADY=1`, `PSLVERR=1`, and `PRDATA=0`, and denied writes return
`PREADY=1` and `PSLVERR=1` without storage updates, including when `PSTRB=0`.
Fixed and multi-peripheral composition only propagate `PPROT/PSTRB` and mux
selected responses; completers own enforcement. Reports add
`protection_policy` metadata and use
`apb_additional_protection_policies_deferred`. At that point, data16 policy
effects, additional predicates, global/window/peripheral policies,
interconnect-owned enforcement, back-to-back policy, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred. `.598`
selected `.599`, APB profile-alias/public-surface synchronization after
`.597`, without behavior changes. `.599` synchronized
`docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md` with the shipped protection alias
behavior, including protection support-accounting prose, CLI examples, report
wording, diagnostics, and narrowed non-goals. `.600` selected `.601`, APB
sideband data16 `PPROT` policy effects readiness audit, without behavior
changes. `.601` audited that readiness and selected `.602`, public contract
selection for sideband data16 APB `PPROT` policy effects, without behavior
changes. A temporary data16 access-policy candidate failed exactly at the
current 32-bit `ApbCompleter` guard, and the audit found no parser, IAL1,
IAL0, report-schema, composition, direct-backend, or VHDL prerequisite before
contract selection. `.602` selected `.603`, direct bounded implementation of
the `sideband_data16_protection` contract, without behavior changes. The
selected sample pairs are data16 protection completer, fixed composition, and
multi-peripheral composition `.ppif`/`.apb` paths; the contract reuses
register-local `allow` / `require (privileged 0|1)`, keeps
`width_policy.selected_contract = sideband_data16`, adds `protection_policy`,
replaces policy-effects residue with
`apb_additional_protection_policies_deferred`, and retains
`apb_remaining_widths_deferred`.

APB data16 PPROT access-policy behavior:
[IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR](../../IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md)
ships `.603`, the selected `sideband_data16_protection` behavior. New data16
protection completer, fixed-composition, and multi-peripheral composition
`.ppif`/`.apb` samples are support-accounted. Sideband-aware data16
multi-register completers accept the same register-local `allow` / `require
(privileged 0|1)` policy syntax as the 32-bit protection path, while preserving
16-bit `PWDATA`/`PRDATA`, 2-bit `PSTRB`, two-byte register/window alignment,
and `width_policy.selected_contract = sideband_data16`. Denied mapped reads
return 16-bit zero data with `PSLVERR=1`; denied writes leave storage
unchanged, including `PSTRB=0`. Fixed and multi-peripheral composition only
propagate `PPROT/PSTRB` and mux responses. Reports add `protection_policy`,
remove `apb_protection_policy_effects_deferred` from the selected data16
protection samples, and keep broader policy, width, back-to-back,
direct-backend, verification-output, backend-language, AXI/AHB, and VHDL work
deferred. `.604` selected `.605`, APB back-to-back transfer policy readiness
audit, without behavior changes. The next audit covers requester transfer
admission, completer setup admission, composition propagation, report/support
accounting movement, diagnostics, validation, rollback, and direct-backend/VHDL
deferral before any timing-policy behavior change.

APB back-to-back readiness audit:
[IAL2_APB_BACK_TO_BACK_READINESS_AUDIT](../../IAL2_APB_BACK_TO_BACK_READINESS_AUDIT.md)
selects `.606`, public APB back-to-back transfer policy contract selection,
without behavior changes. Current requester reports model one outstanding
transfer and deassert `PSEL/PENABLE` in the terminal phase. Current completers
admit setup through `PSEL && !PENABLE` and report one-transfer-at-a-time
assumptions. Fixed and multi-peripheral composition propagate selected endpoint
behavior while requester, completer, top-level composition, and interconnect
reports retain explicit `apb_back_to_back_policy_deferred` residue. The next
contract must settle source vocabulary, explicit versus implicit timing-policy
boundary, requester queued admission, completer setup admission,
composition/interconnect propagation, report/support-accounting movement,
diagnostics, validation, rollback, and direct-backend/VHDL deferral before
behavior work.

APB back-to-back contract selection:
[IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.607`, bounded implementation of the explicit APB back-to-back
timing-policy contract, without behavior changes. The selected requester
transfer syntax is `(timing-policy (back-to-back queued) (queue-depth 1)
(overflow reject))`, and the selected requester response surface requires
`accepted`, `busy`, and a 2-bit `status` field. The selected completer transfer
syntax is `(timing-policy (setup-admission adjacent))`. The first supported
sample family is status-observable requester-transfer, one-register completer,
and fixed one-requester/one-completer composition, each with `.ppif` and
`.apb` coverage. Multi-peripheral propagation, sideband/data16/protection
variants, deeper queues, alternate overflow policies, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.

APB back-to-back behavior:
[IAL2_APB_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_BACK_TO_BACK_BEHAVIOR.md)
ships the selected bounded APB back-to-back timing-policy behavior for the
status-observable requester-transfer, one-register completer, and fixed
one-requester/one-completer composition samples. The requester samples
`ppif/apb_requester_transfer_status_back_to_back.ppif` and `.apb` expose
`accepted`, keep `busy/status`, implement one queued request slot, reject
overflow without overwriting the queued request, and drive queued setup with
`PSEL=1` and `PENABLE=0` without an inserted idle bus cycle. The completer
samples `ppif/apb_completer_back_to_back.ppif` and `.apb` explicitly report
adjacent `PSEL && !PENABLE` setup admission. The fixed-composition samples
`ppif/apb_composition_status_back_to_back.ppif` and `.apb` expose `accepted`
at the top, require compatible endpoint timing policies, report aggregate
`back_to_back_policy` metadata, remove broad
`apb_back_to_back_policy_deferred` residue, and keep narrowed
`apb_additional_back_to_back_policies_deferred` for multi-peripheral
propagation, sideband/data16/protection variants, deeper queues, alternate
overflow policies, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL.

APB multi-peripheral back-to-back readiness:
[IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_READINESS_AUDIT](../../IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_READINESS_AUDIT.md)
audits APB multi-peripheral back-to-back propagation after fixed-composition
behavior shipped. The generated interconnect is propagation-only: it decodes
current `PSEL/PADDR`, forwards `PENABLE`, muxes selected responses, and returns
unmapped errors only for active accesses (`PSEL && PENABLE`). That is
structurally compatible with queued requester setup and per-peripheral adjacent
setup admission. The audit selects `.609`, a direct bounded implementation for
the 32-bit no-sideband multi-peripheral status back-to-back family, while
sideband/data16/protection variants, deeper queues, alternate overflow,
multiple active APB transfers, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.

APB multi-peripheral back-to-back behavior:
[IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md)
ships `.609`, the selected 32-bit no-sideband two-peripheral status
back-to-back family. The new `.ppif` and `.apb` samples reuse the `.607`
requester depth-1 queued overflow-reject policy with `accepted/busy/status`,
require adjacent setup admission on every peripheral completer, preserve the
generated `.isf -> .fsm` review path, and keep the generated interconnect
propagation-only. Queued setup to either peripheral decodes through current
`PSEL/PADDR` with `PENABLE=0`; unmapped errors remain active-access only.
Reports add aggregate `back_to_back_policy`, remove broad
`apb_back_to_back_policy_deferred` only for the selected surfaces, and retain
narrowed `apb_additional_back_to_back_policies_deferred` for
sideband/data16/protection variants, deeper queues, alternate overflow,
multiple active APB transfers, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL.

Post APB multi-peripheral back-to-back selector:
[IAL2_POST_APB_MULTI_PERIPHERAL_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_MULTI_PERIPHERAL_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.611`, APB sideband-aware back-to-back timing-policy readiness audit,
without behavior changes. The selected audit is next because no-sideband fixed
and multi-peripheral back-to-back paths are shipped, while shipped
sideband/data16/protection APB families still retain explicit back-to-back
residue. The audit must settle queued `PPROT/PSTRB` capture, fixed versus
multi-peripheral propagation scope, adjacent completer setup with byte lanes
and endpoint-local policies, report/residue movement, diagnostics,
validation, and rollback before implementation. Data16/protection
back-to-back variants, deeper queues, alternate overflow, accepted-less
requesters, multiple active APB transfers, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.

APB sideband back-to-back readiness audit:
[IAL2_APB_SIDEBAND_BACK_TO_BACK_READINESS_AUDIT](../../IAL2_APB_SIDEBAND_BACK_TO_BACK_READINESS_AUDIT.md)
selects `.612`, bounded requester-first sideband back-to-back implementation,
without behavior changes. No new public timing-policy vocabulary is needed:
the `.606` contract already says accepted requests sample every payload field,
including sidebands when present. The first implementation should add only the
32-bit sideband requester `apb_requester_transfer_sideband_status_back_to_back`
`.ppif`/`.apb` pair, with `PPROT` width 3, `PSTRB` width 4,
`accepted/busy/status`, queued `PPROT/PSTRB` capture, and queued sideband
relaunch. Fixed composition, multi-peripheral composition, completer
timing-policy propagation, data16/protection back-to-back variants, deeper
queues, alternate overflow, accepted-less requesters, multiple active APB
transfers, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.

APB sideband requester back-to-back behavior:
[IAL2_APB_SIDEBAND_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_SIDEBAND_BACK_TO_BACK_BEHAVIOR.md)
ships `.612`, the selected 32-bit sideband-aware requester timing-policy
family. The new `.ppif` and `.apb` samples add `PPROT width 3`, `PSTRB width
4`, `accepted/busy/status`, and the existing depth-1 queued overflow-reject
policy. The generated requester queues `req_prot/req_wstrb` through
`queued_prot/queued_wstrb`, relaunches queued setup without an inserted idle
cycle, drives `PPROT` from the queued value, and masks queued `PSTRB` by the
queued write bit. Reports remove broad `apb_back_to_back_policy_deferred` only
for the selected sideband requester surfaces and retain narrowed future-policy
residue for fixed/multi-peripheral composition, completer propagation,
data16/protection variants, deeper queues, alternate overflow, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL.

APB sideband composition back-to-back readiness audit:
[IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_READINESS_AUDIT](../../IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_READINESS_AUDIT.md)
selects `.614`, public contract selection for the bounded 32-bit
sideband-aware APB completer and fixed-composition timing-policy family,
without behavior changes. The requester prerequisite is present after `.612`,
and existing sideband completer/fixed-composition substrates already sample or
propagate `PPROT/PSTRB`; the remaining guards still reject sideband-aware
adjacent setup and sideband-aware composition timing propagation. `.614` must
settle sample names, one-register completer scope, fixed-composition
propagation, report/support movement, diagnostics, validation, and rollback
before implementation. Multi-peripheral sideband timing propagation,
data16/protection variants, multi-register timing policy, deeper queues,
alternate overflow, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL remain deferred.

APB sideband composition back-to-back contract selection:
[IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.615` to implement the bounded sideband-aware APB completer plus fixed
composition together. The selected public sources are
`ppif/apb_completer_sideband_back_to_back.ppif`, its `.apb` alias,
`ppif/apb_composition_sideband_status_back_to_back.ppif`, and its `.apb`
alias. The completer is one-register, 32-bit, sideband-aware with
`PPROT width 3`, `PSTRB width 4`, and adjacent setup admission. The fixed
composition combines the `.612` sideband requester back-to-back policy with
that completer and sideband-aware wiring. Multi-peripheral sideband timing
propagation, data16/protection variants, multi-register timing policy, deeper
queues, alternate overflow, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.

APB sideband composition back-to-back behavior:
[IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_BEHAVIOR.md)
ships the selected sideband-aware APB completer and fixed-composition
back-to-back behavior. The selected public sources are
`ppif/apb_completer_sideband_back_to_back.ppif`, its `.apb` alias,
`ppif/apb_composition_sideband_status_back_to_back.ppif`, and its `.apb`
alias. Reports expose adjacent setup admission on the sideband completer,
aggregate `back_to_back_policy` on the fixed composition, and narrowed future
residue for data16/protection variants, multi-register timing policy, broader
timing-policy families, deeper queues, alternate overflow, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL.

Post APB sideband composition back-to-back selector:
[IAL2_POST_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.617`, public contract selection for bounded 32-bit sideband-aware
APB multi-peripheral back-to-back propagation, without behavior changes. The
current sideband multi-peripheral substrate already propagates `PPROT/PSTRB`,
but timing propagation still fails at the no-sideband-only multi-peripheral
guard. `.617` must settle exact public sources, endpoint/interconnect
compatibility, report/support movement, diagnostics, validation, and rollback
before implementation. Data16/protection variants, multi-register timing
policy, deeper queues, alternate overflow, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.

APB sideband multi-peripheral back-to-back contract selection:
[IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.618` to implement exactly
`ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif` and
its `.apb` alias. The selected contract is a bounded two-peripheral 32-bit
sideband composition with requester `accepted/busy/status`, depth-1 queued
requester timing, `PPROT width 3`, `PSTRB width 4`, adjacent setup admission on
every one-register peripheral completer, and the existing status/control
address-map/decode shape. Reports must remove broad back-to-back residue for
the selected top/requester/interconnect/peripheral surfaces and retain narrowed
future-policy plus protection-policy effects residue. Data16/protection timing
variants, multi-register timing policy, deeper queues, alternate overflow,
direct backend, verification-output, backend-language variants, AXI, AHB, and
VHDL remain deferred.

APB sideband multi-peripheral back-to-back behavior:
[IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md)
ships selected 32-bit sideband-aware APB multi-peripheral status
back-to-back propagation through the generated interconnect. The public sources
are
`ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif` and
its `.apb` alias. The generated requester queues `PPROT/PSTRB`, the
interconnect decodes the queued setup through current `PSEL/PADDR` with
`PENABLE` low and fans out `PPROT/PSTRB`, and every selected peripheral uses
adjacent sideband setup admission. Reports remove broad back-to-back residue
for the selected top/requester/interconnect/peripheral surfaces while keeping
narrowed future-policy and protection-policy effects residue explicit.
Data16/protection timing variants, multi-register timing policy, deeper queues,
alternate overflow, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL remain deferred.

Post APB sideband multi-peripheral back-to-back selector:
[IAL2_POST_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.620`, APB data16/protection back-to-back timing-policy readiness
audit, without behavior changes. Current data16, protection, and
data16-protection requester/composition samples still report no aggregate
`back_to_back_policy` and keep broad `apb_back_to_back_policy_deferred`, while
timing-policy guards remain bounded to selected 32-bit no-sideband or selected
32-bit sideband-aware one-register families. `.620` must decide whether the
next owner is data16-only, protection-only, combined data16-protection,
multi-register adjacent setup, requester/completer prerequisite, or explicit
deferral before behavior changes.

APB data16/protection back-to-back readiness audit:
[IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_READINESS_AUDIT](../../IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_READINESS_AUDIT.md)
selects `.621`, public contract selection for a bounded APB sideband-aware
multi-register back-to-back timing-policy prerequisite, without behavior
changes. The audit finds that shipped data16/protection completer and
composition samples all use multi-register storage, while current
timing-policy guards still reject multi-register completer storage for adjacent
setup and composition propagation. `.621` must settle exact sideband-aware
32-bit multi-register samples, endpoint compatibility, report/support movement,
diagnostics, validation, rollback, and deferrals before implementation.

APB sideband multi-register back-to-back contract selection:
[IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.622`, direct bounded implementation of exactly the standalone
completer and fixed-composition APB sideband-aware multi-register
back-to-back contract, without behavior changes. The selected public source
pairs are `apb_completer_multi_register_sideband_back_to_back` and
`apb_composition_multi_register_sideband_status_back_to_back` in both `.ppif`
and `.apb` forms. The first implementation is limited to a 32-bit
sideband-aware two-register no-policy completer with adjacent setup admission
and a fixed one-requester/one-completer composition over the `.612` sideband
requester. Multi-peripheral multi-register propagation, data16/protection
variants, deeper queues, alternate overflow, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.

APB sideband multi-register back-to-back behavior:
[IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md)
ships the selected bounded APB sideband-aware multi-register timing-policy
prerequisite. The public sources are
`ppif/apb_completer_multi_register_sideband_back_to_back.ppif`,
`ppif/apb_completer_multi_register_sideband_back_to_back.apb`,
`ppif/apb_composition_multi_register_sideband_status_back_to_back.ppif`, and
`ppif/apb_composition_multi_register_sideband_status_back_to_back.apb`. The
standalone completer accepts adjacent setup for the selected 32-bit
sideband-aware two-register no-policy shape, decodes `reg0` at address `0` and
`reg1` at address `4`, samples `PPROT/PSTRB`, and applies byte-lane writes. The
fixed composition combines that completer with the `.612` sideband requester
queue, reports aggregate `back_to_back_policy`, and keeps broader APB timing
families deferred. `.623` selects the next APB data16/protection
back-to-back owner before any further behavior change.

Post APB sideband multi-register back-to-back selector:
[IAL2_POST_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.624`, public contract selection for bounded APB sideband-aware
data16 back-to-back timing-policy behavior, without behavior changes. Live
reports over representative data16, protection, and data16-protection sources
still keep broad `apb_back_to_back_policy_deferred`. Data16 is selected first
because it widens queued sideband payloads to 16-bit data and `PSTRB width 2`
without adding register-local denied-access side effects. Protection-only
timing, combined data16-protection timing, multi-peripheral multi-register
timing, deeper queues, alternate overflow, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.

APB data16 back-to-back contract selection:
[IAL2_APB_DATA16_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_DATA16_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.625` to directly implement the bounded APB sideband-aware data16
back-to-back timing-policy contract for six public sources:
`ppif/apb_requester_transfer_sideband_data16_status_back_to_back.ppif` and
`.apb`, `ppif/apb_completer_multi_register_sideband_data16_back_to_back.ppif`
and `.apb`, and
`ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif`
and `.apb`. The selected family uses `accepted/busy/status` depth-1 queued
requester timing, 16-bit data, `PSTRB width 2`, a two-register no-policy
adjacent completer with `reg0` at address `0` and `reg1` at address `2`, and
fixed one-requester/one-completer propagation. Protection-only timing,
combined data16-protection timing, multi-peripheral multi-register timing,
deeper queues, alternate overflow, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.

APB data16 back-to-back behavior:
[IAL2_APB_DATA16_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_DATA16_BACK_TO_BACK_BEHAVIOR.md)
ships `.625`, selected sideband-aware data16 requester, standalone
two-register completer, and fixed-composition back-to-back timing behavior.
The requester queues 16-bit write data plus `PPROT width 3` and
`PSTRB width 2`; the completer admits adjacent setup for `reg0` at address `0`
and `reg1` at address `2`; the fixed composition exposes aggregate
`back_to_back_policy` while retaining future-policy, remaining-width, and
protection-policy residue. Protection-only timing, combined data16-protection
timing, multi-peripheral multi-register timing, deeper queues, alternate
overflow, direct backend, verification-output, backend-language variants, AXI,
AHB, and VHDL remain deferred. `.626` selects the next APB
data16/protection back-to-back owner without behavior changes.

Post APB data16 back-to-back selector:
[IAL2_POST_APB_DATA16_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_DATA16_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.627`, public contract selection for bounded APB sideband-aware
protection back-to-back timing, without behavior changes. Live protection and
data16-protection reports still expose `protection_policy`, have no
`back_to_back_policy`, and keep broad `apb_back_to_back_policy_deferred`.
A temporary protected adjacent-setup candidate fails at the current no-policy
timing guard, so protection-only timing is selected before combined
data16-protection timing. Multi-peripheral multi-register timing, deeper
queues, alternate overflow, accepted-less requesters, multiple active APB
transfers, direct backend, verification-output, backend-language variants, AXI,
AHB, and VHDL remain deferred.

APB protection back-to-back contract selection:
[IAL2_APB_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.628` to directly implement exactly four APB sideband-aware
protection back-to-back sources: protected standalone completer `.ppif` and
`.apb`, plus protected fixed-composition status `.ppif` and `.apb`. The
selected completer is 32-bit with `PPROT width 3`, `PSTRB width 4`, `reg0` at
address `0` with read-allow/write-privileged policy, and `reg1` at address `4`
with read/write privileged policy. The fixed composition combines that
protected adjacent completer with the `.612` queued sideband requester while
leaving policy enforcement in the completer. Data16-protection timing,
multi-peripheral multi-register timing, deeper queues, alternate overflow,
accepted-less requesters, multiple active APB transfers, broader protection
policies, direct backend, verification-output, backend-language variants, AXI,
AHB, and VHDL remain deferred.

APB protection back-to-back behavior:
[IAL2_APB_PROTECTION_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_PROTECTION_BACK_TO_BACK_BEHAVIOR.md)
ships `.628`, the selected bounded APB sideband-aware protection
back-to-back timing-policy behavior. The shipped `.ppif` and `.apb` sample
pairs are `apb_completer_multi_register_sideband_protection_back_to_back` and
`apb_composition_multi_register_sideband_protection_status_back_to_back`. The
standalone completer accepts adjacent setup for the exact protected 32-bit
two-register shape, preserves `PPROT` allow/deny and zero-strobe behavior, and
keeps `reg0` at address `0` plus `reg1` at address `4`. The fixed composition
propagates the `.612` queued sideband requester into the protected completer,
reports aggregate `back_to_back_policy`, removes broad back-to-back residue
only for the selected surfaces, and retains narrowed future-timing,
broader-protection, remaining-width, and multi-peripheral decode residue.
`.629` is the next selector for remaining APB timing residue; combined
data16-protection timing, multi-peripheral multi-register timing, deeper
queues, alternate overflow, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.

Post APB protection back-to-back selector:
[IAL2_POST_APB_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.630`, public contract selection for bounded APB sideband-aware
data16-protection back-to-back timing, without behavior changes. Live
data16-protection reports still expose `protection_policy`, have no
`back_to_back_policy`, and keep broad `apb_back_to_back_policy_deferred`.
A temporary data16-protection adjacent-setup candidate still fails at the
current selected-family timing guard, so `.630` must settle the exact public
sources, 16-bit protected two-register shape, requester/status requirements,
report/residue movement, diagnostics, validation, and rollback before
implementation. The selected status/control multi-peripheral
data16-protection timing subset later shipped in `.634`; broader
multi-peripheral multi-register timing, deeper queues, alternate overflow,
direct backend, verification-output, backend-language variants, AXI, AHB, and
VHDL remain deferred.

APB data16-protection back-to-back contract selection:
[IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.631` to directly implement exactly four APB sideband-aware
data16-protection back-to-back public sources: protected standalone data16
completer `.ppif` and `.apb`, plus protected fixed-composition data16 status
`.ppif` and `.apb`. The selected completer is 16-bit with `PPROT width 3`,
`PSTRB width 2`, `reg0` at address `0` with read-allow/write-privileged
policy, and `reg1` at address `2` with read/write privileged policy. The
fixed composition combines that protected data16 adjacent completer with the
`.625` queued data16 sideband requester while leaving policy enforcement in
the completer. The selected status/control multi-peripheral
data16-protection timing subset later shipped in `.634`; broader
multi-peripheral multi-register timing, deeper queues, alternate overflow,
accepted-less requesters, multiple active APB transfers, broader protection
policies, direct backend, verification-output, backend-language variants, AXI,
AHB, and VHDL remain deferred.

APB data16-protection back-to-back behavior:
[IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md)
ships the selected APB sideband-aware data16-protection back-to-back public
sources. The protected standalone data16 completer now accepts adjacent setup
for the selected two-register shape with `reg0` at address `0`, `reg1` at
address `2`, `PPROT width 3`, and `PSTRB width 2`, while preserving allowed,
denied, zero-strobe, byte-lane, and unmapped behavior. The protected
fixed-composition status sample propagates the `.625` queued data16 sideband
requester into that completer, exposes aggregate `back_to_back_policy`, and
keeps policy enforcement in the completer. The `.632` post selector records
the remaining APB timing residue before behavior changes; multi-peripheral
data16-protection timing, broader multi-peripheral multi-register timing,
deeper queues, alternate overflow, accepted-less requesters, multiple active
APB transfers, broader protection policies, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred there.

Post APB data16-protection back-to-back selector:
[IAL2_POST_APB_DATA16_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_DATA16_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.633`, public contract selection for bounded APB sideband-aware
multi-peripheral data16-protection back-to-back timing, without behavior
changes. Existing multi-peripheral data16-protection reports already expose
16-bit data, `PPROT width 3`, `PSTRB width 2`, and completer-owned protection
enforcement, but still have no aggregate `back_to_back_policy` and retain
broad `apb_back_to_back_policy_deferred`. `.633` is the selected contract
owner that settles source names, static topology scope,
requester/completer/interconnect timing requirements, queued setup decode,
sideband propagation, report/residue movement, support accounting,
diagnostics, validation, and rollback before implementation. Broader
multi-peripheral multi-register timing, deeper queues, alternate overflow,
accepted-less requesters, multiple active APB transfers, broader protection
policies, direct backend, verification-output, backend-language variants, AXI,
AHB, and VHDL remain deferred.

APB multi-peripheral data16-protection back-to-back contract selection:
[IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.634` to directly implement exactly two public sources:
`ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif`
and its `.apb` alias. The selected contract keeps the existing two-peripheral
status/control protected data16 topology, requester `accepted/busy/status`
depth-1 queued timing, adjacent setup on both peripheral completers, 16-bit
data, `PPROT width 3`, `PSTRB width 2`, 2-byte-aligned windows at `0` and
`258`, propagation-only interconnect decode, peripheral-owned protection
enforcement, and aggregate multi-peripheral `back_to_back_policy` reporting.
Broader multi-peripheral multi-register timing, deeper queues, alternate
overflow, accepted-less requesters, multiple active APB transfers, broader
protection policies, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.

APB multi-peripheral data16-protection back-to-back behavior:
[IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md)
ships those two selected public sources. The generated requester keeps
depth-1 queued `accepted/busy/status` timing and relaunches queued 16-bit
`PWDATA`, `PPROT`, and 2-bit `PSTRB`; the generated interconnect propagates
queued setup without inserting an idle cycle, decodes the `0` and `258`
windows, translates `PADDR_CONTROL`, and remains enforcement-free; the status
and control peripheral completers own register-local privileged `PPROT[0]`
enforcement and preserve data16 byte-lane, zero-strobe, denied-access,
unmapped, and adjacent-setup behavior. Selected reports remove broad
`apb_back_to_back_policy_deferred` and retain narrowed future timing,
broader-protection, and remaining-width residue. `.635` is now the next
selector for the remaining APB back-to-back timing frontier. Broader
multi-peripheral multi-register timing, deeper queues, alternate overflow,
accepted-less requesters, multiple active APB transfers, broader protection
policies, direct backend, verification-output, backend-language variants, AXI,
AHB, and VHDL remain deferred.

Post APB multi-peripheral data16-protection back-to-back selector:
[IAL2_POST_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.636`, readiness audit for broader APB multi-peripheral
multi-register back-to-back timing propagation, without behavior changes. The
audit is next because broader multi-peripheral multi-register propagation is
the first explicit remaining composition timing residue after `.634`, while
deeper queues, alternate overflow, accepted-less requesters, multiple active
APB transfers, broader protection policies, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred behind future exact owners.

APB multi-peripheral multi-register back-to-back readiness audit:
[IAL2_APB_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT](../../IAL2_APB_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md)
selects `.637`, public contract selection for bounded 32-bit APB
sideband-aware protection multi-peripheral back-to-back timing, without
behavior changes. The selected candidate family starts from
`ppif/apb_composition_multi_peripheral_sideband_protection.ppif`: 32-bit
data/addressing, `PPROT width 3`, `PSTRB width 4`, two protected registers
per peripheral at byte addresses `0` and `4`, status/control windows at `0`
and `256`, propagation-only interconnect decode, peripheral-owned protection
enforcement, and broad deferred back-to-back residue. `.637` must settle the
public contract before any behavior change.

APB multi-peripheral protection back-to-back contract selection:
[IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.638` to directly implement exactly
`ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.ppif`
and its `.apb` alias. The selected public contract uses the existing
two-peripheral status/control protected 32-bit topology with requester
`accepted/busy/status` depth-1 queued timing, adjacent setup on both
peripheral completers, `PPROT width 3`, `PSTRB width 4`, 4-byte-aligned
windows at `0` and `256`, propagation-only interconnect decode,
peripheral-owned protection enforcement, and aggregate multi-peripheral
`back_to_back_policy` reporting.

APB multi-peripheral protection back-to-back behavior:
[IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_BEHAVIOR.md)
ships the selected bounded 32-bit sideband-aware protection timing family.
The `.ppif` and `.apb` sources are support-accounted, generate
requester/interconnect/status/control review artifacts, propagate queued
32-bit `PWDATA` plus `PPROT/PSTRB` without idle-cycle insertion, preserve
peripheral-completer-owned privileged `PPROT[0]` enforcement, remove broad
`apb_back_to_back_policy_deferred`, and keep narrowed future timing,
broader-protection, and alternate-width residue. `.639` is the next selector
for the remaining APB back-to-back timing residue after this protected
multi-peripheral family shipped.

Post APB multi-peripheral protection back-to-back selector:
[IAL2_POST_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.640`, readiness audit for APB no-policy multi-peripheral
multi-register back-to-back timing. Fixed no-policy multi-register timing is
already shipped for selected 32-bit sideband and sideband data16 fixed
compositions, while multi-peripheral no-policy timing is shipped only for
one-register peripheral shapes. The current multi-peripheral timing guard
still rejects broader two-register no-policy peripheral storage, so `.640`
must settle source shape, endpoint storage, interconnect propagation,
report/residue movement, diagnostics, support accounting, validation,
rollback, and docs before any behavior change.

APB no-policy multi-peripheral multi-register back-to-back readiness audit:
[IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT](../../IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md)
selects `.641`, public contract selection for the bounded 32-bit
sideband-aware no-policy multi-peripheral multi-register back-to-back timing
family. Fixed sideband no-policy multi-register timing and sideband data16
no-policy multi-register timing are support-accounted on fixed compositions,
while multi-peripheral no-policy timing is currently one-register per
peripheral. In-memory two-register no-policy multi-peripheral candidates fail
closed at the current multi-peripheral timing guard, so `.641` must settle
public source names, 32-bit register/window shape,
requester/completer/interconnect timing requirements, report/residue
movement, support-accounting identities, diagnostics, validation, rollback,
and docs before implementation.

APB no-policy multi-peripheral multi-register back-to-back contract selection:
[IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.642`, direct implementation of exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif`
and its `.apb` alias. The selected contract is the bounded two-peripheral
32-bit sideband-aware no-policy multi-register family with requester
`accepted/busy/status`, depth-1 queued overflow-reject timing,
`PPROT width 3`, `PSTRB width 4`, status/control windows at bases `0` and
`256`, adjacent setup on both peripherals, and exactly `reg0` at address `0`
plus `reg1` at address `4` with no access policy in each peripheral. Reports
shall add aggregate `back_to_back_policy`, remove broad back-to-back residue
for selected surfaces, retain narrowed future-policy, protection-effects, and
alternate-width residue, and keep sideband data16 no-policy multi-peripheral
multi-register timing deferred.

APB no-policy multi-peripheral multi-register back-to-back behavior:
[IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md)
ships the selected bounded 32-bit sideband-aware no-policy timing behavior for
exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif`
and its `.apb` alias. The generated requester exposes
`accepted/busy/status`, accepts one active transfer plus one queued next
transfer, and relaunches queued 32-bit `PWDATA` plus `PPROT/PSTRB`. The
generated interconnect propagates queued setup without idle-cycle insertion,
decodes status/control windows at bases `0` and `256`, translates
`PADDR_CONTROL`, muxes selected responses, and remains access-policy-free.
Both peripheral completers use adjacent setup and exactly no-policy `reg0` at
local byte address `0` plus `reg1` at local byte address `4`, with 32-bit
reset-0 storage and 4-bit byte-lane writes. Reports add aggregate
multi-peripheral `back_to_back_policy`, remove broad
`apb_back_to_back_policy_deferred`, and retain narrowed future timing,
protection-policy-effects, and alternate-width residue. Sideband data16
no-policy multi-peripheral multi-register timing and generalized
multi-peripheral multi-register shapes remain deferred.

Post APB no-policy multi-peripheral multi-register back-to-back selector:
[IAL2_POST_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.644`, public contract selection for bounded APB sideband-aware
data16 no-policy multi-peripheral multi-register back-to-back timing. The
selector changes no behavior. The next owner is data16 no-policy because fixed
data16 no-policy reg0/reg1 timing, data16-protection multi-peripheral timing,
and 32-bit no-policy multi-peripheral reg0/reg1 timing are already shipped,
while no public data16 no-policy multi-peripheral multi-register back-to-back
source exists yet. `.644` must settle source names, data16 status/control
window shape, endpoint/interconnect timing requirements, no-policy `reg0`/`reg1`
storage, report/residue movement, support-accounting identities, diagnostics,
validation, rollback, and docs before implementation.

APB data16 no-policy multi-peripheral multi-register back-to-back contract
selection:
[IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.645`, direct implementation of exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif`
and its `.apb` alias. The selected contract is one requester, two
peripherals, 32-bit addresses, 16-bit APB/register data, `PPROT width 3`,
`PSTRB width 2`, status/control windows at bases `0` and `258`, adjacent setup
on both peripherals, and exactly no-policy `reg0` at local address `0` plus
`reg1` at local address `2` in each peripheral. Reports shall add aggregate
`back_to_back_policy`, remove broad back-to-back residue, and retain narrowed
future-policy, protection-effects, and remaining-width residue.

APB data16 no-policy multi-peripheral multi-register back-to-back behavior:
[IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md)
ships the selected bounded APB sideband-aware data16 no-policy timing
behavior for exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif`
and its `.apb` alias. The generated requester exposes
`accepted/busy/status`, accepts one active transfer plus one queued next
transfer, and relaunches queued 16-bit `PWDATA` plus `PPROT/PSTRB`. The
generated interconnect propagates queued setup without idle-cycle insertion,
decodes status/control windows at bases `0` and `258`, translates
`PADDR_CONTROL`, muxes selected responses, and remains access-policy-free.
Both peripheral completers use adjacent setup and exactly no-policy `reg0` at
local byte address `0` plus `reg1` at local byte address `2`, with 16-bit
reset-0 storage and 2-bit byte-lane writes. Reports add aggregate
multi-peripheral `back_to_back_policy`, remove broad
`apb_back_to_back_policy_deferred`, and retain narrowed future timing,
protection-policy-effects, and remaining-width residue. Data16-protection
generalization and generalized multi-peripheral multi-register shapes remain
deferred.

Post APB data16 no-policy multi-peripheral multi-register back-to-back
selector:
[IAL2_POST_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.647`, readiness audit for APB data16-protection generalization,
without behavior changes. Selected no-policy multi-peripheral multi-register
timing is shipped for both 32-bit and data16 families, selected protected
data16 timing is shipped for fixed and multi-peripheral status/control
families, and no explicit public multi-peripheral multi-register
data16-protection source family exists yet. `.647` must decide whether the
next exact owner is public contract selection, direct implementation of an
already-selected family, a source-shape/report-static prerequisite, or
explicit deferral. Generalized register shapes, deeper queues, alternate
overflow, accepted-less requesters, multiple active APB transfers, bus
matrices, scoreboards, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL remain deferred.

APB data16-protection multi-peripheral multi-register readiness audit:
[IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT](../../IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md)
selects `.648`, public contract selection for bounded APB sideband-aware
data16-protection multi-peripheral multi-register back-to-back timing, without
behavior changes. Fixed data16-protection multi-register timing and selected
multi-peripheral data16-protection status/control timing are shipped, but no
explicit public multi-peripheral multi-register data16-protection source
family exists yet. `.648` must settle exact source names, storage/policy
shape, report/residue movement, support accounting, diagnostics, validation,
rollback, docs, and Knowledge Map before behavior changes. Generalized
register shapes, deeper queues, alternate overflow, accepted-less requesters,
multiple active APB transfers, bus matrices, scoreboards, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.

APB data16-protection multi-peripheral multi-register contract selection:
[IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.649`, direct implementation of exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif`
and its `.apb` alias. The selected contract is one requester, two
peripherals, 32-bit addresses, 16-bit APB/register data, `PPROT width 3`,
`PSTRB width 2`, status/control windows at bases `0` and `258`, adjacent setup
on both peripherals, and exactly protected `reg0` at local address `0` plus
protected `reg1` at local address `2` in each peripheral. `reg0` reads are
allowed and writes require privileged `PPROT[0]`; `reg1` reads and writes
require privileged `PPROT[0]`. Status/control protected storage
generalization beyond `.634`, generalized register shapes, deeper queues,
alternate overflow, accepted-less requesters, multiple active APB transfers,
bus matrices, scoreboards, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.

APB data16-protection multi-peripheral multi-register back-to-back behavior:
[IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md)
ships the selected bounded APB sideband-aware data16-protection timing
behavior for exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif`
and its `.apb` alias. The generated requester exposes
`accepted/busy/status`, accepts one active transfer plus one queued next
transfer, and relaunches queued 16-bit `PWDATA` plus `PPROT/PSTRB`. The
generated interconnect propagates queued setup without idle-cycle insertion,
decodes status/control windows at bases `0` and `258`, translates
`PADDR_CONTROL`, muxes selected responses, and remains protection-enforcement
free. Both peripheral completers use adjacent setup and exactly protected
`reg0` at local byte address `0` plus protected `reg1` at local byte address
`2`, with 16-bit reset-0 storage, 2-bit byte-lane writes, `reg0` read allow
plus privileged writes, and `reg1` privileged reads/writes. Reports add
aggregate multi-peripheral `back_to_back_policy`, remove broad
`apb_back_to_back_policy_deferred` and old
`apb_protection_policy_effects_deferred`, and retain narrowed future timing,
additional-protection-policy, and remaining-width residue. Status/control
protected storage generalization beyond the selected family and generalized
multi-peripheral multi-register shapes remain deferred.

Post APB data16-protection multi-peripheral multi-register back-to-back
selector:
[IAL2_POST_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.651`, readiness audit for APB status/control protected-storage
generalization, without behavior changes. The selector chooses that residue
because `.649` closed the explicit selected data16-protection `reg0`/`reg1`
two-peripheral timing surface while `.638` and `.634` already ship selected
32-bit and data16 status/control protected two-peripheral timing families.
`.651` must decide whether the next exact owner is public contract selection,
direct implementation, a smaller source-shape/report-static prerequisite, or
explicit deferral before generalized multi-peripheral multi-register timing
families and wider backend/protocol surfaces.

APB status/control protected-storage generalization readiness audit:
[IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_GENERALIZATION_READINESS_AUDIT](../../IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_GENERALIZATION_READINESS_AUDIT.md)
selects `.652`, public contract selection for a bounded APB status/control
protected-storage generalization, without behavior changes. The audit found
that the selected 32-bit and data16 status/control protected families already
ship peripheral-owned privileged `PPROT[0]` enforcement, requester
`accepted/busy/status`, queue-depth `1`, overflow `reject`, adjacent setup,
and propagation-only interconnect timing. `.652` must decide whether the
generalization is new public source pairs, report/static residue cleanup,
alias/support accounting expansion, or explicit deferral before behavior.

APB status/control protected-storage generalization contract selection:
[IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_GENERALIZATION_CONTRACT_SELECTION](../../IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_GENERALIZATION_CONTRACT_SELECTION.md)
selects `.653`, report/static residue cleanup for the already-shipped bounded
APB status/control protected-storage generalization, without behavior changes.
The existing `.638` 32-bit status/control protected source pair and `.634`
data16 status/control protected source pair are the public contract. `.653`
must refine the narrowed timing residue and related static prose so selected
status/control protected storage is not named as live residue.

APB status/control protected-storage residue cleanup:
[IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_RESIDUE_CLEANUP](../../IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_RESIDUE_CLEANUP.md)
ships the `.652` selected report/static cleanup. The narrowed APB timing
residue now states that selected status/control protected storage is complete
for the bounded 32-bit and data16 two-peripheral families, while generalized
multi-peripheral multi-register timing remains future work. No source,
support-accounting, parser, timing, HDL, APB transaction, AXI, AHB, or VHDL
behavior changed.

APB generalized multi-peripheral multi-register timing readiness audit:
[IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_TIMING_READINESS_AUDIT](../../IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_TIMING_READINESS_AUDIT.md)
selects `.655`, public contract selection for bounded APB sideband-aware
32-bit protected `reg0`/`reg1` multi-peripheral multi-register back-to-back
timing, without behavior changes. The shipped selected families already cover
32-bit/data16 no-policy `reg0`/`reg1`, data16 protected `reg0`/`reg1`, and
32-bit/data16 status/control protected timing. A corrected 32-bit protected
`reg0`/`reg1` candidate still fails at the current multi-peripheral timing
guard, so exact public sources, reports, residue movement, support
accounting, diagnostics, validation, rollback, docs, and Knowledge Map are
settled before implementation.

APB 32-bit protection multi-peripheral multi-register contract selection:
[IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.656`, direct implementation of exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.ppif`
and its `.apb` alias, without behavior changes. The selected family uses
32-bit APB/register data, `PPROT width 3`, `PSTRB width 4`, windows at bases
`0` and `256`, adjacent setup on both peripherals, and protected `reg0` at
local address `0` plus protected `reg1` at local address `4` in each
peripheral.

APB 32-bit protection multi-peripheral multi-register back-to-back behavior:
[IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md)
ships the selected bounded APB sideband-aware 32-bit protection timing
behavior for exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.ppif`
and its `.apb` alias. The generated requester exposes
`accepted/busy/status`, accepts one active transfer plus one queued next
transfer, and relaunches queued 32-bit `PWDATA` plus `PPROT/PSTRB`. The
generated interconnect propagates queued setup without idle-cycle insertion,
decodes status/control windows at bases `0` and `256`, translates
`PADDR_CONTROL`, muxes selected responses, and remains protection-enforcement
free. Both peripheral completers use adjacent setup and exactly protected
`reg0` at local byte address `0` plus protected `reg1` at local byte address
`4`, with 32-bit reset-0 storage, 4-bit byte-lane writes, `reg0` read allow
plus privileged writes, and `reg1` privileged reads/writes. Reports add
aggregate multi-peripheral `back_to_back_policy`, remove broad
`apb_back_to_back_policy_deferred` and old
`apb_protection_policy_effects_deferred`, and retain narrowed future timing,
additional-protection-policy, and alternate-width residue. Generalized
multi-peripheral multi-register shapes remain deferred.

Post APB 32-bit protection multi-peripheral multi-register back-to-back
selector:
[IAL2_POST_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.658`, readiness audit for generalized APB multi-peripheral
multi-register source shapes, without behavior changes. The selected audit is
next because the explicit selected 16/32-bit `reg0`/`reg1`
no-policy/protection multi-peripheral timing families and the selected
status/control protected families are shipped, while a generalized shape would
need public rules for register counts, names, addresses, reset values, policy
matrices, and possibly peripheral counts before any implementation.

APB generalized multi-peripheral multi-register source-shape readiness audit:
[IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SOURCE_SHAPE_READINESS_AUDIT](../../IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SOURCE_SHAPE_READINESS_AUDIT.md)
selects `.659`, public contract selection for one bounded generalized APB
multi-peripheral multi-register source-shape family, without behavior
changes. The selected exact 16/32-bit no-policy/protected `reg0`/`reg1` and
status/control protected two-peripheral timing families are shipped, while
current `ApbComposition` remains exact-family guarded. Generalized acceptance
needs public rules for register cardinality, names, local addresses, reset
values, policy matrices, per-peripheral consistency, support accounting,
diagnostics, validation, and residue movement before implementation.

APB generalized multi-peripheral multi-register source-shape contract:
[IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SOURCE_SHAPE_CONTRACT_SELECTION](../../IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SOURCE_SHAPE_CONTRACT_SELECTION.md)
selects `.660`, direct implementation of exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.ppif`
and its `.apb` alias, without behavior changes. The selected family is the
first bounded generalized source-shape step: 32-bit sideband-aware APB, one
requester, exactly two peripheral completers, no register-local access
policies, matching source-ordered `reg0..regN` register sets, two to four
registers per peripheral, public representative `reg0/reg1/reg2` at local
addresses `0/4/8`, status/control windows at `0` and `256`, depth-1 queued
requester timing, adjacent setup, overflow `reject`, and propagation-only
interconnect decode.

APB generalized multi-peripheral multi-register back-to-back behavior:
[IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md)
ships `.660`, the selected bounded APB sideband-aware no-policy generalized
register-set multi-peripheral timing behavior. The supported public sources
are
`ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.ppif`
and its `.apb` alias. They generate a requester, status/control peripheral
completers, an interconnect, and `apb_tb`; propagate queued 32-bit `PWDATA`
plus `PPROT/PSTRB`; keep status/control windows at `0` and `256`; and use
no-policy `reg0/reg1/reg2` at local addresses `0/4/8` in the public
representative. The admitted register-set family remains bounded to matching
no-policy `reg0..regN` storage with two to four registers per peripheral.
Protected/data16 generalized register sets, broader cardinality/peripheral
count, deeper queues, alternate overflow, accepted-less requesters, multiple
active transfers, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL remain deferred.

Post APB generalized multi-peripheral multi-register selector:
[IAL2_POST_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.662`, direct implementation of the bounded APB sideband-aware
data16 no-policy generalized `reg0..regN` register-set multi-peripheral
timing behavior, without behavior changes. The selected public source pair is
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back.ppif`
and its `.apb` alias. The contract mirrors `.660`'s no-policy generalized
shape but uses 16-bit data, `PSTRB width 2`, 2-byte register stride, public
representative `reg0/reg1/reg2` at local addresses `0/2/4`, and data16
status/control windows at bases `0` and `258` with size `258`. Protected
generalized register sets, broader cardinality/peripheral count, deeper
queues, alternate overflow, accepted-less requesters, multiple active
transfers, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.

APB data16 generalized multi-peripheral multi-register back-to-back behavior:
[IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md)
ships `.662`, the selected bounded APB sideband-aware data16 no-policy
generalized `reg0..regN` register-set multi-peripheral timing behavior. The
supported public sources are
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back.ppif`
and its `.apb` alias. They generate a requester, status/control peripheral
completers, an interconnect, and `apb_tb`; propagate queued 16-bit `PWDATA`
plus `PPROT/PSTRB`; keep status/control windows at `0` and `258`; use 2-bit
`PSTRB`; and use no-policy `reg0/reg1/reg2` at local addresses `0/2/4` in the
public representative. The admitted register-set family remains bounded to
matching no-policy `reg0..regN` storage with two to four registers per
peripheral. Protected generalized register sets, broader cardinality/peripheral
count, deeper queues, alternate overflow, accepted-less requesters, multiple
active transfers, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL remain deferred.

Post APB data16 generalized multi-peripheral multi-register selector:
[IAL2_POST_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.664`, public contract selection for bounded APB sideband-aware
32-bit protected generalized `reg0..regN` register-set multi-peripheral
back-to-back timing, without behavior changes. The selector follows `.662`
because no-policy generalized timing is shipped for both selected 32-bit and
data16 widths, while protected generalized register sets still need a public
access-policy matrix for `reg2..regN` before any timing guard widens. `.664`
must settle source names, register cardinality, local-address rules, protected
policy matrix, report/support shape, diagnostics, validation, rollback, docs,
Knowledge Map, and the next owner. Data16 protected generalized register sets,
broader cardinality/peripheral count, deeper queues, alternate overflow,
accepted-less requesters, multiple active transfers, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.

APB protected generalized multi-peripheral multi-register contract:
[IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.665`, direct implementation of exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back.ppif`
and its `.apb` alias, without behavior changes. The selected family is
bounded to 32-bit sideband-aware APB, one requester, exactly two peripheral
completers, matching protected `reg0..regN` register sets with two to four
registers per peripheral, public representative `reg0/reg1/reg2` at local
addresses `0/4/8`, status/control windows at `0` and `256`, queue-depth `1`,
overflow `reject`, adjacent setup on every peripheral, and propagation-only
interconnect decode. The selected policy matrix preserves `.656`: `reg0`
reads are allowed, `reg0` writes require privileged `PPROT[0] == 1`, and every
`reg1..regN` read/write requires privileged `PPROT[0] == 1`. Data16 protected
generalized register sets, broader cardinality/peripheral count, deeper
queues, alternate overflow, accepted-less requesters, multiple active
transfers, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.

APB protected generalized multi-peripheral multi-register behavior:
[IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md)
ships `.665`, the selected bounded APB sideband-aware 32-bit protected
generalized `reg0..regN` register-set multi-peripheral timing behavior. The
supported public sources are
`ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back.ppif`
and its `.apb` alias. They generate a requester, status/control peripheral
completers, an interconnect, and `apb_tb`; propagate queued 32-bit `PWDATA`
plus `PPROT/PSTRB`; keep status/control windows at `0` and `256`; use 4-bit
`PSTRB`; and keep protection enforcement in the peripheral completers rather
than the interconnect. The public representative uses protected
`reg0/reg1/reg2` at local addresses `0/4/8`; the admitted family remains
bounded to matching protected `reg0..regN` storage with two to four registers
per peripheral. The policy matrix keeps `reg0` readable, requires privileged
`PPROT[0] == 1` for `reg0` writes, and requires privileged `PPROT[0] == 1`
for every `reg1..regN` read/write. Data16 protected generalized register
sets, broader cardinality/peripheral count, deeper queues, alternate overflow,
accepted-less requesters, multiple active transfers, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.

Post APB protected generalized multi-peripheral multi-register selector:
[IAL2_POST_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.667`, public contract selection for bounded APB sideband-aware
data16 protected generalized `reg0..regN` register-set multi-peripheral
back-to-back timing, without behavior changes. The selector follows `.665`
because generalized no-policy timing is shipped for both selected widths and
protected generalized timing is shipped for 32-bit, while data16 protected
generalized register sets remain explicitly deferred by the current APB guards
and residue. `.667` must settle exact public source names, object id, source
anchor, 16-bit APB/register data, `PSTRB width 2`, `PPROT width 3`,
status/control windows at `0` and `258`, local addresses `0/2/4/...`,
protected access-policy matrix, report shape, support accounting, diagnostics,
validation, rollback, docs, Knowledge Map, and next owner before behavior
changes. Broader register cardinality, more-than-two-peripheral families,
deeper queues, alternate overflow, accepted-less requesters, multiple active
transfers, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.

APB data16 protected generalized multi-peripheral multi-register contract:
[IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION](../../IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md)
selects `.668`, direct implementation of exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.ppif`
and its `.apb` alias, without behavior changes. The selected family is
bounded to 16-bit sideband-aware APB, one requester, exactly two peripheral
completers, matching protected `reg0..regN` register sets with two to four
registers per peripheral, public representative `reg0/reg1/reg2` at local
addresses `0/2/4`, status/control windows at `0` and `258`, queue-depth `1`,
overflow `reject`, adjacent setup on every peripheral, and propagation-only
interconnect decode. The selected policy matrix keeps `reg0` reads allowed,
requires privileged `PPROT[0] == 1` for `reg0` writes, and requires privileged
`PPROT[0] == 1` for every `reg1..regN` read/write. Broader
cardinality/peripheral count, deeper queues, alternate overflow,
accepted-less requesters, multiple active transfers, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.

APB data16 protected generalized multi-peripheral multi-register behavior:
[IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR](../../IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md)
ships `.668`, the selected bounded APB sideband-aware data16 protected
generalized `reg0..regN` register-set multi-peripheral timing behavior. The
supported public sources are
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.ppif`
and its `.apb` alias. They generate a requester, status/control peripheral
completers, an interconnect, and `apb_tb`; propagate queued 16-bit `PWDATA`
plus `PPROT/PSTRB`; keep status/control windows at `0` and `258`; use 2-bit
`PSTRB`; and keep protection enforcement in the peripheral completers rather
than the interconnect. The public representative uses protected
`reg0/reg1/reg2` at local addresses `0/2/4`; the admitted family remains
bounded to matching protected `reg0..regN` storage with two to four registers
per peripheral. The policy matrix keeps `reg0` readable, requires privileged
`PPROT[0] == 1` for `reg0` writes, and requires privileged `PPROT[0] == 1`
for every `reg1..regN` read/write. Broader cardinality/peripheral count,
deeper queues, alternate overflow, accepted-less requesters, multiple active
transfers, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.

Post APB data16 protected generalized multi-peripheral selector:
[IAL2_POST_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md)
selects `.670`, readiness audit for broader APB generalized register-set
cardinality beyond the selected two-to-four-register families, without
behavior changes. The selector follows `.668` because the selected
two-peripheral generalized register-set matrix is now shipped for 32-bit and
data16 widths, with and without the selected protection matrix, while live
`ApbCompleter` and `ApbComposition` guards still cap each generalized family
at `maximum_count = 4` and exactly two peripheral completers. `.670` must
decide whether the next exact owner is a first bounded cardinality widening, a
smaller report/static, diagnostic, address-map, or fixture prerequisite,
more-than-two-peripheral generalized ownership, or explicit deferral. No
parser, generator, public source, support-accounting, generated artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior changed in `.669`.

APB generalized multi-peripheral register-set cardinality audit:
[IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_READINESS_AUDIT](../../IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_READINESS_AUDIT.md)
selects `.671`, public contract selection for the first bounded APB
sideband-aware 32-bit no-policy five-register generalized `reg0..regN`
register-set multi-peripheral back-to-back timing family, without behavior
changes. The audit found the shared generalized predicates are parameterized
by count/stride/data width and the existing 32-bit no-policy window can hold a
five-register representative, but public source names, whether the family
widens to `maximum_count = 5`, support identities, report shape, diagnostics,
generated-artifact probes for `reg3/reg4`, rollback, and next owner still
need a public contract before implementation. Data16 five-register families,
protected five-register families, more-than-five registers,
more-than-two-peripheral families, queues, alternate overflow,
accepted-less requester timing, multiple active transfers, bus matrices,
scoreboards, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.

APB generalized five-register contract:
[IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION](../../IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION.md)
selected `.672`, direct implementation of exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back.ppif`
and its byte-identical `.apb` profile alias, without behavior changes. The
selected contract widens only the shipped 32-bit sideband-aware no-policy
two-peripheral generalized register-set family from `maximum_count = 4` to
`maximum_count = 5`. The public representative uses
`reg0/reg1/reg2/reg3/reg4` at local addresses `0/4/8/12/16`, 32-bit data,
`PPROT width 3`, `PSTRB width 4`, status/control windows at `0` and `256`,
queue-depth `1`, overflow `reject`, adjacent setup, no register-local
`access-policy`, and propagation-only interconnect decode. `.672` must add the
new support identities and coverage buckets, report both peripheral register
arrays as `[reg0, reg1, reg2, reg3, reg4]`, prove generated `reg3/reg4`
storage/read/write/byte-lane behavior, and keep data16 five-register,
protected five-register, more-than-five-register, more-than-two-peripheral,
deeper-queue, alternate-overflow, accepted-less, multiple-active, bus-matrix,
scoreboard, direct-backend, verification-output, backend-language variant,
AXI, AHB, and VHDL behavior deferred.

APB generalized five-register behavior:
[IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR](../../IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md)
ships the selected APB sideband-aware 32-bit no-policy five-register
generalized register-set timing behavior through the byte-identical
`.ppif`/`.apb` source pair. The admitted 32-bit no-policy two-peripheral
generalized family now accepts source-ordered `reg0..regN` sets with two,
three, four, or five registers, 4-byte spacing, 32-bit data, reset `0`, no
register-local `access-policy`, queue-depth `1`, overflow `reject`, adjacent
setup on both peripheral completers, and propagation-only interconnect
decode. Reports show both status and control peripheral register arrays as
`[reg0, reg1, reg2, reg3, reg4]` for the five-register representative,
support accounting tracks the new PPIF/profile-alias identities, generated
artifacts carry `reg3/reg4` storage/read/write and byte-lane behavior, and
data16 five-register, protected five-register, more-than-five-register,
more-than-two-peripheral, deeper-queue, alternate-overflow, accepted-less,
multiple-active, bus-matrix, scoreboard, direct-backend, verification-output,
backend-language variant, AXI, AHB, and VHDL behavior remain deferred. `.673`
now owns the next APB timing/register-set residue selector.

Post APB generalized five-register selector:
[IAL2_POST_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md)
selects `.674`, public contract selection for the bounded APB sideband-aware
data16 no-policy five-register generalized `reg0..regN` register-set
multi-peripheral back-to-back timing family, without behavior changes. The
selection follows `.672` because the data16 no-policy family is the nearest
cardinality sibling: it keeps protection-policy changes out of scope while
requiring a public contract for 16-bit data, `PSTRB width 2`, status/control
windows at `0` and `258`, representative local addresses `0/2/4/6/8`,
whether the admitted data16 no-policy family widens to `maximum_count = 5`,
support identities, report shape, diagnostics, validation, rollback, docs,
Knowledge Map, and next owner. No parser, generator, public source,
support-accounting, report, generated artifact, HDL/runtime, APB transaction,
AXI, AHB, or VHDL behavior changed in `.673`.

APB data16 generalized five-register contract:
[IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION](../../IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION.md)
selects `.675`, direct implementation of exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back.ppif`
and its byte-identical `.apb` profile alias, without behavior changes. The
selected contract widens only the shipped data16 sideband-aware no-policy
two-peripheral generalized register-set family from `maximum_count = 4` to
`maximum_count = 5`. The public representative uses
`reg0/reg1/reg2/reg3/reg4` at local addresses `0/2/4/6/8`, 16-bit data,
`PPROT width 3`, `PSTRB width 2`, status/control windows at `0` and `258`,
queue-depth `1`, overflow `reject`, adjacent setup, no register-local
`access-policy`, and propagation-only interconnect decode. `.675` must add the
new support identities and coverage buckets, report both peripheral register
arrays as `[reg0, reg1, reg2, reg3, reg4]`, prove generated `reg3/reg4`
storage/read/write/byte-lane behavior, and keep protected five-register,
more-than-five-register, more-than-two-peripheral, deeper-queue,
alternate-overflow, accepted-less, multiple-active, bus-matrix, scoreboard,
direct-backend, verification-output, backend-language variant, AXI, AHB, and
VHDL behavior deferred.

APB data16 generalized five-register behavior:
[IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR](../../IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md)
ships the selected APB sideband-aware data16 no-policy five-register
generalized register-set timing behavior through the byte-identical
`.ppif`/`.apb` source pair. The admitted data16 no-policy two-peripheral
generalized family now accepts source-ordered `reg0..regN` sets with two,
three, four, or five registers, 2-byte spacing, 16-bit data, reset `0`, no
register-local `access-policy`, queue-depth `1`, overflow `reject`, adjacent
setup on both peripheral completers, status/control windows `0` and `258`,
and propagation-only interconnect decode. Reports show both status and
control peripheral register arrays as `[reg0, reg1, reg2, reg3, reg4]` for
the five-register representative, support accounting tracks the new
PPIF/profile-alias identities, generated artifacts carry `reg3/reg4`
storage/read/write and byte-lane behavior, and protected five-register,
more-than-five-register, more-than-two-peripheral, deeper-queue,
alternate-overflow, accepted-less, multiple-active, bus-matrix, scoreboard,
direct-backend, verification-output, backend-language variant, AXI, AHB, and
VHDL behavior remain deferred. `.676` now owns the next APB timing/register-set
residue selector.

Post APB data16 generalized five-register selector:
[IAL2_POST_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md)
selects `.677`, public contract selection for the bounded APB sideband-aware
32-bit protected five-register generalized `reg0..regN` register-set
multi-peripheral timing family, without behavior changes. The selector
follows `.675` because no-policy five-register timing is shipped for both
32-bit and data16 while protected generalized timing remains capped at
two-to-four registers. The 32-bit protected path keeps data16 stride/strobe
details out of the first protected cardinality widening and requires a public
contract for 32-bit data, `PPROT width 3`, `PSTRB width 4`, status/control
windows `0` and `256`, representative local addresses `0/4/8/12/16`,
admitted-family `maximum_count = 5`, protected access-policy matrix, support
identities, report shape, diagnostics, validation, rollback, docs, Knowledge
Map, and next owner before behavior changes.

APB protected generalized five-register contract:
[IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION](../../IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION.md)
selects `.678`, direct implementation of exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.ppif`
and its byte-identical `.apb` profile alias, without behavior changes. The
selected contract widens only the shipped 32-bit sideband-aware protected
two-peripheral generalized `reg0..regN` register-set family from
`maximum_count = 4` to `maximum_count = 5`. The public representative uses
`reg0/reg1/reg2/reg3/reg4` at local addresses `0/4/8/12/16`, 32-bit data,
`PPROT width 3`, `PSTRB width 4`, status/control windows `0` and `256`,
queue-depth `1`, overflow `reject`, adjacent setup, propagation-only
interconnect decode, and the selected register-local privileged `PPROT[0]`
access-policy matrix. `.678` must add the public source pair, support
identities, report/residue movement, diagnostics, generated-artifact probes,
focused tests, docs, and Knowledge Map coverage while keeping data16 protected
five-register, more-than-five-register, more-than-two-peripheral,
deeper-queue, alternate-overflow, accepted-less, multiple-active,
alternate-policy, interconnect-owned-policy, bus-matrix, scoreboard,
direct-backend, verification-output, backend-language variant, AXI, AHB, and
VHDL behavior deferred.

APB protected generalized five-register behavior:
[IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR](../../IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md)
ships the selected APB sideband-aware 32-bit protected five-register
generalized `reg0..regN` register-set multi-peripheral timing behavior. The
public `.ppif` source and byte-identical `.apb` profile alias now admit
two-to-five 32-bit protected registers per selected peripheral, with the
five-register representative at local addresses `0/4/8/12/16`, `PPROT width
3`, `PSTRB width 4`, status/control windows `0` and `256`, queue-depth `1`,
overflow `reject`, adjacent setup, propagation-only interconnect decode, and
peripheral-owned register-local protection. Reports preserve
`[reg0, reg1, reg2, reg3, reg4]`, support accounting records the new PPIF and
profile-alias identities, and generated artifacts include `reg3/reg4`
storage, read/write, byte-lane, and denied-protection branches. Data16
protected five-register, more-than-five-register, more-than-two-peripheral,
deeper-queue, alternate-overflow, accepted-less, multiple-active,
alternate-policy, interconnect-owned-policy, bus-matrix, scoreboard,
direct-backend, verification-output, backend-language variant, AXI, AHB, and
VHDL behavior remain deferred.

Post APB protected generalized five-register selector:
[IAL2_POST_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md)
selects `.680`, public contract selection for the bounded APB sideband-aware
data16 protected five-register generalized `reg0..regN` register-set
multi-peripheral timing family, without behavior changes. The selector
follows `.678` because no-policy five-register timing is shipped for 32-bit
and data16, 32-bit protected five-register timing is shipped, and data16
protected generalized timing remains capped at two-to-four registers. The
next contract owner must settle exact `.ppif`/`.apb` source names, object id,
anchor, `PPROT width 3`, `PSTRB width 2`, status/control windows `0` and
`258`, representative local addresses `0/2/4/6/8`, admitted-family
`maximum_count = 5`, protected access-policy matrix, support identities,
report shape, diagnostics, validation, rollback, docs, Knowledge Map, and
implementation owner before behavior changes.

APB data16 protected generalized five-register contract:
[IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION](../../IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION.md)
selects `.681`, direct implementation of exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back.ppif`
and its byte-identical `.apb` profile alias, without behavior changes. The
selected contract widens only the shipped data16 sideband-aware protected
two-peripheral generalized `reg0..regN` register-set family from
`maximum_count = 4` to `maximum_count = 5`. The public representative uses
`reg0/reg1/reg2/reg3/reg4` at local addresses `0/2/4/6/8`, 16-bit data,
`PPROT width 3`, `PSTRB width 2`, status/control windows `0` and `258`,
queue-depth `1`, overflow `reject`, adjacent setup, propagation-only
interconnect decode, and the selected register-local privileged `PPROT[0]`
access-policy matrix. `.681` must add the public source pair, support
identities, report/residue movement, diagnostics, generated-artifact probes,
focused tests, docs, and Knowledge Map coverage while keeping broader APB,
AXI, AHB, and VHDL behavior deferred.

APB data16 protected generalized five-register behavior:
[IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR](../../IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md)
ships that selected bounded APB sideband-aware data16 protected
five-register generalized `reg0..regN` register-set multi-peripheral timing
behavior through the exact `.ppif` source and byte-identical `.apb` profile
alias. The admitted data16 protected two-peripheral generalized family now
covers two-to-five registers per peripheral, with public representative
`reg0/reg1/reg2/reg3/reg4` at local addresses `0/2/4/6/8`, 16-bit data,
`PPROT width 3`, `PSTRB width 2`, status/control windows `0` and `258`,
queue-depth `1`, overflow `reject`, adjacent setup, propagation-only
interconnect decode, peripheral-owned protection, and the selected
register-local privileged `PPROT[0]` access-policy matrix. More-than-five,
more-than-two-peripheral, deeper-queue, alternate-overflow, accepted-less,
multiple-active, alternate-policy, interconnect-owned-policy, bus-matrix,
scoreboard, direct-backend, verification-output, backend-language variant,
AXI, AHB, and VHDL behavior remain deferred.

Post APB data16 protected generalized five-register selector:
[IAL2_POST_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md)
selects `.683`, a no-behavior readiness audit for broader APB generalized
register-set cardinality after the 32-bit no-policy, data16 no-policy,
32-bit protected, and data16 protected five-register siblings all shipped.
The audit must decide whether the next exact owner is more-than-five
registers, more-than-two peripheral completers, a smaller report/static
diagnostic/address-map/public-fixture prerequisite, or explicit deferral
before any behavior changes. `.682` keeps deeper queues, alternate overflow,
accepted-less, multiple-active, alternate-policy, interconnect-owned-policy,
bus-matrix, scoreboard, direct-backend, verification-output,
backend-language variant, AXI, AHB, and VHDL behavior unchanged.

Broader APB generalized cardinality readiness audit:
[IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BROADER_CARDINALITY_READINESS_AUDIT](../../IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BROADER_CARDINALITY_READINESS_AUDIT.md)
selects `.684`, public contract selection for the first bounded APB
sideband-aware 32-bit no-policy six-register generalized `reg0..regN`
register-set multi-peripheral timing family. The audit chooses six registers
before more-than-two peripherals because it is the smallest step beyond the
current `maximum_count = 5` guard, keeps exactly two peripheral completers,
and avoids data16 stride/strobe and protection-policy changes. `.684` must
settle `reg0/reg1/reg2/reg3/reg4/reg5` local addresses `0/4/8/12/16/20`,
support identities, reports, diagnostics, validation, rollback, docs,
Knowledge Map, and implementation owner before behavior changes.

Six-register APB generalized contract selection:
[IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_CONTRACT_SELECTION](../../IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_CONTRACT_SELECTION.md)
selects `.685`, direct implementation of the bounded APB sideband-aware
32-bit no-policy six-register generalized `reg0..regN` register-set
multi-peripheral timing family. The public source pair is
`ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back.ppif`
and `.apb`; the representative uses `reg0` through `reg5` at local addresses
`0/4/8/12/16/20`. The implementation may widen only the selected 32-bit
no-policy generalized two-peripheral family to `maximum_count = 6`; data16,
protected, more-than-six-register, more-than-two-peripheral, direct-backend,
backend-language, AXI, AHB, and VHDL behavior remain deferred.

Six-register APB generalized behavior:
[IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_BEHAVIOR](../../IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_BEHAVIOR.md)
ships `.685`, bounded APB sideband-aware 32-bit no-policy six-register
generalized `reg0..regN` register-set multi-peripheral timing behavior. The
public source pair is
`ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back.ppif`
and `.apb`; the representative uses `reg0` through `reg5` at local addresses
`0/4/8/12/16/20`. The admitted no-policy two-peripheral family now accepts
two through six source-ordered registers, preserves 32-bit data,
`PPROT width 3`, `PSTRB width 4`, queue-depth `1`, overflow `reject`,
adjacent setup, status/control windows at `0` and `256`, propagation-only
interconnect decode, and no interconnect-owned protection predicate. Reports
list status/control register arrays as
`[reg0, reg1, reg2, reg3, reg4, reg5]`; support accounting tracks the new
`.ppif` and `.apb` identities; focused CLI, parser, schedule, semantic,
outdir, HDL, support-accounting, and capability tests cover `reg5`
storage/read/write and byte-lane behavior. Data16 six-register, protected
six-register, more-than-six-register, more-than-two-peripheral,
direct-backend, backend-language, AXI, AHB, and VHDL behavior remain
deferred.

Post six-register APB generalized selector:
[IAL2_POST_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_NEXT_SLICE_SELECTION](../../IAL2_POST_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_NEXT_SLICE_SELECTION.md)
selects `.687`, public contract selection for bounded APB sideband-aware
data16 no-policy six-register generalized `reg0..regN` register-set
multi-peripheral timing, without behavior changes. Data16 no-policy is next
because it is the nearest unprotected cardinality sibling after `.685`, keeps
the exactly-two-peripheral topology, avoids the protection-policy matrix, and
forces the 16-bit data, 2-bit `PSTRB`, 2-byte stride, and status/control
windows at `0` and `258` to be settled before implementation. A temporary
data16 six-register strict-check probe fails closed at the current data16
generalized storage-shape diagnostic with no support-accounting match. `.687`
must settle the exact public `.ppif`/`.apb` source names, object metadata,
`reg0` through `reg5` local addresses `0/2/4/6/8/10`, whether the data16
no-policy family widens to `maximum_count = 6`, report/support identities,
diagnostics, validation, rollback, docs, Knowledge Map, and next owner before
behavior changes. Protected six-register, more-than-six-register,
more-than-two-peripheral, direct-backend, backend-language, AXI, AHB, and VHDL
behavior remain deferred.

Data16 six-register APB generalized contract:
[IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_CONTRACT_SELECTION](../../IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_CONTRACT_SELECTION.md)
selects `.688`, direct implementation of bounded APB sideband-aware data16
no-policy six-register generalized `reg0..regN` register-set
multi-peripheral timing, without behavior changes. The selected public source
pair is
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif`
and `.apb`; the representative uses `reg0` through `reg5` at local addresses
`0/2/4/6/8/10`. The implementation may widen only the selected data16
no-policy generalized two-peripheral family to `maximum_count = 6`, preserving
16-bit data, `PPROT width 3`, `PSTRB width 2`, queue-depth `1`, overflow
`reject`, adjacent setup, status/control windows at `0` and `258`,
propagation-only interconnect decode, and no interconnect-owned protection
predicate. Protected six-register, more-than-six-register,
more-than-two-peripheral, direct-backend, backend-language, AXI, AHB, and VHDL
behavior remain deferred.

Data16 six-register APB generalized behavior:
[IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_BEHAVIOR](../../IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_BEHAVIOR.md)
ships the selected bounded APB sideband-aware data16 no-policy six-register
generalized `reg0..regN` register-set multi-peripheral timing behavior. The
public `.ppif` source and byte-identical `.apb` profile alias now accept the
selected two-peripheral family with two to six data16 no-policy registers per
peripheral. The public representative uses `reg0` through `reg5` at local
addresses `0/2/4/6/8/10`, 16-bit data, 2-bit `PSTRB`, status/control windows
at `0` and `258`, queue-depth `1`, overflow `reject`, adjacent setup on both
completers, and propagation-only interconnect decode with no
interconnect-owned protection predicate. Protected data16 six-register,
protected 32-bit six-register, more-than-six-register,
more-than-two-peripheral, direct-backend, backend-language, AXI, AHB, and VHDL
behavior remain deferred. The protocol-wide IAL2 AXI/APB/AHB mdBook coverage
mandate across user-friendly, more-control, and raw/full-control modes is
task-tree-owned by `.689` before broad book rewrites or new protocol-wide
examples.
