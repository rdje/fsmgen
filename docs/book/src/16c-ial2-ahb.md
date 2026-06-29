# AHB IAL2 Current Boundary

FSMGen ships two public bounded AHB IAL2 entrypoints today:

```text
ppif/ahb_requester.ppif
ppif/ahb_requester.ahb
```

The `.ppif` source is the generic Protocol/Platform Intent file. The `.ahb`
source is the bounded AHB requester profile alias over the same IAL2 model. It
uses the same `protocol-platform-intent` form, keeps explicit `(profile ahb)`,
and supports exactly one `(ahb-requester amba_requester ...)` object.

Both public IAL2 sources lower through generated review artifacts before HDL:

```text
ppif/ahb_requester.ppif -> amba_requester.isf -> amba_requester.fsm -> HDL module amba_requester
ppif/ahb_requester.ahb  -> amba_requester.isf -> amba_requester.fsm -> HDL module amba_requester
```

FSMGen also keeps direct lower-layer `.fsm` seeds:

```text
fsm/amba_requester.fsm
fsm/ahb_lite_subordinate.fsm
```

These direct seeds remain useful cycle-level coverage, but they are not IAL2
and do not produce generated `.isf` or generated `.fsm` review artifacts.

## Mode Map

| Mode | Current source | Boundary |
| --- | --- | --- |
| Guided mode | `ppif/ahb_requester.ppif` or `ppif/ahb_requester.ahb` | Bounded AHB requester IAL2 source. The `.ppif` entry is support-accounted as `intent.ppif_ahb_requester`; the `.ahb` alias is support-accounted as `intent.ahb_profile_alias_requester`. |
| More-control mode | The same bounded requester sources plus direct `fsm/amba_requester.fsm` and `fsm/ahb_lite_subordinate.fsm` for cycle-level comparison | Selected requester knobs are exposed as `local-command`, `local-status`, `bus`, `burst`, `transfer`, and `response` clauses. The subordinate seed is lower-layer/direct only. |
| Raw/full-control mode | Direct `fsm/amba_requester.fsm` and `fsm/ahb_lite_subordinate.fsm` | IAL2 AHB completer/subordinate generation, interconnect/decode, scoreboards, full manager behavior, direct backend behavior, verification-output generation, backend-language variants, and VHDL remain future task-tree-owned work. |

## Guided PPIF Requester

Run the shipped generic IAL2 requester through the standard review path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-requester ppif/ahb_requester.ppif
```

The strict check reports:

```text
entry_id: intent.ppif_ahb_requester
source_kind: ppif
coverage: ial2_ppif_ahb_requester_pipeline_cli
module_name: amba_requester
```

## AHB Profile Alias

Use the `.ahb` alias when you want the source filename to advertise the AHB
profile while keeping the same IAL2 syntax and generated review artifacts:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-profile-alias ppif/ahb_requester.ahb
```

The `.ahb` strict check reports the authored alias path and support identity:

```text
entry_id: intent.ahb_profile_alias_requester
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_requester_pipeline_cli
module_name: amba_requester
```

The `.ahb` schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_requester.v1`, reports target profile `ahb`,
and exposes generated `amba_requester.isf` before `amba_requester.fsm`.

## Requester Source Shape

Both public IAL2 sources start with the same selected AHB requester shape:

```text
(protocol-platform-intent ahb_requester
  (profile ahb)
  (source
    (object fsmgen-ahb-requester)
    (anchor
      (document FSMGEN-AHB-REQUESTER-CAPTURE-WORKSHEET)
      (section bounded-requester)
      (page stage-1)))
  (ahb-requester amba_requester
    (role requester)
    (clock clk)
    (reset (rst_n active_low async))
    ...))
```

The generated AHB-side HDL ports include `HGRANT`, `HREADY`, `HRESP`,
`HRDATA`, `HBUSREQ`, `HLOCK`, `HADDR`, `HTRANS`, `HWRITE`, `HSIZE`, `HBURST`,
`HPROT`, and `HWDATA`. The local command/status ports include `cmd_valid`,
`cmd_ready`, `cmd_write`, `cmd_addr`, `cmd_wdata`, `cmd_wdata_step`,
`cmd_size`, `cmd_prot`, `cmd_lock`, `cmd_burst`, `cmd_len`, `busy`,
`beat_done`, `done`, `burst_active`, `wrap_active`, `beat_index`,
`beats_remaining`, `active_addr`, `active_hburst`, `last_error`,
`last_retry`, `last_split`, `last_resp`, and `last_read_data`.

The generated IAL1 requester uses an internal completion bit for transaction
completion, so the public `done` status output remains an ordinary status
drive:

```text
(storage
  (var ahb_request_done_q (width 1) (reset 0)))
