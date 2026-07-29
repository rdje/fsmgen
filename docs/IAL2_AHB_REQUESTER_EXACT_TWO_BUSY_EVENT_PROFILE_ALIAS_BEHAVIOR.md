# IAL2 AHB Requester Exact-Two BUSY Event `.ahb` Profile Alias Behavior

Task-tree owner:
`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.7`

Date: 2026-07-24

## Outcome

FSMGen ships the bounded exact-two requester BUSY-event contract through both
the generic IAL2 container and matching AHB vocabulary alias:

```text
ppif/ahb_requester_busy_insert_two.ppif
ppif/ahb_requester_busy_insert_two.ahb
```

The files are byte-identical. Both declare `(profile ahb)`, use the existing
AHB requester generator, lower through the same generated IAL1 and IAL0, and
emit HDL module `amba_requester_busy_insert_two`. The `.ahb` suffix is a public
profile alias over IAL2, not a separate generator, language, or direct lowering
route.

## Preserved Exact-Two Behavior

Both suffixes declare:

```text
(busy-before-beat 2)
(busy-beats 2)
```

They insert exactly two rising
`HGRANT && HREADY && HTRANS == 2'b01` events before the selected pending `SEQ`
transfer. Ready-low and grant-low clocks consume no count. Address, control,
write data, beat index, and remaining data-beat count stay stable for the whole
BUSY episode. Neither BUSY event completes a data beat or consumes a response;
the same pending transfer resumes as `SEQ` after the second event.

Both sources preserve actor-owned width-two `ahb_busy_remaining_q`, the
non-final decrement and final clear/address-pending/SEQ rules, existing
`busy_inserted_q` one-shot, and the checker-required explicit final-over-
nonfinal priority. Generated artifacts are:

```text
amba_requester_busy_insert_two.isf
amba_requester_busy_insert_two.fsm
HDL module amba_requester_busy_insert_two
```

## Report And Alias Difference

Both reports preserve:

```text
schema=fsmgen.ial2.protocol_intent.ahb_requester.v1
busy_insertion.generated_behavior=true
busy_insertion.htrans_busy_encoding=2'b01
busy_insertion.before_beat=2
busy_insertion.beats=2
```

The generic `.ppif` report keeps `ahb_profile_alias_deferred` to identify the
second source surface. Existing suffix-keyed adapter handling removes only that
residue from the `.ahb` report. Both keep identical
`ahb_requester_busy_insert_support` detail: exact two qualified BUSY events
ship, the additive generic exact-three and exact-four sources are supported,
and only counts above four, multiple insertion points, and
runtime/policy/random throttling remain deferred.

No parser or generator algorithm changed for the alias.

## Support And Semantic Introspection

```text
support id:      intent.ahb_profile_alias_requester_busy_insert_two
coverage:        ial2_ahb_profile_alias_requester_busy_insert_two_pipeline_cli
source kind:     ial2_profile_alias
classification:  supported_smoke
strict:          supported
semantic root:   fsm
HDL module:      amba_requester_busy_insert_two
```

This alias moved the support corpus to 316 protocol fixtures and 357
supported-smoke/strict-supported fixtures, with 40 AHB IAL2 paths split
twenty/twenty. The one- and two-subordinate exact-two paired source/alias
lineage later established checkpoints through 320/361/44. The additive generic
exact-three requester established 321/362/45; its matching exact-three alias
established 322/363/46. The generic exact-three paired source established
323/364/47; its matching alias established 324/365/48. The generic
two-subordinate exact-three paired source established 325/366/49; its matching
alias established 326/367/50. The later generic exact-four requester moves
current totals to 327/368 and 51 AHB paths: twenty-six `.ppif` sources and
twenty-five `.ahb` aliases.

The alias is exposed through the same bounded semantic contract as every other
support-accounted source. Strict check and `--emit-semantic-json` report its
alias path, support ID, coverage, source kind, module, and `fsm` semantic root.
The read-only MCP `fsmgen_semantic_introspect` tool returns that normalized
semantic payload through the existing adapter; no alias-specific MCP method or
private parser/generator payload was added.

## Run It

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert_two.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester_busy_insert_two.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester_busy_insert_two.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-requester-busy-insert-two-alias ppif/ahb_requester_busy_insert_two.ahb
./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_requester_busy_insert_two.ahb
perl bin/fsmgen-mcp --workspace-root . --request-json '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"fsmgen_semantic_introspect","arguments":{"source_path":"ppif/ahb_requester_busy_insert_two.ahb"}}}'
```

Focused t/1522 proves byte parity, direct parse/report/artifact parity, strict
check, schedule JSON, semantic JSON, real read-only MCP introspection, outdir
artifacts, HDL module, `--verify-hdl`, diagnostics, and existing-requester
preservation. It deliberately compiles no second simulation. Assertion-enabled
t/1521 remains the shared generated-HDL runtime proof for both byte-identical
sources: continuous, 32-clock ready-low, and 32-clock grant-low scenarios each
observe one BUSY episode, exactly two qualified BUSY events, the same resumed
`SEQ`, and four data beats.

## Explicit Deferrals

The generic two-subordinate exact-two requester/subordinate composition and its
matching `.ahb` alias now ship through the existing generators. The later
generic exact-three requester, its matching `.ahb` alias, both generic/profile
exact-three paired topologies, and the generic exact-four requester also ship.
The exact-four requester alias, literal BUSY counts above four, multiple insertion points, runtime-selected
counts/points, policy/random throttling, distinct local bus-BUSY status,
larger/broader bursts, optional AHB signals, managers, queues/outstanding
transfers, direct seeds/backends, verification-output generation, backend
variants, AXI/APB changes, VHDL, the separate selector repairs, and decision
0020 remain deferred/inactive.

## Rollback

Rollback removes the additive `.ahb` source, support/language/capability/test
entries, and alias behavior/fact documentation together; restores 315/356/39
accounting; and leaves the generic exact-two parser/generator/runtime behavior
and every exact-one/base requester unchanged.
