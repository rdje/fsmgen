# IAL2 AHB Requester Exact-Four BUSY Event `.ahb` Profile Alias Behavior

Task-tree owner:
`IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.5`

Date: 2026-07-29

## Outcome

FSMGen ships exact-four requester BUSY insertion through both public IAL2
source spellings:

```text
ppif/ahb_requester_busy_insert_four.ppif
ppif/ahb_requester_busy_insert_four.ahb
```

The files are byte-identical. Both declare `(profile ahb)`, use the same
existing AHB requester generator, lower through generated IAL1 and IAL0, and
emit HDL module `amba_requester_busy_insert_four`. The `.ahb` suffix is a
profile alias over IAL2, not another language, generator, or direct lowering
route.

## Preserved Exact-Four Behavior

Both sources declare:

```text
(busy-before-beat 2)
(busy-beats 4)
```

They insert exactly four rising
`HGRANT && HREADY && HTRANS == 2'b01` events before the selected pending `SEQ`
transfer. Ready-low and grant-low clocks consume no count. BUSY completes no
data beat or response, and the same pending transfer resumes as `SEQ` after
the fourth qualified event.

The existing minimum-width derivation preserves a width-three
`ahb_busy_remaining_q`. Existing qualified rules retire
`4 -> 3 -> 2 -> 1 -> 0`; priorities, ownership, ports, artifacts, and HDL are
identical between suffixes:

```text
amba_requester_busy_insert_four.isf
amba_requester_busy_insert_four.fsm
HDL module amba_requester_busy_insert_four
```

## Report And Alias Difference

Both reports preserve:

```text
schema=fsmgen.ial2.protocol_intent.ahb_requester.v1
busy_insertion.generated_behavior=true
busy_insertion.htrans_busy_encoding=2'b01
busy_insertion.before_beat=2
busy_insertion.beats=4
```

The generic `.ppif` report keeps `ahb_profile_alias_deferred`. Existing
suffix-keyed handling removes only that residue from the `.ahb` report. Both
retain identical `ahb_requester_busy_insert_support` detail: four events ship,
while counts above four and generalized runtime/policy/random or multiple-
point insertion remain deferred. No parser or generator algorithm changed for
this alias.

## Support And Semantic Introspection

```text
support id:      intent.ahb_profile_alias_requester_busy_insert_four
coverage:        ial2_ahb_profile_alias_requester_busy_insert_four_pipeline_cli
source kind:     ial2_profile_alias
classification: supported_smoke
strict:          supported
semantic root:   fsm
HDL module:      amba_requester_busy_insert_four
```

The alias moves current accounting to 328 protocol fixtures, 369 supported-
smoke and strict-supported fixtures, and 52 AHB IAL2 paths split evenly
between 26 `.ppif` sources and 26 `.ahb` aliases.

Strict check and normalized semantic JSON expose the alias path, support ID,
coverage, source kind, module, and `fsm` semantic root. The existing read-only
`fsmgen_semantic_introspect` MCP tool returns the same bounded semantic payload
with `read_only=true` and `shell_access=false`; no alias-specific MCP route or
private lowering payload was added.

## Run It

```bash
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert_four.ahb
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester_busy_insert_four.ahb
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester_busy_insert_four.ahb
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_requester_busy_insert_four.ahb
```

Generated outputs and temporary workspaces stay under repository-derived,
same-volume roots.

Focused t/1536 passes four top-level subtests and 86 nested assertions. It
proves byte, parse, report, strict-check, schedule, exact artifact, repository-
local output, normalized-semantic, real read-only shell-disabled MCP, verifier,
targeted-diagnostic, requester, and paired-source preservation parity. It
deliberately compiles no simulation.

Assertion-enabled t/1535 remains the sole shared generated-HDL runtime proof
for the byte-identical pair. Its continuous, 32-clock ready-low, and 32-clock
grant-low scenarios observe exact `4 -> 3 -> 2 -> 1 -> 0`, four qualified BUSY
events, stable pending ownership, one resumed `SEQ`, four accepted byte
`INCR4` data beats, and zero final count.

## Explicit Deferrals

Exact-four paired compositions, counts above four, arbitrary/runtime/policy/
random counts, multiple insertion points, local bus-BUSY status, broader
bursts/signals/topologies, generic priority, other protocols/backends,
HIAL/VIAL activation, VHDL, verification generation, and decision 0020 remain
separate.

## Rollback

Rollback removes the `.ahb` file, support/language/capability/test entries, and
this behavior/fact pair; restores 327/368/51 accounting split 26 `.ppif` / 25
`.ahb`; and leaves generic exact-four parser/generator/runtime behavior plus
all exact-one/two/three and paired sources unchanged.
