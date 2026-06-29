# IAL2 AHB Two-Subordinate Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.729`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.729` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.730`, direct implementation of the first
bounded public generic `.ppif` AHB two-subordinate interconnect/decode source.

The selected future source is:

```text
ppif/ahb_interconnect_two_subordinate.ppif
```

The matching `.ahb` profile alias is deliberately not part of `.730`. The
first implementation should land the generic `.ppif` behavior, report shape,
support accounting, diagnostics, tests, and docs first. A later exact selector
can choose a matching `.ahb` alias after the generic behavior is proven.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Selected Source Shape

The selected source keeps the existing aggregate AHB object model and widens
only subordinate cardinality:

```text
(protocol-platform-intent ahb_interconnect_two_subordinate
  (profile ahb)
  (source
    (object fsmgen-ahb-interconnect-two-subordinate)
    ...)
  (ahb-requester amba_requester ...)
  (ahb-subordinate ahb_status_subordinate ...)
  (ahb-subordinate ahb_control_subordinate ...)
  (ahb-interconnect ahb_tb
    (role interconnect)
    (clock clk)
    (reset (rst_n active_low async))
    (children
      (requester requester amba_requester)
      (subordinate status ahb_status_subordinate)
      (subordinate control ahb_control_subordinate))
    (address-map ahb_decode
      (window status
        (base STATUS_BASE width 32 default 0)
        (size STATUS_SIZE width 32 default 4))
      (window control
        (base CONTROL_BASE width 32 default 4)
        (size CONTROL_SIZE width 32 default 4)))
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
      (write-data HWDATA width 32))))
```

The first widening is exactly two subordinate endpoints. It is not a
two-or-more public guarantee yet, even though the implementation may choose
list-shaped internals that make future cardinality widening easier.

## Cardinality And Validation Contract

`.730` must accept exactly:

- one `ahb-requester` object;
- two `ahb-subordinate` objects with distinct object names;
- one `ahb-interconnect` object;
- one requester child binding;
- exactly two subordinate child bindings;
- exactly two address-map windows; and
- one static address-map window per subordinate child instance.

The first selected window defaults are:

```text
STATUS_BASE = 0
STATUS_SIZE = 4
CONTROL_BASE = 4
CONTROL_SIZE = 4
```

All address-map base and size defaults remain static 32-bit values. Base and
size must be 4-byte aligned, size must be positive, windows must not overlap,
and every subordinate child must have exactly one matching window. Source
order defines decode priority, but non-overlap rejection makes that priority
observable only as report metadata in the selected first behavior.

The implementation must fail closed for duplicate subordinate object names,
duplicate subordinate child instances, duplicate child object references,
unknown child object references, unreferenced subordinate objects, duplicate
windows, missing windows, windows that do not match subordinate child
instances, overlapping windows, misaligned windows, duplicate address-map
parameter names, non-AHB profiles, multiple requesters, multiple
interconnects, and attempts to mix this two-subordinate aggregate with APB,
AXI, valid-ready, or unrelated IAL2 objects.

## Per-Subordinate Wiring Contract

The selected two-subordinate `(wiring ...)` block contains only the requester
and global AHB bus names. It intentionally omits the singular
`subordinate-select`, `subordinate-ready-out`, `subordinate-response`, and
`subordinate-read-data` clauses used by the one-subordinate source.

Per-subordinate select, local address, ready-out, response, and read-data
names come from each embedded subordinate object's `(bus ...)` block. The
interconnect implementation must validate that:

- each subordinate `ready-in` matches the global `HREADY`;
- each subordinate `transfer`, `write`, `size`, and `write-data` binding
  matches the requester/global bus;
- each subordinate local address is 32 bits;
- each subordinate response is one bit in this slice;
- each subordinate read data is 32 bits; and
- subordinate select, local address, ready-out, response, and read-data names
  are unique enough to avoid top-level and generated-artifact collisions.

The one-subordinate `ppif/ahb_interconnect.ppif` and
`ppif/ahb_interconnect.ahb` contracts keep their existing scalar
`subordinate-*` wiring shape unchanged.

## Generated Behavior Contract

The selected generated behavior remains single-requester and fixed-grant:

```text
HGRANT = 1
active_transfer = HTRANS != 2'b00
```

For each subordinate window, the generated interconnect must:

