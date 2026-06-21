# AXI IAL2 Manager Mixed Auto-ID Queue-Head Runtime-Validation Support Residue Cleanup

Task owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.204`

Date: 2026-06-21

## Scope

FSMGen already generates and support-accounts runtime beat-count/`RLAST`
validation over the same-family mixed auto-ID plus depth-2 concrete same-ID
queue-head read burst-last scalar last-beat shape shipped by
`IAL2-FEATURE-COMPLETENESS-FRONTIER.202`.

This slice cleans stale public/static wording after `.202`. It does not change
parser syntax, queue-head admission, read-data rules, generated assertions,
public PPIF corpus membership, support-accounting identity, generated
artifacts, strict check/semantic JSON source identity, or HDL behavior.

## Corrected Support Boundary

The public `.ppif` language-surface boundary, downstream integration handoff,
public interface contract, mdBook embedding chapter, and focused static
expectations now describe selected same-family mixed auto-ID plus concrete
queue-head read burst-last runtime validation as supported.

The selected supported family is:

- same-family mixed auto-ID plus concrete queue-head response-demux;
- scalar read-data for read single-beat and read burst-last shapes;
- report-only raw-`ARLEN` burst-length over the mixed read burst-last scalar
  last-beat shape; and
- generated runtime beat-count/`RLAST` validation over that same mixed read
  burst-last scalar last-beat shape.

## Deferred Work

The cleanup keeps these outside the shipped boundary:

- mixed multi-beat read-data;
- broader mixed-family burst-length/runtime validation beyond the selected
  same-family mixed read burst-last scalar shape;
- write-family read-data;
- group-local simultaneous enqueue widening;
- packed burst-vector outputs;
- alternate full burst payload assembly;
- verification-output generation;
- direct backend lowering;
- VHDL/backend-language variants.

## Preservation

The generator support detail already reported the `.202` shape as supported.
This cleanup aligns the remaining public/static surfaces with that behavior and
updates focused expectations only. It does not broaden the supported corpus,
change generated schedules, change emitted HDL, or remove any deferred boundary
other than stale wording for the already-shipped selected runtime-validation
shape.
