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
performance budget or support statement is promoted by activation. The first
leaf must select current evidence and representative profiles before any new
measurement. This ordering matters because the complete v1 calibration closure
is authentic historical evidence, not current performance evidence; its
candidate budgets cannot be copied into a live regression gate.

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
