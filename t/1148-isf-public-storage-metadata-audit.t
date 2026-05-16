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
    isf_public_interface_schedule_report_storage_kind_values
    isf_public_interface_schedule_report_storage_role_values
    isf_public_interface_schedule_report_storage_width_shape
);

subtest 'direct ISF schedule-report storage metadata is exact and unique' => sub {
    assert_storage_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF schedule-report storage metadata is exact and unique' => sub {
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
        assert_storage_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'APB schedule report inferred storage follows advertised metadata' => sub {
    my $isf_path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $report = JSON::PP->new->decode(FSM::Scheduler::ISF->new()->report($actor));
    my %kind = map { $_ => 1 } @{isf_public_interface_schedule_report_storage_kind_values()};
    my %role = map { $_ => 1 } @{isf_public_interface_schedule_report_storage_role_values()};
    my $width_entries = 0;
    my $role_entries = 0;

    ok(@{$report->{inferred_storage} || []}, 'APB report exposes inferred storage entries');
    for my $entry (@{$report->{inferred_storage} || []}) {
        ok($kind{$entry->{kind}}, "storage '$entry->{name}' kind '$entry->{kind}' is advertised");
        if (exists $entry->{role}) {
            $role_entries++;
            ok($role{$entry->{role}}, "storage '$entry->{name}' role '$entry->{role}' is advertised");
        }
        if (exists $entry->{width}) {
            $width_entries++;
            like($entry->{width}, qr/\A[1-9][0-9]*\z/, "storage '$entry->{name}' width is a positive integer");
        }
    }

    my ($done) = grep { $_->{name} eq 'done' } @{$report->{inferred_storage} || []};
    ok($done, 'APB report exposes completion done storage');
    is($done->{kind}, 'register', 'completion pulse storage is reported through the register kind')
        if $done;
    is($done->{role}, 'completion_pulse', 'completion pulse storage reports its role')
        if $done;
    is($done->{width}, 1, 'completion pulse storage reports its known one-bit width')
        if $done;

    ok($width_entries > 0, 'APB report includes width-bearing inferred storage entries');
    ok($role_entries > 0, 'APB report includes role-bearing inferred storage entries');
};

subtest 'runtime dynamic wait storage role follows advertised metadata' => sub {
    my $report = report_source(dynamic_wait_source(), 'dynamic-wait-storage-role.isf');
    my %role = map { $_ => 1 } @{isf_public_interface_schedule_report_storage_role_values()};

    ok($role{dynamic_wait_counter}, 'dynamic_wait_counter is an advertised storage role');

    my ($counter) = grep {
        ($_->{name} // '') eq 'main_wait_1_cnt'
    } @{$report->{inferred_storage} || []};

    ok($counter, 'runtime dynamic wait report exposes generated counter storage');
    is($counter->{kind}, 'counter', 'runtime dynamic wait storage is a counter')
        if $counter;
    is($counter->{role}, 'dynamic_wait_counter', 'runtime dynamic wait storage reports its role')
        if $counter;
    is($counter->{width}, 4, 'runtime dynamic wait storage reports the count-source width')
        if $counter;
};

done_testing();

sub assert_storage_metadata {
    my ($contract, $label) = @_;

    is_deeply(
        $contract->{schedule_report_storage_kind_values},
        isf_public_interface_schedule_report_storage_kind_values(),
        "$label storage kind values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_storage_kind_values},
        "$label storage kind values",
    );
    is_deeply(
        $contract->{schedule_report_storage_role_values},
        isf_public_interface_schedule_report_storage_role_values(),
        "$label storage role values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_storage_role_values},
        "$label storage role values",
    );
    is(
        $contract->{schedule_report_storage_width_shape},
        isf_public_interface_schedule_report_storage_width_shape(),
        "$label storage width shape is exact",
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

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub report_source {
    my ($source, $label) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, $label);
    return decode_json(FSM::Scheduler::ISF->new()->report($actor));
}

sub dynamic_wait_source {
    return <<'ISF';
(actor dynamic_wait_storage_role
  (clock clk)
  (interface
    (input start)
    (input cycles (width 4))
    (output done))
  (transaction main
    (on start)
    (wait cycles)
    (complete done)))
ISF
}
