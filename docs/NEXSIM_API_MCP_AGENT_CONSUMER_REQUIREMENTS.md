# NEXSIM Semantic API and MCP Agent-Consumer Requirements

Version: `1.0`

Status: `consumer requirements baseline; not an implementation or support claim`

Last updated: `2026-08-02`

## 1. Purpose

This document specifies what an expert engineering agent should eventually be
able to discover, inspect, execute, control, explain, compare, and qualify
through NEXSIM's native semantic API and its Model Context Protocol (MCP)
surface.

It is deliberately written from the consumer's point of view. It describes
observable capabilities and contracts, not NEXSIM's internal architecture,
implementation language, parser structure, scheduler data structures, or
storage design.

The document is also deliberately independent of any particular client. A
client may be an interactive debugger, IDE, regression service, verification
orchestration system, autonomous engineering agent, or another tool. No client
must reveal its private intermediate representations, internal model, or
reasoning architecture to use the contract.

This is a living, Git-versioned requirements document. NEXSIM may implement it
incrementally. Capability discovery must always distinguish what is supported
from what this document requests.

## 2. The outcome the consumer needs

The desired outcome is not merely "run a simulation through MCP." The desired
outcome is a semantic laboratory in which a permitted client can:

- construct an exact simulation configuration;
- compile and elaborate it with machine-readable evidence;
- navigate the complete static and elaborated design model;
- execute it under precise scheduler control;
- inspect values and simulator state at consistent points in time;
- ask why an event, value, diagnostic, assertion, or transaction occurred;
- observe verification-framework state rather than scrape text logs;
- checkpoint, replay, branch, and compare executions reproducibly;
- make narrowly authorized state changes with a complete audit trail;
- reduce failures to a portable, sanitized reproduction bundle; and
- determine exactly which claims are supported, partial, unavailable, or
  unverified in the active NEXSIM build.

Deep semantic introspection is the foundation. Stable identity, causality,
bounded control, replay, and truthful capability negotiation turn that
foundation into a dependable engineering interface.

## 3. Audience

This contract is intended for:

- NEXSIM API, runtime, debugger, and MCP implementers;
- client and adapter authors;
- HDL and verification engineers;
- IDE, CI, regression, and analysis-tool integrators;
- autonomous and supervised engineering-agent developers; and
- conformance and qualification authors.

It assumes familiarity with HDL compilation, elaboration, event-driven
simulation, four-state or resolved logic, assertions, coverage, and UVM. It
does not assume knowledge of any particular consuming project's internals.

## 4. Explicit non-claims and non-goals

This document does not claim that any listed capability is currently
implemented. Only a versioned capability response and corresponding
conformance evidence may establish support.

This document does not require NEXSIM to expose internal pointers, private data
structures, implementation-specific scheduler queues, or unrestricted process
memory. Public semantic identities must be opaque and stable within their
declared lifetime.

This document does not make MCP the definition of simulator semantics. The
native typed semantic API is authoritative. MCP is a discoverable, bounded,
secure operability projection of that API.

This document does not require arbitrary shell execution, unrestricted file
access, unrestricted network access, or unaudited runtime mutation.

This document does not privilege one HDL, verification methodology, vendor,
IDE, transport, or client implementation. Language- or framework-specific
capabilities must be discoverable and namespaced.

## 5. Normative language

The key words **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, and **MAY**
express requirement strength.

- **MUST** identifies a condition required for the relevant conformance level.
- **SHOULD** identifies a strong recommendation whose omission needs a stated
  rationale or capability limitation.
- **MAY** identifies an optional extension.

"Supported" means implemented and backed by passing conformance evidence for
the reported NEXSIM build and schema version. "Partial" means that a declared,
machine-readable subset is supported. Absence of a field, empty results, or a
successful transport response must never be interpreted as support by itself.

## 6. Architectural contract

### 6.1 Native semantic API

`NXAPI-ARCH-001` The native API MUST be typed, versioned, and authoritative for
the semantics exposed by NEXSIM.

`NXAPI-ARCH-002` The API SHOULD be usable both in-process and through a
service boundary without changing semantic meaning.

`NXAPI-ARCH-003` Language bindings MAY differ idiomatically, but every binding
MUST preserve identifiers, values, status distinctions, errors, ordering,
snapshot semantics, and capability metadata.

`NXAPI-ARCH-004` The API MUST separate read operations from state-changing
operations. Read access MUST NOT silently acquire mutation authority.

### 6.2 Session and workspace service

`NXAPI-ARCH-005` NEXSIM MUST model workspaces, configured projects, builds,
elaborations, simulation runs, checkpoints, and artifacts as distinct typed
resources.

`NXAPI-ARCH-006` Each resource MUST have an opaque identifier, lifecycle,
ownership scope, creation metadata, and explicit terminal or invalidated state.

`NXAPI-ARCH-007` A client MUST be able to reconnect to a durable session when
policy permits, or receive an explicit `not_durable` result.

### 6.3 MCP projection

`NXAPI-ARCH-008` MCP tools and resources MUST project native API operations;
they MUST NOT independently reinterpret HDL or simulator semantics.

`NXAPI-ARCH-009` Every MCP result MUST state the native API schema family and
version from which it was projected.

`NXAPI-ARCH-010` MCP responses MUST be bounded by default. Large graphs,
traces, waveforms, logs, and artifacts MUST use pagination, field selection,
streaming, or explicit artifact handles.

`NXAPI-ARCH-011` State-changing MCP tools MUST be separately discoverable,
separately authorized, and unmistakable from read-only tools.

### 6.4 Artifacts and exports

`NXAPI-ARCH-012` Human-readable logs, waveform files, coverage databases, and
reports are useful exports, but MUST NOT replace the structured semantic API
when structured data is available.

`NXAPI-ARCH-013` Every exported artifact MUST have a content digest, media
type, schema or format version where applicable, producer build identity,
run/build relationship, size, retention state, and safe retrieval mechanism.

## 7. Universal response envelope

Every native API and MCP operation SHOULD use a common conceptual envelope.
Language bindings may express it as native types rather than literal JSON.

The envelope MUST be able to carry:

- request and correlation identifiers;
- operation name and operation schema version;
- NEXSIM product, build, and semantic-engine identities;
- workspace, build, elaboration, run, and snapshot identifiers when relevant;
- capability status and applicable limitations;
- result status, structured warnings, and structured errors;
- pagination or continuation state;
- completeness and truncation indicators;
- source and object provenance;
- elapsed time, resource consumption, and server timing when requested;
- artifact handles rather than uncontrolled inline payloads; and
- audit identity for authorized mutations or control operations.

`NXAPI-CORE-001` A successful transport response MUST NOT conceal a failed,
partial, cancelled, stale, unsupported, or deadline-exceeded semantic
operation.

`NXAPI-CORE-002` Every collection MUST define deterministic ordering or return
an explicit order key. Repeating an unchanged snapshot query MUST yield the
same order.

`NXAPI-CORE-003` Every potentially incomplete response MUST include
`complete`, `truncated`, and `continuation` semantics. A client must never have
to guess whether more data exists.

## 8. Capability and version discovery

Capability discovery is the first required operation in every session.

`NXAPI-CAP-001` NEXSIM MUST report product version, build identifier, API
versions, MCP profile versions, supported transports, host platform, and
enabled licensed or optional components without exposing secrets.

`NXAPI-CAP-002` It MUST report supported HDL languages, language revisions,
verification frameworks, assertion languages, coverage kinds, waveform
formats, foreign-language interfaces, and extension namespaces.

`NXAPI-CAP-003` Capability state MUST be one of at least:
`supported`, `partial`, `unsupported`, `not_applicable`, `disabled`, or
`unknown`.

`NXAPI-CAP-004` A partial capability MUST report its exact subset, limits, and
known exclusions in structured form.

`NXAPI-CAP-005` Capabilities MUST include the conformance-suite version and
evidence identity used to justify a support claim.

`NXAPI-CAP-006` Build-time availability, runtime enablement, current-session
authorization, and current-design applicability MUST be separate facts.

`NXAPI-CAP-007` A client MUST be able to negotiate a compatible API/schema
version and request failure rather than silent downgrade.

`NXAPI-CAP-008` Deprecated fields and operations MUST carry their replacement,
deprecation version, and earliest removal version.

`NXAPI-CAP-009` Experimental capabilities MUST be clearly marked and MUST NOT
be presented as stable merely because they are enabled.

## 9. Identity, provenance, and snapshots

### 9.1 Stable opaque identities

`NXAPI-ID-001` Source units, declarations, scopes, types, instances, nets,
variables, processes, assertions, cover items, framework objects, transactions,
diagnostics, builds, runs, checkpoints, and artifacts MUST have opaque IDs.

`NXAPI-ID-002` Every ID class MUST declare its stability domain: request,
snapshot, run, elaboration, build, workspace, or content-addressed/global.

`NXAPI-ID-003` An ID MUST NOT be a raw process pointer. Restarting a service or
restoring a checkpoint MUST not accidentally make a stale ID refer to a
different object.

`NXAPI-ID-004` Human-readable hierarchical names MUST be returned alongside
IDs when meaningful, but names MUST NOT be the only identity. Names can be
ambiguous, escaped, generated, rebound, or changed.

`NXAPI-ID-005` If an object is replaced or invalidated after incremental
rebuild, NEXSIM MUST report that fact and SHOULD provide predecessor/successor
mapping where semantically valid.

### 9.2 Source provenance

`NXAPI-PROV-001` Every source-derived semantic object MUST be traceable to
canonical source identity, content digest, language, library, compilation unit,
and one or more source spans.

`NXAPI-PROV-002` Source spans MUST distinguish original source, included
source, macro expansion, generated source, and tool-synthesized objects.

`NXAPI-PROV-003` Macro and include provenance SHOULD preserve expansion stacks
and both spelling and expansion locations.

`NXAPI-PROV-004` Paths MUST be expressed through workspace-relative logical
URIs where possible. Host-absolute paths MAY be withheld or redacted.

`NXAPI-PROV-005` Derived results MUST identify the build, elaboration, run,
snapshot, configuration, and source digests that make them valid.

### 9.3 Consistent snapshots

`NXAPI-SNAP-001` Multi-object reads MUST be evaluated against a declared
immutable snapshot or consistency token.

`NXAPI-SNAP-002` A snapshot MUST identify simulation time, global precision,
delta cycle, scheduler region or equivalent semantic point, run epoch, and
checkpoint ancestry when applicable.

`NXAPI-SNAP-003` A client MUST be able to request "fail if state advanced"
rather than receive values from mixed simulator instants.

`NXAPI-SNAP-004` Long paginated queries MUST either remain pinned to one
snapshot or fail explicitly when that snapshot expires.

`NXAPI-SNAP-005` Snapshot retention, expiry, and pinning costs MUST be
discoverable and quota-controlled.

## 10. Workspace and project configuration

`NXAPI-WORK-001` A client MUST be able to create or open a workspace using
explicit permitted roots and logical project-relative paths.

`NXAPI-WORK-002` NEXSIM MUST NOT infer unrestricted host filesystem authority
from a workspace path. Root policy, symlink policy, write policy, and artifact
policy MUST be explicit.

`NXAPI-WORK-003` A configured project MUST expose source sets, file ordering,
libraries, library mappings, include directories, macro definitions, language
revisions, preprocessing options, compilation-unit boundaries, tops,
parameters or generics, and simulator options.

`NXAPI-WORK-004` Configuration values MUST preserve origin: default, project
manifest, environment, command request, tool extension, or policy override.

`NXAPI-WORK-005` Secrets and sensitive environment values MUST be redacted.
Their presence or influence may be reported without returning their contents.

