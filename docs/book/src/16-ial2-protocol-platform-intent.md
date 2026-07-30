# IAL2 Protocol And Platform Intent

IAL2 is FSMGen's protocol and platform intent layer. Use it when the source
should describe a protocol object, protocol profile, or platform mapping above
explicit cycle-level FSM logic and above explicit ISF actor scheduling.

The layer boundary is fixed:

```text
IAL2 source -> generated IAL1 .isf -> generated IAL0 .fsm -> HDL
```

Generated `.isf` and `.fsm` files are review artifacts. A supported IAL2
feature must keep those artifacts visible through the normal CLI surfaces, and
it must not bypass them with direct HDL generation.

## Where IAL2 Fits

FSMGen's public source layers are:

| Layer | File surface | What the user authors |
| --- | --- | --- |
| IAL0 | `.fsm` | Explicit cycle-authored FSM and decision-tree logic. |
| IAL1 | `.isf` | Scheduling intent that lowers into reviewable `.fsm`. |
| IAL2 | `.ppif` and selected profile aliases | Protocol or platform intent that lowers into reviewable `.isf`, then `.fsm`. |

`.ppif` is the generic IAL2 container. Selected protocol aliases such as
`.axi`, `.apb`, and `.ahb` are aliases over the same IAL2 model, not separate
language layers. A protocol alias does not get direct-lowering privileges.

## Three Authoring Modes

IAL2 documentation uses the same three modes for each protocol:

| Mode | Use it when | Current contract |
| --- | --- | --- |
| Guided mode | You want the smallest checked-in public example for the protocol family. | The book starts from a runnable source and shows the commands that expose generated review artifacts and reports. |
| More-control mode | You need selected knobs such as IDs, sidebands, widths, policies, or bounded register/decode shape. | The book stays inside shipped public clauses and explains the validation/report fields that make those knobs reviewable. |
| Raw/full-control mode | You need the deepest shipped explicit IAL2 source shape for that protocol. | This is still IAL2 through generated `.isf` and `.fsm`; it is not raw HDL authoring and not a bypass around generated review artifacts. |

If a protocol has no shipped IAL2 source surface yet, its row stays honest: the
book can point at existing direct `.fsm` coverage, but it must not present that
coverage as `.ppif`, a profile alias, or generated IAL1 behavior.

## Protocol Navigation

| Protocol | Guided starting point | More-control path | Raw/full-control boundary |
| --- | --- | --- | --- |
| AXI | Checked-in `.ppif` Valid-Ready and selected `.axi` profile-alias samples. | Bounded manager capacity/status, ID-family, transaction, response-demux, read-data, burst, dynamic-ID, same-ID, queue, and runtime-validation families. | Shipped examples remain bounded IAL2 surfaces. Full AXI manager behavior, arbitrary cardinalities, complete scoreboards, direct backend behavior, verification-output generation, backend-language variants, and VHDL remain future task-tree-owned work. |
| APB | Checked-in requester, completer, and fixed-composition `.ppif` samples plus byte-identical `.apb` aliases where selected. | Busy/status, sideband, data16, protection, multi-register, multi-peripheral, generalized register-set, and selected back-to-back timing families. | APB interconnect and decode are protocol-specific generated behavior. More-than-six-register, more-than-two-peripheral, bus-matrix, scoreboard, direct backend, verification-output, backend-language variant, AXI, AHB, and VHDL work remain deferred. |
| AHB | Checked-in bounded requester, word-only and byte-lane subordinate families, one- and two-subordinate interconnects, selected aggregate byte-lane/in-word-`SEQ`/HBURST/BUSY-park/paired-BUSY `.ppif` samples, matching selected `.ahb` profile aliases through exact-four requester BUSY insertion, generic plus matching `.ahb` one-subordinate exact-one through exact-four and two-subordinate exact-two through exact-four paired sources, aggregate HBURST and aggregate BUSY-park surfaces, and direct `.fsm` seeds. | Bounded requester local command/status, bus, burst, transfer, response, fixed-wrap, exact-one BUSY insertion by absence, and canonical decimal literal `busy-beats` values `2..16` without a fixture per count; separated address/data ownership; bounded subordinate control, bus, one-register storage, selected byte/halfword/word lanes, in-word `SEQ`, byte-only HBURST `WRAP4`/`INCR4`, BUSY parking, and one accepted active-phase bank; selected one-/two-subordinate static-window interconnect/decode shapes with retained one-hot data-phase ownership and matching aggregate `.ppif`/`.ahb` surfaces, plus generic and matching `.ahb` one-subordinate exact-one through exact-four and two-subordinate exact-two through exact-four requester/BUSY-parking compositions. | AHB completer behavior, broader interconnect/decode beyond the selected static-window aggregates, optional subordinate signals beyond the shipped HBURST endpoint binding, wider/indefinite HBURST continuation beyond the bounded byte-only `WRAP4`/`INCR4` sources, literal BUSY counts above 16, policy/runtime/random/symbolic BUSY count selection, multiple insertion points, distinct bus-BUSY status, general/deeper queues, multiple outstanding transfers, scoreboards, full manager behavior beyond the bounded requester, direct backend behavior, verification-output generation, backend-language variants, and VHDL remain future task-tree-owned work. |

