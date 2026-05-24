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

subtest 'actor constants are valid actor parameter defaults' => sub {
    my $source = <<'ISF';
(actor actor_constant_param_defaults
  (clock clk)
  (reset rst)
  (constants
    (DEFAULT_WIDTH 4'd8)
    (LANE0 1)
    (LANE1 0))
  (params
    (DATA_W DEFAULT_WIDTH)
    (LANES (LANE0 LANE1)))
  (interface
    (input start)
    (input data_in (width DATA_W))
    (output data_out (width DATA_W)))
  (transaction main
    (on start)
    (set data_out data_in)))
ISF

    my $actor = parse_source($source, 'actor-constant-param-defaults.isf');
    is($actor->{params}[0]{value}, 'DEFAULT_WIDTH',
        'actor parameter preserves authored actor constant scalar default');
    is($actor->{params}[0]{resolved_value}, "4'd8",
        'actor parameter records resolved actor constant scalar default');
    is_deeply($actor->{params}[1]{value}, [qw(LANE0 LANE1)],
        'actor parameter preserves authored actor constant aggregate leaves');
    is_deeply($actor->{params}[1]{resolved_value}, [qw(1 0)],
        'actor parameter records resolved actor constant aggregate leaves');
    is(port_width($actor->{interface}{inputs}, 'data_in'), 8,
        'input width resolves through actor-constant-backed actor parameter');
    is(port_width($actor->{interface}{outputs}, 'data_out'), 8,
        'output width resolves through actor-constant-backed actor parameter');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply($ir->{params}[0],
        { name => 'DATA_W', value => 'DEFAULT_WIDTH', resolved_value => "4'd8" },
        'lowering IR preserves authored scalar default and resolved value');
    is_deeply($ir->{params}[1],
        { name => 'LANES', value => [qw(LANE0 LANE1)], resolved_value => [qw(1 0)] },
        'lowering IR preserves authored aggregate leaves and resolved values');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $fsm = $scheduler->lower($actor)->{files}{'actor_constant_param_defaults.fsm'};
    like($fsm, qr/\(\+constants\s+\(DEFAULT_WIDTH 4'd8\)\s+\(LANE0 1\)\s+\(LANE1 0\)\s+\)/s,
        'scheduled .fsm preserves authored actor constants');
    like($fsm, qr/\(\+params\s+\(DATA_W DEFAULT_WIDTH\)\s+\(LANES \(LANE0 LANE1\)\)\s+\)/s,
        'scheduled .fsm preserves authored actor-constant parameter defaults');
    like($fsm, qr/\(\+size[\s\S]*\(data_in 8\)[\s\S]*\(data_out 8\)/,
        'scheduled .fsm uses resolved parameter widths');
    is_deeply(
        decode_json($scheduler->report($actor))->{actor_params},
        [
            { name => 'DATA_W', value => 'DEFAULT_WIDTH' },
            { name => 'LANES', value => [qw(LANE0 LANE1)] },
        ],
        'schedule report preserves authored actor-constant parameter defaults',
    );

    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'actor_constant_param_defaults.isf');
    write_file($isf_path, $source);
    my $hdl_path = File::Spec->catfile($dir, 'actor_constant_param_defaults.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for actor-constant actor parameter defaults');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for actor-constant actor parameter defaults');
    ok(-s $hdl_path, 'CLI writes HDL for actor-constant actor parameter defaults');
};

subtest 'actor constant actor parameter diagnostics fail closed' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor unknown_constant_param_default
  (clock clk)
  (params
    (DATA_W DEFAULT_WIDTH))
  (interface
    (output data_out)))
ISF
        qr/\AError: actor 'unknown_constant_param_default' parameter 'DATA_W' token 'DEFAULT_WIDTH' is not a declared actor constant or enum member/,
        'unknown actor parameter default token is rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor dependent_param_default
  (clock clk)
  (params
    (BASE_W 8)
    (DATA_W BASE_W))
  (interface
    (output data_out)))
ISF
        qr/\AError: actor 'dependent_param_default' parameter 'DATA_W' actor parameter 'BASE_W' cannot be used as an actor parameter default/,
        'actor-parameter-to-actor-parameter defaults remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor runtime_param_default
  (clock clk)
  (params
    (DATA_W DEFAULT_WIDTH))
  (interface
    (input DEFAULT_WIDTH)
    (output data_out)))
ISF
        qr/\AError: actor 'runtime_param_default' parameter 'DATA_W' token 'DEFAULT_WIDTH' is a runtime interface signal/,
        'runtime interface signals are rejected as actor parameter defaults',
    );

    assert_parse_rejected(
        <<'ISF',
(actor transaction_param_default
  (clock clk)
  (params
    (DATA_W CHILD_W))
  (interface
    (input start)
    (output done))
  (transaction child
    (params
      (CHILD_W 8))
    (on start)
    (complete done)))
ISF
        qr/\AError: actor 'transaction_param_default' parameter 'DATA_W' transaction parameter 'CHILD_W' from transaction 'child' cannot be used as an actor parameter default/,
        'transaction parameters are rejected as actor parameter defaults',
    );
};

done_testing();

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, $label);
}

sub assert_parse_rejected {
    my ($source, $diagnostic_re, $label) = @_;
    my $ok = eval {
        parse_source($source, "$label.isf");
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label fails closed");
    like($diagnostic, $diagnostic_re, "$label diagnostic");
}

sub port_width {
    my ($ports, $name) = @_;
    for my $port (@{$ports || []}) {
        return $port->{width} if ($port->{name} // '') eq $name;
    }
    return undef;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
