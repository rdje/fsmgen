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

subtest 'earlier scalar transaction parameters are valid child transaction defaults' => sub {
    my $source = <<'ISF';
(actor transaction_dependency_defaults
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (constants
    (LIMIT_C 7))
  (params
    (ACTOR_W LIMIT_C))
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
      (BASE 8)
      (WIDTH BASE)
      (LIMIT ACTOR_W)
      (LANES (BASE WIDTH LIMIT_C mode.IDLE))
      (MODE mode.BUSY)
      (COPY_MODE MODE))
    (complete done)))
ISF

    my $actor = parse_source($source, 'transaction-dependency-defaults.isf');
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply(
        $ir->{children}{worker}{params},
        [
            { name => 'BASE',      value => '8' },
            { name => 'WIDTH',     value => 'BASE', resolved_value => '8' },
            { name => 'LIMIT',     value => '7', resolved_value => '7' },
            { name => 'LANES',     value => [qw(BASE WIDTH 7 mode.IDLE)], resolved_value => [qw(8 8 7 0)] },
            { name => 'MODE',      value => 'mode.BUSY', resolved_value => '1' },
            { name => 'COPY_MODE', value => 'MODE', resolved_value => '1' },
        ],
        'generated child IR preserves child-local transaction dependencies and literalizes actor statics',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    like($child_fsm, qr/\(\+params\s+\(BASE 8\)\s+\(WIDTH BASE\)\s+\(LIMIT 7\)\s+\(LANES \(BASE WIDTH 7 mode\.IDLE\)\)\s+\(MODE mode\.BUSY\)\s+\(COPY_MODE MODE\)\s+\)/s,
        'generated child .fsm preserves child-local transaction dependency tokens');

    my $report = decode_json($scheduler->report($actor));
    is_deeply(
        $report->{generated_composition}{children}[0]{parameters},
        [
            { name => 'BASE',      default => '8' },
            { name => 'WIDTH',     default => 'BASE' },
            { name => 'LIMIT',     default => '7' },
            { name => 'LANES',     default => '(BASE WIDTH 7 mode.IDLE)' },
            { name => 'MODE',      default => 'mode.BUSY' },
            { name => 'COPY_MODE', default => 'MODE' },
        ],
        'schedule report child parameter summary preserves child-local dependency tokens',
    );
    is_deeply(
        $report->{generated_composition}{instances}[0]{parameter_bindings},
        [
            { name => 'BASE',      source => 'default', value => '8' },
            { name => 'WIDTH',     source => 'default', value => 'BASE' },
            { name => 'LIMIT',     source => 'default', value => '7' },
            { name => 'LANES',     source => 'default', value => '(BASE WIDTH 7 mode.IDLE)' },
            { name => 'MODE',      source => 'default', value => 'mode.BUSY' },
            { name => 'COPY_MODE', source => 'default', value => 'MODE' },
        ],
        'schedule report generated instance bindings preserve child-local dependency tokens',
    );

    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'transaction_dependency_defaults.isf');
    write_file($isf_path, $source);
    my $hdl_path = File::Spec->catfile($dir, 'transaction_dependency_defaults.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for transaction-parameter-backed transaction defaults');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for transaction-parameter-backed transaction defaults');
    ok(-s $hdl_path, 'CLI writes HDL for transaction-parameter-backed transaction defaults');
};

subtest 'transaction parameter dependency defaults fail closed outside earlier scalar parameters' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor forward_transaction_param_default
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0))
  (transaction worker
    (params
      (WIDTH BASE)
      (BASE 8))
    (complete done)))
ISF
        qr/Transaction 'worker': parameter 'WIDTH' transaction parameter 'BASE' must reference an earlier scalar transaction parameter default/,
        'forward transaction parameter dependencies are rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor self_transaction_param_default
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0))
  (transaction worker
    (params
      (WIDTH WIDTH))
    (complete done)))
ISF
        qr/Transaction 'worker': parameter 'WIDTH' transaction parameter 'WIDTH' must reference an earlier scalar transaction parameter default/,
        'self transaction parameter dependencies are rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor nonscalar_transaction_param_default
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0))
  (transaction worker
    (params
      (LANES (1 0))
      (WIDTH LANES))
    (complete done)))
ISF
        qr/Transaction 'worker': parameter 'WIDTH' transaction parameter 'LANES' must reference an earlier scalar transaction parameter default/,
        'non-scalar transaction parameter dependencies are rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor runtime_signal_transaction_dependency_default
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
        'runtime interface signals remain rejected as transaction defaults',
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
