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

subtest 'earlier scalar actor parameters are valid actor parameter defaults' => sub {
    my $source = <<'ISF';
(actor actor_param_param_defaults
  (clock clk)
  (reset rst)
  (params
    (BASE_W 8)
    (DATA_W BASE_W)
    (LANE0 1)
    (LANES (DATA_W LANE0 BASE_W)))
  (interface
    (input start)
    (input data_in (width DATA_W))
    (output data_out (width DATA_W)))
  (transaction main
    (on start)
    (set data_out data_in)))
ISF

    my $actor = parse_source($source, 'actor-param-param-defaults.isf');
    is($actor->{params}[1]{value}, 'BASE_W',
        'actor parameter preserves authored earlier actor-parameter scalar default');
    is($actor->{params}[1]{resolved_value}, '8',
        'actor parameter records resolved earlier actor-parameter scalar default');
    is_deeply($actor->{params}[3]{value}, [qw(DATA_W LANE0 BASE_W)],
        'actor parameter preserves authored earlier actor-parameter aggregate leaves');
    is_deeply($actor->{params}[3]{resolved_value}, [qw(8 1 8)],
        'actor parameter records resolved earlier actor-parameter aggregate leaves');
    is(port_width($actor->{interface}{inputs}, 'data_in'), 8,
        'input width resolves through actor-parameter-backed actor parameter');
    is(port_width($actor->{interface}{outputs}, 'data_out'), 8,
        'output width resolves through actor-parameter-backed actor parameter');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply($ir->{params}[1],
        { name => 'DATA_W', value => 'BASE_W', resolved_value => '8' },
        'lowering IR preserves authored scalar actor-parameter default and resolved value');
    is_deeply($ir->{params}[3],
        { name => 'LANES', value => [qw(DATA_W LANE0 BASE_W)], resolved_value => [qw(8 1 8)] },
        'lowering IR preserves authored aggregate actor-parameter leaves and resolved values');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $fsm = $scheduler->lower($actor)->{files}{'actor_param_param_defaults.fsm'};
    like($fsm, qr/\(\+params\s+\(BASE_W 8\)\s+\(DATA_W BASE_W\)\s+\(LANE0 1\)\s+\(LANES \(DATA_W LANE0 BASE_W\)\)\s+\)/s,
        'scheduled .fsm preserves authored actor-parameter-backed defaults');
    like($fsm, qr/\(\+size[\s\S]*\(data_in 8\)[\s\S]*\(data_out 8\)/,
        'scheduled .fsm uses resolved parameter widths');
    is_deeply(
        decode_json($scheduler->report($actor))->{actor_params},
        [
            { name => 'BASE_W', value => '8' },
            { name => 'DATA_W', value => 'BASE_W' },
            { name => 'LANE0',  value => '1' },
            { name => 'LANES',  value => [qw(DATA_W LANE0 BASE_W)] },
        ],
        'schedule report preserves authored actor-parameter-backed defaults',
    );

    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'actor_param_param_defaults.isf');
    write_file($isf_path, $source);
    my $hdl_path = File::Spec->catfile($dir, 'actor_param_param_defaults.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for actor-parameter actor parameter defaults');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for actor-parameter actor parameter defaults');
    ok(-s $hdl_path, 'CLI writes HDL for actor-parameter actor parameter defaults');
};

subtest 'actor parameter dependency defaults fail closed outside earlier scalar parameters' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor forward_param_default
  (clock clk)
  (params
    (DATA_W BASE_W)
    (BASE_W 8))
  (interface
    (output data_out)))
ISF
        qr/\AError: actor 'forward_param_default' parameter 'DATA_W' actor parameter 'BASE_W' must reference an earlier scalar actor parameter default/,
        'forward actor-parameter defaults are rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor self_param_default
  (clock clk)
  (params
    (DATA_W DATA_W))
  (interface
    (output data_out)))
ISF
        qr/\AError: actor 'self_param_default' parameter 'DATA_W' actor parameter 'DATA_W' must reference an earlier scalar actor parameter default/,
        'self actor-parameter defaults are rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor nonscalar_param_default
  (clock clk)
  (params
    (LANES (1 0))
    (DATA_W LANES))
  (interface
    (output data_out)))
ISF
        qr/\AError: actor 'nonscalar_param_default' parameter 'DATA_W' actor parameter 'LANES' must reference an earlier scalar actor parameter default/,
        'non-scalar actor-parameter defaults are rejected as scalar sources',
    );

    assert_parse_rejected(
        <<'ISF',
(actor unknown_param_default
  (clock clk)
  (params
    (DATA_W DEFAULT_WIDTH))
  (interface
    (output data_out)))
ISF
        qr/\AError: actor 'unknown_param_default' parameter 'DATA_W' token 'DEFAULT_WIDTH' is not a declared actor constant, earlier scalar actor parameter, enum member, or qualified package scalar constant/,
        'unknown actor parameter default token is rejected',
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
