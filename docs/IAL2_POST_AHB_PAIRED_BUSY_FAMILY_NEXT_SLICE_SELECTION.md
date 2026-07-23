# IAL2 Post-AHB Paired BUSY Family Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.797`

Date: 2026-07-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.797` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.798`, a no-behavior readiness audit for a
bounded **two-subordinate paired AHB BUSY composition**. The target direction
reuses the shipped requester that inserts one held `HTRANS=BUSY` presentation
with the shipped two-subordinate static-window aggregate whose status and
control HBURST-aware byte-lane subordinates both park their `SEQ` context
across BUSY.

Direct implementation is not selected. Although an in-memory candidate already
parses and generates through the current four-child aggregate path, the new
topology needs an explicit two-window runtime-proof contract. The audit must
also resolve a pre-existing report contradiction: the shipped two-subordinate
BUSY-park report says BUSY parking is both shipped and deferred in different
residue entries.

This selector changes no parser, generator, public source, support-accounting
catalog, test, generated artifact, HDL/runtime behavior, direct backend,
verification output, backend-language variant, AXI/APB behavior, broader AHB
behavior, or VHDL behavior. Decision `0020`, the transaction-layer horizon,
and all proposed audits remain inactive.

## Evidence Read

The selector read and reconciled:

- `.794`-`.796`, including the generic and profile-alias paired-BUSY behavior,
  t/1513 runtime proof, t/1514 alias proof, support accounting, and public docs;
- the two-subordinate aggregate HBURST/BUSY-park `.ppif`/`.ahb` family from
  `.782`/`.784`, including status window `[0,4)` and control window `[4,8)`;
- the BUSY requester `.ppif`/`.ahb` family and the one-subordinate paired source;
- `AhbRequester`, `AhbSubordinate`, `AhbInterconnect`, the PPIF adapter,
  `RegressionCorpus`, `LanguageSurfaceSection`, and focused t/1480, t/1492,
  t/1496, t/1497, t/1512, t/1513, t/1514, t/248, and t/297 evidence;
- README, ROADMAP_V2, the AHB mdBook chapter and feature backlog, Knowledge Map,
  task tree, Memory, the proposed AHB pipeline/identifier audits, and decision
  `0020`.

The selector consulted the existing Knowledge Map facts before running new
probes. No fact previously owned the post-`.796` choice or the contradictory
two-subordinate BUSY residue.

## Why Two-Subordinate Pairing Is Next

The one-subordinate paired `.ppif`/`.ahb` family now proves both directions of
the BUSY contract end to end:

```text
requester:    insert one held BUSY before beat index 2
subordinate:  park the armed byte-only WRAP4/INCR4 context across BUSY
```

The shipped two-subordinate aggregate already provides the smallest unpaired
sibling topology:

```text
requester
  -> status  window [0,4), local address HADDR
  -> control window [4,8), local address HADDR - 4
```

Both children already use the same HBURST-aware byte-lane subordinate and both
already report `parks_on=[busy]`. Replacing only the aggregate's base requester
with the shipped BUSY requester therefore extends the proven pair across one
additional decode/mux child without opening a new transfer encoding, burst
policy, address-progression model, arbitration policy, or public status signal.

The alternatives are larger:

- multi-beat, policy-driven, or runtime-selected BUSY changes requester state
  and public control rather than composing shipped behavior;
- a distinct local bus-BUSY status changes the requester port contract;
- halfword/word, wider, or indefinite burst `SEQ` needs the deferred
  multi-word/register-bank progression substrate;
- optional AHB signals and legacy two-bit subordinate `HRESP` open orthogonal
  public signal/policy families; and
- true boundary-free active-transfer pipelining and the protocol-composition
  identifier audit already have proposed inactive owners and are not activated
  by this selector.

## Candidate Construction Probe

The selector built an in-memory candidate from
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif` by:

1. substituting requester object `amba_requester_busy_insert`;
2. adding requester transfer `busy=2'b01` and `busy-before-beat=2`; and
3. updating the requester child reference and temporary source identity.

