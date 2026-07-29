# IAL2 AHB Requester Exact-Three BUSY Event `.ahb` Profile Alias Contract Selection

Task-tree owner:
`IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.4`

Date: 2026-07-29

## Outcome

This slice selects direct implementation of the matching exact-three requester
AHB profile alias:

```text
ppif/ahb_requester_busy_insert_three.ahb
```

The future alias must be a byte-identical mirror of the shipped generic source:

```text
ppif/ahb_requester_busy_insert_three.ppif
```

It is a second public source surface over the existing IAL2 AHB requester
generator, not another generator, language, or direct lowering path. Both
suffixes continue through the same generated IAL1 and IAL0 before HDL.
Implementation is owned by
`IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.5`.

This selector changes no source fixture, parser, generator, support catalog,
capability manifest, generated artifact, report, semantic payload, MCP API,
HDL, runtime behavior, direct backend, AXI/APB behavior, or VHDL behavior.

## Evidence And Feasibility

The selection reconciled:

- the shipped generic exact-three source, behavior record, support entry,
  assertion-enabled t/1528 proof, and current mdBook surface;
- the byte-identical exact-one and exact-two requester `.ppif`/`.ahb` pairs,
  focused t/1512 and t/1522 alias proofs, and shared-runtime precedent;
- `PPIF.pm` profile/suffix validation and requester alias-residue cleanup;
- `RegressionCorpus`, `LanguageSurfaceSection`, t/248, and t/297; and
- the bounded semantic-introspection contract and read-only MCP adapter.

An in-memory reserved-label probe parsed the exact same source text once as
`.ppif` and once as the future `.ahb` path. The `.ahb` result was:

```text
kind=protocol_intent.ahb_requester
mode=requester
source object=fsmgen-ahb-requester-busy-insert-three
intent=ahb_requester_busy_insert_three
IAL1=amba_requester_busy_insert_three.isf
IAL1 text identical=yes
IAL0 files identical=yes
busy_insertion.beats=3
ahb_profile_alias_deferred=removed
ahb_requester_busy_insert_support=identical
```

The adapter already requires explicit `(profile ahb)` for `.ahb`, accepts the
single requester object, invokes the same `AhbRequester` generator, and removes
only `ahb_profile_alias_deferred` for that source suffix. A second exact-three
in-memory probe reproduced the targeted rejection of non-AHB profiles and
non-requester objects on reserved `.ahb` labels, matching shipped t/1522
precedent. No parser or generator delta is needed. The future fixture and
support entry are presently absent, so current public accounting correctly has
no exact-three alias match yet.

## Selected Public And Support Identity

`.5` must add exactly this source/accounting identity:

```text
alias path:       ppif/ahb_requester_busy_insert_three.ahb
support id:       intent.ahb_profile_alias_requester_busy_insert_three
coverage:         ial2_ahb_profile_alias_requester_busy_insert_three_pipeline_cli
source kind:      ial2_profile_alias
intent:           ahb_requester_busy_insert_three
source object:    fsmgen-ahb-requester-busy-insert-three
actor/module:     amba_requester_busy_insert_three
IAL1:             amba_requester_busy_insert_three.isf
IAL0:             amba_requester_busy_insert_three.fsm
semantic root:    fsm
```

The alias source must be byte-identical to its generic sibling. Generated IAL1,
IAL0, HDL module, port/state behavior, numeric report value, and exact-three
qualified-event semantics therefore remain identical. Existing generic source
identity stays `intent.ppif_ahb_requester_busy_insert_three` with source kind
`ppif`.

One additive supported-smoke/strict-supported alias moves current accounting
from 321 to 322 protocol fixtures and from 362 to 363 supported-smoke/strict
fixtures. The public AHB IAL2 inventory moves from 45 paths—23 `.ppif` and 22
`.ahb`—to 46 paths, evenly split between the two suffixes.

## Report, Semantic, And MCP Contract

Both suffixes preserve:

```text
schema=fsmgen.ial2.protocol_intent.ahb_requester.v1
busy_insertion.generated_behavior=true
busy_insertion.htrans_busy_encoding=2'b01
busy_insertion.before_beat=2
busy_insertion.beats=3
```

