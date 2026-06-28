# IAL2 Post APB Data16 Generalized Multi-Peripheral Multi-Register Cardinality Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.676`
- Date: `2026-06-28`
- Status: selected
- Scope: no-behavior next-owner selection after bounded APB data16 no-policy
  five-register generalized timing shipped

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.676` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.677`, public contract selection for the
bounded APB sideband-aware 32-bit protected five-register generalized
`reg0..regN` register-set multi-peripheral back-to-back timing family.

The next slice is a contract-selection slice, not an implementation slice.
It must settle exact source names, object id, anchor, selected policy matrix,
report/support identities, validation, rollback, and the implementation owner
before any parser, generator, sample, test, generated-artifact, HDL/runtime,
or APB transaction behavior changes.

This selector changes no parser behavior, generator behavior, public source
file, support-accounting catalog entry, report behavior, validation behavior,
generated artifact, schedule/check/semantic JSON behavior, HDL/runtime
behavior, suffix acceptance, direct backend lowering, verification-output
generation, backend-language variant, APB transaction behavior, AXI behavior,
AHB behavior, or VHDL behavior.

## Evidence Read

This selector read `.675` data16 no-policy five-register behavior, `.674`
contract, `.673` selector, `.672` 32-bit no-policy five-register behavior,
`.671` contract, `.670` cardinality readiness audit, `.668` data16 protected
generalized behavior, `.665` 32-bit protected generalized behavior, `.662`
data16 no-policy generalized behavior, current `ApbCompleter` and
`ApbComposition` generalized cardinality predicates and residue,
`RegressionCorpus`, `LanguageSurfaceSection`, focused APB/profile-alias/support
surfaces, README, ROADMAP_V2, mdBook, Memory, Knowledge Map, and relevant
decisions.

The shipped state is now:

- 32-bit no-policy generalized timing supports two, three, four, or five
  registers per peripheral;
- data16 no-policy generalized timing supports two, three, four, or five
  registers per peripheral;
- 32-bit protected generalized timing still supports two, three, or four
  registers per peripheral;
- data16 protected generalized timing still supports two, three, or four
  registers per peripheral;
- all selected generalized timing families remain bounded to exactly two
  peripheral completers.

## Why Protected 32-Bit Next

The 32-bit protected five-register family is the nearest remaining APB
cardinality sibling after `.675`.

Selecting it next keeps data16 stride and 2-bit strobe details out of the
first protected cardinality widening. The existing 32-bit protected
generalized family already defines the access-policy matrix, protected
peripheral enforcement owner, 4-byte register spacing, 4-bit `PSTRB`, status
and control windows at `0` and `256`, and propagation-only interconnect
behavior. What remains is a public five-register contract for widening the
protected generalized cardinality bound from `maximum_count = 4` to
`maximum_count = 5`.

## Selected Contract Owner

`.677` shall choose the exact public contract for the bounded APB
sideband-aware 32-bit protected five-register generalized register-set
multi-peripheral family.

The expected public source family is:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.apb`

The selected contract must explicitly decide or confirm:

- protocol-platform-intent name;
- source object id and anchor section;
- one requester and exactly two peripheral completers;
- 32-bit APB address, data, and register width;
- `PPROT width 3` and `PSTRB width 4`;
- status/control windows at bases `0` and `256`;
- queue-depth `1`, overflow `reject`, and adjacent setup admission;
- propagation-only interconnect decode with no interconnect-owned protection
  predicate;
- five-register representative `reg0/reg1/reg2/reg3/reg4` at local byte
  addresses `0/4/8/12/16`;
- whether the selected 32-bit protected generalized family widens to
  `maximum_count = 5`;
- protected access-policy matrix for every selected `reg0..regN`;
- report fields, residue movement, support-accounting identities, capability
  buckets, diagnostics, validation probes, rollback, docs, Knowledge Map, and
  next owner.

The expected protected policy matrix is inherited from the shipped protected
generalized family unless `.677` records a narrower reason to change it:

- `reg0` read: allow;
- `reg0` write: require privileged `PPROT[0] == 1`;
- every `regN` where `N >= 1` read: require privileged `PPROT[0] == 1`;
- every `regN` where `N >= 1` write: require privileged `PPROT[0] == 1`.

## Deferred Boundaries

This selector does not select implementation. It deliberately leaves these
boundaries to future exact owners:

- direct `.677` behavior implementation until the contract is committed;
- data16 protected five-register generalized register sets;
- more than five registers;
- more than two peripheral completers;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- alternate protection-policy matrices;
- interconnect-owned protection predicates;
- bus matrices or scoreboards;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, and VHDL behavior.

## Validation

This no-behavior selector is validated with documentation/continuity gates:

- Knowledge Map generation/check;
- mdBook build;
- docs path audit;
- memory architecture check;
- whitespace diff check;
- fact-card reverify search;
- `scripts/check_doctrines.sh`.

No parser, generator, source, support-accounting, report, generated artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior changes are part of
this selector.

## Rollback

Rollback removes this selector document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, public source, support-accounting, generated artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior changes are part of
this selector.
