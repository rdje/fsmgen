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
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;

subtest 'package scalar constants are valid interface widths' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (DEFAULT_WIDTH 4'd8)
    (SIDE_WIDTH 1))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'package_constant_interface_width.isf');
    write_file($isf_path, <<'ISF');
(actor package_constant_interface_width
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input data_in (width shared.DEFAULT_WIDTH))
    (input sideband (width shared.SIDE_WIDTH))
    (output data_out (width shared.DEFAULT_WIDTH)))
  (transaction main
    (on start)
    (set data_out data_in)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{constant_symbols}{packages}{shared}{DEFAULT_WIDTH}{payload}, "4'd8",
        'actor shell records imported package scalar constant payload');
    is(port_width($actor->{interface}{inputs}, 'data_in'), 8,
        'input width resolves from package scalar constant');
    is(port_width($actor->{interface}{inputs}, 'sideband'), 1,
        'one-bit input width resolves from package scalar constant');
    is(port_width($actor->{interface}{outputs}, 'data_out'), 8,
        'output width resolves from package scalar constant');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $fsm = $scheduler->lower($actor)->{files}{'package_constant_interface_width.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\+size[\s\S]*\(data_in 8\)[\s\S]*\(sideband 1\)[\s\S]*\(data_out 8\)/,
        'scheduled .fsm uses resolved package-constant interface widths');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+constants[\s\S]*\(DEFAULT_WIDTH 4'd8\)[\s\S]*\(SIDE_WIDTH 1\)/,
        'scheduled .fsm embeds imported package root');

    my $report = decode_json($scheduler->report($actor));
    is($report->{inputs}, 3, 'schedule report input count is unchanged');
    is($report->{outputs}, 1, 'schedule report output count is unchanged');

    assert_fsm_reaches_hdl($fsm, 'package_constant_interface_width', qr/\binput\s+wire\s+\[7:0\]\s+data_in\b/,
        'HDL input width is resolved');
    assert_fsm_reaches_hdl($fsm, 'package_constant_interface_width', qr/\boutput\s+reg\s+\[7:0\]\s+data_out\b/,
        'HDL output width is resolved');

    my $hdl_path = File::Spec->catfile($dir, 'package_constant_interface_width.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package-constant interface widths');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package-constant interface widths');
    ok(-s $hdl_path, 'CLI writes HDL for package-constant interface widths');
};

subtest 'package constant interface width diagnostics fail closed' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (DEFAULT_WIDTH 8)
    (ZERO_WIDTH 0)
    (WIDTHS (8 4)))
)
FSM

    assert_parse_file_rejected(
        $dir,
        'unknown_package_constant_width.isf',
        <<'ISF',
(actor unknown_package_constant_width
  (imports
    (package shared))
  (interface
    (output data_out (width shared.MISSING))))
ISF
        qr/actor 'unknown_package_constant_width' interface port 'data_out' references unknown package constant 'shared\.MISSING'/,
        'unknown package constants are rejected as interface widths',
    );

    assert_parse_file_rejected(
        $dir,
        'unqualified_package_constant_width.isf',
        <<'ISF',
(actor unqualified_package_constant_width
  (imports
    (package shared))
  (interface
    (output data_out (width DEFAULT_WIDTH))))
ISF
        qr/actor 'unqualified_package_constant_width' interface port 'data_out' width token 'DEFAULT_WIDTH' is not a declared actor scalar parameter, actor constant, or imported package scalar constant/,
        'unqualified package constants are rejected as interface widths',
    );

    assert_parse_file_rejected(
        $dir,
        'aggregate_package_constant_width.isf',
        <<'ISF',
(actor aggregate_package_constant_width
  (imports
    (package shared))
  (interface
    (output data_out (width shared.WIDTHS))))
ISF
        qr/actor 'aggregate_package_constant_width' interface port 'data_out' package constant 'shared\.WIDTHS' must resolve to a positive integer scalar/,
        'aggregate package constants remain deferred as interface widths',
    );

    assert_parse_file_rejected(
        $dir,
        'package_constant_width_path.isf',
        <<'ISF',
(actor package_constant_width_path
  (imports
    (package shared))
  (interface
    (output data_out (width shared.WIDTHS[0]))))
ISF
        qr/actor 'package_constant_width_path' interface port 'data_out' package constant 'shared\.WIDTHS' aggregate\/member path 'shared\.WIDTHS\[0\]' remains deferred/,
        'package aggregate constant scalar-leaf paths remain deferred as interface widths',
    );

    assert_parse_file_rejected(
        $dir,
        'zero_package_constant_width.isf',
        <<'ISF',
(actor zero_package_constant_width
  (imports
    (package shared))
  (interface
    (output data_out (width shared.ZERO_WIDTH))))
ISF
        qr/actor 'zero_package_constant_width' interface port 'data_out' package constant 'shared\.ZERO_WIDTH' must resolve to a positive integer scalar/,
        'zero-valued package constants are rejected as interface widths',
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
        'ambiguous_package_constant_width.isf',
        <<'ISF',
(actor ambiguous_package_constant_width
  (imports
    (package mode))
  (enums
    (mode (BUSY 1)))
  (interface
    (output data_out (width mode.BUSY))))
ISF
        qr/actor 'ambiguous_package_constant_width' interface port 'data_out' width token 'mode\.BUSY' is ambiguous: it matches local enum member 'mode\.BUSY' and imported package constant 'mode\.BUSY'/,
        'ambiguous local-enum and package-constant width tokens are rejected',
    );

    assert_parse_file_rejected(
        $dir,
        'expression_package_constant_width.isf',
        <<'ISF',
(actor expression_package_constant_width
  (imports
    (package shared))
  (interface
    (output data_out (width (+ shared.DEFAULT_WIDTH 1)))))
ISF
        qr/interface port 'data_out' width must be a positive integer, actor constant, actor scalar parameter, or qualified package scalar constant/,
        'width expressions remain rejected at parse time',
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

sub assert_fsm_reaches_hdl {
    my ($fsm, $module_name, $hdl_re, $label) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, "$module_name.fsm");
    write_file($fsm_path, $fsm);

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file    => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast     => $raw_ast,
        debug_level => 0,
    );
    ok($fsm_module, "$label scheduled .fsm parses through the normal frontend");

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, $hdl_re, $label);
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
