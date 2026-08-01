---
id: ial2-apb-alternate-width-readiness-audit
title: APB alternate widths are ready for public contract selection
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.592?"
  - "did .592 change APB behavior?"
  - "what comes after APB alternate width readiness?"
  - "is APB alternate width work blocked by lower-layer support?"
  - "what must APB alternate width contract selection decide?"
date: 2026-06-27
status: current
tags: [ial2, apb, alternate-widths, pstrb, pprot, readiness, task-tree]
evidence: docs/IAL2_APB_ALTERNATE_WIDTH_READINESS_AUDIT.md; docs/IAL2_APB_PUBLIC_SURFACE_REPORT_STATIC_SYNC.md; docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; t/1470-ial2-apb-profile-alias.t; t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  perl -MJSON::PP -e 'for my $path (@ARGV) { open my $fh, q{-|}, qq{./bin/fsmgen}, qq{--quiet}, qq{--emit-schedule-json}, $path or die $!; local $/; my $json = <$fh>; close $fh or die qq{fsmgen failed for $path\n}; my $r = JSON::PP->new->decode($json); my @ids = map { $_->{id} } @{ $r->{unsupported_residue} || [] }; print "$path: ", join(",", @ids), "\n"; }' ppif/apb_requester_transfer_sideband.ppif ppif/apb_completer_multi_register_sideband.ppif ppif/apb_composition_multi_register_sideband.ppif ppif/apb_composition_multi_peripheral_sideband.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.592|IAL2-FEATURE-COMPLETENESS-FRONTIER\.593|apb_alternate_widths_deferred|public APB alternate-width contract|PSTRB derivation' docs/IAL2_APB_ALTERNATE_WIDTH_READINESS_AUDIT.md
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.592` audits APB alternate-width readiness
after `.591` synchronized the public sideband/strobe surfaces. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.593`, public APB alternate-width contract
selection, without changing behavior.

The parser already preserves authored APB width tokens for requester,
completer, composition, storage, control, and address-map clauses, but current
APB validators intentionally pin address/data/register widths to 32,
`wait_cycles` to 4, `PPROT` to 3, and `PSTRB` to 4. Current generated behavior
also hard-codes the 32-bit/4-strobe path through requester `PSTRB` drive,
completer `strb_q`, byte-lane masks, and multi-peripheral address-map width.

APB alternate-width work is not blocked by lower-layer generated IAL1/IAL0
support for a bounded static-width slice: existing shipped surfaces already
carry width-bearing ports, bitwise operations, concatenation, `when-bit`, and
masked read-modify-write expressions. The next needed step is a public APB
width contract.

`.593` must select the width matrix and boundaries before implementation:
address widths, data/register widths, `PSTRB` derivation from data width,
byte-multiple fail-closed rules, wait-count width policy, address/window
alignment, compatibility across requester/completer/composition/interconnect,
reports, support identities, diagnostics, tests, validation, rollback, and the
next behavior owner or prerequisite.

`.592` changes no parser behavior, generator behavior, source samples,
support-accounting identities, report schemas, JSON behavior, generated
artifacts, HDL/runtime behavior, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.
