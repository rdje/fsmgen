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
    isf_public_interface_schedule_report_reset_kind_values
    isf_public_interface_schedule_report_reset_polarity_values
);

subtest 'direct ISF schedule-report reset metadata is exact and unique' => sub {
    assert_reset_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF schedule-report reset metadata is exact and unique' => sub {
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
        assert_reset_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'schedule reports use advertised reset kind and polarity values' => sub {
    my @reports = (
        ['APB async active-low reset', report_for_file('isf/apb_requester.isf')],
        ['inline sync active-high reset', report_for_source(sync_active_high_source())],
    );
    my %kind = map { $_ => 1 } @{isf_public_interface_schedule_report_reset_kind_values()};
    my %polarity = map { $_ => 1 } @{isf_public_interface_schedule_report_reset_polarity_values()};

    for my $case (@reports) {
        my ($label, $report) = @$case;
        ok(ref($report->{reset}) eq 'HASH', "$label exposes reset summary");
        ok($kind{$report->{reset}{kind}}, "$label reset kind '$report->{reset}{kind}' is advertised");
        ok(
            $polarity{$report->{reset}{polarity}},
            "$label reset polarity '$report->{reset}{polarity}' is advertised",
        );
    }
};

done_testing();

sub assert_reset_metadata {
    my ($contract, $label) = @_;

    is_deeply(
        $contract->{schedule_report_reset_kind_values},
        isf_public_interface_schedule_report_reset_kind_values(),
        "$label reset kind values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_reset_kind_values},
        "$label reset kind values",
    );
    is_deeply(
        $contract->{schedule_report_reset_polarity_values},
        isf_public_interface_schedule_report_reset_polarity_values(),
        "$label reset polarity values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_reset_polarity_values},
        "$label reset polarity values",
    );
}

sub assert_unique_scalar_list {
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

sub report_for_file {
    my ($relpath) = @_;
    my $path = File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relpath);
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    return JSON::PP->new->decode(FSM::Scheduler::ISF->new()->report($actor));
}

sub report_for_source {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'inline-reset-probe.isf');
    return JSON::PP->new->decode(FSM::Scheduler::ISF->new()->report($actor));
}

sub sync_active_high_source {
    return <<'ISF';
(actor reset_probe
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF
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
