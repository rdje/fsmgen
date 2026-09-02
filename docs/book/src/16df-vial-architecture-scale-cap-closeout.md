# Architecture-Scale Cap Closeout

Task-tree leaf `.17.4.8` owns the final cross-family proof for the resource-cap
policy selected by [decision 0093](../../decisions/0093-architecture-scale-caps-are-component-ceilings-with-explicit-route-authority.md).
This work does not raise or lower a cap, promote a support statement or budget,
or turn component defenses into whole-product capacity claims.

## What the live policy already proves

`FSM::VIAL::ArchitectureScaleCapPolicy` rebuilds the workload catalog and the
declaring parser, semantic, bridge, execution, and backend authorities. The
inventory audit found a complete one-group join for every selected workload
axis, retained interactions and non-axis envelopes, the backend/runtime
profile split, and an existing path for every referenced evidence owner. The
focused mutation watcher rejects a missing axis, rewritten workload level, or
caller mutation. The reverify command below derives the current counts instead
of asking readers to trust duplicated point-in-time numerals.

That is necessary alignment evidence, but it is not the final closeout proof.
The policy exposes candidate witnesses without assigning them to closeout
dimensions. The separate consistency authority now joins the independently
reviewed runtime-stream, backend-artifact, checking-model, checking-fault,
checking-randomness, and checking-scoreboard witnesses to explicit dimensions.
The checking-coverage, bridge-profile, serialized-bridge-manifest,
normalized-bridge-collection, execution-profile-selection, and
execution-operation-cardinality, execution-fiber-cardinality,
execution-route-collection, execution-random-attempt, and
execution-serialized-plan witnesses are now joined too. Semantic-parser
admission, semantic-declaration cardinality, semantic-action cardinality and
shape, semantic-repeat layering, and semantic-service scalars are now joined
as well. Semantic-type shape completes the selected group classification; no
group remains pending independent verification.

## Why calibration publication is separate

The immutable calibration closure remains measurement evidence. Its publisher
revision predates the cap-hardening leaves, and its public nonclaims explicitly
include `cap_implementation`. Byte-valid measurement files therefore cannot be
relabelled as proof that the current caps fail atomically or clean up exactly.

The closeout layer consumes the current cap policy internally, rejects
caller-supplied evidence, and keeps two questions separate:

- Is the historical measurement publication still internally authentic?
- Does current code satisfy every selected cap's boundary, adjacent excess,
  diagnostic, atomicity, no-tool, cleanup, and accepted-identity contract?

Only after the second answer is complete may `.17.4.8` disposition the
historical publication. The current authority reaches that prerequisite with
all 23 groups and all 161 required group dimensions verified.

The immutable store is not one uniform target. Its 256 files/32,007,521 bytes
split into three disjoint sets: 232 artifacts/28,398,586 bytes selected by the
closure, 22 backend-emission-v1 files/2,232,452 bytes preserved after the
explicit v2 namespace transition, and the two closure files/1,376,483 bytes.
`FSM::VIAL::ArchitectureScaleCalibrationDisposition` authenticates the selected
set and runs current derivations in a bounded worker before disposition. Its
first exact RED rejects six of the 52
bridge-fanout profiles. Each stale profile recorded a fully materialized
source-map count such as 114,909; current code intentionally stops before
constructing record 65,537. Commit `4834873a8` introduced that safer
pre-materialization admission after publication. All 56 semantic-catalog
profiles remain valid. Consequently, “232 selected artifacts” is not the same
as “232 current artifacts.” [Decision 0095](../../decisions/0095-calibration-closure-versions-atomically-after-current-validator-drift.md)
therefore versions the complete closure-selected lineage atomically instead of
calling the individually unchanged files current.

The guarded census also distinguishes the rest of the closure. Execution/
checking, portable-SystemVerilog runtime, and balanced-portable publications
still validate. Backend emission, portable-VHDL runtime, and OSVVM runtime each
reject their first VHDL-derived reference witness. The closure predates both
the 127-byte scenario-cycle correction in `460df366e` and the 112-byte boundary-
time correction in `0b6e83979`. Only generated
`base_output_arbitration_tb.vhd` changes, from 46,264 to 46,503 bytes; total
portable VHDL source changes from 118,064 to 118,303 bytes while the source-map
count stays 59. The artifact graph and backend evaluation therefore change,
followed by portable-VHDL materialization
`7c44198d…` → `6f12ab75…` and OSVVM materialization
`6ce4f9a1…` → `5cef115e…`. The authored 4,986-byte VIAL source remains
byte-identical.

The authority authenticates v1 as explicitly versioned, superseded evidence;
running the v2 producer against it would conflate two deliberately different
revisions. It revalidates all 108 semantic/bridge profiles, requires 102 exact
matches, and binds the other six source-map diagnostic changes plus their
historical/current projection-byte counts. It independently derives the exact
239-byte VHDL source delta, unchanged 59-map count, graph/evaluation identities,
and both downstream materialization pairs. It then requires pairwise
disjointness and the exact three-set union. Its role remains
`historical_measurement_only`; candidate budgets remain candidate-only and cap
implementation, support, capacity, and public performance claims remain
prohibited or unestablished. A new immutable capture is required before the
data can support future current-performance use, but not for current cap
closeout.

The default test checks the caller-sealed API, incomplete-cap barrier,
canonical closure mismatch, overlap, extra-path, and defensive-report
falsifiers. The exact route authenticates the complete publication,
reconstructs the expected current drift, and validates the historical
disposition:

```sh
scripts/run_with_ram_guard.sh -- env \
  FSMGEN_VIAL_SCALE_CALIBRATION_DISPOSITION_EXACT=1 \
  prove -Iperl \
  t/1764-vial-architecture-scale-calibration-disposition.t
```

## Machine-enforced closeout state

`FSM::VIAL::ArchitectureScaleCapConsistency` is the separate closeout owner.
It accepts no policy or evidence input: the exact class rebuilds the live cap
policy internally and emits every selected group, its axes, declared
authority, implementation leaf, diagnostic families, and candidate evidence.
Each group must contain the same closed dimension set: boundary, adjacent
excess, diagnostics, atomicity, no-tool behavior, cleanup, and accepted
identity.

