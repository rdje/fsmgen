# IAL2 Post-Two-Subordinate Exact-Two Paired-BUSY Alias Next Owner Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.812`

Date: 2026-07-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.812` selects proposed
`IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT`, beginning
with one no-behavior generated-HDL readiness leaf after `.812` commits
cleanly.

The selected question is the smallest literal widening left in the shipped
requester BUSY lineage:

> Can the existing two-bit remaining counter retire exactly three qualified
> requester `HTRANS=BUSY` events at the one shipped literal insertion point,
> across continuously-ready, ready-low, and grant-low operation, without a new
> lowering substrate or any change to pending-transfer ownership?

This selector changes no parser, generator, public source, support catalog,
capability manifest, test, report, artifact, semantic/MCP API, HDL/runtime,
backend, AXI/APB/AHB/VHDL, or transaction-layer behavior.

## Evidence Read

The selector reconciled:

- `.808` through `.811` and the completed requester multiple-BUSY plus
  exact-two paired-composition child trees;
- `FSM::IAL2::ProtocolIntent::AhbRequester` normalization, generated IAL1
  counter/rule emission, report vocabulary, and unsupported residue;
- t/1521 exact-two structural, diagnostic, assertion-enabled continuous,
  ready-low, grant-low, exact-one, and base-requester proofs;
- t/1522 semantic/MCP alias parity and the exact-two one-/two-subordinate
  paired runtime and alias lineage through t/1526;
- support/language/capability accounting at 320 protocol, 361
  supported-smoke+strict, and 44 AHB paths split 22 `.ppif`/22 `.ahb`;
- README, ROADMAP_V2, mdBook AHB current behavior/backlog, task trees, Memory,
  Knowledge Map, proposed correctness owners, and decision 0020.

## Current Boundary

The optional requester clause accepts only literal `(busy-beats 2)`. When it
is absent, the exact-one requester remains canonical. Exact-two behavior uses
actor-owned `ahb_busy_remaining_q` at width two, initializes it before BUSY
visibility, decrements on qualified non-final BUSY events, and uses the
existing final `== 1` rule to clear the count and hand the same pending
transfer to address-pending `SEQ` ownership. Reports expose numeric
`busy_insertion.beats=2` and explicitly defer counts beyond two.

All exact-two generic/alias standalone and paired paths ship. The mdBook's
current deferred-boundary paragraph still said that the two-subordinate
exact-two pairing was unshipped even though `.811` completed its matching
alias; `.812` corrects that stale sentence as part of the required current-
truth reconciliation.

## Static Feasibility Finding

Literal three fits the existing width-two counter. With the emitted rules
unchanged except for initialization to three, qualified BUSY retirement is:

```text
3 --continue--> 2 --continue--> 1 --accept/SEQ--> 0
```

Both rules require `HGRANT && HREADY && HTRANS == BUSY`; therefore a static
reading predicts that ready-low and grant-low clocks consume no count. The
whole multiple-BUSY transaction already remains in its BUSY continuation gate,
and the final rule already reuses the exact-two pending-address `SEQ` handoff.
The parser restriction and report sentence are literal-two policy, not a
storage-width or lowering-shape limitation.

That is sufficient to select a readiness audit, but not sufficient to select
public behavior. Only literal two has assertion-enabled runtime proof. A
three-event disposable generated-HDL candidate must still prove exact
cardinality, stable address/control/write-data/beat ownership, no BUSY data or
response completion, one resumed `SEQ`, four accepted data beats, zero final
remaining count, and unchanged exact-one/exact-two behavior.

## Selected Audit Boundary

The proposed audit's first leaf must:

- create only a repo-local disposable candidate under `.artifacts/`, derived
  from the shipped exact-two requester and current generator;
- admit literal three only inside that disposable workspace and preserve the
  two-bit counter plus current non-final/final rules;
- run assertion-enabled continuously-ready, 32-clock ready-low, and 32-clock
  grant-low generated-HDL scenarios;
- require exactly three qualified BUSY events, one BUSY transition episode,
  one resumed pending `SEQ`, four accepted byte `INCR4` data beats, stable
  pending fields/counters during stalls, and zero remaining count;
- reconcile strict check, schedule/report, generated IAL1/IAL0 artifacts,
  normalized semantic JSON, and the existing read-only
  `fsmgen_semantic_introspect` contract; and
- select a separate exact public contract, the smallest prerequisite, exact
  deferral, or audit closure from evidence. No public source or shipped
  behavior changes in the audit.

Any later public contract must preserve absent-clause exact-one behavior and
literal-two behavior exactly. Source/support/coverage names, diagnostics,
whether the public accepted set is exactly `{2,3}`, report wording, residue,
generic-first/profile-alias cadence, paired-composition sequencing, projected
support accounting, and rollback remain decisions for a later contract leaf.

## Rejected Next Owners

- **Direct literal-three implementation:** rejected until generated-HDL
  runtime proves the apparent width-two reuse boundary.
- **Generalized count width or counts above three:** larger than the smallest
  one-literal extension and may require a different maximum/resource contract.
- **Policy/runtime/random insertion or multiple insertion points:** adds
  control policy and new ownership semantics rather than reusing the existing
  literal point.
- **Distinct local bus-BUSY status:** changes public ports and meaning.
- **Halfword/word or wider/indefinite bursts and optional signals:** broader
  independent feature families.
- **Interconnect selector correctness owners:** remain separately proposed;
  their own boundaries defer activation until requester BUSY work dries out.
- **Decision 0020 transaction layer:** director-owned, proposed/inactive, and
  not PNT-eligible.

## Audit Result

The selected audit `.1` has now passed. A same-volume disposable candidate and
one assertion-enabled Verilator binary proved continuously-qualified,
32-clock ready-low, and 32-clock grant-low internal
`3 -> 2 -> 1 -> 0` retirement, exact cardinality, stable pending ownership,
one resumed `SEQ`, four data beats, and zero final count. Strict, schedule,
artifact, normalized semantic, and real read-only MCP evidence also passed.
No lower-layer repair is required; proposed `.2` owns public contract selection
before any behavior change. The canonical result is
`docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_INSERTION_READINESS_AUDIT.md`.

## Validation And Resource Boundary

Selector closeout is documentation-only plus current-code/static-test
reconciliation, mdBook build, Knowledge Map generation/check, memory
architecture, relative-document paths, diff, and doctrine gates. The future
disposable generated-HDL audit must run from repository-local storage under the
4-GiB descendant RSS guard; it must not use `/tmp`, `/private/tmp`, or a
user-home cache.

## Rollback

Remove this selector record/fact and proposed audit tree, restore `.812` to
active candidate selection, and revert README/ROADMAP_V2/mdBook/task/Memory/
Knowledge Map pointers. No shipped behavior is affected.
