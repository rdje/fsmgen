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
    like($child_fsm, qr/\(\+params\s+\(WIDTH isf_width_capture_1\)\s+\(LIMIT LIMIT_C\)\s+\(LANES \(LANE0 isf_width_capture_2 LIMIT_C\)\)\s+\(MODE isf_width_static_1\)\s+\(isf_width_capture_1 7\)\s+\(isf_width_capture_2 0\)\s+\)/s,
        'generated child .fsm retains allocated actor captures and scoped static defaults');
    like($child_fsm, qr/\(\+constants\s+\(LIMIT_C 7\)\s+\(LANE0 1\)\s+\(isf_width_static_1 1\)\s+\)/s,
        'actor constants and immutable enum support remain declared');

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
    my $original_hdl_path = File::Spec->catfile($dir, 'transaction_static_defaults.sv');
    my ($original_success, undef, undef, undef, $original_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $original_hdl_path, $isf_path],
    );
    ok(!$original_success, 'CLI refuses the original aggregate containing a mutable actor capture');
    like(join('', @{$original_stderr || []}),
        qr/\QParameter binding renderer aggregate default cannot preserve mutable parameter dependency 'isf_width_capture_2'; packed aggregate relationships are unsupported\E/,
        'original source receives the exact captured aggregate-profile refusal');
    ok(!-s $original_hdl_path, 'refused original source emits no partial HDL');

    # Independently authored immutable aggregate; scalar capture and enum stay.
    my $static_source = <<'ISF';
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
      (LANES (LANE0 0 LIMIT_C))
      (MODE mode.BUSY))
    (complete done)))
ISF
    my $static_actor = parse_source($static_source, 'immutable-transaction-static-defaults.isf');
    my $static_fsm = FSM::Scheduler::ISF->new()->lower($static_actor)->{files}{'worker.fsm'};
    my $original_module = parse_scheduled_module($dir, 'original', $child_fsm);
    my $static_module = parse_scheduled_module($dir, 'immutable', $static_fsm);
    my $original_params = $original_module->parameters;
    my $static_params = $static_module->parameters;
    is_deeply([sort keys %$original_params],
        [sort qw(WIDTH LIMIT LANES MODE isf_width_capture_1 isf_width_capture_2)],
        'original child retains all authored declarations and both actor captures');
    is_deeply([sort keys %$static_params],
        [sort qw(WIDTH LIMIT LANES MODE isf_width_capture_1)],
        'immutable child needs only the unchanged scalar capture');
    my $json = JSON::PP->new->canonical;
    is($json->encode({map {$_ => $static_params->{$_}} keys %$static_params}),
        $json->encode({map {$_ => $original_params->{$_}} keys %$static_params}),
        'all authored defaults and the retained capture preserve complete selected values and JSON kinds');
    is($original_params->{isf_width_capture_2}{value_text}, '0',
        'original aggregate-only capture retains the actor LANE1 default');
    is_deeply([map {$_->{parameter}} @{$original_module->parameter_default_sources->{LANES}{references}}],
        ['isf_width_capture_2'], 'original aggregate keeps its mutable capture provenance');
    is_deeply($static_module->parameter_default_sources->{LANES}{references}, [],
        'separate immutable aggregate contains no mutable reference');

    my $static_isf_path = File::Spec->catfile($dir, 'immutable_transaction_static_defaults.isf');
    write_file($static_isf_path, $static_source);
    my $hdl_path = File::Spec->catfile($dir, 'immutable_transaction_static_defaults.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $static_isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for actor-static transaction parameter defaults');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for actor-static transaction parameter defaults');
    ok(-s $hdl_path, 'CLI writes HDL for actor-static transaction parameter defaults');
    if ($success && -s $hdl_path) {
        open my $fh, '<', $hdl_path or die "open $hdl_path: $!";
        local $/;
        my $hdl = <$fh>;
        close $fh or die "close $hdl_path: $!";
        like($hdl, qr/parameter\s+WIDTH\s*=\s*isf_width_capture_1\b/,
            'supported child HDL retains its scalar actor capture');
        like($hdl, qr/parameter\s+LIMIT\s*=\s*7\b/,
            'supported child HDL resolves its immutable actor constant');
        like($hdl, qr/parameter\s+MODE\s*=\s*1\b/,
            'supported child HDL resolves its immutable enum support');
    }
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
