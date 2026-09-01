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
reviewed runtime-stream, backend-artifact, and checking-model witnesses to
explicit dimensions. The same classification remains pending for every other
group.

## Why calibration publication is separate

The immutable calibration closure remains measurement evidence. Its publisher
revision predates the cap-hardening leaves, and its public nonclaims explicitly
include `cap_implementation`. Byte-valid measurement files therefore cannot be
relabelled as proof that the current caps fail atomically or clean up exactly.

The closeout layer will consume the current cap policy internally, reject
caller-supplied evidence, and keep two questions separate:

- Is the historical measurement publication still internally authentic?
- Does current code satisfy every selected cap's boundary, adjacent excess,
  diagnostic, atomicity, no-tool, cleanup, and accepted-identity contract?

Only after the second answer is complete can `.17.4.8` disposition the
historical publication as reusable, superseded, or requiring a versioned
recapture.

## Machine-enforced closeout state

`FSM::VIAL::ArchitectureScaleCapConsistency` is the separate closeout owner.
It accepts no policy or evidence input: the exact class rebuilds the live cap
policy internally and emits every selected group, its axes, declared
authority, implementation leaf, diagnostic families, and candidate evidence.
Each group must contain the same closed dimension set: boundary, adjacent
excess, diagnostics, atomicity, no-tool behavior, cleanup, and accepted
identity.

The runtime-stream, backend-artifact, and checking-model groups are `verified`
across all seven dimensions; all other groups remain
`pending_independent_verification`. Runtime covers the three selected
materialization profiles plus t1720 through t1749 and t1751 through t1762.
Backend covers t1646 through t1650 and t1716 through t1719. Checking models
uses t1630 for exact model-instance/scalar-cell limits, provider-free state
evaluation, and cleanup; t1711 independently proves compact preflight order
and absence of partial ExecutionIR or plan. Each test is listed once and mapped
only to the dimensions it proves. T1763 reconstructs all three sets of
per-dimension projections, requires their complete unions, checks every path,
and rejects omitted or foreign evidence. Policy citations remain candidates
for all unreviewed groups. The validator also
rejects caller arguments, subclass invocants, missing or unknown fields,
caller-promoted dimensions, returned-data mutation, and an early calibration
disposition.

The calibration state remains `historical_measurement_only` and
`blocked_pending_current_cap_verification`. Completing all dimension joins can
only make it eligible for an explicit revalidation; it cannot automatically
relabel historical measurement as current cap proof.

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
