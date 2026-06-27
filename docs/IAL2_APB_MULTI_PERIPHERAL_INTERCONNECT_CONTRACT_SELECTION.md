# IAL2 APB Multi-Peripheral Interconnect/Decode Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.584`

Date: 2026-06-27

## Summary

`.584` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.585`, direct bounded
implementation of APB multi-peripheral interconnect/decode for generated APB
composition sources. This selector changes no behavior.

The selected public contract is additive. Existing one-requester/one-completer
APB composition sources remain valid and keep their current parser, generator,
report, support-accounting, and generated artifact behavior. Multi-peripheral
APB is selected as a widened `(apb-composition ...)` source form, not as a
standalone top-level `(apb-interconnect ...)` IAL2 object.

## Selected Source Shape

The first selected public sources are:

```text
ppif/apb_composition_multi_peripheral.ppif
ppif/apb_composition_multi_peripheral.apb
```

Both use explicit `(profile apb)`, one APB requester, two APB completer
peripherals, and one APB composition object. The selected shape keeps the
latest busy-plus-status requester response so the new sample does not
reintroduce requester busy/status residues.

The selected multi-peripheral composition child vocabulary is:

```text
(children
  (requester requester apb_requester)
  (peripheral status apb_status_regs)
  (peripheral control apb_control_regs))
```

Rules:

- exactly one `(requester INSTANCE OBJECT)` is required;
- two or more `(peripheral INSTANCE OBJECT)` entries are required;
- every peripheral object must reference an embedded `(apb-completer ...)`
  object;
- peripheral instance names, peripheral object names, and generated child
  artifact names must be unique; and
- the existing single-completer `(completer INSTANCE OBJECT)` form remains the
  fixed one-requester/one-completer contract and cannot be mixed with
  `(peripheral ...)` entries in this first multi-peripheral slice.

The selected address-map vocabulary is:

```text
(address-map apb_decode
  (window status
    (base STATUS_BASE width 32 default 0)
    (size STATUS_SIZE width 32 default 256))
  (window control
    (base CONTROL_BASE width 32 default 256)
    (size CONTROL_SIZE width 32 default 256)))
(decode
  (overlap reject)
  (priority source-order)
  (unmapped-address error))
```

Each `(window ...)` name must match a peripheral instance name. Each `base` and
`size` clause declares a static scalar parameter/generic-like binding with an
authored default. Defaults must be non-negative decimal integers, width 32,
4-byte aligned for bases, positive and 4-byte-sized for sizes, within the
32-bit address space, and non-overlapping. The first implementation may accept
only static integer defaults and static integer overrides; runtime expressions,
unknown symbols, negative values, zero sizes, width other than 32, and
overlapping effective windows fail closed.

Peripheral completer register addresses are local to their peripheral window.
For example, a completer register at local address `0` under a window with
base `256` is reached by requester address `256`. The generated APB
interconnect forwards local `PADDR - base` to the selected completer.

## Selected Runnable Sample

The selected `.ppif` sample should use this bounded source shape:

```text
(protocol-platform-intent apb_composition_multi_peripheral
  (profile apb)
  (source
    (object fsmgen-apb-composition-multi-peripheral)
    (anchor
      (document FSMGEN-APB-REQUESTER-CAPTURE-WORKSHEET)
      (section requester-multi-peripheral-composition)
      (page stage-1)))
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
      (busy busy)
      (status status width 2)
      (done done)
      (read-data last_read_data width 32)
      (error last_error))
    (bus
      (address PADDR width 32)
      (write PWRITE)
      (write-data PWDATA width 32)
      (select PSEL)
      (enable PENABLE)
      (ready PREADY)
      (read-data PRDATA width 32)
      (error PSLVERR))
    (transfer apb_transfer
      (setup (select 1) (enable 0))
      (access (select 1) (enable 1))
      (complete-on ready)
      (sample read-data error)
      (latency (min 2) (max 16))))
  (apb-completer apb_status_regs
    (role completer)
    (clock clk)
    (reset (rst_n active_low async))
    (control
      (wait-cycles status_wait_cycles width 4))
    (bus
      (select PSEL_STATUS)
      (enable PENABLE_STATUS)
      (write PWRITE_STATUS)
      (address PADDR_STATUS width 32)
      (write-data PWDATA_STATUS width 32)
      (ready PREADY_STATUS)
      (read-data PRDATA_STATUS width 32)
      (error PSLVERR_STATUS))
    (storage
      (register status_reg
        (address 0 width 32)
        (data status_data_q width 32 reset 0)))
    (transfer apb_complete
      (setup-detect (select 1) (enable 0))
      (wait-cycles status_wait_cycles)
      (read register)
      (write register)
      (unmapped-address error)))
  (apb-completer apb_control_regs
    (role completer)
    (clock clk)
    (reset (rst_n active_low async))
    (control
      (wait-cycles control_wait_cycles width 4))
    (bus
      (select PSEL_CONTROL)
      (enable PENABLE_CONTROL)
      (write PWRITE_CONTROL)
      (address PADDR_CONTROL width 32)
      (write-data PWDATA_CONTROL width 32)
      (ready PREADY_CONTROL)
      (read-data PRDATA_CONTROL width 32)
      (error PSLVERR_CONTROL))
    (storage
      (register control_reg
        (address 0 width 32)
        (data control_data_q width 32 reset 0)))
    (transfer apb_complete
      (setup-detect (select 1) (enable 0))
      (wait-cycles control_wait_cycles)
      (read register)
      (write register)
      (unmapped-address error)))
  (apb-composition apb_tb
    (role composition)
    (clock clk)
    (reset (rst_n active_low async))
    (children
      (requester requester apb_requester)
      (peripheral status apb_status_regs)
      (peripheral control apb_control_regs))
    (address-map apb_decode
      (window status
        (base STATUS_BASE width 32 default 0)
        (size STATUS_SIZE width 32 default 256))
      (window control
        (base CONTROL_BASE width 32 default 256)
        (size CONTROL_SIZE width 32 default 256)))
    (decode
      (overlap reject)
      (priority source-order)
      (unmapped-address error))
    (wiring apb_bus
      (select PSEL)
      (enable PENABLE)
      (write PWRITE)
      (address PADDR width 32)
      (write-data PWDATA width 32)
      (ready PREADY)
      (read-data PRDATA width 32)
      (error PSLVERR))))
