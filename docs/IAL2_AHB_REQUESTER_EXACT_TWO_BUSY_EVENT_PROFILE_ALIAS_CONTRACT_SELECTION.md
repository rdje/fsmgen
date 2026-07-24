# IAL2 AHB Requester Exact-Two BUSY Event `.ahb` Profile Alias Contract Selection

Task-tree owner:
`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.6`

Date: 2026-07-24

## Outcome

This slice selects direct implementation of the matching exact-two requester
AHB profile alias:

```text
ppif/ahb_requester_busy_insert_two.ahb
```

The future alias must be a byte-identical mirror of the shipped generic source:

```text
ppif/ahb_requester_busy_insert_two.ppif
```

It is a second public source surface over the existing IAL2 AHB requester
generator, not another generator, another language, or a direct lowering path.
Both suffixes must continue through the same generated IAL1 and IAL0 before
HDL. Implementation is owned by
`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.7`.

This selector changes no source fixture, parser, generator, support catalog,
capability manifest, generated artifact, report, semantic payload, MCP API,
HDL, runtime behavior, direct backend, AXI/APB behavior, or VHDL behavior.

## Evidence And Feasibility

The selection reconciled:

- the shipped generic exact-two source, behavior record, support entry,
  assertion-enabled t/1521 proof, and current mdBook surface;
- the byte-identical exact-one requester `.ppif`/`.ahb` pair and focused t/1512
  alias proof;
- `PPIF.pm` profile/suffix validation and requester alias-residue cleanup;
- `RegressionCorpus`, `LanguageSurfaceSection`, t/248, and t/297; and
- the bounded semantic-introspection contract and read-only MCP adapter.

An in-memory reserved-label probe parsed the exact same source text once as
`.ppif` and once as the future `.ahb` path. The `.ahb` result:

```text
kind=protocol_intent.ahb_requester
IAL1=amba_requester_busy_insert_two.isf
IAL1 text identical=yes
IAL0 files identical=yes
busy_insertion.beats=2
ahb_profile_alias_deferred=removed
ahb_requester_busy_insert_support=identical
```

The adapter already requires explicit `(profile ahb)` for `.ahb`, accepts the
single requester object, invokes the same `AhbRequester` generator, and removes
only `ahb_profile_alias_deferred` for that source suffix. No parser or
generator delta is needed. The future fixture is presently absent, so the
current support-accounting lookup correctly has no alias match yet.

## Selected Public And Support Identity

`.7` must add exactly this source/accounting identity:

```text
alias path:       ppif/ahb_requester_busy_insert_two.ahb
support id:       intent.ahb_profile_alias_requester_busy_insert_two
coverage:         ial2_ahb_profile_alias_requester_busy_insert_two_pipeline_cli
source kind:      ial2_profile_alias
intent:           ahb_requester_busy_insert_two
source object:    fsmgen-ahb-requester-busy-insert-two
actor/module:     amba_requester_busy_insert_two
IAL1:             amba_requester_busy_insert_two.isf
IAL0:             amba_requester_busy_insert_two.fsm
semantic root:    fsm
```

The alias source must be byte-identical to its generic sibling. The generated
IAL1, IAL0, HDL module, port/state behavior, numeric report value, and exact-two
qualified-event semantics must therefore remain identical. Existing generic
source identity stays `intent.ppif_ahb_requester_busy_insert_two` with source
kind `ppif`.

One additive supported-smoke/strict-supported alias moves current accounting
from 315 to 316 protocol fixtures and from 356 to 357 supported-smoke/strict
fixtures. The public AHB IAL2 inventory moves from 39 paths—twenty `.ppif` and
nineteen `.ahb`—to 40 paths, evenly split between the two suffixes.

## Report, Semantic, And MCP Contract

Both suffixes preserve:

```text
schema=fsmgen.ial2.protocol_intent.ahb_requester.v1
busy_insertion.generated_behavior=true
busy_insertion.htrans_busy_encoding=2'b01
busy_insertion.before_beat=2
busy_insertion.beats=2
```

The generic `.ppif` report keeps `ahb_profile_alias_deferred`; existing
suffix-keyed handling removes only that residue from the `.ahb` report. Both
reports retain byte-identical `ahb_requester_busy_insert_support` detail,
including shipped exact-two semantics and deferral of broader count/policy
behavior.

The bounded semantic API is part of the alias contract, not incidental test
output. Strict check, `--emit-semantic-json`, and the read-only MCP
`fsmgen_semantic_introspect` tool must expose the alias source path, support ID,
coverage key, source kind, generated module `amba_requester_busy_insert_two`,
and semantic source root `fsm`. The MCP adapter must obtain that information
through the existing stable semantic-introspection contract; `.7` must not add
an alias-specific MCP route or expose private parser/generator internals.

## Selected Regression Contract

Focused `t/1522-ial2-ahb-requester-two-busy-insert-profile-alias.t` owns:

- tracked source existence and byte identity with the generic `.ppif`;
- direct parse and generated IAL1/IAL0 equality;
- report equality except for alias-only residue removal;
- strict check, schedule JSON, semantic JSON, output-review artifacts, HDL
  module identity, and `--verify-hdl`;
- support identity, source kind, semantic root, and a read-only
  `fsmgen_semantic_introspect` MCP call over the alias path;
- rejection of wrong-profile/wrong-object reserved-label probes; and
- preservation of the generic exact-two, exact-one `.ppif`/`.ahb`, and base
  requester identities.

t/1522 must not compile or run a second generated-HDL simulation. The
assertion-enabled t/1521 continuous, 32-clock ready-low, and 32-clock grant-low
scenarios remain the shared runtime proof for the byte-identical source pair:
one contiguous BUSY episode, exactly two qualified BUSY events, the same
resumed `SEQ`, and four data beats.

Closeout also requires t/248 and t/297 accounting/capability updates, the
current-surface t/1518 lock, relevant exact-one preservation, mdBook/README/
roadmap/behavior/fact/task/Memory synchronization, Knowledge Map generation
and check, relative-document paths, diff, doctrine gates, and the 4-GiB
descendant RSS cap for heavyweight commands.

## Explicit Non-Selections

`.7` must not change `PPIF.pm`, `AhbRequester.pm`, the public exact-two syntax,
numeric report value, counter/rule implementation, ports, artifacts, or runtime
behavior. It must not add paired exact-two sources, another runtime harness,
counts beyond two, generalized count width, multiple insertion points,
runtime/policy/random throttling, distinct local bus-BUSY status, broader
bursts/signals/managers, queues/outstanding transfers, direct seeds/backends,
verification-output generation, backend variants, AXI/APB changes, VHDL, the
separate selector repairs, or decision 0020.

## Validation

The selector itself is documentation-only plus current-state probes:

```bash
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e '...parse_source(..., "ppif/ahb_requester_busy_insert_two.ahb")...'
./scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- env -u PERL5LIB prove -Iperl t/1518-ial2-ahb-mdbook-current-surface-truthfulness.t
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback of `.6` is documentation-only: remove this record and its fact card,
restore `.6` to active selection, remove pending `.7`, and revert the current
README/roadmap/mdBook/task/Memory pointers. No runtime or public source behavior
is affected.
