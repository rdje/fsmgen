# IAL2 Post-Two-Subordinate Paired BUSY Alias Next Owner Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.804`

Date: 2026-07-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.804` selects the existing canonical
`IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT` tree as the next AHB owner. Its
first leaf must runtime-prove or disprove a suspected requester `WRAP4`
address-progression defect before any repair or further AHB feature expansion.

This selector does **not** activate that tree. The complete one- and
two-subordinate paired BUSY `.ppif`/`.ahb` family is now committed, but the
task-tree pivot rule requires `.804` itself to commit cleanly before the
proposed WRAP tree becomes active. Activation therefore happens only from the
clean post-`.804` repository state.

No parser, generator, public source, support-accounting entry, test, generated
artifact, runtime/HDL behavior, backend, AXI/APB behavior, or VHDL behavior
changes here. Decision `0020` and the protocol-neutral transaction-layer
horizon remain proposed and inactive.

## Evidence Read

The selector reconciled:

- `.801`-`.803` and the complete requester-BUSY, subordinate-BUSY-park, and
  one-/two-subordinate paired composition lineage;
- the public requester sources and generated requester ISF/FSM shape;
- `AhbRequester`, `AhbSubordinate`, `AhbInterconnect`, current unsupported
  residue, focused AHB runtime/parity tests, support accounting, language
  surface, and capability manifest;
- README, ROADMAP_V2, the AHB mdBook chapter and feature backlog, task tree,
  Memory, Knowledge Map, decision `0020`, and the proposed WRAP and
  boundary-free active-transfer audits.

The current requester generator emits this progression after a successful
non-final beat:

```text
when wrap_mode_q:
  when addr_q + addr_step_q == wrap_high_q:
    addr_q = wrap_base_q
  when !(addr_q + addr_step_q == wrap_high_q):
    addr_q = addr_q + addr_step_q
```

The emitted IAL0 FSM preserves the same two sequential clauses. The first can
write `addr_q = wrap_base_q`; the second can then re-evaluate its predicate
against the mutated `addr_q` and overwrite the result with
`wrap_base_q + addr_step_q`. This is the same mutation/retest shape that
previously caused the requester terminal-count defect, but the WRAP concern is
still only source/FSM evidence: no generated-HDL requester test currently
records accepted `WRAP4` addresses through the boundary.

## Why Correctness Audit Comes First

| Candidate | Current evidence | Selection |
| --- | --- | --- |
| Requester `WRAP4` progression audit | Concrete sequential mutation/retest hazard in shipped code; no runtime address-sequence proof | **Selected first** |
| Policy-driven or multiple BUSY insertion | Requires new public control/state policy; bounded one-BUSY behavior already composes end to end | Deferred |
| Distinct local bus-BUSY status | Changes the requester status-port contract; current `local-status.busy` correctly means transaction in progress | Deferred |
| Halfword/word or wider/indefinite bursts | Requires broader multi-word/register-bank progression and larger counters/policies | Deferred |
| Boundary-free active-transfer pipelining | Has a separate proposed audit and needs a larger requester/subordinate phase contract | Deferred behind the narrower WRAP audit |
| Optional AHB signals | Opens orthogonal signal/property contracts without addressing a known correctness risk | Deferred |

The WRAP audit is smaller than every behavior-bearing alternative. It can close
the concern with evidence if the generated HDL is correct, or select one
bounded repair if it reproduces. It does not presume the outcome.

## Selected Audit Contract

After `.804` commits and the repository is clean,
`IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.1` must:

- activate the already-recorded audit owner before adding any probe;
- build a deterministic public-requester generated-HDL `WRAP4` test with a
  starting address that crosses `wrap_high_q` during the four accepted beats;
- record each accepted address and distinguish the required wrap-to-base value
  from an erroneous base-plus-step value;
- correlate the observed sequence with the generated IAL1/IAL0 states and the
  two sequential wrap clauses;
- preserve `SINGLE`, `INCR4`, BUSY insertion, paired compositions, and all
  current source/report/support surfaces;
- make no behavior change in the audit leaf; if the defect reproduces, add and
  select a separate exact repair leaf before editing the generator; and
- synchronize requester behavior docs, mdBook, Knowledge Map, task tree, and
  Memory with the proven result.

Focused validation should reuse the public requester generation path and the
existing requester completion/BUSY tests. Generated-HDL work must use direct
macOS memory-pressure and descendant-RSS observation under the documented
4-GiB process bound.

## Preservation And Rollback

The audit must preserve t/1498 requester BUSY behavior, t/1513/t1515 paired
runtime behavior, t/1514/t1516 alias parity, existing support counts, and all
current AHB source/report/artifact contracts. The boundary-free active-transfer
audit remains proposed until selected separately.

`.804` rollback is documentation-only: remove this selection record and fact,
restore `.804` as active, and revert the synchronized README, roadmap, mdBook,
task-tree, Memory, and Knowledge Map text. No shipped behavior is affected.
