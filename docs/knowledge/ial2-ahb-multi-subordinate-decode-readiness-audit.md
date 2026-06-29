---
id: ial2-ahb-multi-subordinate-decode-readiness-audit
title: AHB multi-subordinate decode is ready for contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.728 select?"
  - "is AHB multi-subordinate decode ready for direct implementation?"
  - "which task owns AHB two-subordinate contract selection?"
  - "why not implement multi-subordinate AHB directly after .728?"
  - "what AHB interconnect widening points fail closed today?"
date: 2026-06-29
status: current
tags: [ial2, ahb, interconnect, decode, readiness, task-tree]
evidence: docs/IAL2_AHB_MULTI_SUBORDINATE_DECODE_READINESS_AUDIT.md; docs/IAL2_POST_AHB_INTERCONNECT_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_INTERCONNECT_DECODE_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_BEHAVIOR.md; ppif/ahb_interconnect.ahb; ppif/ahb_interconnect.ppif; ppif/apb_composition_multi_peripheral.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1478-ial2-ahb-interconnect.t; t/1479-ial2-ahb-interconnect-profile-alias.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ahb && perl -Iperl -MFSM::Adapter::IAL2::PPIF -E 'local $/; open my $fh, "<", "ppif/ahb_interconnect.ahb" or die $!; my $src=<$fh>; $src =~ s/\(subordinate regs ahb_lite_subordinate\)/\(subordinate regs ahb_lite_subordinate\)\n      \(subordinate ctrl ahb_lite_subordinate\)/; my $ok=eval { FSM::Adapter::IAL2::PPIF->new->parse_source($src, "multi_subordinate_child_candidate.ahb"); 1 }; die "unexpected success\n" if $ok; print $@;' && perl -Iperl -MFSM::Adapter::IAL2::PPIF -E 'local $/; open my $fh, "<", "ppif/ahb_interconnect.ahb" or die $!; my $src=<$fh>; $src =~ s/\(size REG_SIZE width 32 default 4\)\)/\(size REG_SIZE width 32 default 4\)\)\n      \(window ctrl\n        \(base CTRL_BASE width 32 default 4\)\n        \(size CTRL_SIZE width 32 default 4\)\)/; my $ok=eval { FSM::Adapter::IAL2::PPIF->new->parse_source($src, "multi_window_candidate.ahb"); 1 }; die "unexpected success\n" if $ok; print $@;' && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.728|IAL2-FEATURE-COMPLETENESS-FRONTIER\.729|two-subordinate AHB interconnect/decode|ahb_multi_subordinate_decode_deferred|duplicate \(subordinate \.\.\.\)|requires exactly one \(window \.\.\.\)' docs/IAL2_AHB_MULTI_SUBORDINATE_DECODE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.728` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.729`, a no-behavior public contract
selection for the first bounded two-subordinate AHB interconnect/decode
surface.

Direct implementation is not the next safe slice because the widened source
syntax, child/address-map cardinality, per-subordinate wiring, generated
artifact naming, report shape, support-accounting identity, diagnostics,
residue migration, validation, and rollback contract are not selected yet.

Current AHB widening points fail closed: extra subordinate objects are
rejected by the aggregate object-count gate, extra subordinate child bindings
are rejected as duplicate `(subordinate ...)`, and extra address-map windows
are rejected by the one-window parser gate.
