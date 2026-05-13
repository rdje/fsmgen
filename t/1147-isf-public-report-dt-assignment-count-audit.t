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
    isf_public_interface_schedule_report_dt_assignments_shape
);

subtest 'direct ISF schedule-report DT assignment-count metadata is exact' => sub {
    assert_dt_assignment_count_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF schedule-report DT assignment-count metadata is exact' => sub {
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
        assert_dt_assignment_count_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'APB schedule-report DT assignment counts match scheduled .fsm DT blocks' => sub {
    my $isf_path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $report = JSON::PP->new->decode($scheduler->report($actor));

    my $fsm_counts = dt_assignment_counts_from_fsm($lowered->{files}{'apb_requester.fsm'});
    ok(keys(%$fsm_counts), 'scheduled .fsm exposes non-state DT blocks to count');

    for my $dt (@{$report->{dt_blocks} || []}) {
        my $name = $dt->{name};
        ok(exists $fsm_counts->{$name}, "schedule report DT '$name' exists in scheduled .fsm");
        like($dt->{assignments}, qr/\A(?:0|[1-9][0-9]*)\z/, "DT '$name' assignment count is an integer");
        is($dt->{assignments}, $fsm_counts->{$name}, "DT '$name' assignment count matches scheduled .fsm");
    }
};

done_testing();

sub assert_dt_assignment_count_metadata {
    my ($contract, $label) = @_;

    is(
        $contract->{schedule_report_dt_assignments_shape},
        isf_public_interface_schedule_report_dt_assignments_shape(),
        "$label schedule-report DT assignments shape is exact",
    );
}

sub dt_assignment_counts_from_fsm {
    my ($fsm_text) = @_;
    my %counts;

    while ($fsm_text =~ /^  \(-([A-Za-z_][A-Za-z0-9_]*)\n(.*?^  \)\n)/msg) {
        my ($name, $body) = ($1, $2);
        my @assignments = $body =~ /^\s+\((?:=|<-|<=|<[0-9]+)\s+\(/gm;
        $counts{$name} = scalar(@assignments);
    }

    return \%counts;
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
