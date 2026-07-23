# IAL2 AHB Requester BUSY-Insertion `.ahb` Profile Alias Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.789`

Date: 2026-07-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.789` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.790`, direct implementation of the matching
bounded AHB requester BUSY-insertion `.ahb` profile alias:

```text
ppif/ahb_requester_busy_insert.ahb
```

The alias must be a byte-identical mirror of the shipped generic source:

```text
ppif/ahb_requester_busy_insert.ppif
```

This selector changes no parser, generator, source fixture, support catalog,
capability manifest, generated artifact, HDL/runtime behavior, direct backend,
verification output, backend-language variant, AXI/APB behavior, broader AHB
behavior, or VHDL behavior.

## Evidence Read

The selector read:

- the `.785`-`.788` requester BUSY-insertion selector, readiness audit,
  contract, shipped behavior record, source, generator, focused t/1498 proof,
  support accounting, language/capability surfaces, README, ROADMAP_V2, mdBook,
  task tree, Memory, and Knowledge Map;
- the existing base requester `.ppif`/`.ahb` byte-identical pair and t/1474
  profile-alias proof;
- the endpoint and aggregate BUSY-park `.ahb` contract/behavior precedents,
  which already establish the cadence `generic .ppif -> matching .ahb`;
- `PPIF.pm`'s existing `.ahb` profile validation and suffix-keyed removal of
  `ahb_profile_alias_deferred` for every requester contract;
- `RegressionCorpus`, t/248, t/297, and `LanguageSurfaceSection`; and
- decisions `0014`, `0015`, `0016`, and `0018`, plus workflow decisions
  `0003`, `0005`, `0006`, and `0007`.

Decision `0020` and its protocol-neutral transaction-layer horizon remain
proposed/inactive. This selection continues only the already-active AHB
feature-completeness lineage.

## Current Probe Evidence

The shipped generic source is support-accounted and verified:

```text
path=ppif/ahb_requester_busy_insert.ppif
entry_id=intent.ppif_ahb_requester_busy_insert
source_kind=ppif
coverage=ial2_ppif_ahb_requester_busy_insert_pipeline_cli
module=amba_requester_busy_insert
IAL1=amba_requester_busy_insert.isf
IAL0=amba_requester_busy_insert.fsm
busy_insertion.before_beat=2
busy_insertion.htrans_busy_encoding=2'b01
```

A reserved `.ahb` source-label parser probe over the same source text already
succeeds without a tracked alias fixture. It preserves the generated IAL1/IAL0
artifacts and `busy_insertion` report, removes only the source-surface
`ahb_profile_alias_deferred` residue, and retains
`ahb_requester_busy_insert_support`:

```text
label=ppif/ahb_requester_busy_insert.ahb
kind=protocol_intent.ahb_requester
module=amba_requester_busy_insert
busy_insertion.before_beat=2
busy_insertion.htrans_busy_encoding=2'b01
ahb_profile_alias_deferred=removed
ahb_requester_busy_insert_support=present
```

The missing support-accounting match is purely because the alias fixture and
catalog entry do not exist yet. The adapter already recognizes `.ahb`, requires
`(profile ahb)`, accepts exactly one requester object, and applies requester
alias-residue cleanup generically. `.790` is therefore data-only: source mirror,
catalog/language/capability/test entries, and documentation.

## Why This Comes Next

The matching alias is the smallest safe follow-on after the generic requester
BUSY-insertion source shipped. It adds no new transaction state, BUSY policy,
bus wiring, receiving-side behavior, composition, or lowering rule. It exposes
the already-verified source through the established AHB vocabulary alias while
preserving the mandatory lowering chain:

```text
.ahb / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

Paired requester/subordinate composition and broader BUSY control both require
new behavioral contracts. Alias exposure does not, so it comes first.

## Selected `.790` Scope

`.790` owns direct implementation of exactly the matching requester
BUSY-insertion `.ahb` profile alias:

```text
alias path:       ppif/ahb_requester_busy_insert.ahb
support identity: intent.ahb_profile_alias_requester_busy_insert
coverage key:     ial2_ahb_profile_alias_requester_busy_insert_pipeline_cli
source kind:      ial2_profile_alias
expected module:  amba_requester_busy_insert
semantic root:    fsm
```

- add `ppif/ahb_requester_busy_insert.ahb` as a byte-identical mirror of
  `ppif/ahb_requester_busy_insert.ppif`;
- support-account it in `RegressionCorpus` with `family: protocol_fixture`,
  `classification: supported_smoke`, `strict_supported: true`, the identity
  above, and `expected_semantic_source_root_kind: fsm`;
- preserve generated `amba_requester_busy_insert.isf`,
  `amba_requester_busy_insert.fsm`, and HDL module
  `amba_requester_busy_insert` exactly;
- preserve `(busy 2'b01)`, `(busy-before-beat 2)`,
  `busy_insertion.generated_behavior = true`, one held BUSY presentation, the
  resumed `SEQ`, and `ahb_requester_busy_insert_support`;
- rely on existing suffix-keyed suppression to remove only
  `ahb_profile_alias_deferred` from the `.ahb` report while the generic `.ppif`
  report keeps it; do not change `PPIF.pm` or `AhbRequester.pm`;
- add focused
  `t/1512-ial2-ahb-requester-busy-insert-profile-alias.t`, proving source
  parity, parse/check/schedule/semantic/outdir/HDL behavior, artifact/module
  identity, BUSY report/residue preservation, alias-only residue removal,
  support identity, and unchanged generic source/t1498 behavior;
- move t/248 from 309 to 310 protocol fixtures and from 350 to 351
  supported-smoke/strict entries, and extend the t/297 `.ahb` capability
  boundary;
- update `LanguageSurfaceSection`, README, ROADMAP_V2, the canonical behavior
  record, mdBook backlog/AHB chapter, Knowledge Map, task tree, and Memory; and
- run focused syntax/check/schedule/semantic/outdir/test/`--verify-hdl` plus
  documentation/doctrine closeout.

The implementation must preserve every shipped requester, subordinate,
interconnect, byte-lane, `SEQ`, `HBURST`, BUSY-park, aggregate, `.ppif`, and
`.ahb` behavior except for the additive alias fixture/catalog/language/docs
entries and selected alias-only residue removal.

## Explicit Non-Selections

`.790` must not add paired requester/subordinate composition, multi-beat or
policy-driven BUSY throttling, runtime-selected insertion points, a distinct
`local-status.bus_busy`, halfword/word burst `SEQ`, wider/indefinite bursts,
multi-word/register-bank progression, optional/property-gated AHB signals,
legacy subordinate two-bit `HRESP`, broader interconnect/decode, scoreboards,
full-manager behavior, direct backend, verification output, backend-language
variants, AXI/APB behavior, broader AHB behavior, or VHDL behavior.

## Validation

Closeout for `.789` is documentation-only plus current-state probes:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester_busy_insert.ppif
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e '...parse_source(..., "ppif/ahb_requester_busy_insert.ahb")...'
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Broad or potentially heavyweight Perl, `prove`, or `fsmgen` commands remain
behind the RAM guard or an equivalent active monitor.

## Rollback

Rollback is documentation-only: remove this selector and its Knowledge Map
fact card, restore the `.789` frontier, and revert README/ROADMAP_V2/mdBook,
task-tree, Memory, and generated Knowledge Map entries. No runtime behavior is
affected.