```

The `.apb` profile alias mirrors the same source shape with the `.apb` suffix,
keeps explicit `(profile apb)`, preserves the authored `.apb` source path in
check and semantic JSON, and support-accounts as a profile-alias fixture.

## Selected Decode And Response Behavior

The generated APB interconnect decodes the requester address against the
effective windows in source order:

```text
hit(P) = PSEL && PADDR >= base(P) && PADDR < base(P) + size(P)
```

Defaults and static overrides must be non-overlapping, so source-order priority
is selected only for deterministic generated text, reporting, and defensive
mux ordering. It is not exposed as an overlap-resolution behavior; overlaps
are rejected.

Request fanout:

- `PSEL_<PERIPHERAL>` is asserted only for the selected hit window;
- `PENABLE`, `PWRITE`, and `PWDATA` are forwarded to each peripheral-side APB
  bus with its selected signal names;
- the selected peripheral receives local `PADDR - base(P)`; unselected
  peripherals receive `PSEL=0` and deterministic zero local address; and
- sideband and strobe signals are not generated in this slice.

Response muxing:

- when no requester transfer is active, `PREADY=0`, `PRDATA=0`, and
  `PSLVERR=0`;
- when a selected peripheral is active, requester-side `PREADY`, `PRDATA`, and
  `PSLVERR` are muxed from that peripheral;
- when requester `PSEL && PENABLE` is active and no window matches,
  requester-side `PREADY=1`, `PRDATA=0`, and `PSLVERR=1`; and
- back-to-back transfer admission and queued requester behavior remain
  deferred.

## Selected Generated Artifacts

The selected lowering chain is:

```text
.ppif/.apb APB composition source
  -> generated endpoint .isf artifacts
  -> generated apb_interconnect.isf
  -> generated endpoint .fsm artifacts
  -> generated apb_interconnect.fsm
  -> generated apb_tb.fsm
  -> HDL root apb_tb
