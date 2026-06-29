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

FSMGen also keeps the older direct `.fsm` AMBA requester seed:

```text
fsm/amba_requester.fsm
```

The direct seed remains useful cycle-level coverage, but it is not IAL2 and
does not produce generated `.isf` or generated `.fsm` review artifacts.

## Mode Map

| Mode | Current source | Boundary |
| --- | --- | --- |
| Guided mode | `ppif/ahb_requester.ppif` or `ppif/ahb_requester.ahb` | Bounded AHB requester IAL2 source. The `.ppif` entry is support-accounted as `intent.ppif_ahb_requester`; the `.ahb` alias is support-accounted as `intent.ahb_profile_alias_requester`. |
| More-control mode | The same bounded requester sources plus direct `fsm/amba_requester.fsm` for cycle-level comparison | Selected requester knobs are exposed as `local-command`, `local-status`, `bus`, `burst`, `transfer`, and `response` clauses. |
| Raw/full-control mode | Direct `fsm/amba_requester.fsm` only | AHB completers/subordinates, interconnect/decode, scoreboards, full manager behavior, direct backend behavior, verification-output generation, backend-language variants, and VHDL remain future task-tree-owned work. |

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

## Direct FSM Seed

The direct seed remains available for the lower-level `.fsm` path:

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

Use the direct seed when you need to inspect or modify explicit cycle-level
state transitions. Use `ppif/ahb_requester.ppif` or `ppif/ahb_requester.ahb`
when you need the public IAL2 source identity, source anchors, generated
`.isf` review artifact, generated `.fsm` review artifact, AHB report schema,
and IAL2 diagnostics.

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

The next selected AHB owner is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.702`, a readiness audit for AHB
completer/subordinate generation. That audit must choose whether a public
contract can be selected next or whether a lower-layer subordinate seed or
other prerequisite is needed first. The selection does not ship
completer/subordinate behavior.

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
```

The `.ppif` and `.ahb` probes passed and generated `amba_requester.isf`,
`amba_requester.fsm`, and HDL module `amba_requester`. The `.ahb` checks also
confirmed profile-alias support accounting and authored alias source identity.
