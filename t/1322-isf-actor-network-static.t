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
    isf_public_interface_schedule_report_actor_network_event_wait_keys
    isf_public_interface_schedule_report_actor_network_instance_keys
    isf_public_interface_schedule_report_actor_network_keys
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
            event_waits => [],
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
            event_waits => [],
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
        },
        'actor-event wait report',
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
(actor qualified_transaction_trigger
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (trigger reader.capture)
    (complete done)))
ISF
        qr/ATL actor transaction trigger '\(trigger reader\.capture\)' is reserved but not supported yet/,
        'transaction-body qualified actor trigger fails closed before generic unsupported-clause diagnostics',
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
