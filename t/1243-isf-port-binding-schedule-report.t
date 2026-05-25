#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_schedule_report_transaction_port_binding_keys
    isf_public_interface_schedule_report_transaction_port_binding_actor_endpoint_kind_values
    isf_public_interface_schedule_report_transaction_port_binding_timing_values
    isf_public_interface_schedule_report_transaction_port_binding_site_kind_values
);

my $source = <<'ISF';
(actor port_binding_report
  (clock clk)
  (interface
    (input start)
    (input fire)
    (input req_addr (width 8))
    (output done)
    (output resp (width 8)))
  (transaction do_child
    (ports
      (input addr (width 8))
      (output data (width 8)))
    (on do_child_start)
    (update data addr)
    (complete do_child_done))
  (transaction spawn_child
    (ports
      (input addr (width 8))
      (output data (width 8)))
    (update data addr)
    (complete done))
  (transaction work
    (ports
      (input addr (width 8)))
    (on work_start)
    (complete done))
  (transaction parent
    (on start)
    (do do_child
      (bind
        (input addr req_addr)
        (output data resp)))
    (spawn spawn_child as w0
      (bind
        (input addr req_addr)
        (output data resp)))
    (complete done))
  (rule fire_work fire
    (trigger work
      (bind
        (input addr req_addr)))))
ISF

subtest 'in-process report exposes bounded transaction port bindings' => sub {
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'port-binding-report.isf');
    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    assert_binding_projection($report, 'in-process schedule report');
};

subtest 'CLI report exposes bounded transaction port bindings' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'port_binding_report.isf');
    write_file($path, $source);

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok($success, 'CLI schedule report succeeds');
    is(join('', @{$stderr_buf || []}), '', 'CLI schedule report keeps stderr clean');

    my $report = decode_json(join('', @{$stdout_buf || []}));
    assert_binding_projection($report, 'CLI schedule report');
};

