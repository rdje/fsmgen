# Adding IAL2 Protocols

This chapter is the user-facing workflow for bringing a new protocol, protocol
profile, or bounded protocol family into IAL2. The canonical engineering
workflow is
[IAL2_NEW_PROTOCOL_SUPPORT_WORKFLOW.md](../../IAL2_NEW_PROTOCOL_SUPPORT_WORKFLOW.md).

The rule for every supported IAL2 protocol surface is:

```text
IAL2 source -> generated IAL1 .isf -> generated IAL0 .fsm -> HDL
```

Generated `.isf` and `.fsm` files are review artifacts. A protocol feature is
not signoff-ready if it skips them, hides them, or makes the book unable to
explain what was generated.

## Start With A Slice

New protocol support starts with one bounded object, not a full bus family.
The first task usually captures evidence or selects a contract; implementation
comes only after the public shape is clear.

The repeatable order is:

1. Capture protocol evidence and the smallest meaningful subset.
2. Audit readiness against current IAL2, IAL1, IAL0, CLI, report, and support
   surfaces.
3. Select the public contract: source suffix, profile, object form, generated
   artifacts, report schema, support identity, diagnostics, examples, tests,
   docs, and residue.
4. Implement only the selected parser/report/generator behavior.
5. Add runnable samples and support-accounting entries.
6. Validate check JSON, semantic JSON, generated artifacts, HDL reachability,
   support accounting, docs, Knowledge Map, and doctrine gates.
7. Commit the slice before selecting the next one.

## What The AXI And APB Work Proved

AXI did not start as a full manager. It started with a Valid-Ready channel,
then grew through manager capacity/status, ID families, transactions, response
demux, queue-head policy, burst handling, dynamic IDs, same-ID ordering, and
read-data families as separate bounded slices.

APB did not start as a full interconnect. It grew through requester transfer,
profile alias exposure, completer generation, fixed composition, register
maps, sidebands, data widths, protection policies, and back-to-back timing as
separate bounded slices.

The reusable lesson is that a new protocol becomes maintainable only when each
slice has a public contract, generated review artifacts, support accounting,
diagnostics, examples, book coverage, and honest residue.

## Public Contract Checklist

Before a protocol slice changes behavior, the contract must answer:

- Which suffix accepts the source: `.ppif` only, a profile alias, or both?
- Which explicit `(profile ...)` value is required?
- Which top-level object form is accepted?
- Which clauses are required, optional, duplicate-forbidden, or unsupported?
- Which generated `.isf` and `.fsm` artifacts appear?
- Which HDL entry is selected?
- Which report schema and support-accounting IDs are stable?
- Which malformed and unsupported forms fail closed?
- Which examples can users run?
- Which behavior remains residue for later task-tree leaves?

If one of those answers is ambiguous, the next task is still selection or
readiness, not implementation.

## Implementation Surfaces

The current implementation uses these public and support surfaces:

- `FSM::Adapter::IAL2::PPIF` parses `.ppif` and selected profile aliases.
- `FSM::IAL2::ProtocolIntent::*` modules normalize the selected protocol
  intent and generate reviewable IAL1.
- `bin/fsmgen` exposes check JSON, schedule JSON, semantic JSON, `--outdir`,
  HDL generation, and capability-manifest behavior.
- `FSM::Support::RegressionCorpus` support-accounts checked-in public
  examples.
- `FSM::Support::LanguageSurfaceSection` advertises supported suffixes and
  selected residue.
- `ppif/` contains runnable public examples.

Those names are implementation references, not a license to bypass the
contract. Future language implementations must preserve the same observable
source syntax, diagnostics, reports, artifacts, and support-accounting results
for any feature they claim.

## Done Means

A protocol slice is done only when the source form, generated artifacts,
reporting, diagnostics, examples, support accounting, book, Knowledge Map,
task tree, Memory, doctrine checks, and commit all agree.

The slice must not imply the whole protocol is supported unless the whole
protocol has actually been selected, implemented, tested, documented, and
support-accounted.
