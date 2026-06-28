# IAL2 APB Generalized Multi-Peripheral Multi-Register Source-Shape Readiness Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.658`
- Date: `2026-06-28`
- Status: audited
- Scope: generalized APB multi-peripheral multi-register source-shape
  readiness after selected `reg0`/`reg1` timing families shipped

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.658` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.659`, public contract selection for one
bounded generalized APB multi-peripheral multi-register source-shape family.

The audit does not select direct implementation. The shipped APB
multi-peripheral multi-register timing surface is intentionally exact-family
based: selected 32-bit/data16 no-policy `reg0`/`reg1`, selected
32-bit/data16 protected `reg0`/`reg1`, and selected 32-bit/data16
status/control protected storage. Any broader source-shape acceptance needs a
public contract for register cardinality, names, local byte addresses, reset
values, policy matrices, per-peripheral consistency, support accounting,
diagnostics, validation, and residue movement before behavior changes.

No parser behavior, generator behavior, public sample, support-accounting
identity, capability bucket, schedule/check/semantic JSON contract, generated
artifact, HDL/runtime behavior, APB transaction behavior, suffix acceptance,
direct backend lowering, verification-output generation, backend-language
variant, AXI behavior, AHB behavior, or VHDL behavior changes in this audit.

## Evidence Read

This audit read the `.657` selector, `.656` 32-bit protected `reg0`/`reg1`
behavior, `.655` 32-bit protected `reg0`/`reg1` contract, `.654`
generalized timing audit, `.649/.648` data16 protected `reg0`/`reg1`
records, `.645/.644` data16 no-policy `reg0`/`reg1` records, `.642/.641`
32-bit no-policy `reg0`/`reg1` records, `.638/.637` 32-bit status/control
protected records, `.634/.633` data16 status/control protected records,
current `ApbComposition` timing guards and residue, `RegressionCorpus`,
`LanguageSurfaceSection`, focused APB/profile-alias/support surfaces, README,
ROADMAP_V2, mdBook, Memory, Knowledge Map, and relevant decisions.

## Readiness Findings

The selected exact families now cover the practical two-register
two-peripheral timing matrix that had explicit owners:

- 32-bit no-policy `reg0`/`reg1`;
- data16 no-policy `reg0`/`reg1`;
- 32-bit protected `reg0`/`reg1`;
- data16 protected `reg0`/`reg1`;
- 32-bit status/control protected storage;
- data16 status/control protected storage.

The current `ApbComposition` multi-peripheral timing guard is still narrow by
design. It accepts two peripheral completers only when they match selected
one-register storage, selected no-policy `reg0`/`reg1` storage, selected
protected `reg0`/`reg1` storage, or selected status/control protected
storage. The guard does not define public rules for arbitrary register counts,
register names, non-adjacent addresses, reset values, mixed register sets,
more than two peripheral completers, or broader access-policy matrices.

That means the next safe owner is not direct implementation. A direct
behavior slice would either keep adding another exact family or silently
define a generalized source language in code. The remaining live residue is
explicitly source-shape work, so it needs a public contract-selection slice
first.

## Selection

`.659` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.659`: select the bounded APB generalized
multi-peripheral multi-register source-shape contract.

`.659` must settle the exact bounded contract before behavior changes:

- whether the first generalized family remains limited to one requester and
  two peripheral completers;
- which APB/register data widths are in scope;
- source vocabulary, public `.ppif`/`.apb` source names, and object ids;
- register cardinality, names, local byte addresses, alignment, reset values,
  and per-peripheral register-set consistency rules;
- access-policy matrix scope, including no-policy versus privileged
  `PPROT[0]` policies;
- address-window and local-address translation requirements;
- requester/interconnect/completer timing expectations;
- report schema, support-accounting identity, capability buckets, diagnostics,
  validation probes, rollback, README, ROADMAP_V2, mdBook, task tree, Memory,
  and Knowledge Map updates.

## Deferred Boundaries

This audit and `.659` do not select implementation for:

- arbitrary unbounded register shapes;
- more than the `.659` selected peripheral count;
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

This audit used code/doc review of the selected APB timing records, current
`ApbComposition` guard and residue, support-accounting/static surface text,
README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map.

Closeout validation runs Knowledge Map generation/check, mdBook build,
whitespace diff, fact-card reverify search, and `scripts/check_doctrines.sh`.

## Rollback

Rollback removes this audit document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, public source, support-accounting, generated-artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior changes are part of
this audit.