subtest 'expression input bindings report actor_expression separately from actor_signal' => sub {
    my $source = <<'ISF';
(actor port_binding_expression_report
  (clock clk)
  (interface
    (input start)
    (input req_hi (width 4))
    (input req_lo (width 4))
    (output done))
  (transaction child
    (ports
      (input addr (width 8)))
    (on child_start)
    (complete done))
  (transaction parent
    (on start)
    (do child
      (bind
        (input addr (concat req_hi req_lo))))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'port-binding-expression-report.isf');
    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    my $binding = $report->{transaction_port_bindings}[0];

    is_deeply(
        sorted([keys %$binding]),
        sorted(isf_public_interface_schedule_report_transaction_port_binding_keys()),
        'expression binding entry still uses the bounded public key set',
    );
    is($binding->{actor_signal}, undef, 'expression input binding has no scalar actor_signal');
    is($binding->{actor_expression}, '(concat req_hi req_lo)', 'expression input binding reports the formatted actor expression');
    is($binding->{actor_endpoint_kind}, 'expression', 'expression input binding reports endpoint kind');
    is($binding->{binding_timing}, 'activation_region', 'expression input binding reports activation-region timing');
};

subtest 'literal input bindings report literal endpoint kind' => sub {
    my $source = <<'ISF';
(actor port_binding_literal_report
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction child
    (ports
      (input addr (width 8)))
    (on child_start)
    (complete done))
  (transaction parent
    (on start)
    (do child
      (bind
        (input addr 8'hA5)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'port-binding-literal-report.isf');
    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    my $binding = $report->{transaction_port_bindings}[0];

    is_deeply(
        sorted([keys %$binding]),
        sorted(isf_public_interface_schedule_report_transaction_port_binding_keys()),
        'literal binding entry still uses the bounded public key set',
    );
    is($binding->{actor_signal}, undef, 'literal input binding has no scalar actor_signal');
    is($binding->{actor_expression}, "8'hA5", 'literal input binding reports the authored literal expression');
    is($binding->{actor_endpoint_kind}, 'literal', 'literal input binding reports endpoint kind');
    is($binding->{binding_timing}, 'activation_region', 'literal input binding reports activation-region timing');
};

done_testing();

sub assert_binding_projection {
    my ($report, $label) = @_;

    ok(exists $report->{transaction_port_bindings}, "$label exposes transaction_port_bindings");
    is(ref($report->{transaction_port_bindings}), 'ARRAY', "$label transaction_port_bindings is an array");
    is(scalar(@{$report->{transaction_port_bindings}}), 5, "$label reports every authored scalar binding");

    my %allowed_site_kind = map { $_ => 1 } @{isf_public_interface_schedule_report_transaction_port_binding_site_kind_values()};
    my %allowed_endpoint_kind = map { $_ => 1 } @{isf_public_interface_schedule_report_transaction_port_binding_actor_endpoint_kind_values()};
    my %allowed_timing = map { $_ => 1 } @{isf_public_interface_schedule_report_transaction_port_binding_timing_values()};
    for my $binding (@{$report->{transaction_port_bindings}}) {
        is_deeply(
            sorted([keys %$binding]),
            sorted(isf_public_interface_schedule_report_transaction_port_binding_keys()),
            "$label binding entry uses the bounded public key set",
        );
        ok($allowed_site_kind{$binding->{site_kind}}, "$label binding site kind is advertised");
        ok($allowed_endpoint_kind{$binding->{actor_endpoint_kind}}, "$label binding endpoint kind is advertised");
        ok($allowed_timing{$binding->{binding_timing}}, "$label binding timing is advertised");
    }

    is_deeply(
        $report->{transaction_port_bindings},
        expected_bindings(),
        "$label preserves bounded do/spawn/rule-trigger binding provenance",
    );
}

sub expected_bindings {
    return [
        {
            site_kind          => 'do',
            owner              => 'parent',
            owner_kind         => 'transaction',
            target_transaction => 'do_child',
            role               => 'input',
            port               => 'addr',
            actor_signal       => 'req_addr',
            actor_expression   => 'req_addr',
            actor_endpoint_kind => 'signal',
            binding_timing      => 'activation_region',
            width              => 8,
            instance           => undef,
            parent_port        => undef,
            child_port         => undef,
            start_signal       => 'do_child_start',
            done_signal        => 'do_child_done',
            trigger_source     => undef,
            payload_source     => undef,
        },
        {
            site_kind          => 'do',
            owner              => 'parent',
            owner_kind         => 'transaction',
            target_transaction => 'do_child',
            role               => 'output',
            port               => 'data',
            actor_signal       => 'resp',
            actor_expression   => 'resp',
            actor_endpoint_kind => 'signal',
            binding_timing      => 'done_guarded',
            width              => 8,
            instance           => undef,
            parent_port        => undef,
            child_port         => undef,
            start_signal       => 'do_child_start',
            done_signal        => 'do_child_done',
            trigger_source     => undef,
            payload_source     => undef,
        },
        {
            site_kind          => 'spawn',
            owner              => 'parent',
            owner_kind         => 'transaction',
            target_transaction => 'spawn_child',
            role               => 'input',
            port               => 'addr',
            actor_signal       => 'req_addr',
            actor_expression   => 'req_addr',
            actor_endpoint_kind => 'signal',
            binding_timing      => 'generated_live_handoff',
            width              => 8,
            instance           => 'w0',
            parent_port        => 'w0_addr',
            child_port         => 'addr',
            start_signal       => 'w0_start',
            done_signal        => 'w0_done',
            trigger_source     => undef,
            payload_source     => undef,
        },
        {
            site_kind          => 'spawn',
            owner              => 'parent',
            owner_kind         => 'transaction',
            target_transaction => 'spawn_child',
            role               => 'output',
            port               => 'data',
            actor_signal       => 'resp',
            actor_expression   => 'resp',
            actor_endpoint_kind => 'signal',
            binding_timing      => 'generated_live_handoff',
            width              => 8,
            instance           => 'w0',
            parent_port        => 'w0_data',
            child_port         => 'data',
            start_signal       => 'w0_start',
            done_signal        => 'w0_done',
            trigger_source     => undef,
            payload_source     => undef,
        },
        {
            site_kind          => 'rule_trigger',
            owner              => 'fire_work',
            owner_kind         => 'rule',
            target_transaction => 'work',
            role               => 'input',
            port               => 'addr',
            actor_signal       => 'req_addr',
            actor_expression   => 'req_addr',
            actor_endpoint_kind => 'signal',
            binding_timing      => 'trigger_payload',
            width              => 8,
            instance           => undef,
            parent_port        => undef,
            child_port         => undef,
            start_signal       => 'work_start',
            done_signal        => undef,
            trigger_source     => 'fire_work_work',
            payload_source     => 'fire_work_work_addr',
        },
    ];
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
