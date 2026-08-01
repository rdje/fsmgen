# AHB and Integration Backlog

IAL2 AHB `.ahb` profile-alias behavior:
[IAL2_AHB_PROFILE_ALIAS_BEHAVIOR](../../IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md)
ships `.ahb` as the bounded AHB requester profile alias. The alias mirrors
`ppif/ahb_requester.ppif` at `ppif/ahb_requester.ahb`, keeps explicit
`(profile ahb)`, accepts exactly one `(ahb-requester amba_requester ...)`
object, lowers through generated `amba_requester.isf` before generated
`amba_requester.fsm`, and support-accounts as
`intent.ahb_profile_alias_requester` with source kind `ial2_profile_alias`.
AHB completers/subordinates, interconnect/decode, scoreboards, full-manager
behavior, direct backend, verification-output, backend-language variants, and
VHDL remain future task-tree-owned work.

Post AHB profile-alias selector:
[IAL2_POST_AHB_PROFILE_ALIAS_NEXT_SLICE_SELECTION](../../IAL2_POST_AHB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md)
selects `.702`, AHB completer/subordinate readiness audit, after requester
`.ppif` and `.ahb` support shipped. The selector keeps current requester
behavior unchanged and records that interconnect/decode depends on a selected
subordinate endpoint shape first.

AHB completer/subordinate readiness audit:
[IAL2_AHB_COMPLETER_SUBORDINATE_READINESS_AUDIT](../../IAL2_AHB_COMPLETER_SUBORDINATE_READINESS_AUDIT.md)
selects `.703`, lower-layer AHB subordinate seed contract selection. The audit
finds the current AHB evidence is requester-only and that no shipped AHB
completer/subordinate/slave fixture or generator exists, so IAL2 AHB
completer/subordinate contract selection remains deferred until the seed
contract is selected.

AHB subordinate seed prerequisite selection:
[IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION](../../IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION.md)
selects `.704`, AHB subordinate source-reference and seed-evidence audit. The
selector found no local AHB/AHB-Lite source reference under `docs/vendor/` and
current shipped AHB evidence remains requester-only, so the direct lower-layer
seed contract remains deferred until subordinate signal/timing/storage/response
and error-policy facts are source-backed.

AHB subordinate source-reference seed-evidence audit:
[IAL2_AHB_SUBORDINATE_SOURCE_REFERENCE_SEED_EVIDENCE_AUDIT](../../IAL2_AHB_SUBORDINATE_SOURCE_REFERENCE_SEED_EVIDENCE_AUDIT.md)
selects `.705`, AHB/AHB-Lite local source-reference import prerequisite,
before source-fact extraction or seed contract selection. The audit found no
local AHB/AHB-Lite source reference artifact and no curated AHB subordinate
source-evidence inventory.

AHB local source-reference import:
[IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT_BLOCKER](../../IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT_BLOCKER.md)
records the historical `.705` blocker.
[IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT](../../IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT.md)
records the `.706` import of the user-approved Arm AMBA AHB Protocol
Specification PDF under `docs/vendor/arm/amba/ahb/`. Source material is now
available locally.
[IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY](../../IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md)
records the `.707` source-backed subordinate fact extraction.
[IAL2_AHB_SUBORDINATE_SEED_CONTRACT_SELECTION](../../IAL2_AHB_SUBORDINATE_SEED_CONTRACT_SELECTION.md)
records the `.708` lower-layer seed contract selection. The selected future
direct seed is `fsm/ahb_lite_subordinate.fsm`, module
`ahb_lite_subordinate`, support-accounting identity
`protocol.ahb_lite_subordinate`, with bounded AHB-Lite/common-AHB
single-register behavior.
[IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR](../../IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md)
records the `.709` shipped direct seed behavior and support-accounting entry.
[IAL2_AHB_COMPLETER_SUBORDINATE_POST_SEED_READINESS_AUDIT](../../IAL2_AHB_COMPLETER_SUBORDINATE_POST_SEED_READINESS_AUDIT.md)
records the `.710` no-behavior post-seed readiness audit and selects `.711`,
public IAL2 AHB subordinate/completer contract selection, before any IAL2 AHB
completer/subordinate behavior ships.
[IAL2_AHB_SUBORDINATE_PUBLIC_CONTRACT_SELECTION](../../IAL2_AHB_SUBORDINATE_PUBLIC_CONTRACT_SELECTION.md)
selected the `.711` future public source `ppif/ahb_lite_subordinate.ppif`,
object `(ahb-subordinate ahb_lite_subordinate ...)`, generated
`ahb_lite_subordinate.isf` before `ahb_lite_subordinate.fsm`, report schema
`fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, support identity
`intent.ppif_ahb_lite_subordinate`, and `.712`, a no-behavior
generated-IAL1/IAL0/SV substrate audit before implementation.
[IAL2_AHB_SUBORDINATE_GENERATED_IAL1_SUBSTRATE_AUDIT](../../IAL2_AHB_SUBORDINATE_GENERATED_IAL1_SUBSTRATE_AUDIT.md)
records the `.712` generated-substrate audit. The core AHB subordinate
transaction flow is representable through generated IAL1, but implementation
is still deferred until generated-IAL1 output default/reset semantics can
prove reset/idle outputs such as `HREADYOUT=1`; `.713` owns that no-behavior
contract selection.
[IAL2_GENERATED_IAL1_OUTPUT_DEFAULT_RESET_CONTRACT_SELECTION](../../IAL2_GENERATED_IAL1_OUTPUT_DEFAULT_RESET_CONTRACT_SELECTION.md)
selects the `.713` generated-IAL1 actor interface output `(reset VALUE)` and
`(default VALUE)` contract and routes implementation to `.714`.
[IAL2_GENERATED_IAL1_OUTPUT_DEFAULT_RESET_BEHAVIOR](../../IAL2_GENERATED_IAL1_OUTPUT_DEFAULT_RESET_BEHAVIOR.md)
records the `.714` shipped substrate: generated-IAL1 outputs now accept
non-negative integer literal reset/default values on resolved positive integer
widths, lower reset metadata into generated `.fsm` `+size`, and lower idle
defaults into generated transaction `<-` output assignments. `.715` now owns
public AHB subordinate `.ppif` implementation over that substrate.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.715` ships that public subordinate path:
`ppif/ahb_lite_subordinate.ppif` now lowers through generated
`ahb_lite_subordinate.isf` before generated `ahb_lite_subordinate.fsm`, emits
HDL module `ahb_lite_subordinate`, reports schema
`fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, and support-accounts as
`intent.ppif_ahb_lite_subordinate`. Remaining AHB subordinate work is the
`.ahb` alias, optional signals, burst `SEQ` continuation, byte-lane/narrow
transfers, legacy two-bit `HRESP`, and interconnect/decode.
`.716` selects `.717`, public AHB subordinate `.ahb` profile-alias contract
selection. At `.716` closeout, behavior was unchanged: use
`ppif/ahb_lite_subordinate.ppif` for the subordinate IAL2 path, and `.ahb`
remains requester-only until a later exact implementation owner.
`.717` selects `.718`, bounded implementation of public AHB subordinate `.ahb`
profile-alias exposure. The selected future source is
`ppif/ahb_lite_subordinate.ahb`, mirroring
`ppif/ahb_lite_subordinate.ppif`, with support identity
`intent.ahb_profile_alias_subordinate`, source kind `ial2_profile_alias`, and
coverage key `ial2_ahb_profile_alias_subordinate_pipeline_cli`. At `.717`
closeout, behavior was still unchanged until `.718` implemented that alias.
`.718` ships that selected public AHB subordinate `.ahb` profile alias at
`ppif/ahb_lite_subordinate.ahb`. It mirrors
`ppif/ahb_lite_subordinate.ppif`, keeps generated
`ahb_lite_subordinate.isf` before generated `ahb_lite_subordinate.fsm`,
reports schema `fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, removes
`ahb_subordinate_profile_alias_deferred` only from subordinate `.ahb` reports,
and support-accounts as `intent.ahb_profile_alias_subordinate` with source kind
`ial2_profile_alias`.
`.719` selects `.720`, AHB interconnect/decode readiness audit, after requester
and subordinate `.ppif`/`.ahb` public entrypoints shipped. The readiness audit
must reconcile requester-side `ahb_interconnect_decode_deferred` and
subordinate-side `ahb_interconnect_generation_deferred` residue before any
fabric behavior.
`.720` selects `.721`, public AHB interconnect/decode contract selection. The
first contract boundary is generic `.ppif`, one requester, one subordinate, one
static address window, generated AHB-specific review artifacts, and no
multi-subordinate fabric or aggregate `.ahb` alias yet.
`.721` selects future `ppif/ahb_interconnect.ppif`, report schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, support identity
`intent.ppif_ahb_interconnect`, generated `ahb_interconnect.isf` before
`ahb_interconnect.fsm`, aggregate `ahb_tb.fsm`, and `.722`, a generated
substrate audit before implementation.
`.722` finds no generated-IAL1/IAL0/SV substrate repair is required before the
selected bounded AHB interconnect/decode implementation. `.723` owns direct
implementation of the generic `.ppif` source, one-requester/one-subordinate
decode, generated `ahb_interconnect.isf`/`.fsm`, aggregate `ahb_tb.fsm`, and
the selected report/support-accounting contract.
`.723` ships `ppif/ahb_interconnect.ppif` as the selected bounded public AHB
interconnect/decode source. It embeds one requester, one subordinate, and one
interconnect object, lowers through generated `amba_requester.isf`,
`ahb_lite_subordinate.isf`, and `ahb_interconnect.isf`, emits generated
`amba_requester.fsm`, `ahb_lite_subordinate.fsm`, `ahb_interconnect.fsm`, and
aggregate `ahb_tb.fsm`, and emits HDL module `ahb_tb`. The report schema is
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`; support accounting records
`intent.ppif_ahb_interconnect`, `source_kind ppif`, and coverage
`ial2_ppif_ahb_interconnect_pipeline_cli`. The shipped decode is one static
window at base 0 size 4, fixed `HGRANT=1`, decoded `HSEL_REGS`, global
`HREADY`, one-bit subordinate `HRESP_REGS` to two-bit requester `HRESP`
OKAY/ERROR mapping, and interconnect-owned two-cycle unmapped active-transfer
ERROR. Aggregate `.ahb` aliases, multi-subordinate fabrics, multiple managers,
bus matrices, optional signals, burst `SEQ` continuation, byte-lane/narrow
transfers, direct backend behavior, verification-output generation, AXI/APB
behavior, and VHDL remain future task-tree-owned work. `.724` owns the next
no-behavior selector after this shipped interconnect.
`.724` selects `.725`, AHB aggregate `.ahb` profile-alias contract selection.
That selector made no behavior change at the time:
`ppif/ahb_interconnect.ppif` remained the shipped aggregate source and the
interconnect report kept `ahb_aggregate_profile_alias_deferred` until the
selected alias implementation owner.
`.725` selects `.726`, bounded implementation of the public aggregate AHB
`.ahb` profile-alias source `ppif/ahb_interconnect.ahb`. The selected alias
must mirror `ppif/ahb_interconnect.ppif`, keep explicit `(profile ahb)`,
preserve generated requester/subordinate/interconnect `.isf` and `.fsm`
review artifacts plus aggregate `ahb_tb.fsm`, use support identity
`intent.ahb_profile_alias_interconnect`, source kind `ial2_profile_alias`,
coverage `ial2_ahb_profile_alias_interconnect_pipeline_cli`, and remove
`ahb_aggregate_profile_alias_deferred` only from aggregate `.ahb` reports.
`.726` ships that alias. FSMGen accepts `ppif/ahb_interconnect.ahb` as the
bounded aggregate AHB profile alias, keeps authored `.ahb` source identity in
check/semantic/schedule/support-accounting surfaces, preserves generated
`amba_requester.isf`, `ahb_lite_subordinate.isf`, `ahb_interconnect.isf`,
`amba_requester.fsm`, `ahb_lite_subordinate.fsm`, `ahb_interconnect.fsm`, and
aggregate `ahb_tb.fsm`, emits HDL module `ahb_tb`, and removes only
`ahb_aggregate_profile_alias_deferred` from aggregate `.ahb` reports. Broader
AHB behavior remains deferred.
`.727` selects `.728`, a no-behavior readiness audit for bounded
multi-subordinate AHB interconnect/decode. The selector records the shipped
six-entrypoint AHB surface, the remaining
`ahb_multi_subordinate_decode_deferred` residue, the current singular parser
and generator assumptions, and the temporary second-subordinate child
fail-closed diagnostic. No behavior changes until a later owner is selected.
`.728` selects `.729`, public contract selection for a first bounded
two-subordinate AHB interconnect/decode surface. The audit finds no separate
lower-layer repair is needed before contract selection, but direct
implementation remains deferred until the source syntax, child/window
cardinality, per-subordinate wiring, generated artifacts, reports, support
accounting, diagnostics, residue migration, validation, and rollback contract
are selected.
`.729` selects `.730`, direct implementation of the selected generic
`ppif/ahb_interconnect_two_subordinate.ppif` contract. The selected first
widening is exactly one requester, two unique subordinate objects, two
subordinate child bindings, two non-overlapping static address-map windows,
requester/global AHB wiring in the interconnect block, per-subordinate bus
names from each subordinate object, report topology
`one_requester_two_subordinate_static_window_interconnect`, support identity
`intent.ppif_ahb_interconnect_two_subordinate`, and coverage
`ial2_ppif_ahb_interconnect_two_subordinate_pipeline_cli`. Matching `.ahb`
alias support remains deferred until after the generic `.ppif` behavior ships.
`.730` ships that selected generic `.ppif` behavior. The public source
`ppif/ahb_interconnect_two_subordinate.ppif` lowers through generated
`amba_requester.isf`, `ahb_status_subordinate.isf`,
`ahb_control_subordinate.isf`, and `ahb_interconnect.isf` before generated
`amba_requester.fsm`, `ahb_status_subordinate.fsm`,
`ahb_control_subordinate.fsm`, `ahb_interconnect.fsm`, and aggregate
`ahb_tb.fsm`, emits HDL module `ahb_tb`, reports topology
`one_requester_two_subordinate_static_window_interconnect`, support-accounts as
`intent.ppif_ahb_interconnect_two_subordinate`, replaces the old
multi-subordinate residue with `ahb_broader_interconnect_decode_deferred`, and
keeps matching two-subordinate `.ahb` alias behavior deferred.
`.731` selects `.732`, direct implementation of the matching bounded public
AHB two-subordinate `.ahb` profile alias. The selected source path is
`ppif/ahb_interconnect_two_subordinate.ahb`, mirroring the shipped generic
two-subordinate `.ppif` source, preserving generated review artifacts and
topology `one_requester_two_subordinate_static_window_interconnect`, using
support identity `intent.ahb_profile_alias_interconnect_two_subordinate`,
source kind `ial2_profile_alias`, and coverage
`ial2_ahb_profile_alias_interconnect_two_subordinate_pipeline_cli`. No behavior
changed in `.731`; the alias remains deferred until `.732` implements it.
`.732` ships that selected alias. FSMGen accepts
`ppif/ahb_interconnect_two_subordinate.ahb`, preserves the same generated
review artifacts and HDL module `ahb_tb` as the generic source, reports
topology `one_requester_two_subordinate_static_window_interconnect`,
support-accounts as `intent.ahb_profile_alias_interconnect_two_subordinate`,
and removes `ahb_aggregate_profile_alias_deferred` from the alias reports; the
generic `.ppif` report keeps that residue as a source-surface distinction.
`.733` selects `.734`, a no-behavior readiness audit for the remaining AHB
residue after the eight public bounded AHB IAL2 entrypoints ship. The audit
must decide the next exact AHB owner or prerequisite before any new parser,
generator, source, support-accounting, manifest, test, schedule/check/semantic
JSON, generated artifact, HDL/runtime, direct-backend, verification-output,
backend-language variant, broader AHB, or VHDL behavior changes.
`.734` selects `.735`, first bounded AHB byte-lane/narrow-transfer readiness
audit. The selected audit must settle the first bounded `HSIZE` encodings,
`HADDR` lane selection, narrow write/read semantics, unaligned/crossing
diagnostics, report/support-accounting expectations, validation gates, and
residue movement before any byte-lane or narrow-transfer behavior changes.
`.735` selects `.736`, public contract selection for the first bounded AHB
byte-lane/narrow-transfer subordinate source, without behavior changes. The
readiness audit finds no lower-layer substrate, source-fact, report, or
support-accounting prerequisite before contract selection. The selected
contract-selection path should use a new generic subordinate `.ppif` source,
settle byte/halfword/word `HSIZE` behavior, `HADDR` lane selection, narrow
write/read projection, unaligned/crossing ERROR diagnostics, report/support
identity, validation, residue movement, and VHDL deferral, and keep the
existing word-only subordinate `.ppif` and `.ahb` sources unchanged.
`.736` selects `.737`, direct implementation of the first bounded AHB
byte-lane/narrow-transfer subordinate source. The selected future source is
`ppif/ahb_lite_subordinate_byte_lane.ppif`, support-accounted as
`intent.ppif_ahb_lite_subordinate_byte_lane`. It accepts byte, halfword, and
word `HSIZE` encodings, uses little-endian active lanes, preserves inactive
lanes on narrow writes, zero-fills inactive lanes on narrow reads, and keeps
unaligned, crossing, unsupported-size, unsupported-transfer, and unmapped
accesses on the existing two-cycle ERROR policy.
`.737` ships that source. `ppif/ahb_lite_subordinate_byte_lane.ppif` now
generates `ahb_lite_subordinate_byte_lane.isf` before
`ahb_lite_subordinate_byte_lane.fsm`, emits HDL module
`ahb_lite_subordinate_byte_lane`, reports `narrow_transfer_policy`, and keeps
existing word-only subordinate `.ppif`/`.ahb` behavior unchanged. At `.737`
closeout, the then-new byte-lane `.ahb` alias, aggregate byte-lane
propagation, optional signals, burst `SEQ`, broader AHB behavior, direct
backend, verification-output, backend-language variants, and VHDL remained
deferred. `.738` selects the next
exact AHB follow-on owner.
`.738` selects `.739`, direct implementation of the matching bounded public
AHB byte-lane/narrow-transfer subordinate `.ahb` profile alias, without
behavior changes. The selected future source is
`ppif/ahb_lite_subordinate_byte_lane.ahb`, mirroring the generic byte-lane
`.ppif` source, preserving generated `ahb_lite_subordinate_byte_lane.isf` and
`ahb_lite_subordinate_byte_lane.fsm`, reporting `narrow_transfer_policy`, and
support-accounting as `intent.ahb_profile_alias_subordinate_byte_lane` with
coverage `ial2_ahb_profile_alias_subordinate_byte_lane_pipeline_cli`. The next
slice is source/support/docs/test work; aggregate byte-lane propagation,
optional signals, burst `SEQ`, broader AHB behavior, direct backend,
verification-output, backend-language variants, and VHDL remain deferred.
`.739` ships that alias. `ppif/ahb_lite_subordinate_byte_lane.ahb` mirrors the
generic byte-lane `.ppif` source, generates
`ahb_lite_subordinate_byte_lane.isf` before
`ahb_lite_subordinate_byte_lane.fsm`, emits HDL module
`ahb_lite_subordinate_byte_lane`, support-accounts as
`intent.ahb_profile_alias_subordinate_byte_lane`, preserves
`narrow_transfer_policy`, and removes the subordinate profile-alias residue
only from the alias report. Aggregate byte-lane propagation, optional signals,
burst `SEQ`, broader AHB behavior, direct backend, verification-output,
backend-language variants, and VHDL remain deferred. `.740` owns the next
AHB follow-on selector.
`.740` selects `.741`, a no-behavior readiness audit for AHB aggregate/
interconnect byte-lane and narrow-transfer propagation. The selector confirms
the endpoint byte-lane `.ppif` and `.ahb` surfaces are shipped, and in-memory
aggregate probes can parse byte-lane subordinate policies and emit byte-lane
subordinate review artifacts. The aggregate reports still keep byte lanes in
deferred residue, so `.741` must settle source shape, report/residue movement,
support identities, validation, and `.ahb` alias sequencing before adding any
public aggregate byte-lane source.
`.741` selects `.742`, public contract selection for a combined bounded
generic `.ppif` AHB aggregate byte-lane/narrow-transfer family. The audit
confirms the current parser/generator substrate can already lower one- and
two-subordinate aggregate candidates with byte-lane subordinate policies, but
the aggregate report must still explicitly select propagated
`narrow_transfer_policy`/byte-lane report shape and remove byte-lane residue
only from the future byte-lane aggregate sources. Likely future sources are
`ppif/ahb_interconnect_byte_lane.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane.ppif`; matching `.ahb`
aliases stay separate follow-on work.
`.742` selects `.743`, direct implementation of that combined bounded generic
`.ppif` family. The selected sources are
`ppif/ahb_interconnect_byte_lane.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane.ppif`; both keep HDL entry
`ahb_tb`, add aggregate report block `composition.byte_lane_propagation`, and
propagate child `narrow_transfer_policy` for embedded byte-lane subordinate
objects. The selected support identities are
`intent.ppif_ahb_interconnect_byte_lane` and
`intent.ppif_ahb_interconnect_two_subordinate_byte_lane`. `.ahb` aliases and
broader AHB work remain deferred.
`.743` ships that selected generic `.ppif` family. The one-subordinate source
emits `ahb_lite_subordinate_byte_lane.isf` /
`ahb_lite_subordinate_byte_lane.fsm`; the two-subordinate source emits
`ahb_status_subordinate_byte_lane.isf`,
`ahb_control_subordinate_byte_lane.isf`,
`ahb_status_subordinate_byte_lane.fsm`, and
`ahb_control_subordinate_byte_lane.fsm`; both keep aggregate HDL entry
`ahb_tb`. Schedule/report JSON now exposes
`composition.byte_lane_propagation` and child `narrow_transfer_policy` for the
selected aggregate byte-lane `.ppif` sources only. Existing word-only
aggregate `.ppif`/`.ahb` behavior, endpoint byte-lane `.ppif`/`.ahb`
behavior, optional signals, burst `SEQ`, broader AHB behavior, direct backend,
verification-output, backend-language variants, and VHDL remain deferred.
`.745` now ships the matching aggregate byte-lane `.ahb` aliases. The public
aliases are `ppif/ahb_interconnect_byte_lane.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane.ahb`, with support identities
`intent.ahb_profile_alias_interconnect_byte_lane` and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane`, source kind
`ial2_profile_alias`, coverage keys
`ial2_ahb_profile_alias_interconnect_byte_lane_pipeline_cli` and
`ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_pipeline_cli`,
HDL module `ahb_tb`, and child counts 3 and 4. They preserve
`composition.byte_lane_propagation`, child `narrow_transfer_policy`,
local-address-before-byte-lane policy, subordinate-owned mapped-hit
byte/halfword/word behavior, and interconnect-owned unmapped ERROR behavior.
Alias reports remove `ahb_aggregate_profile_alias_deferred`, while generic
aggregate byte-lane `.ppif` reports keep that source-surface residue.
`.746` selects `.747`, public report-contract selection for aggregate `.ahb`
alias nested profile-alias residue cleanup, after schedule probes showed
generated child reports inside aggregate `.ahb` aliases still carry endpoint
`ahb_profile_alias_deferred` and `ahb_subordinate_profile_alias_deferred`
residue. `.747` must decide the exact cleanup/preservation boundary before any
report implementation change. Optional signals, burst `SEQ`, broader AHB
behavior, direct backend, verification-output, backend-language variants, and
VHDL remain deferred.
`.747` selects `.748`, direct report cleanup for aggregate `.ahb` alias
nested endpoint profile-alias residue. The selected contract covers shipped
word-only and byte-lane aggregate `.ahb` aliases, removes
`ahb_aggregate_profile_alias_deferred`, `ahb_profile_alias_deferred`, and
`ahb_subordinate_profile_alias_deferred` recursively from aggregate `.ahb`
report trees only, keeps generic aggregate `.ppif` source-surface residue,
and adds no new nested child provenance fields. Optional signals, burst `SEQ`,
broader AHB behavior, direct backend, verification-output, backend-language
variants, and VHDL remain deferred.
`.748` now ships that report-only cleanup. Aggregate AHB `.ahb` report trees
no longer carry the aggregate, requester-child, or subordinate-child
profile-alias residues, while matching generic aggregate `.ppif` reports keep
those source-surface residues. Parser behavior, public source samples, support
accounting, capability-manifest entries, generated `.isf`/`.fsm`, HDL/runtime
behavior, direct backend, verification-output generation, backend-language
variants, AXI/APB behavior, broader AHB behavior, and VHDL behavior are
unchanged. `.749` is the next no-behavior AHB follow-on selector.
`.749` selects `.750`, a no-behavior readiness audit for bounded AHB burst
`SEQ` continuation. Current probes show the aggregate `.ahb` residue cleanup
left true protocol residue only; burst `SEQ` is now the narrowest shared
endpoint/aggregate candidate after byte-lane behavior and alias cleanup, but
implementation remains deferred until readiness settles the first bounded
owner and substrate needs. Optional/property-gated signals, broader
interconnect/decode, legacy two-bit subordinate `HRESP`, scoreboards,
full-manager behavior, direct backend, verification-output, backend-language
variants, AXI/APB behavior, broader AHB behavior, and VHDL remain deferred.
`.750` selects `.751`, a no-behavior public contract selection for first
bounded subordinate-side AHB burst `SEQ` support. Current requester behavior
already emits first-beat `NONSEQ`, later-beat `SEQ`, address progression/wrap
state, and response handling. Current subordinate sources still report
`supported-transfer nonseq`, route `SEQ` to the selected two-cycle ERROR path,
and carry `ahb_burst_seq_support_deferred`; aggregate reports keep
corresponding top-level/interconnect/subordinate burst residue. Direct
implementation is deferred until source syntax, report semantics,
prior-transfer history, address/control progression, bounded byte-lane or
register-bank scope, unsupported-shape fail-closed behavior, residue movement,
tests, docs, and rollback are selected.
`.751` selects `.752`, direct implementation of the new generic `.ppif`
byte-lane subordinate `SEQ` source
`ppif/ahb_lite_subordinate_byte_lane_seq.ppif`. The selected source adds
`(seq-policy in-word-progressive)` and support identity
`intent.ppif_ahb_lite_subordinate_byte_lane_seq`. Existing word-only,
byte-lane, `.ahb` alias, requester, and aggregate behavior stay unchanged.
The first bounded `SEQ` policy supports only byte/halfword in-word
continuation with prior successful active-transfer history, expected address
progression, and stable `HWRITE`/`HSIZE`; HBURST length/wrap, BUSY-in-burst,
multi-word/register-bank, alias, aggregate, optional-signal, broader AHB,
AXI/APB, and VHDL behavior remain deferred.
`.752` now ships that selected generic byte-lane in-word `SEQ` subordinate
source. It adds `ppif/ahb_lite_subordinate_byte_lane_seq.ppif`, generated
`ahb_lite_subordinate_byte_lane_seq.isf` /
`ahb_lite_subordinate_byte_lane_seq.fsm`, HDL module
`ahb_lite_subordinate_byte_lane_seq`, support identity
`intent.ppif_ahb_lite_subordinate_byte_lane_seq`, and structured
`transfer.seq_policy` reporting. `SEQ` OKAY completion is bounded to
byte/halfword in-word progression with prior OKAY `NONSEQ` or valid `SEQ`
history, expected next address, and stable `HWRITE`/`HSIZE`. Standalone
`SEQ`, `SEQ` after `IDLE`/`BUSY`/ERROR/reset, word `SEQ`, crossing,
unexpected address, changed control, unsupported size, unmapped, unaligned,
and crossing accesses fail closed with the selected two-cycle ERROR response.
Existing word-only `.ppif/.ahb`, byte-lane `.ppif/.ahb`, requester, aggregate,
and alias behavior stay preserved. HBURST-driven length/wrap semantics,
BUSY-in-burst parking, multi-word/register-bank progression, `.ahb` alias
exposure, aggregate propagation, optional/property-gated AHB signals, broader
AHB behavior, direct backend, verification-output generation,
backend-language variants, AXI/APB, and VHDL remain deferred.
`.753` selects `.754`, direct implementation of the matching bounded public AHB
byte-lane in-word `SEQ` subordinate `.ahb` profile alias. `.754` now ships
`ppif/ahb_lite_subordinate_byte_lane_seq.ahb`, mirroring the shipped generic
`.ppif` source, support-accounting as
`intent.ahb_profile_alias_subordinate_byte_lane_seq`, using coverage
`ial2_ahb_profile_alias_subordinate_byte_lane_seq_pipeline_cli`, preserving
generated `ahb_lite_subordinate_byte_lane_seq.isf` /
`ahb_lite_subordinate_byte_lane_seq.fsm`, preserving `narrow_transfer_policy`
and `transfer.seq_policy`, and removing `.ahb alias exposure` from the alias
report's remaining `ahb_burst_seq_support_deferred` detail. The generic
`.ppif` report still keeps source-surface alias residue. Aggregate `SEQ`
propagation, HBURST length/wrap semantics, BUSY-in-burst parking,
multi-word/register-bank progression, optional/property-gated AHB signals,
broader AHB behavior, direct backend, verification-output generation,
backend-language variants, AXI/APB, and VHDL remain deferred.
`.755` selects `.756`, a no-behavior readiness audit for bounded AHB aggregate
byte-lane in-word `SEQ` propagation. Current aggregate byte-lane sources still
instantiate non-`SEQ` byte-lane subordinate children and carry
`ahb_burst_seq_support_deferred`; `.756` must audit source family names, one-
and two-subordinate child naming, child `transfer.seq_policy` propagation,
aggregate report shape, residue movement, validation, rollback, and aggregate
`.ahb` alias sequencing before any behavior change.
`.756` selects `.757`, no-behavior public contract selection for a combined
generic `.ppif` aggregate byte-lane in-word `SEQ` propagation family.
Temporary one-subordinate and two-subordinate aggregate `SEQ` probes parse,
strict-check, emit `ahb_tb`, and carry child `narrow_transfer_policy` plus
`transfer.seq_policy`, so no generated-IAL1/IAL0 substrate repair is required
before contract selection. Likely future source names are
`ppif/ahb_interconnect_byte_lane_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif`; exact support
identities, report shape, residue movement, validation, and later aggregate
`.ahb` alias sequencing remain for `.757`.
`.757` selects `.758`, direct implementation of those two generic `.ppif`
aggregate `SEQ` sources. The selected support identities are
`intent.ppif_ahb_interconnect_byte_lane_seq` and
`intent.ppif_ahb_interconnect_two_subordinate_byte_lane_seq`; reports must
preserve `composition.byte_lane_propagation` and add
`composition.seq_policy_propagation`, with generated child reports carrying
both `narrow_transfer_policy` and `transfer.seq_policy`. Matching aggregate
`.ahb` aliases, HBURST length/wrap, BUSY-in-burst, multi-word/register-bank,
optional signals, broader AHB, direct backend, verification-output,
backend-language variants, AXI/APB, and VHDL remain deferred.

