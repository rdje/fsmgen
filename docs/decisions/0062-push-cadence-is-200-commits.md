---
id: push-cadence-is-200-commits
title: Normal push cadence is 200 accumulated local commits
answers:
  - "how often should this repository push commits?"
  - "how many commits should accumulate before pushing?"
  - "should every commit be pushed immediately?"
  - "does an explicitly requested early push change the normal cadence?"
  - "how is the push cadence counter calculated and reset?"
date: 2026-08-10
status: current
tags: [git, push, commit-workflow, continuity, governance]
evidence: COMMIT.md; docs/tasks/PUSH-CADENCE-GOVERNANCE.md
reverify: rg -n '200 accumulated local|rev-list --count|early push' COMMIT.md
---

# 0062 — Push cadence is 200 commits

- Date: 2026-08-10
- Type: feedback/governance
- Status: accepted (supersedes [0005](0005-push-only-on-explicit-request.md))
- Owner: `PUSH-CADENCE-GOVERNANCE.1`

## Context

Decision `0005` retired an earlier short cadence and required explicitly
requested pushes. The director has now selected one normal push per 200 local
commits and authorized a one-time catch-up at `de9d50a5f`. That exception did
not change the standing interval.

Per-slice commits protect task recovery; batched pushes protect remote
durability without publishing every small commit.

## Decision

1. The normal automatic push cadence is one successful push after 200 local
   commits have accumulated beyond the configured upstream.
2. Derive the current count with
   `git rev-list --count @{upstream}..HEAD`. Do not store or increment a second
   mutable counter that can drift from Git.
3. Run the normal push only after the 200th slice is fully committed through
   `COMMIT.md` and the worktree is clean. Verify that a successful push leaves
   the upstream-ahead count at zero; that success begins the next interval.
4. The director may explicitly request a push before the threshold. A
   successful early push also begins a fresh interval, but the normal cadence
   remains 200 commits.
5. An unsuccessful push never resets the interval. Preserve the local commits
   and resolve or report the exact remote-state blocker before treating the
   repository as remotely durable.
6. Per-slice commit discipline is unchanged. In particular, this cadence must
   never be interpreted as permission to combine 200 slices into one commit or
   to push every individual commit.

## Consequences

- The count is exact and recoverable from Git in a fresh session.
- PNT publishes at the 200-commit boundary; an explicit early push does not
  silently shorten later intervals.
- Decision `0005` is historical rather than operative.
