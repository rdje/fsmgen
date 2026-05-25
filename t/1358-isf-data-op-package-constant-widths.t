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

subtest 'package scalar constants are valid explicit data-operation width evidence' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (SHIFT_W 4'd8)
    (HEADER_W 4)
    (PAYLOAD_W 8)
    (CRC_W 4))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'package_constant_data_op_width.isf');
    write_file($isf_path, <<'ISF');
(actor package_constant_data_op_width
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input bit_in)
    (input word (width 16))
    (output done))
  (transaction main
    (on start)
    (shift_left shreg bit_in (width shared.SHIFT_W))
    (shift_right shreg bit_in)
    (extract word as header payload crc (widths shared.HEADER_W shared.PAYLOAD_W shared.CRC_W))
    (assemble header crc as packet (widths shared.HEADER_W shared.CRC_W))
    (shift_right packet bit_in)
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{constant_symbols}{packages}{shared}{SHIFT_W}{payload}, "4'd8",
        'actor shell records imported package scalar constant payload');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'package_constant_data_op_width.fsm'};

    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+constants[\s\S]*\(SHIFT_W 4'd8\)/,
        'scheduled .fsm embeds imported package root');
    like($fsm, qr/\(<- \(shreg \(\| \(>> shreg 1\) \(<< bit_in 7\)\)\)\)/,
        'shift_right consumes package-constant width evidence from shift_left');
    like($fsm, qr/\(<= \(header \(slice word 15 12\)\)\)/,
        'package-constant extract width drives first slice');
    like($fsm, qr/\(<= \(payload \(slice word 11 4\)\)\)/,
        'package-constant extract width drives middle slice');
    like($fsm, qr/\(<= \(crc \(slice word 3 0\)\)\)/,
        'package-constant extract width drives final slice');
    like($fsm, qr/\(<- \(packet \(concat header crc\)\)\)/,
        'package-constant assemble widths preserve concat lowering');
    like($fsm, qr/\(<- \(packet \(\| \(>> packet 1\) \(<< bit_in 7\)\)\)\)/,
        'later shift_right consumes package-constant assemble-derived width');
    unlike($fsm, qr/WIDTH|HIGH|LOW/, 'package-constant data-operation widths leave no placeholder bounds');

    my $report = decode_json($scheduler->report($actor));
    assert_storage($report, 'shreg', 'register', 'data_register', 8);
    assert_storage($report, 'header', 'register', 'extract_field', 4);
    assert_storage($report, 'payload', 'register', 'extract_field', 8);
    assert_storage($report, 'crc', 'register', 'extract_field', 4);
    assert_storage($report, 'packet', 'register', 'data_register', 8);

    my $hdl_isf_path = File::Spec->catfile($dir, 'package_constant_data_op_width_hdl.isf');
    write_file($hdl_isf_path, <<'ISF');
(actor package_constant_data_op_width_hdl
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_left shreg bit_in (width shared.SHIFT_W))
    (assemble header crc as packet (widths shared.HEADER_W shared.CRC_W))
    (shift_right packet bit_in)
    (complete done)))
ISF

    my $hdl_actor = FSM::Adapter::ISF->new()->parse_file($hdl_isf_path);
    my $hdl_fsm = $scheduler->lower($hdl_actor)->{files}{'package_constant_data_op_width_hdl.fsm'};
    like($hdl_fsm, qr/\(<- \(packet \(\| \(>> packet 1\) \(<< bit_in 7\)\)\)\)/,
        'HDL smoke source still publishes package-constant assemble-derived width in scheduled .fsm');

    my $hdl_path = File::Spec->catfile($dir, 'package_constant_data_op_width_hdl.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $hdl_isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package-constant data-operation widths');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package-constant data-operation widths');
    ok(-s $hdl_path, 'CLI writes HDL for package-constant data-operation widths');
};

subtest 'package constant data-operation width diagnostics fail closed' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (DEFAULT_WIDTH 8)
    (ZERO_WIDTH 0)
    (WIDTHS (8 4)))
)
FSM

    assert_lower_file_rejected(
        $dir,
        'unknown_package_constant_data_op_width.isf',
        <<'ISF',
(actor unknown_package_constant_data_op_width
  (imports
    (package shared))
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_right shreg bit_in (width shared.MISSING))
    (complete done)))
