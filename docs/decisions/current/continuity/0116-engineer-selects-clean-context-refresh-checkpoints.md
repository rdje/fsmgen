---
id: engineer-selects-clean-context-refresh-checkpoints
title: Engineer selects clean context-refresh checkpoints
answers: ["who decides when an engineering session needs a fresh context?", "when may an agent pause PNT for session health?"]
date: 2026-10-07
status: current
reverify: rg -n 'Context-refresh checkpoints|0116|signoff quality' SESSION_BOOTSTRAP.md
---

# 0116 — Engineer selects clean context-refresh checkpoints

- Type: feedback/governance
- Status: accepted

## Context

The director requested the current clean pause and clarified that future
context-refresh decisions belong to the engineer. Sustained focus and signoff
quality take precedence over continuing a session after its useful boundary.
Decision 0003 remains the autonomous PNT rule for ordinary engineering work.

## Decision

The engineer may select a context-refresh stop when a fresh session would help
maintain focus or signoff quality, without asking the director to choose whether
to continue. Explain the reason briefly and first make the repository
handoff-ready: commit verified work, preserve preparation and the precise next
owned action, clear the commit message, and consume all required jobs.

Pause only at that clean checkpoint. A context refresh preserves the roadmap
objective and frontier; it does not authorize abandoning work or reporting an
unfinished slice complete. On resume, recover from the committed pointer and
continue the pending leaf.

## Consequences

This refines the session-health boundary of autonomous PNT. Routine task choices
and decomposition continue without check-ins. A clean stop names the latest
commit and next action and confirms that a new session needs only committed
state. Dirty work or a required job still in flight keeps the WAITING status.
