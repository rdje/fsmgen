# IAL2 APB Public-Surface Report-Static Sync

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.591`

Date: 2026-06-27

## Summary

`.591` synchronizes the static public language-surface wording after bounded
APB `PPROT`/`PSTRB` sideband/strobe behavior shipped in `.589`.

The cleanup changes no parser behavior, generator behavior, source samples,
support-accounting identities, validation behavior beyond focused manifest
assertions, generated artifacts, report schemas, schedule/check JSON, semantic
JSON, HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Synchronized Surface

The generic `.ppif` language-surface manifest now describes the shipped
sideband-aware APB `.ppif` coverage:

```text
ppif/apb_requester_transfer_sideband.ppif
ppif/apb_completer_multi_register_sideband.ppif
ppif/apb_composition_multi_register_sideband.ppif
ppif/apb_composition_multi_peripheral_sideband.ppif
```

The same manifest paragraph now says `.apb` mirrors those sideband-aware
`.ppif` sources through support-accounted profile-alias fixtures:

```text
ppif/apb_requester_transfer_sideband.apb
ppif/apb_completer_multi_register_sideband.apb
ppif/apb_composition_multi_register_sideband.apb
ppif/apb_composition_multi_peripheral_sideband.apb
```

The stale broad "APB sidebands" deferred wording is removed from the generic
`.ppif` public boundary. The remaining APB residues stay explicit as APB
alternate widths, APB `PPROT` access-control effects, and APB back-to-back
policy.

## Report Boundary

The APB report code already distinguishes sideband-aware reports from
non-sideband reports:

- Non-sideband APB reports still carry `apb_protection_and_strobes_deferred`.
- Sideband-aware APB reports carry `apb_protection_policy_effects_deferred`.
- Sideband-aware APB reports also retain `apb_alternate_widths_deferred` and
  `apb_back_to_back_policy_deferred`.

`.591` keeps that report schema and behavior unchanged. The only test change is
focused capability-manifest coverage that asserts the corrected static public
wording and prevents the stale broad `.ppif` sideband deferral from returning.

## Next Owner

`.591` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.592`, an APB alternate-width
readiness audit.

APB alternate widths are selected before `PPROT` access-control effects,
back-to-back transfer policy, additional APB topology work, AXI/AHB return,
direct backend, verification-output, backend-language variants, or VHDL because
width policy is the most structural remaining APB residue after sideband/strobe
support. Address/data width choices determine `PSTRB` width, byte-lane mapping,
static validation, generated IAL1/IAL0 port widths, report fields, and whether
sideband-aware aliases can scale beyond the fixed 32-bit first slice.

## Non-Goals

`.591` does not implement alternate APB widths, `PPROT` access-control effects,
back-to-back requester admission, additional APB composition/interconnect
behavior, direct backend lowering, verification-output generation,
backend-language variants, AXI behavior, AHB behavior, or VHDL behavior.

`.591` also does not add or change APB source syntax, samples, support
identities, diagnostics, generated review artifacts, schedule/check/semantic
JSON behavior, or generated HDL/runtime behavior.

## Validation

The closeout validation for `.591` is static-manifest and docs focused:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
env -u PERL5LIB perl -Iperl -c t/297-capability-manifest.t
env -u PERL5LIB prove -Iperl t/297-capability-manifest.t
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
mdbook build docs/book
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is static-surface only: revert the language-surface wording, focused
manifest assertions, this note, its fact card, task-tree frontier updates,
README, ROADMAP_V2, mdBook, Memory, and generated Knowledge Map changes. The
`.589` APB sideband/strobe behavior and report schema remain unchanged.
