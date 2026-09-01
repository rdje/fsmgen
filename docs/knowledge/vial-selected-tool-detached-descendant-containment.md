---
id: vial-selected-tool-detached-descendant-containment
title: VIAL selected-tool containment crosses process-group and sampling boundaries
answers:
  - "can a selected VIAL tool escape process supervision with setsid?"
  - "how does ProcessSupervisor contain a detached selected-tool descendant?"
  - "why is process-tree sampling not the selected-tool cleanup proof?"
  - "what is the difference between lifecycle and outer-worker process containment?"
  - "how does VIAL find a selected-tool process holding the containment pipe?"
  - "does a detached selected-tool child survive timeout cleanup?"
  - "can ProcessSupervisor contain a daemon that closes every inherited descriptor?"
date: 2026-09-01
status: current
tags: [vial, process-supervisor, containment, verilator, ghdl]
evidence: >-
  perl/FSM/VIAL/Backend/ProcessSupervisor.pm;
  t/1640-vial-runner-capture-limits.t;
  t/1664-vial-verilator-shared-lifecycle.t;
  t/1673-vial-ghdl-shared-lifecycle.t;
  t/1678-vial-ghdl-provider-aware-lifecycle.t;
  t/1724-vial-runtime-process-envelope.t;
  t/1755-vial-selected-tool-detached-descendant-containment.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/1640-vial-runner-capture-limits.t
  t/1664-vial-verilator-shared-lifecycle.t
  t/1673-vial-ghdl-shared-lifecycle.t
  t/1678-vial-ghdl-provider-aware-lifecycle.t
  t/1724-vial-runtime-process-envelope.t
  t/1755-vial-selected-tool-detached-descendant-containment.t
---

`FSM::VIAL::Backend::ProcessSupervisor` serves both public lifecycle execution
and process-isolated architecture measurement. Its lifecycle policy owns a
fresh process group; its outer-worker policy deliberately borrows the common
worker's group. Exact detached-PID containment applies to both, while
whole-group TERM/KILL applies only to the lifecycle-owned group.

The supervisor records bounded process-tree observations while the selected
leader is alive. Those observations retain PID, parent, and process-start
identity and catch sustained descendants even after their inherited descriptor
state changes. They are not accepted as a completion proof: an executable RED
showed that a child can fork, call `setsid`, and lose an immediately exiting
leader between observations.

A separate hidden pipe writer therefore crosses exec. The supervisor requires
EOF before returning. If a descendant retains the writer after leader exit,
Darwin discovers exact current-user holders from the authenticated `lsof`
endpoint identity; Linux matches the authenticated pipe inode below
`/proc/*/fd`. Only that residue path performs the holder census. Exact holders
are stopped, killed, and required absent before result or lifecycle cleanup can
continue. Structurally bounded reads drain untrusted pipe payload without
changing its EOF/live-writer meaning, so payload cannot bypass holder cleanup.

A zero-exit leader with residue returns
`VIAL_PROCESS_RESIDUE_ERROR`. Timeout remains the primary result, but only after
group-owned and exact-holder containment completes. The executable watcher
closes captured stdout/stderr, uses zero dwell for normal exit, and covers
normal/timeout behavior under both containment policies. It also proves the
detached PID cannot recreate staging after simulated lifecycle cleanup.

This is private process-integrity behavior. It changes no selected command,
deadline, output limit, backend support, artifact graph, performance claim,
scale capacity, reached boundary, or public API.

The admitted boundary is synchronous and caller-sealed, not a general daemon
job object. The exact GHDL/Verilator lifecycle and qualification profiles may
not deliberately close every inherited nonstandard descriptor, call `setsid`,
and outlive an immediately exiting leader. An executable control proved that
such a child can cross the group, sampling, and writer proofs. The current
macOS `EVFILT_PROC` contract reports a fork but does not deliver or automatically
track the child PID, so it is not a missing generic containment mechanism.
Future daemonizing profiles require a supported non-cooperative host authority
before admission; faster polling is not sufficient.
