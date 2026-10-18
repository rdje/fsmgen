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
date: 2026-10-18
status: current
tags: [agent-runtime, ram, process-safety, prove, fsmgen, continuity]
evidence: scripts/run_with_ram_guard.sh; README.md; COMMIT.md; docs/tasks/AGENT-RUNTIME-RAM-GUARD.md; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; t/2011-ram-guard-stdin.t; docs/audits/ram-guard-stdin-maintained-use-20260930.json
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2011-ram-guard-stdin.t t/1595-agent-runtime-ram-guard-macos-metric.t t/1811-ram-guard-fixture-runtime.t && scripts/run_with_ram_guard.sh -- python3 -B docs/audits/original-join-parent-acceptance-20261018/verify_inventory_memory.py
---

Heavy local commands (especially Perl/`prove`/`fsmgen`) require
`scripts/run_with_ram_guard.sh` or equivalent monitoring. Defaults stop at
88% host memory or 4096 MiB per descendant, below the user's 90% danger zone.
On trips, stop broad work, log the resource caveat in its task and use focused
checks unless the user authorizes another cap.

Child stdin inherits exact pipe/file bytes, EOF, interpreter programs and
independent descriptors. Bare asynchronous Bash previously used `/dev/null`,
permitting zero exit without execution. T2011 recovers
ce4d0029028a3e25f517ea93632cf50f2712354a and reproduces empty success; the repair
passes identical inputs. Cutoff/telemetry/signal/cleanup controls stay qualified.

The fixed-revision audit covers tracked root-repository basename references
and explicit continued stdin recipes. Earlier empty captures were rejected
and replaced with named-script evidence. It cannot establish that all historical
ephemeral/dynamic invocations were unaffected; scope/reviewed interfaces retain.

Inventory diagnostic: control encoding stops; structural/branch-copy/streamed
repair passes all fixed inputs under the same guard. Original-process allocation
is unobserved; no runtime role/permission is granted.
