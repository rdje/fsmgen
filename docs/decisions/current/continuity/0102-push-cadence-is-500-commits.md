---
id: push-cadence-is-500-commits
title: Normal push cadence is 500 accumulated local commits
answers: ["how often should this repository push commits?", "how many commits should accumulate before pushing?", "should every commit be pushed immediately?", "does an explicitly requested early push change the normal cadence?", "how is the push cadence counter calculated and reset?"]
date: 2026-09-23
status: current
supersedes: push-cadence-is-300-commits
reverify: rg -n '500 accumulated local|rev-list --count|early push' COMMIT.md
---

# 0102 — Push cadence is 500 commits

## Context

The director increased the standing interval from 300 to 500 accumulated local commits. Per-slice commits, explicit early-push authority, and exact hosted qualification remain independent safeguards.

## Decision

1. Push normally after 500 commits beyond upstream; derive the count with `git rev-list --count @{upstream}..HEAD`, never a shadow counter.
2. Changing policy does not reset the count; only a successful push starts a new interval, so existing local commits still count.
3. A successful explicitly directed early push starts a fresh 500-commit interval without changing the standing cadence.
4. A failed or incomplete push does not reset the count; per-slice commits and mandatory hosted qualification remain unchanged.

## Consequences

- Decision `0091` becomes historical while its completed-push evidence stays exact.
- Fewer routine pushes trade a wider remote-durability interval for throughput while retaining local task-scoped crash recovery; the threshold never authorizes batched slices or skipped hosted-result consumption.
