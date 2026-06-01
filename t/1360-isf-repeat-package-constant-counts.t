#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;

subtest 'package scalar constants are valid static repeat counts' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (REPEAT_NINE 4'd9))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'package_constant_repeat_count.isf');
    write_file($isf_path, <<'ISF');
(actor package_constant_repeat_count
  (imports
    (package shared))
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done)
    (output flag))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat shared.REPEAT_NINE
      (drive tick))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{constant_symbols}{packages}{shared}{REPEAT_NINE}{payload}, "4'd9",
        'actor shell records imported package scalar repeat constant');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'package_constant_repeat_count.fsm'};

    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+constants[\s\S]*\(REPEAT_NINE 4'd9\)/,
        'scheduled .fsm embeds imported package constants');
    like($fsm, qr/\(main_cnt 4\)/, 'package repeat count drives resolved counter width');
    like($fsm, qr/\(<= \(main_cnt shared\.REPEAT_NINE\)\)/,
        'repeat init preserves authored package constant token');
    like(state_block($fsm, 'main_repeat_init_1'), qr/\(-> main_repeat_check_3\)/,
        'static package repeat count enters the check-first loop');
    like(state_block($fsm, 'main_repeat_check_3'), qr/\(-- main_cnt\)\n\s+\(\?main_cnt\n\s+\(!=0 \(-> main_drive_2\)\)\n\s+\(=0 \(-> main_done_4\)\)/,
        'static package repeat count keeps the normal decrement check');

    assert_fsm_reaches_hdl($fsm, 'package_constant_repeat_count');
};

subtest 'package constant repeat-count diagnostics fail closed' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (REPEAT_NINE 9)
    (REPEAT_ZERO 0)
    (REPEATS (2 3)))
)
FSM

    assert_lower_file_rejected(
        $dir,
        'unknown_package_constant_repeat_count.isf',
        <<'ISF',
(actor unknown_package_constant_repeat_count
  (imports
    (package shared))
  (interface
    (input start)
    (output done)
    (output flag))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat shared.MISSING
      (drive tick))
    (complete done)))
ISF
        qr/Transaction 'main': repeat count references unknown package constant 'shared\.MISSING'/,
        'unknown package constants are rejected as repeat counts',
    );

    assert_lower_file_rejected(
        $dir,
        'unqualified_package_constant_repeat_count.isf',
        <<'ISF',
(actor unqualified_package_constant_repeat_count
  (imports
    (package shared))
  (interface
    (input start)
    (output done)
    (output flag))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat REPEAT_NINE
      (drive tick))
    (complete done)))
ISF
        qr/Transaction 'main': repeat count 'REPEAT_NINE' is neither a declared non-negative actor constant, actor scalar parameter, qualified package scalar constant, nor a known-width runtime scalar/,
        'unqualified package constants are rejected as repeat counts',
    );

    assert_lower_file_rejected(
        $dir,
        'aggregate_package_constant_repeat_count.isf',
        <<'ISF',
(actor aggregate_package_constant_repeat_count
  (imports
    (package shared))
  (interface
    (input start)
    (output done)
    (output flag))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat shared.REPEATS
      (drive tick))
    (complete done)))
ISF
        qr/Transaction 'main': repeat count package constant 'shared\.REPEATS' must resolve to a non-negative integer scalar/,
        'aggregate package constants remain deferred as repeat counts',
    );

    assert_lower_file_rejected(
        $dir,
        'package_constant_repeat_count_path.isf',
        <<'ISF',
(actor package_constant_repeat_count_path
  (imports
    (package shared))
  (interface
    (input start)
    (output done)
    (output flag))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat shared.REPEATS[0]
      (drive tick))
    (complete done)))
ISF
        qr/Transaction 'main': repeat count package constant 'shared\.REPEATS' aggregate\/member path 'shared\.REPEATS\[0\]' remains deferred/,
        'package aggregate constant scalar-leaf paths remain deferred as repeat counts',
    );

    my $zero_path = write_file(File::Spec->catfile($dir, 'zero_package_constant_repeat_count.isf'), <<'ISF');
(actor zero_package_constant_repeat_count
  (imports
    (package shared))
  (interface
    (input start)
    (output done)
    (output flag))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat shared.REPEAT_ZERO
      (drive tick))
    (complete done)))
ISF
    my $zero_actor = FSM::Adapter::ISF->new()->parse_file($zero_path);
    my $zero_fsm = FSM::Scheduler::ISF->new()->lower($zero_actor)->{files}{'zero_package_constant_repeat_count.fsm'};
    unlike($zero_fsm, qr/\bmain_cnt\b/, 'zero-valued package constant emits no repeat counter');
    unlike($zero_fsm, qr/main_repeat_init_/, 'zero-valued package constant emits no repeat init state');
    unlike($zero_fsm, qr/main_repeat_check_/, 'zero-valued package constant emits no repeat check state');
    unlike($zero_fsm, qr/\(= \(tick_start 1\)\)/, 'zero-valued package constant emits no repeat-body drive start');
    like($zero_fsm, qr/\(main_idle_0[\s\S]*\(-> main_done_1\)/,
        'zero-valued package constant links surrounding states directly');
    my $zero_report = decode_json(FSM::Scheduler::ISF->new()->report($zero_actor));
    is_deeply($zero_report->{transaction_loops}, [],
        'zero-valued package constant emits no transaction loop report entry');
    assert_fsm_reaches_hdl($zero_fsm, 'zero_package_constant_repeat_count');

    my $mode_dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($mode_dir, 'mode.fsm'), <<'FSM');
(?pkg:mode
  (+constants
    (BUSY 2))
)
FSM
    assert_lower_file_rejected(
        $mode_dir,
        'ambiguous_package_constant_repeat_count.isf',
        <<'ISF',
(actor ambiguous_package_constant_repeat_count
  (imports
    (package mode))
  (enums
    (mode (BUSY 1)))
  (interface
    (input start)
    (output done)
    (output flag))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat mode.BUSY
      (drive tick))
    (complete done)))
ISF
        qr/Transaction 'main': repeat count token 'mode\.BUSY' is ambiguous: it matches local enum member 'mode\.BUSY' and imported package constant 'mode\.BUSY'/,
        'ambiguous local-enum and package-constant repeat tokens are rejected',
    );

    assert_lower_file_rejected(
        $dir,
        'expression_package_constant_repeat_count.isf',
        <<'ISF',
(actor expression_package_constant_repeat_count
  (imports
    (package shared))
  (interface
    (input start)
    (output done)
    (output flag))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat (+ shared.REPEAT_NINE 1)
      (drive tick))
    (complete done)))
ISF
        qr/Error: transaction 'main' repeat count references enum member 'shared\.REPEAT_NINE'/,
        'package constant expressions remain rejected as repeat counts',
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
