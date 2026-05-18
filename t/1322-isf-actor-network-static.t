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
    isf_public_interface_schedule_report_actor_network_data_movement_keys
    isf_public_interface_schedule_report_actor_network_event_wait_keys
    isf_public_interface_schedule_report_actor_network_instance_keys
    isf_public_interface_schedule_report_actor_network_keys
    isf_public_interface_schedule_report_actor_network_transaction_trigger_keys
);

subtest 'actor-body static instance is parsed, lowered, and reported' => sub {
    my $source = actor_body_network_source('atl_static_network');
    my $actor = parse_source($source, 'atl-static-network.isf');

    is_deeply(
        $actor->{actor_network},
        {
            kind      => 'static_declaration',
            instances => [
                {
                    name        => 'reader',
                    actor_type  => 'packet_reader',
                    declaration => 'actor',
                },
            ],
            data_movements => [],
            event_waits => [],
            transaction_triggers => [],
        },
        'parser preserves actor-body static actor-network instance identity',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    is_deeply(
        [sort keys %{$lowered->{files}}],
        ['atl_static_network.fsm'],
        'static actor-network declaration is report-only in this slice and emits no child artifacts',
    );

    my $report = decode_json($scheduler->report($actor));
    assert_actor_network_report(
        $report,
        {
            kind      => 'static_declaration',
            instances => [
                {
                    name        => 'reader',
                    actor_type  => 'packet_reader',
                    declaration => 'actor',
                },
            ],
            data_movements => [],
            event_waits => [],
            transaction_triggers => [],
        },
        'actor-body network report',
    );

    my $path = write_temp_isf($source);
    my $cli_report = run_schedule_json($path, 'actor-body static actor network');
    is_deeply($cli_report, $report, 'CLI schedule JSON matches in-process report for actor-body static actor network');
};

subtest 'unsupported static graph shapes fail closed' => sub {
    parse_fails_like(
        <<'ISF',
(actor two_instances
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (instance writer of packet_writer)
  (transaction run (on start) (complete done)))
ISF
        qr/currently accepts exactly one actor instance/,
        'multiple static instances are rejected until multi-instance scheduling ships',
    );

    parse_fails_like(
        <<'ISF',
(actor unsupported_group
  (clock clk)
  (interface (input start) (output done))
  (group pipeline (members reader))
  (transaction run (on start) (complete done)))
ISF
        qr/ATL group clauses are not supported yet/,
        'unsupported network group fails closed',
    );

    parse_fails_like(
        <<'ISF',
(actor dynamic_instance
  (clock clk)
  (interface (input start) (output done))
  (instance (select reader writer) of packet_reader)
  (transaction run (on start) (complete done)))
ISF
        qr/static actor instance name must be a scalar HDL identifier/,
        'dynamic or non-scalar instance names fail closed',
    );

    parse_fails_like(
        <<'ISF',
(actor recursive_network
  (clock clk)
  (interface (input start) (output done))
  (instance self of recursive_network)
  (transaction run (on start) (complete done)))
ISF
        qr/cannot instantiate its own enclosing actor type/,
        'direct recursive static actor instance fails closed',
    );

    parse_fails_like(
        <<'ISF',
(actor scoped_network_rejected
  (clock clk)
  (interface (input start) (output done))
  (network
    (instance reader of packet_reader))
  (transaction run (on start) (complete done)))
ISF
        qr/direct '\(instance name of actor_type\)' actor clauses; '\(network \.\.\.\)' is not supported/,
        'scoped network wrapper is rejected',
    );
};

subtest 'selected qualified event wait lowers to parent handoff input' => sub {
    my $actor = parse_source(<<'ISF', 'atl-event-wait.isf');
(actor atl_event_wait
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (await reader.done)
    (complete done)))
ISF

    is_deeply(
        $actor->{actor_network}{event_waits},
        [
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'reader',
                event       => 'done',
                signal      => 'reader_done',
                source      => 'external_handoff',
            },
        ],
        'parser records the selected actor-event wait handoff metadata',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'atl_event_wait.fsm'};
    ok($fsm, 'selected actor-event wait still emits the parent scheduled .fsm only');
    is_deeply(
        [sort keys %{$lowered->{files}}],
        ['atl_event_wait.fsm'],
        'selected actor-event wait does not emit ATL child artifacts or a generated top',
    );
    like($fsm, qr/\(reader_done 1\)/, 'scheduled .fsm exposes generated event handoff input');
    like($fsm, qr/<reader_done\s+\(\-> run_done_2\)/, 'scheduled .fsm awaits the generated event handoff input');

    my $report = decode_json($scheduler->report($actor));
    assert_actor_network_report(
        $report,
        {
            kind      => 'static_declaration',
            instances => [
                {
                    name        => 'reader',
                    actor_type  => 'packet_reader',
                    declaration => 'actor',
                },
            ],
            data_movements => [],
            event_waits => [
                {
                    transaction => 'run',
                    context     => 'transaction_body',
                    instance    => 'reader',
                    event       => 'done',
                    signal      => 'reader_done',
                    source      => 'external_handoff',
                },
            ],
            transaction_triggers => [],
        },
        'actor-event wait report',
    );
};

