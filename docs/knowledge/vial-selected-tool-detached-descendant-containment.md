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
  - "can a stalled ps or lsof suspend ProcessSupervisor?"
  - "how are selected-tool host observers bounded?"
  - "can a wall-clock adjustment change selected-tool cleanup?"
  - "which clock bounds selected-tool TERM and KILL containment?"
  - "can selected-tool SIGKILL reap block ProcessSupervisor?"
  - "how is the exact selected-tool leader reaped after SIGKILL?"
  - "can EINTR make a live selected tool look reaped?"
  - "how does ProcessSupervisor retry interrupted waitpid polls?"
  - "can an interrupted host-observer wait hide a failing command?"
  - "can repeated EINTR suspend a selected-tool host observer read?"
  - "where is the host-observer deadline checked after interrupted sysread?"
  - "can a host-observer failure mask an expired selected-tool timeout?"
  - "what wins when selected-tool observation fails at the tool deadline?"
  - "when does selected-tool observation remain a host error?"
  - "can EINTR suspend containment-pipe holder attribution?"
  - "can interrupted pipe reads suspend post-kill holder absence?"
  - "which deadlines bound selected-tool containment-pipe reads?"
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
  t/1756-vial-selected-tool-host-observer-deadline.t;
  t/1757-vial-selected-tool-monotonic-containment.t;
  t/1758-vial-selected-tool-bounded-leader-reap.t;
  t/1759-vial-selected-tool-interrupted-wait.t;
  t/1760-vial-selected-tool-interrupted-observer-read.t;
  t/1761-vial-selected-tool-observation-timeout-precedence.t;
  t/1762-vial-selected-tool-interrupted-containment-pipe-read.t;
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
  t/1756-vial-selected-tool-host-observer-deadline.t
  t/1757-vial-selected-tool-monotonic-containment.t
  t/1758-vial-selected-tool-bounded-leader-reap.t
  t/1759-vial-selected-tool-interrupted-wait.t
  t/1760-vial-selected-tool-interrupted-observer-read.t
  t/1761-vial-selected-tool-observation-timeout-precedence.t
  t/1762-vial-selected-tool-interrupted-containment-pipe-read.t
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

The `ps` and Darwin `lsof` observers cannot suspend supervision. Each exact
command runs directly through an owned pipe/fork/exec path inside the existing
supervisor containment domain. Setup pipe authentication has an independent
deadline, live process observations share the selected-tool deadline, and
post-timeout or residue cleanup receives a separate bounded observer interval.
Output is drained nonblockingly under the structural census cap. A helper that
does not exit is terminated and reaped by exact owned PID; the caller receives
an explicit host or residue failure, and no detached helper domain remains.

All selected-tool TERM/KILL grace and descendant/holder absence deadlines use
`CLOCK_MONOTONIC`, matching execution and observer supervision. An executable
control replaces the module's wall-time function with backward and forward
steps while independently measuring monotonic elapsed time. Both paths retain
the intended grace, kill and reap the exact tool, leave no process-group
residue, and prove the injected wall clock was never called.

After SIGKILL, exact-leader reap is nonblocking and monotonically bounded. The
supervisor polls its owned PID with `WNOHANG`, retains the delivered wait
status, and completes any process-group absence check before returning or
raising residue. An executable control replaces only the former blocking wait
with a non-completing injection; the repaired path never calls it, returns the
signal status, and leaves no process-group residue.

Every nonblocking owned-child wait distinguishes interruption from completion.
`EINTR` returns pending to the caller's existing monotonic loop; it cannot mark
the selected-tool leader or a host observer reaped, cannot manufacture a
successful helper-command status, and cannot erase the exact wait status. The
poll helper performs only one syscall per call, so repeated interruptions still
encounter the enclosing deadline rather than entering an unbounded internal
retry. The five-phase executable control covers selected-tool exit, TERM,
post-SIGKILL reap, host-observer cleanup, and bounded host-command completion.
Its falsification leg demonstrated a real `exit 42` becoming `exit_code 0`
under the old exit poll; all repaired cases retain exact exit/signal evidence
and leave no process-group residue.

Interrupted host-observer reads also yield to deadline authority. `EINTR`
leaves the inner output-drain attempt, after which the outer command loop polls
the exact helper, checks `CLOCK_MONOTONIC`, and sleeps before another attempt.
The read path cannot spin indefinitely inside an immediate retry. Successful
payload/EOF handling, EAGAIN/EWOULDBLOCK, the structural output cap, the exact
deadline diagnostic, and owned-helper TERM/reap semantics remain distinct. A
sustained-interruption executable control reaches the declared observer
deadline, returns its exact error, exits cleanly, and leaves no process-group
residue.

Observation failure cannot mask an already expired selected-tool deadline.
Both live-stream and post-EOF observation phases capture the monotonic instant
at which observation fails. Detection on or after the selected-tool deadline
uses the normal timeout containment and result path; detection before the
deadline retains `VIAL_PROCESS_HOST_ERROR`. The executable boundary control
forces both deadline races and an independently early failure, then requires
exact timeout/timeout/host-error precedence, clean probe exit, and zero
process-group residue.

Containment-pipe reads cannot suspend either holder-attribution entry or the
post-kill absence loop. The first observation receives the cleanup deadline;
the later observations receive the existing two-second absence deadline.
`EINTR` yields and rechecks that monotonic bound, while EOF, EAGAIN/live-writer,
and structurally bounded payload drain remain distinct results. The executable
control interrupts from the first read, then separately permits one live-writer
read and one real holder kill before sustaining interruption; both phases
return the exact bounded error and leave zero process-group residue.
