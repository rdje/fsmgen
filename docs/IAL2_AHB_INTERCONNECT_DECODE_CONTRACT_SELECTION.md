# IAL2 AHB Interconnect/Decode Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.721`

Date: 2026-06-29

## Outcome

Select the first public AHB interconnect/decode contract and route the next
slice to a generated-substrate audit.

The selected public contract is a conservative generic `.ppif` source with one
AHB requester, one AHB-Lite/common-AHB subordinate, one static address window,
and generated AHB-specific review artifacts before generated IAL0/HDL. It is
not a multi-subordinate fabric, bus matrix, multiple-manager arbiter, aggregate
`.ahb` profile alias, optional-signal expansion, burst continuation feature,
byte-lane/narrow-transfer feature, direct backend path, or verification-output
route.

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.722`, a no-behavior generated
IAL1/IAL0 substrate audit, before implementation. `.722` must verify whether
the generated substrate can cleanly express the selected interconnect contract:
single-requester grant, `HSEL` decode, static address-window hit, local address
translation, `HREADY` aggregation, requester `HRESP[1:0]` widening from
subordinate `HRESP[0]`, selected two-cycle unmapped ERROR, deterministic
defaults, generated fabric artifact, and aggregate top wiring.

## Selected Public Source

The selected first source path is:

```text
ppif/ahb_interconnect.ppif
```

The selected top-level intent name is:

```text
ahb_interconnect
```

The selected public source uses explicit profile selection and a
self-contained endpoint-plus-interconnect body:

```text
(protocol-platform-intent ahb_interconnect
  (profile ahb)
  (source
    (object fsmgen-ahb-interconnect)
    (anchor
      (document ARM-AMBA-AHB-IHI0033-C-2021-09)
      (section bounded-ahb-lite-interconnect)
      (page first-public-contract)))
  (ahb-requester amba_requester
    ...)
  (ahb-subordinate ahb_lite_subordinate
    ...)
  (ahb-interconnect ahb_tb
    (role interconnect)
    (clock clk)
    (reset (rst_n active_low async))
    (children
      (requester requester amba_requester)
      (subordinate regs ahb_lite_subordinate))
    (address-map ahb_decode
      (window regs
        (base REG_BASE width 32 default 0)
        (size REG_SIZE width 32 default 4)))
    (decode
      (overlap reject)
      (priority source-order)
      (unmapped-address error))
    (wiring ahb_bus
      (grant HGRANT)
      (request HBUSREQ)
      (ready HREADY)
      (response HRESP width 2)
      (read-data HRDATA width 32)
      (address HADDR width 32)
      (transfer HTRANS width 2)
      (write HWRITE)
      (size HSIZE width 3)
      (burst HBURST width 3)
      (protection HPROT width 4)
      (lock HLOCK)
      (write-data HWDATA width 32)
      (subordinate-select HSEL_REGS)
      (subordinate-ready-out HREADYOUT_REGS)
      (subordinate-response HRESP_REGS width 1)
      (subordinate-read-data HRDATA_REGS width 32))))
```

The endpoint objects are embedded in the same authored source. The
interconnect object references those endpoint objects by name. Cross-file
endpoint references, implicit mixed-object composition, and binding to
pre-existing generated artifacts are not selected.

## Cardinality And Address Map

The first contract requires exactly:

- one `(ahb-requester ...)` object;
- one `(ahb-subordinate ...)` object; and
- one `(ahb-interconnect ...)` object.

The selected child vocabulary is:

```text
(children
  (requester requester amba_requester)
  (subordinate regs ahb_lite_subordinate))
```

The selected address-map vocabulary is:

```text
(address-map ahb_decode
  (window regs
    (base REG_BASE width 32 default 0)
    (size REG_SIZE width 32 default 4)))
(decode
  (overlap reject)
  (priority source-order)
  (unmapped-address error))
```

Rules:

- the one window name must match the subordinate instance name;
- `base` and `size` are static scalar parameter/generic-like bindings with
  authored defaults;
- defaults must be non-negative decimal integers, width 32, 4-byte aligned for
  bases, positive and 4-byte-sized for sizes, within the 32-bit address space;
- runtime expressions, unknown symbols, negative values, zero sizes, width
  other than 32, and non-static defaults fail closed; and
- local subordinate address is `HADDR - base` when the window hits.

`overlap reject` and `priority source-order` are selected for future
compatibility with multi-subordinate decode and deterministic reporting. With
one window, overlap cannot occur in the selected first behavior.

## Selected Decode And Response Policy

The selected first decode policy is:

```text
active_transfer = HTRANS != IDLE
hit(regs) = active_transfer && HADDR >= REG_BASE && HADDR < REG_BASE + REG_SIZE
HSEL_REGS = hit(regs)
local_HADDR_REGS = hit(regs) ? HADDR - REG_BASE : 0
```

`BUSY` transfers may assert `HSEL_REGS`; the selected subordinate already
ignores BUSY with zero-wait OKAY. `SEQ` remains unsupported by the subordinate
and returns the selected ERROR behavior. This contract does not add burst
continuation.

The selected single-requester grant policy is:

```text
HGRANT = 1
```

`HBUSREQ` remains observable/reportable but does not drive arbitration in this
first contract. Multiple requesters and arbitration fabrics remain future work.

The selected ready/response path is:

- selected subordinate hit: requester `HREADY` follows `HREADYOUT_REGS`;
- selected subordinate hit: requester `HRDATA` follows `HRDATA_REGS`;
- selected subordinate `HRESP_REGS=0` maps to requester `HRESP=2'b00` OKAY;
- selected subordinate `HRESP_REGS=1` maps to requester `HRESP=2'b01` ERROR;
- interconnect never generates RETRY or SPLIT;
- inactive/no-transfer default is `HREADY=1`, `HRESP=2'b00`, `HRDATA=0`; and
- unmapped active transfer is an interconnect-owned two-cycle ERROR:
  first `HREADY=0, HRESP=2'b01, HRDATA=0`, then
  `HREADY=1, HRESP=2'b01, HRDATA=0`.