subtest 'selected qualified transaction trigger lowers to parent handoff output' => sub {
    my $actor = parse_source(<<'ISF', 'atl-transaction-trigger.isf');
(actor atl_transaction_trigger
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (trigger reader.capture)
    (complete done)))
ISF

    is_deeply(
        $actor->{actor_network}{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'reader',
                target_transaction => 'capture',
                signal             => 'reader_capture_start',
                sink               => 'external_handoff',
            },
        ],
        'parser records the selected actor-transaction trigger handoff metadata',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'atl_transaction_trigger.fsm'};
    ok($fsm, 'selected actor-transaction trigger still emits the parent scheduled .fsm only');
    is_deeply(
        [sort keys %{$lowered->{files}}],
        ['atl_transaction_trigger.fsm'],
        'selected actor-transaction trigger does not emit ATL child artifacts or a generated top',
    );
    like($fsm, qr/\(reader_capture_start 1\)/, 'scheduled .fsm exposes generated trigger handoff output');
    like($fsm, qr/\(<1 \(reader_capture_start> 1\)\)/, 'scheduled .fsm pulses the generated trigger handoff output');

    my $report = decode_json($scheduler->report($actor));
    assert_actor_network_report(
        $report,
        {
            kind      => 'static_declaration',
            instances => [
                {
                    name        => 'reader',
                    actor_type  => 'packet_reader',
                    declaration => 'actor',
                },
            ],
            data_movements => [],
            event_waits => [],
            transaction_triggers => [
                {
                    owner_transaction  => 'run',
                    context            => 'transaction_body',
                    instance           => 'reader',
                    target_transaction => 'capture',
                    signal             => 'reader_capture_start',
                    sink               => 'external_handoff',
                },
            ],
        },
        'actor-transaction trigger report',
    );
};

subtest 'selected scalar actor-to-actor data movement lowers to parent handoff ports' => sub {
    my $source = <<'ISF';
(actor atl_scalar_data_movement
  (clock clk)
  (interface (input start) (output done))
  (instance producer of packet_reader)
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload producer.payload))
  (transaction run
    (on start)
    (drive feed_consumer)
    (complete done)))