ISF
        qr/Transaction 'main': shift_right width references unknown package constant 'shared\.MISSING'/,
        'unknown package constants are rejected as data-operation widths',
    );

    assert_lower_file_rejected(
        $dir,
        'unqualified_package_constant_data_op_width.isf',
        <<'ISF',
(actor unqualified_package_constant_data_op_width
  (imports
    (package shared))
  (interface
    (input start)
    (input word (width 8))
    (output done))
  (transaction main
    (on start)
    (extract word as field (widths DEFAULT_WIDTH))
    (complete done)))
ISF
        qr/Transaction 'main': extract width for 'field' token 'DEFAULT_WIDTH' is not a same-transaction scalar parameter, declared actor constant, actor scalar parameter, or imported package scalar constant/,
        'unqualified package constants are rejected as data-operation widths',
    );

    assert_lower_file_rejected(
        $dir,
        'aggregate_package_constant_data_op_width.isf',
        <<'ISF',
(actor aggregate_package_constant_data_op_width
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (assemble header payload as packet (widths 4 shared.WIDTHS))
    (complete done)))
ISF
        qr/Transaction 'main': assemble width for 'payload' package constant 'shared\.WIDTHS' must resolve to a positive integer scalar/,
        'aggregate package constants remain deferred as data-operation widths',
    );

    assert_lower_file_rejected(
        $dir,
        'package_constant_data_op_width_path.isf',
        <<'ISF',
(actor package_constant_data_op_width_path
  (imports
    (package shared))
  (interface
    (input start)
    (input word (width 8))
    (output done))
  (transaction main
    (on start)
    (extract word as field (widths shared.WIDTHS[0]))
    (complete done)))
ISF
        qr/Transaction 'main': extract width for 'field' package constant 'shared\.WIDTHS' aggregate\/member path 'shared\.WIDTHS\[0\]' remains deferred/,
        'package aggregate constant scalar-leaf paths remain deferred as data-operation widths',
    );

    assert_lower_file_rejected(
        $dir,
        'zero_package_constant_data_op_width.isf',
        <<'ISF',
(actor zero_package_constant_data_op_width
  (imports
    (package shared))
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_left shreg bit_in (width shared.ZERO_WIDTH))
    (complete done)))
ISF
        qr/Transaction 'main': shift_left width package constant 'shared\.ZERO_WIDTH' must resolve to a positive integer scalar/,
        'zero-valued package constants are rejected as data-operation widths',
    );

    my $mode_dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($mode_dir, 'mode.fsm'), <<'FSM');
(?pkg:mode
  (+constants
    (BUSY 1))
)
FSM
    assert_lower_file_rejected(
        $mode_dir,
        'ambiguous_package_constant_data_op_width.isf',
        <<'ISF',
(actor ambiguous_package_constant_data_op_width
  (imports
    (package mode))
  (enums
    (mode (BUSY 1)))
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_right shreg bit_in (width mode.BUSY))
    (complete done)))
ISF
        qr/Transaction 'main': shift_right width token 'mode\.BUSY' is ambiguous: it matches local enum member 'mode\.BUSY' and imported package constant 'mode\.BUSY'/,
        'ambiguous local-enum and package-constant width tokens are rejected',
    );

    assert_lower_file_rejected(
        $dir,
        'runtime_package_constant_data_op_width.isf',
        <<'ISF',
(actor runtime_package_constant_data_op_width
  (imports
    (package shared))
  (interface
    (input start)
    (input WIDTH (width 4))
    (output done))
  (transaction main
    (on start)
    (assemble header payload as packet (widths 4 WIDTH))
    (complete done)))
ISF
        qr/Transaction 'main': assemble width for 'payload' token 'WIDTH' is a runtime interface signal; data-operation width evidence accepts positive integer literals, same-transaction scalar parameters, actor constants, actor scalar parameters, or qualified package scalar constants only/,
        'runtime interface signals are rejected as data-operation widths',
    );

    assert_lower_file_rejected(
        $dir,
        'expression_package_constant_data_op_width.isf',
        <<'ISF',
(actor expression_package_constant_data_op_width
  (imports
    (package shared))
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_right shreg bit_in (width (+ shared.DEFAULT_WIDTH 1)))
    (complete done)))
ISF
        qr/shift_right width must be a positive integer literal, same-transaction scalar parameter, actor constant, actor scalar parameter, or qualified package scalar constant/,
        'width expressions remain rejected',
    );
};

done_testing();

sub assert_lower_file_rejected {
    my ($dir, $filename, $source, $regex, $label) = @_;
    my $path = File::Spec->catfile($dir, $filename);
    write_file($path, $source);

    my $ok = eval {
        my $actor = FSM::Adapter::ISF->new()->parse_file($path);
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };
    ok(!$ok, "$label fails closed");
    like($@, $regex, "$label diagnostic");
}

sub assert_storage {
    my ($report, $name, $kind, $role, $width) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$report->{inferred_storage} || []};

    ok($entry, "storage entry '$name' exists");
    return unless $entry;
    is($entry->{kind}, $kind, "storage entry '$name' kind");
    is($entry->{role}, $role, "storage entry '$name' role");
    is($entry->{width}, $width, "storage entry '$name' width");
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
