# AXI Manager Rule Matrix Design Probe

Status: design/probe complete; no IAL2 implementation selected.

Task tree:
[docs/tasks/AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE.md](tasks/AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE.md).

Inputs:

- [docs/AXI_VALID_READY_INTENT_PROBE.md](AXI_VALID_READY_INTENT_PROBE.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)
- [docs/AXI_MANAGER_USER_API_BRAINSTORM.md](AXI_MANAGER_USER_API_BRAINSTORM.md)
- [docs/IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md](IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md)

Related implementation-subset selection:
[docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md](AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md).

## Purpose

This note converts the captured AXI source evidence into a first rule
responsibility matrix for a future IAL2 AXI manager. It exists to prevent the
future API from being either too weak, by serializing everything, or too raw,
by pushing AXI legality onto the user.

It is not a shipped feature. It does not select source syntax, parser
behavior, lowering behavior, generated `.isf`, generated `.fsm`, HDL,
assertion text, queue defaults, ID allocation algorithms, or runtime state
machines.

## Classification Legend

| Class | Meaning |
| --- | --- |
| `static` | The rule can be checked against authored declarations or parameters before generated scheduling exists. |
| `scheduler` | The future generated manager/scheduler/scoreboard must enforce the rule while accepting and issuing work. |
| `assertion` | The future generated artifacts should include runtime checks when the rule depends on external behavior or lower-level raw timing. |
| `environment` | The future design must require an authored or reported assumption because AXI does not provide dynamic discovery or fairness by itself. |
| `residue` | The rule is explicitly outside the first bounded manager design unless a later exact owner selects it. |

## Rule Matrix

| Rule family | Source anchors | First responsibility | Easy mode implication | Power / supervised Raw implication | Residue |
| --- | --- | --- | --- | --- | --- |
| Channel transfer contract | `A2.3`, `A2.3.1`, `A2.3.2.1`, `A2.3.2.2` from the Valid-Ready evidence note | `scheduler`, `assertion` | The user submits transactions; the manager owns `VALID` hold, `READY` acceptance, payload stability, and fire-event reporting. | Power can expose timing policy; supervised Raw can expose channel operations only with checks for valid/ready causality and hold behavior. | Wake-up, snoop, credited transport, and broader pipeline-retiming rules remain outside the first manager. |
| Five AXI channel families | `A1.2` from the ID/order evidence note | `scheduler` | Logical reads and writes expand into `AW/W/B` or `AR/R` responsibilities without user-authored channel choreography. | Power may set fields; supervised Raw may inspect or drive lower-level families under checks. | Non-read/write extensions and coherency channels need later owners. |
| Outstanding transaction capacity | `A1.1`, `A1.2`, `A5.1` | `static`, `scheduler` | Easy mode must support multiple pending transactions when configured with more than one slot; full/accepted/status feedback is required when capacity is reached. | Power overrides cannot bypass capacity; supervised Raw must report or assert capacity violations. | No default depth is selected here. |
| ID width and ID presence | `A5.1.1` | `static`, `scheduler` | If the configured ID width cannot support requested concurrency streams, the manager must serialize, queue, or reject according to policy. | Explicit IDs must fit the configured `ID_W_WIDTH` or `ID_R_WIDTH`; zero-width ID configurations cannot claim multi-ID behavior. | Exact width inference and default ID width policy remain future work. |
| ID allocation and user ID validation | `A5.1`, `A5.1.1`, `A5.2`, `B3` | `static`, `scheduler` | Easy mode should allocate IDs or choose legal defaults; users should not need to pick IDs to get concurrency. | Power may specify IDs, but the manager validates uniqueness, same-ID requirements, and class-specific constraints. | Exact allocation algorithm is not selected. |
| Same-ID ordering | `A5.1`, `A5.3`, `A5.3.4`, `A5.3.5`, `A5.3.6`, `A5.3.8`, `A5.5`, `A5.6` | `scheduler`, `assertion` | Same-ID requests and responses need per-ID ordering queues; the manager must preserve issue-order response expectations instead of handing this to the user. | Power may intentionally reuse an ID for ordering; supervised Raw should still emit checks when ordering is externally observable. | Full Device/Normal, cacheability, shareability, and early-response ordering remain residue. |
| Different-ID concurrency and interleaving | `A5.1`, `A5.3`, `A5.6.1` | `scheduler`, `assertion` | Easy mode may issue different IDs concurrently and must match/reassemble responses so the user sees tagged completions. | Power can expose explicit streams; supervised Raw must report when user timing assumes FIFO return across different IDs. | Coherency and transaction classes outside the first read/write subset remain residue. |
| Ordering-required gaps | `A5.3`, `B3` | `scheduler` | If the user requests ordering that AXI does not otherwise guarantee, the manager must wait for the earlier response before issuing the later request. | Power can request stronger ordering; the manager enforces by stalling, queuing, or rejecting. | Exact user syntax for ordering requirements is not selected. |
| Write response matching | `A5.1.1`, `A5.5` | `scheduler`, `assertion` | Completion for a write must be associated with the submitted write by `BID`/`AWID` and user tag. | Power/supervised Raw should not be able to treat a mismatched `BID` as a valid completion. | Error response policy is not selected. |
| Read data matching and ordering | `A5.1.1`, `A5.6`, `A5.6.1` | `scheduler`, `assertion` | Completion for a read must be associated with `RID`/`ARID`; multi-ID read data needs interleaving-aware collection. | Power may expose IDs and bursts; supervised Raw must not assume read data returns as a single global FIFO. | Read-data chunking and exact burst assembly remain future work. |
| Write data sequencing | `A5.5` | `scheduler`, `assertion` | The manager owns legal write-data order relative to accepted write requests. | Power may expose write-data policy only within source-anchored constraints. | Resource Plane credited-transport relaxation remains residue. |
| Read interleaving capability | `A5.6.1` | `static`, `scheduler`, `environment` | If interleaving is disabled by configuration, the manager must constrain issue or collection accordingly; otherwise it must accept interleaved data for different IDs. | Power users may request stream behavior, but the capability/disable property still controls legal scheduling. | Exact property spelling and discovery source are future design work. |
| Unique-in-flight indicators | `A5.2`, `B3`, `A6.4.4` | `static`, `scheduler`, `assertion` | Easy mode should hide ordinary unique-ID bookkeeping and report only capacity or unsupported-transaction feedback. | Power explicit IDs must be validated against unique-in-flight and same-ID requirements. | Atomic and other B3 transaction families are not first-manager scope unless later selected. |
| Interconnect ID remapping | `A5.3.6`, `A5.4` | `residue` for first manager; later `scheduler`, `assertion` if owned | A single-manager endpoint API should not require users to understand appended manager bits. | A future interconnect/proxy profile must preserve original ordering and route `BID`/`RID` back to the correct manager. | Full interconnect behavior is outside the first manager rule matrix. |
| Subordinate behavior and read-data reordering depth | `A5.3.5`, `A5.6` | `environment`, `assertion` | Easy mode needs declared capability assumptions for attached subordinate behavior; the manager cannot dynamically discover read-data reordering depth. | Power may expose explicit capability declarations; supervised Raw should assert violations against declared capability. | Full subordinate compliance proof is outside the manager. |
| Transaction-class constraints | `B3`, `A6.4.4` | `static`, `scheduler`, `residue` | Unsupported transaction classes should fail closed or be reported as unsupported rather than partially modeled. | Power can only expose transaction classes whose ID constraints are in the owned rule table. | Atomics, exclusives, Prefetch, WriteZero, WriteDeferrable, InvalidateHint, MTE-tag transport, UnstashTranslation, ACT, DVM, StashOnce, translation, and StashTranslation remain residue for first design. |

