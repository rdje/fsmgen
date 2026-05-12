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
    isf_public_interface_schedule_report_dt_kind_values
);

subtest 'direct ISF schedule-report DT kind metadata is exact and unique' => sub {
    assert_dt_kind_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF schedule-report DT kind metadata is exact and unique' => sub {
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
        assert_dt_kind_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'schedule reports use exactly advertised DT kind values' => sub {
    my %advertised = map { $_ => 1 } @{isf_public_interface_schedule_report_dt_kind_values()};
    my %observed;

    for my $fixture (qw(apb_requester.isf full_featured.isf)) {
        my $report = report_for_file($fixture);
        ok(@{$report->{dt_blocks} || []}, "$fixture exposes DT block summaries");

        for my $dt (@{$report->{dt_blocks} || []}) {
            my $kind = $dt->{kind};
            ok($advertised{$kind}, "$fixture DT '$dt->{name}' kind '$kind' is advertised");
            $observed{$kind} = 1;
        }
    }

    is_deeply(
        sorted([keys %observed]),
        sorted(isf_public_interface_schedule_report_dt_kind_values()),
        'fixtures cover every advertised DT kind value',
    );
};

done_testing();

sub assert_dt_kind_metadata {
    my ($contract, $label) = @_;

    is_deeply(
        $contract->{schedule_report_dt_kind_values},
        isf_public_interface_schedule_report_dt_kind_values(),
        "$label schedule_report_dt_kind_values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_dt_kind_values},
        "$label schedule_report_dt_kind_values",
    );
}

sub report_for_file {
    my ($fixture) = @_;
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', $fixture);
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    return decode_json(FSM::Scheduler::ISF->new()->report($actor));
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

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
