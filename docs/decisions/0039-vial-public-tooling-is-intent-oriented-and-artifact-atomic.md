# 0039 — VIAL public tooling is intent-oriented and artifact-atomic

- Date: 2026-07-31
- Type: verification language/public tooling architecture
- Status: accepted
- Extends: [0032](0032-vial-uses-one-source-two-private-irs-and-a-versioned-hial-bridge.md), [0033](0033-vial-v1-uses-spanned-s-expressions-and-typed-semantic-records.md), [0036](0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md), [0037](0037-vial-semantic-types-bind-to-hial-carriers-through-directional-proof-relations.md)
- Evidence owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.8`

## Context

The shipped VIAL source, HIAL bridge, and target-neutral execution plan are
private compiler seams. Before selecting a target backend, FSMGen needs a
public tool boundary that is simple for authors, honest about capabilities,
portable beyond the filesystem/Perl implementation, and unable to expose
private IR or methodology plumbing.

The existing `--emit-verification-output` command cannot serve this role. It
accepts one `.isf` source and emits one inert observation skeleton; VIAL needs
both authored verification intent and an independently review-routed HIAL DUT
source, then semantic checking, optional formatting, bridge binding, planning,
backend execution, and normalized reports.

VIAL also needs to honor the director's terse-or-normal authoring requirement
without letting syntactic convenience create a second semantic language.

## Decision

1. Public VIAL tooling is the explicit `fsmgen vial` command family with
   `capabilities`, `check`, `format`, `plan`, and later `run` actions.
2. `normal_v1` and `terse_v1` are deterministic source projections of one
   semantic model. Terse form removes only the selected structural wrappers;
   it adds no implicit types, values, time, bindings, or capabilities. Both
   reparse to the same provenance-excluding semantic meaning digest.
3. `plan` and `run` take separate VIAL and HIAL sources. HIAL accepts direct
   IAL0, direct IAL1, or IAL2 only through generated/reparsed IAL1 and
   generated IAL0 review artifacts. No direct PPIF bridge is allowed.
4. The portable public API uses closed `fsmgen.vial_tool_request.v1` and
   `fsmgen.vial_tool_result.v1` records over the already-selected
   source-catalog/artifact-sink host abstraction. Private objects never cross
   it.
5. Filesystem output is repository-root-relative, same-volume, deterministic,
   content-addressed by the full plan digest, and atomically materialized from
   an exact repository-local staging root. Non-identical or ambiguous existing
   output fails without overwrite.
6. Public files are only canonical normal source, generated HIAL review
   artifacts, sanitized bridge/plan projections, tool/verification/result
   manifests, and backend artifacts. Raw SemanticIR/ExecutionIR and target
   objects are never serialized.
7. Existing `verification-output-manifest.json` v1 skeleton behavior remains
   unchanged. VIAL runtime output uses explicit
   `fsmgen.verification_output_manifest.v2`; capability discovery selects the
   schema per target rather than guessing from the filename.
8. Capability and support accounting distinguish source semantics, public
   check/format, public plan, backend emission, compile, runtime, result,
   parity, methodology, and scale. One fixture cannot satisfy them by
   association.
9. `.9` selects the first backend contract, `.10` is the first implementation
   owner for this tool contract plus that backend/result producer, and `.11`
   owns runtime parity.

## Consequences

- An author can learn and use VIAL without SV/UVM/VHDL knowledge while still
  obtaining reviewable compiler evidence.
- Terseness is reversible surface sugar, never hidden semantics.
- The CLI and in-memory embedding API share one observable contract without
  requiring a POSIX filesystem or Perl classes.
- Project output cannot leak to `/tmp`, home caches, or another volume, and
  failed operations leave no partial artifact tree.
- Existing verification skeleton consumers remain compatible while VIAL gets
  an honest multi-source/multi-artifact schema.
- Selection alone ships no command, parser widening, file, backend, runtime,
  result, or capability claim.
