# FSMGen
This file is the **single entry point** for the project.
Use it first for objective, navigation, and where to find code/docs quickly.

## Memory & continuity (read this to resume in any harness)
- **`MEMORY_ARCHITECTURE.md`** (repo root) is the durable-agent-memory standard for
  this repo — MANDATORY reading, and mechanically enforced. It defines four layers
  by lifecycle and how a fresh agent (any model, any harness) resumes deterministically:
  - **A — resume pointer**: `MEMORY.md` (bounded, overwrite-only — current state + the single next action).
  - **B — work memory**: task-trees under `docs/tasks/` (index: `docs/TASK_TREE.md`).
  - **C — decision records**: durable cross-cutting facts under `docs/decisions/` (index: `docs/decisions/INDEX.md`).
  - **D — audit trail**: `git log` (commit subjects carry the work-unit id).
- Resume order: this `README.md` → `MEMORY_ARCHITECTURE.md` → `MEMORY.md` → the active
  task-tree's frontier row → only the relevant `docs/decisions/` records.
- **Route every durable thing to a layer and commit before the turn ends** — nothing
  important may live only in the conversation. Before committing run
  `scripts/check_doctrines.sh` (git hooks and CI run it too; a non-compliant
  change cannot merge). The doctrine driver includes the doctrine-bootstrap,
  memory architecture, Knowledge Map, and docs path gates. The tool-neutral bootstrap files
  (`AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`,
  `GEMINI.md`, `.windsurfrules`) are pointers back here plus the doctrine and
  toolbox docs.
- **`DOCTRINE_ENFORCEMENT.md`** (repo root) is the portable doctrine-check
  architecture as applied to FSMGEN, and **`TOOLBOX.md`** is the issue
  pinpointing catalog. Use the toolbox commands first when diagnosing failures,
  trace questions, report drift, support-accounting gaps, docs drift, or
  continuity/gate issues.

## Session safety invariant
- The commit workflow in `COMMIT.md` is mandatory and non-negotiable.
- Doctrine enforcement in `DOCTRINE_ENFORCEMENT.md` and the diagnostic toolbox
  in `TOOLBOX.md` are mandatory workflow surfaces; the registered gate is
  `scripts/check_doctrines.sh`.
- Before any code, test, source, generated-artifact, or config change, the work
  must already have task-tree ownership in `docs/TASK_TREE.md` and
  `docs/tasks/*.md`.
- After every completed task, slice, lane, or task-scoped activity, run that workflow before starting or switching to the next one.
- Do not ask the user whether to run it after completion; run it automatically.
- Do not batch several finished tasks into one later cleanup commit.
- Run git index-mutating steps in that workflow sequentially; never overlap `git add`, `git rm`, `git mv`, or `git commit`.
- The reason is operational, not stylistic: task-scoped commits are the project's crash-recovery mechanism for session loss, app crashes, and machine crashes.
- If a task is complete but not committed, that task is not safely finished yet.

## Documentation path invariant
- Paths in live docs and the mdBook must be relative to the repository root.
- Do not record machine-local absolute paths such as user home directories in
  tracked documentation.
- If a note references an external workspace, describe it without linking to a
  local filesystem path.

## Documentation synchronization invariant
- The mdBook is a required user-facing artifact for every future slice that
  changes behavior, syntax, diagnostics, workflow, public contracts, or any
  other user-visible FSMGen behavior.
- Keep the codebase, mdBook, live specs, roadmap/task-tree status, downstream
  handoff/integration docs, public contract docs, capability-manifest metadata,
  support-accounting catalog entries, tests, and explicit deferrals
  synchronized in the same slice as any downstream-visible change. These
  surfaces must convey the same facts from their different viewpoints for any
  downstream consumer; drift is a project bug.
- For downstream-visible `.isf` or `.ppif` changes, also keep
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`,
  `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`,
  `docs/book/src/13i-downstream-integration.md`,
  `docs/book/src/11-extensions-and-embedding.md`, the manifest
  `language_surface.file_surfaces` boundary, and the support-accounting
  catalog synchronized with the codebase, live specs, mdBook, public contract,
  tests, and explicit deferrals. Those files are downstream-consumer
  integration handoffs, not project-specific private notes.
- Do not treat a user-visible implementation slice as complete until the book
  describes the shipped behavior accurately enough for review without reading
  the codebase.

## Project objective
FSMGen compiles Lisp-like `.fsm` state machine specifications into synthesizable HDL, and now accepts `.isf` intent-scheduling sources that lower into explicit scheduled `.fsm` before HDL generation.
FSMGen is currently implemented in Perl 5, but IAL0, IAL1, IAL2, their public
file formats, reports, diagnostics, examples, and this mdBook-facing
documentation are backend-language-neutral contracts. Future Rust, Rust/Wasm,
browser-capable JavaScript, and Dart/web implementations should target those
same observable contracts, with the Perl implementation serving as the current
reference/oracle rather than the definition of the IAL layers; see
[docs/decisions/0018-ial-contracts-are-backend-language-neutral.md](docs/decisions/0018-ial-contracts-are-backend-language-neutral.md).
All future variants and implementations must satisfy FSMGen's public
contracts, not a reduced or parallel contract. The portability goal is
identical in-memory behavior on any suitable platform/environment, with parity
against the Perl reference for features, functionality, diagnostics, semantic
introspection, examples, fixtures, and tests. The mdBook must grow into the
language-independent blueprint for building a conforming variant in language X.
The dedicated task-tree owner for auditing and hardening that portability
contract is
`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER`. Its `.2.2` readiness audit
separated backend-neutral public contracts from current Perl implementation
details and selected exact future leaves. The `.2.3` leaf selected a portable
in-memory request/result API family with JSON-safe envelopes and virtual
artifacts. The `.2.4` leaf selected a source-catalog plus artifact-sink host
abstraction. The `.2.5` leaf selected the Perl-reference parity harness and
normalization rules. The `.2.6` leaf selected the mdBook language-X
implementation blueprint structure and added the implementation-blueprint
chapter. The `.2.7` leaf selected typed extension/plugin support as out of
scope for the first non-Perl implementation experiment unless a future portable
extension API is selected first. The `.2.8` leaf selected the same-repository
Rust/Rust-Wasm portable API smoke as the first implementation experiment. The
`.3.1` leaf scaffolded the additive `fsmgen_portable_api` Rust contract crate
with fail-closed unsupported-operation behavior and no shipped Perl runtime
integration. The `.3.2` leaf added the first direct `.fsm` check smoke for
`feature.direct_sreset_active_high` only, with all other Rust check sources and
non-check operations still fail-closed. The `.3.3` leaf added the first
Perl-oracle parity smoke for that result through a Rust projection binary and a
focused normalized comparison against the Perl check-JSON oracle.
For SystemVerilog-to-Verilog portability, the default stance is still
FSMGen-owned generation/lowering rather than a mandatory external converter.
Tools such as `sv2v` are future audit candidates only: they may become
optional validation aids, or selected dependencies only if a later owned audit
proves exceptional quality and coverage.
Deep semantic introspection is now a first-class FSMGen feature, tracked by
`SEMANTIC-INTROSPECTION-MCP-FRONTIER`. The selected architecture is stable
semantic-introspection API first and MCP as a required adapter over that API.
The capability manifest now exposes a `semantic_introspection` section that
advertises query domains, query families, versioning/provenance/safety policy,
contract sources, read-only defaults, and selected MCP resource/tool mappings
over the existing capability manifest, check JSON, normalized semantic JSON,
schedule JSON, support-accounting, diagnostics, documentation/example,
embedding, and backend-validation surfaces. `bin/fsmgen-mcp` now ships the
first read-only local JSON-RPC stdio adapter over that contract; the manifest
reports `mcp_adapter_implemented: true` while `write_generation_tools_enabled`
remains false. The adapter now has protocol-level JSON-RPC error-code policy,
id-less notification silence, malformed source-URI percent-encoding rejection,
non-leaking source-query provenance, and bounded support-accounting summary
queries. The shipped client profile is guarded by bounded MCP envelope
snapshots under `t/fixtures/semantic_introspection_mcp/` and documented in the
mdBook compatibility matrix. Official MCP 2025-06-18 stdio framing is
newline-delimited JSON-RPC; FSMGen's stdio path is guarded for one compact
message per line. MCP client roots are not consumed in the shipped profile;
the explicit `--workspace-root` launch argument remains the only source
authority for source-bound queries.
MCP prompt templates are not advertised yet; the shipped semantic surface is
the structured resource/tool API. MCP resource subscriptions and list-change
notifications are also unadvertised in the shipped static-resource profile.
MCP completions are deferred until bounded candidate providers are selected.
MCP logging is deferred until a bounded log-message contract is selected.
MCP pagination is bounded and unpaginated: resource/template/tool list
responses do not emit `nextCursor`, and unissued cursor parameters are rejected
as invalid params.
MCP sampling and elicitation are unsupported in the read-only profile; FSMGen
does not initiate model calls or user-input requests through MCP.
MCP Streamable HTTP and service mode are not shipped; `bin/fsmgen-mcp` exposes
only one-shot `--request-json` and newline-delimited JSON-RPC stdio transports.
Read-only MCP tool calls now return MCP `structuredContent` matching the
serialized JSON text block, and advertise compact per-tool `outputSchema`
envelopes for stable public fields while keeping volatile nested reports
schema-light. The shipped tool descriptors also advertise MCP tool annotations
as read-only and closed-world: `readOnlyHint: true` and `openWorldHint: false`.
`destructiveHint` and `idempotentHint` remain absent because the shipped tools
are not write tools. Common MCP annotations on resources, resource templates,
resource-read contents, and tool-result text blocks remain absent for now, and
tool results do not return resource links; the shipped resource/tool APIs are
the stable navigation surface. MCP progress tokens do not create progress
notifications in the one-shot/stdin profile, and id-less
`notifications/cancelled` messages remain silent notifications rather than a
job-cancellation API. JSON-RPC batch arrays and other non-object request
envelopes are unsupported and return `-32600 Invalid Request`; the shipped
stdio profile remains one compact JSON-RPC request object per line. The MCP
initialize response reports the single supported protocol version
`2025-06-18`; unsupported client protocol strings do not get echoed back, and
client capabilities do not widen the server's minimal resources/tools
capability set. JSON-RPC errors remain message-only for now: stable error
`code`, sanitized `message`, and no `error.data` until a bounded error-data
schema is selected. `initialize.serverInfo` includes the stable display title
`FSMGen Semantic Introspection`, and the instructions remain a compact
read-only semantic-introspection profile summary. The immediate MCP
protocol-hardening pass is now exhausted. Read-only source discovery is now
catalog-backed through `fsmgen://sources` and `fsmgen_discover_sources`: it
uses the existing manifest support catalog, returns only repo/workspace-relative
source identities plus file kind, source kind, query availability, and support
metadata, and does not perform arbitrary workspace traversal, expose hidden
paths, or return machine-local absolute paths. The immediate read-only
semantic-introspection/MCP pass is complete through
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.30`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.223`
now ships bounded dynamic write transaction-ID capture and `BID` response
matching, and `.365` extends that single-active write boundary with same-cycle
release-and-recapture. `DOCTRINE-ENFORCEMENT-ADOPTION.1` now adopts the
portable doctrine driver and FSMGEN toolbox.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.227` now ships
generated bounded single-beat dynamic read ID capture and `RID` matching
behavior through explicit `response-demux.read`, and
`IAL2-FEATURE-COMPLETENESS-FRONTIER.231` now ships generated bounded dynamic
read burst-last/`RLAST` transaction-ID capture and response matching.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.234` now ships bounded scalar dynamic
read-data capture over generated single-active dynamic read response-demux for
one dynamic read transaction. `IAL2-FEATURE-COMPLETENESS-FRONTIER.236` now
adds bounded focused validation for the shipped dynamic transaction-ID family.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.237` audited dynamic burst-length capture
readiness and selected direct bounded report-only raw-`ARLEN` implementation.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.238` now ships generated report-only
dynamic raw-`ARLEN` burst-length capture over generated dynamic last-beat
read-data. `IAL2-FEATURE-COMPLETENESS-FRONTIER.240` now ships generated
dynamic runtime beat-count/`RLAST` validation over that generated dynamic
last-beat boundary, with a support-accounted runtime PPIF sample and the
report-only sample preserved. `IAL2-FEATURE-COMPLETENESS-FRONTIER.241`
selected `.242`, readiness audit for generated dynamic multi-beat output-bank
behavior over the selected dynamic runtime-validation boundary. `.242`
selected `.243`, and `.243` now ships generated dynamic multi-beat read-data
output-bank behavior over generated dynamic runtime validation. `.244`
selected `.245`, readiness audit for multiple/mixed dynamic response-demux
behavior after generated dynamic multi-beat output banks. `.245` selected
`.246`, public contract selection for bounded multiple dynamic write
response-demux behavior, `.246` selected `.247`, and `.247` now ships
generated bounded multiple dynamic write response-demux for all-dynamic write
families with onehot0 same-cycle requests and pairwise unique active dynamic
IDs. `.248` selected `.249`, readiness audit for multiple dynamic read
response-demux after that multiple dynamic write boundary, and `.249`
selected `.250`, public contract selection for bounded multiple dynamic read
response-demux. `.250` selected `.251`, and `.251` now ships generated
bounded multiple dynamic read single-beat response-demux for all-dynamic read
families with onehot0 same-cycle requests and pairwise unique active dynamic
IDs. `.252` selected `.253`, readiness audit for multiple dynamic read
burst-last/`RLAST` response-demux after that single-beat boundary. `.253`
selected `.254`, public contract selection for bounded multiple dynamic read
burst-last/`RLAST` response-demux. `.254` selected `.255`, direct generated
behavior for bounded multiple dynamic read burst-last/`RLAST` response-demux.
`.255` now ships that generated behavior with the support-accounted public
sample
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif`.
`.256` selected `.257`, readiness audit for read-data over generated multiple
dynamic read response-demux, because dynamic read-data coverage still
accepted exactly one dynamic read transaction while the response-demux
substrate had multiple dynamic completion pulses. `.257` selected `.258`,
public contract selection for bounded scalar read-data over generated
multiple dynamic read response-demux. `.258` selected `.259`, and `.259` now
ships generated bounded scalar single-beat and scalar last-beat read-data
over all-dynamic multiple read response-demux through the support-accounted
public samples `ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif`
and
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif`.
`.260` selected `.261`, readiness audit for generated burst-length and
runtime beat-count/`RLAST` validation over generated multiple dynamic read
response-demux, because multi-beat output-bank widening depends on
per-transaction raw-`ARLEN` capture and runtime counter/assertion semantics
across multiple active dynamic reads. `.261` selected `.262`, public
contract selection for bounded burst-length/runtime validation over generated
multiple dynamic read response-demux, because the lower helpers are close
after coverage admission but sample names, split/combined report-only/runtime
scope, report vocabulary, diagnostics, validation, and residue need contract
ownership before implementation. `.262` selected a split implementation, and
`.263` now ships report-only raw-`ARLEN` burst-length capture over generated
multiple dynamic read response-demux through
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif`.
`.264` now ships the runtime beat-count/`RLAST` assertion sibling through
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif`.
`.265` selects `.266`, readiness audit for generated multiple dynamic
multi-beat output-bank behavior over the generated multiple dynamic read
runtime-validation boundary. `.266` selects `.267`, public contract selection
for bounded generated multiple dynamic multi-beat output-bank behavior. `.267`
selected `.268`, and `.268` now ships generated bounded multiple dynamic
multi-beat output-bank behavior through the support-accounted public sample
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif`.
`.269` selected `.270`, readiness audit for mixed dynamic/static
response-demux after the all-dynamic multiple dynamic
write/read/read-data/multi-beat chain is now covered. `.270` selected `.271`,
public contract selection for bounded mixed dynamic/static write `BID`
response-demux. `.271` selected `.272`, direct generated behavior for that
bounded mixed write contract, with existing `response-demux.write` syntax,
exactly one dynamic write transaction, exactly one concrete static write
transaction, and static concrete IDs reserved away from dynamic capture. No
behavior changed in `.270` or `.271`; `.272` shipped that bounded write
behavior. `.273` selected `.274`, readiness audit for mixed dynamic/static read
response-demux before choosing single-beat `RID`, burst-last `RID && RLAST`,
read-data, burst/runtime, multi-beat, report cleanup, or another prerequisite.
`.274` selected `.275`, public contract selection for bounded mixed
dynamic/static read single-beat `RID` response-demux. `.275` selected `.276`,
direct generated behavior for that bounded mixed read contract. `.276` now
ships the bounded read behavior through support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif`.
`.277` selected `.278`, readiness audit for bounded mixed dynamic/static read
burst-last `RID && RLAST` response-demux. `.278` selected `.279`, public
contract selection for that burst-last shape, and `.279` selected `.280`,
direct generated behavior. `.280` now ships generated bounded mixed
dynamic/static read burst-last `RID && RLAST` response-demux through
support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif`.
The shipped behavior uses existing `response-demux.read` syntax with
`response-scope burst-last`, one-bit `axi0_rlast`, one dynamic read
transaction and one concrete static read transaction, reserves static literal
`4'd3` away from dynamic capture, keeps raw `RID` beat assertions separate
from final `RID && RLAST` completions, and reports
`bounded_mixed_dynamic_static_read_rid_rlast_demux_contract`. `.281` selected
`.282`, readiness audit for read-data over generated mixed dynamic/static read
response-demux, because scalar read-data coverage is the next dependency
before mixed burst-length/runtime validation or multi-beat output-bank work.
`.282` selected `.283`, public contract selection for bounded scalar read-data
over generated mixed dynamic/static read response-demux, after finding the
read-data helper substrate close but not contract-complete for the new mixed
completion sources. `.283` selected `.284`, direct generated behavior for
bounded scalar read-data over generated mixed dynamic/static read
response-demux. `.284` now ships that behavior through support-accounted
public samples
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif`
and
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif`.
The shipped capture covers the ordered dynamic-plus-static transaction set,
guards scalar `RDATA`/`RRESP` updates only with generated mixed demux
completion pulses, and reports the mixed-specific single-beat and last-beat
completion-validity strings. `.285` selected `.286`, readiness audit for
generated report-only raw-`ARLEN` burst-length capture over the mixed
dynamic/static last-beat read-data shape. `.286` selected `.287`, direct
bounded implementation of that report-only raw-`ARLEN` capture shape. `.287`
now ships that behavior through support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length.ppif`.
The shipped capture reuses the existing `burst-length` syntax with `source
arlen`, width-8 `axi0_arlen`, `axlen-plus-one` encoding, request capture, and
`validation report-only`; emits per-transaction raw-`ARLEN` storage/capture
rules; keeps scalar `RDATA`/`RRESP` capture guarded only by generated mixed
`RID && RLAST` completion pulses; and reports
`generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`
plus `report_only` burst-length validation. `.288` selected `.289`, direct
bounded implementation of runtime beat-count/`RLAST` validation over that same
mixed dynamic/static raw-`ARLEN` scalar last-beat read-data shape, after
finding the generic runtime machinery ready and no separate public contract
selection needed. `.289` now ships that runtime sibling through
support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion.ppif`.
The generated behavior emits expected-beat storage, read-beat counters,
request-time `ARLEN + 1` initialization, raw matched-read-beat counter
increments for the dynamic captured `RID` and static concrete `RID`, four
runtime assertions per covered transaction, and report/residue updates with
`runtime_assertion`, `response_demux_matched_read_beat`, and no
`generated_beat_count_validation` residue while preserving `.287`
report-only behavior. `.290` selected `.291`, direct bounded implementation
of generated mixed dynamic/static multi-beat output banks over the `.289`
runtime boundary, after finding the existing output-bank machinery
transaction-list driven and the current blocker local to the mixed coverage
predicate. `.291` now ships that behavior through support-accounted public
sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif`.
The generated behavior emits per-transaction data/status output banks, valid
masks, length outputs, scalar worst-observed `RRESP` aggregate outputs,
request-time output-bank clearing, raw matched-read-beat lane capture for the
dynamic captured `RID` and the static concrete `RID`, raw `ARLEN`/expected
beat/count state, four runtime assertions per transaction, empty read-data
residue, and `response_demux.residue = [same_id_ordering]`. `.291` selected
`.292`, the next mixed dynamic/static frontier selector after generated mixed
multi-beat output banks. `.292` now selects `.293`, readiness audit for
multiple mixed dynamic/static transaction cardinality after the one-dynamic
plus one-concrete-static mixed path reached multi-beat output banks. `.293`
now selects `.294`, public contract selection for bounded multiple mixed
dynamic/static write `BID` response-demux, after confirming the current mixed
write/read plan builders and read-data coverage predicates remain singular
while mixed assertion generation is already list-shaped. `.294` now selects
`.295`, direct generated behavior for exactly one dynamic plus two concrete
static write transactions under existing `response-demux.write` syntax, with
new `bounded_multi_mixed_dynamic_static_write_bid_demux_contract` report
vocabulary. `.295` now ships that bounded multiple mixed write behavior
through support-accounted public sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif`.
The generated behavior emits dynamic selected-ID/busy state, per-static busy
state, dynamic capture exclusions for static IDs `4'd3` and `4'd5`, onehot0
request assertions across all selected write transactions, three raw `BID`
response-demux completion pulses, pairwise unique-match assertions, and
list-shaped report fields while preserving the `.272` one-dynamic plus
one-static report contract. `.296` now selects `.297`, readiness audit for
multiple mixed dynamic/static read response-demux after the widened write
contract shipped, because the read plan builder still remains singular while
read-side `RID` and `RID && RLAST` scopes need an owned parity audit before
contract selection or implementation. `.297` now selects `.298`, public
contract selection for bounded multiple mixed dynamic/static read single-beat
`RID` response-demux, leaving burst-last `RID && RLAST`, read-data,
burst-length/runtime validation, multi-beat output banks, broader mixed
cardinalities, same-cycle widening, queues/scoreboards, backend variants, and
VHDL as later owners. `.298` now selects `.299`, direct generated behavior
for exactly one dynamic plus two concrete static read transactions under
existing `response-demux.read` syntax with `response-scope single-beat`,
candidate report mode
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`, and list-shaped
static-ID reservation fields. `.299` now ships that bounded multiple mixed
read behavior through support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif`.
The generated behavior emits dynamic selected-ID/busy state, per-static busy
state, dynamic capture exclusions for static IDs `4'd3` and `4'd5`, onehot0
request assertions across all selected read transactions, three raw
single-beat `RID` response-demux completion pulses, pairwise unique-match
assertions, and list-shaped report fields while preserving the `.276`
one-dynamic plus one-static read report contract. `.299` selected `.300`,
the next exact IAL2 feature-completeness selector after widened mixed read
single-beat behavior. `.300` now selects `.301`, readiness audit for
multiple mixed dynamic/static read burst-last `RID && RLAST` response-demux,
because read-data, burst-length/runtime validation, and multi-beat output
banks over the multi-static mixed read shape need the final-beat completion
contract audited first. `.301` now selects `.302`, public contract selection
for bounded multiple mixed dynamic/static read burst-last `RID && RLAST`
response-demux, after a guarded temporary candidate confirmed the current
fail-closed diagnostic for the multi-static burst-last shape. `.302` now
selects `.303`, direct generated behavior for that bounded multiple mixed
read burst-last contract: exactly one dynamic read plus two pairwise-distinct
concrete static reads under existing `response-demux.read` syntax with
`response-scope burst-last`, one-bit `last-signal`, mode
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
list-shaped mixed/static-ID reservation fields, raw `RID` ownership
assertions, and final `RID && RLAST` completion pulses for `r0`, `r1`, and
`r2`. `.303` now ships that bounded multiple mixed read burst-last behavior
through support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif`.
The generated behavior emits dynamic selected-ID/busy state, per-static busy
state, dynamic capture exclusions for static IDs `4'd3` and `4'd5`, onehot0
request assertions across all selected read transactions, three final-beat
`RID && RLAST` completion pulses, pairwise raw `RID` unique-match assertions,
and list-shaped report fields while preserving the `.276`, `.280`, and `.299`
public report contracts. `.303` selected `.304`, the next exact IAL2
feature-completeness selector after widened mixed read burst-last behavior.
`.304` now selects `.305`, readiness audit for bounded scalar read-data over
generated multiple mixed dynamic/static read response-demux, because `.299`
and `.303` now provide the single-beat and burst-last generated completion
pulses that scalar `RDATA`/`RRESP` capture would consume. The audit must
settle candidate sample stems, completion-validity vocabulary,
dynamic-then-static transaction coverage, diagnostics, validation strategy,
rollback, and residue before raw `ARLEN`, runtime validation, multi-beat
output banks, broader cardinalities, same-cycle widening, queues/scoreboards,
backend variants, or VHDL widen. `.305` now selects `.306`, public contract
selection for bounded scalar read-data over generated multiple mixed
dynamic/static read response-demux, after finding that the scalar read-data
normalization/capture path can already handle arbitrary covered transaction
counts but the current mixed dynamic/static coverage branch only admits the
one-dynamic plus one-static completion sources. `.306` now selects `.307`,
direct generated behavior for that bounded scalar read-data contract over
generated multiple mixed dynamic/static read response-demux. The selected
samples are
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif`
and
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data.ppif`;
the contract uses dynamic-then-static transaction coverage `r0, r1, r2` and
completion-validity strings
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`
and
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`.
`.307` now ships that generated bounded scalar read-data behavior through the
two support-accounted public samples. The generated behavior emits shared
`axi0_rdata`/`axi0_rresp` inputs, scalar data/status outputs for `r0`, `r1`,
and `r2`, one read-data capture rule per transaction guarded only by the
generated multiple mixed demux completion pulse, and report entries that bind
the ordered dynamic-then-static transaction set to the new completion-validity
strings while keeping raw `ARLEN`, runtime validation, multi-beat output
banks, broader cardinalities, same-cycle widening, queues/scoreboards,
backend variants, and VHDL deferred. `.307` selected `.308`, the next exact
IAL2 feature-completeness selector after widened multiple mixed read-data
behavior.
`.308` now selects `.309`, readiness audit for generated report-only
raw-`ARLEN` burst-length capture over generated multiple mixed dynamic/static
read burst-last response-demux and scalar last-beat read-data. The selector
changes no behavior; it chooses the audit because runtime validation and
multi-beat output banks over the multiple mixed shape depend on first settling
request-time raw-`ARLEN` capture for the dynamic transaction and both concrete
static transactions.
`.309` selected `.310`, direct bounded implementation of report-only
raw-`ARLEN` burst-length capture over generated multiple mixed dynamic/static
read burst-last response-demux and scalar last-beat read-data. `.310` now
ships that generated behavior through the support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length.ppif`;
the generated IAL1 adds `axi0_arlen`, raw request-time storage
`axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and `axi0_r2_arlen_q`, request-guarded
burst-length capture rules for `r0`, `r1`, and `r2`, report artifact lists,
and scalar last-beat payload capture still guarded only by generated multiple
mixed `RID && RLAST` completion pulses. `.310` selected `.311`, readiness
audit for generated runtime beat-count/`RLAST` validation over the same
multiple mixed raw-`ARLEN` boundary. Runtime validation, multi-beat output
banks, broader cardinalities, same-cycle widening, queues/scoreboards,
backend variants, and VHDL remain deferred.
`.311` now selects `.312`, direct bounded implementation of runtime
beat-count/`RLAST` validation over generated multiple mixed dynamic/static
raw-`ARLEN` last-beat read-data. The audit changes no behavior; it finds that
the existing runtime-validation machinery is already transaction-list driven
across `r0`, `r1`, and `r2` once the multiple mixed last-beat coverage branch
admits `validation runtime-assertion`. The selected public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_runtime_assertion.ppif`;
multi-beat output banks, broader cardinalities, same-cycle widening,
queues/scoreboards, backend variants, and VHDL remain deferred.
`.312` now ships that runtime-validation behavior. FSMGen emits generated
`axi0_r0_expected_beats_q`, `axi0_r1_expected_beats_q`, and
`axi0_r2_expected_beats_q`, generated `axi0_r0_read_beat_count_q`,
`axi0_r1_read_beat_count_q`, and `axi0_r2_read_beat_count_q`, request-time
beat-count initialization, raw matched-read-beat increment rules, and four
runtime assertions per covered transaction. The public sample reports twelve
generated beat-count assertions and removes `generated_beat_count_validation`
from read-data residue while keeping scalar last-beat `RDATA`/`RRESP` capture
guarded by generated multiple mixed `RID && RLAST` completion pulses.
Multi-beat output banks, broader cardinalities, same-cycle widening,
queues/scoreboards, backend variants, and VHDL remain deferred.
`.312` selected `.313`, readiness audit for generated multiple mixed
dynamic/static multi-beat output banks over this runtime-validation boundary.
`.313` now selects `.314`, direct bounded implementation of generated
multiple mixed dynamic/static multi-beat output banks over that same boundary.
The audit changes no behavior; it finds the public multi-beat syntax,
runtime-assertion `ARLEN` metadata, and transaction-list-driven output-bank
helpers are already present once the multiple mixed coverage branch admits the
runtime multi-beat source shape. The selected public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat.ppif`.
The implementation owner should also add multiple mixed multi-beat
report-residue recognition so the new sample leaves empty read-data residue
and only same-ID ordering response-demux residue.
`.314` now ships that multi-beat behavior. FSMGen emits 48 generated `RDATA`
lane outputs, 48 generated `RRESP` lane outputs, three valid-mask outputs,
three length outputs, three scalar worst-observed `RRESP` aggregate outputs,
per-lane capture rules, output-bank init rules, raw `ARLEN` storage,
expected-beat storage, read-beat counters, and twelve runtime assertions for
`r0`, `r1`, and `r2`. Reports use
`bounded_multi_beat_read_data_contract`, leave `read_data.residue` empty, and
leave response-demux residue limited to `same_id_ordering`. `.314` selected
`.315`, the next exact-owner selector after the multiple mixed dynamic/static
read-data chain reached multi-beat output banks.
`.315` now selects `.316`, readiness audit for broader mixed dynamic/static
transaction cardinality after the one-dynamic plus one- or two-static mixed
chain reached multi-beat output banks. The selector changes no behavior; it
chooses an audit because widening beyond the current bounded shapes could mean
two dynamic plus one static transaction, one dynamic plus three static
transactions, a capped "at least one dynamic and at least one static" set, or
a helper/report cleanup or public contract-selection prerequisite before
implementation.
`.316` now selects `.317`, public contract selection for the first broader
mixed dynamic/static transaction-cardinality shape. The audit changes no
behavior; it finds that mixed demux admission, mixed demux construction,
read burst-last normalization, read-data coverage, and multi-beat residue
predicates all still encode the exact one-dynamic plus one- or two-static
boundary, even though several downstream report/assertion/output-bank helpers
are already transaction-list driven.
`.317` now selects `.318`, direct generated behavior for bounded one-dynamic
plus three-concrete-static write `BID` response-demux. The contract selection
changes no behavior; it reuses the existing
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract` report mode and
chooses public sample stem
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif`.
`.318` now ships that public sample and generated write behavior. Mixed
dynamic/static write response-demux accepts exactly one dynamic write
transaction plus one, two, or three pairwise-distinct concrete static write
transactions, emits generated completion pulses/rules for the full covered
set, records list-shaped static ID reservations/exclusions, and keeps the
existing multi-mixed write report mode.
`.319` now selects `.320`, readiness audit for bounded one-dynamic plus
three-concrete-static mixed dynamic/static read response-demux. The selector
changes no behavior and starts the audit at the single-beat `RID` boundary
before burst-last, read-data, two-dynamic-plus-static, general capped mixed
sets, same-cycle, queue/scoreboard, backend, or VHDL work.
`.320` now selects `.321`, public contract selection for bounded
one-dynamic plus three-concrete-static mixed dynamic/static read single-beat
`RID` response-demux. The audit changes no behavior; it finds the
report/assertion surface is already list-shaped while read admission,
burst-last normalization, and read-data coverage still encode the
one-dynamic plus one- or two-static read boundary.
`.321` now selects `.322`, direct generated behavior for bounded
one-dynamic plus three-concrete-static mixed dynamic/static read single-beat
`RID` response-demux. The selector changes no behavior; it reuses existing
`response-demux.read` syntax and the
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract` report mode,
with cardinality carried by existing list-shaped fields.
`.322` now ships that public sample and generated read single-beat behavior.
Mixed dynamic/static read single-beat response-demux accepts exactly one
dynamic read transaction plus one, two, or three pairwise-distinct concrete
static read transactions, emits generated completion pulses/rules for the
full covered set, records list-shaped static ID reservations/exclusions, and
keeps the existing multi-mixed read report mode. Burst-last and read-data over
the three-static read boundary remain fail-closed.
`.323` is the next exact-owner selector after the three-static mixed read
single-beat demux.
`.323` now selects `.324`, readiness audit for bounded one-dynamic plus
three-concrete-static mixed dynamic/static read burst-last `RID && RLAST`
response-demux. The selector changes no behavior and keeps read-data over the
three-static boundary behind final-beat completion semantics.
`.324` now selects `.325`, public contract selection for bounded one-dynamic
plus three-concrete-static mixed dynamic/static read burst-last `RID && RLAST`
response-demux. The audit changes no behavior; it finds the shipped
three-static single-beat read demux and the existing two-static burst-last
demux are list-shaped, while burst-last admission and read-data coverage
remain explicitly fail-closed for the three-static read boundary.
`.325` now selects `.326`, direct generated behavior for bounded one-dynamic
plus three-concrete-static mixed dynamic/static read burst-last `RID && RLAST`
response-demux. The selector changes no behavior; it reuses existing
`response-demux.read` burst-last syntax, public sample stem
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif`,
and report mode
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`.
`.326` now ships that public sample and generated read burst-last behavior.
Mixed dynamic/static read burst-last response-demux accepts exactly one
dynamic read transaction plus one, two, or three pairwise-distinct concrete
static read transactions, emits generated final-beat completion pulses/rules
for the full covered set, records list-shaped static ID
reservations/exclusions, keeps raw `RID` active-match assertions separate
from `RID && RLAST` completion, and preserves the existing multi-mixed read
burst-last report mode. Read-data over the three-static read boundary remains
fail-closed.
`.327` now selects `.328`, readiness audit for bounded scalar read-data over
generated one-dynamic plus three-concrete-static mixed dynamic/static read
response-demux. The selector changes no behavior; current read-data coverage
still admits the generated multi-mixed completion sources only for exactly
one dynamic plus two concrete static read transactions, so the audit is the
next narrow owner before any three-static read-data behavior.
`.328` now selects `.329`, public contract selection for bounded scalar
read-data over generated one-dynamic plus three-concrete-static mixed
dynamic/static read response-demux. The audit changes no behavior; scalar
read-data normalization, capture-rule generation, and report artifacts are
already transaction-list driven once coverage admits the `r0`, `r1`, `r2`,
`r3` set, but the public samples, support identities, diagnostics, and
residue need a contract owner before implementation.
`.329` now selects `.330`, direct generated behavior for bounded scalar
read-data over generated one-dynamic plus three-concrete-static mixed
dynamic/static read response-demux. The selector changes no behavior; it
fixes the two public sample stems, support identities, transaction order
`r0`, `r1`, `r2`, `r3`, completion-validity vocabulary, scalar output names,
diagnostics, validation gates, rollback, and residue while keeping
three-static `burst_length`, runtime validation, and multi-beat output banks
behind later owners.
`.330` now ships that behavior. The support-accounted public samples
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_read_data.ppif`
and
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data.ppif`
generate scalar `RDATA`/`RRESP` capture for `r0`, `r1`, `r2`, and `r3`
over the generated one-dynamic plus three-concrete-static mixed read demux
completion pulses. Reports keep the existing multi-mixed read response-demux
modes and expose read-data completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`
or
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`.
Three-static `burst_length`, runtime beat-count/`RLAST` validation, and
multi-beat output banks remain fail-closed. `.331` now selects `.332`,
readiness audit for report-only raw-`ARLEN` burst-length capture over the
generated one-dynamic plus three-concrete-static mixed dynamic/static read
burst-last response-demux and scalar last-beat read-data. The selector
changes no behavior and keeps runtime validation, multi-beat output banks,
two-dynamic-plus-static shapes, broader cardinalities, same-cycle widening,
queues/scoreboards, backend variants, and VHDL behind later owners.
`.332` now selects `.333`, direct bounded implementation of report-only
raw-`ARLEN` burst-length capture over that same generated three-static
last-beat read-data boundary. The audit changes no behavior; the public
`burst-length` syntax and transaction-list driven raw-`ARLEN` storage,
capture-rule, and report helpers are already ready once coverage admits the
`r0`, `r1`, `r2`, `r3` transaction set. Three-static runtime validation and
multi-beat output banks remain deferred.
`.333` now ships that behavior. The support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length.ppif`
generates width-8 `axi0_arlen`, raw-`ARLEN` storage and request capture rules
for `r0`, `r1`, `r2`, and `r3`, and scalar last-beat `RDATA`/`RRESP` capture
still guarded by generated mixed `RID && RLAST` completion pulses. Reports
mark `burst_length_validation` as `report_only`, list generated
burst-length input/storage/rules, and keep runtime beat-count/`RLAST`
validation and multi-beat output banks fail-closed. `.334` now audits runtime
validation readiness over this three-static raw-`ARLEN` boundary.
`.334` now selects `.335`, direct bounded implementation of runtime
beat-count/`RLAST` validation over the same three-static raw-`ARLEN`
last-beat read-data boundary. The audit changes no behavior; runtime
validation syntax/report vocabulary, expected-beat storage, beat-count
storage, beat-count rules, assertions, and residue movement are already
transaction-list driven after coverage admits the `r0`, `r1`, `r2`, `r3`
transaction set. Three-static multi-beat output banks remain fail-closed.
`.335` now ships that behavior. The support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_runtime_assertion.ppif`
generates raw-`ARLEN`, expected-beat, and read-beat-count storage for `r0`,
`r1`, `r2`, and `r3`; request-time expected-count initialization;
matched-read-beat counter increments; and four runtime assertions per
covered transaction. Reports mark `beat_count_validation_generated_behavior`
true and remove generated beat-count validation from residue while keeping
multi-beat output banks deferred. `.336` now audits multi-beat output-bank
readiness over this three-static runtime boundary.
`.336` now selects `.337`, direct bounded implementation of generated
multi-beat output banks over that same one-dynamic plus three-concrete-static
mixed dynamic/static runtime-validation read-data boundary. The audit changes
no behavior; public multi-beat syntax, output-bank report vocabulary,
runtime-assertion `ARLEN` metadata, and transaction-list-driven output-bank
helpers are already present. The remaining implementation gap is local to
three-static multi-beat coverage admission, response-demux residue
recognition, support publication, and focused assertions. Two-dynamic-plus
static shapes, broader mixed cardinalities, queues/scoreboards, backend
variants, and VHDL remain deferred.
`.337` now ships generated multi-beat output banks over that same
one-dynamic plus three-concrete-static runtime-validation boundary through
support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat.ppif`.
The sample emits per-transaction output banks for `r0`, `r1`, `r2`, and
`r3`, including 64 generated `RDATA` lanes, 64 generated `RRESP` lanes,
valid masks, length outputs, scalar worst-observed `RRESP` aggregates,
raw-`ARLEN` storage, expected-beat storage, beat counters, lane capture,
aggregate update, and sixteen runtime beat-count/`RLAST` assertions.
Reports mark the read-data residue empty and keep response-demux residue
limited to `same_id_ordering`. Two-dynamic-plus-static shapes, broader mixed
cardinalities, same-cycle widening, queues/scoreboards, backend variants,
and VHDL remain deferred.
`.338` now selects `.339`, readiness audit for two-dynamic-plus-one-static
mixed dynamic/static write `BID` response-demux. The selector changes no
behavior and starts at write response-demux because it is the smallest
behavior-bearing boundary before read response-demux, read-data,
burst-length/runtime validation, or multi-beat output-bank widening can
depend on a combined multiple-dynamic-plus-static policy.
`.339` now selects `.340`, public contract selection for that
two-dynamic-plus-one-static mixed write `BID` response-demux boundary. The
audit changes no behavior; current mixed write admission and constructors
still require exactly one dynamic write transaction plus one, two, or three
concrete static write transactions, while the two-dynamic-plus-static shape
needs an owned public report/assertion contract that combines multi-dynamic
active selected-ID uniqueness with static concrete-ID reservations and
dynamic-vs-static exclusions.
`.340` now selects `.341`, direct generated behavior for bounded
two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux.
The selector changes no behavior. It chooses public sample stem
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic`,
focused behavior label `mixed_dynamic_static_write_demux_multi_dynamic`,
dynamic write transactions `w0`/`w1`, static write transaction `w2` with ID
`3`, the existing `bounded_multi_mixed_dynamic_static_write_bid_demux_contract`
report mode, `onehot0_mixed_write_request`, active dynamic selected-ID
uniqueness, static concrete-ID reservation/exclusion, and mixed response
active/unique assertion roles.
`.341` now ships that generated behavior through the support-accounted public
sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`.
Mixed dynamic/static write response-demux now accepts exactly two dynamic
write transactions plus one concrete static write transaction, emits selected
dynamic ID/busy state for `w0`/`w1`, static busy state for `w2`, onehot0
mixed request assertions, per-dynamic request no-active-same-ID checks,
pairwise active dynamic selected-ID uniqueness, static-ID reservation and
request/active exclusion for `4'd3`, three raw `BID` completion pulses, and
list-shaped report fields while preserving the `.272`, `.295`, and `.318`
mixed write report contracts.
`.342` now selects `.343`, public contract selection for bounded
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
response-demux. The audit changes no behavior; mixed read admission and
construction remain singular on the dynamic side while the lower substrate is
close after `.341` write behavior and `.251` multiple all-dynamic read
behavior. `.343` must settle the public sample stem, support identity,
behavior label, transaction order, static concrete ID, report mode,
completion source, `active_dynamic_ids_must_be_unique`, static-ID exclusions,
assertion names, diagnostics, validation, residue, rollback, and next
frontier before any parser, generator, PPIF sample, support-accounting, test,
JSON, or HDL behavior changes.
`.343` now selects `.344`, direct generated behavior for that bounded
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
response-demux contract. The selector changes no behavior. It chooses public
sample stem
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic`,
focused behavior label `mixed_dynamic_static_read_demux_multi_dynamic`,
dynamic read transactions `r0`/`r1`, static read transaction `r2` with ID
`3`, existing report mode
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`, completion
source `generated_multi_mixed_dynamic_static_read_demux`,
`onehot0_mixed_read_request`, active dynamic selected-ID uniqueness, static
concrete-ID reservation/exclusion, and raw `RID` response active/unique
assertion roles.
`.344` now ships that generated behavior through the support-accounted public
sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif`.
Mixed dynamic/static read single-beat response-demux now accepts exactly two
dynamic read transactions plus one concrete static read transaction, emits
selected dynamic ID/busy state for `r0`/`r1`, static busy state for `r2`,
onehot0 mixed request assertions, per-dynamic request no-active-same-ID
checks, pairwise active dynamic selected-ID uniqueness, static-ID reservation
and request/active exclusion for `4'd3`, three raw `RID` completion pulses,
and list-shaped report fields while preserving the `.276`, `.299`, and
`.322` mixed read single-beat report contracts.
`.345` now selects `.346`, public contract selection for bounded
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST`
response-demux. The audit changes no behavior. A scratch guarded strict-check
probe confirmed the current burst-last mixed dynamic/static boundary still
fails closed for this shape, while the lower substrate is close after `.344`
single-beat behavior and the `.303`/`.326` mixed burst-last patterns. `.346`
must settle the public sample stem, support identity, behavior label, last
signal policy, report mode
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
raw `RID` beat ownership assertions, final `RID && RLAST` completions,
diagnostics, validation, residue, rollback, and next frontier before any
parser, generator, PPIF sample, support-accounting, test, JSON, or HDL
behavior changes.
`.346` now selects `.347`, direct generated behavior for that bounded
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST`
response-demux contract. The selector changes no behavior. It chooses public
sample stem
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last`,
focused behavior label `mixed_dynamic_static_read_rlast_demux_multi_dynamic`,
dynamic read transactions `r0`/`r1`, static read transaction `r2` with ID
`3`, one-bit last signal `axi0_rlast`, report mode
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
raw `RID` beat ownership assertions independent of `RLAST`, final
`RID && RLAST` generated completions, and explicit read-data, raw `ARLEN`,
runtime-validation, and multi-beat residue.
`.347` now ships that generated behavior through the support-accounted public
sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif`.
Mixed dynamic/static read burst-last response-demux now accepts exactly two
dynamic read transactions plus one concrete static read transaction, emits
selected dynamic ID/busy state for `r0`/`r1`, static busy state for `r2`, keeps
raw `RID` active/unique response assertions independent of `RLAST`, and gates
the three generated completion pulses with final `RID && RLAST` matches.
Schedule JSON reports
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`,
`matched_dynamic_or_static_concrete_id_and_last_signal`,
`active_dynamic_ids_must_be_unique`, and static exclusion `4'd3`, while
read-data, raw `ARLEN`, runtime-validation, and multi-beat behavior over this
shape remain explicit residue.
`.348` now selects `.349`, public contract selection for scalar last-beat
read-data over the generated two-dynamic-plus-one-static mixed dynamic/static
read burst-last `RID`/`RLAST` response-demux. The audit changes no behavior. A
scratch guarded strict-check probe reached the read-data coverage gate and
failed closed with the current multiple mixed dynamic/static read-data
diagnostic, so the next selector must settle the public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data`,
behavior label `mixed_dynamic_static_read_data_multi_dynamic_last_beat`, scalar
output naming, completion-validity vocabulary, validation, rollback, and residue
before any parser, generator, PPIF sample, support-accounting, test, JSON, or
HDL behavior changes.
`.349` now selects `.350`, direct generated behavior for scalar last-beat
read-data over that generated two-dynamic-plus-one-static mixed dynamic/static
read burst-last `RID`/`RLAST` response-demux. The selector changes no behavior.
It fixes public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data`,
coverage key
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_pipeline_cli`,
behavior label `mixed_dynamic_static_read_data_multi_dynamic_last_beat`, scalar
last-beat output names, completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`,
and fail-closed residue for single-beat read-data over `.344`, raw `ARLEN`,
runtime validation, multi-beat output banks, broader cardinalities, and backend
variants.
`.350` now ships that selected scalar last-beat read-data behavior through the
support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif`.
The generated surface preserves the `.347`
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`, dynamic
transactions `r0`/`r1`, static transaction `r2`, final `RID && RLAST`
completion pulses, and static exclusion `4'd3`; it adds generated
`axi0_rdata`/`axi0_rresp` inputs, scalar
`axi0_r*_last_rdata`/`axi0_r*_last_rresp` outputs for `r0`/`r1`/`r2`, and
capture rules guarded only by the generated final-beat completion pulses.
Schedule/read-data JSON reports
`bounded_last_beat_read_data_contract`,
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`,
transactions `r0`, `r1`, `r2`, and generated rules
`axi0_r0_read_data_capture`, `axi0_r1_read_data_capture`, and
`axi0_r2_read_data_capture`. Raw `ARLEN`, runtime validation, multi-beat output
banks, single-beat read-data over `.344`, broader cardinalities, and backend
variants remain exact-owner residue; `.351` is the next selector for
report-only raw-`ARLEN` burst-length readiness over this boundary.
`.351` now selects `.352`, readiness audit for report-only raw-`ARLEN`
burst-length capture over that shipped two-dynamic-plus-one-static mixed
dynamic/static scalar last-beat read-data boundary. The selector changes no
behavior. The audit must decide whether the `.350` public sample should grow
the existing `burst-length` syntax directly, needs public contract selection
first, needs helper/report cleanup first, or should defer behind another
prerequisite while preserving runtime validation, multi-beat output banks,
broader cardinalities, direct backend behavior, backend-language variants, and
VHDL as separate owners.
`.352` now selects `.353`, direct implementation of report-only raw-`ARLEN`
burst-length capture over that generated two-dynamic-plus-one-static mixed
dynamic/static scalar last-beat read-data boundary. The audit changes no
behavior. Code review found the current coverage gate already admits the `.350`
shape only when `burst_length` is absent, while the raw-`ARLEN` normalization,
storage, rule, artifact, and report helpers are transaction-list driven once
coverage admits the transaction set. `.353` owns sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length`,
coverage key
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_pipeline_cli`,
behavior label `mixed_dynamic_static_read_data_multi_dynamic_burst_length`,
generated `axi0_arlen`, per-transaction raw-`ARLEN` storage/capture rules, and
report-only diagnostics while preserving runtime validation, multi-beat output
banks, broader cardinalities, and backend variants as future owners.
`.353` now ships that selected report-only raw-`ARLEN` burst-length behavior
through the support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length.ppif`.
The generated surface preserves the `.350` scalar last-beat read-data payload
capture and the `.347` generated mixed `RID && RLAST` completion pulses, adds
generated input `axi0_arlen`, raw-`ARLEN` storage
`axi0_r0_arlen_q`/`axi0_r1_arlen_q`/`axi0_r2_arlen_q`, and request-guarded
capture rules `axi0_r0_burst_length_capture`,
`axi0_r1_burst_length_capture`, and `axi0_r2_burst_length_capture`.
Schedule/read-data reports list the generated burst-length input, storage, and
rules with validation mode `report_only`; runtime beat-count/`RLAST`
validation, multi-beat output banks, broader cardinalities, direct backend
behavior, backend-language variants, and VHDL remain future exact owners.
`.353` advanced the frontier to `.354`, the readiness audit for runtime
validation over this shipped two-dynamic-plus-one-static raw-`ARLEN` boundary.
`.354` now selects `.355`, direct implementation of runtime
beat-count/`RLAST` validation over that generated two-dynamic-plus-one-static
mixed dynamic/static raw-`ARLEN` scalar last-beat read-data boundary. The audit
changes no behavior. Code review found the `.353` public shape already proves
ordered `r0`/`r1` dynamic read bindings plus static `r2`, raw-`ARLEN` capture,
and generated final-beat completion pulses; the existing runtime-validation
helpers are transaction-list driven for expected-beat storage, read-beat
counters, matched-read-beat increments, four assertions per transaction, and
report residue movement. `.355` owns the runtime sibling sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion`,
coverage key
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion_pipeline_cli`,
and behavior label
`mixed_dynamic_static_read_data_multi_dynamic_burst_length_runtime_assertion`,
while preserving two-dynamic-plus-one-static multi-beat output banks, broader
cardinalities, backend variants, and VHDL as future owners.
`.355` now ships that selected runtime beat-count/`RLAST` validation through
the support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion.ppif`.
The generated surface preserves `.353` raw-`ARLEN` capture, `.350` scalar
last-beat `RDATA`/`RRESP` capture, and `.347` final `RID && RLAST` completion
pulses, then adds expected-beat storage, read-beat counters, request-time
initialization from `ARLEN + 1`, matched-read-beat counter increments, and
four beat-count/`RLAST` assertions for each of `r0`, `r1`, and `r2`.
Schedule/read-data reports now name validation mode `runtime_assertion`,
`beat_count_validation_generated_behavior: true`,
`expected_beat_count_encoding: arlen_plus_one`, and
`beat_count_match_source: response_demux_matched_read_beat` for this exact
two-dynamic-plus-one-static scalar last-beat shape. Multi-beat output banks,
broader cardinalities, direct backend behavior, backend-language variants, and
VHDL remain future exact owners. `.355` advanced the frontier to `.356`, the
readiness audit for multi-beat output banks over this runtime boundary.
`.356` now selects `.357`, direct implementation of generated multi-beat
output banks over that two-dynamic-plus-one-static runtime-validation
boundary. The audit changes no behavior. It found the public multi-beat
syntax and output-bank report vocabulary already ship through the all-dynamic,
two-static mixed, and three-static mixed precedents; the remaining gap is
local to admitting the exact `r0`/`r1` dynamic plus `r2` static
`capture-scope multi-beat` branch and recognizing it for response-demux
residue cleanup. `.357` owns sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat`,
coverage key
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat_pipeline_cli`,
and behavior label
`mixed_dynamic_static_read_data_multi_dynamic_multi_beat`.
`.357` now ships that selected generated multi-beat output-bank behavior
through the support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat.ppif`.
The generated surface preserves `.355` runtime beat-count/`RLAST`
validation, `.353` raw-`ARLEN` capture, and `.347` generated final
`RID && RLAST` completion pulses, then emits per-transaction `RDATA`/`RRESP`
lane outputs, valid masks, read-length outputs, and worst-observed scalar
`RRESP` aggregates for `r0`, `r1`, and `r2`. Reports now identify the shape
as `bounded_multi_beat_read_data_contract`, list generated status aggregation
and multi-beat reassembly behavior, keep `read_data.residue` empty for this
sample, and leave only `same_id_ordering` in `response_demux.residue`.
Single-beat read-data over `.344`, broader mixed dynamic/static cardinalities,
same-cycle request widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, VHDL,
profile aliases, queued/blocking policy, and full-manager behavior remain
future exact owners. `.357` advanced the frontier to `.358`, the next IAL2
feature-completeness selector after this read-data chain reached multi-beat
output banks.
`.358` now selects `.359`, readiness audit for scalar single-beat read-data
over the `.344` generated two-dynamic-plus-one-static mixed dynamic/static
read single-beat `RID` response-demux. The selector changes no behavior. It
records candidate sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data`,
coverage key
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data_pipeline_cli`,
and behavior label `mixed_dynamic_static_read_data_multi_dynamic`.
`.359` now selects `.360`, public contract selection for that scalar
single-beat read-data shape. The audit changes no behavior. The selected
candidate surface keeps `.344` response-demux mode
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`, read-data mode
`bounded_single_beat_read_data_contract`, completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`,
and the candidate sample/support/coverage/behavior names selected by `.358`.
`.360` now selects `.361`, direct generated behavior for bounded scalar
single-beat read-data over the `.344` generated two-dynamic-plus-one-static
mixed dynamic/static read single-beat `RID` response-demux. The selector
changes no behavior. The selected public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif`,
with support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data`,
coverage key
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data_pipeline_cli`,
and behavior label `mixed_dynamic_static_read_data_multi_dynamic`. The
selected report contract keeps `.344` response-demux mode/source and
`bounded_single_beat_read_data_contract` with completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`.
`.361` now ships that scalar single-beat read-data behavior. The new public
sample is support-accounted and generates shared `axi0_rdata`/`axi0_rresp`
inputs, scalar data/status outputs for `r0`, `r1`, and `r2`, and capture
rules `axi0_r0_read_data_capture`, `axi0_r1_read_data_capture`, and
`axi0_r2_read_data_capture` guarded by the generated single-beat completion
pulses. Reports keep `.344` response-demux mode/source, set read-data mode to
`bounded_single_beat_read_data_contract`, use completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`,
and leave read-data residue `rlast_completion`, `bursts`, and
`multi_beat_read_data_reassembly`.
`.362` now selects `.363`, readiness audit for same-cycle request/response
and release-and-recapture behavior across the generated dynamic and mixed
dynamic/static response-demux/read-data shapes. The selector changes no
behavior. The current generated dynamic/mixed shapes still report onehot0
same-cycle request policy, active dynamic selected-ID uniqueness, request
no-active-same-ID checks, and static busy state; `.363` must decide whether a
request plus generated completion, dynamic release-and-recapture, or static
release-and-recapture can be widened directly or needs a smaller prerequisite.
`.363` now selects `.364`, public contract selection for the first
single-active dynamic write `BID` same-cycle release-and-recapture boundary.
The audit found capacity admission already accounts for same-cycle completion
fan-in, but response-demux state capture still requires `!busy` and release
uses a separate generated completion rule. The first behavior owner should
therefore define single-slot dynamic write recapture before widening mixed
static recapture, sibling request onehot0 policy, read `RID`/`RLAST`, read-data
payload capture, queues, scoreboards, direct backend behavior, or VHDL.
`.365` now ships direct generated behavior for single-active dynamic write
`BID` same-cycle release-and-recapture. The public contract reuses
`ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif` without new
source syntax, preserves `bounded_dynamic_write_bid_demux_contract`, adds
`same_cycle_release_recapture_policy` report vocabulary, emits
`axi0_w0_dynamic_id_release_recapture`, changes release-only to exclude a
same-cycle request, and replaces the request-not-busy assertion with
`axi0_w0_dynamic_request_idle_or_releasing`. A same-cycle request plus generated
matching completion now pulses completion, captures the new `AWID`, and leaves
busy asserted while the response match still uses the pre-update selected ID.
That behavior advanced the frontier to `.366`, the next selector for
same-cycle and release-recapture residue after the single-active dynamic write
boundary.
`.366` now selects `.367`, public contract selection for first single-active
dynamic read same-cycle release-and-recapture. The selector changes no
behavior. Single-active dynamic read is the closest symmetric sibling after
the write recapture slice because the current `RID` and `RID && RLAST` paths
share selected-ID/busy ownership with the dynamic write path but still report
request-not-busy. The next contract owner must decide whether the first
behavior slice covers single-beat `RID`, burst-last `RID && RLAST`, or a split
scope, and must preserve existing dynamic read-data completion-pulse consumers
before any generator update.
`.367` now selects `.368`, direct generated behavior for single-active dynamic
read single-beat `RID` same-cycle release-and-recapture. The selector changes
no behavior. The selected contract reuses the existing
`ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif` sample and
source syntax, keeps `bounded_dynamic_read_rid_demux_contract`, adds read-side
`same_cycle_release_recapture_policy` report vocabulary, and replaces the
single-active dynamic read request-not-busy assertion role with
idle-or-releasing semantics. Burst-last `RID && RLAST`, scalar last-beat
read-data, burst-length/runtime/multi-beat recapture, multiple dynamic,
mixed dynamic/static, static busy, queue, scoreboard, backend, VHDL, and
full-manager behavior remain later owners.
`.368` now ships generated single-active dynamic read single-beat `RID`
same-cycle release-and-recapture. FSMGen emits
`axi0_r0_dynamic_id_release_recapture`, keeps release-only disjoint from
same-cycle requests, reports `same_cycle_release_recapture_policy:
single_active_dynamic_read`, replaces `axi0_r0_dynamic_request_not_busy` with
`axi0_r0_dynamic_request_idle_or_releasing`, and preserves scalar single-beat
dynamic read-data payload capture under the existing generated completion
pulse. Burst-last `RID && RLAST`, scalar last-beat read-data,
burst-length/runtime/multi-beat recapture, multiple dynamic, mixed
dynamic/static, static busy, queue, scoreboard, backend, VHDL, and
full-manager behavior remain later owners.
`.369` now selects `.370`, readiness audit for single-active dynamic read
burst-last `RID && RLAST` same-cycle release-and-recapture. The selector
changes no behavior. It chooses audit before direct implementation because the
burst-last boundary touches final-beat completion, matched non-last beats,
raw active-match assertions, scalar last-beat read-data, report-only
raw-`ARLEN`, runtime beat-count/`RLAST`, and multi-beat output-bank consumers.
Multiple dynamic request widening, mixed dynamic/static recapture, static busy
recapture, same-ID queues, scoreboards, backend variants, VHDL, and
full-manager behavior remain later owners.
`.370` now selects `.371`, public contract selection for single-active dynamic
read burst-last `RID && RLAST` same-cycle release-and-recapture. The audit
changes no behavior and found no lower cleanup prerequisite, but contract
selection must precede implementation because final-completion-only recapture,
matched non-last beats, raw active-match assertions, scalar last-beat
read-data preservation, raw-`ARLEN`/runtime/multi-beat consumer boundaries,
report vocabulary, and assertion semantics need exact public ownership before
generator behavior changes.
`.371` now selects `.372`, direct generated behavior for single-active dynamic
read burst-last `RID && RLAST` same-cycle release-and-recapture. The selector
changes no behavior. The selected contract reuses the existing burst-last
dynamic read response-demux source syntax and support identity, preserves
`bounded_dynamic_read_rid_rlast_demux_contract`, reports
`release_recapture_source: generated_dynamic_demux_last_beat_completion`,
replaces the single-active burst-last request-not-busy assertion with
idle-or-releasing semantics, preserves raw matched non-last beats and raw
active-match assertions, and treats scalar last-beat read-data, raw-`ARLEN`,
runtime beat-count/`RLAST`, and multi-beat output banks as payload/validation
preservation consumers.
`.372` now ships generated single-active dynamic read burst-last `RID && RLAST`
same-cycle release-and-recapture under the existing public sample/source
syntax. FSMGen emits `axi0_r0_dynamic_id_release_recapture`, keeps release-only
disjoint from same-cycle requests, reports
`release_recapture_source: generated_dynamic_demux_last_beat_completion`,
replaces the burst-last single-active request-not-busy assertion with
`axi0_r0_dynamic_request_idle_or_releasing`, preserves raw matched non-last
beats and raw active-match assertions, and keeps scalar last-beat read-data,
raw-`ARLEN`, runtime beat-count/`RLAST`, and multi-beat output-bank
payload/validation contracts intact. The frontier advances to `.373`, the next
same-cycle/release-recapture selector.
`.373` now selects `.374`, readiness audit for multiple all-dynamic
same-cycle release-and-recapture. The selector changes no behavior. Multiple
all-dynamic response-demux is the nearest broader recapture residue because it
still uses dynamic selected-ID/busy ownership, but it adds sibling onehot0
request policy, active dynamic selected-ID uniqueness, request
no-active-same-ID checks, unique-match assertions, and burst-last raw
non-final-beat handling. Mixed dynamic/static recapture, static busy recapture,
queues, scoreboards, backend variants, VHDL, and full-manager behavior remain
later owners.
`.374` now selects `.375`, generated support-detail prose alignment for the
shipped single-active dynamic read burst-last release-and-recapture behavior
before selecting any multiple-dynamic recapture contract. The audit changes no
behavior. Guarded probes confirmed the multiple dynamic write/read/read-RLAST
samples still report onehot0 request policy, active dynamic selected-ID
uniqueness, request no-active-same-ID checks, response unique-match assertions,
request-not-busy assertions, and no release-recapture fields. The same probes
exposed stale generated support prose saying the single-active dynamic read
burst-last `RID/RLAST` shape is supported without release-and-recapture and
listing same-cycle recapture as future outside only dynamic write plus read
single-beat.
`.375` now aligns that generated support-detail prose with the shipped
single-active dynamic read burst-last release-and-recapture behavior. The
generated dynamic transaction-ID support detail describes single-active dynamic
read single-beat `RID` matching and burst-last `RID/RLAST` matching as
including same-cycle release-and-recapture. At `.375`, same-cycle recapture
remained future only outside the selected single-active dynamic write `BID`,
read single-beat `RID`, and read burst-last `RID/RLAST` demux boundaries.
Parser syntax, PPIF samples, response-demux semantics, generated state/rules,
assertions, HDL, and runtime behavior are unchanged. The frontier advances to
`.376`, selection of the first multiple all-dynamic recapture contract owner.
`.376` now selects `.377`, public contract selection for multiple all-dynamic
write `BID` same-cycle release-and-recapture. The selector changes no
behavior. It starts on the write side because that shape exercises
multi-active dynamic selected-ID/busy ownership, onehot0 request policy,
active-ID uniqueness, request no-active-same-ID checks, response active-match,
response unique-match, and completion-active assertions without read-side
`RLAST`, raw non-final-beat, read-data, raw-`ARLEN`, runtime, or multi-beat
preservation coupling. That selector deliberately left read-side, mixed/static,
static busy, queue, scoreboard, backend-variant, VHDL, and full-manager
recapture behavior to later exact owners.
`.377` now selects `.378`, direct implementation of multiple all-dynamic write
`BID` same-cycle release-and-recapture for the existing
`ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif`
sample. The contract preserves public syntax, support accounting,
`bounded_multi_dynamic_write_bid_demux_contract`, and onehot0 request policy;
adds per-transaction `release_recapture_rule`,
`same_cycle_release_recapture_policy: multi_active_unique_dynamic_write`,
`release_recapture_source: generated_dynamic_demux_completion`, and
`release_recapture_transaction` report fields; replaces per-transaction
request-not-busy assertions with idle-or-releasing assertions; and preserves
no-active-same-ID, active-ID uniqueness, response active/unique-match, and
completion-active assertions. The selector changes no behavior.
`.378` now ships that multiple all-dynamic write `BID` same-cycle
release-and-recapture behavior. FSMGen emits per-transaction
`axi0_w0_dynamic_id_release_recapture` and
`axi0_w1_dynamic_id_release_recapture` rules under the existing
`ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif`
sample, keeps release-only updates disjoint from same-cycle own requests,
reports `same_cycle_release_recapture_policy:
multi_active_unique_dynamic_write`, replaces per-transaction request-not-busy
assertions with `axi0_w0_dynamic_request_idle_or_releasing` and
`axi0_w1_dynamic_request_idle_or_releasing`, and preserves onehot0 sibling
request policy, no-active-same-ID, active-ID uniqueness, response
active/unique-match, completion-active assertions, source syntax, support
identity, generated completion names, and
`bounded_multi_dynamic_write_bid_demux_contract`. `.379` now selects `.380`,
public contract selection for multiple all-dynamic read single-beat `RID`
same-cycle release-and-recapture. The selector changes no behavior. It chooses
single-beat read before burst-last because the single-beat shape shares the
multi-active selected-ID/busy lifecycle, onehot0 request policy, active-ID
uniqueness, request no-active-same-ID, response active/unique-match, and
completion-active assertion structure without `RLAST` final-beat coupling.
The `.380` contract selection must preserve the existing
`bounded_multi_dynamic_read_rid_demux_contract`, support identity, generated
completion pulses, scalar single-beat read-data consumer, and deferred
burst-last/read-data/runtime/multi-beat boundaries before implementation.
`.380` now selects `.381`, direct implementation of multiple all-dynamic read
single-beat `RID` same-cycle release-and-recapture for the existing
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif`
sample. The selector changes no behavior. The selected implementation must
preserve public syntax, support identity,
`bounded_multi_dynamic_read_rid_demux_contract`, generated demux rules,
generated completions, onehot0 request policy, no-active-same-ID, active-ID
uniqueness, response active/unique-match, completion-active assertions, and
scalar single-beat read-data capture over generated completion pulses while
adding per-transaction `multi_active_unique_dynamic_read` release-recapture
report fields and idle-or-releasing request assertions. At that point,
multiple dynamic read burst-last recapture still required a later exact owner;
that burst-last work later shipped in `.385`, and mixed dynamic/static
recapture advanced through `.386`-`.388` to `.389` mixed write implementation.
Static busy-only recapture outside that selected mixed write
boundary, request arbitration beyond onehot0, queues, scoreboards, backend
variants, VHDL, and full-manager behavior remain later exact owners.
`.381` now ships that same-cycle release-and-recapture behavior for
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif`.
FSMGen emits `axi0_r0_dynamic_id_release_recapture` and
`axi0_r1_dynamic_id_release_recapture`, reports
`same_cycle_release_recapture_policy: multi_active_unique_dynamic_read` under
`response_demux.read.dynamic_capture.transactions[]`, replaces the two
per-transaction request-not-busy assertions with
`axi0_r0_dynamic_request_idle_or_releasing` and
`axi0_r1_dynamic_request_idle_or_releasing`, and preserves
`bounded_multi_dynamic_read_rid_demux_contract`, onehot0 request policy,
no-active-same-ID, active-ID uniqueness, raw response active/unique-match,
completion-active assertions, generated completion names, support identity,
and scalar single-beat read-data capture over generated completions. Multiple
dynamic read burst-last recapture then advanced through `.382`-`.385`; mixed
dynamic/static recapture advanced through `.386`-`.388` to `.389` mixed write
implementation. Static busy-only recapture outside that selected mixed
write boundary, request arbitration beyond onehot0, queues, scoreboards,
backend variants, VHDL, and full-manager behavior remain later exact owners.
`.382` selects `.383`, readiness audit for multiple all-dynamic read
burst-last `RID && RLAST` same-cycle release-and-recapture. The selector
changes no behavior. The audit comes before public contract or implementation
because the burst-last path must preserve final `RID && RLAST` completion,
non-final raw read beats, scalar last-beat read-data, raw-`ARLEN`, runtime
beat-count/`RLAST`, and multi-beat output-bank consumers.
`.383` selects `.384`, public contract selection for that multiple
all-dynamic read burst-last recapture boundary. The audit changes no behavior.
The implementation substrate is close, but the contract must first pin the
last-beat release-recapture source, idle-or-releasing assertion semantics,
release-only and release-recapture guards, raw non-final beat preservation,
scalar last-beat read-data, raw-`ARLEN`, runtime beat-count/`RLAST`, and
multi-beat output-bank preservation.
`.384` selects `.385`, direct implementation of the selected multiple
all-dynamic read burst-last `RID && RLAST` recapture contract. The selector
changes no behavior. The implementation must preserve the existing
`bounded_multi_dynamic_read_rid_rlast_demux_contract`, add per-transaction
`multi_active_unique_dynamic_read` report fields with
`release_recapture_source: generated_dynamic_demux_last_beat_completion`, and
replace the selected request-not-busy assertions with idle-or-releasing
assertions while preserving raw non-final beats and the layered read-data,
raw-`ARLEN`, runtime, and multi-beat consumers.
`.385` now ships that behavior for
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif`.
FSMGen emits `axi0_r0_dynamic_id_release_recapture` and
`axi0_r1_dynamic_id_release_recapture`, keeps release-only updates disjoint
from same-transaction same-cycle requests, reports
`same_cycle_release_recapture_policy: multi_active_unique_dynamic_read` with
`release_recapture_source: generated_dynamic_demux_last_beat_completion` under
`response_demux.read.dynamic_capture.transactions[]`, and replaces the two
request-not-busy assertions with
`axi0_r0_dynamic_request_idle_or_releasing` and
`axi0_r1_dynamic_request_idle_or_releasing`. Raw non-final beats remain
matched read beats only, and scalar last-beat read-data, raw-`ARLEN`, runtime
beat-count/`RLAST`, and multi-beat output-bank consumers remain preserved.
`.386` selects `.387`, readiness audit for mixed dynamic/static same-cycle
release-and-recapture. The selector changes no behavior. The audit comes next
because all selected all-dynamic recapture siblings are now covered, while the
mixed boundary must still pin static busy recapture semantics,
dynamic/static concrete-ID reservation, onehot0 sibling policy, assertion
changes, read `RID && RLAST` and raw non-final beat preservation, and layered
read-data/raw-`ARLEN`/runtime/multi-beat implications before behavior changes.
`.387` selects `.388`, public contract selection for mixed dynamic/static
write `BID` same-cycle release-and-recapture. The audit changes no behavior.
Guarded baseline schedule probes for the one-dynamic/one-static mixed write,
read single-beat, and read burst-last public samples passed and confirmed the
current reports still use request-not-busy assertions with no
release-recapture metadata. Mixed write is the next owner because it exercises
both dynamic selected-ID recapture and static concrete busy recapture without
the read `RID`/`RLAST`, read-data, raw-`ARLEN`, runtime validation, and
multi-beat output-bank preservation stack.
`.388` selects `.389`, direct implementation of mixed dynamic/static write
`BID` same-cycle release-and-recapture for the existing support-accounted
public sample. The selector changes no behavior. It preserves public syntax,
`bounded_mixed_dynamic_static_write_bid_demux_contract`, generated mixed
completion source, onehot0 mixed request policy, static-ID reservation,
response active/unique-match, and completion-active assertions while selecting
dynamic recapture report fields, a new `static_capture` report block,
dynamic/static release-only exclusion, dynamic/static release-recapture guards,
and dynamic/static idle-or-releasing request assertions.
`.389` now ships that behavior. FSMGen emits
`axi0_w0_dynamic_id_release_recapture` and
`axi0_w1_static_busy_release_recapture`, keeps release-only rules disjoint from
same-transaction same-cycle requests, reports
`mixed_dynamic_static_dynamic_write` under
`response_demux.write.dynamic_capture` and
`mixed_dynamic_static_static_write` under
`response_demux.write.static_capture`, and replaces the selected
request-not-busy assertions with
`axi0_w0_dynamic_request_idle_or_releasing` and
`axi0_w1_static_request_idle_or_releasing`. Public syntax, support identity,
the mixed write mode, static-ID reservation, onehot0 request policy, response
active/unique-match, and completion-active assertions are preserved.
`.390` selects `.391`, public contract selection for mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture. The selector changes no
behavior. Guarded baseline schedule probes for the mixed read single-beat and
burst-last public samples passed below the 88% host-memory cutoff and
confirmed the post-`.389` read reports still use request-not-busy assertions
with no read-side release-recapture metadata or `static_capture` block.
Single-beat read is next so `.391` can adapt the `.389` dynamic/static
recapture vocabulary to `response_demux.read` while preserving
`bounded_mixed_dynamic_static_read_rid_demux_contract`,
`response_scope: single_beat`, and `generated_mixed_dynamic_static_read_demux`
before burst-last, read-data, raw-`ARLEN`, runtime-validation, and multi-beat
preservation layers are widened.
`.391` selects `.392`, direct implementation of mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture for the existing
support-accounted public sample. The selector changes no behavior. It
preserves public syntax, `bounded_mixed_dynamic_static_read_rid_demux_contract`,
`response_scope: single_beat`, generated mixed read completion source,
static-ID reservation, onehot0 mixed request policy, response
active/unique-match, and completion-active assertions while selecting
`response_demux.read.dynamic_capture` recapture fields, a new
`response_demux.read.static_capture` report block, dynamic/static release-only
exclusion, dynamic/static release-recapture guards, and dynamic/static
idle-or-releasing request assertions.
`.392` now ships that behavior. FSMGen emits
`axi0_r0_dynamic_id_release_recapture` and
`axi0_r1_static_busy_release_recapture`, keeps release-only rules disjoint from
same-transaction same-cycle requests, reports
`mixed_dynamic_static_dynamic_read` under
`response_demux.read.dynamic_capture` and
`mixed_dynamic_static_static_read` under
`response_demux.read.static_capture`, and replaces the selected
request-not-busy assertions with
`axi0_r0_dynamic_request_idle_or_releasing` and
`axi0_r1_static_request_idle_or_releasing`. Public syntax, support identity,
the mixed read single-beat mode/scope/source, static-ID reservation, onehot0
request policy, response active/unique-match, and completion-active assertions
are preserved. The mixed read burst-last `RID && RLAST` sample remains
unchanged with no recapture metadata or `static_capture` report block.
`.393` selects `.394`, readiness audit for mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture. The selector
changes no behavior. Burst-last is the nearest sibling after `.392`, but it
needs audit before contract selection because final-only release and recapture
must preserve raw non-final `RID` beats, raw active/unique-match assertions,
scalar last-beat read-data, raw `ARLEN`, runtime beat-count/`RLAST`
validation, and multi-beat output-bank consumers.
`.394` selects `.395`, public contract selection for mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture. The audit changes
no behavior. A guarded baseline schedule probe confirmed the existing
`bounded_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`, `last_signal: axi0_rlast`, last-beat completion
source, request-not-busy assertions, no recapture metadata, and no
`static_capture` block. Contract selection is next so last-beat report source,
dynamic/static recapture fields, idle-or-releasing assertions, raw non-final
`RID` preservation, and read-data/raw-`ARLEN`/runtime/multi-beat consumers are
pinned before implementation.
`.395` selects `.396`, direct implementation of mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture for the existing
public sample. The selector changes no behavior. The selected contract
preserves the burst-last mode/scope, `last_signal`, last-beat transaction
completion source, raw non-final `RID` assertions, and layered read-data/
raw-`ARLEN`/runtime/multi-beat consumers. It reuses
`mixed_dynamic_static_dynamic_read` and `mixed_dynamic_static_static_read`
policy names, with
`generated_mixed_dynamic_static_read_demux_last_beat_completion` as the
release-recapture source.
`.396` now ships that behavior for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif`.
FSMGen emits `axi0_r0_dynamic_id_release_recapture` and
`axi0_r1_static_busy_release_recapture`, keeps release-only rules disjoint
from same-transaction same-cycle requests, drives both recapture paths from
generated final `RID && RLAST` completion pulses, reports the last-beat
release-recapture source under `response_demux.read.dynamic_capture` and
`response_demux.read.static_capture`, and replaces the selected
request-not-busy assertions with `axi0_r0_dynamic_request_idle_or_releasing`
and `axi0_r1_static_request_idle_or_releasing`. Public syntax, support
identity, the burst-last mode/scope/source, raw non-final `RID` assertions,
and the scalar read-data/raw-`ARLEN`/runtime/multi-beat consumers are
preserved.
`.397` selects `.398`, readiness audit for broader mixed dynamic/static
same-cycle release-and-recapture. The selector changes no behavior. Broader
mixed recapture is the next nearest residue because the one-dynamic plus
one-static mixed write/read/read-`RLAST` recapture family is now covered,
while existing multi-static, three-static, and two-dynamic-plus-one-static
public samples add sibling static busy recapture, static-ID exclusion lists,
active dynamic-ID uniqueness, and read burst-last raw non-final beat
preservation that need audit ownership before any contract or implementation
slice. The `.396` RAM-guard cutoff is recorded, but validation retry is not
the next exact owner.
`.398` selects `.399`, public contract selection for one-dynamic plus
two-static mixed dynamic/static write `BID` same-cycle release-and-recapture.
The audit changes no behavior. Guarded baseline probes confirmed the
two-static, three-static, and two-dynamic-plus-one-static write samples still
report no `static_capture` recapture block; the two-static write sample is the
smallest broader owner because it adds sibling static busy recapture and
multiple static-ID exclusions without adding read `RLAST`/read-data
preservation or two-dynamic active-ID uniqueness.
`.399` selects `.400`, direct implementation of one-dynamic plus two-static
mixed dynamic/static write `BID` same-cycle release-and-recapture. The
selector changes no behavior. `.400` now ships that behavior for the existing
multi-static public sample: dynamic `w0` and static `w1`/`w2`
release-recapture rules, list-shaped dynamic/static recapture report
metadata, release-only guards disjoint from same-transaction same-cycle
requests, and idle-or-releasing request assertions for `w0`, `w1`, and `w2`.
Public syntax, support identity, mode/source/semantics, transaction lists,
static-ID reservations, response-demux matches, generated completions,
onehot0/static-ID-exclusion/active-match/pairwise-unique-match/
completion-active assertions, one-static singular recapture shape, and
three-static no-recapture shape are preserved. `.401` selects the next exact
post two-static mixed write recapture activity before any broader behavior
change.
`.401` now selects `.402`, public contract selection for one-dynamic plus
three-static mixed dynamic/static write `BID` same-cycle release-and-recapture
under the existing three-static public sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif`.
The selector changes no behavior. Three-static write recapture is the smallest
post-`.400` behavior direction because it stays write-only and one-dynamic
while adding only one more concrete static sibling. Two-dynamic recapture
remains deferred behind active dynamic-ID uniqueness and no-active-same-ID
checks; broader mixed read recapture remains deferred behind `RID`/`RLAST`,
read-data, raw-`ARLEN`, runtime, and multi-beat preservation.
`.402` selects `.403`, direct implementation of one-dynamic plus three-static
mixed dynamic/static write `BID` same-cycle release-and-recapture for the
existing three-static public sample. The selector changes no behavior. The
selected contract preserves public syntax, support identity,
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract`,
`generated_multi_mixed_dynamic_static_demux`,
`matched_dynamic_or_static_concrete_id`, transaction lists, static-ID
reservations for `4'd3`/`4'd5`/`4'd7`, generated demux rules/completions, and
onehot0/static-ID-exclusion/active-match/pairwise-unique-match/
completion-active assertions. It selects dynamic recapture fields under
`dynamic_capture.transactions[0]`, list-shaped `static_capture[]` entries for
`w1`/`w2`/`w3`, disjoint release-only and release-recapture guards for all
four transactions, and idle-or-releasing assertion names for `w0`/`w1`/`w2`/
`w3`.
`.403` now ships one-dynamic plus three-static mixed dynamic/static write
`BID` same-cycle release-and-recapture for the existing three-static public
sample. FSMGen emits `axi0_w0_dynamic_id_release_recapture`,
`axi0_w1_static_busy_release_recapture`,
`axi0_w2_static_busy_release_recapture`, and
`axi0_w3_static_busy_release_recapture`, reports dynamic recapture under
`dynamic_capture.transactions[0]`, reports concrete static recapture under
list-shaped `static_capture[]`, makes release-only rules disjoint from
same-transaction same-cycle requests, and replaces `w0`/`w1`/`w2`/`w3`
request-not-busy assertions with idle-or-releasing assertions. Public syntax,
support identity, mode/source/semantics, transaction lists, static-ID
reservations, generated demux/completion behavior, onehot0/
static-ID-exclusion/active-match/pairwise-unique-match/completion-active assertions,
the one-static singular recapture shape, the two-static recapture shape, and
the two-dynamic-plus-one-static no-recapture shape are preserved. `.404`
selects the next post three-static mixed write recapture activity.
`.404` now selects `.405`, readiness audit for two-dynamic-plus-one-static
mixed dynamic/static write `BID` same-cycle release-and-recapture under the
existing `ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`
sample. The selector changes no behavior. This is the nearest post-`.403`
residue because it stays write-only, but it needs an audit before contract
selection: the current mixed write recapture marker is capped at one dynamic
transaction, while the candidate composes two active dynamic selected-ID
owners, one concrete static owner, active dynamic-ID uniqueness,
no-active-same-ID checks, static-ID exclusions, list-shaped dynamic recapture
entries, and `static_capture`. Broader mixed read recapture remains deferred
behind raw non-final `RID`, `RLAST`, read-data, raw-`ARLEN`, runtime, and
multi-beat preservation.
`.405` now selects `.406`, public contract selection for the same
two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle
release-and-recapture boundary. The audit changes no behavior. It found no
smaller parser/source/support-accounting/report/assertion substrate
prerequisite: the existing state builder already computes sibling dynamic
request blocks, active sibling same-ID blocks, static request blocks,
static-ID exclusions, static dynamic-request blocks, idle-or-releasing names,
no-active-same-ID assertions, active dynamic-ID uniqueness, response
active-match, unique-match, and completion-active surfaces. Contract
selection is still required before implementation because the current mixed
write recapture marker is capped at one dynamic transaction and the dynamic
recapture helper currently chooses either multi-active dynamic guards or mixed
static guards. A guarded candidate schedule probe stopped before usable
output at host memory 89.5% against the default 88% cutoff; no cutoff was
raised. Broader mixed read recapture remains deferred behind raw non-final
`RID`, `RLAST`, read-data, raw-`ARLEN`, runtime, and multi-beat preservation.
`.406` now selects `.407`, direct implementation of two-dynamic-plus-one-static
mixed dynamic/static write `BID` same-cycle release-and-recapture for the
existing
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`
sample. The selector changes no behavior. The contract preserves public
syntax, support identity, the multi-mixed write mode/source/semantics,
transaction lists, static ID `4'd3`, generated demux/completion behavior, and
onehot0/no-active-same-ID/active dynamic-ID uniqueness/static-ID-exclusion/
active-match/unique-match/completion-active assertions. It selects dynamic
recapture fields for both `dynamic_capture.transactions[]` entries, new
dynamic policy `mixed_dynamic_static_multi_active_dynamic_write`,
`release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion`,
list-shaped
`static_capture[]` for `w2`, combined dynamic guards across sibling dynamic
request, active sibling same-ID, static request, and static-ID exclusion
blocks, static recapture guarded against both dynamic requests, release-only
exclusion of same-transaction requests, and idle-or-releasing assertions for
`w0`/`w1`/`w2`. Broader mixed read recapture remains deferred behind raw
non-final `RID`, `RLAST`, read-data, raw-`ARLEN`, runtime, and multi-beat
preservation.
`.407` now ships two-dynamic-plus-one-static mixed dynamic/static write `BID`
same-cycle release-and-recapture for the existing
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`
sample. FSMGen emits `axi0_w0_dynamic_id_release_recapture`,
`axi0_w1_dynamic_id_release_recapture`, and
`axi0_w2_static_busy_release_recapture`, reports
`mixed_dynamic_static_multi_active_dynamic_write` for both dynamic capture
transaction entries, reports list-shaped `static_capture[]` for `w2`, keeps
release-only rules disjoint from same-transaction requests, composes dynamic
guards across sibling dynamic request, active sibling same-ID, static request,
and static-ID exclusion blocks, guards static recapture against both dynamic
requests, and replaces `w0`/`w1`/`w2` request-not-busy assertions with
idle-or-releasing assertions. Syntax checks passed. Guarded selected schedule
JSON and focused t/1438 probes stopped before usable output at host memory
94.5% and 92.5% against the default 88% cutoff; no cutoff was raised. `.408`
now selects `.409`, readiness audit for one-dynamic-plus-two-static mixed
dynamic/static read single-beat `RID` same-cycle release-and-recapture. The
selector changes no behavior. It chooses the read single-beat one-dynamic plus
two-static sample because broader mixed write recapture is now covered, while
read burst-last recapture adds raw non-final `RID`, final `RLAST`, read-data,
raw-`ARLEN`, runtime, and multi-beat preservation, and two-dynamic read
recapture adds active dynamic-ID uniqueness and no-active-same-ID guards. A
guarded candidate schedule probe stopped before usable output at host memory
92.0% against the default 88% cutoff; output was 0 bytes and no cutoff was
raised.
`.409` now selects `.410`, public contract selection for
one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture. The audit changes no behavior. A guarded
baseline schedule probe for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif`
completed at host memory 79.6% against the default 88% cutoff and produced a
44021-byte schedule report. The live report still has request-not-busy
assertions for `r0`/`r1`/`r2`, no `static_capture`, and no
release-recapture fields under `dynamic_capture.transactions[]`. No smaller
parser/source/support-accounting/report-substrate or lower IAL prerequisite
was found before contract selection; direct behavior remains deferred until
list-shaped static read recapture, dynamic guard composition,
idle-or-releasing assertion names, and scalar read-data preservation are
contract-owned.
`.410` now selects `.411`, direct implementation of one-dynamic-plus-two-static
mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture
for the existing support-accounted public sample. The selector changes no
behavior. A guarded baseline schedule probe completed at host memory 83.5%
against the default 88% cutoff and produced a 44021-byte report. The selected
contract preserves the public syntax, support identity, multi-mixed read
single-beat mode, generated completion source, response semantics,
dynamic/static/mixed transaction lists, static ID reservations, generated
demux rules/completions, onehot0/static-ID-exclusion/active-match/
unique-match/completion-active assertions, and scalar single-beat read-data
consumers. It selects dynamic recapture fields for
`dynamic_capture.transactions[0]`, list-shaped `static_capture[]` entries for
`r1`/`r2`, `mixed_dynamic_static_dynamic_read`,
`mixed_dynamic_static_static_read`,
`generated_multi_mixed_dynamic_static_read_demux_completion`,
idle-or-releasing assertions for `r0`/`r1`/`r2`, dynamic guards across both
static requests and static-ID exclusions, static guards across dynamic request
and sibling static request, and same-transaction request exclusion on
release-only rules.
`.411` now ships one-dynamic-plus-two-static mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture for the existing public
sample. FSMGen emits `axi0_r0_dynamic_id_release_recapture`,
`axi0_r1_static_busy_release_recapture`, and
`axi0_r2_static_busy_release_recapture`; reports
`mixed_dynamic_static_dynamic_read` under
`dynamic_capture.transactions[0]`; reports list-shaped `static_capture[]` for
`r1`/`r2`; uses
`generated_multi_mixed_dynamic_static_read_demux_completion`; keeps
release-only rules disjoint from same-transaction requests; composes dynamic
guards across both static requests and both static-ID exclusions; composes
static guards across dynamic request and sibling static request; and replaces
`r0`/`r1`/`r2` request-not-busy assertions with idle-or-releasing assertions.
The singular mixed read recapture shape, the three-static no-recapture
boundary, and scalar single-beat read-data consumers remain preserved.
Guarded selected schedule, strict check, semantic JSON, SystemVerilog, and
verify-hdl probes passed; guarded focused `t/1438` stopped at the RAM cutoff
before TAP output. `.412` now selects the next post-read-recapture activity.
`.412` now selects `.413`, readiness audit for one-dynamic-plus-two-static
mixed dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture. The selector changes no behavior. A guarded baseline
schedule probe for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif`
started at host memory 85.2% against the default 88% cutoff and produced a
44340-byte report. The live burst-last report still uses
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`,
request-not-busy assertions for `r0`/`r1`/`r2`, no `static_capture`, and no
release-recapture fields under `dynamic_capture.transactions[]`. The next
audit must pin final-beat release-recapture source, raw non-final `RID`
preservation, list-shaped `static_capture[]`, idle-or-releasing assertion
renames, and scalar read-data/raw-`ARLEN`/runtime/multi-beat preservation
before implementation.
`.413` now selects `.414`, public contract selection for
one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture. The audit changes no behavior. A
guarded baseline schedule probe for the same public burst-last sample started
at host memory 86.3% against the default 88% cutoff and produced a 44340-byte
report showing request-not-busy assertions, no `static_capture`, and no
release-recapture fields. No lower parser, PPIF syntax, support-accounting,
IAL1/HDL lowering, or report-schema prerequisite was found. The next contract
selection must pin
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
`dynamic_capture.transactions[0]`, list-shaped `static_capture[]`, raw
non-final `RID` preservation, and scalar read-data/raw-`ARLEN`/runtime/
multi-beat preservation before implementation.
`.414` now selects `.415`, direct implementation of that
one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture contract. The selector changes no
behavior. The selected contract preserves public syntax, support identity,
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`, `last_signal: axi0_rlast`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, final-beat
completion semantics, `r0`/`r1`/`r2` transaction lists, static ID
reservations for `4'd3` and `4'd5`, generated demux/completion behavior, raw
`RID` assertions, completion-active assertions, and scalar read-data/
raw-`ARLEN`/runtime/multi-beat consumers. It selects
`dynamic_capture.transactions[0]`, list-shaped `static_capture[]`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
mixed read policy names, dynamic/static guard composition, release-only
same-transaction request exclusions, and idle-or-releasing assertion names
for the implementation owner.
`.415` now ships that one-dynamic-plus-two-static mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture behavior for the
existing support-accounted public sample. FSMGen reports
`axi0_r0_dynamic_id_release_recapture` under
`dynamic_capture.transactions[0]`, list-shaped
`axi0_r1_static_busy_release_recapture` and
`axi0_r2_static_busy_release_recapture` entries under `static_capture[]`,
final-beat source
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`, and
idle-or-releasing assertions for `r0`/`r1`/`r2`. Public syntax, support
identity, burst-last mode/source/semantics, generated demux/completion
behavior, raw `RID` active/unique-match assertions, completion-active
assertions, the one-static RLAST recapture shape, the three-static
no-recapture shape, the two-dynamic-plus-one-static no-recapture shape, and
scalar read-data/raw-`ARLEN`/runtime/multi-beat consumers remain preserved.
Guarded selected schedule JSON passed and produced a 46549-byte report;
focused `t/1438`, strict check JSON, semantic JSON, SystemVerilog generation,
and `--verify-hdl` probes stopped at the default 88% RAM guard cutoff before
completion, with no cutoff raised. `.416` now selects the next post
two-static mixed read burst-last recapture slice.
`.416` now selects `.417`, readiness audit for one-dynamic-plus-three-static
mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture.
The selector changes no behavior. A guarded baseline schedule probe for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`
started at host memory 87.3% against the default 88% cutoff and produced a
46985-byte report showing `bounded_multi_mixed_dynamic_static_read_rid_demux_contract`,
`response_scope: single_beat`,
`generated_multi_mixed_dynamic_static_read_demux`, request-not-busy
assertions for `r0`/`r1`/`r2`/`r3`, no `static_capture`, and no
release-recapture fields. The selector chooses an audit before implementation
because the read recapture marker is currently selected only for one dynamic
plus one or two static read states; `.417` must pin three-static
`static_capture[]`, dynamic/static guard composition, idle-or-releasing
assertions, validation gates, rollback, docs, Knowledge Map impact, and
deferred burst-last/two-dynamic/backend boundaries before behavior changes.
`.417` now selects `.418`, public contract selection for
one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture. The audit changes no behavior. It found no
lower parser, PPIF syntax, support-accounting, report-schema, or IAL1/HDL
prerequisite before contract selection: the public three-static read sample
and list-shaped report mode already ship, rule/assertion helpers already
compose over dynamic/static request and static-ID guard arrays, and the mixed
read recapture marker body already projects list-shaped static capture entries
after its current one-or-two-static selection guard. `.418` must pin public
syntax/support identity, list-shaped `static_capture[]` for `r1`/`r2`/`r3`,
`generated_multi_mixed_dynamic_static_read_demux_completion`, dynamic/static
guard composition, idle-or-releasing assertions for all four transactions,
preservation boundaries, validation gates, rollback, docs, and Knowledge Map
impact before implementation.
`.418` now selects `.419`, direct implementation of
one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`.
The selector changes no behavior. The selected contract preserves public
syntax and support identity,
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`,
`response_scope: single_beat`,
`transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux`,
`transaction_completion_semantics:
matched_dynamic_or_static_concrete_id_single_beat`, the `r0`/`r1`/`r2`/`r3`
dynamic/static/mixed transaction lists, static-ID reservations for `4'd3`,
`4'd5`, and `4'd7`, generated demux/completion behavior, onehot0,
static-ID-exclusion, response-active-match, pairwise unique-match, and
completion-active assertions. It selects
`dynamic_capture.transactions[0]` recapture fields, list-shaped
`static_capture[]` entries for `r1`/`r2`/`r3`, release-recapture source
`generated_multi_mixed_dynamic_static_read_demux_completion`, mixed read
policy names, dynamic/static guard composition, release-only
same-transaction request exclusions, idle-or-releasing assertion names, and
deferred burst-last/two-dynamic/backend boundaries for the implementation
owner. A fresh guarded baseline schedule attempt stopped at the default 88%
host RAM cutoff because host memory started at 88.1%; no cutoff was raised,
and the `.416`/`.417` 46985-byte baseline remains the recorded evidence.
`.419` now ships one-dynamic-plus-three-static mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`.
FSMGen now reports dynamic recapture under
`dynamic_capture.transactions[0]`, list-shaped static recapture under
`static_capture[]` for `r1`/`r2`/`r3`,
`generated_multi_mixed_dynamic_static_read_demux_completion`, guard
composition across all three static requests/static-ID exclusions and both
static siblings, release-only same-transaction request exclusions, and
idle-or-releasing request assertions for `r0`/`r1`/`r2`/`r3`. Public syntax,
support identity, mode/scope/source/semantics, generated demux/completion
behavior, onehot0/static-ID/active-match/unique-match/completion-active
assertions, one-/two-static read recapture, three-static burst-last
no-recapture, two-dynamic-plus-one-static no-recapture, and three-static
read-data/raw-`ARLEN`/runtime/multi-beat consumers remain preserved. Syntax
checks passed. Guarded selected schedule and focused `t/1438` probes stopped
immediately because host memory was already 89.9% and 90.0%, above the
default 88% cutoff; no cutoff was raised. Direct normalizer/rule probes
verified the selected recapture fields, guard-array counts, release-recapture
rule headers, assertion names, and adjacent preservation boundaries. `.420`
now selects the next exact owner after three-static read single-beat
recapture.
`.420` now selects `.421`, readiness audit for one-dynamic-plus-three-static
mixed dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture. The selector changes no behavior. A direct baseline
probe for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif`
confirmed the current report remains
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` with
`response_scope: burst_last`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, no
`static_capture`, no dynamic recapture fields, and four request-not-busy
assertions. The audit comes next because `.419` shipped the three-static
single-beat recapture sibling, `.415` shipped the two-static burst-last
recapture precedent, `.326` already ships the three-static burst-last demux
public sample, and the burst-last normalizer still marks recapture only for
exactly one dynamic plus two static states.
`.421` now selects `.422`, public contract selection for
one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture. The audit changes no behavior. A
direct normalizer/report probe confirmed the current three-static burst-last
baseline remains
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` with
`response_scope: burst_last`, one-bit `axi0_rlast`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, no
`static_capture`, no dynamic recapture fields, and four request-not-busy
assertions. A direct marker probe confirmed the substrate already projects
`mixed_dynamic_static_dynamic_read`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`, and
three `static_capture[]` entries for `r1`/`r2`/`r3` if invoked. The remaining
gap is deliberate selection logic in the burst-last normalizer and focused
RLAST expectations, so `.422` must pin the contract before implementation.
`.422` now selects `.423`, direct implementation of
one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif`.
The selector changes no behavior. The selected contract preserves public
syntax/support identity,
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`, one-bit `axi0_rlast`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, final-beat
match semantics, `r0`/`r1`/`r2`/`r3` transaction lists, static-ID
reservations for `4'd3`/`4'd5`/`4'd7`, generated demux/completion behavior,
raw non-final `RID` ownership evidence, adjacent read-data consumers,
dynamic recapture under `dynamic_capture.transactions[0]`, list-shaped
`static_capture[]` entries for `r1`/`r2`/`r3`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
dynamic/static guard composition, release-only same-transaction request
exclusions, idle-or-releasing assertion names, validation gates, rollback,
docs, and deferred two-dynamic/backend/VHDL boundaries.
`.423` now ships that one-dynamic-plus-three-static mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture behavior. The
implementation widens only the burst-last multi-mixed read recapture selector
from exactly one dynamic plus two static read transactions to exactly one
dynamic plus two or three static read transactions, and aligns the focused
RLAST report expectation helper. The selected public sample now reports
dynamic recapture under `dynamic_capture.transactions[0]`, list-shaped
`static_capture[]` entries for `r1`/`r2`/`r3`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
r0/r1/r2/r3 idle-or-releasing assertions, and generated `r3` static
release-recapture rule wiring. Direct preservation probes confirmed the
one-static and two-static RLAST recapture shapes, the
two-dynamic-plus-one-static no-recapture boundary, and the three-static
read-data completion-validity contract remain in their expected shapes.
Guarded selected schedule JSON passed; guarded focused `t/1438`, strict
check JSON, and generated-SV attempts tripped the default RAM guard when host
memory rose above cutoff; guarded verify-HDL was skipped after those repeated
trips. Fallback direct adapter/report and FSM-to-SystemVerilog probes were
used without raising the cutoff. `.424` is now the next selector after this
recapture shipment.
`.424` now selects `.425`, readiness audit for two-dynamic-plus-one-static
mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture
on
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif`.
The selector changes no behavior. A direct adapter/report probe confirmed the
current two-dynamic-plus-one-static mixed read single-beat and burst-last
reports still have no release-recapture fields, no `static_capture`, three
request-not-busy assertions, and zero idle-or-releasing assertions. The
single-beat shape is selected for audit before burst-last because it exercises
multi-dynamic selected-ID recapture, active same-ID blocking, static concrete
busy recapture, onehot0 mixed request policy, no-active-same-ID assertions,
and active dynamic-ID uniqueness without final-only `RLAST` release-source or
raw non-final `RID` questions.
`.425` now selects `.426`, public contract selection for
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture on the same public sample. The audit changes
no behavior. A guarded schedule JSON probe stopped because host memory was
already 95.3% against the default 88% cutoff, so direct fallback probes were
used. Direct probes confirmed the selected sample remains no-recapture today:
no dynamic release-recapture fields, no `static_capture`, no
release-recapture rules in ISF, and request-not-busy assertions for
`r0`/`r1`/`r2`. The audit found the read guard operands already exist; the
contract-selection leaf should pin `mixed_dynamic_static_multi_active_dynamic_read`,
list-shaped static capture for `r2`,
`generated_multi_mixed_dynamic_static_read_demux_completion`, and
idle-or-releasing assertions for `r0`, `r1`, and `r2`.
`.426` now selects `.427`, direct implementation of that
two-dynamic-plus-one-static mixed dynamic/static read single-beat recapture
contract. The selector changes no behavior. The contract preserves the
existing public syntax, support identity,
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`,
`generated_multi_mixed_dynamic_static_read_demux`, and
`matched_dynamic_or_static_concrete_id_single_beat`; it adds dynamic
recapture fields for `r0`/`r1` with
`mixed_dynamic_static_multi_active_dynamic_read`, list-shaped
`static_capture[]` for `r2`, the generated mixed read completion source,
combined dynamic/static guards, same-transaction release-only exclusions, and
idle-or-releasing assertions for `r0`, `r1`, and `r2`.
`.427` now ships that two-dynamic-plus-one-static mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture behavior for the existing
public sample. FSMGen emits `axi0_r0_dynamic_id_release_recapture`,
`axi0_r1_dynamic_id_release_recapture`, and
`axi0_r2_static_busy_release_recapture`; reports
`mixed_dynamic_static_multi_active_dynamic_read` under both dynamic
`dynamic_capture.transactions[]` entries; reports list-shaped
`static_capture[]` for `r2`; composes dynamic guards across sibling dynamic
requests, active sibling same-ID, static requests, and static-ID exclusion;
composes static guards across both dynamic requests; and replaces the
`r0`/`r1`/`r2` request-not-busy assertions with idle-or-releasing assertions.
The two-dynamic burst-last and read-data/raw-`ARLEN`/runtime/multi-beat
consumers remain no-recapture preservation boundaries. A guarded focused
`t/1438` selected filter stopped at the RAM cutoff before TAP output; direct
report and ISF/FSM/SystemVerilog fallback probes covered the selected
behavior. `.428` now selects the next post two-dynamic mixed read recapture
slice.
`.428` now selects `.429`, readiness audit for two-dynamic-plus-one-static
mixed dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture. The selector changes no behavior. Direct baseline
probes on the burst-last response-demux, burst-last read-data, and burst-last
raw-`ARLEN` samples confirmed they still use
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`,
request-not-busy assertions for `r0`/`r1`/`r2`, no `static_capture`, and no
release-recapture rules. The audit is next because this shape reuses the
`.427` dynamic/static guard problem but adds final-beat source, raw non-final
`RID`, `RLAST`, and read-data/raw-`ARLEN`/runtime/multi-beat preservation
questions before any behavior change.
`.429` now selects `.430`, public contract selection for the same
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID &&
RLAST` release-and-recapture boundary. The audit changes no behavior. It found
no lower parser, support-accounting, report-schema, IAL1, or HDL prerequisite:
`.427` already supplied the read-side multi-active mixed recapture policy and
guard storage, while the burst-last normalizer is the remaining selector that
leaves the two-dynamic/one-static RLAST branch unmarked. `.430` must pin
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
dynamic/static report fields, guard composition, idle-or-releasing assertion
names, and read-data/raw-`ARLEN`/runtime/multi-beat preservation before
implementation.
`.430` now selects `.431`, direct implementation of that
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID &&
RLAST` release-and-recapture contract. The selector changes no behavior. The selected
implementation keeps the existing public sample, support identity,
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`axi0_rlast`, `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
raw non-final `RID` assertions, final-beat completion pulses, and
read-data/raw-`ARLEN`/runtime/multi-beat consumers. It adds `r0`/`r1`
dynamic recapture fields with `mixed_dynamic_static_multi_active_dynamic_read`,
list-shaped `static_capture[]` for `r2`, final-beat release-recapture source
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
combined dynamic/static guards, release-only same-transaction request
exclusions, and idle-or-releasing assertions for `r0`, `r1`, and `r2`.
`.431` now ships that two-dynamic-plus-one-static mixed dynamic/static read
burst-last `RID && RLAST` release-and-recapture behavior. FSMGen emits
`axi0_r0_dynamic_id_release_recapture`,
`axi0_r1_dynamic_id_release_recapture`, and
`axi0_r2_static_busy_release_recapture` from generated final-beat completion
pulses only; reports `r0`/`r1` recapture under
`dynamic_capture.transactions[]`; reports list-shaped `static_capture[]` for
`r2`; keeps release-only rules disjoint from same-transaction requests; and
replaces the selected request-not-busy assertions with idle-or-releasing
assertions. Public syntax, support identity, mode/source/semantics, raw
non-final `RID` active/unique-match assertions, final-beat completion
ownership, `.427` single-beat recapture, one-/two-/three-static burst-last
recapture, and read-data/raw-`ARLEN`/runtime/multi-beat consumers are
preserved. A guarded focused `t/1438` selected-case run stopped at host memory
93.0% against the default 88% cutoff; direct report/ISF/FSM/SystemVerilog
probes covered the selected behavior. `.432` is the next post two-dynamic
mixed read burst-last recapture selector.
`.432` now selects `.433`, readiness audit for dynamic same-ID issue-order
policy, queue, and scoreboard ownership after the bounded dynamic/mixed
response-demux, read-data, multi-beat, and same-cycle release-and-recapture
chain reached the two-dynamic-plus-one-static read burst-last boundary. The
selector changes no behavior. It records that dynamic transaction-ID
contract/report support and generated bounded dynamic/mixed response-demux
behavior now exist, while direct same-ID queue or scoreboard behavior still
needs public issue-order policy, request arbitration, overflow/ambiguity
assertions, and report/residue movement before implementation.
`.433` now selects `.434`, public dynamic same-ID policy contract selection
before dynamic per-ID queues, scoreboards, parser/report implementation, or
generated behavior. The audit changes no behavior. It records that bounded
dynamic and mixed response-demux/read-data/multi-beat/recapture substrate now
exists, while dynamic same-ID reuse still lacks source/report vocabulary
distinct from `concrete-id-reuse`. Direct queues or scoreboards remain
deferred until `.434` chooses the dynamic policy spelling, report fields,
diagnostics, allowed first policy values, and first later owner.
`.434` now selects the additive family-local `(dynamic-id-reuse reject)`
source contract under `(same-id-ordering ...)`, distinct from existing
`concrete-id-reuse`, and selects `.435`, metadata-first parser/report
readiness audit before implementation. The selector changes no behavior. The
first dynamic same-ID policy value is only `reject`; dynamic
`issue-order-queue` and `scoreboard` values remain unsupported future owners.
The selected report vocabulary is
`same_id_ordering.dynamic_id_reuse_policy.<family>`, with accepted same-ID
reuse false and no generated queue or scoreboard behavior.
`.435` now selects `.436`, direct metadata-first parser/report implementation
for `(dynamic-id-reuse reject)`. The audit changes no behavior. It found no
lowerer, HDL, support-accounting infrastructure, Knowledge Map, or mdBook
prerequisite. `.436` should add the public syntax, normalized report fields,
focused diagnostics, a metadata-only public sample, and support accounting,
while keeping generated dynamic response-demux plus dynamic same-ID policy
fail-closed until a later owner maps generated no-active-same-ID assertion
enforcement.
`.436` now ships metadata-first parser/report support for the selected
`(dynamic-id-reuse reject)` policy under `(same-id-ordering ...)`. PPIF accepts
dynamic-only family arms and coexistence with existing concrete
`concrete-id-reuse` clauses; empty arms, duplicate dynamic clauses,
unsupported dynamic policy values, selected dynamic policy without
transactions, selected dynamic policy without a same-family dynamic
transaction, and concrete-only same-ID policy against dynamic transaction IDs
fail closed with targeted diagnostics. At the `.436` metadata-only boundary,
dynamic response-demux plus same-family dynamic policy also failed closed;
later `.438` and `.442` slices accept covered generated response-demux
assertion mappings. Reports now carry
`same_id_ordering.dynamic_id_reuse_policy.<family>` with `policy: reject`,
`implementation_status: selected_not_generated`, `enforcement:
not_generated`, `accepted_same_id_reuse: false`,
`request_conflict_policy: no_active_same_id`, and no generated queue or
scoreboard behavior. Dynamic-only policy uses
`same_id_ordering.mode: dynamic_id_reuse_policy`; concrete plus dynamic policy
uses `id_reuse_policy`. The public sample
`ppif/axi_manager_capacity_status_dynamic_same_id_reject_policy.ppif` is
support-accounted as
`intent.ppif_axi_manager_capacity_status_dynamic_same_id_reject_policy`.
At this metadata-first boundary, generated dynamic same-ID enforcement and
response-demux mapping were still deferred; later `.438` and `.442` slices now
cover bounded generated response-demux assertion mappings. Dynamic queues,
scoreboards, HDL behavior, and VHDL behavior remain deferred.
`.437` now selects `.438`, a narrow generated-enforcement report mapping for
selected `dynamic-id-reuse reject` policy over already generated multi-active
dynamic and mixed dynamic/static response-demux shapes. The audit changes no
behavior. The first covered shapes are bounded multiple all-dynamic write/read
response demux and bounded two-dynamic-plus-one-static mixed write/read
response demux where generated reports already expose
`active_dynamic_ids_must_be_unique`, `*_dynamic_request_no_active_same_id`,
and `*_dynamic_active_id_unique` artifacts. Single-active dynamic demux,
one-dynamic mixed demux, queues, scoreboards, direct backend behavior, and
VHDL remain deferred.
`.438` now ships that generated-enforcement report mapping. Same-family
`response-demux.<family>` plus `same-id-ordering.<family>
(dynamic-id-reuse reject)` is accepted for the covered multi-active
all-dynamic and two-dynamic-plus-one-static mixed response-demux shapes
without adding generated rules, storage, assertions, HDL behavior, or runtime
behavior. Covered dynamic policy reports use `implementation_status:
generated_no_active_same_id_reject`, `enforcement:
generated_no_active_same_id_assertions`, `assertion_enforcement:
runtime_assertion`, `response_demux_covered: true`, response-demux
mode/source metadata, covered dynamic transactions, and exact generated
no-active-same-ID plus active-ID uniqueness assertion names. The
support-accounted public sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_same_id_reject.ppif`.
Single-active dynamic demux, one-dynamic mixed demux, queues, scoreboards,
direct backend behavior, backend-language variants, and VHDL remain deferred.
`.439` now selects `.440`, readiness audit for single-active dynamic
same-ID reject mapping. Single-active dynamic response-demux already exposes
generated `*_dynamic_request_idle_or_releasing`, active-match, and
completion-active assertions for write `BID`, read single-beat `RID`, and read
burst-last `RID && RLAST`, but it does not expose the `.438` multi-active
`*_dynamic_request_no_active_same_id` plus `*_dynamic_active_id_unique`
assertion pair. The next audit must decide whether a single-active-specific
generated reject report contract is honest or whether the current fail-closed
behavior remains. One-dynamic mixed mapping, dynamic queues, scoreboards,
direct backend behavior, backend-language variants, VHDL, and new generated HDL
remain deferred.
`.440` now selects `.441`, public contract selection for that single-active
mapping. Guarded compact probes confirmed the single-active write `BID`, read
single-beat `RID`, and read burst-last `RID && RLAST` samples expose generated
`*_dynamic_request_idle_or_releasing`, active-match, and completion-active
assertions while still carrying `same_id_ordering` residue. Temporary guarded
single-active same-ID reject probes still fail closed at the `.438` generated
multi-active no-active-same-ID diagnostic. The existing idle-or-releasing
assertions are strong enough for a single-active generated reject contract, but
they are not the `.438` multi-active evidence model, so `.441` must select
exact report fields, residue movement, and diagnostics before behavior changes.
One-dynamic mixed mapping, dynamic queues, scoreboards, direct backend
behavior, backend-language variants, VHDL, and new generated HDL remain
deferred.
`.442` now ships the single-active dynamic same-ID reject mapping. Same-family
`response-demux.<family>` plus `same-id-ordering.<family>
(dynamic-id-reuse reject)` is accepted for single-active dynamic write `BID`,
read single-beat `RID`, and read burst-last `RID && RLAST` shapes that already
report generated idle-or-releasing, active-match, and completion-active
assertions. Covered policy reports use
`implementation_status: generated_single_active_reject`, `enforcement:
generated_idle_or_releasing_assertions`, `single_active_covered: true`, and
`single_active_request_policy: idle_or_releasing`, while preserving
`accepted_same_id_reuse: false`, `request_conflict_policy:
no_active_same_id`, and generated queue/scoreboard false. They list generated
idle-or-releasing, active-match, and completion-active assertion names and
deliberately do not reuse the `.438` multi-active
`generated_no_active_same_id_assertions` or
`generated_active_id_uniqueness_assertions` fields. The support-accounted
public sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_same_id_reject.ppif`.
The mapping adds no generated rules, storage, assertions, HDL, or runtime
behavior; one-dynamic mixed mapping, dynamic queues, scoreboards, direct
backend behavior, backend-language variants, VHDL, and new generated HDL remain
deferred. `.442` selects `.443`, the next post-single-active-mapping selector.
`.443` now selects `.444`, readiness audit for one-dynamic mixed
dynamic/static dynamic same-ID reject mapping. The selector changes no
behavior. It compares the remaining one-dynamic mixed fail-closed boundary
against the generated mixed response-demux evidence: static concrete ID
reservation/exclusion, dynamic request-not-static-ID and
active-not-static-ID assertions, mixed request onehot0, response
active/unique-match, and completion-active assertions. The next audit must
decide whether that evidence can support a third generated reject report
contract distinct from `.438` multi-active no-active-same-ID coverage and
`.442` single-active idle-or-releasing coverage, or whether the current
fail-closed behavior should remain. Dynamic queues, scoreboards, direct
backend behavior, backend-language variants, VHDL, and new generated HDL
remain deferred.
`.444` now selects `.445`, public report contract selection for one-dynamic
mixed dynamic/static dynamic same-ID reject mapping. Guarded schedule probes
confirmed representative mixed write, read single-beat, read burst-last,
three-static write, and three-static read burst-last samples expose static-ID
reservation/exclusion, mixed request onehot0, response active/unique-match,
and completion-active assertion evidence. A guarded temporary read probe still
failed closed at the generated multi-active no-active-same-ID diagnostic. The
evidence is ready for contract selection, but direct implementation is
deferred because one-dynamic mixed mapping needs report fields and residue
rules distinct from both `.438` multi-active and `.442` single-active
coverage. Dynamic queues, scoreboards, direct backend behavior,
backend-language variants, VHDL, and new generated HDL remain deferred.
`.445` now selects `.446`, direct implementation of the one-dynamic mixed
dynamic/static dynamic same-ID reject report/acceptance mapping. The selected
contract covers generated mixed write `BID`, read single-beat `RID`, and read
burst-last `RID && RLAST` response-demux shapes with exactly one dynamic
transaction plus one, two, or three pairwise-distinct concrete static
transactions. Covered reports use `implementation_status:
generated_mixed_static_id_exclusion_reject`, `enforcement:
generated_static_id_exclusion_assertions`, `mixed_dynamic_static_covered:
true`, `mixed_dynamic_static_request_policy: onehot0_mixed_request`,
`static_id_conflict_policy: static_concrete_ids_reserved`, and
`static_id_exclusion_policy: dynamic_id_must_not_equal_static_concrete_id`,
while preserving `accepted_same_id_reuse: false`,
`request_conflict_policy: no_active_same_id`, and generated queue/scoreboard
false. The mapping is bounded to acceptance/report/residue movement over
existing generated static-ID exclusion, mixed request onehot0, response
active/unique-match, and completion-active evidence; it does not add generated
rules, storage, assertions, HDL, runtime behavior, direct backend behavior,
backend-language variants, queues, scoreboards, VHDL, or new generated HDL.
`.446` now ships that one-dynamic mixed dynamic/static dynamic same-ID reject
mapping. Same-family `response-demux.<family>` plus
`same-id-ordering.<family> (dynamic-id-reuse reject)` is accepted for
generated mixed write `BID`, read single-beat `RID`, and read burst-last
`RID && RLAST` shapes with exactly one dynamic transaction plus one, two, or
three pairwise-distinct concrete static transactions. Covered reports use the
`.445` selected `generated_mixed_static_id_exclusion_reject` and
`generated_static_id_exclusion_assertions` contract, list exact static-ID
reservations, dynamic request/active static-ID exclusion assertions, mixed
request onehot0 assertions, response active/unique-match assertions, and
completion-active assertions, and remove only covered same-family
`same_id_ordering` residue. No new public PPIF sample or support-accounting
entry is added; focused tests insert the same-ID policy into existing
support-accounted mixed response-demux samples in memory and compare generated
IAL1/IAL0 artifacts against the original samples. Dynamic queues,
scoreboards, direct backend behavior, backend-language variants, VHDL, new
generated HDL, and new generated rule/storage/assertion/runtime behavior
remain deferred. `.446` selects `.447`, the next post-mapping selector.
`.447` now selects `.448`, readiness audit for the public dynamic same-ID
`issue-order-queue` policy contract after the bounded `dynamic-id-reuse
reject` mappings shipped. The selector changes no behavior and does not
accept new source values yet. It chooses issue-order queue contract readiness
before scoreboard because concrete same-ID queue-head work already provides
the closest bounded precedent, while dynamic scoreboard behavior has a
different completion-tracking promise and remains a separate later owner.
`.448` must decide whether `dynamic-id-reuse issue-order-queue` becomes
metadata-first selected-not-generated policy, remains unsupported until a
generated queue behavior slice exists, or needs another prerequisite before
parser/report changes.
`.448` now selects `.449`, public dynamic same-ID `issue-order-queue`
policy contract selection. The audit changes no behavior and keeps
`dynamic-id-reuse issue-order-queue` and `dynamic-id-reuse scoreboard`
unsupported until later exact owners. It finds direct generated dynamic queue
behavior too large, direct parser/report implementation premature without a
contract, and scoreboard policy separate from issue-order queue semantics.
`.449` must decide the source spelling, metadata-first report fields,
selected-not-generated boundary, residue movement, diagnostics,
support-accounting impact, validation gates, and non-goals before any parser
or generated behavior change.
`.449` now selects `.450`, metadata-first parser/report implementation for
dynamic same-ID `issue-order-queue` policy. The selected public spelling is
family-local `(dynamic-id-reuse issue-order-queue)` under `same-id-ordering`
read/write arms. `.450` must accept and report the selected metadata with
`implementation_status: selected_not_generated`, `enforcement:
not_generated`, `accepted_same_id_reuse: false`, `generated_queue_behavior:
false`, and residue for `dynamic_per_id_issue_order_queues`, while preserving
dynamic `scoreboard` as unsupported and avoiding generated dynamic queue,
HDL, direct backend, or accepted-reuse behavior.
`.450` now ships that metadata-first parser/report support. Public PPIF
source may use `(dynamic-id-reuse issue-order-queue)` for read or write
same-ID ordering families. The new support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy.ppif`
lowers to the same generated IAL1/IAL0 artifacts as the base dynamic
transaction-ID metadata sample, while its report records
`dynamic_id_reuse_policy.<family>.policy: issue_order_queue`,
`implementation_status: selected_not_generated`,
`request_conflict_policy: dynamic_issue_order_queue_selected_not_generated`,
`accepted_same_id_reuse: false`, `generated_queue_behavior: false`,
`generated_scoreboard_behavior: false`, and residue
`dynamic_per_id_issue_order_queues`. Dynamic `scoreboard`, generated dynamic
queues, accepted dynamic same-ID reuse, HDL, VHDL, direct backend behavior,
and backend-language variants remain deferred. `.450` selects `.451`, the
post-metadata selector for the next dynamic same-ID policy slice.
`.451` now selects `.452`, readiness audit for generated dynamic same-ID
`issue-order-queue` behavior. The selector changes no behavior. It chooses
queue readiness before scoreboard because `.450` made
`dynamic_per_id_issue_order_queues` explicit and user-visible, while dynamic
scoreboard remains a separate unsupported policy with different
completion-tracking semantics. `.452` must decide whether generated dynamic
queue behavior can move to contract selection, needs a narrower prerequisite,
or remains deferred.
`.452` now selects `.453`, public contract selection for generated dynamic
same-ID `issue-order-queue` behavior. The audit changes no behavior. It finds
the dynamic response-demux substrate mature enough for a contract pass, but
direct generated queue behavior still needs the public family/scope,
runtime-ID queue key, entry state, admitted enqueue, dequeue, response
matching, ordering guarantees, overflow/ambiguity assertions, report fields,
and residue movement selected first.
`.453` now selects `.454`, runtime-ID queue-state representation selection
for the first generated dynamic same-ID `issue-order-queue` behavior. The
selector changes no behavior. It chooses the all-dynamic write `BID` path as
the first generated family, but direct behavior still waits for an explicit
representation contract because accepting dynamic same-ID reuse must replace
reject-only active-ID uniqueness proofs with runtime-ID queue state,
enqueue/dequeue semantics, response matching, same-cycle policy,
overflow/ambiguity assertions, report fields, and residue movement.
`.454` now selects `.455`, implementation of the bounded two-transaction
all-dynamic write `BID` dynamic issue-order queue behavior. The selector
changes no behavior. It chooses `compact_runtime_id_issue_order_slots`: each
queue slot stores one-hot transaction identity plus a slot-local captured
runtime ID, and `BID` response demux selects the earliest valid slot whose
captured ID matches the response. Same-ID overlaps are ordered by slot age,
different-ID slot1 responses may complete ahead of slot0, same-cycle selected
dequeue plus one enqueue is supported, and reject-only active-ID uniqueness
assertions remain exclusive to `dynamic-id-reuse reject`.
`.455` now ships that bounded generated behavior through support-accounted
public sample
`ppif/axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue.ppif`.
Generated `response-demux.write` now reports
`bounded_dynamic_write_bid_issue_order_queue_demux_contract`,
`generated_dynamic_issue_order_queue_demux`,
`earliest_matching_captured_runtime_id`,
`compact_runtime_id_issue_order_slots`, and
`dynamic_issue_order_earliest_matching_slot` for exactly two all-dynamic write
transactions. Generated same-ID ordering reports
`generated_dynamic_write_bid_issue_order_queue`,
`accepted_same_id_reuse: true`, queue-specific assertions, slot-local
`AWID` capture, same-cycle selected dequeue plus enqueue, and no same-ID
ordering residue for the covered write family. Dynamic read queues, broader
write cardinalities, mixed dynamic/static queues, dynamic scoreboards, direct
backend behavior, backend-language variants, and VHDL remain future exact
owners. `.455` selects `.456`, the post dynamic write same-ID issue-order queue
selector.
`.456` now selects `.457`, readiness audit for generated dynamic read
same-ID `issue-order-queue` behavior. The selector changes no behavior. It
chooses read queue readiness before broader write cardinality, mixed
dynamic/static queues, scoreboards, validation retry, direct backend,
backend-language variants, or VHDL because existing generated dynamic read
behavior already has single-beat `RID`, burst-last `RID && RLAST`, read-data,
raw `ARLEN`/runtime validation, multi-beat output-bank, and recapture
consumers that a queue implementation must preserve.
`.457` now selects `.458`, public contract selection for the first generated
dynamic read same-ID `issue-order-queue` behavior. The readiness audit changes
no behavior. It chooses all-dynamic read single-beat `RID` before direct
behavior or burst-last `RID && RLAST` because the single-beat shape can reuse
the runtime-ID queue model without final-beat-only dequeue, raw non-final
beats, `RLAST`, read-data, raw `ARLEN`, runtime validation, multi-beat, or
recapture consumer coupling.
`.459` now ships the bounded two-transaction all-dynamic read single-beat
`RID` dynamic same-ID `issue-order-queue` behavior through support-accounted
public sample
`ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue.ppif`.
Generated `response-demux.read` now reports
`bounded_dynamic_read_rid_issue_order_queue_demux_contract`,
`generated_dynamic_issue_order_queue_demux`,
`earliest_matching_captured_runtime_id`,
`compact_runtime_id_issue_order_slots`, and
`dynamic_issue_order_earliest_matching_slot` for exactly two all-dynamic read
transactions with `response-scope single-beat`. Generated same-ID ordering
reports `generated_dynamic_read_rid_issue_order_queue`,
`first_generated_scope: read_rid_two_dynamic_transactions`,
`accepted_same_id_reuse: true`, queue-specific assertions, slot-local `ARID`
capture, same-cycle selected dequeue plus enqueue, earliest matching `RID`,
and no same-ID ordering residue for the covered read family. Read burst-last,
read-data over queues, raw `ARLEN`/runtime, multi-beat, broader queue
cardinality, mixed dynamic/static queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain future exact owners.
`.459` selects `.460`, the post dynamic read single-beat same-ID
issue-order queue selector.
`.460` now selects `.461`, readiness audit for generated dynamic read
burst-last `RID && RLAST` same-ID `issue-order-queue` behavior. The selector
changes no behavior. It chooses burst-last queue readiness because the shipped
dynamic read queue path covers only `response-scope single-beat`, while the
burst-last sibling must settle final-beat-only dequeue, raw non-final beat
policy, `RLAST`/`response-scope`/`last-signal` requirements, selected-match
assertions, downstream read-data/burst/runtime/multi-beat/recapture
preservation, report/residue/support/sample/validation, rollback, and
explicit residue before any behavior change. Read-data over queues, raw
`ARLEN`/runtime over queues, multi-beat output banks over queues, broader
queue cardinality, mixed dynamic/static queues, scoreboards, validation retry,
direct backend behavior, backend-language variants, and VHDL remain future
exact owners.
`.461` now selects `.462`, public contract selection for generated dynamic
read burst-last `RID && RLAST` same-ID `issue-order-queue` behavior. The
readiness audit changes no behavior. It found no lower parser, report-schema,
IAL1, IAL0, or SystemVerilog prerequisite because burst-last response-demux
metadata, one-bit `RLAST` input lowering, compact runtime-ID queue slots,
final dynamic `RID && RLAST` completions, raw non-final dynamic beat
assertions, and concrete burst-last queue-head non-last no-dequeue semantics
already exist. Direct behavior still needs public contract selection for
final-beat-only selected dequeue, raw non-final beat preservation, `RLAST`
requirements, selected completion and report vocabulary, queue assertions,
residue/support/sample/validation, and downstream read-data/burst/runtime/
multi-beat/recapture preservation.
`.462` now selects `.463`, direct implementation of the first generated
dynamic read burst-last `RID && RLAST` same-ID `issue-order-queue` behavior.
The contract-selection slice changes no behavior. It selects exactly two
all-dynamic reads, explicit `response-demux.read` with `response-scope
burst-last` and one-bit `last-signal`, compact runtime-ID issue-order slots,
raw `RID` beat matching without `RLAST`, selected final dequeue and generated
completion only on the earliest matching captured runtime ID plus `RLAST`,
mode `bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract`,
completion source `generated_dynamic_issue_order_queue_demux_last_beat`,
implementation status `generated_dynamic_read_rid_rlast_issue_order_queue`,
and first scope `read_rid_rlast_two_dynamic_transactions`. Read-data over
generated dynamic read queues, raw `ARLEN`, runtime validation, multi-beat
output banks, queue recapture widening, broader queue cardinality, mixed
dynamic/static queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain future exact owners.
`.463` now ships generated bounded two-transaction all-dynamic read
burst-last `RID && RLAST` dynamic same-ID `issue-order-queue` behavior. The
public sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue.ppif`
uses exactly two dynamic reads, `same-id-ordering.read
(dynamic-id-reuse issue-order-queue)`, explicit generated
`response-demux.read`, `response-scope burst-last`, and one-bit
`last-signal axi0_rlast`. FSMGen generates compact runtime-ID queue slots with
slot-local `ARID`, raw earliest matching `RID` response ownership, final
completion/dequeue only on earliest matching captured runtime ID plus `RLAST`,
same-cycle selected final dequeue plus one enqueue, and queue assertions
including non-final no-dequeue. Reports use
`bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract`,
`generated_dynamic_issue_order_queue_demux_last_beat`,
`generated_dynamic_read_rid_rlast_issue_order_queue`, and
`first_generated_scope: read_rid_rlast_two_dynamic_transactions`. Read-data
over generated dynamic read queues, raw `ARLEN`, runtime validation,
multi-beat output banks, broader queue cardinality, mixed dynamic/static
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain future exact owners.
`.464` now selects `.465`, readiness audit for read-data routing over
generated dynamic read same-ID `issue-order-queue` response-demux pulses. The
selector changes no behavior. Read-data is next because generated dynamic read
same-ID queues now ship both single-beat `RID` and burst-last `RID && RLAST`
completion sources, while read-data over generated dynamic read queues remains
explicitly unowned. The audit must decide whether the first behavior owner is
scalar single-beat over generated dynamic read single-beat queues, scalar
last-beat over generated dynamic read burst-last queues, a paired bounded
scalar contract, a report/static cleanup prerequisite, a lower-layer
prerequisite, or deferral. Raw `ARLEN`, runtime validation, multi-beat output
banks, queue recapture widening, broader queue cardinality, mixed
dynamic/static queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL remain future exact owners.
`.465` now selects `.466`, public contract selection for paired bounded
scalar read-data routing over generated dynamic read same-ID
`issue-order-queue` completions. The readiness audit changes no behavior. It
selects a paired contract because generated dynamic read same-ID queues now
ship both single-beat `generated_dynamic_issue_order_queue_demux` and
burst-last `generated_dynamic_issue_order_queue_demux_last_beat` completion
sources, and the ordinary generated dynamic read-data path already supports
the matching scalar single-beat and scalar last-beat public syntax. `.466`
must pin the public source shape, sample identities, report keys, diagnostics,
residue, validation, rollback, and queue-specific read-data completion
validity names
`generated_dynamic_read_issue_order_queue_response_demux_completion_pulse` and
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`
before behavior changes. Raw `ARLEN`, runtime validation, multi-beat output
banks, queue recapture widening, broader queue cardinality, mixed
dynamic/static queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL remain future exact owners.
`.466` now selects `.467`, direct implementation of paired bounded scalar
read-data routing over generated dynamic read same-ID `issue-order-queue`
completions. The contract-selection slice changes no behavior. It reuses
existing `read-data.read` syntax and selects two public samples:
`ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data.ppif`
and
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data.ppif`.
The implementation must cover exactly two all-dynamic read transactions with
complete scalar transaction bindings, keep the underlying queue response-demux
modes and sources, report
`generated_dynamic_read_issue_order_queue_response_demux_completion_pulse` for
single-beat capture and
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`
for last-beat capture, and leave raw `ARLEN`, runtime validation, multi-beat
output banks, queue recapture widening, broader queue cardinality, mixed
dynamic/static queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL as future exact owners.

`.467` now ships paired scalar read-data routing over generated dynamic read
same-ID `issue-order-queue` completions. It adds the public samples
`ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data.ppif`
and
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data.ppif`,
queue-specific read-data coverage and completion-validity vocabulary, scalar
`RDATA`/`RRESP` capture for `r0` and `r1`, tests, behavior docs, and Knowledge
Map coverage. The response-demux remains queue-owned, raw `ARLEN` remains
absent, and scalar queue read-data without `burst-length` remains the shipped
behavior.

`.468` selected `.469`, direct bounded implementation of report-only
raw-`ARLEN` burst-length capture over generated dynamic read same-ID
`issue-order-queue` last-beat read-data. `.469` now ships that behavior
through the support-accounted public sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif`,
the support-accounting entry, generated `axi0_arlen` input,
per-transaction raw-`ARLEN` storage/capture rules, queue-specific
report/static-rule vocabulary, focused tests, docs, mdBook, and Knowledge Map
coverage. `.471` now ships runtime beat-count/`RLAST` validation over that
generated dynamic read same-ID `issue-order-queue` last-beat raw-`ARLEN`
shape through the support-accounted public sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif`.
The generator emits per-transaction expected-beat storage, read-beat counters,
request-time `ARLEN[4:0] + 5'd1` initialization, matched queue read-beat
counter increments, four beat-count/`RLAST` assertions per transaction,
focused tests, docs, mdBook, and Knowledge Map coverage. Multi-beat output
banks remained future work until `.472`, which now selects `.473`, direct
bounded implementation of multi-beat output banks over that generated dynamic
read same-ID `issue-order-queue` runtime-validation boundary. The audit found
no new public contract-selection prerequisite: existing multi-beat
`read-data.read` syntax is sufficient, and a guarded temporary queue
multi-beat candidate failed closed only at the local dynamic issue-order queue
read-data coverage gate. Broader queues, mixed dynamic/static queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain future exact owners. `.473` now ships that multi-beat output-bank
behavior through
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif`,
with `bounded_multi_beat_read_data_contract`, queue matched-beat lane capture,
valid masks, length outputs, worst-observed scalar `RRESP` aggregates, and
empty read-data residue. `.474` selected `.475`, public report/static contract
selection for generated dynamic same-ID `issue-order-queue` same-cycle
selected-dequeue-plus-enqueue recapture. `.475` now selects `.476`, readiness
audit for identity-preserving same-transaction queue recapture ID refresh. It
does not add a positive recapture report field yet: current queue reports keep
`generated_update_rules` as literal emitted-rule lists under
`same_id_ordering.dynamic_id_reuse_policy.*.generated_queues[]`, while
classic `same_cycle_release_recapture_policy` and `release_recapture_*` fields
remain exclusive to response-demux capture state. `.477` now emits
state-key-preserving same-transaction selected-dequeue-plus-enqueue dynamic
queue update rules such as `r0_dequeue_enqueue_r0`,
`r1_r0_dequeue_enqueue_r0`, `w0_dequeue_enqueue_w0`, and
`w1_w0_dequeue_enqueue_w0`; those rules refresh the affected slot-local
captured `ARID`/`AWID` while preserving retained slot IDs. `.479` now reports
that support explicitly under each generated dynamic queue entry with
`same_transaction_recapture_policy: refresh_captured_request_id`,
`same_transaction_recapture_rule_scope:
state_key_preserving_selected_dequeue_enqueue`, and
`same_transaction_recapture_id_source` set to the queue request-ID source
(`axi0_awid` for write BID queues and `axi0_arid` for read RID/RID-and-RLAST
queues). The literal `generated_update_rules` list remains the emitted-rule
evidence, and classic `release_recapture_*` fields remain exclusive to
response-demux capture state. `.480` now selects `.481`, readiness audit for
the smallest broader dynamic queue cardinality step: one generated all-dynamic
write BID same-ID `issue-order-queue` widened from two transactions to a
bounded depth-3, three-transaction queue. Mixed dynamic/static queues,
scoreboards, read-side depth-3 queues, direct backend behavior,
backend-language variants, and VHDL remain future exact owners.
`.481` now selects `.482`, direct bounded implementation of that depth-3
all-dynamic write queue. The readiness audit found the behavior blocker is the
local dynamic queue admission/storage gate, which still requires depth 2 and
exactly two transactions. Transition, assignment, state-expression,
selected-match, assertion, and report helpers are already queue-depth and
transaction-list driven. `.482` now ships the generated depth-3 write shape
through support-accounted public sample
`ppif/axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue.ppif`.
The generated queue has three compact runtime-ID slots, covers `w0`/`w1`/`w2`,
reports `first_generated_scope: write_bid_three_dynamic_transactions`, and
keeps same-transaction captured-`AWID` refresh fields under the generated
queue report. Ambiguous depth-3 cross-transaction dequeue/enqueue rule names
include the selected dequeued transaction, while existing depth-2 and
same-transaction refresh rule names stay stable. Read depth-3 queues,
read-data, mixed dynamic/static queues, scoreboards, arbitrary cardinality,
direct backend behavior, backend-language variants, and VHDL remain future
owners. `.483` now selects `.484`, readiness audit for generated
all-dynamic read single-beat `RID` same-ID `issue-order-queue` cardinality
widening from two transactions to one bounded depth-3, three-transaction
queue. Read single-beat is the smallest read-side depth-3 audit after the
write proof because it adds generated `RID` completion without `RLAST`,
read-data, raw `ARLEN`, runtime validation, output banks, mixed static-ID
exclusion, or scoreboard semantics. A RAM-guarded temporary read-depth3
schedule probe stopped at host-memory cutoff before producing data; no
unguarded retry or cutoff raise was used. Backend-language variants and
external converters such as `sv2v` remain outside this IAL2 slice;
FSMGen-owned generation/lowering remains the default under the backend
portability frontier. `.484` now selects `.485`, direct bounded
implementation of one generated all-dynamic read single-beat `RID` same-ID
`issue-order-queue` with exactly three dynamic read transactions, generated
single-beat `RID` response-demux completion, `read-max-pending` at least 3,
and queue depth 3. The readiness audit found the current blocker is local:
the dynamic read planner still requires exactly two all-dynamic reads and
records depth 2, while the shared dynamic queue builder admits depth 3 only
for write. A lightweight helper probe produced 99 transition rules, 19
assertions, zero duplicate names, the disambiguated cross-transaction rule,
the tail-selected refresh rule, and the `r2` completion-selected-match
assertion. Read burst-last depth-3, read-data over depth-3 queues, mixed
dynamic/static queues, scoreboards, arbitrary cardinality, backend-language
variants, external converter dependencies, and VHDL remain deferred.
`.485` now ships that generated depth-3 all-dynamic read single-beat `RID`
same-ID `issue-order-queue` behavior through support-accounted public sample
`ppif/axi_manager_capacity_status_dynamic_read_depth3_same_id_issue_order_queue.ppif`.
Generated `response-demux.read` covers `r0`/`r1`/`r2`, reports
`bounded_dynamic_read_rid_issue_order_queue_demux_contract`,
`generated_dynamic_issue_order_queue_demux`,
`read_rid_three_dynamic_transactions`, queue depth 3, and queue-owned
same-transaction captured-`ARID` refresh fields. The generated queue allocates
three compact runtime-ID slots, emits slot2 onehot and `r2`
completion-selected-match assertions, and keeps depth-2 read queues plus the
depth-3 write queue behavior unchanged. Read burst-last depth-3, read-data
over depth-3 queues, mixed dynamic/static queues, scoreboards, arbitrary
cardinality, direct backend behavior, backend-language variants, external
converter dependencies, and VHDL remain deferred. `.486` is the next
post-behavior selector. `.486` now selects `.487`, readiness audit for
generated all-dynamic read burst-last `RID && RLAST` same-ID
`issue-order-queue` cardinality widening from the shipped two-transaction
dynamic read burst-last queue to one bounded depth-3, three-transaction queue.
It is the smallest next audit because `.485` proves the read depth-3 runtime-ID
queue shape and `.463` proves RLAST-gated dynamic read queue semantics.
Read-data over depth-3 queues, mixed dynamic/static queues, scoreboards,
arbitrary cardinality, direct backend behavior, backend-language variants,
external converter dependencies such as `sv2v`, and VHDL remain deferred;
FSMGen-owned generation/lowering remains the default. `.487` now selects
`.488`, direct bounded implementation of one generated all-dynamic read
burst-last `RID && RLAST` same-ID `issue-order-queue` with exactly three
dynamic read transactions, one-bit `last_signal`, `read-max-pending` at least
3, and queue depth 3. The readiness audit found only local planner, builder,
and RLAST scope-reporting gates. A direct helper probe produced 99 transition
rules, 20 assertions, zero duplicate names, the non-final no-dequeue
assertion, the slot2 onehot assertion, the `r2` completion-selected-match
assertion, the tail-selected recapture rule, and the disambiguated
cross-transaction enqueue rule. `.488` now ships that generated
three-transaction read burst-last `RID && RLAST` same-ID `issue-order-queue`
behavior through support-accounted public sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue.ppif`.
The response-demux report lists `r0`/`r1`/`r2`, generated
`axi0_r0_response_demux`/`axi0_r1_response_demux`/`axi0_r2_response_demux`
rules, generated completions, `generated_dynamic_issue_order_queue_demux_last_beat`,
and `read_rid_rlast_three_dynamic_transactions`. The generated queue
allocates three compact runtime-ID slots, gates completion and dequeue on
earliest matching captured `RID` plus one-bit `axi0_rlast`, keeps matching
non-final beats from dequeuing, and reports the slot2 onehot and `r2`
completion-selected-match assertions. Existing depth-2 RLAST queues,
depth-3 single-beat read queues, and depth-3 write queues remain unchanged.
Read-data over depth-3 queues, mixed dynamic/static queues, scoreboards,
arbitrary cardinality, direct backend behavior, backend-language variants,
external converter dependencies such as `sv2v`, and VHDL remain deferred;
FSMGen-owned generation/lowering remains the default. `.489` is the next
post-behavior selector. `.489` now selects `.490`, readiness audit for scalar
last-beat read-data over the generated all-dynamic read burst-last
`RID && RLAST` depth-3 same-ID `issue-order-queue` behavior shipped in
`.488`. The selector is next because `.488` now provides the missing
three-transaction queue-owned last-beat completion source, `.467`/`.469`/
`.471`/`.473` prove the two-transaction dynamic issue-order queue read-data
ladder, and the concrete depth-3 queue-head chain shows depth-3 read-data
needs explicit audit ownership before implementation. Mixed dynamic/static
queues, scoreboards, arbitrary cardinality, direct backend behavior,
backend-language variants, external converter dependencies such as `sv2v`,
and VHDL remain deferred; FSMGen-owned generation/lowering remains the
default. `.491` now ships scalar last-beat read-data over that generated
depth-3 dynamic RLAST queue through support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data.ppif`.
The generated capture covers `r0`, `r1`, and `r2`, binds each
`axi0_r*_read_data_capture` rule to the generated queue completion pulse,
captures `axi0_rdata`/`axi0_rresp` into `axi0_r*_last_rdata`/
`axi0_r*_last_rresp`, and reports
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`
with `read_rid_rlast_three_dynamic_transactions`. Raw `ARLEN`, runtime
beat-count/`RLAST` validation, multi-beat output banks, mixed dynamic/static
queues, scoreboards, arbitrary cardinality, direct backend behavior,
backend-language variants, external converter dependencies such as `sv2v`,
and VHDL remain deferred; FSMGen-owned generation/lowering remains the
default. `.492` now selects `.493`, readiness audit for report-only raw
`ARLEN` burst-length capture over that depth-3 dynamic RLAST queue
read-data. This is the smallest adjacent owner because `.491` supplies the
exact three-transaction scalar last-beat queue read-data surface, while
`.469` already proves report-only raw `ARLEN` over the two-transaction
dynamic RLAST queue. Runtime validation, multi-beat output banks, mixed
dynamic/static queues, scoreboards, arbitrary cardinality, verification-code
generation, direct backend behavior, backend-language variants, external
converter dependencies such as `sv2v`, and VHDL remain deferred;
FSMGen-owned generation/lowering remains the default. `.493` now selects
`.494`, direct bounded implementation of report-only raw `ARLEN` over that
same depth-3 dynamic RLAST queue read-data shape. The audit found only a
local dynamic issue-order queue read-data coverage gate: depth-2 queue
raw-`ARLEN` and depth-3 no-burst read-data are already supported, while the
generated burst-length storage/rule/report helpers already enumerate all
covered transactions. The RAM-guarded in-memory candidate failed closed at
that local diagnostic. Runtime validation, multi-beat output banks, mixed
dynamic/static queues, scoreboards, arbitrary cardinality,
verification-code generation, direct backend behavior, backend-language
variants, external converter dependencies such as `sv2v`, and VHDL remain
deferred; FSMGen-owned generation/lowering remains the default. `.494` now
ships that report-only raw `ARLEN` behavior through support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length.ppif`.
The generated `read-data.read` path keeps the queue-owned
`RID && RLAST` completion pulse, adds generated input `axi0_arlen`, stores raw
request-time length in `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and
`axi0_r2_arlen_q`, and emits `axi0_r*_burst_length_capture` rules for
`r0`/`r1`/`r2`. The report advertises
`burst_length_validation: report_only`,
`generated_burst_length_inputs: [axi0_arlen]`, and the three generated
storage/rule names. Runtime validation over this depth-3 queue, multi-beat
output banks over this depth-3 queue, mixed dynamic/static queues,
scoreboards, arbitrary cardinality, verification-code generation, direct
backend behavior, backend-language variants, external converter dependencies
such as `sv2v`, and VHDL remain deferred; FSMGen-owned generation/lowering
remains the default. `.495` now selects `.496`, readiness audit for runtime
beat-count/`RLAST` validation over that same depth-3 dynamic RLAST queue
raw-`ARLEN` read-data shape. This is the smallest adjacent owner because
`.494` supplies the exact three-transaction report-only raw-`ARLEN` queue
read-data surface, while `.471` already proves runtime beat-count/`RLAST`
validation over the two-transaction dynamic RLAST queue. Multi-beat output
banks, mixed dynamic/static queues, scoreboards, arbitrary cardinality,
verification-code generation, direct backend behavior, backend-language
variants, external converter dependencies such as `sv2v`, and VHDL remain
deferred; FSMGen-owned generation/lowering remains the default. `.496` now
selects `.497`, direct bounded implementation of runtime beat-count/`RLAST`
validation over that same depth-3 dynamic RLAST queue raw-`ARLEN` read-data
shape. The audit found only the local dynamic issue-order queue read-data
coverage gate: the unmodified runtime candidate failed closed at the existing
diagnostic, and a RAM-guarded out-of-tree one-line predicate overlay proved the
existing runtime helpers enumerate `r0`/`r1`/`r2` expected-beat storage,
read-beat counters, six rules, and twelve beat-count/`RLAST` assertion
names. Multi-beat output banks, mixed dynamic/static queues, scoreboards,
arbitrary cardinality, verification-code generation, direct backend
behavior, backend-language variants, external converter dependencies such as
`sv2v`, and VHDL remain deferred; FSMGen-owned generation/lowering remains
the default. `.497` now ships that selected runtime-validation behavior through
support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif`.
The generated path keeps queue-owned `RID && RLAST` completion and scalar
last-beat read-data capture, adds per-transaction expected-beat storage and
read-beat counters for `r0`/`r1`/`r2`, emits six beat-count init/increment
rules, and emits twelve `ARLEN`/beat-count/`RLAST` runtime assertions. The
read-data report advertises `burst_length_validation: runtime_assertion`,
`beat_count_validation_generated_behavior: true`, three
`generated_expected_beat_count_storage` entries, three
`generated_beat_count_storage` entries, six `generated_beat_count_rules`, and
twelve `generated_beat_count_assertions`. The `.494` report-only sample
remains supported and keeps runtime beat-count state absent. Multi-beat output
banks over this depth-3 queue, mixed dynamic/static queues, scoreboards,
arbitrary cardinality, verification-code generation, direct backend behavior,
backend-language variants, external converter dependencies such as `sv2v`, and
VHDL remain deferred; FSMGen-owned generation/lowering remains the default.
`.498` now selects `.499`, readiness audit for multi-beat output banks over
that same depth-3 dynamic RLAST queue runtime-validation read-data shape. This
is the smallest adjacent owner because `.497` supplies the exact
three-transaction runtime-validation queue read-data surface, while `.473`
already proves multi-beat output banks over the two-transaction dynamic RLAST
queue. Mixed dynamic/static queues, scoreboards, arbitrary cardinality,
verification-code generation, direct backend behavior, backend-language
variants, external converter dependencies such as `sv2v`, and VHDL remain
deferred; FSMGen-owned generation/lowering remains the default.
`.500` now ships that selected multi-beat output-bank behavior through
support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif`.
The generated path keeps queue-owned `RID && RLAST` completion, raw-`ARLEN`
capture, expected-beat storage, read-beat counters, six beat-count rules, and
twelve beat-count/`RLAST` runtime assertions, and adds per-transaction
multi-beat `RDATA`/`RRESP` output banks for `r0`/`r1`/`r2`, valid masks,
length outputs, scalar worst-observed `RRESP` aggregate outputs, output-init
rules, 48 lane-capture rules, and aggregate update rules. The read-data report
advertises `bounded_multi_beat_read_data_contract`, `capture_scope:
multi_beat`, response-demux matched-read-beat capture, runtime-assertion
burst-length validation, three generated valid-mask outputs, three generated
length outputs, 48 data outputs, 48 status outputs, and 48 capture rules.
Existing two-transaction dynamic queue multi-beat behavior, the `.494`
report-only depth-3 raw-`ARLEN` sample, and the `.497` depth-3 scalar
runtime-validation sample remain supported. Mixed dynamic/static queues,
scoreboards, arbitrary cardinality, verification-code generation, direct
backend behavior, backend-language variants, external converter dependencies
such as `sv2v`, and VHDL remain deferred; FSMGen-owned generation/lowering
remains the default.
`.501` now selects `.502`, readiness audit for generated mixed
dynamic/static write `BID` same-ID `issue-order-queue` behavior with exactly
one dynamic write transaction and one concrete static write transaction. It
changes no behavior. This is the smallest mixed queue owner after `.500`
closed the all-dynamic depth-3 queue/read-data ladder: write `BID` avoids
read-only `RLAST`, read-data, raw `ARLEN`, runtime beat-count validation, and
multi-beat output-bank complications. Optional external converter audits such
as `sv2v`, scoreboards, arbitrary cardinality, same-cycle widening,
verification-code generation, direct backend behavior, backend-language
variants, and VHDL remain deferred; FSMGen-owned generation/lowering remains
the default.
`.502` now audits that boundary and selects `.503`, direct bounded
implementation for exactly one dynamic write transaction plus one concrete
static write transaction. Parser support already accepts
`dynamic-id-reuse issue-order-queue`; a RAM-guarded temporary mixed write
candidate failed closed only at the local all-dynamic write queue planner
diagnostic requiring two or three all-dynamic write transactions. The direct
implementation is therefore local to mixed queue planning, report projection,
queue rule/assertion coverage, sample/support accounting, and focused tests.
External converter dependencies such as `sv2v`, mixed read queues,
multi-static or two-dynamic-plus-static queues, scoreboards, arbitrary
cardinality, backend behavior, backend-language variants, verification-code
generation, and VHDL remain deferred.
`.503` now ships generated mixed dynamic/static write `BID` same-ID
`issue-order-queue` behavior through support-accounted public sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue.ppif`.
The generated response-demux uses
`bounded_mixed_dynamic_static_write_bid_issue_order_queue_demux_contract`,
`generated_mixed_dynamic_static_issue_order_queue_demux`,
`earliest_matching_captured_or_static_runtime_id`, compact runtime-ID slots,
and `mixed_dynamic_static_issue_order_earliest_matching_slot`. Dynamic
enqueues store `axi0_awid`; static enqueues store the sized concrete literal
such as `4'd3`; static/dynamic runtime-ID overlap is allowed and ordered by
queue position. The same-ID ordering report uses
`generated_mixed_dynamic_static_write_bid_issue_order_queue`,
`generated_mixed_dynamic_static_issue_order_queue`,
`accepted_same_id_reuse: true`, `generated_scoreboard_behavior: false`,
`active_id_uniqueness_policy: not_required_for_issue_order_queue`, and
`static_id_conflict_policy: ordered_overlap_allowed`. Mixed read queues,
multi-static/two-dynamic mixed queues, scoreboards, arbitrary cardinality,
backend behavior, backend-language variants, verification-code generation,
external converter dependencies such as `sv2v`, and VHDL remain deferred;
FSMGen-owned generation/lowering remains the default.
`.504` now selects `.505`, readiness audit for generated mixed dynamic/static
read single-beat `RID` same-ID `issue-order-queue` behavior. This is the
smallest adjacent FSMGen-owned queue continuation after `.503`: it reuses the
one-dynamic plus one-concrete-static queue model and the all-dynamic read
single-beat `RID` queue model while avoiding mixed read burst-last
`RID && RLAST`, read-data, raw `ARLEN`, runtime validation, multi-beat output
banks, broader mixed cardinality, scoreboards, direct backend behavior,
backend-language variants, verification-code generation, external converter
dependencies such as `sv2v`, and VHDL. No parser, generator, PPIF sample,
support-accounting catalog, generated artifact, report JSON, test,
HDL/runtime behavior, backend behavior, external converter dependency, or
VHDL behavior changed in `.504`.
`.505` now audits that boundary and selects `.506`, direct bounded
implementation for exactly one dynamic read transaction plus one concrete
static read transaction. Parser support already accepts read
`dynamic-id-reuse issue-order-queue`; a RAM-guarded temporary mixed read
candidate fails closed only at the local all-dynamic read queue planner
diagnostic requiring exactly two all-dynamic read transactions, or exactly
three all-dynamic read transactions with single-beat or burst-last scope. The
direct implementation is therefore local to mixed read queue planning, read
response-demux projection, mixed queue coverage gating, report projection,
queue rule/assertion coverage, sample/support accounting, and focused tests.
External converter dependencies such as `sv2v`, mixed read burst-last queues,
read-data, raw `ARLEN`, runtime validation, multi-beat output banks, broader
mixed cardinality, scoreboards, backend behavior, backend-language variants,
verification-code generation, and VHDL remain deferred.
`.506` now ships generated mixed dynamic/static read single-beat `RID`
same-ID `issue-order-queue` behavior through support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue.ppif`.
The top-level response-demux report remains the aggregate
`bounded_response_demux_contract`, while `response_demux.read.mode` reports
`bounded_mixed_dynamic_static_read_rid_issue_order_queue_demux_contract`.
The generated read demux uses
`generated_mixed_dynamic_static_issue_order_queue_demux`,
`earliest_matching_captured_or_static_runtime_id`, compact runtime-ID slots,
`captured_or_static_request_id`, and
`mixed_dynamic_static_issue_order_earliest_matching_slot`. Dynamic enqueues
store `axi0_arid`; static enqueues store the sized concrete literal such as
`4'd3`; static/dynamic runtime-ID overlap is allowed and ordered by queue
position. The same-ID ordering report uses
`generated_mixed_dynamic_static_read_rid_issue_order_queue`,
`generated_mixed_dynamic_static_issue_order_queue`,
`accepted_same_id_reuse: true`, `generated_scoreboard_behavior: false`,
`active_id_uniqueness_policy: not_required_for_issue_order_queue`, and
`static_id_conflict_policy: ordered_overlap_allowed`. Mixed read burst-last
queues, read-data over this queue, raw `ARLEN`, runtime validation,
multi-beat output banks, multi-static/two-dynamic mixed queues, scoreboards,
arbitrary cardinality, backend behavior, backend-language variants,
verification-code generation, external converter dependencies such as `sv2v`,
and VHDL remain deferred; FSMGen-owned generation/lowering remains the
default.
`.507` now selects `.508`, readiness audit for generated mixed
dynamic/static read burst-last `RID && RLAST` same-ID `issue-order-queue`
behavior. This selector changes no behavior. The next audit is the smallest
adjacent owner because `.506` proves the queue-owned one-dynamic plus
one-static mixed read `RID` model, `.463` proves all-dynamic read burst-last
queue completion/dequeue semantics, and `.280` proves mixed read final
`RID && RLAST` response-demux matching. Read-data over mixed read queues, raw
`ARLEN`, runtime validation, multi-beat output banks, broader mixed
cardinality, scoreboards, backend behavior, backend-language variants,
verification-code generation, external converter dependencies such as `sv2v`,
and VHDL remain deferred; FSMGen-owned generation/lowering remains the
default.
`.508` now audits that boundary and selects `.509`, direct bounded
implementation of generated mixed dynamic/static read burst-last
`RID && RLAST` same-ID `issue-order-queue` behavior for exactly one dynamic
read transaction and one concrete static read transaction. A RAM-guarded
temporary candidate derived from the `.506` mixed read queue sample by
switching to `response-scope burst-last` and adding one-bit `axi0_rlast`
fails closed at the local planner diagnostic that still permits mixed
dynamic/static read issue-order queues only for `response_scope single-beat`.
No parser, IAL1, IAL0, SystemVerilog, backend-language, external converter,
verification-output, or VHDL prerequisite is required first. The direct
implementation is local to mixed read burst-last queue admission, last-beat
response-demux report projection, mixed queue behavior gating, report
vocabulary, sample/support accounting, and focused tests. Read-data over the
mixed queue, raw `ARLEN`, runtime validation, multi-beat output banks,
broader mixed cardinality, scoreboards, backend behavior, backend-language
variants, verification-code generation, external converter dependencies such
as `sv2v`, and VHDL remain deferred.
`.509` now ships that bounded mixed dynamic/static read burst-last
`RID && RLAST` same-ID `issue-order-queue` behavior through support-accounted
sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue.ppif`.
The generated queue stores `axi0_arid` for the dynamic enqueue and `4'd3` for
the static enqueue in the public sample, matches the earliest stored
captured-or-static `RID`, completes/dequeues only on the selected match plus
`axi0_rlast`, and emits the non-final no-dequeue assertion. Reports now expose
`bounded_mixed_dynamic_static_read_rid_rlast_issue_order_queue_demux_contract`,
`generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`,
`earliest_matching_captured_or_static_runtime_id_and_last_signal`,
`generated_mixed_dynamic_static_read_rid_rlast_issue_order_queue`, and
`read_rid_rlast_one_dynamic_one_static_transaction`. Read-data over the mixed
queue, raw `ARLEN`, runtime validation, multi-beat output banks, broader mixed
cardinality, scoreboards, backend behavior, backend-language variants,
verification-code generation, external converter dependencies such as `sv2v`,
and VHDL remain deferred.
`.510` now selects `.511`, public `.ppif` downstream-contract,
capability-manifest, and mdBook surface synchronization before any further
mixed queue behavior. The selector found the behavior-specific
`.503`/`.506`/`.509` surfaces current, but the downstream handoff, public
interface contract, embedding chapter, and `language_surface.file_surfaces`
`.ppif` manifest boundary do not yet advertise the generated mixed
dynamic/static same-ID `issue-order-queue` chain for write `BID`, read
single-beat `RID`, and read burst-last `RID && RLAST`. `.511` owns that
public-surface repair without parser/generator/sample/support-accounting,
generated-artifact, schedule/check/semantic JSON, HDL/runtime, backend,
external-converter, verification-output, or VHDL behavior changes. Mixed
read-data over these queues, raw `ARLEN`, runtime validation, multi-beat output
banks, broader mixed cardinality, scoreboards, backend behavior,
backend-language variants, verification-code generation, external converter
dependencies such as `sv2v`, and VHDL remain deferred.

`.511` now ships that public-surface synchronization. The downstream
integration spec, public interface contract, embedding chapter, and
`language_surface.file_surfaces` `.ppif` manifest boundary now advertise
generated one-dynamic plus one-concrete-static mixed dynamic/static same-ID
`issue-order-queue` behavior for write `BID`, read single-beat `RID`, and read
burst-last `RID && RLAST`. The manifest test now locks that boundary. The
later `.514` slice adds paired scalar read-data over the generated mixed read
single-beat and burst-last queue completions. `.516` adds report-only
raw-`ARLEN` burst-length capture over the generated mixed read burst-last queue
completion. `.518` now ships runtime beat-count/`RLAST` validation over that
same generated mixed read burst-last queue completion. Multi-beat output banks
over generated mixed dynamic/static issue-order queues remain deferred, as do
broader mixed cardinality, scoreboards, backend behavior, backend-language
variants, verification-code generation, external converter dependencies such as
`sv2v`, and VHDL. `.519` is the next readiness audit over mixed queue
multi-beat output banks.

`.512` now selects `.513`, readiness audit for scalar read-data routing over
generated mixed dynamic/static read same-ID `issue-order-queue` completion
pulses. The selector follows the prior all-dynamic queue and mixed
response-demux ladders: scalar read-data over generated read completion pulses
is the next smallest user-visible gap before raw `ARLEN`, runtime validation,
multi-beat output banks, broader mixed cardinality, scoreboards, backend
behavior, backend-language variants, verification-code generation, external
converter dependencies such as `sv2v`, or VHDL. `.512` changes no parser,
generator, PPIF sample, support-accounting catalog, generated artifact,
schedule/check/semantic JSON, test, HDL/runtime behavior, backend behavior,
external converter dependency, verification-output, or VHDL behavior.

`.513` now audits that scalar read-data boundary and selects `.514`, direct
bounded implementation of paired scalar read-data routing over generated mixed
dynamic/static read same-ID `issue-order-queue` completions. Temporary
single-beat and burst-last candidates parsed to the current read-data coverage
fallback, showing no parser, source-shape, IAL1, IAL0, backend, or VHDL
prerequisite; the remaining work is local to read-data coverage, report,
sample, support-accounting, and public-doc surfaces for
`generated_mixed_dynamic_static_issue_order_queue_demux` and
`generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`. Raw
`ARLEN`, runtime validation, multi-beat output banks, broader mixed
cardinality, scoreboards, backend behavior, backend-language variants,
verification-code generation, external converter dependencies such as `sv2v`,
and VHDL remain deferred. `.513` changes no parser, generator, PPIF sample,
support-accounting catalog, generated artifact, schedule/check/semantic JSON,
test, HDL/runtime behavior, backend behavior, external converter dependency,
verification-output, or VHDL behavior.

`.514` now ships paired scalar read-data routing over the generated mixed
dynamic/static read same-ID `issue-order-queue` completions. The
support-accounted public samples are
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue_read_data.ppif`
and
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data.ppif`.
Both shapes use exactly one dynamic read transaction plus one concrete static
read transaction, one depth-2 generated mixed queue, existing scalar
`read-data.read` syntax, complete scalar `RDATA`/`RRESP` output bindings, and
queue-specific completion-validity names
`generated_mixed_dynamic_static_read_issue_order_queue_response_demux_completion_pulse`
or
`generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse`.
Raw `ARLEN`, runtime validation, multi-beat output banks, broader mixed
cardinality, scoreboards, backend behavior, backend-language variants,
verification-code generation, external converter dependencies such as `sv2v`,
and VHDL remain deferred. `.515` is the raw-`ARLEN` burst-length readiness
audit over the mixed burst-last queue read-data path.

`.515` now audits that raw-`ARLEN` boundary and selects `.516`, direct bounded
implementation of report-only raw-`ARLEN` burst-length capture over generated
mixed dynamic/static read burst-last same-ID `issue-order-queue` scalar
read-data. A temporary candidate that added existing `burst-length` metadata
to the `.514` burst-last sample reached the local mixed queue read-data
coverage branch and failed only because that branch still requires no
`burst_length` metadata. The selected `.516` sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif`.
Runtime validation is now covered by `.517`/`.518`; multi-beat output banks,
broader mixed cardinality, scoreboards, backend behavior,
backend-language variants, verification-code generation, external converter
dependencies such as `sv2v`, and VHDL remain deferred.

`.518` now ships runtime beat-count/`RLAST` validation over generated mixed
dynamic/static read burst-last same-ID `issue-order-queue` scalar last-beat
read-data with raw-`ARLEN` capture. The public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif`.
The slice admits only the `.516` depth-2 mixed queue shape with exactly one
dynamic read plus one concrete static read, complete scalar last-beat
`RDATA`/`RRESP` bindings, runtime-assertion raw-`ARLEN` metadata, per-transaction
expected-beat/read-beat-count storage, eight beat-count/`RLAST` assertions, and
completion validity
`generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse`.
Multi-beat output banks, broader mixed cardinality, scoreboards, backend
behavior, backend-language variants, verification-code generation, external
converter dependencies such as `sv2v`, and VHDL remain deferred. `.519` is the
multi-beat output-bank readiness audit over this mixed queue path.

`.519` now selects `.520`, direct bounded implementation of multi-beat output
banks over the `.518` mixed queue runtime-validation read-data path. Source
inspection found the remaining blocker local to
`_read_data_response_demux_transaction_coverage`: the mixed dynamic/static
issue-order queue branch does not yet list `capture-scope multi-beat` or require
runtime-assertion `burst-length` metadata for that multi-beat queue shape. Shared
parser syntax, normalization, report metadata, output-bank rule generation,
status aggregation, beat-count/`RLAST` assertions, response-state lookup, and
test helper vocabulary are already present. The selected `.520` sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif`.
Broader mixed cardinality, scoreboards, backend behavior,
backend-language variants, verification-code generation, external converter
dependencies such as `sv2v`, and VHDL remain deferred.

`.520` now ships multi-beat output banks over generated mixed dynamic/static
read burst-last same-ID `issue-order-queue` runtime-validation read-data. The
support-accounted public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif`.
The shipped boundary remains exact: one dynamic read plus one concrete static
read, one depth-2 generated mixed queue, generated burst-last queue completion
source `generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`,
`capture-scope multi-beat`, runtime-assertion raw-`ARLEN` burst-length
metadata, complete per-transaction data/status output banks, scalar
worst-observed `RRESP` aggregate outputs, valid-mask outputs, length outputs,
and completion validity
`generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse`.
The read-data report residue is empty for this bounded queue-owned shape.
Broader mixed issue-order queue cardinality, scoreboards, backend behavior,
backend-language variants, verification-code generation, external converter
dependencies such as `sv2v`, and VHDL remain deferred. `.522` now selects
`.523`, readiness audit for one-dynamic plus two-concrete-static mixed
dynamic/static write `BID` same-ID issue-order queue behavior. `.523` now
selects `.524`, direct bounded implementation for that one-dynamic plus
two-concrete-static write queue shape. The audit found the current candidate
fails closed only at the local mixed write issue-order queue
planner/materializer boundary, while lower queue transition, assignment,
assertion, storage, and report helpers are already transaction-list driven.
No parser, IAL1, IAL0, SystemVerilog, backend, external converter, or VHDL
prerequisite is required before the bounded `.524` implementation. `.524` now
ships generated mixed dynamic/static write `BID` same-ID `issue-order-queue`
behavior for one dynamic write plus two pairwise-distinct concrete static
writes through support-accounted public sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static.ppif`.
The generated queue remains FSMGen-owned, uses compact runtime-ID slots of
depth three, enqueues `axi0_awid`, `4'd3`, and `4'd5`, reports
`write_bid_one_dynamic_two_static_transactions`, and preserves the `.503`
one-static mixed queue plus all-dynamic write depth-2/depth-3 queues. Broader
read queue cardinality, read-data, raw `ARLEN`, runtime validation,
multi-beat output banks, scoreboards, arbitrary mixed cardinality,
group-local simultaneous enqueue widening, backend behavior,
verification-output generation, backend-language variants, external converter
dependencies such as `sv2v`, and VHDL remain deferred.
`.525` now selects `.526`, readiness audit for the IAL2 protocol/platform
generality guardrail before more profile-specific implementation. AXI is the
first shipped IAL2 profile/example, not the definition of IAL2. Common IAL2
constructs remain protocol/platform-generic and AXI-specific vocabulary stays
profile-local unless compatible reuse is proven across multiple profiles.
`.526` now selects `.527`, public-surface cleanup for that IAL2
protocol/platform generality guardrail. The audit found the architecture
records correct and the remaining risk in downstream/public capability
boundary wording: public `.ppif` surfaces should lead with AXI as the first
shipped IAL2 profile/example, not the IAL2 definition.
`.527` now synchronizes the public `.ppif` contract, downstream handoff, and
capability-manifest language-surface boundary with that guardrail and selects
`.528`, post-guardrail IAL2 next-slice selection. Public `.ppif` surfaces now
lead with AXI as the first shipped IAL2 profile/example, not the IAL2
definition; future protocol-specific suffixes are profile aliases over IAL2;
and common IAL2 constructs stay small until compatible reuse is proven across
profiles.
`.528` now selects `.529`, readiness audit for a protocol-neutral/non-AXI
Valid-Ready `.ppif` example boundary. The selector deliberately does not
return to another AXI behavior slice before auditing the existing
Valid-Ready family as the next small IAL2 generality exercise.
`.529` now selects `.530`, public contract selection for a
protocol-neutral/non-AXI Valid-Ready `.ppif` profile and source-vocabulary
boundary. The audit found that `.ppif` is the generic IAL2 container, but the
current Valid-Ready implementation path still requires a profile clause and
accepts only AXI protocol names plus AXI channel families. A non-AXI or
protocol-neutral Valid-Ready sample therefore needs public vocabulary
selection before parser, generator, sample, support-accounting, or report
changes.
`.530` now selects `.531`, direct bounded implementation of the first
protocol-neutral/non-AXI Valid-Ready `.ppif` sample. The selected contract
keeps `(profile valid-ready)` explicit and required, keeps no-profile input
unsupported, uses `ppif/valid_ready_handshake.ppif` with support identity
`intent.ppif_valid_ready_handshake`, treats `(channel data_link)` as an
authored logical channel identifier rather than an AXI family, selects
`producer-to-consumer` as the first neutral role, and introduces no `.axi` or
other suffix alias.
`.531` now ships that first protocol-neutral/non-AXI Valid-Ready `.ppif`
sample. `ppif/valid_ready_handshake.ppif` lowers through generated
`data_link_valid_ready_monitor.isf` and `data_link_valid_ready_monitor.fsm`,
reports `target_channel.protocol = "valid-ready"`,
`target_channel.family = "data_link"`, and
`target_channel.role = "producer-to-consumer"`, and is support-accounted as
`intent.ppif_valid_ready_handshake`. Existing AXI Valid-Ready, AXI AW/W
bundle, AXI manager capacity/status, unsupported suffix aliases, direct
backend, verification-output, backend-language variant, and VHDL boundaries
remain unchanged.
`.532` now selects `.533`, readiness audit for protocol-neutral/non-AXI
Valid-Ready `.ppif` bundles. This is the next smallest IAL2 generality owner
because `.531` deliberately kept `(profile valid-ready)` multi-channel bundles
fail-closed while the existing aggregate bundle path is shipped only through
the AXI AW/W profile sample. No behavior changes in `.532`.
`.533` now selects `.534`, public contract selection for a bounded
protocol-neutral/non-AXI Valid-Ready `.ppif` bundle. The audit found no
separate aggregate wrapper/top prerequisite, but direct implementation would
still force public choices into code: sample/support identity, both neutral
roles, source-anchor inheritance, generic aggregate residue, docs/manifest
wording, and RAM-guard-friendly validation. No behavior changes in `.533`.
`.534` now selects `.535`, direct bounded implementation of
`ppif/valid_ready_dual_channel_bundle.ppif`. The contract keeps explicit
`(profile valid-ready)`, selects support identity
`intent.ppif_valid_ready_dual_channel_bundle`, exercises both neutral roles,
preserves the aggregate `valid_ready_bundle.v1` schema, requires generic
neutral aggregate residue instead of AXI manager residue, and preserves the
AXI AW/W bundle boundary. No behavior changes in `.534`.
`.535` now ships that protocol-neutral/non-AXI Valid-Ready `.ppif` bundle.
`ppif/valid_ready_dual_channel_bundle.ppif` lowers through generated
`data_downstream_valid_ready_monitor.isf`,
`status_upstream_valid_ready_monitor.isf`, their generated `.fsm` monitors,
and the aggregate wrapper/top `valid_ready_dual_channel_bundle.fsm`.
Schedule/check/semantic JSON report support identity
`intent.ppif_valid_ready_dual_channel_bundle`, both neutral roles,
one inherited channel source, generic aggregate residue
`valid_ready_profile_bundle_behavior_outside_monitor`, and no AXI manager
residue. Existing AXI AW/W bundle behavior still reports its AXI-profile
`axi_manager_concurrency` residue.
`.536` now selects `.537`, readiness audit for future IAL2 profile-alias file
suffixes after the neutral one-channel and dual-channel Valid-Ready `.ppif`
examples shipped. The selector is not an `.axi` implementation selection; it
audits how future suffixes such as `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`,
`.atb`, `.smbus`, or `.i2s` can remain aliases over the same IAL2 model
without changing `.ppif` behavior, support accounting, reports, source paths,
or mandatory `IAL2 -> IAL1 -> IAL0` lowering.
`.537` now selects `.538`, public unsupported-alias inventory synchronization
before any profile-alias suffix implementation. The audit found that `.axi`,
`.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` are valid future
profile-alias candidates over IAL2, but the shipped CLI still accepts only
`.fsm`, `.isf`, and `.ppif` as source suffixes, the PPIF adapter requires a
`.ppif` path, and the manifest unsupported-alias inventory must be aligned with
the public boundary prose before any suffix behavior changes.
`.538` synchronized that pre-`.540` public inventory: at that point the
capability manifest kept `.pif`, `.ppi`, `.axi`, `.chi`, `.ace`, `.ahb`,
`.apb`, `.atb`, `.smbus`, and `.i2s` unsupported in the first IAL2 public
file-surface slice. The shipped source suffixes were still `.fsm`, `.isf`, and
`.ppif`; no profile-alias suffix was accepted until `.540`. `.538` selected
`.539`, public contract selection for the first IAL2 profile-alias suffix.
`.539` now selects `.540`, direct bounded implementation of `.axi` as the first
IAL2 profile-alias suffix. The selected alias mirrors
`ppif/axi_aw_valid_ready.ppif` at `ppif/axi_aw_valid_ready.axi`, requires an
explicit AXI-family profile such as `(profile axi4)`, and remains an IAL2 alias
that lowers through generated `.isf` before generated `.fsm`. This is only the
first profile-alias example; it does not make IAL2 AXI-only.
`.540` now ships that `.axi` profile-alias behavior for the selected AXI AW
Valid-Ready sample. `ppif/axi_aw_valid_ready.axi` uses the same IAL2
`protocol-platform-intent` shape as `.ppif`, must declare an explicit
AXI-family profile (`axi`, `axi3`, `axi4`, or `axi5`), and lowers through the
reviewable `axi_aw_valid_ready_monitor.isf` and
`axi_aw_valid_ready_monitor.fsm` artifacts before HDL generation. Check JSON
and semantic JSON keep the authored `.axi` path and support-account the sample
as `intent.axi_profile_alias_aw_valid_ready` with source kind
`ial2_profile_alias`. `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`,
`.i2s`, `.pif`, and `.ppi` remain unsupported; `.ppif` remains the generic
IAL2 container and AXI remains only the first profile-alias example.
`.541` now selects `.542`, a post-`.axi` IAL2 generality readiness audit before
another behavior implementation. It also corrects Knowledge Map routing so
current `.axi` acceptance questions point to the shipped `.540` behavior card,
while older profile-alias readiness and inventory cards are historical
pre-implementation facts. The next owner must choose from neutral/profile-
generic evidence and must not treat AXI as all of IAL2.
`.542` now selects `.543`, public-surface historical wording sync for the
post-`.axi` profile-alias chronology. The audit found code, manifest,
support-accounting, and Knowledge Map routing current after `.540`/`.541`; the
remaining prerequisite is to make pre-`.540` mdBook wording around `.537` and
`.538` explicitly historical before selecting another behavior owner.
`.543` now completes that public wording sync: README, ROADMAP_V2, and mdBook
make the `.537`/`.538` profile-alias readiness and unsupported-inventory
wording explicitly historical pre-`.540` state, while current `.axi` behavior
and remaining unsupported aliases stay clear. AXI remains the first shipped
profile-alias example, not the definition or full scope of IAL2. No behavior
changed in `.543`.
`.544` now selects `.545`, a non-AXI profile-alias readiness audit after the
public chronology sync. The next owner is deliberately not another AXI
implementation: it must audit `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`,
`.smbus`, `.i2s`, `.pif`, and `.ppi` readiness or prerequisites without
accepting any new suffix or changing behavior.
`.545` now selects `.546`, a non-AXI profile-alias taxonomy and evidence
prerequisite. The audit found no non-AXI protocol suffix ready for contract
selection: `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` still
lack source-shape, profile-matching, report, support-accounting, and mdBook
evidence, while `.pif` and `.ppi` remain generic-container candidates rather
than protocol aliases.
`.546` now selects `.547`, a generic-container alias policy selection for
`.pif` and `.ppi`. The taxonomy records that `.ppif` is the shipped generic
IAL2 container, `.pif` and `.ppi` are generic-container spelling candidates,
and `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` are
protocol-profile alias candidates that still lack contract evidence.
Protocol-neutral `(profile valid-ready)` under `.ppif` remains the current
non-AXI IAL2 evidence; it proves IAL2 is not AXI-only but does not define a
protocol suffix contract.
`.547` keeps `.pif` and `.ppi` explicitly unsupported historical
generic-container spellings and selects `.548`, an APB IAL2 source-shape
readiness audit. `.ppif` remains the only shipped generic IAL2 container.
The next APB owner must audit whether existing APB lower-layer fixtures are
enough for an APB `.ppif` source-shape contract, a lower-layer prerequisite, a
report/support-accounting prerequisite, or deferral; it must not accept `.apb`
or add APB `.ppif` behavior.
`.548` now selects `.549`, APB `.ppif` source-shape public contract
selection. The audit found that APB has enough lower-layer evidence in the
existing ISF requester, requester/completer FSMs, composition top, mdBook
examples, and support catalog to choose a public IAL2 source-shape contract
before implementation. At `.548` closeout, that evidence was not yet an IAL2
behavior contract: `.apb` remained unsupported, no APB `.ppif` sample existed,
and report/support-accounting identities still needed selection before behavior
changes.
`.549` now selects `.550`, direct bounded implementation of the first APB
`.ppif` source shape. The selected source uses `(profile apb)` and one
`(apb-requester apb_requester ...)` object, selects the future sample
`ppif/apb_requester_transfer.ppif`, support identity
`intent.ppif_apb_requester_transfer`, generated review artifacts
`apb_requester.isf` and `apb_requester.fsm`, and report schema
`fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`. `.apb` remains
unsupported.
`.550` now ships that APB `.ppif` requester-transfer first slice. The sample
`ppif/apb_requester_transfer.ppif` parses `(profile apb)` with one
`(apb-requester apb_requester ...)` object, emits report schema
`fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`, generates review
artifacts `apb_requester.isf` and `apb_requester.fsm` through IAL1 before
IAL0, reaches HDL module `apb_requester`, and support-accounts
`intent.ppif_apb_requester_transfer`. `.apb` and all other new suffixes remain
unsupported; APB is a `.ppif` profile behavior, not an AXI extension.
`.551` now selects `.552`, an APB `.apb` profile-alias readiness audit. The
selector found that `.550` creates enough generic `.ppif` APB evidence to
audit `.apb` alias readiness, but direct `.apb` implementation still needs a
separate public file-surface contract for explicit profile matching,
source-path/report identity, support accounting, manifest wording,
diagnostics, and generated `.isf` review artifacts before generated `.fsm`.
`.552` now selects `.553`, APB `.apb` public profile-alias contract
selection. The audit found APB is ready for contract selection because the
shipped `.ppif` requester-transfer path already locks profile `apb`,
`apb-requester` vocabulary, generated `apb_requester.isf` and
`apb_requester.fsm` review artifacts, report schema, strict check JSON,
semantic JSON, and support accounting. At `.552` closeout, `.apb` remained
unsupported until a separate contract and implementation owner settled explicit
profile policy, authored `.apb` source identity, support-accounting
identity/source kind, manifest wording, diagnostics, and mandatory generated
`.isf` review preservation.
`.553` now selects `.554`, direct bounded implementation of the first APB
`.apb` profile-alias suffix. The selected contract mirrors
`ppif/apb_requester_transfer.ppif` at future path
`ppif/apb_requester_transfer.apb`, keeps explicit `(profile apb)` with no
suffix inference, lowers through generated `apb_requester.isf` before
`apb_requester.fsm`, support-accounts the alias as
`intent.apb_profile_alias_requester_transfer` with source kind
`ial2_profile_alias`, and reserves focused
`t/1470-ial2-apb-profile-alias.t` coverage. At `.553` closeout, `.apb`
remained unsupported until `.554` implemented the contract.
`.554` now ships that bounded APB `.apb` profile-alias requester-transfer
behavior. The sample `ppif/apb_requester_transfer.apb` uses explicit
`(profile apb)` with one `(apb-requester apb_requester ...)` object, lowers
through generated `apb_requester.isf` before `apb_requester.fsm`, preserves the
authored `.apb` source path in check JSON and semantic JSON, reaches HDL module
`apb_requester`, and support-accounts
`intent.apb_profile_alias_requester_transfer` with source kind
`ial2_profile_alias`. `.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`, `.i2s`,
`.pif`, and `.ppi` remain unsupported aliases, and APB completer/interconnect
generation, sidebands, alternate widths, multi-peripheral decode,
back-to-back policy, direct backend lowering, verification-output generation,
backend-language variants, and VHDL remain deferred.
`.555` now selects `.556`, a no-behavior public-surface sync after APB `.apb`
profile-alias support shipped. The next owner must make current `.axi`
behavior/fact wording stop listing `.apb` as unsupported after `.554`, while
preserving historical pre-`.554` closeout wording and keeping `.chi`, `.ace`,
`.ahb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` unsupported.
`.556` now completes that public-surface sync. Current profile-alias surfaces
list `.axi` and `.apb` as shipped bounded aliases, keep `.chi`, `.ace`,
`.ahb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` unsupported, and
preserve pre-`.554` `.apb`-unsupported wording only as dated history. `.556`
selects `.557`, the next exact IAL2 owner selector after the sync.
`.557` now selects `.558`, a no-behavior readiness audit for APB
completer/interconnect generation. The selector reverified the supported APB
completer fixture, the APB requester-to-completer composition top, and the
current `.apb` requester-transfer schedule/check path, then chose the explicit
`apb_completer_and_interconnect_generation_deferred` residue for audit before
any APB expansion behavior.
`.558` now selects `.559`, APB completer/interconnect public contract
selection. The audit found the lower-layer APB completer and requester-to-
completer composition fixtures plus current APB IAL2 requester-transfer
residue are sufficient for a contract selector, but direct behavior still needs
owned decisions for source vocabulary, completer/interconnect split policy,
mandatory generated `.isf` before `.fsm` artifacts, aggregate top shape,
report/support-accounting identities, diagnostics, and `.ppif` versus `.apb`
exposure.
`.559` now selects `.560`, APB completer generated-IAL1 substrate audit. The
contract splits the combined APB completer/interconnect residue: first select
`.ppif` APB completer generation with future sample `ppif/apb_completer.ppif`,
object `(apb-completer apb_completer ...)`, generated `apb_completer.isf`
before `apb_completer.fsm`, report schema
`fsmgen.ial2.protocol_intent.apb_completer.v1`, and future support identity
`intent.ppif_apb_completer`; APB interconnect/composition and `.apb`
completer alias exposure remain deferred until later owners.
`.560` now selects `.561`, IAL1 expression entry-activation guard rendering
repair before APB completer behavior. The audit found generated-IAL1 substrate
pieces for no-public-done target transactions, runtime `wait_cycles`, storage
reset/update, address-dependent read/write state, `PSLVERR`, and generated
report/artifact structure. At `.560` closeout, direct APB `.ppif` completer
implementation was blocked because `(when EXPR (sample ...))` entry guards
lowered to invalid generated `.fsm` guard suffixes containing `ARRAY(...)`.
The APB setup detector requires `PSEL && !PENABLE`, so `.561` was selected to
repair IAL1 guard serialization before any APB completer parser/generator/
sample/support change.
`.561` now ships that IAL1 guard serialization repair. First-clause
`(when EXPR (sample ...))` entry activation stores rendered `.fsm` expression
guard text for sample enables and entry transitions while preserving the
structured expression AST for internal analysis. Scalar entry guards, existing
when-body behavior, and runtime-wait behavior remain covered by focused tests.
`.562` now ships the first generated APB `.ppif` completer behavior. The
sample `ppif/apb_completer.ppif` uses explicit `(profile apb)` with one
`(apb-completer apb_completer ...)` object, lowers through generated
`apb_completer.isf` before generated `apb_completer.fsm`, emits report schema
`fsmgen.ial2.protocol_intent.apb_completer.v1`, and support-accounts
`intent.ppif_apb_completer`. The bounded subset covers setup detection
`PSEL && !PENABLE`, runtime `wait_cycles`, address-0 register read/write, and
unmapped-address `PSLVERR`. At `.562` closeout `.apb` remained requester-
transfer only; `.569` later exposes the same bounded completer through
`ppif/apb_completer.apb`. APB interconnect/composition, sidebands, alternate
widths, multi-register decode, back-to-back policy, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, and
VHDL remain deferred.
`.563` now selects `.564`, a no-behavior APB interconnect/composition
readiness audit after generated APB requester and completer `.ppif` endpoints
both exist. The selector reverified the completer `.ppif`, requester `.ppif`,
requester `.apb`, lower-layer completer, and lower-layer APB composition
surfaces, then chose the `apb_interconnect_generation_deferred` residue for
audit. APB completer `.apb` alias exposure, multi-register decode, sidebands,
alternate widths, back-to-back policy, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, and
VHDL remain deferred.
`.564` now selects `.565`, APB interconnect/composition public contract
selection. The readiness audit found contract selection is justified because
generated APB `.ppif` requester and completer endpoint paths both exist and
the strict-supported lower-layer `fsm/apb_tb.fsm` target already wires
`apb_requester` to `apb_completer` through the APB bus. Direct interconnect
implementation, APB completer `.apb` alias exposure, multi-register decode,
sidebands, alternate widths, back-to-back policy, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, and
VHDL remain deferred until a public composition contract is selected.
`.565` now selects `.566`, direct bounded APB `.ppif` composition
implementation. The selected first contract is `ppif/apb_composition.ppif`
with top-level intent `apb_composition`, exactly one embedded
`(apb-requester apb_requester ...)`, exactly one embedded `(apb-completer
apb_completer ...)`, and one explicit `(apb-composition apb_tb ...)` object
that references those endpoints. It generates `apb_requester.isf`,
`apb_requester.fsm`, `apb_completer.isf`, `apb_completer.fsm`, and
`apb_tb.fsm`, selects report schema
`fsmgen.ial2.protocol_intent.apb_composition.v1`, and support-accounts
`intent.ppif_apb_composition`. At `.565`/`.566` closeout, requester `busy`
exposure, `.apb` composition/completer aliases, multi-peripheral
interconnect/decode, multi-register decode, sidebands, alternate widths,
back-to-back policy, direct backend lowering, verification-output generation,
backend-language variants, AXI behavior, and VHDL remained deferred; `.569`
later ships the completer and fixed-composition `.apb` aliases.
`.566` now ships that APB `.ppif` composition behavior. The sample
`ppif/apb_composition.ppif` lowers one embedded APB requester and one embedded
APB completer through generated `apb_requester.isf`,
`apb_completer.isf`, `apb_requester.fsm`, `apb_completer.fsm`, and
`apb_tb.fsm`; selects `apb_tb.fsm` as the HDL entry; emits report schema
`fsmgen.ial2.protocol_intent.apb_composition.v1`; and support-accounts
`intent.ppif_apb_composition` with semantic source root kind `top`. The top
exposes `start`, request fields, `wait_cycles`, `done`, `last_error`, and
`last_read_data`, but not requester `busy`. `.566` selects `.567`, the next
no-behavior APB surface selector after shipped requester, completer, and fixed
composition `.ppif` paths.
`.567` now selects `.568`, APB `.apb` profile-alias public contract selection
for APB completer and fixed APB requester/completer composition sources. The
selector confirmed requester-transfer `.apb`, completer `.ppif`, and
composition `.ppif` still pass, while temporary completer/composition `.apb`
copies failed closed with the requester-transfer-only alias diagnostic at
`.567` closeout. No behavior changed in `.567`; exact `.apb` sample paths,
support identities, source-kind behavior, diagnostics, and validation scope
were selected in `.568` before `.569` implemented alias widening.
`.568` now selects `.569`, direct bounded implementation of APB `.apb`
profile-alias widening for shipped APB completer and fixed APB composition
sources. The selected future samples are `ppif/apb_completer.apb` and
`ppif/apb_composition.apb`, both retaining explicit `(profile apb)`,
generated `.isf`/`.fsm` review artifacts, authored `.apb` source identity in
check/semantic JSON, and source kind `ial2_profile_alias`. The selected
support identities are `intent.apb_profile_alias_completer` and
`intent.apb_profile_alias_composition`; the composition alias keeps `apb_tb`
as semantic top with children `apb_requester` and `apb_completer`. No behavior
changed in `.568`; `.569` owns the parser/sample/support/test/docs behavior
widening, while multi-peripheral interconnect/decode, requester busy/status,
multi-register decode, sidebands/strobes, alternate widths, back-to-back
policy, direct backend, verification-output, backend-language variants, AXI,
and VHDL remain deferred.
`.569` now ships that bounded APB `.apb` alias widening. The public aliases
`ppif/apb_completer.apb` and `ppif/apb_composition.apb` mirror the shipped
generic `.ppif` completer and fixed requester/completer composition sources,
preserve authored `.apb` source identity in check and semantic JSON, lower
through the same generated `.isf` and `.fsm` review artifacts, and
support-account as `intent.apb_profile_alias_completer` and
`intent.apb_profile_alias_composition` with source kind `ial2_profile_alias`.
The `.apb` suffix now accepts exactly requester-transfer, completer, and fixed
one-requester/one-completer composition APB shapes; missing profile,
non-APB profile, non-APB objects, and implicit mixed requester/completer
sources still fail closed. `.569` selects `.570`, the next no-behavior APB
surface selector after requester/completer/composition `.apb` alias coverage
shipped.
`.570` now selects `.571`, APB requester busy/status public contract
selection, without changing behavior. Current generated APB requester and
fixed composition IAL2 reports expose `done`, `last_error`, and
`last_read_data` while carrying `apb_requester_busy_status_deferred`;
lower-layer hand-authored `fsm/apb_requester.fsm` and `fsm/apb_tb.fsm`
already expose `busy`. The next owner must decide exact source syntax,
whether the first widening exposes only `busy` or also a named status field,
generated `.isf`/`.fsm` review artifacts, fixed composition top-port
propagation, support/report/residue/docs updates, diagnostics, validation, and
rollback before any parser or generator behavior changes.
The APB-shaped `PSEL && !PENABLE` setup detector now lowers without
`ARRAY(...)`, and direct APB `.ppif` completer implementation is routed to
`.562` without adding APB behavior in `.561`.

No behavior
changed in `.273`, `.274`, `.275`,
`.277`, `.278`, `.279`, `.281`,
`.282`, `.283`, `.285`, `.286`, `.288`, `.290`, `.292`, `.293`, `.294`, `.296`, `.297`, `.298`, `.300`, `.301`, `.302`, `.304`, `.305`, `.306`, `.308`, `.309`, `.311`, `.313`, `.315`, `.316`, `.317`, `.323`, `.324`, `.325`, `.327`, `.328`, `.329`, `.331`, `.332`, `.334`, `.336`, `.338`, `.339`, `.340`, `.342`, `.343`, `.345`, `.346`, `.348`, `.349`, `.351`, `.352`, `.354`, `.356`, `.358`, `.359`, `.360`, `.362`, `.363`, `.364`, `.366`, `.367`, `.369`, `.370`, `.371`, `.373`, `.374`, `.376`, `.377`, `.379`, `.380`, `.382`, `.383`, `.384`, `.386`, `.387`, `.388`, `.390`, `.391`, `.393`, `.394`, `.395`, `.397`, `.398`, `.399`, `.401`, `.402`, `.404`, `.405`, `.406`, `.408`, `.409`, `.410`, `.412`, `.413`, `.414`, `.416`, `.417`, `.418`, `.420`, `.421`, `.422`, `.424`, `.425`, `.426`, `.428`, `.429`, `.430`, `.432`, `.433`, `.434`, `.435`, `.437`, `.470`, `.472`, `.474`, `.475`, `.476`, `.492`, `.493`, `.495`, `.496`, `.498`, `.499`, `.504`, `.510`, `.511`, `.512`, `.513`, `.515`, `.517`, `.519`, `.521`, `.522`, `.523`, `.525`, `.526`, `.527`, `.528`, `.529`, `.530`, `.532`, `.533`, `.534`, `.536`, `.537`, `.539`, `.541`, `.542`, `.543`, `.544`, `.545`, `.546`, `.547`, `.548`, `.549`, `.551`, `.552`, `.553`, `.555`, `.556`, `.557`, `.558`, `.559`, `.560`, `.563`, `.564`, `.565`, `.567`, `.568`, or `.570`.
Current primary target is SystemVerilog, with Verilog conversion support and a scoped direct-root VHDL scaffold for the accepted single-FSM subset, including delayed-pulse clock-branch lowering, generic-bearing direct-root module headers with typed scalar/vector sized-literal defaults, signed vector and signed scalar direct-root ports, scalar/vector two-state `bit` input-port and internal declaration lowering, signed scalar/vector, non-signed four-state `logic` input-port/internal declaration lowering, and vector `logic signed` internal declaration lowering, scalar and signed scalar addition/subtraction/multiplication RHS/chain lowering, vector numeric-literal addition/subtraction emitted by compound update/shorthand forms, same-width unsigned-style addition/subtraction/multiplication/division/modulo/XOR RHS/chain lowering, same-width signed vector addition/subtraction/multiplication/division/modulo RHS lowering for signed targets and operands, signed vector numeric-literal addition/subtraction/multiplication/division/modulo RHS lowering including signed vector negative decimal addition, subtraction, multiplication, division, and modulo literals, non-signed vector positive decimal multiplication/division/modulo literal lowering in signal-first, literal-first, and literal-literal order, non-signed vector negative decimal addition/subtraction/multiplication/division/modulo literal lowering, bounded generated AMBA wrap arithmetic for `fsm/amba_requester.fsm`, bounded non-signed vector, signed vector, and scalar output-port decimal literal assignment lowering including non-signed vector, signed vector, and scalar negative decimal literals, bounded direct aggregate-output packed-vector lowering, a bounded C3 external-RTL literal/concat composition VHDL structural top for `t/corpus/composition_intent_integer_literals.fsm`, bounded external-RTL scalar integer, scalar integer expression, one-bit sized bitstring, multi-bit sized bitstring, and resolved packed aggregate VHDL generic maps including resolved package-backed constants, a bounded C1 standalone-DT child composition VHDL passthrough top for `t/corpus/standalone_dtc_explicit_system_autowire.fsm`, bounded C1 standalone-DT scalar integer, scalar expression, one-bit sized bitstring, multi-bit sized bitstring, packed-list, and packed-map VHDL generic maps, a bounded C2 generated-FSM child composition VHDL scalar-autowire top for `t/corpus/implicit_composition_system_autowire.fsm`, bounded C2 generated-FSM scalar integer, scalar expression, one-bit sized bitstring, multi-bit sized bitstring, and resolved packed aggregate VHDL generic maps, and a bounded APB/C4 generated-FSM child composition VHDL top for `fsm/apb_tb.fsm` with scalar integer, scalar expression, one-bit sized bitstring, multi-bit sized bitstring, resolved packed aggregate, and resolved package-backed generic maps in the same APB/C4 shape.
Scalar division/modulo, including signed scalar division/modulo, in the direct
VHDL scaffold remains an explicit fail-closed boundary; full aggregate
record/array VHDL, broader generated-FSM/C4 composition VHDL beyond the exact
shipped fixtures, internal-net-heavy composition tops beyond APB, VHDL package
declaration/emission, full composition VHDL parity, and generic-map families
remain deferred outside these shipped sets: external-RTL scalar integer,
scalar integer expression, one-bit sized bitstring, multi-bit sized bitstring
literal/resolved-package-constant, and resolved packed aggregate actuals;
standalone-DT scalar integer, scalar expression, one-bit sized bitstring,
multi-bit sized bitstring, packed-list, and packed-map actuals; generated-FSM
scalar integer, scalar expression, one-bit sized bitstring, multi-bit sized
bitstring, and resolved packed aggregate actuals; and APB/C4 generated-FSM
scalar integer, scalar expression, one-bit sized bitstring, multi-bit sized
bitstring, resolved packed aggregate, and resolved package-backed actuals.
External-RTL, standalone-DT, and generated-FSM aggregate actuals that do not
lower to one packed literal are locked fail-closed by
`BACKEND-API-VALIDATION-FRONTIER.97.1`,
`BACKEND-API-VALIDATION-FRONTIER.98.1`, and
`BACKEND-API-VALIDATION-FRONTIER.99.1`, not treated as record/array generic
support; package-root direct HDL generation is locked fail-closed by
`BACKEND-API-VALIDATION-FRONTIER.100.1`: `?pkg` roots remain import-only
declaration containers, not standalone SystemVerilog or VHDL package HDL
output roots. Declared aggregate structural VHDL ports/nets/types are locked
fail-closed by `BACKEND-API-VALIDATION-FRONTIER.101.1` before record/array
emission; GHDL validation remains blocked by
`BACKEND-API-VALIDATION-FRONTIER.102.1` because `ghdl` is unavailable in the
current environment. Direct roots now expose declaration-only internal
storage/helper nets plus generated enable wires in `structural_rtl_ir.nets[]`,
expose generated enable assignments in machine-readable
`structural_rtl_ir.assignment_records[]` with structured `lhs`, `rhs`,
rendered text, and provenance, populate generated-enable net
`source`/`targets[]` connectivity from those assignment records, reroute the
direct SystemVerilog top state/standalone-DT generated-enable condition block
through `StructuralRTLIR`, populate direct input-port generated-enable RHS
`targets[]` connectivity on `structural_rtl_ir.ports[]`, populate direct
output-port source summaries on `structural_rtl_ir.ports[]` from lowered
output-drive families, and retain `structural_rtl_ir.auxiliary_assignments[]`
as the scalar-string compatibility mirror. Generated-enable RHS expressions
and captured assignment RHS metadata now pass through a shared AST logic
simplification step before SystemVerilog text is emitted. That pass covers
boolean and width-proven vector/multi-bit bitwise identities, annihilators,
idempotence, complements, double negation, absorption, and consensus-style
forms while preserving width-changing masks such as `BUS1 & 1'b1`; direct
`assignment_records[]` store that same simplified RHS AST. Broader
output-drive/always-block body consumer modeling remains outside the compact
source summary.
Direct instance/link selector `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1`
confirmed direct roots are leaf structural summaries and intentionally keep
`instances[]`, `declared_links[]`, and `resolved_links[]` empty; populated
instances and links remain a composition-top structural contract. Selector
`R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` deferred broader/full direct
SystemVerilog rerouting through `StructuralRTLIR` until direct behavior-body,
state-update, output, and assertion regions have exact structural ownership.
Direct VHDL backend/reroute work through `StructuralRTLIR` is deferred by
`R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` until the SystemVerilog-backed
IAL0/IAL1/IAL2 path is feature complete. The first exact private ISF
lowerer extraction is shipped as `FSM::Scheduler::ISF::ATLGeneratedTop` for
ATL generated-top report projection and data-link child-interface marking;
broader parser/lowerer extraction remains deferred behind future exact owners.
IAL2 protocol/platform intent is public through bounded `.ppif` sources, with
mandatory lowering `IAL2 -> IAL1 -> IAL0`; direct IAL2-to-IAL0 lowering is not
a public contract. Current bounded `.ppif` coverage includes one-channel
Valid-Ready sources, the shipped AXI AW/W multi-channel Valid-Ready bundle,
the protocol-neutral dual-channel Valid-Ready bundle, and one-object AXI
manager capacity/status sources. Support-accounted AXI manager coverage now
includes capacity/status, ID-family metadata, transaction envelopes and
fan-in, concrete-ID assertions, bounded auto-ID lifecycle, same-ID reject and
issue-order-queue policy, generated auto-ID write/read response-demux,
generated single/last/multi-beat read-data capture, burst-length/runtime
validation, scalar `RRESP` aggregation, one-or-more read burst-last
queue-head groups, one-or-more write queue-head groups, and read single-beat
queue-head response-demux including multiple response-demux-only and scalar
read-data groups plus the selected one-group read single-beat depth-3
response-demux-only and scalar read-data shapes plus the selected one-group
read burst-last depth-3 response-demux-only, scalar last-beat read-data, and
report-only raw-`ARLEN` burst-length and runtime beat-count/`RLAST`
validation shapes plus the selected runtime-validation multi-beat output-bank
shape plus the selected one-group write depth-3 response-demux-only shape plus
multiple or mixed depth-3 response-demux-only queue-head groups for read
single-beat, read burst-last, and write families plus selected multiple/mixed
depth-3 read single-beat scalar read-data groups plus selected
multiple/mixed depth-3 read burst-last scalar last-beat read-data groups plus
selected report-only raw-`ARLEN` burst-length capture and runtime
beat-count/`RLAST` validation over those multiple/mixed depth-3 read
burst-last scalar last-beat groups plus selected report-only raw-`ARLEN`
burst-length capture over same-family mixed auto-ID plus concrete queue-head
read burst-last scalar last-beat read-data plus metadata-first dynamic
transaction-ID parser/report support for `(id dynamic)`, generated
single-active dynamic write `BID` response matching plus same-cycle
release-and-recapture, and generated
single-active dynamic read single-beat `RID` response matching plus
same-cycle release-and-recapture, plus generated bounded two-transaction
all-dynamic read single-beat same-ID `RID` issue-order queue behavior.
Selector
`.228` selected `.229`, readiness audit for dynamic read burst-last/`RLAST`
transaction-ID capture and response matching before any behavior changes.
Selector `.178` selected
read burst-last scalar last-beat read-data over multiple/mixed depth-3
queue-head groups as the next readiness audit; no behavior changed in that
selector slice. Audit `.179` selected `.180`, direct bounded implementation of
that burst-last scalar last-beat read-data behavior over multiple/mixed
depth-3 queue-head groups with no `burst_length` metadata; no behavior
changed in the audit slice. Implementation `.180` now ships that behavior.
Selector `.181` selected `.182`, readiness audit for generated report-only
raw-`ARLEN` burst-length capture over those multiple/mixed depth-3 queue-head
scalar last-beat read-data groups; no behavior changed in the selector slice.
Audit `.182` selected `.183`, direct bounded implementation of generated
report-only raw-`ARLEN` burst-length capture over those groups. Temporary
in-memory candidates with report-only `burst-length` metadata fail closed only
at the local last-beat coverage gate, while existing raw-`ARLEN`
storage/rule/report helpers are transaction-list driven once coverage admits
the shape. Implementation `.183` now ships that report-only raw-`ARLEN`
burst-length behavior for the two-depth-3 and mixed depth-3/depth-2 queue-head
scalar last-beat read-data samples. The generated behavior adds width-8
`axi0_arlen`, per-transaction raw-`ARLEN` storage, request-guarded
burst-length capture rules, and support-accounted strict check/semantic JSON
while preserving scalar last-beat `RDATA`/`RRESP` capture and leaving
`generated_beat_count_validation` residue. Selector `.184` selected `.185`,
readiness audit for generated runtime beat-count/`RLAST` validation over the
same multiple/mixed depth-3 queue-head scalar last-beat read-data shape. Audit
`.185` selected `.186`, and implementation `.186` now ships that generated
runtime-validation behavior for the two-depth-3 and mixed depth-3/depth-2
queue-head scalar last-beat read-data samples. The generated path preserves
request-captured raw-`ARLEN` and scalar last-beat `RDATA`/`RRESP` capture,
adds expected-beat storage, read-beat counters, request-time initialization,
matched-read-beat counter increments, and beat-count/`RLAST` assertions, sets
`burst_length_validation: runtime_assertion`, removes
`generated_beat_count_validation` residue, and keeps
`multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation` residue. Multi-beat payload, write-family read-data,
mixed auto-ID, group-local enqueue widening, packed outputs, direct backend,
verification-output generation, VHDL, and backend-language variants remain
deferred. Selector `.187` selected `.188`, report/static support-residue
cleanup, because live `.186` reports generate runtime validation while the AXI
ID/order unsupported-residue detail still classifies multiple/mixed depth-3
runtime validation with multi-beat payload as outside the shell.
Cleanup `.188` now aligns that support/residue wording: selected
multiple/mixed depth-3 read burst-last queue-head scalar last-beat read-data
with runtime-assertion beat-count/`RLAST` validation is reported as supported,
and left only read burst-last multi-beat payload over those multiple/mixed
depth-3 queue-head groups as unsupported residue. Selector `.189` selected
`.190`, readiness audit for generated multi-beat output-bank behavior over
those multiple/mixed depth-3 runtime-validation groups. Audit `.190` selected
`.191`, and implementation `.191` now ships generated multi-beat output-bank
behavior over the two existing `.186` depth `3,3` and mixed depth `3,2`
runtime-validation queue-head shapes. The two new public samples are
support-accounted, strict check/semantic JSON matched, and HDL-verifiable;
generated reports set `read_data.mode:
bounded_multi_beat_read_data_contract`, `output_shape:
per_beat_output_bank`, runtime-assertion `ARLEN` validation, empty
`read_data` residue, and empty `response_demux` residue. Selector `.192`
selected `.193`, readiness audit for same-family mixed auto-ID lifecycle plus
concrete same-ID queue-head response-demux before any behavior change. Audit
`.193` selected `.194`, direct bounded response-demux-only implementation of
that mixed family boundary. Implementation `.194` now ships that behavior for
public read single-beat, read burst-last, and write response-demux-only
fixtures. The generated reports use mixed auto-ID plus queue-head mode,
produce generated completion outputs/rules/assertions for both the auto-ID and
concrete queue-head transactions, keep the request-ID bus owned by the
auto-ID lifecycle generated output, and add concrete request-ID drive rules
for same-family concrete transactions. Selector `.195` selected `.196`,
readiness audit for mixed read-data consumption over same-family mixed auto-ID
plus concrete same-ID queue-head response-demux before any behavior expansion.
Audit `.196` selected `.197`, direct bounded implementation of scalar
read-data consumption for the read single-beat and read burst-last mixed
families. The probes fail closed only at the local read-data coverage boundary
that still treats mixed response-demux as auto-ID-only.
Implementation `.197` now ships that bounded scalar read-data behavior for the
read single-beat and read burst-last same-family mixed auto-ID plus concrete
same-ID queue-head response-demux shapes. The two new public
support-accounted samples bind `RDATA`/`RRESP` for `r0`, `r1`, and `r2`,
reuse the combined generated response-demux completions, report
`generated_mixed_auto_id_queue_head_response_demux_completion_pulse` for
single-beat capture and
`generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse`
for burst-last last-beat capture, strict-check and HDL-verify cleanly, and
keep existing PPIF syntax. Selector `.198` selected `.199`, readiness audit
for generated report-only raw-`ARLEN` burst-length capture over the read
burst-last same-family mixed auto-ID plus concrete queue-head scalar
last-beat read-data shape. Audit `.199` found temporary report-only and
runtime-assertion probes both generate through existing helpers, selected
`.200` to publish/support-account the report-only boundary first, and
requires `.200` to preserve or lock runtime validation as separately owned.
Implementation `.200` now ships that support-accounted report-only
raw-`ARLEN` burst-length boundary through
`ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length.ppif`.
Audit `.201` selected `.202`, direct bounded support/publication of generated
runtime beat-count/`RLAST` validation over that same mixed auto-ID plus
concrete queue-head read burst-last scalar last-beat shape. Implementation
`.202` now ships that support-accounted runtime-assertion sibling through
`ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.ppif`;
the runtime sample reports `burst_length_validation: runtime_assertion`,
`beat_count_match_source: response_demux_matched_read_beat`, expected-beat
storage, read-beat counters, six beat-count rules, twelve beat-count/`RLAST`
assertions, strict support accounting, semantic JSON support, and HDL, while
removing `generated_beat_count_validation` residue.
Audit `.206` selected `.207`, direct bounded implementation of generated
mixed multi-beat output-bank behavior over the same runtime-validation shape.
The audit found that the current blocker is local to the mixed read-data
coverage predicate; existing transaction-list helpers already provide the
expected output-bank, scalar aggregate, burst-length, beat-count, assertion,
and report artifacts after admission.
Implementation `.207` now ships that support-accounted mixed multi-beat
output-bank boundary through
`ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data.ppif`.
The sample reports
`generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse`,
three covered read transactions (`r0`, `r1`, `r2`), 48 generated per-beat
RDATA lane outputs, 48 generated per-beat RRESP lane outputs, three valid
masks, three length outputs, three scalar `RRESP` aggregate outputs, 48 lane
capture rules, three output-bank clear rules, three scalar aggregate update
rules, three raw-`ARLEN` storage signals, three expected-beat counters, six
beat-count rules, twelve beat-count/`RLAST` assertions, strict support
accounting, semantic JSON support, and HDL while keeping read-data residue
empty.
Selector `.208` now chooses `.209`, readiness audit for group-local
simultaneous enqueue widening across generated concrete same-ID queue-head
families. Live read multi-group, write multi-group, and mixed multi-beat
queue-head samples still report a family-wide request onehot assertion even
when multiple concrete-ID queue groups exist, so `.209` must audit admission,
direction-level capacity accounting, transition generation, and preservation
before any behavior change.
Audit `.209` selected `.210`, counted admission/capacity prerequisite audit
before group-local same-ID enqueue widening. Live probes show one Boolean
request fan-in per direction, one family-wide same-ID request onehot
assertion, and per-group queue update rules; generated IAL1 confirms admitted
pulses still use scalar pending storage plus completion fan-in while capacity
rules increment pending by one for any request fan-in. Distinct concrete-ID
group queue transitions are structurally separable, but group-local request
onehot replacement must wait for counted request admission and pending/status
accounting ownership.
Implementation `.211` now ships that counted capacity substrate for generated
same-ID queue-head families with multiple concrete-ID groups while preserving
the family-wide request onehot assertion. Schedule reports identify
`request_accounting.mode: counted_same_id_selected_requests`, counted request
events/terms/groups, the additive `request_count_expression`,
`maximum_request_count`, capacity-matrix ownership, Boolean completion
accounting, and `over_capacity_policy: reject_current_request_set`; affected
capacity matrices report `accounting_mode: counted_submit`. Non-counted
directions and mixed auto-ID single concrete-group directions stay on Boolean
fan-in. Selector `.212` found the counted matrix is not sufficient by itself:
admitted-request pulses still use scalar pending storage plus Boolean
completion fan-in, so direct group-local onehot narrowing could enqueue
requests that the capacity matrix rejects. Audit `.213` selected `.214`, the
bounded implementation owner for counted admitted-request guard alignment plus
group-local request assertions over generated multi-group queue-head families.
Implementation `.214` now ships that boundary: counted multi-group queue-head
families gate admitted-request pulses with a request-set fit expression derived
from the counted capacity/status matrix, replace the family-wide request
onehot with one request assertion per concrete-ID queue group, and preserve
Boolean admission plus the existing family-wide assertion for non-counted
directions and mixed auto-ID single concrete-group directions. Implementation
`.219` now ships metadata-first dynamic transaction-ID parser/report support:
the public PPIF syntax accepts exactly transaction-local `(id dynamic)` when a
positive-width matching ID family declares request/response ID signals, reports
`policy dynamic`, `request_id_source`, `response_id_signal`, `ownership
user_supplied`, and `implementation_status selected_not_generated`, adds a
support-accounted metadata-only sample, and keeps dynamic capture, response
matching, queues, scoreboards, read-data routing, and HDL behavior deferred.
Selector `.220` selects `.221`, readiness audit for generated dynamic
transaction-ID capture and response matching before any behavior changes.
Audit `.221` selects `.222`, public contract selection for bounded dynamic
write transaction-ID capture and `BID` response matching. The audit found the
lower substrate can likely carry the narrow write shape, but the public
contract must first define admitted-request capture timing, single-active
dynamic ownership, matched-response completion/release semantics, diagnostics,
reports, validation, and residue.
Implementation `.223` ships that first dynamic behavior. Explicit
`response-demux.write` with exactly one transaction-local dynamic write ID now
captures `AWID` at the admitted write request, stores generated selected-ID
and busy state, matches raw write responses with `BID == captured_id`, pulses
the transaction completion, releases busy from that completion, reports
`bounded_dynamic_write_bid_demux_contract`, and adds
`ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif` as a
support-accounted sample. Implementation `.365` extends that same single-active
write sample with same-cycle release-and-recapture. Implementation `.227` also
ships the selected single-beat dynamic read shape, and `.368` extends it with
same-cycle release-and-recapture: explicit
`response-demux.read` with exactly one
transaction-local dynamic read ID captures admitted `ARID`, stores generated
selected-ID/busy state, matches raw read responses with `RID == captured_id`,
pulses the generated read completion, releases busy, reports
`bounded_dynamic_read_rid_demux_contract`, and adds
`ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif` as a
support-accounted sample. Implementation `.231` also ships the selected
burst-last dynamic read shape, and `.372` extends it with same-cycle
release-and-recapture: explicit `response-demux.read` with exactly one
transaction-local dynamic read ID, `response-scope burst-last`, and one-bit
`last-signal` captures admitted `ARID`, stores generated selected-ID/busy
state, matches raw read responses with `RID == captured_id && RLAST`, pulses
the generated read completion, releases or recaptures busy, reports
`bounded_dynamic_read_rid_rlast_demux_contract`, and adds
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif`
as a support-accounted sample. Metadata-only dynamic IDs remain unchanged when
no behavior clause consumes them. Multiple dynamic transactions, mixed
dynamic/static demux, same-cycle recapture outside the selected single-active
write, read single-beat, and read burst-last boundaries, same-ID ordering,
read-data
routing, burst-length/runtime validation, queues, scoreboards, direct backend
behavior, HDL shapes outside this selected SystemVerilog path, and VHDL remain
deferred.
Public `.pif`/`.ppi`/`.axi` aliases, broader concrete same-ID queues,
packed burst-vector outputs, alternate full burst payload assembly, full AXI
manager behavior, direct backend lowering, verification-output generation,
VHDL, backend-language variants, and dynamic arbitration beyond the selected
counted concrete-ID queue-head groups remain deferred.
IAL2 feature completeness on the SystemVerilog-backed path remains active
under `IAL2-FEATURE-COMPLETENESS-FRONTIER`; `.174` now ships generated
multiple or mixed depth-3 concrete same-ID queue-head response-demux for
response-demux-only read single-beat, read burst-last, and write families.
The six new public samples are support-accounted and preserve read-data,
burst-length, runtime-validation, multi-beat, mixed auto-ID, direct backend,
and VHDL boundaries.
Selector `.175` chooses `.176`, readiness audit for generated read-data over
multiple or mixed depth-3 concrete same-ID queue-head groups. That selector is
documentation-only and leaves parser, generator, sample, support-accounting,
HDL, and generated-artifact behavior unchanged.
Audit `.176` selects `.177`, direct bounded implementation of read
single-beat scalar `RDATA`/`RRESP` over generated multiple/mixed depth-3
queue-head groups. Burst-last read-data, burst-length, runtime-validation,
multi-beat payload, mixed auto-ID, direct backend, and VHDL remain deferred.
Implementation `.177` now ships that bounded read single-beat scalar
read-data behavior for two-depth-3 and mixed depth-3/depth-2 concrete
same-ID queue-head groups. The two public samples are support-accounted,
strict check/semantic JSON matched, and HDL-verifiable. The implementation
widens only the local single-beat read-data coverage admission predicate;
burst-last read-data over multiple/mixed depth-3 groups was selected next.
Selector `.178` selected `.179`, readiness audit for generated read burst-last
scalar last-beat read-data over multiple/mixed depth-3 queue-head groups.
Audit `.179` selected `.180`, and implementation `.180` now ships generated
read burst-last scalar last-beat `RDATA`/`RRESP` over two-depth-3 and mixed
depth-3/depth-2 concrete same-ID queue-head groups with no `burst_length`
metadata. The two public samples are support-accounted, strict check/semantic
JSON matched, and HDL-verifiable. The implementation widens only the local
no-`burst_length` last-beat read-data coverage admission predicate. Selector
`.181` selected `.182`, readiness audit for generated report-only
raw-`ARLEN` burst-length capture over multiple/mixed depth-3 queue-head
scalar last-beat read-data. Audit `.182` selected `.183`, direct bounded
implementation of report-only raw-`ARLEN` burst-length over those groups.
Implementation `.183` now ships that report-only raw-`ARLEN` burst-length
behavior for two-depth-3 and mixed depth-3/depth-2 queue-head scalar last-beat
read-data groups. The two public samples are support-accounted, strict
check/semantic JSON matched, and HDL-verifiable. Selector `.184` selected
`.185`, readiness audit for generated runtime beat-count/`RLAST` validation
over the same multiple/mixed depth-3 queue-head scalar last-beat read-data
shape. Audit `.185` selected `.186`, and implementation `.186` now ships that
runtime-validation behavior. The two new public samples are support-accounted,
strict check/semantic JSON matched, and HDL-verifiable; generated reports set
`burst_length_validation: runtime_assertion`, remove
`generated_beat_count_validation` residue, and preserve explicit multi-beat
payload, per-beat output, and scalar `RRESP` aggregation residue. Multi-beat
payload, write-family read-data, mixed auto-ID, group-local enqueue widening,
packed outputs, direct backend, verification-output generation, VHDL, and
backend-language variants remain deferred. Selector `.187` selected `.188`,
report/static support-residue cleanup, before multi-beat output-bank behavior
or broader behavior expansion. Cleanup `.188` now reports selected
multiple/mixed depth-3 runtime-validation scalar last-beat shapes as
supported and leaves only read burst-last multi-beat payload over those groups
as unsupported residue. Selector `.189` selected `.190`, readiness audit for
generated multi-beat output-bank behavior over those multiple/mixed depth-3
runtime-validation groups. Audit `.190` selected `.191`, direct bounded
implementation of generated multi-beat output-bank behavior over the two
existing `.186` depth `3,3` and mixed depth `3,2` runtime-validation
queue-head shapes. Implementation `.191` now ships that behavior with two
support-accounted public samples for queue-depth sets `3,3` and `3,2`.
Selector `.192` selected `.193`, readiness audit for same-family mixed
auto-ID lifecycle plus concrete same-ID queue-head response-demux. Audit
`.193` selected `.194`, direct bounded response-demux-only implementation.
Implementation `.194` now ships that bounded mixed response-demux behavior for
read single-beat, read burst-last, and write public fixtures, and `.195` is
the next selector.
The first
in-process AXI manager outstanding-capacity and acceptance/status generator is
now shipped as `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`; it
accepts a structured AXI4 manager contract, emits generated `.isf` before
`.fsm`, reaches SystemVerilog through the existing IAL1/IAL0 path, and reports
schema `fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1`. The
public `.ppif` capacity/status parser/CLI first slice is now shipped for one
`(manager-capacity-status NAME ...)` object under
`(protocol-platform-intent ...)`, `(profile axi4)`, and top-level source
anchors, with sample, support-accounting, check JSON, semantic JSON, generated
review artifacts, default HDL, and `--verify-hdl` coverage. The next AXI
manager subset is selected as ID-family declaration and static validation, and
the additive optional `(id-families ...)` public `.ppif` extension is now
shipped for the existing capacity/status object with report metadata, a
separate sample, support accounting, check JSON, semantic JSON source identity,
and unchanged generated `.isf`, `.fsm`, and HDL behavior. The next exact AXI
manager subset is selected as a machine-readable AST/structural logical
read/write transaction envelope and static-validation contract; the readiness
audit selects an additive optional `(transactions ...)` static/report metadata
extension under the existing `manager-capacity-status` object, with no
IAL1/IAL0/SV prerequisite for the first slice because transaction events bind
to existing direction-level abstract events. That optional `(transactions ...)`
public `.ppif` extension is now shipped for the existing capacity/status
object with machine-readable AST/structural report metadata, a separate
sample, support accounting, check JSON, semantic JSON source identity, and
initially unchanged generated `.isf`, `.fsm`, and HDL behavior. Transaction
event dispatch and direction fan-in are now shipped for that same object:
distinct per-transaction request/completion events become generated IAL1
inputs, write or read directions with multiple transaction events use OR
fan-in guards, the existing IAL1/IAL0/SystemVerilog path carries the behavior,
and schedule JSON additively reports `transaction_event_dispatch` metadata.
The concrete transaction ID assertion slice is now shipped: transactions with
concrete requested IDs declare used ID-family request/response ID signals as
generated IAL1 inputs, lower assertion-only checks to `.fsm` `+assert`
carriers, emit verification-only SystemVerilog assertions, and report
`id_response_rule_engine` metadata. Auto-ID allocation, ID release, response
demux, ordering, bursts, queued policy, aliases, full-manager behavior, and
VHDL remained residue before the explicit lifecycle work. The AXI manager
auto-ID lifecycle readiness audit is now
complete: the current IAL1/IAL0/SystemVerilog substrate can carry a bounded
scalar request-ID lifecycle, but auto-ID allocation must not be inferred
directly from ID width or existing `(id auto)` syntax. The bounded contract is
now selected as an explicit optional `(auto-id-lifecycle (write (pool ...))
(read (pool ...)))` clause under `manager-capacity-status`; existing
`(id auto)` remains structural/report-only when that clause is absent. That
parser/report metadata and static-validation slice is now shipped with
`auto_id_lifecycle` report metadata, a runnable `.ppif` sample, support
accounting, check JSON, semantic JSON, and initially unchanged generated
`.isf`, `.fsm`, and HDL behavior. Bounded request-ID drive behavior is now
shipped for explicit auto-ID lifecycle families: request ID signals become
generated IAL1 outputs, per-auto-transaction selected-ID/busy state is
generated, deterministic first-free allocation and completion-event release
rules lower through `.fsm` to SystemVerilog, runtime assertions cover
no-ID-available and illegal same-family simultaneous requests, and
`auto_id_lifecycle.generated_behavior` is true. Same-ID ordering, read-data
interleaving/reassembly, bursts, queued policy, aliases, full-manager behavior,
and VHDL remain residue. The bounded AXI write response-demux parser/report
metadata slice is now shipped for explicit
`(response-demux (write (response-event EVENT) (transaction-completion
generated)))` opt-in syntax. The generated behavior follow-up is now shipped:
the generator adds `BID` as a generated IAL1 input, treats write transaction
completion names as generated pulse outputs, emits one guarded response-demux
rule per auto-ID write transaction using `(pulse COMPLETION)`, keeps capacity
and auto-ID release driven by those pulses, emits unmatched/ambiguous response
assertions, and reports `response_demux.generated_behavior` true with
generated rules, completion signals, assertions, and write-demux residue
removed.
The generated behavior readiness audit concluded that write `BID` demux needed
a small IAL1 prerequisite first: generated transaction completion names must
be one-cycle pulse actions, not sticky flopped rule assignments. That
prerequisite is now shipped as bounded IAL1 `(pulse TARGET)` rule actions that
lower as `<1` pulse-domain assignments. The
post-demux report alignment follow-up is now shipped:
`auto_id_lifecycle.residue` removes stale `response_demux` residue when
generated write `BID` demux drives auto-ID release. The first bounded
same-ID step is now shipped as generated auto-ID same-ID avoidance: FSMGen
emits pairwise active selected-ID assertions, reports machine-readable
`same_id_ordering` metadata, removes covered same-ID residue from generated
auto-ID lifecycle and write response-demux reports, and keeps concrete-ID
same-ID ordering plus per-ID response queues as residue. Selector `.36` chose
read response-demux readiness as the next exact slice, readiness audit `.37`
concluded that the public contract must be selected before parser/report or
behavior changes, and selector `.38` chose the explicit bounded read arm with
`(response-scope single-beat)`. The parser/report metadata slice `.39` is now
shipped: `.ppif` accepts read, write, or mixed `response-demux` family arms;
the read arm requires `response-event`, `response-scope single-beat`, and
`transaction-completion generated`; schedule JSON reports structural
`response_demux.read` metadata with `generated_behavior` false; and the new
read-demux sample is covered by check JSON, semantic JSON, and support
accounting. Readiness audit `.40` concluded that bounded single-beat generated
read `RID` response-demux behavior can be implemented directly with no new
IAL1/IAL0/SystemVerilog prerequisite. The generated behavior slice `.41` is
now shipped: response-demux helpers are family-aware, the generator adds
`RID` as a generated input, emits generated read completion pulse
outputs/rules/assertions, and keeps read capacity release plus read auto-ID
release on those generated completion pulses. Schedule JSON reports
`response_demux.read.generated_behavior` true with generated rules, completion
signals, assertions, and read-demux residue removed. Selector `.42` chose
`.43` as the next readiness audit over the interdependent read-data payload,
burst/`RLAST`, and per-ID ordering/reassembly residues after generated read
demux. Audit `.43` concluded that the bounded public read-data payload/status
contract must be selected before parser/report metadata or generated behavior
changes. Selector `.44` chose explicit bounded `(read-data (read ...))`
syntax for single-beat `RDATA`/`RRESP` capture, with generated read
response-demux as the completion source and `RLAST`/bursts deferred. The
`.45` slice now ships parser/report metadata and static validation for that
read-data contract: `.ppif` accepts the structural `read-data` AST form,
check JSON and semantic JSON support-account the new sample, and generated
behavior was initially deferred behind the `.46` readiness audit.
Readiness audit `.46` concluded that generated single-beat `RDATA`/`RRESP`
capture can be implemented directly with no new IAL1/IAL0/SystemVerilog
prerequisite: existing width-bearing IAL1 inputs/outputs and normal guarded
rule assignments can hold captured payload/status values under the generated
read demux completion pulse. Slice `.47` now ships that behavior: explicit
`read-data` contracts generate width-bearing `RDATA`/`RRESP` inputs,
per-transaction data/status outputs, one normal guarded capture rule per read
transaction, schedule JSON generated artifact lists, and
`read_data.generated_behavior: true` with generated-capture residue removed.
Selector `.48` chose `IAL2-FEATURE-COMPLETENESS-FRONTIER.49`, AXI
burst/`RLAST` completion readiness, as the next exact prerequisite before
multi-beat read-data reassembly or broader read-side manager behavior.
Readiness audit `.49` concluded that no new IAL1/IAL0/SystemVerilog substrate
prerequisite is evident for a later bounded `RLAST` implementation, but the
public source contract had to be selected first.
Selector `.50` chose an additive read `response-demux` contract:
`response-scope burst-last` plus one-bit `last-signal`. It keeps generated
transaction completion as the last-beat pulse, publishes no per-transaction
beat-valid output, uses `RLAST` rather than `ARLEN`/beat-count metadata for
this first boundary, rejects the current single-beat `read-data` contract when
paired with burst-last response demux, and leaves multi-beat read-data
reassembly deferred. Slice `.51` ships parser/report metadata and static
validation for that contract, including a support-accounted sample and
structural report fields with `generated_behavior: false`, while generated
`.isf`, `.fsm`, and HDL behavior remain unchanged. Audit `.52` found no new
IAL1/IAL0/SystemVerilog prerequisite. Slice `.53` ships generated
burst-last/`RLAST` completion behavior: explicit burst-last read response
demux now emits the raw response beat input, generated `RID` input, generated
one-bit `RLAST` input, generated transaction completion pulse outputs,
RLAST-gated response-demux rules, assertions, auto-ID lifecycle residue
movement, same-ID coverage movement, and HDL reachability. The active frontier
selector `.54` found one remaining report-contract drift: generated schedule
report prose still describes burst-last `RLAST` metadata as report-only and
generated burst/last-beat tracking as outside the capacity/status shell.
Slice `.55` aligns that report/static text: reports now say burst-last
response-demux generates matched-`RID`-and-`RLAST` last-beat completion
behavior, and list generated burst-last `RLAST` response-demux completion as
supported. Selector `.56` chose
`IAL2-FEATURE-COMPLETENESS-FRONTIER.57`, public AXI burst read-data contract
selection, because the current `read-data` shape is single-beat-only and
cannot yet express burst capture scope, output binding, beat-count/depth,
`RRESP` aggregation, or interleaving semantics. Selector `.57` chooses
explicit last-beat read-data capture as the first bounded burst-side contract:
`capture-scope last-beat`, `status-policy last-beat`, and
`interleaving last-beat-by-rid` under `read-data`, paired only with generated
`response_scope burst_last` response demux. Slice `.58` ships parser/report
metadata and static validation for that contract: `.ppif` accepts the new
last-beat read-data shape, requires generated burst-last read response-demux
metadata, reports `bounded_last_beat_read_data_contract` with
`generated_behavior: false`, adds a strict support-accounted sample, and keeps
generated `.isf`, `.fsm`, HDL behavior, check JSON semantics, and existing
single-beat read-data behavior unchanged. Readiness audit `.59` found no new
IAL1/IAL0/SystemVerilog prerequisite because the existing read-data
input/output/capture-rule helpers can use the generated burst-last completion
pulses from response demux. Slice `.60` now ships generated last-beat
`RDATA`/`RRESP` capture behavior: the last-beat sample emits generated data and
status inputs, per-transaction last-beat data/status outputs, normal guarded
capture rules driven by generated burst-last completion pulses, `.fsm`
assignments, HDL reachability, and read-data generated artifact report lists.
Selector `.61` chooses public AXI burst read-data beat-count/depth contract
selection as the next exact owner, because full multi-beat reassembly,
per-beat outputs, `RRESP` aggregation, missing/extra beat validation, and
per-ID reassembly all need an explicit expected-count/depth contract first.
Selector `.62` chooses an additive ARLEN-based `burst-length` contract:
`source arlen`, width-8 `axlen-plus-one` encoding, transaction-request
capture, required `max-beats` in range `1..256`, and `validation report-only`.
Slice `.63` ships parser/report metadata and static validation for that
contract: `.ppif` accepts optional last-beat `read-data` `burst-length`
metadata, reports ARLEN/max-beats fields, adds a support-accounted sample,
and splits vague beat-count residue into explicit generated-capture and
validation owners. Selector `.64` chooses a generated ARLEN burst-length
capture readiness audit before behavior changes, audit `.65` finds no new
IAL1/IAL0/SystemVerilog substrate prerequisite for raw ARLEN capture, and
implementation `.66` ships that behavior: `axi0_arlen` is a generated width-8
input, each covered read transaction gets raw-ARLEN storage
(`axi0_r0_arlen_q`, `axi0_r1_arlen_q`), request-event guarded capture rules,
`.fsm`/SystemVerilog lowering, `burst_length_generated_behavior: true`, and
generated burst-length input/storage/rule report fields. Audit `.67` finds
the IAL1/IAL0/SystemVerilog substrate ready for generated beat-count/RLAST
validation, but preserves `validation report-only` as no-runtime-check
behavior. Selector `.68` chooses `(validation runtime-assertion)` with
normalized report value `runtime_assertion`, preserves
`validation report-only` as no-runtime-check behavior, and requires parser
support plus generated validation behavior to ship together. Implementation
`.69` ships that first runtime-validation behavior: `.ppif` accepts
`validation runtime-assertion`, the generator emits per-transaction
expected-beat storage, matched-read-beat counters, initialization and
increment rules, runtime assertions for ARLEN bounds, extra beats, early
`RLAST`, and missing final `RLAST`, and schedule JSON reports generated
beat-count validation artifacts while report-only behavior remains unchanged.
Implementation `.72` ships parser/report metadata and static validation for
the public AXI multi-beat read-data reassembly/output contract selected by
`.71`: `capture-scope multi-beat` with mandatory ARLEN `burst-length`
runtime assertions, per-beat status, `multi-beat-by-rid` interleaving,
per-transaction data/status output prefixes, valid-mask outputs, and length
outputs. Audit `.73` found no new IAL1/IAL0/SystemVerilog prerequisite for
generated output-bank behavior. Implementation `.74` ships that behavior:
the public multi-beat sample now emits generated `RDATA`/`RRESP` inputs,
per-transaction data/status lane outputs, valid-mask outputs, length outputs,
request-time output-bank clearing, and lane capture rules guarded by matched
read beat, `!request_event`, and current beat-count equality. Schedule JSON
reports `multi_beat_reassembly_generated_behavior: true`, lists generated
multi-beat output/init/capture artifacts, and reduces read-data residue to
`rresp_aggregation`. Selector `.75` chooses public scalar `RRESP`
aggregation contract selection as the next exact owner before parser/report
metadata or generated behavior changes. Selector `.76` chooses additive
scalar `RRESP` aggregation syntax: read-level
`(status-aggregation (policy worst-observed))` plus transaction-local
`(status-aggregate-output NAME)`, reported as `worst_observed`. Per-beat
`RRESP` lanes remain mandatory. Implementation `.77` ships parser/report
metadata and static validation for that public contract: the multi-beat sample
now accepts `status-aggregation`, reports `status_aggregation` as
`worst_observed`, `status_aggregation_generated_behavior: false`,
`status_aggregate_output: per_transaction_scalar`, per-transaction aggregate
output names/widths, and narrows read-data residue to
`generated_rresp_aggregation` while leaving generated `.isf`, `.fsm`, and HDL
output-bank behavior unchanged. Audit `.78` finds no new
IAL1/IAL0/SystemVerilog prerequisite for first generated width-2
`worst_observed` scalar behavior. Implementation `.79` ships that behavior:
the multi-beat sample now emits width-2 scalar aggregate outputs such as
`axi0_r0_rresp`, initializes them to `2'd0` on request in the existing
output-bank init rule, updates them on matched accepted read-data beats when
the current aggregate is less than the current `RRESP` under `!request_event`,
reports generated aggregate output/init/update artifacts, and removes
`generated_rresp_aggregation` from read-data residue. Width-3 responses
remain deferred. Selector `.80` chooses `.81`, AXI per-ID read-data
interleaving and queue readiness, because the live public sample now has empty
`read_data` residue while `response_demux` and `same_id_ordering` still carry
read-data interleaving, bursts, concrete-ID same-ID ordering, and per-ID queue
residue. Audit `.81` finds the current generated auto-ID multi-beat sample
already has bounded `multi_beat_by_rid` output-bank behavior through generated
same-ID avoidance, matched-`RID` response demux, and per-transaction beat
counters/output banks. The broad `read_data_interleaving` residue is therefore
too conservative for that covered subset. Implementation `.82` aligns that
report/static residue: the public multi-beat sample now reports
`response_demux.residue: [bursts]` and
`same_id_ordering.residue: [concrete_id_same_id_ordering,
per_id_issue_order_queues, bursts]` while keeping `read_data.residue: []`.
Generated `.isf`, `.fsm`, and SystemVerilog behavior is unchanged. Selector
`.83` chooses `IAL2-FEATURE-COMPLETENESS-FRONTIER.84`, AXI burst
payload/output readiness, because `bursts` is now the only
`response_demux` residue and remains shared with `same_id_ordering` while the
public multi-beat sample already has burst-last `RLAST` demux, raw ARLEN
capture, beat-count/RLAST runtime validation, per-beat output banks, valid
masks, length outputs, and scalar aggregate `RRESP`. Audit `.84` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.85`, report/static `bursts` residue
alignment for the covered generated auto-ID multi-beat output-bank subset,
because the selected per-beat output bank is already the bounded burst
payload/output shape for that subset. Packed/full burst assembly remains a
separate deferred contract. Verification-code generation
(`SV/UVM` agents, monitors, scoreboards, checkers, coverage, and reusable VIP)
is a valid FSMGEN route, but it is tracked as a separate roadmap lane from
the current synthesizable RTL/HDL feature-completeness path. That lane is now
task-tree owned by `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER`: the default
source stance is IAL1 (`.isf`) first. Audit `.2` found the existing IAL1
assert/assume/cover/property/monitor surface sufficient for inline
SystemVerilog assertion projection, but insufficient for first-class generated
SV/UVM or VHDL-oriented verification artifacts. Frontier `.3` selected an
actor-level passive observation metadata contract as the first IAL1
verification-specific source feature. Implementation
`ISF-VERIFICATION-OBSERVATION-METADATA.1` ships the report-only parser,
additive `verification_observations[]` schedule JSON projection, public
contract metadata, supported-smoke fixture, and mdBook example for that
contract. Frontier `.4` selected a passive UVM monitor skeleton package as the
first SV/UVM output target. It may declare inert UVM 1.2 snapshot item and
monitor classes from `verification_observations[]`, but it must not sample a
DUT interface, publish transactions, infer events, build an agent, generate a
scoreboard, generate coverage, or emit reusable VIP behavior. Public CLI,
artifact layout, report/manifest shape, support accounting, and validation
gates were selected by `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`: the
command is `--emit-verification-output uvm-passive-monitor
--verification-outdir DIR source.isf`, writing
`DIR/uvm/<actor>_observation_uvm_pkg.sv` plus
`DIR/verification-output-manifest.json` for `.isf` sources with passive
`verification_observations[]`. Implementation `.8` ships that bounded
verification-output mode and advertises `uvm_passive_monitor_skeleton` through
the capability manifest, while leaving schedule/check/semantic JSON unchanged
for this first skeleton. FSMGen still does not claim UVM compile support.
Frontier `.5` audited VHDL assertion/testbench/PSL feasibility and selected no
VHDL verification artifact yet: the current VHDL path is synthesizable
scaffold-only, the external validation contract is SystemVerilog-only, and
GHDL validation is not active. Frontier `.9` selected the first VHDL
verification validation substrate as artifact-shape and inert-behavior checks
with manifest non-claims for VHDL compile, syntax, PSL, simulation, formal,
and analyzer support. Frontier `.10` selected the first VHDL-oriented
verification artifact as an inert VHDL observation metadata package. Frontier
`.11` now ships `--emit-verification-output vhdl-observation-package
--verification-outdir DIR source.isf`, writing
`DIR/vhdl/<actor>_observation_vhdl_pkg.vhd` plus
`DIR/verification-output-manifest.json` for `.isf` sources with passive
`verification_observations[]`. The capability manifest advertises canonical
target `vhdl_observation_package_skeleton`; the artifact and manifest remain
shape-only and inert, with no VHDL compile, VHDL syntax, PSL, simulator,
analyzer, scoreboard, coverage, reusable VIP, or direct IAL2 support claim.
Frontier `.6` audited direct IAL2-to-verification routing and selected no
direct `.ppif` verification-output route for the current lane: future
protocol-specific verification facts should first lower or annotate generated
IAL1 `.isf` review artifacts, then reuse the IAL1 verification-output path,
unless a later exact owner proves a direct route is required.
Implementation `.85` ships that report/static alignment: the public
multi-beat sample now reports `response_demux.residue: []` and
`same_id_ordering.residue: [concrete_id_same_id_ordering,
per_id_issue_order_queues]` while keeping `read_data.residue: []`.
Generated `.isf`, `.fsm`, and SystemVerilog behavior is unchanged. The next
selector was `IAL2-FEATURE-COMPLETENESS-FRONTIER.86`, which chose the
next AXI manager feature-completeness owner and carried the IAL2 factoring
question: keep a small common semantic core only where reuse across multiple
profiles is proven, and leave premature one-protocol abstractions in
protocol/platform vocabularies until evidence justifies sharing.
Selector `.86` chooses `IAL2-FEATURE-COMPLETENESS-FRONTIER.87`, AXI
concrete-ID same-ID ordering readiness. The public multi-beat sample now
leaves only `concrete_id_same_id_ordering` and `per_id_issue_order_queues`
under `same_id_ordering.residue`, while concrete-ID samples still keep
`same_id_ordering` under `id_response_rule_engine.residue`. Audit `.87`
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.88`, conservative fail-closed
static validation for multiple concrete-ID transactions in the same read or
write response family that share one concrete ID value. Implementation `.88`
now rejects that unsupported authored same-ID reuse before any per-ID queue,
scoreboard, public same-ID policy, or full same-ID ordering behavior, while
leaving valid single-concrete-ID samples behavior-stable. Selector
`IAL2-FEATURE-COMPLETENESS-FRONTIER.89` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.90`, AXI per-ID issue-order queue
readiness, because direct queue behavior needs a public same-ID reuse policy
and substrate audit before implementation. Audit `.90` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.91`, AXI same-ID reuse policy contract
selection, because the lower layers can carry bounded scalar/bank state but
the public source still does not define reject, queue, stall, block, or
scoreboard semantics for accepted same-ID reuse. Selector `.91` chooses an
optional AXI-profile-local `(same-id-ordering (read|write
(concrete-id-reuse reject)))` source contract and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.92`, which now ships parser/report
metadata plus static validation for that explicit reject policy. The PPIF
adapter accepts one optional `(same-id-ordering ...)` clause, duplicate or
missing policy arms fail closed, omitted policy preserves the `.88`
unselected-policy diagnostic, explicit `reject` emits a policy-specific
same-family concrete-ID reuse diagnostic, and `scoreboard` remains rejected.
Schedule JSON reports
`same_id_ordering.mode: concrete_id_reuse_policy` and
`concrete_id_reuse_policy.<family>.generated_queue_behavior: false`; generated
`.isf`, `.fsm`, and SystemVerilog stay unchanged for valid sources. Selector
`IAL2-FEATURE-COMPLETENESS-FRONTIER.93` chooses
`IAL2-FEATURE-COMPLETENESS-FRONTIER.94`, public AXI same-ID issue-order queue
policy contract selection, before parser/report metadata or generated queue
behavior. Selector `.94` chooses family-local
`(concrete-id-reuse issue-order-queue)` under the existing
`same-id-ordering` clause, with queue depth bounded by family `max-pending`
and concrete transaction inventory. It requires queue-head response demux for
accepted same-ID reuse and selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.95`,
a behavior-readiness audit, before parser/report metadata or generated queue
behavior. Audit `.95` finds generated queue-head behavior is too broad to
ship directly because current response demux is auto-ID selected-ID matching,
concrete transactions have no queue-head state, and queue enqueue needs an
admitted per-transaction request boundary. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.96`, parser/report metadata and static
validation for `issue-order-queue`, with `implementation_status:
selected_not_generated` and duplicated concrete same-ID reuse still
fail-closed until generated queue-head behavior ships. Implementation `.96`
now accepts `(concrete-id-reuse issue-order-queue)` in read/write
`same-id-ordering` arms, normalizes the report policy to `issue_order_queue`,
reports `accepted_same_id_reuse: false` and `generated_queue_behavior: false`,
keeps duplicated concrete same-ID transactions fail-closed with a
selected-not-generated diagnostic, and adds
`ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif` as a
support-accounted metadata-only sample. Audit `.97` finds that queue state and
queue-head response demux remain too broad for the next slice. The smaller
prerequisite is admitted per-transaction request pulses for selected
`issue-order-queue` families. Implementation `.98` now emits one internal
admitted-request pulse storage target plus one pulse rule per concrete
transaction in the selected family, with the guard derived from the
transaction request event, current direction pending storage, family
`max-pending`, and same-cycle completion fan-in, not from the generated
`can_accept` status output. Schedule JSON reports
`enforcement: admitted_request_boundary`,
`implementation_status: admitted_request_pulses_generated`,
`accepted_same_id_reuse: false`, `generated_queue_behavior: false`, and the
`admitted_request_boundary` pulse/rule/guard payload under
`same_id_ordering.concrete_id_reuse_policy.<family>`. Multi-transaction
selected families also emit a request mutual-exclusion assertion so one
direction-level capacity increment cannot admit multiple concrete identities
in the same cycle. Duplicated concrete same-ID reuse, queue state,
queue-head response demux, accepted same-ID reuse, direct backend lowering,
and VHDL remain fail-closed/deferred. `.98` advances the active frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.99`, the next AXI manager selector after
admitted request pulses. Selector `.99` chooses
`IAL2-FEATURE-COMPLETENESS-FRONTIER.100`, AXI same-ID issue-order queue state
and queue-head demux readiness audit, because admitted request pulses solve
only the enqueue boundary. Accepted same-ID reuse still needs bounded
queue storage, enqueue/dequeue semantics, queue-head response demux,
duplicate-ID validation changes, assertions, and residue movement to be
audited together before generated behavior changes.
Audit `.100` confirms the next behavior step should still not be direct
queue-state or queue-head demux implementation. The selected same-ID sample
reports admitted request pulses, but `accepted_same_id_reuse` and
`generated_queue_behavior` remain false. Existing generated response demux is
auto-ID busy/selected-ID matching, including the read burst-last path, so
queue-head demux needs queue identity state first. The active frontier is now
`IAL2-FEATURE-COMPLETENESS-FRONTIER.101`, bounded AXI same-ID issue-order
queue state representation selection, to pin down grouping, bounds, storage
shape, transaction identity encoding, diagnostics, assertions, report
vocabulary, and the later implementation split before duplicate concrete
same-ID reuse can be accepted.
Selector `.101` chooses `compact_onehot_transaction_slots` as the future
generated queue representation: family-local and concrete-ID-value-local
compacted slots, slot `0` as head, one explicit transaction identity bit per
slot/transaction, depth bounded by `min(max-pending, concrete transaction
inventory)`, enqueue sourced only from admitted request pulses, and no arrays,
dynamic indexed left-hand sides, hidden unbounded queues, or pointer modulo
arithmetic. It also finds that implementation still needs a concrete same-ID
queue-head response-demux source contract because the current
`response-demux` syntax and implementation are auto-ID-lifecycle oriented.
The active frontier is now `IAL2-FEATURE-COMPLETENESS-FRONTIER.102`, AXI
same-ID queue-head response-demux contract selection.
Selector `.102` reuses the existing `response-demux` read/write family arms
for concrete same-ID queue-head demux, but only when the same family selects
`concrete-id-reuse issue-order-queue`, has duplicate concrete-ID groups, and
does not also require same-family auto-ID demux in the first contract. The
selected report modes are `bounded_write_bid_queue_head_demux_contract` and
`bounded_read_rid_queue_head_demux_contract`, both selected-not-generated
until behavior ships. The active frontier is now
`IAL2-FEATURE-COMPLETENESS-FRONTIER.103`, AXI same-ID queue-head
response-demux metadata/static validation.
Implementation `.103` ships that selected-not-generated metadata and static
validation. The public sample
`ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif`
uses two concrete read transactions sharing ID `3`, selected
`issue-order-queue`, and a burst-last read `response-demux` arm. Schedule JSON
reports `bounded_read_rid_queue_head_demux_contract`,
`implementation_status: selected_not_generated`,
`transaction_completion_source: generated_queue_head_demux`, and the duplicate
concrete-ID queue group, while `accepted_same_id_reuse` and
`generated_queue_behavior` remain false. Read-data consumption of this
selected-not-generated queue-head demux fails closed. The active frontier is
now `IAL2-FEATURE-COMPLETENESS-FRONTIER.104`, generated same-ID queue
state/queue-head behavior readiness. Audit `.104` finds no obvious new
IAL1/IAL0/SystemVerilog substrate prerequisite for the first bounded generated
same-ID behavior slice, but direct broad implementation is still too large:
queue state needs a queue-head-demux dequeue event, and queue-head demux needs
queue-head transaction identity from queue state. The active frontier advances
to `IAL2-FEATURE-COMPLETENESS-FRONTIER.105`, first generated AXI same-ID queue
state and queue-head behavior slice selection, before generated queue behavior
or accepted same-ID reuse can change. Selector `.105` chooses the first
generated behavior implementation boundary as the existing read burst-last
queue-head sample shape: one duplicate concrete read-ID group, two read
transactions, computed depth 2, generated compact one-hot queue state, and
generated queue-head completion demux shipped together. The active frontier
advances to `IAL2-FEATURE-COMPLETENESS-FRONTIER.106`, generated AXI same-ID
read burst-last queue state and queue-head demux behavior. Implementation
`.106` now ships that bounded behavior for the public sample: `r0`/`r1`
completion names are generated pulse outputs, raw read response/RID/RLAST are
generated inputs, compact one-hot depth-2 queue slots track issue order, finite
enqueue/dequeue/same-cycle update rules maintain the queue, and queue-head
last-beat matches pulse the covered transaction completions. Schedule JSON now
reports `response_demux.generated_behavior: true`,
`same_id_ordering.generated_behavior: true`,
`accepted_same_id_reuse: true`, and `generated_queue_behavior: true` only for
that covered read burst-last two-transaction depth-2 shape. Write behavior,
read `single-beat`, deeper or multiple groups, same-family mixed auto-ID,
read-data consumption of concrete queue-head demux, direct backend, and VHDL
remain deferred. The active frontier advances to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.107`, the next same-ID queue behavior
expansion audit/selector. Selector `.107` chooses the next behavior owner as
`IAL2-FEATURE-COMPLETENESS-FRONTIER.108`: generated write-family concrete
same-ID queue-head behavior for exactly one duplicate write-ID group of two
transactions at depth 2. That next slice should reuse compact one-hot queue
slots and queue-head `BID` demux, while keeping read `single-beat`, deeper or
multiple groups, same-family mixed auto-ID, read-data consumption, direct
backend, and VHDL deferred.
Implementation `.108` ships that bounded write behavior for
`ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif`.
The covered write sample generates admitted write enqueue pulses, compact
one-hot depth-2 queue slots for concrete write ID `3`, finite queue updates,
generated `axi0_w0_complete`/`axi0_w1_complete` pulse outputs, and queue-head
`BID` demux rules guarded by `axi0_write_complete`, `axi0_bid == 4'd3`, and
the slot-0 transaction bit. Schedule JSON reports
`generated_write_bid_queue_head_demux`, accepted same-ID reuse, and generated
queue behavior for that write shape. At that point, read `single-beat`
remained deferred until `.110`; deeper or multiple groups, same-family mixed
auto-ID, read-data consumption of concrete queue-head demux, direct backend,
and VHDL remain deferred.
After `.108`, the frontier advanced to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.109`, the same-ID queue behavior
expansion audit/selector after shipped read burst-last and write depth-2
queue-head behavior.
Selector `.109` chooses
`IAL2-FEATURE-COMPLETENESS-FRONTIER.110`: generated read `single-beat`
concrete same-ID queue-head behavior for one duplicate read-ID group of two
transactions at depth 2. Implementation `.110` ships that bounded shape for
`ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif`:
compact one-hot read queue slots, admitted read enqueue pulses, generated read
completion pulse outputs, queue-head `RID` demux rules without `RLAST`,
support-accounting coverage, and Verilator-clean generated SystemVerilog.
Read-data consumption, deeper or multiple groups, same-family mixed auto-ID,
generalized per-ID queues, direct backend, and VHDL remain deferred. The
`.111` selector chooses `IAL2-FEATURE-COMPLETENESS-FRONTIER.112`, AXI
read-data consumption of generated concrete same-ID queue-head demux
readiness. Existing generated read-data capture consumes generated auto-ID
read response-demux completion pulses, but the current contract still
fail-closes when `read_data` consumes a concrete queue-head read demux. Audit
`.112` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.113`,
generated single-beat read-data capture for the bounded read single-beat
concrete same-ID queue-head demux shape. No lowerer prerequisite is evident:
the behavior slice must make read-data coverage source-aware for generated
queue-head completion signals instead of only auto-ID transaction lists, then
add the combined public sample, tests, support accounting, and docs.
Implementation `.113` now ships that bounded behavior for
`ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif`:
generated `RDATA`/`RRESP` inputs, per-transaction data/status outputs,
capture rules guarded by generated queue-head completion pulses, and
`completion_validity: generated_queue_head_response_demux_completion_pulse`
while preserving existing auto-ID read-data report values. Selector `.114`
selected `.115`, generated last-beat read-data capture for the bounded read
burst-last concrete same-ID queue-head demux shape. Implementation `.115` now
ships that bounded behavior for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif`:
the generator reuses the already generated `RLAST`-qualified queue-head
completion pulses, emits generated `RDATA`/`RRESP` inputs plus
per-transaction last-beat data/status outputs, guards capture rules with the
generated queue-head last-beat completion pulses, and reports
`generated_queue_head_response_demux_last_beat_completion_pulse` while
preserving existing auto-ID last-beat and queue-head single-beat read-data
report values. Selector `.116` chose `.117`, generated raw-`ARLEN`
burst-length capture for the bounded queue-head last-beat read-data shape.
Implementation `.117` now ships that bounded report-only burst-length behavior
for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif`:
the generator emits generated `axi0_arlen` input, per-transaction raw-`ARLEN`
storage, request-guarded burst-length capture rules, the existing queue-head
last-beat `RDATA`/`RRESP` capture rules, and report fields with
`burst_length_generated_behavior: true` while keeping
`completion_validity: generated_queue_head_response_demux_last_beat_completion_pulse`.
Selector `.118` chose `.119`, generated queue-head beat-count/RLAST runtime
validation for the bounded queue-head last-beat read-data shape.
Implementation `.119` now ships that runtime-validation sibling for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`:
the generator preserves request-bound raw-`ARLEN` capture and queue-head
last-beat `RDATA`/`RRESP` capture, adds expected-count storage,
matched-read-beat counters, initialization/increment rules, and runtime
assertions for request-time `ARLEN` bounds, over-count/extra beats, early
`RLAST`, and missing final `RLAST`. It keeps the queue-head last-beat
completion-validity report and counts matched read beats from raw response
event plus concrete `RID` plus active queue-head transaction identity before
any multi-beat queue-head read-data, deeper or multiple queue groups, mixed
auto-ID, direct backend, or VHDL work.
Implementation `.121` now ships generated multi-beat read-data output-bank
behavior for the same bounded read burst-last concrete same-ID queue-head
demux shape in
`ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif`.
The generated path emits request-time output-bank clearing, per-beat
`RDATA`/`RRESP` lane captures guarded by raw matched queue-head read beat
plus beat-count lane index, valid-mask and length outputs, scalar `RRESP`
aggregation, generated beat-count/`RLAST` validation artifacts, and empty
`read_data`/`response_demux` residue for that bounded sample.
Selector `.122` chose `.123`, a readiness audit for multiple independent read
burst-last depth-2 concrete same-ID queue-head response-demux groups. Audit
`.123` selected `.124`, generated read burst-last response-demux-only
queue-head behavior for two or more duplicate concrete read-ID groups, each
exactly two transactions at computed depth `2`. Implementation `.124` now
ships that behavior for
`ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif`.
The generated path emits concrete-ID-scoped compact one-hot queue storage,
finite depth-2 transition rules, generated completion pulse outputs, and
queue-head response-demux rules for `RID` `3` and `RID` `5` groups while
preserving the existing family-wide admitted-request onehot boundary.
Selector `.125` chose `.126`, readiness audit for read-data coverage over
multiple generated read burst-last concrete same-ID queue-head groups. Audit
`.126` selected `.127`, generated multi-group queue-head multi-beat read-data
output-bank behavior. Implementation `.127` now ships that behavior for
`ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif`.
The generated path flattens the `RID` `3` and `RID` `5` generated queue groups
into multi-beat read-data coverage, emits per-transaction output-bank clearing,
`RDATA`/`RRESP` lane capture, valid masks, length outputs, scalar `RRESP`
aggregation, raw-`ARLEN` capture, and beat-count/`RLAST` runtime validation,
and reports empty `read_data`/`response_demux` residue for the bounded sample.
Audit `.129` selected `.130`, generated multi-group queue-head last-beat
read-data capture. Implementation `.130` now ships that behavior for
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif`.
The generated path flattens the `RID` `3` and `RID` `5` generated queue groups
into scalar last-beat read-data coverage, emits generated `RDATA`/`RRESP`
inputs, per-transaction last-beat data/status outputs, and scalar capture rules
guarded by generated queue-head last-beat completion pulses, while keeping
`burst_length` metadata absent. Implementation `.132` now ships report-only
raw-`ARLEN` burst-length capture for the same multi-group queue-head scalar
last-beat shape:
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif`
adds the shared generated `axi0_arlen` input, per-transaction raw-`ARLEN`
storage for `r0`, `r1`, `r2`, and `r3`, request-guarded burst-length capture
rules, and preserves the generated queue-head last-beat scalar capture rules.
The report records `burst_length_validation: report_only`, the four
generated burst-length storage elements/rules, and
`generated_beat_count_validation` residue. Implementation `.135` now ships
the runtime-validation sibling for the same multi-group queue-head scalar
last-beat shape:
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`
adds per-transaction expected-beat storage, matched read-beat counters,
request-time initialization, raw queue-head matched-beat increment rules, and
beat-count/`RLAST` runtime assertions across `r0`, `r1`, `r2`, and `r3`, while
preserving scalar final `RDATA`/`RRESP` outputs guarded by generated
queue-head last-beat completion pulses. The report records
`burst_length_validation: runtime_assertion`, generated expected-beat and
beat-count artifacts, and removes `generated_beat_count_validation` residue
for that bounded sample.
Selector `.131` chose `.132`, generated report-only raw-`ARLEN` burst-length
capture for the multi-group queue-head scalar last-beat read-data shape, and
`.132` completed that implementation boundary. Selector `.133` chose `.134`,
readiness audit for generated runtime-validation multi-group queue-head scalar
last-beat read-data, because the next behavior would add expected-beat
storage, matched-beat counters, and beat-count/`RLAST` assertions across
multiple queue groups while preserving scalar final outputs. Audit `.134`
found no new IAL1, IAL0, SystemVerilog, direct-backend, or VHDL prerequisite;
the remaining local blocker is the queue-head read-data coverage gate. It
selected `.135`, and `.135` completed that implementation boundary. Same-family
auto-ID, deeper queues, read single-beat multi-group queue-head
behavior, packed outputs, direct backend, and VHDL remain deferred.
Selector `.136` chose `.137`, narrow report/static residue cleanup, because
the shipped `.135` live report supports runtime-validation multi-group
queue-head scalar last-beat read-data while one AXI ID/order support-detail
string and focused PPIF/parser assertion still preserve stale unsupported
wording for that exact behavior. `.137` completed that cleanup: the report
now describes generated runtime-validation multi-group queue-head scalar
last-beat read-data as supported, focused parser expectations reject the
retired unsupported-residue wording, and `.135`, `.132`, `.130`, `.127`,
`.124`, and `.119` live schedule behavior is preserved. The active frontier is
`.139`, readiness audit for generated write-family multi-group queue-head
response-demux. Selector `.138` chose that audit because a temporary two-group
write probe reported two duplicate concrete write-ID groups but remained
metadata-only with `generated_same_id_queue_head_demux` residue, while the
one-group write queue-head sample and read burst-last multi-group queue-head
behavior are already generated. Audit `.139` found no new parser,
support-accounting, generated-artifact, lowerer, direct-backend, or VHDL
prerequisite: downstream queue storage, transition, assertion, response-demux
state/rule, report, and residue helpers already group-iterate for write once
behavior exists. `.140` shipped that generated write-family multi-group
queue-head response-demux for
`ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif`:
`BID` `3` covers `w0`/`w1`, `BID` `5` covers `w2`/`w3`, every generated
group remains depth `2`, generated completion signals cover `w0` through
`w3`, and `generated_same_id_queue_head_demux` residue is removed for the
covered write family. The implementation preserves the family-wide
admitted-request onehot boundary and leaves group-local simultaneous enqueue
widening deferred. Selector `.141` chose `.142`, readiness audit for generated
read single-beat multi-group queue-head response-demux, because a temporary
read single-beat two-group probe reported two duplicate concrete read-ID
groups but remained selected-not-generated with
`generated_same_id_queue_head_demux` residue while adjacent read burst-last
multi-group, read single-beat one-group, and write multi-group queue-head
response-demux shapes were generated. Audit `.142` found no new parser,
support-accounting, lowerer, direct-backend, or VHDL prerequisite; queue-head
planning, storage, transition, assertion, response-demux rule, report, and
residue helpers already group-iterate for read single-beat once behavior
exists. `.143` shipped generated read single-beat multi-group queue-head
response-demux for
`ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif`:
`RID` `3` covers `r0`/`r1`, `RID` `5` covers `r2`/`r3`, every generated
group remains depth `2`, generated completion signals cover `r0` through
`r3`, no `RLAST` or `read_data` behavior is introduced, and
`generated_same_id_queue_head_demux` residue is removed for the covered read
single-beat response-demux-only family. Strict check JSON and normalized
semantic JSON match the support-accounting entry for the sample, keeping the
MCP-facing deep semantic introspection surface aligned with the public support
catalog. Selector `.144` chose `.145`, readiness audit for generated
read-data over read single-beat multi-group queue-head groups. Audit `.145`
found no new parser, IAL1, IAL0/SystemVerilog, direct-backend, or VHDL
prerequisite and selected `.146`, the bounded implementation owner. `.146`
shipped generated read-data over read single-beat multi-group queue-head
response-demux for
`ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif`:
`RID` `3` covers `r0`/`r1`, `RID` `5` covers `r2`/`r3`, generated
`axi0_rdata`/`axi0_rresp` inputs feed scalar per-transaction captures, and
the capture rules are guarded by generated queue-head completion pulses with
`completion_validity:
generated_queue_head_response_demux_completion_pulse`. Strict check JSON and
normalized semantic JSON match the new support-accounting entry. Selector
`.147` chose `.148`, readiness audit for generated concrete same-ID
queue-head groups deeper than two slots, after live reports confirmed all
generated queue-head families remain depth-2 and code inspection found the
builder, storage, transition matrix, state/full helpers, and assertions
specialized around slots `0` and `1`. Same-family mixed auto-ID, group-local
enqueue widening, packed outputs, direct backend, and VHDL remain deferred.
The IAL2 factoring stance remains evidence-driven: keep AXI-specific same-ID
ordering in the AXI vocabulary until another profile proves the same semantic
need.
Full-manager behavior, profile aliases, queued/blocking policy, direct
backend lowering, and VHDL remain residue. VHDL remains behind SV-backed IAL
feature completeness.

The project objective is robust, traceable FSM-to-HDL generation with clear assignment semantics, optimization via AST factorization, and behavior-preserving refactoring toward a modular architecture.

## Fast ramp-up order
1. `README.md` (this file): project objective + navigation.
2. `COMMIT.md`: mandatory commit workflow and safety invariant for crash recovery; pair it with `DOCTRINE_ENFORCEMENT.md` and `TOOLBOX.md` for the mechanical rule gate and diagnostic commands.
3. `SESSION_BOOTSTRAP.md`: default first task for a new engineering session.
4. `ROADMAP_STATUS.md`: canonical live roadmap/workstream status.
5. `docs/TASK_TREE_README.md`: setup guide for adopting this task-tree tracking workflow in another project.
6. `docs/TASK_TREE.md`: repo-local task-tree workflow, active tree index, and PNT frontier rules.
7. `ROADMAP_V2.md`: detailed post-`R0`..`R7` roadmap intent and sequencing.
8. `docs/book/src/SUMMARY.md`: progressive mdBook table of contents.
9. `docs/USER_GUIDE.md`: broad live reference during the book split.
10. `docs/COMPOSITION_SCOPE.md`: concrete `R6` composition scope and acceptance boundary.
11. `docs/COMPOSITION_LEGACY_MAPPING.md`: historical `fx/bin/fsmgen` composition behavior mapped onto the active `R6` plan.
12. `docs/EXTENSION_MODEL.md`: active `R7` typed extension boundary replacing legacy `.plg` / `PPlugin` as architecture direction.
13. `docs/SPECFORGE_FEEDBACK_RESPONSE.md`: FSMGen's tracked response and alignment plan for SPECFORGE adapter feedback.
14. `docs/INTENT_SCHEDULING_BRAINSTORM.md`: living brainstorm log for an intent-scheduling layer above explicit cycle-authored `.fsm`.
15. `docs/ISF_ATL_DESIGN_PROPOSAL.md`: live design proposal for ISF Actor Transfer Level actor-network orchestration.
16. `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`: single self-contained downstream `.isf` integration handoff plus `.ppif`/IAL2-to-IAL1 lowering-stack boundary.
17. `docs/DOWNSTREAM_ISSUE_REPORTING.md`: strict downstream issue-reporting protocol for local FSMGen reproduction.
18. `docs/ISF_SPEC.md`: active R14 `.isf` Intent Scheduling Format specification.
19. `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`: live downstream-consumer API contract for ISF parser/scheduler surfaces.
20. `docs/ISF_LIBRARY_CATALOG.md`: live catalog of shipped reusable ISF library definitions.
21. `docs/BIN_FSMGEN_IMPORT_TREE.md`: live `bin/fsmgen` import-tree and runtime-spine architecture snapshot.
22. `docs/REGRESSION_CORPUS.md`: human-readable regression/support-accounting corpus companion.
23. `docs/INTENT_CAPTURE_AXI_CASE_STUDY.md`: AXI intent-capture case-study notes for future high-level synthesis work.
24. `docs/IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md`: first non-code IAL2 protocol/platform intent evaluation and go/no-go criteria.
25. `docs/AXI_VALID_READY_INTENT_PROBE.md`: first AXI Valid-Ready source-anchor evidence inventory for future IAL2 design/probe work.
26. `docs/AXI_MANAGER_USER_API_BRAINSTORM.md`: captured AXI manager user-facing API direction for future IAL2 work.
27. `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`: first AXI ID/order/concurrency source-anchor evidence inventory for future IAL2 manager rule-engine work.
28. `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`: first AXI manager source-to-rule responsibility matrix for future IAL2 work.
29. `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md`: selected the first post-Valid-Ready AXI manager subset: outstanding-capacity plus acceptance/status feedback.
30. `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_READINESS_AUDIT.md`: readiness audit for the selected AXI manager capacity/status subset and first in-process generator boundary.
31. `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_GENERATOR_FIRST_SLICE.md`: first in-process AXI manager capacity/status generator slice and report surface.
32. `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_SYNTAX_SELECTION.md`: selected public `.ppif` syntax/readiness boundary for one AXI manager capacity/status object.
33. `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md`: first public `.ppif` parser/CLI slice for one AXI manager capacity/status object.
34. `docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md`: selected the next AXI manager subset: ID-family declaration and static validation.
35. `docs/AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md`: readiness audit for the additive ID-family/static-validation implementation boundary.
36. `docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md`: shipped additive `.ppif` ID-family metadata slice for one AXI manager capacity/status object.
37. `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md`: selected the next AXI manager subset: logical read/write transaction envelope and static validation.
38. `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md`: readiness audit for the additive transaction-envelope/static-validation implementation boundary.
39. `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md`: shipped additive `.ppif` transaction-envelope metadata slice for one AXI manager capacity/status object.
40. `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md`: selected the next prerequisite: transaction event dispatch and direction fan-in.
41. `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md`: readiness audit for additive per-transaction event dispatch and direction fan-in.
42. `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md`: shipped additive `.ppif` transaction event dispatch/fan-in slice for one AXI manager capacity/status object.
43. `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md`: selected the next AXI manager subset: ID/response rule-engine readiness.
44. `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md`: readiness audit for additive concrete transaction ID request/response assertions.
45. `docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md`: shipped additive concrete transaction ID request/response assertions for the public AXI manager capacity/status object.
46. `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md`: selected AXI manager auto-ID lifecycle/request-ID drive readiness as the next subset.
47. `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md`: readiness audit selecting bounded auto-ID pool/request-ID drive contract selection before implementation.
48. `docs/AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md`: selected explicit optional `auto-id-lifecycle` bounded-pool syntax before parser/report implementation.
49. `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_METADATA_FIRST_SLICE.md`: shipped additive `.ppif` auto-ID lifecycle parser/report metadata for one AXI manager capacity/status object.
50. `docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md`: shipped bounded auto-ID request-ID drive behavior for explicit lifecycle families.
51. `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION.md`: selected AXI manager generated response-demux readiness after bounded auto-ID request-ID drive.
52. `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md`: readiness audit selecting bounded write response-demux public contract before implementation.
53. `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md`: selected explicit write-only `response-demux` public syntax before parser/report implementation.
54. `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`: shipped write-only `response-demux` parser/report metadata for one AXI manager capacity/status object.
55. `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md`: readiness audit selecting the IAL1 rule-pulse prerequisite before generated write `BID` demux behavior.
56. `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`: shipped generated write `BID` response-demux behavior for explicit `response-demux` contracts.
57. `docs/AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION.md`: selected report-residue alignment after generated write `BID` demux before larger ordering/read-response work.
58. `docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md`: shipped auto-ID lifecycle report-residue alignment after generated write `BID` demux.
59. `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION.md`: selected same-ID ordering readiness after generated write response demux and residue alignment.
60. `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT.md`: readiness audit selecting bounded auto-ID same-ID avoidance assertions/report metadata before per-ID queues.
61. `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md`: shipped bounded generated auto-ID same-ID avoidance assertions/report metadata.
62. `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md`: selected read `RID` response-demux readiness after generated auto-ID same-ID avoidance.
63. `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md`: readiness audit selecting a bounded read response-demux public contract before parser/report or behavior changes.
64. `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md`: selected explicit `response-scope single-beat` read response-demux syntax before parser/report implementation.
65. `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`: shipped read response-demux parser/report metadata and static validation without generated read behavior.
66. `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md`: readiness audit selecting bounded generated single-beat read `RID` response-demux behavior before implementation.
67. `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`: shipped bounded generated single-beat read `RID` response-demux behavior.
68. `docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md`: selected read-data payload/burst readiness after generated read response demux.
69. `docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md`: readiness audit selecting bounded read-data contract selection before parser/report or behavior changes.
70. `docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md`: selected explicit bounded `read-data` syntax for single-beat `RDATA`/`RRESP` metadata.
71. `docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md`: shipped read-data parser/report metadata and static validation without generated data-capture behavior.
72. `docs/AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md`: readiness audit selecting direct generated single-beat `RDATA`/`RRESP` capture behavior before implementation.
73. `docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md`: shipped generated single-beat `RDATA`/`RRESP` capture behavior for explicit `read-data` contracts.
74. `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT.md`: readiness audit selecting public burst/`RLAST` completion contract selection before parser/report or generated behavior changes.
75. `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md`: selected additive `response-scope burst-last` plus one-bit `last-signal` syntax before parser/report implementation.
76. `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md`: shipped parser/report metadata and static validation for `response-scope burst-last` with generated behavior deferred.
77. `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT.md`: readiness audit selecting direct generated burst-last/`RLAST` completion behavior.
78. `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md`: shipped generated burst-last/`RLAST` completion behavior.
79. `docs/AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION.md`: selected AXI `RLAST` report/static-text alignment after generated `RLAST` behavior.
80. `docs/AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md`: shipped AXI `RLAST` schedule-report prose alignment after generated behavior.
81. `docs/AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION.md`: selected public AXI burst read-data contract selection after generated `RLAST` completion/report alignment.
82. `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md`: selected explicit last-beat `RDATA`/`RRESP` capture as the first bounded burst read-data contract.
83. `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md`: shipped parser/report metadata and static validation for explicit last-beat `RDATA`/`RRESP` capture with generated behavior deferred.
84. `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md`: readiness audit selecting direct generated last-beat `RDATA`/`RRESP` capture behavior.
85. `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md`: shipped generated last-beat `RDATA`/`RRESP` capture behavior.
86. `docs/AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md`: selected public AXI burst read-data beat-count/depth contract selection after generated last-beat capture.
87. `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md`: selected ARLEN-based `burst-length` syntax and report contract before parser/report metadata.
88. `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md`: shipped parser/report metadata and static validation for ARLEN-based `burst-length` contracts.
89. `docs/AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION.md`: selected generated ARLEN burst-length capture readiness audit after report-only metadata.
90. `docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_READINESS_AUDIT.md`: audited generated raw-ARLEN capture readiness and selected direct behavior.
91. `docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md`: shipped generated raw-ARLEN capture behavior for opt-in last-beat read-data `burst-length` contracts.
92. `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT.md`: audited beat-count/RLAST validation readiness and selected public runtime-validation contract selection before behavior.
93. `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md`: selected `(validation runtime-assertion)` / `runtime_assertion` as the public beat-count/RLAST validation contract before behavior.
94. `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md`: shipped generated beat-count/RLAST runtime validation for `(validation runtime-assertion)` burst-length contracts.
95. `docs/AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md`: selected public multi-beat read-data reassembly/output contract selection after generated beat-count/RLAST validation.
96. `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md`: selected per-beat output-bank public contract for multi-beat read-data reassembly/output.
97. `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md`: shipped parser/report metadata and static validation for the public multi-beat read-data output-bank contract.
98. `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT.md`: audited generated output-bank behavior readiness and selected direct scalar-lane behavior.
99. `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md`: shipped generated multi-beat read-data output-bank behavior for the public multi-beat sample.
100. `docs/AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION.md`: selected public scalar `RRESP` aggregation contract selection after generated multi-beat read-data output-bank behavior.
101. `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md`: selected additive scalar `RRESP` aggregation syntax and report contract before parser/report metadata.
102. `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE.md`: shipped parser/report metadata and static validation for the selected scalar `RRESP` aggregation contract.
103. `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_READINESS_AUDIT.md`: audited generated scalar `RRESP` aggregation readiness and selected direct generated behavior.
104. `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE.md`: shipped generated scalar `RRESP` aggregation outputs/init/update behavior.
105. `docs/AXI_IAL2_MANAGER_POST_RRESP_AGGREGATION_NEXT_SLICE_SELECTION.md`: selected per-ID read-data interleaving and queue readiness after scalar `RRESP` aggregation.
106. `docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT.md`: audited read-data interleaving/queue readiness and selected report/static residue alignment for the covered generated auto-ID multi-beat-by-RID subset.
107. `docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE.md`: aligned read-data interleaving residue for the covered generated auto-ID multi-beat-by-RID subset.
108. `docs/AXI_IAL2_MANAGER_POST_INTERLEAVING_ALIGNMENT_NEXT_SLICE_SELECTION.md`: selected AXI burst payload/output readiness audit after read-data interleaving residue alignment.
109. `docs/AXI_IAL2_MANAGER_BURST_PAYLOAD_OUTPUT_READINESS_AUDIT.md`: audited bounded burst payload/output readiness and selected report/static `bursts` residue alignment.
110. `docs/AXI_IAL2_MANAGER_BURST_RESIDUE_ALIGNMENT_FIRST_SLICE.md`: aligned broad `bursts` residue for the covered generated auto-ID multi-beat output-bank subset.
111. `docs/AXI_IAL2_MANAGER_POST_BURST_RESIDUE_NEXT_SLICE_SELECTION.md`: selected AXI concrete-ID same-ID ordering readiness after bounded burst residue alignment.
112. `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT.md`: audited concrete-ID same-ID ordering readiness and selected fail-closed static validation.
113. `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md`: shipped fail-closed static validation for unsupported same-family concrete-ID reuse.
114. `docs/AXI_IAL2_MANAGER_POST_CONCRETE_ID_STATIC_VALIDATION_NEXT_SLICE_SELECTION.md`: selected per-ID issue-order queue readiness after concrete-ID static validation.
115. `docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md`: audited per-ID issue-order queue readiness and selected same-ID reuse policy contract selection.
116. `docs/AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md`: selected explicit same-ID reuse reject policy syntax before parser/report metadata.
117. `docs/AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md`: shipped parser/report metadata and static validation for explicit same-ID reuse reject policy.
118. `docs/AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION.md`: selected same-ID issue-order queue policy contract selection after explicit reject policy.
119. `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md`: selected the public AXI same-ID `issue-order-queue` policy contract and the follow-up behavior-readiness audit.
120. `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT.md`: audited same-ID `issue-order-queue` behavior readiness and selected metadata-first support.
121. `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md`: shipped metadata-first parser/report support for selected-not-generated `issue-order-queue`.
122. `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md`: audited admitted enqueue readiness and selected admitted request pulses before queue state.
123. `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md`: shipped admitted request pulse generation for selected same-ID `issue-order-queue` families while accepted same-ID reuse remains deferred.
124. `docs/AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION.md`: selected same-ID issue-order queue state and queue-head demux readiness after admitted request pulses.
125. `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_DEMUX_READINESS_AUDIT.md`: audited same-ID issue-order queue state and queue-head demux readiness after admitted request pulses.
126. `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION.md`: selected compact one-hot transaction slots as the future bounded same-ID queue representation.
127. `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_CONTRACT_SELECTION.md`: selected the public/report contract for concrete same-ID queue-head response demux.
128. `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`: shipped selected-not-generated same-ID queue-head response-demux parser/report metadata and static validation.
129. `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md`: audited generated same-ID queue state plus queue-head behavior readiness and selected the first generated behavior slice selector.
130. `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION.md`: selected the first generated same-ID queue behavior implementation boundary.
131. `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md`: shipped bounded generated read burst-last depth-2 concrete same-ID queue state plus queue-head response demux.
132. `docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`: shipped bounded generated write depth-2 concrete same-ID queue state plus queue-head `BID` response demux.
133. `docs/AXI_IAL2_MANAGER_POST_WRITE_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md`: selected read `single-beat` depth-2 concrete same-ID queue-head response demux as the next bounded behavior slice.
134. `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`: shipped bounded generated read single-beat depth-2 concrete same-ID queue state plus queue-head `RID` response demux without `RLAST`.
135. `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md`: selected queue-head read-data consumption readiness after generated read single-beat same-ID queue-head behavior.
136. `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md`: audited queue-head read-data readiness and selected generated single-beat queue-head read-data capture.
137. `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE.md`: shipped generated single-beat queue-head `RDATA`/`RRESP` capture for the bounded read single-beat concrete same-ID queue-head sample.
138. `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md`: selected generated last-beat queue-head `RDATA`/`RRESP` capture for the bounded read burst-last concrete same-ID queue-head sample.
139. `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md`: shipped generated last-beat queue-head `RDATA`/`RRESP` capture for the bounded read burst-last concrete same-ID queue-head sample.
140. `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md`: selected generated raw-`ARLEN` burst-length capture for the bounded queue-head last-beat read-data shape.
141. `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md`: shipped report-only raw-`ARLEN` burst-length capture for the bounded queue-head last-beat read-data sample.
142. `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md`: selected generated queue-head beat-count/RLAST runtime validation for the bounded queue-head last-beat read-data shape.
143. `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`: shipped generated queue-head beat-count/RLAST runtime validation for the bounded queue-head last-beat read-data sample.
144. `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`: selected generated queue-head multi-beat read-data output-bank behavior for the bounded read burst-last concrete same-ID queue-head demux shape.
145. `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`: shipped generated queue-head multi-beat read-data output-bank behavior for the bounded read burst-last concrete same-ID queue-head sample.
146. `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md`: selected multiple independent read burst-last depth-2 concrete same-ID queue-head response-demux group readiness after generated queue-head multi-beat read-data.
147. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md`: audited multiple depth-2 read burst-last queue-head response-demux groups and selected the narrow implementation owner.
148. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`: shipped generated multiple read burst-last depth-2 concrete same-ID queue-head response-demux groups.
149. `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_DEMUX_NEXT_SLICE_SELECTION.md`: selected read-data-over-multiple-generated-queue-groups readiness after generated multi-group queue-head demux.
150. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md`: audited read-data coverage over multiple generated queue-head groups and selected multi-beat output-bank behavior.
151. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`: shipped generated multi-group queue-head multi-beat read-data output-bank behavior.
152. `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md`: selected last-beat-only read-data over multiple generated queue-head groups as the next audit owner.
153. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md`: audited scalar last-beat read-data over multiple generated queue-head groups and selected the narrow implementation owner.
154. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md`: shipped generated multi-group queue-head scalar last-beat read-data capture.
155. `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md`: selected generated report-only raw-`ARLEN` capture for multi-group queue-head scalar last-beat read-data.
156. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md`: shipped generated report-only raw-`ARLEN` capture for multi-group queue-head scalar last-beat read-data.
157. `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md`: selected runtime-validation multi-group queue-head scalar last-beat readiness audit.
158. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md`: audited runtime-validation multi-group queue-head scalar last-beat readiness and selected the implementation owner.
159. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`: shipped generated runtime-validation multi-group queue-head scalar last-beat read-data and records the `.137` support-report residue alignment.
160. `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`: selected report/static residue cleanup after generated runtime-validation multi-group queue-head scalar last-beat read-data.
161. `docs/AXI_IAL2_MANAGER_POST_SUPPORT_RESIDUE_CLEANUP_NEXT_SLICE_SELECTION.md`: selected write-family multi-group queue-head response-demux readiness audit after support-residue cleanup.
162. `docs/AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md`: audited generated write-family multi-group queue-head response-demux readiness and selected the implementation owner.
163. `docs/AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`: shipped generated write-family multi-group queue-head response-demux behavior.
164. `docs/AXI_IAL2_MANAGER_POST_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`: selected read single-beat multi-group queue-head response-demux readiness audit after generated write-family multi-group queue-head response-demux.
165. `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md`: audited generated read single-beat multi-group queue-head response-demux readiness and selected the implementation owner.
166. `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`: shipped generated read single-beat multi-group queue-head response-demux behavior.
167. `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`: selected read-data over read single-beat multi-group queue-head readiness audit after generated read single-beat multi-group response-demux.
168. `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md`: audited generated read-data over read single-beat multi-group queue-head readiness and selected the implementation owner.
169. `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`: shipped generated read-data over read single-beat multi-group queue-head response-demux behavior.
170. `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md`: selected deeper concrete same-ID queue-head readiness audit after generated read-data over read single-beat multi-group queue-head response-demux.
171. `docs/AXI_IAL2_MANAGER_DEEPER_QUEUE_HEAD_GROUPS_READINESS_AUDIT.md`: audited generated concrete same-ID queue-head groups deeper than two slots and selected the depth-3 read single-beat response-demux implementation owner.
172. `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`: shipped generated read single-beat depth-3 queue-head response-demux behavior.
173. `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`: selected focused PPIF support-detail expectation alignment before the next depth-3 behavior expansion.
174. `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md`: audited generated scalar read-data over read single-beat depth-3 queue-head response-demux readiness and selected the implementation owner.
175. `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`: shipped generated scalar read-data over read single-beat depth-3 queue-head response-demux behavior.
176. `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md`: selected read burst-last depth-3 queue-head response-demux readiness audit after generated read single-beat depth-3 queue-head read-data.
177. `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md`: audited generated read burst-last depth-3 queue-head response-demux readiness and selected the implementation owner.
178. `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`: shipped generated read burst-last depth-3 queue-head response-demux behavior.
179. `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`: selected read-data over read burst-last depth-3 queue-head response-demux readiness audit after generated read burst-last depth-3 queue-head response-demux.
180. `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md`: audited generated read-data over read burst-last depth-3 queue-head response-demux readiness and selected the implementation owner.
181. `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`: shipped generated scalar last-beat read-data over read burst-last depth-3 queue-head response-demux behavior.
182. `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md`: selected report-only raw-`ARLEN` burst-length readiness after generated read burst-last depth-3 queue-head read-data.
183. `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md`: audited report-only raw-`ARLEN` burst-length over generated read burst-last depth-3 queue-head read-data readiness and selected the implementation owner.
184. `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md`: shipped generated report-only raw-`ARLEN` burst-length capture over read burst-last depth-3 queue-head read-data.
185. `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md`: selected runtime-validation readiness after generated read burst-last depth-3 queue-head report-only raw-`ARLEN` burst-length behavior.
186. `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md`: audited runtime-validation readiness over generated read burst-last depth-3 queue-head raw-`ARLEN` burst-length and selected the implementation owner.
187. `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`: shipped generated runtime beat-count/`RLAST` validation over read burst-last depth-3 queue-head raw-`ARLEN` burst-length.
188. `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`: selected multi-beat output-bank readiness after generated read burst-last depth-3 queue-head runtime-validation behavior.
189. `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md`: audited generated depth-3 multi-beat output-bank readiness and selected the implementation owner.
190. `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`: shipped generated multi-beat read-data output-bank behavior over read burst-last depth-3 queue-head runtime-validation.
191. `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md`: selected write depth-3 queue-head response-demux readiness after generated read burst-last depth-3 queue-head multi-beat read-data.
192. `docs/AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md`: audited generated write depth-3 queue-head response-demux readiness and selected the implementation owner.
193. `docs/AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`: shipped generated write depth-3 queue-head response-demux behavior.
194. `docs/AXI_IAL2_MANAGER_POST_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`: selected multiple/mixed depth-3 queue-head response-demux readiness after generated write depth-3 queue-head response-demux.
195. `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md`: audited multiple/mixed depth-3 queue-head response-demux readiness and selected the implementation owner.
196. `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`: shipped generated multiple/mixed depth-3 queue-head response-demux behavior.
197. `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`: selected read-data over multiple/mixed depth-3 queue-head groups as the next readiness audit.
198. `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md`: audited multiple/mixed depth-3 queue-head read-data readiness and selected read single-beat scalar implementation.
199. `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`: shipped generated multiple/mixed depth-3 read single-beat queue-head scalar read-data behavior.
200. `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md`: selected burst-last scalar last-beat read-data over multiple/mixed depth-3 queue-head groups as the next readiness audit.
201. `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md`: audited multiple/mixed depth-3 queue-head burst-last last-beat read-data readiness and selected the bounded implementation owner.
202. `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md`: shipped generated multiple/mixed depth-3 read burst-last queue-head scalar last-beat read-data behavior.
203. `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md`: selected report-only raw-`ARLEN` burst-length readiness over multiple/mixed depth-3 queue-head scalar last-beat read-data.
204. `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md`: audited report-only raw-`ARLEN` burst-length readiness over multiple/mixed depth-3 queue-head scalar last-beat read-data and selected the direct implementation owner.
205. `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md`: shipped generated report-only raw-`ARLEN` burst-length capture over multiple/mixed depth-3 queue-head scalar last-beat read-data.
206. `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md`: selected runtime beat-count/`RLAST` validation readiness over multiple/mixed depth-3 queue-head scalar last-beat read-data.
207. `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md`: audited runtime beat-count/`RLAST` validation readiness over multiple/mixed depth-3 queue-head scalar last-beat read-data and selected the direct implementation owner.
208. `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`: shipped generated runtime beat-count/`RLAST` validation over multiple/mixed depth-3 queue-head scalar last-beat read-data.
209. `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`: selected report/static support-residue cleanup after generated runtime beat-count/`RLAST` validation over multiple/mixed depth-3 queue-head scalar last-beat read-data.
210. `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP.md`: cleaned stale support/residue wording for generated runtime beat-count/`RLAST` validation over multiple/mixed depth-3 queue-head scalar last-beat read-data.
211. `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_RESIDUE_CLEANUP_NEXT_SLICE_SELECTION.md`: selected multi-beat output-bank readiness over multiple/mixed depth-3 runtime-validation queue-head groups.
212. `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md`: audited generated multi-beat output-bank readiness over multiple/mixed depth-3 runtime-validation queue-head groups and selected the direct implementation owner.
213. `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`: shipped generated multi-beat output-bank behavior over multiple/mixed depth-3 runtime-validation queue-head groups.
214. `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md`: selected same-family mixed auto-ID lifecycle plus concrete same-ID queue-head response-demux readiness after generated multiple/mixed depth-3 multi-beat output banks.
215. `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md`: audited same-family mixed auto-ID lifecycle plus concrete same-ID queue-head response-demux readiness and selected the direct bounded implementation owner.
216. `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`: shipped same-family mixed auto-ID lifecycle plus concrete same-ID queue-head response-demux behavior for bounded response-demux-only read single-beat, read burst-last, and write shapes.
217. `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`: selected mixed read-data consumption readiness after same-family mixed auto-ID plus concrete queue-head response-demux.
218. `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md`: audited mixed scalar read-data readiness over same-family mixed auto-ID plus concrete queue-head response-demux and selected the direct bounded implementation owner.
219. `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`: shipped bounded scalar read-data over same-family mixed auto-ID plus concrete queue-head response-demux for read single-beat and read burst-last shapes.
220. `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md`: selected mixed report-only raw-`ARLEN` burst-length readiness after bounded mixed scalar read-data.
221. `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md`: audited mixed report-only raw-`ARLEN` burst-length readiness and selected the direct support/publication owner.
222. `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md`: shipped support-accounted mixed report-only raw-`ARLEN` burst-length capture and locked mixed runtime validation as separately owned.
223. `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md`: audited mixed runtime beat-count/`RLAST` validation readiness and selected the direct implementation owner.
224. `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`: shipped support-accounted mixed runtime beat-count/`RLAST` validation.
225. `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`: selected mixed runtime validation support/static and public-contract residue cleanup after mixed runtime validation shipped.
226. `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP.md`: cleaned stale mixed runtime-validation support/static and public-contract wording after the behavior shipped.
227. `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_CLEANUP_NEXT_SLICE_SELECTION.md`: selected mixed multi-beat output-bank readiness audit after mixed runtime support cleanup.
228. `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md`: audited mixed multi-beat output-bank readiness after mixed runtime validation and selected the direct bounded implementation owner.
229. `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`: shipped generated mixed multi-beat output-bank behavior over the selected same-family mixed auto-ID plus depth-2 concrete same-ID queue-head runtime-validation shape.
230. `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md`: selected group-local simultaneous enqueue widening readiness after generated mixed multi-beat output-bank behavior.
231. `docs/AXI_IAL2_MANAGER_GROUP_LOCAL_SAME_ID_ENQUEUE_READINESS_AUDIT.md`: audited group-local same-ID enqueue readiness and selected counted admission/capacity prerequisite audit.
232. `docs/AXI_IAL2_MANAGER_COUNTED_ADMISSION_CAPACITY_READINESS_AUDIT.md`: audited counted same-ID request admission/capacity placement and selected the bounded counted capacity substrate implementation.
233. `docs/AXI_IAL2_MANAGER_COUNTED_SAME_ID_CAPACITY_SUBSTRATE_BEHAVIOR.md`: shipped counted same-ID selected-request capacity/status substrate for generated multi-group queue-head families while preserving family-wide request onehot behavior.
234. `docs/AXI_IAL2_MANAGER_POST_COUNTED_CAPACITY_NEXT_SLICE_SELECTION.md`: selected admitted-request guard alignment readiness before group-local same-ID enqueue behavior.
235. `docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_READINESS_AUDIT.md`: audited counted admitted-request guard alignment and selected bounded group-local request assertion implementation.
236. `docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_BEHAVIOR.md`: shipped counted admitted-request guard alignment and group-local request assertions for generated multi-group queue-head families.
237. `docs/AXI_IAL2_MANAGER_POST_COUNTED_GROUP_LOCAL_ENQUEUE_NEXT_SLICE_SELECTION.md`: selected dynamic same-ID issue-order queue readiness after counted group-local enqueue behavior.
238. `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_READINESS_AUDIT.md`: audited dynamic/user transaction-ID readiness and selected public contract selection before generalized per-ID queues.
239. `docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CONTRACT_SELECTION.md`: selected transaction-local `(id dynamic)` contract and dynamic-ID metadata readiness audit.
240. `docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_READINESS_AUDIT.md`: audited metadata-first `(id dynamic)` parser/report readiness and selected direct implementation.
241. `docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md`: shipped metadata-first `(id dynamic)` parser/report behavior and support-accounted dynamic-ID metadata sample.
242. `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_TRANSACTION_ID_METADATA_NEXT_SLICE_SELECTION.md`: selected generated dynamic transaction-ID capture and response matching readiness after metadata-only `(id dynamic)` support.
243. `docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md`: audited generated dynamic ID capture/matching readiness and selected bounded dynamic write `BID` contract selection.
244. `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md`: selected existing `response-demux.write` plus one dynamic write transaction as the direct generated dynamic write ID capture/matching contract.
245. `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_BEHAVIOR.md`: shipped bounded dynamic write transaction-ID capture and `BID` response matching for one explicit `response-demux.write` dynamic write transaction.
246. `docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md`: selected first AXI-derived IAL2 implementation subset and pre-code contract.
247. `docs/AXI_IAL2_VALID_READY_READINESS_AUDIT.md`: code/test/docs/report owner map for the future AXI Valid-Ready IAL2 implementation.
248. `docs/AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md`: first in-process AXI Valid-Ready IAL2 generator slice and report surface.
249. `docs/decisions/0016-ppif-is-first-public-ial2-container.md`: selects `.ppif` as the first public generic IAL2 file surface.
250. `docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md`: first public `.ppif` parser/CLI slice for one AXI Valid-Ready source object.
251. `docs/IAL2_PPIF_MULTI_VALID_READY_READINESS.md`: readiness map for future multi-channel `.ppif` Valid-Ready support.
252. `docs/IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md`: selected future aggregate bundle contract for multi-channel `.ppif` Valid-Ready support.
253. `docs/IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md`: shipped bounded multi-channel `.ppif` Valid-Ready bundle report/review-artifact behavior.
254. `docs/IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md`: shipped aggregate semantic JSON for multi-channel `.ppif` bundles.
255. `docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION.md`: selected aggregate wrapper/top HDL entry contract for multi-channel `.ppif` bundles.
256. `docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md`: shipped aggregate wrapper/top HDL entry for the tracked multi-channel `.ppif` bundle.
257. `docs/PDF_EXTRACTION_WORKFLOW.md`: portable workflow for source-anchored PDF text, table, diagram, and image extraction.
258. `docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md`: generic IAL2 file-surface candidates and layered lowering decision.
259. `docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md`: IAL2 protocol-profile extension refinement.
260. `docs/decisions/0017-ppif-valid-ready-bundle-contract.md`: future multi-channel `.ppif` bundle contract decision.
261. `docs/decisions/0018-ial-contracts-are-backend-language-neutral.md`: IAL contracts and mdBook stay backend-language-neutral for future Rust, Rust/Wasm, browser-capable JavaScript, and Dart/web parity.
262. `docs/FEATURE_BACKLOG.md`: pointer to the canonical mdBook feature backlog for deferred/not-fully-shipped user-visible work.
263. `CHANGES.md`: chronological technical changes.
264. `DEVELOPMENT_NOTES.md`: design rationale and decisions.
265. `MEMORY.md`: continuity/handoff state.
266. `LIVE_ACHIEVEMENT_STATUS.md`: latest completed roadmap-aligned slice.
267. `WARP.md`: repository-specific agent/development guidance.
268. `.agents/workflows/commit.md`: automation-oriented commit workflow description.
269. `docs/SEMANTIC_INTROSPECTION_MCP_FIRST_CLASS_SELECTION.md`: selected
     first-class semantic-introspection and MCP contract-manifest boundary.
270. `DOCTRINE_ENFORCEMENT.md`: mechanical doctrine-enforcement architecture and
     FSMGEN doctrine registry.
271. `TOOLBOX.md`: FSMGEN diagnostic and doctrine toolbox with exact issue-pinpointing
     commands.
272. `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_ID_NEXT_SLICE_SELECTION.md`:
     selected dynamic read transaction-ID capture and `RID` response matching
     readiness after generated dynamic write ID behavior.
273. `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md`:
     audited generated dynamic read transaction-ID capture and `RID` matching
     readiness and selected bounded single-beat contract selection.
274. `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md`:
     selected existing `response-demux.read` plus one dynamic read transaction
     as the direct generated bounded single-beat dynamic read ID capture and
     `RID` matching contract.
275. `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md`:
     shipped bounded single-beat dynamic read transaction-ID capture and `RID`
     response matching for one explicit `response-demux.read` dynamic read
     transaction.
276. `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_ID_NEXT_SLICE_SELECTION.md`:
     selected dynamic read burst-last/`RLAST` transaction-ID capture and
     response matching readiness after generated dynamic read ID behavior.
277. `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_READINESS_AUDIT.md`:
     audited dynamic read burst-last/`RLAST` transaction-ID capture readiness
     and selected public contract selection before behavior changes.
278. `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md`:
     selected existing `response-demux.read` burst-last syntax plus one dynamic
     read transaction as the direct generated dynamic read `RID`/`RLAST`
     matching contract.
279. `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md`:
     shipped bounded dynamic read burst-last/`RLAST` transaction-ID capture and
     `RID`/`RLAST` response matching for one explicit `response-demux.read`
     dynamic read transaction.
280. `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_NEXT_SLICE_SELECTION.md`:
     selected dynamic read-data routing readiness after generated dynamic read
     burst-last/`RLAST` response-demux behavior.
281. `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_READINESS_AUDIT.md`:
     audited dynamic read-data routing readiness and selected direct bounded
     scalar single-beat plus last-beat implementation.
282. `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md`:
     shipped bounded scalar dynamic read-data capture over generated
     single-active dynamic read response-demux for scalar single-beat and
     scalar last-beat shapes.
283. `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION.md`:
     selected AXI manager focused-suite cost cleanup before further dynamic
     behavior expansion.
284. `docs/AXI_IAL2_MANAGER_DYNAMIC_FOCUSED_SUITE_CLEANUP.md`: added bounded
     focused validation for the shipped dynamic transaction-ID family before
     dynamic burst-length readiness work.
285. `docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_READINESS_AUDIT.md`:
     audited report-only dynamic raw-`ARLEN` burst-length readiness over
     generated dynamic last-beat read-data and selected the direct
     implementation owner.
286. `docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md`:
     shipped generated report-only dynamic raw-`ARLEN` burst-length capture
     over generated single-active dynamic read last-beat read-data.
287. `docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_READINESS_AUDIT.md`:
     audited dynamic runtime beat-count/`RLAST` validation readiness over
     generated dynamic last-beat read-data and selected the direct
     implementation owner.
288. `docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md`:
     shipped generated dynamic runtime beat-count/`RLAST` validation over
     generated single-active dynamic read last-beat read-data.
289. `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`:
     selected generated dynamic multi-beat output-bank readiness after
     dynamic runtime validation shipped.
290. `docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_READINESS_AUDIT.md`:
     audited dynamic multi-beat output-bank readiness and selected direct
     bounded implementation over generated dynamic runtime validation.
291. `docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md`:
     shipped generated dynamic multi-beat read-data output-bank behavior over
     generated dynamic runtime validation.
292. `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md`:
     selected multiple/mixed dynamic response-demux readiness audit after
     generated dynamic multi-beat output banks shipped.
293. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RESPONSE_DEMUX_READINESS_AUDIT.md`:
     audited multiple/mixed dynamic response-demux readiness and selected
     public contract selection for bounded multiple dynamic write demux.
294. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md`:
     selected direct generated behavior for bounded multiple dynamic write
     response-demux with onehot0 dynamic write requests and pairwise unique
     active dynamic IDs.
295. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md`:
     shipped generated bounded multiple dynamic write response-demux for
     all-dynamic write families with onehot0 dynamic write requests and
     pairwise unique active dynamic IDs.
296. `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`:
     selected multiple dynamic read response-demux readiness audit after
     bounded multiple dynamic write response-demux shipped.
297. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md`:
     audited multiple dynamic read response-demux readiness and selected
     public contract selection for bounded multiple dynamic read demux.
298. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md`:
     selected direct generated behavior for bounded multiple dynamic read
     single-beat response-demux.
299. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md`:
     shipped generated bounded multiple dynamic read single-beat
     response-demux for all-dynamic read families with onehot0 dynamic read
     requests and pairwise unique active dynamic IDs.
300. `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`:
     selected readiness audit for multiple dynamic read burst-last/`RLAST`
     response-demux after bounded multiple dynamic read single-beat
     response-demux shipped.
301. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md`:
     audited multiple dynamic read burst-last/`RLAST` response-demux readiness
     and selected public contract selection before behavior changes.
302. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md`:
     selected direct generated behavior for bounded multiple dynamic read
     burst-last/`RLAST` response-demux.
303. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md`:
     shipped generated bounded multiple dynamic read burst-last/`RLAST`
     response-demux with raw `RID` beat assertions and final `RID && RLAST`
     completion pulses.
304. `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`:
     selected `.257`, readiness audit for read-data over generated multiple
     dynamic read response-demux.
305. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_READINESS_AUDIT.md`:
     audited read-data over generated multiple dynamic read response-demux
     and selected public contract selection before behavior changes.
306. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_CONTRACT_SELECTION.md`:
     selected direct generated behavior for bounded scalar read-data over
     generated multiple dynamic read response-demux.
307. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md`:
     shipped generated bounded scalar read-data over generated multiple
     dynamic read response-demux with public single-beat and last-beat
     samples.
308. `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION.md`:
     selected readiness audit for burst-length/runtime validation over
     generated multiple dynamic read response-demux after scalar multiple
     dynamic read-data shipped.
309. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_READINESS_AUDIT.md`:
     audited burst-length/runtime validation readiness over generated multiple
     dynamic read response-demux and selected public contract selection.
310. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_CONTRACT_SELECTION.md`:
     selected a split public contract: report-only multiple dynamic raw-ARLEN
     capture first, then runtime beat-count/RLAST validation.
311. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR.md`:
     shipped generated report-only raw-ARLEN burst-length capture over
     generated multiple dynamic read response-demux and scalar last-beat
     read-data.
312. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md`:
     shipped generated runtime beat-count/RLAST validation over generated
     multiple dynamic read response-demux and scalar last-beat read-data.
313. `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`:
     selected generated multiple dynamic multi-beat output-bank readiness
     audit after multiple dynamic runtime validation shipped.
314. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_READINESS_AUDIT.md`:
     audited generated multiple dynamic multi-beat output-bank readiness and
     selected public contract selection before behavior changes.
315. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_CONTRACT_SELECTION.md`:
     selected direct generated implementation of bounded multiple dynamic
     multi-beat output-bank behavior and reserved the explicit
     `dynamic_read_data_multi_transaction_multi_beat` public sample stem.
316. `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md`:
     shipped generated bounded multiple dynamic multi-beat output-bank
     behavior over generated multiple dynamic runtime validation.
317. `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md`:
     selected mixed dynamic/static response-demux readiness after generated
     bounded multiple dynamic multi-beat output banks shipped.
318. `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md`:
     audited mixed dynamic/static response-demux readiness and selected public
     contract selection for bounded mixed dynamic/static write `BID`
     response-demux.
319. `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md`:
     selected direct generated behavior for bounded mixed dynamic/static
     write `BID` response-demux.
320. `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md`:
     shipped generated bounded mixed dynamic/static write `BID`
     response-demux for exactly one dynamic write transaction plus one
     concrete static write transaction.
321. `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md`:
     selected mixed dynamic/static read response-demux readiness after generated
     bounded mixed dynamic/static write `BID` response-demux shipped.
322. `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md`:
     audited mixed dynamic/static read response-demux readiness and selected
     public contract selection for bounded mixed dynamic/static read
     single-beat `RID` response-demux.
323. `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md`:
     selected direct generated behavior for bounded mixed dynamic/static read
     single-beat `RID` response-demux.
324. `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md`:
     shipped generated bounded mixed dynamic/static read single-beat `RID`
     response-demux for exactly one dynamic read transaction plus one concrete
     static read transaction.
325. `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md`:
     selected mixed dynamic/static read burst-last `RID && RLAST`
     response-demux readiness after bounded mixed dynamic/static read
     single-beat `RID` response-demux shipped.
326. `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md`:
     audited mixed dynamic/static read burst-last `RID && RLAST`
     response-demux readiness and selected public contract selection.
327. `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md`:
     selected direct generated behavior for bounded mixed dynamic/static read
     burst-last `RID && RLAST` response-demux.

## Documentation index (all `.md` files in this repo)
- `README.md` — single entry point and navigation hub.
- `DOCTRINE_ENFORCEMENT.md` — root doctrine-enforcement architecture and check registry.
- `TOOLBOX.md` — root FSMGEN diagnostic toolbox and gate-command catalog.
- `SESSION_BOOTSTRAP.md` — canonical first-task file for a new engineering session.
- `ROADMAP_STATUS.md` — canonical live roadmap/workstream status board.
- `ROADMAP_V2.md` — detailed post-`R0`..`R7` roadmap intent and sequencing.
- `docs/book/` — mdBook source for the progressive FSMGen book.
- `docs/BOOK_PLAN.md` — migration plan from the monolithic guide into the mdBook.
- `docs/USER_GUIDE.md` — broad live reference and command usage during the split.
- `docs/TASK_TREE_README.md` — setup guide for adopting the task-tree tracking workflow in another project.
- `docs/TASK_TREE.md` — repo-local task-tree workflow, active tree index, and PNT frontier rules.
- `docs/tasks/TEMPLATE.md` — reusable template for one top-level task tree.
- `docs/tasks/GENERATED-HDL-ARTIFACT-PLACEMENT.md` — completed artifact-hygiene task tree for routing implicit generated HDL into git-ignored hidden artifact directories while preserving explicit output paths.
- `docs/tasks/RHS-LOGIC-SIMPLIFICATION-FRONTIER.md` — completed generated-HDL quality tree for AST-level boolean and width-proven vector/multi-bit RHS logic-equivalence simplification before HDL emission.
- `docs/tasks/DOCTRINE-ENFORCEMENT-ADOPTION.md` — completed adoption tree for the portable doctrine-enforcement architecture, FSMGEN-specific issue-pinpointing toolbox catalog, doctrine driver, bootstrap self-check, docs path wrapper, pre-commit wiring, and hosted CI wiring.
- `docs/tasks/AGENT-RUNTIME-RAM-GUARD.md` — agent-runtime safety tree for guarded heavyweight local commands that could otherwise exhaust host RAM.
- `docs/tasks/PROJECT-REMAINING-WORK-TASKTREE-OWNERSHIP.md` — completed roadmap-maintenance task tree that routed the 2026-06-05 remaining-work inventory to existing active owners or new broad owner trees.
- `docs/tasks/COMPOSITION-TYPE-BACKLOG-EXHAUSTION.md` — completed Composition/type backlog tree; shipped aggregate parameter/generic equality/inequality, closed the remaining Composition/type leaves behind exact prerequisites, and routed VHDL-dependent work through the completed backend/API frontier.
- `docs/tasks/ISF-REMAINING-BROAD-FRONTIER.md` — proposed broad `R14` ISF frontier owner tree for deferred ISF backlog directions not already owned by narrower active trees.
- `docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md` — completed current backend-language portability contract tree; `.2.1` captured the variant-parity doctrine, `.2.2` completed the readiness audit, `.2.3` selected the portable in-memory request/result API, `.2.4` selected the source-catalog plus artifact-sink host abstraction, `.2.5` selected the Perl-reference parity harness, `.2.6` selected the mdBook language-X blueprint structure, `.2.7` selected the typed extension/plugin portability boundary, `.2.8` selected the same-repo Rust/Rust-Wasm portable API smoke experiment, `.3.1` scaffolded the `fsmgen_portable_api` contract crate, `.3.2` added the first direct `.fsm` check smoke, and `.3.3` added the first Perl-oracle parity smoke.
- `docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md` — completed IAL1-first verification-code generation tree; `.1` promoted the deferred verification-code route into task-tree ownership, `.2` completed the IAL1 source-readiness audit, `.3` selected actor-level passive observation metadata as the first source prerequisite, `.4` selected a passive UVM monitor skeleton package as the first SV/UVM output target, `.7` selected the public verification-output CLI/artifact/report/support-accounting surface, `.8` shipped the bounded inert UVM passive-monitor skeleton output mode, `.5` deferred VHDL artifact selection behind validation-substrate selection, `.9` selected shape-only inert-artifact validation, `.10` selected an inert VHDL observation package, `.11` shipped the bounded inert VHDL observation package output mode, and `.6` selected no direct IAL2 verification-output route for the current lane.
- `docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md` — completed implementation owner for the selected IAL1 passive observation source feature; `.1` shipped actor-level `(observe NAME (role passive_monitor) (signals SIG...))` metadata, additive `verification_observations[]` schedule JSON projection, public contract metadata, a supported-smoke fixture, and mdBook coverage without generated verification output.
- `docs/tasks/ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.md` — completed downstream-response task tree answering SPECFORGE's 2026-06-16 transaction phase-membership/value/order request; records that no runtime code change was needed, `.isf` remains SPECFORGE's synthesizable target, future checked transaction phase-group metadata belongs in an owned ISF slice, and `.val` is not a replacement for `.isf`.
- `docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.md` — completed downstream-response task tree for SPECFORGE's 2026-06-22 declarative field-structured storage request; records that FSMGen accepts the direction as future ISF work, existing runtime field operations are not static field-map declarations, and implementation selection moves to `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1`.
- `docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.md` — completed ISF storage-metadata frontier; `.1` selected a metadata-only scalar storage-field contract, `.2` shipped parser validation plus `inferred_storage[].fields` report projection, `.3` selected support-accounting promotion as the next residual, `.4` shipped `isf/storage_fields.isf` as the support-accounted public sample, and `.5` closed the narrow frontier before broader reset derivation, access behavior, aggregate, bank, packet layout, or direct semantic-payload work.
- `docs/ISF_FIELD_STRUCTURED_STORAGE_FRONTIER_CLOSEOUT.md` — closeout for `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.5`; records that scalar storage fields are shipped/support-accounted and that broader field behavior/layout/semantic-payload directions require future exact task-tree leaves.
- `docs/ISF_FIELD_STRUCTURED_STORAGE_NEXT_RESIDUAL_SELECTION.md` — selector for `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.3`; records that the next bounded residual is a support-accounted scalar storage-field fixture and explicitly defers broader field behavior/layout/semantic-payload work.
- `docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md` — audit for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2`; records that existing IAL1 checks/properties are sufficient for inline SV assertion projection but not enough for first-class generated verification artifacts, and selects `.3`.
- `docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md` — selector for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3`; chooses the metadata-only actor-level `observe` source contract and routes implementation to `ISF-VERIFICATION-OBSERVATION-METADATA.1`.
- `docs/IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION.md` — selector for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4`; chooses a passive UVM monitor skeleton package as the first SV/UVM output target and routes public CLI/artifact/report/support-accounting selection to `.7`.
- `docs/IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md` — selector for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`; chose `--emit-verification-output uvm-passive-monitor --verification-outdir DIR`, the UVM package artifact layout, manifest shape, support-accounting entry, capability-manifest surface, diagnostics, and validation boundary implemented by `.8`.
- `docs/IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION.md` — selector for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5`; records that no VHDL verification artifact is selected yet and routes the prerequisite to `.9`, VHDL verification validation-substrate selection.
- `docs/IAL1_VHDL_VERIFICATION_VALIDATION_SUBSTRATE_SELECTION.md` — selector for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9`; chooses shape-only inert-artifact validation with explicit no-compile/no-PSL manifest claims and routes first VHDL artifact selection to `.10`.
- `docs/IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION.md` — selector for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10`; chose `vhdl-observation-package`, an inert VHDL observation metadata package target implemented by `.11`.
- `docs/IAL1_DIRECT_IAL2_VERIFICATION_ROUTE_AUDIT.md` — audit for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6`; selected no direct `.ppif` verification-output route for the current lane and requires future protocol verification facts to route through reviewable generated IAL1 unless a later exact owner proves otherwise.
- `docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md` — completed immediate semantic-introspection/MCP task tree; `.2` made deep semantic introspection a first-class feature, `.29` shipped catalog-backed source discovery, and `.30` returned active priority to IAL2.
- `docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md` — completed backend/API frontier owner tree for VHDL, external validation, ABC, structured generation, embedding API, and normalized export backlog through `.132`.
- `docs/tasks/ARCHITECTURE-DEBT-FRONTIER.md` — completed architecture-debt frontier owner tree; direct-backend structural internal declaration nets shipped, and ISF parser/lowerer extraction remains deferred behind future exact ownership.
- `docs/tasks/ISF-FRONTIER-SPAWN-AWAITANY-BOOK-RUNNABLE-EXAMPLES.md` — completed `R14` task tree that added runnable `lisp` book examples (in `13d`) for the shipped loop-contained spawn + `(await_all done)` and multi-pending `(await_any done)` + drain features (`t/1376` count 36 → 38); all repeat-body-activation frontier shapes now have copy-pasteable book examples.
- `docs/tasks/ISF-LOOP-AND-DEEPER-REPEAT-BODY-MULTI-PENDING-AWAITANY-LOWERING.md` — completed `R14` task tree (scheduler-frontier #6) that lifted the multi-pending `(await_any done)` + later `(await_all done)` deferral for loop-contained / deeper-nested repeats, locked by `t/1384`; **completes the repeat-body-activation nesting frontier** (cross-domain `do` is excluded — net-new CDC lowering).
- `docs/tasks/ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.md` — completed `R14` task tree (scheduler-frontier #5) that enabled the basic `(spawn ...)` + same-body `(await_all done)`/single-pending `(await_any done)` subset inside a loop-contained or deeper-nested repeat (lowering + composition parity with the top-level repeat-body spawn); gate relaxation + drain-requirement rule + multi-pending-await_any deferral, locked by `t/1383`. Undrained/multi-pending spawn and cross-domain stay deferred; the full-HDL composition-wiring limitation is pre-existing (top-level too).
- `docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.md` — completed `R14` task tree (scheduler-frontier #4) that enabled a same-domain generated `(do child (params ...))` at deeper branch nesting (`when⁺ → repeat`, `switch → when⁺ → repeat`) to lower + instantiate its child; a 3-part lowering change (collector recursion, param threading, validator relaxation) locked by `t/1382` with verified `.fsm`↔`_top` ordinal agreement, cross-domain and spawn deferred.
- `docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.md` — completed `R14` task tree (scheduler-frontier #3) that enabled a plain local `(do child)` at deeper branch nesting (`when⁺ → repeat`, `switch → when⁺ → repeat`) to lower; a clean validator relaxation locked by `t/1381` (deeper-nested generated-do and spawn stay deferred).
- `docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.md` — completed `R14` task tree (scheduler-frontier #2) that enabled a same-domain generated `(do child (params ...))` inside a `(repeat ...)` directly in one `(while ...)`/`(until ...)` body to lower and instantiate its child in the `_top`; threaded the generated-child activation through the loop-body path + added loop-body discovery to the collector, locked by `t/1380` (cross-domain do and spawn stay deferred).
- `docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.md` — completed `R14` task tree (scheduler-frontier #1) that enabled a plain local `(do child)` inside a `(repeat ...)` directly contained in one `(while ...)`/`(until ...)` body to lower; a validator-only gate relaxation locked by `t/1379` (spawn, generated-do, and deeper nesting stay deferred).
- `docs/tasks/ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.md` — completed `R14` task tree answering SPECFORGE's 2026-05-29 clarity request on the actor-local `(types)`↔`(enums)` relationship; documents that an enum name is not an auto type alias (co-declare `(type NAME (bits k))`), replies in `docs/SPECFORGE_FEEDBACK_RESPONSE.md`, and locks the rule with `t/1378`.
- `docs/tasks/R14-ASPECT-COVERAGE-AUDIT.md` — completed `R14` roadmap-maintenance task tree confirming every ISF backlog aspect is task-tree owned; registered `ISF-FULL-WIDTH-INFERENCE` (Proposed) and recorded IAL2 as a non-R14 horizon exploration.
- `docs/tasks/ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.md` — active `R14` task tree (CDC lane) enabling a blocking cross-domain `(do)`/`(spawn)` through a new `(crossings (activation child (from SRC)(to DEST)))` kind that routes the activation start/done through two acknowledged-event CDC children; validator-acceptance and CDC routing ship together (a validator-only relaxation would emit an unsynchronized cross-clock handoff).
- `docs/tasks/ISF-FULL-WIDTH-INFERENCE.md` — completed `R14` task tree: activated, probed, and found no decidable multi-unknown extract/assemble width-inference sub-case beyond the shipped single-missing inference (2+-unknown is underdetermined → correctly fail-closed); recorded the fail-closed terminal and locked it with `t/1385`.
- `docs/tasks/BOOK-COOKBOOK-COMPOSITION-RUNNABLE.md` — completed `R14` task tree that upgraded cookbook composition recipes 3/4/5 from `text` schematics to verified inline-runnable `lisp` examples (C1/C2/C3 patterns proven by `t/101`); `t/1377` now gates 14 standalone `.fsm` fixtures.
- `docs/tasks/BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.md` — completed `R14` task tree that extended the example-correctness build gate from the ISF surface to the non-ISF `.fsm` (IAL0) book chapters; demoted 19 multi-file/schematic blocks to `text` and added `t/1377-book-fsm-example-generation-audit.t` (11 standalone `.fsm` fixtures gated).
- `docs/tasks/CI-CORPUS-SYSTEM-INCOMPLETE-SECTION-FIX.md` — completed CI-maintenance task tree that fixed the stale `t/corpus/system_incomplete_section.fsm` fixture.
- `docs/tasks/ISF-G8-HEADING-DENSITY.md` — completed `R14` task tree that added 4 sub-headings to the Pipeline section of 13-intent-scheduling.md.
- `docs/tasks/ISF-G4-BACKLOG-TRUTH-SYNC.md` — completed `R14` task tree that appended a dated status snapshot to 14-feature-backlog.md.
- `docs/tasks/ISF-G2-LOW-DENSITY-EXAMPLES.md` — completed `R14` task tree that added constants_demo (13a), bank_demo + dataop_demo (13e) examples.
- `docs/tasks/ISF-G5-13-INTENT-EXAMPLES.md` — completed `R14` task tree that added blinker + handshake_intent examples to 13-intent-scheduling.md.
- `docs/tasks/ISF-G6-13J-EXAMPLES.md` — completed `R14` task tree that added 3 complete actor examples (type_alias_demo, enum_demo, aggregate_storage_demo) to 13j.
- `docs/tasks/ISF-G7-13D-ACCEPT-PATH-EXAMPLES.md` — completed `R14` task tree that added 4 complete accept-path control-flow actor examples (when/switch+default/while/until) to 13d.
- `docs/tasks/ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.md` — completed `R14` task tree that propagated the recent diagnostic surface (cross-domain, sub-axis, loop-contained, deeper-nested, `t/1372-1376`) to `ISF_PUBLIC_INTERFACE_CONTRACT.md` and `SPECFORGE_FEEDBACK_RESPONSE.md`.
- `docs/tasks/ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.md` — completed `R14` task tree that added `t/1376-isf-book-example-lowering-audit.t`. The test extracts every `lisp`-tagged book block and verifies it parses + lowers; failures block the test suite. 20 fixtures currently lower cleanly.
- `docs/tasks/ISF-DIAGNOSTIC-EXAMPLES-G3.md` — completed `R14` task tree that added 4 representative examples for the remaining `remains deferred` template families and adopted the `lisp` vs `text` block-tag convention (`lisp` for accept-path fixtures only).
- `docs/tasks/ISF-COOKBOOK-WALKTHROUGHS.md` — completed `R14` task tree that added clause-by-clause walkthroughs to cookbook ISF recipes 9-13.
- `docs/tasks/ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.md` — completed `R14` task tree that fixed 14 broken ISF examples identified in the example-correctness audit addendum. Re-audit reports 20 complete fixtures lower cleanly, 0 failures.
- `docs/tasks/ISF-COOKBOOK-RECIPES-G1.md` — completed `R14` task tree that addressed audit gap G1 by adding five ISF recipes to cookbook chapter 12 (basic actor, spawn, parameterized blocking do, rule trigger, repeat-body generated do).
- `docs/tasks/ISF-MDBOOK-COVERAGE-AUDIT.md` — completed `R14` doc-only task tree that published `docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md` identifying eight gap categories (G1-G8) and a prioritized slice queue for closing the coverage gap between the codebase and the mdBook.
- `docs/tasks/ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.md` — completed `R14` task tree that added user-facing `.fsm` source examples to book chapters 13b (five examples) and 13d (two examples) for the seven targeted diagnostics shipped this session (cross-domain repeat-body do, four activation-override sub-axes, loop-contained, deeper-nested).
- `docs/tasks/ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.md` — completed `R14` task tree that extended the targeted-diagnostic synchronization for the loop-contained and deeper-nested slices to book chapters `13b-transactions.md`, `13d-control-flow.md`, `13h-lowering-reference.md`, and `13k-isf-feature-support-matrix.md`.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH.md` — completed bootstrap architecture-maintenance task tree consolidating the import-tree note refresh for the four R14 diagnostic-precision slices; recorded `LoweringIR.pm` line count moved from `11144` to `11309`; topology unchanged.
- `docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.md` — completed `R14` task tree that shipped a targeted `deeper-nested repeat-body <do|spawn> remains deferred` diagnostic for deeper-when and when-inside-switch cases at the two repeat-body subset entry points; broader deeper-nested implementation remains a future leaf; regression `t/1375-isf-deeper-nested-repeat-body-activation-diagnostic.t`.
- `docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.md` — completed `R14` task tree that shipped a targeted `loop-contained repeat-body <do|spawn> remains deferred` diagnostic when a `(repeat ...)` with `do` or `spawn` body clauses is nested inside `(while ...)` or `(until ...)`; broader loop-contained implementation remains a future leaf; regression `t/1374-isf-loop-contained-repeat-body-activation-diagnostic.t`.
- `docs/tasks/ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.md` — completed `R14` task tree that split the aggregated static-timing override gate into four sub-axis-specific gates (repeat-count, wait-count, latency-bound, watchdog-limit) each with its own targeted diagnostic; regression `t/1373-isf-timing-param-sub-axis-diagnostic.t`.
- `docs/tasks/ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.md` — completed `R14` task tree that shipped a targeted cross-domain repeat-body `do` diagnostic; broader cross-domain `do` implementation remains a separate future leaf of this tree; regression `t/1372-isf-cross-domain-repeat-body-do-diagnostic.t`.
- `docs/tasks/ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.md` — completed `R14` task tree that extended the activation-site parameter override-specialized default-preserving gate to transaction port widths (`(ports (input/output NAME (width PARAM)))`); regression `t/1371-isf-transaction-port-activation-override-width-gate.t`.
- `docs/tasks/ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.md` — completed `R14` task tree that extended the activation-site parameter override-specialized default-preserving gate from timing parameters (wait, repeat, latency, watchdog, contract) to data-operation width parameters (`shift_left`, `shift_right`, `assemble`, `extract`); regression `t/1370-isf-data-op-activation-override-width-gate.t`.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the same-domain generated `(do worker (params ...) (bind ...) (domain core))` before post-do multi-pending `(await_any done)` without final drain shape on both branch-contained subsets, completing the BEFORE-POST-DO-AWAITANY missing-drain matrix across the five generated-do families.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the bound generated `(do worker (params ...) (bind ...))` before post-do multi-pending `(await_any done)` without final drain shape on the when-body subset (switch already existed).
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the static-parameter generated `(do worker (params ...))` before post-do multi-pending `(await_any done)` without final drain shape on both branch-contained subsets.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the plain generated-child `(do worker)` before post-do multi-pending `(await_any done)` without final drain shape on both branch-contained subsets.
- `docs/tasks/ISF-REPEAT-LOCALDO-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the local `(do child)` before post-do multi-pending `(await_any done)` without final drain shape on both branch-contained subsets.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the static-parameter generated `(do worker (params ...))` prior-`await_any` plus spawn-after-do without final drain shape on the switch-branch subset, completing the SPAWN-AFTER-DO without-drain matrix across the five generated-do families.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the plain generated-child `(do worker)` prior-`await_any` plus spawn-after-do without final drain shape on the switch-branch subset.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the bound generated `(do child (params ...) (bind ...))` prior-`await_any` plus second post-spawn `await_any` shape on both branch-contained subsets, completing the SECOND-AWAITANY missing-drain matrix across the five generated-do families.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the static-parameter generated `(do child (params ...))` prior-`await_any` plus second post-spawn `await_any` shape on both branch-contained subsets.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the plain generated-child `(do child)` prior-`await_any` plus second post-spawn `await_any` shape on the switch-branch subset.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the same-domain generated `do` prior-`await_any` plus second post-spawn `await_any` shape.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-DOMAIN-SECOND-AWAITANY-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after the R14 same-domain generated-do prior-`await_any` plus second post-spawn `await_any` repeat-body slice.
- `docs/tasks/ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for prior-observation second post-spawn `await_any` mdBook and `t/1307` audit wording across the local-do plus four generated-do families.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained same-domain generated `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-BOUND-SECOND-AWAITANY-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after the R14 static-parameter and bound generated-do prior-`await_any` plus second post-spawn `await_any` repeat-body slices.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained bound generated `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained static-parameter generated `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after the R14 generated-child second-`await_any` slice.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained plain generated-child `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-REPEAT-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after recent R14 repeat-body child-activation slices.
- `docs/tasks/ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained local `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained same-domain generated `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained bound generated `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained static-parameter generated `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC.md` — completed `R14` documentation/audit truth-sync task tree for prior-`await_any` spawn-after-do repeat wording.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained plain generated-child `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained local `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained same-domain generated `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained bound generated `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained static-parameter generated `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained local `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained plain generated-child `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained same-domain generated `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained bound generated `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained static-parameter generated `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained plain generated-child `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained local `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY.md` — completed `R14` task tree for same-domain generated `do` before post-do multi-pending `await_any` in branch-contained nested repeats.
- `docs/tasks/ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for mdBook static-zero repeat child-activation wording.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after static-zero repeat pruning.
- `docs/tasks/ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE.md` — completed `R14` task tree for bounded static-zero repeat specialized child-activation artifact pruning.
- `docs/tasks/ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE.md` — completed `R14` task tree for bounded static-zero repeat child-activation artifact pruning.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note.
- `docs/tasks/ISF-STATIC-ZERO-REPEAT-NOOP.md` — completed `R14` task tree for bounded static zero-count repeat no-op lowering.
- `docs/tasks/ROADMAP-R14-REPEAT-ZERO-STATUS-TRUTH-SYNC.md` — completed `R14` roadmap maintenance task tree for repeat zero status truth sync.
- `docs/tasks/NO-RESET-SCHEDULED-FSM-HDL.md` — completed `R14` task tree for reset-free scheduled `.fsm` HDL support.
- `docs/tasks/ISF-CDC-NO-RESET-FIXTURE.md` — completed `R14` task tree for no-reset acknowledged-event CDC fixture coverage.
- `docs/tasks/ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for data-operation width backlog wording.
- `docs/tasks/ISF-SCHEDULE-REPORT-STORAGE-ROLES.md` — completed `R14` task tree for additive schedule-report storage-role metadata.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO.md` — completed `R14` task tree for same-transaction-parameter-zero runtime divisor safety.
- `docs/tasks/ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for static timing fail-closed checklist wording.
- `docs/tasks/ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES.md` — completed `R14` task tree for generated child static timing parameter activation override gates.
- `docs/tasks/ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in top-level await-local watchdog limits.
- `docs/tasks/ISF-LATENCY-TRANSACTION-PARAM-BOUNDS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in latency bounds.
- `docs/tasks/ISF-WAIT-TRANSACTION-PARAM-COUNTS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in wait counts.
- `docs/tasks/R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the top-boundary convention/connect-by-name frontier.
- `docs/tasks/R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the portable synthesizable-type frontier.
- `docs/tasks/R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the reusable standalone-DT/module-library frontier.
- `docs/tasks/R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the shared-datapath contract frontier.
- `docs/tasks/R11-PARAMETER-GENERIC-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the semantic parameter/generic frontier.
- `docs/tasks/R11-RTLIF-INTERFACE-SOURCE-DIRECTION.md` — completed `R11` task tree for deciding the `.rtlif` interface-source direction.
- `docs/tasks/R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the next composition-contract frontier.
- `docs/tasks/R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.md` — completed `R10` task tree for auditing the diagnostic/provenance exit frontier.
- `docs/tasks/R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.md` — completed `R10` task tree for cleaning D-input self-dependency diagnostic implementation leakage.
- `docs/tasks/R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.md` — completed `R10` task tree for cleaning direct self-dependency diagnostic stack leakage.
- `docs/tasks/R10-CLI-QUIET-BANNER-CLEANUP.md` — completed `R10` task tree for aligning quiet CLI banner behavior with diagnostics.
- `docs/tasks/R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.md` — completed `R10` task tree for auditing and cleaning up the next source-provenance and diagnostic frontier.
- `docs/tasks/R9-STRICT-MODE-FRONTIER-AUDIT.md` — completed `R9` task tree for auditing the strict-mode support-tier frontier.
- `docs/tasks/R8-LANGUAGE-CONTRACT-EXIT-AUDIT.md` — completed `R8` task tree for auditing the language-contract exit criteria.
- `docs/tasks/RICHER-AGGREGATE-OPERATORS.md` — completed aggregate-types task tree for richer aggregate operator widening.
- `docs/tasks/R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.md` — completed `R8` task tree for resolving the next parser-accepted language-surface gray zone.
- `docs/tasks/BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.md` — completed aggregate-types task tree for backend-owned structured aggregate lowering audit.
- `docs/tasks/AGGREGATE-AUTOGROWTH-FROM-USAGE.md` — completed aggregate-types task tree for bounded automatic aggregate growth from usage.
- `docs/tasks/DYNAMIC-DIVISOR-SAFETY-FRONTIER.md` — completed language-ergonomics task tree for direct runtime literal-zero divisor rejection.
- `docs/tasks/INFERENCE-FIRST-SCALAR-AUTHORING.md` — completed language-ergonomics task tree for the first inference-first scalar authoring slice.
- `docs/tasks/COMPOSITION-WIRING-LISPISH.md` — completed `R11` task tree for canonical Lisp-ish `?wiring` list forms.
- `docs/tasks/R8-STRICT-SUPPORT-TIER-CUTS.md` — completed `R8` task tree for the latest strict-mode support-tier cut.
- `docs/tasks/FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.md` — completed roadmap-maintenance task tree for broad feature-backlog owner coverage synchronization.
- `docs/tasks/TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for synchronizing stale completed task-tree commit evidence.
- `docs/tasks/TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for synchronizing stale `this commit` completed task-tree evidence.
- `docs/tasks/ISF-REPEAT-TRANSACTION-PARAM-COUNTS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in repeat counts.
- `docs/tasks/ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC.md` — completed `R14` roadmap-maintenance task tree for detailed active-lane roadmap status truth sync.
- `docs/tasks/ISF-GENERATED-DO-BINDING-TIMING-COVERAGE.md` — completed `R14` task tree for generated blocking `do` binding timing regression coverage.
- `docs/tasks/ROADMAP-R14-BINDING-TIMING-HISTORICAL-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for binding timing history truth sync.
- `docs/tasks/ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for rule-trigger output-binding history truth sync.
- `docs/tasks/ISF-DIRECT-ON-PARAM-DIAGNOSTIC.md` — completed `R14` task tree for direct `(on ... (params ...))` diagnostic hardening.
- `docs/tasks/ISF-CONFLICT-RESOLUTION.md` — completed `R14` task tree for ISF same-cycle conflict semantics.
- `docs/tasks/ISF-TRANSACTION-OVER-RULE-PRIORITY.md` — completed `R14` task tree for covered transaction-over-rule same-target priority.
- `docs/tasks/ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for stale transaction-over-rule priority mdBook wording.
- `docs/tasks/ISF-COMPOSITION-INSTANTIATION.md` — completed `R14` task tree for generated child instantiation and spawn parameter binding.
- `docs/tasks/ISF-STORAGE-PORT-ROUND-ROBIN.md` — completed `R14` task tree for bounded storage-port round-robin resource arbitration.
- `docs/tasks/ISF-OUTPUT-BUNDLE-ROUND-ROBIN.md` — completed `R14` task tree for bounded output-bundle round-robin resource arbitration.
- `docs/tasks/ISF-TRANSACTION-START-ROUND-ROBIN.md` — completed `R14` task tree for bounded transaction-start round-robin resource arbitration.
- `docs/tasks/ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.md` — completed `R14` task tree for bounded round-robin resource arbitration.
- `docs/tasks/ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.md` — completed `R14` task tree for output-bundle priority resource enforcement.
- `docs/tasks/ISF-STORAGE-PORT-RESOURCE-PRIORITY.md` — completed `R14` task tree for storage-port priority resource enforcement.
- `docs/tasks/ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.md` — completed `R14` task tree for storage-port member documentation truth sync.
- `docs/tasks/ISF-RESOURCE-PRIORITY.md` — completed `R14` task tree for resource arbitration and priority enforcement.
- `docs/tasks/ISF-RESOURCE-CATALOG.md` — completed `R14` task tree for the shareable resource kind registry.
- `docs/tasks/ISF-RULE-ACTIONS.md` — completed `R14` task tree for expression-valued rule assignments.
- `docs/tasks/ISF-STAGES-CONTRACTS.md` — completed `R14` task tree for transaction stages and temporal contracts.
- `docs/tasks/ISF-DATA-WIDTHS.md` — completed `R14` task tree for data-operation width inference.
- `docs/tasks/ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in data-operation width evidence.
- `docs/tasks/ISF-ASSEMBLE-STATIC-PART-WIDTHS.md` — completed `R14` task tree for optional `assemble` part-width evidence.
- `docs/tasks/ISF-DATA-OP-STATIC-WIDTH-SOURCES.md` — completed `R14` task tree for actor-local static value sources in data-operation width evidence.
- `docs/tasks/ISF-SHIFT-LEFT-EXPLICIT-WIDTH.md` — completed `R14` task tree for optional `shift_left` width evidence.
- `docs/tasks/ISF-SCHEDULE-REPORTS.md` — completed `R14` task tree for schedule-report storage classes and schema stabilization.
- `docs/tasks/ISF-FIXTURE-COVERAGE.md` — completed `R14` task tree for realistic fixtures and strict-mode coverage.
- `docs/tasks/ISF-BURST-FIXTURE-PROMOTION.md` — completed `R14` task tree for burst-reader fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-UART-FIXTURE-PROMOTION.md` — completed `R14` task tree for UART-like fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-PHASE-FIXTURE-PROMOTION.md` — completed `R14` task tree for phase fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-SWITCH-FIXTURE-PROMOTION.md` — completed `R14` task tree for switch fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-WHEN-FIXTURE-PROMOTION.md` — completed `R14` task tree for `when` fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.md` — completed `R14` task tree for generated-composition fixture strict/outdir/HDL promotion.
- `docs/tasks/ISF-RULE-RESOURCE-FIXTURE-PROMOTION.md` — completed `R14` task tree for rule/resource arbitration fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.md` — completed `R14` task tree for stage/contract fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.md` — completed `R14` task tree for FIFO controller fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.md` — completed `R14` task tree for FIFO datapath bank-access fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.md` — completed `R14` task tree for FIFO reusable-library fixture schedule/strict/outdir/HDL promotion.
- `docs/tasks/ISF-I2C-FIXTURE-PROMOTION.md` — completed `R14` task tree for I2C-like fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-COMPATIBILITY-SURFACE.md` — completed `R14` task tree for legacy handshake and removed assign compatibility policy.
- `docs/tasks/ISF-PORT-BINDING.md` — completed `R14` task tree for transaction ports and actor pin access.
- `docs/tasks/ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.md` — completed `R14` task tree for generated-child rule-trigger output bindings.
- `docs/tasks/ISF-CONTROL-FLOW.md` — completed `R14` task tree for transaction-local waits and dynamic loops.
- `docs/tasks/ISF-WAIT-ZERO.md` — completed `R14` task tree for zero-count transaction wait semantics.
- `docs/tasks/ISF-DYNAMIC-WAIT.md` — completed `R14` task tree for non-literal transaction wait counts.
- `docs/tasks/ISF-PARAM-WAIT-COUNTS.md` — completed `R14` task tree for actor-parameter-backed static transaction wait counts.
- `docs/tasks/ISF-WAIT-PACKAGE-CONSTANT-COUNTS.md` — completed `R14` task tree for qualified package scalar constants in static transaction wait counts.
- `docs/tasks/ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.md` — completed `R14` task tree for completion zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.md` — completed `R14` task tree for independent setter zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.md` — completed `R14` task tree for explicit independent update zero-bypass coverage.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.md` — completed `R14` task tree for independent shift zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE.md` — completed `R14` task tree for independent assemble zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.md` — completed `R14` task tree for independent extract zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.md` — completed `R14` task tree for independent bank-load zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.md` — completed `R14` task tree for independent bank-store zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.md` — completed `R14` task tree for carrying pending samples across consecutive runtime wait zero-count links.
- `docs/tasks/ISF-DYNAMIC-WAIT-STAGE-SAMPLE.md` — completed `R14` task tree for stage zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.md` — completed `R14` task tree for contract arm zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.md` — completed `R14` task tree for loop decision zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.md` — completed `R14` task tree for dynamic waits after bank load/store predecessors.
- `docs/tasks/ISF-DYNAMIC-WAIT-SYNC-SAMPLE.md` — completed `R14` task tree for await_all/await_any zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.md` — completed `R14` task tree for spawn zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-PHASE-SAMPLE.md` — completed `R14` task tree for transaction phase zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-SPAWN-IN-REPEAT.md` — completed `R14` task tree for static child spawn inside repeat bodies.
- `docs/tasks/ISF-REPEAT-SPAWN-PARAMS.md` — completed `R14` task tree for repeat-body spawn parameter overrides.
- `docs/tasks/ISF-REPEAT-BODY-CHILD-ACTIVATION.md` — completed `R14` task tree for repeat-body child activation widening.
- `docs/tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md` — completed `R14` task tree for static ISF Actor Transfer Level actor-network orchestration.
- `docs/tasks/ISF-CONTRACT-ACTOR-PARAM-WINDOWS.md` — completed `R14` task tree for actor-parameter-backed temporal contract windows.
- `docs/tasks/ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.md` — completed `R14` task tree for qualified package scalar constants in temporal contract windows.
- `docs/tasks/ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.md` — completed `R14` task tree for generated child same-transaction scalar parameter defaults in temporal contract windows.
- `docs/tasks/ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.md` — completed `R14` task tree for direct transaction same-transaction scalar parameter defaults in temporal contract windows.
- `docs/tasks/ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.md` — completed `R14` task tree for activation-site override diagnostics on generated child temporal contract-window parameters.
- `docs/tasks/ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for activation override diagnostic coverage synchronization.
- `docs/tasks/ROADMAP-R14-LATEST-SLICE-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for latest R14 slice roadmap truth synchronization.
- `docs/tasks/ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for historical transaction-port binding recovery-note truth synchronization.
- `docs/tasks/ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.md` — completed `R14` task tree for duplicate generated rule-trigger output actor-target diagnostics.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for transaction-port binding report non-claim wording.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.md` — completed `R14` task tree for duplicate output-binding actor-target diagnostics.
- `docs/tasks/ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC.md` — completed `R14` task tree for direct/local rule-trigger output-binding diagnostic hardening.
- `docs/tasks/ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for authored binding timing metadata wording.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.md` — completed `R14` task tree for authored transaction-port binding timing request report metadata.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.md` — completed `R14` task tree for bounded transaction-port binding timing report metadata.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.md` — completed `R14` task tree for explicit transaction input-binding timing syntax.
- `docs/tasks/ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.md` — completed `R14` task tree for same-value activation-site overrides on generated child temporal contract-window parameters.
- `docs/tasks/ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.md` — completed `R14` task tree for positive actor constants in transaction latency bounds.
- `docs/tasks/ISF-LATENCY-ACTOR-PARAM-BOUNDS.md` — completed `R14` task tree for actor-parameter-backed transaction latency bounds.
- `docs/tasks/ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.md` — completed `R14` task tree for qualified package scalar constants in transaction latency bounds.
- `docs/tasks/ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed actor interface port widths.
- `docs/tasks/ISF-INTERFACE-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed actor interface port widths.
- `docs/tasks/ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in actor interface port widths.
- `docs/tasks/ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in actor-owned scalar storage widths.
- `docs/tasks/ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed actor-owned scalar storage widths.
- `docs/tasks/ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed actor-owned scalar storage widths.
- `docs/tasks/ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in actor-owned bank storage widths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed actor-owned bank storage widths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed actor-owned bank storage widths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.md` — completed `R14` task tree for actor-constant-backed actor-owned bank storage depths.
- `docs/tasks/ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed transaction-local port widths.
- `docs/tasks/ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed transaction-local port widths.
- `docs/tasks/ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in transaction-local port widths.
- `docs/tasks/ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in transaction-local port widths.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.md` — completed `R14` task tree for transaction-port binding endpoint-kind schedule-report metadata.
- `docs/tasks/ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for stale mdBook transaction-port package-constant width wording.
- `docs/tasks/ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in explicit data-operation width evidence.
- `docs/tasks/ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.md` — completed `R14` task tree for qualified package scalar constants in actor-owned bank storage depths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.md` — completed `R14` task tree for actor-parameter-backed actor-owned bank storage depths.
- `docs/tasks/ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.md` — completed `R14` task tree for positive actor constants in watchdog limits.
- `docs/tasks/ISF-WATCHDOG-ACTOR-PARAM-LIMITS.md` — completed `R14` task tree for actor-parameter-backed watchdog limits.
- `docs/tasks/ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.md` — completed `R14` task tree for qualified package scalar constants in watchdog limits.
- `docs/tasks/ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor constants as repeat counter width evidence.
- `docs/tasks/ISF-REPEAT-ACTOR-PARAM-COUNTS.md` — completed `R14` task tree for actor-parameter-backed repeat counts.
- `docs/tasks/ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.md` — completed `R14` task tree for qualified package scalar constants in static transaction repeat counts.
- `docs/tasks/ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.md` — completed `R14` task tree for a bounded static zero-count repeat policy.
- `docs/tasks/ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.md` — completed `R14` task tree for runtime scalar repeat zero-count skip policy.
- `docs/tasks/ISF-REPEAT-COUNT-SOURCE-BOUNDARY.md` — completed `R14` task tree for the accepted repeat count source boundary.
- `docs/tasks/ISF-BACKLOG-OWNER-TRUTH-SYNC.md` — completed `R14` task tree for mdBook backlog task-tree owner truth synchronization.
- `docs/tasks/ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.md` — completed `R14` task tree for targeted transaction-parameter repeat count diagnostics.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.md` — completed `R14` task tree for dynamic-divisor drive-expression coverage hardening.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-CONTROL-BANK-COVERAGE.md` — completed `R14` task tree for dynamic-divisor control and bank expression coverage hardening.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.md` — completed `R14` task tree for actor-parameter-zero dynamic-divisor safety.
- `docs/tasks/ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for synchronizing stale next-PNT roadmap wording.
- `docs/tasks/CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.md` — completed project-operations task tree for repairing the hosted strict wiring and direct LHS diagnostic regression.
- `docs/tasks/CI-FEATURE-BACKLOG-STATUS-AUDIT.md` — completed project-operations task tree for repairing a stale feature-backlog status audit expectation.
- `docs/tasks/ISF-ATL-FRONTIER-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for synchronizing stale closed ATL frontier wording.
- `docs/tasks/ISF-ATL-BACKLOG-TRUTH-SYNC.md` — completed `R14` task tree for synchronizing stale ATL backlog prose.
- `docs/tasks/ISF-ATL-COMPACT-INSTANCE-ALIAS.md` — completed `R14` task tree for the compact ATL static instance alias.
- `docs/tasks/ISF-ATL-COMPACT-GROUP-ALIAS.md` — completed `R14` task tree for the compact ATL concurrent group alias.
- `docs/tasks/ISF-ATL-MULTI-EVENT-WAIT.md` — completed `R14` task tree for bounded ATL transaction-body multi-event waits.
- `docs/tasks/ISF-ATL-PIN-MIXED-ROUTE-SETS.md` — completed `R14` task tree for bounded generated-child ATL top-level pin mixed scalar/vector route sets.
- `docs/tasks/ISF-ATL-PIN-VECTOR-MULTI-ROUTE.md` — completed `R14` task tree for bounded generated-child ATL top-level pin exact-width vector multi-route sets.
- `docs/tasks/ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.md` — completed `R14` task tree for bounded generated-child ATL top-level pin exact-width vector routes.
- `docs/tasks/ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.md` — completed `R14` task tree for bounded generated-child ATL actor-to-actor exact-width vector routes.
- `docs/tasks/ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.md` — completed `R14` task tree for shared ATL route-drive formal/actual-argument boundary hardening.
- `docs/tasks/ISF-ATL-PIN-EGRESS-MULTI-ROUTE.md` — completed `R14` task tree for bounded generated-child ATL resolved-child pin-egress multi-route scalar movement.
- `docs/tasks/ISF-ATL-PIN-INGRESS-MULTI-ROUTE.md` — completed `R14` task tree for bounded generated-child ATL top-level pin-ingress multi-route scalar movement.
- `docs/tasks/ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.md` — completed `R14` task tree for bounded generated-child ATL multi-route scalar data movement.
- `docs/tasks/ROADMAP-R14-FRONTIER-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for removing stale R14 frontier text after ATL multi-route closure.
- `docs/tasks/ISF-ATL-DOC-STATUS-TRUTH-SYNC.md` — completed `R14` task tree for ATL book/proposal/status truth synchronization after tree closure.
- `docs/tasks/ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.md` — completed `R14` task tree for SPECFORGE-reported ISF stage/contract conformance bugs.
- `docs/tasks/ISF-ACTIVATION-BIND-EXPRESSIONS.md` — completed `R14` task tree for expression-valued activation input bindings.
- `docs/tasks/ISF-SETTER-SYNTAX.md` — completed `R14` task tree for scalar setter syntax shared by rules and transactions.
- `docs/tasks/ISF-TRANSACTION-ACTIVATION.md` — completed `R14` task tree for task-like transaction activation and parameter overrides.
- `docs/tasks/ISF-ACTIVATION-PARAM-OVERRIDES.md` — completed `R14` task tree for remaining rule-trigger and direct-activation parameter overrides.
- `docs/tasks/ISF-ACTIVATION-PARAM-ACTOR-PARAMS.md` — completed `R14` task tree for actor-local scalar parameter defaults as generated activation parameter override values.
- `docs/tasks/ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for activation parameter value-domain prose.
- `docs/tasks/ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.md` — completed `R14` task tree for actor static values in reusable-library use-site parameter overrides.
- `docs/tasks/ISF-LIBRARY-USE-PACKAGE-CONSTANTS.md` — completed `R14` task tree for package scalar constants in reusable-library use-site parameter overrides.
- `docs/tasks/ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.md` — completed `R14` task tree for actor constants in actor parameter defaults.
- `docs/tasks/ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.md` — completed `R14` task tree for ordered actor-parameter-backed actor parameter defaults.
- `docs/tasks/ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.md` — completed `R14` task tree for actor-static generated-child transaction parameter defaults.
- `docs/tasks/ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.md` — completed `R14` task tree for earlier-scalar generated-child transaction parameter dependency defaults.
- `docs/tasks/ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.md` — completed `R14` task tree for package scalar constants in generated-child transaction parameter defaults.
- `docs/tasks/ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.md` — completed `R14` task tree for package scalar constants in generated activation parameter overrides.
- `docs/tasks/ROADMAP-CURRENT-ACTIVE-LANE-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for synchronizing stale current-active-lane roadmap wording.
- `docs/tasks/ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.md` — completed `R14` task tree for package scalar constants in actor parameter defaults.
- `docs/tasks/ISF-LIBRARY-SYSTEM-BINDINGS.md` — completed `R14` task tree for reusable-library clock/reset name remapping.
- `docs/tasks/ISF-STORAGE-VAR-ALIASES.md` — completed `R14` task tree for actor-owned scalar storage variable aliases.
- `docs/tasks/ISF-STORAGE-VAR-SURFACE.md` — completed `R14` task tree for the narrowed actor-owned scalar storage source vocabulary.
- `docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md` — completed `R14` task tree for ISF spec, book, manifest, and contract synchronization.
- `docs/tasks/ISF-CLOCK-DOMAINS.md` — completed `R14` task tree for multi-clock and CDC semantics.
- `docs/tasks/ISF-TIMING-CONVENTIONS.md` — completed `R14` task tree for default actor timing conventions.
- `docs/tasks/ISF-DOWNSTREAM-INTEGRATION-SPEC.md` — completed `R14` task tree for the self-contained `.isf` downstream integration handoff.
- `docs/tasks/ISF-LIVE-BOOK-DOCUMENT-PATHS.md` — completed `R14` task tree for advertising complete ISF mdBook live-document paths through the public contract.
- `docs/tasks/ISF-REPEAT-BODY-DOC-TRUTH-SYNC.md` — completed `R14` task tree for repeat-body shipped-subset documentation truth synchronization.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX.md` — completed `R14` task tree for the book-facing ISF shipped feature matrix.
- `docs/tasks/ISF-RULE-GUARD-DOC-TRUTH-SYNC.md` — completed `R14` task tree for standalone enum/aggregate rule-guard backlog truth synchronization.
- `docs/tasks/ISF-LOOP-BODY-DOC-TRUTH-SYNC.md` — completed `R14` task tree for loop-body shipped-clause documentation truth synchronization.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.md` — completed `R14` task tree for shipped stage/contract coverage in the ISF book feature matrix.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.md` — completed `R14` task tree for transaction port/binding coverage in the ISF book feature matrix.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.md` — completed `R14` task tree for report metadata coverage in the ISF book feature matrix.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.md` — completed `R14` task tree for downstream issue-bundle coverage in the ISF book feature matrix.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.md` — completed `R14` task tree for `.isf` CLI example coverage in the ISF book feature matrix.
- `docs/tasks/ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.md` — completed `R14` task tree for exactly-one-missing-part `assemble` width inference.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-CONSTANTS.md` — completed `R14` task tree for actor-constant zero divisor rejection in shipped ISF runtime expression contexts.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-SAFETY.md` — completed `R14` task tree for literal-zero divisor rejection in shipped ISF runtime expression contexts.
- `docs/tasks/ISF-BACKLOG-TRUTH-SYNC.md` — completed `R14` task tree for synchronizing stale ISF feature-backlog status text.
- `docs/tasks/ISF-RESOURCE-BACKLOG-TRUTH-SYNC.md` — completed `R14` task tree for synchronizing resource arbitration and storage-role backlog status text.
- `docs/tasks/ISF-FEATURE-BACKLOG-STATUS-SYNC.md` — completed `R14` task tree for synchronizing stale ISF feature-backlog status labels after closed task trees.
- `docs/tasks/ISF-GENERATED-NAME-POLICY.md` — completed `R14` task tree for generated-name stability policy in schedule reports and generated artifacts.
- `docs/tasks/ISF-SCHEDULE-REPORT-SCHEMA-VERSION.md` — completed `R14` task tree for report-level schedule JSON schema-version metadata.
- `docs/tasks/ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.md` — completed `R14` task tree for schedule-report additive/deprecation evolution policy.
- `docs/tasks/ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.md` — completed `R14` task tree for schedule-report assignment provenance and multi-file child summary boundary.
- `docs/tasks/ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.md` — completed `R14` task tree for the executable schedule-report golden fixture matrix.
- `docs/tasks/ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.md` — completed `R14` task tree for freezing schedule JSON schema version 1.
- `docs/tasks/ISF-PARAM-OVERRIDE-CONSTANTS.md` — completed `R14` task tree for actor constants in activation parameter overrides.
- `docs/tasks/ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.md` — completed `R14` task tree for synchronizing removed `(assign ...)` diagnostic truth.
- `docs/tasks/ISF-SPEC-TEST-INDEX-SYNC.md` — completed `R14` task tree for keeping the ISF spec focused-test index synchronized.
- `docs/tasks/DOWNSTREAM-ISSUE-REPRO-FLOW.md` — completed `R14` task tree for downstream reproducible issue-reporting flow.
- `docs/tasks/ISF-ACTOR-PHASE-STAGE-REPORTS.md` — completed `R14` task tree for actor-level phase/stage schedule-report metadata.
- `docs/tasks/ISF-ACTOR-PARAM-REPORTS.md` — completed `R14` task tree for actor-level parameter default schedule-report metadata.
- `docs/tasks/ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.md` — completed `R14` task tree for exactly-one-missing-field `extract` width inference.
- `docs/tasks/ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.md` — completed `R14` task tree for positive actor constants in bounded eventual temporal-contract windows.
- `docs/tasks/ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS.md` — completed `R14` task tree for temporal-contract monitor storage schedule-report roles.
- `docs/tasks/ISF-TEMPORAL-CONTRACT-ASSERTIONS.md` — completed `R14` task tree for temporal-contract SystemVerilog assertion projection.
- `docs/tasks/ISF-CDC-FIXTURE-MATRIX.md` — completed `R14` task tree for dual acknowledged-event CDC fixture hardening.
- `docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md` — completed `R14` task tree for ISF enum/type/aggregate parity with existing `.fsm` semantic machinery.
- `docs/tasks/ISF-DYNAMIC-WAIT-STORAGE-REPORTS.md` — completed `R14` task tree for runtime dynamic-wait counter storage schedule-report roles.
- `docs/tasks/ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.md` — completed `R14` task tree for generated activation handoff storage schedule-report roles.
- `docs/tasks/ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.md` — completed `R14` task tree for generated activation start/done handoff storage schedule-report roles.
- `docs/tasks/ISF-TRANSACTION-PORT-STORAGE-REPORTS.md` — completed `R14` task tree for transaction-local port storage schedule-report roles.
- `docs/tasks/ISF-RULE-TRIGGER-STORAGE-REPORTS.md` — completed `R14` task tree for rule-trigger source and payload-source storage schedule-report roles.
- `docs/tasks/FSMGEN-IR-AUDIT.md` — completed architecture task tree for current IR inventory, canonical/private boundary classification, repo-local IR policy, and consolidation follow-up selection.
- `docs/tasks/IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.md` — completed architecture follow-up that guarded the current direct-root `structural_rtl_ir` projection before future convergence work.
- `docs/tasks/IR-EXPRESSION-AST-OWNERSHIP.md` — completed architecture follow-up for expression representation ownership and conversion boundaries.
- `docs/tasks/EXPR-NAMER-TRACKED-COPY-CLEANUP.md` — completed architecture follow-up that removed the tracked `ExpressionNamer.pm.new` duplicate.
- `docs/tasks/EXPR-AST-UTILS-OWNER-CONSOLIDATION.md` — completed architecture follow-up that collapsed duplicate `FSM::AST::Utils` ownership.
- `docs/tasks/EXPR-NAMER-LEGACY-PARSE-BOUNDARY.md` — completed architecture follow-up for guarding `ExpressionNamer` legacy hash/string parse boundaries.
- `docs/tasks/GLOBAL-AST-MANAGER-BOUNDARY.md` — completed architecture follow-up for resolving legacy `GlobalASTManager` ownership.
- `docs/tasks/ISF-LOWERINGIR-BOUNDARY-EXTRACTION.md` — completed architecture follow-up that inventoried private ISF `LoweringIR` subfamilies and deferred helper-owner extraction.
- `docs/tasks/MODULE-INFO-PROJECTION-GUARD.md` — completed architecture follow-up that audited `module_info` mirrors and closed without extra guard work.
- `docs/tasks/ROADMAP-ACTIVE-LANE-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for repairing stale live-roadmap active-lane/frontier claims.
- `docs/tasks/ROADMAP-ACTIVE-LANE-LATEST-SLICE-SYNC.md` — completed roadmap-maintenance task tree for synchronizing the lower live-roadmap latest-slice summary.
- `docs/tasks/R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for composition parser token and top-symbol diagnostics.
- `docs/tasks/R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for composition endpoint-shape diagnostics.
- `docs/tasks/R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for C1 passthrough exposure diagnostics.
- `docs/tasks/R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for missing explicit composition wiring diagnostics.
- `docs/tasks/R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for unsupported composition backend target diagnostics.
- `docs/tasks/R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for composition ports shape-gate diagnostics.
- `docs/tasks/R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for duplicate composition declaration diagnostics.
- `docs/tasks/R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for unsupported composition child-kind and legacy ports-mapping diagnostics.
- `docs/tasks/R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for malformed composition child-entry structure.
- `docs/tasks/R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for malformed external RTL child source count and payload shape.
- `docs/tasks/R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for malformed generated-child source count and payload shape.
- `docs/tasks/R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported standalone DTC explicit-system auto-wiring corpus coverage.
- `docs/tasks/R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for wrong-kind generated-child source realization.
- `docs/tasks/R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported standalone DT explicit-system corpus coverage.
- `docs/tasks/R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported implicit composition system-port auto-wiring corpus coverage.
- `docs/tasks/R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported direct implicit system defaults corpus coverage.
- `docs/tasks/R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported custom system clock corpus coverage.
- `docs/tasks/R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported compound update variant corpus coverage.
- `docs/tasks/R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported nested and compound guard corpus coverage.
- `docs/tasks/R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported arithmetic and XOR operator corpus coverage.
- `docs/tasks/R12-RESET-STATE-ALIAS-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported reset-state alias corpus coverage.
- `docs/tasks/R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.md` — completed `R9` task tree for strict-mode rejection of the legacy `<=+` assignment alias.
- `docs/tasks/R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported RHS expression variant corpus coverage.
- `docs/tasks/R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported computed comparison selector corpus coverage.
- `docs/tasks/R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported symbolic/default test-selector corpus coverage.
- `docs/tasks/R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported plain test-signal corpus coverage.
- `docs/tasks/R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported standalone DT guard corpus coverage.
- `docs/tasks/R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported relational test-branch selector corpus coverage.
- `docs/tasks/R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported computed test-selector corpus coverage.
- `docs/tasks/R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported relational-operator corpus coverage.
- `docs/tasks/R12-GUARD-SHORTHAND-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported guard-shorthand corpus coverage.
- `docs/tasks/R12-STATE-DTE-GUARD-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported state-DT header guard corpus coverage.
- `docs/tasks/R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported update-shorthand variant corpus coverage.
- `docs/tasks/R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained duplicate default test-selector expected-failure corpus coverage.
- `docs/tasks/R12-TOP-LEVEL-FORM-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained unsupported top-level form expected-failure corpus coverage.
- `docs/tasks/R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained delayed-pulse LHS target expected-failure corpus coverage.
- `docs/tasks/R12-PLUS-FSM-BODY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained malformed legacy `+fsm` root-body expected-failure corpus coverage.
- `docs/tasks/R12-SYMBOL-TOKEN-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained symbol-definition token expected-failure corpus coverage.
- `docs/tasks/R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained aggregate parameter-expression expected-failure corpus coverage.
- `docs/tasks/R12-PARAM-DEPENDENCY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained parameter dependency expected-failure corpus coverage.
- `docs/tasks/R12-SYMBOL-VALUE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained symbol-definition value expected-failure corpus coverage.
- `docs/tasks/R12-SYMBOL-ENTRY-MALFORMED-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained malformed symbol-definition entry expected-failure corpus coverage.
- `docs/tasks/R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained empty symbol-definition section expected-failure corpus coverage.
- `docs/tasks/R12-INIT-DIRECTIVE-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained `:=` init-directive shape expected-failure corpus coverage.
- `docs/tasks/R12-CONDITION-EXPRESSION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained condition-expression expected-failure corpus coverage.
- `docs/tasks/R12-RHS-EXPRESSION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained RHS expression expected-failure corpus coverage.
- `docs/tasks/R12-FSM-ROOT-BODY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained structured `?fsm` root-body expected-failure corpus coverage.
- `docs/tasks/R12-STATE-BODY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained state/DT body expected-failure corpus coverage.
- `docs/tasks/R12-UPDATE-SHORTHAND-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained update-shorthand expected-failure corpus coverage.
- `docs/tasks/R12-INLINE-MODIFIER-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained inline compound modifier expected-failure corpus coverage.
- `docs/tasks/R12-TEST-SELECTOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained test-signal/test-selector expected-failure corpus coverage.
- `docs/tasks/R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained authored operator/directive expected-failure corpus coverage.
- `docs/tasks/R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained assignment-boundary expected-failure corpus coverage.
- `docs/tasks/R12-NAME-REFERENCE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained source-name, state/DT-name, and transition-target expected-failure corpus coverage.
- `docs/tasks/R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained language-contract expected-failure corpus coverage.
- `docs/tasks/R12-MALFORMED-FORM-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained malformed-form expected-failure corpus coverage.
- `docs/tasks/R12-SYSTEM-SECTION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained malformed `+system` expected-failure corpus coverage.
- `docs/tasks/R8-PARTIAL-LHS-PULSE-BOUNDARY.md` — completed `R8` task tree for the delayed-pulse partial-LHS fail-closed boundary.
- `docs/tasks/R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.md` — completed `R8` task tree for preferred `<=-` partial-LHS dual-output coverage and the remaining pulse/vector decision split.
- `docs/BIN_FSMGEN_IMPORT_TREE.md` — live `bin/fsmgen` import-tree and runtime-spine architecture snapshot.
- `docs/IR_POLICY.md` — repo-local policy for adding, extending, exposing, or retiring IR and IR-like compiler surfaces.
- `docs/COMPOSITION_SCOPE.md` — concrete composition scope and acceptance boundary for the active architecture.
- `docs/COMPOSITION_LEGACY_MAPPING.md` — historical legacy-composition behavior mapped onto the active architecture.
- `docs/EXTENSION_MODEL.md` — typed extension boundary for the active `R7` replacement path.
- `docs/SPECFORGE_FEEDBACK_RESPONSE.md` — tracked FSMGen response to SPECFORGE adapter/tool-integration feedback.
- `docs/DOWNSTREAM_ISSUE_REPORTING.md` — strict downstream issue-reporting protocol for locally reproducible FSMGen bug reports.
- `docs/INTENT_SCHEDULING_BRAINSTORM.md` — living brainstorm log for inferring/scheduling cycles from a hardware-native intent layer above explicit `.fsm`.
- `docs/ISF_ATL_DESIGN_PROPOSAL.md` — live design proposal for ISF Actor Transfer Level actor-network orchestration.
- `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` — single self-contained downstream `.isf` integration handoff that must stay synchronized with the live spec, book, public contract, manifest metadata, tests, and code.
- `docs/ISF_SPEC.md` — active R14 `.isf` Intent Scheduling Format specification.
- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` — live downstream-consumer API contract for ISF parser/scheduler surfaces.
- `docs/ISF_LIBRARY_CATALOG.md` — live catalog of shipped reusable ISF library definitions.
- `docs/REGRESSION_CORPUS.md` — human-readable companion to the machine-checked support and regression catalog.
- `docs/SEMANTIC_INTROSPECTION_MCP_FIRST_CLASS_SELECTION.md` — selected first-class semantic-introspection API and MCP adapter boundary, records the shipped read-only adapter, and names the current client-compatibility limits.
- `docs/INTENT_CAPTURE_AXI_CASE_STUDY.md` — AXI intent-capture case-study notes for future high-level synthesis work.
- `docs/IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md` — first non-code IAL2 protocol/platform intent evaluation and go/no-go criteria.
- `docs/AXI_VALID_READY_INTENT_PROBE.md` — first bounded AXI Valid-Ready source-anchor evidence inventory for future IAL2 design/probe work.
- `docs/AXI_MANAGER_USER_API_BRAINSTORM.md` — captured AXI manager user-facing API direction for future IAL2 work.
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md` — first bounded AXI ID/order/concurrency source-anchor evidence inventory for future IAL2 manager rule-engine work.
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md` — first bounded AXI manager source-to-rule responsibility matrix for future IAL2 work.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md` — selected the first post-Valid-Ready AXI manager subset: outstanding-capacity plus acceptance/status feedback.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_READINESS_AUDIT.md` — readiness audit for the selected AXI manager capacity/status subset and first in-process generator boundary.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_GENERATOR_FIRST_SLICE.md` — first in-process AXI manager capacity/status generator slice and report surface.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_SYNTAX_SELECTION.md` — selected public `.ppif` syntax/readiness boundary for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md` — first public `.ppif` parser/CLI slice for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md` — selected the next AXI manager subset: ID-family declaration and static validation.
- `docs/AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md` — readiness audit for the additive ID-family/static-validation implementation boundary.
- `docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md` — shipped additive `.ppif` ID-family metadata slice for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md` — selected the next AXI manager subset: logical read/write transaction envelope and static validation.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md` — readiness audit for the additive transaction-envelope/static-validation implementation boundary.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md` — shipped additive `.ppif` transaction-envelope metadata slice for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md` — selected the next prerequisite: transaction event dispatch and direction fan-in.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md` — readiness audit for additive per-transaction event dispatch and direction fan-in.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md` — shipped additive `.ppif` transaction event dispatch/fan-in slice for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md` — selected the next AXI manager subset: ID/response rule-engine readiness.
- `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md` — readiness audit for additive concrete transaction ID request/response assertions.
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md` — shipped additive concrete transaction ID request/response assertions for the public AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md` — selected AXI manager auto-ID lifecycle/request-ID drive readiness as the next subset.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md` — readiness audit selecting bounded auto-ID pool/request-ID drive contract selection before implementation.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md` — selected explicit optional `auto-id-lifecycle` bounded-pool syntax before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_METADATA_FIRST_SLICE.md` — shipped additive `.ppif` auto-ID lifecycle parser/report metadata for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md` — shipped bounded auto-ID request-ID drive behavior for explicit lifecycle families.
- `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION.md` — selected AXI manager generated response-demux readiness after bounded auto-ID request-ID drive.
- `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md` — readiness audit selecting bounded write response-demux public contract before implementation.
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected explicit write-only `response-demux` public syntax before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md` — shipped write-only `response-demux` parser/report metadata for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md` — readiness audit selecting the IAL1 rule-pulse prerequisite before generated write `BID` demux behavior.
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md` — shipped generated write `BID` response-demux behavior for explicit `response-demux` contracts.
- `docs/AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION.md` — selected report-residue alignment after generated write `BID` demux before larger ordering/read-response work.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md` — shipped auto-ID lifecycle report-residue alignment after generated write `BID` demux.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION.md` — selected same-ID ordering readiness after generated write `BID` demux and residue alignment.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT.md` — readiness audit selecting bounded auto-ID same-ID avoidance assertions/report metadata before per-ID queues.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md` — shipped bounded generated auto-ID same-ID avoidance assertions/report metadata.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md` — selected read `RID` response-demux readiness after generated auto-ID same-ID avoidance.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md` — readiness audit selecting a bounded read response-demux public contract before parser/report or behavior changes.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected explicit `response-scope single-beat` read response-demux syntax before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md` — shipped read response-demux parser/report metadata and static validation without generated read behavior.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md` — readiness audit selecting bounded generated single-beat read `RID` response-demux behavior before implementation.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md` — shipped bounded generated single-beat read `RID` response-demux behavior for explicit read response-demux contracts.
- `docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data payload, burst/`RLAST`, and per-ID ordering/reassembly readiness as the next AXI manager IAL2 audit after generated read demux.
- `docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md` — readiness audit selecting bounded public read-data payload/status contract selection before parser/report or generated behavior changes.
- `docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md` — selected bounded single-beat `read-data` syntax for `RDATA`/`RRESP` capture before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md` — shipped structural `read_data` parser/report metadata and static validation without generated capture behavior.
- `docs/AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md` — readiness audit selecting generated single-beat `RDATA`/`RRESP` capture behavior with no new IAL1/IAL0/SystemVerilog prerequisite.
- `docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md` — shipped generated single-beat `RDATA`/`RRESP` capture behavior for explicit `read-data` contracts.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT.md` — readiness audit selecting public AXI burst/`RLAST` completion contract selection before parser/report metadata or generated behavior changes.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md` — selected additive read `response-demux` `response-scope burst-last` plus one-bit `last-signal` syntax before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for `response-scope burst-last` with generated `RLAST` behavior deferred.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT.md` — readiness audit selecting direct generated burst-last/`RLAST` completion behavior.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md` — shipped generated burst-last/`RLAST` completion behavior.
- `docs/AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION.md` — selected AXI `RLAST` report/static-text alignment before larger read-data reassembly or manager behavior.
- `docs/AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md` — shipped generated AXI `RLAST` schedule-report prose alignment.
- `docs/AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION.md` — selected public AXI burst read-data contract selection after generated `RLAST` completion/report alignment.
- `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md` — selected explicit last-beat `RDATA`/`RRESP` capture as the first bounded burst read-data contract.
- `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for explicit last-beat `RDATA`/`RRESP` capture with generated behavior deferred.
- `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md` — readiness audit selecting direct generated last-beat `RDATA`/`RRESP` capture behavior.
- `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md` — shipped generated last-beat `RDATA`/`RRESP` capture behavior.
- `docs/AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md` — selected public AXI burst read-data beat-count/depth contract selection after generated last-beat capture.
- `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md` — selected ARLEN-based `burst-length` syntax and report contract before parser/report metadata.
- `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for ARLEN-based `burst-length` contracts.
- `docs/AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION.md` — selected generated ARLEN burst-length capture readiness audit after report-only metadata.
- `docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_READINESS_AUDIT.md` — audited generated raw-ARLEN capture readiness and selected direct behavior.
- `docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md` — shipped generated raw-ARLEN capture behavior for opt-in last-beat read-data `burst-length` contracts.
- `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT.md` — audited beat-count/RLAST validation readiness and selected public runtime-validation contract selection before behavior.
- `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md` — selected `(validation runtime-assertion)` / `runtime_assertion` as the public beat-count/RLAST validation contract before behavior.
- `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md` — shipped generated beat-count/RLAST runtime validation for `(validation runtime-assertion)` burst-length contracts.
- `docs/AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md` — selected public multi-beat read-data reassembly/output contract selection after generated beat-count/RLAST validation.
- `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md` — selected per-beat output-bank public contract for multi-beat read-data reassembly/output.
- `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for the public multi-beat read-data output-bank contract.
- `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT.md` — audited generated output-bank behavior readiness and selected direct scalar-lane behavior.
- `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md` — shipped generated multi-beat read-data output-bank behavior for the public multi-beat sample.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION.md` — selected public scalar `RRESP` aggregation contract selection after generated multi-beat read-data output-bank behavior.
- `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md` — selected additive scalar `RRESP` aggregation syntax and report contract before parser/report metadata.
- `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for the selected scalar `RRESP` aggregation contract.
- `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_READINESS_AUDIT.md` — audited generated scalar `RRESP` aggregation readiness and selected direct generated behavior.
- `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE.md` — shipped generated scalar `RRESP` aggregation outputs/init/update behavior.
- `docs/AXI_IAL2_MANAGER_POST_RRESP_AGGREGATION_NEXT_SLICE_SELECTION.md` — selected per-ID read-data interleaving and queue readiness after scalar `RRESP` aggregation.
- `docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT.md` — audited read-data interleaving/queue readiness and selected report/static residue alignment for the covered generated auto-ID multi-beat-by-RID subset.
- `docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE.md` — aligned read-data interleaving residue for the covered generated auto-ID multi-beat-by-RID subset.
- `docs/AXI_IAL2_MANAGER_POST_INTERLEAVING_ALIGNMENT_NEXT_SLICE_SELECTION.md` — selected AXI burst payload/output readiness audit after read-data interleaving residue alignment.
- `docs/AXI_IAL2_MANAGER_BURST_PAYLOAD_OUTPUT_READINESS_AUDIT.md` — audited bounded burst payload/output readiness and selected report/static `bursts` residue alignment.
- `docs/AXI_IAL2_MANAGER_BURST_RESIDUE_ALIGNMENT_FIRST_SLICE.md` — aligned broad `bursts` residue for the covered generated auto-ID multi-beat output-bank subset.
- `docs/AXI_IAL2_MANAGER_POST_BURST_RESIDUE_NEXT_SLICE_SELECTION.md` — selected AXI concrete-ID same-ID ordering readiness after bounded burst residue alignment.
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT.md` — audited concrete-ID same-ID ordering readiness and selected fail-closed static validation for unsupported authored same-ID reuse.
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md` — shipped fail-closed static validation for unsupported same-family concrete-ID reuse.
- `docs/AXI_IAL2_MANAGER_POST_CONCRETE_ID_STATIC_VALIDATION_NEXT_SLICE_SELECTION.md` — selected per-ID issue-order queue readiness after concrete-ID static validation.
- `docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md` — audited per-ID issue-order queue readiness and selected same-ID reuse policy contract selection.
- `docs/AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md` — selected explicit same-ID reuse reject policy syntax before parser/report metadata.
- `docs/AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md` — shipped parser/report metadata and static validation for explicit same-ID reuse reject policy.
- `docs/AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION.md` — selected same-ID issue-order queue policy contract selection after explicit reject policy.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md` — selected the public AXI same-ID `issue-order-queue` policy contract and the follow-up behavior-readiness audit.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT.md` — audited same-ID `issue-order-queue` behavior readiness and selected metadata-first support.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md` — shipped metadata-first parser/report support for selected-not-generated `issue-order-queue`.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md` — audited admitted enqueue readiness and selected admitted request pulses before queue state.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md` — shipped admitted request pulse generation for selected same-ID `issue-order-queue` families while accepted same-ID reuse remains deferred.
- `docs/AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION.md` — selected same-ID issue-order queue state and queue-head demux readiness after admitted request pulses.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_DEMUX_READINESS_AUDIT.md` — audited same-ID queue-state and queue-head response-demux readiness.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION.md` — selected compact one-hot transaction slots for future same-ID issue-order queues.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected the concrete same-ID queue-head response-demux public/report contract.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md` — shipped selected-not-generated concrete same-ID queue-head response-demux metadata and static validation.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md` — audited generated same-ID queue state plus queue-head behavior readiness and selected the first generated behavior slice selector.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION.md` — selected read burst-last, one duplicate concrete-ID group, two-transaction depth-2 generated queue state plus queue-head demux as the first behavior implementation boundary.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md` — shipped bounded generated read burst-last depth-2 concrete same-ID queue state plus queue-head response demux for the public same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped bounded generated write depth-2 concrete same-ID queue state plus queue-head `BID` response demux for the public write same-ID sample.
- `docs/AXI_IAL2_MANAGER_POST_WRITE_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md` — selected bounded read `single-beat` concrete same-ID queue-head response demux as the next behavior slice.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped bounded generated read single-beat depth-2 concrete same-ID queue state plus queue-head `RID` response demux without `RLAST`.
- `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md` — selected queue-head read-data consumption readiness after generated read single-beat same-ID queue-head behavior.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md` — audited queue-head read-data readiness and selected generated single-beat queue-head read-data capture.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE.md` — shipped generated single-beat queue-head `RDATA`/`RRESP` capture for the bounded read single-beat concrete same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected generated last-beat queue-head `RDATA`/`RRESP` capture for the bounded read burst-last concrete same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated last-beat queue-head `RDATA`/`RRESP` capture for the bounded read burst-last concrete same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md` — selected generated raw-`ARLEN` burst-length capture for the bounded queue-head last-beat read-data shape.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md` — shipped report-only raw-`ARLEN` burst-length capture for the bounded queue-head last-beat read-data sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md` — selected generated queue-head beat-count/RLAST runtime validation for the bounded queue-head last-beat read-data shape.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated queue-head beat-count/RLAST runtime validation for the bounded queue-head last-beat read-data sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected generated queue-head multi-beat read-data output-bank behavior for the bounded read burst-last concrete same-ID queue-head demux shape.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated queue-head multi-beat read-data output-bank behavior for the bounded read burst-last concrete same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected multiple independent read burst-last depth-2 concrete same-ID queue-head response-demux group readiness after generated queue-head multi-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple depth-2 read burst-last queue-head response-demux groups and selected the narrow implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated multiple read burst-last depth-2 concrete same-ID queue-head response-demux groups.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data-over-multiple-generated-queue-groups readiness after generated multi-group queue-head demux.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md` — shipped generated multi-group queue-head multi-beat read-data output-bank behavior.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected last-beat-only read-data over multiple generated queue-head groups as the next audit owner.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md` — audited scalar last-beat read-data over multiple generated queue-head groups and selected the narrow implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated multi-group queue-head scalar last-beat read-data capture.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md` — selected generated report-only raw-`ARLEN` capture for multi-group queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` capture for multi-group queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md` — selected runtime-validation multi-group queue-head scalar last-beat readiness audit.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited runtime-validation multi-group queue-head scalar last-beat readiness and selected the implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated runtime-validation multi-group queue-head scalar last-beat read-data and records the `.137` support-report residue alignment.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected report/static residue cleanup after generated runtime-validation multi-group queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_POST_SUPPORT_RESIDUE_CLEANUP_NEXT_SLICE_SELECTION.md` — selected write-family multi-group queue-head response-demux readiness audit after support-residue cleanup.
- `docs/AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited generated write-family multi-group queue-head response-demux readiness and selected the implementation owner.
- `docs/AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated write-family multi-group queue-head response-demux behavior.
- `docs/AXI_IAL2_MANAGER_POST_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected read single-beat multi-group queue-head response-demux readiness audit after generated write-family multi-group queue-head response-demux.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited generated read single-beat multi-group queue-head response-demux readiness and selected the implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated read single-beat multi-group queue-head response-demux behavior and its semantic-introspection support-accounting surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data over read single-beat multi-group queue-head readiness audit after generated read single-beat multi-group response-demux.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md` — audited generated read-data over read single-beat multi-group queue-head readiness and selected the implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md` — shipped generated read-data over read single-beat multi-group queue-head response-demux behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected deeper concrete same-ID queue-head readiness audit after generated read-data over read single-beat multi-group queue-head response-demux.
- `docs/AXI_IAL2_MANAGER_DEEPER_QUEUE_HEAD_GROUPS_READINESS_AUDIT.md` — audited generated concrete same-ID queue-head groups deeper than two slots and selected generated read single-beat depth-3 response-demux through generalized shared queue-state helpers.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated read single-beat depth-3 queue-head response-demux behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected focused PPIF support-detail expectation alignment before the next depth-3 behavior expansion.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md` — audited scalar read-data over generated read single-beat depth-3 queue-head response-demux readiness and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md` — shipped generated scalar read-data over read single-beat depth-3 queue-head response-demux behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected read burst-last depth-3 queue-head response-demux readiness audit after generated read single-beat depth-3 queue-head read-data.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited generated read burst-last depth-3 queue-head response-demux readiness and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated read burst-last depth-3 queue-head response-demux behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data over read burst-last depth-3 queue-head response-demux readiness audit after generated read burst-last depth-3 queue-head response-demux.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md` — audited scalar read-data over generated read burst-last depth-3 queue-head response-demux readiness and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md` — shipped generated scalar last-beat read-data over read burst-last depth-3 queue-head response-demux and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected report-only raw-`ARLEN` burst-length readiness audit after generated read burst-last depth-3 queue-head read-data.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only raw-`ARLEN` burst-length over generated read burst-last depth-3 queue-head read-data readiness and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` burst-length capture over read burst-last depth-3 queue-head read-data and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md` — selected runtime-validation readiness after generated read burst-last depth-3 queue-head report-only raw-`ARLEN` burst-length behavior.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited runtime-validation readiness over generated read burst-last depth-3 queue-head raw-`ARLEN` burst-length and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated runtime beat-count/`RLAST` validation over read burst-last depth-3 queue-head raw-`ARLEN` burst-length and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected multi-beat output-bank readiness after generated read burst-last depth-3 queue-head runtime-validation behavior.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md` — audited generated multi-beat output-bank readiness over read burst-last depth-3 queue-head runtime validation and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated multi-beat read-data output-bank behavior over read burst-last depth-3 queue-head runtime validation and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected write depth-3 queue-head response-demux readiness after generated read burst-last depth-3 queue-head multi-beat read-data.
- `docs/AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited generated write depth-3 queue-head response-demux readiness and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated write depth-3 queue-head response-demux behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected multiple/mixed depth-3 queue-head response-demux readiness after generated write depth-3 queue-head response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple/mixed depth-3 queue-head response-demux readiness and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated multiple/mixed depth-3 queue-head response-demux behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data over multiple/mixed depth-3 queue-head groups as the next readiness audit after generated multiple/mixed depth-3 response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md` — audited read-data over multiple/mixed depth-3 queue-head groups and selected read single-beat scalar implementation.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md` — shipped generated multiple/mixed depth-3 read single-beat queue-head scalar read-data behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected burst-last scalar last-beat read-data over multiple/mixed depth-3 queue-head groups as the next readiness audit.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md` — audited multiple/mixed depth-3 queue-head burst-last last-beat read-data readiness and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated multiple/mixed depth-3 read burst-last queue-head scalar last-beat read-data behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md` — selected report-only raw-`ARLEN` burst-length readiness over multiple/mixed depth-3 queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only raw-`ARLEN` burst-length readiness over multiple/mixed depth-3 queue-head scalar last-beat read-data and selected the direct implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` burst-length capture over multiple/mixed depth-3 queue-head scalar last-beat read-data and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md` — selected runtime beat-count/`RLAST` validation readiness over multiple/mixed depth-3 queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited runtime beat-count/`RLAST` validation readiness over multiple/mixed depth-3 queue-head scalar last-beat read-data and selected the direct implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated runtime beat-count/`RLAST` validation over multiple/mixed depth-3 queue-head scalar last-beat read-data and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected report/static support-residue cleanup after generated runtime beat-count/`RLAST` validation over multiple/mixed depth-3 queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP.md` — cleaned stale support/residue wording for generated runtime beat-count/`RLAST` validation over multiple/mixed depth-3 queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_RESIDUE_CLEANUP_NEXT_SLICE_SELECTION.md` — selected multi-beat output-bank readiness over multiple/mixed depth-3 runtime-validation queue-head groups.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md` — audited generated multi-beat output-bank readiness over multiple/mixed depth-3 runtime-validation queue-head groups and selected the direct implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated multi-beat output-bank behavior over multiple/mixed depth-3 runtime-validation queue-head groups and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected same-family mixed auto-ID lifecycle plus concrete same-ID queue-head response-demux readiness after generated multiple/mixed depth-3 multi-beat output banks.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited same-family mixed auto-ID lifecycle plus concrete same-ID queue-head response-demux readiness and selected the direct bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped same-family mixed auto-ID lifecycle plus concrete same-ID queue-head response-demux behavior for bounded response-demux-only read single-beat, read burst-last, and write shapes.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected mixed read-data consumption readiness after same-family mixed auto-ID plus concrete queue-head response-demux.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md` — audited mixed scalar read-data readiness over same-family mixed auto-ID plus concrete queue-head response-demux and selected the direct bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_BEHAVIOR.md` — shipped bounded scalar read-data over same-family mixed auto-ID plus concrete queue-head response-demux for read single-beat and read burst-last shapes.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected mixed report-only raw-`ARLEN` burst-length readiness after bounded mixed scalar read-data.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md` — audited mixed report-only raw-`ARLEN` burst-length readiness and selected the direct support/publication owner.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md` — shipped support-accounted mixed report-only raw-`ARLEN` burst-length capture and records the historical pre-`.202` runtime boundary.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited mixed runtime beat-count/`RLAST` validation readiness and selected the direct implementation owner.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped support-accounted mixed runtime beat-count/`RLAST` validation and its semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected support/static and public-contract residue cleanup after mixed runtime validation shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP.md` — cleaned stale support/static and public-contract wording after mixed runtime validation shipped.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_CLEANUP_NEXT_SLICE_SELECTION.md` — selected mixed multi-beat output-bank readiness audit after mixed runtime support cleanup.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md` — audited mixed multi-beat output-bank readiness after mixed runtime validation and selected the direct bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated mixed multi-beat output-bank behavior over the selected same-family mixed auto-ID plus depth-2 concrete same-ID queue-head runtime-validation shape and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected group-local simultaneous enqueue widening readiness after generated mixed multi-beat output-bank behavior.
- `docs/AXI_IAL2_MANAGER_GROUP_LOCAL_SAME_ID_ENQUEUE_READINESS_AUDIT.md` — audited group-local same-ID enqueue readiness and selected counted admission/capacity prerequisite audit.
- `docs/AXI_IAL2_MANAGER_COUNTED_ADMISSION_CAPACITY_READINESS_AUDIT.md` — audited counted same-ID request admission/capacity placement and selected the bounded counted capacity substrate implementation.
- `docs/AXI_IAL2_MANAGER_COUNTED_SAME_ID_CAPACITY_SUBSTRATE_BEHAVIOR.md` — shipped counted same-ID selected-request capacity/status substrate for generated multi-group queue-head families while preserving family-wide request onehot behavior.
- `docs/AXI_IAL2_MANAGER_POST_COUNTED_CAPACITY_NEXT_SLICE_SELECTION.md` — selected admitted-request guard alignment readiness before group-local same-ID enqueue behavior.
- `docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_READINESS_AUDIT.md` — audited counted admitted-request guard alignment and selected bounded group-local request assertion implementation.
- `docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_BEHAVIOR.md` — shipped counted admitted-request guard alignment and group-local request assertions for generated multi-group queue-head families.
- `docs/AXI_IAL2_MANAGER_POST_COUNTED_GROUP_LOCAL_ENQUEUE_NEXT_SLICE_SELECTION.md` — selected dynamic same-ID issue-order queue readiness after counted group-local enqueue behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_READINESS_AUDIT.md` — audited dynamic/user transaction-ID readiness and selected public contract selection before generalized per-ID queues.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CONTRACT_SELECTION.md` — selected transaction-local `(id dynamic)` contract and dynamic-ID metadata readiness audit.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_READINESS_AUDIT.md` — audited metadata-first `(id dynamic)` parser/report readiness and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md` — shipped metadata-first `(id dynamic)` parser/report behavior and support-accounted dynamic-ID metadata sample.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_TRANSACTION_ID_METADATA_NEXT_SLICE_SELECTION.md` — selected generated dynamic transaction-ID capture and response matching readiness after metadata-only `(id dynamic)` support.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md` — audited generated dynamic ID capture/matching readiness and selected bounded dynamic write `BID` contract selection.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md` — selected existing `response-demux.write` plus one dynamic write transaction as the direct generated dynamic write ID capture/matching contract.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_BEHAVIOR.md` — shipped bounded dynamic write transaction-ID capture and `BID` response matching for one explicit `response-demux.write` dynamic write transaction.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_ID_NEXT_SLICE_SELECTION.md` — selected dynamic read transaction-ID capture and `RID` response matching readiness after generated dynamic write ID behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md` — audited generated dynamic read transaction-ID capture and `RID` matching readiness and selected bounded single-beat contract selection.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md` — selected existing `response-demux.read` plus one dynamic read transaction as the direct generated bounded single-beat dynamic read ID capture and `RID` matching contract.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md` — shipped bounded single-beat dynamic read transaction-ID capture and `RID` response matching for one explicit `response-demux.read` dynamic read transaction.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_ID_NEXT_SLICE_SELECTION.md` — selected dynamic read burst-last/`RLAST` transaction-ID capture and response matching readiness after generated dynamic read ID behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_READINESS_AUDIT.md` — audited dynamic read burst-last/`RLAST` transaction-ID capture readiness and selected public contract selection before behavior changes.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md` — selected existing `response-demux.read` burst-last syntax plus one dynamic read transaction as the direct generated dynamic read `RID`/`RLAST` matching contract.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md` — shipped bounded dynamic read burst-last/`RLAST` transaction-ID capture and `RID`/`RLAST` response matching for one explicit `response-demux.read` dynamic read transaction.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_NEXT_SLICE_SELECTION.md` — selected dynamic read-data routing readiness after generated dynamic read burst-last/`RLAST` response-demux behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_READINESS_AUDIT.md` — audited dynamic read-data routing readiness and selected direct bounded scalar single-beat plus last-beat implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md` — shipped bounded scalar dynamic read-data capture over generated single-active dynamic read response-demux for scalar single-beat and scalar last-beat shapes.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION.md` — selected AXI manager focused-suite cost cleanup before further dynamic behavior expansion.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_FOCUSED_SUITE_CLEANUP.md` — added bounded focused validation for the shipped dynamic transaction-ID family before dynamic burst-length readiness work.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only dynamic raw-`ARLEN` burst-length readiness over generated dynamic last-beat read-data and selected the direct implementation owner.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only dynamic raw-`ARLEN` burst-length capture over generated single-active dynamic read last-beat read-data.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited dynamic runtime beat-count/`RLAST` validation readiness over generated dynamic last-beat read-data and selected the direct implementation owner.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated dynamic runtime beat-count/`RLAST` validation over generated single-active dynamic read last-beat read-data.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected generated dynamic multi-beat output-bank readiness after dynamic runtime validation shipped.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_READINESS_AUDIT.md` — audited dynamic multi-beat output-bank readiness and selected direct bounded implementation over generated dynamic runtime validation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md` — shipped generated dynamic multi-beat read-data output-bank behavior over generated dynamic runtime validation.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected multiple/mixed dynamic response-demux readiness audit after generated dynamic multi-beat output banks shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple/mixed dynamic response-demux readiness and selected public contract selection for bounded multiple dynamic write demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded multiple dynamic write response-demux with onehot0 dynamic write requests and pairwise unique active dynamic IDs.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded multiple dynamic write response-demux for all-dynamic write families with onehot0 dynamic write requests and pairwise unique active dynamic IDs.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected multiple dynamic read response-demux readiness audit after bounded multiple dynamic write response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple dynamic read response-demux readiness and selected public contract selection for bounded multiple dynamic read demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded multiple dynamic read single-beat response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded multiple dynamic read single-beat response-demux for all-dynamic read families with onehot0 dynamic read requests and pairwise unique active dynamic IDs.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected readiness audit for multiple dynamic read burst-last/`RLAST` response-demux after bounded multiple dynamic read single-beat response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple dynamic read burst-last/`RLAST` response-demux readiness and selected public contract selection before behavior changes.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded multiple dynamic read burst-last/`RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded multiple dynamic read burst-last/`RLAST` response-demux with raw `RID` beat assertions and final `RID && RLAST` completion pulses.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data readiness audit after generated multiple dynamic read burst-last/`RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_READINESS_AUDIT.md` — audited read-data readiness over generated multiple dynamic read response-demux and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded scalar read-data over generated multiple dynamic read response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md` — shipped generated bounded scalar read-data over generated multiple dynamic read response-demux with public single-beat and last-beat samples.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION.md` — selected readiness audit for burst-length/runtime validation over generated multiple dynamic read response-demux after scalar multiple dynamic read-data shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_READINESS_AUDIT.md` — audited burst-length/runtime validation readiness over generated multiple dynamic read response-demux and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_CONTRACT_SELECTION.md` — selected a split public contract: report-only multiple dynamic raw-`ARLEN` capture first, then runtime beat-count/`RLAST` validation.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` burst-length capture over generated multiple dynamic read response-demux and scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md` — shipped generated runtime beat-count/`RLAST` validation over generated multiple dynamic read response-demux and scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected generated multiple dynamic multi-beat output-bank readiness audit after multiple dynamic runtime validation shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_READINESS_AUDIT.md` — audited generated multiple dynamic multi-beat output-bank readiness and selected public contract selection before behavior changes.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_CONTRACT_SELECTION.md` — selected direct generated implementation of bounded multiple dynamic multi-beat output-bank behavior and reserved the explicit `dynamic_read_data_multi_transaction_multi_beat` public sample stem.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md` — shipped generated bounded multiple dynamic multi-beat output-bank behavior over generated multiple dynamic runtime validation.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected mixed dynamic/static response-demux readiness after generated bounded multiple dynamic multi-beat output banks shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited mixed dynamic/static response-demux readiness and selected public contract selection for bounded mixed dynamic/static write `BID` response-demux.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded mixed dynamic/static write `BID` response-demux.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded mixed dynamic/static write `BID` response-demux with static concrete-ID reservation away from dynamic capture.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md` — selected mixed dynamic/static read response-demux readiness after bounded mixed dynamic/static write `BID` response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited mixed dynamic/static read response-demux readiness and selected public contract selection for bounded mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded mixed dynamic/static read single-beat `RID` response-demux with static concrete-ID reservation away from dynamic capture.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md` — selected mixed dynamic/static read burst-last `RID && RLAST` readiness after bounded mixed dynamic/static read single-beat `RID` response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited mixed dynamic/static read burst-last `RID && RLAST` readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded mixed dynamic/static read burst-last `RID && RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded mixed dynamic/static read burst-last `RID && RLAST` response-demux with final-beat completion and raw `RID` beat assertions.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data readiness after bounded mixed dynamic/static read burst-last `RID && RLAST` response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md` — audited mixed dynamic/static read-data readiness and selected public contract selection before behavior.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded scalar read-data over generated mixed dynamic/static read response-demux.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md` — shipped generated bounded scalar read-data capture over generated mixed dynamic/static read response-demux.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md` — selected mixed dynamic/static report-only raw-ARLEN burst-length readiness after scalar mixed read-data shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md` — audited mixed dynamic/static read-data burst-length readiness and selected direct report-only raw-ARLEN capture behavior.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` burst-length capture over generated mixed dynamic/static read burst-last response-demux and scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited mixed dynamic/static runtime beat-count/`RLAST` validation readiness after report-only raw-`ARLEN` capture and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated runtime beat-count/`RLAST` validation over generated mixed dynamic/static read burst-last response-demux and scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md` — audited mixed dynamic/static multi-beat output-bank readiness after generated mixed runtime validation and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md` — shipped generated mixed dynamic/static multi-beat output banks over generated mixed runtime validation.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected multiple mixed dynamic/static transaction cardinality readiness after generated mixed dynamic/static multi-beat output banks shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple mixed dynamic/static transaction cardinality and selected public contract selection for bounded multiple mixed dynamic/static write `BID` response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded multiple mixed dynamic/static write `BID` response-demux with one dynamic and two concrete static write transactions.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded multiple mixed dynamic/static write `BID` response-demux with one dynamic and two concrete static write transactions.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md` — selected multiple mixed dynamic/static read response-demux readiness after bounded multiple mixed dynamic/static write `BID` response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple mixed dynamic/static read response-demux readiness and selected public contract selection for bounded multiple mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded multiple mixed dynamic/static read single-beat `RID` response-demux with one dynamic and two concrete static read transactions.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded multiple mixed dynamic/static read single-beat `RID` response-demux with one dynamic and two concrete static read transactions.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md` — selected multiple mixed dynamic/static read burst-last `RID && RLAST` readiness after bounded multiple mixed dynamic/static read single-beat `RID` response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple mixed dynamic/static read burst-last `RID && RLAST` readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded multiple mixed dynamic/static read burst-last `RID && RLAST` response-demux with one dynamic and two concrete static read transactions.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded multiple mixed dynamic/static read burst-last `RID && RLAST` response-demux with one dynamic and two concrete static read transactions.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md` — selected scalar read-data readiness after bounded multiple mixed dynamic/static read single-beat and burst-last response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md` — audited scalar read-data readiness over generated multiple mixed dynamic/static read response-demux and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded scalar read-data over generated multiple mixed dynamic/static read response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md` — shipped generated bounded scalar read-data over generated multiple mixed dynamic/static read response-demux.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md` — selected report-only raw-`ARLEN` burst-length readiness after multiple mixed scalar read-data shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only raw-`ARLEN` burst-length readiness over generated multiple mixed dynamic/static last-beat read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` burst-length capture over generated multiple mixed dynamic/static read burst-last response-demux and scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited runtime beat-count/`RLAST` validation readiness over generated multiple mixed dynamic/static raw-`ARLEN` last-beat read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated runtime beat-count/`RLAST` validation over generated multiple mixed dynamic/static raw-`ARLEN` last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md` — audited multiple mixed dynamic/static multi-beat output-bank readiness over generated runtime validation and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md` — shipped generated multiple mixed dynamic/static multi-beat output banks over generated runtime validation.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected broader mixed dynamic/static transaction cardinality readiness after generated multiple mixed dynamic/static multi-beat output banks shipped.
- `docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_READINESS_AUDIT.md` — audited broader mixed dynamic/static cardinality readiness and selected public contract selection before behavior changes.
- `docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_CONTRACT_SELECTION.md` — selected one dynamic plus three concrete static write `BID` response-demux as the first broader mixed cardinality behavior.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md` — selected one dynamic plus three concrete static mixed dynamic/static read response-demux readiness after the three-static write demux shipped.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited one dynamic plus three concrete static mixed dynamic/static read response-demux readiness and selected public contract selection for the single-beat `RID` boundary.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for one dynamic plus three concrete static mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated one dynamic plus three concrete static write `BID` response-demux while preserving the existing multi-mixed write report mode.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated one dynamic plus three concrete static mixed dynamic/static read single-beat `RID` response-demux while preserving the existing multi-mixed read report mode.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md` — selected one dynamic plus three concrete static mixed dynamic/static read burst-last `RID && RLAST` readiness after the three-static read single-beat demux shipped.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited one dynamic plus three concrete static mixed dynamic/static read burst-last `RID && RLAST` readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for one dynamic plus three concrete static mixed dynamic/static read burst-last `RID && RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated one dynamic plus three concrete static mixed dynamic/static read burst-last `RID && RLAST` response-demux while preserving the existing multi-mixed read report mode.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md` — selected scalar read-data readiness after the three-static read burst-last demux shipped.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md` — audited scalar read-data readiness over generated one dynamic plus three concrete static mixed dynamic/static read response-demux and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded scalar read-data over generated one dynamic plus three concrete static mixed dynamic/static read response-demux.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md` — shipped generated scalar read-data over generated one dynamic plus three concrete static mixed dynamic/static read response-demux.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md` — selected report-only raw-`ARLEN` burst-length readiness after three-static scalar read-data shipped.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md` — audited three-static mixed dynamic/static read-data report-only raw-`ARLEN` burst-length readiness and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` burst-length capture over generated one dynamic plus three concrete static mixed dynamic/static last-beat read-data.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited three-static mixed dynamic/static runtime beat-count/`RLAST` validation readiness and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated runtime beat-count/`RLAST` validation over generated one dynamic plus three concrete static mixed dynamic/static raw-`ARLEN` last-beat read-data.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md` — audited three-static mixed dynamic/static multi-beat output-bank readiness and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md` — shipped generated multi-beat output banks over generated one dynamic plus three concrete static mixed dynamic/static runtime-validation read-data.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected readiness audit for two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux after the three-static mixed read-data chain reached multi-beat output banks.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` response-demux readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST` response-demux readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_READINESS_AUDIT.md` — audited scalar last-beat read-data readiness over the two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST` response-demux and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_CONTRACT_SELECTION.md` — selected direct generated behavior for scalar last-beat read-data over the two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BEHAVIOR.md` — shipped scalar last-beat read-data capture over the generated two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_NEXT_SLICE_SELECTION.md` — selected report-only raw-`ARLEN` burst-length readiness audit after two-dynamic-plus-one-static mixed dynamic/static read burst-last read-data shipped.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only raw-`ARLEN` burst-length readiness over generated two-dynamic-plus-one-static mixed dynamic/static read burst-last read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_BEHAVIOR.md` — shipped report-only raw-`ARLEN` burst-length capture over generated two-dynamic-plus-one-static mixed dynamic/static read burst-last read-data.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited runtime beat-count/`RLAST` validation readiness over generated two-dynamic-plus-one-static mixed dynamic/static raw-`ARLEN` read burst-last read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped runtime beat-count/`RLAST` validation over generated two-dynamic-plus-one-static mixed dynamic/static raw-`ARLEN` read burst-last read-data.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md` — audited multi-beat output-bank readiness over generated two-dynamic-plus-one-static mixed dynamic/static runtime-validation read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_BEHAVIOR.md` — shipped generated multi-beat output banks over generated two-dynamic-plus-one-static mixed dynamic/static runtime-validation read-data.
- `docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected scalar single-beat read-data readiness audit after the two-dynamic-plus-one-static mixed dynamic/static read-data chain reached multi-beat output banks.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md` — audited scalar single-beat read-data readiness over the generated two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` response-demux and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md` — selected direct generated scalar single-beat read-data behavior over the generated two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md` — shipped scalar single-beat read-data capture over the generated two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md` — selected same-cycle request/response and release-and-recapture readiness audit after the two-dynamic-plus-one-static mixed dynamic/static read-data sibling shipped.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_MIXED_SAME_CYCLE_READINESS_AUDIT.md` — audited same-cycle request/response and release-and-recapture readiness for generated dynamic/mixed response-demux/read-data shapes and selected the single-active dynamic write contract-selection boundary.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md` — audited mixed dynamic/static same-cycle release-and-recapture readiness and selected mixed dynamic/static write `BID` public contract selection as the next owner.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md` — selected direct mixed dynamic/static write `BID` same-cycle release-and-recapture implementation under the existing public sample.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md` — shipped mixed dynamic/static write `BID` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected public contract selection for mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture after mixed write recapture shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md` — selected direct mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture implementation under the existing public sample.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md` — shipped mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture after mixed read single-beat recapture shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md` — audited mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md` — selected direct mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture implementation under the existing public sample.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md` — shipped mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected broader mixed dynamic/static same-cycle release-and-recapture readiness audit after the one-dynamic plus one-static mixed recapture family shipped.
- `docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md` — audited broader mixed dynamic/static same-cycle release-and-recapture readiness and selected one-dynamic plus two-static mixed write `BID` public contract selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md` — selected direct one-dynamic plus two-static mixed dynamic/static write `BID` same-cycle release-and-recapture implementation under the existing multi-static public sample.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md` — shipped one-dynamic plus two-static mixed dynamic/static write `BID` same-cycle release-and-recapture under the existing multi-static public sample.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected public contract selection for one-dynamic plus three-static mixed dynamic/static write `BID` same-cycle release-and-recapture after the two-static recapture sibling shipped.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md` — selected direct one-dynamic plus three-static mixed dynamic/static write `BID` same-cycle release-and-recapture implementation under the existing three-static public sample.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md` — shipped one-dynamic plus three-static mixed dynamic/static write `BID` same-cycle release-and-recapture under the existing three-static public sample.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle release-and-recapture after the three-static recapture sibling shipped.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_READINESS_AUDIT.md` — audited two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle release-and-recapture readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md` — selected direct two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle release-and-recapture implementation under the existing public sample.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md` — shipped two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture after broader mixed write recapture shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md` — audited one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md` — selected direct one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture implementation under the existing public sample.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md` — shipped one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture after the single-beat two-static recapture sibling shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md` — audited one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md` — selected direct one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture implementation under the existing public sample.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md` — shipped one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture after the two-static read recapture family shipped.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md` — audited one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md` — selected direct one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture implementation under the existing three-static public sample.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md` — shipped one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture under the existing three-static public sample.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture after the single-beat three-static recapture sibling shipped.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md` — audited one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md` — selected direct one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture implementation under the existing three-static public sample.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md` — shipped one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture under the existing three-static public sample.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture after the one-dynamic-plus-three-static burst-last recapture sibling shipped.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md` — audited readiness for two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md` — selected direct implementation of the two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture contract.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md` — shipped two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture after the single-beat two-dynamic recapture sibling shipped.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md` — audited readiness for two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md` — selected direct implementation of the two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture contract.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md` — shipped two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected dynamic same-ID issue-order readiness audit after the bounded dynamic/mixed response-demux, read-data, multi-beat, and recapture chain reached two-dynamic-plus-one-static mixed read burst-last recapture.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_READINESS_AUDIT.md` — audited dynamic same-ID policy readiness after bounded dynamic/mixed recapture completion and selected public dynamic same-ID policy contract selection before queues or scoreboards.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_CONTRACT_SELECTION.md` — selected additive `(dynamic-id-reuse reject)` public contract and metadata-first parser/report readiness audit before implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_METADATA_READINESS_AUDIT.md` — audited metadata-first implementation readiness for `(dynamic-id-reuse reject)` and selected direct parser/report implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_METADATA_FIRST_SLICE.md` — shipped metadata-first parser/report support for `(dynamic-id-reuse reject)`, including report fields, diagnostics, sample/support accounting, and deferred generated enforcement.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_READINESS_AUDIT.md` — audited generated dynamic same-ID reject enforcement mapping readiness and selected a narrow multi-active dynamic/mixed response-demux report mapping.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR.md` — shipped generated dynamic same-ID reject enforcement report mapping over covered multi-active dynamic/mixed response-demux assertions.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md` — selected single-active dynamic same-ID reject mapping readiness audit after the multi-active generated reject mapping shipped.
- `docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT.md` — audited single-active dynamic same-ID reject mapping readiness and selected public report contract selection.
- `docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION.md` — selected direct implementation of the single-active dynamic same-ID reject report/acceptance mapping contract.
- `docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR.md` — shipped single-active dynamic same-ID reject report/acceptance mapping over existing generated idle-or-releasing response-demux assertions.
- `docs/AXI_IAL2_MANAGER_POST_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md` — selected one-dynamic mixed dynamic/static dynamic same-ID reject mapping readiness audit after the single-active generated reject mapping shipped.
- `docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT.md` — audited one-dynamic mixed dynamic/static dynamic same-ID reject mapping readiness and selected public report contract selection.
- `docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION.md` — selected direct implementation of the one-dynamic mixed dynamic/static dynamic same-ID reject report/acceptance mapping contract.
- `docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR.md` — shipped one-dynamic mixed dynamic/static dynamic same-ID reject report/acceptance mapping over existing generated static-ID exclusion response-demux assertions.
- `docs/AXI_IAL2_MANAGER_POST_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md` — selected dynamic same-ID `issue-order-queue` policy contract readiness after all bounded dynamic reject mappings shipped.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_READINESS_AUDIT.md` — audited dynamic same-ID `issue-order-queue` policy readiness and selected public contract selection before parser/report changes.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_CONTRACT_SELECTION.md` — selected metadata-first parser/report support for dynamic same-ID `issue-order-queue` policy before generated queue behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_METADATA_FIRST_BEHAVIOR.md` — shipped metadata-first parser/report support and a public PPIF sample for dynamic same-ID `issue-order-queue` policy.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_NEXT_SLICE_SELECTION.md` — selected generated dynamic same-ID `issue-order-queue` behavior readiness after metadata-first dynamic issue-order policy support.
- `docs/AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated dynamic same-ID `issue-order-queue` readiness and selected public contract selection before implementation.
- `docs/AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md` — selected runtime-ID queue-state representation before the first generated dynamic same-ID `issue-order-queue` behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_ID_QUEUE_STATE_REPRESENTATION_SELECTION.md` — selected compact runtime-ID issue-order slots before generated dynamic write `BID` queue behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — shipped generated bounded two-transaction all-dynamic write `BID` dynamic issue-order queue behavior.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md` — selected dynamic read same-ID `issue-order-queue` readiness after the generated dynamic write `BID` queue shipped.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited dynamic read same-ID `issue-order-queue` readiness and selected public contract selection for the first all-dynamic read single-beat `RID` queue.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md` — selected the public contract for the bounded two-transaction all-dynamic read single-beat `RID` dynamic same-ID `issue-order-queue` behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — shipped generated bounded two-transaction all-dynamic read single-beat `RID` dynamic same-ID issue-order queue behavior.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md` — selected generated dynamic read burst-last `RID && RLAST` same-ID issue-order queue readiness after the single-beat read queue behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated dynamic read burst-last `RID && RLAST` same-ID issue-order queue readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md` — selected the public contract for the first generated dynamic read burst-last `RID && RLAST` same-ID issue-order queue behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — shipped generated bounded two-transaction all-dynamic read burst-last `RID && RLAST` dynamic same-ID issue-order queue behavior.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md` — selected read-data over generated dynamic read same-ID issue-order queue readiness after generated dynamic read burst-last same-ID queue behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md` — audited read-data over generated dynamic read same-ID issue-order queue completions and selected paired scalar public contract selection.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_CONTRACT_SELECTION.md` — selected direct implementation of paired scalar read-data over generated dynamic read same-ID issue-order queue completions.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md` — shipped paired scalar read-data over generated dynamic read same-ID issue-order queue completions.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only raw-`ARLEN` burst-length readiness over generated dynamic read same-ID issue-order queue last-beat read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md` — shipped report-only raw-`ARLEN` burst-length capture over generated dynamic read same-ID issue-order queue last-beat read-data.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited runtime beat-count/`RLAST` validation readiness over generated dynamic read same-ID issue-order queue raw-`ARLEN` read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped runtime beat-count/`RLAST` validation over generated dynamic read same-ID issue-order queue raw-`ARLEN` read-data.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md` — audited multi-beat output-bank readiness over generated dynamic read same-ID issue-order queue runtime-validation read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md` — shipped multi-beat output banks over generated dynamic read same-ID issue-order queue runtime-validation read-data.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_READINESS_AUDIT.md` — audited queue recapture readiness after generated dynamic read same-ID issue-order queue multi-beat output banks and selected report/static contract selection.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_REPORT_CONTRACT_SELECTION.md` — selected identity-preserving same-transaction queue recapture ID-refresh readiness before adding any positive queue recapture report field.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_READINESS_AUDIT.md` — audited identity-preserving same-transaction queue recapture ID refresh and selected direct implementation of state-key-preserving dynamic queue update rules.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_BEHAVIOR.md` — shipped state-key-preserving dynamic same-ID issue-order queue recapture ID refresh for generated two-transaction dynamic queue families.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_REPORT_CONTRACT_SELECTION.md` — selected queue-owned public report fields for generated dynamic same-ID issue-order queue identity recapture.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_REPORT_BEHAVIOR.md` — shipped queue-owned `same_transaction_*` report fields for generated dynamic same-ID issue-order queue identity recapture.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_QUEUE_RECAPTURE_REPORT_NEXT_SLICE_SELECTION.md` — selected depth-3 all-dynamic write BID same-ID issue-order queue readiness as the next dynamic queue widening audit after identity-recapture report alignment.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated all-dynamic write BID depth-3 same-ID issue-order queue readiness and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — shipped generated all-dynamic write BID depth-3 same-ID issue-order queue behavior with rule-name disambiguation for ambiguous cross-transaction enqueue rules.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md` — selected generated all-dynamic read single-beat RID depth-3 same-ID issue-order queue readiness as the next dynamic queue widening audit after write depth-3 behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated all-dynamic read single-beat RID depth-3 same-ID issue-order queue readiness and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — shipped generated all-dynamic read single-beat RID depth-3 same-ID issue-order queue behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue readiness and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — shipped generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue behavior.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md` — selected scalar last-beat read-data over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue behavior as the next readiness audit.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md` — audited scalar last-beat read-data over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue behavior and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md` — shipped scalar last-beat read-data over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue behavior.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_NEXT_SLICE_SELECTION.md` — selected report-only raw-`ARLEN` readiness over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue read-data as the next audit.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only raw-`ARLEN` readiness over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue read-data and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md` — shipped report-only raw-`ARLEN` burst-length capture over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue read-data.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_NEXT_SLICE_SELECTION.md` — selected runtime beat-count/`RLAST` validation readiness over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue raw-`ARLEN` read-data as the next audit.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited runtime beat-count/`RLAST` validation readiness over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue raw-`ARLEN` read-data and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped runtime beat-count/`RLAST` validation over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue raw-`ARLEN` read-data.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected multi-beat output-bank readiness over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue runtime-validation read-data as the next audit.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md` — audited multi-beat output-bank readiness over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue runtime-validation read-data and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md` — shipped multi-beat output banks over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue runtime-validation read-data.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected generated mixed dynamic/static write `BID` same-ID issue-order queue readiness after the all-dynamic depth-3 dynamic queue/read-data ladder closed.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated mixed dynamic/static write `BID` same-ID issue-order queue readiness and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — documents generated mixed dynamic/static write `BID` same-ID issue-order queue behavior for one dynamic plus one concrete static transaction.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md` — selected mixed dynamic/static read single-beat `RID` same-ID issue-order queue readiness after the first mixed write `BID` issue-order queue shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated mixed dynamic/static read single-beat `RID` same-ID issue-order queue readiness and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — documents generated mixed dynamic/static read single-beat `RID` same-ID issue-order queue behavior for one dynamic plus one concrete static transaction.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md` — selected generated mixed dynamic/static read burst-last `RID && RLAST` same-ID issue-order queue readiness after the mixed read single-beat `RID` queue shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated mixed dynamic/static read burst-last `RID && RLAST` same-ID issue-order queue readiness and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — documents generated mixed dynamic/static read burst-last `RID && RLAST` same-ID issue-order queue behavior for one dynamic plus one concrete static transaction.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_PUBLIC_SURFACE_SYNC.md` — synchronized the public `.ppif` boundary after generated mixed dynamic/static same-ID issue-order queue behavior shipped.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_PUBLIC_SURFACE_SYNC_NEXT_SLICE_SELECTION.md` — selected mixed dynamic/static issue-order queue scalar read-data readiness after public-surface synchronization.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md` — audited scalar read-data readiness over generated mixed dynamic/static read same-ID issue-order queue completions and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md` — documents paired scalar read-data over generated mixed dynamic/static read same-ID issue-order queue completions.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only raw-`ARLEN` burst-length readiness over generated mixed dynamic/static read burst-last same-ID issue-order queue read-data and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md` — documents report-only raw-`ARLEN` burst-length capture over generated mixed dynamic/static read burst-last same-ID issue-order queue read-data.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audits runtime beat-count/`RLAST` validation readiness over generated mixed dynamic/static read burst-last same-ID issue-order queue raw-`ARLEN` read-data and selects direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md` — documents runtime beat-count/`RLAST` validation over generated mixed dynamic/static read burst-last same-ID issue-order queue raw-`ARLEN` read-data.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md` — audits multi-beat output-bank readiness over generated mixed dynamic/static read burst-last same-ID issue-order queue runtime-validation read-data and selects direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md` — documents shipped multi-beat output banks over generated mixed dynamic/static read burst-last same-ID issue-order queue runtime-validation read-data.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_MULTI_STATIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited one-dynamic plus two-concrete-static mixed dynamic/static write `BID` same-ID issue-order queue readiness and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_MULTI_STATIC_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — documents generated mixed dynamic/static write `BID` same-ID issue-order queue behavior for one dynamic plus two concrete static transactions.
- `docs/IAL2_PROTOCOL_GENERALITY_GUARDRAIL_READINESS_SELECTION.md` — selected an IAL2 protocol/platform generality guardrail audit after the deep AXI first-example chain, preserving AXI as a profile/example rather than the whole IAL2 language.
- `docs/IAL2_PROTOCOL_GENERALITY_GUARDRAIL_READINESS_AUDIT.md` — audited the IAL2 protocol/platform generality guardrail and selected public-surface cleanup so downstream/public `.ppif` summaries lead with AXI as the first shipped IAL2 profile/example, not the IAL2 definition.
- `docs/IAL2_PROTOCOL_GENERALITY_GUARDRAIL_PUBLIC_SURFACE_SYNC.md` — synchronized the public `.ppif` contract, downstream handoff, and capability-manifest language-surface boundary with the IAL2 protocol/platform generality guardrail.
- `docs/IAL2_POST_GUARDRAIL_NEXT_SLICE_SELECTION.md` — selected a readiness audit for a protocol-neutral/non-AXI Valid-Ready `.ppif` example boundary as the next IAL2 generality exercise.
- `docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_READINESS_AUDIT.md` — audited protocol-neutral/non-AXI Valid-Ready `.ppif` readiness and selected public profile/source vocabulary contract selection before any non-AXI sample or behavior change.
- `docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_CONTRACT_SELECTION.md` — selected `(profile valid-ready)`, `ppif/valid_ready_handshake.ppif`, and `intent.ppif_valid_ready_handshake` for the first protocol-neutral/non-AXI Valid-Ready `.ppif` implementation slice.
- `docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_BEHAVIOR.md` — documents the shipped protocol-neutral `(profile valid-ready)` `.ppif` sample, report fields, support accounting, and deferred boundaries.
- `docs/IAL2_POST_NEUTRAL_VALID_READY_PPIF_NEXT_SLICE_SELECTION.md` — selected protocol-neutral/non-AXI Valid-Ready `.ppif` bundle readiness as the next IAL2 generality owner after the first neutral sample shipped.
- `docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_READINESS_AUDIT.md` — audited protocol-neutral/non-AXI Valid-Ready bundle readiness and selected public contract selection before neutral bundle behavior changes.
- `docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_CONTRACT_SELECTION.md` — selected `ppif/valid_ready_dual_channel_bundle.ppif`, `intent.ppif_valid_ready_dual_channel_bundle`, and the generic aggregate residue contract for the first protocol-neutral/non-AXI Valid-Ready bundle implementation.
- `docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_BEHAVIOR.md` — documents the shipped protocol-neutral/non-AXI dual-channel Valid-Ready `.ppif` bundle, support accounting, generated artifacts, generic aggregate residue, and preserved AXI AW/W residue boundary.
- `docs/IAL2_POST_NEUTRAL_VALID_READY_BUNDLE_NEXT_SLICE_SELECTION.md` — selected profile-alias readiness as the next IAL2 owner after the neutral Valid-Ready bundle shipped.
- `docs/IAL2_PROFILE_ALIAS_SUFFIX_READINESS_AUDIT.md` — audited future IAL2 profile-alias suffix readiness and selected public unsupported-alias inventory synchronization before any suffix behavior change.
- `docs/IAL2_PROFILE_ALIAS_UNSUPPORTED_INVENTORY_SYNC.md` — synchronizes the public unsupported-alias inventory for future IAL2 profile-alias suffixes and selects first-alias contract selection.
- `docs/IAL2_FIRST_PROFILE_ALIAS_CONTRACT_SELECTION.md` — selects `.axi` as the first IAL2 profile-alias contract while keeping AXI as an example over IAL2, not the IAL2 definition.
- `docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md` — documents the shipped `.axi` IAL2 profile-alias behavior, explicit AXI-family profile matching, generated `.isf`/`.fsm` review artifacts, support accounting, and remaining unsupported aliases.
- `docs/IAL2_POST_AXI_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md` — selects the post-`.axi` IAL2 generality readiness audit and records the Knowledge Map routing correction for historical pre-implementation alias facts.
- `docs/IAL2_POST_AXI_GENERALITY_READINESS_AUDIT.md` — audits post-`.axi` generality readiness and selects public historical wording sync before another behavior owner.
- `docs/IAL2_PROFILE_ALIAS_PUBLIC_CHRONOLOGY_SYNC.md` — synchronizes README, ROADMAP_V2, and mdBook wording so `.537`/`.538` profile-alias notes are explicitly historical pre-`.540` state while `.axi` remains only the first shipped IAL2 profile-alias example.
- `docs/IAL2_NON_AXI_PROFILE_ALIAS_READINESS_SELECTION.md` — selects the non-AXI profile-alias readiness audit after the public chronology sync, explicitly avoiding another AXI implementation.
- `docs/IAL2_NON_AXI_PROFILE_ALIAS_READINESS_AUDIT.md` — audits non-AXI profile-alias readiness and selects a taxonomy/evidence prerequisite before any non-AXI suffix contract.
- `docs/IAL2_NON_AXI_PROFILE_ALIAS_TAXONOMY_EVIDENCE_PREREQUISITE.md` — separates `.pif`/`.ppi` generic-container candidates from non-AXI protocol-profile alias candidates and selects a generic-container alias policy owner.
- `docs/IAL2_PIF_PPI_GENERIC_CONTAINER_ALIAS_POLICY_SELECTION.md` — keeps `.pif`/`.ppi` unsupported historical generic-container spellings and selects an APB IAL2 source-shape readiness audit.
- `docs/IAL2_APB_SOURCE_SHAPE_READINESS_AUDIT.md` — audits APB lower-layer evidence and selects APB `.ppif` source-shape public contract selection before any APB behavior or `.apb` suffix support.
- `docs/IAL2_APB_PPIF_SOURCE_SHAPE_CONTRACT_SELECTION.md` — selects `(profile apb)`, the first `(apb-requester ...)` source shape, `ppif/apb_requester_transfer.ppif`, `intent.ppif_apb_requester_transfer`, and direct implementation as the next exact owner.
- `docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md` — ships the first APB `.ppif` requester-transfer behavior with `ppif/apb_requester_transfer.ppif`, generated `apb_requester.isf`/`apb_requester.fsm`, and report schema `fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`; the later `.apb` alias is documented separately.
- `docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md` — ships the first APB `.ppif` completer behavior with `ppif/apb_completer.ppif`, generated `apb_completer.isf`/`apb_completer.fsm`, report schema `fsmgen.ial2.protocol_intent.apb_completer.v1`, address-0 register read/write, runtime `wait_cycles`, unmapped-address `PSLVERR`, and later `.apb` alias exposure through `ppif/apb_completer.apb`.
- `docs/IAL2_POST_APB_REQUESTER_TRANSFER_NEXT_SLICE_SELECTION.md` — selects APB `.apb` profile-alias readiness audit after APB `.ppif` requester-transfer behavior, without accepting `.apb` or changing behavior.
- `docs/IAL2_APB_PROFILE_ALIAS_READINESS_AUDIT.md` — audits APB `.apb` profile-alias readiness and selects public `.apb` contract selection while keeping `.apb` unsupported at `.552` closeout.
- `docs/IAL2_APB_PROFILE_ALIAS_CONTRACT_SELECTION.md` — selects direct bounded implementation of the first APB `.apb` profile alias at `ppif/apb_requester_transfer.apb`, with explicit `(profile apb)` and generated `.isf` review preservation.
- `docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md` — ships `.apb` as the bounded APB requester-transfer, APB completer, and fixed APB requester/completer composition IAL2 profile alias with explicit `(profile apb)`, generated `.isf`/`.fsm` review artifacts, and support identities `intent.apb_profile_alias_requester_transfer`, `intent.apb_profile_alias_completer`, and `intent.apb_profile_alias_composition`.
- `docs/IAL2_POST_APB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md` — selects a no-behavior public-surface sync after APB `.apb` shipped so current `.axi`/`.apb` alias wording and Knowledge Map routing stay aligned.
- `docs/IAL2_POST_APB_PROFILE_ALIAS_PUBLIC_SURFACE_SYNC.md` — synchronizes current `.axi`/`.apb` profile-alias public surfaces so `.apb` is no longer listed as unsupported after `.554`.
- `docs/IAL2_POST_APB_SURFACE_SYNC_NEXT_SLICE_SELECTION.md` — selects APB completer/interconnect generation readiness audit after the post-APB public-surface sync.
- `docs/IAL2_APB_COMPLETER_INTERCONNECT_READINESS_AUDIT.md` — audits APB completer/interconnect generation readiness and selects public contract selection before any APB completer/interconnect behavior.
- `docs/IAL2_APB_COMPLETER_INTERCONNECT_CONTRACT_SELECTION.md` — selects a split APB completer-first `.ppif` contract and routes the next slice to generated-IAL1 substrate audit before implementation.
- `docs/IAL2_APB_COMPLETER_GENERATED_IAL1_SUBSTRATE_AUDIT.md` — audits generated-IAL1 substrate readiness for APB completer and selects expression entry-guard rendering repair before APB completer behavior.
- `docs/IAL1_EXPRESSION_ENTRY_GUARD_RENDERING_BEHAVIOR.md` — ships the IAL1 expression entry-guard rendering repair so first-clause `(when EXPR (sample ...))` generated `.fsm` sample enables and entry transitions use rendered expression guard text instead of `ARRAY(...)`.
- `docs/IAL2_POST_APB_COMPLETER_NEXT_SLICE_SELECTION.md` — selects APB interconnect/composition readiness audit after generated APB requester and completer `.ppif` endpoints both exist; later slices ship fixed composition and `.apb` completer/composition alias exposure.
- `docs/IAL2_APB_INTERCONNECT_COMPOSITION_READINESS_AUDIT.md` — audits APB interconnect/composition readiness after generated APB requester/completer endpoints and selects public contract selection before any generated composition behavior.
- `docs/IAL2_APB_INTERCONNECT_COMPOSITION_CONTRACT_SELECTION.md` — selects the explicit APB `.ppif` requester/completer composition contract and routes the next slice to direct bounded implementation.
- `docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md` — ships the first fixed one-requester/one-completer APB `.ppif` composition behavior with `ppif/apb_composition.ppif`, generated endpoint `.isf`/`.fsm` review artifacts, selected `apb_tb.fsm` HDL entry, report schema `fsmgen.ial2.protocol_intent.apb_composition.v1`, support identity `intent.ppif_apb_composition`, and later `.apb` alias exposure through `ppif/apb_composition.apb`.
- `docs/IAL2_POST_APB_COMPOSITION_NEXT_SLICE_SELECTION.md` — selects APB `.apb` profile-alias public contract selection for the shipped APB completer and fixed APB composition `.ppif` shapes, without changing behavior.
- `docs/IAL2_APB_PROFILE_ALIAS_COMPLETER_COMPOSITION_CONTRACT_SELECTION.md` — selects direct bounded implementation of APB `.apb` alias widening for `ppif/apb_completer.apb` and `ppif/apb_composition.apb`, with explicit `(profile apb)`, generated review-artifact preservation, support identities `intent.apb_profile_alias_completer` and `intent.apb_profile_alias_composition`, and no behavior change in the selector slice.
- `docs/IAL2_POST_APB_ALIAS_WIDENING_NEXT_SLICE_SELECTION.md` — selects APB requester busy/status public contract selection after requester-transfer, completer, fixed composition, and bounded `.apb` alias coverage all shipped, without changing behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION.md` — selected direct single-active dynamic write `BID` same-cycle release-and-recapture behavior under the existing dynamic write response-demux public sample.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR.md` — shipped single-active dynamic write `BID` same-cycle release-and-recapture under the existing dynamic write response-demux public sample.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected `.367`, public contract selection for first single-active dynamic read same-cycle release-and-recapture after dynamic write recapture shipped.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION.md` — selected direct single-active dynamic read single-beat `RID` same-cycle release-and-recapture behavior under the existing dynamic read response-demux public sample.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_BEHAVIOR.md` — shipped single-active dynamic read single-beat `RID` same-cycle release-and-recapture under the existing dynamic read response-demux public sample.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for single-active dynamic read burst-last `RID && RLAST` same-cycle release-and-recapture after single-beat read recapture shipped.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md` — audited single-active dynamic read burst-last `RID && RLAST` same-cycle release-and-recapture readiness and selected public contract selection before behavior changes.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md` — selected direct single-active dynamic read burst-last `RID && RLAST` same-cycle release-and-recapture behavior under the existing burst-last dynamic read response-demux public sample.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md` — shipped single-active dynamic read burst-last `RID && RLAST` same-cycle release-and-recapture under the existing burst-last dynamic read response-demux public sample.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for multiple all-dynamic same-cycle release-and-recapture after single-active dynamic read burst-last recapture shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_READINESS_AUDIT.md` — audited multiple all-dynamic same-cycle release-and-recapture readiness and selected generated support-detail prose alignment before broader recapture selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_CONTRACT_OWNER_SELECTION.md` — selected multiple all-dynamic write `BID` recapture as the first broader same-cycle recapture owner.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md` — selected direct multiple all-dynamic write `BID` same-cycle release-and-recapture under the existing multiple dynamic write response-demux public sample.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_BEHAVIOR.md` — shipped multiple all-dynamic write `BID` same-cycle release-and-recapture under the existing multiple dynamic write response-demux public sample.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected multiple all-dynamic read single-beat `RID` recapture contract selection after multiple dynamic write recapture shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_CONTRACT_SELECTION.md` — selected direct multiple all-dynamic read single-beat `RID` same-cycle release-and-recapture under the existing multiple dynamic read response-demux public sample.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_BEHAVIOR.md` — shipped multiple all-dynamic read single-beat `RID` same-cycle release-and-recapture under the existing multiple dynamic read response-demux public sample.
- `docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md` — selected first AXI-derived IAL2 implementation subset and pre-code contract.
- `docs/AXI_IAL2_VALID_READY_READINESS_AUDIT.md` — code/test/docs/report owner map for a future AXI Valid-Ready IAL2 implementation slice.
- `docs/AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md` — first in-process AXI Valid-Ready IAL2 generator slice and report surface.
- `docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md` — first public `.ppif` parser/CLI slice for one AXI Valid-Ready source object.
- `docs/IAL2_PPIF_MULTI_VALID_READY_READINESS.md` — readiness map for future multi-channel `.ppif` Valid-Ready support.
- `docs/IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md` — selected future aggregate bundle contract for multi-channel `.ppif` Valid-Ready support.
- `docs/IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md` — shipped bounded multi-channel `.ppif` Valid-Ready bundle report/review-artifact behavior.
- `docs/IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md` — shipped aggregate semantic JSON for multi-channel `.ppif` bundles.
- `docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION.md` — selected aggregate wrapper/top HDL entry contract for multi-channel `.ppif` bundles.
- `docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md` — shipped aggregate wrapper/top HDL entry for the tracked multi-channel `.ppif` bundle.
- `ppif/axi_aw_valid_ready.ppif` — first checked-in runnable `.ppif` sample for the public IAL2 Valid-Ready CLI surface.
- `ppif/valid_ready_handshake.ppif` — checked-in runnable protocol-neutral/non-AXI `(profile valid-ready)` `.ppif` sample for the bounded Valid-Ready monitor path.
- `ppif/axi_aw_w_valid_ready_bundle.ppif` — checked-in runnable multi-channel `.ppif` bundle sample for aggregate report/review-artifact modes.
- `ppif/valid_ready_dual_channel_bundle.ppif` — checked-in runnable protocol-neutral/non-AXI dual-channel `(profile valid-ready)` `.ppif` bundle sample for aggregate report/review-artifact and wrapper/top HDL modes.
- `ppif/axi_manager_capacity_status_id_family.ppif` — checked-in runnable `.ppif` sample for static AXI manager ID-family metadata.
- `ppif/axi_manager_capacity_status_transaction_envelope.ppif` — checked-in runnable `.ppif` sample for AXI manager transaction-envelope metadata and concrete direction-level ID assertions.
- `ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif` — checked-in runnable `.ppif` sample for AXI manager transaction event dispatch/fan-in and concrete per-transaction ID assertions.
- `ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated read burst-last depth-2 concrete same-ID queue state plus queue-head response demux.
- `ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated multiple read burst-last depth-2 concrete same-ID queue-head response-demux groups.
- `ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif` — checked-in runnable `.ppif` sample for generated multi-group queue-head multi-beat read-data output-bank behavior.
- `ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated write-family multi-group queue-head response-demux behavior.
- `ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated read single-beat depth-2 concrete same-ID queue state plus queue-head `RID` response demux without `RLAST`.
- `ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated read single-beat multi-group queue-head `RID` response demux without `RLAST` or `read_data`, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif` — checked-in runnable `.ppif` sample for generated single-beat `RDATA`/`RRESP` capture from generated read single-beat concrete same-ID queue-head response demux.
- `ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif` — checked-in runnable `.ppif` sample for generated single-beat scalar `RDATA`/`RRESP` capture over the selected read single-beat depth-3 queue-head group, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_read_data.ppif` — checked-in runnable `.ppif` sample for generated single-beat scalar `RDATA`/`RRESP` capture over two depth-3 concrete same-ID queue-head groups, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data.ppif` — checked-in runnable `.ppif` sample for generated single-beat scalar `RDATA`/`RRESP` capture over mixed depth-3/depth-2 concrete same-ID queue-head groups, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated read burst-last depth-3 concrete same-ID queue-head response-demux, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif` — checked-in runnable `.ppif` sample for generated scalar last-beat `RDATA`/`RRESP` capture over the selected read burst-last depth-3 queue-head group, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif` — checked-in runnable `.ppif` sample for generated report-only raw-`ARLEN` burst-length capture over the selected read burst-last depth-3 queue-head read-data group, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif` — checked-in runnable `.ppif` sample for generated runtime beat-count/`RLAST` validation over the selected read burst-last depth-3 queue-head raw-`ARLEN` burst-length group, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif` — checked-in runnable `.ppif` sample for generated single-beat scalar `RDATA`/`RRESP` capture over multiple read single-beat queue-head groups, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated write depth-2 concrete same-ID queue state plus queue-head `BID` response demux.
- `ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated write depth-3 concrete same-ID queue state plus queue-head `BID` response demux, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated read single-beat two-depth-3 concrete same-ID queue-head `RID` response demux, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated read single-beat mixed depth-3/depth-2 concrete same-ID queue-head `RID` response demux, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated read burst-last two-depth-3 concrete same-ID queue-head `RID`/`RLAST` response demux, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated read burst-last mixed depth-3/depth-2 concrete same-ID queue-head `RID`/`RLAST` response demux, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data.ppif` — checked-in runnable `.ppif` sample for generated read burst-last scalar last-beat `RDATA`/`RRESP` capture over two depth-3 concrete same-ID queue-head groups, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data.ppif` — checked-in runnable `.ppif` sample for generated read burst-last scalar last-beat `RDATA`/`RRESP` capture over mixed depth-3/depth-2 concrete same-ID queue-head groups, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length.ppif` — checked-in runnable `.ppif` sample for generated report-only raw-`ARLEN` burst-length capture over two depth-3 read burst-last queue-head scalar last-beat read-data groups, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length.ppif` — checked-in runnable `.ppif` sample for generated report-only raw-`ARLEN` burst-length capture over mixed depth-3/depth-2 read burst-last queue-head scalar last-beat read-data groups, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif` — checked-in runnable `.ppif` sample for generated runtime beat-count/`RLAST` validation over two depth-3 read burst-last queue-head scalar last-beat read-data groups, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion.ppif` — checked-in runnable `.ppif` sample for generated runtime beat-count/`RLAST` validation over mixed depth-3/depth-2 read burst-last queue-head scalar last-beat read-data groups, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data.ppif` — checked-in runnable `.ppif` sample for generated mixed auto-ID plus depth-2 concrete same-ID queue-head multi-beat output-bank behavior over the selected runtime-validation read burst-last shape, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_write_multi_depth3_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated write two-depth-3 concrete same-ID queue-head `BID` response demux, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_write_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated write mixed depth-3/depth-2 concrete same-ID queue-head `BID` response demux, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif` — checked-in runnable `.ppif` sample for metadata-first dynamic transaction-ID parser/report support with `(id dynamic)`, support-accounted through check JSON and semantic JSON while HDL dynamic matching remains deferred.
- `ppif/axi_manager_capacity_status_dynamic_same_id_reject_policy.ppif` — checked-in runnable `.ppif` sample for metadata-first dynamic same-ID reject policy parser/report support with `(dynamic-id-reuse reject)`, support-accounted while generated enforcement remains deferred.
- `ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif` — checked-in runnable `.ppif` sample for generated single-active dynamic write transaction-ID capture, `BID` response matching, and same-cycle release-and-recapture through explicit `response-demux.write`, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif` — checked-in runnable `.ppif` sample for generated bounded multiple dynamic write transaction-ID capture, `BID` response matching, and same-cycle release-and-recapture through explicit `response-demux.write` with all-dynamic write transactions, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif` — checked-in runnable `.ppif` sample for generated bounded mixed dynamic/static write `BID` response matching through explicit `response-demux.write` with one dynamic and one concrete static write transaction, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif` — checked-in runnable `.ppif` sample for generated bounded multiple mixed dynamic/static write `BID` response matching through explicit `response-demux.write` with one dynamic and two concrete static write transactions, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif` — checked-in runnable `.ppif` sample for generated bounded broader mixed dynamic/static write `BID` response matching through explicit `response-demux.write` with one dynamic and three concrete static write transactions, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif` — checked-in runnable `.ppif` sample for generated bounded multiple mixed dynamic/static read single-beat `RID` response matching through explicit `response-demux.read` with one dynamic and two concrete static read transactions, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif` — checked-in runnable `.ppif` sample for generated bounded broader mixed dynamic/static read single-beat `RID` response matching through explicit `response-demux.read` with one dynamic and three concrete static read transactions, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif` — checked-in runnable `.ppif` sample for generated bounded two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` response matching through explicit `response-demux.read`, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif` — checked-in runnable `.ppif` sample for generated scalar single-beat `RDATA`/`RRESP` capture over generated two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` response-demux, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length.ppif` — checked-in runnable `.ppif` sample for generated report-only raw-`ARLEN` burst-length capture over generated two-dynamic-plus-one-static mixed dynamic/static read burst-last/`RLAST` response-demux and scalar last-beat read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion.ppif` — checked-in runnable `.ppif` sample for generated runtime beat-count/`RLAST` validation over generated two-dynamic-plus-one-static mixed dynamic/static read burst-last/`RLAST` response-demux and scalar last-beat read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat.ppif` — checked-in runnable `.ppif` sample for generated multi-beat output banks over generated two-dynamic-plus-one-static mixed dynamic/static read burst-last/`RLAST` response-demux and runtime beat-count/`RLAST` validation, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length.ppif` — checked-in runnable `.ppif` sample for generated report-only raw-`ARLEN` burst-length capture over generated one dynamic plus three concrete static mixed dynamic/static read burst-last/`RLAST` response-demux and scalar last-beat read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_runtime_assertion.ppif` — checked-in runnable `.ppif` sample for generated runtime beat-count/`RLAST` validation over generated one dynamic plus three concrete static mixed dynamic/static read burst-last/`RLAST` response-demux and scalar last-beat read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat.ppif` — checked-in runnable `.ppif` sample for generated multi-beat output banks over generated one dynamic plus three concrete static mixed dynamic/static read burst-last/`RLAST` response-demux and runtime beat-count/`RLAST` validation, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif` — checked-in runnable `.ppif` sample for generated bounded multiple mixed dynamic/static read burst-last `RID && RLAST` response matching and same-cycle release-and-recapture through explicit `response-demux.read` with one dynamic and two concrete static read transactions, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif` — checked-in runnable `.ppif` sample for generated scalar single-beat `RDATA`/`RRESP` capture over generated mixed dynamic/static read single-beat response-demux, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif` — checked-in runnable `.ppif` sample for generated scalar last-beat `RDATA`/`RRESP` capture over generated mixed dynamic/static read burst-last/`RLAST` response-demux, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length.ppif` — checked-in runnable `.ppif` sample for generated report-only raw-`ARLEN` burst-length capture over generated mixed dynamic/static read burst-last/`RLAST` response-demux and scalar last-beat read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion.ppif` — checked-in runnable `.ppif` sample for generated runtime beat-count/`RLAST` validation over generated mixed dynamic/static read burst-last/`RLAST` response-demux and scalar last-beat read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif` — checked-in runnable `.ppif` sample for generated mixed dynamic/static multi-beat read-data output banks over generated mixed dynamic/static read burst-last/`RLAST` response-demux and runtime beat-count/`RLAST` validation.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length.ppif` — checked-in runnable `.ppif` sample for generated report-only raw-`ARLEN` burst-length capture over generated multiple mixed dynamic/static read burst-last/`RLAST` response-demux and scalar last-beat read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_runtime_assertion.ppif` — checked-in runnable `.ppif` sample for generated runtime beat-count/`RLAST` validation over generated multiple mixed dynamic/static read burst-last/`RLAST` response-demux and scalar last-beat read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif` — checked-in runnable `.ppif` sample for generated single-active dynamic read transaction-ID capture, single-beat `RID` response matching, and same-cycle release-and-recapture through explicit `response-demux.read`, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif` — checked-in runnable `.ppif` sample for generated bounded multiple dynamic read transaction-ID capture, single-beat `RID` response matching, and same-cycle release-and-recapture through explicit `response-demux.read` with all-dynamic read transactions, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_same_id_reject.ppif` — checked-in runnable `.ppif` sample for generated dynamic same-ID reject enforcement mapping over multiple all-dynamic read single-beat response-demux assertions, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_response_demux_same_id_reject.ppif` — checked-in runnable `.ppif` sample for generated single-active dynamic same-ID reject enforcement mapping over read single-beat `RID` response-demux idle-or-releasing assertions, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue.ppif` — checked-in runnable `.ppif` sample for generated bounded two-transaction all-dynamic write `BID` dynamic same-ID issue-order queue behavior, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue.ppif` — checked-in runnable `.ppif` sample for generated bounded one-dynamic plus one-concrete-static mixed dynamic/static write `BID` same-ID issue-order queue behavior, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static.ppif` — checked-in runnable `.ppif` sample for generated bounded one-dynamic plus two-concrete-static mixed dynamic/static write `BID` same-ID issue-order queue behavior, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue.ppif` — checked-in runnable `.ppif` sample for generated bounded one-dynamic plus one-concrete-static mixed dynamic/static read single-beat `RID` same-ID issue-order queue behavior, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue.ppif` — checked-in runnable `.ppif` sample for generated bounded one-dynamic plus one-concrete-static mixed dynamic/static read burst-last `RID && RLAST` same-ID issue-order queue behavior, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue_read_data.ppif` — checked-in runnable `.ppif` sample for scalar single-beat `RDATA`/`RRESP` capture over generated bounded one-dynamic plus one-concrete-static mixed dynamic/static read single-beat same-ID issue-order queue completions, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data.ppif` — checked-in runnable `.ppif` sample for scalar last-beat `RDATA`/`RRESP` capture over generated bounded one-dynamic plus one-concrete-static mixed dynamic/static read burst-last same-ID issue-order queue completions, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif` — checked-in runnable `.ppif` sample for report-only raw-`ARLEN` burst-length capture over generated bounded one-dynamic plus one-concrete-static mixed dynamic/static read burst-last same-ID issue-order queue read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif` — checked-in runnable `.ppif` sample for runtime beat-count/`RLAST` validation over generated bounded one-dynamic plus one-concrete-static mixed dynamic/static read burst-last same-ID issue-order queue raw-`ARLEN` read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif` — checked-in runnable `.ppif` sample for generated multi-beat read-data output banks over generated bounded one-dynamic plus one-concrete-static mixed dynamic/static read burst-last same-ID issue-order queue runtime-validation read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue.ppif` — checked-in runnable `.ppif` sample for generated bounded three-transaction all-dynamic write `BID` dynamic same-ID issue-order queue behavior, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue.ppif` — checked-in runnable `.ppif` sample for generated bounded two-transaction all-dynamic read single-beat `RID` dynamic same-ID issue-order queue behavior, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_depth3_same_id_issue_order_queue.ppif` — checked-in runnable `.ppif` sample for generated bounded three-transaction all-dynamic read single-beat `RID` dynamic same-ID issue-order queue behavior, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue.ppif` — checked-in runnable `.ppif` sample for generated bounded two-transaction all-dynamic read burst-last `RID && RLAST` dynamic same-ID issue-order queue behavior, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue.ppif` — checked-in runnable `.ppif` sample for generated bounded three-transaction all-dynamic read burst-last `RID && RLAST` dynamic same-ID issue-order queue behavior, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data.ppif` — checked-in runnable `.ppif` sample for scalar last-beat `RDATA`/`RRESP` capture over generated bounded three-transaction all-dynamic read burst-last `RID && RLAST` dynamic same-ID issue-order queue behavior, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length.ppif` — checked-in runnable `.ppif` sample for report-only raw-`ARLEN` burst-length capture over generated bounded three-transaction all-dynamic read burst-last `RID && RLAST` dynamic same-ID issue-order queue read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif` — checked-in runnable `.ppif` sample for runtime beat-count/`RLAST` validation over generated bounded three-transaction all-dynamic read burst-last `RID && RLAST` dynamic same-ID issue-order queue raw-`ARLEN` read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif` — checked-in runnable `.ppif` sample for generated scalar single-beat `RDATA`/`RRESP` capture over generated multiple dynamic read single-beat response-demux, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif` — checked-in runnable `.ppif` sample for generated scalar last-beat `RDATA`/`RRESP` capture over generated multiple dynamic read burst-last/`RLAST` response-demux, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif` — checked-in runnable `.ppif` sample for generated report-only raw-`ARLEN` burst-length capture over generated multiple dynamic read burst-last/`RLAST` response-demux and scalar last-beat read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif` — checked-in runnable `.ppif` sample for generated runtime beat-count/`RLAST` validation over generated multiple dynamic read burst-last/`RLAST` response-demux and scalar last-beat read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif` — checked-in runnable `.ppif` sample for generated bounded multiple dynamic multi-beat read-data output banks over generated multiple dynamic read burst-last/`RLAST` response-demux and runtime validation, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif` — checked-in runnable `.ppif` sample for generated multi-beat read-data output banks over generated dynamic read burst-last same-ID issue-order queue runtime-validation read-data, support-accounted through check JSON and semantic JSON.
- `ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif` — checked-in runnable `.ppif` sample for AXI manager auto-ID lifecycle bounded-pool request-ID drive behavior.
- `ppif/axi_manager_capacity_status_read_response_demux.ppif` — checked-in runnable `.ppif` sample for AXI manager read response-demux generated single-beat `RID` behavior.
- `ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif` — checked-in runnable `.ppif` sample for generated AXI manager burst-last `RLAST` response-demux completion behavior.
- `ppif/axi_manager_capacity_status_read_data_last_beat.ppif` — checked-in runnable `.ppif` sample for structural AXI manager last-beat `RDATA`/`RRESP` metadata paired with generated burst-last response-demux completion.
- `ppif/axi_manager_capacity_status_read_data_multi_beat.ppif` — checked-in runnable `.ppif` sample for public multi-beat read-data output-bank behavior with generated per-beat data/status lanes, valid mask, length outputs, and generated scalar `RRESP` aggregation behavior.
- `docs/PDF_EXTRACTION_WORKFLOW.md` — portable workflow for task-owned source-anchored PDF text, table, diagram, and image extraction.
- `docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md` — generic IAL2 file-surface candidates and layered lowering decision.
- `docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md` — IAL2 protocol-profile extension refinement.
- `docs/decisions/0016-ppif-is-first-public-ial2-container.md` — selects `.ppif` as the first public generic IAL2 file surface.
- `docs/decisions/0017-ppif-valid-ready-bundle-contract.md` — future multi-channel `.ppif` bundle contract decision.
- `docs/decisions/0018-ial-contracts-are-backend-language-neutral.md` — IAL contracts and mdBook stay backend-language-neutral for future Rust, Rust/Wasm, browser-capable JavaScript, and Dart/web parity.
- `docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf` — tracked repo-local raw AXI protocol specification reference for future task-tree-owned IAL2 probes.
- `docs/vendor/accellera/systemrdl/SystemRDL_2.0_Jan2018.pdf` — tracked repo-local raw Accellera SystemRDL 2.0 reference for future task-tree-owned register/interface intent probes.
- `docs/vendor/accellera/pss/Portable_Test_Stimulus_Standard_v3.0.pdf` — tracked repo-local raw Accellera Portable Test and Stimulus 3.0 reference for future task-tree-owned portable scenario/test intent probes.
- `docs/vendor/accellera/uvm/UVM_Class_Reference_Manual_1.2.pdf` — tracked repo-local raw Accellera UVM 1.2 class reference for future task-tree-owned verification-integration probes.
- `docs/vendor/accellera/uvm/uvm_users_guide_1.2.pdf` — tracked repo-local raw Accellera UVM 1.2 user guide for future task-tree-owned verification-integration probes.
- `docs/FEATURE_BACKLOG.md` — repo-level pointer to the canonical mdBook backlog for deferred/not-fully-shipped user-visible features.
- `docs/VHDL_SCOPE.md` — scoped VHDL backend plan and shipped direct-root scaffold boundary.
- `CHANGES.md` — persistent technical change history.
- `DEVELOPMENT_NOTES.md` — architecture notes and engineering rationale.
- `MEMORY.md` — live continuity context and recovery notes.
- `LIVE_ACHIEVEMENT_STATUS.md` — latest completed roadmap-aligned slice for fast recovery.
- `COMMIT.md` — canonical commit workflow specification.
- `WARP.md` — project guidance for Warp/agent workflows.
- `.agents/workflows/commit.md` — agent workflow definition for commit operations.
- `.github/workflows/README.md` — active hosted CI and GitHub Pages workflow overview.

## Project file and directory map
### Core entrypoints and pipeline
- `bin/fsmgen` — main CLI entrypoint.
- `bin/fsmgen-mcp` — read-only local JSON-RPC stdio adapter over the
  `semantic_introspection` manifest contract.
- `bin/fsmgen-issue-bundle` — downstream issue-bundle helper that captures
  reproducible FSMGen command artifacts for local triage.
- `perl/FSM/Adapter/ISF.pm` — `.isf` parser facade for intent-scheduling sources.
- `perl/FSM/Scheduler/ISF.pm` — `.isf` lowering facade that emits scheduled `.fsm` and schedule JSON reports.
- `perl/FSM/Scheduler/ISF/LoweringIR.pm` — typed lowering IR builder for `.isf` actors, transactions, drives, control flow, and spawned children.
- `perl/FSM/Scheduler/ISF/ATLGeneratedTop.pm` — private ATL generated-top helper for schedule-report projection and data-link child-interface marking.
- `perl/FSM/Scheduler/ISF/Emitter/FSM.pm` — scheduled `.fsm` emitter for `.isf` lowering results.
- `perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm` — generated `?top` emitter for ISF spawned-child parent/child handoff.
- `perl/FSM/Scheduler/ISF/Emitter/JSON.pm` — machine-readable schedule-report emitter for `.isf` lowering results.
- `perl/FSM/VerificationOutput/UVM/PassiveMonitorSkeleton.pm` — explicit verification-output builder for the inert UVM passive-monitor skeleton package and artifact manifest.
- `perl/FSM/VerificationOutput/VHDL/ObservationPackageSkeleton.pm` — explicit verification-output builder for the inert VHDL observation metadata package and artifact manifest.
- `perl/FSM/Pipeline/HDLGenerator.pm` — thin public generation facade around source/direct/composition orchestrators; accepts supported `.fsm`, `.isf`, and `.ppif` source roots.
- `perl/FSM/Composition/Net.pm` — typed internal net plan for multi-child composition wiring.
- `perl/FSM/Composition/Parser.pm` — first typed composition parser/IR boundary.
- `perl/FSM/Composition/Plan.pm` — typed realized top-planning object for active composition work.
- `perl/FSM/Composition/RTLInterfaceLoader.pm` — sidecar external-RTL interface loader for the shipped `C3` composition lane.
- `perl/FSM/Extension/Loader.pm` — explicit typed extension-module loader for the active `R7` replacement seam.
- `perl/FSM/Extension/Registry.pm` — typed extension registry for the active `R7` replacement seam.
- `perl/FSM/Extension/Context.pm` — typed hook context object passed to active extensions.
- `perl/FSM/Support/CapabilityManifest.pm` — machine-readable capability manifest builder for downstream tool integration.
- `perl/FSM/Support/CapabilityManifestContract.pm` — bounded top-level capability-manifest shell contract advertised through the manifest itself.
- `perl/FSM/Support/DiagnosticsContract.pm` — bounded manifest-facing contract for the `diagnostics` section's public top-level and stable-code entry families.
- `perl/FSM/Support/EmbeddingContract.pm` — bounded manifest-facing contract for the `embedding` section's public top-level and nested contract-owner map.
- `perl/FSM/Support/BackendValidationContract.pm` — bounded manifest-facing contract for the `backend_validation` section's public top-level and nested contract-owner map.
- `perl/FSM/Support/DocumentationContract.pm` — bounded manifest-facing contract for the `documentation` section's public path-list keys.
- `perl/FSM/Support/LanguageSurfaceContract.pm` — bounded manifest-facing contract for the `language_surface` section's public top-level, first nested key lists, file-surface discovery keys, and per-suffix supported CLI-mode metadata.
- `perl/FSM/Support/VerificationOutputsContract.pm` — bounded manifest-facing contract for generated verification-output target discovery and artifact-manifest key families.
- `perl/FSM/Support/VerificationOutputsSection.pm` — capability-manifest `verification_outputs` section builder for the shipped UVM passive-monitor skeleton and VHDL observation package targets.
- `perl/FSM/Support/ProducerContract.pm` — bounded manifest-facing contract for the `producer` section's public identity/build metadata keys.
- `perl/FSM/Support/SemanticExportsContract.pm` — bounded manifest-facing contract for the `semantic_exports` section's public top-level and nested contract-owner map.
- `perl/FSM/Support/SemanticIntrospectionContract.pm` — bounded manifest-facing first-class semantic-introspection contract with query domains, query families, MCP resource/tool mappings, safety policy, and public surface ownership.
- `perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` — read-only
  semantic-introspection adapter that exposes manifest-selected MCP
  resources/tools over local JSON-RPC stdio without write/generation tools.
- `perl/FSM/Support/SemanticIntrospectionSection.pm` — dedicated `semantic_introspection` manifest-section builder.
- `perl/FSM/Support/CheckDiagnostics.pm` — bounded `--check --json` report builder and stable-code classifier.
- `perl/FSM/Support/CheckDiagnosticsContract.pm` — bounded `--check --json` key-presence contract advertised through the capability manifest.
- `perl/FSM/Support/CheckFailureDiagnosticContract.pm` — shared bounded nested-object contract for failure `diagnostic` payloads in public check JSON and normalized semantic JSON.
- `perl/FSM/Support/CheckResultContract.pm` — bounded nested-object contract for successful public check JSON `result` payloads.
- `perl/FSM/Support/CompositionReportContract.pm` — bounded sanitized composition provenance/report contract for semantic JSON.
- `perl/FSM/Support/NormalizedSemanticCompositionContract.pm` — bounded nested-object contract for the `semantic.composition` summary in successful public normalized semantic JSON composition sources, including bounded `children[]`, `children[].parameter_overrides[]`, `generated_children[]`, `generated_children[].parameter_overrides[]`, `standalone_dt_children[]`, and `shared_datapath_candidates[]` shallow/alias entry key families.
- `perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm` — bounded nested-object contract for the `semantic.explicit_system_contract` summary in successful public normalized semantic JSON when that authored explicit contract is preserved.
- `perl/FSM/Support/NormalizedSemanticForwardIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir` summary in successful public normalized semantic JSON.
- `perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir.lowered_rtl_ir` summary in successful public normalized semantic JSON, including output-drive, selector-conflict, standalone-DT multi-drive, and composition-only extension key families.
- `perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir.structural_rtl_ir` summary in successful public normalized semantic JSON, including bounded `assignment_records[]` structured generated-enable entries, bounded `auxiliary_assignments[]` scalar-string compatibility values, bounded `ports[]` core keys, direct input-port `targets[]` extension/entry keys, `nets[]`, generated-enable net `source`/`targets[]` connectivity entry keys, `declared_links[]`, `resolved_links[]`, shallow `instances[]`, nested `instances[].interface_ports[]`, nested `instances[].parameter_overrides[]` core plus optional raw-value/value-metadata extension keys, and nested `instances[].port_bindings[]` core plus typed-extension entry keys.
- `perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir.intent_hir` summary in successful public normalized semantic JSON, including its composition-only extension keys and composition-child alias key families.
- `perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm` — bounded nested-object contract for the `semantic.signal_analysis` summary in successful public normalized semantic JSON, including the shared core signal-entry keys.
- `perl/FSM/Support/NormalizedSemanticSystemContract.pm` — bounded nested-object contract for the `semantic.system_contract` summary in successful public normalized semantic JSON.
- `perl/FSM/Support/NormalizedSemanticSymbolContract.pm` — bounded nested-object contract for the optional `semantic.symbol_contract` summary in successful public normalized semantic JSON symbol-rich sources.
- `perl/FSM/Support/NormalizedSemanticModuleContract.pm` — bounded nested-object contract for the `semantic.module` summary in successful public normalized semantic JSON.
- `perl/FSM/Support/NormalizedSemanticPayloadContract.pm` — bounded nested-object contract for successful public normalized semantic JSON `semantic` payloads.
- `perl/FSM/Support/DiagnosticCodes.pm` — stable diagnostic-code registry consumed by support accounting and the capability manifest.
- `perl/FSM/Support/DiagnosticCodeRegistryContract.pm` — bounded stable-code registry contract advertised through the capability manifest.
- `perl/FSM/Support/DebugRuntimeContract.pm` — bounded in-process debug save/restore/scoped runtime contract advertised through `embedding.debug_runtime`.
- `perl/FSM/Support/ExtensionContract.pm` — bounded typed-extension/context contract advertised to embedders through the capability manifest.
- `perl/FSM/Support/HDLGeneratorFacadeContract.pm` — bounded public in-process `HDLGenerator` constructor/generation facade contract advertised through `embedding.hdl_generator_facade`.
- `perl/FSM/Support/ISFPublicInterfaceContract.pm` — bounded public ISF parser/scheduler facade and schedule-report contract advertised through `embedding.isf_public_interface`.
- `perl/FSM/Support/ISFResourceCatalog.pm` — shared ISF resource-kind registry consumed by the parser and public contract, including current arbiters, shareable resource kinds, shipped/backlog status, and meaning text.
- `perl/FSM/Support/HDLGeneratorModuleInfoContract.pm` — bounded nested-object contract for `HDLGenerator` `module_info` identity plus direct/composition scalar summary subsurfaces.
- `perl/FSM/Support/HDLGeneratorCompositionPlanContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `composition_plan` branch plus its sanitized composition-summary fallback surfaces.
- `perl/FSM/Support/HDLGeneratorCompositionSpecContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `composition_spec` branch plus its sanitized composition-summary fallback surfaces.
- `perl/FSM/Support/HDLGeneratorFSMModuleContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `fsm_module` CoreAST branch plus its semantic-summary fallback surfaces.
- `perl/FSM/Support/HDLGeneratorRawASTContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `raw_ast` parser/debug branch plus its semantic-summary fallback surface.
- `perl/FSM/Support/HDLGeneratorResolvedPackageImportsContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `resolved_package_imports` package-spec map plus its stable package-import summary surface.
- `perl/FSM/Support/HDLGeneratorStatisticsContract.pm` — bounded nested-object contract for `HDLGenerator` `statistics` direct/composition scalar summary subsurfaces.
- `perl/FSM/Support/HDLGeneratorSourceInfoContract.pm` — bounded nested-object contract for `HDLGenerator` `source_info` identity and package-import summary subsurfaces.
- `perl/FSM/Support/HDLGeneratorResultContract.pm` — bounded top-level result contract plus delegated nested `source_info`/`module_info`/`statistics` owners, delegated shell-only `composition_plan`/`composition_spec`/`fsm_module`/`raw_ast`/`resolved_package_imports` owners, advertised stable subsurfaces for `source_info`/`module_info`/`statistics` rather than whole-hash promises, an explicitly raw `composition_report` compatibility branch, and reused semantic-layer shell contracts rather than separate whole-hash promises for in-process `HDLGenerator` embedders.
- `perl/FSM/Support/SerializablePlanReportContract.pm` — bounded `embedding.serializable_plan_reports` contract that advertises JSON-safe plan/report surfaces and raw `HDLGenerator` shell replacement guidance for embedders.
- `perl/FSM/Support/SerializableCompositionPlanSnapshot.pm` — JSON-safe bounded composition-plan snapshot builder/contract for embedders that need plan summaries without traversing raw `FSM::Composition::Plan` objects.
- `perl/FSM/Support/SerializableGenerationResultSnapshot.pm` — JSON-safe bounded `HDLGenerator` result snapshot builder/contract for embedders that need result summaries without exporting raw compatibility-shell objects.
- `perl/FSM/Support/SerializableDiagnosticSummary.pm` — JSON-safe bounded diagnostic summary builder/contract for stable diagnostic code/count inspection across public reports.
- `perl/FSM/Support/HDLExternalValidation.pm` — optional Verilator/Yosys validation lane for generated SystemVerilog.
- `perl/FSM/Support/HDLExternalValidationContract.pm` — bounded external validation contract advertised through the capability manifest.
- `perl/FSM/Support/NormalizedSemanticReport.pm` — bounded normalized semantic JSON report builder for downstream tool integration.
- `perl/FSM/Support/NormalizedSemanticReportContract.pm` — bounded normalized semantic JSON key-presence contract advertised through the capability manifest.
- `perl/FSM/Support/ReportGeneratedOutputContract.pm` — shared bounded nested-object contract for public `generated_output` payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/ReportCommandContract.pm` — shared bounded nested-object contract for public `command` payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/ReportProducerContract.pm` — shared bounded nested-object contract for public `producer` payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/ReportSourceContract.pm` — shared bounded nested-object contract for public `source` payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/SupportAccountingMatchContract.pm` — shared bounded nested-object contract for public support-accounting match payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/SupportAccountingContract.pm` — bounded support-accounting section contract advertised through the capability manifest.
- `perl/FSM/Support/RegressionCorpus.pm` — production support-accounting catalog owner consumed by the manifest and regression tests.
- `perl/FSM/SourceClassifier.pm` — top-level source-kind classification for FSM vs composition inputs.
- `perl/FSM/Adapter/FSMGenFull.pm` — FSM adapter/parsing entry.
- `perl/FSM/HDL/FlattenedDT.pm` — Flattened decision-tree facade.
- `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm` — live direct SystemVerilog post-flattening assembly owner.
- `perl/FSM/Package/IntegerLiteralSupport.pm` — shared `.fsm` integer-literal interpreter and target-HDL normalizer for decimal, based, prefixed, and intent-level sized spellings such as `5'23`, `8'-10`, and `20'x1`.
- `perl/FSM/Synthesis/EnableGraph.pm` — enable synthesis/helper ownership.

### Input, tests, and support
- `fsm/` — sample/input `.fsm` files.
- `ppif/` — sample/input `.ppif` files for shipped IAL2 public surfaces.
- `t/` — regression and behavior tests.
- `t/fixtures/semantic_introspection_mcp/` — bounded read-only MCP resource/tool envelope snapshots for client compatibility.
- `scripts/check_doctrines.sh` — doctrine-enforcement driver for registered
  deterministic repo rules.
- `scripts/check_doctrine_bootstrap.sh` — doctrine adoption self-check for root
  doctrine/toolbox docs, bootstrap pointers, hook wiring, and CI wiring.
- `scripts/check_docs_relative_paths.sh` — docs path-hygiene doctrine wrapper
  over `t/1414-docs-relative-paths-audit.t`.
- `scripts/check_memory_architecture.sh` — memory-architecture doctrine check
  registered under the doctrine driver.
- `docs/` — user and technical docs.
- `generated/` — generated parser/output artifacts.
- `grammars/` — grammar definitions.
- `rust/Cargo.toml` — additive Rust experiment workspace for the backend-language portability smoke.
- `rust/fsmgen-portable-api/` — incomplete `fsmgen_portable_api` contract crate; currently supports only the `feature.direct_sreset_active_high` `.fsm` check smoke, exposes a test-only parity projection binary for that smoke, and otherwise fails closed without Perl runtime integration.

## Quick start
```bash
./bin/fsmgen fsm/trial_0.fsm
./bin/fsmgen --output /tmp/trial_0.sv fsm/trial_0.fsm
./bin/fsmgen --debug=3 fsm/lte_dif_pmaster.fsm
./bin/fsmgen --verify-hdl --output /tmp/lte_dif_pmaster.sv fsm/lte_dif_pmaster.fsm
./bin/fsmgen --strict isf/apb_requester.isf
./bin/fsmgen --emit-schedule-json isf/i2c_master.isf
./bin/fsmgen --emit-schedule-json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --emit-verification-output uvm-passive-monitor --verification-outdir /tmp/fsmgen-uvm isf/verification_observation_metadata.isf
./bin/fsmgen --emit-verification-output vhdl-observation-package --verification-outdir /tmp/fsmgen-vhdl-observation isf/verification_observation_metadata.isf
./bin/fsmgen --capability-manifest
perl bin/fsmgen-mcp --request-json '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

When `--output` is omitted, generated HDL is written under the git-ignored
`.artifacts/<language>/` directory, such as `.artifacts/sv/trial_0.sv` or
`.artifacts/vhd/direct_assignment_pair_form.vhd`. Use `--output` when you want
an exact destination path.
Verification-output mode is separate from HDL generation: it requires
`--verification-outdir DIR` and writes the selected artifact tree there instead
of using `.artifacts/<language>/`.

For a read-only MCP client, configure the local command as
`perl /path/to/fsmgen/bin/fsmgen-mcp --workspace-root /path/to/workspace`.
For one-shot probes, use `--request-json` with JSON-RPC 2.0 requests; for
example, call `fsmgen_capability_query`, `fsmgen_support_summary`,
`fsmgen_explain_diagnostic`, `fsmgen_discover_sources`,
`fsmgen_find_examples`, `fsmgen_check`, `fsmgen_semantic_introspect`, or
`fsmgen_schedule_preview`. Source discovery supports `query`, `limit`,
`file_kind`, `source_kind`, and `classification` filters over the bounded
catalog. Source-bound calls use a workspace-relative `source_path`.

## Documentation quick preview
```bash
mdbook build docs/book
cd docs/book && mdbook serve
```
- The mdBook is the progressive learning surface.
- `docs/USER_GUIDE.md` remains the broad live reference while that split is still in progress.
- GitHub Pages publishes the same mdBook from `docs/book` through the active
  workflow in `.github/workflows/pages.yml` when the repository's Pages source
  is set to GitHub Actions.

## Local CI / pre-push regression
```bash
scripts/check_doctrines.sh
./bin/ci-regression quick
./bin/ci-regression smoke
./bin/ci-regression isf
./bin/ci-regression
./bin/ci-regression --list
```
- `scripts/check_doctrines.sh` is the fast doctrine gate used by pre-commit and
  CI; it currently runs doctrine-bootstrap, memory architecture, Knowledge
  Map, and docs path checks.
- `bin/ci-regression` is the repo-owned local regression entrypoint.
- The script resolves the repository root itself, so you can invoke it without depending on your current working directory.
- It supports explicit turnaround tiers:
  - `quick`: curated smoke set across direct `.fsm`, composition
    classification, one composition child path, ISF parse/schedule, and the
    ISF public contract.
  - `smoke`: alias for `quick`, provided for the fast basic-functionality
    check described by the tier.
  - `isf`: all ISF-focused tests in the current 109x, 11xx, 12xx, and 13xx
    numbered bands.
  - `full`: the complete Perl regression suite with `prove -I perl t`.
- With no mode argument it runs `full`, preserving the historical pre-push
  gate behavior.
- It also builds the mdBook with `mdbook build docs/book` by default, so the
  user-facing book stays under the same local quality gate; use `--no-book`
  only for a deliberately code-only local turnaround check.
- When `verilator` and `yosys` are installed, the external SystemVerilog validation smoke runs too; otherwise that test is skipped.
- GitHub Actions is active again under [.github/workflows/](.github/workflows/).
  The hosted regression workflow calls `./bin/ci-regression`, so the local and
  GitHub quality gates use the same repo-owned entrypoint.
- Hosted CI uses a minimal Perl setup. Ordinary runtime paths should not rely
  on undeclared local CPAN modules, and CLI report modes tested for clean
  stderr must remain compatible with the hosted Perl version.

## Local RAM guard for heavy runs
Broad `prove`, supported-corpus, and direct `fsmgen` runs can spawn large Perl
children. Agent-launched heavyweight local commands must use the RAM guard or
an equivalent active monitor:

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh --process-max-rss-mb 3072 -- ./bin/fsmgen --check-json ppif/axi_aw_valid_ready.ppif
```

The guard defaults to stopping the command tree when host memory reaches 88%
or when any descendant reaches 4096 MiB RSS. That keeps local runs below the
90% danger zone. If the guard trips, stop the broad run, record the resource
caveat in the owning task-tree leaf, and continue only with a narrower focused
check unless the user explicitly authorizes a different cap.

## CLI quick reference
```bash
./bin/fsmgen [options] <fsm_file_or_isf_file>
```
- `-o, --output <file>`: explicit output path.
- With no `--output`, generated HDL is saved under `.artifacts/<language>/`.
- `--outdir <dir>`: write every scheduled `.fsm` file produced from a multi-file `.isf` lowering.
- `-l, --language <systemverilog|sv|verilog|v|vhdl>`: target language.
- `-d, --debug[=N]`: numeric debug compatibility level (`0..4`; bare `--debug` implies `4`).
- `--trace-verbosity <none|low|medium|high|debug>`: named trace verbosity.
- `--trace-log[=FILE]`: trace output file (default `trace.log`).
- `--trace-emojis` / `--notrace-emojis`: emoji marker toggle.
- `--extension-module <Module::Name>`: load an explicit typed extension module from `@INC` (may be repeated).
- `--extension-config <file>`: load typed extension modules from an explicit config file (may be repeated).
- `--capability-manifest`: print the versioned JSON FSMGen capability manifest and exit.
- `--check --json`: run the full pipeline as a check, emit JSON diagnostics, and do not write HDL.
- `--emit-semantic-json`: run the full pipeline, emit bounded normalized semantic JSON, and do not write HDL.
- `--emit-schedule-json`: for `.isf` input, emit the scheduler's JSON report and exit before HDL generation.
- `--emit-verification-output uvm-passive-monitor`: for `.isf` input with passive `verification_observations[]`, emit the inert UVM passive-monitor skeleton package and artifact manifest.
- `--emit-verification-output vhdl-observation-package`: for `.isf` input with passive `verification_observations[]`, emit the inert VHDL observation metadata package and artifact manifest.
- `--verification-outdir <dir>`: required destination directory for `--emit-verification-output`.
- `--verify-hdl`: after writing generated SystemVerilog, run Verilator lint and ABC-free Yosys structural synthesis; optional ABC executable discovery is reported for contract visibility but ABC is not required or run by the CLI. In-process callers can explicitly opt into ABC-backed Yosys mapping validation with `FSM::Support::HDLExternalValidation::validate_systemverilog_file(..., abc_mapping => 1)`.
- `-q, --quiet`: suppress informational output.

Inputs ending in `.isf` are parsed by the intent scheduler, lowered to one or
more explicit `.fsm` sources, and then fed through the normal `.fsm` pipeline
unless `--emit-schedule-json` or `--emit-verification-output` is requested.
For `.isf` inputs, `--check --json` and `--check-json` emit structured
`success: false` JSON for parser, lowering, report-building, and downstream
semantic check failures instead of leaving stdout empty.
For successful `.isf` and `.ppif` inputs that lower through generated `.fsm`
temporaries, public check JSON and normalized semantic JSON keep
`source.resolved_path` on the original resolved `.isf`/`.ppif` file and can
match support accounting against those public source paths. The normalized
semantic payload still describes the generated `.fsm` semantic root.

The bounded machine-readable surfaces are backed by support accounting:
`--check --json` is corpus-covered across supported, strict-supported, and
expected-failure entries, while `--emit-semantic-json` is corpus-covered across
current supported, strict-supported, and expected-failure entries.
Those two public JSON/report surfaces now also share one bounded nested-object
owner for their `support_accounting` match payloads:
[perl/FSM/Support/SupportAccountingMatchContract.pm](perl/FSM/Support/SupportAccountingMatchContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`producer` object owner for FSMGen identity plus the report builder owner:
[perl/FSM/Support/ReportProducerContract.pm](perl/FSM/Support/ReportProducerContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`source` object owner for the caller-facing input string and resolved source
path:
[perl/FSM/Support/ReportSourceContract.pm](perl/FSM/Support/ReportSourceContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`command` object owner for invocation metadata such as `mode`, `json`,
`strict_mode`, and `target_language`:
[perl/FSM/Support/ReportCommandContract.pm](perl/FSM/Support/ReportCommandContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`generated_output` object owner for whether the report invocation emitted HDL
artifacts:
[perl/FSM/Support/ReportGeneratedOutputContract.pm](perl/FSM/Support/ReportGeneratedOutputContract.pm).
Successful public check JSON reports now also have one bounded nested `result`
object owner for module identity plus basic summary counts:
[perl/FSM/Support/CheckResultContract.pm](perl/FSM/Support/CheckResultContract.pm).
Failed public check JSON reports now also have one bounded nested `diagnostic`
object owner for the core stable diagnostic fields, matched-only corpus keys,
optional extracted artifact paths, and nested support-accounting metadata:
[perl/FSM/Support/CheckFailureDiagnosticContract.pm](perl/FSM/Support/CheckFailureDiagnosticContract.pm).
Failed public normalized semantic JSON reports now explicitly reuse that same
bounded nested `diagnostic` owner too.
Successful public normalized semantic JSON reports now also have one bounded
nested `semantic` object owner for module/system metadata, signal analysis,
and the forward-IR projection:
[perl/FSM/Support/NormalizedSemanticPayloadContract.pm](perl/FSM/Support/NormalizedSemanticPayloadContract.pm).
That payload owner now advertises `optional_child_presence_keys` for
`composition` and `symbol_contract`, and the normalized semantic report
contract republishes the same family as
`success_semantic_optional_child_presence_keys` so embedders can discover those
optional success children without inferring them from prose.
For composition sources, the nested `semantic.composition` owner also
advertises bounded `children[]`, `children[].parameter_overrides[]`,
`generated_children[]`, `generated_children[].parameter_overrides[]`, and
`standalone_dt_children[]` shallow/alias entry key families. Standalone-DT child
entries include the current reusable-DT names, enable-family metadata, module
enable-family metadata, and nested multi-drive target metadata. Each child
entry's `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` summaries, and
the nested standalone-DT multi-drive assertion shape, remain delegated to their
existing bounded contracts:
[perl/FSM/Support/NormalizedSemanticCompositionContract.pm](perl/FSM/Support/NormalizedSemanticCompositionContract.pm).
The composition-side `shared_datapath_candidates[]` collection is also
advertised there as an alias of the already bounded lowered-RTL
`composition_shared_datapath_candidates[]` candidate, contributor,
drive-intent, aggregate-enable, assertion, and bound-connection schemas instead
of duplicating those internals.
The nested `semantic.system_contract` summary inside that payload now also has
its own bounded owner for the explicit clock/reset contract keys emitted today:
[perl/FSM/Support/NormalizedSemanticSystemContract.pm](perl/FSM/Support/NormalizedSemanticSystemContract.pm).
The nested `semantic.explicit_system_contract` summary inside that payload now
also has its own bounded owner when the authored explicit contract is
preserved:
[perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm](perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm).
The nested `semantic.signal_analysis` summary inside that payload now also has
its own bounded owner for the current sanitized signal families plus the shared
core signal-entry keys emitted across direct and composition roots:
[perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm](perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm).
The nested `semantic.forward_ir` summary inside that payload now also has its
own bounded owner for the current sanitized forward semantic projections:
[perl/FSM/Support/NormalizedSemanticForwardIRContract.pm](perl/FSM/Support/NormalizedSemanticForwardIRContract.pm).
The nested `semantic.forward_ir.lowered_rtl_ir` summary inside that branch now
also has its own bounded owner for the current lowered-RTL shell, including
the bounded `output_drive_families[]` entry schema, selector-conflict target
count/list metadata, the bounded `selector_conflict_targets[]` entry schema,
standalone-DT multi-drive target metadata, the bounded
`standalone_dt_multi_drive_targets[]` entry schema and nested
`multi_drive_assertion` metadata keys, and the current composition-only
extension keys. For composition roots, that same contract also advertises the
bounded `composition_shared_datapath_candidates[]` entry schema, optional
declared-type extension keys, contributor entries and `bound_connection_expr`
metadata, contributor `drive_intent` entries plus nested drive-intent
`rhs_enable_families[]` entries, aggregate enable-family entries,
aggregate-family contributors, and multi/same-value assertion metadata.
Contributor child `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir`
summaries remain delegated to their existing bounded contracts:
[perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm).
The nested `semantic.forward_ir.structural_rtl_ir` summary inside that branch
now also has its own bounded owner for the current structural-RTL shell,
including bounded `assignment_records[]` structured generated-enable entry
keys, bounded `auxiliary_assignments[]` scalar-string compatibility values,
bounded `ports[]` core entry keys, composition-top port extension keys,
bounded `nets[]` entry keys, generated-enable net `source`/`targets[]`
connectivity entry keys, and bounded `declared_links[]` plus `resolved_links[]`
entry keys, plus bounded shallow `instances[]` entry keys, nested
`instances[].interface_ports[]` entry keys, and nested
`instances[].parameter_overrides[]` core plus optional raw-value/value-metadata
extension keys, plus nested `instances[].port_bindings[]` core plus
typed-extension entry keys:
[perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm).
Direct roots now populate `structural_rtl_ir.nets[]` with declaration-only
internal storage/helper nets projected from the backend internal declaration
plan plus generated enable wires projected from the already-prepared direct
backend enable registries and assignment analysis. Those direct net entries
preserve width, signedness, state-model, and declared-type metadata where
available. Direct generated enable assignments now live in
`structural_rtl_ir.assignment_records[]` as machine-readable continuous
assignment records with structured `lhs`, `rhs`, rendered text, and
provenance. Generated-enable net entries now also populate structured
`source` objects for assignment-record drivers and structured `targets[]`
entries for direct nets consumed by another generated-enable assignment-record
RHS. `structural_rtl_ir.auxiliary_assignments[]` mirrors those rendered lines
as scalar strings for compatibility. The direct SystemVerilog top
state/standalone-DT generated-enable condition block is now rerouted through
those `StructuralRTLIR` assignment records by an explicit backend marker
handoff that is removed before final HDL is returned. Direct input ports
consumed by generated-enable assignment-record RHS ASTs now also expose
structured `targets[]` entries on `structural_rtl_ir.ports[]` using the same
assignment-record target endpoint shape as generated-enable net targets.
Direct output ports whose names match bounded lowered output-drive families now
also expose a structured `source` summary on `structural_rtl_ir.ports[]` with
`kind`, `signal_name`, `multiplexer_type`, `driver_count`, `driver_blocks`,
`rhs_values`, `driver_enable_signals`, and `family_enable_signals`. Broader
output-drive/always-block body consumer modeling remains outside that compact
summary. Direct instance/link selector
`R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` confirms direct roots intentionally
keep `instances[]`, `declared_links[]`, and `resolved_links[]` empty; populated
instances and links remain a composition-top structural contract. Selector
`R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` confirms broader/full direct
SystemVerilog rerouting through `StructuralRTLIR` is still outside that
projection until direct behavior-body, state-update, output, and assertion
regions are structurally owned. Direct VHDL backend/reroute work remains
outside the projection and is deferred by
`R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` until the SystemVerilog-backed
IAL0/IAL1/IAL2 path is feature complete.
The nested `semantic.forward_ir.intent_hir` summary inside that branch now
also has its own bounded owner for the current intent-hir shell plus the
current composition-only extension keys. For composition roots, that same owner
also advertises bounded alias key families for
`composition_children[]`, `composition_generated_children[]`, and
`composition_standalone_dt_children[]` by delegating to the already bounded
`semantic.composition` child and standalone-DT child schema owners. The
`composition_children[].parameter_overrides[]` and
`composition_generated_children[].parameter_overrides[]` alias key families are
likewise bounded and delegate to the structural instance parameter-override
schema owner. Nested child `intent_hir`, `lowered_rtl_ir`, and
`structural_rtl_ir`
summaries stay delegated to their existing bounded contracts:
[perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm](perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm).
The optional `semantic.symbol_contract` summary inside that payload now also
has its own bounded owner for symbol-rich sources:
[perl/FSM/Support/NormalizedSemanticSymbolContract.pm](perl/FSM/Support/NormalizedSemanticSymbolContract.pm).
The nested `semantic.module` summary inside that payload now also has its own
bounded owner for the core module keys plus the current optional metric-key
family:
[perl/FSM/Support/NormalizedSemanticModuleContract.pm](perl/FSM/Support/NormalizedSemanticModuleContract.pm).
The nested `semantic.composition` summary inside that payload now also has its
own bounded owner for composition sources, including bounded
`children[].parameter_overrides[]` and
`generated_children[].parameter_overrides[]` alias key families that delegate to
`semantic.forward_ir.structural_rtl_ir.instances[].parameter_overrides[]`:
[perl/FSM/Support/NormalizedSemanticCompositionContract.pm](perl/FSM/Support/NormalizedSemanticCompositionContract.pm).
The generated-child public-export hardening edge now publishes
`parameter_override_count`, `parameter_overrides[]`, and bounded
parameter-override alias key families for
`semantic.composition.generated_children[]` and
`semantic.forward_ir.intent_hir.composition_generated_children[]`.
The symbol-contract constants public-export hardening edge now publishes
bounded scalar/list value key families for
`semantic.symbol_contract.constants` and
`semantic.forward_ir.intent_hir.symbol_contract.constants`. Every advertised
constant value carries `kind`; scalar values add `payload`, and list values add
`items`. That constants edge did not widen enum/type nested schemas,
package-import internals, or full normalized semantic export stabilization.
The symbol-contract enum public-export hardening edge now publishes enum
value-kind families for `semantic.symbol_contract.enums` and
`semantic.forward_ir.intent_hir.symbol_contract.enums`: enum entries are
member-payload maps, and dynamic enum members carry scalar payloads.
The symbol-contract type public-export hardening edge now publishes bounded
recursive type-entry schema metadata for `semantic.symbol_contract.types` and
`semantic.forward_ir.intent_hir.symbol_contract.types`: scalar entries carry
`kind`, `signed`, `width`, and optional `state_model`, while aggregate entries
carry recursive `items` or `members` plus `member_order`.
The symbol-contract package-import public-export hardening edge now publishes
explicit scalar package-name entry metadata for
`semantic.symbol_contract.package_imports` and
`semantic.forward_ir.intent_hir.symbol_contract.package_imports`.
`package_import_entry_value_kinds` is `[scalar_package_name]`, and
`package_import_entry_value_meaning` is `authored package-import package-name
string` on the top-level contract surface. Inside grouped
`presence_key_family_map` discovery maps, the corresponding
`*_package_import_entry_value_meaning` entries are single-element arrays
containing that same meaning string, preserving the invariant that every
grouped family-map value is array-valued. That edge does not expose raw
`FSM::Package::Spec` internals,
package source AST, package symbols, VHDL package declaration/emission, or full
normalized semantic export stabilization.
The direct VHDL scaffold now lowers generated two-state vector `bit [N:0]`
internal declarations to VHDL `std_logic_vector` signals while preserving
scalar `bit` as `std_logic`. Typed read-only direct-root two-state ports that
generate `input bit NAME` or `input bit [N:0] NAME` now lower to VHDL
`std_logic` / `std_logic_vector` input ports. Typed read-only non-signed
four-state ports that generate `input logic NAME` or
`input logic [N:0] NAME` now lower to VHDL `std_logic` /
`std_logic_vector` input ports. It also lowers generated vector `logic signed`
internal declarations to VHDL `signed` signals and generated signed vector
direct-root ports to VHDL `signed` ports. Same-width signed vector
addition/subtraction/multiplication/division/modulo RHS assignments now lower
as native signed VHDL arithmetic when the target and all operands are same-width
signed vectors, with multiplication/division/modulo target-width resized. The
scaffold also lowers signed vector numeric-literal addition/subtraction and
multiplication/division/modulo RHS assignments through target-width
`to_signed` literal conversion, with multiplication/division/modulo resized to
the target width. The direct VHDL scaffold also lowers the bounded generated
AMBA wrap arithmetic family in `fsm/amba_requester.fsm`, including
`beats_total_q * addr_step_q`, `addr_q - addr_q % (beats_total_q * addr_step_q)`,
and the matching wrap-high expression, through explicit unsigned target-width
resizes. Bounded direct aggregate-output packed-vector lowering is also shipped
for `t/corpus/direct_rhs_concat_target_autogrowth.fsm` and
`t/corpus/direct_aggregate_constant_target_autogrowth.fsm`; the maintained
supported direct-root VHDL sweep now runs clean. The first bounded composition
VHDL structural top is also shipped for the C3 external-RTL literal/concat
fixture in `t/corpus/composition_intent_integer_literals.fsm`, emitting VHDL
concurrent literal/concat assignments and an `entity work.uart_tx` port map
without SystemVerilog `module`/`assign` syntax. A second bounded composition
VHDL structural top is shipped for the C1 standalone-DT passthrough fixture in
`t/corpus/standalone_dtc_explicit_system_autowire.fsm`, emitting the VHDL child
entity plus a top-level `entity work.standalone_route_src` port map for the
explicit passthrough ports. The same bounded C1 standalone-DT family also
emits scalar integer generic maps such as `WIDTH => 16`, scalar expression
generic maps such as `EXPR_WIDTH => (8 + 1)`, and one-bit sized bitstring
generic maps such as `ENABLE_DEFAULT => '1'`, and multi-bit sized bitstring
generic maps such as `RESET_VALUE => "10100101"` before the standalone-DT
child port map; packed-list generic maps such as
`LANES => "1010010100111100"` and packed-map generic maps such as
`FRAME => "101"` also emit before that port map. The bounded C2 generated-FSM scalar-autowire top
is also shipped for `t/corpus/implicit_composition_system_autowire.fsm`, emitting
VHDL-safe generated-child shared-datapath export ports/assignments, scalar
structural signals, and both generated child entity port maps. The same
bounded C2 generated-FSM family also emits scalar integer generic maps such as
`WIDTH => 16` and scalar expression generic maps such as
`EXPR_WIDTH => (16 + 1)`, one-bit sized bitstring generic maps such as
`ENABLE_DEFAULT => '1'`, multi-bit sized bitstring generic maps such as
`RESET_VALUE => "10100101"`, and resolved packed aggregate generic maps such
as `LANES => "1010010100111100"` and `FRAME => "101"` before a generated
child port map. The bounded
APB/C4 generated-FSM top is shipped for `fsm/apb_tb.fsm`, emitting
`apb_requester` and `apb_completer` child VHDL entities, vector APB structural
signals, deterministic shared-datapath sink signals, and both child entity port
maps. The same APB/C4 family also emits scalar integer generic maps such as
`TIMEOUT_CYCLES => 8` and `TIMEOUT_CYCLES => 6`, scalar expression generic maps
such as `TIMEOUT_CYCLES => (4 + 1)` and `TIMEOUT_CYCLES => (3 + 3)`, and
one-bit sized bitstring generic maps such as `ENABLE_DEFAULT => '1'`, plus
multi-bit sized bitstring generic maps such as `RESET_VALUE => "10100101"` and
`RESET_VALUE => "00111100"`, and resolved packed aggregate generic maps such
as `LANES => "0011110010100101"` and `FRAME => "101"` before the
requester/completer child port maps. Qualified package constants in the same
APB/C4 subset are resolved before VHDL emission, so `param_pkg.TIMEOUT_8` and
`param_pkg.RESET_A5` emit `TIMEOUT_CYCLES => 8` and
`RESET_VALUE => "10100101"` without leaking package tokens.
Signed scalar division/modulo and mixed signed/unsigned scalar arithmetic
remain explicitly fail-closed; full aggregate
VHDL record/array lowering, broader generated-FSM/C4 composition VHDL beyond
the exact shipped fixtures, internal-net-heavy/bus-heavy tops beyond APB,
generic-map families outside the shipped external-RTL scalar literal/expression,
metadata-backed one-bit sized bitstring, multi-bit sized bitstring
literal/resolved-package-constant, resolved packed aggregate actuals,
standalone-DT scalar integer/expression/one-bit sized bitstring/multi-bit sized bitstring/packed-list/packed-map actuals and generated-FSM scalar
integer/expression, one-bit sized bitstring, multi-bit sized bitstring, and
resolved packed aggregate actuals, plus APB/C4 generated-FSM scalar integer,
scalar expression, one-bit sized bitstring, and multi-bit sized bitstring
actuals, resolved packed aggregate actuals, and resolved package-backed
actuals, external-RTL aggregate actuals that do not lower to one packed
literal, standalone-DT aggregate actuals that do not lower to one packed
literal, APB/C4 aggregate actuals that do not lower to one packed literal,
generated-FSM aggregate actuals that do not lower to one packed literal now
locked fail-closed before VHDL emission,
VHDL package
declaration/emission, GHDL validation, broad expression parity beyond the
shipped AMBA wrap family, package-import internals, unrelated forward-IR
payloads, and full normalized semantic export stabilization remain out of scope
until later exact leaves own them.
Package-root direct HDL generation is locked fail-closed by
`BACKEND-API-VALIDATION-FRONTIER.100.1`: `?pkg` roots remain import-only
declaration containers, not standalone SystemVerilog or VHDL package output
roots.
Declared aggregate structural VHDL ports/nets/types are locked fail-closed by
`BACKEND-API-VALIDATION-FRONTIER.101.1`: composition tops with declared
aggregate structural surfaces do not emit VHDL record/array declarations until a
future exact aggregate-lowering leaf owns them.
GHDL validation blocker reconfirmation is locked by
`BACKEND-API-VALIDATION-FRONTIER.102.1`: `ghdl` is unavailable in the current
environment, so external HDL validation remains SystemVerilog-only until a
future exact GHDL lane can run the tool.
Completed backend/API frontier leaf
`BACKEND-API-VALIDATION-FRONTIER.132` exhausted the active backend/API selector:
the supported-smoke `.fsm` corpus passes under `--language vhdl`, `ghdl` remains
unavailable, and remaining broad backend/API directions require future exact
owners before implementation. Completed selector leaf
`ARCHITECTURE-DEBT-FRONTIER.3` deferred ISF
parser/lowerer extraction until a stable family is proven by a future exact
owner. Completed implementation leaf
`R11-DIRECT-BACKEND-COORDINATION-FRONTIER.2` projects top-level direct state
and standalone-DT enable wires into `structural_rtl_ir.nets[]` without
claiming DT-specific/LHS WEN/EN wires, assignment connectivity, instances,
links, auxiliary assignments, or rerouting HDL emission. Completed
implementation leaf `R11-DIRECT-STRUCTURAL-WEN-EN-NETS.1` projects direct
DT-specific and LHS-level WEN/EN wires into `structural_rtl_ir.nets[]` as
declaration-only one-bit nets without claiming assignment connectivity,
instances, links, auxiliary assignments, or rerouting HDL emission. Completed
implementation leaf `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.2` projects
already-rendered direct generated enable assignment lines into
`structural_rtl_ir.auxiliary_assignments[]` as scalar strings without claiming
assignment records, direct net connectivity, instances, links, or rerouting
HDL emission. Completed implementation leaf
`R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.2` projects those same generated
enable assignments into machine-readable `structural_rtl_ir.assignment_records[]`
entries while retaining `auxiliary_assignments[]` as the compatibility mirror
and without rerouting HDL emission. Completed implementation leaf
`R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2` populates generated-enable direct
net `source` objects for assignment-record drivers and `targets[]` entries for
direct nets consumed by another generated-enable assignment-record RHS.
Completed implementation leaf `R11-DIRECT-STRUCTURAL-HDL-REROUTING.2`
reroutes the direct SystemVerilog top state/standalone-DT generated-enable
condition block through `StructuralRTLIR` assignment records by using explicit
backend markers that are removed before final HDL is returned. Completed
implementation leaf `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2`
populates direct input-port generated-enable RHS target connectivity on
`structural_rtl_ir.ports[]` without changing HDL emission. Completed
implementation leaf `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.2` populates
direct output-port `source` summaries from lowered output-drive families
without changing HDL emission. Completed selector leaf
`R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` confirms direct roots intentionally
keep empty instance/link arrays and no direct implementation leaf is warranted
today. Completed selector leaf
`R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` defers broader/full direct
SystemVerilog rerouting until direct behavior-body, state-update, output, and
assertion regions have exact structural ownership. Completed selector leaf
`R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` defers direct VHDL backend/reroute
work until the SystemVerilog-backed IAL0/IAL1/IAL2 path is feature complete.
Completed
implementation leaf `ARCHITECTURE-DEBT-FRONTIER.2.1` projects direct backend
storage/helper declaration-plan entries into `structural_rtl_ir.nets[]`
without rerouting HDL emission. The shipped literal-literal positive modulo
edge lowers
an 8-bit non-signed `REM = (% 2 3)` fixture to
`REM <= std_logic_vector(resize(to_unsigned(2, 8) mod to_unsigned(3, 8), 8));`.
The shipped literal-literal positive division edge
lowers an 8-bit non-signed `QUOT = (/ 2 3)` fixture to
`QUOT <= std_logic_vector(resize(to_unsigned(2, 8) / to_unsigned(3, 8), 8));`.
The shipped literal-literal positive multiplication edge lowers an 8-bit non-signed `PROD = (* 2 3)` fixture to
`PROD <= std_logic_vector(resize(to_unsigned(2, 8) * to_unsigned(3, 8), 8));`.
The shipped literal-first positive modulo edge lowers an
8-bit non-signed `REM = (% 2 A)` fixture to
`REM <= std_logic_vector(resize(to_unsigned(2, 8) mod unsigned(A), 8));`.
The shipped literal-first positive division edge lowers
an 8-bit non-signed `QUOT = (/ 2 A)` fixture to
`QUOT <= std_logic_vector(resize(to_unsigned(2, 8) / unsigned(A), 8));`.
The shipped literal-first positive multiplication
edge lowers an 8-bit non-signed `PROD = (* 2 A)` fixture to
`PROD <= std_logic_vector(resize(to_unsigned(2, 8) * unsigned(A), 8));`.
The shipped signal-first positive
modulo edge lowers an 8-bit non-signed
`REM = (% A 2)` fixture to
`REM <= std_logic_vector(resize(unsigned(A) mod to_unsigned(2, 8), 8));`.
The shipped signal-first positive division edge lowers an 8-bit
non-signed `QUOT = (/ A 2)` fixture to
`QUOT <= std_logic_vector(resize(unsigned(A) / to_unsigned(2, 8), 8));`.
The shipped signal-first positive multiplication edge lowers an 8-bit non-signed
`PROD = (* A 2)` fixture to
`PROD <= std_logic_vector(resize(unsigned(A) * to_unsigned(2, 8), 8));`.
Broad VHDL expression-literal parity remains deferred beyond this bounded
literal-literal arithmetic subset.
The shipped non-signed negative modulo edge lowers an 8-bit
non-signed `REM = (% A -2)` fixture to
`REM <= std_logic_vector(resize(unsigned(A) mod unsigned(to_signed(-2, 8)), 8));`.
The shipped non-signed division edge
lowers an 8-bit non-signed `QUOT = (/ A -2)` fixture to
`QUOT <= std_logic_vector(resize(unsigned(A) / unsigned(to_signed(-2, 8)), 8));`.
The shipped non-signed multiplication edge
lowers an 8-bit non-signed `PROD = (* A -2)` fixture to
`PROD <= std_logic_vector(resize(unsigned(A) * unsigned(to_signed(-2, 8)), 8));`.
The shipped non-signed subtraction edge lowers an 8-bit non-signed
`DIFF = (- A -1)` fixture to
`DIFF <= std_logic_vector(unsigned(A) - unsigned(to_signed(-1, 8)));`.
Broad VHDL expression parity, aggregate, package, GHDL, composition-parity,
and normalized semantic stabilization work remain deferred until exact leaves
own them.
The manifest is still not a full normalized semantic export stabilization
promise.
The manifest-facing stable diagnostic-code registry now has its own explicit
bounded contract owner in
[perl/FSM/Support/DiagnosticCodeRegistryContract.pm](perl/FSM/Support/DiagnosticCodeRegistryContract.pm),
so downstream tools can discover the public diagnostics sibling keys and stable
entry keys without treating the whole diagnostics tree as frozen.
The capability manifest shell now has that same explicit split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
builds the JSON, while
[perl/FSM/Support/CapabilityManifestContract.pm](perl/FSM/Support/CapabilityManifestContract.pm)
owns the bounded top-level and first nested section key lists advertised under
`manifest_contract`.
That shell contract now explicitly includes the first nested
`support_accounting` key list too, so machine consumers do not have to
special-case the corpus-backed section while discovering the current bounded
manifest shape.
The manifest's `support_accounting` section now also advertises that same
bounded owner through `support_accounting.section_contract`, while keeping the
existing inline support-accounting payload and catalog metadata in place for
compatibility.
The manifest's `embedding` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current in-process embedding surfaces, while
[perl/FSM/Support/EmbeddingContract.pm](perl/FSM/Support/EmbeddingContract.pm)
owns the bounded top-level and nested contract-owner map advertised through
`embedding.section_contract` without flattening the whole embedding tree into
one accidental API.
The current embedding children include
`embedding.debug_runtime`, owned by
[perl/FSM/Support/DebugRuntimeContract.pm](perl/FSM/Support/DebugRuntimeContract.pm),
and `embedding.hdl_generator_facade`, owned by
[perl/FSM/Support/HDLGeneratorFacadeContract.pm](perl/FSM/Support/HDLGeneratorFacadeContract.pm),
and `embedding.isf_public_interface`, owned by
[perl/FSM/Support/ISFPublicInterfaceContract.pm](perl/FSM/Support/ISFPublicInterfaceContract.pm),
and `embedding.serializable_generation_result_snapshot`, owned by
[perl/FSM/Support/SerializableGenerationResultSnapshot.pm](perl/FSM/Support/SerializableGenerationResultSnapshot.pm),
so callers can discover the shipped in-process runtime, facade, and report
boundaries from the manifest instead of inferring them from Perl implementation
files.
The snapshot child advertises the JSON-safe `HDLGenerator` result summary
contract directly, while the existing
`embedding.serializable_plan_reports.generation_result_snapshot_contract`
reference remains available for plan/report compatibility.
The facade child reports `default_generation_mode: flattened_debug_first` and
does not expose a public `generation_mode` constructor option; structured
non-flattened generation remains a separate backend path to implement later.
The manifest's `diagnostics` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current registry/check surfaces, while
[perl/FSM/Support/DiagnosticsContract.pm](perl/FSM/Support/DiagnosticsContract.pm)
owns the bounded top-level, scalar-string, and stable-code entry families
advertised through `diagnostics.section_contract` without flattening the whole
diagnostics tree into one accidental API.
The manifest's `producer` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current FSMGen identity/build metadata, while
[perl/FSM/Support/ProducerContract.pm](perl/FSM/Support/ProducerContract.pm)
owns the bounded top-level, scalar-string, and boolean field families
advertised through `producer.section_contract`. That keeps tool/build identity
discoverable without pretending this is already a package-manager release API.
The manifest's `semantic_exports` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current bounded semantic interchange surfaces, while
[perl/FSM/Support/SemanticExportsContract.pm](perl/FSM/Support/SemanticExportsContract.pm)
owns the bounded top-level and nested contract-owner map advertised through
`semantic_exports.section_contract`. That keeps `normalized_semantic_json`
discoverable without pretending every future semantic export format is already
frozen.
The manifest's `semantic_introspection` section is the first-class query
contract for AI/tooling integration:
[perl/FSM/Support/SemanticIntrospectionSection.pm](perl/FSM/Support/SemanticIntrospectionSection.pm)
publishes query domains, query families, versioning/provenance/safety policy,
contract-surface ownership, MCP adapter entrypoints, MCP resource URI
templates, and MCP tool names, while
[perl/FSM/Support/SemanticIntrospectionContract.pm](perl/FSM/Support/SemanticIntrospectionContract.pm)
owns the bounded schema advertised through
`semantic_introspection.section_contract`.
[perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm](perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm)
and [bin/fsmgen-mcp](bin/fsmgen-mcp) implement the first read-only local
JSON-RPC stdio adapter over that contract. The section reports
`mcp_adapter_implemented: true` and `write_generation_tools_enabled: false`;
source-bound responses include `adapter_provenance`, normalize workspace/repo
absolute paths to relative source identities, and redact other absolute paths.
Protocol-level JSON-RPC failures use `-32700` for parse errors, `-32600` for
invalid requests, `-32601` for unknown methods, and `-32000` for adapter call
errors. Write/generation, network, shell, mutation, commit, and push tools are
still not part of the public semantic-introspection surface. The
`fsmgen_support_summary` tool returns bounded support-accounting aggregates,
`fsmgen_discover_sources` returns catalog-backed relative source identities
without workspace traversal, `fsmgen_find_examples` includes support-summary
context, and `fsmgen_explain_diagnostic` links stable diagnostic metadata to
matching support-accounting examples.
The manifest's `backend_validation` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current backend validation surfaces, while
[perl/FSM/Support/BackendValidationContract.pm](perl/FSM/Support/BackendValidationContract.pm)
owns the bounded top-level and nested contract-owner map advertised through
`backend_validation.section_contract`. That keeps
`systemverilog_external` discoverable without pretending every future backend
validation lane is already frozen.
The manifest's `language_surface` section now follows the same pattern:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the authored-surface summary, while
[perl/FSM/Support/LanguageSurfaceContract.pm](perl/FSM/Support/LanguageSurfaceContract.pm)
owns the bounded top-level and first nested section-key lists advertised
through `language_surface.surface_contract` without pretending the whole
authored language is frozen. The bounded `language_surface.file_surfaces`
section advertises the shipped `.fsm`/`.isf`/`.ppif` file suffixes, including
the `.ppif` bounded-public rule that IAL2 lowers through generated `.isf`
before generated `.fsm`, and publishes the supported CLI modes plus current
support/deferral boundary for each shipped suffix.
The manifest's `verification_outputs` section is the bounded discovery surface
for generated verification artifacts:
[perl/FSM/Support/VerificationOutputsSection.pm](perl/FSM/Support/VerificationOutputsSection.pm)
publishes the shipped `uvm_passive_monitor_skeleton` target, its
`uvm-passive-monitor` CLI target, `.isf` source restriction,
`uvm/<actor>_observation_uvm_pkg.sv` artifact path pattern, manifest path, and
no-UVM-compile-support validation boundary. It also publishes the shipped
`vhdl_observation_package_skeleton` target, its `vhdl-observation-package` CLI
target, `.isf` source restriction,
`vhdl/<actor>_observation_vhdl_pkg.vhd` artifact path pattern, manifest path,
and no-VHDL-compile/no-VHDL-syntax/no-PSL validation boundary, while
[perl/FSM/Support/VerificationOutputsContract.pm](perl/FSM/Support/VerificationOutputsContract.pm)
owns the bounded target, artifact-manifest, observation, signal, source, and
validation key families advertised through
`verification_outputs.section_contract`.
The manifest's `documentation` section now has the same split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current doc pointers, while
[perl/FSM/Support/DocumentationContract.pm](perl/FSM/Support/DocumentationContract.pm)
owns the bounded top-level and path-list contract advertised through
`documentation.section_contract` without freezing the exact file lists forever.

## Assignment semantics (quick reference)
- `A <- expr`: synchronous/flopped assignment where `A` names the flop output/Q value.
- `A <= expr`: synchronous/flopped variant where `A` names the D-input/next-value side.
- `A = expr`: combinational assignment.
- Safety rule: combinational `=` cannot create direct/indirect RHS feedback to same LHS.
- Safety rule: D-input-named `<=` / `<=-` cannot read the same LHS name from the RHS or guard; use `<-` for ordinary register feedback. In default mode, legacy `<=+` is accepted as an alias for `<=-`; strict mode rejects `<=+` and points to preferred `<=-`.

## README maintenance policy
- Keep `README.md` as the canonical onboarding hub.
- Update it when any of the following changes materially:
  - project objective/scope,
  - document set or purpose,
  - key file paths / architecture entrypoints,
  - onboarding workflow.
- It does **not** need to be updated on every commit—only when meaningful for onboarding accuracy.

## Fresh session shortcut
For a new engineering session, the preferred one-line instruction is:

```text
Read SESSION_BOOTSTRAP.md and start from there.
```

That startup ritual must still honor the session safety invariant above:
`COMMIT.md` is mandatory, and every completed task, slice, or lane must be committed before the next one starts.