Runtime, backend, checking-model, checking-fault, checking-randomness,
checking-scoreboard, checking-coverage, bridge-profile-cardinality, serialized
manifest, normalized-collection, execution-profile-selection, and
execution-operation-cardinality, execution-fiber-cardinality,
execution-route-collection, execution-random-attempt, and
execution-serialized-plan, semantic-parser-admission, semantic-declaration-
cardinality, semantic-action-cardinality, semantic-action-shape, and semantic-
repeat-layering, semantic-service-scalar, and semantic-type-shape groups are
`verified` across all seven dimensions.
Runtime covers the selected materialization profiles plus t1720 through t1749
and t1751 through t1762.
Backend covers t1646 through t1650 and t1716 through t1719. Checking models
uses t1630 for exact model-instance/scalar-cell limits, provider-free state
evaluation, and cleanup; t1711 independently proves compact preflight order
and absence of partial ExecutionIR or plan. Checking faults uses t1633 for its
exact limit, lifecycle oracle, and cleanup; t1714 independently proves compact
preflight order and absence of partial ExecutionIR or plan. Each test is listed
once and mapped only to the dimensions it proves. Randomness uses t1634 for the
exact accepted/adjacent plan-byte route pair, nominal/adjacent occurrence-cap
outcomes already detailed in the verification-architecture chapter, replay,
and cleanup; t1715 independently proves compact occurrence preflight.
Scoreboards preserve their layered authority: t1631 proves both exact selected
axes through a provider-free complete-transaction FIFO oracle and owns cleanup;
t1690 independently proves semantic scalar capacity admission and its adjacent
failure before reference resolution; t1712 proves compact normalized-path
preflight, accepted plan identity, and both adjacent execution excesses before
scoreboard normalization, but is not boundary evidence. Coverage is similarly
layered: t1632 proves the exact static domain, packed-vector oracle, cleanup,
and lower source-byte route authority; t1691 proves semantic scalar admission;
t1713 proves compact normalized-path excess and identity but is not boundary
evidence. Bridge-profile cardinality uses t1602's exact single-unit/domain
limit and adjacent excess, deterministic manifest/report identities, and
same-volume cleanup. The strengthened witness also requires unset backend/tool
selectors and no rejected metrics or manifest/report identity.
The serialized-manifest join keeps the enclosing route and terminal authority
distinct. T1602 proves the exact provider-free workload ladder, cleanup, and
repeatable identities. T1704 observes canonical encoding only after structural
and uniqueness validation: 16,777,216 bytes pass, while the first complete
valid record above the cap encodes to 16,777,219 bytes and returns the stable
manifest-root diagnostic with no partial manifest or report.
Normalized collections retain a different split. T1602 alone proves every
selected collection's exact limit ladder, provider-free construction, cleanup,
and workload identities. T1694 through t1703 each prove one collection's first
constructible excess, stable normalized path and diagnostic, atomic rejection,
and representative accepted identity. They are deliberately not exact-boundary,
no-tool, or cleanup evidence. The backend-binding witness preserves its
multi-binding first-excess shape rather than claiming single-record adjacency;
the source-map witness additionally stops before constructing the first excess
record.
Execution-profile selection requires five complementary witnesses. T1603
freezes the exact fixed-scalar catalog and rejects every unowned two-selection
shape at the caller-sealed generator. T1616 proves a deterministic 512-scenario
qualification plus same-volume cleanup; t1617 admits the exact 4,096-scenario
limit; t1618 atomically rejects 4,097 with no metrics, ExecutionIR, or plan; and
t1705 proves the ordinary one-fixture/unit/domain resource summary before
defensive second-unit/domain rejection. Construction and invocation shapes
explicitly carry no backend, provider, or tool selector.
Operation cardinality requires six complementary witnesses. T1619 owns the
accepted per-scenario qualification, exact plan identity, and same-volume
cleanup. T1620 and t1621 preserve the exact component boundary's later
plan-byte dominance and the first semantic excess. T1622 and t1626 preserve
the aggregate qualification, exact compact preflight, first aggregate excess,
and preflight-dominated route without pretending a final plan was built.
T1706 independently admits the compact exact boundary and rejects the first
excess before bridge indexing. Every workload and ordinary invocation shape
explicitly carries no backend, provider, or tool selector.
Fiber cardinality requires three complementary witnesses. T1623 freezes both
accepted qualification plans and owns same-volume success/failure cleanup.
T1624 admits exactly 16,384 simultaneously live fibers and atomically rejects
16,385 before bridge indexing. T1625 admits the 65,536-total-fiber component
preflight even though the later serialized-plan cap rejects that route, then
atomically rejects the 65,537-fiber structural excess before bridge indexing.
All three workload shapes explicitly select no backend or external tool.
Route collections require eight deliberately layered witnesses. T1603, t1606,
and t1607 own accepted binding, type, and source-map gate plans plus same-volume
success/failure cleanup. Their exact reachable boundaries differ: t1628 admits
2,054 bindings before 2,055 crosses the bridge event cap; t1627 admits 1,043
types before 1,044 crosses serialized bridge bytes; and t1607 admits 46,294
source maps before 46,295 crosses serialized plan bytes. T1707/t1708 retain
exact local type-table/source-map component admission and first excess before
payload cloning or insertion; t1709 rejects compactly known binding excess
before binding construction. These route results do not lower the larger
component ceilings. All accepted gate constructions and layered route
rejections select no backend or external tool.
Random attempts retain an exact three-witness authority. T1614 admits the
1,000,000-attempt boundary at zero-based attempt 999,999 and freezes the
construction, decision, generated plan, replayed plan, and evaluation
identities; it also owns same-volume success/failure cleanup. T1615 rejects
the 1,000,001-attempt adjacent excess with the exact random diagnostic and no
partial ExecutionIR, plan, or metrics. T1710 independently proves that the
same exhaustion occurs during random projection before serialized-plan
preflight or any final materializer. The lower 262,144-attempt t1613
qualification remains a useful regression but is superseded for this closeout
join by t1614's stronger boundary proof. Accepted and rejected workload shapes
select no backend or external tool.
Serialized plans require three complementary witnesses. T1611 admits the exact
16,777,216-byte canonical plan, freezes its content-derived identity and closed
evaluation, and owns no-tool plus same-volume success/failure cleanup. T1612
owns the first complete valid excess and public plan-root diagnostic. T1634
independently rejects before random-decision, ExecutionIR, plan, or report
materialization and preserves replay-route identity and cleanup. The lower
one-MiB t1609 and four-MiB t1610 ladders remain regressions but are superseded
for this closeout join by t1611's exact-cap proof.
Parser admission uses the exact three-witness policy inventory. T1601 closes
all semantic workload axes and levels, proves provider-free construction plus
same-volume cleanup, and freezes accepted gate identities. T1687 admits 64
direct imports and rejects 65 before recursive parsing. T1693 admits the
1,048,576-byte per-source and 16,777,216-byte combined-source boundaries, then
rejects each first byte excess before lexing. Both focused rejection witnesses
retain stable diagnostics and publish no partial semantic report.
Declaration cardinality retains its deliberately asymmetric two-witness
authority. T1601 admits exactly 1,024 fixtures and rejects 1,025 through the
closed semantic matrix; every expected rejection now explicitly publishes no
semantic-projection, semantic-report, or format identity. T1689 independently
admits exactly 4,096 declarations and rejects 4,097 before parsing a malformed
later section. Together they retain stable diagnostics, provider-free shape,
same-volume cleanup, and deterministic accepted identities without inventing
a redundant third witness.
Action cardinality is deliberately asymmetric too. T1601 alone admits exactly
65,536 expanded actions, rejects 65,537 through the generated catalog route,
and owns provider-free construction, same-volume cleanup, accepted identities,
and absence of partial semantic or format identities on rejection. T1686 adds
three independent excess-order controls: repeat multiplication, an action after
a full boundary, and malformed action syntax after a full boundary all retain
the stable scenario-root limit before further semantic construction and publish
no semantic report. Its focused repeat route now also independently admits the
same expanded-action boundary with no backend/tool selector and fixed semantic
identities; t1601 remains the exact generated action-axis and cleanup owner.
Action shape uses a separate asymmetric pair. T1601 owns both exact axes:
parallel depth 16 admits before 17 rejects, while 256 fibers in one parallel form admit before 257 reject.
It also owns provider-free construction, same-volume
cleanup, deterministic accepted identities, and absence of partial semantic or
format identities on rejection. T1688 independently strengthens only the fiber
axis: it pins the exact accepted projection/report identities and proves the
adjacent excess wins before invalid join-value resolution without a semantic
report. T1688 is not depth, no-tool, or cleanup evidence.
Repeat layering preserves two different ceilings: t1686 proves that a non-empty repeat at count 65,535 is accepted at exactly 65,536 expanded actions and count 65,536 is the first effective excess, while t1601 proves the lower gate, action-dominated higher routes, and the first intrinsic excess at 1,000,001.
The linked decision record explains why no legal non-empty body can admit the nominal
repeat-count ceiling. Together the three evidence paths preserve distinct
scenario-root and count-path diagnostics, atomic rejection, provider-free
shape, cleanup, and deterministic accepted identities without lowering either
component ceiling.
Service scalars use three complementary witnesses. T1601 admits both exact
1,000,000 boundaries and rejects both 1,000,001 excesses, closes every
backend/tool selector, publishes no partial
semantic or format identity on rejection, and owns same-volume success/failure
cleanup. T1690 independently freezes the scoreboard diagnostic, admission
before transaction resolution, and accepted projection/report identities.
T1691 does the same for cross `max_bins` before coverpoint resolution. The two
focused tests do not claim shared staging cleanup or closed no-tool
construction beyond what t1601 directly proves.
Type shape uses a distinct asymmetric pair. T1601 admits/rejects exact list lengths 65,536/65,537, record-field counts 256/257, and aggregate depths 32/33.
It also owns closed no-tool
construction, rejection atomicity, shared cleanup, and broad accepted
identities. T1692 independently freezes all three diagnostics, admission
before invalid inner-type resolution, and fixed accepted projection/report
identities; it is not shared cleanup or closed no-tool evidence.
T1763 reconstructs all twenty-three sets of per-dimension projections,
requires their complete unions, checks every path, and rejects omitted or
foreign evidence. The validator also
rejects caller arguments, subclass invocants, missing or unknown fields,
caller-promoted dimensions, returned-data mutation, and an early calibration
disposition.

