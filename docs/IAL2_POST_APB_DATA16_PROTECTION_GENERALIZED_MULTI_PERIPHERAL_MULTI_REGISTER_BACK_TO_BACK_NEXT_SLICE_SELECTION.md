# IAL2 Post APB Data16 Protection Generalized Multi-Peripheral Multi-Register Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.669`
- Date: `2026-06-28`
- Status: selected
- Scope: next APB timing/register-set residue owner after selected data16
  protected generalized register-set timing shipped

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.669` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.670`, readiness audit for broader APB
generalized register-set cardinality beyond the selected two-to-four-register
families.

This selector changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Evidence Read

This selector read the `.668` data16 protected generalized behavior, `.667`
contract, `.666` selector, `.665` 32-bit protected generalized behavior,
`.662` data16 no-policy generalized behavior, `.660` 32-bit no-policy
generalized behavior, `.656` protected `reg0`/`reg1` behavior, shipped
16/32-bit no-policy/protection/status-control records, current
`ApbCompleter` and `ApbComposition` guards/residue, `RegressionCorpus`,
`LanguageSurfaceSection`, README, ROADMAP_V2, mdBook, Memory, Knowledge Map,
and relevant decisions.

## Current State

The selected APB generalized register-set timing surface now covers exactly
two peripheral completers and two to four registers per peripheral for:

- 32-bit sideband-aware no-policy `reg0..regN` register sets (`.660`);
- sideband-aware data16 no-policy `reg0..regN` register sets (`.662`);
- 32-bit sideband-aware protected `reg0..regN` register sets (`.665`);
- sideband-aware data16 protected `reg0..regN` register sets (`.668`).

The live `ApbCompleter` adjacent-setup predicates and live `ApbComposition`
multi-peripheral timing predicates pass `minimum_count = 2` and
`maximum_count = 4` for each selected generalized register-set family. The
multi-peripheral predicates also keep the selected generalized behavior
bounded to exactly two peripheral completers with matching register counts.

The live report/static residue now names broader cardinality beyond the
selected bounded families as future work after `.668`.

## Selection

`.670` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.670`: audit broader APB generalized
register-set cardinality readiness before any behavior change.

`.670` must decide whether the next exact roadmap-aligned owner is:

- public contract selection for a first bounded cardinality widening beyond
  four registers;
- a smaller report/static, diagnostic, address-map, or fixture prerequisite;
- a more-than-two-peripheral generalized owner instead;
- explicit deferral in favor of queues, overflow, accepted-less requester
  timing, multiple active transfers, bus matrices, scoreboards, direct
  backend, verification-output, backend-language variants, AXI, AHB, or VHDL.

If `.670` selects cardinality widening, it must settle the exact public
source names, representative register count, width/policy family, address
stride and window sizing, report/support identities, diagnostics, validation
cost, rollback, README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map,
and next owner before any source, parser, generator, support-accounting, or
test behavior changes.

## Rationale

Broader register cardinality is the smallest coherent APB timing/register-set
residue after `.668`.

The project has now shipped the selected two-peripheral generalized
register-set shape for both 32-bit and data16 widths, with and without the
selected protection matrix. The next cardinality step is still behavior
bearing because it changes accepted source shape, generated storage/read/write
logic, report cardinality, diagnostics, fixture accounting, and potential
generated-artifact size. Auditing first keeps a future implementation from
silently widening all four generalized families at once.

## Deferred Boundaries

This selector does not select implementation for:

- register cardinality beyond a future `.670` decision;
- more than two peripheral completers;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- interconnect-owned, window-owned, programmable, boolean, multi-predicate,
  or non-privileged protection policy families;
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