## API Consequences

The matrix preserves the earlier API direction:

- Easy mode is not a limited mode. It can use multiple pending transactions
  when configured capacity, ID width, ordering requirements, and subordinate
  assumptions allow it.
- Easy mode must expose flow-control feedback, not protocol internals. The
  useful feedback families are accepted/full/pending/slots and a structured
  block reason such as `max_pending_reached`, `id_busy`,
  `unique_id_required`, `same_id_required`, `ordering_wait_required`,
  `read_interleaving_disabled`, or `unsupported_transaction_kind`.
- Power mode can expose transaction fields and explicit IDs, but those fields
  remain validated by the same rule matrix.
- Supervised Raw mode can expose lower-level channel activity only with a
  report of which static checks, scheduler protections, runtime assertions,
  and environment assumptions remain active.

## First-Implementation Gate

A future implementation leaf should not start until it selects all of these:

- the exact first subset, for example Valid-Ready only, assertion/report only,
  or a narrow read/write manager subset,
- the authored source surface and profile/container spelling,
- the generated IAL1 `.isf` review artifact shape,
- the generated IAL0 `.fsm` review artifact shape,
- the schedule/report contract for rule classifications and residue,
- the focused tests proving accepted, queued, blocked, matched, interleaved,
  and fail-closed cases,
- and the mdBook chapter that explains the shipped behavior without requiring
  codebase inspection.

## Current Conclusion

The first rule matrix confirms that the future AXI manager can make AXI
concurrency easy without hiding AXI legality. The manager should own IDs,
outstanding windows, ordering queues, response matching, interleaving policy,
and flow-control feedback across Easy, Power, and supervised Raw levels.

The first implementation subset is now selected in
[docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md](AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md):
a source-anchored AXI Valid-Ready channel contract/monitor that proves the
IAL2-to-IAL1-to-IAL0 chain before the full manager is attempted. Code and
tests still require a later exact implementation owner.
