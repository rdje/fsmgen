#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'legacy single-clock actors default omitted timing clauses' => sub {
    my $actor = parse_source(<<'ISF', 'default-timing.isf');
(actor default_timing
  (interface
    (input start)
    (input ready)
    (output done))
  (transaction main
    (on start)
    (await ready)
    (complete done)))
ISF

    is($actor->{clock}, 'clk', 'omitted actor clock defaults to clk');
    is_deeply(
        $actor->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'omitted actor reset defaults to async active-low rst_n',
    );
    is($actor->{watchdog}, '65535', 'omitted actor watchdog defaults to 65535');

    my ($fsm, $report) = lower_and_report($actor, 'default_timing.fsm');
    like($fsm, qr/\(clock clk\)/, 'lowering emits default clock');
    like($fsm, qr/\(areset rst_n\)/, 'lowering emits default async reset');
    like($fsm, qr/\(main_wd 16\)/, 'default watchdog limit uses a 16-bit counter');
    is($report->{clock}, 'clk', 'report exposes default clock');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'report exposes default reset',
    );
    is($report->{watchdog}, '65535', 'report exposes default watchdog as 2^16 - 1');
};

subtest 'explicit timing clauses override defaults' => sub {
    my $actor = parse_source(<<'ISF', 'explicit-timing.isf');
(actor explicit_timing
  (clock bus_clk)
  (reset (bus_rst sync active_high))
  (watchdog 17)
  (interface
    (input start)
    (input ready)
    (output done))
  (transaction main
    (on start)
    (await ready)
    (complete done)))
ISF

    is($actor->{clock}, 'bus_clk', 'explicit clock is preserved');
    is_deeply(
        $actor->{reset},
        { name => 'bus_rst', kind => 'sync', polarity => 'active_high' },
        'explicit reset policy is preserved',
    );
    is($actor->{watchdog}, '17', 'explicit watchdog is preserved');

    my ($fsm, $report) = lower_and_report($actor, 'explicit_timing.fsm');
    like($fsm, qr/\(clock bus_clk\)/, 'lowering emits explicit clock');
    like($fsm, qr/\(sreset bus_rst\)/, 'lowering emits explicit sync reset');
    is($report->{clock}, 'bus_clk', 'report exposes explicit clock');
    is_deeply(
        $report->{reset},
        { name => 'bus_rst', kind => 'sync', polarity => 'active_high' },
        'report exposes explicit reset',
    );
    is($report->{watchdog}, '17', 'report exposes explicit watchdog');
};

subtest 'actor constants can name watchdog limits' => sub {
    my $actor = parse_source(<<'ISF', 'constant-watchdog.isf');
(actor constant_watchdog
  (clock clk)
  (constants
    (WD_LIMIT 17))
  (watchdog WD_LIMIT)
  (interface
    (input start)
    (input ready)
    (output done))
  (transaction main
    (on start)
    (await ready)
    (complete done)))
ISF

    is($actor->{watchdog}, '17', 'actor-level watchdog constant resolves in the public actor shell');

    my ($fsm, $report) = lower_and_report($actor, 'constant_watchdog.fsm');
    like($fsm, qr/\(main_wd 5\)/, 'actor-level watchdog constant drives the inferred counter width');
    like($fsm, qr/\(<= \(main_wd \(- 17 1\)\)\)/, 'actor-level watchdog constant drives the init value');
    is($report->{watchdog}, '17', 'report exposes the resolved actor-level watchdog limit');
    is($report->{actor_constants}[0]{name}, 'WD_LIMIT', 'actor constant declaration remains report-visible');
};

subtest 'actor constants can name await-local watchdog overrides' => sub {
    my $actor = parse_source(<<'ISF', 'constant-await-watchdog.isf');
(actor constant_await_watchdog
  (clock clk)
  (constants
    (WD_LIMIT 9))
  (interface
    (input start)
    (input ready)
    (output done))
  (transaction main
    (on start)
    (await ready (watchdog WD_LIMIT))
    (complete done)))
ISF

    my ($fsm, $report) = lower_and_report($actor, 'constant_await_watchdog.fsm');
    like($fsm, qr/\(main_wd 4\)/, 'await-local watchdog constant drives the inferred counter width');
    like($fsm, qr/\(<= \(main_wd \(- 9 1\)\)\)/, 'await-local watchdog constant drives the init value');
    is($report->{watchdog}, '65535', 'actor-level default watchdog remains report-visible');
};

