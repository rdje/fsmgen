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
    isf_public_interface_schedule_report_transaction_ordering
);

subtest 'direct ISF transaction-ordering metadata is exact' => sub {
    assert_transaction_ordering_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF transaction-ordering metadata is exact' => sub {
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
        assert_transaction_ordering_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'schedule-report transaction summaries follow advertised ordering' => sub {
    my ($report, $lowered) = lower_and_report('full_featured.isf');
    my @names = map { $_->{name} } @{$report->{transactions} || []};

    is_deeply(
        \@names,
        [sort @names],
        'transaction summaries are sorted lexically by transaction name',
    );
    ok(@names > 1, 'fixture exercises more than one transaction summary');

    my @scheduled_states = scheduled_state_names($lowered->{files}{'full_featured.fsm'});
    for my $transaction (@{$report->{transactions} || []}) {
        my $name = $transaction->{name};
        my @expected_states = grep { belongs_to_transaction($_, $name) } @scheduled_states;
        is_deeply(
            $transaction->{states},
            \@expected_states,
            "transaction '$name' states keep scheduled .fsm emission order",
        );
    }
};

done_testing();

sub assert_transaction_ordering_metadata {
    my ($contract, $label) = @_;

    is(
        $contract->{schedule_report_transaction_ordering},
        isf_public_interface_schedule_report_transaction_ordering(),
        "$label schedule_report_transaction_ordering is exact",
    );
}

sub lower_and_report {
    my ($fixture) = @_;
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', $fixture);
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    my $scheduler = FSM::Scheduler::ISF->new();

    return (
        decode_json($scheduler->report($actor)),
        $scheduler->lower($actor),
    );
}

sub scheduled_state_names {
    my ($fsm_text) = @_;
    return $fsm_text =~ /^  \(([A-Za-z_][A-Za-z0-9_]*)\n/gm;
}

sub belongs_to_transaction {
    my ($state_name, $transaction_name) = @_;
    return $state_name =~ /\A\Q$transaction_name\E(?:_|_timeout\z)/;
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
