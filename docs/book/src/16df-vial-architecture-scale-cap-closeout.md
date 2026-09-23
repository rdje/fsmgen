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
repaired; clean independent/publication closeout is complete, and budget work
remains solely `.17.5.3`.

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
enforcement later requires exact host/tool/guard/provider identity plus exact
selection/workload/correctness identity. The capture Git revision remains
immutable evidence provenance, but is not a runtime match field: otherwise the
qualification and gate commits would make their own budget permanently
informational. Deterministic drift rejects during correctness; environment
drift retains applicable correctness checks and informational timing. Expensive
capture and gate execution belongs to full pre-push or explicitly selected
important steps, not every ordinary slice.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-applicability-identity-v1 -->
- Claim: The sealed v2 corpus binds capture policy `regression-promotion-policy/19cf4105...5ece` and capture revision `155aa22ea...bcb`. Requiring that revision to equal a future run would make every post-qualification performance verdict informational. Decision 0096's amended contract therefore retains revision as immutable provenance while exact environment and deterministic behavior identities decide enforcement eligibility; the immutable capture policy bytes and identity do not change. This repairs applicability semantics, not a budget, performance result, support tier, or capacity claim.
- Re-derive: Read the authenticated corpus report for its policy and capture revision, then run t1765. Require the original policy identity unchanged and the separately content-addressed applicability contract to name exact host/tool/guard/provider plus selection/workload/correctness projection fields.
- Falsify: Rehash an applicability contract that restores the capture revision as a runtime match dimension and require t1765 to reject it. Caller input must reject; deterministic mismatch must select correctness rejection, while environment mismatch must select correctness plus informational performance.
- Durability: Retain decision 0096, the executable policy, focused watcher, owning task, this chapter, bounded claim record, doctrine gates, and the work-unit Git commit.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-applicability-identity-v1 -->

### Authenticated current-budget qualification

The qualifier consumes the sealed v2 corpus in memory. It accepts only the
repository root, loads the authenticated complete corpus and all-profile store,
and does not accept caller-supplied evidence or a budget. It independently
recounts the validation plus three measured records for each selected profile;
checks clean revision, workload, host, tool, guard, provider, stage order,
process outcome, cleanup, and correctness; and reconstructs all measured wall
and CPU stage sums plus maximum process-tree RSS.

Applicability uses two separate identities. `evidence_revision` preserves the
capture commit as provenance. The performance-applicability identity combines
the repaired contract with the exact environment and a correctness projection
that retains every record's non-timing stage counts, artifact byte/hash rows,
and correctness-oracle evidence identities. This prevents a report-level
workload match from hiding changed generated bytes, semantic counts, or oracle
evidence. Canonical JSON number validation also prevents string `"1"` from
passing as numeric schema version or count `1`.

For each metric, the qualifier sorts the three accepted run totals, records
minimum/median/maximum/median absolute deviation, and applies the Decision 0056
formula with checked safe-integer addition and multiplication. The resulting
qualification rows are now sealed by the publication below, but remain
unenforced:

| # | selected route | wall ns | CPU ns | peak tree RSS bytes |
|---:|---|---:|---:|---:|
| 1 | semantic catalog / actions | 2,000,000,000 | 2,000,000,000 | 268,435,456 |
| 2 | bridge fanout / backend bindings | 18,325,000,000 | 18,165,000,000 | 671,088,640 |
| 3 | execution graph / bindings | 31,479,000,000 | 31,395,000,000 | 1,325,400,064 |
| 4 | checking state / random occurrences | 34,683,000,000 | 34,755,000,000 | 1,040,187,392 |
| 5 | SystemVerilog portable backend emission | 35,836,000,000 | 36,390,000,000 | 1,090,519,040 |
| 6 | portable VHDL backend emission | 24,033,000,000 | 24,270,000,000 | 922,746,880 |
| 7 | OSVVM backend emission | 27,891,000,000 | 25,305,000,000 | 956,301,312 |
| 8 | SystemVerilog portable runtime | 312,422,000,000 | 298,875,000,000 | 2,634,022,912 |
| 9 | portable VHDL runtime | 46,812,000,000 | 46,515,000,000 | 1,157,627,904 |
| 10 | OSVVM runtime | 194,013,000,000 | 176,235,000,000 | 1,694,498,816 |
| 11 | balanced portable SystemVerilog | 429,258,000,000 | 462,510,000,000 | 4,177,526,784 |

Re-derive the in-memory report without publishing it:

```sh
scripts/run_with_ram_guard.sh --process-max-rss-mb 4096 -- \
  perl -Iperl \
  -MFSM::VIAL::ArchitectureScaleRegressionPromotionQualification \
  -MJSON::PP -e \
  'print JSON::PP->new->canonical(1)->encode(FSM::VIAL::ArchitectureScaleRegressionPromotionQualification->derive({repository_root => "."})), "\n"'
```

Run the formula, projection, caller-sealing, type, overflow, and mutation
watcher with:

```sh
prove -Iperl -v t/1779-vial-regression-promotion-qualification.t
```

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-current-budget-qualification-v1 -->
- Claim: From the authenticated current v2 corpus, the in-memory qualifier independently reconstructs 11 validation and 33 measured records (44 accepted controller invocations, zero exclusions), retains all four records' exact non-timing correctness facts for each profile, and applies Decision 0056's integer-safe formulas. The resulting 11-profile report is 762,664 canonical bytes at identity `regression-promotion-qualification/d8fb1813...0c97`; its largest correctness projection is 165,285 bytes. The qualifier itself remains in-memory; its separately sealed publication does not activate a regression gate, support tier, performance result, or capacity claim.
- Re-derive: Run the guarded public derivation above against the authenticated current corpus. Require the exact 11/33/44/0 summary, 762,664-byte canonical report, d8fb1813...0c97 identity, eleven ordered budgets, and maximum 165,285-byte correctness projection; inspect the separate source-evidence, environment, correctness, formula, and applicability identities.
- Falsify: Run t1779. Historical policy, missing/reordered profiles, exclusions, failed or rewritten oracle evidence, mixed host, string-typed schema/count/artifact/run values, unsafe integers, addition overflow, rehashed budget changes, and rehashed applicability changes must all reject; the closed synthetic fixture must reproduce independently calculated floor, multiplier, and rounding examples.
- Durability: Retain Qualification, Policy's canonical-number repair, t1765/t1779, task `.17.5.3.1.2`, this chapter, bounded claim record, authenticated current-corpus and qualification-publication evidence, doctrine gates, and the work-unit Git commit. Enforcement remains separately owned by `.17.5.4`.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-current-budget-qualification-v1 -->

### Immutable qualification publication and CLI

The current-budget store and its explicit command now retain the real
first-version publication. Store `publish` and `load` accept only the
repository root and run beneath the repository RAM guard. Publication
additionally requires one unchanged clean Git revision. The store derives and
validates the qualifier's complete report internally; callers cannot supply
evidence, paths, budgets, a publisher revision, or a recalibration choice.

The fixed first-version coordinate is
`.artifacts/qualification/vial-scale/v2/regression-promotion-budget-qualification-v1/current/`.
It contains exactly
`regression-promotion-budget-qualification.json` and
`qualification-manifest.json`. The outer report preserves the exact in-memory
qualification unchanged, including its derivation-time nonclaims, while the
publication wrapper records that the qualification was sealed. The compact
manifest independently binds the publisher revision, source corpus and file
set, formula authority, summary, and every ordered profile's budget,
environment, provider, applicability, and correctness identities.

The initial-version contract is closed and content-addressed: there is no
predecessor, bytes cannot be overwritten, recalibration requires a separately
owned task with old-versus-new current-corpus qualifications, and rollback
removes consumers and gates before retiring immutable publication bytes.
Publication alone leaves performance enforcement `not_activated`.

Report reads are capped at 1,048,576 bytes and manifest reads at 65,536 bytes.
Both files and their directory are authenticated by exact census, canonical
newline JSON, digests, same-volume/current-owner/single-link checks, no-follow
stable reads, and post-read identity checks. Publication fsyncs both files and
directories before one directory rename. Only an exact sole interrupted stage
can recover; collisions, ambiguous or malformed stages, residue, aliases,
oversized state, and post-validation mutation reject.

The real publication was created from clean CLI revision
`8667f766cfb5721600c466568b432ac4432255f7`. It binds qualification
`regression-promotion-qualification/d8fb18132ebb52d85f30f40edc46f8e81a47bba90eb61f9bf02ae0821da60c97`,
source corpus
`regression-promotion-corpus/ab2df8992d85b8466f4afca530a5af36984031c453002534fc92ff5678a2e505`,
source file set
`dc5b315b827389eb466776716f6851cdd9ddd13b2f1aec441f8a51b7d72dc66f`,
and `decision-0056`. Its exact immutable identities and files are:

| item | exact value |
|---|---|
| publication report identity | `regression-promotion-budget-qualification-report/0da2324912a8ffcaa0c167e75a5ecac87911eb3bc44f6d8c2b128d07e869622c` |
| publication identity | `regression-promotion-budget-qualification-publication/1c2a3832b2b4163e1a6a8124feff2b452f8522c2929098447f3903115ad2945f` |
| complete file-set SHA-256 | `28ba972c3f8cbcc00d1d32c9db0d4015de57f0df49d11d7076262cd050069095` |
| report | 764,010 bytes; SHA-256 `524fad657f5f1b5d3bc6eb0287d86729af2d8ae9e725838a8305bd09f696a3fd` |
| manifest | 28,148 bytes; SHA-256 `5eebce24d05ef5493a4b42ab90c0114e45a49c2a169e22cb46c6af336ef69c62` |

