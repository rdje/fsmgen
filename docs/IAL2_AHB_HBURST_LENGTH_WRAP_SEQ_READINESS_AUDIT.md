# IAL2 AHB HBURST Length/Wrap SEQ Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.762`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.762` audits bounded AHB
HBURST-driven length/wrap `SEQ` readiness and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.763`, a no-behavior public contract
selection for the first endpoint-only HBURST-aware byte-lane `SEQ` source
family.

Direct implementation is not selected in this slice. The current requester
already drives `HBURST`, tracks burst length, and computes increment/wrap
address progression, but the current subordinate source contract has no
`HBURST` bus binding and the aggregate interconnect does not forward a
subordinate-local burst signal. A public source/report contract must be
selected before behavior changes.

This audit changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The audit read:

- `.761`, the selector that routed HBURST length/wrap readiness after
  aggregate byte-lane `SEQ` `.ahb` alias shipment;
- `.760` aggregate byte-lane `SEQ` `.ahb` alias behavior;
- `.758` aggregate byte-lane `SEQ` `.ppif` behavior;
- `.754` endpoint byte-lane `SEQ` `.ahb` alias behavior;
- `.752` endpoint byte-lane `SEQ` `.ppif` behavior;
- `.751` first bounded subordinate-side `SEQ` contract selection;
- shipped requester, endpoint subordinate, and aggregate byte-lane `SEQ`
  source samples;
- `perl/FSM/Adapter/IAL2/PPIF.pm`;
- `perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm`;
- `perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm`;
- `perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm`;
- support-accounting and language-surface owners;
- focused AHB tests `t/1486`, `t/1487`, `t/1488`, and `t/1489`;
- README, ROADMAP_V2, mdBook backlog/AHB chapter, task tree, Memory, Knowledge
  Map, and decisions `0014`, `0015`, `0016`, and `0018`.

## Current Requester Boundary

Requester support is not the first blocker. The shipped requester source and
generator already expose:

```text
cmd_burst
cmd_len
HBURST
active_hburst
burst_active
wrap_active
beat_index
beats_remaining
active_addr
```

`AhbRequester` normalizes `SINGLE`, `INCR`, `WRAP4`, `INCR4`, `WRAP8`,
`INCR8`, `WRAP16`, and `INCR16`, computes beat totals, computes wrap base and
wrap high addresses, drives first beat `NONSEQ`, drives later beats `SEQ`, and
updates `HADDR` by either incrementing or wrapping on accepted beats.

That requester-generated behavior remains a useful upstream stimulus and
comparison point. It does not make subordinate HBURST semantics public, because
the subordinate contract currently cannot see `HBURST`.

## Current Subordinate Boundary

The selected endpoint `SEQ` source has no `HBURST` bus binding:

```text
(bus
  (select HSEL)
  (ready-in HREADY)
  (address HADDR width 32)
  (transfer HTRANS width 2)
  (write HWRITE)
  (size HSIZE width 3)
  (write-data HWDATA width 32)
  (ready-out HREADYOUT)
  (response HRESP width 1)
  (read-data HRDATA width 32))