`NXAPI-WORK-006` A normalized effective configuration and its digest MUST be
available before build. This enables exact cache keys and reproducible reruns.

`NXAPI-WORK-007` Dependency discovery MUST expose source-to-source, package,
library, include, macro, binding, foreign-library, and generated-artifact
relationships where applicable.

`NXAPI-WORK-008` Invalid or ambiguous configurations MUST fail with structured
diagnostics before execution begins.

`NXAPI-WORK-009` NEXSIM SHOULD support content-addressed, in-memory source
overlays so a client can compile a candidate change without overwriting the
workspace source.

`NXAPI-WORK-010` Every overlay MUST identify its base source digest, complete
replacement content or exact patch semantics, owner, lifetime, and build
scope. Overlay content must never be mistaken for committed workspace state.

`NXAPI-WORK-011` Applying an overlay to persistent source is outside ordinary
simulation authority and MUST require a separate explicit file-write contract,
if NEXSIM offers one at all.

`NXAPI-WORK-012` A client SHOULD be able to compare diagnostics and semantic
models for base and overlay builds without changing either input set.

## 11. Preprocessing, parsing, analysis, and compilation

`NXAPI-BUILD-001` Build requests MUST expose distinct stage results for
configuration, preprocessing, parsing, semantic analysis, compilation, code
generation when present, and linking when present.

`NXAPI-BUILD-002` A later-stage failure MUST NOT erase successful earlier-stage
evidence. Each stage needs start/end state, timing, diagnostics, and artifacts.

`NXAPI-BUILD-003` Preprocessed views SHOULD be retrievable by bounded source
range, with macro/include provenance. Whole-unit exports MAY be artifacts.

`NXAPI-BUILD-004` Parse and semantic models MUST remain queryable for valid
regions of a partially invalid source set when NEXSIM can establish their
soundness.

`NXAPI-BUILD-005` Incremental builds MUST report reused units, invalidated
units, invalidation causes, cache hits/misses, and resulting build identity.

`NXAPI-BUILD-006` Build cancellation MUST be supported. Cancellation MUST
produce a terminal structured state and preserve only explicitly valid partial
artifacts.

`NXAPI-BUILD-007` Build operations MUST support deadlines and resource budgets
without silently weakening semantic checks.

`NXAPI-BUILD-008` Where parser data is exposed, token, syntax-tree, and recovery
nodes MUST retain language revision, exact source spans, macro/include
provenance, missing/error-node status, and relationship to semantic objects.

`NXAPI-BUILD-009` A client SHOULD be able to query the standards feature or
semantic rule associated with a diagnostic or semantic construct. References
must identify standard/version/clause without copying restricted standards
text into the response.

### 11.1 Diagnostics

`NXAPI-DIAG-001` Diagnostics MUST be structured with stable code, severity,
stage, primary span, message template identity, rendered message, and build
identity.

`NXAPI-DIAG-002` Diagnostics SHOULD include related spans, cause chains,
candidate definitions, notes, standards references, and machine-applicable
fixes when sound.

`NXAPI-DIAG-003` A fix MUST identify the exact source digest to which it
applies and MUST NOT be represented as safe when conflicting edits are
possible.

`NXAPI-DIAG-004` Suppression, promotion, waiver, and policy effects MUST be
reported with provenance. A suppressed diagnostic is not the same as no
diagnostic.

`NXAPI-DIAG-005` Duplicate diagnostics SHOULD carry a stable grouping key and
occurrence count rather than forcing clients to deduplicate prose.

`NXAPI-DIAG-006` Internal errors MUST be distinguishable from user-source
errors and MUST include a sanitized support bundle reference or correlation ID.

## 12. Elaboration

`NXAPI-ELAB-001` A client MUST be able to enumerate candidate tops and create
an elaboration from explicit top, configuration, library, parameter/generic,
and binding choices.

`NXAPI-ELAB-002` The elaboration result MUST expose the instance hierarchy,
generate choices, bound architectures or modules, interfaces, programs,
checkers, packages, configurations, binds, and foreign boundaries applicable
to the selected languages.

`NXAPI-ELAB-003` Every instance MUST expose declaration identity, parent,
children, hierarchical name, source provenance, effective parameters or
generics, port bindings, and creation/binding cause.

`NXAPI-ELAB-004` Generate constructs MUST preserve generate-block identity,
index values, selected alternatives, and source relationships.

`NXAPI-ELAB-005` Port maps and connections MUST expose formal and actual
objects, direction, type compatibility, conversion nodes, slices, concatenation,
aliases, resolved nets, implicit objects, and unconnected/defaulted status.

`NXAPI-ELAB-006` Black boxes, encrypted/protected regions, unsupported
constructs, unresolved binds, and foreign models MUST be explicit semantic
boundaries with limitation metadata.

`NXAPI-ELAB-007` Elaboration diagnostics MUST be structured and stage-specific.
A parse-clean design is not thereby elaboration-clean.

`NXAPI-ELAB-008` NEXSIM SHOULD expose elaboration dependency and creation
graphs so a client can explain why an object exists and what would invalidate
it.

`NXAPI-ELAB-009` An elaboration fingerprint MUST include every effective input
that can change elaborated meaning.

## 13. Static semantic graph

The semantic graph is the primary read model for source and elaborated design
meaning. It must support precise point queries and bounded graph traversals.

### 13.1 Symbols, scopes, declarations, and references

`NXAPI-SEM-001` A client MUST be able to enumerate scopes and symbols with
kind, language, visibility, lifetime, declaration span, containing scope, and
canonical ID.

`NXAPI-SEM-002` Definition, declaration, implementation, override, import,
export, bind, and reference relationships MUST be separately queryable.

`NXAPI-SEM-003` Reference queries MUST distinguish read, write, read/write,
call, type use, inheritance, sensitivity, event, assertion, coverage, and
elaboration-only uses.

`NXAPI-SEM-004` Name resolution SHOULD expose candidate sets and rejection
reasons when resolution fails or is ambiguous.

`NXAPI-SEM-005` Package imports, wildcards, aliases, library selection, lexical
scope, class scope, hierarchical lookup, and configuration effects MUST be
represented rather than flattened into unexplained final names.

### 13.2 Types and constants

`NXAPI-TYPE-001` Types MUST expose language kind, canonical identity, source
spelling, resolved/base type, dimensions, ranges, signedness, state domain,
resolution function, fields or members, parameters, and layout when defined.

`NXAPI-TYPE-002` Packed and unpacked dimensions, arrays, records/structs,
unions, enums, classes, interfaces, access/handle types, queues, associative
arrays, strings, files, real types, physical/time types, and user-defined
resolved types MUST be distinguishable when applicable.

`NXAPI-TYPE-003` Width and range calculations MUST preserve exact expressions,
evaluated values, and evaluation provenance. Unknown or invalid widths MUST
not be guessed.

`NXAPI-TYPE-004` Constant evaluation MUST return value, type, signedness,
state domain, precision, dependencies, and diagnostic status.

`NXAPI-TYPE-005` Assignment compatibility and conversion queries SHOULD explain
implicit conversion, sizing, truncation, extension, state-domain conversion,
and lossy behavior.

### 13.3 Connectivity and dataflow

`NXAPI-CONN-001` A client MUST be able to query drivers, loads, readers,
writers, aliases, resolution contributors, continuous assignments, procedural
assignments, port connections, primitive paths, and foreign boundaries.

`NXAPI-CONN-002` Connectivity MUST preserve slices, indices, conditions,
concatenations, transformations, and source provenance rather than reporting
only whole-object adjacency.

`NXAPI-CONN-003` Bounded fan-in, fan-out, upstream, downstream, and path queries
MUST support depth, node, edge, time, and result limits.

`NXAPI-CONN-004` A path result MUST report whether it is structural, potential,
active under the current elaboration, runtime-observed, or blocked by an opaque
boundary.

`NXAPI-CONN-005` Multiple drivers and resolved objects MUST expose all
contributors and the applicable resolution semantics.

`NXAPI-CONN-006` Combinational-loop, undriven, multiply-driven, width-mismatch,
and unused-object analyses SHOULD be accessible as structured findings with
soundness limitations.

### 13.4 Processes and behavioral structure

`NXAPI-PROC-001` Processes MUST expose kind, source, containing instance,
lifetime, sensitivity or trigger model, variables, read/write sets, called
subprograms, and static control-flow summary when available.

`NXAPI-PROC-002` Event expressions, delays, waits, clocking events, fork/join
relationships, disable targets, and process creation relationships MUST be
queryable.

`NXAPI-PROC-003` Functions, tasks, methods, constructors, virtual dispatch,
overrides, callbacks, and foreign calls SHOULD expose call relationships and
source provenance.

`NXAPI-PROC-004` Static summaries MUST state whether they are exact,
conservative, profile-derived, partial, or unavailable.

`NXAPI-PROC-005` Runtime process inspection SHOULD expose bounded call stacks,
activation frames, source locations, arguments, locals, return values, and
exception/disable/unwind state subject to language semantics and access policy.

`NXAPI-PROC-006` Static and runtime race analysis SHOULD identify participating
accesses, processes, scheduler regions, ordering assumptions, source spans,
and whether the finding is proven, potential, observed, or suppressed.

## 14. Query language and graph navigation

`NXAPI-QUERY-001` The API MUST provide typed point operations for common
questions and MAY additionally provide a composable semantic query language.

`NXAPI-QUERY-002` Query inputs MUST use explicit selectors such as IDs, exact
names, name patterns, kinds, source ranges, hierarchy roots, relationship
types, and property predicates.

`NXAPI-QUERY-003` Pattern syntax and case/escaping rules MUST be declared.
Server-side regular expressions, if supported, MUST be resource-limited.

`NXAPI-QUERY-004` Queries MUST support field masks so a client does not need to
retrieve full object records for simple questions.

`NXAPI-QUERY-005` Traversals MUST support maximum depth, nodes, edges, response
bytes, runtime, and cancellation.

`NXAPI-QUERY-006` Query plans or cost estimates SHOULD be available for
expensive operations. The service MAY reject an unbounded query before work
begins.

`NXAPI-QUERY-007` Saved queries MAY be supported, but their identity MUST bind
to a schema version and access scope.

`NXAPI-QUERY-008` Results MUST report opaque boundaries and excluded result
classes. "No path found" must be distinguishable from "search incomplete."

## 15. Runtime objects and values

### 15.1 Runtime identity

`NXAPI-RUN-001` Runtime objects MUST retain a queryable relationship to their
static declaration and elaborated instance identities.

`NXAPI-RUN-002` Dynamically created processes, class objects, transactions,
queues, and framework objects MUST receive identities whose creation event,
creator, type, lifetime, and destruction are observable when supported.

`NXAPI-RUN-003` Reused storage or handles MUST NOT cause a destroyed object's ID
to identify a later object accidentally.

`NXAPI-RUN-004` Object enumeration MUST allow filters by hierarchy, type,
lifetime, creation interval, framework role, and liveness.

### 15.2 Value representation

`NXAPI-VALUE-001` Values MUST preserve the language's native semantic domain.
SystemVerilog four-state values, VHDL resolved logic values, strengths,
signedness, ranges, enum identity, and unknown/high-impedance states must not
be flattened into ordinary integers.

`NXAPI-VALUE-002` The value model MUST support scalars, packed and unpacked
arrays, records/structs, unions, enums, strings, queues, associative arrays,
class handles and fields, real values, time/physical values, and opaque foreign
values as capabilities permit.

`NXAPI-VALUE-003` A value response MUST include type ID, exact width or shape,
state domain, signedness, display radix, snapshot ID, and completeness.

