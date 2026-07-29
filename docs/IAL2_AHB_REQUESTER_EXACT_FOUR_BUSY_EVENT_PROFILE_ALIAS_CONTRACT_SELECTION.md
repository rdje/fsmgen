# IAL2 AHB Requester Exact-Four BUSY Event `.ahb` Profile Alias Contract Selection

Task-tree owner:
`IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.4`

Date: 2026-07-29

## Outcome

This slice selects direct implementation of the matching exact-four requester
AHB profile alias:

```text
ppif/ahb_requester_busy_insert_four.ahb
```

The future alias must be a byte-identical mirror of the shipped generic source:

```text
ppif/ahb_requester_busy_insert_four.ppif
```

It is a second public source surface over the existing AHB requester generator,
not another generator, language, or lowering path. Both suffixes continue
through the same generated IAL1 and IAL0 before HDL. Proposed implementation
is owned by
`IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.5`.

This selector changes no fixture, parser, generator, support catalog,
capability manifest, report, semantic payload, MCP API, artifact, HDL, runtime,
backend, protocol, verification-generation, HIAL/VIAL, or VHDL behavior.

## Evidence And Feasibility

The selection reconciled the shipped generic exact-four source/behavior/t1535,
the exact-one/two/three requester alias pairs and t1512/t1522/t1529 precedent,
`PPIF.pm` suffix validation and alias-residue cleanup, support/language/
capability accounting, normalized semantics, read-only MCP, roadmap, mdBook,
Knowledge Map, HIAL/VIAL parking, and decision 0020.

A warning-free in-memory reserved-label probe parsed the exact source text once
as `.ppif` and once as the future `.ahb` path. The `.ahb` result was:

```text
kind=protocol_intent.ahb_requester
mode=requester
IAL1 text identical=yes
IAL0 files/text identical=yes
busy_insertion.beats=4
ahb_busy_remaining_q width=3
ahb_profile_alias_deferred=removed
ahb_requester_busy_insert_support=identical
```

Separate probes reproduced targeted rejection of a non-AHB profile and a
non-requester object on the reserved `.ahb` label. Existing suffix handling
already requires `(profile ahb)`, accepts the requester object, invokes the same
`AhbRequester` generator, and removes only `ahb_profile_alias_deferred`. No
parser or generator delta is needed. The future fixture and support entry are
absent, so current public accounting correctly remains 327/368/51.

## Selected Public And Support Identity

`.5` must add exactly:

```text
alias path:       ppif/ahb_requester_busy_insert_four.ahb
support id:       intent.ahb_profile_alias_requester_busy_insert_four
coverage:         ial2_ahb_profile_alias_requester_busy_insert_four_pipeline_cli
source kind:      ial2_profile_alias
intent:           ahb_requester_busy_insert_four
source object:    fsmgen-ahb-requester-busy-insert-four
actor/module:     amba_requester_busy_insert_four
IAL1:             amba_requester_busy_insert_four.isf
IAL0:             amba_requester_busy_insert_four.fsm
semantic root:    fsm
```

The generic source keeps support ID
`intent.ppif_ahb_requester_busy_insert_four` and source kind `ppif`. One
additive supported-smoke/strict-supported alias projects accounting from 327
to 328 protocol fixtures, from 368 to 369 supported-smoke/strict fixtures, and
from 51 to 52 AHB paths, evenly split 26 `.ppif` / 26 `.ahb`.

## Report, Semantic, And MCP Contract

Both suffixes preserve:

```text
schema=fsmgen.ial2.protocol_intent.ahb_requester.v1
busy_insertion.generated_behavior=true
busy_insertion.htrans_busy_encoding=2'b01
busy_insertion.before_beat=2
busy_insertion.beats=4
counter width=3
```

The generic report keeps `ahb_profile_alias_deferred`; the alias removes only
that residue. Both retain identical exact-four
`ahb_requester_busy_insert_support` detail and defer only counts above four and
broader policy/runtime/random/multiple-point insertion.

Strict check, normalized semantic JSON, and read-only
`fsmgen_semantic_introspect` must expose the alias path, selected support ID and
coverage, source kind `ial2_profile_alias`, module
`amba_requester_busy_insert_four`, and semantic root `fsm`. `.5` must add no
alias-specific MCP route or private lowering payload.

## Selected Regression Contract

Focused `t/1536-ial2-ahb-requester-four-busy-insert-profile-alias.t` owns:

- tracked alias existence and byte identity with the generic source;
- direct parse and generated IAL1/IAL0 equality, including width three;
- report equality except alias-only residue removal;
- strict check, schedule JSON, normalized semantic JSON, review artifacts,
  repository-local output, HDL module identity, and `--verify-hdl`;
- support identity, coverage, source kind, semantic root, and a real read-only
  shell-disabled MCP call over the alias path;
- targeted wrong-profile/wrong-object reserved-label diagnostics; and
- preservation of generic exact-four, exact-one/two/three generic/alias,
  paired sources, and base requester identities.

t1536 must not compile or run a second simulation. Assertion-enabled t1535
remains the sole shared runtime proof for the byte-identical pair: continuous,
32-clock ready-low, and 32-clock grant-low exact `4 -> 3 -> 2 -> 1 -> 0`, four
qualified BUSY events, stable pending ownership, one resumed `SEQ`, four data
beats, and zero final counter.

Closeout also requires t248/t297 accounting and capability updates, t1518
current-surface locking, representative existing alias preservation, mdBook/
README/roadmap/behavior/fact/task/Memory synchronization, Knowledge Map and
relative-path gates, exact same-volume cleanup, the authorized host-100/
process-4096 profile, canonical Stats-compatible RAM plus separate kernel
pressure, diff, doctrines, and rollback evidence.

## Explicit Non-Selections And Rollback

`.5` must not change `PPIF.pm`, `AhbRequester.pm`, public exact-four syntax,
minimum-width lowering, numeric report values, counter/rules, ports, artifacts,
or runtime behavior. It must not add a second runtime harness, exact-four
paired compositions, counts above four, runtime/policy/random counts, multiple
insertion points, local bus-BUSY status, broader bursts/signals/topologies,
other protocols/backends, HIAL/VIAL activation, VHDL, verification generation,
or decision 0020 behavior.

Rollback of `.4` is documentation-only: remove this record/fact, restore `.4`
to active selection, remove proposed `.5`, and restore roadmap/mdBook/task/
Memory pointers. No public or runtime behavior is affected.

## Implementation Outcome

Leaf `.5` now ships the selected byte-identical alias with the exact support,
semantic, report-residue, artifact, verifier, and preservation contract above.
Focused t1536 proves parity without a second simulation; t1535 remains shared
runtime. Current accounting is 328/369/52 split 26 `.ppif` / 26 `.ahb`. See
`docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md`.
