# IAL2 AHB Interconnect Default/Decode Output-Arbitration Audit

Task-tree owner:
`IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1`

Date: 2026-07-29

## Outcome

The shipped generated AHB interconnect has an AHB-generator-local selector
overlap. In its `idle` state, the generated IAL0 enables unconditional output
defaults together with mapped-hit, retained-data-owner, or unmapped-ERROR
output drives. The generic lowering preserves those independent source
families and correctly emits `onehot0` assertions; weakening that analysis
would hide the generated ambiguity and affect unrelated FSMs.

The complete conflicting output set is:

- one window: `HADDR_REGS`, `HSEL_REGS`, `HRDATA`, `HREADY`, and `HRESP`;
- two windows: `HADDR_STATUS`, `HSEL_STATUS`, `HADDR_CONTROL`,
  `HSEL_CONTROL`, `HRDATA`, `HREADY`, and `HRESP`.

Generated metadata also instruments `HGRANT`, one `ahb_data_owner_N_q` target
per window, and `next_state`. Those selectors are state- or
condition-exclusive and are not part of the defect.

This audit changes no parser, generator, public source, support identity,
report, artifact, semantic/MCP API, HDL, runtime, backend, protocol, or
transaction-layer behavior. It selects proposed child `.2` to freeze an exact
generator-local mutually exclusive arbitration contract before repair.

## Fresh Base Reproduction

The audit generated `ppif/ahb_interconnect.ppif` into the task-owned,
same-volume disposable workspace
`.artifacts/tmp/ial2-lowering/ahb-interconnect-arbitration-audit-r1/` and
compiled a SystemVerilog harness without `--no-assert`. The harness issued one
mapped request with a decimal `+ADDR` argument.

Separate runs reproduced the same first failure:

```text
AUDIT mapped address=0
[315] ... dut.fabric: selector multi-value conflict: HADDR_REGS

AUDIT mapped address=2
[315] ... dut.fabric: selector multi-value conflict: HADDR_REGS
```

Both runs exited nonzero through the generated assertion. Address zero is the
important negative control: the selected local address happens to equal the
default value, but the lowering still sees two independently enabled RHS
families, `0` and `HADDR`. The conflict is therefore selector ownership, not
merely unequal runtime values.

## Generated Selector Inventory

Fresh `FSM::Pipeline::HDLGenerator` metadata reports eight selector targets
for the one-window interconnect and eleven for the two-window interconnect.
The target counts include safe state/owner targets as well as the conflicting
outputs.

| Target family | One window | Two windows | Generated sources | Audit result |
| --- | --- | --- | --- | --- |
| subordinate address | `HADDR_REGS` | `HADDR_STATUS`, `HADDR_CONTROL` | idle `0`; mapped local address | conflicting on each mapped hit |
| subordinate select | `HSEL_REGS` | `HSEL_STATUS`, `HSEL_CONTROL` | idle `0`; mapped `1` | conflicting on each mapped hit |
| requester read data | `HRDATA` | `HRDATA` | idle `0`; retained-owner `HRDATA_*` | conflicting while an owner supplies data |
| requester ready | `HREADY` | `HREADY` | idle `1`; unmapped `0`; retained-owner `HREADYOUT_*` | conflicting on unmapped first cycle and retained-owner response |
| requester response | `HRESP` | `HRESP` | idle OKAY; unmapped ERROR; retained-owner OKAY/ERROR | conflicting on unmapped ERROR and owner ERROR paths |
| fixed grant | `HGRANT` | `HGRANT` | fixed `1` in mutually exclusive FSM states | safe; not selected for repair |
| data owner | `ahb_data_owner_0_q` | `ahb_data_owner_0_q`, `ahb_data_owner_1_q` | accept `1`; completion without replacement `0` | safe because clear explicitly excludes accept |
| FSM transition | `next_state` | `next_state` | `idle`; `unmapped_error_complete` | safe because source states are exclusive |

The one-window metadata is exact:

- `HADDR_REGS`: `haddr_regs_0_en` versus `haddr_regs_haddr_en`;
- `HSEL_REGS`: `hsel_regs_0_en` versus `hsel_regs_1_en`;
- `HRDATA`: `hrdata_0_en` versus `hrdata_hrdata_regs_en`;
- `HREADY`: `hready_0_en`, `hready_1_en`, and
  `hready_hreadyout_regs_en`;
- `HRESP`: `hresp__2_b0_en` versus `hresp__2_b1_en`.

The two-window metadata replicates the address/select families per authored
window. Its global muxes expand to `HRDATA_*` and `HREADYOUT_*` sources for
both status and control owners. This proves the cardinality change is a
generator-loop replication of one defect, not a second lowering problem.

## IAL0 Ownership Trace

`FSM::IAL2::ProtocolIntent::AhbInterconnect::_build_ahb_interconnect_fsm`
currently emits these independent `idle`-state families:

