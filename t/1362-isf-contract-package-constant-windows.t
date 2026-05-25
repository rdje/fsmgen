#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;

subtest 'package scalar constants are valid static contract windows' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (WINDOW_FOUR 4)
    (WINDOW_TWO 3'd2))
)
FSM

    my $nested_path = File::Spec->catfile($dir, 'package_constant_contract_window.isf');
    write_file($nested_path, <<'ISF');
(actor package_constant_contract_window
  (imports
    (package shared))
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within shared.WINDOW_FOUR)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($nested_path);
    is($actor->{constant_symbols}{packages}{shared}{WINDOW_FOUR}{payload}, 4,
        'actor shell records imported package scalar contract window');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'package_constant_contract_window.fsm'};

    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+constants[\s\S]*\(WINDOW_FOUR 4\)[\s\S]*\(WINDOW_TWO 3'd2\)/,
        'scheduled .fsm embeds imported package constants');
    like($fsm, qr/\(== main_contract_1_age 3\)/,
        'nested package contract window resolves before monitor expiry emission');

    my $report = JSON::PP->new->decode(FSM::Scheduler::ISF->new()->report($actor));
    is($report->{temporal_contracts}[0]{within_cycles}, 4,
        'nested package contract window reports the resolved cycle bound');

    assert_fsm_reaches_hdl($fsm, 'package_constant_contract_window');

    my $flat_path = File::Spec->catfile($dir, 'package_constant_contract_flat_window.isf');
    write_file($flat_path, <<'ISF');
(actor package_constant_contract_flat_window
  (imports
    (package shared))
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack within shared.WINDOW_TWO))
    (complete done)))
ISF

    my $flat_actor = FSM::Adapter::ISF->new()->parse_file($flat_path);
    my $flat_lowered = FSM::Scheduler::ISF->new()->lower($flat_actor);
    like($flat_lowered->{files}{'package_constant_contract_flat_window.fsm'}, qr/\(== main_contract_1_age 1\)/,
        'flat package contract window resolves before monitor expiry emission');

    my $flat_report = JSON::PP->new->decode(FSM::Scheduler::ISF->new()->report($flat_actor));
    is($flat_report->{temporal_contracts}[0]{within_cycles}, 2,
        'flat package contract window reports the resolved cycle bound');
};

subtest 'package constant contract-window diagnostics fail closed' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (WINDOW_FOUR 4)
    (WINDOW_ZERO 0)
    (WINDOWS (2 3)))
)
FSM

    assert_lower_file_rejected(
        $dir,
        'unknown_package_constant_contract_window.isf',
        <<'ISF',
(actor unknown_package_constant_contract_window
  (imports
    (package shared))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within shared.MISSING)))
    (complete done)))
ISF
        qr/Transaction 'main': contract 'ack_seen' within references unknown package constant 'shared\.MISSING' in transaction body/,
        'unknown package constants are rejected as contract windows',
    );

    assert_lower_file_rejected(
        $dir,
        'unqualified_package_constant_contract_window.isf',
        <<'ISF',
(actor unqualified_package_constant_contract_window
  (imports
    (package shared))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within WINDOW_FOUR)))
    (complete done)))
ISF
        qr/Transaction 'main': contract 'ack_seen' within token 'WINDOW_FOUR' is not a declared actor constant, actor scalar parameter, or qualified package scalar constant in transaction body/,
        'unqualified package constants are rejected as contract windows',
    );

    assert_lower_file_rejected(
        $dir,
        'aggregate_package_constant_contract_window.isf',
        <<'ISF',
(actor aggregate_package_constant_contract_window
  (imports
    (package shared))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within shared.WINDOWS)))
    (complete done)))
ISF
        qr/Transaction 'main': contract 'ack_seen' within package constant 'shared\.WINDOWS' must resolve to a positive integer scalar cycle count in transaction body/,
        'aggregate package constants remain deferred as contract windows',
    );

    assert_lower_file_rejected(
        $dir,
        'package_constant_contract_window_path.isf',
        <<'ISF',
(actor package_constant_contract_window_path
  (imports
    (package shared))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within shared.WINDOWS[0])))
    (complete done)))
ISF
        qr/Transaction 'main': contract 'ack_seen' within package constant 'shared\.WINDOWS' aggregate\/member path 'shared\.WINDOWS\[0\]' remains deferred/,
        'package aggregate constant scalar-leaf paths remain deferred as contract windows',
    );

    assert_lower_file_rejected(
        $dir,
        'zero_package_constant_contract_window.isf',
        <<'ISF',
(actor zero_package_constant_contract_window
  (imports
    (package shared))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within shared.WINDOW_ZERO)))
    (complete done)))
ISF
        qr/Transaction 'main': contract 'ack_seen' within package constant 'shared\.WINDOW_ZERO' must resolve to a positive integer scalar cycle count in transaction body/,
        'zero-valued package constants keep the positive contract-window policy',
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
        'ambiguous_package_constant_contract_window.isf',
        <<'ISF',
(actor ambiguous_package_constant_contract_window
  (imports
    (package mode))
  (enums
    (mode (BUSY 1)))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within mode.BUSY)))
    (complete done)))
ISF
        qr/Transaction 'main': contract 'ack_seen' within token 'mode\.BUSY' is ambiguous: it matches local enum member 'mode\.BUSY' and imported package constant 'mode\.BUSY' in transaction body/,
        'ambiguous local-enum and package-constant contract-window tokens are rejected',
    );

    assert_lower_file_rejected(
        $dir,
        'expression_package_constant_contract_window.isf',
        <<'ISF',
(actor expression_package_constant_contract_window
  (imports
    (package shared))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within (+ shared.WINDOW_FOUR 1))))
    (complete done)))
ISF
        qr/Error: transaction 'main' contract window references enum member 'shared\.WINDOW_FOUR'/,
        'package constant expressions remain rejected as contract windows',
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

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
