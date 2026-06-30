# IAL2 AHB Interconnect Profile-Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.726`

Date: 2026-06-29

## Outcome

FSMGen now ships the selected bounded public aggregate AHB `.ahb`
profile-alias source:

```text
ppif/ahb_interconnect.ahb
```

The alias mirrors the generic aggregate interconnect source:

```text
ppif/ahb_interconnect.ppif
```

Both sources use the same IAL2 `protocol-platform-intent` form with explicit
profile review text:

```text
(profile ahb)
(ahb-requester amba_requester ...)
(ahb-subordinate ahb_lite_subordinate ...)
(ahb-interconnect ahb_tb ...)
```

The alias does not infer the profile from the suffix, does not create a direct
backend path, and does not broaden the selected AHB topology.

## Lowering And Reports

The mandatory reviewable lowering chain remains:

```text
.ahb / IAL2
  -> generated amba_requester.isf
  -> generated ahb_lite_subordinate.isf
  -> generated ahb_interconnect.isf
  -> generated amba_requester.fsm
  -> generated ahb_lite_subordinate.fsm
  -> generated ahb_interconnect.fsm
  -> generated ahb_tb.fsm
  -> HDL module ahb_tb
```

The report schema remains:

```text
fsmgen.ial2.protocol_intent.ahb_interconnect.v1
```

Check JSON reports module `ahb_tb`, `composition_child_count: 3`, and the
authored `.ahb` source path. Semantic JSON reports the generated composition
root as `top`.

Support accounting records the alias as:

```text
entry_id: intent.ahb_profile_alias_interconnect
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_pipeline_cli
```

The generic `.ppif` interconnect sample keeps support identity
`intent.ppif_ahb_interconnect`, source kind `ppif`, and coverage
`ial2_ppif_ahb_interconnect_pipeline_cli`.

## Residue

The alias report removes stale profile-alias residue from the aggregate report
tree:

```text
ahb_aggregate_profile_alias_deferred
ahb_profile_alias_deferred
ahb_subordinate_profile_alias_deferred
```

The requester and subordinate residue ids are removed from generated child
reports because the authored aggregate source is already the public `.ahb`
profile-alias surface. The alias keeps the broader AHB residue explicit:

```text
ahb_multi_subordinate_decode_deferred
ahb_optional_signal_residue
ahb_burst_seq_support_deferred
ahb_direct_backend_deferred
ahb_verification_output_deferred
```

The generic `.ppif` interconnect report keeps
`ahb_aggregate_profile_alias_deferred` plus the generated requester and
subordinate child profile-alias residues for source-surface distinction.

## Validation

The implementation is covered by:

```bash
prove -Iperl t/1479-ial2-ahb-interconnect-profile-alias.t
prove -Iperl t/1478-ial2-ahb-interconnect.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect.ahb
```

Broader AHB work remains task-tree-owned future work: multi-subordinate
decode, multiple managers, arbitration fabrics, bus matrices, optional and
property-gated AHB signals, burst `SEQ` continuation, byte lanes, narrow
transfers, legacy two-bit subordinate `HRESP` compatibility, direct backend
lowering, verification-output generation, backend-language variants, AXI/APB
behavior, and VHDL.
