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

subtest 'package scalar constants are valid actor-owned scalar storage widths' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (DEFAULT_WIDTH 4'd8)
    (SIDE_WIDTH 1))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'package_constant_scalar_storage_width.isf');
    write_file($isf_path, <<'ISF');
(actor package_constant_scalar_storage_width
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (storage
    (var counter (width shared.DEFAULT_WIDTH))
    (variable shadow (width shared.SIDE_WIDTH)))
  (transaction main
    (on start)
    (update counter (+ counter 1))
    (update shadow 1)
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{constant_symbols}{packages}{shared}{DEFAULT_WIDTH}{payload}, "4'd8",
        'actor shell records imported package scalar constant payload');
    is(storage_width($actor, 'counter'), 8, 'var width resolves from package scalar constant');
    is(storage_width($actor, 'shadow'), 1, 'variable alias width resolves from package scalar constant');
    is(storage_signal_width($actor, 'counter'), 8, 'var signal width is finalized');
    is(storage_signal_width($actor, 'shadow'), 1, 'variable alias signal width is finalized');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $fsm = $scheduler->lower($actor)->{files}{'package_constant_scalar_storage_width.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\+size[\s\S]*\(counter 8\)[\s\S]*\(shadow 1\)/,
        'scheduled .fsm uses resolved package-constant scalar storage widths');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+constants[\s\S]*\(DEFAULT_WIDTH 4'd8\)[\s\S]*\(SIDE_WIDTH 1\)/,
        'scheduled .fsm embeds imported package root');

    my $report = decode_json($scheduler->report($actor));
    assert_actor_storage($report, 'counter', 8);
    assert_actor_storage($report, 'shadow', 1);

    assert_fsm_reaches_hdl($fsm, 'package_constant_scalar_storage_width',
        qr/\breg\s+\[7:0\]\s+counter\b/,
        'HDL counter width is resolved');
    assert_fsm_reaches_hdl($fsm, 'package_constant_scalar_storage_width',
        qr/\breg\s+shadow\b/,
        'HDL one-bit shadow width is resolved');

    my $hdl_path = File::Spec->catfile($dir, 'package_constant_scalar_storage_width.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package-constant scalar storage widths');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package-constant scalar storage widths');
    ok(-s $hdl_path, 'CLI writes HDL for package-constant scalar storage widths');
};

subtest 'package constant scalar storage width diagnostics fail closed' => sub {
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
        'unknown_package_constant_scalar_storage_width.isf',
        <<'ISF',
(actor unknown_package_constant_scalar_storage_width
  (imports
    (package shared))
  (storage
    (var counter (width shared.MISSING))))
ISF
        qr/actor 'unknown_package_constant_scalar_storage_width' storage 'counter' references unknown package constant 'shared\.MISSING'/,
        'unknown package constants are rejected as scalar storage widths',
    );

    assert_parse_file_rejected(
        $dir,
        'unqualified_package_constant_scalar_storage_width.isf',
        <<'ISF',
(actor unqualified_package_constant_scalar_storage_width
  (imports
    (package shared))
  (storage
    (var counter (width DEFAULT_WIDTH))))
ISF
        qr/actor 'unqualified_package_constant_scalar_storage_width' storage 'counter' width token 'DEFAULT_WIDTH' is not a declared actor scalar parameter, actor constant, or imported package scalar constant/,
        'unqualified package constants are rejected as scalar storage widths',
    );

    assert_parse_file_rejected(
        $dir,
        'aggregate_package_constant_scalar_storage_width.isf',
        <<'ISF',
(actor aggregate_package_constant_scalar_storage_width
  (imports
    (package shared))
  (storage
    (var counter (width shared.WIDTHS))))
ISF
        qr/actor 'aggregate_package_constant_scalar_storage_width' storage 'counter' package constant 'shared\.WIDTHS' must resolve to a positive integer scalar/,
        'aggregate package constants remain deferred as scalar storage widths',
    );

    assert_parse_file_rejected(
        $dir,
        'package_constant_scalar_storage_width_path.isf',
        <<'ISF',
(actor package_constant_scalar_storage_width_path
  (imports
    (package shared))
  (storage
    (var counter (width shared.WIDTHS[0]))))
ISF
        qr/actor 'package_constant_scalar_storage_width_path' storage 'counter' package constant 'shared\.WIDTHS' aggregate\/member path 'shared\.WIDTHS\[0\]' remains deferred/,
        'package aggregate constant scalar-leaf paths remain deferred as scalar storage widths',
    );

    assert_parse_file_rejected(
        $dir,
        'zero_package_constant_scalar_storage_width.isf',
        <<'ISF',
(actor zero_package_constant_scalar_storage_width
  (imports
    (package shared))
  (storage
    (var counter (width shared.ZERO_WIDTH))))
ISF
        qr/actor 'zero_package_constant_scalar_storage_width' storage 'counter' package constant 'shared\.ZERO_WIDTH' must resolve to a positive integer scalar/,
        'zero-valued package constants are rejected as scalar storage widths',
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
        'ambiguous_package_constant_scalar_storage_width.isf',
        <<'ISF',
(actor ambiguous_package_constant_scalar_storage_width
  (imports
    (package mode))
  (enums
    (mode (BUSY 1)))
  (storage
    (var counter (width mode.BUSY))))
ISF
        qr/actor 'ambiguous_package_constant_scalar_storage_width' storage 'counter' width token 'mode\.BUSY' is ambiguous: it matches local enum member 'mode\.BUSY' and imported package constant 'mode\.BUSY'/,
        'ambiguous local-enum and package-constant storage width tokens are rejected',
    );

    assert_parse_file_rejected(
        $dir,
        'expression_package_constant_scalar_storage_width.isf',
        <<'ISF',
(actor expression_package_constant_scalar_storage_width
  (imports
    (package shared))
  (storage
    (var counter (width (+ shared.DEFAULT_WIDTH 1)))))
ISF
        qr/actor 'expression_package_constant_scalar_storage_width' storage 'counter' width requires '\(width positive_integer_or_actor_scalar_parameter_or_actor_constant_or_qualified_package_scalar_constant\)'/,
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

sub storage_entry {
    my ($actor, $name) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$actor->{storage} || []};
    ok($entry, "found storage '$name'");
    return $entry;
}

sub storage_width {
    my ($actor, $name) = @_;
    my $entry = storage_entry($actor, $name);
    return $entry ? $entry->{width} : undef;
}

sub storage_signal_width {
    my ($actor, $name) = @_;
    my $entry = storage_entry($actor, $name);
    my ($signal) = grep { $_->{name} eq $name } @{$entry->{signals} || []};
    ok($signal, "found storage signal '$name'");
    return $signal ? $signal->{width} : undef;
}

sub assert_actor_storage {
    my ($report, $name, $width) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$report->{inferred_storage} || []};

    ok($entry, "schedule report includes actor storage '$name'");
    is($entry->{kind}, 'register', "actor storage '$name' reports register kind") if $entry;
    is($entry->{role}, 'actor_storage', "actor storage '$name' reports actor_storage role") if $entry;
    is($entry->{width}, $width, "actor storage '$name' reports width") if $entry;
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