`NXAPI-VALUE-004` Large composite values MUST support slices, field selection,
element ranges, page limits, and summaries. Truncation MUST be explicit.

`NXAPI-VALUE-005` Uninitialized, inaccessible, optimized-away, unavailable,
invalid, destroyed, and unsupported values MUST be distinct states.

`NXAPI-VALUE-006` A formatted string MAY accompany a typed value, but it MUST
NOT be the only representation.

`NXAPI-VALUE-007` Resolved values SHOULD expose current driver contributions,
strengths, resolution result, and last contribution changes.

`NXAPI-VALUE-008` Value change history queries MUST state sampling semantics:
event change, settled value, scheduler-region observation, periodic sample, or
waveform reconstruction.

## 16. Simulation time and scheduler semantics

An agent needs the simulator's observable scheduling semantics, not its private
queue implementation.

`NXAPI-TIME-001` Every run MUST expose global time precision and each relevant
scope or unit's declared time unit and precision.

`NXAPI-TIME-002` Time values MUST use exact integer/rational or equally lossless
representation. Floating-point conversion MUST NOT be the sole representation.

`NXAPI-SCHED-001` A snapshot MUST identify simulation time, delta cycle, and
the language-defined scheduler region or equivalent observable phase.

`NXAPI-SCHED-002` NEXSIM MUST expose the ordered semantic regions it supports,
their language/version applicability, and any implementation limitation that
affects observable ordering.

`NXAPI-SCHED-003` A permitted client SHOULD be able to inspect bounded summaries
of runnable, blocked, waiting, suspended, terminated, and scheduled processes.

`NXAPI-SCHED-004` Process state SHOULD expose current source location or wait
site, wake condition, parent/child process relationships, disable state, and
last activation cause.

`NXAPI-SCHED-005` Pending updates SHOULD expose target, value summary, scheduled
time/region, originating process or source, and insertion order where the
language makes order observable.

`NXAPI-SCHED-006` NEXSIM SHOULD expose nonblocking assignments, signal
transactions, timed callbacks, event triggers, clocking-block activity, and
foreign callbacks through normalized semantic event classes.

`NXAPI-SCHED-007` Scheduler inspection MUST be snapshot-consistent and bounded.
It MUST NOT require exposing mutable internal queue addresses.

`NXAPI-SCHED-008` A client MUST be able to distinguish quiescence, normal
completion, explicit finish/stop, deadlock, zero-time livelock, iteration limit,
timeout, cancellation, resource exhaustion, and simulator failure.

`NXAPI-SCHED-009` Deadlock and zero-time-livelock findings SHOULD include the
participating process/wait/event graph and a bounded repeating-cycle witness.

## 17. Causality and explanation

This is a first-class requirement. Raw hierarchy and current values answer
"what." Engineering diagnosis also needs "why."

`NXAPI-CAUSE-001` A client MUST be able to ask why a value has its current
value at a snapshot.

`NXAPI-CAUSE-002` The answer SHOULD include the most recent effective writes,
driver contributions, resolution, scheduling events, activating processes,
conditions, and source spans necessary to explain the result.

`NXAPI-CAUSE-003` A client MUST be able to ask why a process woke, blocked,
terminated, or did not wake when an expected trigger occurred.

`NXAPI-CAUSE-004` A client SHOULD be able to ask why an assertion attempted,
passed, failed, became vacuous, or was disabled.

`NXAPI-CAUSE-005` A client SHOULD be able to ask why a framework phase,
objection, report, factory choice, configuration lookup, transaction, or
register-model update occurred.

`NXAPI-CAUSE-006` Explanations MUST be structured causal graphs with typed
nodes and edges, not prose alone. Human-readable summaries MAY accompany them.

`NXAPI-CAUSE-007` Every causal edge MUST identify its evidence source, snapshot
or event interval, source provenance, and whether it is exact, conservative,
inferred, sampled, or incomplete.

`NXAPI-CAUSE-008` Causal queries MUST support depth, fan-out, time-window,
event-count, and response-size bounds.

`NXAPI-CAUSE-009` If optimization or an opaque boundary prevents exact
explanation, the response MUST identify the boundary rather than fabricate a
cause.

`NXAPI-CAUSE-010` NEXSIM SHOULD support "first cause before time T" and "what
changed between snapshots A and B" queries.

## 18. Execution lifecycle and control

### 18.1 Run lifecycle

`NXAPI-CTRL-001` The API MUST support explicit create, initialize, start, run,
pause, resume, stop, cancel, and dispose lifecycle operations as applicable.

`NXAPI-CTRL-002` Each asynchronous operation MUST expose queued/running/paused/
completed/failed/cancelled state, progress, current simulation point, resource
use, diagnostics, and terminal reason.

`NXAPI-CTRL-003` Run requests MUST support exact stop conditions including
simulation time, delta count, scheduler point, event count, source breakpoint,
object change, assertion event, framework event, and client cancellation when
supported.

`NXAPI-CTRL-004` A time limit, wall-clock deadline, CPU budget, memory budget,
event budget, output budget, and zero-time-iteration budget MUST be distinct.

`NXAPI-CTRL-005` A control request MUST be idempotent where possible. Otherwise
it MUST accept an idempotency key and report whether execution began.

`NXAPI-CTRL-006` Control operations MUST accept an expected run epoch and
snapshot/position precondition so stale clients cannot act on an advanced run.

### 18.2 Stepping

`NXAPI-STEP-001` NEXSIM SHOULD support stepping to the next simulation time,
delta cycle, semantic scheduler region, value-change event, selected object's
event, process activation, source statement, assertion event, or framework
event.

`NXAPI-STEP-002` Step results MUST identify the exact stop reason, prior and
new snapshots, executed semantic events, and any limit reached.

`NXAPI-STEP-003` Source stepping MUST define behavior across optimized code,
macros, generated statements, inlined subprograms, foreign calls, and multiple
processes.

### 18.3 Breakpoints and watchpoints

`NXAPI-BP-001` Breakpoints SHOULD be settable by source span, declaration,
instance/object, process, simulation time, delta, scheduler region, event kind,
assertion, diagnostic, report, framework phase, or user-defined condition.

`NXAPI-BP-002` Conditional breakpoints MUST use a safe, bounded expression
language with declared evaluation point and side-effect prohibition.

`NXAPI-BP-003` Watchpoints SHOULD support value change, transition pattern,
driver change, read/write access where observable, queue size, object creation,
and selected framework events.

`NXAPI-BP-004` Breakpoint and watchpoint hits MUST return identity, condition,
trigger evidence, snapshot, relevant objects, and hit count.

`NXAPI-BP-005` One-shot, hit-count, sampled, disabled, and scoped breakpoints
MUST be distinguishable.

## 19. Authorized mutation and fault injection

Read-only access is the safe default. Mutation is valuable for debugging and
verification only when narrow, explicit, auditable, and reversible where
semantics allow.

`NXAPI-MUT-001` Mutation MUST require a separately granted capability and
operation-specific authorization scope.

`NXAPI-MUT-002` Supported mutation classes SHOULD include deposit, force,
release, memory/array element update, framework configuration before its legal
freeze point, and declared fault-injection operations.

`NXAPI-MUT-003` NEXSIM MUST define the exact language and scheduler semantics of
each mutation class, including when it becomes visible and what later events
can overwrite it.

`NXAPI-MUT-004` Every mutation request MUST carry target IDs, typed values,
expected snapshot/run epoch, requested semantic point, authorization identity,
reason, and idempotency key.

`NXAPI-MUT-005` Every mutation result MUST return before/after snapshots,
effective targets, conversions, rejected targets, warnings, and an audit record.

`NXAPI-MUT-006` Multi-target mutation SHOULD support atomic validation and
commit. If atomicity cannot be provided, partial application MUST be impossible
or unambiguously reported with exact applied operations.

`NXAPI-MUT-007` Force/release operations MUST expose force stack or ownership
semantics, original driver behavior, and release outcome.

`NXAPI-MUT-008` Fault injection SHOULD support bounded duration, activation
condition, target set, injected semantic effect, automatic cleanup, and
replayable identity.

`NXAPI-MUT-009` Arbitrary code execution, arbitrary memory writes, and arbitrary
shell commands MUST NOT be disguised as simulator mutation.

`NXAPI-MUT-010` The audit stream MUST be queryable and exportable. It MUST
include actor, authorization, request, result, time, snapshot, and target
provenance without leaking secrets.

## 20. Checkpoints, replay, branching, and determinism

`NXAPI-REPLAY-001` NEXSIM SHOULD support creating, listing, validating,
restoring, and deleting checkpoints through explicit lifecycle operations.

`NXAPI-REPLAY-002` A checkpoint MUST identify build/elaboration, exact source
and configuration digests, simulator build, semantic time/scheduler point,
random state, external dependencies, mutation history, and compatibility rules.

`NXAPI-REPLAY-003` Restore MUST fail closed on incompatible inputs unless an
explicit migration is supported and evidenced.

`NXAPI-REPLAY-004` A client SHOULD be able to fork a new run from a checkpoint
without mutating the parent run.

`NXAPI-REPLAY-005` NEXSIM MUST expose master seeds, named random streams,
stream creation ancestry, current stream state when permitted, and random
stability limitations.

`NXAPI-REPLAY-006` A replay manifest SHOULD record control requests, authorized
mutations, selected external inputs, foreign-interface interactions, and any
nondeterministic dependency necessary for reproduction.

`NXAPI-REPLAY-007` Deterministic replay MUST be a verified claim with a stated
scope. It must not be inferred merely because two runs currently match.

`NXAPI-REPLAY-008` Replay divergence SHOULD stop at the earliest observable
mismatch and report both snapshots, compared objects/events, and causal context.

`NXAPI-REPLAY-009` Checkpoint and replay data MUST support retention, quota,
encryption, portability, and sanitization policies.

## 21. SystemVerilog/UVM semantic introspection

UVM observability must be structured and simulator-neutral. Parsing console
messages is an inadequate substitute for framework state.

### 21.1 UVM environment identity and topology

`NXAPI-UVM-001` NEXSIM MUST report detected UVM implementation/version,
compilation identity, selected test, command-line settings, and capability
coverage.

`NXAPI-UVM-002` The UVM component tree MUST expose stable component IDs,
hierarchical names, types, creation source, parent/children, build order, and
current lifecycle state.

`NXAPI-UVM-003` Non-component objects SHOULD expose type, creator, source,
lifetime, and owning/related component when known.

### 21.2 Phases and objections

`NXAPI-UVM-PHASE-001` Phase domains, schedules, phase nodes, current phase,
transitions, jumps, synchronization, and per-component callbacks MUST be
queryable.

`NXAPI-UVM-PHASE-002` Phase history MUST include start/end time and delta,
callback ordering, process identity, and termination reason.

`NXAPI-UVM-OBJ-001` Objection state MUST expose source object, description,
count, total, raise/drop times, propagation path, drain time, and current blockers.

`NXAPI-UVM-OBJ-002` A "why has the phase not ended?" query SHOULD return the
active objection graph and relevant process state.

### 21.3 Factory

`NXAPI-UVM-FACT-001` Factory state MUST expose registered types, type and
instance overrides, precedence/order, source/provenance, and current effective
resolution.

`NXAPI-UVM-FACT-002` Object/component creation events SHOULD record requested
type, instance path, matching overrides, selected type, creator, source, and
result identity.

`NXAPI-UVM-FACT-003` A client SHOULD be able to ask why a requested type became
the instantiated type and receive the exact override resolution chain.

### 21.4 Configuration and resource databases

`NXAPI-UVM-CFG-001` Configuration/resource entries MUST expose name, scope
pattern, type, value subject to access policy, precedence, insertion order,
writer, source, and lifetime.