The ordered applicability identities paired with the eleven budget rows above
are:

```text
 1 regression-promotion-profile-applicability/19ce6ee465015507745c6d8b4756af37771ac31bb6485a62ebc2b07c8dc69a29
 2 regression-promotion-profile-applicability/992ed88be3790e7dde0de8ff939902fbe32c2656487d5862f560dd75c29d9182
 3 regression-promotion-profile-applicability/405a1a9c981b0a640ea973d6328a4483fd59b62db39e38f7dc956320967fdb2b
 4 regression-promotion-profile-applicability/a13a3d33fb25a83480521a4c4b3283fe509ce1ca45e9c184c5ef251f0d0f24db
 5 regression-promotion-profile-applicability/352d896bd84b5a040158f2b92af65c9b7c6235ffe0412aa58cb184e852e23b91
 6 regression-promotion-profile-applicability/f61a57e40519c0d009c1e53ee0bfadcd18546fa58deed3a593ef44389cb74344
 7 regression-promotion-profile-applicability/10cff79f1ca3633c470f2cccb8af7cadfe909113e72c096d53dd06e045e09f24
 8 regression-promotion-profile-applicability/7985b5a4b9db7e69f5a00f390422e6b5064d40cffc13f742fd7912c517230dbc
 9 regression-promotion-profile-applicability/f8b0375359b6db5d3f9a4f6374844ff5460569ba8878d140d64279077945740d
10 regression-promotion-profile-applicability/302b0b561728d18d348d765f75269c16bc0eb579034ca9bbf367841f3de16339
11 regression-promotion-profile-applicability/25eeb66c5f3cd55d2192d924ca720810d74469d454dfc3d1e80ebfc410afeb7a
```

A distinct guarded `--validate` emitted 793,084 canonical newline JSON bytes
at SHA-256 `19ac96edf6ea6aafad80672084bf3f528a4944a6cf5df6264d524bc9e93f9d64`
and exactly reloaded both objects. Independent canonicalization and content-
identity reconstruction reproduced the report, publication, and file-set
identities above. The exact two-file census consists only of current-owner,
same-volume, single-link regular files; publication staging and temporary
validation output are absent. The manifest records 11 qualified profiles,
11 validation records, 33 raw records, 44 accepted controller invocations,
and zero exclusions. Its explicit nonclaims forbid interpreting publication
as a promoted gate, observed performance result, support promotion,
architecture-scale capacity, historical reuse, producer/provider/simulator/
controller execution, or profile recapture/resume.

Run the caller-sealing, storage, recovery, collision, cleanup, and race watcher
without creating the real publication:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl -v \
  t/1780-vial-regression-promotion-qualification-store.t
```

The executable exposes only explicit `--publish` and `--validate` operations:

```sh
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_regression_promotion_budget_qualification.pl --publish

scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_regression_promotion_budget_qualification.pl --validate
```

It derives the repository root from its own tracked location and admits no
caller root, evidence, budget, publisher, predecessor, worker, or callback.
Each operation delegates to the caller-sealed store exactly once. A successful
result is emitted only after the complete canonical newline JSON value fits
the 1,048,576-byte output envelope. Usage failures return status 2; operational
failures return status 1 with no JSON result and one sanitized diagnostic no
larger than 4,096 bytes. Standalone `--help` is the only success without an
operation. These commands do not execute a producer, provider, simulator, or
measurement controller; publication alone does not activate enforcement.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-budget-qualification-cli-contract-v1 -->
- Claim: The qualification CLI exposes only exact `--publish` and `--validate` operations, caps complete canonical newline JSON stdout at 1,048,576 bytes and one sanitized failure diagnostic at 4,096 bytes, uses status 2 for closed usage errors and status 1 for operational failures, and accepts no caller repository, evidence, budget, publication, or recovery input. The interface can invoke the separately authenticated real publication, but does not itself activate a performance gate, support tier, performance result, or capacity claim.
- Re-derive: Run t1781 and inspect the executable's exact options, store dispatch, result-key validation, canonical encoder, output ceiling, diagnostic ceiling, and repository-root derivation. Require fresh `publish` and `load` doubles to receive only the script-derived root and canonical output at the exact admitted ceiling.
- Falsify: Run t1781. No/multiple/case-variant/abbreviated/unknown options, positional arguments, help mixed with an operation, cap-plus-one output, malformed store state, and hostile multiline path-bearing oversized failures must reject with the exact status class, no partial JSON, bounded sanitized diagnostics, and no residue.
- Durability: Retain the executable, t1781, caller-sealed store, task `.17.5.3.2.2`, this chapter, the regression-promotion Knowledge card, bounded claim record, doctrine gates, and the work-unit Git commit. The real clean-revision publication is separately retained by `.17.5.3.2.3`.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-budget-qualification-cli-contract-v1 -->

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-budget-qualification-store-contract-v1 -->
- Claim: The caller-sealed current-budget qualification store fixes one two-file v2 coordinate for all 11 ordered qualified profiles, bounds report bytes at 1,048,576 and manifest bytes at 65,536, and permits at most one exact recovery stage before an atomic same-volume rename. These are immutable-storage containment and recovery limits; the stored real publication does not activate a performance gate, support tier, performance result, or capacity claim.
- Re-derive: Run guarded t1780, query `ArchitectureScaleRegressionPromotionQualificationStore->publication_limits`, and construct the private publication value from the public real qualification without invoking `publish`. Require the API, fixed file census, limits, exact 11-profile bindings, canonical bytes, and source qualification identity to agree.
- Falsify: Begin with t1780 RED against the missing store, then run it against the implementation. Caller evidence/path/budget input, qualification drift, malformed/noncanonical/cap-plus-one bytes, extra entries, symlink/hard-link aliases, exact/malformed/ambiguous recovery, collision, injected partial write, retained staging, and a late directory mutation must separate fail-closed behavior from the accepted exact publication and recovery controls.
- Durability: Retain QualificationStore, t1780, task `.17.5.3.2.1`, this chapter, the regression-promotion Knowledge card, bounded claim record, doctrine gates, and the work-unit Git commit. The explicit CLI and real clean-revision publication are separately retained by `.17.5.3.2.2` and `.17.5.3.2.3`.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-budget-qualification-store-contract-v1 -->

### Independent current-budget verification

The publication can be checked without loading any FSMGEN production module:

```sh
scripts/run_with_ram_guard.sh -- \
  scripts/verify_vial_regression_promotion_budget_qualification.pl
```

The verifier derives the repository root from its own tracked location and
accepts no arguments. It requires the exact canonical two-file namespace and
absent publication staging, authenticates the existing producer-independent
current-corpus result, then reloads every source profile itself. From those
records it reconstructs measurement and correctness identities, three-sample
statistics, Decision-0056 budgets, exact environment/provider/applicability
bindings, every profile qualification, the complete qualification, both outer
publication identities, and both length-delimited file-set identities. Its
single canonical newline JSON result appears only after every comparison
succeeds and must fit its declared result ceiling.

This verifier is read-only evidence for the sealed budgets. It does not
recapture measurements, mutate the publication, or activate performance
enforcement.

### Copied hostile qualification and applicability

Run the destructive controls only against a same-volume copy:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1783-vial-regression-promotion-budget-qualification-mutations.t
```

The suite copies the exact qualification, complete current corpus, and both
independent verifiers beneath `.artifacts/tmp/`. It first admits the copied
baseline. It then rejects independent changes to content, schema,
canonicality, numeric type, formula, budget, profile order/count,
host/tool/guard/provider/applicability fields, publisher/source/revision
provenance, historical evidence, namespace membership and shape, links,
collision, staging, and residue. Every rejection emits no partial JSON result;
every control restores the exact copied path/mode/link/owner/device/byte/hash
census, and a final complete verification must pass before the fixture is
removed. Inode-aware before/after censuses protect both real namespaces.

The authenticated applicability contract deliberately separates a later
revision from later evidence. Once correctness passes, exact deterministic and
environment identities are eligible for later performance enforcement. Host,
tool, guard, or provider drift keeps correctness mandatory but makes
performance informational. Selection, workload, or correctness-projection
drift rejects before performance, and an unavailable exact provider is never a
pass. Publication remains immutable: recalibration cannot overwrite the
current version and requires a separately owned new version with distinct old
and new current-corpus qualification evidence.

### Final current-budget publication agreement

