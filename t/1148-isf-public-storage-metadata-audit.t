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

subtest 'generated activation handoff storage roles follow advertised metadata' => sub {
    my %role = map { $_ => 1 } @{isf_public_interface_schedule_report_storage_role_values()};

    ok($role{transaction_port_binding}, 'transaction_port_binding is an advertised storage role');
    ok($role{trigger_done_observe}, 'trigger_done_observe is an advertised storage role');

    my $spawn_report = report_source(spawn_binding_source(), 'spawn-binding-storage-role.isf');
    for my $case (
        ['w0_addr', 'counter', 8],
        ['w0_data', 'counter', 8],
    ) {
        my ($name, $kind, $width) = @$case;
        my ($entry) = grep { ($_->{name} // '') eq $name } @{$spawn_report->{inferred_storage} || []};
        ok($entry, "spawn binding report exposes '$name' storage");
        is($entry->{kind}, $kind, "'$name' storage kind is stable")
            if $entry;
        is($entry->{role}, 'transaction_port_binding', "'$name' storage reports its role")
            if $entry;
        is($entry->{width}, $width, "'$name' storage reports its handoff width")
            if $entry;
    }

    my $trigger_report = report_source(trigger_binding_source(), 'trigger-binding-storage-role.isf');
    my ($done_seen) = grep {
        ($_->{name} // '') eq 'launch_worker_trigger_0_done_seen'
    } @{$trigger_report->{inferred_storage} || []};
    ok($done_seen, 'generated rule-trigger report exposes done-observe storage');
    is($done_seen->{kind}, 'counter', 'done-observe storage uses the generated counter class')
        if $done_seen;
    is($done_seen->{role}, 'trigger_done_observe', 'done-observe storage reports its role')
        if $done_seen;
    is($done_seen->{width}, 1, 'done-observe storage is one bit')
        if $done_seen;

    my ($trigger_payload) = grep {
        ($_->{name} // '') eq 'launch_worker_trigger_0_addr'
    } @{$trigger_report->{inferred_storage} || []};
    ok($trigger_payload, 'generated rule-trigger report exposes input handoff storage');
    is($trigger_payload->{role}, 'transaction_port_binding', 'trigger input handoff uses the transaction_port_binding role')
        if $trigger_payload;
    is($trigger_payload->{width}, 8, 'trigger input handoff preserves port width')
        if $trigger_payload;
};

subtest 'transaction-local port storage role follows advertised metadata' => sub {
    my $report = report_source(transaction_port_source(), 'transaction-port-storage-role.isf');
    my %role = map { $_ => 1 } @{isf_public_interface_schedule_report_storage_role_values()};

    ok($role{transaction_port}, 'transaction_port is an advertised storage role');

    my ($entry) = grep {
        ($_->{name} // '') eq 'addr'
    } @{$report->{inferred_storage} || []};

    ok($entry, 'transaction port report exposes materialized port storage');
    is($entry->{kind}, 'register', 'transaction port storage is a register')
        if $entry;
    is($entry->{role}, 'transaction_port', 'transaction port storage reports its role')
        if $entry;
    is($entry->{width}, 8, 'transaction port storage reports its declared width')
        if $entry;
};

subtest 'rule-trigger source storage roles follow advertised metadata' => sub {
    my $direct_report = report_source(rule_trigger_storage_source(), 'rule-trigger-storage-role.isf');
    my $generated_report = report_source(trigger_binding_source(), 'generated-rule-trigger-storage-role.isf');
    my %role = map { $_ => 1 } @{isf_public_interface_schedule_report_storage_role_values()};

    ok($role{rule_trigger_source}, 'rule_trigger_source is an advertised storage role');
    ok($role{rule_trigger_payload_source}, 'rule_trigger_payload_source is an advertised storage role');

    for my $case (
        [$direct_report, 'launch_worker', 'rule_trigger_source', 1],
        [$direct_report, 'launch_worker_addr', 'rule_trigger_payload_source', 8],
        [$generated_report, 'launch_worker_trigger_0', 'rule_trigger_source', 1],
        [$generated_report, 'launch_worker_trigger_0_addr_payload', 'rule_trigger_payload_source', 8],
    ) {
        my ($report, $name, $expected_role, $width) = @$case;
        my ($entry) = grep { ($_->{name} // '') eq $name } @{$report->{inferred_storage} || []};

        ok($entry, "rule-trigger report exposes '$name' storage");
        is($entry->{kind}, 'counter', "'$name' storage uses the generated counter class")
            if $entry;
        is($entry->{role}, $expected_role, "'$name' storage reports its role")
            if $entry;
        is($entry->{width}, $width, "'$name' storage reports its inferred width")
            if $entry;
    }
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

sub spawn_binding_source {
    return <<'ISF';
(actor spawn_binding_storage_role
  (clock clk)
  (interface
    (input start)
    (input req (width 8))
    (output resp (width 8))
    (output done))
  (transaction child
    (ports
      (input addr (width 8))
      (output data (width 8)))
    (update data addr)
    (complete done))
  (transaction main
    (on start)
    (spawn child as w0
      (bind
        (input addr req)
        (output data resp)))
    (complete done)))
ISF
}

sub trigger_binding_source {
    return <<'ISF';
(actor trigger_binding_storage_role
  (clock clk)
  (interface
    (input fire)
    (input req (width 8))
    (output done))
  (transaction parent
    (on fire)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (ports
      (input addr (width 8)))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (WIDTH 16))
      (bind
        (input addr req)))))
ISF
}

sub transaction_port_source {
    return <<'ISF';
(actor transaction_port_storage_role
  (clock clk)
  (interface
    (input start)
    (input req (width 8))
    (output done))
  (transaction main
    (ports
      (input addr (width 8)))
    (on start)
    (set addr req)
    (complete done)))
ISF
}

sub rule_trigger_storage_source {
    return <<'ISF';
(actor rule_trigger_storage_role
  (clock clk)
  (interface
    (input fire)
    (input req (width 8))
    (output done))
  (transaction worker
    (ports
      (input addr (width 8)))
    (on worker_start)
    (complete done))
  (rule launch fire
    (trigger worker
      (bind
        (input addr req)))))
ISF
}