`NXAPI-UVM-CFG-002` Reads and writes SHOULD be traceable with requester, lookup
scope, candidates, selected entry, precedence reasoning, time, and source.

`NXAPI-UVM-CFG-003` A failed lookup SHOULD report searched scopes and rejection
reasons without exposing values the caller is unauthorized to read.

### 21.5 TLM, ports, exports, and transactions

`NXAPI-UVM-TLM-001` TLM ports, exports, implementations, sockets, connections,
min/max connection requirements, and resolved endpoints MUST be queryable.

`NXAPI-UVM-TLM-002` Analysis fan-out, FIFO occupancy, pending requests,
blocking calls, and transaction flow SHOULD be observable with bounded history.

`NXAPI-UVM-TLM-003` Transaction records SHOULD carry stable transaction ID,
type, producer, consumers, begin/end time, parent/child links, attributes,
recording stream, and source provenance.

`NXAPI-UVM-TLM-004` Transaction payload access MUST honor type, size, redaction,
and authorization limits.

### 21.6 Sequences, sequencers, and drivers

`NXAPI-UVM-SEQ-001` Active sequences MUST expose type, instance, parent,
sequencer, state, priority, relevance, start/finish times, current item, and
source.

`NXAPI-UVM-SEQ-002` Sequencer arbitration SHOULD expose queued requests, locks,
grabs, grants, chosen request, arbitration reason, and response routing.

`NXAPI-UVM-SEQ-003` Driver handshake state SHOULD expose current request,
get/peek/item_done/response events, responsible processes, and blocked parties.

`NXAPI-UVM-SEQ-004` A client SHOULD be able to ask why a sequence did not
receive a grant.

### 21.7 Register abstraction layer

`NXAPI-UVM-RAL-001` Register-model topology MUST expose blocks, maps, registers,
fields, memories, aliases, rights, reset values, addresses, strides, and HDL
backdoor paths.

`NXAPI-UVM-RAL-002` Effective frontdoor/backdoor selection, adapter, predictor,
sequencer, map, and byte-enable/endian transformation MUST be queryable.

`NXAPI-UVM-RAL-003` Desired, mirrored, reset, and observed values MUST remain
distinct and typed.

`NXAPI-UVM-RAL-004` Register accesses SHOULD expose request, path, bus
transaction linkage, prediction source, mirror updates, status, response,
check result, and source.

`NXAPI-UVM-RAL-005` A client SHOULD be able to ask why a mirror differs from an
observed design value and receive the relevant access/prediction causal chain.

### 21.8 Reports, callbacks, and policies

`NXAPI-UVM-REPORT-001` UVM reports MUST be structured with severity, ID,
verbosity, action, file/line, reporter, phase, time, process, catcher effects,
and final disposition.

`NXAPI-UVM-REPORT-002` Report configuration MUST expose effective severity/ID
actions, verbosity, file routing, and their scope/provenance.

`NXAPI-UVM-REPORT-003` Report catchers and callbacks SHOULD expose registration,
ordering, invocation, mutation/suppression effects, and source.

`NXAPI-UVM-REPORT-004` Final report counts MUST distinguish emitted, caught,
demoted/promoted, suppressed, and terminated-by-action reports.

`NXAPI-UVM-CB-001` Callback registration and invocation SHOULD expose target,
callback type/instance, ordering, enabled state, call source, and result effect.

## 22. Assertions and temporal properties

`NXAPI-ASRT-001` NEXSIM MUST report supported assertion/property languages and
semantic subsets by language revision.

`NXAPI-ASRT-002` Assertion declarations and elaborated instances MUST expose
IDs, source, hierarchy, clock/event, disable condition, severity/action, and
compile/elaboration status.

`NXAPI-ASRT-003` Runtime assertion events MUST distinguish attempt, active
thread, antecedent match, consequent progress, pass, fail, vacuous success,
disable, abort, and unsupported/opaque state where applicable.

`NXAPI-ASRT-004` Failure records SHOULD include sampled values, local variables,
matched sequence path, clock ticks, source spans, cause, and relevant waveform
window.

`NXAPI-ASRT-005` Assertion-control state MUST expose enabled/disabled scope,
control source, time interval, and effect on attempts and coverage.

`NXAPI-ASRT-006` Break-on-attempt/pass/fail/vacuity/disable SHOULD be supported
under the normal authorization and control model.

`NXAPI-ASRT-007` Assertion statistics MUST distinguish unavailable monitoring,
zero attempts, disabled intervals, vacuous passes, nonvacuous passes, failures,
active threads at termination, and incomplete runs.

`NXAPI-ASRT-008` Temporal thread inspection and history MAY be bounded by
retention limits, which MUST be reported.

## 23. Coverage

Coverage is evidence with provenance. A number without scope, exclusions, run
completeness, and merge history is not sufficient qualification evidence.

### 23.1 Coverage capabilities and model

`NXAPI-COV-001` NEXSIM MUST discoverably report support for statement, branch,
condition, expression, toggle, finite-state-machine, assertion, functional,
and user-defined coverage kinds.

`NXAPI-COV-002` Each coverage model and item MUST expose stable ID, kind,
source, elaborated scope, goal, weight, enabled state, support state, and
applicability.

`NXAPI-COV-003` Functional coverage MUST expose covergroups, instances,
coverpoints, bins, illegal/ignore/default bins, crosses, options, sample events,
and per-instance/type aggregation semantics.

`NXAPI-COV-004` Coverage values MUST distinguish hit count, percentage, goal,
covered state, unachievable/illegal state, excluded state, unsupported state,
unavailable data, and incomplete run.

`NXAPI-COV-005` A zero hit count MUST not be conflated with an item that was not
instrumented or whose sampling event never existed.

### 23.2 Samples, deltas, exclusions, and merges

`NXAPI-COV-006` NEXSIM SHOULD expose bounded sample history or first/last/sample
summaries with snapshot, values, process, and source provenance.

`NXAPI-COV-007` A client SHOULD be able to query coverage deltas between two
snapshots, checkpoints, runs, or merged databases.

`NXAPI-COV-008` Exclusions and waivers MUST expose author/source, reason, target,
scope, creation time, applicable build/source digest, review state, and expiry
when defined.

`NXAPI-COV-009` Merge operations MUST report every input identity, compatibility
decision, conflict, weighting rule, duplicate handling, output identity, and
loss of information.

`NXAPI-COV-010` Incompatible coverage databases MUST fail closed or produce an
explicit partial result. They MUST NOT be silently combined.

`NXAPI-COV-011` Standard and tool-native coverage exports MAY be provided, but
the structured API MUST remain sufficient to query the reported result.

## 24. Waveforms, traces, and event streams

### 24.1 Waveform selection and retrieval

`NXAPI-TRACE-001` A client MUST be able to select trace targets by semantic ID,
hierarchy, kind, source, connectivity relation, assertion, transaction, or
framework relationship.

`NXAPI-TRACE-002` Trace configuration MUST expose sampling/event semantics,
start/stop conditions, hierarchy depth, data kinds, retention, and resource
cost before capture begins.

`NXAPI-TRACE-003` Value traces MUST preserve exact typed values, time, delta,
observable scheduler point, and change cause when available.

`NXAPI-TRACE-004` Server-side range queries MUST support time window,
transition limit, object limit, decimation or summary mode, and continuation.

`NXAPI-TRACE-005` Decimation, lossy compression, sampling, dropped events, or
retention expiry MUST be explicit. A lossy trace must not look exact.

`NXAPI-TRACE-006` A client SHOULD be able to request a bounded pre-trigger and
post-trigger window around a breakpoint, assertion, report, transaction, or
selected event.

`NXAPI-TRACE-007` Waveform export MAY support formats such as VCD, FST, or other
declared formats. Exported files MUST carry scope/precision/limitations and an
artifact manifest.

### 24.2 Semantic event and transaction timelines

`NXAPI-TRACE-008` NEXSIM SHOULD provide a unified timeline of process,
scheduler, assertion, framework, transaction, report, mutation, and checkpoint
events with typed links.

`NXAPI-TRACE-009` Events MUST carry event ID, run/snapshot context, exact time,
delta/region when applicable, source/object relationships, and payload schema.

`NXAPI-TRACE-010` A transaction timeline SHOULD correlate high-level
transactions with TLM calls, sequence items, driver handshakes, protocol-level
activity, register accesses, assertions, and reports when mappings exist.

### 24.3 Subscriptions

`NXAPI-SUB-001` Clients SHOULD be able to subscribe to bounded value, event,
diagnostic, assertion, framework, coverage-delta, progress, and lifecycle
streams.

`NXAPI-SUB-002` Subscriptions MUST define delivery order, snapshot context,
buffer limit, backpressure policy, resume token, heartbeat, and loss behavior.

`NXAPI-SUB-003` Overflow MUST produce an explicit gap record with the lost
range. Silent event loss is forbidden.

`NXAPI-SUB-004` Filters MUST execute server-side and be resource-limited.

`NXAPI-SUB-005` Subscription cancellation and expiry MUST be explicit and
idempotent.

## 25. Regression and orchestration services

The semantic API need not become a general CI system, but it should expose the
simulator-facing orchestration necessary for reproducible verification.

`NXAPI-ORCH-001` A run specification MUST be able to bind build/elaboration,
test, seed, plus arguments, runtime configuration, resource budgets, expected
artifacts, and termination policy.

`NXAPI-ORCH-002` Matrix expansion SHOULD support tests, seeds, parameters,
generics, tops, configuration profiles, and declared environment dimensions
without requiring shell-script generation.

`NXAPI-ORCH-003` Compile/elaboration reuse MUST use exact compatibility keys and
report reuse evidence. It must not be inferred from filename coincidence.

`NXAPI-ORCH-004` Each job MUST expose queue, allocation, execution, collection,
and terminal states, along with worker identity, retries, and resource use.

`NXAPI-ORCH-005` Parallelism, queue priority, CPU, memory, disk, artifact, and
wall-clock limits MUST be policy-controlled and observable.

`NXAPI-ORCH-006` Retry policy MUST distinguish infrastructure failure,
simulator internal error, source failure, deterministic test failure, timeout,
resource exhaustion, cancellation, and suspected nondeterminism.

`NXAPI-ORCH-007` Result classification MUST be structured and configurable. A
zero process exit code MUST NOT automatically mean verification pass.

`NXAPI-ORCH-008` Final results SHOULD include build/elaboration status, run
termination, assertion summary, framework report summary, coverage status,
final state checks, diagnostic summary, expected/missing artifacts, and policy
verdict.

`NXAPI-ORCH-009` Job cancellation MUST propagate to simulator operations and
artifact collection with an auditable terminal state.

`NXAPI-ORCH-010` A portable run manifest SHOULD be exportable for exact rerun
subject to security and environmental compatibility.

## 26. Normalized results and evidence bundles

`NXAPI-RESULT-001` NEXSIM MUST provide a machine-readable terminal result whose
schema distinguishes compile, elaborate, start, run, verification, and artifact
collection outcomes.

`NXAPI-RESULT-002` The result MUST include source/configuration/build/run
fingerprints, simulator identity, capability evidence, seed/random scope,
termination reason, incomplete evidence, and artifact manifest.

`NXAPI-RESULT-003` User policy MAY define pass/fail, but the underlying observed
facts MUST remain available and unchanged.

`NXAPI-RESULT-004` Evidence bundles SHOULD contain a manifest, structured
results, selected logs, diagnostic/assertion/report data, trace slices,
configuration, source digests, and reproduction instructions.

`NXAPI-RESULT-005` Bundle creation MUST support sanitization, path rewriting,
source omission, secret scanning/redaction, size limits, and an explicit list
of excluded data.