Detailed protocol examples are split into separate follow-on chapters so the
examples can be validated and kept current per protocol without making this
map unreadable. AXI examples are in [AXI IAL2 Examples](16a-ial2-axi.md), and
APB examples are in [APB IAL2 Examples](16b-ial2-apb.md). The current AHB
boundary is documented in [AHB Current Boundary](16c-ial2-ahb.md).

## Reviewing Generated Artifacts

These command families are the common IAL2 inspection path:

```bash
./bin/fsmgen --quiet --strict --check --json SOURCE.ppif
./bin/fsmgen --quiet --emit-schedule-json SOURCE.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json SOURCE.ppif
./bin/fsmgen --quiet --outdir generated SOURCE.ppif
```

For selected profile aliases, replace `SOURCE.ppif` with the alias file, such
as a shipped `.axi`, `.apb`, or `.ahb` example. The expected review shape is the
same: source identity remains on the public IAL2 file, reports describe the
protocol intent and residue, and `--outdir` writes generated `.isf` and `.fsm`
review artifacts before HDL.

## Implementation Workflow

This chapter is the user-facing protocol map. The engineering workflow for
adding or extending an IAL2 protocol is
[Adding IAL2 Protocols](15a-ial2-new-protocol-support.md).

The implementation blueprint is
[Implementation Blueprint](15-implementation-blueprint.md). It describes how
future implementation-language variants must preserve the same source syntax,
diagnostics, reports, generated review artifacts, support accounting, and HDL
behavior for every IAL2 feature they claim.

## Current Boundaries

AXI and APB have shipped IAL2 `.ppif` examples and selected profile aliases.
They are still bounded protocol surfaces, not claims that every AXI or APB
legal behavior is generated.

AHB has shipped bounded generic `.ppif` requester coverage, bounded generic
`.ppif` AHB-Lite/common-AHB word-only, byte-lane, byte-lane in-word `SEQ`, and
byte-lane HBURST `WRAP4`/`INCR4` `SEQ` subordinate coverage, selected
one-subordinate and two-subordinate aggregate
interconnect/decode `.ppif` coverage, selected generic aggregate byte-lane
propagation `.ppif` coverage, matching selected `.ahb` profile aliases for
those bounded surfaces, the older direct `.fsm` AMBA requester seed, and a
direct lower-layer subordinate seed at `fsm/ahb_lite_subordinate.fsm`. The AHB
IAL2 paths lower through generated `.isf` and generated `.fsm` review
artifacts.

Any new suffix, protocol object, report family, generated artifact, or example
must first be selected by a task-tree leaf, then documented with checked-in
examples and the standard gates.
