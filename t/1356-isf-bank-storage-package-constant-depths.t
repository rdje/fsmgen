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

subtest 'package scalar constants are valid actor-owned bank storage depths' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (DEFAULT_DEPTH 4'd2))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'package_constant_bank_storage_depth.isf');
    write_file($isf_path, <<'ISF');
(actor package_constant_bank_storage_depth
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input idx)
    (input wdata (width 8))
    (output rdata (width 8))
    (output done))
  (storage
    (bank data (width 8) (depth shared.DEFAULT_DEPTH)))
  (transaction main
    (on start)
    (store data idx wdata)
    (load data idx as rdata)
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{constant_symbols}{packages}{shared}{DEFAULT_DEPTH}{payload}, "4'd2",
        'actor shell records imported package scalar constant payload');
    is(storage_depth($actor, 'data'), 2, 'bank depth resolves from package scalar constant');
    is_deeply(storage_signal_names($actor, 'data'), [qw(data_0 data_1)], 'bank signal names are finalized');
    is_deeply(storage_signal_widths($actor, 'data'), [8, 8], 'bank signal widths remain finalized');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $fsm = $scheduler->lower($actor)->{files}{'package_constant_bank_storage_depth.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\+size[\s\S]*\(data_0 8\)[\s\S]*\(data_1 8\)/,
        'scheduled .fsm uses resolved package-constant bank depth');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+constants[\s\S]*\(DEFAULT_DEPTH 4'd2\)/,
        'scheduled .fsm embeds imported package root');
    like($fsm, qr/\(<- \(data_1 wdata\) <\(== idx 1\)\)/, 'store includes the resolved final bank entry');
    like($fsm, qr/\(<- \(rdata> data_1\) <\(== idx 1\)\)/, 'load includes the resolved final bank entry');

    my $report = decode_json($scheduler->report($actor));
    assert_actor_storage($report, 'data_0', 8);
    assert_actor_storage($report, 'data_1', 8);
    assert_bank_accesses($report, 2);

    assert_fsm_reaches_hdl($fsm, 'package_constant_bank_storage_depth',
        qr/\breg\s+\[7:0\]\s+data_0\b/,
        'HDL data_0 width is resolved');
    assert_fsm_reaches_hdl($fsm, 'package_constant_bank_storage_depth',
        qr/\breg\s+\[7:0\]\s+data_1\b/,
        'HDL data_1 width is resolved');

    my $hdl_path = File::Spec->catfile($dir, 'package_constant_bank_storage_depth.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package-constant bank storage depths');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package-constant bank storage depths');
    ok(-s $hdl_path, 'CLI writes HDL for package-constant bank storage depths');
};