The calibration evidence remains `historical_measurement_only`. With all
dimension joins complete, the current-cap proof is `complete` and the
publication is `eligible_for_explicit_revalidation`. Exact revalidation
rejects the expected post-publication drift; the atomic closure is therefore
`explicitly_versioned_historical`, while its publication is an
`authentic_superseded_publication`. Eligibility and versioning never relabel
historical measurement as `cap_implementation`, which remains prohibited.

## Reverify the inventory

The policy watcher re-derives declared values and includes its omission and
mutation falsifiers:

```sh
prove -Iperl t/1685-vial-architecture-scale-cap-policy.t
```

The exact inventory can be reconstructed directly from the policy object:

```sh
perl -Iperl -MFSM::VIAL::ArchitectureScaleCapPolicy=build_architecture_scale_cap_policy -e '
  my $p = build_architecture_scale_cap_policy();
  my $axes = 0;
  $axes += keys %$_ for values %{$p->{axis_groups}};
  print "axes=$axes groups=", scalar(keys %{$p->{groups}}),
        " interactions=", scalar(keys %{$p->{interactions}}),
        " envelopes=", scalar(keys %{$p->{non_axis_envelopes}}), "\n";
'
```

The owning task-tree records the independent re-derivation, falsification, and
durability legs. The sealed foundation can be inspected without running a
product route or external tool:

```sh
perl -Iperl -MFSM::VIAL::ArchitectureScaleCapConsistency -e '
  my $class = "FSM::VIAL::ArchitectureScaleCapConsistency";
  my $report = $class->build;
  for my $group (sort keys %{$report->{groups}}) {
    my %state = map {
      $report->{groups}{$group}{dimensions}{$_}{status} => 1
    } @{$report->{required_dimensions}};
    print "$group: ", join(",", sort keys %state), "\n";
  }
'
```

Family-specific slices now promote dimensions only after independent evidence
review. Reverify the completed runtime join, including every cited witness,
under the repository-local RAM guard:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1663-vial-architecture-scale-portable-runtime-materialization.t \
  t/1672-vial-architecture-scale-portable-vhdl-runtime-materialization.t \
  t/1676-vial-architecture-scale-osvvm-runtime-materialization.t \
  t/17{20..49}-vial-*.t t/17{51..63}-vial-*.t
```

Reverify the completed backend join, including its policy and sealed-report
falsifiers, with:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1646-vial-architecture-scale-backend-emission-portable-sv.t \
  t/1647-vial-architecture-scale-backend-emission-portable-vhdl.t \
  t/1648-vial-architecture-scale-backend-emission-osvvm.t \
  t/1649-vial-architecture-scale-backend-emission-native-uvm.t \
  t/1650-vial-architecture-scale-backend-emission-family-qualification.t \
  t/1716-vial-backend-portable-sv-cap-order.t \
  t/1717-vial-backend-portable-vhdl-cap-order.t \
  t/1718-vial-backend-osvvm-provider-admission-order.t \
  t/1719-vial-backend-native-uvm-cap-order.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify both scoreboard limits, semantic scalar order, compact execution
preflight, and sealed-report falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1631-vial-architecture-scale-checking-scoreboards.t \
  t/1690-vial-semantic-scoreboard-capacity-order.t \
  t/1712-vial-execution-scoreboard-cardinality-preflight.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify the layered coverage limits, lower source-byte route authority,
semantic scalar order, compact execution preflight, and sealed falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1632-vial-architecture-scale-checking-coverage.t \
  t/1691-vial-semantic-cross-max-bins-order.t \
  t/1713-vial-execution-coverage-cardinality-preflight.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify exact bridge-profile admission, the strengthened atomic/no-tool
controls, cleanup, and sealed-report falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1602-vial-architecture-scale-bridge-fanout.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify serialized-manifest workload admission, terminal canonical-byte
authority, validation order, atomic rejection, and sealed falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1602-vial-architecture-scale-bridge-fanout.t \
  t/1704-hial-vial-bridge-serialized-manifest-terminal-authority.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify all normalized bridge collections, their exact shared ladder, each
focused cap-order control, and sealed-report falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1602-vial-architecture-scale-bridge-fanout.t \
  t/16{94..99}-hial-vial-bridge-*-cap-order.t \
  t/17{00..03}-hial-vial-bridge-*-cap-order.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify fixed-scalar ownership, the scenario ladder, ordinary profile
admission, cleanup, and sealed-report falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1603-vial-architecture-scale-execution-foundation.t \
  t/161{6..8}-vial-architecture-scale-execution-scenario-*.t \
  t/1705-vial-execution-selected-domain-cap-order.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify both operation-cardinality ladders, exact compact preflights,
same-volume cleanup, and sealed-report falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1619-vial-architecture-scale-execution-operation-qualification.t \
  t/162{0..1}-vial-architecture-scale-execution-operation-*.t \
  t/1622-vial-architecture-scale-execution-total-operation-qualification.t \
  t/1626-vial-architecture-scale-execution-total-operation-limit.t \
  t/1706-vial-execution-operation-cardinality-cap-order.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify both fiber axes, qualification cleanup, exact component boundaries,
route dominance, adjacent excesses, and sealed-report falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1623-vial-architecture-scale-execution-fiber-qualification.t \
  t/1624-vial-architecture-scale-execution-live-fiber-limit.t \
  t/1625-vial-architecture-scale-execution-total-fiber-limit.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify all three execution route collections, their accepted gate identities,
exact reachable boundaries, local defenses, cleanup, and sealed falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1603-vial-architecture-scale-execution-foundation.t \
  t/1606-vial-architecture-scale-execution-types.t \
  t/1607-vial-architecture-scale-execution-source-maps.t \
  t/1627-vial-architecture-scale-execution-type-qualification.t \
  t/1628-vial-architecture-scale-execution-binding-limits.t \
  t/1707-vial-execution-type-cap-order.t \
  t/1708-vial-execution-source-map-cap-order.t \
  t/1709-vial-execution-binding-cardinality-preflight.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify the exact random-attempt boundary, adjacent exhaustion, terminal
projection order, cleanup, and sealed falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1614-vial-architecture-scale-execution-random-limit.t \
  t/1615-vial-architecture-scale-execution-random-over-limit.t \
  t/1710-vial-execution-random-attempt-authority.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify the exact serialized-plan boundary, first complete excess,
pre-materialization order, cleanup, identities, and sealed falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1611-vial-architecture-scale-execution-plan-limit.t \
  t/1612-vial-architecture-scale-execution-plan-over-limit.t \
  t/1634-vial-architecture-scale-checking-random-replay.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify the closed semantic catalog, exact import and byte parser boundaries,
pre-recursion/pre-lex order, cleanup, identities, and sealed falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1601-vial-architecture-scale-semantic-catalog.t \
  t/1687-vial-parser-direct-import-cap-order.t \
  t/1693-vial-parser-source-byte-cap-order.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify exact declaration and fixture cardinality, failure atomicity,
admission order, cleanup, identities, and sealed falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1601-vial-architecture-scale-semantic-catalog.t \
  t/1689-vial-semantic-declaration-cap-order.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify exact action cardinality, early reservation order, failure atomicity,
cleanup, identities, and sealed falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1601-vial-architecture-scale-semantic-catalog.t \
  t/1686-vial-semantic-action-cap-order.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify both semantic-service scalar boundaries, first excesses, diagnostic
and pre-reference order, fixed identities, shared cleanup, and sealed
falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1601-vial-architecture-scale-semantic-catalog.t \
  t/1690-vial-semantic-scoreboard-capacity-order.t \
  t/1691-vial-semantic-cross-max-bins-order.t \
  t/1685-vial-architecture-scale-cap-policy.t \
  t/1763-vial-architecture-scale-cap-consistency.t
```

