# IAL2 Post-APB Requester-Transfer Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.551`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.551` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.552`, an APB `.apb` profile-alias
readiness audit after the first APB `.ppif` requester-transfer behavior.

The selected next owner is an audit, not an implementation. It must decide
whether APB has enough evidence to select a public `.apb` profile-alias
contract, whether another APB `.ppif` behavior or public-surface prerequisite
should come first, or whether `.apb` should remain deferred.

No parser behavior, generator behavior, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, APB behavior, non-AXI behavior, common
construct promotion, profile-alias suffix syntax, generic-container alias
syntax, direct backend lowering, or VHDL behavior changed.

## Evidence Read

The APB sequence is now:

- `.548` found enough lower-layer APB evidence for an APB `.ppif`
  source-shape contract selection, but not behavior.
- `.549` selected the first APB `.ppif` source shape: required
  `(profile apb)`, one `(apb-requester apb_requester ...)` object, sample path
  `ppif/apb_requester_transfer.ppif`, support identity
  `intent.ppif_apb_requester_transfer`, review artifacts
  `apb_requester.isf` and `apb_requester.fsm`, and report schema
  `fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`.
- `.550` shipped that APB `.ppif` requester-transfer behavior through the
  mandatory `IAL2 -> IAL1 -> IAL0 -> HDL` lowering chain.

The current APB report confirms the public boundary:

- source layer `IAL2`;
- generated IAL1 format `isf`;
- generated IAL0 format `fsm`;
- `direct_ial2_to_ial0 = 0`;
- profile `apb`;
- object `apb-requester`;
- role `requester`;
- generated HDL module `apb_requester`;
- support-accounted source kind `ppif`; and
- `.apb` remains rejected as a known unsupported IAL2 alias candidate.

The verified APB residue remains:

```text
apb_multi_peripheral_decode_deferred
apb_protection_and_strobes_deferred
apb_completer_and_interconnect_generation_deferred
apb_alternate_widths_deferred
apb_back_to_back_policy_deferred
```

The profile-alias chronology is also relevant. `.540` already shipped `.axi`
as the first bounded IAL2 profile-alias suffix over the same
`protocol-platform-intent` model, with explicit AXI-family profile matching,
reviewable generated `.isf` and `.fsm` artifacts, authored alias source paths
in reports, support accounting under `source_kind` `ial2_profile_alias`, and
direct IAL2-to-IAL0 lowering still forbidden. `.chi`, `.ace`, `.ahb`,
`.apb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` remain unsupported.

The code and public surfaces match that boundary:

- `bin/fsmgen` resolves `.apb` as a known source suffix but rejects it through
  the unsupported-Ial2-alias diagnostic before PPIF parsing.
- `FSM::Adapter::IAL2::PPIF` accepts `.ppif` and `.axi` files; `.axi` has the
  only profile-alias validation path today.
- `LanguageSurfaceSection` advertises shipped suffixes `.fsm`, `.isf`,
  `.ppif`, and `.axi`; `.apb` remains in
  `unsupported_first_slice_aliases`.
- `RegressionCorpus` support-accounts APB requester-transfer as
  `source_kind => 'ppif'`, while the first `.axi` alias is
  `source_kind => 'ial2_profile_alias'`.
- `t/1436-ial2-ppif-parser-cli.t` locks APB `.ppif` parsing, report JSON,
  check JSON, semantic JSON, materialized review artifacts, and `.apb`
  rejection.
- The mdBook documents APB `.ppif` commands and explicitly says `.apb` remains
  unsupported.

## Selection Rationale

The next exact owner should be APB `.apb` profile-alias readiness, not direct
`.apb` implementation. `.550` created the missing APB generic `.ppif` evidence
that `.546` and `.548` lacked, but accepting a new suffix still requires a
separate file-surface contract. That contract must settle source-path identity,
profile matching, mismatch diagnostics, support-accounting identity or reuse,
manifest wording, check/semantic JSON behavior, and preservation of the
mandatory generated `.isf` review step.

APB behavior expansion is still valuable, especially completer/interconnect
generation, sidebands, alternate widths, multi-peripheral decode, and
back-to-back policy. Those are APB behavior owners, though. They do not need to
block an audit that asks whether the already shipped requester-transfer source
is enough to choose the `.apb` alias contract, or whether one more APB behavior
slice should precede aliasing.

APB lower-layer/report cleanup is not the best next owner. The current report
already exposes schema, source anchors, generated artifacts, static rules, and
explicit residue. No cleanup gap blocks an alias-readiness audit.

Returning immediately to AXI would leave the new APB `.ppif` evidence
unclassified against the profile-alias promise in decisions `0015` and `0016`.
Another unrelated non-AXI protocol source-shape audit would be premature while
APB is the only non-AXI protocol with a shipped protocol-specific `.ppif`
behavior.

## Selected `.552` Scope

`.552` should audit APB `.apb` profile-alias readiness before any suffix
behavior change.

The audit should read `.551`, `.550`, `.549`, `.548`, `.540`, `.539`, `.538`,
decisions `0015`, `0016`, `0017`, and `0018`, the APB `.ppif` sample and live
report/check/semantic behavior, `bin/fsmgen` suffix resolution and PPIF
dispatch, `FSM::Adapter::IAL2::PPIF` parse/profile validation,
`FSM::IAL2::ProtocolIntent::ApbRequesterTransfer`,
`LanguageSurfaceSection`, `RegressionCorpus`, focused PPIF/APB tests, README,
ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map.

The audit should decide the next exact owner from:

- APB `.apb` public profile-alias contract selection;
- one more APB `.ppif` behavior prerequisite before aliasing;
- APB profile-alias manifest/support-accounting/report prerequisite;
- APB lower-layer/report cleanup prerequisite; or
- explicit `.apb` deferral with evidence.

If the audit selects APB `.apb` contract selection, it should record the
expected public contract before implementation:

- `.apb` remains an IAL2 profile alias over the same
  `protocol-platform-intent` model, not a separate layer.
- `.apb` sources should preserve the explicit `(profile apb)` rule unless the
  contract owner deliberately selects another profile policy.
- Equivalent `.ppif` and `.apb` APB requester-transfer sources must lower
  through generated `apb_requester.isf` before `apb_requester.fsm`.
- Authored alias source paths must remain visible in check JSON, semantic JSON,
  reports, diagnostics, and support-accounting evidence.
- Direct `.apb -> .fsm`, direct `.apb -> HDL`, and direct IAL2-to-IAL0 lowering
  remain forbidden.
- Missing profile, suffix/profile mismatch, unsupported APB object, unsupported
  `.apb` breadth, known unsupported aliases, and unknown suffix diagnostics
  must stay distinct.

`.552` must not accept `.apb`, `.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`,
`.i2s`, `.pif`, `.ppi`, or any other new suffix; must not extend `.axi`; must
not add APB samples; must not change parser, generator, manifest,
support-accounting, schedule/check/semantic JSON, HDL, runtime, backend,
verification-output, external converter, AXI, APB behavior, direct backend
lowering, or VHDL behavior.

## Validation

Closeout for this selector is documentation-only plus direct APB behavior
reverification:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-apb-requester-transfer.apb
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

The `/tmp/fsmgen-apb-requester-transfer.apb` probe is expected to fail closed
with the known unsupported `.apb` alias diagnostic.

## Rollback

Rollback is documentation-only: remove this selector, its Knowledge Map fact,
task-tree advancement, README/ROADMAP_V2/mdBook sync, and Memory pointer. No
parser, generator, sample, support-accounting, generated HDL, runtime, or
backend artifact rollback is required.
