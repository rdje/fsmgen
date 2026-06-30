# IAL2 AHB Burst SEQ Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.750`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.750` audits bounded AHB burst `SEQ`
continuation readiness and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.751`, a no-behavior public contract
selection for the first bounded subordinate-side `SEQ` support.

Direct implementation is not selected in this slice. Current requester burst
generation already emits first-beat `NONSEQ`, later-beat `SEQ`, address
progression, wrapping modes, local length/count state, and response handling.
The remaining missing public contract is subordinate acceptance/reporting for
selected `SEQ` continuation, plus the exact fail-closed boundary for unsupported
burst shapes.

This audit changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test behavior,
schedule/check/semantic JSON behavior, generated artifact, HDL/runtime
behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Evidence Read

The audit read:

- `.749`, the selector that routed this readiness audit after aggregate alias
  residue cleanup;
- `.748`, the aggregate `.ahb` alias nested endpoint profile-residue cleanup;
- shipped AHB requester, subordinate, subordinate alias, interconnect,
  two-subordinate, byte-lane, aggregate byte-lane, and aggregate alias behavior
  documents;
- the AHB source fact inventory and seed/IAL2 subordinate contract records;
- current AHB requester, subordinate, interconnect, and PPIF parser
  implementation entrypoints;
- focused AHB tests `t/1473`, `t/1475`, `t/1478`, `t/1480`, `t/1482`, and
  `t/1484` by targeted reads and pattern searches;
- public AHB `.ppif` and `.ahb` source samples;
- README, ROADMAP_V2, mdBook backlog/AHB chapter, task tree, Memory, Knowledge
  Map, COMMIT workflow, TOOLBOX, and decisions `0013`, `0014`, `0015`, `0016`,
  and `0018`.

The source-backed AHB fact inventory records that `SEQ` represents remaining
burst transfers with related addresses and unchanged control information.
That is a stronger requirement than simply treating any standalone `SEQ` as
another independent register access.

## Current Requester Boundary

The bounded requester surface is not the first blocker. The public requester
source already exposes:

```text
cmd_burst
cmd_len
cmd_wdata_step
burst_active
wrap_active
beat_index
beats_remaining
active_addr
active_hburst
```

The current requester generator:

- captures `cmd_burst` and `cmd_len`;
- sets beat counts for `SINGLE`, `INCR`, `WRAP4`, `INCR4`, `WRAP8`, `INCR8`,
  `WRAP16`, and `INCR16`;
- drives first accepted beat as `NONSEQ`;
- drives later beats as `SEQ`;
- advances on `HREADY`;
- increments or wraps `HADDR` by the selected transfer size; and
- handles `OKAY`, `ERROR`, `RETRY`, and `SPLIT` response encodings.

The requester report still has broader requester residue such as full-manager
behavior, completer/subordinate composition, and verification-output work, but
it does not carry `ahb_burst_seq_support_deferred`. Requester generation is
therefore not the next exact owner for removing the subordinate/aggregate
`SEQ` residue.

## Current Subordinate Boundary

The word-only and byte-lane subordinate sources both keep the current source
contract:

```text
(supported-transfer nonseq)
```

The PPIF parser currently treats `(supported-transfer ...)` as a single scalar
clause. It does not yet select plural supported transfers, a new burst policy
clause, or a new source name that distinguishes `NONSEQ`-only behavior from a
future `NONSEQ` plus bounded `SEQ` behavior.

The current generated subordinate IAL1 accepts an active address phase when:

```text
HSEL && HREADY && (HTRANS == NONSEQ || HTRANS == SEQ)
```

It then samples address, write/read, size, transfer type, and wait count. In
the current access body, `trans_q == SEQ` routes to `error_first` followed by
`error_complete`. Both word-only and byte-lane subordinate reports keep:

```text
ahb_burst_seq_support_deferred
```

A focused in-process adapter probe confirmed:

```text
ppif/ahb_lite_subordinate.ppif
  supported_transfer=nonseq
  ahb_burst_seq_support_deferred present
  generated IAL1 routes SEQ to ERROR

ppif/ahb_lite_subordinate_byte_lane.ppif
  supported_transfer=nonseq
  ahb_burst_seq_support_deferred present
  generated IAL1 routes SEQ to ERROR
