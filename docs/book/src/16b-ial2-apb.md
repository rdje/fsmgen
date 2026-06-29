# APB IAL2 Examples

APB is the first broad non-AXI IAL2 protocol family in the book. It uses the
same IAL2 lowering rule as every other protocol surface:

```text
APB IAL2 source -> generated IAL1 .isf -> generated IAL0 .fsm -> HDL
```

APB interconnect and decode behavior is APB-specific generated behavior. Do
not read it as a shared AXI/AHB interconnect abstraction.

## Mode Map

| Mode | Start with | What it demonstrates |
| --- | --- | --- |
| Guided mode | `ppif/apb_requester_transfer.ppif`, `ppif/apb_completer.ppif`, and `ppif/apb_composition.ppif`, plus their selected `.apb` aliases | Requester transfer, standalone completer, fixed requester/completer composition, `.ppif`/`.apb` alias parity, and visible generated review artifacts. |
| More-control mode | Busy/status, sideband, data16, protection, multi-register, and back-to-back examples | Selected APB knobs while staying in bounded requester, completer, and composition families. |
| Raw/full-control mode | `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif` and `.apb` | A two-peripheral, six-register, sideband-aware, data16 generalized register-set composition with APB-specific address-map/decode and queued back-to-back timing. |

Raw/full-control mode is still IAL2. It does not mean raw HDL and it does not
allow direct IAL2-to-IAL0 or IAL2-to-HDL lowering.

## Guided Mode

The smallest APB requester source is `ppif/apb_requester_transfer.ppif`:

```text
(protocol-platform-intent apb_requester_transfer
  (profile apb)
  (apb-requester apb_requester
    (role requester)
    (clock clk)
    (reset (rst_n active_low async))
    (request
      (start start)
      (write req_write)
      (address req_addr width 32)
      (write-data req_wdata width 32))
    (response
      (done done)
      (read-data last_read_data width 32)
      (error last_error))
    (transfer apb_transfer
      (setup (select 1) (enable 0))
      (access (select 1) (enable 1))
      (complete-on ready)
      (sample read-data error)
      (latency (min 2) (max 16)))))
```

Run the generic `.ppif` and selected `.apb` alias:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.apb
```

The `.apb` files are profile aliases over the same IAL2 model. They keep
explicit `(profile apb)`, preserve authored `.apb` source identity, and report
`source_kind` as `ial2_profile_alias`. The generic `.ppif` files report
`source_kind` as `ppif`.

For fixed requester/completer composition, use
`ppif/apb_composition.ppif` or `ppif/apb_composition.apb`. The checked-in
source contains an `apb-requester`, an `apb-completer`, and an
`apb-composition` that wires them through the APB bus.

```bash
./bin/fsmgen --quiet --outdir generated ppif/apb_composition.ppif
```

That guided composition path writes:

```text
generated/apb_requester.isf
generated/apb_completer.isf
generated/apb_requester.fsm
generated/apb_completer.fsm
generated/apb_tb.fsm
```

The requester and completer `.isf` files are generated IAL1 review artifacts.
The requester, completer, and `apb_tb` `.fsm` files are generated IAL0 review
artifacts.

## More-Control Mode

Use more-control APB examples when the design needs explicit bus-side knobs
without leaving shipped APB families:

- requester accepted/busy/status outputs, for example
  `ppif/apb_requester_transfer_busy.ppif`;
- sideband `PPROT` and `PSTRB`, for example
  `ppif/apb_requester_transfer_sideband.ppif`;
- 16-bit APB data and 2-bit strobe width, for example
  `ppif/apb_requester_transfer_sideband_data16.ppif`;
- multi-register completers, for example
  `ppif/apb_completer_multi_register.ppif`;
- register-local protection policy, for example
  `ppif/apb_completer_multi_register_sideband_protection.ppif`;
- selected adjacent setup and back-to-back timing, for example
  `ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif`.

Useful probes are:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.apb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition.apb
```

The completer schedule report uses
`fsmgen.ial2.protocol_intent.apb_completer.v1` and records generated
`apb_completer.isf` before `apb_completer.fsm`. The composition semantic JSON
keeps the authored `.apb` source path and support-accounts
`intent.apb_profile_alias_composition` with `source_kind` set to
`ial2_profile_alias`.

## Raw/Full-Control Mode

The raw/full-control APB example for this chapter is:

```text
ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif
```

The byte-identical `.apb` profile alias is also checked in:

```text
ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.apb
```

This selected family combines:

- requester accepted, busy, status, done, read-data, and error responses;
- 16-bit `PWDATA`/`PRDATA`;
- 3-bit `PPROT` and 2-bit `PSTRB`;
- queued back-to-back timing with queue depth 1 and overflow reject;
- two generated peripheral completers, `status` and `control`;
- `reg0` through `reg5` at local byte addresses `0/2/4/6/8/10`;
- APB-specific address windows at `STATUS_BASE` and `CONTROL_BASE`;
- overlap reject, source-order decode priority, and unmapped-address error;
- adjacent setup admission in both peripheral completers.

Validate the raw/full-control `.ppif` and `.apb` forms:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.apb
```

An outdir run for the `.ppif` source writes APB-specific requester,
peripheral-completer, interconnect, and top review artifacts:

```text
generated/apb_requester.isf
generated/apb_status_regs.isf
generated/apb_control_regs.isf
generated/apb_interconnect.isf
generated/apb_requester.fsm
generated/apb_status_regs.fsm
generated/apb_control_regs.fsm
generated/apb_interconnect.fsm
generated/apb_tb.fsm
```

The `apb_interconnect` artifacts are APB-specific decode/routing artifacts.
They are not a shared protocol-neutral interconnect contract.

## Residue

The shipped APB IAL2 surface is broad but bounded. The following remain future
task-tree-owned work:

- more-than-six-register generalized families;
- more-than-two peripheral completers;
- broader protection/data-width matrices;
- bus matrices;
- scoreboards;
- direct backend behavior;
- verification-output generation;
- backend-language variants;
- AXI, AHB, and VHDL behavior.

## Validation Used For This Chapter

This chapter was validated from checked-in sources with:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.apb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition.apb
./bin/fsmgen --quiet --outdir /tmp/fsmgen-doc-apb-692-out ppif/apb_composition.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.apb
./bin/fsmgen --quiet --outdir /tmp/fsmgen-doc-apb-692-raw-out ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif
```

The temporary outdir probes confirmed both the fixed composition review
artifacts and the raw/full-control APB-specific interconnect artifacts.
