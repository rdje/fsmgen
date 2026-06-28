# IAL2 Post APB Protection Generalized Multi-Peripheral Multi-Register Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.666`
- Date: `2026-06-28`
- Status: selected
- Scope: next APB timing/register-set residue owner after selected 32-bit
  protected generalized register-set timing shipped

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.666` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.667`, public contract selection for the
bounded APB sideband-aware data16 protected generalized `reg0..regN`
register-set multi-peripheral back-to-back timing family.

This selector changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Evidence Read

This selector read the `.665` 32-bit protected generalized behavior, `.664`
contract, `.663` selector, `.662` data16 no-policy generalized behavior,
`.660` 32-bit no-policy generalized behavior, `.656` protected `reg0`/`reg1`
behavior, shipped 16/32-bit no-policy/protection/status-control
multi-peripheral records, current `ApbCompleter` and `ApbComposition`
guards/residue, `RegressionCorpus`, `LanguageSurfaceSection`, focused
APB/profile-alias/support surfaces, README, ROADMAP_V2, mdBook, Memory,
Knowledge Map, and relevant decisions.

## Current State

The generalized APB register-set timing surface now covers:

- 32-bit no-policy `reg0..regN` register sets (`.660`);
- data16 no-policy `reg0..regN` register sets (`.662`);
- 32-bit protected `reg0..regN` register sets (`.665`).

The protected APB data16 timing surface remains exact-family based:

- exact data16 protected `reg0`/`reg1` timing is shipped;
- exact data16 status/control protected-storage timing is shipped;
- the live guards explicitly keep data16 protected generalized register sets
  deferred after `.665`.

The live `ApbCompleter` adjacent-setup guard now admits selected 32-bit
protected generalized `reg0..regN` completers but still admits data16
protected timing only for the selected two-register and status/control
families. The live `ApbComposition` multi-peripheral timing guard mirrors that
boundary.

## Selection

`.667` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.667`: select the bounded APB
sideband-aware data16 protected generalized register-set multi-peripheral
back-to-back public contract before implementation.

`.667` must settle the public contract before any behavior change:

- exact public `.ppif`/`.apb` source names, object id, and source anchor;
- one-requester/exactly-two-peripheral scope;
- 16-bit APB/register data, `PSTRB width 2`, and `PPROT width 3`;
- sideband data16 address-map shape with status/control windows at `0` and
  `258`;
- queue-depth `1`, overflow `reject`, adjacent setup on every peripheral,
  propagation-only interconnect decode, and no interconnect-owned protection
  predicate;
- register cardinality bounded to two, three, or four source-ordered
  registers;
- local byte addresses `0`, `2`, ..., `2*N`;
- reset values, data-signal uniqueness, and per-peripheral consistency;
- the data16 protected access-policy matrix for every selected `reg0..regN`
  register;
- report shape, support-accounting identities, capability buckets,
  diagnostics, validation probes, rollback, README, ROADMAP_V2, mdBook, task
  tree, Memory, Knowledge Map, and next owner.

## Rationale

Data16 protected generalized register sets are the smallest coherent APB
timing/register-set residue after `.665`.

The project has now shipped the generalized no-policy shape for both selected
widths and the protected generalized shape for 32-bit. The remaining
policy-bearing alternate-width gap is data16 protected generalized
`reg0..regN`. Selecting a public contract first keeps width/stride/strobe
rules separate from implementation and prevents the data16 timing guard from
quietly inheriting a policy matrix without a documented source/report
contract.

## Deferred Boundaries

This selector does not select implementation for:

- broader register cardinality beyond the future `.667` contract;
- more than two peripheral completers;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- interconnect-owned, window-owned, programmable, boolean, multi-predicate, or
  non-privileged protection policy families;
- bus matrices or scoreboards;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, or VHDL behavior.

## Validation

This selector closeout uses documentation/continuity validation only:

- Knowledge Map generation/check;
- mdBook build;
- docs path audit;
- memory architecture check;
- whitespace diff check;
- fact-card reverify search;
- `scripts/check_doctrines.sh`.

No parser, generator, public source, support-accounting, generated-artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior is changed by this
selector.

## Rollback

Rollback removes this selector document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, public source, support-accounting, generated-artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior changes are part of
this selector.