...
(complete ahb_request_done_q)
```

## Requester Clauses

The first public AHB source intentionally models a bounded requester rather
than a full AMBA manager. The accepted object is exactly one
`(ahb-requester amba_requester ...)` under `(profile ahb)`.

Required blocks:

- `clock` and `reset`;
- `local-command` for `cmd_*` request fields;
- `local-status` for status outputs and last-response capture;
- `bus` for AHB request/response signal bindings;
- `burst` for the selected AHB burst encodings;
- `transfer` for IDLE/NONSEQ/SEQ transfer behavior;
- `response` for OKAY/ERROR/RETRY/SPLIT actions.

Selected widths are fixed in this slice: 32-bit address/data, 3-bit AHB size
and burst, 4-bit protection, 5-bit local length/index/count, and 2-bit transfer
and response. Unsupported widths, missing required blocks, duplicate blocks,
duplicate fields, unsupported fields, and non-AHB profiles fail closed.

The selected transfer behavior is:

- first accepted beat uses `HTRANS=NONSEQ`;
- later accepted beats use `HTRANS=SEQ`;
- transfer activity is gated by `HGRANT`;
- response advancement is gated by `HREADY`;
- `OKAY` advances or completes;
- `ERROR` completes with error status;
- `RETRY` and `SPLIT` keep the request active for re-request behavior.

## Alias Diagnostics

`.ahb` is accepted only as the bounded AHB requester profile alias:

- missing `(profile ...)` is rejected;
- any profile other than `ahb` is rejected as a suffix/profile mismatch;
- any object other than exactly one `(ahb-requester amba_requester ...)` is
  rejected for this slice;
- malformed AHB requester fields still use the same requester diagnostics as
  the `.ppif` source.

Known aliases that have not shipped yet still fail closed. For example, a
temporary `.chi` copy reports a known unsupported alias, while an unrelated
`.foo` suffix reports an unknown source suffix.

## Direct FSM Seeds

The direct requester seed remains available for the lower-level `.fsm` path:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/amba_requester.fsm
./bin/fsmgen --quiet -o generated/amba_requester.sv fsm/amba_requester.fsm
```

It is support-accounted separately:

```text
entry_id: protocol.amba_requester
source_kind: fsm
coverage: direct_root_pipeline_cli
module_name: amba_requester
```

The direct subordinate seed is a bounded AHB-Lite/common-AHB single-register
fixture:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
./bin/fsmgen --quiet -o generated/ahb_lite_subordinate.sv fsm/ahb_lite_subordinate.fsm
```

It is support-accounted separately:

```text
entry_id: protocol.ahb_lite_subordinate
source_kind: fsm
coverage: direct_root_pipeline_cli
module_name: ahb_lite_subordinate
```

The subordinate seed accepts selected `NONSEQ` word reads/writes to
`32'h00000000`, ignores `IDLE` and `BUSY` with zero-wait OKAY, inserts bounded
data-phase wait states through `wait_cycles`, and reports unsupported `SEQ`,
unsupported sizes, and unmapped addresses with the source-backed two-cycle
ERROR response. It uses a one-bit AHB-Lite `HRESP` OKAY/ERROR boundary.

Use the direct seeds when you need to inspect or modify explicit cycle-level
state transitions. Use `ppif/ahb_requester.ppif` or `ppif/ahb_requester.ahb`
when you need the public IAL2 requester source identity, source anchors,
generated `.isf` review artifact, generated `.fsm` review artifact, AHB report
schema, and IAL2 diagnostics.

## Residue

The following are not shipped by the current AHB IAL2 surface:

- AHB completer/subordinate generation;
- AHB interconnect/decode generation;
- AHB scoreboards;
- full AHB manager behavior beyond the bounded requester;
- direct IAL2-to-IAL0 or IAL2-to-HDL lowering;
- verification-output generation;
- backend-language variants;
- VHDL behavior.

The `.ppif` report keeps its historical `.ahb` profile-alias residue for the
generic `.ppif` source. The shipped `.ahb` alias removes that stale residue
from alias reports while keeping the broader AHB residue above.

