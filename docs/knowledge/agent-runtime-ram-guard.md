---
id: agent-runtime-ram-guard
title: Agent heavyweight commands must use the RAM guard
answers:
  - "how should agents run broad prove or fsmgen commands without exhausting RAM?"
  - "what RAM limit should agent-launched Perl commands use?"
  - "what should happen if a broad supported-corpus run hits the RAM guard?"
  - "which script guards heavy local commands from reaching 90 percent host RAM?"
date: 2026-06-21
status: current
tags: [agent-runtime, ram, process-safety, prove, fsmgen, continuity]
evidence: scripts/run_with_ram_guard.sh; README.md; COMMIT.md; docs/tasks/AGENT-RUNTIME-RAM-GUARD.md; MEMORY.md
reverify: scripts/run_with_ram_guard.sh --help | rg 'host-max-pct|process-max-rss-mb|4096'
---

Agent-launched heavyweight local commands, especially broad
Perl/`prove`/`fsmgen` runs, must use `scripts/run_with_ram_guard.sh` or an
equivalent active monitor.

The default guard stops the command tree at 88% host memory or when any
descendant reaches 4096 MiB RSS. Those defaults stay below the user's 90%
host-RAM danger zone. If the guard trips, stop the broad run, record a
resource caveat in the owning task-tree leaf, and continue with narrower
focused checks unless the user explicitly authorizes a different cap.
