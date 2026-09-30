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
date: 2026-09-30
status: current
tags: [agent-runtime, ram, process-safety, prove, fsmgen, continuity]
evidence: scripts/run_with_ram_guard.sh; README.md; COMMIT.md; docs/tasks/AGENT-RUNTIME-RAM-GUARD.md; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; t/2011-ram-guard-stdin.t; docs/audits/ram-guard-stdin-maintained-use-20260930.json
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2011-ram-guard-stdin.t t/1595-agent-runtime-ram-guard-macos-metric.t t/1811-ram-guard-fixture-runtime.t
---

Agent-launched heavyweight local commands, especially broad
Perl/`prove`/`fsmgen` runs, must use `scripts/run_with_ram_guard.sh` or an
equivalent active monitor.

The default guard stops the command tree at 88% host memory or when any
descendant reaches 4096 MiB RSS. Those defaults stay below the user's 90%
host-RAM danger zone. If the guard trips, stop the broad run, record a
resource caveat in the owning task-tree leaf, and continue with narrower
focused checks unless the user explicitly authorizes a different cap.

The child now explicitly inherits stdin, preserving exact piped/file bytes,
EOF, stdin-fed interpreter programs and independent inherited descriptors.
Previously, the bare asynchronous Bash launch substituted `/dev/null`; a
stdin-fed program could exit zero without running. T2011 independently recovers
the exact old guard from ce4d0029028a3e25f517ea93632cf50f2712354a and reproduces
that empty success, while the repaired launcher passes the same inputs. Existing
cutoff, telemetry, signal and cleanup controls remain qualified.

The fixed-revision maintained-use audit covers tracked root-repository basename
references and explicit continued stdin recipes. Earlier documented empty
captures were rejected and replaced with named-script evidence. This finite
census cannot establish that every historical ephemeral or dynamic invocation
was unaffected; its scope and reviewed interfaces are retained in the audit.
