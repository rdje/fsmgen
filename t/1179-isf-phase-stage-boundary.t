#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, 'phase-stage-boundary.isf');
}

sub lower_actor {
    my ($actor) = @_;
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_parse_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        parse_source($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected by the parser");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'actor-level phase and stage metadata is validated then carried' => sub {
    my $source = <<'ISF';
(actor actor_phase_stage
  (clock clk)
  (interface
    (input start)
    (output done))
  (phase setup (outputs done) (next finish))
  (stage pass_through (input start) (output done) (latency (max 3)))
  (transaction main
    (on start)
    (complete done)))
ISF

    my $actor = parse_source($source);
    is_deeply(
        $actor->{phases},
        [
            {
                name => 'setup',
                body => [
                    ['outputs', 'done'],
                    ['next',    'finish'],
                ],
            },
        ],
        'actor-level phase metadata keeps the advertised name/body shell',
    );
    is_deeply(
        $actor->{stages},
        [
            {
                name => 'pass_through',
                body => [
                    ['input',   'start'],
                    ['output',  'done'],
                    ['latency', ['max', '3']],
                ],
            },
        ],
        'actor-level stage metadata keeps the advertised name/body shell',
    );

    my $lowered = lower_actor($actor);
    like($lowered->{files}{'actor_phase_stage.fsm'}, qr/\bmain_idle_0\b/, 'validated metadata actor still lowers');
};

subtest 'transaction phase remains a pass-through sequential state' => sub {
    my $actor = parse_source(<<'ISF');
(actor transaction_phase
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (phase first_phase (outputs done) (next finish))
    (complete done)))
ISF

    my $lowered = lower_actor($actor);
    like(
        $lowered->{files}{'transaction_phase.fsm'},
        qr/\(main_phase_1\n\s+\(-> main_done_2\)/,
        'transaction phase lowers as the documented pass-through state',
    );
};

subtest 'unsupported transaction stage body fails closed during lowering' => sub {
    my $actor = parse_source(<<'ISF');
(actor transaction_stage
  (clock clk)
  (interface
    (input start)
    (input ready)
    (output valid)
    (output done))
  (transaction main
    (on start)
    (stage pass_through (input ready) (output valid) (latency (max 3)))
    (complete done)))
ISF

    my $ok = eval {
        lower_actor($actor);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, 'unsupported transaction stage body is rejected by lowering');
    ok(!ref($diagnostic), 'transaction stage diagnostic is scalar');
    like(
        $diagnostic,
        qr/\ATransaction 'main': stage 'pass_through' has unsupported subclause 'latency'/,
        'transaction stage diagnostic is bounded',
    );
};

subtest 'malformed phase and stage shapes fail before actor-shell return' => sub {
    assert_parse_rejected(<<'ISF', 'nested actor phase name', qr/\AError: \(phase \.\.\.\) requires a scalar name/);
(actor bad_actor_phase
  (clock clk)
  (interface (input start) (output done))
  (phase (setup) (outputs done))
  (transaction main (on start) (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'scalar actor stage body', qr/\AError: stage 'pipe' body entries must be list forms/);
(actor bad_actor_stage
  (clock clk)
  (interface (input start) (output done))
  (stage pipe ready)
  (transaction main (on start) (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'duplicate actor phase name', qr/\AError: duplicate actor phase 'setup'/);
(actor duplicate_actor_phase
  (clock clk)
  (interface (input start) (output done))
  (phase setup (outputs done))
  (phase setup (next finish))
  (transaction main (on start) (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'nested transaction phase name', qr/\AError: \(phase \.\.\.\) requires a scalar name/);
(actor bad_transaction_phase
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (phase (first_phase) (outputs done))
    (complete done)))
ISF
};

done_testing();
