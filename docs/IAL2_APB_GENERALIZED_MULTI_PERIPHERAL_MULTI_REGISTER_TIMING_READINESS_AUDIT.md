# IAL2 APB Generalized Multi-Peripheral Multi-Register Timing Readiness Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.654`
- Date: `2026-06-28`
- Status: audited
- Scope: APB multi-peripheral multi-register back-to-back timing readiness
  after status/control protected-storage residue cleanup

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.654` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.655`, public contract selection for the
bounded APB sideband-aware 32-bit protected `reg0`/`reg1`
multi-peripheral multi-register back-to-back timing family.

The audit does not select broad generalized timing. Current implementation
and public samples still intentionally describe exact bounded families: one
requester, two peripheral completers, depth-1 queued requester timing,
overflow `reject`, adjacent setup on every peripheral, selected 16/32-bit
sideband buses, and exact two-register storage shapes.

No parser behavior, generator behavior, public source, support-accounting
identity, capability bucket, schedule/check/semantic JSON contract,
generated artifact, HDL/runtime behavior, APB transaction behavior, suffix
acceptance, direct backend lowering, verification-output generation,
backend-language variant, AXI behavior, AHB behavior, or VHDL behavior
changes in this audit.

## Evidence Read

This audit read the `.653` residue cleanup, `.652` status/control contract,
`.651` status/control readiness audit, shipped `.649` data16 protected
`reg0`/`reg1` multi-peripheral multi-register behavior, shipped `.645` and
`.642` no-policy multi-peripheral multi-register behavior, shipped `.638`
and `.634` status/control protected behavior, current
`ApbComposition`/`ApbCompleter` timing guards and residue,
`RegressionCorpus`, `LanguageSurfaceSection`, focused APB/profile-alias/support
tests, README, ROADMAP_V2, mdBook, Memory, Knowledge Map, and relevant
decisions.

Live schedule-report probes confirmed the shipped selected families:

- 32-bit no-policy `reg0`/`reg1` multi-peripheral multi-register timing:
  data width `32`, `PSTRB width 4`, control base `256`, no protection owner,
  queued interconnect propagation, and narrowed timing residue.
- data16 no-policy `reg0`/`reg1` multi-peripheral multi-register timing:
  data width `16`, `PSTRB width 2`, control base `258`, no protection owner,
  queued interconnect propagation, and narrowed timing residue.
- data16 protected `reg0`/`reg1` multi-peripheral multi-register timing:
  data width `16`, `PSTRB width 2`, control base `258`, peripheral-completer
  protection owner, queued interconnect propagation, and narrowed timing,
  protection, and remaining-width residue.
- 32-bit status/control protected multi-peripheral timing:
  `status_reg/status_shadow_reg` plus `control_reg/control_shadow_reg`,
  data width `32`, `PSTRB width 4`, control base `256`,
  peripheral-completer protection owner, queued interconnect propagation, and
  narrowed timing/protection/alternate-width residue.
- data16 status/control protected multi-peripheral timing:
  `status_reg/status_shadow_reg` plus `control_reg/control_shadow_reg`,
  data width `16`, `PSTRB width 2`, control base `258`,
  peripheral-completer protection owner, queued interconnect propagation, and
  narrowed timing/protection/remaining-width residue.

A temporary `/tmp` candidate for 32-bit protected `reg0`/`reg1`
multi-peripheral multi-register timing was derived from the shipped `.649`
data16 protected source with targeted 32-bit data/strobe/address/window
changes. It failed closed at the current multi-peripheral timing guard:

```text
APB multi-peripheral selected back-to-back timing-policy supports only one-register peripheral completer storage, the selected two-peripheral sideband no-policy reg0/reg1 storage shape, or the selected two-peripheral sideband protection status/control storage shape in this slice
```

## Readiness Findings

The immediate missing bounded family is the 32-bit counterpart of `.649`:
protected `reg0`/`reg1` storage on both two-register peripheral completers.
The substrate already exists in separate pieces:

- `.628` ships selected 32-bit protected `reg0`/`reg1` storage for standalone
  completers and fixed composition.
- `.642` ships selected 32-bit no-policy `reg0`/`reg1` multi-peripheral
  multi-register timing.
- `.638` ships selected 32-bit protected status/control multi-peripheral
  timing.
- `.649` ships selected data16 protected `reg0`/`reg1`
  multi-peripheral multi-register timing.

The current `ApbComposition` guard intentionally lacks a 32-bit
`_multi_peripheral_completers_are_selected_sideband_protection_multi_register`
acceptance path, while `ApbCompleter` already recognizes the 32-bit protected
`reg0`/`reg1` adjacent-setup shape. That makes the next safe owner a public
contract-selection slice, not direct implementation and not broad generalized
timing.

## Selection

`.655` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.655`: select the bounded APB
sideband-aware 32-bit protected `reg0`/`reg1` multi-peripheral
multi-register back-to-back timing public contract.

`.655` must settle exact public `.ppif` and `.apb` source names, source
object id, register/storage and access-policy matrix, address-window
requirements, requester/interconnect timing, report/residue movement,
support-accounting identities, diagnostics, validation, rollback, docs, and
Knowledge Map before behavior changes.

## Deferred Boundaries

This audit does not select:

- arbitrary register counts, names, addresses, reset values, or policy
  matrices;
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

This audit used code/doc review and live report/candidate probes. Closeout
validation passed Knowledge Map generation/check, mdBook build, whitespace
diff, APB module syntax checks for `ApbComposition.pm` and `ApbCompleter.pm`,
the fact-card reverify search, and `scripts/check_doctrines.sh`.

## Rollback

Rollback removes this audit document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, public source, support-accounting, generated-artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior changes are part of
this audit.