`NXAPI-RESULT-006` Every bundle MUST be content-addressed or carry strong
digests for all components and the manifest itself.

## 27. Differential analysis and conformance comparison

An agent should be able to compare two configurations, revisions, simulator
builds, runs, or external result sets at semantic checkpoints without forcing
either producer to reveal its internals.

`NXAPI-DIFF-001` Comparison inputs MUST identify their schemas, value domains,
time models, source/build fingerprints, capability sets, and completeness.

`NXAPI-DIFF-002` NEXSIM SHOULD compare hierarchy, types, connectivity,
elaboration choices, initial state, selected checkpoints, event streams,
assertion results, transactions, reports, coverage, and terminal outcomes.

`NXAPI-DIFF-003` Object alignment MUST use explicit stable IDs, source/name/type
mappings, or a declared user mapping. Heuristic mappings MUST report confidence
and ambiguity.

`NXAPI-DIFF-004` Comparison policies MUST define unknown-state handling,
strength handling, time tolerance, ordering tolerance, ignored objects,
sampling alignment, numeric tolerance, and opaque boundaries.

`NXAPI-DIFF-005` The result MUST distinguish equal, different, incomparable,
unsupported, missing, truncated, and not-observed states.

`NXAPI-DIFF-006` For runtime mismatches, NEXSIM SHOULD identify the earliest
observable divergence and provide a bounded causal slice on both sides.

`NXAPI-DIFF-007` Mismatch classification SHOULD distinguish source/configuration,
compile, elaboration, initialization, scheduling, value, assertion, framework,
foreign-interface, nondeterminism, observation, and tool-internal causes.

`NXAPI-DIFF-008` Comparison reports MUST preserve raw evidence references so a
client can verify the normalized conclusion.

## 28. Failure localization and reduction

`NXAPI-DEBUG-001` NEXSIM SHOULD support time bisection using checkpoints or
replay to locate the first interval containing a failure or divergence.

`NXAPI-DEBUG-002` It SHOULD support dependency slices rooted at a value,
assertion, report, transaction, or failing output, with exact/conservative
labels.

`NXAPI-DEBUG-003` It MAY assist source, hierarchy, stimulus, event, transaction,
seed, and configuration reduction, but every proposed reduction MUST remain a
separate candidate until rerun evidence preserves the failure.

`NXAPI-DEBUG-004` Reduction operations MUST record transformations, preserved
failure signature, attempts, nondeterminism observations, and rollback data.

`NXAPI-DEBUG-005` A minimized reproduction bundle SHOULD contain the smallest
verified source/configuration/input set found, exact run manifest, expected
failure signature, and limitations.

`NXAPI-DEBUG-006` NEXSIM MUST NOT overwrite original sources as an implicit
part of reduction.

## 29. Performance, scale, and resource boundedness

### 29.1 Query scale

`NXAPI-PERF-001` Every collection operation MUST support pagination or a
documented small upper bound.

`NXAPI-PERF-002` Cursors MUST be opaque, snapshot-bound, access-bound, expiring,
and resistant to tampering.

`NXAPI-PERF-003` Field masks, server-side filters, aggregation, batching, and
summary modes MUST be available for high-cardinality semantic data.

`NXAPI-PERF-004` The API SHOULD support batch point reads and graph queries to
avoid one network round trip per object.

`NXAPI-PERF-005` Large values, traces, waveforms, coverage databases, logs, and
bundles MUST use streams or artifacts rather than unbounded inline results.

`NXAPI-PERF-006` Compression MAY be negotiated, but content encoding and
uncompressed size MUST be reported.

### 29.2 Limits and fairness

`NXAPI-PERF-007` NEXSIM MUST expose per-operation limits for time, memory,
result bytes, nodes, edges, events, retained snapshots, checkpoints, streams,
and concurrent operations.

`NXAPI-PERF-008` Limit failures MUST report the reached limit, completed work,
valid partial data, continuation options, and safe tuning range when permitted.

`NXAPI-PERF-009` One client MUST NOT be able to starve control, health, or
cancellation operations through expensive read queries.

`NXAPI-PERF-010` Quotas and scheduling SHOULD be attributable by workspace,
session, client, operation class, and authorization principal.

### 29.3 Measurement

`NXAPI-PERF-011` Operations SHOULD expose server processing time, queue time,
serialization time, rows/nodes/events examined, bytes read/written, cache use,
and peak resource consumption.

`NXAPI-PERF-012` Performance targets MUST be published per release and tested
against declared fixture scales. This document intentionally does not invent
numeric service-level objectives before implementation evidence exists.

## 30. Concurrency and multi-client behavior

`NXAPI-CONCUR-001` NEXSIM MUST define whether a run supports one controller and
many readers, multiple coordinated controllers, or another explicit model.

`NXAPI-CONCUR-002` Control ownership SHOULD use leases with identity, scope,
expiry, renewal, revocation, and observable holder information subject to
privacy policy.

`NXAPI-CONCUR-003` Read operations MUST be snapshot-consistent even while a run
advances.

`NXAPI-CONCUR-004` State-changing operations MUST use optimistic preconditions,
serialized control, or explicit transactions to prevent lost updates.

`NXAPI-CONCUR-005` The API MUST define ordering among control requests,
mutations, subscription events, and lifecycle transitions.

`NXAPI-CONCUR-006` Request cancellation MUST not cancel another client's work
unless the caller has explicit administrative authority.

`NXAPI-CONCUR-007` Session handoff SHOULD support a deliberate transfer of
control ownership without losing audit continuity.

## 31. Error model

`NXAPI-ERR-001` Errors MUST have stable machine-readable code, category,
operation stage, retryability, human message, correlation ID, and structured
details.

`NXAPI-ERR-002` At minimum, error categories MUST distinguish invalid request,
schema mismatch, unsupported capability, disabled capability, unauthorized,
forbidden target, not found, ambiguous, stale ID, stale snapshot, conflict,
limit exceeded, deadline exceeded, cancelled, source/configuration failure,
compile failure, elaboration failure, runtime failure, foreign-component
failure, artifact failure, transport failure, and NEXSIM internal error.

`NXAPI-ERR-003` Unsupported, not applicable, unavailable in this build,
unavailable for this design, and unavailable under current authorization MUST
not collapse into one error.

`NXAPI-ERR-004` Partial results MUST identify which portions are valid and why
the remainder is missing.

`NXAPI-ERR-005` Retrying an operation marked retryable MUST be safe under its
idempotency contract.

`NXAPI-ERR-006` Error text and details MUST redact secrets, forbidden paths,
unapproved source contents, and other tenants' data.

`NXAPI-ERR-007` Internal errors SHOULD offer a sanitized diagnostic bundle or
support token without exposing raw internal memory.

## 32. Security, trust, and data governance

### 32.1 Least privilege

`NXAPI-SEC-001` Read source, read semantic model, read runtime state, control
run, mutate state, manage checkpoints, manage artifacts, administer workspace,
and access sensitive values MUST be separate authorization scopes.

`NXAPI-SEC-002` Denied fields and operations MUST fail or redact explicitly.
Redaction must not be confused with an empty semantic value.

`NXAPI-SEC-003` Capability tokens SHOULD be short-lived, audience-bound,
operation-scoped, workspace/run-scoped, and revocable.

### 32.2 Filesystem, process, and network boundaries

`NXAPI-SEC-004` NEXSIM MUST canonicalize paths, enforce configured workspace
roots, define symlink behavior, and reject path traversal.

`NXAPI-SEC-005` Project-owned artifacts and temporary data SHOULD reside under
declared workspace-local storage unless an explicitly authorized external store
is selected.

`NXAPI-SEC-006` MCP and API clients MUST NOT gain arbitrary shell access through
build options, file names, foreign-interface configuration, log viewers, or
artifact handlers.

`NXAPI-SEC-007` External commands and foreign libraries, if supported, MUST use
an allowlisted policy with identity, digest, arguments, environment, isolation,
resource limits, and audit record.

`NXAPI-SEC-008` Network access MUST be disabled by default or governed by an
explicit destination/protocol policy and auditable authorization.

### 32.3 Isolation and retention

`NXAPI-SEC-009` Workspaces, tenants, sessions, runs, snapshots, streams, caches,
and artifacts MUST be isolated according to the deployment's declared trust
model.

`NXAPI-SEC-010` Source, value, log, waveform, coverage, checkpoint, and bundle
retention MUST be configurable by data class.

`NXAPI-SEC-011` Deletion MUST identify the exact resource and terminal state.
Shared content-addressed data MUST not be physically removed while authorized
references remain.

`NXAPI-SEC-012` Sensitive data scanning and redaction SHOULD be available for
logs, artifacts, evidence bundles, and MCP responses.

`NXAPI-SEC-013` Audit records MUST be tamper-evident within the declared trust
model and queryable by authorized principals.

### 32.4 Untrusted design input

`NXAPI-SEC-014` HDL, verification code, foreign models, artifacts, and project
manifests MUST be treated as untrusted inputs.

`NXAPI-SEC-015` Parser, compiler, elaborator, simulator, query engine, and MCP
adapter MUST enforce input-size, recursion, expansion, execution, and output
limits appropriate to their stage.

`NXAPI-SEC-016` Protected or encrypted source support MUST disclose what
semantic visibility is unavailable and enforce provider access policy.

## 33. Service observability and operability

`NXAPI-OBS-001` NEXSIM MUST expose health, readiness, version, capability,
resource-pressure, and dependency status without requiring a simulation run.

`NXAPI-OBS-002` API and MCP operations MUST carry correlation IDs through logs,
metrics, traces, asynchronous jobs, artifacts, and errors.

`NXAPI-OBS-003` Structured logs SHOULD distinguish client request, build,
elaboration, run, framework, security, audit, and internal-service events.

`NXAPI-OBS-004` Service metrics SHOULD include operation rates/latencies,
failures, queue depth, active sessions/runs, memory, CPU, storage, cache,
checkpoint, stream, and dropped-event counters.

`NXAPI-OBS-005` Authorized profiling SHOULD expose compile/elaboration hotspots,
simulation event/process hotspots, trace overhead, memory consumers, and query
cost without requiring internal pointer access.

`NXAPI-OBS-006` Readiness MUST distinguish "service accepts requests" from
"requested toolchain, language, framework, or worker is available."

## 34. Extension and interoperability model

`NXAPI-EXT-001` Extensions MUST be namespaced, versioned, capability-discovered,
and forbidden from changing core field meanings.

`NXAPI-EXT-002` Extension objects and events SHOULD preserve core identity,
snapshot, provenance, error, authorization, and boundedness contracts.

`NXAPI-EXT-003` Plugins MUST declare trust requirements, execution isolation,
data access, compatibility, resource budgets, and failure containment.

`NXAPI-EXT-004` Foreign-language interfaces and procedural interfaces SHOULD
expose boundary calls, callbacks, object mappings, errors, and nondeterminism
effects where policy and implementation allow.

`NXAPI-EXT-005` IDE/debug adapters MAY map the native API to other protocols,
but an adapter MUST NOT claim semantic fidelity for data its target protocol
cannot represent.

`NXAPI-EXT-006` Standard export formats SHOULD be accompanied by a limitations
manifest that identifies lost semantics.

## 35. Timing, power, mixed-language, and safe experiments

### 35.1 Timing and gate-level semantics

`NXAPI-TIMING-001` NEXSIM MUST capability-discover support for specify blocks,
path delays, timing checks, pulse handling, inertial/transport behavior,
interconnect delay, standard delay annotation, and gate/primitive simulation.

`NXAPI-TIMING-002` Effective timing data MUST expose source, annotation source,
instance/path target, delay tuple, min/typ/max selection, scale conversion,
override precedence, rejected annotations, and diagnostics.