The final watcher joins the independent and production authorities against the
unchanged real publication:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1784-vial-regression-promotion-budget-qualification-closeout.t
```

It takes inode-aware censuses of both real namespaces, runs the closed
independent verifier and production `--validate`, then compares the publisher,
source, report, publication, qualification, file-set, formula, summary, and
applicability identities. Every ordered profile must also agree on measurement
records, statistics, budgets, environment/provider state, and deterministic
correctness. Only complete bounded canonical results are admitted. The final
censuses must remain exact; qualification, profile, and corpus staging,
copied-fixture residue, and child processes must all be absent. This closes the
qualification evidence, but still does not activate performance enforcement.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-budget-qualification-publication-1c2a3832b-v1 -->
- Claim: From clean publisher revision `8667f766cfb5721600c466568b432ac4432255f7`, the real two-file current-budget qualification contains a 764,010-byte report at SHA-256 `524fad65...a3fd` and a 28,148-byte manifest at SHA-256 `5eebce24...9c62`. It binds qualification `d8fb1813...0c97`, report identity `0da23249...622c`, publication identity `1c2a3832...945f`, file-set digest `28ba972c...9095`, source corpus/file-set `ab2df899...e505`/`dc5b315b...c66f`, Decision 0056, all eleven ordered budget/applicability bindings, and exact 11/33/44/0 evidence. A distinct validation emitted 793,084 canonical bytes at SHA-256 `19ac96ed...9d64`. This is an immutable qualification seal, not an active gate, fresh performance result, support tier, or capacity claim.
- Re-derive: Run t1784 under the repository RAM guard. It must execute the independent verifier and production `--validate`, independently authenticate/reload the source, join exact measurement, correctness, statistic, budget, environment, provider, applicability, profile, qualification, publication, and file-set identities, reproduce the exact 793,084-byte production result/digest, and preserve both real censuses.
- Falsify: T1782 began RED for the missing independent verifier; t1783 began RED for the missing hostile suite; t1784 began RED for the missing final join. Run t1780+t1781+t1782+t1783+t1784. Production controls must reject unsafe storage and invocation; independent controls must reject every named copied content/schema/type/formula/budget/identity/provenance/path/alias/collision/staging/residue mutation without partial output, restore the copy exactly, distinguish environmental from deterministic drift, forbid provider-unavailable pass, and make any independent/production identity disagreement or residue fail final closeout.
- Durability: Retain the immutable publication, store/CLI, both independent verifiers, t1780/t1781/t1782/t1783/t1784, completed `.17.5.3`, this chapter, the Knowledge card, claim record, doctrine gates, and Git commits. `.17.5.4` separately owns gate activation and CI placement.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-budget-qualification-publication-1c2a3832b-v1 -->

### Stable regression-gate contract

The regression gate now has a caller-sealed metadata contract before any
execution or CI wiring. It accepts only the repository root under the active
RAM guard, authenticates the immutable current qualification, derives the
canonical capture plan independently, and joins every ordered adapter dispatch
to its workload, correctness, provider, environment, applicability, and frozen
budget binding. Contract derivation invokes no producer, provider, simulator,
measurement controller, or publication path.

Each future complete gate run is fixed at one validation plus three fresh raw
measurements for every selected profile. Correctness and the exact selection,
workload, and non-timing correctness identities are admitted before any timing
classification. The maximum fresh wall, CPU, and tree-RSS value is compared to
the corresponding frozen budget only when host, tool, guard, and provider
identity all match. An unmatched environment still requires correctness but
reports timing as informational; an unavailable exact provider is
`unavailable`, never `pass`. There is no caller performance override.

Gate observations and qualification evidence have deliberately different
lifecycles. A completed result will atomically replace one bounded latest
observation below
`.artifacts/qualification/vial-scale/v2/regression-promotion-gate-v1/current/`.
An interrupted run preserves the preceding result and removes owned staging.
The latest observation cannot overwrite the qualification, supply calibration
evidence, or rewrite a budget. Ordinary commits keep focused checks; the
complete gate belongs to full pre-push and selected important steps, with
hosted performance classification derived from identity rather than a bypass
flag.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-gate-contract-v1 -->
- Claim: The metadata-only regression-gate contract authenticates the current qualification publication/file set, joins all eleven ordered canonical dispatches to their exact frozen evidence, and requires 11 validations plus 33 fresh raw measurements (44 controller invocations). It fixes maximum-per-metric comparison after correctness, exact-environment-only enforcement, informational unmatched performance, unavailable-not-pass provider status, and no caller override. The real contract identity is `regression-promotion-gate-contract/0150f4b3...e368`; its selected result/profile/IPC/error ceilings are 1,048,576/67,108,864/65,536/4,096 bytes with one recovery entry. These are execution, applicability, and containment rules, not an executed gate, observed performance result, support tier, or capacity claim.
- Re-derive: Run guarded exact t1785. Public derivation must authenticate qualification publication 1c2a3832...945f and file set 28ba972c...9095, reproduce contract 0150f4b3...e368, join all 11 profiles and 11/33/44 counts, preserve every frozen budget, and execute no producer.
- Falsify: T1785 began RED for the absent authority, poisons every work entrypoint during successful derivation, and rejects plan, order, manifest, provider, correctness, budget, applicability, immutability, schema, and dispatch drift. Caller evidence, absent guards, borrowed invocants, and returned-value mutation cannot alter the contract.
- Durability: Retain Decision 0097, ArchitectureScaleRegressionPromotionGateContract, t1785, task `.17.5.4.1`, the mdBook, compact regression-promotion Knowledge card, bounded claim record, doctrine watchers, and work-unit Git commit. Children `.17.5.4.2` through `.4` own execution, CI placement, and independent closeout.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-gate-contract-v1 -->

Re-derive the real metadata contract without running a scale producer:

```sh
scripts/run_with_ram_guard.sh -- env \
  FSMGEN_VIAL_REGRESSION_GATE_CONTRACT_EXACT=1 \
  prove -Iperl -v \
  t/1785-vial-regression-promotion-gate-contract.t
```

### One-profile gate execution and classification

The first execution layer now accepts only `repository_root` plus one qualified
ordinal, derives the authenticated gate contract internally, and requires one
unchanged clean revision under the active RAM guard. For an available profile,
one fresh child invokes the selected canonical adapter exactly once; that
adapter owns the required validation record and three raw measurement records.
The adapter validates the complete report in the child and again in the parent.

The report may be much larger than the 65,536-byte worker IPC envelope. The
profile authority therefore creates a current-owner, mode-0600, same-volume
temporary file at the repository root and unlinks its name immediately. The
child writes canonical report bytes through the inherited descriptor, while
IPC carries only bounded content-addressed result metadata. The parent reloads
the complete anonymous spool, checks its byte count and SHA-256, revalidates the
report, reconstructs the result, and closes the last descriptor. No report path
or repeatable calibration artifact remains.

Admission reuses the qualification authority's exact non-timing projection and
record accounting through an exact-caller seam. Selection coordinates,
workload, ordered validation/measurement records, clean common identity,
correctness projection, oracle/artifact facts, and zero residue must agree
before timing is considered. Each fresh metric is reduced by maximum. Exact
environment equality applies the inclusive frozen threshold as `pass` or
`fail`; a different host/tool/guard/provider tuple is `informational`. A missing
required exact executable or repository-local provider is `unavailable`, never
`pass`; a present wrong version or changed provider bytes is identity drift and
rejects.

Three runtime routes need a narrower definition of cross-run correctness.
OSVVM/GHDL, portable-Verilator, and portable-VHDL/GHDL lifecycle evidence
include fresh monotonic process telemetry. Evidence sizes/digests, transitive
handle digests, oracle evidence identities, and stage byte totals can therefore
change even when the workload, source, provider, normalized result, outcomes,
and semantic counts agree. The portable emit stage precedes process capture and
remains exact.

Raw projection identity equality is still the first path. Only a mismatch
retrieves authenticated full current and qualified projections through the
caller-sealed seams. Exact schema/backend coordinates select one table entry:

- ordinal 10 OSVVM normalizes six evidence, five handles, six oracle identities,
  and six stage-byte positions per record: `4 x 29 = 116` fields;
- ordinal 9 portable VHDL/GHDL normalizes the same six/five/six/six partition,
  with an explicitly authenticated distinct publish-evidence kind:
  `4 x 29 = 116` fields;
- ordinal 8 portable Verilator normalizes five evidence, four handles, five
  oracle identities, and five stage-byte positions: `4 x 24 = 96` fields.

The other eight profiles remain raw-exact. Scalar shape, digest form, stage,
kind, count, order, and uniqueness fail closed; every unlisted field compares
canonically. Admission retains the immutable qualified identity. This is not
recalibration and changes no qualification byte, budget, provider rule, or
semantic oracle.

The worker envelope and error text remain bounded and canonical. Timeout,
exception, exit, signal, malformed or oversized IPC/report bytes, record
reordering, numeric-looking strings, mixed revisions, adapter mutation, or a
surviving process-group member reject without leaving the anonymous spool.
The default watcher uses deterministic synthetic reports and invokes no real
provider or simulator:

```sh
prove -Iperl -v \
  t/1786-vial-regression-promotion-gate-profile.t \
  t/1793-vial-regression-promotion-gate-correctness-stability.t
