# IAL2 AHB Interconnect Default/Decode Output-Arbitration Behavior

Task-tree owner:
`IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.3`

Date: 2026-07-29

## Outcome

Generated AHB interconnect IAL0 now gives every affected output exactly one
enabled value family per cycle. Generic selector analysis and generated
`onehot0` assertions remain enabled; the repair is local to
`perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm`.

Public AHB source syntax, ports, decode windows, report schemas, support
accounting, generated artifact names, semantic JSON, read-only MCP behavior,
and transaction behavior are unchanged.

## Per-Window Decode Modes

For each static subordinate window, the generator emits complementary modes:

```text
mapped_hit:
  HSEL_*  = 1
  HADDR_* = HADDR - window_base

!mapped_hit:
  HSEL_*  = 0
  HADDR_* = 0
```

Address zero is intentionally covered by the mapped family even though its
translated value equals the default. One-window and two-window fabrics use the
same construction independently for every subordinate.

## Global Response Modes

`HREADY`, `HRESP`, and `HRDATA` now select one of three exclusive modes:

1. A retained data-phase owner forwards its subordinate ready, response, and
   read data.
2. A first-cycle unmapped active transfer drives `HREADY=0`, `HRESP=ERROR`,
   and zero read data before entering `unmapped_error_complete`.
3. The ordinary default applies only under
   `!any_owner && !unmapped_address`, driving ready/OKAY/zero.

The independent per-owner blocks remain independent. An impossible
multiple-owner state is therefore still visible to the generic selector
assertions instead of being hidden by priority masking.

## Preserved Behavior

The repair preserves:

- fixed single-requester `HGRANT=1` and input visibility;
- owner capture, wait-state retention, successful/ERROR retirement, and
  same-edge mapped replacement;
- static decode and local-address translation;
- subordinate one-bit response mapping to requester two-bit OKAY/ERROR;
- interconnect-owned two-cycle unmapped ERROR; and
- the existing mapped-owner-to-unmapped non-promise.

## Assertion Boundary

Focused `t/1530-ial2-ahb-interconnect-output-arbitration.t` directly
instantiates generated one-window and two-window `ahb_interconnect` modules
without `--no-assert`. It covers mapped address zero and nonzero, status and
control windows, local translation, wait, success, subordinate ERROR,
same-edge mapped replacement, and two-cycle unmapped ERROR.

At this interconnect slice's commit, paired aggregate tests `t/1513`-`t/1516`,
`t/1523`, and `t/1525` retained `--no-assert` for the separately tracked
generated subordinate overlap. That later endpoint repair now ships under
`IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.3`; all six paired
tests run with repaired-fabric and generated-endpoint assertions enabled. See
`IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_BEHAVIOR.md`.

## Validation

The implementation passed Perl syntax checks, updated structural tests
`t/1478` and `t/1480`, assertion-enabled direct-fabric `t/1530`, paired
preservation `t/1513`-`t/1516`, `t/1523`, and `t/1525`, current-surface
truthfulness `t/1518`, and broad accounting/capability tests `t/248` and
`t/297`. The broad pair completed 6,911 assertions.

Heavy gates used the director-authorized macOS verification profile
`--host-max-pct 100 --process-max-rss-mb 4096`. Host capacity was observed
with the Stats-compatible VM formula, while
`kern.memorystatus_vm_pressure_level` supplied the independent safety state;
the kernel state remained normal during the final verification.

## Rollback

Rollback restores the former unconditional idle defaults and mapped/owner
blocks together with `t/1478`, `t/1480`, and `t/1530`. It does not change the
separately owned subordinate assertion boundary.
