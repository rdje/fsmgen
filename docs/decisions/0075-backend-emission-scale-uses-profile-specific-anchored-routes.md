# 0075 — Backend-emission scale uses profile-specific anchored routes

- Date: 2026-08-21
- Type: verification architecture/scalability
- Status: selected by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.1`
- Refines: [0055](0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md), [0056](0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md), [0072](0072-an-unreachable-declared-cap-is-a-result-not-a-level-to-rewrite.md)
- Repair owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2`
- Generator owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3`

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
| portable SystemVerilog | `T=21`: `8/3, 164,093, 54, 0` | `T=1,024`: `8/3, 2,803,325, 1,057, 0` | `T=4,096`: `8/3, 10,910,333, 4,129, 0` | `T=6,319`: `8/3, 16,776,830, 6,352, 0` | `T=6,320`: `VIAL_BACKEND_LIMIT_EXCEEDED` at `/artifacts`, no artifacts |
| portable VHDL | `T=21`: `17/6, 116,560, 59, 20` | `T=128`: `17/6, 174,929, 166, 20` | `T=512`: `17/6, 386,897, 550, 20` | `T=29,508`: selected `17/6, 16,776,739, 29,546, 20` after validator repair | `T=29,509`: `VIAL_VHDL_BACKEND_LIMIT_EXCEEDED` at `/artifacts`, rendered size 16,777,307 |
| OSVVM 2026.05 | `T=21`: selected `16/7, 120,911, 66, 12+20` after repairs | `T=128`: selected `16/7, 179,280, 173, 12+20` | `T=512`: selected `16/7, 391,248, 557, 12+20` | `T=29,508`: selected `16/7, 16,781,090, 29,553, 12+20` | `T=29,509`: portable-foundation byte rejection, no wrapper artifacts |
| native UVM review profile | `T=21`: `16/10, 138,345, 75, 14` | `T=22`: selected negotiation rejection after repair | preflight-dominated by `T=22` | preflight-dominated; backend byte/map caps are unreachable in the selected matrix | preflight-dominated; no artifact graph |

The portable-VHDL reference above uses the selected generated scale source name.
The checked repository fixture itself emits 116,558 bytes; the two-byte
difference is source-location text, not semantic or renderer instability. The
OSVVM source totals add its fixed 4,351-byte adapter to those six portable
sources. Its `12+20` check notation means twelve wrapper checks are visible in
the OSVVM result and successful completion of the portable emitter's twenty
checks is a required internal prerequisite.

Four defects prevent the table from being consumed immediately:

1. `VHDLPortableStaticValidator` performs four whole-metadata regex scans for
   each operation. At `T=512` validation takes about 70.5 seconds, and `T=1,024`
   exceeds the selected 300-second emission ceiling while remaining CPU-bound.
   Direct use of the unchanged renderer proves 29,508/29,509 as the adjacent
   byte boundary, and the actual emitter already rejects 29,509 before static
   validation. The accepted boundary must be rerun after the validator is made
   linear without weakening any of its twenty checks.
2. The OSVVM wrapper copies six portable source files to new relative paths but
   discards their detailed portable source-map entries. Its current thirteen
   entries are seven adapter mappings plus six whole-file placeholders. The
   selected complete closure is every translated portable entry plus the seven
   adapter entries: 66 at reference, 173 at gate, 557 at qualification, and
   29,553 at the selected limit.
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
3. **Keep the earliest authority.** Portable SV rejects at 6,320 operations;
   VHDL and OSVVM reject at the portable six-source boundary of 29,509;
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
- **Falsification:** adjacent 6,319/6,320, 29,508/29,509, 128/129-byte
  identifier, and native-UVM 21/22 witnesses challenge the selected boundary.
  The 48,274/48,275 native-UVM plan route additionally disproves any claim that
  its generated byte or map cap was reached.
- **Durability gap:** this decision, the matching Knowledge Map fact, the active
  task-tree owner, and the synchronized mdBook retain the selection and its
  gap, but the exploratory probe is not a tracked producer or continuing
  watcher. Active `.17.2.6` owns that missing executable durability: repair
  tests must first add RED controls, and `.17.2.6.3` must add the canonical
  generator/watchers before the figures can become durable derived gates.

## Consequences

- `backend_emission_v1` becomes a closed profile recipe rather than an
  ambiguous reference to another family's level name.
- The portable profiles receive exact reachable candidate and adjacent-cap
  outcomes; native UVM remains honestly restricted to its selected gallery.
- OSVVM's adapter and provider are represented as separate authorities instead
  of being counted as seven generated provider sources or silently folded into
  the portable byte cap.
- No emitter, runtime, public API, support, performance, or capacity behavior
  changes in this selection slice.