subtest 'package constant bank storage depth diagnostics fail closed' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (DEFAULT_DEPTH 2)
    (ZERO_DEPTH 0)
    (DEPTHS (2 4)))
)
FSM

    assert_parse_file_rejected(
        $dir,
        'unknown_package_constant_bank_storage_depth.isf',
        <<'ISF',
(actor unknown_package_constant_bank_storage_depth
  (imports
    (package shared))
  (storage
    (bank data (width 8) (depth shared.MISSING))))
ISF
        qr/actor 'unknown_package_constant_bank_storage_depth' storage bank 'data' references unknown package constant 'shared\.MISSING'/,
        'unknown package constants are rejected as bank storage depths',
    );

    assert_parse_file_rejected(
        $dir,
        'unqualified_package_constant_bank_storage_depth.isf',
        <<'ISF',
(actor unqualified_package_constant_bank_storage_depth
  (imports
    (package shared))
  (storage
    (bank data (width 8) (depth DEFAULT_DEPTH))))
ISF
        qr/actor 'unqualified_package_constant_bank_storage_depth' storage bank 'data' depth token 'DEFAULT_DEPTH' is not a declared actor scalar parameter, actor constant, or imported package scalar constant/,
        'unqualified package constants are rejected as bank storage depths',
    );

    assert_parse_file_rejected(
        $dir,
        'aggregate_package_constant_bank_storage_depth.isf',
        <<'ISF',
(actor aggregate_package_constant_bank_storage_depth
  (imports
    (package shared))
  (storage
    (bank data (width 8) (depth shared.DEPTHS))))
ISF
        qr/actor 'aggregate_package_constant_bank_storage_depth' storage bank 'data' package constant 'shared\.DEPTHS' must resolve to a positive integer scalar/,
        'aggregate package constants remain deferred as bank storage depths',
    );

    assert_parse_file_rejected(
        $dir,
        'package_constant_bank_storage_depth_path.isf',
        <<'ISF',
(actor package_constant_bank_storage_depth_path
  (imports
    (package shared))
  (storage
    (bank data (width 8) (depth shared.DEPTHS[0]))))
ISF
        qr/actor 'package_constant_bank_storage_depth_path' storage bank 'data' package constant 'shared\.DEPTHS' aggregate\/member path 'shared\.DEPTHS\[0\]' remains deferred/,
        'package aggregate constant scalar-leaf paths remain deferred as bank storage depths',
    );

    assert_parse_file_rejected(
        $dir,
        'zero_package_constant_bank_storage_depth.isf',
        <<'ISF',
(actor zero_package_constant_bank_storage_depth
  (imports
    (package shared))
  (storage
    (bank data (width 8) (depth shared.ZERO_DEPTH))))
ISF
        qr/actor 'zero_package_constant_bank_storage_depth' storage bank 'data' package constant 'shared\.ZERO_DEPTH' must resolve to a positive integer scalar/,
        'zero-valued package constants are rejected as bank storage depths',
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
        'ambiguous_package_constant_bank_storage_depth.isf',
        <<'ISF',
(actor ambiguous_package_constant_bank_storage_depth
  (imports
    (package mode))
  (enums
    (mode (BUSY 1)))
  (storage
    (bank data (width 8) (depth mode.BUSY))))
ISF
        qr/actor 'ambiguous_package_constant_bank_storage_depth' storage bank 'data' depth token 'mode\.BUSY' is ambiguous: it matches local enum member 'mode\.BUSY' and imported package constant 'mode\.BUSY'/,
        'ambiguous local-enum and package-constant bank depth tokens are rejected',
    );

    assert_parse_file_rejected(
        $dir,
        'runtime_package_constant_bank_storage_depth.isf',
        <<'ISF',
(actor runtime_package_constant_bank_storage_depth
  (imports
    (package shared))
  (interface
    (input start)
    (input DEPTH)
    (output done))
  (storage
    (bank data (width 8) (depth DEPTH))))
ISF
        qr/actor 'runtime_package_constant_bank_storage_depth' storage bank 'data' depth token 'DEPTH' is a runtime interface signal; storage bank depths accept positive integer literals, actor constants, actor scalar parameters, or qualified package scalar constants only/,
        'runtime interface signals are rejected as bank storage depths',
    );

    assert_parse_file_rejected(
        $dir,
        'expression_package_constant_bank_storage_depth.isf',
        <<'ISF',
(actor expression_package_constant_bank_storage_depth
  (imports
    (package shared))
  (storage
    (bank data (width 8) (depth (+ shared.DEFAULT_DEPTH 1)))))
ISF
        qr/actor 'expression_package_constant_bank_storage_depth' storage 'data' depth requires '\(depth positive_integer_or_actor_scalar_parameter_or_actor_constant_or_qualified_package_scalar_constant\)'/,
        'depth expressions remain rejected at parse time',
    );

    assert_parse_file_rejected(
        $dir,
        'transaction_port_width_package_constant.isf',
        <<'ISF',
(actor transaction_port_width_package_constant
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction child
    (ports
      (input addr (width shared.DEFAULT_DEPTH)))
    (on start)
    (complete done)))
ISF
        qr/transaction 'child' port 'addr' width requires '\(width positive_integer_or_actor_scalar_parameter_or_actor_constant\)'/,
        'transaction-local port widths do not inherit this bank-depth package constant widening',
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

sub storage_depth {
    my ($actor, $name) = @_;
    my $entry = storage_entry($actor, $name);
    return $entry ? $entry->{depth} : undef;
}

sub storage_signal_names {
    my ($actor, $name) = @_;
    my $entry = storage_entry($actor, $name);
    return [
        map { $_->{name} }
        @{$entry->{signals} || []}
    ];
}

sub storage_signal_widths {
    my ($actor, $name) = @_;
    my $entry = storage_entry($actor, $name);
    return [
        map { $_->{width} }
        @{$entry->{signals} || []}
    ];
}

sub assert_actor_storage {
    my ($report, $name, $width) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$report->{inferred_storage} || []};

    ok($entry, "schedule report includes actor storage '$name'");
    is($entry->{kind}, 'register', "actor storage '$name' reports register kind") if $entry;
    is($entry->{role}, 'actor_storage', "actor storage '$name' reports actor_storage role") if $entry;
    is($entry->{width}, $width, "actor storage '$name' reports width") if $entry;
}

sub assert_bank_accesses {
    my ($report, $depth) = @_;
    is(scalar(@{$report->{bank_accesses} || []}), 2, 'schedule report exposes store and load bank accesses');
    for my $entry (@{$report->{bank_accesses} || []}) {
        is($entry->{bank}, 'data', 'bank access records bank name');
        is($entry->{width}, 8, 'bank access records bank width');
        is($entry->{depth}, $depth, 'bank access records resolved bank depth');
        is_deeply($entry->{scalar_entries}, [qw(data_0 data_1)], 'bank access records scalarized entries');
    }
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