`NXAPI-TIMING-003` Timing-check state and violations SHOULD expose check type,
reference/data events, limits, condition, notifier effect, source, annotated
origin, snapshot, and relevant trace window.

`NXAPI-TIMING-004` Gates, primitives, user-defined primitives, specify paths,
and delayed objects MUST participate in identity, connectivity, value,
scheduler, trace, and causality queries rather than becoming opaque strings.

`NXAPI-TIMING-005` A client SHOULD be able to compare zero-delay, unit-delay,
and annotated-timing configurations and locate the first semantic divergence.

### 35.2 Power-aware semantics

`NXAPI-POWER-001` NEXSIM MUST capability-discover supported power-intent
languages, revisions, command subsets, and simulation semantics.

`NXAPI-POWER-002` Power domains, supplies, supply sets, power states, isolation,
retention, level shifting, corruption, and power-control relationships SHOULD
be exposed as typed semantic objects with source provenance.

`NXAPI-POWER-003` Runtime power events SHOULD expose state transitions,
controlling conditions, affected objects, isolation/retention actions,
corruption/restoration effects, scheduler point, and causal relationships.

`NXAPI-POWER-004` A power-aware value response MUST distinguish native HDL
unknowns from power-induced corruption when the simulator can establish the
origin.

`NXAPI-POWER-005` Power-intent omissions, unsupported commands, conflicting
strategies, and partially modeled domains MUST be explicit limitations.

### 35.3 Mixed-language and analog-adjacent boundaries

`NXAPI-MIXED-001` NEXSIM MUST report supported mixed-language combinations,
revision pairs, binding rules, type conversions, time-resolution rules, and
unsupported crossings.

`NXAPI-MIXED-002` Cross-language instances, ports, signals, parameters/generics,
subprogram calls, foreign callbacks, and converted values MUST retain identities
and source provenance on both sides of the boundary.

`NXAPI-MIXED-003` Cross-language scheduling and value conversion MUST be
explainable at the observable semantic level, including loss of strength,
state-domain, range, precision, or type information.

`NXAPI-MIXED-004` Real-number modeling, wreal-like nets, analog/mixed-signal
extensions, or co-simulation MAY be supported, but each semantic subset,
solver synchronization boundary, tolerance, and inaccessible state must be
capability-discovered.

`NXAPI-MIXED-005` A digital-only build MUST report analog-adjacent constructs
as unsupported or opaque; it must not silently approximate them as ordinary
digital objects.

### 35.4 Typed interactive verification endpoints

`NXAPI-INTERACT-001` NEXSIM MAY allow a testbench to register typed interactive
endpoints for transactions, commands, observations, callbacks, or services.

`NXAPI-INTERACT-002` Registered endpoints MUST expose schema, direction,
legal lifecycle interval, scheduler semantics, blocking behavior, timeout,
authorization, source, and owning component/object.

`NXAPI-INTERACT-003` Invoking an endpoint MUST be an explicit controlled
operation with typed arguments, expected run epoch, idempotency behavior,
result/error schema, causal event identity, and replay record.

`NXAPI-INTERACT-004` An endpoint MUST NOT become arbitrary language eval,
unrestricted method invocation, or shell execution.

### 35.5 What-if analysis

`NXAPI-WHATIF-001` A client SHOULD be able to create a child experiment from a
base configuration, elaboration, run-start state, or checkpoint while
preserving the parent unchanged.

`NXAPI-WHATIF-002` Candidate differences MAY include source overlays,
parameters/generics, top/configuration, timing annotation, power intent, seed,
runtime arguments, framework overrides, selected mutation/faults, or policy.

`NXAPI-WHATIF-003` Every child experiment MUST return a normalized difference
manifest and support semantic/result comparison with its parent.

`NXAPI-WHATIF-004` A proposed fix or experiment becomes evidence only after its
own build/elaboration/run checks pass. NEXSIM must not label an unexecuted
candidate as a repair.

## 36. MCP-specific contract

The MCP surface is for safe, discoverable agent operability. It should make
common semantic work natural while preserving the native API's identities,
schemas, status distinctions, security boundaries, and snapshot guarantees.

### 35.1 Initialization and negotiation

`NXMCP-INIT-001` Initialization MUST report NEXSIM product/build identity,
native API schema versions, MCP projection version, supported MCP features,
maximum default result sizes, and authorization summary.

`NXMCP-INIT-002` The client and server MUST negotiate compatible protocol and
schema versions. Incompatibility MUST fail explicitly.

`NXMCP-INIT-003` Capability changes caused by workspace selection,
authorization, build completion, elaboration, run start, or extension loading
MUST be discoverable without restarting the client.

`NXMCP-INIT-004` Stdio and streamable network transports MAY be supported. The
transport choice MUST NOT change semantic results or authorization meaning.

### 35.2 Resources

MCP resources are best suited to stable or snapshot-addressed read views.
Suggested URI families include:

- `nexsim://server/capabilities`
- `nexsim://workspace/{workspace_id}/configuration`
- `nexsim://build/{build_id}/status`
- `nexsim://build/{build_id}/diagnostics`
- `nexsim://elaboration/{elaboration_id}/hierarchy/{object_id}`
- `nexsim://elaboration/{elaboration_id}/semantic/{object_id}`
- `nexsim://run/{run_id}/status`
- `nexsim://run/{run_id}/snapshot/{snapshot_id}/object/{object_id}`
- `nexsim://run/{run_id}/snapshot/{snapshot_id}/uvm/topology`
- `nexsim://run/{run_id}/assertions/summary`
- `nexsim://run/{run_id}/coverage/summary`
- `nexsim://artifact/{artifact_id}`

`NXMCP-RES-001` Resource URIs MUST use opaque IDs and MUST NOT embed unrestricted
host paths, source contents, secrets, or bearer credentials.

`NXMCP-RES-002` Mutable-state resources MUST identify the snapshot or return a
short status view that explicitly states its observation point.

`NXMCP-RES-003` Resource templates MUST document required variables, access
scope, schema, pagination, and maximum inline size.

`NXMCP-RES-004` Large artifacts MUST be retrieved through bounded ranges,
approved local artifact paths, or expiring authorized handles according to
deployment policy.

`NXMCP-RES-005` Resource change notifications MAY be offered, but high-rate
simulation data MUST use a bounded subscription/stream contract.

### 35.3 Tools

MCP tools are best suited to parameterized queries, asynchronous work, control,
and authorized mutation. The recommended tool families are listed in section
37.

`NXMCP-TOOL-001` Every tool MUST publish an input schema and a structured output
schema or versioned result-type identifier.

`NXMCP-TOOL-002` Tool results MUST place machine-readable data in structured
content. Human-readable text MAY summarize but MUST NOT be the only result.

`NXMCP-TOOL-003` Read-only, control, mutation, artifact-writing, and
administrative tools MUST carry accurate behavior annotations and distinct
authorization requirements.

`NXMCP-TOOL-004` State-changing tools MUST require an explicit run/workspace,
expected epoch or snapshot, idempotency key, authorization scope, and reason.

`NXMCP-TOOL-005` Asynchronous tools MUST return an operation ID and support
status, progress, cancellation, and terminal-result retrieval.

`NXMCP-TOOL-006` Tool errors MUST preserve the native API error code and
structured details; they must not collapse into conversational prose.

`NXMCP-TOOL-007` Tool descriptions MUST state result bounds, default limits,
side effects, persistence, cancellation behavior, and whether replay is safe.

### 35.4 Roots and locality

`NXMCP-ROOT-001` Client-provided roots MUST be treated as candidate authorized
workspaces, not blanket filesystem access.

`NXMCP-ROOT-002` NEXSIM MUST report which roots were accepted, rejected, or
restricted and why.

`NXMCP-ROOT-003` Project-relative logical paths SHOULD be used in schemas and
messages. Absolute host paths must be policy-controlled and redacted where
appropriate.

`NXMCP-ROOT-004` Generated data, caches, logs, and temporary workspaces SHOULD
remain within the selected project or deployment-owned storage root unless an
explicit external artifact store is authorized.

### 35.5 Progress, cancellation, and notifications

`NXMCP-PROG-001` Builds, elaborations, long queries, simulations, comparisons,
coverage merges, exports, and bundle creation MUST support progress tokens or
operation-status polling.

`NXMCP-PROG-002` Progress MUST include semantic stage and completed/estimated
work where a sound estimate exists. False precision is discouraged.

`NXMCP-PROG-003` Cancellation must be acknowledged, propagated, and followed
by a terminal state that says what valid evidence remains.

`NXMCP-PROG-004` Notifications SHOULD cover lifecycle, diagnostics, breakpoint,
assertion, report, framework, resource-pressure, and subscription-gap events
subject to client filters.

### 35.6 Prompt and context hygiene

`NXMCP-CONTEXT-001` MCP operations SHOULD return compact summaries plus IDs for
drill-down. They MUST NOT flood the client context with complete hierarchies,
logs, waveforms, or coverage databases by default.

`NXMCP-CONTEXT-002` Results SHOULD include suggested next semantic queries as
typed links or operation hints, not precomposed conclusions that obscure raw
evidence.

`NXMCP-CONTEXT-003` Server-provided text, source, logs, diagnostics, reports,
and design strings are untrusted data. They MUST remain clearly separated from
tool instructions and authorization decisions.

`NXMCP-CONTEXT-004` The MCP server MUST NOT infer approval for mutation,
filesystem writes, external commands, network access, or artifact disclosure
from natural-language content inside the simulated design or logs.

## 37. Recommended operation catalog

Names below are conceptual and may be adapted to NEXSIM naming conventions.
The separation and semantics matter more than spelling.

### 36.1 Foundation and workspace

| Native operation family | Suggested MCP tool | Purpose |
| --- | --- | --- |
| `capabilities.get` | `nexsim_capabilities_get` | Negotiate product, schema, language, framework, and operation support. |
| `service.health` | `nexsim_health_get` | Read health, readiness, pressure, and dependency state. |
| `workspace.open` | `nexsim_workspace_open` | Open one explicitly authorized root/configuration. |
| `workspace.describe` | `nexsim_workspace_describe` | Return roots, policies, effective configuration, and digests. |
| `workspace.close` | `nexsim_workspace_close` | Release a workspace without deleting persistent artifacts implicitly. |
| `project.configure` | `nexsim_project_configure` | Validate and materialize an explicit source/build configuration. |
| `source.read` | `nexsim_source_read` | Read an authorized, bounded source range with digest and provenance. |
| `source.overlay.create` | `nexsim_source_overlay_create` | Create a content-addressed candidate source view without overwriting files. |

### 36.2 Build and elaboration

| Native operation family | Suggested MCP tool | Purpose |
| --- | --- | --- |
| `build.create` | `nexsim_build_create` | Start a versioned, budgeted preprocessing/analysis/compile operation. |
| `operation.status` | `nexsim_operation_status` | Read progress and terminal results for any asynchronous operation. |
| `operation.cancel` | `nexsim_operation_cancel` | Cancel one identified operation. |
| `build.diagnostics.query` | `nexsim_diagnostics_query` | Query structured diagnostics by stage, severity, code, source, or unit. |
| `build.preprocessed.read` | `nexsim_preprocessed_read` | Read a bounded expanded-source range and expansion provenance. |
| `elaboration.create` | `nexsim_elaboration_create` | Elaborate explicit tops/configurations/parameter values. |
| `elaboration.describe` | `nexsim_elaboration_describe` | Read fingerprints, roots, boundaries, and status. |

### 36.3 Static semantic introspection

