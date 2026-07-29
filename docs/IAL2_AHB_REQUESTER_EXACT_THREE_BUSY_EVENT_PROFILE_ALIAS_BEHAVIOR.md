# IAL2 AHB Requester Exact-Three BUSY Event `.ahb` Profile Alias Behavior

Task-tree owner:
`IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.5`

Date: 2026-07-29

## Outcome

FSMGen ships the bounded exact-three requester BUSY-event contract through both
the generic IAL2 container and matching AHB vocabulary alias:

```text
ppif/ahb_requester_busy_insert_three.ppif
ppif/ahb_requester_busy_insert_three.ahb
```

The files are byte-identical. Both declare `(profile ahb)`, use the existing
AHB requester generator, lower through the same generated IAL1 and IAL0, and
emit HDL module `amba_requester_busy_insert_three`. The `.ahb` suffix is a
public profile alias over IAL2, not a separate generator, language, or direct
lowering route.

## Preserved Exact-Three Behavior

Both suffixes declare:

```text
(busy-before-beat 2)
(busy-beats 3)
```

They insert exactly three rising
`HGRANT && HREADY && HTRANS == 2'b01` events before the selected pending `SEQ`
transfer. Ready-low and grant-low clocks consume no count. Address, control,
write data, beat index, and remaining data-beat count stay stable for the whole
BUSY episode. No BUSY event completes a data beat or consumes a response; the
same pending transfer resumes as `SEQ` after the third event.

Both sources preserve the actor-owned width-two `ahb_busy_remaining_q`, literal
three initialization, qualified non-final decrement and final clear/address-
pending/SEQ rules, existing `busy_inserted_q` one-shot, whole-BUSY continuation,
and checker-required priorities. Generated artifacts are:

```text
amba_requester_busy_insert_three.isf
amba_requester_busy_insert_three.fsm
HDL module amba_requester_busy_insert_three
```

## Report And Alias Difference

Both reports preserve:

```text
schema=fsmgen.ial2.protocol_intent.ahb_requester.v1
busy_insertion.generated_behavior=true
busy_insertion.htrans_busy_encoding=2'b01
busy_insertion.before_beat=2
busy_insertion.beats=3
```

The generic `.ppif` report keeps `ahb_profile_alias_deferred` to identify the
second source surface. Existing suffix-keyed adapter handling removes only that
residue from the `.ahb` report. Both keep identical
`ahb_requester_busy_insert_support` detail: exact three qualified BUSY events
ship and the additive generic exact-four source is supported, while counts
above four, multiple insertion points, and runtime/policy/random throttling
remain deferred.

No parser or generator algorithm changed for the alias.

## Support And Semantic Introspection

```text
support id:      intent.ahb_profile_alias_requester_busy_insert_three
coverage:        ial2_ahb_profile_alias_requester_busy_insert_three_pipeline_cli
source kind:     ial2_profile_alias
classification: supported_smoke
strict:          supported
semantic root:   fsm
HDL module:      amba_requester_busy_insert_three
```

The alias established 322 protocol fixtures, 363 supported-smoke/strict-
supported fixtures, and 46 AHB IAL2 paths. The generic exact-three paired
source established 323/364/47; its matching alias moves current support
checkpoint to 324/365/48. The generic two-subordinate exact-three paired source
established 325/366/49; its matching alias established 326/367/50. The generic
exact-four requester established 327/368/51 and its matching alias established
328/369/52. The later exact-four paired generic/profile pair moves current
support accounting to 330 protocol fixtures, 371 supported-smoke/strict-
supported fixtures, and 54 AHB paths split 27 `.ppif` sources / 27 `.ahb`
aliases.

Strict check and `--emit-semantic-json` expose the alias path, support ID,
coverage, source kind, module, and `fsm` semantic root. The read-only MCP
`fsmgen_semantic_introspect` tool returns that normalized semantic payload
through the existing adapter with `read_only=true` and `shell_access=false`;
no alias-specific MCP method or private parser/generator payload was added.

## Run It

Run heavyweight commands under the repository RAM guard:

```bash
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert_three.ahb
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester_busy_insert_three.ahb
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester_busy_insert_three.ahb
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_requester_busy_insert_three.ahb
```

Generated outputs should use a repository-derived same-volume path.

Focused t/1529 proves byte, parse, report, artifact, strict-check, schedule,
normalized-semantic, real read-only MCP, outdir, verifier, targeted-diagnostic,
and requester-preservation parity. It passes four top-level subtests and 72
nested assertions in 53 seconds, and deliberately compiles no simulation.

The updated regression-corpus accounting and capability-manifest gates pass
6,911 assertions together. The strengthened AHB current-surface truthfulness
gate passes all five top-level subtests.

Assertion-enabled t/1528 remains the sole shared generated-HDL runtime proof
for both byte-identical sources. Its continuous, 32-clock ready-low, and
32-clock grant-low scenarios directly observe internal `3 -> 2 -> 1 -> 0`, one
BUSY episode, exactly three qualified BUSY events, stable pending ownership,
the same resumed `SEQ`, four accepted byte `INCR4` data beats, and zero final
count.

## Explicit Deferrals

Generic/profile one- and two-subordinate exact-three paired compositions and
the generic/profile exact-four requester pair now also ship. Literal BUSY
counts above four, multiple insertion points, runtime-selected counts/points, policy/
random throttling, distinct local bus-BUSY status, larger/broader bursts,
optional AHB signals, managers, queues/outstanding transfers, direct seeds/
backends, verification-output generation, backend variants, selector repairs,
AXI/APB changes, VHDL, and decision 0020 remain separate and inactive.

## Rollback

Rollback removes the additive `.ahb` source, support/language/capability/test
entries, and alias behavior/fact documentation together; restores
321/362/45 accounting split 23 `.ppif`/22 `.ahb`; and leaves generic
exact-three parser/generator/runtime behavior plus every exact-one/two/base and
paired requester surface unchanged.