```

A focused parse probe confirmed that adding a candidate subordinate bus clause:

```text
(burst HBURST width 3)
```

currently fails closed with:

```text
Error: .ppif (ahb-subordinate ahb_lite_subordinate_byte_lane_seq bus ...) has unsupported clause '(burst ...)'
```

The current `seq-policy in-word-progressive` report covers byte/halfword
in-word continuation only:

```text
mode: in_word_progressive
supported_sizes: [byte, halfword]
address_progression: previous_address_plus_size_bytes
control_stability: [HWRITE, HSIZE]
clears_on: [reset, idle, busy, error, new_nonseq]
```

The generated subordinate state is sufficient for a bounded extension: it
already stores continuation validity, expected address, size, and direction.
No generated-IAL1/IAL0/SystemVerilog substrate repair is evident before a
contract-selection slice, but the public bus and report schema are not yet
selected for HBURST-aware behavior.

## Current Aggregate Boundary

The selected aggregate byte-lane `SEQ` sources have requester/fabric `HBURST`
on the top AHB bus, and `AhbInterconnect` validates global burst/protection
width compatibility against the requester. The generated interconnect currently
uses global `HBURST` only for input visibility; it does not forward any
subordinate-local `HBURST_*` signal.

A generated interconnect probe for `ppif/ahb_interconnect_byte_lane_seq.ppif`
reported:

```text
global_hburst_refs=3
subordinate_hburst_refs=0
subordinate_select_refs=5
subordinate_addr_refs=5
```

Current aggregate tests assert local-address, `HSIZE`, and `HWRITE`
propagation into byte-lane `SEQ` subordinates, and the report records
`composition.seq_policy_propagation` with:

```text
mode: subordinate_owned_in_word_seq_policy
local_address_policy: subtract_window_base_before_subordinate_seq_policy
```

That means aggregate propagation should follow the endpoint contract. It should
not be included in the first HBURST implementation owner, because aggregate
HBURST forwarding needs its own source/report/wiring boundary after the
endpoint subordinate contract exists.

## Readiness Findings

The first HBURST length/wrap step should extend the byte-lane `SEQ`
subordinate contract, but it should do so through a new generic endpoint source
family rather than mutating the shipped `ppif/ahb_lite_subordinate_byte_lane_seq.ppif`
source.

Reasons:

- preserving the shipped in-word `SEQ` source keeps existing support
  accounting, report shape, generated artifacts, and focused tests stable;
- the parser currently rejects subordinate `(burst ...)`, so direct behavior
  would require public syntax work first;
- the report must name which HBURST modes are supported, how length/wrap
  windows are derived, which unsupported HBURST/HSIZE/address combinations
  fail closed, and how residue narrows;
- aggregate wiring currently has no subordinate-local burst signal, so
  aggregate-inclusive behavior would mix endpoint semantics with aggregate
  forwarding work; and
- BUSY-in-burst parking and multi-word/register-bank progression are not
  prerequisites for a first bounded endpoint subset if the new contract
  explicitly leaves them fail-closed/deferred.

No IAL1/IAL0/SystemVerilog prerequisite is selected. Current generated IAL1 can
express local state, address comparisons, counters, and branch structure, and
the requester already proves increment/wrap arithmetic is representable in the
current generated path. The missing work is public contract selection followed
by a scoped implementation.

## Selected `.763` Scope

`.763` must select the public contract for a bounded endpoint-only
HBURST-aware byte-lane `SEQ` source family before behavior changes.

The contract selection must decide:

- the exact new source path and whether the matching `.ahb` alias is a later
  owner;
- the new subordinate bus clause for `HBURST`;
- whether the policy is an extension of `seq-policy` or a new explicit
  burst/length policy clause;
- the first supported HBURST modes and which modes stay fail-closed;
- how burst length, wrap window, address progression, `HSIZE`, `HWRITE`, and
  reset/ERROR/new-`NONSEQ` history are represented;
- whether any useful first subset should be byte-only, byte-plus-halfword,
  fixed-length only, wrap-only, increment-only, or another bounded form;
- generated `.isf`, `.fsm`, and HDL review-artifact names;
- report keys, residue movement, support-accounting identity, diagnostics, and
  preservation expectations; and
- focused validation for parser/report shape, strict check JSON, schedule JSON,
  semantic JSON, generated review text, HDL generation, and existing-source
  preservation.

The selected `.763` owner must not implement parser/generator behavior or add a
public source sample. It should produce the exact implementation owner if the
contract is ready, or select a narrower prerequisite if the contract evidence
finds one.

## Explicit Non-Selections

This audit does not select:

- direct HBURST length/wrap implementation;
- mutation of the existing byte-lane in-word `SEQ` source;
- aggregate-inclusive HBURST propagation;
- matching `.ahb` alias exposure for a future HBURST-aware source;
- BUSY-in-burst parking/continuation behavior;
- multi-word/register-bank `SEQ` progression;
- optional/property-gated AHB signals;
- broader AHB interconnect/decode cardinality;
- legacy two-bit subordinate `HRESP` compatibility;
- scoreboards or full-manager behavior;
- direct backend behavior;
- verification-output generation;
- backend-language variants;
- AXI/APB behavior; or
- VHDL.

## Validation

Closeout for `.762` is documentation-only plus targeted read/probe evidence:

```bash
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e '...endpoint/aggregate bus and residue probe...'
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e '...candidate subordinate (burst HBURST width 3) fail-closed probe...'
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e '...generated interconnect HBURST forwarding probe...'
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Broad or potentially heavyweight Perl, `prove`, or `fsmgen` commands remain
behind `scripts/run_with_ram_guard.sh` or equivalent monitoring.

## Rollback

Rollback is documentation-only: remove this audit, its Knowledge Map fact card,
task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer update,
and regenerated Knowledge Map entries. No runtime behavior is affected.