AHB aggregate byte-lane in-word `SEQ` behavior:
[IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_BEHAVIOR](../../IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_BEHAVIOR.md)
ships `.758`, the two generic `.ppif` aggregate `SEQ` sources
`ppif/ahb_interconnect_byte_lane_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif`. They
support-account as `intent.ppif_ahb_interconnect_byte_lane_seq` and
`intent.ppif_ahb_interconnect_two_subordinate_byte_lane_seq`, lower through
generated byte-lane `SEQ` subordinate `.isf`/`.fsm` review artifacts before
aggregate `ahb_tb`, preserve `composition.byte_lane_propagation`, add
`composition.seq_policy_propagation`, and propagate child
`narrow_transfer_policy` plus `transfer.seq_policy`. HBURST length/wrap,
BUSY-in-burst, multi-word/register-bank, optional signals, broader AHB, direct
backend, verification-output, backend-language variants, AXI/APB, and VHDL
remain deferred.

Post AHB aggregate byte-lane in-word `SEQ` PPIF selector:
[IAL2_POST_AHB_AGGREGATE_BYTE_LANE_SEQ_PPIF_NEXT_SLICE_SELECTION](../../IAL2_POST_AHB_AGGREGATE_BYTE_LANE_SEQ_PPIF_NEXT_SLICE_SELECTION.md)
selects `.760`, direct implementation of the matching aggregate byte-lane
`SEQ` `.ahb` aliases
`ppif/ahb_interconnect_byte_lane_seq.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb`. The selector
records the alias support identities, propagation reports, and alias-only
child `.ahb alias exposure` cleanup expectations.
HBURST length/wrap, BUSY-in-burst, multi-word/register-bank, optional signals,
broader AHB, direct backend, verification-output, backend-language variants,
AXI/APB, and VHDL remain deferred.

AHB aggregate byte-lane in-word `SEQ` profile-alias behavior:
[IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR](../../IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR.md)
ships `.760`, the matching aggregate byte-lane `SEQ` `.ahb` aliases
`ppif/ahb_interconnect_byte_lane_seq.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb`. They
support-account as `intent.ahb_profile_alias_interconnect_byte_lane_seq` and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_seq`, use
source kind `ial2_profile_alias`, preserve `composition.byte_lane_propagation`,
`composition.seq_policy_propagation`, child `narrow_transfer_policy`, and
child `transfer.seq_policy`, and remove aggregate/requester/subordinate
profile-alias residue plus child `.ahb alias exposure` wording from alias
report trees while generic `.ppif` reports keep source-surface residue.
HBURST length/wrap, BUSY-in-burst, multi-word/register-bank, optional signals,
broader AHB, direct backend, verification-output, backend-language variants,
AXI/APB, and VHDL remain deferred.

Post AHB aggregate byte-lane in-word `SEQ` alias selector:
[IAL2_POST_AHB_AGGREGATE_BYTE_LANE_SEQ_ALIAS_NEXT_SLICE_SELECTION](../../IAL2_POST_AHB_AGGREGATE_BYTE_LANE_SEQ_ALIAS_NEXT_SLICE_SELECTION.md)
selects `.762`, a no-behavior readiness audit for bounded AHB
HBURST-driven length/wrap `SEQ` semantics. Endpoint and aggregate `SEQ` alias
reports have profile-alias/source-surface cleanup complete, leaving
`ahb_burst_seq_support_deferred` as the front-most shared AHB `SEQ` residue.
`.762` must audit HBURST source syntax/forwarding, bounded burst kinds,
length/wrap windows, endpoint-only versus aggregate-inclusive scope,
diagnostics, report shape, generated review artifacts, validation, rollback,
and explicit deferrals before behavior changes.

AHB HBURST length/wrap `SEQ` readiness audit:
[IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_READINESS_AUDIT](../../IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_READINESS_AUDIT.md)
selects `.763`, a no-behavior public contract selection for a new
endpoint-only HBURST-aware byte-lane `SEQ` source family. Requester
HBURST/wrap generation is already present, but the selected byte-lane `SEQ`
subordinate bus has no HBURST binding and candidate `(burst HBURST width 3)`
syntax failed before `.764`. Aggregate byte-lane `SEQ` interconnects see global
`HBURST` but do not forward subordinate-local HBURST, so aggregate propagation,
matching `.ahb` aliases, BUSY-in-burst, multi-word/register-bank, broader
AHB, direct backend, verification-output, backend-language variants, AXI/APB,
and VHDL remain deferred.

AHB HBURST length/wrap `SEQ` contract selection:
[IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_CONTRACT_SELECTION](../../IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_CONTRACT_SELECTION.md)
selects `.764`, direct implementation of
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif`. The selected generic
endpoint source adds `(burst HBURST width 3)` and
`(seq-policy hburst-in-word-progressive)`, support-accounts as
`intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq`, and supports
byte-only `WRAP4`/`INCR4` `SEQ` inside one 32-bit register word. `SINGLE`
remains non-SEQ only; wider/indefinite bursts, halfword/word burst `SEQ`,
BUSY-in-burst, aggregate propagation, matching `.ahb` aliases, broader AHB,
direct backend, verification-output, backend-language variants, AXI/APB, and
VHDL remain deferred.

