# IAL2 AHB Two-Subordinate Profile-Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.732`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.732` ships the matching bounded public AHB
two-subordinate `.ahb` profile-alias source:

```text
ppif/ahb_interconnect_two_subordinate.ahb
```

The alias mirrors the generic source:

```text
ppif/ahb_interconnect_two_subordinate.ppif
```

It uses the same `protocol-platform-intent` form, keeps explicit
`(profile ahb)`, and is still IAL2. It is not a direct backend path and does
not broaden the selected AHB topology.

Support accounting records the alias as:

```text
entry_id: intent.ahb_profile_alias_interconnect_two_subordinate
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_two_subordinate_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

## Lowering And Reports

The mandatory reviewable lowering chain remains:

```text
.ahb / IAL2
  -> generated amba_requester.isf
  -> generated ahb_status_subordinate.isf
  -> generated ahb_control_subordinate.isf
  -> generated ahb_interconnect.isf
  -> generated amba_requester.fsm
  -> generated ahb_status_subordinate.fsm
  -> generated ahb_control_subordinate.fsm
  -> generated ahb_interconnect.fsm
  -> generated ahb_tb.fsm
  -> HDL module ahb_tb
```

The report schema remains:

```text
fsmgen.ial2.protocol_intent.ahb_interconnect.v1
```

The topology remains:

```text
one_requester_two_subordinate_static_window_interconnect
```

Check JSON reports module `ahb_tb`, `composition_child_count: 4`, authored
`.ahb` source identity, and the support-accounting identity above. Semantic
JSON reports the generated composition root as `top`.

## Source Contract

The alias source contains exactly one AHB requester object, two distinct AHB
subordinate objects, and one AHB interconnect object. The interconnect
children remain:

```text
(requester requester amba_requester)
(subordinate status ahb_status_subordinate)
(subordinate control ahb_control_subordinate)
```

The selected static windows remain:

```text
status:  STATUS_BASE=0, STATUS_SIZE=4
control: CONTROL_BASE=4, CONTROL_SIZE=4
```

The alias keeps the same decode behavior as the generic `.ppif`: fixed
single-requester `HGRANT=1`, active-transfer decode when `HTRANS != IDLE`,
status-window hits drive `HSEL_STATUS` and `HADDR_STATUS = HADDR`,
control-window hits drive `HSEL_CONTROL` and `HADDR_CONTROL = HADDR - 4`,
the selected subordinate's ready/data/one-bit response is muxed back to the
requester, and unmapped active transfers produce the selected two-cycle ERROR
response.

## Residue

The `.ahb` alias reports remove:

```text
ahb_aggregate_profile_alias_deferred
```

The generic `.ppif` report keeps that residue as a source-surface distinction.
Both reports keep:

```text
ahb_broader_interconnect_decode_deferred
ahb_optional_signal_residue
ahb_burst_seq_support_deferred
ahb_direct_backend_deferred
ahb_verification_output_deferred
```

Broader AHB work remains task-tree-owned future work: more-than-two
subordinate cardinality, multiple requesters, arbitration, bus matrices,
dynamic/programmed windows, optional signals, burst continuation, byte lanes,
legacy two-bit subordinate `HRESP`, direct backend behavior,
verification-output generation, backend-language variants, AXI, APB, and VHDL.

## Validation

Focused validation for the slice:

```bash
prove -Iperl t/1481-ial2-ahb-interconnect-two-subordinate-profile-alias.t
prove -Iperl t/1480-ial2-ahb-interconnect-two-subordinate.t
prove -Iperl t/1479-ial2-ahb-interconnect-profile-alias.t
prove -Iperl t/1478-ial2-ahb-interconnect.t
prove -Iperl t/297-capability-manifest.t
prove -Iperl t/248-regression-corpus-accounting.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ahb
```
