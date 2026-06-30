# AHB IAL2 Current Boundary

FSMGen ships seven public bounded AHB IAL2 entrypoints today:

```text
ppif/ahb_requester.ppif
ppif/ahb_lite_subordinate.ppif
ppif/ahb_interconnect.ppif
ppif/ahb_interconnect_two_subordinate.ppif
ppif/ahb_requester.ahb
ppif/ahb_lite_subordinate.ahb
ppif/ahb_interconnect.ahb
```

The `.ppif` sources are generic Protocol/Platform Intent files. They cover the
bounded AHB requester, the bounded AHB-Lite/common-AHB subordinate, and the
selected one-requester/one-subordinate and one-requester/two-subordinate
static-window interconnect/decode tops.
The `.ahb` sources are bounded profile aliases over the same IAL2 model. They
use the same `protocol-platform-intent` form, keep explicit `(profile ahb)`,
and support exactly one selected endpoint object:
`(ahb-requester amba_requester ...)` or
`(ahb-subordinate ahb_lite_subordinate ...)`, or the selected aggregate
one-requester/one-subordinate interconnect shape
`(ahb-interconnect ahb_tb ...)`. The two-subordinate interconnect is currently
generic `.ppif` only; matching `.ahb` alias behavior remains deferred.

All public AHB IAL2 sources lower through generated review artifacts before
HDL:

```text
ppif/ahb_requester.ppif          -> amba_requester.isf -> amba_requester.fsm -> HDL module amba_requester
ppif/ahb_requester.ahb           -> amba_requester.isf -> amba_requester.fsm -> HDL module amba_requester
ppif/ahb_lite_subordinate.ppif   -> ahb_lite_subordinate.isf -> ahb_lite_subordinate.fsm -> HDL module ahb_lite_subordinate
ppif/ahb_lite_subordinate.ahb    -> ahb_lite_subordinate.isf -> ahb_lite_subordinate.fsm -> HDL module ahb_lite_subordinate
ppif/ahb_interconnect.ppif       -> amba_requester.isf + ahb_lite_subordinate.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_lite_subordinate.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate.ppif -> amba_requester.isf + ahb_status_subordinate.isf + ahb_control_subordinate.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_status_subordinate.fsm + ahb_control_subordinate.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect.ahb        -> amba_requester.isf + ahb_lite_subordinate.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_lite_subordinate.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
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
| Guided mode | `ppif/ahb_requester.ppif`, `ppif/ahb_lite_subordinate.ppif`, `ppif/ahb_interconnect.ppif`, `ppif/ahb_interconnect_two_subordinate.ppif`, `ppif/ahb_requester.ahb`, `ppif/ahb_lite_subordinate.ahb`, or `ppif/ahb_interconnect.ahb` | Bounded AHB requester, bounded AHB-Lite/common-AHB subordinate, selected one-requester/one-subordinate static-window AHB interconnect, selected generic one-requester/two-subordinate static-window AHB interconnect, and matching one-subordinate `.ahb` aliases. |
| More-control mode | The same bounded IAL2 sources plus direct `fsm/amba_requester.fsm` and `fsm/ahb_lite_subordinate.fsm` for cycle-level comparison | Requester knobs are exposed as `local-command`, `local-status`, `bus`, `burst`, `transfer`, and `response` clauses. Subordinate knobs are exposed as `control`, `bus`, one-register `storage`, and `transfer` clauses. Interconnect knobs are exposed as `children`, one or two static `address-map` windows, `decode`, and `wiring` clauses. |
| Raw/full-control mode | Direct `.fsm` seeds and the generated `.isf`/`.fsm` review artifacts emitted from IAL2 | AHB completer behavior, broader AHB interconnect/decode beyond the selected one-requester/one-subordinate static-window `.ppif`/`.ahb` source and selected generic one-requester/two-subordinate static-window `.ppif` source, optional signals, burst continuation, byte-lane/narrow-transfer behavior, full manager behavior, direct backend behavior, verification-output generation, backend-language variants, and VHDL remain future task-tree-owned work. |

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

## Guided PPIF Subordinate

Run the shipped generic IAL2 subordinate through the same review path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-subordinate ppif/ahb_lite_subordinate.ppif
```