ISF
    my $actor = parse_source($source, 'atl-scalar-data-movement.isf');

    my $expected_movement = {
        kind            => 'scalar_actor_handoff',
        transaction     => 'run',
        context         => 'transaction_body',
        drive           => 'feed_consumer',
        source_instance => 'producer',
        source_endpoint => 'payload',
        source_signal   => 'producer_payload',
        sink_instance   => 'consumer',
        sink_endpoint   => 'payload',
        sink_signal     => 'consumer_payload',
        width           => 1,
        width_source    => 'scalar_one_bit',
        route_lifetime  => 'drive_call_cycle',
        storage         => 'none',
        source          => 'external_handoff',
        sink            => 'external_handoff',
    };

    is_deeply(
        $actor->{drives}{feed_consumer}{body},
        [
            [ 'consumer_payload', 'producer_payload' ],
        ],
        'parser rewrites the selected ATL endpoint pair to generated parent handoff signals',
    );
    is_deeply(
        $actor->{actor_network}{data_movements},
        [ $expected_movement ],
        'parser records the selected scalar actor-to-actor data movement metadata',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'atl_scalar_data_movement.fsm'};
    ok($fsm, 'selected scalar data movement still emits the parent scheduled .fsm only');
    is_deeply(
        [sort keys %{$lowered->{files}}],
        ['atl_scalar_data_movement.fsm'],
        'selected scalar data movement does not emit ATL child artifacts or a generated top',
    );
    like($fsm, qr/\(producer_payload 1\)/, 'scheduled .fsm exposes generated source handoff input');
    like($fsm, qr/\(consumer_payload 1\)/, 'scheduled .fsm exposes generated sink handoff output');
    like($fsm, qr/\(<- \(consumer_payload>?\s+producer_payload\) <feed_consumer_start\)/,
        'drive body lowers the selected scalar handoff through the named drive request');

    my $report = decode_json($scheduler->report($actor));
    assert_actor_network_report(
        $report,
        {
            kind      => 'static_declaration',
            instances => [
                {
                    name        => 'producer',
                    actor_type  => 'packet_reader',
                    declaration => 'actor',
                },
                {
                    name        => 'consumer',
                    actor_type  => 'packet_writer',
                    declaration => 'actor',
                },
            ],
            data_movements => [ $expected_movement ],
            event_waits => [],
            transaction_triggers => [],
        },
        'actor scalar data movement report',
    );

    my $path = write_temp_isf($source);
    my $cli_report = run_schedule_json($path, 'actor scalar data movement');
    is_deeply($cli_report, $report, 'CLI schedule JSON matches in-process report for scalar data movement');
};

subtest 'reserved endpoint-aware drive movement forms fail closed with ATL diagnostics' => sub {
    parse_fails_like(
        <<'ISF',
(actor qualified_drive_sink
  (clock clk)
  (interface (input start) (input payload) (output done))
  (instance reader of packet_reader)
  (drive feed_reader
    (reader.payload payload))
  (transaction run
    (on start)
    (drive feed_reader)
    (complete done)))
ISF
        qr/drive 'feed_reader' body ATL scalar actor-to-actor data movement requires exactly two direct static actor instances/,
        'named drive body qualified actor sink fails closed before local dotted-name diagnostics',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_drive_source
  (clock clk)
  (interface (input start) (output payload) (output done))
  (instance reader of packet_reader)
  (drive read_payload
    (payload reader.payload))
  (transaction run
    (on start)
    (drive read_payload)
    (complete done)))
ISF
        qr/drive 'read_payload' body ATL scalar actor-to-actor data movement requires exactly two direct static actor instances/,
        'named drive body qualified actor source fails closed before local dotted-name diagnostics',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_inline_drive_source
  (clock clk)
  (interface (input start) (output payload) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (drive inline_payload (payload reader.payload))
    (complete done)))
ISF
        qr/transaction 'run' inline drive source ATL actor data movement source 'reader\.payload' is reserved but not supported yet/,
        'inline drive qualified actor source fails closed before local dotted-name diagnostics',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_drive_without_call
  (clock clk)
  (interface (input start) (output done))
  (instance producer of packet_reader)
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload producer.payload))
  (transaction run
    (on start)
    (complete done)))