```

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-gate-profile-execution-v1 -->
- Claim: The one-profile gate runs one validation and three raw measurements in a fresh child, revalidates the report in its parent, and passes the complete report through an unlinked same-volume spool with 67,108,864-byte report and 65,536-byte IPC ceilings. Correctness precedes timing: raw identity remains exact, while exact ordinal 10, 9, and 8 projections exclude respectively 116, 116, and 96 sealed process-telemetry derivatives and require every other field to match; the other eight profiles remain raw-exact. Exact-host thresholds pass or fail, unmatched hosts are informational, and unavailable providers cannot pass. This is a correctness-comparison repair, not recalibration, a complete real-gate result, support, or capacity.
- Re-derive: Run guarded t1785+t1786+t1793. Require authenticated defensive full-projection retrieval, one child producer and two report validations, exact 1/3/4 record accounting, ordinal 10 and 9's 4 x 29 plus ordinal 8's 4 x 24 partitions, eight other profiles raw-exact, inclusive thresholds, identity-derived classifications, and no spool residue.
- Falsify: T1793's portable-Verilator and portable-VHDL cases began RED at lines 324 and 490, then reject semantic, missing/new/duplicate, digest/byte shape, order, and foreign-backend changes while retaining the OSVVM matrix. T1786 rejects all three routes' adjacent correctness drift before timing plus caller, guard, record, provider, worker, IPC, report, and residue attacks.
- Durability: Retain Decision 0099, both caller-sealed seams, table-driven comparator, t1785/t1786/t1793, repair leaves `.17.5.4.4.1`, `.17.5.4.4.2.1`, and `.17.5.4.4.2.2.1`, this chapter, its Knowledge card and claim record, doctrine gates, and Git. Child `.2.2.2` owns clean production closeout.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-gate-profile-execution-v1 -->

### Eleven-profile in-memory gate coordination

The aggregate layer exposes one root-only `run` operation. It derives the
authenticated gate contract once, freezes the clean execution revision and
contract bytes, then visits ordinals 1 through 11 exactly once in plan order.
Each visit uses the profile authority's coordinator-only execution seam; the
public one-profile route remains root-plus-ordinal and continues to derive its
own authority. The coordinator re-admits every returned profile through a
separate caller-sealed profile validator before retaining it.

The in-memory result carries all eleven complete profile results and their
qualification, publication, file-set, contract, selection, revision,
correctness, environment, provider, performance, cleanup, and content
identities. A second complete readmission pass reconstructs every count and
classification. Changed contract bytes, a worker mutating an earlier returned
result, mixed observed host or guard state, duplicate identity, or changed
profile order therefore rejects rather than entering the aggregate.

Required workload and observed work are deliberately separate. The contract
always retains 11 validation, 33 raw-measurement, and 44 controller-invocation
requirements with zero exclusions. When every provider is available, observed
counts must reproduce all three totals. An unavailable exact provider reports
zero fabricated observations for that profile, so the aggregate preserves the
required totals while reporting lower observed totals and an incomplete
observation. Aggregate precedence is `fail`, then `unavailable`, then
`informational`, then `pass`.

The canonical aggregate is content-addressed and must fit the contract's
1,048,576-byte result ceiling. This layer writes no result, qualification,
corpus, staging tree, or other artifact; atomic latest-result replacement
remains the next child. The default watcher substitutes only the sealed
profile-worker boundary and executes no producer or simulator:

```sh
prove -Iperl -v \
  t/1786-vial-regression-promotion-gate-profile.t \
  t/1787-vial-regression-promotion-gate-coordinator.t
```

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-gate-coordination-v1 -->
- Claim: The root-only regression-gate coordinator derives one authenticated contract, visits all eleven ordinals exactly once in plan order through the caller-sealed profile authority, re-admits every full profile result, and content-addresses one canonical in-memory aggregate bounded at 1,048,576 bytes. Its required 11 validation, 33 raw-measurement, and 44 controller-invocation totals remain distinct from honest observed counts when an exact provider is unavailable; zero exclusions are admitted. Aggregate precedence is fail, unavailable, informational, then pass. This is synthetic-watched coordination machinery, not result publication, a real gate run, an observed performance claim, CI activation, support, or capacity.
- Re-derive: Run t1786 plus t1787 and inspect ArchitectureScaleRegressionPromotionGateCoordinator with GateProfile's exact-caller execution and admission seams. Require one contract derivation, ordinals 1 through 11 once in order, exact complete 11/33/44/0 evidence for the all-available control, bounded content identity, no artifact, honest unavailable counts, and all four aggregate precedence outcomes.
- Falsify: T1787 began RED on the absent coordinator, then rejects caller authority, missing/extra/duplicate/reordered profiles, mixed contract/qualification/file-set/revision/host/guard/provider state, classification or threshold forgery, malformed or oversized results, child failure, repository mutation, worker-side contract mutation, post-admission evidence mutation, and process residue. The synthetic worker boundary poisons real production execution by construction.
- Durability: Retain ArchitectureScaleRegressionPromotionGateCoordinator, GateProfile's sealed seams, t1786/t1787, task `.17.5.4.2.2`, this chapter, the compact regression-promotion Knowledge card, bounded claim record, doctrine watchers, and the work-unit Git commit. Children `.2.3` and `.2.4` still own latest-result publication, CLI integration, and adversarial closeout; `.3` and `.4` still own CI placement and independent real execution.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-gate-coordination-v1 -->

### Atomic latest gate-result storage

The result store exposes exact-class `publish({repository_root})` and
producer-free `load({repository_root})` operations. It independently derives
the current gate contract; neither operation accepts a result, contract, path,
budget, applicability tuple, or qualification from its caller. Publication
executes the coordinator only when no recovery stage exists, then re-admits
the complete aggregate through the coordinator's store-only validator. Load
re-admits stored bytes but never executes a producer.

The only current coordinate is
`.artifacts/qualification/vial-scale/v2/regression-promotion-gate-v1/current/regression-promotion-gate-result.json`.
Its canonical newline-terminated JSON is bounded at 1,048,576 bytes. The store
writes a mode-0600 content-addressed file beneath the contract's same-volume
staging root, flushes and syncs the file and directories, reloads and validates
the exact bytes, checks that the preceding target did not change, and only
then atomically renames over `current`. The preceding valid observation
therefore remains visible if execution or staging fails before replacement.

At startup, publication recovers at most one valid stage whose filename,
digest, current execution revision, current contract, qualification
publication, qualification identity, and qualification file set all agree.
Malformed or ambiguous owned stages are rejected and removed. Successful,
failed, recovered, unchanged, and loaded paths leave no staging tree. Result
files and staging entries must be real current-owner, same-device, one-link
regular files whose pathname and handle identities remain unchanged; aliases,
special files, oversized or noncanonical bytes, and post-validation mutation
fail closed.

The store reads a preceding result only after new coordination, solely to
validate the replacement target. It never treats that observation as
qualification, calibration, budget, applicability, or execution input. The
immutable two-file qualification namespace remains byte-separate. This layer
provides storage machinery, not a CLI, CI activation, real gate execution,
observed performance, support, or capacity. Its synthetic watcher is:

```sh
prove -Iperl -v \
  t/1787-vial-regression-promotion-gate-coordinator.t \
  t/1788-vial-regression-promotion-gate-store.t
```

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-gate-latest-result-store-v1 -->
- Claim: The exact-caller regression-gate result store accepts only a complete coordinator result against an independently derived current contract and publishes canonical newline-terminated JSON at one fixed qualification-distinct coordinate under a 1,048,576-byte ceiling. It fsyncs one same-volume content-addressed stage and its directories, reloads exact bytes, then atomically replaces the latest observation; interruption before replacement preserves the preceding valid result. It recovers at most one exact current-revision stage and leaves owned staging absent after success, rejection, recovery, unchanged publication, or load. Prior results are never qualification, calibration, budget, applicability, or execution inputs. This is synthetic-watched storage machinery, not a real gate run, CI activation, observed performance, support, or capacity.
- Re-derive: Run t1787 plus t1788 and inspect GateStore with Coordinator's store-only admission seam. Require the fixed coordinate, 1,048,576-byte ceiling, independent contract derivation, producer-free load, exact canonical bytes, file/directory sync, one same-volume stage, atomic published/replaced/recovered/unchanged states, prior-byte preservation on injected pre-rename failure, and absent staging.
- Falsify: T1788 began RED on the absent store, then rejects caller-selected results or paths, qualification/result coordinate aliasing, stale or mixed evidence, malformed, noncanonical, or cap-plus-one bytes, digest mismatch, invalid or ambiguous stages, symlink, hardlink, FIFO, wrong-device identity, post-validation target mutation, and direct coordinator-seam use. Every owned-stage failure control proves cleanup; adjacent t1787 proves only the exact store path readmits a complete aggregate.
- Durability: Retain ArchitectureScaleRegressionPromotionGateStore, Coordinator's exact-store admission seam, t1787/t1788, task `.17.5.4.2.3`, the mdBook chapter, compact regression-promotion Knowledge card, bounded claim record, doctrine watchers, and work-unit commit. Child `.2.4` still owns the explicit CLI and adversarial public-path closeout; `.3` and `.4` still own CI placement and independent real execution.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-gate-latest-result-store-v1 -->

### Explicit gate command

The repository-relative gate command has no default operation. It accepts
exactly one case-sensitive, unabbreviated `--run` or `--validate-result`:

```sh
# Expensive: execute all eleven profiles and replace the latest observation.
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_regression_promotion_gate.pl --run