The current AHB subordinate work has selected a public IAL2 contract but has
not shipped parser or generator behavior for it yet.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.705` recorded that no AHB/AHB-Lite source
reference artifact was available, `.706` imported the user-approved Arm AMBA
AHB Protocol Specification PDF under `docs/vendor/arm/amba/ahb/`, `.707`
extracted the first source-backed subordinate fact inventory, and `.708`
selected the first direct seed contract. `.709` now ships that direct fixture
as `fsm/ahb_lite_subordinate.fsm`, module `ahb_lite_subordinate`, with
support-accounting identity `protocol.ahb_lite_subordinate`.

That fixture is a bounded AHB-Lite/common-AHB single-register subordinate. Its
selected port set is `HSEL`, `HADDR`, `HTRANS`, `HWRITE`,
`HSIZE`, `HREADY`, `HWDATA`, fixture-local `wait_cycles`, `HREADYOUT`,
one-bit `HRESP`, and `HRDATA`. The shipped behavior accepts `NONSEQ` word
reads/writes to `32'h00000000`, ignores `IDLE` and `BUSY` with zero-wait
OKAY, uses bounded data-phase wait states, and reports unsupported `SEQ`,
unsupported sizes, and unmapped addresses through the source-backed two-cycle
ERROR response. IAL2 AHB completer/subordinate source, parser, generator,
support-accounting, and manifest behavior still remain deferred.
`.710` audits post-seed readiness and selects `.711`, public IAL2 AHB
subordinate/completer contract selection, before any such behavior changes.
`.711` then selects the future generic `.ppif` subordinate source:

```text
ppif/ahb_lite_subordinate.ppif
(ahb-subordinate ahb_lite_subordinate ...)
ahb_lite_subordinate.isf
ahb_lite_subordinate.fsm
fsmgen.ial2.protocol_intent.ahb_subordinate.v1
intent.ppif_ahb_lite_subordinate
```

That selected source will mirror the direct seed's bounded
AHB-Lite/common-AHB behavior: one subordinate endpoint, `HSEL && HREADY`
address/control acceptance, ignored `IDLE`/`BUSY`, selected `NONSEQ` word
transfers, one 32-bit register at address `0`, bounded `wait_cycles`, one-bit
OKAY/ERROR `HRESP`, and two-cycle ERROR for unsupported `SEQ`, unsupported
sizes, or unmapped addresses. The `.ahb` subordinate alias, AHB
interconnect/decode, burst `SEQ` support, optional AHB signals, byte-lane
behavior, legacy two-bit `HRESP`, direct backend behavior,
verification-output generation, backend-language variants, AXI, APB, and VHDL
remain deferred.

`.712` audits the generated-IAL1/IAL0/SV substrate for that selected
subordinate contract. The generated path can model the core transaction flow,
but direct implementation remains deferred because reset/idle output behavior
must be reviewable in generated artifacts first. In particular, the selected
contract needs `HREADYOUT=1`, `HRESP=0`, and `HRDATA=0` at reset/idle.

The current owned implementation leaf is `.715`, selected public IAL2 AHB
subordinate `.ppif` behavior over the shipped generated-IAL1 output
default/reset substrate. `.714` proved the substrate with parser metadata,
generated `.fsm` reset/default review output, and strict SystemVerilog output
reset/default coverage. Public AHB subordinate `.ppif` behavior remains
deferred until `.715` ships it.

## Validation Used For This Chapter

This chapter was validated with:

```bash
prove -v t/1473-ial2-ahb-requester.t
prove -v t/1474-ial2-ahb-profile-alias.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --outdir /tmp/fsmgen-700-ahb-alias-out ppif/ahb_requester.ahb
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
./bin/fsmgen --quiet --output /tmp/fsmgen_ahb_lite_subordinate.sv fsm/ahb_lite_subordinate.fsm
rg -n "size_q_eq|size_q_ne|HRESP <- 1|HREADYOUT <- 1|reg_data_q <- HWDATA|HTRANS == 2'b1" /tmp/fsmgen_ahb_lite_subordinate.sv
rg -n "ppif/ahb_lite_subordinate\\.ppif|ahb-subordinate|intent\\.ppif_ahb_lite_subordinate|HREADYOUT|output default" docs/IAL2_AHB_SUBORDINATE_PUBLIC_CONTRACT_SELECTION.md docs/IAL2_AHB_SUBORDINATE_GENERATED_IAL1_SUBSTRATE_AUDIT.md docs/book/src/16c-ial2-ahb.md
prove -v t/1476-isf-output-default-reset.t
```

The `.ppif` and `.ahb` probes passed and generated `amba_requester.isf`,
`amba_requester.fsm`, and HDL module `amba_requester`. The `.ahb` checks also
confirmed profile-alias support accounting and authored alias source identity.
The direct subordinate strict check passed as
`protocol.ahb_lite_subordinate`, and the generated HDL inspection confirmed
the selected transfer, word-size, write-update, and two-cycle ERROR response
paths.
The generated-substrate audit confirmed core AHB subordinate transaction
representability, while routing generated-IAL1 output default/reset semantics
to a smaller owned substrate before public subordinate behavior ships. The
follow-on contract selector chose `(reset VALUE)` and `(default VALUE)` output
metadata, and `.714` shipped parser/lowering/strict-HDL coverage for that
substrate. Public subordinate behavior is now owned by `.715`.
