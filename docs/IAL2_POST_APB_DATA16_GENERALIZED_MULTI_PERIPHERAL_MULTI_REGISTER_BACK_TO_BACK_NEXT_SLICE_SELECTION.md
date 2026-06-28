# IAL2 Post APB Data16 Generalized Multi-Peripheral Multi-Register Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.663`
- Date: `2026-06-28`
- Status: selected
- Scope: next APB timing/register-set residue owner after selected data16
  no-policy generalized register-set timing shipped

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.663` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.664`, public contract selection for the
bounded APB sideband-aware 32-bit protected generalized `reg0..regN`
register-set multi-peripheral back-to-back timing family.

This selector changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Evidence Read

This selector read the `.662` data16 generalized behavior, `.661` selector,
`.660` 32-bit no-policy generalized behavior, `.659` generalized source-shape
contract, `.658` source-shape readiness audit, `.656` 32-bit protected
`reg0`/`reg1` behavior, `.645/.644` data16 no-policy records, shipped
16/32-bit no-policy/protection/status-control multi-peripheral records,
current `ApbCompleter` and `ApbComposition` guards/residue,
`RegressionCorpus`, `LanguageSurfaceSection`, focused APB/profile-alias/support
surfaces, README, ROADMAP_V2, mdBook, Memory, Knowledge Map, and relevant
decisions.

## Current State

The no-policy generalized APB register-set timing surface is now shipped for
both selected widths:

- `.660` ships 32-bit sideband-aware no-policy `reg0..regN` register sets with
  two to four registers per peripheral, local addresses `0/4/8/...`, and
  status/control windows at `0` and `256`;
- `.662` ships sideband-aware data16 no-policy `reg0..regN` register sets with
  two to four registers per peripheral, local addresses `0/2/4/...`, and
  status/control windows at `0` and `258`.

The protected APB timing surface is still exact-family based:

- `.656` ships 32-bit protected `reg0`/`reg1` two-peripheral timing;
- earlier data16-protection slices ship exact data16 protected `reg0`/`reg1`
  and status/control protected families;
- status/control protected storage variants are shipped for the bounded
  two-peripheral 32-bit/data16 families.

The live `ApbCompleter` adjacent-setup guard admits selected exact protected
two-register and status/control protected families. The live `ApbComposition`
multi-peripheral timing guard admits selected 32-bit and data16 no-policy
generalized register sets, selected exact protected `reg0`/`reg1` families,
and selected status/control protected families. It does not define a protected
generalized `reg0..regN` matrix.

The current report/static residue explicitly keeps protected generalized
register sets deferred after the selected no-policy generalized families.

## Selection

`.664` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.664`: select the bounded APB
sideband-aware 32-bit protected generalized register-set multi-peripheral
back-to-back public contract before implementation.

`.664` must settle the public contract before any behavior change:

- exact public `.ppif`/`.apb` source names, object id, and source anchor;
- whether the family remains bounded to one requester and exactly two
  peripheral completers;
- whether the register-set count remains bounded to two, three, or four
  source-ordered registers;
- protected register names, local byte addresses, address widths, data widths,
  reset values, data-signal uniqueness, and per-peripheral consistency;
- the access-policy matrix for every selected `reg0..regN` register, including
  the public rule for `reg2..regN`;
- requester/interconnect/completer timing expectations, including queue depth
  `1`, overflow `reject`, adjacent setup on every peripheral, propagation-only
  interconnect decode, and no interconnect-owned protection predicate;
- report shape, support-accounting identities, capability buckets,
  diagnostics, validation probes, rollback, README, ROADMAP_V2, mdBook, task
  tree, Memory, Knowledge Map, and next owner.

## Rationale

Protected generalized register sets are the smallest coherent APB
timing/register-set residue after `.662`.

The project has now shipped the generalized no-policy shape for both selected
32-bit and data16 widths. The remaining register-set generalization gap is the
policy-bearing side: current protected behavior proves exact `reg0`/`reg1`
families, but extending that to `reg2..regN` would silently define new
register-local protection semantics unless a public contract selects the
policy matrix first.

The first protected generalized owner is 32-bit contract selection rather than
data16 or direct implementation. That isolates the protection-policy decision
from alternate-width stride/strobe concerns and lets the next slice state the
source names, report contract, diagnostics, and rollback before code widens
any timing guard.

## Deferred Boundaries

This selector does not select implementation for:

- data16 protected generalized register sets;
- broader register cardinality beyond the future `.664` contract;
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
