# VIAL Public Tooling Version-1 Contract

Date: 2026-07-31
Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.8`
Status: selected and implemented for the bounded portable profile; `.10.1` ships public
capabilities/check/normal-terse formatting and `.10.2` ships canonical
planning plus virtual/repository-local atomic artifacts. `.10.3` ships the
private backend/trace seam and `.10.4` ships public Verilator runtime/results
after clean activation commit `8ba4278d8`
Decision: `0039`

## Outcome

VIAL gets one coherent public tool family:

```text
fsmgen vial capabilities
fsmgen vial check SOURCE.vial
fsmgen vial format --style normal|terse SOURCE.vial
fsmgen vial plan --dut HIAL_SOURCE SOURCE.vial
fsmgen vial run --dut HIAL_SOURCE --backend BACKEND_PROFILE SOURCE.vial
```

The first runtime-profile contract is selected by completed `.9` under
decision `0043`. Completed `.10.1` implements the first three source-only
actions and completed `.10.2` implements `plan` plus artifact publication;
later children retain backend emission and runtime. This contract freezes the public syntax,
request/result API, source-style equivalence, path/artifact/report schemas,
capability discovery, diagnostics, support accounting, compatibility, and
atomicity rules before a backend exists.

The public boundary is intent-oriented. A VIAL author names a fixture,
scenario, DUT source, and requested backend profile; the compiler owns HIAL
review routing, bridge production, binding, logical-time planning, generated
SV/UVM/VHDL plumbing, compilation, and methodology details. Factory, phase,
objection, callback-class, target hierarchy, and simulator-region vocabulary
do not leak into this tool surface.

## One Meaning, Two Source Projections

`normal_v1` and `terse_v1` are two deterministic source projections of the
same typed VIAL semantic model. They are not profiles and cannot change
capabilities, inferred types, authored order, stable semantic IDs, logical
time, random-decision identities, or the bound plan.

The existing checked source is the canonical `normal_v1` shape. It starts:

```lisp
(vial
  (version 1)
  (package example
    (imports)
    (types
      (type data_t (logic 32)))
    (transactions
      (transaction write ...))
    (models)
    (scoreboards)
    (fixtures
      (fixture smoke
        ...
        (scenarios
          (scenario success
            (timeout (cycles bus 32))
            (steps
              (reset bus 3)
              ...)))))))
```

The corresponding `terse_v1` projection is:

```lisp
(vial 1
  (package example
    (type data_t (logic 32))
    (transaction write ...)
    (fixture smoke
      ...
      (scenario success
        (timeout (cycles bus 32))
        (reset bus 3)
        ...))))