# Producer-free: authenticate and print the stored result.
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_regression_promotion_gate.pl --validate-result
```

`--run` invokes the result store's public publication operation, then reloads
through its producer-free public load operation. `--validate-result` only
loads. Both paths validate the store envelope, artifact metadata, and the
coordinator's closed result field set before printing only the canonical gate
result. The repository root comes from the tracked script location; callers
cannot inject a path, result, qualification, budget, applicability identity,
provider, worker, callback, or performance downgrade.

Complete newline-terminated stdout is buffered through the same 1,048,576-byte
gate-result ceiling. Exact-cap output succeeds and cap-plus-one returns status
1 with no partial JSON. Operational failures emit one repository-path-
sanitized printable diagnostic bounded at 4,096 bytes before output begins. Omitted, repeated,
combined, abbreviated, case-variant, unknown, positional, or help-plus-
operation selections return usage status 2; standalone `--help` is the only
non-operation success.

T1789 exercises copied fresh-process command/store fixtures without a real
producer. Together, t1786-t1788 retain the deterministic profile, aggregate,
and same-volume hostile storage controls beneath that public boundary. Full
real execution and CI placement remain separate rollback owners.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-gate-cli-contract-v1 -->
- Claim: The repository-relative regression-promotion gate CLI accepts exactly one explicit `--run` or producer-free `--validate-result`, derives its root only from the tracked script, validates the public store result and coordinator field set, and buffers only canonical newline gate-result JSON through a 1,048,576-byte stdout ceiling. Exact-cap output succeeds; cap-plus-one or any pre-output operational failure returns status 1 with empty stdout and one sanitized diagnostic bounded at 4,096 bytes. Closed usage returns status 2, and no caller flag supplies evidence, coordinates, applicability, or an enforcement downgrade. This is synthetic-watched command machinery, not a real gate result, CI activation, support, or capacity.
- Re-derive: Run t1789 and inspect run_vial_regression_promotion_gate.pl. Require script-derived roots, `--run` dispatch to publish then producer-free load, `--validate-result` dispatch to load only, exact store/result field admission, canonical exact-cap stdout, stable statuses, bounded error text, and no copied fixture residue. Run t1786-t1788 alongside it to retain deterministic worker, aggregate, and atomic-store behavior beneath the command.
- Falsify: T1789 began RED because the runner path was absent, then rejects no, repeated, combined, positional, unknown, abbreviated, case-variant, repeated-help, and help-plus-operation selection; malformed publish/load/artifact/result shapes; result-limit drift; cap-plus-one output; and hostile path, control-character, multiline, and oversized failures without partial stdout. T1786-t1788 separately reject threshold, identity, provider, worker, IPC, filesystem, interruption, recovery, mutation, and residue attacks.
- Durability: Retain the executable gate runner, t1789 plus t1786-t1788, completed implementation parent `.17.5.4.2`, this mdBook chapter, compact regression-promotion Knowledge card, bounded third-shard claim record, doctrine watchers, and work-unit commit. `.17.5.4.3` and `.17.5.4.4` still own CI placement and independent real execution.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-gate-cli-contract-v1 -->

### Regression-gate CI evidence contract

A fresh checkout initially has no generated current corpus or budget
qualification because those coordinates live beneath ignored `.artifacts`.
Decision 0098's durable source exists under
`vial/qualification/regression_promotion_gate/evidence-v1/`: fifteen
byte-identical canonical JSON payloads plus one closed manifest. The manifest
orders all 13 corpus and two qualification files, fixes each generated
destination, and binds the 7,012,284-byte payload as transport
`regression-promotion-gate-evidence-transport/3b4c486e...2bbc6`. Its 8,388,608-
byte payload ceiling and 32,768-byte manifest ceiling are transport bounds,
not product capacities.

Authenticate the tracked source without creating or changing `.artifacts`:

```sh
perl scripts/verify_vial_regression_promotion_evidence_transport.pl
```

The repository-derived command accepts no caller path, root, source, evidence,
identity, or destination. It imports no production module; requires the exact
ordinary same-device, single-link file/directory census; rejects unsafe paths,
links, aliases, special nodes, noncanonical JSON, and byte/digest/identity
drift; and independently re-derives the corpus and qualification content
seals. Its canonical result inventories all fifteen payloads and is itself
content addressed. T1790 repeats the valid pass from a copied bundle, mutates
each admission boundary, and proves the tracked source and existing generated
coordinates remain byte-identical.

Materialize the authenticated bytes at their fixed generated coordinates,
validate both production consumers, then remove only roots owned by that
invocation:

```sh
perl scripts/materialize_vial_regression_promotion_gate_evidence.pl materialize
perl scripts/verify_vial_regression_promotion_current_corpus.pl
perl scripts/verify_vial_regression_promotion_budget_qualification.pl
perl scripts/materialize_vial_regression_promotion_gate_evidence.pl cleanup
```

The materializer accepts only `materialize` or `cleanup`; no option supplies a
root, source, destination, identity, receipt, or overwrite policy. It takes one
nonblocking exclusive lock through the read-only authenticated manifest, stages
the complete bundle below an identity-scoped repository-volume transaction,
writes a closed canonical journal and pending receipt, atomically installs the
corpus first, and installs qualification last as the commit point. An exact
existing pair is idempotent. A mismatch is never replaced.

The committed receipt distinguishes a fresh invocation's two created roots
from an exact pair that the command merely adopted. Cleanup reauthenticates the
source, receipt, complete destination census, file bytes/digests, and
filesystem identities; it removes qualification before corpus only when the
receipt owns both. An interrupted invocation resumes only the exact journal,
stage, pending receipt, and installed-root combinations reachable at the named
commit boundaries. T1791 exercises those recoveries in a copied fresh checkout,
runs both production validators after each recovery, and rejects malformed,
stale, mixed, linked, aliased, special-file, partial, mutated, concurrent, and
caller-controlled state. Both operations emit one canonical result bounded at
32,768 bytes and emit no partial result on failure. Neither operation executes
the regression gate.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-evidence-materialization-v1 -->
- Claim: The repository-derived evidence materializer accepts exactly `materialize` or `cleanup`, stages the authenticated 15-file/7,012,284-byte transport through one nonblocking manifest lock and one identity-scoped same-volume journal, installs corpus before qualification, and records whether it created two exact roots or adopted zero. Exact existing evidence is idempotent, mismatches never overwrite, recovery admits only reachable transaction states, cleanup removes only receipt-owned exact roots, and canonical result output is bounded at 32,768 bytes. This transports accepted evidence; it does not execute the gate, providers, CI, performance enforcement, support promotion, or capacity qualification.
- Re-derive: Run t1791 under the repository RAM guard. Its copied fresh checkout must materialize the exact bundle, pass the production current-corpus and budget-qualification validators after fresh installation and every interrupted-boundary recovery, return canonical content-addressed results, preserve adopted roots, and leave no owned state after cleanup.
- Falsify: T1791 starts from the absent executable, then rejects missing/extra/unknown caller operations, concurrent lock ownership, source and destination drift, partial destinations, stale identity namespaces, noncanonical or mixed journal/receipt/stage state, extra/missing payloads, symlinks, hardlinks, FIFO nodes, and unsafe cleanup with empty stdout. Boundary interruptions must recover the exact transaction; hostile nodes and unowned adopted roots must survive cleanup.
- Durability: The executable materializer, authenticated tracked bundle/verifier, t1791, production corpus/qualification validators, Decision 0098, owning task, Knowledge Map card, claim record, mdBook chapter, doctrine gates, and work-unit commit retain the behavior. Local and hosted CI remain separately owned by `.17.5.4.3.2.3` and `.17.5.4.3.3`.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-evidence-materialization-v1 -->

### Local regression-gate placement

The selected-important-step and unsharded pre-push entrypoints are now:

```sh
# Run only the authenticated architecture-scale gate lifecycle, then the book.
./bin/ci-regression vial-gate

# Run ordinary Perl regression, the same gate lifecycle once, then the book.
./bin/ci-regression
```

Pass `--no-book` only when the book check is deliberately owned elsewhere.
Both paths materialize authenticated evidence, run the current-corpus and
budget-qualification validators, execute `--run` beneath
`scripts/run_with_ram_guard.sh`, and invoke receipt-bounded cleanup. Unsharded
`full` enters that sequence only after ordinary regression succeeds. Quick,
smoke, ISF, direct tests, and all current hosted shard options remain gate-free.

After materialization succeeds, cleanup is attempted exactly once even when a
validator, the RAM guard, or the gate fails. The primary failure status wins;
a simultaneous cleanup failure is also diagnosed. A cleanup-only failure after
a successful gate becomes the command failure. Materializer receipt semantics
preserve exact adopted evidence, while newly installed evidence is removed.
Cleanup never targets the qualification-distinct latest observation, so a
successful gate result remains available for producer-free validation.

T1183 first failed on the absent mode and zero full-path gate commands. Its
GREEN watcher checks dry-run order and command cardinality, then uses a copied
driver plus five fixed command stubs to inject materializer, validator, guard, gate, and
cleanup failures without executing the real eleven-profile workload. Hosted
workflow wiring is now complete; independent real gate execution remains a
separate owner.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-local-ci-placement-v1 -->
- Claim: Local `vial-gate` and unsharded `full` share one ordered five-step regression-promotion lifecycle: authenticated materialization, two production evidence validators, one RAM-guarded `--run`, and receipt-bounded cleanup. Full enters it once after ordinary Perl regression. Quick, smoke, ISF, direct tests, and each current hosted shard family remain gate-free. Cleanup is attempted once after successful materialization on success or downstream failure, preserves adopted evidence and the latest observation, and propagates cleanup or primary failure without converting either to success. This is local CI placement, not a real gate observation, hosted activation, recalibration, support, or capacity evidence.
- Re-derive: Run `prove -Iperl t/1183-ci-regression-tier-selection.t`, inspect `bin/ci-regression`, and compare `vial-gate --dry-run --no-book` with unsharded and each hosted-shard `full --dry-run --no-book`. Require the selected five-command order, one post-regression full occurrence, one RAM-guarded gate command, and zero occurrences in every excluded mode.
- Falsify: T1183 began RED because `vial-gate` was unknown and unsharded full selected zero gate commands. Its copied-driver stubs now fail materialization, either validator, the guard, gate, and cleanup independently at status 23; every post-materialization failure attempts cleanup exactly once, failure remains nonzero, case-variant mode and selected/hosted mixing reject, and no real gate runs.
- Durability: Retain `bin/ci-regression`, t1183, the materializer and production validators, common RAM guard, gate CLI, Decision 0098, owning task, Knowledge Map card, this chapter, bounded claim record, doctrine watchers, and work-unit commit. Hosted wiring is retained by `.17.5.4.3.3`; `.17.5.4.4` independently owns real execution closeout.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-local-ci-placement-v1 -->

The hosted provider contract installs no substitute runtime tool. It
materializes exact OSVVM 2026.05, rejects an ambient Verilator or fixed GHDL
artifact before execution, and runs every provider-free or
repository-materialization profile under the RAM guard. The exact
Verilator/GHDL runtime profiles must report `unavailable`; available Ubuntu
measurements remain informational because their host identity differs from the
qualification. This preserves useful correctness work without turning absence
or a near-version tool into a performance pass.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-hosted-evidence-selection-v1 -->
- Claim: A tracked-only fresh checkout keeps the current corpus and qualification absent from ignored generated coordinates but carries their exact 15-file/7,012,284-byte canonical transport under `vial/qualification/regression_promotion_gate/evidence-v1/`. The 8,725-byte manifest binds transport `3b4c486e...2bbc6` and the accepted corpus/qualification seals; a caller-closed, read-only, production-independent verifier reproduces them. Hosted selection remains 8 available profiles with informational timing plus three unavailable exact-runtime profiles. This is authenticated source and provider selection, not materialization, CI activation, a gate result, support, or capacity.
- Re-derive: Run the transport verifier and require verification `ae9c67c9...55b6`, census 15/7,012,284, manifest 8,725/`d20cae85...94f7`, and source file sets `dc5b315b...c66f`/`28ba972c...9095`. Run both generated-source verifiers, byte-compare generated and tracked payloads, and inspect the qualification for the 8-available/3-unavailable provider partition.
- Falsify: T1790 copies the source and rejects schema, order, path, byte, digest, identity, source-seal, canonicality, payload-schema, extra/missing, link, alias, FIFO, and caller-input mutations with empty result output, then restores the identity. Running only the verifier against empty generated coordinates proves source authentication does not materialize; regeneration, mutable cache/artifacts, substitute tools, archives, and caller evidence fail the fixed seal.
- Durability: The tracked payloads, manifest, verifier, t1790, Decision 0098, task tree, Knowledge Map card, claim record, chapter, and work-unit commit retain the source/provider selection. `.17.5.4.3.2.2` supplies authenticated materialization and `.17.5.4.3.3` supplies the distinct hosted consumer.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-hosted-evidence-selection-v1 -->

### Hosted regression-gate placement

The regression workflow now has a seventh required family: one unsharded VIAL
gate on Ubuntu 24.04 with exact Perl 5.32. It installs no HDL runtime package,
rejects ambient Verilator and both fixed GHDL 6.0.0 coordinates, recursively
materializes OSVVM 2026.05 at commit
`2f7c391051dfb11890fa4bdbda9918d1db492250`, and invokes the same public
`./bin/ci-regression vial-gate --no-book` command as local selected execution.
The terminal `build` job consumes this family's result alongside the six prior
families, so it cannot silently skip the gate.

After the public lifecycle publishes and reloads its result, a separate
argument-free verifier reads only the fixed latest-result coordinate beneath
the RAM guard. It independently requires canonical newline JSON and
content-addressed aggregate/profile identities, the exact immutable
qualification references, aggregate `unavailable`, ordinals 1-7 and 11 as
`accepted_informational`, ordinals 8-10 as `unavailable` rather than `pass`,
required topology 11/33/44, and honest observed topology 8/24/32. Run that
postcondition against a retained result with:

```sh
./scripts/run_with_ram_guard.sh -- \
  scripts/verify_vial_regression_promotion_hosted_result.pl
