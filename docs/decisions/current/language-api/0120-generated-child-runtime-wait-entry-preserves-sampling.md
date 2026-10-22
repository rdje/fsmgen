---
id: isf-generated-leading-runtime-wait-entry
title: Generated child runtime wait entry preserves sampling
answers:
  - "why did a generated child leading runtime wait lose count sampling?"
  - "how does a generated runtime wait preserve start guarding and zero bypass?"
date: 2026-10-22
status: current
tags: [isf, waits, generated, activation, lowering]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/ChildActivation.pm; t/2095-isf-generated-leading-runtime-wait.t; docs/audits/generated-leading-wait-20261022.json.gz; docs/tasks/ISF-REDUCTION-DELIVERY.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2095-isf-generated-leading-runtime-wait.t
---
# 0120 — Generated child runtime wait entry preserves sampling

- Type: generated transaction entry contract
- Status: source repair qualified; external generated-entry runtime pending
- Owner: `ISF-REDUCTION-DELIVERY.11.1`

## Context

The physical width audit finds native-admitted generated children whose leading
runtime wait never loads its counter or bypasses zero. Child construction adds
or replaces entry edges after transaction lowering, then activation guarding
overwrites transition conditions. Authored entry counter loads can also retain
their old source guard instead of the generated start/history guard.

## Decision

After applying the final child activation guard, rebuild a leading runtime wait
through the existing dynamic-wait predecessor helper. Remove only old canonical
entry counter loads and replace the entry edges with that shared count split.
Materialize any requested pending-sample clones through the existing constructor
before module finalization. Keep ordinary child entries, completion behavior and
the existing sampled-count evaluator unchanged.

Positive counts load exactly one selected counter under the activation guard;
zero bypasses the wait or continues through the next count split. Held start and
seen-start states cannot load or enter again. Pending samples use canonical
positive and zero-path clones; dependent zero targets retain the existing refusal.

## Evidence and limits

The corrected unchanged regression fails the seven defect subtests against the
exact committed old module, then passes all nine against the restored repair.
Actual loaded hashes and compiled method files identify both modules. Independent
truth tables cover the declared three-bit range, authored/injected entries,
expressions, chains, samples, caller kinds and native/API/newline MCP parity.
Initial unknown-guard and sample-clone oracle mistakes remain separate drafts.

Re-derivation is actual IR/carriers and source/public products; falsification is
the exact old/current regression, independent count/activation truth partitions,
pending-sample and ordinary-entry controls; durability is the permanent test,
retained source/identity/log receipt and Git. Full external footprints and raw-root
stream reconstruction are not claimed. Actual external HDL timing remains owned
by `.11.2`, which must pin its witness and observer before execution. No generic
width or grouped-reduction delivery is inferred.