| Native operation family | Suggested MCP tool | Purpose |
| --- | --- | --- |
| `semantic.object.get` | `nexsim_semantic_object_get` | Retrieve selected fields for stable semantic IDs. |
| `semantic.query` | `nexsim_semantic_query` | Run a bounded typed query over symbols, types, references, or processes. |
| `hierarchy.children` | `nexsim_hierarchy_children` | Page through elaborated children under one object. |
| `symbol.definition` | `nexsim_symbol_definition` | Resolve a reference or name with provenance and alternatives. |
| `symbol.references` | `nexsim_symbol_references` | Query typed references with source ranges. |
| `type.describe` | `nexsim_type_describe` | Return exact type, dimensions, domain, fields, and conversions. |
| `connectivity.query` | `nexsim_connectivity_query` | Query drivers, loads, aliases, ports, fan-in/out, or bounded paths. |
| `process.describe` | `nexsim_process_describe` | Read behavioral kind, triggers, read/write sets, and source relationships. |
| `timing.query` | `nexsim_timing_query` | Query effective delays, annotations, timing checks, and violations. |
| `power.query` | `nexsim_power_query` | Query power-intent objects, runtime power state, and corruption causes. |
| `mixed_boundary.query` | `nexsim_mixed_boundary_query` | Inspect cross-language bindings, conversions, and scheduler boundaries. |

### 36.4 Runtime and explanation

| Native operation family | Suggested MCP tool | Purpose |
| --- | --- | --- |
| `run.create` | `nexsim_run_create` | Create a run from an exact elaboration and runtime manifest. |
| `run.control` | `nexsim_run_control` | Start, run, pause, resume, stop, or cancel under preconditions. |
| `run.step` | `nexsim_run_step` | Advance to a precisely declared semantic stop condition. |
| `snapshot.create` | `nexsim_snapshot_create` | Pin a consistent semantic observation point. |
| `runtime.objects.query` | `nexsim_runtime_objects_query` | Find static and dynamic runtime objects. |
| `runtime.values.read` | `nexsim_values_read` | Batch-read typed values from one snapshot. |
| `scheduler.query` | `nexsim_scheduler_query` | Inspect bounded process/event/update state. |
| `causality.explain` | `nexsim_causality_explain` | Explain a value, event, activation, assertion, or framework outcome. |
| `breakpoint.create` | `nexsim_breakpoint_create` | Add an authorized, bounded stop condition. |
| `breakpoint.manage` | `nexsim_breakpoint_manage` | List, enable, disable, or delete breakpoints/watchpoints. |
| `runtime.mutate` | `nexsim_runtime_mutate` | Apply separately authorized deposits, forces, releases, or faults. |
| `interactive.invoke` | `nexsim_interactive_invoke` | Invoke one testbench-registered typed endpoint under lifecycle and replay controls. |

### 36.5 Replay, verification, and evidence

| Native operation family | Suggested MCP tool | Purpose |
| --- | --- | --- |
| `checkpoint.create` | `nexsim_checkpoint_create` | Create a fingerprinted run checkpoint. |
| `checkpoint.restore` | `nexsim_checkpoint_restore` | Restore or fork under compatibility checks. |
| `replay.verify` | `nexsim_replay_verify` | Replay and report the earliest divergence. |
| `trace.query` | `nexsim_trace_query` | Retrieve a bounded semantic/value/event window. |
| `subscription.create` | `nexsim_subscription_create` | Start one filtered, backpressured event stream. |
| `uvm.query` | `nexsim_uvm_query` | Query topology, phases, objections, factory, config, TLM, sequences, RAL, or reports. |
| `assertion.query` | `nexsim_assertion_query` | Query assertion definitions, events, threads, and statistics. |
| `coverage.query` | `nexsim_coverage_query` | Query models, bins, deltas, exclusions, and provenance. |
| `coverage.merge` | `nexsim_coverage_merge` | Create an audited, compatibility-checked merged result. |
| `run.compare` | `nexsim_runs_compare` | Compare two evidence sets and locate first divergence. |
| `evidence.bundle.create` | `nexsim_evidence_bundle_create` | Create a bounded, sanitized reproduction/evidence bundle. |
| `artifact.list` | `nexsim_artifact_list` | Enumerate typed, digested artifacts. |
| `artifact.read` | `nexsim_artifact_read` | Read metadata or bounded content/ranges under policy. |

### 36.6 Operation design rules

The catalog MUST NOT become one universal `query` tool with an untyped command
string. Common high-value operations need typed schemas, stable errors, accurate
side-effect declarations, and fine-grained authorization.

A general semantic query facility remains useful for graph composition, but it
must obey the same identities, snapshot semantics, bounds, and security model.

Write-capable operations should be fewer and narrower than read operations.
Creating a build or run is a controlled persistent action; mutating a running
design is a stronger permission; arbitrary external command execution is out
of scope.

## 38. Illustrative request and response shapes

These examples illustrate semantics, not fixed wire spelling. IDs are opaque.
Field names may evolve through the versioning rules in section 42.

### 37.1 Capability discovery

```json
{
  "operation": "capabilities.get",
  "accept_schema": ["nexsim.semantic.v1"],
  "requested_families": [
    "systemverilog",
    "uvm",
    "scheduler_introspection",
    "checkpoint_replay",
    "mcp_projection"
  ]
}
```

```json
{
  "status": "ok",
  "product": {"name": "NEXSIM", "version": "<reported>", "build_id": "build:opaque"},
  "schema": "nexsim.semantic.v1",
  "capabilities": [
    {
      "name": "scheduler_introspection",
      "state": "partial",
      "subset": ["time", "delta", "region", "process_state"],
      "limitations": ["pending_update_causality_unavailable"],
      "evidence_id": "conformance:opaque"
    }
  ]
}
```

The placeholder values are intentional. This requirements document must not
pretend to know NEXSIM's current version or support state.

### 37.2 Bounded hierarchy query

```json
{
  "operation": "hierarchy.children",
  "elaboration_id": "elab:7f2d",
  "parent_id": "obj:top",
  "kinds": ["module", "interface", "program", "checker"],
  "fields": ["id", "kind", "name", "declaration_id", "source_spans"],
  "limit": 200,
  "continuation": null
}
```

```json
{
  "status": "ok",
  "elaboration_id": "elab:7f2d",
  "complete": true,
  "truncated": false,
  "items": [
    {
      "id": "obj:dut",
      "kind": "module",
      "name": "tb.dut",
      "declaration_id": "decl:dut",
      "source_spans": [{"uri": "workspace://rtl/dut.sv", "start": [12, 1], "end": [80, 10]}]
    }
  ]
}
```

### 37.3 Snapshot-consistent value and causality query

```json
{
  "operation": "runtime.values.read",
  "run_id": "run:19a4",
  "snapshot_id": "snap:105ns-d3-observed",
  "reads": [
    {"object_id": "obj:state_q", "format": "symbolic"},
    {"object_id": "obj:ready", "format": "logic"}
  ]
}
```

```json
{
  "status": "ok",
  "snapshot": {"id": "snap:105ns-d3-observed", "time_fs": "105000000", "delta": 3, "region": "observed"},
  "values": [
    {
      "object_id": "obj:state_q",
      "type_id": "type:state_t",
      "value": {"kind": "enum", "literal": "ACTIVE", "encoding": "2'b01"},
      "complete": true
    },
    {
      "object_id": "obj:ready",
      "type_id": "type:logic",
      "value": {"kind": "four_state", "bits": "1"},
      "complete": true
    }
  ]
}
```

```json
{
  "operation": "causality.explain",
  "run_id": "run:19a4",
  "snapshot_id": "snap:105ns-d3-observed",
  "question": {"kind": "why_value", "object_id": "obj:state_q"},
  "bounds": {"max_depth": 8, "max_nodes": 200, "max_bytes": 131072}
}
```

The causal result should link the selected value to its effective assignment,
process activation, sampled condition, clock/event, preceding drivers, and
source spans. If an opaque region prevents that chain, the result must name the
opaque boundary and mark the explanation incomplete.

### 37.4 Authorized control and mutation

```json
{
  "operation": "run.step",
  "run_id": "run:19a4",
  "expected_epoch": 14,
  "from_snapshot": "snap:105ns-d3-observed",
  "stop": {"kind": "next_assertion_event"},
  "budget": {"max_events": 100000, "wall_time_ms": 5000},
  "idempotency_key": "client-generated-opaque-key"
}
```

```json
{
  "operation": "runtime.mutate",
  "run_id": "run:19a4",
  "expected_epoch": 15,
  "at_snapshot": "snap:110ns-d0-readwrite",
  "authorization_scope": "runtime.force",
  "reason": "bounded fault-injection experiment",
  "idempotency_key": "client-generated-opaque-key-2",
  "mutations": [
    {
      "kind": "force",
      "target_id": "obj:ready",
      "value": {"kind": "four_state", "bits": "0"},
      "release": {"after_time_fs": "10000000"}
    }
  ]
}
```

The mutation must either be rejected before application or return an exact
audit record, before/after snapshots, effective scheduler semantics, and
automatic-release outcome. Natural-language intent alone is never authority.

### 37.5 MCP structured result

An MCP tool response should provide compact text for a person and the complete
bounded machine result separately:

```json
{
  "content": [
    {"type": "text", "text": "Paused at 110 ns, delta 2, after assertion failure asrt:17."}
  ],
  "structuredContent": {
    "schema": "nexsim.semantic.v1/step-result",
    "run_id": "run:19a4",
    "prior_snapshot_id": "snap:105ns-d3-observed",
    "snapshot_id": "snap:110ns-d2-observed",
    "stop_reason": {"kind": "assertion_failure", "assertion_id": "asrt:17"},
    "complete": true
  },
  "isError": false
}
```

The structured result is authoritative. The text summary is convenience.

## 39. Capability delivery priorities

The priorities below define a dependency order, not a release schedule. A
later capability may be prototyped early, but it cannot be considered dependable
without the foundations it relies upon.

### Priority 0: trustworthy semantic foundation

Priority 0 is the minimum useful contract for serious read-oriented tooling:

- truthful capability and version discovery;
- stable opaque IDs and source provenance;
- workspace/configuration fingerprints;
- structured build stages and diagnostics;
- explicit elaboration and hierarchy;
- symbols, types, references, processes, and connectivity;
- build/elaboration/run lifecycle identities;
- exact value representation;
- snapshot-consistent batch reads;
- truthful timing, power, mixed-language, and foreign-boundary capability
  discovery even when those capabilities are unsupported;
- bounded queries, pagination, field masks, and cancellation;
- structured errors and support-state distinctions;
- least-privilege workspace and source access;
- native API/MCP schema parity; and
- conformance evidence for every reported supported capability.

At Priority 0, execution may be coarse-grained, but read results must already be
truthful, typed, bounded, and reproducible.

### Priority 1: professional debug and verification observability

Priority 1 makes the interface a practical semantic debugger:

- precise run/pause/stop and stepping;
- scheduler time/delta/region/process visibility;
- breakpoints and watchpoints;
- value/event trace windows and bounded subscriptions;
- causal explanations;
- assertions with attempts, threads, failures, vacuity, and disables;
- UVM topology, phases, objections, factory, configuration, TLM, sequences,
  reports, and register-model basics;
- checkpoints, restore, fork, seed/random identity, and deterministic replay
  scope;
- unified terminal results and evidence bundles; and
- service health, profiling, and resource budgets.

### Priority 2: qualification and automated diagnosis

Priority 2 enables deeper autonomous verification work:

- separately authorized deposit/force/release and fault injection;
- first-divergence comparison and causal slicing;
- coverage models, samples, deltas, exclusions, and audited merges;
- deep UVM transaction, sequencer arbitration, RAL prediction, and callback
  history;
