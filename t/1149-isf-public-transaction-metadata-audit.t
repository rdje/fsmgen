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
    isf_public_interface_schedule_report_transaction_count_shape
    isf_public_interface_schedule_report_transaction_states_shape
);

subtest 'direct ISF schedule-report transaction metadata is exact' => sub {
    assert_transaction_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF schedule-report transaction metadata is exact' => sub {
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
        assert_transaction_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'APB schedule report transactions follow advertised metadata' => sub {
    my $isf_path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $report = JSON::PP->new->decode(FSM::Scheduler::ISF->new()->report($actor));

    ok(@{$report->{transactions} || []}, 'APB report exposes transaction summaries');
    for my $transaction (@{$report->{transactions} || []}) {
        my $name = $transaction->{name};
        ok(!ref($name) && length($name), 'transaction name is a non-empty scalar');
        ok(ref($transaction->{states}) eq 'ARRAY', "transaction '$name' states is an array");
        ok(@{$transaction->{states}}, "transaction '$name' states is non-empty");

        for my $state (@{$transaction->{states}}) {
            ok(!ref($state) && length($state), "transaction '$name' state '$state' is scalar");
            like($state, qr/\A\Q$name\E(?:_|_timeout\z)/, "transaction '$name' owns state '$state'");
        }

        like($transaction->{count}, qr/\A(?:0|[1-9][0-9]*)\z/, "transaction '$name' count is an integer");
        is($transaction->{count}, scalar(@{$transaction->{states}}), "transaction '$name' count matches states length");
    }
};

done_testing();

sub assert_transaction_metadata {
    my ($contract, $label) = @_;

    is(
        $contract->{schedule_report_transaction_states_shape},
        isf_public_interface_schedule_report_transaction_states_shape(),
        "$label transaction states shape is exact",
    );
    is(
        $contract->{schedule_report_transaction_count_shape},
        isf_public_interface_schedule_report_transaction_count_shape(),
        "$label transaction count shape is exact",
    );
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
