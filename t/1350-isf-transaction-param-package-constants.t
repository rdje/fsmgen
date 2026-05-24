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

subtest 'package scalar constants are valid generated child transaction defaults' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (DEFAULT_WIDTH 4'd8)
    (LANE0 1)
    (LANE1 0))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'transaction_package_constant_defaults.isf');
    write_file($isf_path, <<'ISF');
(actor transaction_package_constant_defaults
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH shared.DEFAULT_WIDTH)
      (LANES (shared.LANE0 shared.LANE1)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply(
        $ir->{children}{worker}{params},
        [
            { name => 'WIDTH', value => 'shared.DEFAULT_WIDTH', resolved_value => "4'd8" },
            { name => 'LANES', value => [qw(shared.LANE0 shared.LANE1)], resolved_value => [qw(1 0)] },
        ],
        'generated child IR preserves package constant defaults and resolved values',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    like($child_fsm, qr/\(\+import\s+shared\s+\)/s,
        'generated child .fsm emits package import');
    like($child_fsm, qr/\(\+params\s+\(WIDTH shared\.DEFAULT_WIDTH\)\s+\(LANES \(shared\.LANE0 shared\.LANE1\)\)\s+\)/s,
        'generated child .fsm preserves package-constant transaction parameter defaults');
    like($child_fsm, qr/\(\?pkg:shared[\s\S]*\(\+constants[\s\S]*\(DEFAULT_WIDTH 4'd8\)[\s\S]*\(LANE0 1\)[\s\S]*\(LANE1 0\)/,
        'generated child .fsm embeds imported package constant root');

    my $report = decode_json($scheduler->report($actor));
    is_deeply(
        $report->{generated_composition}{children}[0]{parameters},
        [
            { name => 'WIDTH', default => 'shared.DEFAULT_WIDTH' },
            { name => 'LANES', default => '(shared.LANE0 shared.LANE1)' },
        ],
        'schedule report child parameter summary preserves package-constant defaults',
    );
    is_deeply(
        $report->{generated_composition}{instances}[0]{parameter_bindings},
        [
            { name => 'WIDTH', source => 'default', value => 'shared.DEFAULT_WIDTH' },
            { name => 'LANES', source => 'default', value => '(shared.LANE0 shared.LANE1)' },
        ],
        'schedule report generated instance bindings preserve package-constant defaults',
    );

    my $hdl_path = File::Spec->catfile($dir, 'transaction_package_constant_defaults.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package-constant transaction parameter defaults');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package-constant transaction parameter defaults');
    ok(-s $hdl_path, 'CLI writes HDL for package-constant transaction parameter defaults');
};

subtest 'package constant transaction parameter diagnostics fail closed' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (LANES (1 0))
    (DEFAULT_WIDTH 8))
)
FSM

    assert_lower_file_rejected(
        $dir,
        'unknown_package_constant.isf',
        <<'ISF',
(actor unknown_package_constant
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0))
  (transaction worker
    (params
      (WIDTH shared.MISSING))
    (complete done)))
ISF
        qr/Transaction 'worker': parameter 'WIDTH' references unknown package constant 'shared\.MISSING'/,
        'unknown package constants are rejected',
    );

    assert_lower_file_rejected(
        $dir,
        'unqualified_package_constant.isf',
        <<'ISF',
(actor unqualified_package_constant
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0))
  (transaction worker
    (params
      (WIDTH DEFAULT_WIDTH))
    (complete done)))
ISF
        qr/Transaction 'worker': parameter 'WIDTH' token 'DEFAULT_WIDTH' is not an earlier scalar transaction parameter, declared actor constant, actor scalar parameter, enum member, or qualified package scalar constant/,
        'unqualified package constants are rejected',
    );

    assert_lower_file_rejected(
        $dir,
        'aggregate_package_constant.isf',
        <<'ISF',
(actor aggregate_package_constant
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0))
  (transaction worker
    (params
      (LANE_SET shared.LANES))
    (complete done)))
ISF
        qr/Transaction 'worker': parameter 'LANE_SET' package constant 'shared\.LANES' must resolve to a scalar numeric or exact-width literal value/,
        'aggregate package constants remain deferred as transaction parameter defaults',
    );

    assert_lower_file_rejected(
        $dir,
        'package_constant_leaf_path.isf',
        <<'ISF',
(actor package_constant_leaf_path
  (imports
    (package shared))
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0))
  (transaction worker
    (params
      (LANE shared.LANES[0]))
    (complete done)))
ISF
        qr/Transaction 'worker': parameter 'LANE' package constant 'shared\.LANES' aggregate\/member path 'shared\.LANES\[0\]' remains deferred/,
        'package aggregate constant scalar-leaf paths remain deferred',
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
        'ambiguous_package_constant.isf',
        <<'ISF',
(actor ambiguous_package_constant
  (imports
    (package mode))
  (enums
    (mode (BUSY 1)))
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0))
  (transaction worker
    (params
      (DEFAULT mode.BUSY))
    (complete done)))
ISF
        qr/Transaction 'worker': parameter 'DEFAULT' token 'mode\.BUSY' is ambiguous: it matches local enum member 'mode\.BUSY' and imported package constant 'mode\.BUSY'/,
        'ambiguous local-enum and package-constant tokens are rejected',
    );
};

done_testing();

sub assert_lower_file_rejected {
    my ($dir, $filename, $source, $regex, $label) = @_;
    my $path = File::Spec->catfile($dir, $filename);
    write_file($path, $source);
    my $ok = eval {
        my $actor = FSM::Adapter::ISF->new()->parse_file($path);
        FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
        1;
    };
    ok(!$ok, "$label fails closed");
    like($@, $regex, "$label diagnostic");
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
