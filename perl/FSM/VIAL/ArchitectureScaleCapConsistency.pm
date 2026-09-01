package FSM::VIAL::ArchitectureScaleCapConsistency;

use v5.20;
use strict;
use warnings;

use Carp qw(confess);
use Scalar::Util qw(blessed);

use FSM::VIAL::ArchitectureScaleCapPolicy qw(
    build_architecture_scale_cap_policy
);

my $SCHEMA = 'fsmgen.vial_architecture_scale_cap_consistency.v1';
my $POLICY_BUILDER =
    'FSM::VIAL::ArchitectureScaleCapPolicy::build_architecture_scale_cap_policy';
my $CALIBRATION_AUTHORITY =
    'FSM::VIAL::ArchitectureScaleCalibrationClosurePublication';
my @DIMENSIONS = qw(
    boundary adjacent_excess diagnostics atomicity no_tool cleanup
    accepted_identity
);

# Later family-specific slices may promote one entry only after independently
# reviewing its evidence. An absent entry is deliberately visible as pending;
# policy citations are candidates, not dimension proof.
my $VERIFIED_DIMENSIONS = {};

sub build {
    my ($class, @args) = @_;
    _exact_invocant($class, 'build');
    confess __PACKAGE__ . "->build requires no arguments\n" if @args;
    my $report = _expected_report();
    _assert_report($report);
    return _clone($report);
}

sub required_dimensions {
    my ($class, @args) = @_;
    _exact_invocant($class, 'required_dimensions');
    confess __PACKAGE__ . "->required_dimensions requires no arguments\n"
        if @args;
    return [@DIMENSIONS];
}