AHB HBURST length/wrap `SEQ` behavior:
[IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_BEHAVIOR](../../IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_BEHAVIOR.md)
ships `.764`, the generic endpoint-only source
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif`. It adds subordinate
`(burst HBURST width 3)`, `(seq-policy hburst-in-word-progressive)`,
support-accounting entry
`intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq`, generated
`ahb_lite_subordinate_byte_lane_hburst_seq.isf` / `.fsm` review artifacts,
and HDL module `ahb_lite_subordinate_byte_lane_hburst_seq`. Runtime support
is byte-only `WRAP4`/`INCR4` `SEQ` inside one 32-bit register word. `SINGLE`
remains independent `NONSEQ` only; wider/indefinite bursts, halfword/word
burst `SEQ`, BUSY-in-burst, aggregate propagation, matching `.ahb` aliases,
broader AHB, direct backend, verification-output, backend-language variants,
AXI/APB, and VHDL remain deferred.

Post AHB HBURST `SEQ` `.ppif` selector:
[IAL2_POST_AHB_HBURST_SEQ_PPIF_NEXT_SLICE_SELECTION](../../IAL2_POST_AHB_HBURST_SEQ_PPIF_NEXT_SLICE_SELECTION.md)
selects `.766`, direct implementation of the matching public
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb` profile alias. The alias
mirrors the generic `.ppif` source, support-accounts as
`intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq`, uses coverage
`ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_pipeline_cli`,
reports source kind `ial2_profile_alias`, preserves generated
`ahb_lite_subordinate_byte_lane_hburst_seq.isf` / `.fsm`, preserves
`bindings.bus.burst` and
`transfer.seq_policy.mode = hburst_in_word_progressive`, and removes `.ahb`
alias exposure only from the alias report. Aggregate HBURST propagation,
BUSY-in-burst, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank, optional signals, broader AHB, direct backend,
verification-output, backend-language variants, AXI/APB, and VHDL remain
deferred.

AHB HBURST length/wrap `SEQ` profile-alias behavior:
[IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_PROFILE_ALIAS_BEHAVIOR](../../IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_PROFILE_ALIAS_BEHAVIOR.md)
ships `.766`, the matching public
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb` profile alias. The alias
support-accounts as
`intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq`, uses source kind
`ial2_profile_alias`, preserves generated
`ahb_lite_subordinate_byte_lane_hburst_seq.isf` / `.fsm`, preserves
`bindings.bus.burst` and
`transfer.seq_policy.mode = hburst_in_word_progressive`, and removes endpoint
profile-alias residue plus `.ahb alias exposure` only from the alias report.
The generic `.ppif` report keeps source-surface alias residue. Aggregate
HBURST propagation, BUSY-in-burst, halfword/word burst
`SEQ`, wider or indefinite bursts, multi-word/register-bank, optional signals,
broader AHB, direct backend, verification-output, backend-language variants,
AXI/APB, and VHDL remain deferred.

Post AHB HBURST `SEQ` alias selector:
[IAL2_POST_AHB_HBURST_SEQ_ALIAS_NEXT_SLICE_SELECTION](../../IAL2_POST_AHB_HBURST_SEQ_ALIAS_NEXT_SLICE_SELECTION.md)
selects `.768`, a no-behavior readiness audit for bounded aggregate AHB
HBURST propagation. The current aggregate byte-lane `SEQ` sources still
strict-check as shipped and expose requester/global `HBURST`, but their child
subordinates remain on the older `in_word_progressive` endpoint contract with
no subordinate-local burst binding. Temporary one- and two-subordinate HBURST
aggregate candidates lowered far enough to show child
`hburst_in_word_progressive` reports, then failed strict checks closed because
`regs.HBURST_REGS` or `status.HBURST_STATUS` was left unconnected by the
composition top. Aggregate HBURST forwarding, matching aggregate aliases,
BUSY-in-burst, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank, optional signals, broader AHB, direct backend,
verification-output, backend-language variants, AXI/APB, and VHDL remain
deferred.

AHB aggregate HBURST `SEQ` readiness audit:
[IAL2_AHB_AGGREGATE_HBURST_SEQ_READINESS_AUDIT](../../IAL2_AHB_AGGREGATE_HBURST_SEQ_READINESS_AUDIT.md)
selects `.769`, a no-behavior public contract selection for a combined bounded
generic `.ppif` aggregate HBURST-aware byte-lane `SEQ` propagation family.
Likely source names are `ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`. `.769`
must pin exact paths, child object names, subordinate-local HBURST names,
support identities, coverage keys, child HBURST fanout policy, aggregate
report schema, residue movement, tests, docs, and later matching aggregate
`.ahb` alias sequencing before implementation.

AHB aggregate HBURST `SEQ` contract selection:
[IAL2_AHB_AGGREGATE_HBURST_SEQ_CONTRACT_SELECTION](../../IAL2_AHB_AGGREGATE_HBURST_SEQ_CONTRACT_SELECTION.md)
selects `.770`, direct implementation of
`ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`. The
selected support identities are
`intent.ppif_ahb_interconnect_byte_lane_hburst_seq` and
`intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq`; the
selected child HBURST fanout is requester/global `HBURST` directly to
`HBURST_REGS`, `HBURST_STATUS`, and `HBURST_CONTROL`; and the selected report
shape reuses `composition.seq_policy_propagation` with
`subordinate_owned_hburst_in_word_seq_policy`. Matching aggregate `.ahb`
aliases, BUSY-in-burst, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, broader AHB, backend variants, AXI/APB,
and VHDL remain deferred.

AHB aggregate HBURST `SEQ` behavior:
[IAL2_AHB_AGGREGATE_HBURST_SEQ_BEHAVIOR](../../IAL2_AHB_AGGREGATE_HBURST_SEQ_BEHAVIOR.md)
ships `ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`. The
sources support-account as `intent.ppif_ahb_interconnect_byte_lane_hburst_seq`
and `intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq`,
forward requester/global `HBURST` to child-local `HBURST_REGS`,
`HBURST_STATUS`, and `HBURST_CONTROL`, preserve
`composition.byte_lane_propagation`, and reuse
`composition.seq_policy_propagation` with
`subordinate_owned_hburst_in_word_seq_policy`.

Post AHB aggregate HBURST `SEQ` PPIF selector:
[IAL2_POST_AHB_AGGREGATE_HBURST_SEQ_PPIF_NEXT_SLICE_SELECTION](../../IAL2_POST_AHB_AGGREGATE_HBURST_SEQ_PPIF_NEXT_SLICE_SELECTION.md)
selects `.771`, a no-behavior public contract selection for matching
aggregate HBURST-aware `.ahb` aliases. Matching aggregate `.ahb` aliases,
BUSY-in-burst, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, broader AHB, backend variants, AXI/APB,
and VHDL remain deferred.

AHB aggregate HBURST `SEQ` alias contract selector:
[IAL2_AHB_AGGREGATE_HBURST_SEQ_ALIAS_CONTRACT_SELECTION](../../IAL2_AHB_AGGREGATE_HBURST_SEQ_ALIAS_CONTRACT_SELECTION.md)
selects `.772`, direct implementation of the matching aggregate HBURST-aware
`.ahb` profile aliases `ppif/ahb_interconnect_byte_lane_hburst_seq.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb`. They must
support-account as `intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq`
and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq`
with source kind `ial2_profile_alias`, and reserved `.ahb` label probes confirm
the existing suffix-keyed suppression removes the aggregate/child alias residue
with no adapter change, so `.772` is data-only. BUSY-in-burst, halfword/word
burst `SEQ`, wider or indefinite bursts, multi-word/register-bank progression,
broader AHB, backend variants, AXI/APB, and VHDL remain deferred.

AHB aggregate HBURST `SEQ` alias behavior:
[IAL2_AHB_AGGREGATE_HBURST_SEQ_PROFILE_ALIAS_BEHAVIOR](../../IAL2_AHB_AGGREGATE_HBURST_SEQ_PROFILE_ALIAS_BEHAVIOR.md)
ships `ppif/ahb_interconnect_byte_lane_hburst_seq.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb`,
support-accounted as
`intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq` and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq`
(`source_kind: ial2_profile_alias`). The aliases mirror the generic `.ppif`
sources, keep HDL entry `ahb_tb` and
`composition.seq_policy_propagation` mode
`subordinate_owned_hburst_in_word_seq_policy`, and drop the aggregate/child
profile-alias residue. Focused coverage is `t/1493`. BUSY-in-burst,
halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, broader AHB, backend variants, AXI/APB,
and VHDL remain deferred.

Post AHB aggregate HBURST alias selector:
[IAL2_POST_AHB_AGGREGATE_HBURST_ALIAS_NEXT_SLICE_SELECTION](../../IAL2_POST_AHB_AGGREGATE_HBURST_ALIAS_NEXT_SLICE_SELECTION.md)
selects `.774`, a no-behavior readiness audit for bounded AHB subordinate
BUSY-in-burst parking — holding the in-word `SEQ` burst context across an
`HTRANS = BUSY` beat rather than clearing it. This is the smallest next
burst-`SEQ` increment after the byte-only `WRAP4`/`INCR4` in-word HBURST `SEQ`
endpoint+aggregate `.ppif`/`.ahb` family: the endpoint burst-context registers
already exist, BUSY is currently folded into the burst-history clear alongside
IDLE (the then-generated `ahb_seq_idle_clear` transaction fired on
`(| (== HTRANS idle) (== HTRANS busy))` and the endpoint report `clears_on`
lists `busy`), and the endpoint/aggregate residue already defer BUSY-in-burst
continuation/handling, so parking is a bounded clear-versus-park decode edit
plus report/residue narrowing inside the shipped byte-only window. Halfword/word
burst `SEQ`, wider or indefinite bursts, multi-word/register-bank progression,
optional/property-gated `HPROT`/`HMASTLOCK` signals, broader AHB, backend
variants, AXI/APB, and VHDL were weighed as larger and remain deferred.

AHB subordinate BUSY-park readiness audit:
[IAL2_AHB_SUBORDINATE_BUSY_PARK_READINESS_AUDIT](../../IAL2_AHB_SUBORDINATE_BUSY_PARK_READINESS_AUDIT.md)
audits bounded AHB subordinate BUSY-in-burst parking and selects `.775`, a
public contract selection for the endpoint BUSY-parking source. The burst-context
registers already exist, so the minimal delta is stopping the
then-generated `ahb_seq_idle_clear` transaction from firing on BUSY (unassigned registers hold
their value across the parked beat). The endpoint source declares
`(ignored-transfer busy)`, so a distinct "busy parks" declaration is needed, and
the shipped requester never drives `HTRANS = BUSY` on the bus, so parking is a
subordinate-side capability with requester-side BUSY insertion deferred.
Halfword/word burst `SEQ`, wider or indefinite bursts, multi-word/register-bank
progression, optional signals, broader AHB, backend variants, AXI/APB, and VHDL
remain deferred.

AHB subordinate BUSY-park contract selection:
[IAL2_AHB_SUBORDINATE_BUSY_PARK_CONTRACT_SELECTION](../../IAL2_AHB_SUBORDINATE_BUSY_PARK_CONTRACT_SELECTION.md)
selects `.776`, the direct implementation of a new additive endpoint source
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif` (preserving the
shipped source and its `t/1491`). The source replaces `(ignored-transfer busy)`
with the new `(parked-transfer busy)` vocabulary; gated on that flag,
`ahb_seq_idle_clear` fires only on IDLE so a BUSY beat holds, the report drops
`busy` from `clears_on` and adds `parks_on: [busy]`, and the burst-`SEQ` residue
narrows. The existing `SEQ`-beat validation is the fail-closed path for a
drifting resume. `.776` adds focused `t/1494` (`NONSEQ → SEQ → BUSY → SEQ`) and
bumps `t/248`/`t/297` accounting. The matching `.ahb` alias, aggregate
BUSY-parking, requester-side BUSY insertion, and larger burst work remain
deferred.

AHB subordinate BUSY-park behavior:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.776` shipped
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif`,
support-accounted as
`intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park` with coverage
`ial2_ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`
(`source_kind: ppif`). The source declares `(ignored-transfer idle)` and
`(parked-transfer busy)`; the new `parked-transfer` clause gates BUSY out of the
then-generated `ahb_seq_idle_clear` transaction so it fired on IDLE only, and the unassigned
`seq_*` registers hold the in-word burst context across the BUSY beat while the
following `SEQ` beat resumes through the existing `seq_ok_base` validation. The
`SEQ`-policy report drops `busy` from `clears_on` and adds `parks_on: [busy]`,
and the residue records shipped BUSY-in-burst parking. The shipped
`ahb_lite_subordinate_byte_lane_hburst_seq` source is unchanged (BUSY still
clears). Focused coverage is `t/1494`; `t/248` moves to 292 protocol / 333 total
supported-smoke entries. The matching `.ahb` alias, aggregate BUSY-parking,
requester-side BUSY insertion, halfword/word burst `SEQ`, wider or indefinite
bursts, multi-word/register-bank progression, optional signals, broader AHB,
backend variants, AXI/APB, and VHDL remain deferred.

AHB subordinate BUSY-park `.ahb` alias contract selection:
[IAL2_AHB_SUBORDINATE_BUSY_PARK_ALIAS_CONTRACT_SELECTION](../../IAL2_AHB_SUBORDINATE_BUSY_PARK_ALIAS_CONTRACT_SELECTION.md)
selects `.778`, direct implementation of the matching endpoint BUSY-park `.ahb`
profile alias `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb`. The
alias mirrors the shipped generic BUSY-park `.ppif` source, will support-account
as `intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park` with
coverage
`ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`,
reports `source_kind: ial2_profile_alias`, preserves generated
`ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf` / `.fsm` and the
`parks_on: [busy]` / `clears_on` BUSY-park report shape, and removes
`ahb_subordinate_profile_alias_deferred` plus the `.ahb alias exposure` residue
wording only from the alias report through the existing suffix-keyed suppression.
A reserved `.ahb`-label probe confirms the alias is data-only (no adapter
change); `.778` adds the alias fixture, its `RegressionCorpus` entry, focused
`t/1495`, the `t/248` bump (292 → 293 protocol / 333 → 334 total), the `t/297`
manifest, and docs. Aggregate BUSY-parking, requester-side BUSY insertion,
halfword/word burst `SEQ`, wider or indefinite bursts, multi-word/register-bank
progression, optional signals, broader AHB, backend variants, AXI/APB, and VHDL
remain deferred.

AHB subordinate BUSY-park `.ahb` alias behavior:
[IAL2_AHB_SUBORDINATE_BUSY_PARK_PROFILE_ALIAS_BEHAVIOR](../../IAL2_AHB_SUBORDINATE_BUSY_PARK_PROFILE_ALIAS_BEHAVIOR.md)
ships `.778`, the matching endpoint BUSY-park `.ahb` profile alias
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb`, a byte-identical
mirror of the generic BUSY-park `.ppif` source. It support-accounts as
`intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park` with
coverage
`ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`,
reports `source_kind: ial2_profile_alias`, preserves generated
`ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf` / `.fsm` and the
BUSY-park `parks_on: [busy]` / `clears_on` report, and removes
`ahb_subordinate_profile_alias_deferred` plus the `.ahb alias exposure` residue
wording only from the alias report through the existing suffix-keyed suppression.
Focused coverage is `t/1495`; `t/248` moves to 293 protocol / 334 total
supported-smoke entries. Aggregate BUSY-parking, requester-side BUSY insertion,
halfword/word burst `SEQ`, wider or indefinite bursts, multi-word/register-bank
progression, optional signals, broader AHB, backend variants, AXI/APB, and VHDL
remain deferred.

Post-endpoint-BUSY-park selector:
[IAL2_POST_AHB_ENDPOINT_BUSY_PARK_NEXT_SLICE_SELECTION](../../IAL2_POST_AHB_ENDPOINT_BUSY_PARK_NEXT_SLICE_SELECTION.md)
records the `.779` no-behavior selection of `.780`, a readiness audit for bounded
aggregate AHB BUSY-parking propagation — holding a child subordinate's in-word
HBURST `SEQ` burst context across an `HTRANS = BUSY` beat inside the interconnect
aggregate propagation, mirroring the shipped endpoint BUSY-park. It is the next
step in the endpoint → aggregate cadence: the endpoint BUSY-park residue defers
`aggregate propagation` while the aggregate residue still lists `BUSY-in-burst
handling` first. The interconnect `_seq_policy_propagation_report` already clones
each child's `seq_policy` verbatim, so a `(parked-transfer busy)` child
auto-forwards its `parks_on: [busy]` into `composition.seq_policy_propagation`;
the delta is new aggregate stems plus residue narrowing. Requester-side BUSY
insertion, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, optional signals, broader AHB, backend
variants, AXI/APB, and VHDL remain deferred.

Aggregate BUSY-park propagation readiness audit:
[IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_READINESS_AUDIT](../../IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_READINESS_AUDIT.md)
records the `.780` no-behavior audit finding aggregate BUSY-park propagation
ready — the interconnect composes child subordinate FSMs via
`AhbSubordinate->generate` and clones each child `seq_policy` verbatim, so a
`(parked-transfer busy)` child parks BUSY through the shipped endpoint machinery
with no interconnect generator/parser/report change and the child `seq_ok_base`
fail-closed path carries through composition — and selects `.781`, the public
contract selection for the aggregate BUSY-park source(s) (stem name(s), one vs
both stems, support identity/coverage/source kind, residue scope, tests, and the
later matching aggregate `.ahb` alias). Requester-side BUSY insertion,
halfword/word burst `SEQ`, wider or indefinite bursts, multi-word/register-bank
progression, optional signals, broader AHB, backend variants, AXI/APB, and VHDL
remain deferred.

Aggregate BUSY-park propagation contract selection:
[IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_CONTRACT_SELECTION](../../IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_CONTRACT_SELECTION.md)
records the `.781` no-behavior selection of `.782`, which ships both aggregate
BUSY-park `.ppif` stems (mirroring `.770`):
`ahb_interconnect_byte_lane_hburst_seq_busy_park` (support identity
`intent.ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park`, child count 3) and
`ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park` (child count 4),
each a copy of the shipped aggregate HBURST `SEQ` source with the child transfer
`(ignored-transfer busy)` replaced by `(parked-transfer busy)`. The delta is
source data plus narrowing only the aggregate HBURST residue at
`AhbInterconnect.pm:1401` — no interconnect code change, since the verbatim
`seq_policy` clone forwards `parks_on: [busy]` — with focused `t/1496`, `t/248`
moving to 295 protocol / 336 total, and the matching aggregate `.ahb` aliases
deferred to a later slice. Requester-side BUSY insertion, halfword/word burst
`SEQ`, wider or indefinite bursts, multi-word/register-bank progression, optional
signals, broader AHB, backend variants, AXI/APB, and VHDL remain deferred.

Aggregate BUSY-park propagation behavior:
[IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_BEHAVIOR](../../IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_BEHAVIOR.md)
documents the `.782` shipped aggregate BUSY-park `.ppif` sources
`ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif` (support identity
`intent.ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park`, child count 3) and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif`
(support identity
`intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park`,
child count 4). Each is a byte-for-byte copy of the shipped aggregate HBURST
`SEQ` source with every inlined child transfer's `(ignored-transfer busy)`
replaced by `(parked-transfer busy)`, so each child holds the in-word `SEQ` burst
context across an accepted `HTRANS = BUSY` beat and `composition.seq_policy_propagation`
reports `parks_on: [busy]` with a BUSY-free `clears_on` per child. No interconnect
generator/parser/report code changed (the verbatim `seq_policy` clone forwards the
park); only the aggregate HBURST residue at `AhbInterconnect.pm:1401` narrowed to
record shipped BUSY-in-burst parking. Focused coverage is `t/1496`; `t/248` moved
to 295 protocol / 336 total; `t/1492`/`t/1493` and the endpoint BUSY-park
`t/1494`/`t/1495` are preserved. The matching aggregate BUSY-park `.ahb` aliases,
requester-side BUSY insertion, halfword/word burst `SEQ`, wider or indefinite
bursts, multi-word/register-bank progression, optional signals, broader AHB,
backend variants, AXI/APB, and VHDL remain deferred.