```

An `always()` step re-enters receipt-bounded evidence cleanup, then removes the
preflight-proved OSVVM source, latest-result directory, and result publication
stage and asserts every selected coordinate is absent. T1183 inventories all
seven family dependencies, 17 immutable action uses, and exact ordinary,
dedicated, corpus, and dynamic test ownership. T1792 exercises the verifier in
a copied repository without a real gate: qualification, topology, host
classification, unavailable-not-pass, content identity, canonicality, caller,
guard, and staging mutations all reject with no partial acceptance output.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-hosted-ci-placement-v1 -->
- Claim: Hosted regression CI configures seven required families, including one unsharded VIAL gate on Ubuntu 24.04 with Perl 5.32. That family installs no HDL runtime package, rejects ambient Verilator and fixed GHDL coordinates, materializes exact OSVVM 2026.05, invokes the public `vial-gate` command, and independently requires an unavailable aggregate with eight informational and three unavailable-not-pass profiles plus required 11/33/44 and observed 8/24/32 topology. The final aggregate consumes the gate result, and always-cleanup covers only owned evidence, OSVVM, result, and staging coordinates. This is workflow placement, not evidence that hosted execution completed and not a performance, support, or capacity claim.
- Re-derive: Inspect `.github/workflows/regression.yml`, run guarded t1183+t1792, and require one non-matrix `vial_gate` job, exact provider preflight/materialization, the public gate command, guarded independent verifier, always-cleanup, seven aggregate dependencies, 17 pinned action uses, and complete disjoint ownership of every tracked `t/*.t` by the four existing test families.
- Falsify: T1183 began RED with no seventh job, gate dependency, result variable, or two associated action uses. Its workflow oracle rejects a missing provider boundary, OSVVM pin, public command, guarded verifier, cleanup, aggregate edge, test owner, or immutable action pin. T1792 rehashes hostile canonical fixtures and rejects qualification, topology, informational-host, unavailable-not-pass, profile identity, canonical-byte, caller, guard, and staging drift without executing a producer.
- Durability: Retain the regression workflow and README, hosted-result verifier, t1183, t1792, Decision 0098, owning task, Knowledge Map card, mdBook chapters, bounded claim record, doctrine gates, and work-unit commit. `.17.5.4.4` independently owns real gate execution and residue closeout.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-hosted-ci-placement-v1 -->

The first hosted execution of that placement did not complete cleanly.
Push `54ac1c22d` ran the public `vial-gate` command in
[Perl FSM Regression run 35782532228](https://github.com/rdje/fsmgen/actions/runs/35782532228),
job `106931292867`. Evidence materialization and both production validators
completed. The guarded gate step then failed before any profile result existed:

```text
calibration closure publication root is absent
```

`ArchitectureScaleRegressionPromotionPolicy->derive` asked
`validate_complete_publication` for the historical closure at ignored
`.artifacts/qualification/vial-scale/v1/calibration-closure-v1`. A fresh
checkout does not carry that publication, so the isolated worker stopped in
`_publication_metadata`. The independent
verifier was skipped. That absence is the released-log cause. It is distinct
from the published contract, which still requires an unavailable aggregate,
and from the local exact-pinned observation, which passed every selected
profile.

Public derivation now loads the tracked seal at
`vial/qualification/regression_promotion_policy/regression-promotion-policy-v1.json`.
That document is the already-pinned policy object. It keeps the historical
disposition and does not make historical evidence current. A fresh checkout
can load it without the ignored publication. The published hosted contract
still names an unavailable aggregate; this alignment does not invent a hosted
pass. A failed or unavailable hosted run remains neither support nor capacity.

The same push failed every Perl-file shard. The released logs name separate
families, and the terminal build job failed because those families failed:

- Paired-busy alias tests reached `yosys_synthesis` and stopped with
  `status=timed_out`.
- OSVVM runtime admission stopped at
  `ArchitectureScaleOSVVMRuntimeMaterialization` because the artifact graph
  failed its exact oracle.
- Several regression-promotion tests still read ignored
  `.artifacts/qualification/vial-scale` paths that a fresh checkout does not
  carry. The policy and capture-plan mutation checks now skip that ignored
  closure when it is absent. The profile-store checks skip that same closure
  the same way. The corpus-store checks skip that same closure the same
  way. The revision-1 publication census skips that ignored tree the same
  way. The current-corpus verifier and its mutation checks skip that ignored
  corpus the same way. The budget-qualification verifier, its mutation
  checks, and its closeout skip that ignored publication and source corpus
  the same way. Those checks still run when the ignored input is present.
- `t/350-support-contract-builder-audit.t` now admits the regression-gate
  status because that contract already carries guidance. The semantic-family
  envelope stays outside the guidance assertion because its own nonclaims
  already exclude support classification.

Those families are not one defect, and none of them is support or capacity.
The parse messages that appear before passing language-contract tests are
expected diagnostics.

### Exact-pinned production gate observation

From clean execution revision
`ef59330ab17328a03a316fa7d8ed19b4ff6e9d4a`, the selected-important-step
command completed the real local lifecycle:

```sh
./bin/ci-regression vial-gate --no-book
```

It re-authenticated and adopted the exact current corpus and qualification,
then passed all eleven profiles on their pinned host, guard, provider, and tool
identities. Required and observed topology exactly match the qualified
validation, raw-measurement, and controller counts. There are no failed,
informational, unavailable, or excluded profiles. All measured maxima remain at
or below their immutable qualified budgets.

The qualification-distinct latest observation is canonical JSON; its exact
byte count and file SHA-256 are retained in the verified claim below. The hash is
`f04fac651d1dfe7b2c90e47ba5ba219a949256f05a27e2b80cdc61f50eac72f4`
and gate identity
`regression-promotion-gate-result/c7787a020db6f63a816ad6616a979151966a96d84d9008fc7497127bb3dd02f2`.
It binds contract `0150f4b3...e368`, qualification `d8fb1813...0c97`,
qualification publication `1c2a3832...945f`, and file set
`28ba972c...9095`. Producer-free reload is explicit:

```sh
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_regression_promotion_gate.pl --validate-result
```

An independent raw-JSON join re-derived the file and content identities, every
profile's selection/workload/correctness/environment/provider/measurement/budget
binding, unique validation/raw identity sets, inclusive budget checks, and
cleanup. Eleven anonymous report spools were removed; final
census found no gate, GHDL, Verilator, receipt, or staging residue. T1786 and
T1787 separately retain safely simulated unmatched-host informational,
provider-unavailable non-pass, and aggregate-precedence behavior.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-production-gate-observation-ef59330ab-v1 -->
- Claim: Clean revision `ef59330ab17328a03a316fa7d8ed19b4ff6e9d4a` completed the public exact-pinned VIAL regression gate and published canonical 60,097-byte result `c7787a02...02f2` with all eleven profiles accepted/pass, required and observed 11/33/44 validation/raw/controller topology, zero exclusions, eleven removed spools, and zero process or staging residue. This is one environment- and revision-bound observation; it is not qualification evidence, recalibration, historical reuse, support promotion, architecture-scale capacity, or whole-product capacity.
- Re-derive: Run `./bin/ci-regression vial-gate --no-book` from an exact clean qualified environment, reload with guarded `scripts/run_vial_regression_promotion_gate.pl --validate-result`, then independently parse the canonical result and immutable qualification with JSON::PP/Digest::SHA. Require exact aggregate/profile content joins, the complete ordered ordinal set, unique qualified topology, qualification/publication/file-set identities, all observed maxima within fixed budgets, and absent residue.
- Falsify: The real gate successively rejected each affected runtime ordinal before publication, proving correctness drift does not become a pass. The profile/correctness watchers retain semantic, schema, topology, provider, threshold, worker, IPC, and telemetry-boundary attacks; the coordinator watcher retains fail > unavailable > informational > pass precedence. Simulated unmatched and unavailable routes cannot become exact-host pass.
- Durability: Retain Decision 0099, the result identity/hash and exact evidence transcript in task `.17.5.4.4.2.2.2`, the public runner and stores, t1183 and t1779-t1793, the mdBook chapter, Knowledge card, bounded claim record, doctrine gates, and work-unit Git commit. The latest-result file is deliberately replaceable; Git preserves this observation while future runs produce their own identity.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-production-gate-observation-ef59330ab-v1 -->

### Machine-readable regression-gate capability

Both public capability entrypoints now expose the same bounded discovery
record without reading generated evidence or the replaceable latest result:

```sh
./bin/fsmgen vial capabilities --json
./bin/fsmgen --capability-manifest
```

The VIAL result places it at
`capability_evidence.architecture_scale_regression`; the complete manifest
places it at `language_surface.vial_tooling.architecture_scale_regression`.
Capability `vial.architecture_scale.regression_gate.v1` names the selected gate
commands and schemas, exact evidence and qualification identities, ordered
profile coordinates and budgets, topology, reference host/guard/providers,
applicability, cadence, latest-result coordinate, cleanup, supported scope, and
nonclaims. The tracked support snapshot is pure and defensive; T1794 joins every
field to the immutable transport/qualification or an executable gate authority.

This publishes a bounded regression capability, not an architecture-scale or
whole-product capacity tier. The former ambiguous aggregate `scale` nonclaim is
therefore replaced only on VIAL tooling discovery by precise capacity, product
size, composition, language, tool, parity, and support-promotion nonclaims.
Fixture-level support classifications and their narrower `scale` nonclaims are
unchanged.

<!-- CLAIM-VERIFICATION:BEGIN vial-architecture-scale-regression-capability-v1 -->
- Claim: Public VIAL discovery exposes one artifact-independent contract for eleven exact qualified gate-candidate profiles, required topology 11/33/44, immutable per-profile budgets, and exact environment/applicability rules under capability `vial.architecture_scale.regression_gate.v1`. It claims only the shipped bounded regression gate; it does not claim support promotion, architecture-scale capacity, whole-product capacity, arbitrary-tool capacity, or general cross-backend parity.
- Re-derive: Run both capability commands above, T1794, and T1795. Require identical nested contracts with the complete ordered profile projection, topology, evidence identities, provider requirements, budgets, applicability, result coordinate, cleanup, supported scope, precise nonclaims, and an exact human-guide projection.
- Falsify: The initial CLI probe found the nested record absent even though the aggregate manifest carried it; T1555 now fails on that split. T1794 independently joins the static snapshot to tracked transport/qualification data and executable policy, store, limit, provider, and support authorities, exercises defensive rebuilding, and rejects aggregate `scale` ambiguity or support/capacity promotion. T1795 rejects missing or reordered guide rows, mixed providers, changed budgets or hosts, and capacity-nonclaim inversion.
- Durability: Retain the pure support contract, both public embeddings, T1555/T1794/T1795, complete manifest watcher, task-tree evidence, this chapter, Knowledge Map card, bounded claim record, doctrine gates, and work-unit commits. Discovery reads no ignored or replaceable artifact, while the documented dry run remains executable and side-effect free.
<!-- CLAIM-VERIFICATION:END vial-architecture-scale-regression-capability-v1 -->

### Run the bounded gate

Use the public commands from the repository root:

```sh
# Discover the contract without reading generated evidence or a prior result.
./bin/fsmgen vial capabilities --json

# Preview the selected lifecycle without executing it.
./bin/ci-regression vial-gate --dry-run --no-book

# Run only the selected VIAL gate.
./bin/ci-regression vial-gate --no-book

# Run the complete pre-push regression tier.
./bin/ci-regression --no-book

# Validate the latest result without invoking a profile producer.
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_regression_promotion_gate.pl --validate-result

# Independently authenticate the tracked evidence transport.
perl scripts/verify_vial_regression_promotion_evidence_transport.pl
```

The dry run prints the selected five-step transaction in order: materialize the
tracked evidence without overwriting a pre-existing root, independently verify
the current corpus, independently verify the qualification, execute all gate
profiles under the repository RAM guard, and clean only roots named by the
materialization receipt. `vial-gate` is the selected important-step command;
the unqualified `ci-regression` command is the full pre-push tier. Ordinary
slices continue to use focused checks.

### Qualified reference envelope

The performance reference is deliberately exact, not a class of similar
machines:

| Field | Exact qualified value |
| --- | --- |
| Operating system | Darwin 25.5.0, arm64 |
| CPU | Apple M4 Pro, 12 logical cores |
| Physical memory | 25,769,803,776 bytes |
| Filesystem | APFS |
| Process-tree sampler | `fsmgen.perl_process_tree_sampler.v1` |
| Resource guard | active repository RAM guard; host maximum 88%; one descendant maximum 4096 MiB; sample interval 250,000,000 ns |

External providers are equally pinned:

| Provider identity | Kind and version | Exact revision/profile identity |
| --- | --- | --- |
| `external_exact_osvvm_2026_05` | repository materialization, OSVVM 2026.05 | revision `2f7c391051dfb11890fa4bdbda9918d1db492250` |
| `qualified_verilator_5_046` | exact Verilator 5.046 | `tool-profile/40de18b1140d38a1ea081f6e3ccdb26628b2e848a76a4e24c3c2a3bee56bc9c6` |
| `qualified_ghdl_6_0_0_llvm_jit` | exact GHDL 6.0.0-llvm-jit | revision `e589c698c351369ac5bcfe7abe1f1152ac5d4727`; `tool-profile/911258b328f62381fe59916c7d272d5f5cb5c31b6274e98b00bf3865ecf98191` |
| `qualified_osvvm_2026_05_ghdl_6_0_0_llvm_jit` | exact `6.0.0-llvm-jit+OSVVM-2026.05` | `tool-profile/cb9962d5707404479548b6f837c908a76b1316d08251828324023d3560be46c6` |

Each row below is one immutable selected envelope. Times are exact decimal
seconds derived from the integral nanosecond budgets, and RSS is exact MiB
derived from the integral byte budget; none is a rounded recommendation.
`not_applicable` means that profile has no external verification provider.

| Ordinal | Exact selection key | Required provider | Wall | CPU | Peak tree RSS |
| ---: | --- | --- | ---: | ---: | ---: |
| 1 | `semantic_bridge\|semantic_catalog_v1\|gate_candidate_v1\|actions\|-` | `not_applicable` | 2.000 s | 2.000 s | 256 MiB |
| 2 | `semantic_bridge\|bridge_fanout_v1\|gate_candidate_v1\|backend_bindings\|-` | `not_applicable` | 18.325 s | 18.165 s | 640 MiB |
| 3 | `execution_checking\|execution_graph_v1\|gate_candidate_v1\|bindings\|-` | `not_applicable` | 31.479 s | 31.395 s | 1264 MiB |
| 4 | `execution_checking\|checking_state_v1\|gate_candidate_v1\|random_occurrences\|-` | `not_applicable` | 34.683 s | 34.755 s | 992 MiB |
| 5 | `backend_emission\|backend_emission_v1\|gate_candidate_v1\|-\|sv_portable_verilator` | `not_applicable` | 35.836 s | 36.390 s | 1040 MiB |
| 6 | `backend_emission\|backend_emission_v1\|gate_candidate_v1\|-\|vhdl_portable_ghdl` | `not_applicable` | 24.033 s | 24.270 s | 880 MiB |
| 7 | `backend_emission\|backend_emission_v1\|gate_candidate_v1\|-\|vhdl_osvvm_qualified` | `external_exact_osvvm_2026_05` | 27.891 s | 25.305 s | 912 MiB |
| 8 | `portable_runtime\|runtime_stream_v1\|gate_candidate_v1\|-\|sv_portable_verilator` | `qualified_verilator_5_046` | 312.422 s | 298.875 s | 2512 MiB |
| 9 | `portable_vhdl_runtime\|runtime_stream_v1\|gate_candidate_v1\|-\|vhdl_portable_ghdl` | `qualified_ghdl_6_0_0_llvm_jit` | 46.812 s | 46.515 s | 1104 MiB |
| 10 | `osvvm_runtime\|runtime_stream_v1\|gate_candidate_v1\|-\|vhdl_osvvm_qualified` | `qualified_osvvm_2026_05_ghdl_6_0_0_llvm_jit` | 194.013 s | 176.235 s | 1616 MiB |
| 11 | `balanced_portable\|balanced_portable_v1\|gate_candidate_v1\|-\|sv_portable_verilator` | `not_applicable` | 429.258 s | 462.510 s | 3984 MiB |

The topology is fixed at eleven profile workers. Each profile contributes one
validation record and three fresh raw measurements, producing 11 validation,
33 raw, and 44 controller records with zero sample exclusions.

### Applicability, publication, and cleanup

Correctness is always the first decision. `selection_key`, `workload_identity`,
and `correctness_projection_identity` must match exactly; deterministic drift
rejects the profile before a performance comparison on every host. After that
check, outcomes are:

| Situation | Gate outcome |
| --- | --- |
| Host, tool, guard, and provider all exactly match | Every wall, CPU, and RSS maximum must be at or below its budget; the comparison is inclusive. |
| Environment does not exactly match | Correctness remains required; performance is informational. |
| An exact required provider is absent | `unavailable`, never pass. |
| A provider is present but its pinned identity drifts | fail. |

There is no performance override. A later matching revision can become
performance-enforcement eligible only after correctness passes. Changing a
budget is not a gate side effect: recalibration requires a separately owned
version that retains immutable old and new evidence.

The gate atomically replaces one latest observation at
`.artifacts/qualification/vial-scale/v2/regression-promotion-gate-v1/current/regression-promotion-gate-result.json`.
The result is capped at 1,048,576 bytes and is never qualification evidence.
Profile report spools are anonymous and unlinked before worker exit; process
and staging residue are forbidden. Evidence cleanup removes only exact roots
owned by the current receipt, while the latest result is preserved.

### Scope boundary

The claim is intentionally narrow: FSMGen ships a bounded regression gate for
these eleven exact qualified gate-candidate profiles. It requires correctness
for every available profile, enforces performance only on the exact qualified
environment, and treats provider absence as unavailable rather than pass.

It does **not** claim architecture-scale capacity, a “big” or “really big”
whole product, multi-unit or multi-domain capacity, mixed-language capacity,
native UVM runtime, full-language coverage, synthesis capacity, arbitrary-tool
capacity, support promotion, general cross-backend parity, performance
enforcement on unmatched hosts, or a pass when a provider is unavailable.

Re-derive the authenticated transport and the tracked policy seal with:

```sh
perl scripts/verify_vial_regression_promotion_evidence_transport.pl
prove -Iperl t/1790-vial-regression-promotion-evidence-transport.t
prove -Iperl t/1765-vial-architecture-scale-regression-promotion-policy.t
```

Public policy derivation loads
`vial/qualification/regression_promotion_policy/regression-promotion-policy-v1.json`
under the repository RAM guard. It does not read the ignored historical
closure. Local comparison subtests still recompute that comparison when the
closure is present on the machine.

Current capture, budget qualification/publication, independent agreement,
profile and aggregate gate execution, latest-result storage, explicit CLI,
authenticated transport/materialization, and local/hosted CI placement are
complete. The exact-pinned local production observation now closes the sealed
budgets' execution path. Historical candidate budgets remain candidate-only,
the current result remains a replaceable observation rather than calibration,
and whole-product big/really-big capacity remains unclaimed. `.17.5.5` owns the
broader command, envelope, variability, support/capability, and nonclaim
publication.

## Revision-separated complete-corpus validation

Subsequent commits do not rewrite an immutable capture revision. The earlier
coordinator nevertheless reused public single-profile resume during complete-
corpus validation, requiring the sealed revision to equal the revision running
the validator. That is right for a caller selecting one profile directly, but
it made an authenticated complete seal non-revalidatable after the next commit.
Independent verification and production inventory still admitted the seal
while production validation rejected at its first profile.

Coordination schema v2 separates those authorities. `capture_revision` comes
only from the authenticated complete corpus and remains in every profile's
common identity. `execution_revision` comes from the current clean checkout
and is pinned before and after every child, parent validation, reload, and final
complete-corpus comparison. ProfileCapture's public `capture` and `resume` APIs
remain same-revision strict. Only an exact-caller seam used by CorpusCoordinator
can carry the seal-derived capture revision; foreign callers, injected
revisions, seal/profile disagreement, and executing-repository mutation reject.
Validation remains producer-free and read-only and preserves publication bytes.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-revision-separated-validation-v1 -->
- Claim: Public regression-promotion profile resume remains exact-current-revision only, while complete-corpus validation derives immutable capture revision solely from the authenticated complete seal and pins the clean executing revision separately. Coordination schema v2 reports both revisions; validation remains producer-free, repeats child and parent public report validation plus current environment admission, and leaves every publication byte unchanged. This is sealed-evidence revalidation, not general historical compatibility, recapture, performance qualification, support, or capacity promotion.
- Re-derive: Run guarded t1769 and t1773. Require ordinary public resume to reject a prior-revision profile, then require a complete synthetic corpus captured at one clean commit to validate after a second clean commit through eleven exact-caller resumes. The result must report distinct capture/execution revisions, retain capture revision in common identity, capture zero profiles, resume all eleven, and preserve complete bytes.
- Falsify: Call the private seam outside CorpusCoordinator; inject capture/execution revision through every public coordinator method; mutate complete-versus-profile capture revision; corrupt the seam's revision; and dirty the executing repository after complete admission. Every control must reject, while existing stale host/guard/tool/provider, malformed result, child failure, mutation, bounded IPC, and cleanup controls remain green.
- Durability: Retain the `.17.5.2.5.4.1` task record, ProfileCapture, CorpusCoordinator, t1769/t1773, this chapter, the compact regression-promotion fact card, bounded claim record, doctrine gates, and the work-unit Git chain. Child `.5.4.2` owns the real sealed-corpus closeout result.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-revision-separated-validation-v1 -->

### Whole-profile validation process isolation

Complete-corpus coordination processes profiles in plan order, but each whole
ProfileCapture operation now runs in a fresh outer child. Inside that child,
ProfileCapture still performs its existing report-validation child followed by
the independent parent-side public validation. The outer child then exits, so
the long-lived CorpusCoordinator retains only the existing bounded canonical
profile result rather than the validator's temporary graph and allocator
state. CorpusCoordinator still reloads the published profile and pins the
current clean execution revision after each worker.

The outer pipe is nonblocking and close-on-exec. Success uses the existing
bounded profile IPC envelope; exceptions use a separately bounded
canonical failure record. Missing output, signals, nonzero exits, malformed or
noncanonical JSON, oversized results, and post-worker publication mutation all
fail closed before a complete seal can be admitted. This process topology does
not weaken dual validation or the exact-caller capture-revision authority.

Run the synthetic process-identity and hostile-worker watcher with:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1773-vial-regression-promotion-corpus-coordinator.t
```

The synthetic watcher proves the isolation boundary and unchanged result
semantics. A subsequent clean-revision guarded production validation completed
every stored profile through this topology and emitted one canonical result.
Guarded inventory and independent before/after census preserved the exact seal,
so real-publication resource and byte-invariance closeout is now complete.

## Independent final regression closeout

From clean revision `840c895f3`, `./bin/ci-regression vial-gate --no-book`
completed the exact pinned gate with all eleven profiles accepted and PASS.
The latest result's exact bytes, identity, topology, exclusions, and SHA-256
are retained in the verified claim below. Producer-free validation, every
independent evidence verifier, and a production-module-free JSON::PP/Digest::SHA
reconstruction all agree on its qualification, transport, budgets, unique
records, both public machine entrypoints, and every maximum.

The complete guarded policy-through-public hostile band passed. It retains
pinned-host pass, unmatched-host informational,
unavailable-provider non-pass, CI selection, evidence mutations, atomicity,
and public-guide falsifiers. Every evidence hash remained unchanged; the latest
result changed inode atomically; all report spools were removed; and the final
process, staging, and receipt censuses were empty. This observation does not
recalibrate, promote support, or establish architecture or whole-product
capacity.

<!-- CLAIM-VERIFICATION:BEGIN vial-regression-promotion-production-gate-observation-840c895f-v1 -->
- Claim: Clean revision `840c895f3af08e80b05853b531011ddb2c5c4e1e` completed the public exact-pinned VIAL regression gate and published canonical 60,100-byte result `f4b022fa...f5f97` with all eleven profiles accepted/pass, exact 11/33/44 validation/raw/controller topology, zero exclusions, eleven removed spools, unchanged evidence, atomic latest replacement, and zero process, staging, or receipt residue. This is one revision- and environment-bound observation, not qualification, recalibration, support promotion, architecture-scale capacity, or whole-product capacity.
- Re-derive: Run the public gate from that clean qualified revision, producer-free result validation, every independent evidence verifier, and a production-module-free JSON::PP/Digest::SHA join. Require the exact result bytes/hash and aggregate/profile/qualification/public/transport joins, all qualified record-identity sets at their required cardinalities, every maximum within frozen budgets, unchanged evidence, and absent residue.
- Falsify: Run the guarded t1183, t1555, and t1765-t1795 policy-through-public band. Require pinned pass, simulated unmatched informational and unavailable-provider non-pass, plus every capture/store/resume/isolation/corpus/qualification/gate/transport/materialization/hosted/correctness/capability/public hostile mutation to reject. Atomic replacement or any evidence/residue drift invalidates closeout.
- Durability: Retain task `.17.5.6.2`, this chapter, the regression-promotion Knowledge Card, bounded claim record, public gate/store, independent verifiers, t1183/t1555/t1765-t1795, doctrine gates, and the work-unit Git commit. The latest result remains replaceable; Git preserves this exact observation and its nonclaims.
<!-- CLAIM-VERIFICATION:END vial-regression-promotion-production-gate-observation-840c895f-v1 -->