Reverify all three semantic-type-shape boundaries and first excesses,
pre-inner-resolution order, fixed identities, shared cleanup, and the complete
all-group calibration unlock with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1601-vial-architecture-scale-semantic-catalog.t \
  t/1692-vial-semantic-type-shape-cap-order.t \
  t/1685-vial-architecture-scale-cap-policy.t \
  t/1763-vial-architecture-scale-cap-consistency.t
```

Reverify exact parallel depth and fiber shape, pre-join admission order,
failure atomicity, cleanup, identities, and sealed falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1601-vial-architecture-scale-semantic-catalog.t \
  t/1688-vial-semantic-parallel-fiber-cap-order.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify the accepted effective repeat boundary, both adjacent enforcement
layers, failure atomicity, cleanup, identities, and sealed falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1601-vial-architecture-scale-semantic-catalog.t \
  t/1686-vial-semantic-action-cap-order.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

These joins change no cap, level, accepted profile, provider boundary,
product behavior, publication, support statement, budget, or capacity claim.

Reverify both true checking-model limits, their compact-preflight hardener, and
the sealed-report falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1630-vial-architecture-scale-checking-models.t \
  t/1711-vial-execution-model-cardinality-preflight.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify the layered randomness route, component excess, replay, and sealed
falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1634-vial-architecture-scale-checking-random-replay.t \
  t/1715-vial-execution-random-occurrence-preflight.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

Reverify the true fault limit, compact-preflight hardener, and sealed-report
falsifiers with:

```sh
scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_SCALE_EXACT=1 \
  prove -Iperl t/1633-vial-architecture-scale-checking-faults.t \
  t/1714-vial-execution-fault-cardinality-preflight.t \
  t/1763-vial-architecture-scale-cap-consistency.t \
  t/1685-vial-architecture-scale-cap-policy.t
```

## What happens after cap closeout

Architecture-scale regression promotion is active under `.17.5`, but no
performance budget or support statement is promoted by activation. The
selection leaf is complete and `.17.5.2` now owns current capture and atomic
publication. The complete v1 calibration closure remains authentic historical
evidence, not current performance evidence; its candidate budgets cannot be
copied into a live regression gate.

[Decision 0096](../../decisions/0096-regression-promotion-uses-a-current-eleven-profile-corpus.md)
selects the smaller independently versioned current corpus. Exact cap tests
already cover every resource axis; performance promotion needs representative
stage and tool routes. The eleven stable coordinate selections are:

| Authority | Family/route | Gate coordinate |
| --- | --- | --- |
| semantic/bridge | semantic catalog | `actions` |
| semantic/bridge | bridge fanout | `backend_bindings` |
| execution/checking | execution graph | `bindings` |
| execution/checking | checking state | `random_occurrences` |
| backend emission | portable SystemVerilog | `sv_portable_verilator` |
| backend emission | portable VHDL | `vhdl_portable_ghdl` |
| backend emission | OSVVM-qualified VHDL | `vhdl_osvvm_qualified` |
| portable runtime | SystemVerilog/Verilator | `sv_portable_verilator` |
| portable runtime | VHDL/GHDL | `vhdl_portable_ghdl` |
| OSVVM runtime | VHDL/GHDL + OSVVM | `vhdl_osvvm_qualified` |
| balanced portable | structural composition | `sv_portable_verilator` |

The historical complete closure contains 356 raw records; the selected
coordinates contain 33. Their summed historical raw wall values are
6,806,844,563,000 ns and 2,135,252,066,000 ns respectively. The difference is
a capture-scope comparator, not a regression budget. `.17.5.2` must reconstruct
all eleven profiles at the current revision, run one validation and three fresh
measurements per profile, allow zero exclusions, and publish 44 records
atomically below
`.artifacts/qualification/vial-scale/v2/regression-promotion-corpus-v1/`.
Here “44” means common measurement-controller invocations. Each selected
measurement adapter groups its validation and three measurements inside one
guard-visible profile worker, so capture uses eleven ordered worker lifecycles,
not 44 publication workers.

Implementation remains split into recoverable steps. `.17.5.2.1` derives the
closed dispatch plan without running producers. `.17.5.2.2` owns isolated
per-profile capture, v2 publication, exact profile resume, and prerequisite
legacy-store hardening. `.17.5.2.3` owns the complete coordinator,
fresh-worker corpus reload, and bounded CLI. Only after those implementation
commits are clean does `.17.5.2.4` run the real guarded capture at one revision.
`.17.5.2.5` then independently reloads, falsifies, documents, and closes the
publication for the still-separate budget qualification leaf. Activation
itself runs no simulator, measurement producer, or artifact publication.

The first real guarded capture at clean revision `610ed7869` retained the
first four profiles, then failed closed before publishing ordinal five or a
corpus seal. The backend-emission selection deliberately has no policy
`primary_axis`, but its canonical producer report requires
`primary_axis=artifact_graph`; the capture admission had incorrectly treated
the nullable selection coordinate as the complete report-coordinate schema.
The same distinction applies to the remaining runtime and balanced reports.
Synthetic capture/resume doubles copied the null selection value and therefore
did not expose the mismatch. This is an admission-contract defect, not a
simulator result or a reason to weaken the producer report.

The exact four-report prefix remains evidence rather than being deleted or
relabelled. A rollback-capable same-volume move preserves its 600,036 report
bytes plus a 4,503-byte canonical failure manifest under the exact capture
revision in `.artifacts/qualification/vial-scale/history/`. Independent
reconstruction yields archive identity
`regression-promotion-failed-prefix/f46939aab1731f2b2a136a0d06cf161d4ff6ec99b2336559227a668c8b86e5a4`,
five files/604,539 bytes; at archival time the active v2 namespace and archive
staging were empty. None of this is a performance, capacity, simulator-support,
or regression-budget claim.

Reconstruct the retained failed prefix without measuring or invoking a
simulator:

```bash
scripts/verify_vial_regression_promotion_failed_prefix.pl
```

Verification schema v2 keeps the historical archive independently replayable
when the active namespace is absent. When a current namespace is present, it
must instead be the exact 13-file repaired seal: eleven profile reports plus
the authenticated corpus report and manifest at revision `155aa22ea`. The
verifier checks current file/content identities, exact directory census,
same-volume ownership, staging absence, and inode separation from history; a
foreign, mutated, linked, or partial current namespace rejects before output.
The focused copied-evidence controls are runnable without a simulator:

```bash
prove -Iperl t/1775-vial-regression-promotion-failed-prefix-verifier.t
```

The repair keeps decision-0096 selection keys and all publication paths
unchanged, but advances the dispatch contract to capture-plan schema v2. Every
entry now carries a separate closed `report_coordinate_authority` with a
content-addressed identity. Its family, level, primary axis, and backend
profile come from a metadata-only public method on the selected adapter; that
method runs the adapter's existing canonical producer-ownership validation.
The plan pins all eleven resulting identities, so rehashing a forged plan or
authority cannot make foreign coordinates current.

| Producer group | Policy selection axis | Admitted report axis |
| --- | --- | --- |
| semantic/bridge | `actions` or `backend_bindings` | same selected axis |
| execution/checking | `bindings` or `random_occurrences` | same selected axis |
| backend emission | null | `artifact_graph` |
| portable and OSVVM runtime | null | `runtime_trace_records` |
| balanced portable | null | `interaction_profile` |

Both child capture and parent resume compare reports against this new
authority. Synthetic reports also use it, so all eleven doubles reproduce the
real producer shape instead of copying a nullable selection axis. Focused
controls change and omit every coordinate, add a backend coordinate where it
is inapplicable, forge the adapter result and both plan identities, and prove
that selection and report axes remain independent. Run the complete repaired
contract without real producer or simulator execution:

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1766-vial-architecture-scale-regression-promotion-capture-plan.t \
  t/1767-vial-architecture-scale-regression-promotion-profile-store.t \
  t/1768-vial-architecture-scale-regression-promotion-profile-capture.t \
  t/1769-vial-architecture-scale-regression-promotion-profile-resume.t \
  t/1772-vial-regression-promotion-corpus-store.t \
  t/1773-vial-regression-promotion-corpus-coordinator.t \
  t/1774-vial-regression-promotion-corpus-cli.t
```

