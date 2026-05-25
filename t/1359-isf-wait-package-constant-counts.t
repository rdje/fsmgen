#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;

subtest 'package scalar constants are valid static wait counts' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (WAIT_ZERO 0)
    (WAIT_TWO 2)
    (WAIT_ONE 4'd1))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'package_constant_wait_count.isf');
    write_file($isf_path, <<'ISF');
(actor package_constant_wait_count
  (imports
    (package shared))
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input din (width 8))
    (output done)
    (output out (width 8)))
  (drive (outp val)
    (out val))
  (transaction main
    (on start)
    (sample din as hold)
    (wait shared.WAIT_ZERO)
    (wait shared.WAIT_TWO)
    (drive outp hold)
    (wait shared.WAIT_ONE)
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{constant_symbols}{packages}{shared}{WAIT_TWO}{payload}, '2',
        'actor shell records imported package scalar wait constant');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'package_constant_wait_count.fsm'};

    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+constants[\s\S]*\(WAIT_ZERO 0\)[\s\S]*\(WAIT_TWO 2\)[\s\S]*\(WAIT_ONE 4'd1\)/,
        'scheduled .fsm embeds imported package constants');
    unlike($fsm, qr/\bmain_wait_0\b/, 'package-constant zero wait emits no hidden wait state');
    like(state_block($fsm, 'main_wait_1'), qr/\(<= \(hold din\)\)/,
        'pending sample survives package-constant zero wait and piggybacks onto first positive wait');
    like(state_block($fsm, 'main_wait_1'), qr/\(-> main_wait_2\)/,
        'WAIT_TWO first generated wait state advances');
    like(state_block($fsm, 'main_wait_2'), qr/\(-> main_drive_3\)/,
        'WAIT_TWO second generated wait state exits to following clause');
    like(state_block($fsm, 'main_wait_4'), qr/\(-> main_done_5\)/,
        'exact-width WAIT_ONE emits one wait state');

    my $report = decode_json($scheduler->report($actor));
    is_deeply(
        [map { $_->{cycles} } @{$report->{transaction_waits}}],
        [2, 1],
        'package-constant waits resolve to exact static wait counts',
    );
    is_deeply(
        [map { $_->{count_kind} } @{$report->{transaction_waits}}],
        [qw(static static)],
        'package-constant waits remain static waits in report metadata',
    );
    is_deeply(
        [map { $_->{count_source} } @{$report->{transaction_waits}}],
        [qw(shared.WAIT_TWO shared.WAIT_ONE)],
        'wait report entries preserve authored package-constant count sources',
    );
    is_deeply(
        $report->{transactions}[0]{states},
        [qw(main_idle_0 main_wait_1 main_wait_2 main_drive_3 main_wait_4 main_done_5)],
        'package-constant zero wait creates no state gap and positive package constants keep emitted order',
    );

    assert_fsm_reaches_hdl($fsm, 'package_constant_wait_count');
};

subtest 'package constant wait-count diagnostics fail closed' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (WAIT_TWO 2)
    (WAITS (2 3)))
)
FSM

    assert_lower_file_rejected(
        $dir,
        'unknown_package_constant_wait_count.isf',
        <<'ISF',
(actor unknown_package_constant_wait_count
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (wait shared.MISSING)
    (complete done)))
ISF
        qr/Transaction 'main': wait count references unknown package constant 'shared\.MISSING' in transaction body/,
        'unknown package constants are rejected as wait counts',
    );

    assert_lower_file_rejected(
        $dir,
        'unqualified_package_constant_wait_count.isf',
        <<'ISF',
(actor unqualified_package_constant_wait_count
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (wait WAIT_TWO)
    (complete done)))
ISF
        qr/Transaction 'main': wait count 'WAIT_TWO' is neither a same-transaction scalar parameter, declared actor constant, actor parameter, qualified package scalar constant, nor a known-width runtime scalar in transaction body/,
        'unqualified package constants are rejected as wait counts',
    );

    assert_lower_file_rejected(
        $dir,
        'aggregate_package_constant_wait_count.isf',
        <<'ISF',
(actor aggregate_package_constant_wait_count
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (wait shared.WAITS)
    (complete done)))
ISF
        qr/Transaction 'main': wait count package constant 'shared\.WAITS' must resolve to a non-negative integer scalar in transaction body/,
        'aggregate package constants remain deferred as wait counts',
    );

    assert_lower_file_rejected(
        $dir,
        'package_constant_wait_count_path.isf',
        <<'ISF',
(actor package_constant_wait_count_path
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (wait shared.WAITS[0])
    (complete done)))
ISF
        qr/Transaction 'main': wait count package constant 'shared\.WAITS' aggregate\/member path 'shared\.WAITS\[0\]' remains deferred/,
        'package aggregate constant scalar-leaf paths remain deferred as wait counts',
    );

    my $mode_dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($mode_dir, 'mode.fsm'), <<'FSM');
(?pkg:mode
  (+constants
    (BUSY 2))
)
FSM
    assert_lower_file_rejected(
        $mode_dir,
        'ambiguous_package_constant_wait_count.isf',
        <<'ISF',
(actor ambiguous_package_constant_wait_count
  (imports
    (package mode))
  (enums
    (mode (BUSY 1)))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (wait mode.BUSY)
    (complete done)))
ISF
        qr/Transaction 'main': wait count token 'mode\.BUSY' is ambiguous: it matches local enum member 'mode\.BUSY' and imported package constant 'mode\.BUSY' in transaction body/,
        'ambiguous local-enum and package-constant wait tokens are rejected',
    );

    assert_lower_file_rejected(
        $dir,
        'expression_package_constant_wait_count.isf',
        <<'ISF',
(actor expression_package_constant_wait_count
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (wait (+ shared.WAIT_TWO 1))
    (complete done)))
ISF
        qr/Error: transaction 'main' wait count references enum member 'shared\.WAIT_TWO'/,
        'package constant expressions remain rejected as wait counts',
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

sub assert_fsm_reaches_hdl {
    my ($fsm, $module_name) = @_;
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
    ok($fsm_module, "$module_name scheduled .fsm parses through the normal .fsm frontend");

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);

    like($hdl, qr/\bmodule\s+\Q$module_name\E\b/, "$module_name reaches HDL generation");
}

sub state_block {
    my ($fsm, $state_name) = @_;
    my ($block) = ($fsm =~ /(  \(\Q$state_name\E\b.*?\n  \))/s);
    return $block // '';
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