```

The generated reusable APB interconnect review artifact is:

```text
apb_interconnect.isf
apb_interconnect.fsm
```

The generated composition top instantiates one requester child, one generated
`apb_interconnect` child, and one child per APB peripheral. For the selected
sample, the generated top contains these child modules:

```text
apb_requester
apb_interconnect
apb_status_regs
apb_control_regs
```

The generated top public interface exposes the requester request inputs,
requester busy/status/done/error/read-data outputs, shared clock/reset, and
per-peripheral wait-cycle controls. The APB bus remains internal wiring.

## Selected Reports

The report schema string remains additive:

```text
fsmgen.ial2.protocol_intent.apb_composition.v1
```

Existing one-requester/one-completer reports remain unchanged. New
multi-peripheral reports add fields under the existing composition report:

```text
composition.topology = multi_peripheral_interconnect
composition.requester = { instance_name, object_name, role }
composition.peripherals[] = [
  {
    instance_name,
    object_name,
    role,
    address_window,
    local_address_policy,
    decoded_select_signal
  }
]
composition.address_map = {
  name,
  address_width,
  windows[],
  overlap_policy,
  priority,
  unmapped_address
}
composition.response_mux = {
  ready,
  read_data,
  error,
  selected_policy,
  unmapped_policy
}
composition.generated_interconnect = {
  object_name,
  ial1_artifact,
  ial0_artifact
}
```

`composition.child_instance_count` counts generated top child instances:
requester + generated interconnect + peripherals. For the selected two
peripheral sample, it is `4`. A separate
`composition.endpoint_child_instance_count` records requester + peripherals;
for the selected sample, it is `3`.

`children[]` keeps requester child metadata first, records the generated
interconnect child second, and then lists peripheral child reports in source
order. Existing one-completer composition reports keep their current two-child
shape.

Multi-peripheral composition reports remove
`apb_interconnect_multi_peripheral_decode_deferred` from the composition
report. Endpoint requester and completer child reports keep their own residue
unless the selected endpoint behavior already removed it. Sidebands/strobes,
alternate widths, and back-to-back policy remain explicit residue.

## Selected Diagnostics

`.585` must add targeted diagnostics for:

- multi-peripheral composition with fewer than two peripherals;
- mixing the fixed `(completer ...)` child form with `(peripheral ...)`;
- duplicate requester, peripheral instance, peripheral object, window, or
  parameter names;
- peripheral child references to unknown objects or non-APB-completer objects;
- address-map windows missing for a peripheral or windows referencing unknown
  peripherals;
- base/size width other than 32, negative values, unaligned bases,
  non-positive or unaligned sizes, and base+size overflow;
- overlapping effective address windows after static defaults or static
  overrides are resolved;
- unsupported `overlap`, `priority`, or `unmapped-address` policies;
- duplicate generated bus/local signal names across requester, interconnect,
  and peripherals; and
- unsupported sideband/strobe, alternate-width, runtime-expression, or
  cross-protocol interconnect clauses.

## Selected Samples And Support Accounting

`.585` shall add:

```text
ppif/apb_composition_multi_peripheral.ppif
ppif/apb_composition_multi_peripheral.apb
```

Selected support identities:

```text
intent.ppif_apb_composition_multi_peripheral
intent.apb_profile_alias_composition_multi_peripheral
```

Selected coverage names:

```text
ial2_ppif_apb_composition_multi_peripheral_pipeline_cli
ial2_apb_profile_alias_composition_multi_peripheral_pipeline_cli
```

The expected HDL top remains `apb_tb`, and expected child modules are
`apb_requester`, `apb_interconnect`, `apb_status_regs`, and
`apb_control_regs`.

## Validation Required For `.585`

The implementation slice must include:

- syntax checks for touched parser, generator, support, and test files;
- focused APB prove coverage for profile aliases, completers, composition,
  support accounting, and capability manifest;
- direct schedule/check/semantic/outdir probes for both new public sources;
- generated artifact checks for `apb_interconnect.isf`,
  `apb_interconnect.fsm`, `apb_tb.fsm`, requester/peripheral child artifacts,
  address translation, decoded `PSEL` fanout, response muxing, and unmapped
  error response;
- diagnostics probes for every selected fail-closed boundary;
- preservation probes for existing requester-transfer, completer,
  one-requester/one-completer composition, busy/status, and multi-register APB
  samples in both `.ppif` and `.apb` forms;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, behavior
  record, support-accounting docs, and capability-surface updates; and
- doctrine closeout gates.

## Non-Goals

`.584` changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts,
schedule/check/semantic JSON, HDL/runtime behavior, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, APB
behavior, AHB behavior, or VHDL behavior.

The selected contract does not add APB side effects, byte lanes, `PPROT`,
`PSTRB`, APB4/APB5 sidebands, alternate address/data widths, back-to-back
request admission, multiple requesters, bus matrices, scoreboards, queues,
direct IAL2-to-IAL0 lowering, direct backend lowering, verification-output
generation, AXI interconnect, AHB interconnect, or VHDL behavior.

APB, AXI, and AHB remain distinct protocol-specific interconnect/decode
owners. No shared cross-protocol interconnect implementation is selected.

## Rollback

Rollback is documentation-only: revert this selector, its fact card,
task-tree frontier updates, README, ROADMAP_V2, mdBook, Memory, and generated
Knowledge Map changes. `.583` remains the completed readiness audit, and no
APB behavior changes are included in this selector.
