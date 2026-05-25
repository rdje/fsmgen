#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;

subtest 'package scalar constants are valid static latency bounds' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (LAT_MIN 2)
    (LAT_MAX 4'd8))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'package_constant_latency_bounds.isf');
    write_file($isf_path, <<'ISF');
(actor package_constant_latency_bounds
  (imports
    (package shared))
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min shared.LAT_MIN) (max shared.LAT_MAX))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{constant_symbols}{packages}{shared}{LAT_MIN}{payload}, 2,
        'actor shell records imported package scalar latency min');
    is($actor->{constant_symbols}{packages}{shared}{LAT_MAX}{payload}, "4'd8",
        'actor shell records imported package scalar latency max');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'package_constant_latency_bounds.fsm'};

    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+constants[\s\S]*\(LAT_MIN 2\)[\s\S]*\(LAT_MAX 4'd8\)/,
        'scheduled .fsm embeds imported package constants');
    like($fsm, qr/\(main_cc 4\)/, 'package latency max drives resolved counter width');
    like($fsm, qr/<main_cc<2/, 'package latency min resolves before guard emission');
    like($fsm, qr/\(=8 \(-> main_timeout\)\)/,
        'package latency max resolves before timeout emission');

    assert_fsm_reaches_hdl($fsm, 'package_constant_latency_bounds');
};

subtest 'package constant latency-bound diagnostics fail closed' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (LAT_MIN 2)
    (LAT_ZERO 0)
    (LAT_AGG (2 3)))
)
FSM

    assert_lower_file_rejected(
        $dir,
        'unknown_package_constant_latency_bound.isf',
        <<'ISF',
(actor unknown_package_constant_latency_bound
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min shared.MISSING) (max 8))))
ISF
        qr/Transaction 'main': latency min references unknown package constant 'shared\.MISSING' in transaction body/,
        'unknown package constants are rejected as latency bounds',
    );

    assert_lower_file_rejected(
        $dir,
        'unqualified_package_constant_latency_bound.isf',
        <<'ISF',
(actor unqualified_package_constant_latency_bound
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min LAT_MIN) (max 8))))
ISF
        qr/Transaction 'main': latency min token 'LAT_MIN' is not a same-transaction scalar parameter, declared actor constant, actor scalar parameter, or qualified package scalar constant in transaction body/,
        'unqualified package constants are rejected as latency bounds',
    );

    assert_lower_file_rejected(
        $dir,
        'aggregate_package_constant_latency_bound.isf',
        <<'ISF',
(actor aggregate_package_constant_latency_bound
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min shared.LAT_AGG) (max 8))))
ISF
        qr/Transaction 'main': latency min package constant 'shared\.LAT_AGG' must resolve to a positive integer scalar cycle count in transaction body/,
        'aggregate package constants remain deferred as latency bounds',
    );

    assert_lower_file_rejected(
        $dir,
        'package_constant_latency_bound_path.isf',
        <<'ISF',
(actor package_constant_latency_bound_path
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min shared.LAT_AGG[0]) (max 8))))
ISF
        qr/Transaction 'main': latency min package constant 'shared\.LAT_AGG' aggregate\/member path 'shared\.LAT_AGG\[0\]' remains deferred/,
        'package aggregate constant scalar-leaf paths remain deferred as latency bounds',
    );

    assert_lower_file_rejected(
        $dir,
        'zero_package_constant_latency_bound.isf',
        <<'ISF',
(actor zero_package_constant_latency_bound
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min shared.LAT_ZERO) (max 8))))
ISF
        qr/Transaction 'main': latency min package constant 'shared\.LAT_ZERO' must resolve to a positive integer scalar cycle count in transaction body/,
        'zero-valued package constants keep the positive latency-bound policy',
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
        'ambiguous_package_constant_latency_bound.isf',
        <<'ISF',
(actor ambiguous_package_constant_latency_bound
  (imports
    (package mode))
  (enums
    (mode (BUSY 1)))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min mode.BUSY) (max 8))))
ISF
        qr/Transaction 'main': latency min token 'mode\.BUSY' is ambiguous: it matches local enum member 'mode\.BUSY' and imported package constant 'mode\.BUSY' in transaction body/,
        'ambiguous local-enum and package-constant latency tokens are rejected',
    );

    assert_lower_file_rejected(
        $dir,
        'expression_package_constant_latency_bound.isf',
        <<'ISF',
(actor expression_package_constant_latency_bound
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min (+ shared.LAT_MIN 1)) (max 8))))
ISF
        qr/Error: transaction 'main' latency min references enum member 'shared\.LAT_MIN'/,
        'package constant expressions remain rejected as latency bounds',
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
