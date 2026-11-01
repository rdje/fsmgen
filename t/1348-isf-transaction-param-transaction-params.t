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
use FSM::Pipeline::SourceFrontend;

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
    like($child_fsm, qr/\(\+params\s+\(BASE 8\)\s+\(WIDTH BASE\)\s+\(LIMIT isf_width_capture_1\)\s+\(LANES \(BASE WIDTH LIMIT_C isf_width_static_2\)\)\s+\(MODE isf_width_static_1\)\s+\(COPY_MODE MODE\)\s+\(isf_width_capture_1 7\)\s+\)/s,
        'generated child .fsm preserves local aliases, actor capture and immutable static defaults');
    like($child_fsm, qr/\(\+constants\s+\(LIMIT_C 7\)\s+\(isf_width_static_1 1\)\s+\(isf_width_static_2 0\)\s+\)/s,
        'generated child declares actor constant and both enum support values');

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
    my $original_hdl_path = File::Spec->catfile($dir, 'transaction_dependency_defaults.sv');
    my ($original_success, undef, undef, undef, $original_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $original_hdl_path, $isf_path],
    );
    ok(!$original_success, 'CLI refuses the original mutable transaction aggregate defaults');
    like(join('', @{$original_stderr || []}),
        qr/\QParameter binding renderer aggregate default cannot preserve mutable parameter dependency 'BASE'; packed aggregate relationships are unsupported\E/,
        'original source receives the exact transaction aggregate-profile refusal');
    ok(!-s $original_hdl_path, 'refused original source emits no partial HDL');

    # A separate authored aggregate has static leaves; scalar aliases stay local.
    my $static_source = <<'ISF';
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
      (LANES (8 8 LIMIT_C mode.IDLE))
      (MODE mode.BUSY)
      (COPY_MODE MODE))
    (complete done)))
ISF
    my $static_actor = parse_source($static_source, 'immutable-transaction-dependency-defaults.isf');
    my $static_fsm = FSM::Scheduler::ISF->new()->lower($static_actor)->{files}{'worker.fsm'};
    my $original_module = parse_scheduled_module($dir, 'original', $child_fsm);
    my $static_module = parse_scheduled_module($dir, 'immutable', $static_fsm);
    my $json = JSON::PP->new->canonical;
    is($json->encode($static_module->parameters), $json->encode($original_module->parameters),
        'independently authored immutable source preserves every selected parameter value and JSON kind');
    is_deeply([map {$_->{parameter}} @{$original_module->parameter_default_sources->{LANES}{references}}],
        [qw(BASE WIDTH)], 'original aggregate retains both ordered transaction parameter references');
    is_deeply($static_module->parameter_default_sources->{LANES}{references}, [],
        'separate immutable aggregate contains no mutable reference');

    my $static_isf_path = File::Spec->catfile($dir, 'immutable_transaction_dependency_defaults.isf');
    write_file($static_isf_path, $static_source);
    my $hdl_path = File::Spec->catfile($dir, 'immutable_transaction_dependency_defaults.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $static_isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for transaction-parameter-backed transaction defaults');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for transaction-parameter-backed transaction defaults');
    ok(-s $hdl_path, 'CLI writes HDL for transaction-parameter-backed transaction defaults');
    if ($success && -s $hdl_path) {
        open my $fh, '<', $hdl_path or die "open $hdl_path: $!";
        local $/;
        my $hdl = <$fh>;
        close $fh or die "close $hdl_path: $!";
        like($hdl, qr/parameter\s+WIDTH\s*=\s*BASE\b/,
            'positive child HDL preserves the immediate WIDTH alias');
        like($hdl, qr/parameter\s+COPY_MODE\s*=\s*MODE\b/,
            'positive child HDL preserves the immediate enum-backed scalar alias');
        like($hdl, qr/parameter\s+LIMIT\s*=\s*isf_width_capture_1\b/,
            'positive child HDL retains its allocated actor capture');
    }
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

sub parse_scheduled_module {
    my ($dir, $label, $source) = @_;
    my $path = File::Spec->catfile($dir, "$label.fsm");
    write_file($path, $source);
    my $raw = FSM::Pipeline::SourceFrontend->parse_fsm_file(fsm_file => $path, debug_level => 0);
    return FSM::Pipeline::SourceFrontend->create_fsm_module(raw_ast => $raw, debug_level => 0);
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