The repaired real capture is now complete. From an empty active namespace at
clean revision `155aa22ea3099642eb6b7f5de81ea03633e72bcb`, the guarded
production operation ran all eleven current adapters and published eleven
atomic profile reports: eleven validations, 33 fresh raw measurements, 44
accepted controller invocations, and zero exclusions. The runtime routes used
their exact owned providers—Verilator 5.046, GHDL 6.0.0 LLVM JIT, and the
qualified GHDL-plus-OSVVM combination—while repository-only emission routes
remained correctly distinct from external simulator execution.

The complete same-volume seal has these authenticated identities:

| Evidence | Current identity |
| --- | --- |
| corpus | `regression-promotion-corpus/ab2df8992d85b8466f4afca530a5af36984031c453002534fc92ff5678a2e505` |
| publication | `regression-promotion-corpus-publication/865c5cce3deee3eaaca9b66cd5d7f007a6e10b6423ac7d5dff2dc7484cd8432e` |
| capture plan | `regression-promotion-capture-plan/fbf697407b0ba326a11a10cbb2d31744f8d28944a0d4d402294cd960dea09737` |
| policy | `regression-promotion-policy/19cf41056da86d95c266597e7db76eff3810ee29511a005e1051053009a65ece` |
| complete file set | `dc5b315b827389eb466776716f6851cdd9ddd13b2f1aec441f8a51b7d72dc66f` |

The complete report is 23,288 bytes with SHA-256
`d6139d0f122ced6148846909b3dcf54fd2aed65df1b86f98425d265c060f84a1`;
its manifest is 1,280 bytes with SHA-256
`3de607e3d3504f7fe49ca092b32b5be7c4f2452ceb9af14559d83aef92990273`.
A distinct guarded process then ran producer-free validation, captured no new
profile, resumed all eleven, and reproduced every common, provider, report,
plan, policy, publication, and file-set identity. Guarded inventory reported
eleven present profiles and zero missing profiles with no staging residue.
The historical-prefix verifier also succeeds against this exact current seal;
it does not mistake an authenticated current publication for failed-capture
residue or admit it as historical evidence.

Review the sealed result without invoking a measurement producer:

```bash
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_regression_promotion_corpus.pl --validate
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_regression_promotion_corpus.pl --inventory
```

For a producer-independent census, use the separately implemented read-only
verifier:

```bash
scripts/verify_vial_regression_promotion_current_corpus.pl
prove -Iperl t/1776-vial-regression-promotion-current-corpus-verifier.t
scripts/run_with_ram_guard.sh -- \
  prove -v t/1777-vial-regression-promotion-current-corpus-mutations.t
```

It derives the repository root from its tracked location and imports no
FSMGEN production module. The verifier traverses only the sealed namespace,
requires the exact same-volume owner, directory and 13-file regular/one-link
census, reads each file within its authenticated size, and reconstructs every
canonical JSON identity directly. It independently recomputes each profile
publication and family report identity, all report coordinates, common
revision/host/guard state, 44 ordered controller records, successful
correctness oracles, cleanup, applicability, provider bindings, and explicit
nonclaims. The complete namespace is 6,220,126 bytes and its canonical
13-file inventory digest is
`94c11e5c81843f412cb8d1af23b7699dbb15b1af19077c1903cab91d8eddbb57`.
This inventory identity is deliberately distinct from the production
`file_set_sha256`: that seal directly hashes only the complete report and
manifest, while the report transitively authenticates all eleven profile
byte/hash identities. Both chains agree on the current evidence, but they
answer different census questions.
The provider census remains seven non-external foundation routes, one
repository-materialized OSVVM route, and three exact external-tool routes.
The focused watcher compares every path, inode, mode, link, owner, byte count,
and file hash before and after execution, and the verifier emits only one
bounded canonical result after the complete census succeeds.

The copied-artifact watcher closes the independent falsification leg without
writing the sealed namespace. It installs the verifier beside an exact
repository-local same-volume copy, admits the baseline, and fires 17 controls:
report, manifest, profile record, order, identity, provider, count, digest,
canonicality, symlink, hard link, FIFO, extra and missing paths, both staging
roots, and historical-profile substitution. Every mutation rejects with empty
stdout, every restored copy re-authenticates, the fixture is removed, and the
real path/inode/owner/device/size/hash census stays identical. Foreign-owner
and foreign-device mutations are not fabricated: the former needs privilege
and the latter would violate the same-volume evidence policy; direct lstat
enforcement and the same-owner/device baseline remain watched.

Canonicalization diagnosis is a separate, read-only operation:

```bash
scripts/run_with_ram_guard.sh -- \
  scripts/measure_vial_regression_promotion_canonicalization.pl \
  --phase corpus-load \
  --sample-relative .artifacts/diagnostics/vial-scale/corpus.sample.txt \
  --sample-seconds 3
scripts/run_with_ram_guard.sh -- \
  scripts/measure_vial_regression_promotion_canonicalization.pl \
  --phase balanced-validation \
  --sample-relative .artifacts/diagnostics/vial-scale/balanced.sample.txt \
  --sample-seconds 3
```

The runner instruments the JSON encoder already used by production; it does
not add a second probe encoding. It preserves imported prototypes, times
top-level clones, counts recursive clone nodes separately, launches macOS
`sample -file` directly into the repository, and independently verifies the
sealed corpus before and after. On production-source baseline `fafe5d88b`,
complete load consumed 13 files/6,220,126 bytes and returned 25,417 canonical
bytes. Its 23.093509-second phase created 36,790,450 canonical bytes plus
13,558,259 clone-encoding bytes and hashed 30,407,371 bytes. Twelve complete
policy encodes account for 16,496,724 bytes: CorpusStore derives the plan once,
then eleven public ProfileStore loads each derive it again.

The first repair keeps plan authority inside ProfileStore. Its closed
`load_all({repository_root})` derives once, preflights all eleven staging
coordinates, reads the eleven publications in plan order, returns one closed
plan/profile bundle, and postflights staging after the read. CorpusStore accepts
no plan or bundle from its caller; it checks the returned plan, entries,
publications, artifacts, count, and order before applying every existing report
and profile-reference oracle. Focused hostile controls cover missing/reordered/
string-typed bundles, changed plan/report data, early and late staging, and prove
that complete load no longer calls the individual public profile loader.

The final guarded v3 comparison preserves the exact 13-file/6,220,126-byte
inventory, corpus/publication identities, and 25,417-byte returned value.
Policy whole-graph encodes fall from 12/16,496,724 bytes to 1/1,374,727 bytes;
total canonical materialization falls 36,790,450→20,186,110 bytes, top-level
clones 1,091→124, recursive clone nodes 50,256→4,188, clone-encoding bytes
13,558,259→12,567,517, and hashed input 30,407,371→13,981,715 bytes. This host
point falls from 23.093509/9.41 seconds wall/user CPU to 6.554453/5.32 seconds,
but the rounded three-second sampler footprint rises from 210.2M to 220.6M.
Those observations prove the targeted multiplicity repair, not a performance or
memory budget, support tier, capacity limit, or stable cross-host ratio.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-corpus-load-plan-derivation-repair-v1 -->
- Claim: The closed regression-promotion all-profile load derives one current plan internally, preflights and postflights all eleven staging coordinates, returns eleven authenticated publications in plan order, and lets complete corpus reload retain every existing plan/report/profile/artifact oracle without accepting caller plan authority. Against production-source baseline fafe5d88b, guarded v3 point observations preserve the exact 13-file/6,220,126-byte inventory and 25,417-byte returned value while policy whole-graph encodes fall from 12/16,496,724 bytes to 1/1,374,727 bytes, total canonical bytes from 36,790,450 to 20,186,110, and user CPU from 9.41 to 5.32 seconds; rounded sampled footprint rises from 210.2M to 220.6M. This proves the targeted authority-rebuild repair, not a performance or memory budget, support tier, capacity limit, or stable ratio.
- Re-derive: Run guarded t1767+t1772, then rerun the v3 corpus-load command with a fresh repository-local sample name. Require one policy whole-graph encode, exact output SHA-256 11e0c755...21e7, exact before/after inventory 94c11e5c...bb57, empty staging, and final result structure matching 5e1a9eec...ab6f; treat timing and sampler footprint only as revision/host observations.
- Falsify: t1767 must reject caller coordinates, missing publications, every pre-existing profile staging coordinate, and residue introduced during the ordered read; t1772 must reject missing/reordered/string-typed/foreign-plan/changed-report bundles and prove complete load never falls back to individual profile loads. Compare the baseline and repaired guarded results; any changed corpus/output identity or policy count other than one falsifies the repair.
- Durability: Retain ProfileStore, CorpusStore, t1767/t1772/t1778, task `.17.5.2.5.3.1`, this chapter, the compact regression-promotion fact card, bounded claim record, final result/sample identities, doctrine gates, and work-unit Git chain. Raw samples remain diagnostic supplements; tracked code, tests, and commands are the durable reproducer.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-corpus-load-plan-derivation-repair-v1 -->

