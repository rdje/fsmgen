#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_dt_assignment_operator_family_map
);

subtest 'direct ISF DT assignment metadata is exact and unique' => sub {
    assert_dt_assignment_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF DT assignment metadata is exact and unique' => sub {
    my @views = (
        {
            label => 'in-process capability manifest',
            payload => build_capability_manifest(),
        },
        {
            label => 'CLI capability manifest',
            payload => run_capability_manifest('--capability-manifest'),
        },
        {
            label => 'CLI capability manifest alias',
            payload => run_capability_manifest('--emit-capability-manifest'),
        },
    );

    for my $view (@views) {
        my $label = $view->{label};
        assert_dt_assignment_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'scheduled .fsm assignment operators stay within the advertised families' => sub {
    my $isf_path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm_text = $lowered->{files}{'apb_requester.fsm'};

    my @operators = assignment_operators_from_fsm($fsm_text);
    ok(@operators, 'scheduled .fsm exposes assignment operators to audit');

    my %advertised = advertised_assignment_operators();
    for my $operator (@operators) {
        ok($advertised{$operator}, "scheduled .fsm assignment operator '$operator' is advertised");
    }

    my %seen = map { $_ => 1 } @operators;
    for my $operator (qw(= <- <=)) {
        ok($seen{$operator}, "APB scheduled .fsm includes advertised operator '$operator'");
    }
};

done_testing();

sub assert_dt_assignment_metadata {
    my ($contract, $label) = @_;
    my $family_map = $contract->{dt_assignment_operator_family_map};

    is_deeply(
        $family_map,
        isf_public_interface_dt_assignment_operator_family_map(),
        "$label DT assignment operator family map is exact",
    );
    assert_operator_family($family_map->{combinational}, "$label combinational operators");
    assert_operator_family($family_map->{sequential}, "$label sequential operators");
}

sub assert_operator_family {
    my ($values, $label) = @_;
    my %seen;

    ok(ref($values) eq 'ARRAY', "$label is an array");
    for my $value (@{$values || []}) {
        ok(!ref($value), "$label entry '$value' is scalar");
        next if ref($value);
        ok(length($value), "$label entry '$value' is non-empty");
        ok(!$seen{$value}++, "$label does not duplicate '$value'");
    }
}

sub assignment_operators_from_fsm {
    my ($fsm_text) = @_;
    return $fsm_text =~ /^\s+\((=|<-|<=)\s+\(/gm;
}

sub advertised_assignment_operators {
    my %advertised;
    my $family_map = isf_public_interface_dt_assignment_operator_family_map();
    for my $family (keys %$family_map) {
        $advertised{$_} = 1 for @{$family_map->{$family}};
    }
    return %advertised;
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}