subtest 'unsupported actor-level watchdog tokens fail closed' => sub {
    assert_parse_rejected(<<'ISF', 'zero-valued watchdog constant', qr/\AError: actor 'zero_watchdog' watchdog constant 'WD_LIMIT' must resolve to a positive integer/);
(actor zero_watchdog
  (clock clk)
  (constants
    (WD_LIMIT 0))
  (watchdog WD_LIMIT)
  (interface (input start)))
ISF

    assert_parse_rejected(<<'ISF', 'actor parameter watchdog token', qr/\AError: actor 'parameter_watchdog' watchdog token 'WD_LIMIT' is an actor parameter; watchdog limits accept positive integer literals or actor constants only/);
(actor parameter_watchdog
  (clock clk)
  (params
    (WD_LIMIT 17))
  (watchdog WD_LIMIT)
  (interface (input start)))
ISF

    assert_parse_rejected(<<'ISF', 'runtime interface watchdog token', qr/\AError: actor 'runtime_watchdog' watchdog token 'limit' is a runtime interface signal; watchdog limits accept positive integer literals or actor constants only/);
(actor runtime_watchdog
  (clock clk)
  (watchdog limit)
  (interface (input start) (input limit)))
ISF
};

subtest 'unsupported await-local watchdog tokens fail closed' => sub {
    assert_lower_rejected(<<'ISF', 'await watchdog actor parameter', qr/\ATransaction 'main': watchdog token 'WD_LIMIT' is an actor parameter; watchdog limits accept positive integer literals or actor constants only in await watchdog override/);
(actor await_parameter_watchdog
  (clock clk)
  (params
    (WD_LIMIT 9))
  (interface (input start) (input ready) (output done))
  (transaction main
    (on start)
    (await ready (watchdog WD_LIMIT))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'await watchdog runtime signal', qr/\ATransaction 'main': watchdog token 'limit' is a runtime interface signal; watchdog limits accept positive integer literals or actor constants only in await watchdog override/);
(actor await_runtime_watchdog
  (clock clk)
  (interface (input start) (input ready) (input limit) (output done))
  (transaction main
    (on start)
    (await ready (watchdog limit))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'distinct await watchdog limits', qr/\ATransaction 'main': multiple distinct await watchdog limits are not supported by the current single watchdog counter/);
(actor distinct_await_watchdog
  (clock clk)
  (constants
    (WD_LIMIT 9))
  (interface (input start) (input ready_a) (input ready_b) (output done))
  (transaction main
    (on start)
    (await ready_a)
    (await ready_b (watchdog WD_LIMIT))
    (complete done)))
ISF
};

subtest 'clock-domains own their clocks and resets while watchdog still defaults' => sub {
    my $actor = parse_source(<<'ISF', 'domain-timing.isf');
(actor domain_timing
  (clock-domains
    (domain core (clock core_clk)))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF

    is($actor->{clock}, 'core_clk', 'default domain clock is preserved');
    is($actor->{reset}, undef, 'omitted domain reset remains omitted');
    is($actor->{watchdog}, '65535', 'omitted actor watchdog still defaults with clock-domains');

    my ($fsm, $report) = lower_and_report($actor, 'domain_timing.fsm');
    like($fsm, qr/\(clock core_clk\)/, 'lowering emits the domain clock');
    unlike($fsm, qr/\([as]reset /, 'lowering does not invent a domain reset');
    is($report->{clock}, 'core_clk', 'report exposes the default-domain clock');
    is($report->{reset}, undef, 'report keeps omitted domain reset null');
    is($report->{watchdog}, '65535', 'report exposes default watchdog for clock-domains actor');
};

done_testing();

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, $label);
}

sub lower_and_report {
    my ($actor, $fsm_name) = @_;
    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{$fsm_name};
    ok(defined($fsm), "lowering emits $fsm_name");
    my $report = decode_json($scheduler->report($actor));
    return ($fsm, $report);
}

sub assert_parse_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        parse_source($source, "$label.isf");
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during parsing");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        my $actor = parse_source($source, "$label.isf");
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during lowering");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}
