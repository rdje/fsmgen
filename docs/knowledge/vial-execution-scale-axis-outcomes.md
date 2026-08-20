---
id: vial-execution-scale-axis-outcomes
title: VIAL execution scale reports each axis at its earliest real authority
answers:
  - "which VIAL execution scale axes reach their selected limits?"
  - "how are exact 1 MiB 4 MiB and 16 MiB VIAL plans constructed?"
  - "how is the one million random attempt boundary proved?"
  - "which cap wins for VIAL operations bindings types and source maps?"
  - "how does the VIAL execution qualification prove exactly 262144 random attempts and replay equality?"
  - "how does the VIAL execution qualification produce an exact four MiB semantic plan?"
  - "how does the VIAL execution limit produce an exact sixteen MiB semantic plan?"
  - "how does VIAL reject the first complete execution plan operation above sixteen MiB?"
  - "how does the VIAL execution qualification concentrate 8192 operations in one scenario?"
  - "which cap rejects 65536 and 65537 VIAL operations in one scenario?"
  - "which cap rejects 65536 total VIAL operations across 32 scenarios?"
  - "does the VIAL total-operation axis have a qualified operating point?"
  - "do the VIAL fiber axes reach their qualification levels?"
  - "which VIAL execution axis actually reaches its own nominal cap?"
  - "how is the exact 16384 simultaneously-live-fiber limit proved?"
  - "what rejects 16385 simultaneously live fibers?"
  - "how is the exact 65536 total-fiber limit authored and what rejects it?"
  - "why do the VIAL total-fiber limit and over-limit levels have different authorities?"
  - "why does the VIAL total-fiber ladder switch from literal fibers to repeat?"
  - "which VIAL execution level is cheaper to run, the limit or the over-limit?"
  - "how are the VIAL total-operation limit and over-limit levels authored?"
  - "why is the VIAL 1000000-operation limit level never materialized?"
  - "what does a preflight_dominated VIAL scale evaluation mean?"
  - "what rejects 1000001 total VIAL operations?"
  - "how much memory does a million-operation VIAL execution graph need?"
  - "why does a VIAL scale level need an explicitly raised RAM-guard cutoff?"
  - "which cap rejects 8192 VIAL execution types?"
  - "how many execution types can the VIAL direct-IAL1 route actually reach?"
  - "does the VIAL execution-type axis have a qualified operating point?"
  - "why are the remaining VIAL binding, type, and source-map levels unowned?"
  - "how many bindings, execution types, and source maps can a VIAL route reach?"
  - "why does VIAL not re-level an unreachable execution scale axis?"
  - "what does an envelope_unconstructible VIAL scale evaluation mean?"
  - "does the VIAL execution contract declare caps its bridge cannot reach?"
  - "how are the VIAL binding qualification limit and over-limit levels reported?"
  - "how many bindings does the canonical VIAL route actually accept?"
date: 2026-08-20
status: current
tags: [vial, execution-ir, scale, limits, qualification, reachability]
evidence: >-
  docs/decisions/0072-an-unreachable-declared-cap-is-a-result-not-a-level-to-rewrite.md;
  docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md;
  perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm; perl/FSM/VIAL/ExecutionBuilder.pm;
  perl/FSM/Support/VIALExecutionContract.pm; t/1607-vial-architecture-scale-execution-source-maps.t;
  t/1610-vial-architecture-scale-execution-plan-qualification.t;
  t/1613-vial-architecture-scale-execution-random-qualification.t;
  t/1614-vial-architecture-scale-execution-random-limit.t;
  t/1615-vial-architecture-scale-execution-random-over-limit.t;
  t/1616-vial-architecture-scale-execution-scenario-qualification.t;
  t/1617-vial-architecture-scale-execution-scenario-limit.t;
  t/1618-vial-architecture-scale-execution-scenario-over-limit.t;
  t/1619-vial-architecture-scale-execution-operation-qualification.t;
  t/1620-vial-architecture-scale-execution-operation-limit.t;
  t/1621-vial-architecture-scale-execution-operation-over-limit.t;
  t/1622-vial-architecture-scale-execution-total-operation-qualification.t;
  t/1623-vial-architecture-scale-execution-fiber-qualification.t;
  t/1624-vial-architecture-scale-execution-live-fiber-limit.t;
  t/1625-vial-architecture-scale-execution-total-fiber-limit.t;
  t/1626-vial-architecture-scale-execution-total-operation-limit.t;
  t/1627-vial-architecture-scale-execution-type-qualification.t;
  t/1628-vial-architecture-scale-execution-binding-limits.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  prove -Iperl t/1607-vial-architecture-scale-execution-source-maps.t
  t/1610-vial-architecture-scale-execution-plan-qualification.t
  t/1613-vial-architecture-scale-execution-random-qualification.t
  t/1614-vial-architecture-scale-execution-random-limit.t
  t/1615-vial-architecture-scale-execution-random-over-limit.t
  t/1616-vial-architecture-scale-execution-scenario-qualification.t
  t/1617-vial-architecture-scale-execution-scenario-limit.t
  t/1618-vial-architecture-scale-execution-scenario-over-limit.t
  t/1619-vial-architecture-scale-execution-operation-qualification.t
  t/1620-vial-architecture-scale-execution-operation-limit.t
  t/1621-vial-architecture-scale-execution-operation-over-limit.t
  t/1622-vial-architecture-scale-execution-total-operation-qualification.t
  t/1623-vial-architecture-scale-execution-fiber-qualification.t
  t/1624-vial-architecture-scale-execution-live-fiber-limit.t
  t/1625-vial-architecture-scale-execution-total-fiber-limit.t
  t/1626-vial-architecture-scale-execution-total-operation-limit.t
  t/1627-vial-architecture-scale-execution-type-qualification.t
  t/1628-vial-architecture-scale-execution-binding-limits.t
