---
id: required-specforge-delivery-controls-task-selection
title: Required SPECFORGE delivery controls task selection
answers: ["which work has exclusive priority until SPECFORGE requests are delivered?", "may independent defects interrupt required SPECFORGE feature delivery?"]
date: 2026-10-22
status: current
reverify: rg -n '0121|exclusive|required delivery' docs/tasks/ISF-REDUCTION-DELIVERY.md docs/SPECFORGE_FEEDBACK_RESPONSE.md
---
# 0121 — Required SPECFORGE delivery controls task selection

- Type: feedback/governance
- Status: accepted
- Owner: `ISF-REDUCTION-DELIVERY.13`

## Context

The director reconfirmed that SPECFORGE requests `.7`, `.8`, `.9`, `.10`
and `.12` have exclusive priority. The saved frontier had expanded from
required reduction width preservation into verification of an independently
found generated-wait defect and a malformed-await diagnostic repair.
Their discovery during a width audit does not make them reduction prerequisites.

## Decision

Select only required delivery of the named requests and demonstrated blockers
of that delivery. The reset question is answered. Continue required grouped
reductions through parameter-width preservation, then the remaining required
aggregate ports, durations and named timers in their checked dependency order.
Defer unrelated roadmap activity and optional extensions until required delivery
and its qualified publication/feedback are complete. A newly discovered issue
stays owned and scheduled; immediate diversion requires evidence that it blocks
a required request or its validation. Merely sharing a code path is insufficient.

The generated-wait source repair remains committed and source-qualified.
Defer its separate external runtime witness `.11.2` and the malformed-await
repair `.12` until after the required request handoff, unless a required test
makes either a demonstrated blocker. Preserve their evidence and incomplete
qualification. This supersedes their former before-width ordering; neither
is closed or erased. Optional inversion `.7.2` has the same delivery boundary.

## Consequences

Resume at `.2.3.2.1.1`: preserve original static references so generic parameter
widths cannot silently change a value whose source dependency was erased.
Source/IR/IAL0, generic HDL and grouped reductions remain required work;
private provenance alone is not delivery. Existing full-CI, native qualification
and exact-SHA publication gates remain in force at publication. Do not change
SPECFORGE's repository, pins or integration records. Decision `0116` retains
clean session-health checkpoints without changing this priority.