Balanced public validation consumed the 1,244,823-byte ordinal-11 publication
and returned its exact 1,241,948-byte report. Its 492.563279-second phase
created 1,325,878,982 canonical bytes plus 121,737,844 clone-encoding bytes,
hashed 1,044,992,073 bytes, and crossed 946,272 top-level clone boundaries.
The fresh gates, independent routes, replay, emission, and byte comparisons
are required correctness work. One rebuild is not: `_canonical_bundle`
accepts a six-gate composition, then calls public emitter evaluation, which
rebuilds that composition despite an existing exact-caller measurement seam
designed to reuse it.

The second repair changes only that call site: `_canonical_bundle` passes its
already accepted composition to `_measurement_evaluate`. The exact-caller seam
still builds two independent emission routes, emits both, compares their bytes,
and applies the complete artifact/report oracle. Guarded exact t1681 proves one
six-gate producer evaluation, zero public-emitter evaluations, and one private-
seam evaluation during independent report regeneration; it also retains exact
report regeneration, foreign-caller rejection, replay, mutation rejection, all
five structural stages, and cleanup.

The guarded v3 comparison preserves the 1,244,823-byte input and exact
1,241,948-byte returned report with SHA-256 `0999d139...edb5`. Canonical bytes
fall 1,325,878,982→813,307,147; clone-encoding bytes
121,737,844→70,814,879; hashed input 1,044,992,073→640,333,611; top-level
clones 946,272→596,715; and recursive clone nodes
68,435,593→42,088,166. The emitter's own operation counts remain exact at
7,269 canonical calls/152,611,792 bytes, 358,230 clone calls/358,218 recursive
nodes, and 22 hashes/75,749,997 input bytes, localizing the removed work to the
composition rebuild. This host point records wall/user CPU
492.563279/491.72→297.920989/294.52 seconds and rounded sampled
reported/peak footprint 299.1M/325.6M→296.2M/320.5M. These are revision/host
observations, not a performance or memory budget, support tier, capacity limit,
or stable ratio.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-balanced-composition-reuse-v1 -->
- Claim: The balanced regression-promotion measurement adapter evaluates its six-gate composition once and passes that accepted value through the emitter's exact-caller seam, while the seam retains two independent emission routes, byte-equal rerun, replay, complete artifact/report oracles, and foreign-caller rejection. Against production-source baseline fafe5d88b, one guarded v3 host point preserves the exact 1,241,948-byte report and SHA-256 0999d139...edb5 while canonical bytes fall from 1,325,878,982 to 813,307,147, clone-encoding bytes from 121,737,844 to 70,814,879, hashed input from 1,044,992,073 to 640,333,611, and user CPU from 491.72 to 294.52 seconds; rounded reported/peak footprint moves from 299.1M/325.6M to 296.2M/320.5M. This proves the targeted composition-rebuild removal, not a performance or memory budget, support tier, capacity limit, or stable ratio.
- Re-derive: Run exact guarded t1681 and require one producer evaluation, zero public-emitter evaluations, and one private-seam evaluation during exact report regeneration. Then rerun guarded v3 balanced-validation with a fresh repository-local sample name; require exact input/output identities, before/after inventory 94c11e5c...bb57, empty staging, unchanged corpus bytes, and final result structure matching b03f7ea7...cf2. Treat timing and footprint only as revision/host observations.
- Falsify: t1681 must retain exact report regeneration, both emission routes, replay, all artifact/report/member oracles, foreign-caller rejection, hostile report/applicability rejection, and cleanup. t1778 must prove `_canonical_bundle` passes its accepted composition to the private seam and contains no public-emitter call. Compare baseline and repaired module counters; any output change, nonzero public-emitter count, producer count other than one, or changed emitter operation count falsifies the repair.
- Durability: Retain Measurement, Emission, t1681/t1778, task `.17.5.2.5.3.2`, this chapter, the compact regression-promotion fact card, bounded claim record, final result/sample identities, doctrine gates, and work-unit Git chain. Raw samples remain diagnostic supplements; tracked code, tests, and commands are the durable reproducer.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-balanced-composition-reuse-v1 -->

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-canonicalization-characterization-v1 -->
- Claim: On production-source baseline fafe5d88b, final-schema guarded diagnostics preserved the exact current publication and returned values while attributing complete-corpus load and balanced public validation. Corpus load consumed 6,220,126 artifact bytes, ran for 23.093509 seconds, created 36,790,450 canonical plus 13,558,259 clone-encoding bytes, and exposed twelve 1,374,727-byte policy encodes. Balanced validation consumed a 1,244,823-byte artifact, returned 1,241,948 canonical bytes, ran for 492.563279 seconds, created 1,325,878,982 canonical plus 121,737,844 clone-encoding bytes, hashed 1,044,992,073 bytes, and crossed 946,272 top-level clone boundaries. Source inspection binds the avoidable portions to twelve plan derivations and one bypassed accepted-composition seam; required fresh correctness recomputation remains in scope. This is defect characterization, not a performance budget, support tier, or capacity limit.
- Re-derive: Run the two guarded commands above with new repository-local sample names. Require v3 instrumentation, exact input/output identities, before/after inventory 94c11e5c...bb57, empty staging, corpus result structure matching da17e6df...468ee, balanced result structure matching 87cbbc32...f5e2f, and the exact module/call/byte totals stated here; timing and sampler footprint are revision/host point observations, not frozen limits.
- Falsify: Run t1778 to prove the underlay adds no encoder call, attributes exact existing clone/canonical bytes, preserves values and imported prototypes, restores every wrapper, rejects open/off-volume/unguarded invocation, and reaches only the public phase boundaries. Compare the independent macOS samples for active Perl hash/array/value-copy opcodes, and inspect the two source call chains to reject the competing hypothesis that unique artifact size alone explains the multiplicity.
- Durability: Retain the tracked runner, t1778, task `.17.5.2.5.3` result and child owners, this chapter, the regression-promotion Knowledge card, bounded claim record, exact artifact hashes/commands, doctrine gates, and work-unit Git chain. The raw repository-local samples are diagnostic supplements; the tracked runner and commands are the durable reproducer.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-canonicalization-characterization-v1 -->

This proves current capture, producer-free re-admission, and actual copied-
artifact falsification, not a regression budget, support tier, capacity limit,
or performance qualification. Both characterized authority rebuilds are now
repaired; clean independent/publication closeout remains under `.17.5.2.5.4`,
and budget work remains solely `.17.5.3`.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-real-current-corpus-capture-v1 -->
- Claim: At clean revision 155aa22ea3099642eb6b7f5de81ea03633e72bcb, guarded production capture published the repaired eleven-profile current corpus as eleven validations, 33 fresh raw measurements, 44 accepted controller invocations, and zero exclusions; its complete report is 23,288 bytes with SHA-256 d6139d0f...84a1 and its manifest is 1,280 bytes with SHA-256 3de607e3...0273. A distinct guarded producer-free process resumed all eleven. A separately implemented read-only verifier imports no production module and reconstructs the exact 13-file/6,220,126-byte namespace, inventory SHA-256 94c11e5c...bb57, identities, records, providers, correctness oracles, cleanup, and nonclaims. Same-volume copied-artifact controls independently falsify every sealed content, semantic, file-shape, namespace, staging, and historical-substitution class that is safe to construct. This proves current capture, two distinct re-admission paths, and actual-artifact falsification, not a regression budget, support, performance, or capacity.
- Re-derive: Run guarded `--validate` and `--inventory`, then run `scripts/verify_vial_regression_promotion_current_corpus.pl` against the active corpus. Require corpus ab2df899...e505, publication 865c5cce...432e, plan fbf69740...9737, policy 19cf4105...ece, file-set dc5b315b...c66f, report 23,288 bytes/d6139d0f...84a1, manifest 1,280 bytes/3de607e3...0273, inventory 94c11e5c...bb57, 13 files/6,220,126 bytes, eleven profiles/validations, 33 raw records, 44 invocations, zero exclusions/missing profiles, and the exact seven-foundation/one-materialized/three-external provider partition.
- Falsify: Run guarded t1777. Its exact same-volume copy must accept before mutation and after every restore; report, manifest, profile record, order, identity, provider, count, digest, canonicality, symlink, hard-link, FIFO, extra/missing path, both staging, and historical-substitution controls must reject with empty stdout; the real namespace census and final fixture absence must remain exact. Foreign owner/device controls remain explicitly unavailable where privilege or cross-volume data would be required.
- Durability: Retain the exact task result, mdBook section, Knowledge card, bounded claim record, clean revision, same-volume sealed artifacts, tracked production validate/inventory path, tracked independent verifier, t1776/t1777 watchers, doctrine gate, and work-unit Git chain.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-real-current-corpus-capture-v1 -->

