# IAL2 APB Profile-Alias Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.552`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.552` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.553`, APB `.apb` public profile-alias
contract selection.

The selected next owner is still not implementation. It must write the public
file-surface contract before any `.apb` parser, generator, sample, manifest,
support-accounting, check JSON, semantic JSON, HDL, or backend behavior
changes.

No parser behavior, generator behavior, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, APB behavior, non-AXI behavior, common
construct promotion, profile-alias suffix syntax, generic-container alias
syntax, direct backend lowering, or VHDL behavior changed.

## Evidence Read

The APB source-shape sequence is now coherent:

- `.548` found enough lower-layer APB evidence to select an APB `.ppif`
  source-shape contract.
- `.549` selected `(profile apb)` plus one
  `(apb-requester apb_requester ...)` object as the first APB `.ppif` source
  shape.
- `.550` shipped `ppif/apb_requester_transfer.ppif` through the mandatory
  `IAL2 -> IAL1 -> IAL0 -> HDL` lowering chain.
- `.551` selected this readiness audit before any `.apb` suffix behavior.

The live APB `.ppif` probes confirm the shipped behavior:

- `--emit-schedule-json ppif/apb_requester_transfer.ppif` reports schema
  `fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`, source layer
  `IAL2`, generated IAL1 format `isf`, generated IAL0 format `fsm`,
  `direct_ial2_to_ial0 = 0`, profile `apb`, object `apb-requester`, role
  `requester`, generated IAL1 `apb_requester.isf`, generated IAL0
  `apb_requester.fsm`, and HDL module `apb_requester`.
- `--strict --check --json ppif/apb_requester_transfer.ppif` succeeds and
  support-accounts `intent.ppif_apb_requester_transfer` with source kind
  `ppif`.
- `--strict --emit-semantic-json ppif/apb_requester_transfer.ppif` succeeds
  and reports the generated APB requester semantic root as generated `.fsm`
  content.
- The same source copied to a temporary `.apb` path fails closed with
  `source suffix '.apb' is a known IAL2 alias candidate but is not supported in
  this slice`.

The code and manifest surfaces keep the same boundary:

- `bin/fsmgen` knows `.apb` only as a known unsupported IAL2 alias suffix.
- `FSM::Adapter::IAL2::PPIF` accepts `.ppif` and the first `.axi` profile
  alias; there is no `.apb` profile-alias validation path.
- `FSM::IAL2::ProtocolIntent::ApbRequesterTransfer` reports APB as a `.ppif`
  profile and keeps `.apb` in enforced static-rule wording as unsupported.
- `LanguageSurfaceSection` advertises shipped suffixes `.fsm`, `.isf`,
  `.ppif`, and `.axi`; `.apb` remains in
  `unsupported_first_slice_aliases`.
- `RegressionCorpus` accounts APB requester-transfer as `source_kind =>
  'ppif'`; the existing `.axi` profile alias is the precedent for
  `source_kind => 'ial2_profile_alias'`.
- `t/1436-ial2-ppif-parser-cli.t` locks APB `.ppif` parsing, report JSON,
  strict check JSON, semantic JSON, materialized review artifacts, HDL
  generation, and `.apb` known-unsupported rejection.
- `t/297-capability-manifest.t` locks `.axi` as the only shipped
  profile-alias suffix and keeps `.apb` unsupported.

The public docs mostly matched that boundary. The audit found one stale mdBook
sentence in the historical first `.ppif` decision paragraph that still listed
`.axi` as unshipped. `.552` corrects that public wording so the book now says
`.axi` is shipped only for the bounded AXI AW Valid-Ready profile-alias sample,
while `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and
`.ppi` remain unsupported.

## Readiness Finding

APB is ready for public `.apb` contract selection, not direct `.apb`
implementation in this slice.

The positive evidence is the shipped APB `.ppif` requester-transfer path. It
already exercises an APB-specific profile, APB-specific object vocabulary,
source anchors, APB report schema, support-accounted CLI check/semantic
identity, generated `.isf` review artifacts, generated `.fsm` review
artifacts, and generated HDL. That is enough to write an alias contract without
inventing the APB behavior at the same time.

Direct implementation still needs a separate contract because `.apb` must
settle public file-surface semantics that `.ppif` does not answer by itself:

- whether `.apb` keeps explicit `(profile apb)` or infers the profile;
- how suffix/profile mismatch diagnostics differ from known unsupported alias
  and unknown suffix diagnostics;
- whether the first support identity reuses `intent.ppif_apb_requester_transfer`
  or gets an alias-specific identity such as
  `intent.apb_profile_alias_requester_transfer`;
- whether support accounting uses `source_kind => 'ial2_profile_alias'`, like
  `.axi`;
- how check JSON, semantic JSON, schedule JSON, and diagnostics preserve the
  authored `.apb` path while still lowering through generated `.isf` before
  generated `.fsm`;
- how the capability manifest describes `.apb` before and after behavior
  ships; and
- which APB object breadth stays fail-closed beyond the one requester-transfer
  object.

One more APB `.ppif` behavior slice is not required before contract selection.
Completer/interconnect generation, sidebands, alternate widths,
multi-peripheral decode, and back-to-back policy remain real APB behavior
residue, but none blocks selecting the bounded alias contract for the already
shipped requester-transfer source.

An APB lower-layer/report cleanup prerequisite is also not required. The
current APB report already exposes source layer, generated formats, source
object anchors, target protocol, static rules, generated artifacts, and
unsupported residue clearly enough for a contract-selection slice.

## Selected `.553` Scope

`.553` should select the APB `.apb` public profile-alias contract before any
behavior change.

The contract-selection owner should define:

- `.apb` as an IAL2 profile alias over the same `protocol-platform-intent`
  model, not a new layer and not an APB-to-FSM shortcut.
- The first alias source shape for APB requester-transfer, expected to mirror
  `ppif/apb_requester_transfer.ppif` at a future `.apb` sample path.
- The explicit profile policy, with `(profile apb)` preserved unless the
  contract deliberately selects and justifies a different policy.
- Equivalent `.ppif` and `.apb` requester-transfer lowering through generated
  `apb_requester.isf` before generated `apb_requester.fsm`.
- Authored `.apb` source-path identity in schedule/check/semantic JSON,
  diagnostics, reports, and support-accounting evidence.
- Support-accounting identity and `source_kind`, with `.axi` as the precedent
  for `ial2_profile_alias`.
- Capability-manifest wording for shipped suffixes and unsupported first-slice
  aliases after the future implementation.
- Distinct diagnostics for missing profile, suffix/profile mismatch,
  unsupported APB object breadth, known unsupported aliases, unknown suffixes,
  and malformed APB requester-transfer syntax.

`.553` must not accept `.apb`, `.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`,
`.i2s`, `.pif`, `.ppi`, or any other new suffix; must not extend `.axi`; must
not add APB samples; must not change parser, generator, manifest,
support-accounting, schedule/check/semantic JSON, HDL, runtime, backend,
verification-output, external converter, AXI, APB behavior, direct backend
lowering, or VHDL behavior.

## Validation

This audit closeout uses documentation and direct behavior probes:

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

The `.apb` probe is expected to fail closed with the known unsupported alias
diagnostic.

## Rollback

Rollback is documentation-only: remove this audit note, its Knowledge Map fact,
the `.553` task-tree owner, README/ROADMAP_V2/mdBook sync, and Memory pointer.
No parser, generator, sample, support-accounting catalog, generated HDL,
runtime behavior, or backend artifact rollback is required.
