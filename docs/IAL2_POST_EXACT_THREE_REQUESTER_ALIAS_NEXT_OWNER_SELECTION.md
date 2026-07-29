# IAL2 Post-Exact-Three Requester Alias Next-Owner Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.813`

Date: 2026-07-29

## Outcome

Select proposed
`IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1`, a
documentation-and-runtime readiness audit of the shipped AHB interconnect's
overlapping idle-default and mapped-decode output selectors. Activate that
child only after this selector commits cleanly.

No parser, generator, public source, support entry, test, artifact,
semantic/MCP API, HDL/runtime, backend, protocol, or transaction-layer
behavior changes in this selector.

## Current Checkpoint

The complete exact-one, exact-two, and exact-three requester lineage now ships
through generic `.ppif` and matching `.ahb` surfaces. Exact-three uses the
existing width-two counter and assertion-enabled requester runtime directly
proves `3 -> 2 -> 1 -> 0`. The one- and two-subordinate exact-two paired
families, their aliases, and the exact-three requester alias establish the
current checkpoint:

```text
322 protocol fixtures
363 supported-smoke and strict-supported fixtures
46 AHB IAL2 paths: 23 .ppif + 23 .ahb
```

This leaves exact-three paired compositions as an additive feature candidate,
but not as the next safe owner.

## Correctness Evidence Takes Priority

`AhbInterconnect` currently emits both selector families below in its `idle`
state for every subordinate:

```text
unconditional state default:
  HSEL_<SUBORDINATE>  <- 0
  HADDR_<SUBORDINATE> <- 0

mapped active-transfer branch:
  HSEL_<SUBORDINATE>  <- 1
  HADDR_<SUBORDINATE> <- local_address
```

The first family comes from `subordinate_idle_lines`; the second comes from
`subordinate_hit_blocks`. A mapped transfer enables both families together.
Existing assertion-enabled evidence stops first at
`selector multi-value conflict: HADDR_REGS`. The overlap is present in the
base non-BUSY interconnect generator and is independent of exact-one/two/three
requester behavior.

The aggregate generated-HDL tests `t/1513`, `t/1515`, `t/1523`, and `t/1525`
all compile with `--no-assert`. Consequently, selecting another paired
composition now would extend a public aggregate family whose selector
assertions are still deliberately disabled. That is not a signoff-level
foundation for the next feature slice.

## Why The General ISF Priority Gap Is Not Selected

The separately tracked
`ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT` finding came from a
disposable requester candidate. Current requester behavior avoids that route,
and assertion-enabled requester-only exact-one/two/three runtime passes. Its
protocol-neutral scheduler question remains valid, but it does not block the
current public AHB requester path.

The interconnect default/decode overlap, by contrast, is emitted by shipped
public aggregate sources today. The AHB-specific audit is therefore the
smaller and more immediate correctness owner.

## Selected Audit Boundary

After clean `.813` commit, activate
`IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1` to:

1. reproduce assertion-enabled mapped transfers in the base non-BUSY
   one-subordinate aggregate at address zero and a nonzero in-window address;
2. trace the complete affected output set across idle defaults, mapped hits,
   retained data-phase ownership, and unmapped ERROR handling;
3. decide whether the smallest repair belongs in AHB-generated IAL0, generic
   FSM output-priority lowering, or shared selector-conflict analysis;
4. freeze a separate repair contract with assertion-enabled base, one-window,
   and two-window runtime gates before behavior changes.

The audit must preserve decode windows, address translation, retained
data-phase ownership, response/read-data routing, unmapped two-cycle ERROR,
requester BUSY behavior, source syntax, reports, exact artifacts, semantic
JSON, and read-only MCP behavior. It must not weaken or remove generated
selector assertions.

## Deferred Alternatives

Until the selected audit resolves ownership, keep separate:

- exact-three one- and two-subordinate paired compositions and aliases;
- literal BUSY counts above three and generalized counter width;
- runtime/policy/random or multiple-point BUSY insertion;
- distinct local bus-BUSY status;
- wider or indefinite bursts and optional AHB signals;
- the protocol-neutral rule-versus-transaction priority owner;
- broader protocols/backends/VHDL; and
- decision 0020 transaction-layer behavior, which remains director-gated and
  inactive.

## Validation And Rollback

This selector is documentation-only. Validate task/index/Memory alignment,
Knowledge Map generation/check, mdBook build, repository-relative docs,
README entrypoint, project-data locality, diff cleanliness, and all doctrine
gates. Remove generated book output before commit.

Rollback removes this selector and fact, restores `.813` as the active
post-alias selector, and leaves both proposed correctness trees inactive. No
runtime or public behavior rollback is required because this slice changes
none.