Aggregate BUSY-park propagation alias contract selection:
[IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_ALIAS_CONTRACT_SELECTION](../../IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_ALIAS_CONTRACT_SELECTION.md)
records the `.783` no-behavior selection of `.784`, direct implementation of the
matching aggregate BUSY-park `.ahb` profile aliases
`ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb` and its
two-subordinate sibling (byte-identical mirrors of the shipped generic `.ppif`
sources). A reserved `.ahb`-label parse proves the aliases are data-only: they
keep the aggregate topology (child counts 3/4), preserve each child
`seq_policy.parks_on = [busy]`/BUSY-free `clears_on`, and drop the top-level
`ahb_aggregate_profile_alias_deferred` and embedded
`ahb_subordinate_profile_alias_deferred` residues through the existing
suffix-keyed suppression with no adapter change. `.784` support-accounts them as
`intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park` (child
count 3) and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park`
(child count 4), source kind `ial2_profile_alias`, adds focused `t/1497`, and
moves `t/248` to 297 protocol / 338 total. Requester-side BUSY insertion,
halfword/word burst `SEQ`, wider or indefinite bursts, multi-word/register-bank
progression, optional signals, broader AHB, backend variants, AXI/APB, and VHDL
remain deferred.

Aggregate BUSY-park propagation profile alias behavior:
[IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_PROFILE_ALIAS_BEHAVIOR](../../IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_PROFILE_ALIAS_BEHAVIOR.md)
documents the `.784` shipped matching aggregate BUSY-park `.ahb` profile aliases
`ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb` and its
two-subordinate sibling, byte-identical mirrors of the generic `.ppif` sources.
They support-account as
`intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park` (child
count 3) and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park`
(child count 4), source kind `ial2_profile_alias`, and produce identical
generated review artifacts, HDL, and `composition.seq_policy_propagation` reports
(each child `parks_on: [busy]`, BUSY-free `clears_on`), differing only in that the
alias reports drop the aggregate + embedded profile-alias residue through the
existing suffix-keyed suppression with no adapter change. Focused coverage is
`t/1497`; `t/248` moved to 297 protocol / 338 total. Requester-side BUSY
insertion, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, optional signals, broader AHB, backend
variants, AXI/APB, and VHDL remain deferred.

AHB requester BUSY-insertion behavior:
[IAL2_AHB_REQUESTER_BUSY_INSERTION_BEHAVIOR](../../IAL2_AHB_REQUESTER_BUSY_INSERTION_BEHAVIOR.md)
documents `.788`, the shipped additive
`ppif/ahb_requester_busy_insert.ppif` source. It adds `(busy 2'b01)` and
`(busy-before-beat 2)` to the requester transfer block, generates a
`transfer_busy` drive plus one-bit `busy_inserted_q` one-shot, holds the pending
address/control/data and counters across the BUSY presentation, then resumes the
same beat as `SEQ`. The report adds `busy_insertion` and
`ahb_requester_busy_insert_support`; support identity is
`intent.ppif_ahb_requester_busy_insert` with coverage
`ial2_ppif_ahb_requester_busy_insert_pipeline_cli`. Focused t/1498 proves
`NONSEQ(0) → SEQ(1) → BUSY(2 held) → SEQ(2 resumed) → SEQ(3)`, exact four data
beats, diagnostics, CLI/report/support surfaces, and base-requester preservation.
`.788` closed at 309 protocol / 350 supported-smoke and strict entries. The
matching `.ahb` alias now ships; policy/runtime/multi-beat BUSY, a distinct local
bus-BUSY status, two-subordinate paired behavior, larger burst progression,
optional signals, broader AHB, backend variants, AXI/APB, and VHDL remain
deferred. The first generic paired composition now ships below.

AHB requester BUSY-insertion profile-alias contract:
[IAL2_AHB_REQUESTER_BUSY_INSERTION_PROFILE_ALIAS_CONTRACT_SELECTION](../../IAL2_AHB_REQUESTER_BUSY_INSERTION_PROFILE_ALIAS_CONTRACT_SELECTION.md)
documents `.789`, which selected `.790`; `.790` now ships the matching
`ppif/ahb_requester_busy_insert.ahb` alias as a byte-identical mirror of the
generic source. Existing `.ahb` parsing preserves the BUSY report and generated
artifacts while removing only `ahb_profile_alias_deferred`. Its support identity
is
`intent.ahb_profile_alias_requester_busy_insert` with coverage
`ial2_ahb_profile_alias_requester_busy_insert_pipeline_cli`; parser/generator
behavior remains unchanged. The canonical result is
[IAL2_AHB_REQUESTER_BUSY_INSERTION_PROFILE_ALIAS_BEHAVIOR](../../IAL2_AHB_REQUESTER_BUSY_INSERTION_PROFILE_ALIAS_BEHAVIOR.md).
Focused t/1512 proves alias parity/CLI/artifacts/support, t/1498 retains runtime
proof, and current accounting is 310 protocol / 351 supported-smoke and strict.

Post-requester-BUSY-alias selector:
[IAL2_POST_AHB_REQUESTER_BUSY_INSERTION_ALIAS_NEXT_SLICE_SELECTION](../../IAL2_POST_AHB_REQUESTER_BUSY_INSERTION_ALIAS_NEXT_SLICE_SELECTION.md)
documents `.791`, which selects `.792`, a no-behavior readiness audit for one
paired BUSY-inserting-requester/BUSY-parking-subordinate aggregate. A
current-state construction probe already composes the endpoint behaviors and
generated artifacts, with subordinate and aggregate `parks_on = [busy]`. The
probe also finds that `AhbInterconnect::_child_report` omits the requester's
optional `busy_insertion` block from aggregate JSON, so `.792` must settle
report propagation and exact end-to-end runtime proof before implementation.
Decision 0020 remains proposed/inactive.

Paired AHB BUSY composition readiness audit:
[IAL2_AHB_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT](../../IAL2_AHB_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md)
documents `.792`, which confirms the one-subordinate aggregate is
implementation-ready after contract selection and advances to `.793`. Existing
endpoint/interconnect/top machinery generates the full composition; only an
additive conditional aggregate-child clone of requester `busy_insertion` is
needed. The generated top already has sufficient command/status and
deterministic internal bus/subordinate observation points for held-BUSY,
parked-context, resumed-SEQ, four-beat, and final-storage proof. `.793` must
freeze the generic `.ppif` source/support/report/runtime contract; alias and
two-subordinate siblings were deferred by that audit and ship in later slices.

Paired AHB BUSY composition contract:
[IAL2_AHB_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION](../../IAL2_AHB_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md)
documents `.793`, which selects `.794` direct implementation of
`ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif`.
The aggregate requester child conditionally gains the existing
`busy_insertion` block; together with propagated `parks_on = [busy]`, this is
the selected non-duplicative paired report. Support targets are 311 protocol /
352 supported-smoke and strict. Focused t/1513/Verilator coverage must prove
held requester and subordinate state/storage on BUSY, resumed `SEQ`, four data
beats, OKAY/zero remaining, and final `32'h44332211`. Generic `.ppif` ships
first; the alias and generic two-subordinate variant ship in later slices.

Paired AHB BUSY composition behavior:
[IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR](../../IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md)
documents `.794`, which ships the selected generic one-requester/
one-subordinate pair. Aggregate requester-child JSON conditionally preserves
`busy_insertion`; subordinate-child and aggregate SEQ-policy propagation keep
`parks_on = [busy]`; there is no duplicate top summary. Generated-HDL t/1513
proves `NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)`, one
BUSY, four byte data beats, held requester/subordinate state and storage,
OKAY/zero completion, and final `32'h44332211` storage. The prerequisite AHB
phase corrections make the requester hold through data-phase `HREADY`, claim
each subordinate transfer once, replace the competing idle-clear transaction
with a concurrent rule, use width-safe counted wait cycles, select HDL-safe
interconnect instance `fabric`, and omit the tautological zero-base lower bound.
The public source passes `--verify-hdl`; accounting is 311 protocol / 352
supported-smoke and strict. True boundary-free active-transfer pipelining and
broader BUSY policy remain deferred. The matching one-subordinate alias and
generic two-subordinate paired behavior ship below.

Paired AHB BUSY composition profile-alias contract:
[IAL2_AHB_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION](../../IAL2_AHB_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md)
documents `.795`, which selected `.796`; `.796` now ships the matching
`ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb`
profile alias. The byte-identical source preserves the exact generated
IAL1/IAL0 artifacts, requester-child `busy_insertion`, subordinate/aggregate
`parks_on = [busy]`, and bounded support residue while existing suffix handling
removes only aggregate/requester/subordinate alias residue. The `.ppif` and
`.ahb` files are two public source surfaces for one generator architecture,
not two generators. Support is now 312 protocol / 353 supported-smoke and
strict; focused t/1514 proves alias public surfaces and t/1513 retains runtime.
Two-subordinate paired behavior, broader BUSY/status/burst work, proposed
audits, and decision 0020 remain deferred or inactive.

Paired AHB BUSY composition profile-alias behavior:
[IAL2_AHB_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR](../../IAL2_AHB_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md)
documents the `.796` shipped alias, exact source/artifact/report parity,
support identity, alias-only residue cleanup, commands, validation, and
explicit deferrals.

Post paired AHB BUSY family selector:
[IAL2_POST_AHB_PAIRED_BUSY_FAMILY_NEXT_SLICE_SELECTION](../../IAL2_POST_AHB_PAIRED_BUSY_FAMILY_NEXT_SLICE_SELECTION.md)
documents `.797`, which selects `.798`, a no-behavior readiness audit for the
two-subordinate paired BUSY sibling. The existing four-child generator path
already composes requester `busy_insertion` with both status/control
`parks_on=[busy]` policies. The audit must freeze the two-window runtime proof
and resolve contradictory residue that simultaneously calls BUSY continuation
deferred and BUSY parking shipped. Decision 0020 and proposed audits remain
inactive.

Two-subordinate paired AHB BUSY readiness audit:
[IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_READINESS_AUDIT](../../IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_READINESS_AUDIT.md)
documents `.798`. The temporary candidate passes check, schedule, semantic,
review-artifact, SystemVerilog, and Yosys surfaces with four children, exact
status/control windows, requester `busy_insertion`, and both propagated
`parks_on=[busy]`. `.799` first repairs contradictory shipped BUSY residue
without behavior change; `.800` then selects the paired public contract and
two-window runtime proof. Decision 0020 and proposed audits remain inactive.

Two-subordinate AHB BUSY report repair:
[IAL2_AHB_TWO_SUBORDINATE_BUSY_REPORT_REPAIR](../../IAL2_AHB_TWO_SUBORDINATE_BUSY_REPORT_REPAIR.md)
documents `.799`. Parked two-subordinate generic/alias reports now say shipped
BUSY parking consistently in both broader-interconnect and burst residue,
while non-parking reports keep BUSY-continuation deferral. No source, artifact,
support count, or HDL/runtime behavior changed. `.800` is active for paired
public contract selection; decision 0020 and proposed audits remain inactive.

Two-subordinate paired AHB BUSY contract selection:
[IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_CONTRACT_SELECTION](../../IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_CONTRACT_SELECTION.md)
documents `.800` and selects `.801`. The exact generic source reuses the
existing four-child generator, adds one support entry for 313 protocol / 354
supported-smoke+strict, and requires t/1515 to prove status-base-0 and
control-base-4 `INCR4` BUSY parking with local-address subtraction,
non-interference, and `44332211`/`88776655` storage. The alias remains later;
decision 0020 and proposed audits remain inactive.

Two-subordinate paired AHB BUSY behavior:
[IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_BEHAVIOR](../../IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md)
documents `.801`. The shipped generic `.ppif` source reuses the existing
four-child generator path, support-accounts at 313 protocol / 354
supported-smoke+strict, and exposes requester `busy_insertion` plus both
status/control `parks_on=[busy]` policies. Generated-HDL t/1515 proves exact
status-base-0 and control-base-4 `NONSEQ,SEQ,BUSY,SEQ,SEQ` flows, selected-
child parking, unselected-child non-interference, control local-address
subtraction, and retained `44332211`/`88776655` storage. No generator
algorithm changed; the matching alias, decision 0020, and proposed audits
remain inactive.

Two-subordinate paired AHB BUSY profile-alias contract:
[IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION](../../IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md)
documents `.802`, which selects `.803`. The future `.ahb` file is a
byte-identical mirror of the `.801` generic source and reuses the same
four-child generator architecture. An in-memory reserved-label probe preserves
all four IAL1/five IAL0 artifacts, requester `busy_insertion`, both
status/control `parks_on=[busy]` policies, and removes only alias residue.
t/1516 will prove parity/public surfaces; t/1515 retains runtime proof. Targets
are 314 protocol / 355 supported-smoke+strict. Decision 0020 and proposed
audits remain inactive.

Two-subordinate paired AHB BUSY profile-alias behavior:
[IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR](../../IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md)
documents `.803`. The shipped `.ahb` alias is byte-identical to the `.801`
generic source and reuses one four-child generator path. It preserves exact
artifacts/windows, requester `busy_insertion`, both status/control
`parks_on=[busy]`, and t/1515 runtime behavior while existing suffix handling
removes only alias residue. t/1516 proves parity/public surfaces, diagnostics,
and `--verify-hdl`; accounting is 314 protocol / 355 supported-smoke+strict.
Decision 0020 and proposed audits remain inactive.

Post-paired-BUSY-family next-owner selection:
[IAL2_POST_TWO_SUBORDINATE_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION](../../IAL2_POST_TWO_SUBORDINATE_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION.md)
documents `.804`. It selects the existing requester WRAP-progression audit as
the next exact AHB owner because the shipped generator and emitted IAL0 FSM
contain a concrete sequential mutation/retest hazard: a wrap-boundary clause
may write `addr_q = wrap_base_q`, then the following negated clause may
re-evaluate the mutated address and overwrite it with base-plus-step. No
current requester generated-HDL test records accepted `WRAP4` addresses through
the boundary, so the audit must prove or disprove the risk before selecting any
repair. Policy/multiple BUSY, distinct bus-BUSY status, larger bursts,
boundary-free pipelining, and optional signals remain deferred. The audit is
not activated until `.804` commits cleanly; decision 0020 remains inactive.

Requester WRAP-progression runtime audit:
[IAL2_AHB_REQUESTER_WRAP_PROGRESSION_RUNTIME_AUDIT](../../IAL2_AHB_REQUESTER_WRAP_PROGRESSION_RUNTIME_AUDIT.md)
documents `.1`. At audit commit `ec9fa2ee3`, generated-HDL t/1517 proved byte
`WRAP4` from address `3` presented `3,1,2,3`, not required `3,0,1,2`: a
generated state wrote `wrap_base_q`, then the next state re-tested the mutated
address and overwrote base-plus-step. The common path serves WRAP4/8/16. `.2`
was selected to repair both the IAL2 requester generator and direct requester
seed, using increment first
then wrap when the incremented address equals `wrap_high_q`; no public clause,
report field, support entry, or artifact name changes. The audit itself changes
no behavior.

Requester WRAP-progression repair:
[IAL2_AHB_REQUESTER_WRAP_PROGRESSION_REPAIR](../../IAL2_AHB_REQUESTER_WRAP_PROGRESSION_REPAIR.md)
documents `.2`. The generated requester and both direct-seed success paths now
increment first and then replace an incremented `wrap_high_q` value with
`wrap_base_q`. Generated-HDL t/1517 proves byte/halfword/word WRAP4 plus byte
WRAP8/WRAP16, including required byte WRAP4 start `3` addresses `3,0,1,2`.
Public syntax, ports, reports, support accounting, artifacts, non-wrap
progression, and paired BUSY INCR4 behavior remain unchanged. Broader bursts,
BUSY policy/status, optional AHB signals, and decision 0020 remain deferred or
inactive.

Post-requester-WRAP next-owner selection:
[IAL2_POST_REQUESTER_WRAP_REPAIR_NEXT_OWNER_SELECTION](../../IAL2_POST_REQUESTER_WRAP_REPAIR_NEXT_OWNER_SELECTION.md)
documents `.805`. Six aggregate/paired AHB `.ahb` aliases ship with t1493,
t1497, t1514, and t1516 parity ownership, but current mdBook navigation/mode
text and three canonical behavior/fact pairs still defer one or more aliases.
`.806` owns a current-truth-only repair plus t1518 drift coverage, preserving
historical time-local statements and all code/source/support/runtime behavior.
The boundary-free active-transfer audit and decision 0020 stay proposed and
inactive.

AHB current-surface alias truthfulness repair:
[IAL2_AHB_CURRENT_SURFACE_ALIAS_TRUTHFULNESS_REPAIR](../../IAL2_AHB_CURRENT_SURFACE_ALIAS_TRUTHFULNESS_REPAIR.md)
documents `.806`. Current protocol navigation, AHB mode/requester guidance,
and the aggregate HBURST, aggregate BUSY-park, and paired BUSY behavior/fact
pairs now acknowledge six shipped aliases while preserving historical
time-local statements. t/1518 locks the paths and current claims. No
code/source/support/report/artifact/HDL/runtime behavior changes; the
boundary-free audit and decision 0020 remain proposed/inactive.

Post-current-surface-repair next-owner selection:
[IAL2_POST_CURRENT_SURFACE_REPAIR_NEXT_OWNER_SELECTION](../../IAL2_POST_CURRENT_SURFACE_REPAIR_NEXT_OWNER_SELECTION.md)
documents `.807`. It selects the existing boundary-free AHB active-transfer
audit because generated subordinate ownership releases only on an unselected,
`IDLE`, or `BUSY` boundary and existing paired runtime supplies that boundary.
Audit `.1` must drive consecutive selected NONSEQ/SEQ phases, record address/
data ownership, ready/response, acceptance, and storage exactly once, and make
no behavior change. Decision 0020 remains inactive.

