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

subtest 'package scalar constants are valid actor parameter defaults' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (DEFAULT_WIDTH 4'd8)
    (LANE0 1)
    (LANE1 0))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'package_constant_actor_param.isf');
    write_file($isf_path, <<'ISF');
(actor package_constant_actor_param
  (imports
    (package shared))
  (params
    (DATA_W shared.DEFAULT_WIDTH)
    (LANES (shared.LANE0 shared.LANE1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input data_in (width DATA_W))
    (output data_out (width DATA_W)))
  (transaction main
    (on start)
    (set data_out data_in)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{constant_symbols}{packages}{shared}{DEFAULT_WIDTH}{payload}, "4'd8",
        'actor shell records imported package scalar constant payload');
    is($actor->{params}[0]{value}, 'shared.DEFAULT_WIDTH',
        'actor parameter preserves authored package scalar constant token');
    is($actor->{params}[0]{resolved_value}, "4'd8",
        'actor parameter records resolved package scalar constant default');
    is_deeply($actor->{params}[1]{value}, [qw(shared.LANE0 shared.LANE1)],
        'actor parameter preserves authored package scalar constant aggregate leaves');
    is_deeply($actor->{params}[1]{resolved_value}, [qw(1 0)],
        'actor parameter records resolved package scalar constant aggregate leaves');
    is(port_width($actor->{interface}{inputs}, 'data_in'), 8,
        'input width resolves through package-constant-backed actor parameter');
    is(port_width($actor->{interface}{outputs}, 'data_out'), 8,
        'output width resolves through package-constant-backed actor parameter');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply(
        $ir->{params}[0],
        { name => 'DATA_W', value => 'shared.DEFAULT_WIDTH', resolved_value => "4'd8" },
        'lowering IR preserves authored package constant scalar default and resolved value',
    );
    is_deeply(
        $ir->{params}[1],
        { name => 'LANES', value => [qw(shared.LANE0 shared.LANE1)], resolved_value => [qw(1 0)] },
        'lowering IR preserves authored package constant aggregate leaves and resolved values',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $fsm = $scheduler->lower($actor)->{files}{'package_constant_actor_param.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\+params\s+\(DATA_W shared\.DEFAULT_WIDTH\)\s+\(LANES \(shared\.LANE0 shared\.LANE1\)\)\s+\)/s,
        'scheduled .fsm preserves authored package-constant parameter defaults');
    like($fsm, qr/\(\+size[\s\S]*\(data_in 8\)[\s\S]*\(data_out 8\)/,
        'scheduled .fsm uses resolved package-constant-backed parameter widths');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+constants[\s\S]*\(DEFAULT_WIDTH 4'd8\)[\s\S]*\(LANE0 1\)[\s\S]*\(LANE1 0\)/,
        'scheduled .fsm embeds imported package constant root');
    is_deeply(
        decode_json($scheduler->report($actor))->{actor_params},
        [
            { name => 'DATA_W', value => 'shared.DEFAULT_WIDTH' },
            { name => 'LANES', value => [qw(shared.LANE0 shared.LANE1)] },
        ],
        'schedule report preserves authored package-constant actor parameter defaults',
    );

    my $hdl_path = File::Spec->catfile($dir, 'package_constant_actor_param.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package-constant actor parameter defaults');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package-constant actor parameter defaults');
    ok(-s $hdl_path, 'CLI writes HDL for package-constant actor parameter defaults');
};

subtest 'package constant actor parameter diagnostics fail closed' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (LANES (1 0))
    (DEFAULT_WIDTH 8))
)
FSM

    assert_parse_file_rejected(
        $dir,
        'unknown_package_constant.isf',
        <<'ISF',
(actor unknown_package_constant
  (imports
    (package shared))
  (params
    (DATA_W shared.MISSING))
  (interface
    (output data_out)))
ISF
        qr/actor 'unknown_package_constant' parameter 'DATA_W' references unknown package constant 'shared\.MISSING'/,
        'unknown package constant defaults are rejected',
    );

    assert_parse_file_rejected(
        $dir,
        'unqualified_package_constant.isf',
        <<'ISF',
(actor unqualified_package_constant
  (imports
    (package shared))
  (params
    (DATA_W DEFAULT_WIDTH))
  (interface
    (output data_out)))
ISF
        qr/actor 'unqualified_package_constant' parameter 'DATA_W' token 'DEFAULT_WIDTH' is not a declared actor constant, earlier scalar actor parameter, enum member, or qualified package scalar constant/,
        'unqualified package constants are rejected',
    );

    assert_parse_file_rejected(
        $dir,
        'aggregate_package_constant.isf',
        <<'ISF',
(actor aggregate_package_constant
  (imports
    (package shared))
  (params
    (LANE_SET shared.LANES))
  (interface
    (output data_out)))
ISF
        qr/actor 'aggregate_package_constant' parameter 'LANE_SET' package constant 'shared\.LANES' must resolve to a scalar numeric or exact-width literal value/,
        'aggregate package constants remain deferred as actor parameter defaults',
    );

    assert_parse_file_rejected(
        $dir,
        'package_constant_leaf_path.isf',
        <<'ISF',
(actor package_constant_leaf_path
  (imports
    (package shared))
  (params
    (LANE shared.LANES[0]))
  (interface
    (output data_out)))
ISF
        qr/actor 'package_constant_leaf_path' parameter 'LANE' package constant 'shared\.LANES' aggregate\/member path 'shared\.LANES\[0\]' remains deferred/,
        'package aggregate constant scalar-leaf paths remain deferred',
    );

    my $mode_dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($mode_dir, 'mode.fsm'), <<'FSM');
(?pkg:mode
  (+constants
    (BUSY 1))
)
FSM
    assert_parse_file_rejected(
        $mode_dir,
        'ambiguous_package_constant.isf',
        <<'ISF',
(actor ambiguous_package_constant
  (imports
    (package mode))
  (enums
    (mode (BUSY 1)))
  (params
    (DEFAULT mode.BUSY))
  (interface
    (output data_out)))
ISF
        qr/actor 'ambiguous_package_constant' parameter 'DEFAULT' token 'mode\.BUSY' is ambiguous: it matches local enum member 'mode\.BUSY' and imported package constant 'mode\.BUSY'/,
        'ambiguous local-enum and package-constant tokens are rejected',
    );
};

done_testing();

sub assert_parse_file_rejected {
    my ($dir, $filename, $source, $regex, $label) = @_;
    my $path = File::Spec->catfile($dir, $filename);
    write_file($path, $source);
    my $ok = eval {
        FSM::Adapter::ISF->new()->parse_file($path);
        1;
    };
    ok(!$ok, "$label fails closed");
    like($@, $regex, "$label diagnostic");
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
