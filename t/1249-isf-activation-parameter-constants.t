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
use FSM::Scheduler::ISF::LoweringIR;

subtest 'actor constants specialize spawn and generated do parameter overrides' => sub {
    my $source = <<'ISF';
(actor activation_parameter_constants
  (clock clk)
  (constants
    (TOP_WIDTH 16)
    (LANE_A 8'hA5)
    (LANE_B 8'h3C))
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WIDTH TOP_WIDTH)
        (LANES (LANE_A LANE_B))))
    (do worker
      (params
        (WIDTH TOP_WIDTH)
        (LANES (LANE_A LANE_B))))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8)
      (LANES (8'h00 8'h00)))
    (complete done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);

    is_deeply(
        [ map { $_->{parameter_overrides} } @{$ir->{spawn_instances}} ],
        [
            [
                { name => 'WIDTH', value => '16' },
                { name => 'LANES', value => ["8'hA5", "8'h3C"] },
            ],
            [
                { name => 'WIDTH', value => '16' },
                { name => 'LANES', value => ["8'hA5", "8'h3C"] },
            ],
        ],
        'spawn and generated do overrides resolve actor constants before IR publication',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $top_fsm = $lowered->{files}{'activation_parameter_constants_top.fsm'};
    ok(defined($top_fsm), 'generated top is emitted');
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 16\)\s+\(LANES \(8'hA5 8'h3C\)\)\s+\)\s+\)/s,
        'spawn generated top applies resolved actor-constant overrides');
    like($top_fsm, qr/\(\?fsmc:parent_worker_do_0 worker\s+\(params\s+\(WIDTH 16\)\s+\(LANES \(8'hA5 8'h3C\)\)\s+\)\s+\)/s,
        'generated do top applies resolved actor-constant overrides');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [ map { $_->{parameter_bindings} } @{$report->{generated_composition}{instances}} ],
        [
            [
                { name => 'WIDTH', source => 'override', value => '16' },
                { name => 'LANES', source => 'override', value => "(8'hA5 8'h3C)" },
            ],
            [
                { name => 'WIDTH', source => 'override', value => '16' },
                { name => 'LANES', source => 'override', value => "(8'hA5 8'h3C)" },
            ],
        ],
        'schedule report exposes resolved literal override values',
    );
};

subtest 'actor constants specialize rule-trigger parameter overrides' => sub {
    my $source = <<'ISF';
(actor trigger_parameter_constants
  (clock clk)
  (constants
    (TOP_WIDTH 16))
  (interface
    (input fire)
    (output done))
  (transaction parent
    (on fire)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (WIDTH TOP_WIDTH)))))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply(
        $ir->{spawn_instances}[0]{parameter_overrides},
        [ { name => 'WIDTH', value => '16' } ],
        'rule-trigger override resolves actor constant before generated instance metadata',
    );

    my $top_fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'trigger_parameter_constants_top.fsm'};
    like($top_fsm, qr/\(\?fsmc:launch_worker_trigger_0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'rule-trigger generated top applies resolved actor-constant override');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        $report->{generated_composition}{instances}[0]{parameter_bindings},
        [ { name => 'WIDTH', source => 'override', value => '16' } ],
        'rule-trigger report exposes resolved literal override value',
    );
};

subtest 'runtime or unknown symbols remain fail closed as parameter values' => sub {
    assert_lower_rejected(<<'ISF', 'input signal is not a parameter value source', qr/unsupported parameter value 'runtime_width'/);
(actor runtime_signal_parameter_value
  (clock clk)
  (interface
    (input start)
    (input runtime_width (width 8))
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WIDTH runtime_width)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'actor parameter is not a parameter value source', qr/unsupported parameter value 'TOP_WIDTH'/);
(actor actor_parameter_value
  (clock clk)
  (params
    (TOP_WIDTH 16))
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WIDTH TOP_WIDTH)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF
};

done_testing();

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, 'activation-parameter-constants.isf');
}

sub lower_source {
    my ($source) = @_;
    return FSM::Scheduler::ISF->new()->lower(parse_source($source));
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        lower_source($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}
