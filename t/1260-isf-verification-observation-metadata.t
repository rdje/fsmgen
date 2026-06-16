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
    isf_public_interface_schedule_report_top_level_keys
    isf_public_interface_schedule_report_verification_observation_keys
    isf_public_interface_schedule_report_verification_observation_signal_keys
    isf_public_interface_schedule_report_verification_observation_role_values
);

subtest 'actor-level observe metadata reaches bounded schedule report' => sub {
    my $actor = FSM::Adapter::ISF->new()->parse_source(
        observation_source(),
        'verification-observation-report.isf',
    );

    is_deeply(
        $actor->{verification_observations},
        [
            {
                name => 'link_rx',
                role => 'passive_monitor',
                signals => [
                    { name => 'valid', direction => 'input',  width => 1 },
                    { name => 'ready', direction => 'output', width => 1 },
                    { name => 'data',  direction => 'input',  width => 8 },
                ],
            },
        ],
        'parser records source-ordered resolved interface signal observations',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $report = decode_json($scheduler->report($actor));

    is_deeply(
        sorted([keys %$report]),
        sorted(isf_public_interface_schedule_report_top_level_keys()),
        'report exposes exactly the advertised top-level keys',
    );
    is_deeply(
        sorted([keys %{$report->{verification_observations}[0]}]),
        sorted(isf_public_interface_schedule_report_verification_observation_keys()),
        'observation entries expose the advertised keys',
    );
    is_deeply(
        sorted([keys %{$report->{verification_observations}[0]{signals}[0]}]),
        sorted(isf_public_interface_schedule_report_verification_observation_signal_keys()),
        'observation signal entries expose the advertised keys',
    );
    is_deeply(
        isf_public_interface_schedule_report_verification_observation_role_values(),
        ['passive_monitor'],
        'contract advertises the first role value family',
    );
    is_deeply(
        $report->{verification_observations},
        [
            {
                name => 'link_rx',
                role => 'passive_monitor',
                clock => 'clk',
                reset => {
                    name => 'rst_n',
                    kind => 'async',
                    polarity => 'active_low',
                },
                signals => [
                    { name => 'valid', direction => 'input',  width => 1 },
                    { name => 'ready', direction => 'output', width => 1 },
                    { name => 'data',  direction => 'input',  width => 8 },
                ],
            },
        ],
        'schedule report publishes inherited timing and observed signal metadata',
    );

    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'observe_metadata_report.fsm'};
    like($fsm, qr/\bmain_idle_0\b/, 'actor still lowers normally');
    unlike($fsm, qr/link_rx|passive_monitor|verification_observations/, 'observe metadata does not create scheduled .fsm content');
};

subtest 'CLI schedule JSON preserves observation projection' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($tempdir, 'observe_metadata_report.isf');
    write_file($path, observation_source());

    my $cli_report = run_schedule_json($path);
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    my $in_process_report = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    is_deeply(
        $cli_report->{verification_observations},
        $in_process_report->{verification_observations},
        'CLI preserves the in-process verification observation projection',
    );
};

subtest 'malformed observe declarations fail closed with targeted diagnostics' => sub {
    assert_parse_rejected(
        source_with_observe('(observe link_rx (signals valid))'),
        'missing role',
        qr/\AError: observe 'link_rx' in actor 'bad_observe' requires '\(role passive_monitor\)'/,
    );
    assert_parse_rejected(
        source_with_observe('(observe link_rx (role active_monitor) (signals valid))'),
        'unsupported role',
        qr/\AError: observe 'link_rx' in actor 'bad_observe' has unsupported role 'active_monitor'; supported role: passive_monitor/,
    );
    assert_parse_rejected(
        source_with_observe('(observe link_rx (role passive_monitor) (signals))'),
        'empty signals',
        qr/\AError: observe 'link_rx' in actor 'bad_observe' requires a non-empty '\(signals SIG\.\.\.\)' clause/,
    );
    assert_parse_rejected(
        source_with_observe('(observe link_rx (role passive_monitor) (signals valid valid))'),
        'duplicate observed signal',
        qr/\AError: observe 'link_rx' in actor 'bad_observe' has duplicate signal 'valid'/,
    );
    assert_parse_rejected(
        source_with_observe('(observe link_rx (role passive_monitor) (signals child.valid))'),
        'dotted endpoint signal',
        qr/\AError: observe 'link_rx' in actor 'bad_observe' signals entries must be scalar actor interface signal names/,
    );
    assert_parse_rejected(
        source_with_observe(<<'ISF'),
  (storage (var watched (width 1)))
  (observe link_rx (role passive_monitor) (signals watched))
ISF
        'actor storage signal',
        qr/\AError: observe 'link_rx' in actor 'bad_observe' references actor-owned storage 'watched'; observe signals must be actor interface inputs or outputs/,
    );
    assert_parse_rejected(
        source_with_observe(<<'ISF', transaction_body => <<'TX'),
  (observe link_rx (role passive_monitor) (signals sample_in))
ISF
    (ports
      (input sample_in))
    (on valid)
    (complete done)
TX
        'transaction-local port signal',
        qr/\AError: observe 'link_rx' in actor 'bad_observe' references transaction-local port 'sample_in' in transaction 'main'; observe signals must be actor interface inputs or outputs/,
    );
    assert_parse_rejected(
        source_with_observe('(observe link_rx (role passive_monitor) (signals missing))'),
        'unknown signal',
        qr/\AError: observe 'link_rx' in actor 'bad_observe' references unknown actor interface signal 'missing'/,
    );
    assert_parse_rejected(
        duplicate_observe_source(),
        'duplicate observe declaration',
        qr/\AError: duplicate observe declaration 'link_rx' in actor 'duplicate_observe'/,
    );
    assert_parse_rejected(
        multi_domain_observe_source(),
        'multi-domain observation',
        qr/\AError: actor 'multi_domain_observe' observe declarations require a single-clock actor; multi-domain observation partitioning remains deferred/,
    );
};

done_testing();

sub observation_source {
    return <<'ISF';
(actor observe_metadata_report
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input valid)
    (input data (width 8))
    (output ready)
    (output done))
  (observe link_rx
    (role passive_monitor)
    (signals valid ready data))
  (transaction main
    (on valid)
    (complete done)))
ISF
}

sub source_with_observe {
    my ($observe, %args) = @_;
    my $transaction_body = $args{transaction_body} // <<'TX';
    (on valid)
    (complete done)
TX
    chomp $transaction_body;
    return <<ISF;
(actor bad_observe
  (clock clk)
  (interface
    (input valid)
    (output done))
$observe
  (transaction main
$transaction_body))
ISF
}

sub duplicate_observe_source {
    return <<'ISF';
(actor duplicate_observe
  (clock clk)
  (interface
    (input valid)
    (output done))
  (observe link_rx (role passive_monitor) (signals valid))
  (observe link_rx (role passive_monitor) (signals valid))
  (transaction main
    (on valid)
    (complete done)))
ISF
}

sub multi_domain_observe_source {
    return <<'ISF';
(actor multi_domain_observe
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (interface
    (input valid (domain core))
    (output done (domain core)))
  (observe link_rx (role passive_monitor) (signals valid))
  (transaction main
    (domain core)
    (on valid)
    (complete done)))
ISF
}

sub assert_parse_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected by the parser");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

sub run_schedule_json {
    my ($path) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok($success, '--emit-schedule-json succeeds');
    is(join('', @{$stderr_buf || []}), '', '--emit-schedule-json keeps stderr clean');

    return decode_json(join('', @{$stdout_buf || []}));
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