The subordinate receives global `HREADY`, not an independent endpoint-local
ready signal.

## Generated Artifact Contract

The selected generated review chain is:

```text
ppif/ahb_interconnect.ppif
  -> amba_requester.isf
  -> amba_requester.fsm
  -> ahb_lite_subordinate.isf
  -> ahb_lite_subordinate.fsm
  -> ahb_interconnect.isf
  -> ahb_interconnect.fsm
  -> ahb_tb.fsm
  -> HDL module ahb_tb
```

`ahb_interconnect.isf` and `ahb_interconnect.fsm` are the selected AHB-specific
fabric review artifacts. `ahb_tb.fsm` is the generated aggregate top that wires
the generated requester, interconnect, and subordinate artifacts.

The next substrate audit must decide whether the current generated-IAL1/IAL0
pipeline can express this chain directly or whether another lower-layer
prerequisite is required before implementation.

## Report And Support Accounting

The selected report contract is:

```text
schema: fsmgen.ial2.protocol_intent.ahb_interconnect.v1
mode: requester-subordinate-interconnect
target_protocol.profile: ahb
target_protocol.object: ahb-interconnect
target_protocol.role: interconnect
generated_artifacts.ial1: amba_requester.isf, ahb_lite_subordinate.isf, ahb_interconnect.isf
generated_artifacts.ial0: amba_requester.fsm, ahb_lite_subordinate.fsm, ahb_interconnect.fsm, ahb_tb.fsm
hdl_entry: ahb_tb
```

The selected support-accounting identity is:

```text
id: intent.ppif_ahb_interconnect
relpath: ppif/ahb_interconnect.ppif
family: protocol_fixture
classification: supported_smoke
coverage: ial2_ppif_ahb_interconnect_pipeline_cli
source_kind: ppif
strict_supported: 1
expected_module_name: ahb_tb
expected_semantic_source_root_kind: fsm
```

The selected focused test file is:

```text
t/1478-ial2-ahb-interconnect.t
```

Capability-manifest wording should describe bounded AHB requester, subordinate,
and first one-window interconnect/decode `.ppif` coverage, while `.ahb`
aggregate alias support remains deferred.

## Diagnostics And Residue

The implementation owner must fail closed for:

- missing requester, subordinate, or interconnect object;
- duplicate requester/subordinate/interconnect objects;
- mixed endpoint objects without an interconnect object;
- unknown child references;
- child roles that do not match the referenced object;
- missing or malformed `address-map`;
- window name that does not match the subordinate instance;
- malformed `base` or `size`;
- unaligned base or size;
- unsupported width;
- runtime expression defaults;
- unsupported multiple subordinate windows in this first contract;
- unsupported multiple requesters or bus matrix/arbitration fabric;
- unsupported optional/property-gated AHB signals;
- unsupported burst `SEQ` continuation beyond existing endpoint ERROR;
- unsupported byte-lane/narrow-transfer behavior;
- unsupported legacy two-bit subordinate `HRESP`;
- `.ahb` aggregate alias input; and
- direct backend, verification-output, backend-language variants, AXI, APB, or
  VHDL requests.

The canonical interconnect residue key for new AHB interconnect/decode reports
is:

```text
ahb_interconnect_decode_deferred
```

Existing requester and subordinate endpoint reports may preserve their current
historical residue keys until a behavior or cleanup owner explicitly migrates
them with preservation tests. The new interconnect report should not carry
`ahb_interconnect_decode_deferred` for the selected one-window behavior, but it
must still carry residue for multi-subordinate fabric, optional signals, burst
continuation, byte lanes/narrow transfers, direct backend, verification-output,
backend-language variants, AXI, APB, and VHDL.

## Selected `.722` Scope

`.722` should audit the generated-IAL1/IAL0/SV substrate for the selected AHB
interconnect contract before implementation. It should verify, without changing
tracked behavior, whether generated artifacts can faithfully express:

- constant `HGRANT=1`;
- active-transfer and static-window hit detection;
- local address subtraction;
- `HSEL` fanout;
- global `HREADY` feedback to requester and subordinate;
- `HREADYOUT` muxing and inactive defaults;
- one-bit subordinate `HRESP` to two-bit requester `HRESP` mapping;
- interconnect-owned two-cycle unmapped ERROR;
- generated fabric and aggregate-top artifacts;
- child instance wiring and generated HDL entry; and
- report/support-accounting/source-identity preservation.

`.722` must choose whether the next owner after substrate audit is direct
implementation or a smaller substrate repair.

## Non-Changes

`.721` is a contract-selection slice only. It does not change parser,
generator, source sample, support-accounting catalog, capability manifest
behavior, focused test behavior, schedule/check/semantic JSON behavior,
generated artifact, HDL/runtime behavior, direct backend behavior,
verification-output generation, backend-language variant, AXI, APB, broader AHB
behavior, or VHDL behavior.
