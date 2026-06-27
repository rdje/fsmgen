---
id: ial2-apb-data16-pprot-effects-readiness-audit
title: APB data16 PPROT policy effects are ready for contract selection
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.601?"
  - "is APB data16 PPROT policy behavior ready?"
  - "what blocks APB data16 access-policy today?"
  - "which task owns APB data16 PPROT contract selection?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.602?"
date: 2026-06-27
status: current
tags: [ial2, apb, pprot, protection, data16, readiness, task-tree]
evidence: docs/IAL2_APB_DATA16_PPROT_EFFECTS_READINESS_AUDIT.md; docs/IAL2_POST_APB_PROFILE_SYNC_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md; docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; ppif/apb_completer_multi_register_sideband_data16.ppif; ppif/apb_composition_multi_peripheral_sideband_data16.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: perl -MFile::Temp=tempfile -we 'local $/; open my $in, q{<}, q{ppif/apb_completer_multi_register_sideband_data16.ppif} or die $!; my $s=<$in>; close $in; $s =~ s/\(data reg0_data_q width 16 reset 0\)/(data reg0_data_q width 16 reset 0)\n        (access-policy\n          (read require (privileged 1))\n          (write allow))/ or die q{reg0 substitution failed\n}; my ($fh,$path)=tempfile(q{fsmgen-data16-policy-XXXX}, SUFFIX=>q{.ppif}, DIR=>q{/tmp}, UNLINK=>1); print $fh $s; close $fh; my $out = qx(./bin/fsmgen --quiet --emit-schedule-json $path 2>&1); print $out;' && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.601|IAL2-FEATURE-COMPLETENESS-FRONTIER\.602|data16 PPROT|selected 32-bit APB data width' docs/IAL2_APB_DATA16_PPROT_EFFECTS_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.601` audits sideband data16 APB `PPROT`
policy effects and selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.602`, public
contract selection.

The parser already preserves register-local `(access-policy ...)` clauses, and
the generated completer/composition policy helpers are data-width aware. The
current first fail-closed boundary is the explicit APB completer validation
guard requiring selected 32-bit APB data width for access-policy shapes.

A temporary `/tmp` data16 policy candidate failed exactly at that guard. The
audit exposed no parser, IAL1, IAL0, report-schema, composition, direct-backend,
or VHDL prerequisite, so the next work is public contract selection rather than
lower-layer repair.

`.601` changes no parser, generator, sample, support-catalog, validation,
generated-artifact, report-schema, JSON, HDL/runtime, APB, AXI, AHB, backend,
verification-output, backend-language, or VHDL behavior.
