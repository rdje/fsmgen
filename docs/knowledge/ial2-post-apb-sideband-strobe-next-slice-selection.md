---
id: ial2-post-apb-sideband-strobe-next-slice-selection
title: APB public-surface cleanup follows sideband/strobe behavior
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.590?"
  - "what comes after APB sideband strobe behavior?"
  - "why is APB public surface cleanup next?"
  - "does .590 change APB behavior?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.591?"
date: 2026-06-27
status: current
tags: [ial2, apb, sideband, strobe, pprot, pstrb, selector, task-tree, public-surface]
evidence: docs/IAL2_POST_APB_SIDEBAND_STROBE_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md; docs/IAL2_APB_SIDEBAND_STROBE_CONTRACT_SELECTION.md; ppif/apb_requester_transfer_sideband.ppif; ppif/apb_completer_multi_register_sideband.ppif; ppif/apb_composition_multi_register_sideband.ppif; ppif/apb_composition_multi_peripheral_sideband.ppif; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  perl -MJSON::PP -e 'for my $path (@ARGV) { open my $fh, q{-|}, qq{./bin/fsmgen}, qq{--quiet}, qq{--emit-schedule-json}, $path or die $!; local $/; my $json = <$fh>; close $fh or die qq{fsmgen failed for $path\n}; my $r = JSON::PP->new->decode($json); my @ids = map { $_->{id} } @{ $r->{unsupported_residue} || [] }; print "$path: ", join(",", @ids), "\n"; }' ppif/apb_requester_transfer_sideband.ppif ppif/apb_completer_multi_register_sideband.ppif ppif/apb_composition_multi_register_sideband.ppif ppif/apb_composition_multi_peripheral_sideband.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.590|IAL2-FEATURE-COMPLETENESS-FRONTIER\.591|APB public-surface|apb_protection_policy_effects_deferred|apb_alternate_widths_deferred|apb_back_to_back_policy_deferred'
  docs/IAL2_POST_APB_SIDEBAND_STROBE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.590` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.591`, a public-surface and report-static
cleanup owner after bounded APB `PPROT`/`PSTRB` sideband/strobe behavior.

The selector follows `.589` because APB sideband-aware requester, completer,
fixed-composition, and multi-peripheral composition reports now remove the
broad `apb_protection_and_strobes_deferred` residue and keep narrower
remaining residue: `apb_protection_policy_effects_deferred`,
`apb_alternate_widths_deferred`, and `apb_back_to_back_policy_deferred`, with
topology residues only on narrower endpoint/fixed-composition shapes.

The next owner is cleanup before deeper APB widening because the public
language-surface manifest still has stale generic `.ppif` prose that lists APB
sidebands as deferred even though `.589` shipped bounded sideband-aware APB
`.ppif` and `.apb` samples. `.591` must align that public/static wording
without changing APB source acceptance, generated artifacts, JSON behavior
except corrected static prose, or HDL/runtime behavior.

`.590` changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts, JSON behavior,
HDL/runtime behavior, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior.
