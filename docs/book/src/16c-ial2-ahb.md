# AHB Current Boundary

AHB is not a shipped IAL2 protocol surface yet. FSMGen currently has a
support-accounted direct `.fsm` AMBA requester seed:

```text
fsm/amba_requester.fsm
```

That file is useful current AHB coverage and future IAL2 source material, but
it is not a `.ppif` source, not a `.ahb` profile alias, and not generated from
IAL2. Treat it as a direct IAL0 FSMGen fixture.

## Mode Map

| Mode | Current source | Boundary |
| --- | --- | --- |
| Guided mode | `fsm/amba_requester.fsm` | Direct `.fsm` AHB requester seed, support-accounted as `protocol.amba_requester`. |
| More-control mode | The same direct `.fsm` seed | Requester knobs are authored directly as FSM signals and states, not as AHB IAL2 clauses. |
| Raw/full-control mode | Not shipped for AHB IAL2 | `.ahb`, AHB `.ppif`, generated AHB `.isf`, generated AHB `.fsm`, AHB completers, AHB interconnect/decode, scoreboards, and full-manager behavior need future task-tree leaves. |

Unlike the AXI and APB chapters, this chapter does not describe runnable AHB
IAL2 examples. There are none checked in today.

## Guided Direct FSM Seed

The direct seed models a bounded AHB requester/master with one local command
active at a time. Its source comments and state machine cover:

- arbitration through `HBUSREQ` and `HGRANT`;
- `SINGLE`, `INCR`, `INCR4`, `INCR8`, `INCR16`, `WRAP4`, `WRAP8`, and
  `WRAP16` bursts;
- `HTRANS=NONSEQ` for the first beat and `HTRANS=SEQ` for later beats;
- wait states through `HREADY`;
- `HRESP` handling for `OKAY`, `ERROR`, `RETRY`, and `SPLIT`;
- local command inputs and status outputs.

Validate the direct seed with the normal `.fsm` path:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/amba_requester.fsm
./bin/fsmgen --quiet -o generated/amba_requester.sv fsm/amba_requester.fsm
```

The strict check reports the support-accounting entry:

```text
entry_id: protocol.amba_requester
source_kind: fsm
coverage: direct_root_pipeline_cli
module_name: amba_requester
```

The generated HDL module is `amba_requester`. Its AHB-side ports include
`HGRANT`, `HREADY`, `HRESP`, `HRDATA`, `HBUSREQ`, `HLOCK`, `HADDR`, `HTRANS`,
`HWRITE`, `HSIZE`, `HBURST`, `HPROT`, and `HWDATA`. Its local command/status
ports include `cmd_valid`, `cmd_ready`, `cmd_write`, `cmd_addr`, `cmd_wdata`,
`cmd_wdata_step`, `cmd_size`, `cmd_prot`, `cmd_lock`, `cmd_burst`, `cmd_len`,
`busy`, `beat_done`, `done`, `burst_active`, `wrap_active`, `beat_index`,
`beats_remaining`, `active_addr`, `active_hburst`, `last_error`,
`last_retry`, `last_split`, `last_resp`, and `last_read_data`.

Because this is already a `.fsm` source, there is no generated IAL1 `.isf`
review artifact and no generated IAL0 `.fsm` review artifact. The authored
`.fsm` file itself is the reviewable cycle-level source.

## More-Control Direct-FSM Details

The current requester knobs are direct FSM ports and storage, not protocol
intent clauses:

- `cmd_burst` selects fixed, incrementing, or wrapping burst families;
- `cmd_len` supplies the bounded length for incrementing bursts;
- `cmd_size` selects the address step from byte through 128-byte beats;
- `cmd_prot`, `cmd_lock`, `cmd_write`, `cmd_addr`, `cmd_wdata`, and
  `cmd_wdata_step` drive the bus-side request fields;
- wrap bursts compute local wrap span, base, and high-address state before
  transfer;
- `HREADY` stalls the transfer state until a beat is accepted;
- `HRESP` records `last_error`, `last_retry`, `last_split`, and `last_resp`;
- read transfers capture `HRDATA` into `last_read_data`.

This is meaningful AHB coverage, but it is still direct FSMGen coverage. It
does not provide an AHB IAL2 report schema, AHB source anchors, AHB generated
artifact metadata, AHB profile-alias support accounting, or AHB IAL2 static
diagnostics.

## Unsupported `.ahb` Boundary

The `.ahb` suffix is known to the CLI as a future IAL2 alias candidate, but it
is not accepted today. A temporary copy of the direct seed with a `.ahb`
extension fails closed:

```bash
cp fsm/amba_requester.fsm /tmp/fsmgen-doc-ahb-693.ahb
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-doc-ahb-693.ahb
```

The expected diagnostic is:

```text
source suffix '.ahb' is a known IAL2 alias candidate but is not supported in this slice
```

That failure is the current public boundary. Do not rename the direct `.fsm`
fixture to `.ahb` and treat it as an IAL2 source.

## Future IAL2 Task-Tree Prerequisites

AHB IAL2 guided mode needs a future readiness and contract sequence before any
source is added. That sequence has to select an AHB IAL2 object vocabulary,
explicit profile policy, source anchors, generated `.isf` artifact shape,
generated `.fsm` artifact shape, report schema, support-accounting identity,
diagnostics, and validation gates.

AHB IAL2 more-control mode needs task-tree owners for mapping the direct seed's
requester controls into explicit IAL2 clauses. Those owners must settle burst,
size, protection, lock, arbitration, wait-state, response, retry/split,
status, and wrap-address behavior without bypassing generated review artifacts.

AHB IAL2 raw/full-control mode needs later owners for any subordinate/completer
shape, interconnect/decode or arbitration behavior, scoreboards, broader
manager behavior, protocol matrices, verification-output generation, direct
backend behavior, backend-language variants, and VHDL.

## Residue

The following are not shipped by the current AHB surface:

- `ppif/*ahb*` examples;
- `.ahb` profile aliases;
- `FSM::IAL2::ProtocolIntent::Ahb*` implementation modules;
- generated AHB `.isf` review artifacts;
- generated AHB `.fsm` review artifacts;
- AHB IAL2 check, schedule, or semantic JSON report families;
- AHB completer/subordinate generation;
- AHB interconnect/decode generation;
- AHB scoreboards;
- full AHB manager behavior;
- direct IAL2-to-IAL0 or IAL2-to-HDL lowering;
- verification-output generation;
- backend-language variants;
- VHDL behavior.

## Validation Used For This Chapter

This chapter was validated from checked-in and temporary boundary sources with:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/amba_requester.fsm
./bin/fsmgen --quiet -o /tmp/fsmgen-693-amba-requester.sv fsm/amba_requester.fsm
cp fsm/amba_requester.fsm /tmp/fsmgen-693-amba-requester.ahb
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-693-amba-requester.ahb
```

The first two probes passed for the direct `.fsm` seed. The `.ahb` probe failed
closed with the known unsupported IAL2 alias diagnostic, which is the expected
boundary for this slice.