```text
unconditional defaults:
  HREADY <- 1
  HRESP  <- OKAY
  HRDATA <- 0
  HSEL_* <- 0
  HADDR_* <- 0

per-window mapped hit:
  HSEL_* <- 1
  HADDR_* <- local_address

per retained data owner:
  HREADY <- HREADYOUT_*
  HRDATA <- HRDATA_*
  HRESP  <- mapped HRESP_*

unmapped first cycle:
  HREADY <- 0
  HRESP  <- ERROR
  HRDATA <- 0
  HSEL_* <- 0
  HADDR_* <- 0
```

The generated FSM backend groups identical RHS values where appropriate, but
it does not and must not choose priority between different active RHS
families. `FSM::IR::LoweredRTLIRBuilder` derives the family enables and
`FSM::Backend::GeneratedModuleEmitter` emits the runtime assertions. Their
metadata and HDL agree exactly with the authored IAL0, so neither generic
component owns the repair.

## Past-Change Audit

The relevant historical changes predate this task-tree and are now accounted
for here:

- commit `ab4838dd5` introduced the one-window generated interconnect,
  including idle defaults, mapped-hit output drives, response muxing, and the
  two-cycle unmapped state;
- commit `700ff29dd` generalized the same shape across two subordinate
  windows, including per-window zero defaults and mapped local-address/select
  drives;
- commit `3e1dcc930` correctly added retained data-phase ownership and moved
  `HREADY`/`HRESP`/`HRDATA` response selection from current-window hits to the
  retained owner, while leaving the pre-existing unconditional global
  defaults in place.

The first two commits originated the default/decode overlap. The third did
not create the address/select defect, but it preserved and made explicit the
global default/owner overlap. Later aggregate tests t1513, t1515, t1523, and
t1525 compile with `--no-assert`, so their functional results did not expose
the interconnect selector assertions. The separate requester-only
assertion-enabled proofs are unaffected.

## Selected Repair Owner

Proposed child
`IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.2` owns exact contract
selection. The selected direction is limited to generated
`AhbInterconnect.pm` IAL0 shape:

1. each subordinate address/select output must have mutually exclusive
   mapped-hit versus not-hit drives in `idle`;
2. global `HREADY`/`HRESP`/`HRDATA` must have mutually exclusive retained
   owner, current unmapped-first-cycle, and ordinary-default drives;
3. an impossible multiple-owner condition must remain visible to generated
   selector assertions rather than be priority-masked;
4. fixed `HGRANT`, input visibility, owner capture/clear/replacement,
   `unmapped_error_complete`, and `next_state` behavior remain unchanged;
5. generic lowered-RTL selector analysis and assertion emission remain
   unchanged and enabled.

The contract must preserve current decode windows, local address translation,
selected/unselected child behavior, retained data-phase ownership, response
mapping, wait states, subordinate ERROR behavior, interconnect-owned two-cycle
unmapped ERROR, and the existing documented non-promise for a mapped owner
completion directly into a new unmapped address phase.

## Validation Boundary For The Future Repair

Before implementation, `.2` must freeze an assertion-enabled gate that
covers:

- base one-window mapped address zero and nonzero in-window requests;
- one- and two-window mapped success, wait-state, subordinate ERROR, and
  interconnect-unmapped ERROR cases;
- status/control select and local-address exclusivity;
- retained-owner `HREADY`/`HRESP`/`HRDATA`, completion, and same-edge mapped
  replacement;
- removal of `--no-assert` from the affected paired aggregate runtime family,
  including exact-one and exact-two one-/two-subordinate proofs;
- unchanged public source bytes, support identities/counts, report schemas and
  payloads, exact IAL1/IAL0 artifact names, normalized semantic JSON,
  read-only MCP behavior, ports, and current mdBook examples;
- focused t1478/t1480 shape checks, new focused runtime proof, paired
  preservation, t1518, t248/t297, mdBook, Knowledge Map, memory/path/diff, and
  doctrine gates.

All heavyweight commands remain under the unchanged 88% host / 4096-MiB
descendant RAM guard. Initial attempts correctly stopped before work at 97.3%
host use while an unrelated external compiler was active. After it released
memory, guarded generation began at 65.6%, compilation at 69.1%, the two base
runtime probes at 73.2% and 75.3%, the one-window metadata run at 78.6%, and
two-window generation/metadata at 81.7%/85.5%; every admitted command stayed
below both fixed limits.

The disposable workspace contained exactly 45 files / 2,663,969 bytes after
the probes. That exact task-owned directory was removed after the evidence was
recorded, and a path census confirmed no residue. Pre-existing artifacts
elsewhere under `.artifacts/` were not changed.

## Closeout Validation

Knowledge Map generation/check passes at 1,008 facts and 5,124 question keys.
The mdBook builds successfully under the fixed guard and its generated output
was removed. Memory architecture, relative document paths, the bounded README
entry point, project-data locality, diff checks, fact reverify commands, and
all registered doctrine gates pass.

## Rollback

This audit has no behavior to roll back. Revert its record/fact and proposed
child only if the evidence is invalidated. Any later repair must roll back the
generated IAL0 arbitration and its assertion-enabled tests together; removing
or weakening generic selector assertions is not an acceptable rollback.
