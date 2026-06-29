# IAL2 AHB Requester PPIF Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.697`

Date: 2026-06-29

## Outcome

FSMGen ships the first bounded AHB requester IAL2 source:

```text
ppif/ahb_requester.ppif
```

The source uses the generic `.ppif` suffix, declares `(profile ahb)`, and
contains exactly one `(ahb-requester amba_requester ...)` object. It lowers
through generated review artifacts before HDL:

```text
ppif/ahb_requester.ppif -> amba_requester.isf -> amba_requester.fsm -> HDL module amba_requester
```

This implements the public contract selected by
`IAL2-FEATURE-COMPLETENESS-FRONTIER.696`.

Implementation note: `IAL2-FEATURE-COMPLETENESS-FRONTIER.700` later shipped
the bounded `.ahb` profile alias for this same requester at
`ppif/ahb_requester.ahb`. This document remains the generic `.ppif` behavior
record.

## Source Shape

The checked-in source contains the selected top-level shape:

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

The object requires:

- `local-command`: `cmd_valid`, `cmd_ready`, `cmd_write`, `cmd_addr`,
  `cmd_wdata`, `cmd_wdata_step`, `cmd_size`, `cmd_prot`, `cmd_lock`,
  `cmd_burst`, and `cmd_len`;
- `local-status`: `busy`, `beat_done`, `done`, `burst_active`,
  `wrap_active`, `beat_index`, `beats_remaining`, `active_addr`,
  `active_hburst`, `last_error`, `last_retry`, `last_split`, `last_resp`, and
  `last_read_data`;
- `bus`: `HGRANT`, `HREADY`, `HRESP`, `HRDATA`, `HBUSREQ`, `HLOCK`, `HADDR`,
  `HTRANS`, `HWRITE`, `HSIZE`, `HBURST`, `HPROT`, and `HWDATA`;
- `burst`: the selected `SINGLE`, `INCR`, `WRAP4`, `INCR4`, `WRAP8`,
  `INCR8`, `WRAP16`, and `INCR16` encodings;
- `transfer`: IDLE/NONSEQ/SEQ encodings, first-beat/later-beat policy, and
  `HREADY` as the selected advance condition;
- `response`: OKAY/ERROR/RETRY/SPLIT encodings and the selected complete or
  re-request actions.

The selected widths are fixed in this slice: 32-bit address/data, 3-bit AHB
size/burst, 4-bit protection, 5-bit local length/index/count, and 2-bit
transfer/response.

## Lowering And Reports

`FSM::Adapter::IAL2::PPIF` parses `ahb-requester` objects and dispatches them
to `FSM::IAL2::ProtocolIntent::AhbRequester`.

The generator returns:

```text
layer: IAL2
kind: protocol_intent.ahb_requester
mode: requester
schema: fsmgen.ial2.protocol_intent.ahb_requester.v1
generated IAL1: amba_requester.isf
generated IAL0: amba_requester.fsm
HDL module: amba_requester
```

The report records source object anchors, target protocol/profile/object/role,
normalized clock/reset, local-command, local-status, bus, burst, transfer, and
response bindings, generated artifact metadata, and unsupported residue.
`layering.direct_ial2_to_ial0` is always false.

Generated IAL1 uses an internal completion bit:

```text
(storage
  (var ahb_request_done_q (width 1) (reset 0)))
...
(complete ahb_request_done_q)
```

The public `done` output remains a status output, not the transaction
completion pulse.

## Support Accounting

The public sample is support-accounted as:

```text
id: intent.ppif_ahb_requester
relpath: ppif/ahb_requester.ppif
family: protocol_fixture
classification: supported_smoke
coverage: ial2_ppif_ahb_requester_pipeline_cli
source_kind: ppif
strict_supported: 1
expected_module_name: amba_requester
expected_semantic_source_root_kind: fsm
```

The older direct seed keeps its existing identity:

```text
id: protocol.amba_requester
relpath: fsm/amba_requester.fsm
source_kind: fsm
coverage: direct_root_pipeline_cli
```

## Diagnostics

The parser/generator fail closed for:

- non-`ahb` profile on an `ahb-requester`;
- missing `(source ...)`;
- missing `(ahb-requester ...)`;
- duplicate `ahb-requester` objects;
- mixing `ahb-requester` with Valid-Ready, AXI manager, APB requester,
  APB completer, or APB composition objects;
- missing required `ahb-requester` blocks;
- duplicate block or field names;
- unsupported block or field names;
- malformed width bindings;
- unsupported widths outside the selected first contract;
- unsupported burst, transfer, or response encodings.

At `.697` closeout, the `.ahb` suffix remained unsupported and kept the known
profile-alias candidate diagnostic. Current FSMGen accepts the bounded
`ppif/ahb_requester.ahb` alias after `.700`.

## Residue

The generic AHB requester `.ppif` report preserves the `.697`
`ahb_profile_alias_deferred` residue for compatibility. The current `.ahb`
alias removes that stale residue from alias reports. The AHB requester `.ppif`
slice still does not implement:

- AHB completers or subordinates;
- AHB interconnect/decode, arbitration fabrics, or bus matrices;
- scoreboards;
- full AHB manager behavior beyond the bounded requester;
- direct IAL2-to-IAL0 or IAL2-to-HDL lowering;
- verification-output generation;
- backend-language variants;
- AXI, APB, or VHDL behavior.

## Validation

The slice was validated with:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm
prove -v t/1473-ial2-ahb-requester.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --outdir /tmp/fsmgen-697-ahb-out ppif/ahb_requester.ppif
./bin/fsmgen --quiet -o /tmp/fsmgen-697-ahb.sv ppif/ahb_requester.ppif
cp ppif/ahb_requester.ppif /tmp/fsmgen-697-ahb.ahb
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-697-ahb.ahb
```

The `.ppif` probes passed, support accounting matched
`intent.ppif_ahb_requester`, and the `.ahb` probe failed closed with the known
unsupported-alias diagnostic at `.697` closeout. Current `.ahb` behavior is
documented in `docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md`.