The dispatch authority now implements the metadata-only first step. It
authenticates the promotion policy internally, preserves policy order, and
binds every selection to its current adapter, public measurement method,
closed arguments, producer-authority metadata, provider and applicability
prerequisites, record sequence, and unique repository-relative report path.
The report-directory token is derived from the complete selection key, while
the leading ordinal makes order reviewable. Derivation is defensive and
content-addressed; it invokes no producer, provider, simulator, measurement
controller, or publication transaction.

Structural OSVVM emission and OSVVM runtime deliberately have different
provider prerequisites. The structural dispatch binds the exact repository
materialization but does not invoke an external verification tool. The runtime
dispatch requires the exact qualified GHDL-plus-OSVVM tool profile. This keeps
source materialization from masquerading as simulator execution.

The first `.17.5.2.2` implementation slice adds a producer-free v2 profile
store. Its public API accepts only the repository root, plan ordinal, and an
already-admitted report; it derives the current plan internally, so callers
cannot choose a path or substitute a revision-1 coordinate. The store wraps
the report with the exact plan, policy, dispatch entry, and a content-addressed
publication identity. It writes canonical newline-terminated JSON to one
repository-local staging directory, synchronizes the file and directory, then
renames the complete directory to the exact plan coordinate.

Reload performs an exact directory census before a bounded read and compares
pathname and opened-handle identities. Extra entries, malformed or
noncanonical JSON, absolute/escaping/historical coordinates, cross-device
state, symlinks, multiply linked files, collisions, and ambiguous or residual
staging all fail closed. An exact sole interrupted stage may recover; anything
ambiguous stays in place for diagnosis. The provisional 64 MiB file ceiling is
a storage-admission limit, not evidence that a profile fits, performs, or has
capacity. Real capture must fit or fail without relaxing the ceiling.

The isolated single-profile capture boundary is implemented. Its public
API accepts only the repository root and one plan ordinal. It derives the
current dispatch internally, requires a clean Git revision, and forks one
guard-visible child. The child invokes exactly the plan's public adapter method
with the sealed arguments, calls that adapter's public `validate_report`, and
admits only the selected gate coordinate, accepted validation followed by
three accepted gate records, zero exclusions, complete cleanup, and one clean
revision/host/tool/guard identity. Numeric or string lookalikes cannot replace
the required JSON scalar types.

Provider admission is route-specific. Structural OSVVM emission must retain
the exact read-only repository materialization and must remain non-external.
Runtime routes must reproduce the complete content-addressed tool profile;
an internally consistent foreign provider still rejects. Only an admitted
report reaches the v2 store. The child returns bounded metadata—not report
bytes—through canonical IPC, and the parent reloads the publication, compares
artifact identity, re-runs public adapter validation, and proves the repository
revision stayed clean and unchanged.

Exceptions, signals, unframed exits, malformed or noncanonical IPC, an
oversized envelope, mixed record identities, reordered or incomplete samples,
failed outcomes, residue, and producer-side repository mutation all fail
closed. The focused watcher crosses all eleven plan routes using public-method
doubles and repository-local Git fixtures; it proves dispatch and admission
without running a scale producer, simulator, or real capture. The guarded real
capture remains owned by `.17.5.2.4` after the coordinator and resume path ship.

Exact single-profile resume is producer-free. Its public API accepts only the
repository root and numeric plan ordinal, loads the existing publication in a
fresh child, runs the selected adapter's public validator, and repeats report,
dispatch, provider, applicability, cleanup, revision, host, guard, and tool
admission. Foundation routes must reproduce the current in-process tool
identity; qualified runtime routes remain bound to their complete external-tool
profile. The parent reloads the same bytes and independently repeats validation
after child completion. There is no capture fallback and resume never seals a
complete corpus.

Store reload now rejects same-profile staging residue even when an apparently
valid target exists. Rehashed stale plan or dispatch envelopes, foreign
providers, mixed records, stale common identities, target-census changes,
revision-1 substitutions, noncanonical post-worker mutation, validator-side
repository mutation, child exceptions, and signals all reject. The store's
existing bounded topology tests continue to own malformed, oversized,
symlink, hard-link, cross-device, collision, and ambiguous-stage controls.

The producer-free complete-corpus store is also implemented. Its public
surface accepts only the repository root plus all eleven already-admitted
profile results; it derives the plan, publication identity, and
`.artifacts/qualification/vial-scale/v2/regression-promotion-corpus-v1/complete`
coordinate internally. Before sealing, it reloads every referenced profile
through the per-profile store and requires exact order, selection/report and
artifact identities, eleven validations, 33 raw records, 44 controller
invocations, and zero exclusions.

The complete identity has two deliberate levels. Revision, host, and resource
guard must be byte-equal across all profiles. Tool and provider identity stay
inside each ordered profile because the selected set intentionally mixes
repository-only routes, Verilator, GHDL, and GHDL plus OSVVM. Treating one tool
profile as globally common would reject the valid heterogeneous corpus;
dropping the ordered per-profile identities would admit substitution. The
store also projects transient artifact status such as `published`, `loaded`,
or `recovered` out of the content hash, so exact resume produces the same
corpus instead of a false collision.

The store writes canonical newline-terminated
`regression-promotion-corpus.json` and `corpus-manifest.json` into one
repository-local stage, synchronizes both files and the directory, and
atomically renames the complete directory. The fixed 1,048,576-byte report and
65,536-byte manifest ceilings contain storage and read failure; they say
nothing about scale fit or capacity. Reload holds the no-follow directory
identity while censusing and bounded-reading both regular, one-link,
same-volume files, then recensuses before admission. Exact sole-stage recovery
and byte-identical republish succeed. Partial/ambiguous stages, collisions,
late entries, malformed/noncanonical/cap-plus-one bytes, mixed or reordered
profiles, rehashed JSON type substitutions, mutated profile references,
symlinks, hard links, and cleanup residue reject.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-corpus-storage-contract-v1 -->
- Claim: The producer-free current-corpus store seals exactly eleven ordered admitted profile references representing eleven validations, 33 raw measurements, 44 controller invocations, and zero exclusions as one canonical same-volume report-plus-manifest directory. Report bytes are bounded at 1,048,576 and manifest bytes at 65,536; these are storage-containment limits, not performance, support, workload-fit, or capacity claims.
- Re-derive: Run the guarded t1772 watcher, query `ArchitectureScaleRegressionPromotionCorpusStore->publication_limits`, and reload its synthetic two-file publication; the public limits, complete summary, file census, hashes, and current profile references must independently agree.
- Falsify: t1772 must reject missing, duplicated, reordered, mixed-identity, stale, or mutated profile input; JSON string ordinal/count/version substitutions; collision, partial failure, ambiguous/residual staging, malformed/noncanonical/cap-plus-one report or manifest bytes, late directory entries, symlinks, and hard links while admitting exact recovery and status-independent byte-identical republish.
- Durability: Retain CorpusStore, t1772, task `.17.5.2.3.1`, this chapter, the capture Knowledge card, this bounded claim record, doctrine gates, and the work-unit Git chain; real capture remains separately owned by `.17.5.2.4`.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-corpus-storage-contract-v1 -->