```

The closed mapping is:

| Normal form | Terse form |
| --- | --- |
| root `(vial (version 1) PACKAGE)` | root `(vial 1 PACKAGE)` |
| empty `(imports)` | omitted |
| non-empty `(imports NAME...)` | source-ordered `(import NAME)` clauses |
| `(types DECL...)` | source-ordered `type`/`enum` declarations in the package body |
| `(transactions DECL...)` | source-ordered `transaction` declarations in the package body |
| `(models DECL...)` | source-ordered `model` declarations in the package body |
| `(scoreboards DECL...)` | source-ordered `scoreboard` declarations in the package body |
| `(fixtures DECL...)` | source-ordered `fixture` declarations in the package body |
| fixture `(scenarios DECL...)` | source-ordered `scenario` declarations in the fixture body |
| scenario `(steps ACTION...)` | source-ordered actions directly after `timeout` |

Every other form is identical. Terse syntax does not add implicit types,
values, timeouts, seeds, scenarios, DUT bindings, events, callbacks, or target
behavior. A source is entirely normal or entirely terse: the root's second
item selects the style, and wrapper/flattened forms from the other style are
rejected as `VIAL_SOURCE_STYLE_ERROR` rather than guessed.

`format --style normal` always emits the fully explicit normal form; `format
--style terse` emits only the mapping above. Both outputs are valid authored
sources. Reparse must produce equal `fsmgen.vial_semantic_projection.v1`
meaning digests. Raw source digests and source spans are expected to differ and
remain honest provenance; they are excluded from the meaning digest.

Formatting is deterministic UTF-8 with LF endings, two-space indentation,
lowercase reserved words/literal digits where the lexical contract permits,
one final newline, declaration/action order preserved, and no comment
retention in version 1. Formatting never binds a DUT or writes an artifact.

Completed `.10.1` widens the shipped parser through one private normalization
step: both projections enter the same `SemanticBuilder`, and `t/1555` proves
format/reparse equality through `fsmgen.vial_semantic_projection.v1`. No
second terse semantic pipeline exists.

## CLI Contract

### Common rules

- `SOURCE.vial` is one repository-root-relative VIAL source.
- `--quiet` suppresses human progress, never diagnostics.
- `--json` returns the closed public result envelope on stdout. Without it,
  diagnostics remain stable and human-readable.
- `--fixture ID` is optional when the source contains exactly one fixture and
  otherwise required.
- repeatable `--scenario ID` selects authored-order scenarios; omission means
  all scenarios in authored order.
- `--profile ID` defaults to the single profile inferred by the checked source
  and bridge. Supplying another ID requires an advertised exact capability.
- `--replay RELPATH` and repeatable `--native-catalog RELPATH` are accepted
  only by `plan`/`run`. The first profile requires an empty native catalog.
- all persisted paths and diagnostics use repository-root-relative `/`
  identities. Absolute paths and `..` traversal are rejected.

### `capabilities`

`fsmgen vial capabilities [--json]` returns the VIAL-only projection of the
ordinary capability manifest. It never implies a backend or runtime is
available merely because a source/bridge/execution schema exists.

### `check`

```text
fsmgen vial check [--style auto|normal|terse] [--json] SOURCE.vial
```

`check` lexes, parses, types, validates, and builds the sanitized semantic
report. It needs no HIAL source, creates no bridge/plan, and writes no file.
`auto` is the default and uses the unambiguous root discriminator above;
explicit style mismatch fails.

### `format`

```text
fsmgen vial format --style normal|terse SOURCE.vial
```

The formatted source is written to stdout only. `--json`, `--dut`, `--outdir`,
fixture/scenario/profile/replay/native/backend options, and legacy HDL/report
flags are incompatible. An embedding host receives the same text as a result
field rather than an artifact write.

### `plan`

```text
fsmgen vial plan \
  --dut ppif/ahb_lite_subordinate.ppif \
  [--fixture base_output_arbitration] \
  [--scenario success ...] \
  [--profile core_directed_single_clock_execution_v1] \
  [--replay RELPATH] \
  [--native-catalog RELPATH ...] \
  [--outdir RELDIR] \
  [--json] \
  vial/ahb_subordinate_base_output_arbitration.vial
