# Backlog: Future HIAL/VIAL Verification

This page contains future work only. It is not a completion log and does not
describe current support. Start with
[HIAL/VIAL Verification: Start Here](16d-hial-vial-verification-architecture.md)
for shipped behavior and current boundaries, then use
`./bin/fsmgen vial capabilities --json` or
`./bin/fsmgen --capability-manifest` for machine-readable current truth.

## Architecture boundary for future work

HIAL remains the synthesizable hardware-intent stack. VIAL remains its peer for
verification intent. Future work must preserve the review-routed HIAL bridge,
target-neutral logical time, deterministic decisions and replay, normalized
results, typed native extensions, repository-local artifacts, and private
compiler IR.

A new backend or language feature is not supported merely because it parses,
emits text, compiles an isolated probe, or succeeds under another profile. It
must have a named capability profile, exact provider and tool identity where
applicable, exercised behavior, deterministic result evidence, failure and
cleanup coverage, support accounting, and explicit nonclaims.

## Future capability families

| Direction | Required outcome before it can be called supported |
| --- | --- |
| Native-UVM product runtime | Qualify generated fixtures through preprocessing, parsing, library and fixture compilation, elaboration, execution, normalized results, and the declared parity boundary under an exact simulator/provider tuple. |
| Additional VHDL profiles | Qualify each additional simulator, methodology provider, language feature, or property subset independently; do not infer it from the existing private profiles. |
| Mixed-language execution | Select and qualify a named binding adapter and toolchain for HIAL and VIAL in different HDLs. Separate single-language successes are insufficient. |
| Broader result parity | Define a shared observable-outcome oracle for each added fixture and backend pair. Generated text and waveform identity are not parity. |
| Capacity or support promotion | Promote only separately owned, reproducible evidence. The bounded regression gate is protective evidence, not a general capacity claim. |
| Expressive VIAL families | Extend verification intent by semantic compression, with readable source-mapped backend output and no requirement that authors learn backend methodology machinery. |
| Native intent simulation | Select executable reference semantics before treating direct HIAL/VIAL execution as authoritative or comparable with generated HDL backends. |

### Selected expressive-language programme

Decision `0034` and activity `.19` preserve the closed VIAL v1 contract and select additive v2
growth. The first programme covers lifecycle; notification and interception;
timed interfaces; transactions, scenarios, and stimulus orchestration; typed
communication, models, and scoreboards; implementation substitution; scoped
configuration; register intent; constrained decisions; coverage and
properties; faults; and semantic results, diagnostics, debugging, and
introspection.

The selected v2 source envelope adds exactly one ordered `intents` section
between `scoreboards` and `fixtures`. Normal source uses `(version 2)` and an
explicit `(intents ...)` wrapper; terse source uses root integer `2` and omits
only that outer wrapper. Every non-empty block still names its VIAL family and
revision. Unknown families, revisions, nodes, mixed-version imports, or
unregistered compatibility adapters fail before typed SemanticIR exists.

Version 1 is not deprecated or silently upgraded. The future migration action
will convert an entire valid v1 import catalog atomically, insert an empty v2
intent section, and compare a base-meaning compatibility digest without
overwriting the original sources. This is a selected contract, not current
parser/tool capability; current commands continue to accept and emit v1 only.

Each family advances vertically. Its normal and terse forms must produce one
typed meaning; IR and plans must preserve identity, bounds, source maps, and
fail-closed capabilities; portable SystemVerilog, native UVM, and VHDL/OSVVM
must each implement the exact selected mapping or reject before output; and
qualification, support accounting, runnable documentation, generated-code
quality, cleanup, and nonclaims close the family. A private emitter preview is
useful implementation evidence, but it is not public authoring or runtime
support.

The author-facing test is simple: a VIAL user must not need to learn backend
methodology APIs. The generated-artifact test is equally strict: backend code
must remain deterministic, efficient, readable, minimally shaped, and
source-mapped. Later semantic families remain admissible through the same
owned gate, so this programme is a bounded delivery order rather than a new
language ceiling.

## Nonclaims retained by this backlog

The backlog does not claim complete SystemVerilog, UVM, VHDL, property,
methodology, mixed-language, cross-backend, arbitrary-tool, or scale support.
It does not turn private emitters into public APIs, promote experimental probe
results, deprecate legacy observation outputs, or reinterpret architecture
limits as product capacity.

## Where completed evidence belongs

Existing behavior belongs in the stable architecture and specialist evidence
chapters, not here:

- [public source, planning, and execution](16d-hial-vial-verification-architecture.md#shipped-public-source-planning-and-execution-tooling);
- [portable Verilator runtime evidence](16dc-vial-portable-verilator-runtime-measurement.md);
- [private portable VHDL qualification](16dd-vial-portable-vhdl-runtime-measurement.md);
- [private OSVVM qualification](16de-vial-osvvm-runtime-execution-plan.md); and
- [bounded architecture-scale regression evidence](16df-vial-architecture-scale-cap-closeout.md).

The roadmap owns direction, the task tree owns implementation status and
evidence, and Git owns exact history. This page intentionally carries none of
their progress narration.
