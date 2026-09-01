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
The runtime group still cites the three earlier materialization witnesses while
the completed runtime leaf has a much larger set of boundary, admission,
cleanup, and process-containment witnesses. The policy test validates the
generic catalog join but does not yet bind that runtime evidence or the same
guarantees across every other group.

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

The initial report marks every dimension `pending_independent_verification`.
That state is deliberate. A policy citation is useful evidence to review, but
its presence alone cannot prove which closeout dimensions it exercises. The
report validator rejects caller arguments, subclass invocants, missing or
unknown fields, caller-promoted dimensions, returned-data mutation, and an
early calibration disposition.

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
review. The foundation itself does not alter product behavior.