The generic `.ppif` report keeps `ahb_profile_alias_deferred`; existing
suffix-keyed handling removes only that residue from the `.ahb` report. Both
reports retain byte-identical `ahb_requester_busy_insert_support` detail: exact
three-event behavior ships, while counts above three and broader count-policy/
insertion-point behavior remain deferred.

The bounded semantic API is part of the alias contract. Strict check,
`--emit-semantic-json`, and the read-only MCP `fsmgen_semantic_introspect` tool
must expose the alias path, selected support ID and coverage key, source kind
`ial2_profile_alias`, generated module `amba_requester_busy_insert_three`, and
semantic source root `fsm`. The existing stable semantic-introspection contract
must supply that information; `.5` must not add an alias-specific MCP route or
expose private parser/generator internals.

## Selected Regression Contract

Focused `t/1529-ial2-ahb-requester-three-busy-insert-profile-alias.t` owns:

- tracked source existence and byte identity with the generic `.ppif`;
- direct parse and generated IAL1/IAL0 equality;
- report equality except for alias-only residue removal;
- strict check, schedule JSON, semantic JSON, output-review artifacts, HDL
  module identity, and `--verify-hdl`;
- support identity, coverage key, source kind, semantic root, and a read-only
  `fsmgen_semantic_introspect` call over the alias path;
- rejection of wrong-profile/wrong-object reserved-label probes; and
- preservation of generic exact-three, exact-two `.ppif`/`.ahb`, exact-one
  `.ppif`/`.ahb`, paired exact-two families, and base requester identities.

t/1529 must not compile or run a second generated-HDL simulation. The
assertion-enabled t/1528 continuous, 32-clock ready-low, and 32-clock grant-low
scenarios remain the sole shared runtime proof for the byte-identical source
pair: one BUSY episode, exactly three qualified BUSY events, direct private
counter `3 -> 2 -> 1 -> 0`, stall-time stability, the same resumed `SEQ`, and
four accepted byte `INCR4` data beats.

Closeout also requires t/248 and t/297 accounting/capability updates, the
current-surface t/1518 lock, relevant exact-one/two/paired preservation,
mdBook/README/roadmap/behavior/fact/task/Memory synchronization, Knowledge Map
generation and check, relative-document paths, diff and doctrine gates, and the
unchanged 4-GiB descendant RSS cap for heavyweight commands.

## Explicit Non-Selections

`.5` must not change `PPIF.pm`, `AhbRequester.pm`, public exact-three syntax,
numeric report value, counter/rule implementation, ports, artifacts, or runtime
behavior. It must not add a second runtime harness, exact-three paired sources,
counts above three, generalized count width, multiple insertion points,
runtime/policy/random throttling, distinct local bus-BUSY status, broader
bursts/signals/managers, queues/outstanding transfers, direct seeds/backends,
verification-output generation, backend variants, selector repairs, AXI/APB,
VHDL, or decision 0020.

## Validation

The selector itself is documentation-only plus current-state probes:

```bash
scripts/run_with_ram_guard.sh -- perl -Iperl -MFSM::Adapter::IAL2::PPIF -e '...parse_source(..., "ppif/ahb_requester_busy_insert_three.ahb")...'
scripts/run_with_ram_guard.sh -- prove -Iperl t/1518-ial2-ahb-mdbook-current-surface-truthfulness.t
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback of `.4` is documentation-only: remove this record and its fact card,
restore `.4` to active selection, remove pending `.5`, and revert current
README/roadmap/mdBook/task/Memory pointers. No runtime or public source behavior
is affected.

## Implementation Outcome

`.5` now ships the selected byte-identical alias at
`ppif/ahb_requester_busy_insert_three.ahb`, support-accounted as
`intent.ahb_profile_alias_requester_busy_insert_three`. Focused t/1529 proves
byte/parse/report/check/schedule/semantic/artifact/HDL-verifier/diagnostic
parity and a real read-only shell-disabled `fsmgen_semantic_introspect` call;
t/1528 remains the sole shared assertion-enabled runtime proof. Canonical
current behavior is
`docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md`.