ISF
        qr/drive 'feed_consumer' ATL scalar actor-to-actor data movement requires exactly one top-level transaction drive call/,
        'selected data movement drive requires one top-level drive call',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_drive_nested_call
  (clock clk)
  (interface (input start) (output done))
  (instance producer of packet_reader)
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload producer.payload))
  (transaction run
    (on start)
    (when start
      (drive feed_consumer))
    (complete done)))
ISF
        qr/transaction 'run' when body ATL scalar actor-to-actor data movement drive '\(drive feed_consumer\)' is reserved for top-level transaction bodies only/,
        'selected data movement drive call remains top-level only',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_drive_multiple_pairs
  (clock clk)
  (interface (input start) (output done))
  (instance producer of packet_reader)
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload producer.payload)
    (consumer.valid producer.valid))
  (transaction run
    (on start)
    (drive feed_consumer)
    (complete done)))
ISF
        qr/drive 'feed_consumer' body ATL scalar actor-to-actor data movement requires exactly one drive-body pair/,
        'selected data movement drive body remains one scalar pair only',
    );
};

subtest 'unsupported qualified event and trigger forms fail closed with ATL diagnostics' => sub {
    parse_fails_like(
        <<'ISF',
(actor nested_qualified_event_wait
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (when start
      (await reader.done))
    (complete done)))
ISF
        qr/ATL actor event wait '\(await reader\.done\)' is reserved for top-level transaction bodies only/,
        'nested qualified actor event wait fails closed before generic enum diagnostics',
    );

    parse_fails_like(
        <<'ISF',
(actor multiple_qualified_event_waits
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (await reader.done)
    (await reader.ready)
    (complete done)))
ISF
        qr/exceeds the current one-event-wait subset/,
        'multiple qualified actor event waits fail closed until fan-in/fan-out policy ships',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_event_wait_signal_conflict
  (clock clk)
  (interface
    (input start)
    (input reader_done)
    (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (await reader.done)
    (complete done)))
ISF
        qr/generated handoff signal 'reader_done' conflicts with a declared actor signal/,
        'generated actor event handoff names fail closed on actor signal conflicts',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_event_wait_multi_domain
  (clock-domains
    (domain core (clock clk_a) :default)
    (domain io (clock clk_b)))
  (interface
    (input start (domain core))
    (output done (domain core)))
  (instance reader of packet_reader)
  (transaction run
    (domain core)
    (on start)
    (await reader.done)
    (complete done)))
ISF
        qr/ATL actor event waits require a single-clock actor in the current subset/,
        'actor event waits fail closed for multi-domain actors until cross-clock ATL events ship',
    );

    parse_fails_like(
        <<'ISF',
(actor nested_qualified_transaction_trigger
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (when start
      (trigger reader.capture))
    (complete done)))
ISF
        qr/ATL actor transaction trigger '\(trigger reader\.capture\)' is reserved for top-level transaction bodies only/,
        'nested qualified actor trigger fails closed before generic unsupported-clause diagnostics',
    );

    parse_fails_like(
        <<'ISF',
(actor multiple_qualified_transaction_triggers
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (trigger reader.capture)
    (trigger reader.flush)
    (complete done)))
ISF
        qr/exceeds the current one-trigger subset/,
        'multiple qualified actor triggers fail closed until fan-in/fan-out policy ships',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_transaction_trigger_signal_conflict
  (clock clk)
  (interface
    (input start)
    (output done)
    (output reader_capture_start))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (trigger reader.capture)
    (complete done)))
ISF
        qr/generated handoff signal 'reader_capture_start' conflicts with a declared actor signal/,
        'generated actor trigger handoff names fail closed on actor signal conflicts',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_handoff_signal_conflict
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (await reader.capture_start)
    (trigger reader.capture)
    (complete done)))
