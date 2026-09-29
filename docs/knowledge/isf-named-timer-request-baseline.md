---
id: isf-named-timer-request-baseline
title: Named timers are distinct from transaction watchdog errors
answers:
  - "does ISF support concurrent named timers?"
  - "can separate awaits use distinct watchdog limits?"
  - "does watchdog expiry set last_error?"
  - "where is the SPECFORGE named timer request preserved?"
date: 2026-09-30
status: current
tags: [isf, timer, watchdog, expiry, counter, specforge]
evidence: docs/audits/specforge-timer-intake-20260930/manifest.json; docs/audits/specforge-timer-intake-20260930/capture.t; docs/audits/specforge-timer-intake-20260930/verify.py; perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; docs/book/src/13b-transactions.md
reverify: python3 -B docs/audits/specforge-timer-intake-20260930/verify.py
---

The preserved `sf-isf-named-timers` feature packet requests actor-owned timers
that run concurrently across transaction completion, start/restart/stop commands
from rules and transactions, ordinary expiry conditions and schedule metadata.
Cycle-count limits are required; duration limits depend on duration support
shipping. Distinct per-await watchdog limits are optional and remain separate.
SEM `.60.2` owns delivery; this intake does not implement the feature.

Parser rejects the proposed `timers` clause. LoweringIR
`_transaction_watchdog_limit` refuses distinct effective await limits because
the current transaction has a shared watchdog counter. The accepted watchdog
carrier loads the limit minus one, tests zero, and enters a timeout state that
requests delayed completion, sets `last_error` and returns to transaction idle.
That error path must remain compatible when ordinary named expiry is added.

The audit compares complete native/API/newline products and independently
checks the actual watchdog carrier. All previous baseline schedule fields match
the supplied report after excluding only separately shipped reset provenance.
Its offline verifier checks immutable identities and rejects matching-copy
report corruption and changed load/error assignments. No native HDL was run.
External corpus observations remain supplied evidence.

The illustrative packet body starts a timer then checks `when` immediately;
it is not a behavioral test that waits for expiry. Delivery needs a true
concurrent expiry test through the selected rule/wait contract, preserving
ordinary `when` semantics. The capture script describes the dated baseline;
future timer support may intentionally invalidate those refusal expectations.