The strict check reports:

```text
entry_id: intent.ppif_ahb_lite_subordinate
source_kind: ppif
coverage: ial2_ppif_ahb_lite_subordinate_pipeline_cli
module_name: ahb_lite_subordinate
```

The schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, reports target object
`ahb-subordinate`, exposes generated `ahb_lite_subordinate.isf` before
`ahb_lite_subordinate.fsm`, and records output reset/default policy:

```text
HREADYOUT: reset 1, default 1
HRESP:     reset 0, default 0
HRDATA:    reset 0, default 0
```

The generated `.isf` keeps those values as actor-level output metadata, and
the generated `.fsm` keeps them as `+size` reset metadata plus idle output
assignments.

## Guided PPIF Interconnect

Run the shipped generic one-requester/one-subordinate AHB interconnect through
the same review path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-interconnect ppif/ahb_interconnect.ppif
```

The strict check reports:

```text
entry_id: intent.ppif_ahb_interconnect
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_pipeline_cli
module_name: ahb_tb
composition_child_count: 3
```

The schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, reports target object
`ahb-interconnect`, exposes generated `amba_requester.isf`,
`ahb_lite_subordinate.isf`, and `ahb_interconnect.isf` before generated
`amba_requester.fsm`, `ahb_lite_subordinate.fsm`, `ahb_interconnect.fsm`, and
aggregate `ahb_tb.fsm`, and records HDL entry `ahb_tb`.

The selected interconnect behavior is deliberately bounded:

- one requester child named `requester`;
- one subordinate child named `regs`;
- one static address window, `REG_BASE=0` and `REG_SIZE=4`;
- fixed single-requester `HGRANT=1`;
- active transfer decode when `HTRANS != IDLE` and `HADDR` is inside the static
  window;
- decoded `HSEL_REGS` and local `HADDR_REGS = HADDR - REG_BASE` on hits;
- global `HREADY` feedback to the requester and subordinate;
- hit response/data muxing from `HREADYOUT_REGS`, `HRDATA_REGS`, and one-bit
  `HRESP_REGS`;
- requester-side `HRESP=2'b00` for subordinate OKAY and `HRESP=2'b01` for
  subordinate ERROR; and
- interconnect-owned two-cycle unmapped active-transfer ERROR.

The generated aggregate top wires the requester, interconnect, and subordinate
through `ahb_tb.fsm`; the generated HDL entry is module `ahb_tb`.

## Guided PPIF Two-Subordinate Interconnect

Run the shipped generic one-requester/two-subordinate AHB interconnect through
the same review path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-two-subordinate ppif/ahb_interconnect_two_subordinate.ppif
```

The strict check reports:

```text
entry_id: intent.ppif_ahb_interconnect_two_subordinate
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_two_subordinate_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

The schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, reports topology
`one_requester_two_subordinate_static_window_interconnect`, exposes generated
`amba_requester.isf`, `ahb_status_subordinate.isf`,
`ahb_control_subordinate.isf`, and `ahb_interconnect.isf` before generated
`amba_requester.fsm`, `ahb_status_subordinate.fsm`,
`ahb_control_subordinate.fsm`, `ahb_interconnect.fsm`, and aggregate
`ahb_tb.fsm`, and records HDL entry `ahb_tb`.

The selected two-subordinate behavior is deliberately bounded:

- one requester child named `requester`;
- two subordinate children named `status` and `control`;
- two static non-overlapping address windows, `STATUS_BASE=0`,
  `STATUS_SIZE=4`, `CONTROL_BASE=4`, and `CONTROL_SIZE=4`;
- fixed single-requester `HGRANT=1`;
- active transfer decode when `HTRANS != IDLE` and `HADDR` is inside exactly
  one static window;
- decoded `HSEL_STATUS` and zero-base local `HADDR_STATUS = HADDR` on status
  hits;
- decoded `HSEL_CONTROL` and local `HADDR_CONTROL = HADDR - CONTROL_BASE` on
  control hits;
- unselected subordinate selects low and local addresses zero;
- global `HREADY` feedback to the requester and both subordinates;
- hit response/data muxing from the selected subordinate's `HREADYOUT_*`,
  `HRDATA_*`, and one-bit `HRESP_*`; and
- interconnect-owned two-cycle unmapped active-transfer ERROR.

The two-subordinate interconnect wiring block contains only requester/global
AHB bus names. Per-subordinate select, local address, ready-out, response, and
read-data names come from each subordinate object's `(bus ...)` block. Scalar
`subordinate-select`, `subordinate-ready-out`, `subordinate-response`, and
`subordinate-read-data` wiring clauses remain required for the one-subordinate
source and are rejected for the two-subordinate source.

The generic two-subordinate `.ppif` report keeps
`ahb_aggregate_profile_alias_deferred` because a matching
`ppif/ahb_interconnect_two_subordinate.ahb` alias has not shipped. It also
replaces the old multi-subordinate residue with
`ahb_broader_interconnect_decode_deferred` to make the remaining AHB
interconnect/decode backlog explicit.

The next selected AHB owner is that exact alias:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.732` will add
`ppif/ahb_interconnect_two_subordinate.ahb` as a profile alias over the shipped
two-subordinate `.ppif` behavior. Until that implementation lands, the public
AHB surface remains the seven entrypoints listed above.

## AHB Profile Alias

Use the `.ahb` aliases when you want the source filename to advertise the AHB
profile while keeping the same IAL2 syntax and generated review artifacts.
The requester alias is:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-profile-alias ppif/ahb_requester.ahb
```

The requester `.ahb` strict check reports the authored alias path and support
identity:

```text
entry_id: intent.ahb_profile_alias_requester
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_requester_pipeline_cli
module_name: amba_requester
```

The `.ahb` schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_requester.v1`, reports target profile `ahb`,
and exposes generated `amba_requester.isf` before `amba_requester.fsm`.

The subordinate alias is:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-subordinate-profile-alias ppif/ahb_lite_subordinate.ahb
```

The subordinate `.ahb` strict check reports:

```text
entry_id: intent.ahb_profile_alias_subordinate
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_subordinate_pipeline_cli
module_name: ahb_lite_subordinate
```

The subordinate `.ahb` schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, reports target object
`ahb-subordinate`, exposes generated `ahb_lite_subordinate.isf` before
`ahb_lite_subordinate.fsm`, and removes
`ahb_subordinate_profile_alias_deferred` from the alias report while preserving
the broader AHB residue.

The aggregate interconnect alias is:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-interconnect-profile-alias ppif/ahb_interconnect.ahb
```

The aggregate `.ahb` strict check reports:

```text
entry_id: intent.ahb_profile_alias_interconnect
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_pipeline_cli
module_name: ahb_tb
composition_child_count: 3
```

The aggregate `.ahb` schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, reports target object
`ahb-interconnect`, exposes generated `amba_requester.isf`,
`ahb_lite_subordinate.isf`, and `ahb_interconnect.isf` before generated
`amba_requester.fsm`, `ahb_lite_subordinate.fsm`, `ahb_interconnect.fsm`, and
aggregate `ahb_tb.fsm`, and removes `ahb_aggregate_profile_alias_deferred`
from the alias report while preserving the broader AHB residue.

## Requester Source Shape

The public requester sources start with the selected AHB requester shape:

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

The public requester intentionally models a bounded requester rather than a
full AMBA manager. The accepted object is exactly one
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

The selected requester transfer behavior is:

- first accepted beat uses `HTRANS=NONSEQ`;
- later accepted beats use `HTRANS=SEQ`;
- transfer activity is gated by `HGRANT`;
- response advancement is gated by `HREADY`;
- `OKAY` advances or completes;
- `ERROR` completes with error status;
- `RETRY` and `SPLIT` keep the request active for re-request behavior.

## Subordinate Source Shape

The public subordinate source starts with the selected AHB-Lite/common-AHB
single-register shape:

```text
(protocol-platform-intent ahb_lite_subordinate
  (profile ahb)
  (source
    (object fsmgen-ahb-lite-subordinate)
    (anchor
      (document ARM-AMBA-AHB-IHI0033-C-2021-09)
      (section bounded-ahb-lite-subordinate)
      (page first-public-contract)))
  (ahb-subordinate ahb_lite_subordinate
    (role subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    ...))
```

The generated HDL ports are `HSEL`, `HREADY`, `HADDR`, `HTRANS`, `HWRITE`,
`HSIZE`, `HWDATA`, fixture-local `wait_cycles`, `HREADYOUT`, one-bit `HRESP`,
and `HRDATA`.

Required blocks:

- `clock` and `reset`;
- `control` with `(wait-cycles wait_cycles width 4)`;
- `bus` with the selected AHB-Lite/common-AHB signal bindings;
- `storage` with exactly one register at address `0`;
- `transfer` with selected encodings and response policy.

Selected subordinate widths are fixed in this slice: 32-bit address/write-data
/read-data/register data, 2-bit `HTRANS`, 3-bit `HSIZE`, 4-bit `wait_cycles`,
and one-bit `HRESP`. Unsupported widths, missing required blocks, duplicate
blocks, duplicate names, unsupported fields, and non-AHB profiles fail closed.

## Subordinate Behavior

The selected subordinate transaction begins only when `HSEL && HREADY` and
`HTRANS` is `NONSEQ` or `SEQ`. `IDLE` and `BUSY` are ignored by not starting
the transaction; the idle/default outputs remain:

```text
HREADYOUT = 1
HRESP     = 0
HRDATA    = 0
```

For accepted transfers, the generated `.isf` samples `HADDR`, `HWRITE`,
`HSIZE`, `HTRANS`, and `wait_cycles`, drives the data phase pending state with
`HREADYOUT=0`, waits the sampled count, then resolves the transfer:

- `NONSEQ`, word size, address `0`, and `HWRITE=1` writes `reg_data_q` from
  `HWDATA` and completes with OKAY;
- `NONSEQ`, word size, address `0`, and `HWRITE=0` drives `HRDATA` from
  `reg_data_q` and completes with OKAY;
- `SEQ` is treated as unsupported burst continuation and returns ERROR;
- unsupported sizes return ERROR;
- unmapped addresses return ERROR.

ERROR completion is the selected source-backed two-cycle policy:

```text
cycle 1: HREADYOUT = 0, HRESP = 1, HRDATA = 0
cycle 2: HREADYOUT = 1, HRESP = 1, HRDATA = 0
```

The generated behavior performs no write update on ERROR.

## Alias Diagnostics

`.ahb` is accepted only as the bounded AHB requester, subordinate, or selected
aggregate interconnect profile alias:

- missing `(profile ...)` is rejected;
- any profile other than `ahb` is rejected as a suffix/profile mismatch;
- any object other than exactly one `(ahb-requester amba_requester ...)`,
  exactly one `(ahb-subordinate ahb_lite_subordinate ...)`, or the selected
  aggregate one-requester/one-subordinate `(ahb-interconnect ahb_tb ...)`
  shape is rejected for this slice;
- mixed endpoint objects outside the selected aggregate shape are rejected;
- duplicate requester, subordinate, or interconnect objects are rejected;
- malformed AHB requester, subordinate, and interconnect fields still use the
  same focused diagnostics as the equivalent `.ppif` source.

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

The direct subordinate seed remains available for cycle-level comparison:

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

Use the direct seeds when you need to inspect explicit cycle-level state
transitions. Use the public IAL2 sources when you need source identity, source
anchors, generated `.isf` review artifacts, generated `.fsm` review artifacts,
protocol-intent reports, support accounting, and IAL2 diagnostics.

## Residue

The following are not shipped by the current AHB IAL2 surface:

- AHB completer behavior;
- broader multi-subordinate fabrics, multiple requesters/managers,
  arbitration fabrics, bus matrices, programmable/dynamic windows, and broader
  AHB interconnect/decode beyond the selected one-requester/one-subordinate
  static-window `ppif/ahb_interconnect.ppif` /
  `ppif/ahb_interconnect.ahb` source and selected generic
  one-requester/two-subordinate static-window
  `ppif/ahb_interconnect_two_subordinate.ppif` source;
- optional/property-gated AHB signals such as `HBURST`, `HPROT`, `HMASTLOCK`,
  and AHB5 additions on the subordinate side;
- burst `SEQ` continuation support in the subordinate;
- byte-lane and narrow-transfer behavior;
- legacy two-bit `HRESP` compatibility for the subordinate;
- AHB scoreboards;
- full AHB manager behavior beyond the bounded requester;
- direct IAL2-to-IAL0 or IAL2-to-HDL lowering;
- verification-output generation;
- backend-language variants;
- VHDL behavior.

The generic AHB requester `.ppif` report keeps historical `.ahb`
profile-alias residue, and the shipped requester `.ahb` alias removes that
stale residue from alias reports. The generic subordinate `.ppif` report keeps
its historical `ahb_subordinate_profile_alias_deferred` residue, and the
shipped subordinate `.ahb` alias removes that stale residue from alias reports.
The generic aggregate interconnect `.ppif` report keeps
`ahb_aggregate_profile_alias_deferred` for source-surface distinction, and the
shipped aggregate `.ahb` alias removes that stale residue from alias reports.
The generic two-subordinate aggregate `.ppif` report also keeps
`ahb_aggregate_profile_alias_deferred` because matching `.ahb` alias behavior
has not shipped, and it uses `ahb_broader_interconnect_decode_deferred` for
the remaining AHB interconnect/decode backlog.

## Validation Used For This Chapter

This chapter was validated with:

```bash
prove -v t/1473-ial2-ahb-requester.t
prove -v t/1474-ial2-ahb-profile-alias.t
prove -v t/1475-ial2-ahb-subordinate.t
prove -v t/1476-isf-output-default-reset.t
prove -v t/1477-ial2-ahb-subordinate-profile-alias.t
prove -v t/1478-ial2-ahb-interconnect.t
prove -v t/1479-ial2-ahb-interconnect-profile-alias.t
prove -v t/1480-ial2-ahb-interconnect-two-subordinate.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
```

The requester `.ppif` and `.ahb` probes passed and generated
`amba_requester.isf`, `amba_requester.fsm`, and HDL module `amba_requester`.
The subordinate `.ppif` and `.ahb` probes passed and generated
`ahb_lite_subordinate.isf`, `ahb_lite_subordinate.fsm`, and HDL module
`ahb_lite_subordinate`. The generated subordinate artifacts preserve
`HREADYOUT`/`HRESP`/`HRDATA` reset/default metadata, selected register read
and write behavior, unsupported `SEQ` routing, unsupported size/address
ERROR routing, support accounting as `intent.ppif_ahb_lite_subordinate` for
the generic source, and support accounting as
`intent.ahb_profile_alias_subordinate` for the alias source. The interconnect
`.ppif` and `.ahb` probes passed and generated `amba_requester.isf`,
`ahb_lite_subordinate.isf`, `ahb_interconnect.isf`, `amba_requester.fsm`,
`ahb_lite_subordinate.fsm`, `ahb_interconnect.fsm`, aggregate `ahb_tb.fsm`,
and HDL module `ahb_tb`, support-accounted as `intent.ppif_ahb_interconnect`
for the generic source and `intent.ahb_profile_alias_interconnect` for the
alias source.
The two-subordinate `.ppif` probe passed and generated `amba_requester.isf`,
`ahb_status_subordinate.isf`, `ahb_control_subordinate.isf`,
`ahb_interconnect.isf`, `amba_requester.fsm`, `ahb_status_subordinate.fsm`,
`ahb_control_subordinate.fsm`, `ahb_interconnect.fsm`, aggregate
`ahb_tb.fsm`, and HDL module `ahb_tb`, support-accounted as
`intent.ppif_ahb_interconnect_two_subordinate`.