The complete-corpus coordinator now supplies three closed operations over only
the repository root. `inventory` performs a no-follow publication census and
reports present, missing, or incomplete state without executing a worker.
`capture` walks the internally derived plan in order, resumes an exact existing
profile or captures a missing one, reloads its artifact again in the parent,
and calls the complete store only after every route passes. `validate` requires
an existing complete seal, repeats fresh-worker resume validation for the
whole plan, and loads rather than republishes the seal. None of these methods
accept a caller-supplied plan, profile, result, worker, or callback.

Process isolation has one authority. The coordinator delegates each operation
to `ArchitectureScaleRegressionPromotionProfileCapture`, whose bounded
canonical child IPC already owns exceptions, exits, signals, malformed bytes,
and independent child/parent adapter validation. Adding another coordinator
fork would duplicate failure framing without strengthening admission. The
coordinator instead owns whole-corpus order, clean-revision stability, common
host/guard identity, route-specific provider identity, and seal timing. JSON
numeric strings, mixed identities, reordered results, repository mutation,
post-worker artifact mutation, or incomplete publications fail before sealing.

Inspect the closed coordination limits without running a worker:

```sh
perl -Iperl \
  -MFSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator \
  -MJSON::PP \
  -e 'print JSON::PP->new->canonical(1)->encode(FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator->coordination_limits), "\n"'
```

Run the synthetic all-route coordinator watcher under the RAM guard:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1773-vial-regression-promotion-corpus-coordinator.t
```

The repository-relative CLI requires an explicit operation; there is no
default capture. This matters because a typo or omitted option must not start
real providers and tools. `--limits` is guard-free. Inventory, capture, and
validation retain the coordinator's active RAM-guard and clean-revision
requirements. The script accepts no repository path or evidence injection.

```sh
scripts/run_vial_regression_promotion_corpus.pl --limits
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_regression_promotion_corpus.pl --inventory
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_regression_promotion_corpus.pl --validate
```

Use `--capture` only from the intended clean implementation revision when all
selected providers are available. The command encodes the whole result as
canonical newline-terminated JSON and checks its fixed output envelope before
writing, so a rejected oversized result cannot leave a plausible partial
document on stdout.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-corpus-cli-output-contract-v1 -->
- Claim: The regression-promotion corpus CLI requires exactly one explicit operation and emits no partial result unless its canonical newline-terminated JSON fits within 1,048,576 bytes. Exact-cap output is admitted and cap-plus-one rejects; this is a metadata-output containment limit, not corpus-storage capacity, workload fit, support, performance, or proof that real capture completed.
- Re-derive: Run `scripts/run_vial_regression_promotion_corpus.pl --limits` and the guarded t1774 watcher; the limits schema, fresh-process method log, canonical exact-boundary stdout length, and CLI source constant must independently agree.
- Falsify: t1774 must reject omitted, multiple, positional, unknown, abbreviated, case-variant, and help-plus-operation selections; prove each operation dispatches once with the script-derived root; admit exact-cap canonical output; and reject cap-plus-one with empty stdout while propagating coordinator failure without false JSON success.
- Durability: Retain the tracked CLI, t1774, task `.17.5.2.3.3`, this chapter, the capture Knowledge card, this bounded claim record, doctrine gates, and the work-unit Git chain; real capture remains separately owned by `.17.5.2.4`.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-corpus-cli-output-contract-v1 -->

The legacy storage remediation is complete. Both publishers now expose their
selected ceilings, encode and reject before staging, and require one
newline-terminated canonical JSON file that is regular, same-volume, one-link,
within its ceiling, and stable across pathname and opened-handle checks. Reads
stop at ceiling plus one. Exact interrupted staging passes through the same
bounded reader before recovery.

The independent watcher recenses the immutable legacy artifacts before
using either product reader; every historical semantic/bridge and
execution/checking file remains admitted without rewrite, rehash, or relabel.
These ceilings contain storage and failure; they do not measure or enlarge
workload capacity, supported scale, performance, or a reached boundary. The
separately completed coordinator audit remains a process-lifetime result and
does not alter these byte limits.

<!-- CLAIM-VERIFICATION:BEGIN vial-legacy-matrix-publication-storage-ceilings-v1 -->
- Claim: The immutable revision-1 semantic/bridge publisher admits all 111 existing canonical publications below a 524,288-byte storage ceiling, with a 253,882-byte current maximum; execution/checking admits all 75 existing canonical publications below a 1,048,576-byte ceiling, with a 759,867-byte current maximum. Both limits are fail-closed publication-containment bounds, not workload-capacity, support, performance, or reached-boundary claims.
- Re-derive: Run `prove -Iperl -v t/1771-vial-legacy-matrix-publication-bounds.t`; its independent lstat/JSON census must reproduce 111 files/7,418,437 bytes/253,882-byte maximum and 75 files/7,312,415 bytes/759,867-byte maximum, then reload every file through the repaired readers and query both `publication_limits` methods.
- Falsify: The watcher must admit exact-cap canonical write and reload for each publisher, reject cap-plus-one before staging, reject a pre-existing cap-plus-one file from stat, reject cap-plus-one recovery staging through the bounded reader, and reject malformed, missing-newline, noncanonical, extra-entry, during-read directory mutation, symlink, and hard-link substitutions.
- Durability: Retain both publishers, t1771, task `.17.5.2.2.4`, this chapter, the architecture-scale Knowledge card, this bounded claim record, doctrine watcher, and work-unit Git chain; any artifact, limit, or admission drift must make the watcher fail.
<!-- CLAIM-VERIFICATION:END vial-legacy-matrix-publication-storage-ceilings-v1 -->

Run the legacy publication census and hostile boundary watcher with:

```sh
prove -Iperl -v t/1771-vial-legacy-matrix-publication-bounds.t
```

Run the bounded metadata-only watcher with:

```sh
prove -Iperl \
  t/1766-vial-architecture-scale-regression-promotion-capture-plan.t
```

Run the producer-free v2 storage and adversarial admission watcher with:

```sh
prove -Iperl \
  t/1767-vial-architecture-scale-regression-promotion-profile-store.t
```

Run the isolated ordinal-dispatch and accepted-report watcher under the RAM
guard with:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1768-vial-architecture-scale-regression-promotion-profile-capture.t
```

Run the producer-free fresh-worker resume watcher under the same guard with:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1769-vial-architecture-scale-regression-promotion-profile-resume.t
```

Inspect the complete-store contract without creating an artifact:

```sh
perl -Iperl \
  -MFSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore \
  -MJSON::PP \
  -e 'print JSON::PP->new->canonical(1)->encode(FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore->publication_limits), "\n"'
```

Run its producer-free complete-publication and hostile-storage watcher under
the RAM guard:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1772-vial-regression-promotion-corpus-store.t
```

Authenticate both the selection policy and dispatch plan under the repository
RAM guard with:

```sh
scripts/run_with_ram_guard.sh -- env \
  FSMGEN_VIAL_SCALE_PROMOTION_CAPTURE_PLAN_EXACT=1 \
  prove -Iperl \
  t/1765-vial-architecture-scale-regression-promotion-policy.t \
  t/1766-vial-architecture-scale-regression-promotion-capture-plan.t
```

Qualified tools are resolved through their exact profiles. A shell-global
`ghdl` is not required; the repository-local GHDL provider is the authority.
If an exact provider is absent, the route is unavailable—not passing. Timing
enforcement later applies only to the exact common revision/host/tool/guard
identity; unmatched environments retain applicable correctness checks and
informational timing. Expensive capture and gate execution belongs to full
pre-push or explicitly selected important steps, not every ordinary slice.

Re-derive the selection and its closure comparison with:

```sh
scripts/run_with_ram_guard.sh -- env \
  FSMGEN_VIAL_SCALE_PROMOTION_POLICY_EXACT=1 \
  prove -Iperl \
  t/1765-vial-architecture-scale-regression-promotion-policy.t
```

Current capture, budget qualification, gate/CI integration, public truth, and
independent closeout remain separate rollback owners. Until those leaves pass,
all historical candidate budgets stay candidate-only, and whole-product
big/really-big capacity remains unclaimed.
