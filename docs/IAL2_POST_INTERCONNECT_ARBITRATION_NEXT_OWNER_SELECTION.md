# IAL2 Post-Interconnect-Arbitration Next-Owner Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.814`

Date: 2026-07-29

## Outcome

Select proposed
`IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1` as the next exact
IAL2 correctness owner after the generated AHB interconnect output-arbitration
tree completed at clean commit `6eeac974c`.

This selector changes continuity and documentation only. It does not modify
parser, generator, source, support, test, artifact, semantic/MCP, HDL/runtime,
backend, protocol, or transaction-layer behavior.

## Evidence

The interconnect repair removed the mapped/default fabric overlap and direct
one-/two-window t1530 now passes with generic selector assertions enabled. Six
current paired aggregate runtimes still compile with `--no-assert`:

```text
t/1513
t/1514
t/1515
t/1516
t/1523
t/1525
```

The preceding feasibility probe suppressed only the disposable interconnect
assertion block and left requester/subordinate assertions enabled. It stopped
in the generated subordinate at cycle 345:

```text
selector same-value conflict: HRDATA_REGS 0 enables=01100000
```

The ordered enable vector identifies the generated transaction idle-state
`HRDATA_REGS <- 0` and generated `ahb_phase_capture` rule
`HRDATA_REGS <- 0` as simultaneously enabled. `AhbSubordinate.pm` authors
both source families. The first assertion does not establish the complete
affected output set across base, byte-lane, HBURST/SEQ, BUSY-parking, direct,
and generated endpoint variants, so the next safe step is the existing
no-behavior audit rather than a guessed repair.

## Candidate Comparison

### Selected: subordinate output-arbitration audit

This is the smallest correctness prerequisite because it owns the sole known
remaining reason the current paired AHB family disables assertions. Its audit
leaf already requires exact source/IAL1/IAL0/HDL/runtime evidence, complete
selector mapping, repair-layer selection, preservation, and a separate
contract before behavior changes.

### Deferred: exact-three paired composition

The exact-three requester and alias already ship, but adding their paired
aggregate variants would extend the same endpoint family while subordinate
assertions remain disabled. That is expansion across a known correctness
boundary, so it follows the selected audit.

### Deferred: counts, policy, status, bursts, and optional signals

Counts above three, generalized width, runtime/policy/multiple-point BUSY
insertion, local bus-BUSY status, wider or indefinite bursts, and optional AHB
signals are larger public-behavior changes. None removes the present endpoint
assertion boundary.

### Deferred: generic priority enforcement and decision 0020

The audit must determine whether the overlap is AHB-generator-local or exposes
a generic rule/transaction/default-priority prerequisite. Selecting the generic
priority task before the complete endpoint selector map would pre-judge that
ownership. Decision 0020 remains director-owned and inactive.

## Selected Audit Contract

After this selector commits cleanly, activate only
`IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1`. The audit must:

- reproduce the endpoint failure independently of the repaired interconnect;
- map same-value and multi-value output selectors across current subordinate
  variants and direct/generated forms;
- trace transaction defaults, phase capture/hold, error retirement, wait,
  read/write success, and two-cycle ERROR ownership;
- prove initial capture, wait, same-edge completion/next capture, read, write,
  success, ERROR, SEQ, BUSY, and IDLE boundaries;
- select a separate contract or prerequisite without changing behavior;
- preserve public/report/support/artifact/semantic-MCP/backend surfaces; and
- use same-volume disposable storage plus the director-authorized macOS
  `--host-max-pct 100 --process-max-rss-mb 4096` profile, reporting exact
  Stats-compatible capacity and kernel pressure state separately.

## Rollback

Before child activation, rollback removes this selector record/fact and the
`.814` selection state only. After activation, rollback follows the subordinate
task tree and must keep its audit evidence separate from any later repair.
