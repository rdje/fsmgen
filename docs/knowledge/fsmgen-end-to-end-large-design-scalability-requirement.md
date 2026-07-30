---
id: fsmgen-end-to-end-large-design-scalability-requirement
title: FSMGen must handle end-to-end big to really big designs
answers:
  - "must FSMGen support large designs end to end?"
  - "what does big to really big design support mean for FSMGen?"
  - "is FSMGen large-design scalability an active priority?"
  - "which task owns end-to-end FSMGen scalability?"
date: 2026-07-30
status: current
tags: [scalability, performance, large-design, end-to-end, requirement]
evidence: docs/tasks/FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY.md; docs/TASK_TREE.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'big to really big|FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY|end-to-end design capacity' docs/tasks/FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY.md docs/TASK_TREE.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

The director requires FSMGen to handle end-to-end big to really big designs.
This covers the complete source-to-HDL/verification path, not a parser-only
microbenchmark, and it must preserve correctness, diagnostics, deterministic
artifacts, same-volume locality, and recoverability.

Proposed task `FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY` owns measurable
`big`/`really_big` workload profiles, per-stage correctness oracles, peak
descendant RSS/time/artifact metrics, bottleneck analysis, evidence-backed
budgets, graceful beyond-capacity behavior, and stable regression gates.

The requirement is durably parked, not active. Completed selector `.830`
chooses the smaller assertion-backed transaction-invoked named-drive priority
audit first; a later roadmap selector must activate scale from a clean
boundary.

The priority audit's bounded `.2` contract selection does not change this
status or count as large-design evidence.

Clean audit commit `e715a34c7` activates only that no-behavior contract; the
scale tree remains proposed and unchanged.

Completed contract `.2` selects bounded priority implementation `.3` and
separately records a direct-VHDL expression defect. Neither is large-design
capacity evidence; the scale tree remains independently proposed.

The completed direct-VHDL reduction audit selects a bounded scalar repair and
unsupported-reduction rejection for proposed implementation `.2`. It supplies
backend correctness evidence only, not an end-to-end scalability result; the
large-design tree remains proposed.
