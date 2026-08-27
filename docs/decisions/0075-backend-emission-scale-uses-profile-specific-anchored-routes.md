# 0075 — Backend-emission scale uses profile-specific anchored routes

- Date: 2026-08-21
- Type: verification architecture/scalability
- Status: selected by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.1`; portable-SystemVerilog evidence revised by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.4`
- Refines: [0055](0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md), [0056](0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md), [0072](0072-an-unreachable-declared-cap-is-a-result-not-a-level-to-rewrite.md)
- Repair owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2`
- Generator owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3`
- Portable-SystemVerilog revision-2 owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.4`

## Context

`backend_emission_v1` originally selected gate and qualification only by an
`upstream_workload_level` string. That string does not name one canonical
ExecutionIR: `execution_graph_v1` has thirteen independent axes, and several of
their advertised levels stop at an earlier parser, bridge, or plan cap. The
four emitters also do not share one supported semantic surface. Portable
SystemVerilog and portable VHDL render all operations in the checked AHB plan;
the OSVVM profile wraps the portable VHDL graph; native UVM intentionally emits
only its selected review-gallery matrix.

The common scale route therefore starts with the checked AHB reference VIAL and
HIAL, then inserts a literal repeat of the existing response expectation
immediately before `scoreboard_check`. The expanded operation total is the
profile-local independent variable `T`. This preserves the transaction, public
start, fixed random decision, models, scoreboard, coverage, fault, and declared
probe used by all portable negotiations. It traverses the ordinary parser,
checked-AHB `PlanBuilder`, and canonical ExecutionIR; it is not a caller-created
plan or padding source.

Bounded probes selected these exact outcomes. A tuple in the portable columns
is `artifacts/sources, source bytes, source-map entries, visible static checks`.

| Profile | Reference | Gate candidate | Qualification candidate | Limit | First excess |
| --- | --- | --- | --- | --- | --- |
| portable SystemVerilog (oracle revision 2) | `T=21`: `8/3, 164,507, 54, 0` | `T=1,024`: `8/3, 2,803,857, 1,057, 0` | `T=4,096`: `8/3, 10,910,865, 4,129, 0` | `T=6,318`: `8/3, 16,774,723, 6,351, 0` | `T=6,319`: `VIAL_BACKEND_LIMIT_EXCEEDED` at `/artifacts`, no artifacts; pre-cap size `16,777,362` |
| portable VHDL | `T=21`: `17/6, 118,064, 59, 21` | `T=128`: `17/6, 176,433, 166, 21` | `T=512`: `17/6, 388,401, 550, 21` | `T=29,506`: `17/6, 16,777,107, 29,544, 21` | `T=29,507`: `VIAL_VHDL_BACKEND_LIMIT_EXCEEDED` at `/artifacts`, rendered size 16,777,675 |
| OSVVM 2026.05 | `T=21`: selected `16/7, 122,415, 66, 12+21` after repairs | `T=128`: selected `16/7, 180,784, 173, 12+21` | `T=512`: selected `16/7, 392,752, 557, 12+21` | `T=29,506`: selected `16/7, 16,781,458, 29,551, 12+21` | `T=29,507`: portable-foundation byte rejection, no wrapper artifacts |
| native UVM review profile | `T=21`: `16/10, 138,345, 75, 14` | `T=22`: selected negotiation rejection after repair | preflight-dominated by `T=22` | preflight-dominated; backend byte/map caps are unreachable in the selected matrix | preflight-dominated; no artifact graph |

### Portable-SystemVerilog oracle revision 2 (2026-08-24)

The original portable-SystemVerilog table was exact at its `5d309b0eb`
freeze. Later correctness repairs `1e9ab0e61` (backward logical-phase
rollover) and `69384201c` (direct-drive lowering and finalization) changed the
generated scheduler source without revising the scale oracle. The mismatch is
therefore stale evidence, not renderer nondeterminism and not authority to
remove the repairs.

Fresh ordinary Parser, checked-AHB bridge, public `PlanBuilder`, and backend
emission independently regenerated every portable level twice. Reference
grows by 414 bytes; gate and qualification each grow by 532 bytes. This
different delta disproves a fixed padding explanation. The accepted adjacent
shape is now `T=6,318`, 2,493 bytes below the unchanged 16-MiB source cap;
`T=6,319` renders 16,777,362 source bytes before the cap and rejects atomically
because it is 146 bytes over. The accepted fixture-source identities are:

| Level | Fixture bytes | Fixture SHA-256 |
| --- | ---: | --- |
| reference | 106,181 | `1839aae7d65c3394442a4b26538b9ea73ab35ae142ca32e29177775919d0f730` |
| gate | 2,745,531 | `ec5a91968cea2bb5f88994188517cc8b506bf49d6a4ec984fc6b0ad4ee367481` |
| qualification | 10,852,539 | `d7087673e824dc18e6a91d7a41f819483428650049fc92a0bd28e3a1737065e8` |
| limit | 16,716,397 | `f05f90e1a730b187e2eb6f2f15925c92b1a5f4a6dd12268d705297410dc7eb21` |

Conditional zero-overhead emission is not a valid way to preserve the former
boundary. The renderer already emits rollover statements only when the
operation topology crosses a backward logical-phase boundary, and the
expanded checked-AHB route contains that real transition. Removing it would
restore the semantic defect. Shortening generated diagnostics or comments
only to recover 146 bytes would couple the qualification boundary to cosmetic
text and conceal the first genuine cap excess. Revision 2 instead keeps the
cap and corrected semantics unchanged, changes the portable artifact-oracle
discriminator to `portable_sv_artifact_graph_v2`, and publishes schema
`fsmgen.vial_architecture_scale_backend_emission_portable_sv_oracle.v2` with
version `2`. The common five role labels remain stable because portable VHDL,
OSVVM, and native UVM share them; the versioned profile oracle carries the
portable evidence compatibility break.

The portable-VHDL reference above uses the selected generated scale source name.
The checked repository fixture itself emits 118,062 bytes; the two-byte
difference is source-location text, not semantic or renderer instability. The
OSVVM source totals add its fixed 4,351-byte adapter to those six portable
sources. Its `12+21` check notation means twelve wrapper checks are visible in
the OSVVM result and successful completion of the portable emitter's 21
checks is a required internal prerequisite.

### Portable-VHDL trace-v2 refinement (2026-08-27)

Decision `0090` atomically adds a compact authenticated sample snapshot to the
generated portable-VHDL fixture and one structural check proving exactly one
catalogued snapshot call per inactive-edge sample barrier. The fixed source
increase is 1,504 bytes; it does not grow per anchored operation. Fresh direct
emission therefore refines the portable six-source 16-MiB boundary by two
operations, from the historical 29,508/29,509 pair to 29,506/29,507. The
accepted 29,506 graph is 16,777,107 bytes with 29,544 maps; 29,507 renders
16,777,675 bytes and rejects atomically. OSVVM inherits the same portable-
foundation boundary and adds its unchanged 4,351-byte adapter only after that
foundation succeeds. This is a versioned structural-oracle refinement, not a
performance, runtime-capacity, or support regression.

Selection found four defects that had to be repaired before the table could be
consumed:

1. `VHDLPortableStaticValidator` performs four fixed whole-metadata census
   scans plus three whole-metadata regex scans for each operation. At `T=512`
   validation takes about 70.5 seconds, and `T=1,024`
   exceeds the selected 300-second emission ceiling while remaining CPU-bound.
   Implementation audit also finds that `_source_map_entries` calls
   `_find_line` once per operation, and each call splits and scans the complete
   metadata source; the accepted emission would otherwise move from one
   quadratic blocker to another. The same repair leaf therefore owns bounded
   single-pass metadata and line-anchor indexes.
   Direct use of the trace-v2 renderer proves 29,506/29,507 as the adjacent
   byte boundary, and the actual emitter rejects 29,507 before static
   validation. The accepted boundary must be rerun after the validator is made
   linear without weakening its now-21-check structural contract.
2. The OSVVM wrapper copies six portable source files to new relative paths but
   discards their detailed portable source-map entries. Its current thirteen
   entries are seven adapter mappings plus six whole-file placeholders. The
   selected complete closure is every translated portable entry plus the seven
   adapter entries: 66 at reference, 173 at gate, 557 at qualification, and
   29,551 at the selected limit.
3. Every OSVVM emission recursively re-verifies fourteen provider repositories
   across a current 2,122-file materialization before entering the portable emitter. Repeating
   that immutable prerequisite for every level exceeded the same 300-second
   ceiling. One exact verification must be reusable within a sealed generator
   evaluation without allowing a caller to forge it or converting provider
   identity into VHDL execution evidence.
4. Native-UVM negotiation accepts added expectations that the renderer never
   evaluates. At `T=22`, the source graph and byte count remain identical to
   reference while only a coarse source-map association mentions the new
   expectation. The support contract explicitly nonclaims complete UVM emission
   and scale, so negotiation must reject the first expanded shape rather than
   advertise fixed output as scale. The otherwise reachable plan boundary at
   48,274/48,275 operations is falsification evidence only, not a selected
   native-UVM route.

One catalog defect is independent of those behaviors. The portable SV entry's
`backend_artifacts_base => 3` is not an exact total inventory; OSVVM calls six
portable sources plus one generated adapter “generated provider sources”; and
the native-UVM catalog omits its enforced one-million-entry source-map cap.
OSVVM's 16-MiB value applies to the six-source portable foundation, not to the
seven-source wrapper total, which may exceed it by the fixed adapter size.

Repair leaf `.17.2.6.2.1` closes item 1 with one exact metadata index and one
source-line/end-column index per emitted source. Its guarded executable watcher
accepts `T=29,506` twice at 16,777,107 source bytes/29,544 maps with all 21
checks passing and retains the exact atomic `T=29,507` rejection. Leaf
`.17.2.6.2.2` closes item 3 with one callback-scoped lexical capability: entry
verifies the exact provider root once, matching local emissions receive
defensive result clones, and callback completion invalidates every retained
handle. Source mismatch, caller forgery, stale reuse, and consumer failure all
fail closed without publishing artifacts. Leaf `.17.2.6.2.3` closes item 2 by
validating the portable map's schema, artifact digests, source identities,
line/column bounds, and complete six-source coverage, then translating all 59
ordered entries to wrapper paths and identities after the seven unchanged
adapter entries. Reference closure is now the selected 66 entries; malformed
portable evidence publishes no wrapper artifacts. Leaf `.17.2.6.2.4` closes
item 4 with one exact reference-shape predicate over operation count and order,
scenario partition, fiber bounds, resource count, and expectation roles. T=22,
larger shapes, and a different 21-operation shape now reject at negotiation
with no artifact graph. Leaf `.17.2.6.2.5` closes the catalog defect with one
defensively cloned, closed four-profile authority set shared by workload
construction and VHDL/native-UVM discovery. Portable SV now names its complete
3-source/8-artifact inventory; OSVVM separates six portable sources, one fixed
adapter, and the provider while naming the portable-only byte authority and 66
reference maps; native UVM records its enforced one-million-map cap beside the
exact selected matrix. Unknown, missing, obsolete, or contradictory fields
fail closed. The guarded five-repair family passes before generator activation.

## Decision

1. **Use the anchored operation recipe only where emission is complete for that
   shape.** Portable SV, portable VHDL, and OSVVM own the exact `T` levels in the
   table. Native UVM owns reference emission plus exact fail-closed evidence at
   its adjacent unsupported shape; larger levels report
   `preflight_dominated` / `not_constructed` and carry no downstream identity.
2. **Make structural authority exact and profile-local.** Every accepted result
   proves sorted artifact inventory and relative paths, exact source count and
   byte total, source hashes, complete generated-line-to-canonical-source-map
   closure, generated identifier bounds, static-check inventory, manifest
   consistency, and a byte-equal independent rerun. “Generated bytes” always
   names the precise source set to which a cap applies.
3. **Keep the earliest authority.** Portable SV revision 2 rejects at 6,319 operations;
   VHDL and OSVVM reject at the portable six-source boundary of 29,507;
   native UVM rejects negotiation at 22. An over-limit result must contain the
   exact diagnostic and no artifacts, operation identity, or staging residue.
   An earlier result is not relabelled as a backend capacity measurement.
4. **Repair before generating.** `.17.2.6.2` separately owns linear VHDL
   validation and accepted-boundary proof, reusable sealed OSVVM provider
   preflight, translated OSVVM source maps, native-UVM closed negotiation, and
   final catalog/support/decision alignment. `.17.2.6.3` may consume no profile
   until all selected repair leaves close.
5. **Keep identity limits distinct.** VIAL accepts a 128-byte source identifier
   and rejects 129 bytes. At the accepted edge, the longest generated
   identifiers are 131 bytes for portable SV, 142 for portable VHDL and OSVVM,
   and 154 for native UVM; all remain below each backend's 255-byte generated
   identifier cap. The fixed OSVVM adapter's own maximum is 34 bytes.
6. **Keep emission pure and staging separate.** The four emitter entrypoints
   return in-memory artifact graphs and do not create their repository-relative
   `artifact_root`. The generator later owns content-addressed staging beneath
   `.artifacts/tmp/vial-scale/`, exact success/failure cleanup, and consumer-
   failure cleanup. No external compiler, simulator, or runtime executes here.
7. **Retain all nonclaims.** These fixtures do not claim supported capacity,
   performance, whole-product `big`/`really_big`, full-language coverage,
   native-UVM runtime, OSVVM provider compilation, synthesis, mixed-language
   behavior, or general cross-backend parity.

## Claim verification

- **Re-derivation:** the selected counts come from fresh canonical
  parser/bridge/PlanBuilder/emitter executions, independent source-byte and
  source-map censuses, private-renderer boundary calculation where the known
  validator defect prevents completion, and exact source inspection for each
  defect.
- **Falsification:** adjacent 6,318/6,319, 29,506/29,507, 128/129-byte
  identifier, and native-UVM 21/22 witnesses challenge the selected boundary.
  The 48,274/48,275 native-UVM plan route additionally disproves any claim that
  its generated byte or map cap was reached.
- **Durability:** all four backend behavior repairs plus catalog/support
  alignment have RED controls and continuing exact watchers. The shared
  authority module, support projections, decision, Knowledge Map facts,
  task-tree evidence, and synchronized mdBook retain the repaired facts. Only
  the canonical scale generator remains proposed `.17.2.6` work.

## Consequences

- `backend_emission_v1` becomes a closed profile recipe rather than an
  ambiguous reference to another family's level name.
- The portable profiles receive exact reachable candidate and adjacent-cap
  outcomes; native UVM remains honestly restricted to its selected gallery.
- OSVVM's adapter and provider are represented as separate authorities instead
  of being counted as seven generated provider sources or silently folded into
  the portable byte cap; catalog and discovery project one shared exact source.
- No emitter, runtime, public API, support, performance, or capacity behavior
  changes in this selection slice.
