---
id: push-cadence-is-300-commits
title: Normal push cadence is 300 accumulated local commits
answers: ["how often should this repository push commits?", "how many commits should accumulate before pushing?", "should every commit be pushed immediately?", "does an explicitly requested early push change the normal cadence?", "how is the push cadence counter calculated and reset?"]
date: 2026-08-29
status: superseded
supersedes: push-cadence-is-200-commits
superseded_by: push-cadence-is-500-commits
reverify: rg -n 'superseded by.*0102' docs/decisions/0091-push-cadence-is-300-commits.md
---

# 0091 — Push cadence is 300 commits

- Status: superseded by [0102](0102-push-cadence-is-500-commits.md)

## Context

The director increased the standing interval from 200 to 300 accumulated local commits. Per-slice commits, explicit early-push authority, and exact hosted qualification remain independent safeguards.

## Decision

1. Push normally after 300 commits beyond upstream; derive the count with `git rev-list --count @{upstream}..HEAD`, never a shadow counter.
2. Changing policy does not reset the count; only a successful push starts a new interval, so existing local commits still count.
3. A successful explicitly directed early push starts a fresh 300-commit interval without changing the standing cadence.
4. A failed or incomplete push does not reset the count; per-slice commits and mandatory hosted qualification remain unchanged.

## Consequences

- Decision `0062` becomes historical while its completed-push evidence stays exact.
- Fewer routine pushes trade a wider remote-durability interval for throughput while retaining local task-scoped crash recovery; the threshold never authorizes batched slices or skipped hosted-result consumption.
