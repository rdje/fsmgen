---
id: ial2-post-ahb-two-subordinate-alias-next-slice-selection
title: Post AHB two-subordinate alias selector chooses remaining-residue audit
answers:
  - "what follows AHB two-subordinate .ahb alias behavior?"
  - "which task owns the next AHB follow-on after the two-subordinate alias?"
  - "why audit remaining AHB residue after the eight-entrypoint AHB surface?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.733 select?"
date: 2026-06-30
status: current
tags: [ial2, ahb, selector, residue, task-tree]
evidence: docs/IAL2_POST_AHB_TWO_SUBORDINATE_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_TWO_SUBORDINATE_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_TWO_SUBORDINATE_BEHAVIOR.md; docs/IAL2_AHB_MULTI_SUBORDINATE_DECODE_READINESS_AUDIT.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ahb && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ahb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.733|IAL2-FEATURE-COMPLETENESS-FRONTIER\.734|remaining AHB residue|ppif/ahb_interconnect_two_subordinate\.ahb|intent\.ahb_profile_alias_interconnect_two_subordinate' docs/IAL2_POST_AHB_TWO_SUBORDINATE_ALIAS_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.733` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.734`, a no-behavior readiness audit for
the remaining AHB residue after the eight public bounded AHB IAL2 entrypoints
ship.

The eight public AHB IAL2 entrypoints are the requester, subordinate,
one-subordinate aggregate interconnect, and two-subordinate aggregate
interconnect `.ppif` sources plus their matching selected `.ahb` aliases.

The selector chooses an audit instead of direct implementation because the
remaining AHB backlog spans multiple independent axes: AHB completer behavior,
broader interconnect/decode, optional signals, burst `SEQ`, byte-lane and
narrow-transfer behavior, legacy two-bit subordinate `HRESP`, scoreboards,
full-manager behavior, direct backend, verification-output generation,
backend-language variants, and VHDL.

`.733` changes no behavior. `.734` must select the next exact AHB owner or a
required prerequisite from current roadmap/code/docs evidence.
