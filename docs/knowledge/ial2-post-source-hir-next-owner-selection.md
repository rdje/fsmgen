---
id: ial2-post-source-hir-next-owner-selection
title: Post-SourceHIR priority is authoritative IAL2 task-ledger repair
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.842 select?"
  - "what follows the completed private SourceHIR frontier?"
  - "why is IAL2-FEATURE-COMPLETENESS-FRONTIER.705 still blocked?"
  - "which IAL2 task nodes are missing from the root child enumeration?"
  - "does post-HIR selection activate the public builder or HIAL VIAL?"
date: 2026-07-30
status: current
tags: [ial2, selector, task-tree, continuity, blocker, hir, hial, vial]
evidence: docs/IAL2_POST_SOURCE_HIR_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/TASK_TREE_README.md; docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT_BLOCKER.md; docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT.md; docs/decisions/0031-source-hir-remains-a-private-validated-architecture-boundary.md
reverify: perl -0777 -ne 'my ($head)=split(/\n- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER\.1`/, $_, 2); my %listed=map { $_=>1 } ($head =~ /IAL2-FEATURE-COMPLETENESS-FRONTIER\.(\d+)/g); my %nodes=map { $_=>1 } (/^- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER\.(\d+)`/mg); my @missing=grep {!$listed{$_}} sort {$a<=>$b} keys %nodes; print "nodes=".(scalar keys %nodes)." listed=".(scalar keys %listed)." missing=".join(q{,},@missing)."\n";' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.(705|706|707|708|709|842|843)|historical blocker|resolved by' docs/IAL2_POST_SOURCE_HIR_NEXT_OWNER_SELECTION.md docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT_BLOCKER.md docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
---

Parent selector `.842` selects proposed `.843`, the exact authoritative IAL2
task-ledger reconciliation and mechanical-integrity owner.

Before repair, the task file has 842 numbered nodes but only 840 direct-child
references; `.633` and `.842` are the exact omissions. `.705` is the only live
blocked node, even though `.706` imported the approved source reference,
`.707` extracted its facts, `.708` selected the direct seed, and `.709` shipped
that seed. Canonical records already describe `.705` as historical/resolved.

The ledger repair is smaller and more foundational than any proposed product
architecture because PNT depends on the authoritative node list. HIAL/VIAL is
the strongest later product-architecture candidate, but remains proposed.
Private SourceHIR completion does not implicitly activate the public builder.
Scale, MCP-write, protocols/backends, simulator profiles, lifecycle review,
decision `0020`, and every director-gated owner remain unchanged.

Clean selector commit `bd1ef6765` activates only `.843` through a separate
continuity transition. The selected repair remains unimplemented during
activation, and no product behavior changes.
