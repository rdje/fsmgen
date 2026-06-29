# IAL2 AHB Subordinate Seed Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.708`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.708` selects the first lower-layer AHB
subordinate seed contract. The selected seed is a direct `.fsm` fixture named
`fsm/ahb_lite_subordinate.fsm` with module name `ahb_lite_subordinate` and
support-accounting identity `protocol.ahb_lite_subordinate`.

The selected subset is a bounded AHB-Lite/common-AHB word-register subordinate
seed. It establishes the source-backed endpoint behavior needed before any
IAL2 AHB completer/subordinate public source vocabulary is selected.

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.709`, direct
implementation of the selected lower-layer seed. `.709` must add the direct
`.fsm` seed and its focused validation/support-accounting/docs updates, and
must not add IAL2 AHB completer/subordinate parser or generator behavior.

No seed, parser behavior, generator behavior, public source sample,
support-accounting catalog entry, capability manifest, test behavior,
schedule/check/semantic JSON behavior, generated artifact, HDL/runtime
behavior, suffix behavior, direct backend behavior, verification-output
generation, backend-language variant, AXI, APB, or VHDL behavior changed in
this selector.

## Evidence Read

The selector read:

- `.707`, the source-backed AHB/AHB-Lite subordinate fact inventory;
- the imported Arm AMBA AHB Protocol Specification PDF at
  `docs/vendor/arm/amba/ahb/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification.pdf`;
- `.706`, the source-reference import record;
- `.703` and `.704`, the prerequisite and source-reference audit records;
- `.702`, the AHB completer/subordinate readiness audit;
- shipped AHB requester sources `ppif/ahb_requester.ppif`,
  `ppif/ahb_requester.ahb`, and `fsm/amba_requester.fsm`;
- APB lower-layer seed precedent `fsm/apb_completer.fsm` and the generated
  IAL1 substrate audit;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  workflow decisions.

## Selected Seed Shape

The first direct seed is:

```text
fsm/ahb_lite_subordinate.fsm
(?fsm:ahb_lite_subordinate ...)
protocol.ahb_lite_subordinate
```

The seed uses the current direct `.fsm` system convention with a repository
clock/reset pair and documents that `rst_n` is the AHB active-low reset
counterpart:

```text
(+system
  (clock clk)
  (areset rst_n)
)
```

The public seed remains lower-layer/direct. It is not an IAL2 `.ppif` or
`.ahb` source, not an interconnect, and not an AHB requester/completer
composition.

## Selected Port Set

The selected first-seed protocol ports are:

| Direction | Signal | Width | Contract |
| --- | --- | --- | --- |
| input | `HSEL` | 1 | Local selected-subordinate decode input, corresponding to the source `HSELx` role. |
| input | `HADDR` | 32 | Address phase address. |
| input | `HTRANS` | 2 | Transfer type: `IDLE`, `BUSY`, `NONSEQ`, `SEQ`. |
| input | `HWRITE` | 1 | Direction: write when high, read when low. |
| input | `HSIZE` | 3 | Transfer size; first seed accepts word transfers only. |
| input | `HREADY` | 1 | Previous transfer completion/selection gate. |
| input | `HWDATA` | 32 | Write data for the selected data phase. |
| input | `wait_cycles` | 4 | Fixture-local bounded wait-state control. |
| output | `HREADYOUT` | 1 | Subordinate data-phase completion/wait response. |
| output | `HRESP` | 1 | AHB-Lite/common-AHB OKAY/ERROR status, `0` for OKAY and `1` for ERROR. |
| output | `HRDATA` | 32 | Read data; zero on idle and read ERROR. |

`HBURST`, `HPROT`, `HMASTLOCK`, AHB5 property-gated signals, user signals,
parity/check signals, exclusive-access signals, and multi-manager identity
signals are explicit residue. The first seed does not silently include them
or infer defaults from requester code.

## Transfer Contract

The seed accepts a new address/control phase only when:

```text
HSEL == 1 && HREADY == 1
```

For `HTRANS == IDLE` or `HTRANS == BUSY`, the seed ignores the transfer and
returns zero-wait OKAY with no storage change.

For `HTRANS == NONSEQ`, the seed samples address/control and enters a data
phase. The only supported successful transfer is a 32-bit word transfer
(`HSIZE == 3'b010`) to address `32'h00000000`.

For `HTRANS == SEQ`, the first seed reports unsupported burst continuation
through the selected ERROR response policy. Burst state, wrapped/incrementing
addresses, and related unchanged-control rules are deferred.

When `wait_cycles` is nonzero, the seed inserts bounded data-phase wait states
by driving `HREADYOUT == 0` and `HRESP == 0` while decrementing the sampled
wait counter. Write data is consumed in the completion data phase, not in the
address phase, matching the AHB address/data phase separation.

## Register And Data Policy

The first seed implements one 32-bit register:

```text
address 32'h00000000 -> reg_data_q[31:0]
```

Successful word writes update `reg_data_q` from `HWDATA` in the completion
cycle. Successful word reads drive `HRDATA` from `reg_data_q` in the
completion cycle.

All other addresses and all unsupported sizes report ERROR and do not update
storage. Narrow byte-lane behavior, strobes, byte-address lane mapping,
unaligned-address policy, and register banks wider than one register are
future owners.

## Reset And Default Outputs

On reset, the seed resets internal state and `reg_data_q` to zero. During
reset and in idle, the selected output defaults are:

```text
HREADYOUT = 1
HRESP     = 0
HRDATA    = 32'h00000000
```

That preserves the source requirement that subordinates drive `HREADYOUT`
high during reset and gives the direct fixture stable idle/read-error data.

## Response Policy

Successful transfers complete with:

```text
HRESP     = 0
HREADYOUT = 1
```

Pending wait cycles use:

```text
HRESP     = 0
HREADYOUT = 0
```

Unsupported `NONSEQ` and unsupported `SEQ` transfers use the source-backed
two-cycle ERROR response after any selected OKAY wait cycles:

```text
cycle 1: HRESP = 1, HREADYOUT = 0, HRDATA = 32'h00000000
cycle 2: HRESP = 1, HREADYOUT = 1, HRDATA = 32'h00000000
```

The seed performs no write update on ERROR. The first seed does not model
legacy two-bit `HRESP` RETRY/SPLIT responses; the source-backed AHB-Lite
OKAY/ERROR subset is the selected boundary.

## Validation Scope For `.709`

The implementation leaf must add:

- `fsm/ahb_lite_subordinate.fsm`;
- `protocol.ahb_lite_subordinate` support-accounting coverage matching the
  direct protocol fixture precedent used by `protocol.apb_completer` and
  `protocol.amba_requester`;
- focused strict check and HDL-generation validation for the new direct seed;
- focused support-accounting validation;
- README, ROADMAP_V2, mdBook, Knowledge Map, task tree, and Memory sync.

The expected focused command set for `.709` starts with:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
./bin/fsmgen --quiet --output /tmp/fsmgen_ahb_lite_subordinate.sv fsm/ahb_lite_subordinate.fsm
prove -Iperl t/248-regression-corpus-accounting.t
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

If a broader HDL validation gate is warranted, `.709` may add the smallest
focused owned test or command, but it must not merge IAL2 source work into the
direct seed implementation.

## Explicit Residue

The following remain future task-tree-owned work:

- IAL2 AHB completer/subordinate `.ppif` source vocabulary;
- `.ahb` completer/subordinate profile alias;
- generated `.isf`/`.fsm` review artifacts for IAL2 AHB subordinate behavior;
- AHB interconnect/decode, multi-subordinate muxing, and topology;
- burst `SEQ` support, `HBURST`, wrapping/incrementing bursts, and burst
  address progression;
- `HBURST`, `HPROT`, `HMASTLOCK`, AHB5 property-gated signals, user signals,
  parity/check signals, exclusive access, and multi-manager identity signals;
- byte-lane/narrow transfer write behavior and alignment policy;
- register banks beyond the single selected word register;
- requester/subordinate integration examples and scoreboards;
- legacy two-bit `HRESP` RETRY/SPLIT compatibility;
- direct backend, verification-output generation, backend-language variants,
  AXI, APB, and VHDL.

## Rejected Alternatives

Selecting an IAL2 AHB completer/subordinate public contract now is rejected
because the lower-layer subordinate seed still has to ship first.

Naming the first seed `amba_subordinate` is rejected because the selected
source-backed behavior is the AHB-Lite/common-AHB OKAY/ERROR subset, not the
full historical AMBA AHB response space.

Including `HBURST`, `HPROT`, `HMASTLOCK`, or AHB5 optional/property-gated
signals in the first seed is rejected because they are not needed for the
single-register word-transfer oracle and would expand the first endpoint
beyond the smallest reviewable behavior.

Always-ready-only behavior is rejected because a bounded `wait_cycles` input
is a small fixture-local control that exercises the source-backed
`HREADYOUT` wait-state contract before IAL2 work depends on it.

## Validation

This selector is documentation-only:

```bash
rg -n 'HSEL|HREADY|HTRANS|HREADYOUT|HRESP|HRDATA|Response Timing Facts|Reset And Validity Facts' \
  docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md
rg -n 'protocol.apb_completer|protocol.amba_requester' \
  perl/FSM/Support/RegressionCorpus.pm t/248-regression-corpus-accounting.t
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback of `.708` removes this selector, its Knowledge Map fact card, and the
README/ROADMAP/mdBook/task-tree/Memory updates. No runtime behavior, source
sample, parser rule, generator, support-accounting entry, test, generated
artifact, public suffix behavior, direct backend behavior, or backend-language
behavior is changed by this selector.