AHB pipelined active-transfer runtime audit:
[IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT](../../IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md)
documents `.1`. Generated-HDL t/1519 proves two ready/OKAY bus acceptances for
direct `NONSEQ` address 0 then `SEQ` address 1, but only one internal admission
and completion; sampled address/transfer remain 0/`NONSEQ`, and the second
lane-one write is absent from storage. An endpoint-only boundary requirement
would deadlock or accept the held next phase, so `.2` is selected to freeze a
bounded atomic completion-edge phase-recapture contract before implementation.
Decision 0020 remains inactive.

AHB pipelined active-transfer contract selection:
[IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION](../../IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md)
documents `.2`. The bus accepts the next active address phase at cycle 37,
eleven cycles before generated internal done, so `.3` must capture exactly one
next address/control phase at the ready/completion edge. The bank contains
HADDR/HTRANS/optional HBURST/HWRITE/HSIZE/wait_cycles, not data-phase HWDATA;
it drives the following data phase not-ready and relaunches after the current
FSM tail. Sequence history commits before queued evaluation. Final ERROR plus
IDLE cancels, while final ERROR plus active HTRANS captures. The report gains
an additive `phase_pipeline` policy; `.4` separately audits the direct `.fsm`
seed. General queues and decision 0020 remain inactive.

AHB pipelined active-transfer repair:
[IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_REPAIR](../../IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_REPAIR.md)
documents `.3`. The generated subordinate now has one accepted
HADDR/HTRANS/optional HBURST/HWRITE/HSIZE/wait_cycles bank and never banks
data-phase HWDATA. Preservation required the generated requester to separate
address/data ownership, retire accepted HTRANS to IDLE, and capture response/
read data at completion; the generated interconnect now retains one one-hot
subordinate data-phase owner through that completion. t/1519 proves exact
boundary-free NONSEQ-to-SEQ retention and final-ERROR active-capture versus
IDLE cancel; t/1513 and t/1515 preserve exact paired results. Public source,
support, artifact, and direct-seed identities are unchanged. General/deeper
queues, multiple outstanding transfers, `.4` direct-seed audit work, and
decision 0020 remain outside this leaf.

Direct AHB subordinate pipelined active-transfer runtime audit:
[IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT](../../IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md)
documents `.4`. Generated-HDL t/1520 proves the unchanged direct
`fsm/ahb_lite_subordinate.fsm` seed accepts two active address phases at the
bus but captures/completes only one when the second lands on either successful
or final-ERROR completion. `ACCESS` and `ERROR_COMPLETE` return to `IDLE`
without sampling the accepted phase. The success case retains storage
`0x11111111`; the ERROR case keeps exactly two ERROR cycles and zero storage.
No behavior changes. `.5` historically owned exact direct-seed contract
selection; `.6` later invalidated its no-bank realization, and `.7`/`.8` now
own corrected selection/implementation. The generated family and decision
0020 remain unchanged/inactive.

Direct AHB subordinate pipelined active-transfer contract selection:
[IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION](../../IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md)
documents `.5`. The historical no-queue direct-state contract atomically
dispatches selected accepted NONSEQ from successful/final-ERROR completion by
loading existing addr/write/size/wait registers and entering `ACCESS`; selected
SEQ loads wait and enters `UNSUPPORTED`; IDLE/BUSY/unselected returns to
`IDLE`. `.6` proved that realization unsafe because direct register-input mux
outputs also feed current completion predicates: capturing the following
read's `HWRITE=0` suppressed the completing write and produced storage zero.
The failed attempt was restored. The
[completion-capture substrate audit](../../IAL2_AHB_DIRECT_SUBORDINATE_COMPLETION_CAPTURE_SUBSTRATE_AUDIT.md)
records the evidence. The
[register-output completion contract](../../IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_CONTRACT_SELECTION.md)
records `.7`'s selected Q-named `<-` four-state correction and its warning-clean
four-scenario probe; the D-input bank/relaunch fallback was rejected for
`UNOPTFLAT` and extra latency. The
[register-output completion repair](../../IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_REPAIR.md)
now records `.8` shipment: t1520 proves exact success/ERROR/SEQ/IDLE retention
with Q-named four-state dispatch, one capture/completion per acceptance, and no
pending/relaunch. Generated roles, public/support/artifact identities, broader
AHB, and decision 0020 remain unchanged.

Post AHB phase-repair selector:
[IAL2_POST_AHB_PHASE_REPAIR_NEXT_OWNER_SELECTION](../../IAL2_POST_AHB_PHASE_REPAIR_NEXT_OWNER_SELECTION.md)
records `.808` selection of
`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT`. `.1` proved the
pre-repair one-bit procedural insertion exposed ten ready-qualified BUSY edges
under continuously-ready operation even though report JSON said
`beats=single`; the former requester/paired tests counted only one HTRANS episode.
The imported Arm specification permits fixed-length BUSY-to-SEQ changes while
ready is low, so the defect is accepted-edge cardinality rather than that
transition. Assertion-enabled single/count-two candidates pass continuously-
ready and 32-clock ready-low cases with four unchanged data beats. `.2` now
selects `single` as exactly one rising
`HGRANT && HREADY && HTRANS == BUSY` event. A conditional accept rule hands the
same transfer into existing address-pending `SEQ` ownership, and a ready/BUSY
gate keeps BUSY pending through ready or grant stalls; no new public syntax,
report field, storage, or counter is needed. Assertion-enabled public
32-clock ready-low and grant-low probes each pass with one qualified BUSY event
and four data beats. `.3` now ships that conditional rule/gate repair. t/1498
keeps assertions enabled and proves continuously-qualified plus both 32-clock
stall scenarios; t/1513-t/1516 require one qualified embedded BUSY event per
generic/alias paired command. Public syntax/report/support/artifacts remain
unchanged. A separate proposed interconnect owner tracks the pre-existing
default/decode selector conflict that keeps paired runtimes on `--no-assert`.
Multiple-BUSY implementation remained unshipped at `.3`; generalized counts,
runtime-selected throttling, local bus-BUSY status, larger bursts, optional
signals, and decision 0020 remain deferred/inactive. See the
[selected repair contract](../../IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR_CONTRACT_SELECTION.md)
and [shipped repair](../../IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR.md).

`.4` selected the first public exact-two extension without changing shipped
behavior. Additive generic source
`ppif/ahb_requester_busy_insert_two.ppif` adds optional literal
`(busy-beats 2)` beside `(busy-before-beat 2)`; absence preserves exact-one and
all other values fail closed. The selected width-two
`ahb_busy_remaining_q` initializes before BUSY visibility, decrements only on
qualified non-final BUSY events, and on the second event clears and reuses
existing address-pending `SEQ` ownership. The new source reports numeric
`busy_insertion.beats=2`, support-accounts as
`intent.ppif_ahb_requester_busy_insert_two`. `.5` now ships it through the
existing requester generator with actor-owned counter storage and a
checker-required final-over-nonfinal rule priority. Assertion-enabled t1521
passes continuous/32-clock-ready-low/32-clock-grant-low exact-two proof, and
accounting is 315 protocol / 356 supported-smoke+strict fixtures. The
matching alias now ships after `.6` selected `.7`: byte-identical
`ppif/ahb_requester_busy_insert_two.ahb` uses existing suffix handling, support
identity `intent.ahb_profile_alias_requester_busy_insert_two`, semantic root
`fsm`, and no parser/generator or runtime change. Focused t1522 proves
report/artifact/semantic JSON/real read-only MCP parity; t1521 remains the
shared runtime. That requester/alias checkpoint was 316 protocol / 357
supported-smoke+strict fixtures and 40 AHB paths. The first generic
one-subordinate paired exact-two source and its matching aggregate alias now
ship, as does the generic two-subordinate exact-two sibling. Its matching
two-subordinate alias, other counts/points,
policy/runtime behavior, and decision 0020 remain deferred. See the
[exact-two contract](../../IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_CONTRACT_SELECTION.md)
[shipped behavior](../../IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_BEHAVIOR.md),
the
[selected exact-two alias contract](../../IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md),
and [shipped alias behavior](../../IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md).

`.809` selects the next no-behavior owner:
[IAL2 exact-two paired BUSY composition readiness](../../IAL2_POST_REQUESTER_MULTI_BUSY_NEXT_OWNER_SELECTION.md).
An in-memory one-requester/one-subordinate candidate already preserves three
children, `ahb_tb`, the exact-two requester artifacts and numeric child
`busy_insertion.beats=2`, plus subordinate and propagated `parks_on=[busy]`.
The [completed runtime audit](../../IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md)
now proves one BUSY transition episode with exactly two qualified events,
stable requester pending fields/counters, stable subordinate
continuation/phase/storage and interconnect data owner, no BUSY data-beat
completion, one resumed pending `SEQ`, four clean byte beats, and final storage
`32'h44332211`. The same existing generators produce all three children and
the `ahb_tb` top; no substrate repair is required. The
[selected contract](../../IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md)
freezes generic source
`ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif`,
the unchanged three-child artifact/report shape, t1523 runtime, normalized
semantic JSON and real read-only MCP proof. `.3` now ships that generic source
through the existing generators at 317 protocol / 358 supported+strict / 41
AHB paths. Its matching alias and the generic two-subordinate exact-two
composition now also ship. The matching two-subordinate alias subsequently
ships, and the generic exact-three requester follows below; policy/runtime
insertion, exact-three paired compositions, and decision 0020 remain
separate/inactive.
See the
[shipped behavior](../../IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md).
`.4` now selects proposed `.5` data-only implementation of the byte-identical
matching `.ahb` alias. Existing suffix handling preserves three children,
numeric requester `beats=2`, BUSY parking, artifacts, and normalized semantic
root `top` while removing only alias residue. Projected accounting is
318/359/42; t1524 must prove real read-only MCP parity without a second runtime,
with t1523 shared. No alias ships from `.4`; two-subordinate exact-two and
decision 0020 remain separate/inactive. See the
[selected alias contract](../../IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md).
`.5` shipped that byte-identical alias at the 318/359/42 checkpoint;
t1524 proves strict/schedule/normalized-semantic/real read-only MCP parity and
t1523 remains the shared runtime. Follow-on `.6` ships no source, but its
[two-subordinate exact-two readiness audit](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md)
proves the existing four-child architecture across both windows. Two commands
produce exactly four qualified BUSY events, two resumed `SEQ` events, eight
data beats, stable selected/unselected subordinate and interconnect ownership,
clean status, and final status/control storage
`32'h44332211`/`32'h88776655`. Strict check, normalized semantic JSON, and a
real read-only MCP call agree on `ahb_tb`/root `top`/four children; support is
truthfully unmatched for the disposable candidate. No substrate or API repair
is required. Follow-on `.7` selected `.8` implementation of topology-first
generic source
`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif`.
The name explicitly separates topology from requester cardinality and avoids
an ambiguous double-`two`. The
[selected contract](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md)
freezes the existing four-child artifacts, status/control windows, retained
response owner, numeric requester `beats=2`, both child/propagated BUSY parks,
t1525's single two-command runtime, normalized semantic JSON, and real
read-only MCP parity. `.8` now ships that source through the existing
generators. Focused t1525 proves strict/source/schedule/report/artifact/outdir/
verifier parity, normalized semantic JSON, the real read-only MCP adapter, and
one two-command generated-HDL runtime totaling four qualified BUSY events, two
resumed `SEQ` events, eight data beats, and final status/control storage
`44332211`/`88776655`. That source established the 319/360/43 checkpoint with
22 `.ppif` and 21 `.ahb`. See the
[shipped behavior](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md).
At that `.8` checkpoint, the matching alias and decision 0020 remained
separate.
Parent selector `.810` now chooses proposed `.811` direct data-only
implementation of that byte-identical matching `.ahb` alias. Existing suffix
handling preserves the exact four-child report/artifact/window/owner contract,
numeric requester `beats=2`, both BUSY parks, normalized semantic root `top`,
and real read-only MCP parity while removing only profile-alias residue. The
projected checkpoint is 320/361/44 with 22 `.ppif` and 22 `.ahb`; focused
t1526 will prove byte/report/artifact/strict/semantic/MCP/outdir/verifier/
diagnostic parity without a second simulation, with t1525 shared. See the
[selected alias contract](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md).
No behavior changes in `.810`; broader AHB and decision 0020 remain separate.
`.811` now ships the byte-identical matching alias at 320/361/44, evenly split
22 `.ppif`/22 `.ahb`. Focused t1526 passes four subtests covering byte/report/
artifact/strict/schedule/normalized-semantic/real read-only MCP/outdir/
verifier/diagnostic and preservation parity without a second simulation;
t1525 remains the shared two-window runtime. No parser, generator, semantic
model, or MCP API changed. See the
[shipped alias behavior](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md).

Post-alias selector `.812` changes no behavior. Static inspection finds that
literal `(busy-beats 3)` fits the shipped width-two requester counter and the
current qualified non-final/final rules would retire it as
`3 -> 2 -> 1 -> 0` through the same pending `SEQ` handoff. Because only
literal two has assertion-enabled runtime proof, `.812` selects proposed
`IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.1` rather than
public implementation. The audit must use a same-volume disposable candidate
and guarded continuous/32-ready-low/32-grant-low generated HDL to prove exact
three-event cardinality, stable ownership, one resumed `SEQ`, four data beats,
and zero remaining. See the
[next-owner selection](../../IAL2_POST_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION.md).

Exact-three readiness audit `.1` now passes without changing the public
surface. A same-volume disposable candidate preserved the width-two counter
and existing qualified non-final/final rules. One assertion-enabled generated-
HDL binary proved continuous, 32-clock ready-low, and 32-clock grant-low
operation with internal `3 -> 2 -> 1 -> 0`, exactly three qualified BUSY
events, no stall-time consumption or BUSY data completion, stable pending
ownership, one resumed `SEQ`, four byte `INCR4` data beats, and zero final
count. Strict check, schedule/report, exact artifacts, normalized semantic JSON,
and real read-only MCP parity also passed; exact-one/two/base and malformed
boundaries remained distinct. No lower-layer repair is needed. Proposed `.2`
owns the public exact-three contract before implementation. See the
[readiness audit](../../IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_INSERTION_READINESS_AUDIT.md).

Contract leaf `.2` now selects proposed `.3`, the additive generic
`ppif/ahb_requester_busy_insert_three.ppif` implementation. The bounded
language will accept literal `busy-beats` values 2..3 while absence remains
exact-one; 0/1/4+/non-literals stay invalid. The existing width-two counter,
qualified non-final/final rules, priorities, and pending `SEQ` ownership are
unchanged. Exact-three reports numeric `beats=3`, shared exact-one/two/three
residue becomes truthful, and projected support is 321/362/45 split 23
`.ppif`/22 `.ahb`. Focused t1528 must directly prove internal
`3 -> 2 -> 1 -> 0` under continuous/32-ready-low/32-grant-low operation, and
t1521 gains direct exact-two `2 -> 1 -> 0` observation. The matching
exact-three `.ahb` alias remains a later selector. See the
[selected contract](../../IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_CONTRACT_SELECTION.md).

