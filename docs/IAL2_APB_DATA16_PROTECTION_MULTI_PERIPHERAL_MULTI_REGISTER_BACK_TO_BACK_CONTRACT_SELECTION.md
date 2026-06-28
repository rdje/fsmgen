# IAL2 APB Data16-Protection Multi-Peripheral Multi-Register Back-To-Back Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.648`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection only for bounded APB sideband-aware
  data16-protection multi-peripheral multi-register back-to-back timing
  behavior

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.648` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.649` to directly implement exactly two
public sources:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.apb`

The selected family combines the shipped fixed data16-protection
`reg0`/`reg1` adjacent-completer contract with the shipped data16
multi-peripheral interconnect propagation contract and the shipped no-policy
data16 multi-peripheral multi-register topology.

No parser behavior, generator behavior, public source file,
support-accounting catalog entry, validation behavior, generated artifact,
schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix
acceptance, direct backend lowering, verification-output generation,
backend-language variant, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior changes in this selector slice.

## Evidence Read

This selection read:

- `.647` data16-protection multi-peripheral multi-register readiness audit;
- `.646` post-data16 no-policy multi-peripheral multi-register selector;
- `.645/.644` data16 no-policy multi-peripheral multi-register behavior and
  contract;
- `.642/.641/.640` no-policy multi-peripheral multi-register behavior,
  contract, and readiness audit;
- `.638` protected multi-peripheral behavior;
- `.634/.633` data16-protection multi-peripheral behavior and contract;
- `.631/.630/.629` data16-protection fixed-composition behavior and contract;
- current fixed and multi-peripheral data16-protection `.ppif`/`.apb` sources
  and reports;
- ApbRequesterTransfer, ApbCompleter, ApbComposition, RegressionCorpus,
  LanguageSurfaceSection, focused APB/profile-alias/support tests, README,
  ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

The current implementation already has the selected pieces:

- sideband data16 requester queueing and relaunch for 16-bit `PWDATA`, 3-bit
  `PPROT`, and 2-bit `PSTRB`;
- fixed-composition data16-protection `reg0`/`reg1` adjacent-completer
  behavior with register-local privileged `PPROT[0]` policy;
- sideband data16 multi-peripheral windows at bases `0` and `258`, size
  `258`, and alignment `2`;
- data16 multi-peripheral interconnect propagation without idle-cycle
  insertion;
- selected no-policy data16 two-register two-peripheral source topology.

The current `ApbComposition` multi-peripheral timing guard accepts the
selected data16 no-policy `reg0`/`reg1` shape and the selected
data16-protection status/control shape. `.649` must widen only the data16
multi-peripheral compatibility guard to the selected protected `reg0`/`reg1`
two-register peripheral shape.

## Selected Public Sources

`.649` shall add exactly these public source pairs:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.apb`

The selected `.apb` profile alias must mirror the `.ppif` source and lower
through the same generated `.isf` review artifacts before generated `.fsm`
artifacts.

The selected `protocol-platform-intent` name is
`apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back`.
The selected source object is
`fsmgen-apb-composition-multi-peripheral-multi-register-sideband-data16-protection-status-back-to-back`.
The selected source anchor section is
`requester-multi-peripheral-composition-multi-register-sideband-data16-protection-status-back-to-back`.

No standalone requester, standalone completer, fixed-composition, 32-bit,
status/control protected storage, generalized register-shape, AXI, AHB, VHDL,
direct-backend, or verification-output source is selected in `.648`.

## Selected Source Contract

The selected source is intentionally narrow:

- one requester and exactly two peripheral completers;
- requester object `apb_requester`;
- peripheral objects `apb_status_regs` and `apb_control_regs`;
- generated interconnect object `apb_interconnect`;
- 32-bit APB address and address-map widths;
- 16-bit request write data, requester read data, `PWDATA`, `PRDATA`, and
  peripheral register data;
- requester request `req_prot width 3` and `req_wstrb width 2`;
- APB bus and every peripheral bus use `PPROT width 3` and `PSTRB width 2`;
- requester response fields include `accepted`, `busy`, `status width 2`,
  `done`, `last_read_data width 16`, and `last_error`;
- requester transfer policy is `(timing-policy (back-to-back queued)
  (queue-depth 1) (overflow reject))`;
- every peripheral completer transfer policy is `(timing-policy
  (setup-admission adjacent))`;
- static non-overlapping address-map/decode keeps the current sideband data16
  status/control window shape;
- the composition itself has no top-level timing-policy clause.

The selected address map is the current sideband data16 multi-peripheral
shape:

- status window base default `0`, size default `258`;
- control window base default `258`, size default `258`;
- alignment `2`;
- overlap policy `reject`;
- priority `source-order`;
- unmapped address policy `error`.

## Selected Protected Peripheral Storage

Both selected peripheral completers use the same local protected data16
two-register shape:

- `reg0` at byte address `0`, address width `32`, data width `16`, reset `0`;
- `reg1` at byte address `2`, address width `32`, data width `16`, reset `0`;
- `reg0` access policy: read allow, write require privileged `1`;
- `reg1` access policy: read require privileged `1`, write require
  privileged `1`.

The status peripheral should use unique data signal names such as
`status_reg0_data_q` and `status_reg1_data_q`. The control peripheral should
use `control_reg0_data_q` and `control_reg1_data_q`. Register names remain
local endpoint names and must stay `reg0`/`reg1`.

This slice does not select the already-shipped status/control protected
storage names (`status_reg`, `status_shadow_reg`, `control_reg`,
`control_shadow_reg`) as the explicit multi-register family. That
status/control protected topology remains owned by `.634`.

## Interconnect And Protection Contract

The generated interconnect remains propagation-only:

- decode the current `PSEL/PADDR` while `PENABLE` is low;
- fan out decoded `PSEL` to the selected status or control peripheral;
- forward `PENABLE`, `PWRITE`, 16-bit `PWDATA`, `PPROT`, and 2-bit `PSTRB`;
- translate `PADDR_CONTROL` by subtracting the selected control base `258`;
- mux selected peripheral `PREADY`, `PRDATA`, and `PSLVERR`;
- complete unmapped accesses only on active `PSEL && PENABLE` cycles;
- do not register the selected peripheral;
- do not insert an idle cycle between a completed access and the queued setup;
- do not enforce any protection policy.

Protection enforcement remains owned by each peripheral completer:

- mapped reads denied by register-local policy return zero data and
  `PSLVERR`;
- mapped writes denied by register-local policy complete with `PSLVERR` and
  no storage update;
- zero-strobe writes are successful no-byte writes when allowed and
  side-effect-free errors when denied;
- unmapped peripheral-local addresses complete with `PSLVERR`.

The outstanding model remains unchanged: at most one active APB bus transfer
and one requester-side queued next transfer.

## Report And Support Movement

Selected reports shall add aggregate `back_to_back_policy` metadata using the
existing multi-peripheral report shape, with requester, interconnect, and
every peripheral endpoint represented.

Selected reports shall preserve:

- `composition.topology = multi_peripheral_interconnect`;
- `composition.width_policy.data_width = 16`;
- `composition.width_policy.strobe_width = 2`;
- `composition.width_policy.protection_width = 3`;
- `composition.address_map.alignment_bytes = 2`;
- `children[2].transfer.registers = [reg0, reg1]`;
- `children[3].transfer.registers = [reg0, reg1]`.

Selected reports shall include peripheral-owned `protection_policy` metadata
for both selected `reg0`/`reg1` peripheral completers.

Selected top, requester, interconnect, and peripheral report surfaces shall
remove broad `apb_back_to_back_policy_deferred` residue. They shall retain
narrowed residue for:

- unselected APB timing-policy families;
- broader APB protection-policy effects;
- alternate width families beyond the selected sideband-aware 16/32-bit
  boundary.

## Validation For `.649`

`.649` must include focused validation covering:

- parser/source existence for the selected `.ppif` and `.apb` alias;
- schedule JSON aggregate `back_to_back_policy`;
- semantic/check JSON support-accounting identities;
- status/control windows at `0` and `258`;
- both peripheral completers carrying `reg0`/`reg1` at local addresses `0`
  and `2`;
- 16-bit `PWDATA/PRDATA`, `PPROT width 3`, and `PSTRB width 2`;
- queued requester relaunch of `PWDATA`, `PPROT`, and `PSTRB`;
- peripheral-owned protection metadata and no interconnect-owned predicate;
- generated review artifacts and HDL shape;
- malformed storage diagnostics for wrong `reg1` address and wrong
  protection policy;
- RegressionCorpus, LanguageSurfaceSection, capability manifest, README,
  ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map updates.

## Deferred Boundaries

`.649` must keep deferred:

- status/control protected storage generalization beyond `.634`;
- generalized register counts, names, addresses, and policy matrices;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester surfaces;
- multiple active APB transfers;
- bus matrices and scoreboards;
- direct backend lowering and verification-output generation;
- backend-language variants, AXI, AHB, and VHDL behavior.

## Validation

This selector is documentation-only. It used code/doc review plus live
schedule-report probes for existing fixed and multi-peripheral
data16-protection sources:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif
```

Closeout validation also runs Knowledge Map generation/check, mdBook build,
memory architecture, whitespace diff, and doctrine gates.

## Rollback

Rollback removes this contract-selection document, its Knowledge Map fact
card, README, ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge
Map updates. No parser, generator, sample, support-accounting,
schedule/check/semantic JSON, generated-artifact, HDL/runtime, suffix,
direct-backend, verification-output, backend-language, APB, AXI, AHB, or VHDL
behavior is changed by this selector.