```

`plan` routes the HIAL source through its canonical review path, constructs the
sanitized bridge, binds and elaborates the selected fixture/scenarios, then
materializes only public projections. It does not emit target verification
code, compile, simulate, or produce a result manifest.

Completed `.10.2` ships this action. Direct IAL0 supports transaction-free
endpoint/reset fixtures because its bridge truth has no transaction contract;
transaction-bearing VIAL must use a route that publishes matching reviewed
transactions. This first direct-IAL0 route accepts one root `.fsm` and rejects
package imports rather than silently constructing an incomplete review graph.
Direct IAL1 and IAL2 retain their checked transaction facts.

Version 1 accepts direct `.fsm`, direct `.isf`, or `.ppif` only through
generated/reparsed IAL1 and generated IAL0 review artifacts, exactly as
decision `0035` requires. Using `.ppif` as a DUT source is not the legacy
`--emit-verification-output` direct-IAL2 route: protocol truth reaches VIAL
only through generated/reviewed IAL1 bridge metadata.

### `run`

```text
fsmgen vial run --dut HIAL_SOURCE --backend BACKEND_PROFILE [PLAN_OPTIONS] SOURCE.vial
```

`run` performs the identical plan operation, negotiates the named backend,
emits its artifacts, executes the qualified tool profile, and writes the
selected result manifest. `sv_portable_verilator` is now a selected known-value
backend contract under decision `0043`. Private emission/trace validation ships
through completed `.10.3`; completed `.10.4` now ships public publication,
exact Verilator 5.046 execution, trace capture, and normalized result
production. Any other backend profile fails atomically as
`VIAL_BACKEND_UNSUPPORTED`.

### Incompatible legacy options

The `vial` subcommand cannot combine with top-level `--language`, `--output`,
`--outdir`, `--check`, `--check-json`, `--emit-semantic-json`,
`--emit-schedule-json`, `--emit-verification-output`,
`--verification-outdir`, or `--verify-hdl`. Contextual `vial plan/run
--outdir` belongs to the VIAL parser and does not widen the legacy HDL option.

## Portable In-Memory API

The API reuses the selected portable `capabilities(request?)` and
`execute(request)` concepts rather than publishing Perl classes. A VIAL
request is a closed JSON-safe record:

```text
schema: fsmgen.vial_tool_request.v1
schema_version: 1
action: capabilities | check | format | plan | run
vial_source
hial_source
options
```

`vial_source` and non-null `hial_source` use the selected source-catalog
envelope: `source_id`, optional `source_kind_hint`, `text`, `encoding`,
`origin`, `display_name`, optional `canonical_id`, optional `relative_path`,
and JSON-safe metadata. `hial_source` is null for capabilities/check/format and
required for plan/run.

`options` has exactly:

```text
source_style
output_style
fixture_id
scenario_ids
execution_profile
backend_profile
replay_manifest
native_extension_catalogs
artifact_policy
quiet
```

For `plan`/`run`, `artifact_policy` has exactly `mode` and `artifact_root`.
`mode` is `virtual` or `repository`; `artifact_root` is null for the default
content-addressed root or one safe repository-relative directory. In virtual
mode the caller owns the returned graph and no filesystem commit is claimed.
In repository mode the host adapter must publish that same graph atomically;
the shipped CLI is that adapter.

Inapplicable values are null or empty arrays, never absent. The host supplies
the selected `source_catalog` for dependencies and `artifact_sink` for virtual
artifacts beside the JSON request; callbacks, filehandles, paths to temporary
files, and host-language objects never enter the public request.

The closed result is:

```text
schema: fsmgen.vial_tool_result.v1
schema_version: 1
action
success
status
source_identities
source_style
semantic_report
formatted_source
bridge_manifest
plan
tool_manifest
verification_output_manifest
result_manifest
artifacts
capability_evidence
support_accounting
diagnostics
implementation
```

Inapplicable report fields are null and artifact arrays are non-null. Private
SemanticIR, bridge-builder objects, ExecutionIR, parser forms, target backend
objects, raw exceptions, code references, filehandles, and absolute host paths
are forbidden. The filesystem CLI is an adapter over this exact request/result
plus source-catalog/artifact-sink boundary.

## Repository-Local Artifact Layout

For `plan` and `run`, the default root is:

```text
.artifacts/vial/<fixture-slug>/<full-plan-sha256>/
```

An explicit `--outdir RELDIR` must be repository-root-relative, resolve on the
repository volume, and remain inside the repository after symlink resolution.
Persisted schemas record the relative identity, never a machine-local absolute
path. Tests, caches, staging, logs, replay files, and generated outputs obey
the same-volume policy; `/tmp`, user-home caches, and off-volume roots are not
fallbacks.

The selected tree is:

```text
OUT/
  vial-tool-manifest.json
  source/vial-normal.vial
  review/...                         # only generated HIAL review artifacts
  hial-vial-bridge.json
  vial-plan.json
  verification-output-manifest.json # run only; schema v2
  backends/<backend-profile>/...     # run only
  results/<result-id-digest>/verification-result-manifest.json # run only