The current adapter accepted it and reported:

```text
layer:       IAL2
child count: 4

IAL1:
  amba_requester_busy_insert.isf
  ahb_status_subordinate_byte_lane_hburst_seq.isf
  ahb_control_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert.fsm
  ahb_status_subordinate_byte_lane_hburst_seq.fsm
  ahb_control_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm

children[0].busy_insertion.before_beat: 2
children[2].transfer.seq_policy.parks_on: [busy]
children[3].transfer.seq_policy.parks_on: [busy]
composition.seq_policy_propagation.subordinates[*].seq_policy.parks_on: [busy]
```

This confirms that the `.794` conditional child-report propagation and the
existing two-subordinate generation/wiring paths compose without a parser or
endpoint-generator change. It does not yet prove two-window runtime behavior.

## Confirmed Report Contradiction

The live shipped report for
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif`
currently contains both:

```text
ahb_broader_interconnect_decode_deferred:
  ... BUSY-in-burst continuation ... remain future work.

ahb_burst_seq_support_deferred:
  ... ships ... BUSY-in-burst parking ...
```

The second statement is correct for this source and matches both child reports.
The contradiction is report text only; it does not disprove generated parking
behavior. Root cause is local to `AhbInterconnect::_unsupported_residue`: the
two-subordinate broader-interconnect detail branches on
`$hburst_seq_policy_selected` but not on the already-computed
`$hburst_busy_park_selected`. That wording predates the BUSY-park shipment and
was not narrowed with the dedicated burst residue.

`.798` must decide the smallest repair boundary and preserve the important
negative case: non-parking two-subordinate HBURST sources must continue to say
BUSY continuation is deferred, while parked sources must not contradict their
shipped behavior. No report repair is made in this selector.

## Selected `.798` Audit Scope

`.798` must audit and route exactly one bounded two-subordinate paired generic
source. It must:

- reproduce the in-memory four-child candidate through check, schedule,
  semantic, review-artifact, and generated-HDL surfaces;
- determine whether any parser, endpoint, interconnect, top, phase-ownership,
  decode, response-mux, or HDL substrate repair is required;
- root-cause and select the report-only fix for the contradictory
  `ahb_broader_interconnect_decode_deferred` wording, including preservation of
  non-parking and one-subordinate residue;
- define the next public-contract owner or a narrower prerequisite, with exact
  source/support/coverage/artifact/module/semantic-root choices deferred until
  that contract owner;
- audit a generated-HDL proof that runs a byte `INCR4` through the status window
  and through the nonzero-base control window, proving each selected subordinate
  parks across the requester's BUSY beat, the unselected subordinate remains
  unaffected, local-address subtraction is preserved, four data beats complete,
  and the correct per-window storage/status result is produced;
- preserve the one-subordinate paired `.ppif`/`.ahb`, the base two-subordinate
  BUSY-park `.ppif`/`.ahb`, and all existing AHB focused tests;
- decide generic `.ppif` before a later matching `.ahb` alias, expected for the
  established cadence; and
- record validation, docs/mdBook/Knowledge Map, rollback, and resource-monitoring
  boundaries before implementation.

`.798` remains no-behavior. It must not add the candidate source, alias, support
entry, test, generated artifact, runtime change, broader BUSY policy/status,
larger burst progression, optional signals, pipeline-audit behavior, direct
backend, verification output, backend variants, AXI/APB changes, or VHDL.

## Validation

`.797` closeout is documentation-only. Evidence includes the in-memory candidate
probe and a direct live-report residue probe, both observed under direct macOS
memory-pressure and descendant-RSS monitoring. Closeout also runs:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is documentation-only: remove this selector and its Knowledge Map fact,
restore `.797` as active, remove `.798`, and revert README, ROADMAP_V2, mdBook,
task-tree, Memory, and generated Knowledge Map changes. No behavior is affected.