sub _expected_report {
    my $policy = build_architecture_scale_cap_policy();
    my %axes_for;
    for my $family (sort keys %{$policy->{axis_groups}}) {
        for my $axis (sort keys %{$policy->{axis_groups}{$family}}) {
            my $group = $policy->{axis_groups}{$family}{$axis};
            push @{$axes_for{$group}}, "$family/$axis";
        }
    }

    my %groups;
    my $complete = 1;
    for my $name (sort keys %{$policy->{groups}}) {
        my $selected = $policy->{groups}{$name};
        my %dimensions;
        for my $dimension (@DIMENSIONS) {
            my $verified = exists($VERIFIED_DIMENSIONS->{$name})
                ? $VERIFIED_DIMENSIONS->{$name}{$dimension}
                : undef;
            my $record = defined($verified)
                ? _clone($verified)
                : {
                    status => 'pending_independent_verification',
                    evidence => [],
                    rationale =>
                        'policy citations are candidates, not dimension proof',
                };
            $complete = 0 unless $record->{status} eq 'verified';
            $dimensions{$dimension} = $record;
        }
        $groups{$name} = {
            axes => [@{$axes_for{$name} // []}],
            declared_authority => $selected->{declared_authority},
            earliest_stage => $selected->{earliest_stage},
            path_contract => $selected->{path_contract},
            atomicity_contract => $selected->{atomicity},
            implementation_leaf => $selected->{implementation_leaf},
            diagnostic_families => _clone(
                $selected->{diagnostic_families},
            ),
            candidate_evidence => _clone($selected->{evidence}),
            dimensions => \%dimensions,
        };
    }

    return {
        schema => $SCHEMA,
        schema_version => 1,
        decision => $policy->{decision},
        policy => {
            builder => $POLICY_BUILDER,
            schema => $policy->{schema},
            decision => $policy->{decision},
        },
        required_dimensions => [@DIMENSIONS],
        groups => \%groups,
        calibration => {
            authority => $CALIBRATION_AUTHORITY,
            evidence_role => 'historical_measurement_only',
            cap_proof_status => $complete ? 'complete' : 'incomplete',
            disposition => $complete
                ? 'eligible_for_explicit_revalidation'
                : 'blocked_pending_current_cap_verification',
            unlock_condition => 'all_group_dimensions_verified',
            prohibited_relabel => 'cap_implementation',
        },
        explicit_nonclaims => _clone($policy->{explicit_nonclaims}),
    };
}

sub _assert_report {
    my ($report) = @_;
    confess "architecture-scale cap consistency report must be one unblessed hash\n"
        unless @_ == 1 && ref($report) eq 'HASH' && !blessed($report);
    _assert_exact_keys($report, [qw(
        schema schema_version decision policy required_dimensions groups
        calibration explicit_nonclaims
    )], 'consistency report');
    confess "architecture-scale cap consistency schema is unsupported\n"
        unless ($report->{schema} // '') eq $SCHEMA
            && ($report->{schema_version} // 0) == 1;

    my $policy = build_architecture_scale_cap_policy();
    my $expected = _expected_report();
    confess "consistency report decision contradicts the cap policy\n"
        unless ($report->{decision} // '') eq $policy->{decision};
    _assert_exact_keys(
        $report->{policy}, [qw(builder schema decision)],
        'consistency policy authority',
    );
    confess "consistency report policy authority contradicts the live policy\n"
        unless ($report->{policy}{builder} // '') eq $POLICY_BUILDER
            && ($report->{policy}{schema} // '') eq $policy->{schema}
            && ($report->{policy}{decision} // '') eq $policy->{decision};
    _assert_string_array(
        $report->{required_dimensions}, 'required closeout dimensions',
    );
    confess "required closeout dimensions contradict the sealed contract\n"
        unless join("\0", @{$report->{required_dimensions}})
            eq join("\0", @DIMENSIONS);

    confess "consistency report groups must be one unblessed hash\n"
        unless ref($report->{groups}) eq 'HASH'
            && !blessed($report->{groups});
    my @actual_groups = sort keys %{$report->{groups}};
    my @expected_groups = sort keys %{$policy->{groups}};
    confess "consistency report group inventory contradicts the cap policy\n"
        unless join("\0", @actual_groups) eq join("\0", @expected_groups);

    my %axes_for;
    for my $family (sort keys %{$policy->{axis_groups}}) {
        for my $axis (sort keys %{$policy->{axis_groups}{$family}}) {
            push @{$axes_for{$policy->{axis_groups}{$family}{$axis}}},
                "$family/$axis";
        }
    }

    for my $name (@actual_groups) {
        my $group = $report->{groups}{$name};
        _assert_exact_keys($group, [qw(
            axes declared_authority earliest_stage path_contract
            atomicity_contract implementation_leaf diagnostic_families
            candidate_evidence dimensions
        )], "consistency group '$name'");
        _assert_string_array($group->{axes},
            "consistency group '$name' axes");
        confess "consistency group '$name' axes contradict the cap policy\n"
            unless join("\0", @{$group->{axes}})
                eq join("\0", @{$axes_for{$name} // []});
        my $selected = $policy->{groups}{$name};
        for my $pair (
            [declared_authority => 'declared_authority'],
            [earliest_stage => 'earliest_stage'],
            [path_contract => 'path_contract'],
            [atomicity_contract => 'atomicity'],
            [implementation_leaf => 'implementation_leaf'],
        ) {
            my ($report_field, $policy_field) = @{$pair};
            confess "consistency group '$name/$report_field' contradicts the cap policy\n"
                unless defined($group->{$report_field})
                    && !ref($group->{$report_field})
                    && $group->{$report_field} eq $selected->{$policy_field};
        }
        _assert_string_array($group->{diagnostic_families},
            "consistency group '$name' diagnostics");
        _assert_string_array($group->{candidate_evidence},
            "consistency group '$name' candidate evidence");
        confess "consistency group '$name' diagnostics contradict the cap policy\n"
            unless _same_plain(
                $group->{diagnostic_families},
                $selected->{diagnostic_families},
            );
        confess "consistency group '$name' candidate evidence contradicts the cap policy\n"
            unless _same_plain(
                $group->{candidate_evidence}, $selected->{evidence},
            );

        _assert_exact_keys(
            $group->{dimensions}, \@DIMENSIONS,
            "consistency group '$name' dimensions",
        );
        for my $dimension (@DIMENSIONS) {
            my $record = $group->{dimensions}{$dimension};
            _assert_exact_keys($record, [qw(status evidence rationale)],
                "consistency group '$name/$dimension'");
            confess "consistency group '$name/$dimension' evidence must be one array\n"
                unless ref($record->{evidence}) eq 'ARRAY';
            confess "consistency group '$name/$dimension' rationale must be a non-empty scalar\n"
                unless defined($record->{rationale})
                    && !ref($record->{rationale})
                    && length($record->{rationale});
            if (($record->{status} // '') eq 'pending_independent_verification') {
                confess "consistency group '$name/$dimension' pending evidence must be empty\n"
                    if @{$record->{evidence}};
            } elsif (($record->{status} // '') eq 'verified') {
                _assert_string_array($record->{evidence},
                    "consistency group '$name/$dimension' verified evidence");
            } else {
                confess "consistency group '$name/$dimension' has unsupported status\n";
            }
            confess "consistency group '$name/$dimension' contradicts "
                . "the sealed evidence authority\n"
                unless _same_plain(
                    $record,
                    $expected->{groups}{$name}{dimensions}{$dimension},
                );
        }
    }

    _assert_exact_keys($report->{calibration}, [qw(
        authority evidence_role cap_proof_status disposition unlock_condition
        prohibited_relabel
    )], 'calibration consistency barrier');
    my $expected_proof = $expected->{calibration}{cap_proof_status};
    my $expected_disposition = $expected->{calibration}{disposition};
    confess "calibration authority contradicts the sealed contract\n"
        unless ($report->{calibration}{authority} // '')
            eq $CALIBRATION_AUTHORITY;
    confess "calibration evidence role contradicts the sealed contract\n"
        unless ($report->{calibration}{evidence_role} // '')
            eq 'historical_measurement_only';
    confess "calibration proof status contradicts verification state\n"
        unless ($report->{calibration}{cap_proof_status} // '')
            eq $expected_proof;
    confess "calibration disposition contradicts verification state\n"
        unless ($report->{calibration}{disposition} // '')
            eq $expected_disposition;
    confess "calibration unlock condition contradicts the sealed contract\n"
        unless ($report->{calibration}{unlock_condition} // '')
            eq 'all_group_dimensions_verified';
    confess "calibration prohibited relabel contradicts the publication nonclaim\n"
        unless ($report->{calibration}{prohibited_relabel} // '')
            eq 'cap_implementation';
    _assert_string_array($report->{explicit_nonclaims}, 'explicit nonclaims');
    confess "consistency report nonclaims contradict the cap policy\n"
        unless _same_plain(
            $report->{explicit_nonclaims}, $policy->{explicit_nonclaims},
        );
    return 1;
}

sub _assert_exact_keys {
    my ($value, $expected, $label) = @_;
    confess "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @{$expected};
    my @unknown = sort grep { !$expected{$_} } keys %{$value};
    my @missing = grep { !exists($value->{$_}) } @{$expected};
    confess "$label has unknown field '$unknown[0]'\n" if @unknown;
    confess "$label is missing field '$missing[0]'\n" if @missing;
}

sub _assert_string_array {
    my ($value, $label) = @_;
    confess "$label must be one non-empty array\n"
        unless ref($value) eq 'ARRAY' && @{$value};
    my %seen;
    for my $entry (@{$value}) {
        confess "$label must contain unique non-empty scalars\n"
            unless defined($entry) && !ref($entry) && length($entry)
                && !$seen{$entry}++;
    }
}

sub _same_plain {
    my ($left, $right) = @_;
    return 1 if !defined($left) && !defined($right);
    return 0 unless defined($left) && defined($right);
    return $left eq $right unless ref($left) || ref($right);
    return 0 unless ref($left) eq ref($right);
    if (ref($left) eq 'HASH') {
        return 0 unless join("\0", sort keys %{$left})
            eq join("\0", sort keys %{$right});
        return 0 if grep { !_same_plain($left->{$_}, $right->{$_}) }
            keys %{$left};
        return 1;
    }
    if (ref($left) eq 'ARRAY') {
        return 0 unless @{$left} == @{$right};
        for my $index (0 .. $#{$left}) {
            return 0 unless _same_plain($left->[$index], $right->[$index]);
        }
        return 1;
    }
    return 0;
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return {map { $_ => _clone($value->{$_}) } keys %{$value}}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @{$value}] if ref($value) eq 'ARRAY';
    return $value;
}

sub _exact_invocant {
    my ($class, $method) = @_;
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

1;
