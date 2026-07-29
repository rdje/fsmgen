# IAL2 Post-Subordinate-Arbitration Next-Owner Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.815`

Date: 2026-07-29

## Outcome

Select proposed `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1` as the next
exact correctness owner after the generated AHB subordinate
output-arbitration tree completed at clean behavior commit `1eec6253d` and the
HIAL/VIAL architecture was parked without changing IAL2 priority at clean
commit `64f056b12`.

This selector changes continuity and documentation only. It does not modify
parser, generator, source, support, test, artifact, semantic/MCP, HDL/runtime,
backend, protocol, verification-generation, or transaction-layer behavior.

## Evidence

The generated endpoint repair removed exactly five redundant IAL1 writes.
Base/rich direct t1519 and paired t1513-t1516/t1523/t1525 now compile and run
with generic selector assertions enabled. Within that current audited AHB
family, only direct-seed t1520 still invokes Verilator with `--no-assert`.

The direct seed authors intentional conditional overrides inside
`fsm/ahb_lite_subordinate.fsm`:

- `access` defaults `HREADYOUT=0`, then successful completion writes
  `HREADYOUT=1`;
- `access` defaults `HRDATA=0`, then a successful read writes
  `HRDATA=reg_data_q`; and
- `access`/`unsupported` default `HRESP=0`, then an error path writes
  `HRESP=1`.

The completed generated-endpoint audit already reproduced these as three
direct-seed bus-output conflicts with all internal selector assertions kept
enabled. The first ordinary assertion failure is the HREADYOUT multi-value
selection. This is direct IAL0 authoring, not the generated
`AhbSubordinate.pm` defect.

The selector's focused guarded gate passed
`t/1211-isf-runtime-selector-conflict-instrumentation.t`,
`t/1219-isf-rule-transaction-priority.t`, and
`t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t`: 3 files / 9
tests in 7 wallclock seconds. That proves current direct success, active-ERROR,
SEQ-to-ERROR, and ERROR-to-IDLE behavior remains deterministic while generic
selector visibility remains authoritative.

## Candidate Comparison

### Selected: direct IAL0 subordinate output arbitration

This is the smallest correctness prerequisite because it owns the only known
remaining assertion exception in the audited AHB endpoint/composition family.
Its task is already isolated from generated IAL2 endpoint behavior, has exact
source and runtime evidence, and requires an exclusive output-mode contract
before any seed change.

### Deferred: exact-three paired composition

The exact-three requester and alias already ship, and the generated endpoint
and fabric families are now assertion-clean. Adding one-/two-subordinate
exact-three paired sources is nevertheless public feature expansion. It should
not precede removal of the existing direct-seed assertion exception.

### Deferred: larger counts, policy, status, bursts, and optional signals

Counts above three and their width contract, runtime/policy/multiple-point
BUSY insertion, distinct local bus-BUSY status, wider or indefinite bursts,
and optional AHB signals are broader public-behavior changes. None resolves the
current direct IAL0 selector conflict.

### Deferred: generic priority enforcement

The direct seed deliberately authors independent default and conditional
different-value writes inside the same states. Generic selector assertions
correctly expose those non-exclusive modes, and the focused generic tests pass.
Changing generic priority would hide the seed's ownership problem rather than
repair it.

### Deferred: HIAL/VIAL and decision 0020

`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE` remains proposed/inactive and
does not change current IAL2 priority. Decision 0020 remains director-owned and
inactive.

## Selected Contract Boundary

After this selector commits cleanly, activate only
`IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1`. That leaf must:

- reconcile the direct seed, t1520, generated selector metadata, and the
  completed diagnostic evidence;
- select mutually exclusive access/wait/read/write/success/unsupported/ERROR
  output modes without changing bounded word-only or two-cycle-ERROR behavior;
- preserve Q-named completion-edge phase capture, exact success/ERROR/SEQ/IDLE
  results, public source/support/artifact identities, and generic assertions;
- freeze a separate implementation leaf before changing the seed or removing
  `--no-assert` from t1520;
- keep generated IAL2 endpoints, other protocols, backends, VHDL, HIAL/VIAL,
  and decision 0020 unchanged; and
- use repository-derived same-volume disposable storage plus the
  director-authorized macOS `--host-max-pct 100 --process-max-rss-mb 4096`
  profile, reporting exact Stats-compatible capacity and kernel pressure state
  separately.

## Rollback

Before child activation, rollback removes this selector record/fact and the
`.815` selection state only. After activation, rollback follows the direct
IAL0 task tree and keeps contract selection separate from implementation.
