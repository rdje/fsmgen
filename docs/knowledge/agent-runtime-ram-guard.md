---
id: agent-runtime-ram-guard
title: Agent heavyweight commands must use the RAM guard
answers:
  - "how should agents run broad prove or fsmgen commands without exhausting RAM?"
  - "what RAM limit should agent-launched Perl commands use?"
  - "what should happen if a broad supported-corpus run hits the RAM guard?"
  - "which script guards heavy local commands from reaching 90 percent host RAM?"
  - "does the RAM guard preserve piped and file standard input?"
  - "why can guarded stdin Python exit successfully without running its program?"
  - "why did the static inventory exceed the RAM guard?"
date: 2026-10-29
status: current
tags: [agent-runtime, ram, process-safety, prove, fsmgen, continuity]
evidence: scripts/run_with_ram_guard.sh; COMMIT.md; docs/audits/ram-guard-stdin-maintained-use-20260930.json; docs/audits/ram-containment-20261029.json.gz
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2011-ram-guard-stdin.t t/1595-agent-runtime-ram-guard-macos-metric.t t/1811-ram-guard-fixture-runtime.t t/2234-ram-guard-descendant-containment.t && scripts/run_with_ram_guard.sh -- python3 -B docs/audits/original-join-parent-acceptance-20261018/verify_inventory_memory.py
---

Broad Perl/prove/fsmgen: `scripts/run_with_ram_guard.sh` or equivalent.
88% host/4096 MiB/descendant; danger 90%; cap changes need user.
Log trips; retry focused. Python3 owns a session before launch;
startup refuses at cutoff. Census includes orphaned nested groups; TERM/freeze/rescan/KILL catches forks. Deliberate session escape needs monitoring.
T2234 rejects the old PPID race; old unmonitored outputs stay unqualified. Fix inspection/cleanup failures.

Stdin: pipe/file bytes, EOF, programs, independent fds. Async Bash
used `/dev/null`: zero exit could mean no execution. T2011's exact
ce4d0029028a3e25f517ea93632cf50f2712354a control fails; repaired stdin passes
cutoff/telemetry/signal/cleanup checks.

Fixed audit: tracked root basenames/continued stdin recipes. Empty captures
reject; named scripts supply evidence. Ephemeral/dynamic impact unknown; scope/interfaces persist. Inventory encoding control stops;
structural/branch-copy/streamed repair passes fixed inputs with unchanged guard.
Original allocation is unobserved; no runtime role/permission.
