# IAL2 Post APB No-Policy Multi-Peripheral Multi-Register Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.643`
- Date: `2026-06-28`
- Status: selected
- Scope: next APB back-to-back timing residue owner after selected 32-bit
  no-policy multi-peripheral multi-register timing shipped

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.643` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.644`, public contract selection for the
bounded APB sideband-aware data16 no-policy multi-peripheral multi-register
back-to-back timing-policy family.

This selector changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Current State

The APB back-to-back timing frontier now has these selected behaviors shipped:

- fixed 32-bit no-sideband requester/completer/composition timing;
- selected 32-bit sideband requester/completer/fixed-composition timing;
- selected 32-bit sideband no-policy multi-register fixed-composition timing;
- selected 32-bit sideband protection multi-register fixed-composition timing;
- selected sideband data16 no-policy requester/completer/fixed-composition
  timing;
- selected sideband data16-protection fixed-composition timing;
- selected no-sideband two-peripheral multi-peripheral timing;
- selected 32-bit sideband two-peripheral one-register multi-peripheral
  timing;
- selected sideband data16-protection status/control two-peripheral timing;
- selected 32-bit sideband protection status/control two-peripheral timing;
- selected 32-bit sideband no-policy reg0/reg1 two-peripheral timing.

The current public samples also define the relevant uncombined data16
surfaces:

- `ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif`
  ships fixed-composition no-policy data16 timing with `reg0` at byte address
  `0`, `reg1` at byte address `2`, 16-bit data, and `PSTRB width 2`.
- `ppif/apb_composition_multi_peripheral_sideband_data16.ppif` ships the
  sideband data16 multi-peripheral topology, but each peripheral has one
  no-policy register and no back-to-back timing policy.
- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif`
  ships data16 multi-peripheral timing, but only for the selected protected
  status/control storage family.

No public sideband data16 no-policy multi-peripheral multi-register
back-to-back `.ppif` or `.apb` source exists yet.

## Selection

`.644` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.644`: select the public APB
sideband-aware data16 no-policy multi-peripheral multi-register
back-to-back timing-policy contract.

The contract-selection slice must settle the exact public sources and public
report contract before implementation. It should decide whether the selected
source pair uses a name in the
`apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back`
family, and it must define the source object, anchor section, `.apb` alias,
support-accounting identities, coverage buckets, diagnostics, validation, and
rollback boundary.

## Rationale

Sideband data16 no-policy multi-peripheral multi-register timing is now the
smallest coherent APB timing residue.

The already shipped pieces line up cleanly:

- `.625` proves the selected data16 requester queue captures and relaunches
  16-bit `PWDATA`, `PPROT`, and 2-bit `PSTRB`, and that adjacent no-policy
  two-register data16 completers decode `reg0` at address `0` and `reg1` at
  address `2`.
- `.618` and `.634` prove generated multi-peripheral interconnect propagation
  for selected sideband/data16 timing without inserting an idle cycle.
- `.642` proves the no-policy reg0/reg1 multi-peripheral multi-register
  composition shape for 32-bit data.

The remaining delta is therefore narrow: combine the selected sideband data16
no-policy reg0/reg1 endpoint shape with the selected two-peripheral
interconnect propagation contract. The current `ApbComposition` timing guard
still admits the sideband data16 multi-peripheral timing family only for the
selected sideband data16-protection status/control storage shape, and the
global back-to-back residue still names sideband data16 no-policy
multi-peripheral multi-register timing as future work.

Data16-protection generalization is not next because selected
data16-protection status/control multi-peripheral timing already shipped in
`.634`, while broader access-policy matrices and protection ownership are a
larger policy axis. Generalized multi-peripheral multi-register shapes, deeper
queues, alternate overflow policies, accepted-less requesters, and multiple
active APB transfers are also broader because they need new shape,
request-admission, or outstanding-model contracts before implementation can be
bounded.

## `.644` Contract-Selection Questions

`.644` must select the exact public APB data16 no-policy multi-peripheral
multi-register timing contract before behavior changes, including:

- exact `.ppif` and `.apb` source names, source object, and source anchor;
- whether the first owner is exactly one requester and exactly two peripheral
  completers using the status/control window topology;
- whether the selected address map reuses the current sideband data16
  multi-peripheral shape: status base `0`, control base `258`, size `258`,
  and alignment `2`;
- requester requirements: `accepted/busy/status`, 32-bit address, 16-bit
  write/read data, `PPROT width 3`, `PSTRB width 2`, depth-1 queued timing,
  and overflow `reject`;
- peripheral requirements: adjacent setup admission on every peripheral,
  exactly no-policy `reg0` at address `0` and `reg1` at address `2`, 16-bit
  register data, reset `0`, and no register-local `access-policy` clauses;
- interconnect requirements: propagation-only queued setup decode, no idle
  insertion, local-address translation by the selected window base, selected
  response muxing, active-access-only unmapped completion, and no protection
  enforcement;
- report/residue movement for aggregate `back_to_back_policy`,
  `apb_back_to_back_policy_deferred`,
  `apb_additional_back_to_back_policies_deferred`,
  `apb_protection_policy_effects_deferred`, and remaining width residue;
- diagnostics for malformed data16 no-policy multi-peripheral multi-register
  timing shapes;
- focused parser/generator/profile-alias/support/capability tests and direct
  schedule/check/semantic JSON plus generated-artifact/HDL-shape gates;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, validation,
  and rollback boundaries.

`.644` must keep data16-protection generalization, generalized register
counts/names/policies, queue depths other than `1`, overflow policies other
than `reject`, accepted-less requester surfaces, multiple active APB
transfers, bus matrices, scoreboards, direct backend lowering,
verification-output generation, backend-language variants, AXI, AHB, and VHDL
behavior deferred unless it explicitly selects a smaller prerequisite instead
of implementation.

## Validation

This selector is documentation-only. It used code/doc review plus live
schedule-report probes for representative shipped surfaces:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif
```

Closeout validation also runs Knowledge Map generation/check, mdBook build,
memory architecture, whitespace diff, and doctrine gates.

## Rollback

Rollback removes this selector document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, sample, support-accounting, schedule/check/semantic
JSON, generated-artifact, HDL/runtime, suffix, direct-backend,
verification-output, backend-language, APB, AXI, AHB, or VHDL behavior is
changed by this selector.