```

## Current Aggregate Boundary

The aggregate interconnect already decodes active transfers using
`HTRANS != IDLE`, subtracts the selected window base for local subordinate
addresses, forwards `HTRANS`, `HWRITE`, `HSIZE`, `HWDATA`, and `HREADY` to the
selected subordinate through top wiring, and owns unmapped active-transfer
ERROR responses.

The aggregate reports still carry top-level `ahb_burst_seq_support_deferred`.
For aggregate byte-lane sources, corrected child-report probing showed:

```text
requester child: no ahb_burst_seq_support_deferred
interconnect child: ahb_burst_seq_support_deferred present
subordinate child: ahb_burst_seq_support_deferred present
```

That means aggregate propagation should follow a subordinate/interconnect
contract. It is not the first implementation owner, because the embedded
subordinate report and generated subordinate behavior still define the mapped
hit response to `SEQ`.

## Readiness Findings

There is no evidence of a generated-IAL1/IAL0 substrate blocker comparable to
the earlier AHB output-default/reset gap. Current generated IAL1 already
supports sampled address/control, wait states, storage updates, read drives,
conditional branches, and internal state in requester paths. The likely
implementation substrate can express a bounded subordinate state machine once
the public contract is selected.

Direct implementation remains premature for three reasons:

1. The public source syntax still says `supported-transfer nonseq`; changing
   behavior without selecting a new source/report contract would create
   documentation and machine-report drift.
2. The source-backed protocol fact says `SEQ` is related to a preceding burst
   transfer with unchanged control. Treating any standalone `SEQ` as another
   independent access would be too permissive.
3. The existing subordinate has only one word register, while byte-lane sources
   have in-word byte/halfword address policy. The first useful `SEQ` subset
   needs a deliberate address-progression boundary, such as byte-lane
   in-word progression, an explicitly selected register-bank source, or another
   bounded policy. That belongs in a contract-selection slice before code.

## Selected `.751` Scope

`.751` must select the public contract for first bounded subordinate-side
`SEQ` support before behavior changes.

The contract selection must decide:

- whether the first public source is a new source or a widening of existing
  word-only and/or byte-lane subordinate sources;
- whether `supported-transfer` becomes repeatable, gains a new scalar value, or
  is paired with another explicit burst-support clause;
- whether the first selected behavior requires a prior accepted `NONSEQ`
  before any `SEQ` can complete with OKAY;
- how expected next address, transfer size, write/read direction, and control
  consistency are represented and reported;
- whether byte-lane in-word progression, a new multi-register/register-bank
  source, word-only behavior, or another smaller subset is selected first;
- how unsupported standalone `SEQ`, unexpected address progression, wrap
  points, length validation, unsupported sizes, unmapped addresses, and changed
  control fail closed;
- how `ahb_burst_seq_support_deferred` moves or narrows in endpoint,
  `.ahb` alias, aggregate, and child reports;
- which focused tests/probes cover source parsing, generated IAL1/FSM review
  text, report JSON, schedule/check/semantic JSON, preservation, malformed
  source diagnostics, and rollback; and
- how aggregate propagation and requester preservation are explicitly deferred
  or sequenced.

## Explicit Non-Selections

This audit does not select direct parser/generator implementation. It does not
add public sources, support-accounting entries, report fields, tests, generated
artifacts, or HDL behavior.

This audit does not select optional/property-gated AHB signals, `HBURST`
forwarding into subordinates, AHB5 optional signals, security, exclusive
access, user signals, parity/check signals, legacy two-bit subordinate
`HRESP`, broader interconnect/decode cardinality, multiple requesters,
arbitration, bus matrices, scoreboards, full-manager behavior, direct backend
behavior, verification-output generation, backend-language variants, AXI/APB
behavior, broader AHB behavior, or VHDL behavior.

## Validation

Closeout for `.750` is documentation-only plus targeted read/probe evidence:

```bash
perl -Iperl -MFSM::Adapter::IAL2::PPIF -we '...focused AHB residue probe...'
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Broad or potentially heavyweight Perl, `prove`, or `fsmgen` commands remain
behind `scripts/run_with_ram_guard.sh` or equivalent monitoring.

## Rollback

Rollback is documentation-only: remove this audit, its Knowledge Map fact card,
task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer update,
and regenerated Knowledge Map entries. No runtime behavior is affected.