- failure time bisection and verified reduction;
- portable sanitized reproduction bundles;
- multi-run orchestration and normalized result policy; and
- source-overlay and child-experiment comparison without implicit workspace
  writes;
- high-volume semantic streams with resumable backpressure.

### Priority 3: ecosystem and scale

Priority 3 broadens deployment and extensibility:

- distributed worker orchestration and durable remote sessions;
- multi-tenant quotas and artifact stores;
- extension/plugin ecosystems with conformance profiles;
- standard debugger/IDE/coverage/waveform interoperability;
- sophisticated profiling and performance analysis;
- cross-build schema migrations for durable artifacts; and
- large-scale regression comparison and evidence analytics.

## 40. Conformance levels

NEXSIM SHOULD publish support by conformance level as well as by individual
capability. A product may support selected higher-level features while still
reporting a lower complete level.

### Level A: Inspect

Level A requires the complete Priority-0 foundation. An agent can build,
elaborate, navigate, and read a consistent semantic model without scraping
logs or guessing support.

### Level B: Debug

Level B adds controlled execution, scheduler observation, breakpoints,
stepping, trace windows, assertion detail, core UVM visibility, and causal
explanation.

### Level C: Replay

Level C adds checkpoints, exact run manifests, random-state scope, branching,
replay verification, first divergence, and audited control history.

### Level D: Qualify

Level D adds coverage provenance, deep verification-framework introspection,
authorized mutation/fault injection, comparison, reduction, evidence bundles,
and the scale/security evidence needed for qualification workflows.

No level should be claimed unless every mandatory requirement assigned to it
passes the declared conformance suite for the reported build and supported
language/framework profile.

## 41. Conformance and acceptance test requirements

### 40.1 Test fixture classes

The conformance suite SHOULD include small, deterministic fixtures for:

- preprocessing, include, and nested macro provenance;
- syntax errors, semantic errors, and valid partial models;
- library/package/import/name-resolution behavior;
- parameters/generics, configurations, binds, and generated hierarchy;
- ports, slices, aliases, multiple drivers, resolution, and conversions;
- packed/unpacked/composite/native-state-domain values;
- blocking, nonblocking, signal-transaction, delta, region, and race-sensitive
  scheduling cases;
- dynamically created processes and objects;
- checkpoint/replay with multiple random streams;
- assertion attempt/pass/fail/vacuity/disable behavior;
- UVM topology, phases, objections, factory override chains, configuration
  precedence, TLM flow, sequence arbitration, reports, and RAL prediction;
- code, assertion, and functional coverage including exclusions and merge
  incompatibility;
- trace overflow, subscription gaps, cancellation, and expired snapshots;
- unauthorized reads, forbidden paths, stale IDs, stale epochs, rejected
  mutations, and audit behavior;
- partial/unsupported capability truthfulness;
- pagination stability and resource-limit behavior; and
- differential first-divergence localization.

### 40.2 Positive, negative, and adversarial evidence

`NXAPI-TEST-001` Every supported operation MUST have positive tests, invalid
input tests, unsupported/applicability tests, authorization tests, limit tests,
cancellation tests when asynchronous, and schema-compatibility tests.

`NXAPI-TEST-002` Identity tests MUST prove stability within the declared domain,
staleness detection outside it, and non-aliasing after object destruction or
rebuild.

`NXAPI-TEST-003` Snapshot tests MUST attempt concurrent advancement and
pagination to prove that mixed-time results cannot occur silently.

`NXAPI-TEST-004` Causal tests MUST compare returned graphs with known minimal
causes and verify incomplete/opaque labeling.

`NXAPI-TEST-005` Replay tests MUST perturb seeds, configuration, source,
external input, and simulator build to prove compatibility failures and
earliest-divergence evidence.

`NXAPI-TEST-006` Security tests MUST include path traversal, symlink escapes,
oversized requests, expansion bombs, hostile strings, unauthorized tools,
cross-session IDs, artifact disclosure, output flooding, and instruction-like
content embedded in source/log data.

`NXAPI-TEST-007` MCP conformance MUST compare native and MCP results for semantic
parity, status/error parity, bounds, redaction, cancellation, and side-effect
annotations.

### 40.3 Determinism and oracle policy

`NXAPI-TEST-008` Each deterministic fixture MUST state its source/configuration
digest, expected semantic checkpoints, expected terminal result, and allowed
variation.

`NXAPI-TEST-009` Expected results SHOULD be derived from standards, independent
reference models, cross-implementation agreement, manually reviewed traces, or
another named authority. Oracle origin must be explicit.

`NXAPI-TEST-010` Comparing against another tool is evidence, not automatic
proof. Tool disagreement must remain classified until root-caused.

`NXAPI-TEST-011` Nondeterministic tests MUST state the distributional or
invariant claim and retain seeds/manifests for every failure.

### 40.4 Performance and robustness evidence

`NXAPI-TEST-012` Each release SHOULD run scale fixtures covering object count,
hierarchy depth, source size, event rate, trace rate, coverage count, concurrent
clients, artifact size, and checkpoint size.

`NXAPI-TEST-013` Published results SHOULD include latency percentiles, peak
memory, throughput, overhead of enabled introspection, cancellation latency,
and resource-limit behavior under declared hardware/configuration.

`NXAPI-TEST-014` Long-running soak and repeated create/dispose cycles SHOULD
check leaks, stale resources, ID reuse, dropped events, and retained workspace
data.

### 40.5 Support-claim evidence

For every declared supported capability, the capability response SHOULD link
to a conformance record containing:

- NEXSIM build and source revision;
- API and MCP schema versions;
- host/toolchain profile;
- language/framework profile;
- suite revision and fixture digests;
- pass/fail/skip counts;
- skipped-test reasons;
- known limitations and waivers;
- evidence bundle digest; and
- review or CI identity.

This makes support machine-verifiable rather than marketing prose.

## 42. Schema evolution, compatibility, and amendment protocol

### 41.1 Stable requirement identities

Requirement IDs in this document are durable. Amendments SHOULD add new IDs or
clarify existing text without silently repurposing an ID to mean something
incompatible.

If a requirement is retired, its ID remains in history with replacement or
rationale. It is not reassigned.

### 41.2 API and MCP schema evolution

`NXAPI-EVOL-001` Schemas MUST use explicit version identifiers and published
compatibility rules.

`NXAPI-EVOL-002` Compatible additions SHOULD be optional fields, new enum values
with unknown-value handling, new operations, or new capability namespaces.

`NXAPI-EVOL-003` Removing fields, changing units, changing identity lifetime,
changing ordering, weakening snapshot guarantees, changing error meaning, or
changing side effects requires an incompatible schema version.

`NXAPI-EVOL-004` Clients MUST be able to request strict rejection of unknown or
incompatible behavior where safety requires it.

`NXAPI-EVOL-005` Deprecation notices MUST provide replacement, migration
guidance, deprecation release, and removal horizon.

`NXAPI-EVOL-006` Durable checkpoints, artifacts, evidence bundles, saved
queries, and audit records MUST declare reader compatibility and migration
support separately from the live API.

`NXAPI-EVOL-007` Native API and MCP projection versions MAY advance separately,
but their compatibility mapping and semantic parity coverage MUST be published.

### 41.3 Amending this requirements document

An amendment should be made when one of the following occurs:

- NEXSIM publishes a concrete native API or MCP schema;
- a prototype reveals a missing operation, ambiguity, unsafe behavior, or scale
  problem;
- a new HDL, verification framework, assertion, coverage, or foreign-interface
  requirement becomes relevant;
- conformance evidence changes priority or exposes an incorrect assumption;
- a client integration demonstrates a better bounded operation shape; or
- the NEXSIM director changes scope or policy.

Each amendment MUST record:

- document version and date;
- trigger and evidence;
- affected requirement IDs;
- compatibility impact;
- priority/conformance impact;
- changes to examples or operation catalog;
- whether the change is a consumer request, accepted NEXSIM target, implemented
  capability, or verified support claim; and
- the owning Git commit.

Requested, accepted, implemented, and verified are four different states. The
document must never promote one state to another without evidence.

## 43. Requirement coverage checklist

The following checklist is a compact review index. It does not replace the
normative requirements above.

| Area | Essential consumer outcome |
| --- | --- |
| Capability truth | Know exactly what this build, session, design, and authorization support. |
| Configuration | Reconstruct every semantic build/elaboration/run input and origin. |
| Candidate views | Compile and compare source overlays without silently modifying the workspace. |
| Identity | Refer to semantic objects safely across queries and detect staleness. |
| Provenance | Map every derived fact back to source, expansion, configuration, and build. |
| Build | Separate preprocessing, parsing, analysis, compilation, link, and diagnostics. |
| Elaboration | Inspect selected tops, hierarchy, binds, generates, ports, and opaque boundaries. |
| Static semantics | Query symbols, types, references, processes, constants, and connectivity. |
| Values | Preserve native logic domains, strengths, types, dimensions, and completeness. |
| Scheduler | Observe time, delta, regions, processes, events, updates, and termination cause. |
| Timing/power | Inspect annotations, timing checks, power state, corruption, and their causes. |
| Mixed language | Preserve cross-language identities, conversions, scheduling, and limitations. |
| Causality | Ask why a value/event/process/assertion/framework outcome occurred. |
| Control | Run, pause, stop, step, break, watch, cancel, and budget precisely. |
| Mutation | Use narrowly authorized, preconditioned, audited deposits/forces/faults. |
| Interaction | Invoke only registered typed testbench endpoints with lifecycle and replay controls. |
| Replay | Checkpoint, restore, fork, track randomness, and detect first divergence. |
| UVM | Inspect topology, phases, objections, factory, config, TLM, sequences, RAL, reports. |
| Assertions | Inspect instances, attempts, threads, vacuity, disables, failures, and samples. |
| Coverage | Preserve model, sample, exclusion, merge, provenance, and incompleteness meaning. |
| Traces | Select semantically, query bounded windows, subscribe with backpressure and gap proof. |
| Orchestration | Run exact test/seed/config matrices with structured lifecycle and results. |
| Comparison | Align evidence explicitly and classify first semantic divergence. |
| Reduction | Bisect and minimize while rerunning to prove the failure remains. |
| Scale | Filter, batch, page, stream, cancel, quota, and measure every large operation. |
| Errors | Preserve stable codes, stage, retryability, partial validity, and redaction. |
| Security | Enforce roots, least privilege, isolation, untrusted-input limits, retention, audit. |
| MCP | Project native semantics faithfully through typed, bounded, discoverable operations. |
| Conformance | Back every support claim with versioned, reproducible positive and negative evidence. |
| Evolution | Version schemas and requirements without silently changing meaning. |

## 44. Closing position

The strongest NEXSIM interface would let an engineering agent work at the same
semantic altitude as an expert verification engineer: not merely reading logs,
but navigating design meaning, controlling an exact experiment, observing
scheduler and framework state, tracing causes, reproducing failures, and
building reviewable evidence.

That does not require NEXSIM to know the client's internal architecture. The
shared boundary is a typed simulation contract: stable objects, exact values,
explicit time, observable causes, controlled actions, truthful limitations,
and reproducible evidence.

The native API should remain the durable semantic foundation. MCP can then make
that foundation exceptionally useful to agents—provided it stays faithful,
bounded, secure, and honest about what NEXSIM actually supports.

## 45. Revision history

| Version | Date | State | Summary |
| --- | --- | --- | --- |
| `1.0` | `2026-08-02` | consumer requirements baseline | Initial complete request covering semantic discovery, control, explanation, verification-framework introspection, replay, evidence, MCP projection, security, scale, conformance, and evolution. No NEXSIM implementation or support is claimed. |