```

Direct HIAL inputs are referenced by identity/digest and are not copied.
Generated IAL1/IAL0 review artifacts retain their canonical text and immediate
provenance under `review/`. The bridge and plan files are byte-for-byte
canonical JSON projections of `fsmgen.hial_vial_bridge_manifest.v1` and
`fsmgen.vial_plan.v1`; private objects are never serialized.

Every virtual artifact has `relpath`, `kind`, `language`, `role`, `content`,
`encoding`, `source_layer`, and `generated_from`. Persisted manifest entries
add `id`, `bytes`, `sha256`, optional `schema`, and optional
`backend_profile`, but omit `content`.

The tool manifest inventories every other declared artifact but deliberately
does not hash itself: including its own digest would create a recursive value
with no finite canonical encoding. The complete returned/committed graph still
contains `vial-tool-manifest.json`, and exact-tree validation includes it.

Writes are all-or-nothing. The filesystem adapter validates the complete
artifact graph and hashes in memory, stages only under
`.artifacts/tmp/vial/<operation-id>/` on the repository volume, fsyncs where
supported, and commits the exact root only after success. Failure removes the
exact owned staging root. An existing identical complete tree returns
`unchanged`; any partial tree, non-identical file, undeclared file, symlink,
path collision, case-fold collision, or file/directory collision fails without
overwrite. No `--force` or broad recursive cleanup option is selected.

## `fsmgen.vial_tool_manifest.v1`

`vial-tool-manifest.json` has exactly:

```text
schema
schema_version
operation_id
status
action
source_style
source_identities
fixture_id
scenario_ids
execution_profile
backend_profile
artifact_root
artifacts
reports
capability_evidence
support_accounting
diagnostics
cleanup
```

`status` in a persisted manifest is `planned` or `executed` and therefore has
empty diagnostics. `checked`, `formatted`, `unchanged`, `unsupported`, and
`error` remain result-envelope statuses. When an identical tree already exists,
the current result is `unchanged` and the stored manifest remains the original
byte-identical `planned`/`executed` record because replay performs no write.
`reports` maps `normal_source`, `bridge`, `plan`, `verification_output`, and
`result` to relative identity/digest records or null. `cleanup` records the
repository-relative staging identity, `staging_removed`, and
`atomic_commit_completed`; it never records a host temp path.

## Verification-Output Manifest Migration

The existing `verification-output-manifest.json` schema version 1 and its two
`.isf` skeleton targets remain byte- and behavior-compatible. Their current
top-level keys, target IDs, paths, validation non-claims, CLI command, and
capability entries do not change in `.8`.

VIAL `run` selects a distinct schema:

```text
schema: fsmgen.verification_output_manifest.v2
schema_version: 2
manifest_id
mode: vial_run
producer
source_set
fixture
plan
profile
artifacts
validation
diagnostics
compatibility
```

Its artifact entries use the persisted artifact metadata family above.
`compatibility` names `legacy_schema:
fsmgen.verification_output_manifest.v1`, records
`legacy_v1_projection_available: false`, and explains that v1 requires one
IAL1 actor/observation-skeleton target and cannot losslessly represent a
multi-source VIAL plan/backend/result tree. Consumers select by explicit
schema, never filename or permissive key probing.

Capability discovery advertises the manifest schema per target. A later owner
may migrate an existing skeleton target to v2 only with a lossless projection,
explicit compatibility tests, and its own task-tree decision. V1 and v2 may
coexist under the same stable filename because each output root contains
exactly one manifest.

## Capability Discovery And Support Accounting

Completed `.10.1` adds `language_surface.vial_tooling` with exact
discovery families for command/API schemas, source styles, accepted HIAL
routes, artifact layout, manifest schemas, supported actions, backend
profiles, diagnostics, limits, and non-claims. It also changes the `.vial`
file-surface CLI list only for actions actually implemented.

Shipped `.10.1` capability IDs are:

```text
vial.tooling.cli.v1
vial.tooling.api.v1
vial.source_projection.normal_v1
vial.source_projection.terse_v1
vial.semantic_projection.v1
```

Completed `.10.2` additionally ships:

```text
vial.artifact_layout.v1
vial.tool_manifest.v1
vial.verification_output_manifest.v2
```

Private bridge/execution capabilities remain separately reported and cannot be
promoted by association. Backend, compile, runtime, result, parity, UVM, VHDL,
mixed-language, and scale capabilities appear only after their exact owners
produce evidence.

Support accounting remains split:

```text
feature.vial_public_check_format
  coverage: vial_public_check_format_cli_api

feature.vial_public_plan
  coverage: vial_public_plan_cli_api