---

The ladder reports the first real authority in semantic → bridge → plan order.
It never forges a downstream object to reach a preferred cap, and a structural
cap reached before a later rejection is distinguished from an accepted plan.

| Axis | Selected points | Result and first authority |
|---|---|---|
| plan bytes | 1 / 4 / 16 MiB, then one action more | exact accepted plans at all three sizes; the next action is rejected at `/plan` |
| random attempts | 262,144 / 1,000,000 / 1,000,001 | exact candidates accept at attempts 262,143 and 999,999; the next returns `VIAL_RANDOM_EXHAUSTED` |
| scenarios | 512 / 4,096 / 4,097 | 512 and 4,096 accept; 4,097 is rejected at `/scenario_ids` |
| operations/scenario | 8,192 / 65,536 / 65,537 | 8,192 accepts; plan bytes reject 65,536; parser action count rejects 65,537 |
| operations total | 65,536 / 1,000,000 / 1,000,001 | qualification hits plan bytes; limit is preflight-dominated; excess reaches its own cap |
| live fibers | 1,024 / 16,384 / 16,385 | qualification and limit accept; excess reaches its own cap |
| total fibers | 8,192 / 65,536 / 65,537 | qualification accepts; limit reaches its cap then hits plan bytes; excess reaches its own cap |
| execution types | 8,192 / 65,536 / 65,537 | qualification hits the parser's 4,096-declaration cap; limit/excess are envelope-unconstructible |
| bindings | 32,768 / 65,536 / 65,537 | all three are envelope-unconstructible |
| source maps | 262,144 / 1,000,000 / 1,000,001 | all three are envelope-unconstructible |

The exact plan ladder contains 2,974 / 12,166 / 48,850 genuine resets and
2,991 / 12,183 / 48,867 maps. The 512- and 4,096-scenario plans are 496,709 and
3,779,103 bytes. The 8,192-operation single-scenario plan is 2,955,783 bytes.
Fiber qualification plans are 432,528 bytes at 1,024 live fibers and 3,222,659
bytes at 8,192 total fibers; the 16,384-live limit plan is 6,553,464 bytes.

Literal construction saturates before the largest fiber and operation levels,
so those levels use the ordinary checked `repeat` form. The million-operation
graph costs about 5.0 KiB resident per operation: measured descendant RSS was
436 / 1,442 / 2,692 / 3,977 MiB at 65,536 / 262,144 / 524,288 / 786,432.
Decision `0061` clause 8 therefore permits the 1,000,000-operation limit to be
`preflight_dominated` / `not_materialized` by the smaller 65,536-operation plan
witness; 1,000,001 is opt-in evidence at a 6,144-MiB descendant cutoff.

Decision `0072` keeps declared levels even when no shipped route can construct
them. Such a level is `envelope_unconstructible` / `not_constructed`: it carries
the exact constructor diagnostic, no retained source or stage identity, a
refused raw build, and paired limit-interaction and route-boundary records. The
measured whole-route boundaries are 2,054 bindings (2,055 rejects at `/events`),
1,043 execution types (1,044 rejects at the serialized-manifest `/` cap), and
46,294 source-map records (46,295 rejects at `/plan`). Binding, type, and
source-map unconstructible records are implemented; final family qualification
and cleanup remain in `.17.2.4.2`. `.17.4` owns the cross-layer cap-policy
decision. Current status and user behavior live in
`docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` and
`docs/book/src/16d-hial-vial-verification-architecture.md`.

Exact pre-partition prose is recoverable with
`git show 5514e692c:docs/knowledge/vial-execution-scale-reachability.md`.
