# IAL2 APB Generalized Multi-Peripheral Multi-Register Broader Cardinality Readiness Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.683`
- Date: `2026-06-28`
- Status: audited
- Scope: broader APB generalized register-set cardinality after the selected
  two-peripheral five-register families

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.683` audits broader APB generalized
register-set cardinality after the 32-bit no-policy, data16 no-policy,
32-bit protected, and data16 protected five-register siblings shipped.

The audit selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.684`, public contract
selection for the first bounded APB sideband-aware 32-bit no-policy
six-register generalized `reg0..regN` register-set multi-peripheral
back-to-back timing family.

This audit changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Evidence Read

This audit read the `.682` selector, `.681` data16 protected five-register
behavior, `.678` 32-bit protected five-register behavior, `.675` data16
no-policy five-register behavior, `.672` 32-bit no-policy five-register
behavior, `.670` cardinality audit, current `ApbCompleter` and
`ApbComposition` register-count and peripheral-count guards, APB residue
reports, `RegressionCorpus`, `LanguageSurfaceSection`, focused
APB/profile-alias/support/capability tests, README, ROADMAP_V2, mdBook,
Memory, Knowledge Map, and relevant decisions.

## Current State

The selected generalized APB timing support is bounded to exactly two
peripheral completers and two-to-five registers per peripheral for these four
families:

- 32-bit sideband-aware no-policy register sets, stride `4`, data width `32`;
- sideband-aware data16 no-policy register sets, stride `2`, data width `16`;
- 32-bit sideband-aware protected register sets, stride `4`, data width `32`;
- sideband-aware data16 protected register sets, stride `2`, data width `16`.

Current `ApbCompleter` storage guards use parameterized minimum/maximum count,
stride, data-width, and protection-policy checks. Current `ApbComposition`
multi-peripheral timing guards additionally require exactly two peripheral
completers and matching register counts across the two completers.

The public support catalog now has one five-register representative for each
of the four sibling families. Focused APB/profile-alias/composition tests
cover parser/report/schedule/outdir/HDL evidence for those representatives.

The live residue still keeps broader cardinality, more-than-two-peripheral
topology, deeper queues, alternate overflow, accepted-less requester timing,
multiple active transfers, bus matrices, scoreboards, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL as future
work.

## Live Probes

Two temporary `/tmp` probes confirmed the current fail-closed boundaries:

- A synthetic six-register 32-bit no-policy two-peripheral source based on
  `ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back.ppif`
  fails strict check JSON with the current selected storage-shape diagnostic
  and no support-accounting match.
- A synthetic three-peripheral 32-bit no-policy five-register source fails
  strict check JSON with the explicit diagnostic `APB multi-peripheral
  selected back-to-back timing-policy supports only two peripheral completers
  in this slice`.

These probes changed no repository source or generated artifact.

## Readiness Findings

The next contract should start with six registers, not three peripherals:

- six registers are the smallest public step beyond the current
  `maximum_count = 5` boundary;
- the 32-bit no-policy shape avoids adding data16 stride/strobe differences
  and avoids adding protection-policy matrix changes to the first broader
  cardinality step;
- the existing storage guards are already parameterized by maximum count,
  stride, and data width;
- the selected two-peripheral interconnect/report/test surfaces already carry
  source-ordered `reg0..regN` arrays and generated `reg3/reg4` probes, making
  `reg5` the narrowest next generated-artifact extension;
- more-than-two peripheral completers cross the explicit two-peripheral guard
  plus public address-map/window, topology, interconnect fanout/mux, report,
  support-accounting, and fixture-naming boundaries.

Direct implementation is not ready in `.683` because the public contract still
has to define:

- exact public `.ppif`/`.apb` source names, object id, and source anchor;
- whether the selected family admits exactly six registers or widens the
  existing 32-bit no-policy generalized family to `maximum_count = 6`;
- representative register names and local addresses, expected as
  `reg0/reg1/reg2/reg3/reg4/reg5` at `0/4/8/12/16/20`;
- report/support identities and capability buckets;
- diagnostic wording for too many registers after the selected widening;
- generated-artifact validation probes for `reg5`;
- rollback and next-owner boundaries.

## Selection

`.684` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.684`: select the bounded APB
sideband-aware 32-bit no-policy six-register generalized register-set
multi-peripheral public contract before implementation.

`.684` must settle:

- exact public source names for the `.ppif` and `.apb` alias;
- protocol-platform-intent name, source object id, and source anchor;
- one requester and exactly two peripheral completers;
- 32-bit APB/register data, `PPROT width 3`, and `PSTRB width 4`;
- status/control windows at `0` and `256`;
- representative `reg0/reg1/reg2/reg3/reg4/reg5` local addresses
  `0/4/8/12/16/20`;
- no register-local `access-policy` clauses;
- queue-depth `1`, overflow `reject`, adjacent setup on both completers, and
  propagation-only interconnect decode;
- report fields, residue movement, support-accounting identities, capability
  buckets, diagnostics, validation probes, rollback, README, ROADMAP_V2,
  mdBook, task tree, Memory, Knowledge Map, and implementation owner.

## Deferred Boundaries

This audit does not select implementation for:

- data16 six-register generalized register sets;
- protected six-register generalized register sets;
- more than six registers;
- more than two peripheral completers;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- alternate protection-policy matrices;
- interconnect-owned protection policy;
- bus matrices or scoreboards;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, or VHDL behavior.

## Validation

This audit closeout uses documentation/continuity validation plus the live
temporary fail-closed probes:

- `./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-apb-six-register-audit.ppif`
- `./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-apb-three-peripheral-audit.ppif`
- `knowledge-map/scripts/gen_knowledge_map.sh`
- `knowledge-map/scripts/check_knowledge_map.sh`
- `mdbook build docs/book`
- `scripts/check_docs_relative_paths.sh`
- `scripts/check_memory_architecture.sh`
- `git diff --check`
- `scripts/check_doctrines.sh`

No parser, generator, public source, support-accounting, generated-artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior is changed by this
audit.

## Rollback

Rollback removes this audit document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, public source, support-accounting, generated-artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior changes are part of
this audit.