feature.vial_sv_portable_verilator_runtime # shipped by .10.4
```

The existing `verification.vial_ahb_subordinate_base_output_arbitration`
entry continues to prove bounded semantic/private-execution meaning. Distinct
`feature.vial_public_check_format` with coverage
`vial_public_check_format_cli_api` proves `.10.1`; neither entry silently
satisfies public planning or a runtime family.

## Diagnostics And Atomic Failure

The wrapper preserves existing parser/binder diagnostic codes and adds only:

```text
VIAL_TOOL_INVOCATION_ERROR
VIAL_SOURCE_STYLE_ERROR
VIAL_HIAL_SOURCE_ERROR
VIAL_BACKEND_UNSUPPORTED
VIAL_ARTIFACT_PATH_ERROR
VIAL_ARTIFACT_COLLISION
VIAL_MANIFEST_SCHEMA_ERROR
VIAL_RUN_INVOCATION_ERROR
VIAL_RUN_PATH_ERROR
VIAL_RUN_TOOL_ERROR
VIAL_RUN_COMMAND_ERROR
VIAL_RUN_COLLISION
VIAL_RUN_COMPILE_ERROR
VIAL_RUN_RUNTIME_ERROR
VIAL_RUN_LIMIT_EXCEEDED
VIAL_RUN_TRACE_ERROR
VIAL_RUN_RESULT_ERROR
VIAL_RUN_CLEANUP_ERROR
VIAL_RUN_HOST_ERROR
VIAL_HOST_ERROR
```

Each diagnostic has stable `code`, `severity`, `message`, `source_locations`,
`semantic_path`, `related`, `notes`, and `hints`. Locations are source-relative;
filesystem failures are sanitized to repository-relative identities. A failed
check/format has no artifact; failed plan/run returns no partial bridge, plan,
result, or committed tree. Unsupported is a diagnosed capability outcome, not
a downgraded pass.

## Compatibility, Ownership, And Non-Claims

- Existing `.fsm`/`.isf`/`.ppif` commands, generated HDL, report JSON,
  `--emit-verification-output`, skeleton artifacts, and manifest v1 remain
  unchanged.
- `.vial` remains outside default HDL generation. The public boundary is the
  explicit `vial` subcommand.
- HIAL remains an architectural collective name; no `.hial` suffix or HIAL
  authoring language is introduced.
- Plan mode publishes sanitized bridge/plan files, not public constructors or
  raw IR.
- No backend was selected by `.8`. Decision `0043` and completed `.9` select
  `sv_portable_verilator`; completed `.10.1` ships source tooling and completed
  `.10.2` ships plan/artifact behavior. Clean `.10.2` commit `045629c97`
  activates `.10.3` for backend/trace emission. Completed `.10.3` ships that
  private seam; completed `.10.4` exposes its qualified execution through
  public run/result publication. `.11` owns parity against the
  handwritten AHB oracle.
- Factories, phases, objections, UVM component classes, VHDL process plumbing,
  target hierarchy, callbacks, and host-language escape hatches remain backend
  implementation details unless a later typed VIAL semantic owner selects an
  author-facing abstraction.

Completed `.10.1` adds source-style normalization, canonical formatting, the
public source-only CLI/API, capability/support discovery, and diagnostics.
Completed `.10.2` composes the existing private HIAL bridge and execution
builders behind public defensive projections, widens core v1 only to admit a
transaction-free DUT binding for direct IAL0 truth, and atomically publishes
canonical plan trees. It changes no generated HIAL HDL, backend, compile,
simulation, runtime, result, parity, UVM, VHDL, mixed-language, or scale
behavior.

Completed `.10.4` adds the public `run` action, exact command/tool validation,
repository-local bounded execution staging, normalized trace/result/output
manifests, deterministic virtual and filesystem reruns, atomic publication,
and exact cleanup. It adds no complete-four-state, parity, UVM, VHDL,
mixed-language, or scale claim.

## Validation And Rollback

Completed `.10.1` adds task-tree-approved
`t/1555-vial-public-source-tooling.t` and proves:

- normal/terse parse-format-reparse semantic-digest equality and deterministic
  output;
- exact CLI/API request/result shapes and incompatible options;
- closed/defensive CLI/API results, incompatible-option/path/host-object
  diagnostics, no artifact writes, legacy dispatch preservation, and exact
  capability/support accounting.

Completed `.10.2` proves:

- all three HIAL review routes with the checked `.ppif` path proving the
  generated/reparsed IAL1 bridge boundary;
- byte-stable canonical bridge/plan files, artifact ordering/hashes, virtual
  sink parity, default/explicit repository-local roots, idempotent identical
  output, collision/symlink/traversal rejection, and atomic cleanup;
- manifest v1 preservation and exact v2 schema discovery;
- capability/support/non-claim truth, diagnostic sanitization, JSON safety,
  defensive ownership, and no private-object leakage; and
- focused source/bridge/execution tests, docs truth, mdBook, Knowledge Map,
  memory, relative paths, task acceptance, doctrines, and exact output cleanup.

Completed `.10.3` independently proves deterministic backend emission and pure
trace projection without executing a simulator. Completed `.10.4` independently
proves public API byte determinism, atomic CLI publication/unchanged replay,
exact tool/argv qualification, bounded runtime capture, both selected scenario
outcomes, all ten semantic result streams, result-byte identity, and exact
staging cleanup without borrowing planning or emission evidence as runtime
evidence.

Selection rollback remains the decision-`0039` path. `.10.1` implementation
rollback removes only the `vial` source subcommand/API adapter, terse
normalizer/formatter, public tooling capability/support entries, and `t/1555`;
it retains the `.3` normal parser, private bridge/ExecutionIR, decisions
`0032`-`0037`, and every legacy CLI/artifact. Later artifact/backend rollback
is independently scoped to `.10.2` through `.10.4`.
