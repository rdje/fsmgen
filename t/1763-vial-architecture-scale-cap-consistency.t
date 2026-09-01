#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'perl';

use FSM::VIAL::ArchitectureScaleCapConsistency;
use FSM::VIAL::ArchitectureScaleCapPolicy qw(
    build_architecture_scale_cap_policy
);

my $class = 'FSM::VIAL::ArchitectureScaleCapConsistency';
my @dimensions = qw(
    boundary adjacent_excess diagnostics atomicity no_tool cleanup
    accepted_identity
);

sub dies {
    my ($code) = @_;
    local $@;
    eval { $code->(); 1 };
    return $@;
}

subtest 'sealed report enumerates every selected group and closeout dimension' => sub {
    my $policy = build_architecture_scale_cap_policy();
    my $report = $class->build;

    is(
        $report->{schema},
        'fsmgen.vial_architecture_scale_cap_consistency.v1',
        'consistency report has one versioned schema',
    );
    is($report->{decision}, $policy->{decision},
        'consistency report retains the policy decision');
    is_deeply($report->{required_dimensions}, \@dimensions,
        'closeout dimensions are closed and ordered');
    is_deeply(
        [sort keys %{$report->{groups}}],
        [sort keys %{$policy->{groups}}],
        'every selected policy group enters the consistency report',
    );

    my %expected_axes;
    for my $family (sort keys %{$policy->{axis_groups}}) {
        for my $axis (sort keys %{$policy->{axis_groups}{$family}}) {
            push @{$expected_axes{$policy->{axis_groups}{$family}{$axis}}},
                "$family/$axis";
        }
    }

    my @missing_evidence;
    for my $name (sort keys %{$report->{groups}}) {
        my $group = $report->{groups}{$name};
        is_deeply($group->{axes}, $expected_axes{$name},
            "$name retains its exact ordered axes");
        is($group->{declared_authority},
            $policy->{groups}{$name}{declared_authority},
            "$name retains its declared authority");
        is($group->{implementation_leaf},
            $policy->{groups}{$name}{implementation_leaf},
            "$name retains its implementation leaf");
        is_deeply($group->{candidate_evidence},
            $policy->{groups}{$name}{evidence},
            "$name retains candidate evidence without upgrading it");
        is_deeply([sort keys %{$group->{dimensions}}],
            [sort @dimensions],
            "$name cannot omit a closeout dimension");
        for my $dimension (@dimensions) {
            is($group->{dimensions}{$dimension}{status},
                'pending_independent_verification',
                "$name/$dimension remains explicitly pending");
            is_deeply($group->{dimensions}{$dimension}{evidence}, [],
                "$name/$dimension does not relabel candidate evidence");
        }
        push @missing_evidence,
            grep { !-f $_ } @{$group->{candidate_evidence}};
    }
    is_deeply(\@missing_evidence, [],
        'every policy candidate-evidence path exists');

    is($report->{calibration}{evidence_role},
        'historical_measurement_only',
        'calibration stays measurement evidence');
    is($report->{calibration}{cap_proof_status}, 'incomplete',
        'pending dimensions keep cap proof incomplete');
    is($report->{calibration}{disposition},
        'blocked_pending_current_cap_verification',
        'historical publication cannot be dispositioned prematurely');
    is($report->{calibration}{prohibited_relabel}, 'cap_implementation',
        'the historical publication nonclaim remains explicit');
};

subtest 'callers cannot inject authority or mutate the sealed report' => sub {
    like(dies(sub { $class->build({groups => {}}) }),
        qr/requires no arguments/,
        'callers cannot inject a policy or evidence map');
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleCapConsistency::build('borrowed');
    }), qr/requires the exact class invocant/,
        'borrowed invocants fail closed');

    {
        package Local::CapConsistencySubclass;
        our @ISA = ('FSM::VIAL::ArchitectureScaleCapConsistency');
    }
    like(dies(sub { Local::CapConsistencySubclass->build }),
        qr/requires the exact class invocant/,
        'subclass invocants fail closed');

    my $first = $class->build;
    my ($first_group) = sort keys %{$first->{groups}};
    $first->{groups}{$first_group}{dimensions}{cleanup}{status} = 'verified';
    push @{$first->{groups}{$first_group}{candidate_evidence}}, 'caller';
    $first->{calibration}{disposition} = 'reusable';
    my $second = $class->build;
    is($second->{groups}{$first_group}{dimensions}{cleanup}{status},
        'pending_independent_verification',
        'returned dimension mutation cannot enter authority');
    ok(!(grep { $_ eq 'caller' }
        @{$second->{groups}{$first_group}{candidate_evidence}}),
        'returned evidence mutation cannot enter authority');
    is($second->{calibration}{disposition},
        'blocked_pending_current_cap_verification',
        'returned calibration mutation cannot bypass the barrier');

    my $assert = $class->can('_assert_report');
    ok(defined($assert), 'private sealed-report assertion is available');

    my $missing = $class->build;
    delete $missing->{groups}{$first_group}{dimensions}{cleanup};
    like(dies(sub { $assert->($missing) }),
        qr/dimensions is missing field 'cleanup'/,
        'missing dimensions fail closed');

    my $forged = $class->build;
    $forged->{groups}{$first_group}{dimensions}{cleanup} = {
        status => 'verified',
        evidence => ['t/1685-vial-architecture-scale-cap-policy.t'],
        rationale => 'caller supplied',
    };
    like(dies(sub { $assert->($forged) }),
        qr/cleanup' contradicts the sealed evidence authority/,
        'callers cannot promote a dimension through the private validator');

    my $extra = $class->build;
    $extra->{unexpected} = 1;
    like(dies(sub { $assert->($extra) }),
        qr/consistency report has unknown field 'unexpected'/,
        'unknown report fields fail closed');

    my $premature = $class->build;
    $premature->{calibration}{disposition} = 'reusable';
    like(dies(sub { $assert->($premature) }),
        qr/calibration disposition contradicts verification state/,
        'premature calibration disposition fails closed');
};

done_testing;
