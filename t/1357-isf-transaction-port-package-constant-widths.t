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

subtest 'package scalar constants are valid transaction-local port widths' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (DEFAULT_WIDTH 4'd8))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'package_constant_transaction_port_width.isf');
    write_file($isf_path, <<'ISF');
(actor package_constant_transaction_port_width
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input req_addr (width 8))
    (output done)
    (output resp (width 8)))
  (transaction child
    (ports
      (input addr (width shared.DEFAULT_WIDTH))
      (output data (width shared.DEFAULT_WIDTH)))
    (on child_start)
    (update data addr)
    (complete child_done))
  (transaction parent
    (on start)
    (do child
      (bind
        (input addr req_addr)
        (output data resp)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{constant_symbols}{packages}{shared}{DEFAULT_WIDTH}{payload}, "4'd8",
        'actor shell records imported package scalar constant payload');
    is(transaction_port_width($actor, 'child', 'inputs', 'addr'), 8,
        'input transaction port width resolves from package scalar constant');
    is(transaction_port_width($actor, 'child', 'outputs', 'data'), 8,
        'output transaction port width resolves from package scalar constant');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $fsm = $scheduler->lower($actor)->{files}{'package_constant_transaction_port_width.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\+size[\s\S]*\(addr 8\)[\s\S]*\(data 8\)/,
        'scheduled .fsm uses resolved package-constant transaction port widths');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+constants[\s\S]*\(DEFAULT_WIDTH 4'd8\)/,
        'scheduled .fsm embeds imported package root');
    like($fsm, qr/\(= \(addr req_addr\)\)/, 'do binding drives resolved input port');
    like($fsm, qr/\(= \(resp> data\) <child_done\)/, 'do binding reads resolved output port');

    my $report = decode_json($scheduler->report($actor));
    is_deeply(
        [map { $_->{width} } @{$report->{transaction_port_bindings} || []}],
        [8, 8],
        'schedule report binding widths use the resolved transaction port width',
    );

    assert_fsm_reaches_hdl($fsm, 'package_constant_transaction_port_width',
        qr/\breg\s+\[7:0\]\s+addr\b/,
        'HDL addr width is resolved');
    assert_fsm_reaches_hdl($fsm, 'package_constant_transaction_port_width',
        qr/\breg\s+\[7:0\]\s+data\b/,
        'HDL data width is resolved');

    my $hdl_path = File::Spec->catfile($dir, 'package_constant_transaction_port_width.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package-constant transaction port widths');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package-constant transaction port widths');
    ok(-s $hdl_path, 'CLI writes HDL for package-constant transaction port widths');
};

subtest 'package constant transaction port width diagnostics fail closed' => sub {
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
        'unknown_package_constant_transaction_port_width.isf',
        <<'ISF',
(actor unknown_package_constant_transaction_port_width
  (imports
    (package shared))
  (transaction child
    (ports
      (input addr (width shared.MISSING)))))
ISF
        qr/actor 'unknown_package_constant_transaction_port_width' transaction 'child' port 'addr' references unknown package constant 'shared\.MISSING'/,
        'unknown package constants are rejected as transaction port widths',
    );

    assert_parse_file_rejected(
        $dir,
        'unqualified_package_constant_transaction_port_width.isf',
        <<'ISF',
(actor unqualified_package_constant_transaction_port_width
  (imports
    (package shared))
  (transaction child
    (ports
      (input addr (width DEFAULT_WIDTH)))))
ISF
        qr/actor 'unqualified_package_constant_transaction_port_width' transaction 'child' port 'addr' width token 'DEFAULT_WIDTH' is not a same-transaction scalar parameter, declared actor scalar parameter, actor constant, or imported package scalar constant/,
        'unqualified package constants are rejected as transaction port widths',
    );

    assert_parse_file_rejected(
        $dir,
        'aggregate_package_constant_transaction_port_width.isf',
        <<'ISF',
(actor aggregate_package_constant_transaction_port_width
  (imports
    (package shared))
  (transaction child
    (ports
      (input addr (width shared.WIDTHS)))))
ISF
        qr/actor 'aggregate_package_constant_transaction_port_width' transaction 'child' port 'addr' package constant 'shared\.WIDTHS' must resolve to a positive integer scalar/,
        'aggregate package constants remain deferred as transaction port widths',
    );

    assert_parse_file_rejected(
        $dir,
        'package_constant_transaction_port_width_path.isf',
        <<'ISF',
(actor package_constant_transaction_port_width_path
  (imports
    (package shared))
  (transaction child
    (ports
      (input addr (width shared.WIDTHS[0])))))
ISF
        qr/actor 'package_constant_transaction_port_width_path' transaction 'child' port 'addr' package constant 'shared\.WIDTHS' aggregate\/member path 'shared\.WIDTHS\[0\]' remains deferred/,
        'package aggregate constant scalar-leaf paths remain deferred as transaction port widths',
    );

    assert_parse_file_rejected(
        $dir,
        'zero_package_constant_transaction_port_width.isf',
        <<'ISF',
(actor zero_package_constant_transaction_port_width
  (imports
    (package shared))
  (transaction child
    (ports
      (input addr (width shared.ZERO_WIDTH)))))
ISF
        qr/actor 'zero_package_constant_transaction_port_width' transaction 'child' port 'addr' package constant 'shared\.ZERO_WIDTH' must resolve to a positive integer scalar/,
        'zero-valued package constants are rejected as transaction port widths',
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
        'ambiguous_package_constant_transaction_port_width.isf',
        <<'ISF',
(actor ambiguous_package_constant_transaction_port_width
  (imports
    (package mode))
  (enums
    (mode (BUSY 1)))
  (transaction child
    (ports
      (input addr (width mode.BUSY)))))
ISF
        qr/actor 'ambiguous_package_constant_transaction_port_width' transaction 'child' port 'addr' width token 'mode\.BUSY' is ambiguous: it matches local enum member 'mode\.BUSY' and imported package constant 'mode\.BUSY'/,
        'ambiguous local-enum and package-constant width tokens are rejected',
    );

    assert_parse_file_rejected(
        $dir,
        'runtime_package_constant_transaction_port_width.isf',
        <<'ISF',
(actor runtime_package_constant_transaction_port_width
  (imports
    (package shared))
  (interface
    (input WIDTH))
  (transaction child
    (ports
      (input addr (width WIDTH)))))
ISF
        qr/actor 'runtime_package_constant_transaction_port_width' transaction 'child' port 'addr' width token 'WIDTH' is a runtime interface signal; transaction port widths accept positive integer literals, same-transaction scalar parameters, actor constants, actor scalar parameters, or qualified package scalar constants only/,
        'runtime interface signals are rejected as transaction port widths',
    );

    assert_parse_file_rejected(
        $dir,
        'expression_package_constant_transaction_port_width.isf',
        <<'ISF',
(actor expression_package_constant_transaction_port_width
  (imports
    (package shared))
  (transaction child
    (ports
      (input addr (width (+ shared.DEFAULT_WIDTH 1))))))
ISF
        qr/transaction 'child' port 'addr' width requires '\(width positive_integer_or_same_transaction_scalar_parameter_or_actor_scalar_parameter_or_actor_constant_or_qualified_package_scalar_constant\)'/,
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

sub transaction_by_name {
    my ($actor, $name) = @_;
    my ($tx) = grep { $_->{name} eq $name } @{$actor->{transactions} || []};
    ok($tx, "found transaction '$name'");
    return $tx;
}

sub transaction_port_width {
    my ($actor, $transaction_name, $direction, $port_name) = @_;
    my $tx = transaction_by_name($actor, $transaction_name);
    my ($port) = grep { $_->{name} eq $port_name } @{($tx->{ports} || {})->{$direction} || []};
    ok($port, "found $direction port '$port_name'");
    return $port ? $port->{width} : undef;
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