ISF
        qr/generated handoff signal 'reader_capture_start' is used by both actor event wait 'reader\.capture_start' and actor transaction trigger 'reader\.capture'/,
        'event and trigger generated handoff name collisions fail closed',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_transaction_trigger_multi_domain
  (clock-domains
    (domain core (clock clk_a) :default)
    (domain io (clock clk_b)))
  (interface
    (input start (domain core))
    (output done (domain core)))
  (instance reader of packet_reader)
  (transaction run
    (domain core)
    (on start)
    (trigger reader.capture)
    (complete done)))
ISF
        qr/ATL actor transaction triggers require a single-clock actor in the current subset/,
        'actor transaction triggers fail closed for multi-domain actors until cross-clock ATL triggers ship',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_rule_trigger
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction local
    (complete done))
  (rule kick start
    (trigger reader.capture)))
ISF
        qr/ATL actor transaction trigger '\(trigger reader\.capture\)' is reserved but not supported yet/,
        'rule-level qualified actor trigger fails closed before unknown-transaction diagnostics',
    );

    my $actor = parse_source(<<'ISF', 'local-await-trigger.isf');
(actor local_await_trigger
  (clock clk)
  (interface
    (input start)
    (input ack)
    (output done))
  (instance reader of packet_reader)
  (transaction child
    (complete done))
  (transaction run
    (on start)
    (await ack)
    (complete done))
  (rule kick start
    (trigger child)))
ISF
    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    ok($lowered->{files}{'local_await_trigger.fsm'}, 'unqualified local await and rule trigger still lower');
};

done_testing();

sub assert_actor_network_report {
    my ($report, $expected, $label) = @_;

    is_deeply(
        [sort keys %{$report->{actor_network}}],
        [sort @{isf_public_interface_schedule_report_actor_network_keys()}],
        "$label exposes advertised actor_network keys",
    );
    is_deeply(
        [sort keys %{$report->{actor_network}{instances}[0]}],
        [sort @{isf_public_interface_schedule_report_actor_network_instance_keys()}],
        "$label exposes advertised actor_network instance keys",
    );
    if (@{$report->{actor_network}{event_waits} || []}) {
        is_deeply(
            [sort keys %{$report->{actor_network}{event_waits}[0]}],
            [sort @{isf_public_interface_schedule_report_actor_network_event_wait_keys()}],
            "$label exposes advertised actor_network event_wait keys",
        );
    }
    if (@{$report->{actor_network}{data_movements} || []}) {
        is_deeply(
            [sort keys %{$report->{actor_network}{data_movements}[0]}],
            [sort @{isf_public_interface_schedule_report_actor_network_data_movement_keys()}],
            "$label exposes advertised actor_network data_movement keys",
        );
    }
    if (@{$report->{actor_network}{transaction_triggers} || []}) {
        is_deeply(
            [sort keys %{$report->{actor_network}{transaction_triggers}[0]}],
            [sort @{isf_public_interface_schedule_report_actor_network_transaction_trigger_keys()}],
            "$label exposes advertised actor_network transaction_trigger keys",
        );
    }
    is_deeply($report->{actor_network}, $expected, "$label preserves actor-network identity");
}

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, $label);
}

sub parse_fails_like {
    my ($source, $pattern, $label) = @_;
    my $ok = eval {
        parse_source($source, 'actor-network-negative.isf');
        1;
    };
    ok(!$ok, "$label rejects source");
    like($@, $pattern, "$label reports the bounded diagnostic");
}

sub run_schedule_json {
    my ($path, $label) = @_;
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok($success, "$label CLI schedule JSON succeeds");
    is(join('', @{$stderr_buf || []}), '', "$label CLI schedule JSON keeps stderr clean");
    return decode_json(join('', @{$stdout_buf || []}));
}

sub write_temp_isf {
    my ($source) = @_;
    my $dir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'atl-static-network.isf');
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $source or die "cannot write $path: $!";
    close $fh or die "cannot close $path: $!";
    return $path;
}

sub actor_body_network_source {
    my ($actor_name) = @_;
    return <<"ISF";
(actor $actor_name
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (complete done)))
ISF
}