Leaf `.3` now ships that generic exact-three requester. The normalizer accepts
only literal values 2..3, the source reports numeric `beats=3`, and shared
exact-one/two/three residue now defers only counts above three plus broader
policy/points. The width-two counter and qualified rules are unchanged.
Assertion-enabled t1528 passes continuous/32-ready-low/32-grant-low runtime
with direct `3 -> 2 -> 1 -> 0` observation, one BUSY episode, three qualified
events, one resumed `SEQ`, four data beats, stable pending ownership, and zero
final count; t1521 now directly locks exact-two `2 -> 1 -> 0`. Strict,
schedule, artifact, verifier, normalized semantic JSON, and real read-only MCP
parity pass. The generic checkpoint is 321/362/45 split 23 `.ppif`/22 `.ahb`.
Leaf `.4` now selects active `.5`, data-only implementation of the matching
byte-identical exact-three `.ahb` alias. Existing suffix handling preserves
numeric `beats=3`, exact IAL1/IAL0/HDL, and normalized semantic/read-only MCP
behavior while removing only alias residue. The projected checkpoint is
322/363/46 split 23 `.ppif`/23 `.ahb`; focused t1529 must prove parity without
a second runtime, and t1528 remains shared. No alias ships from `.4`. See the
[shipped behavior](../../IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_BEHAVIOR.md)
and the
[selected alias contract](../../IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md).
At activation after clean selector commit `b7c62d2b6`, the alias and projected
accounting remained unshipped; the `.5` outcome follows.
Leaf `.5` now ships the byte-identical alias at
`ppif/ahb_requester_busy_insert_three.ahb`. Existing suffix handling removes
only profile-alias residue while preserving numeric `beats=3`, exact artifacts,
HDL, and normalized semantic/read-only MCP behavior. Focused t1529 passes four
top-level subtests/72 nested assertions without a second simulation; t1528
remains the shared runtime proof. That shipment established the 322/363/46
checkpoint split 23/23.
See the
[shipped alias behavior](../../IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md).
Clean alias commit `c224b2cba` satisfies the parent activation boundary, so
`.813` is now the active documentation-only selector for the next exact IAL2
owner. No new behavior ships from activation.
Leaf `.813` now selects proposed
`IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1`. The shipped
interconnect emits subordinate select/address defaults and mapped-hit writes
to the same outputs in one state, assertion-enabled evidence fails first on
`HADDR_REGS`, and aggregate runtime tests t1513/t1515/t1523/t1525 retain
`--no-assert`. This correctness audit therefore precedes exact-three paired
expansion. It must reproduce the base conflict, map the complete overlap, and
select the smallest repair owner without changing behavior. See the
[post-alias selector](../../IAL2_POST_EXACT_THREE_REQUESTER_ALIAS_NEXT_OWNER_SELECTION.md).
The `.813` selector committed cleanly at `347a85f80`; the selected arbitration
audit `.1` is now active. Activation changes continuity/docs state only.
Audit `.1` now reproduces the base assertion at mapped addresses zero and two,
maps eight one-window and eleven two-window selector targets, and isolates the
actual conflicts to five and seven outputs respectively. `HADDR_*`/`HSEL_*`
overlap mapped hit with ordinary defaults; `HRDATA`/`HREADY`/`HRESP` overlap
retained-owner or unmapped handling with their defaults. `HGRANT`, owner bits,
and `next_state` are instrumented but exclusive. The repair belongs in
generated `AhbInterconnect` IAL0; generic selector analysis/assertions remain
correct and mandatory. Proposed child `.2` owns exact no-behavior contract
selection after the audit commits cleanly. See the
[arbitration audit](../../IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_AUDIT.md).
Audit commit `c32255645` is clean, so contract-selection child `.2` is now
active. Activation changes continuity/docs state only; no arbitration repair
has started.
Contract leaf `.2` now selects proposed implementation `.3`. Per-window
`HSEL_*`/`HADDR_*` use complementary mapped-hit/not-hit modes; global
`HREADY`/`HRESP`/`HRDATA` use retained-owner, first-cycle-unmapped, or
`!any_owner && !unmapped_address` ordinary-default modes. Independent owner
blocks preserve impossible-multiple-owner assertion visibility, and all
decode/phase/report/public behavior remains fixed. A paired feasibility probe
with only fabric assertions suppressed exposed a separate subordinate
idle-state plus `ahb_phase_capture` `HRDATA_REGS <- 0` overlap, so `.3` uses
direct-fabric assertion-enabled t1530 and keeps paired `--no-assert`; proposed
`IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1` owns the endpoint
audit. See the
[selected arbitration contract](../../IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md).
Contract commit `3883c3a0d` is clean, so selected implementation `.3` is now
active. Activation changed continuity/documentation state only. Leaf `.3` now
ships complementary mapped-hit/not-hit `HSEL_*`/`HADDR_*` modes and exclusive
retained-owner, first-cycle-unmapped, or ordinary global response modes.
Assertion-enabled direct-fabric t1530 passes one- and two-window mapped-zero,
mapped-nonzero, wait, success, subordinate ERROR, same-edge replacement, and
two-cycle unmapped ERROR behavior. Paired aggregate tests retain `--no-assert`
only for the separately tracked subordinate idle/phase-capture overlap. See
the
[shipped arbitration behavior](../../IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_BEHAVIOR.md).
Clean child commit `6eeac974c` completes the arbitration tree. Parent selector
`.814` activated from that handoff-ready boundary and now selects proposed
`IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1`. Direct fabric
assertions pass, but paired t1513-t1516/t1523/t1525 retain `--no-assert`; the
durable endpoint probe identifies overlapping transaction-idle and
`ahb_phase_capture` `HRDATA_REGS <- 0` families. Exact-three paired expansion
follows the no-behavior endpoint audit. See the
[post-interconnect selector](../../IAL2_POST_INTERCONNECT_ARBITRATION_NEXT_OWNER_SELECTION.md).
The `.814` selector committed cleanly at `ece98c002`. After the independently
parked scalability requirement also committed cleanly at `54964456f` without
changing priority, the selected subordinate audit `.1` is active. Activation
changes continuity and documentation state only; no behavior repair has
started.
Audit `.1` independently reproduces the generated direct endpoint at time 40
on `HRDATA 0` and the repaired-fabric paired endpoint at time 345 on
`HRDATA_REGS 0`. Base, byte-lane, SEQ, HBURST/SEQ, and BUSY-park variants have
8/10/20/20/20 total conflict targets respectively, with exactly three bus
targets each. Runtime proves idle+capture, idle+hold, and final-ERROR
retire+capture modes while success/read/write/SEQ/BUSY/IDLE behavior and all
internal assertions remain intact under diagnostic-only bus logging. Generic
priority correctly keeps same-value multiple ownership visible, so proposed
`.2` owns the exact `AhbSubordinate.pm`-local contract. A separate
hand-authored IAL0 seed conditional-override gap is parked without changing
priority. See the
[subordinate arbitration audit](../../IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_AUDIT.md).
Audit commit `0dad690cb` is clean, so selected generated-endpoint contract leaf
`.2` is active. Activation changes continuity and documentation state only;
the direct IAL0 seed task remains parked and no output repair has started.
Contract `.2` selects exactly five redundant generated-IAL1 write removals:
HRESP/HRDATA from capture and hold plus HRDATA from error retirement. It keeps
all HREADYOUT ownership, retirement OKAY, transaction/data/ERROR drives,
priorities, and generic assertions. The richest disposable candidate passes
the existing active success/SEQ, ERROR continuation, and ERROR cancellation
runtime with assertions enabled and exact results unchanged. Proposed `.3`
owns implementation and assertion-enabled base/rich plus one-/two-window
paired gates; the direct IAL0 seed remains parked. See the
[selected subordinate arbitration contract](../../IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md).
Contract `.2` commits cleanly at `ef14893f5`, so implementation `.3` is active.
Activation changes continuity/documentation state only; no generated output
repair has shipped yet.
Implementation `.3` now removes exactly the selected five generated-IAL1
writes. Assertion-enabled t1519 passes both base and richest direct endpoints;
t1513-t1516, t1523, and t1525 retire `--no-assert` across the one-/two-window
generic/alias exact-one/exact-two paired family without changing exact BUSY,
transfer, beat, SEQ, ERROR, or storage results. Generic assertions stay
authoritative, all public/report/support/semantic/MCP surfaces remain fixed,
and the separately hand-authored direct IAL0 seed stays parked. See the
[shipped subordinate arbitration behavior](../../IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_BEHAVIOR.md).
Clean behavior commit `1eec6253d` completes the generated subordinate
arbitration tree, and clean HIAL/VIAL parking commit `64f056b12` preserves the
active IAL2 priority. Parent selector `.815` is now active from that
handoff-ready boundary and selects proposed
`IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1`. Generated direct and paired
AHB tests now run with assertions; t1520 alone retains `--no-assert` because
the hand-authored seed has separate HREADYOUT, HRDATA, and HRESP conditional
overrides. Direct-seed correctness precedes exact-three paired expansion and
broader AHB work. See the
[post-subordinate selector](../../IAL2_POST_SUBORDINATE_ARBITRATION_NEXT_OWNER_SELECTION.md).
The `.815` selector committed cleanly at `8cae38a73`, so selected direct-seed
contract leaf `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1` is active.
Activation changes continuity and documentation state only; the seed and
t1520 assertion boundary remain unchanged until the contract is selected.
Contract `.1` selects proposed implementation `.2`: remove exactly access
HREADYOUT/HRESP/HRDATA zero writes and unsupported HRESP zero, relying on the
existing implicit zero mux baseline only where conditional nonzero owners
remain. Unsupported HREADYOUT/HRDATA zero drives stay explicit. An exact-four
repository-local candidate passes the complete t1520 harness with every
selector assertion enabled and unchanged success/ERROR/SEQ/IDLE results. The
tracked seed and `--no-assert` remain unchanged until `.2` activates. See the
[direct-seed arbitration contract](../../IAL0_AHB_DIRECT_SUBORDINATE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md).
Contract `.1` committed cleanly at `454767c15`, so implementation `.2` is
active. Activation changes continuity/documentation state only; no direct-seed
repair has shipped yet.
Implementation `.2` now ships exactly those four removals. Access receives
pending/OKAY/zero-data values from the existing emitted zero baseline until
its conditional ready/ERROR/read-data owner fires; unsupported keeps explicit
not-ready and zero-data owners while using the response baseline during its
wait. t1520 removes only `--no-assert` and passes all four unchanged scenarios
with selector assertions enabled. Public/report/semantic-MCP, generated IAL2,
protocol/backend/VHDL, and HIAL/VIAL boundaries remain unchanged. See the
[shipped direct-seed arbitration behavior](../../IAL0_AHB_DIRECT_SUBORDINATE_OUTPUT_ARBITRATION_BEHAVIOR.md).
Clean behavior commit `35a6fbfcf` completes the direct child tree. Parent
selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.816` selects proposed
`IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1` from that
handoff-ready boundary. A same-volume disposable generic one-subordinate
candidate compiles with every selector assertion enabled and passes five
presentations, four accepted beats, one BUSY episode, three qualified BUSY
events, one resumed `SEQ`, and storage `0x44332211`. The audit must still freeze
public source/support/report/semantic-MCP/test boundaries before any behavior;
aliases, the two-window form, broader BUSY semantics, HIAL/VIAL, and decision
0020 remain separate. See the
[post-direct selector](../../IAL2_POST_DIRECT_ARBITRATION_NEXT_OWNER_SELECTION.md).
Clean selector commit `bc3d9eaf1` activates only the selected readiness-audit
leaf. Activation changes continuity documentation and no generated or public
behavior; the audit must complete before any contract or implementation.
Audit `.1` now proves the existing exact-three requester and one-subordinate
parking aggregate compose through exact 3 IAL1/4 IAL0 artifacts with every
selector assertion enabled. Strict/schedule/normalized-semantic/read-only-MCP
surfaces agree, runtime passes 5/4/1/3/1/`44332211`, and current preservation
owners pass. Pending `.2` must freeze the one generic public source and
projected 323/364/47 support boundary before implementation. No exact-three
paired public source ships in the audit. See the
[readiness audit](../../IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md).
Clean audit commit `c1f3232f9` activates only contract selector `.2`.
Activation changes continuity documentation and no public or generated
behavior.
Contract `.2` now freezes one generic exact-three paired source through the
existing three-child architecture, exact support/semantic identities, and
assertion-enabled t1531 5/4/1/3/1/`44332211` runtime. Projected accounting is
323/364/47 split 24 `.ppif`/23 `.ahb`. Pending `.3` is the separate data-only
implementation; the source remains unshipped during selection. See the
[contract](../../IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md).
Clean contract commit `547d8102f` activates only `.3`; the selected source,
support path, and t1531 remain unshipped until implementation passes.
Implementation `.3` now ships the selected generic exact-three paired source
through existing generators. Exact 3 IAL1/4 IAL0 artifacts, strict support,
normalized semantic/read-only MCP parity, and assertion-enabled t1531
5/4/1/3/1/`44332211` runtime pass, moving current accounting to 323/364/47
split 24 `.ppif`/23 `.ahb`. The matching alias, two-subordinate exact-three
topology, broader BUSY policy, HIAL/VIAL activation, VHDL, and verification
generation remain separate. See the
[behavior record](../../IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md).

Clean behavior commit `00d71114d` activates only parent selector `.817` from
the 323/364/47 handoff. It now selects `.818`, the byte-identical
exact-three paired `.ahb` profile alias. A same-volume candidate proves strict,
exact-artifact, schedule, residue, and normalized-semantic readiness through
existing machinery; projected accounting is 324/365/48 split 24/24. t1532
will own alias parity and t1531 remains shared assertion-enabled runtime. The
smaller data-only IAL2 closure outranks two-window/new-policy work and the
broader HIAL/VIAL audit. HIAL/VIAL stays proposed with event-capable compiled
Verilator separated from authoritative full-language/SystemVerilog-UVM
simulation and with VHDL/mixed-language claims qualified independently. See
the [selection record](../../IAL2_POST_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md).
Clean selector commit `c70fe528f` activates only `.818`; the alias, support
entry, t1532, and projected accounting remain unshipped during activation.
Implementation `.818` now ships the byte-identical exact-three paired `.ahb`
alias through existing suffix/lowering machinery. t1532 proves byte, report,
strict, schedule, exact-artifact, normalized-semantic, real read-only MCP,
repository-local output, HDL-verifier, diagnostic, and preservation parity;
t1531 remains the shared assertion-enabled runtime. Current accounting is
324 protocol / 365 supported+strict / 48 AHB paths split 24 `.ppif`/24 `.ahb`.
Two-subordinate exact-three, broader BUSY policy/count/burst/signal work,
generic priority, HIAL/VIAL activation, VHDL, and verification generation
remain separate.
Clean behavior commit `d94f303d8` activates only no-behavior parent selector
`.819`. The selector must reconcile those adjacent owners and select exactly
one next bounded slice; activation changes continuity only.
Selector `.819` now chooses the proposed two-subordinate exact-three paired AHB
readiness audit. A same-volume disposable generic candidate strict-checks at
`ahb_tb`/4 children/29 signals, emits exact 4 IAL1/5 IAL0 artifacts, preserves
both parked endpoint contexts and one-hot response ownership, exports normalized
semantic root `top`, and passes `--verify-hdl`. The audit must still prove real
read-only MCP and assertion-enabled two-command 10/8/2/6/2 runtime with final
status/control `44332211`/`88776655` before selecting projected 325/366/49
support. HIAL/VIAL remains proposed with portable-fast event-capable compiled
Verilator separated from full-language/SystemVerilog-UVM authority and with
VHDL/mixed-language profiles qualified independently. See the
[selection record](../../IAL2_POST_EXACT_THREE_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md).
Clean selector commit `e2109a2ba` activates only the selected readiness-audit
`.1`; no public source, support, test, artifact, semantic/MCP API, HDL/runtime,
simulator, backend, HIAL/VIAL, VHDL, or verification-generation behavior
changes in activation.
Audit `.1` now proves real read-only MCP plus assertion-enabled two-window
exact-three 10/8/2/6/2 runtime with final status/control
`44332211`/`88776655`; no lower-layer repair is required. It selects proposed
generic public-contract `.2` at projected 325/366/49 split 25 `.ppif`/24
`.ahb`, pending a separate clean activation. No source ships in the audit.
Clean audit commit `c2aa63c3e` activates only generic contract `.2`; no public
source, support, test, artifact, API, HDL/runtime, HIAL/VIAL, VHDL, or
verification-generation behavior changes in activation.
Contract `.2` now freezes one generic source/support/t1533 boundary at
projected 325/366/49 split 25 `.ppif`/24 `.ahb` and selects proposed data-only
implementation `.3`, pending clean activation. No source ships in selection.
Clean contract commit `129d52967` activates only data-only implementation
`.3`; no public source, support, test, artifact, API, HDL/runtime, HIAL/VIAL,
VHDL, or verification-generation behavior changes in activation.
Implementation `.3` now ships the generic two-window exact-three source,
exact support identity, normalized semantic/read-only MCP parity, and
assertion-enabled t1533 10/8/2/6/2 runtime at 325/366/49 split 25 `.ppif`/24
`.ahb`. Proposed parent selector `.820` may activate only after the clean
behavior commit. The matching alias, broader BUSY semantics, HIAL/VIAL, VHDL,
and verification generation remain separate.
Clean behavior commit `1a73bc65e` activates only no-behavior parent selector
`.820`; activation changes continuity documentation and no public behavior.
Selector `.820` now chooses proposed `.821`, the byte-identical two-window
exact-three `.ahb` alias. A same-volume candidate passes strict, schedule,
exact 4 IAL1/5 IAL0 artifact, normalized semantic, real read-only MCP, and
public HDL-verifier checks without a repair. Projected accounting is
326/367/50 split 25/25; t1534 owns parity and t1533 remains shared runtime.
See the
[selection record](../../IAL2_POST_TWO_SUBORDINATE_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md).
Clean selector commit `f3585f98d` activates only data-only alias
implementation `.821`; activation changes continuity documentation and no
public behavior.
Implementation `.821` now ships the byte-identical two-window exact-three
`.ahb` alias and exact support identity at 326/367/50 split 25/25. Focused
t1534 proves byte/report/strict/schedule/artifact/normalized-semantic/
read-only-MCP/repository-local-output/HDL-verifier/diagnostic/preservation
parity without a second simulation; t1533 remains the shared assertion-enabled
10/8/2/6/2 runtime. Proposed `.822` owns the next roadmap-aligned selection.
Clean behavior commit `db402fd9d` activates only no-behavior selector `.822`;
activation changes continuity documentation and no public behavior.
Selector `.822` now chooses proposed exact-four requester BUSY counter-width
readiness. A same-volume one-file/2,313-byte transform fails closed before
output at the intentional literal-`2..3` normalizer boundary; the generator
also hardcodes width-two `ahb_busy_remaining_q`, making four the first
unrepresentable adjacent count. The audit must decide bounded width three
versus reusable minimum-width derivation and prove exact `4 -> 3 -> 2 -> 1 ->
0` runtime before selecting a public contract. See the
[selection record](../../IAL2_POST_TWO_SUBORDINATE_EXACT_THREE_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md).
Clean selector commit `db0990c9d` activates only exact-four readiness audit
`.1`; activation changes continuity documentation and no public behavior.
Audit `.1` now passes: a disposable IAL1 candidate changes only actor identity,
counter width `2 -> 3`, and initializer `3 -> 4`; unchanged rules lower and
verify cleanly, and assertion-enabled continuous/32-ready-low/32-grant-low
runs directly observe exact `4 -> 3 -> 2 -> 1 -> 0`, four qualified BUSY
events, five presentations, four data beats, and zero final counter. The next
proposed no-behavior `.2` must freeze minimum unsigned width
`ceil(log2(busy_beats + 1))`, so exact two/three remain width two and exact four
uses width three, before selecting any public literal-`2..4` implementation.
See the [readiness audit](../../IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_INSERTION_READINESS_AUDIT.md).
Clean audit commit `74d91347e` activates only no-behavior contract `.2`;
activation changes continuity documentation and no public behavior.
Contract `.2` selects proposed generic implementation `.3` with exact source/
support identities, literal range `2..4`, and minimum counter widths 2/2/3 for
counts two/three/four. t1535 will own assertion-enabled
`4 -> 3 -> 2 -> 1 -> 0` runtime and strict/schedule/artifact/semantic/read-only-
MCP/verifier/preservation gates. One generic source projects 327/368/51 split
26 `.ppif` / 25 `.ahb`; the alias remains separate. See the
[contract selection](../../IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_CONTRACT_SELECTION.md).
Clean contract commit `58efc8aff` activates only implementation `.3`;
activation changes continuity documentation and no public behavior.
Implementation `.3` now ships `ppif/ahb_requester_busy_insert_four.ppif`
through the existing requester pipeline. Literal normalization is `2..4`;
integer-loop minimum-width lowering preserves two-bit counters for exact two
and three and emits three bits for exact four. Assertion-enabled t1535 proves
continuous/32-ready-low/32-grant-low `4 -> 3 -> 2 -> 1 -> 0` runtime plus
strict/schedule/artifact/semantic/read-only-MCP/verifier and preservation
surfaces. Current accounting is 327 protocol / 368 supported+strict / 51 AHB
paths split 26 `.ppif` / 25 `.ahb`. The exact-four alias and broader
BUSY/HIAL-VIAL/VHDL/verification work remain separate. See the
[behavior record](../../IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_BEHAVIOR.md).
Clean generic behavior commit `95bfb7e4b` activates only no-behavior alias
contract selector `.4`. The exact-four `.ahb` alias, support identity, focused
parity test, and projected 328/369/52 boundary remain unshipped during
activation; generic behavior stays fixed at 327/368/51.
Contract `.4` now selects proposed data-only alias implementation `.5`. The
future `ppif/ahb_requester_busy_insert_four.ahb` must be byte-identical, reuse
width-three IAL1/IAL0 and numeric `beats=4`, remove only alias-deferred residue,
and support-account at projected 328/369/52 split 26/26. Focused t1536 owns
parity without simulation; t1535 remains shared runtime. See the
[alias contract](../../IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md).
Clean contract commit `3370e15cd` activates only data-only alias
implementation `.5`. The alias, support entry, t1536, and 328/369/52 boundary
remain unshipped during activation; generic behavior stays at 327/368/51.
Implementation `.5` now ships the byte-identical exact-four `.ahb` alias
through existing suffix/lowering machinery. Focused t1536 proves width-three
IAL1/IAL0, numeric report, alias-only residue cleanup, strict/schedule/artifact,
normalized semantic/read-only MCP, verifier, diagnostic, requester, and paired-
source parity without simulation; assertion-enabled t1535 remains shared
runtime. Current accounting is 328/369/52 split 26 `.ppif` / 26 `.ahb`. See
the [shipped alias behavior](../../IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md).
The exact-four child tree is complete. Pending parent selector `.823` may
activate only after the clean `.5` behavior commit.
Clean exact-four alias behavior commit `ba2d1c01f` activates parent selector
`.823` without changing behavior. The exact-four generic/profile pair remains
at 328/369/52 split 26/26; t1536 remains parity-only and t1535 remains the
shared assertion-enabled runtime while the selector reconciles the next owner.
Selector `.823` now chooses proposed one-window exact-four paired-BUSY
readiness audit `.1`. A same-volume candidate strict-checks and lowers to exact
3 IAL1/4 IAL0 artifacts with width-three literal-four requester state,
one-hot response ownership, BUSY parking, and public HDL verification. The
audit must still prove real read-only MCP and assertion-enabled
5/4/1/4/1/`44332211` runtime before any projected 329/370/53 public contract.
See the [selection record](../../IAL2_POST_EXACT_FOUR_REQUESTER_ALIAS_NEXT_OWNER_SELECTION.md).
Clean selector commit `d91c5c7c9` activates only readiness audit `.1`.
Activation adds no public paired source, support, test, or behavior; assertion-
enabled aggregate runtime and real read-only MCP remain pending.
Audit `.1` now passes strict/artifact/normalized-semantic/real read-only-MCP/
public-verifier surfaces plus assertion-enabled 5 presentations / 4 data beats
/ 1 BUSY episode / 4 qualified BUSY events / `4->3->2->1->0` / 1 resumed
`SEQ` / storage `0x44332211`. No repair is required. Pending `.2` owns a
separate generic contract projecting 329/370/53 split 27 `.ppif`/26 `.ahb`.
See the [readiness audit](../../IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md).
Clean audit commit `19772adec1` activates only contract selector `.2`.
Activation changes continuity documentation and no public or generated
behavior.
Contract `.2` now freezes one generic exact-four paired source through the
existing three-child architecture, exact support/semantic identities, and
assertion-enabled t1537 5/4/1/4/1/`44332211` runtime. Projected accounting is
329/370/53 split 27 `.ppif`/26 `.ahb`. Pending `.3` is the separate data-only
implementation; the source remains unshipped during selection. See the
[contract](../../IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md).
Clean contract commit `d54dc8afb` activates only `.3`; the selected source,
support path, and t1537 remain unshipped until implementation passes.
Implementation `.3` ships the generic exact-four paired source at 329/370/53
split 27 `.ppif`/26 `.ahb`, with exact 3 IAL1/4 IAL0 artifacts, semantic/read-
only-MCP parity, and assertion-enabled t1537 5/4/1/4/1/`44332211` runtime.
Parent selector `.824` then selected the byte-identical matching `.ahb` alias
as `.825`. Implementation `.825` now ships that alias at 330/371/54 split
27/27. Focused t1538 passes 4 top-level subtests and 88 nested assertions for
byte/report/artifact/strict/schedule/normalized-semantic/real read-only MCP/
repository-local-output/public-verifier/diagnostic/preservation parity without
another simulation; t1537 remains shared runtime. Pending `.826` owns the next
no-behavior selection after the clean `.825` commit.
Clean behavior commit `40b8ead71` now activates `.826` as continuity only;
selection has not changed public behavior.
Selector `.826` now chooses proposed two-subordinate exact-four paired-BUSY
readiness audit `.1`. A repository-local candidate passes strict checking,
exact 4 IAL1/5 IAL0 lowering, width-three exact-four requester state,
normalized semantic `ahb_tb`/`top`/4-child identity, real read-only shell-
disabled MCP, and public HDL verification while remaining intentionally
unmatched by support accounting. The exact 11-file/2,180,377-byte workspace
was removed. The audit must directly prove assertion-enabled two-command
10 presentations / 8 beats / 2 BUSY episodes / 8 qualified BUSY events / 2
resumed `SEQ` / status `44332211` / control `88776655` before any projected
331/372/55 generic contract. See the
[selection record](../../IAL2_POST_EXACT_FOUR_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md).
Clean selector commit `4abb0a357` activates only readiness audit `.1`.
Activation adds no public source, support, test, or behavior; assertion-enabled
two-command exact-four runtime remains pending.
Audit `.1` now proves strict/artifact/normalized-semantic/real read-only-MCP/
public-verifier surfaces plus assertion-enabled two-command 10 presentations /
8 beats / 2 BUSY episodes / 8 qualified BUSY events / 2 resumed `SEQ` / status
`44332211` / control `88776655`. No lower-layer repair is required. Pending
`.2` owns a separate generic contract projecting 331/372/55 split 28 `.ppif`/
27 `.ahb`. See the
[readiness audit](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md).
Clean audit commit `a5d162d60` activates only generic contract selector `.2`.
Activation adds no public source, support, test, artifact, or behavior; the
audit remains the runtime authority while `.2` freezes the future contract.
Contract `.2` now freezes one generic two-window exact-four source through the
existing four-child architecture, exact support/semantic identities, 4 IAL1/5
IAL0 artifacts, and all-assertion t1539 10/8/2/8/2/`44332211`/`88776655`
runtime. Projected accounting is 331/372/55 split 28 `.ppif`/27 `.ahb`.
Pending `.3` is the separate data-only implementation; no source ships in
selection. See the
[contract](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md).
Clean contract commit `4d0cc34bd` activates only data-only implementation
`.3`. The selected source/support/t1539/testbench remain absent during
activation, so public behavior stays at 330/371/54 split 27/27.
Implementation `.3` now ships that generic source and exact support through
existing generators. t1539 proves the six-field source delta, strict/report/
4-IAL1/5-IAL0 artifacts, normalized semantic/read-only-MCP/public-verifier
surfaces, explicit unmatched-neighbor diagnostics, repository-local output,
and assertion-enabled 10/8/2/8/2/`44332211`/`88776655` runtime. Current
accounting is 331/372/55 split 28 `.ppif`/27 `.ahb`; t1533/t1534/t1537/t1538
preserve both adjacent generic/profile families. See the
[behavior record](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md).
Clean behavior commit `a62ddb705` activates parent selector `.827` without a
public behavior change. Accounting remains 331/372/55 split 28 `.ppif`/27
`.ahb` while it selects one exact next roadmap owner.
Selector `.827` selects pending `.828`, the byte-identical matching two-window
exact-four `.ahb` alias through existing suffix/lowering machinery. A direct
same-volume strict/artifact/semantic/read-only-MCP/verifier probe passes with
alias-only residue removal. Implementation projects 332/373/56 split 28/28;
t1540 will own parity without another simulation while t1539 remains the
shared assertion-enabled runtime. See the
[next-owner selection](../../IAL2_POST_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md).
Clean selector commit `bc29c2e49` activates only implementation `.828`.
The alias/support/t1540 remain absent during activation, so public behavior
stays at 331/372/55 split 28 `.ppif`/27 `.ahb`.
Implementation `.828` now ships the byte-identical two-window exact-four
`.ahb` alias and exact support entry. Focused t1540 passes 4 top-level
subtests and 97 nested assertions across byte/lowering/report/residue/strict/
schedule/artifact/semantic/read-only-MCP/repository-local-output/verifier/
diagnostic parity without another simulation; t1539 remains the shared
all-assertion runtime. Current accounting is 332/373/56 split 28 `.ppif`/28
`.ahb`. Counts above four, broader BUSY semantics, generic priority,
HIAL/VIAL, verification generation, VHDL, portability, scale, other
protocols/backends, and decision `0020` remain separate.
Clean behavior commit `3519cde33` activates parent selector `.829` as
continuity only. Accounting remains 332/373/56 split 28 `.ppif`/28 `.ahb`;
the selector will choose exactly one smallest next owner without changing
public behavior.
Selector `.829` chooses the proposed
[`IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT`](../../tasks/IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.md).
The no-behavior audit will select a reusable finite literal count range above
four and prove representative counter-width transitions, qualified runtime,
stalls, diagnostics, and preservation before any public widening. The current
exact-five transform fails only at the intentional `2..4` gate, while minimum
width derivation is already generic; an open-ended exact-count fixture cadence
is not selected. See the
[selection record](../../IAL2_POST_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md).
Accounting and behavior remain 332/373/56 split 28/28. HIAL/VIAL, dynamic BUSY
policy, generic priority, VHDL/portability, scale, and decision `0020` stay
separate.
Clean selector commit `a2750d8a6` activates only audit `.1`. This is a
continuity change: literal `2..4`, accounting 332/373/56 split 28/28, generated
HDL/runtime, reports, and all broader owners remain unchanged while the audit
chooses a finite range and verification contract.
Audit `.1` now selects proposed no-behavior contract `.2` for canonical literal
`busy-beats` values `2..16`. A same-volume patched-copy probe passes 46
structural/report/read-only-MCP/diagnostic assertions and seven all-assertion
count-5/8/16 runs, including 32-clock ready/grant stalls at the first and
maximum new boundaries. Counts 5/8/16 use widths 3/4/5, complete four data
beats, resume one `SEQ`, and finish at zero. The AHB protocol supplies no
numeric BUSY cap; FSMGen selects 16 to match its bounded `max_beats=16` profile.
See the [readiness audit](../../IAL2_AHB_REQUESTER_GENERALIZED_BUSY_COUNT_RANGE_READINESS_AUDIT.md).
Current literal `2..4`, existing source bytes, and 332/373/56 split 28/28 stay
unchanged until a later contract and implementation.
Clean audit commit `18f63a971` activates only contract `.2`. This continuity
change leaves generated behavior and accounting unchanged while `.2` freezes
the exact admission, diagnostic, residue, test, runtime, preservation, and
rollback boundary before a separate implementation.
Completed contract `.2` selects proposed lowerer/test-only `.3`. It freezes
canonical decimal literals `2..16`, the exact diagnostic, unchanged minimum-
width and qualified-retirement logic, one numeric residue template, no public
fixture per count, t1541 plus generic 5/8/16 assertion runtime, and migration
of t1535's touched temporary workspaces to `.artifacts/tmp/tests`. Public
behavior remains `2..4` until `.3` ships; see the
[contract record](../../IAL2_AHB_REQUESTER_GENERALIZED_BUSY_COUNT_RANGE_CONTRACT_SELECTION.md).
Clean contract commit `7e2b436cf` activates only implementation `.3`.
Activation is continuity-only: public literal `2..4`, generated behavior,
existing source bytes, and 332/373/56 split 28/28 remain unchanged.
Implementation `.3` now ships canonical decimal literal counts `2..16`
through the existing lowerer, unified numeric residue, t1541 boundaries, and
seven all-assertion 5/8/16 runtimes. It adds no count-specific public fixture
or support identity, so accounting remains 332/373/56 split 28/28. The touched
eight exact-one-through-four requester generic/profile tests use explicit
repository-local workspaces and subprocess temp storage; the four exact-four
paired generic/profile tests configure repository-local subprocess temp roots.
See the
[shipped behavior](../../IAL2_AHB_REQUESTER_GENERALIZED_BUSY_COUNT_RANGE_BEHAVIOR.md).
Clean behavior commit `2f64611ca` activates no-behavior parent selector
`.830`; public `2..16` behavior and 332/373/56 split 28/28 remain unchanged
while it selects one next roadmap owner.
Completed selector `.830` chooses proposed no-behavior
`ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.1`. The evidence narrows the
gap: direct rule/transaction data assignments already honor declared priority,
while a transaction-invoked named drive is lowered with separate `drive`
provenance and can remain enabled beside a conflicting rule selector. The
audit will reproduce both cases protocol-neutrally and select exact masking or
a fail-closed prerequisite without weakening generated selector assertions.
See the
[selection record](../../IAL2_POST_GENERALIZED_BUSY_COUNT_NEXT_OWNER_SELECTION.md).
Canonical AHB `2..16`, accounting 332/373/56 split 28/28, HIAL/VIAL, VHDL,
scale, broader BUSY policy, and decision `0020` remain unchanged and separately
gated until a clean activation commit.
Clean selector commit `f67705356` activates only audit `.1`. This is a
continuity transition; direct assignment behavior, the unresolved named-drive
seam, all AHB behavior, and every broader roadmap owner remain unchanged.
Audit `.1` now selects proposed no-behavior contract `.2`. Focused t1542
proves the direct assignment control passes with the higher rule value, while
the named-drive form reports only an unproved warning and fails the generated
different-value selector assertion. Shared drive bodies collapse multiple
transaction callers into one request, so whole-drive masking is unsafe. A
disposable unique-caller candidate instead masks only the conflicting target
and passes with both `out=1` and unrelated `side=1`. The contract will freeze
that bidirectional target-local rule for exactly one local caller and fail
closed for ambiguous callers. See the
[readiness audit](../../ISF_RULE_TRANSACTION_NAMED_DRIVE_PRIORITY_READINESS_AUDIT.md).
No lowering or runtime behavior changes until a later implementation.
Clean audit commit `e715a34c7` activates only contract `.2`. This continuity
transition does not alter the direct path, named-drive conflict, generated
assertions, AHB behavior, or any broader roadmap owner.
Contract `.2` selects implementation `.3`: retain drive
provenance, carry one exact local transaction caller privately into priority
analysis, mask only the conflicting target in either priority direction, and
fail unique unordered or prioritized ambiguous ownership before HDL. Public
schedule/semantic schemas remain bounded and selector assertions remain.
SystemVerilog and native Verilog are executable qualification lanes. The
direct VHDL scaffold currently leaks the unary reduction token in
`drive_zero_en and (|drive_zero_start)`; this is not valid-VHDL evidence and is
separately owned by decision `0023` plus proposed
`DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING`. See the
[contract](../../ISF_RULE_TRANSACTION_NAMED_DRIVE_PRIORITY_CONTRACT_SELECTION.md).
Clean contract commit `b44afcc51` activates `.3` continuity-only. No product
behavior changes during selection or activation.
Implementation `.3` now ships the protocol-neutral named-drive repair. An
exactly-one-local-caller drive participates in actor-level rule/transaction
priority under that transaction's logical identity while retaining raw drive
provenance. Suppression is target-local in either direction, so the drive
request, transaction lifecycle, parameters, and unrelated drive outputs
survive. Unique unordered different-value overlap fails closed; same-value
fan-in remains compatible; prioritized shared, generated, or mixed ownership
fails as `isf_ambiguous_rule_transaction_drive_priority`; and unprioritized
ambiguous/unused overlap keeps the bounded `not_doable` warning. t1542 proves
both directions with assertion-enabled SystemVerilog, proves native Verilog,
and keeps direct VHDL explicitly unqualified under decision `0023`. The public
report/semantic key sets do not widen. See the
[shipped behavior](../../ISF_RULE_TRANSACTION_NAMED_DRIVE_PRIORITY_BEHAVIOR.md).
Clean behavior commit `1dbff8fc6` activates parent selector `.831`
continuity-only. All shipped behavior and broader owner boundaries remain
unchanged while `.831` compares and selects exactly one next roadmap owner.
Completed selector `.831` chooses the proposed no-behavior
[direct-VHDL reduction-expression audit](../../tasks/DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.md).
The exact defect is the foreign SystemVerilog token in
`drive_zero_en and (|drive_zero_start)`. Audit `.1` will reproduce scalar and
vector unary OR, AND, and XOR, distinguish scalar identity from vector
reduction semantics, and choose exact VHDL translation or deterministic
pre-emission rejection. No `ghdl`, `nvc`, or `vcom` is installed, so the audit
cannot claim executable VHDL qualification. See the
[selection record](../../IAL2_POST_NAMED_DRIVE_PRIORITY_NEXT_OWNER_SELECTION.md).
All shipped named-drive/AHB behavior and broader HIAL/VIAL, scale, simulator,
startup-alignment, protocol, and backend owners remain unchanged pending a
clean activation commit.
Clean selector commit `5f904d2d2` activates only the direct-VHDL audit `.1`.
The reduction-token leak and all parser, backend, HDL, runtime, AHB, and
broader-roadmap behavior remain unchanged during this continuity transition.
Completed audit `.1` now selects proposed implementation `.2`. The original
named-drive operand is a declared scalar, so positive unary OR/AND/XOR lowers
by identity and complemented reduction lowers to VHDL `not`; static bit
selects share that scalar rule. Vectors, range slices, unresolved or compound
operands, malformed shapes, and residual reduction tokens must fail closed
before emission. Public one-operand source operators remain rejected, and no
native vector-reduction or compiler-qualification claim is made. See the
[readiness audit](../../DIRECT_VHDL_REDUCTION_EXPRESSION_READINESS_AUDIT.md).
This audit changes no current output; `.2` requires a clean activation commit.
Clean audit commit `16f6140c4` activates only implementation `.2`. Product
output remains unchanged during this continuity transition; `.2` now owns the
selected adapter change and regression proof.
Implementation `.2` now ships the reconciled contract. Scalars and static bit
selects lower by identity/complement; declared vectors use required-only
backend-owned `std_logic` OR/AND/XOR fold helpers, with signed casts and
helper-name collision protection. Range, invalid-select, unresolved,
compound, malformed, and residual forms fail closed. The initial blanket
vector rejection was rejected by preservation evidence because existing AMBA
`HRESP` and APB `wait_ctr`/`addr_q` direct paths require vector truthiness.
t1542/t1543 plus real t1420/t386 prove token-free output while public
one-operand source syntax remains rejected. See the
[shipped behavior](../../DIRECT_VHDL_REDUCTION_EXPRESSION_BEHAVIOR.md).
No external VHDL compiler qualification is claimed. Clean behavior commit
`2879f22af` activates parent selector `.832` continuity-only; all shipped
behavior remains unchanged while it selects exactly one next roadmap owner.
Completed `.832` selects the proposed no-behavior
[nested-bitwise concurrent-assertion audit](../../tasks/ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.md).
The AXI fixed-four read behavioral guard correctly preserves
`high & (bit3 | bit2)` through an intermediate, but its generated concurrent
property inlines `high & bit3 | bit2`. SystemVerilog precedence changes the
meaning and rejects legal address `0x00000004`; current t1507 passes because
its Verilator runtime explicitly uses `--no-assert`. Audit `.1` will select a
general AST-preserving renderer contract and assertion-enabled coverage before
implementation `.2`. See the
[selection record](../../IAL2_POST_DIRECT_VHDL_REDUCTION_NEXT_OWNER_SELECTION.md).
HIAL/VIAL, big-design scale, maintenance, other protocol/backend, simulator,
and decision-`0020` owners remain independent.
Clean selector commit `1be57f7bd` activates only audit `.1` continuity-only.
The malformed concurrent property and every shipped behavior remain unchanged
while the audit selects a general repair contract.
Completed audit `.1` proves there is no mixed legacy/CoreAST expression graph:
the loss occurs when concurrent-check rendering substitutes an inlineable
CoreAST signal with standalone driving-expression text after its parent
precedence context has been erased. The selected general repair groups every
successfully substituted intermediate expression, preserving that AST boundary
for any operator pair without changing the canonical CoreAST renderer or AXI
source. Tracked t1544 characterizes the current defect; separate `.2` owns the
t1410-t1412/t1544 reconciliation and assertion-enabled legal-`0x00000004`
t1507 proof. See the
[readiness audit](../../ISF_ASSERT_NESTED_BITWISE_PRECEDENCE_READINESS_AUDIT.md).
No generated behavior changes during this audit slice.
Clean audit commit `628ca0c33` activates only implementation `.2`
continuity-only. The malformed property remains unchanged during activation;
`.2` now owns the selected grouping repair and assertion-enabled AXI proof.
Implementation `.2` now ships grouped inline-intermediate substitution.
Direct, overlapping-implication, and delayed property leaves preserve nested
mixed-precedence semantics. The AXI admission set stays unchanged: t1507's
negative/positive harness reaches exact `5/17/5/17/4` including legal address
`0x00000004`, while a separate all-assertion legal-only harness reaches exact
`1/4/1/4/1`. The split is required because the intentional illegal commands
correctly violate the boundary assertion. See the
[shipped behavior](../../ISF_ASSERT_NESTED_BITWISE_PRECEDENCE_BEHAVIOR.md).

Clean behavior commit `80aa203ab` activates parent selector `.833`
continuity-only. The repair and all shipped feature behavior remain unchanged
while that selector compares the remaining roadmap directions and chooses
exactly one next owner.

Completed `.833` selects proposed no-behavior
[mdBook VHDL introduction boundary sync](../../tasks/MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC.md).
Chapter 00's blanket VHDL non-implementation claim and Chapter 10's blanket
composition-rejection wording contradict this chapter's canonical partially
shipped direct/C1/C2/C3/APB-C4 boundary. The selected leaf will align only those
summaries while preserving full-backend, external-compiler, GHDL, broad-
composition, aggregate/package, and parity deferrals. See the
[selection record](../../IAL2_POST_ASSERTION_PRECEDENCE_NEXT_OWNER_SELECTION.md).
HIAL/VIAL, end-to-end scale, other startup maintenance, known defects,
protocol/backend expansion, simulator profiles, and decision `0020` remain
separate.
Clean selector commit `191a65151` activates only the selected book leaf
continuity-only. The stale summaries, this canonical boundary, and all product
behavior remain unchanged during activation.
Completed book leaf `.1` now aligns Chapters 00 and 10 with this canonical
boundary. The concise summaries state that bounded direct single-FSM and exact
C1 standalone-DT, C2 generated-FSM, C3 external-RTL, and APB/C4 generated-FSM
VHDL families are shipped while full parity, external compiler qualification,
broader composition, aggregate/package emission, and unsupported shapes remain
deferred or fail closed. No product behavior changes.
Clean documentation commit `0c9f402ca` activates parent selector `.834`
continuity-only. This aligned VHDL boundary and every shipped behavior remain
unchanged while the next roadmap owner is selected.
Completed `.834` selects proposed no-behavior
[frozen-legacy task-tree workflow sync](../../tasks/TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC.md).
At selection time, active workflow prose still required writes to or called
canonical the four decision-`0007`-frozen blobs. The selected leaf was scoped
to route guidance through task trees, decisions, bounded Memory, this book,
and git while preserving decision `0019`'s node-list/frontier rule. See the
[selection record](../../IAL2_POST_VHDL_BOOK_SYNC_NEXT_OWNER_SELECTION.md).
Import-tree refresh, HIAL/VIAL, scale, public-test drift, other protocols/
backends, simulator profiles, and decision `0020` remain separate.
Clean selector commit `dc055558c` activates only the selected workflow leaf
continuity-only. The stale guidance, all four frozen blobs, and every product
behavior remain unchanged during activation.
That child is now complete. The task-tree workflow uses the current layered
memory model, the reusable template preserves decision `0019`'s live node-list
rule, and all four frozen blobs remain untouched. No product behavior changes;
the next clean action returns to a new parent selector.
Clean workflow completion commit `771d2918c` activates parent selector `.835`
continuity-only. The workflow repair and every product behavior remain
unchanged while the next roadmap owner is selected.
Completed `.835` selects the proposed no-behavior
[`bin/fsmgen` import-tree refresh](../../tasks/BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH.md).
The live closure is `228` project files / `227` packages / `19` IAL2 owners,
while the maintained note still records `213` / `212` / `IAL2: 5`. The child
will refresh only the architecture note and fact after a separate clean
activation. HIAL/VIAL, scale, public-test drift, rustdoc fences, other
protocols/backends, simulator profiles, and decision `0020` remain separate.
See the [selection record](../../IAL2_POST_FROZEN_WORKFLOW_SYNC_NEXT_OWNER_SELECTION.md).
Clean selector commit `23a987e06` activates only the import-tree child
continuity-only. The stale note/fact, live import closure, and every product
behavior remain unchanged until the documentation repair commits.
The import refresh and intervening README, project-document lifecycle, and
portable TASK-ACCEPTANCE doctrine work are complete. Clean integration commit
`d5b371184` activates parent selector `.836` continuity-only. The selector will
choose one smallest PNT-eligible proposed owner without activating the
scheduled four-document lifecycle review or a director-gated item. Product
behavior remains unchanged during activation.
Completed `.836` selects proposed
[public-sync repair `.1`](../../tasks/PUBLIC-SYNC-TEST-DRIFT-REPAIR.md).
Current HEAD's public ISF contract payload contains three verification-
observation discovery families that its authoritative top-level presence list
omits, so t1131 fails. The selected child will synchronize only that list after
a separate clean activation. Public-sync `.2`/`.3`, the four-fence rustdoc
repair, the scheduled four-document lifecycle review, architecture horizons,
and director-gated items remain separate. See the
[selection record](../../IAL2_POST_TASK_ACCEPTANCE_NEXT_OWNER_SELECTION.md).
Clean selector commit `06c03e6bf` activates only public-sync `.1`
continuity-only. The authoritative public presence list, payload, tests, and
product behavior remain unchanged during activation; `.2` and `.3` stay
pending.
Public-sync `.1` is now complete: the authoritative presence list advertises
all three already-shipped verification-observation discovery families, its
payload/list difference is empty, and t1131 plus adjacent contract gates pass.
No payload, schema, parser/scheduler, generated artifact, or product behavior
changed. `.2` remains pending until the clean `.1` commit; `.3` stays behind
`.2`.
Clean `.1` implementation commit `012660f90` activates public-sync `.2`
continuity-only. The authoritative ISF spec currently indexes 327 of 332
focused tests: five links are missing and none is extra. The spec, tests, and
product behavior remain unchanged during activation; `.3` stays pending.
Public-sync `.2` is now complete: the authoritative ISF focused-test index
contains all 332 current paths exactly, focused t1250 passes, and the guarded
295-file / 2,037-test ISF regression is green. No test or product behavior
changed. `.3` remains pending until the clean `.2` commit.
Clean `.2` implementation commit `4ba108b3d` activates public-sync `.3`
continuity-only. Current t1474 has one stale diagnostic regex: it names the
one-subordinate aggregate but not the parser's already-shipped two-subordinate
aggregate wording. The canonical public `.ahb` source remains strict-check
clean; no test or product behavior changes during activation.
Public-sync `.3` is now complete: exactly one t1474 regex names both shipped
aggregate shapes, the six-file profile-alias gate passes 36 tests, and the
canonical public `.ahb` strict check stays clean. Adjacent verification found
four old generated-IAL0 ERROR-drive patterns in t1475/t1482 that predate
named-drive priority masks; pending `.4` owns them without changing behavior.
Clean `.3` implementation commit `ce891bbd7` activates public-sync `.4`
continuity-only for exactly those four patterns. The tests, lowerer/generator,
generated artifacts, and product behavior remain unchanged during activation.
Public-sync `.4` is now complete: t1475/t1482 require the exact shipped
inverse-winner masks, both focused files and the named-drive/AHB preservation
cluster pass, and both canonical public sources strict-check. No product
behavior changed; the public-sync `.1`-.4 tree is complete.
Clean public-sync completion commit `b2c114e2e` activates parent selector `.837`
continuity-only. It selects no candidate during activation; the known four-
fence mdBook rustdoc repair remains proposed pending current-HEAD comparison.
Completed `.837` selects proposed
[mdBook rustdoc fence repair `.1`](../../tasks/MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.md).
Current-HEAD full-book doctests fail only at the four already-owned untyped
plain-text diagrams in Chapters 13, 13b, 13f, and 13h. After a separate clean
activation, the child will add only explicit `text` annotations and prove
diagram-content preservation plus clean doctest/HTML builds. The scheduled
four-document lifecycle review and every director-gated direction stay
inactive. See the
[selection record](../../IAL2_POST_PUBLIC_SYNC_NEXT_OWNER_SELECTION.md).
Clean selector commit `9e3308e5c` activates only the four-fence repair `.1`
continuity-only. All four openings and diagram contents remain unchanged
during activation; the scheduled lifecycle review stays inactive.
The four-fence repair is complete: exactly those four openings now use
explicit `text`, every diagram byte is preserved, and all 36 chapters pass
full-book doctest plus HTML build. No product or lifecycle-policy behavior
changed.
Clean four-fence completion commit `59fcaa99e` activates parent selector `.838`
continuity-only. No candidate is selected during activation; the scheduled
four-document lifecycle review and every director-gated direction stay
inactive.
Completed `.838` selects proposed
[protocol-composition instance-identifier audit `.1`](../../tasks/PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.md).
Current HEAD's public APB multi-peripheral composition emits
`apb_interconnect interconnect (` and Verilator rejects the reserved instance
token, while AHB already carries a local `fabric` avoidance. The child will
inventory all producers/targets and select a shared contract after a separate
clean activation; the lifecycle review and every director gate stay inactive.
See the [selection record](../../IAL2_POST_RUSTDOC_NEXT_OWNER_SELECTION.md).
Clean selector commit `b0bcb12b5` activates only the identifier audit `.1`
continuity-only. All composition name producers, reports, generated HDL, tests,
and target behavior remain unchanged during activation.
The identifier audit is complete. Direct C4, APB/AHB/AXI, reusable-library,
spawn/generated activation, ATL, parent/domain/CDC, and both structural
emitters were inventoried. Decision `0027` selects one target-case-aware
portable keyword union, fail-closed authored labels, and deterministic
generated keyword/role/numeric suffixes. Public AHB `fabric` and fixed AXI
labels already pass target tools; public APB `interconnect` reproduces the
SystemVerilog failure and is the explicit implementation delta.
Clean audit commit `53a54c6c9` activates only identifier implementation `.2`.
The selected registry/allocator, source diagnostics, emitter defenses, APB/AHB
integration, report delta, and focused regressions are unchanged during that
continuity commit.
Identifier implementation `.2` is complete. Direct C4, spawn, reusable-library,
ATL, APB/AHB normalization, and both structural emitters share the portable
policy. APB now emits, wires, and reports `interconnect_instance`; AHB
`fabric` and fixed AXI labels remain byte-stable. Public APB generation passes
Verilator parse/lint and Yosys synthesis. Module/top/port/net/parameter names
remain outside this child-instance-label contract.
Preservation testing also found that t1502 still expects the AXI write-request
assertion text from before grouped inline-intermediate rendering commit
`80aa203ab`. Proposed inactive
[assertion repair `.3`](../../tasks/ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.md)
owns that exact test-truth synchronization after a separate clean activation;
the identifier slice does not weaken or change the assertion.
Clean identifier completion commit `299db4cae` activates only assertion repair
`.3`. This continuity step changes task/book/Memory/changelog pointers only;
the assertion builder/emitter, expected text, generated AXI HDL, and runtime
behavior remain unchanged until the test-truth repair commits separately.
Assertion repair `.3` is complete. Its one-line t1502 regex now expects the
grouped antecedent and consequent emitted since `80aa203ab`; t1502's built-in
Verilator, Yosys, and compiled structural-top behavior all pass. No builder,
emitter, assertion, generated HDL, or AXI runtime output changed in `.3`.
Clean grouped-assertion expectation completion commit `5fb1c0d47` activates
parent selector `.839` continuity-only. No candidate is selected during
activation; the scheduled lifecycle review and every director-gated direction
remain inactive.
Completed `.839` selects proposed no-behavior
`BIN-FSMGEN-IMPORT-TREE-JUL30-IDENTIFIER-REFRESH.1`. The live entrypoint closure
is now `229` project files / `228` packages / `19` IAL2 owners because the
portable identifier implementation added one reachable Support owner; the
canonical note/fact remain one package lower. The separate stale AHB
counts-beyond-four residue stays an independent next documentation candidate.
See the [selection record](../../IAL2_POST_IDENTIFIER_NEXT_OWNER_SELECTION.md).
Clean selector commit `28d3e777a` activates only the selected identifier-era
import-map child continuity-only. The stale note/fact, separate AHB residue,
and every product behavior remain unchanged during activation.
The identifier-era import-map child is complete. The canonical architecture
note/fact now match the live `229` / `228` / `19` closure, `Support 71`, and
portable identifier-policy reachability. Product behavior is unchanged; the
separate Chapter 16c AHB residue remains for the next clean parent selector.
Clean identifier-era import-map completion commit `ae2f75648` activates parent
selector `.840` continuity-only. No candidate is selected during activation;
the scheduled lifecycle review and every director-gated direction remain
inactive.
Completed `.840` selects proposed no-behavior
`MDBOOK-AHB-BUSY-COUNT-RESIDUE-SYNC.1`. Chapter 16c's current sections and the
requester lowerer agree that canonical literal `2..16` ships without a fixture
per count, but one later residue bullet still says counts beyond four are
unshipped. The child will synchronize only that contradiction after clean
activation. See the
[selection record](../../IAL2_POST_IMPORT_MAP_NEXT_OWNER_SELECTION.md).
Clean selector commit `6e1c73d8c` activates only the selected Chapter 16c
residue-sync leaf continuity-only. The stale bullet, support accounting, and
every product behavior remain unchanged during activation.
After clean activation commit `76a7424fa`, the child corrects only that stale
bullet. Chapter 16c now separates exact-one-through-four catalog fixtures from
generic canonical literal counts `5..16` without per-count fixtures and keeps
all above-16/runtime residue explicit; product behavior and accounting remain
unchanged.
Clean AHB book completion commit `3fb84b23e` activates parent selector `.841`
continuity-only. No candidate is selected during activation; the scheduled
lifecycle review and every director-gated direction remain inactive.
Completed `.841` selects proposed no-behavior
`FSMGEN-HIR-ROADMAP-FRONTIER.2`. The source-facing HIR boundary is the narrow
prerequisite for future high-level frontends and the host-language builder.
The selected leaf will apply `docs/IR_POLICY.md`, choose reuse/new/textual
handoff, one first frontend or builder, and one golden fixture before any
implementation. HIAL/VIAL, scale, MCP-write, and every director-gated direction
remain inactive. See the
[selection record](../../IAL2_POST_AHB_BOOK_SYNC_NEXT_OWNER_SELECTION.md).
Clean selector commit `b4e66c067` activates only HIR `.2` continuity-only.
The architecture boundary, first frontend/builder, golden fixture, current IR
owners, and every product behavior remain unchanged during activation.
The HIR tree is now complete through clean private-disposition commit
`24fbf3882`. Parent selector `.842` is active continuity-only to choose one
next roadmap-aligned owner; it does not implicitly activate the proposed public
builder or any director-gated direction.
Completed `.842` selects proposed no-product-behavior `.843`, a bounded repair
of the authoritative IAL2 task ledger before any architecture activation. An
exact census finds 842 numbered nodes but only 840 root child references:
`.633` and `.842` are missing. The sole live `blocked` node, `.705`, also has a
source-reference condition already resolved and consumed by `.706`-`.709`.
The selected leaf will reconcile that state and mechanically lock direct-child
node integrity. HIAL/VIAL remains the strongest later product-architecture
candidate; the public builder, scale, MCP-write, transaction layering, and
every director-gated direction remain inactive. See the
[selection record](../../IAL2_POST_SOURCE_HIR_NEXT_OWNER_SELECTION.md).
Clean selector commit `bd1ef6765` activates only `.843` through continuity
changes. The exact node/status drift, future integrity check, all product
surfaces, and every broader architecture candidate remain unchanged during
activation.
Completed `.843` repairs the live task ledger to 844 numbered nodes / 844
unique root child references, normalizes `.73` to `done`, marks the resolved
historical `.705` blocker live `done`, restores `.758`'s commit field, and
ships eighth doctrine `TASK-TREE-INTEGRITY`. The read-only check validates
active-tree root/node/ancestry/child/status/container/leaf shape and keeps
decision-`0019` historical views outside enforcement. Proposed `.844` owns the
next exact roadmap selector; no public product behavior or architecture owner
is activated. See the
[integrity record](../../TASK_TREE_LIVE_NODE_INTEGRITY.md).
Decision `0042` later extends that same read-only doctrine to optional bounded,
exact-source sealed subtree segments and exact version-object compact
terminals, without migrating ordinary one-file trees.
Clean integrity commit `c21765214` activates only `.844` through continuity
changes. Candidate reconciliation/selection, every product surface, and every
broader architecture owner remain unchanged until activation commits cleanly.
Completed `.844` selects proposed no-product-behavior
`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.1`. Its first audit will choose
the VIAL topology, typed HIAL/VIAL bridge, portable/native verification
semantics, SV/UVM and VHDL backend/profile boundaries, migration/parity/scale
contracts, and exact later leaves before implementation. Public builder,
whole-product scale, MCP-write, protocols/backends, lifecycle/transaction
horizons, and all director-gated work remain inactive; the selected audit
requires separate clean activation. See the
[selection record](../../IAL2_POST_TASK_TREE_INTEGRITY_NEXT_OWNER_SELECTION.md).
Clean selector commit `031b21d4f` activates only that HIAL/VIAL architecture
audit through a separate continuity transition. The audit findings, typed
bridge, verification semantics, backend profiles, migration, parity, scale
contract, exact implementation leaves, and all user-visible behavior remain
unchanged until the audit executes after activation commits cleanly.