- decode `active_transfer && HADDR` inside that static window;
- assert only the selected subordinate's `HSEL_*`;
- drive that subordinate's local address as `HADDR - window_base`;
- drive unselected subordinate selects low and local addresses to zero;
- pass requester `HTRANS`, `HWRITE`, `HSIZE`, and `HWDATA` to both
  subordinates through the aggregate top;
- feed global `HREADY` to both subordinate `ready-in` ports;
- mux selected `HREADYOUT_*`, `HRDATA_*`, and one-bit `HRESP_*` back to the
  requester; and
- map one-bit subordinate OKAY/ERROR to requester `HRESP=2'b00/2'b01`.

Unmapped active transfers remain interconnect-owned two-cycle ERROR responses:

```text
cycle 1: HREADY = 0, HRESP = 2'b01, HRDATA = 0
cycle 2: HREADY = 1, HRESP = 2'b01, HRDATA = 0
```

No RETRY, SPLIT, burst continuation, arbitration, bus matrix, programmable
decode, byte-lane, narrow-transfer, optional-signal, direct-backend, or
verification-output behavior is selected.

## Generated Artifacts

`.730` must emit generated IAL1 review artifacts before generated IAL0:

```text
amba_requester.isf
ahb_status_subordinate.isf
ahb_control_subordinate.isf
ahb_interconnect.isf
```

Generated IAL0 artifacts:

```text
amba_requester.fsm
ahb_status_subordinate.fsm
ahb_control_subordinate.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The HDL entry remains:

```text
ahb_tb
```

The aggregate top must instantiate requester, generated interconnect, status
subordinate, and control subordinate children. Generated instance names must
remain deterministic and collision-avoiding. Authored child instance names
must remain visible in reports even when generated instance names are adjusted
to avoid top-port collisions.

## Reports And Support Accounting

The selected report schema remains:

```text
fsmgen.ial2.protocol_intent.ahb_interconnect.v1
```

The selected topology is:

```text
one_requester_two_subordinate_static_window_interconnect
```

Check JSON should report:

```text
module_name: ahb_tb
composition_child_count: 4
```

The selected support-accounting identity is:

```text
entry_id: intent.ppif_ahb_interconnect_two_subordinate
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_two_subordinate_pipeline_cli
```

The new source report must remove or narrow the old
`ahb_multi_subordinate_decode_deferred` residue for that source. Broader AHB
interconnect work remains explicit under a new narrowed residue such as:

```text
ahb_broader_interconnect_decode_deferred
```

The exact narrowed residue detail should state that the first two-subordinate
static-window interconnect/decode source ships, while broader subordinate
cardinality, multiple requesters, arbitration, bus matrices, programmable or
dynamic windows, optional AHB signals, burst continuation, byte lanes, direct
backend, verification-output, backend-language variants, AXI/APB behavior, and
VHDL remain future work.

## Validation Contract

`.730` must add focused coverage, expected to use the next AHB-focused test
file:

```text
t/1480-ial2-ahb-interconnect-two-subordinate.t
```

Minimum validation:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1480-ial2-ahb-interconnect-two-subordinate.t
prove -Iperl t/1480-ial2-ahb-interconnect-two-subordinate.t
prove -Iperl t/1478-ial2-ahb-interconnect.t
prove -Iperl t/1479-ial2-ahb-interconnect-profile-alias.t
prove -Iperl t/297-capability-manifest.t
scripts/run_with_ram_guard.sh prove -Iperl t/248-regression-corpus-accounting.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate.ppif
```

The focused test must cover source parsing, generated IAL1/IAL0 artifact names,
decoded select/local-address behavior for both subordinate windows, response
muxing, unmapped two-cycle ERROR, aggregate top wiring, support accounting,
schedule/check/semantic JSON, outdir artifacts, and malformed-source
diagnostics.

## Rollback

Rollback of `.730` must remove the new public source, parser/generator support
for the two-subordinate aggregate shape, generated list-shaped AHB
interconnect behavior, support-accounting entry, focused tests, behavior docs,
Knowledge Map fact card, and README/ROADMAP/mdBook/task-tree/MEMORY updates.
Existing AHB requester, subordinate, one-subordinate interconnect `.ppif`, and
all shipped `.ahb` alias behavior must remain intact.
