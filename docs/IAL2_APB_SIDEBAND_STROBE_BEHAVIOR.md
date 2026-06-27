# IAL2 APB Sideband/Strobe Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.589`

Date: 2026-06-27

## Outcome

FSMGen now ships bounded APB `PPROT`/`PSTRB` sideband and byte-lane strobe
behavior for generated APB IAL2 sources:

```text
ppif/apb_requester_transfer_sideband.ppif
ppif/apb_requester_transfer_sideband.apb
ppif/apb_completer_multi_register_sideband.ppif
ppif/apb_completer_multi_register_sideband.apb
ppif/apb_composition_multi_register_sideband.ppif
ppif/apb_composition_multi_register_sideband.apb
ppif/apb_composition_multi_peripheral_sideband.ppif
ppif/apb_composition_multi_peripheral_sideband.apb
```

Existing APB sources without sideband clauses remain valid and keep their
previous generated artifacts and broad sideband/strobe deferred residue.

## Source Shape

The bounded source syntax adds requester-side sideband inputs:

```lisp
(request
  (start start)
  (write req_write)
  (address req_addr width 32)
  (write-data req_wdata width 32)
  (protection req_prot width 3)
  (write-strobe req_wstrb width 4))
```

Requester, completer, and composition bus/wiring blocks add the APB-side
signals:

```lisp
(protection PPROT width 3)
(strobe PSTRB width 4)
```

The first slice is fixed-width: address, write data, and read data remain
32-bit APB; `PPROT` width must be 3; `PSTRB` width must be 4.

## Generated Behavior

Requester lowering samples `req_prot` and `req_wstrb` with the existing
request fields, drives `PPROT` from the sampled protection value, and drives
`PSTRB` as:

```lisp
(& wstrb (concat is_write is_write is_write is_write))
```

That makes read transfers drive `PSTRB=0` and write transfers drive the
sampled strobe. The terminal phase clears `PPROT` and `PSTRB` with the other
APB request controls.

Completer lowering samples `PPROT` and `PSTRB` during APB setup detection
(`PSEL && !PENABLE`). For mapped writes, `PSTRB` controls little-endian byte
lanes:

```text
PSTRB[0] -> PWDATA[7:0]
PSTRB[1] -> PWDATA[15:8]
PSTRB[2] -> PWDATA[23:16]
PSTRB[3] -> PWDATA[31:24]
```

Unselected bytes preserve the previous register value. `PSTRB=4'b0000` is a
successful no-byte write when the address hits a selected register. Reads
ignore `PSTRB`. `PPROT` is sampled and propagated, but protection
access-control effects are not implemented in this slice.

Fixed one-requester/one-completer composition wires requester `PPROT/PSTRB` to
the completer. Multi-peripheral composition wires requester `PPROT/PSTRB` into
the generated APB interconnect and fans them out to each peripheral-side bus
while preserving the existing decoded `PSEL`, local address translation,
response mux, and unmapped active-access error behavior.

## Reports And Support

The new support-accounting identities are:

```text
intent.ppif_apb_requester_transfer_sideband
intent.apb_profile_alias_requester_transfer_sideband
intent.ppif_apb_completer_multi_register_sideband
intent.apb_profile_alias_completer_multi_register_sideband
intent.ppif_apb_composition_multi_register_sideband
intent.apb_profile_alias_composition_multi_register_sideband
intent.ppif_apb_composition_multi_peripheral_sideband
intent.apb_profile_alias_composition_multi_peripheral_sideband
```

Sideband-aware reports replace `apb_protection_and_strobes_deferred` with
`apb_protection_policy_effects_deferred`. Alternate APB widths and back-to-back
transfer policy remain deferred.

## CLI Examples

Emit schedule JSON for the sideband requester:

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_requester_transfer_sideband.ppif
```

Run strict check JSON for the `.apb` sideband completer alias:

```bash
./bin/fsmgen --strict --check --json ppif/apb_completer_multi_register_sideband.apb
```

Generate review artifacts and HDL for the sideband multi-peripheral
composition:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-sideband-multi \
  --output /tmp/fsmgen-apb-sideband-multi/apb_tb.sv \
  ppif/apb_composition_multi_peripheral_sideband.ppif
```

## Non-Goals

This slice does not add alternate APB address/data widths, runtime-selected
strobe widths, APB protection access-control effects, register side effects
beyond byte-lane writes, back-to-back transfer admission, multiple requesters,
bus matrices, scoreboards, queues, direct IAL2-to-IAL0 lowering, direct backend
lowering, verification-output generation, backend-language variants, AXI
behavior, AHB behavior, or VHDL behavior.

## Validation

Focused validation for the behavior passed:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
perl -Iperl -c t/1470-ial2-apb-profile-alias.t
perl -Iperl -c t/1471-ial2-apb-completer.t
perl -Iperl -c t/1472-ial2-apb-composition.t
prove -Iperl t/1470-ial2-apb-profile-alias.t \
  t/1471-ial2-apb-completer.t \
  t/1472-ial2-apb-composition.t \
  t/248-regression-corpus-accounting.t \
  t/297-capability-manifest.t
```

Direct schedule/outdir probes passed for the new `.ppif` sideband samples.

A later RAM-guarded closeout rerun of the same focused `prove` command stopped
at the 88% host-memory cutoff after `t/1470` and `t/1471` passed. It was not
rerun unguarded.

## Rollback

Rollback of `.589` removes the eight sideband sample files, parser support for
the sideband clauses, APB requester/completer/composition sideband lowering,
the eight support-accounting entries, focused tests, this behavior record, its
Knowledge Map fact card, the regression corpus doc sync, and the
README/ROADMAP/mdBook/task-tree/memory updates. Earlier APB requester,
completer, composition, `.apb`, busy/status, multi-register, and
multi-peripheral behavior remains owned by previous slices.
