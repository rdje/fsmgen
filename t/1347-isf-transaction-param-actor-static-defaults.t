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
use FSM::Scheduler::ISF::LoweringIR;

subtest 'actor static values are valid generated child transaction defaults' => sub {
    my $source = <<'ISF';
(actor transaction_static_defaults
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (constants
    (LIMIT_C 7)
    (LANE0 1))
  (params
    (BASE_W LIMIT_C)
    (LANE1 0))
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH BASE_W)
      (LIMIT LIMIT_C)
      (LANES (LANE0 LANE1 LIMIT_C))
      (MODE mode.BUSY))
    (complete done)))
ISF

    my $actor = parse_source($source, 'transaction-static-defaults.isf');
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply(
        $ir->{children}{worker}{params},
        [
            { name => 'WIDTH', value => '7', resolved_value => '7' },
            { name => 'LIMIT', value => '7', resolved_value => '7' },
            { name => 'LANES', value => [qw(1 0 7)], resolved_value => [qw(1 0 7)] },
            { name => 'MODE',  value => 'mode.BUSY', resolved_value => '1' },
        ],
        'generated child IR literalizes actor constants and actor scalar parameters while preserving enum tokens',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    like($child_fsm, qr/\(\+params\s+\(WIDTH 7\)\s+\(LIMIT 7\)\s+\(LANES \(1 0 7\)\)\s+\(MODE mode\.BUSY\)\s+\)/s,
        'generated child .fsm publishes literal actor-static transaction defaults and authored enum token');

    my $report = decode_json($scheduler->report($actor));
    is_deeply(
        $report->{generated_composition}{children}[0]{parameters},
        [
            { name => 'WIDTH', default => '7' },
            { name => 'LIMIT', default => '7' },
            { name => 'LANES', default => '(1 0 7)' },
            { name => 'MODE',  default => 'mode.BUSY' },
        ],
        'schedule report child parameter summary publishes the self-contained defaults',
    );
    is_deeply(
        $report->{generated_composition}{instances}[0]{parameter_bindings},
        [
            { name => 'WIDTH', source => 'default', value => '7' },
            { name => 'LIMIT', source => 'default', value => '7' },
            { name => 'LANES', source => 'default', value => '(1 0 7)' },
            { name => 'MODE',  source => 'default', value => 'mode.BUSY' },
        ],
        'schedule report generated instance bindings use the self-contained default values',
    );

    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'transaction_static_defaults.isf');
    write_file($isf_path, $source);
    my $hdl_path = File::Spec->catfile($dir, 'transaction_static_defaults.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for actor-static transaction parameter defaults');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for actor-static transaction parameter defaults');
    ok(-s $hdl_path, 'CLI writes HDL for actor-static transaction parameter defaults');
};

subtest 'transaction parameter actor-static defaults fail closed outside scalar statics' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor transaction_param_dependency
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0))
  (transaction worker
    (params
      (WIDTH BASE_W)
      (BASE_W 8))
    (complete done)))
ISF
        qr/Transaction 'worker': parameter 'WIDTH' transaction parameter 'BASE_W' must reference an earlier scalar transaction parameter default/,
        'forward transaction parameter defaults cannot depend on sibling transaction parameters',
    );

    assert_lower_rejected(
        <<'ISF',
(actor nonscalar_actor_param_transaction_default
  (clock clk)
  (params
    (LANES (1 0)))
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0))
  (transaction worker
    (params
      (WIDTH LANES))
    (complete done)))
ISF
        qr/Transaction 'worker': parameter 'WIDTH' actor parameter 'LANES' must resolve to a scalar numeric or exact-width literal value/,
        'non-scalar actor parameters cannot feed scalar transaction parameter defaults',
    );

    assert_lower_rejected(
        <<'ISF',
(actor runtime_signal_transaction_default
  (clock clk)
  (interface
    (input start)
    (input runtime_width)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0))
  (transaction worker
    (params
      (WIDTH runtime_width))
    (complete done)))
ISF
        qr/Transaction 'worker': parameter 'WIDTH' token 'runtime_width' is a runtime interface signal/,
        'runtime interface signals cannot feed generated child transaction defaults',
    );

    assert_lower_rejected(
        <<'ISF',
(actor unknown_transaction_default
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0))
  (transaction worker
    (params
      (WIDTH DEFAULT_WIDTH))
    (complete done)))
ISF
        qr/Transaction 'worker': parameter 'WIDTH' token 'DEFAULT_WIDTH' is not an earlier scalar transaction parameter, declared actor constant, actor scalar parameter, enum member, or qualified package scalar constant/,
        'unknown transaction parameter default tokens fail closed',
    );
};

done_testing();

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, $label);
}

sub assert_lower_rejected {
    my ($source, $diagnostic_re, $label) = @_;
    my $ok = eval {
        my $actor = parse_source($source, "$label.isf");
        FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label fails closed");
    like($diagnostic, $diagnostic_re, "$label diagnostic");
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
