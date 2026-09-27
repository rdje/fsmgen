---
id: native-setpgid-causal-frontier
title: Native setpgid EPERM needs same-call group and session evidence
answers:
  - "what caused the T1972 pre-exec setpgid EPERM?"
  - "do parent and child setpgid timing controls explain the original failure?"
  - "can a correct process group coexist with native setpgid EPERM?"
date: 2026-09-27
status: current
tags: [process, supervision, containment, native, diagnosis]
evidence: docs/audits/native-group-discriminator-20260927/manifest.json; docs/audits/native-group-discriminator-20260927/result.jsonl; docs/audits/native-group-discriminator-20260927/probe.c; docs/audits/native-group-discriminator-20260927/verify.py; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: python3 -B docs/audits/native-group-discriminator-20260927/verify.py
---

The T1972 child 43538 failed before exec with setpgid undef and immediately
captured errno=1. The production diagnostic identifies the syscall, not its
native cause. Its group and session were not retained and cannot be recovered
after the child was reaped. The original cause remains unproved.

The fixed standalone native matrix retains child-only, parent-first, child-first,
simultaneous and intentional session-leader controls. Ordinary timing controls
succeed on Darwin 27.0.0 xnu-13432.1.9; this is not proof that all races are absent.
The deliberate session leader fails with EPERM while PGID=SID=PID, independently
queried by its parent. Therefore correct group membership cannot replace a
successful setpgid return. This control does not attribute the original failure.

Owner HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.10
retains causal repair. Child .2 seals the native discriminator; .3.1 qualifies
native syscall context capture before .3.2 observes one original T1972 attempt.
A passing original cannot close the failure. No host change, admission relaxation,
original retry or production repair occurs in the native discriminator slice.

Re-derivation uses the predeclared native matrix; falsification uses actual
session-leader rejection, independent parent queries and corrupt-record controls;
durability uses tracked source/result/manifest and the exact verifier.
