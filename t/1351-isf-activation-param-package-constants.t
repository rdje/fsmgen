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

subtest 'package scalar constants specialize generated activation overrides' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (DEFAULT_WIDTH 4'd8)
    (LANE0 1)
    (LANE1 0))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'activation_package_constant_overrides.isf');
    write_file($isf_path, <<'ISF');
(actor activation_package_constant_overrides
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WIDTH shared.DEFAULT_WIDTH)
        (LANES (shared.LANE0 shared.LANE1))))
    (do worker
      (params
        (WIDTH shared.DEFAULT_WIDTH)
        (LANES (shared.LANE1 shared.LANE0))))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8)
      (LANES (0 0)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply(
        [ map { $_->{parameter_overrides} } @{$ir->{spawn_instances}} ],
        [
            [
                { name => 'WIDTH', value => "4'd8" },
                { name => 'LANES', value => [ '1', '0' ] },
            ],
            [
                { name => 'WIDTH', value => "4'd8" },
                { name => 'LANES', value => [ '0', '1' ] },
            ],
        ],
        'spawn and generated do overrides resolve package constants before IR publication',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $top_fsm = $lowered->{files}{'activation_package_constant_overrides_top.fsm'};
    ok(defined($top_fsm), 'generated top is emitted for package-constant overrides');
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 4'd8\)\s+\(LANES \(1 0\)\)\s+\)\s+\)/s,
        'spawn generated top applies resolved package-constant overrides');
    like($top_fsm, qr/\(\?fsmc:parent_worker_do_0 worker\s+\(params\s+\(WIDTH 4'd8\)\s+\(LANES \(0 1\)\)\s+\)\s+\)/s,
        'generated do top applies resolved package-constant overrides');
    unlike($top_fsm, qr/shared\./,
        'generated top does not emit package constant tokens in activation overrides');

    my $report = decode_json($scheduler->report($actor));
    is_deeply(
        [ map { $_->{parameter_bindings} } @{$report->{generated_composition}{instances}} ],
        [
            [
                { name => 'WIDTH', source => 'override', value => "4'd8" },
                { name => 'LANES', source => 'override', value => '(1 0)' },
            ],
            [
                { name => 'WIDTH', source => 'override', value => "4'd8" },
                { name => 'LANES', source => 'override', value => '(0 1)' },
            ],
        ],
        'schedule report exposes resolved package-constant literal override values',
    );

    my $hdl_path = File::Spec->catfile($dir, 'activation_package_constant_overrides.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package-constant activation overrides');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package-constant activation overrides');
    ok(-s $hdl_path, 'CLI writes HDL for package-constant activation overrides');
};

subtest 'package scalar constants specialize rule-trigger overrides' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (DEFAULT_WIDTH 4'd8))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'trigger_package_constant_overrides.isf');
    write_file($isf_path, <<'ISF');
(actor trigger_package_constant_overrides
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input fire)
    (output done))
  (transaction parent
    (on fire)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (WIDTH shared.DEFAULT_WIDTH)))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply(
        $ir->{spawn_instances}[0]{parameter_overrides},
        [ { name => 'WIDTH', value => "4'd8" } ],
        'rule-trigger override resolves package constant before generated instance metadata',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $top_fsm = $scheduler->lower($actor)->{files}{'trigger_package_constant_overrides_top.fsm'};
    like($top_fsm, qr/\(\?fsmc:launch_worker_trigger_0 worker\s+\(params\s+\(WIDTH 4'd8\)\s+\)\s+\)/s,
        'rule-trigger generated top applies resolved package-constant override');

    my $report = decode_json($scheduler->report($actor));
    is_deeply(
        $report->{generated_composition}{instances}[0]{parameter_bindings},
        [ { name => 'WIDTH', source => 'override', value => "4'd8" } ],
        'rule-trigger report exposes resolved package-constant literal override value',
    );
};

subtest 'package constant activation override diagnostics fail closed' => sub {
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
    (spawn worker as w0
      (params
        (WIDTH shared.MISSING))))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' parameter 'WIDTH' references unknown package constant 'shared\.MISSING'/,
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
    (spawn worker as w0
      (params
        (WIDTH DEFAULT_WIDTH))))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' parameter 'WIDTH' uses unsupported parameter value 'DEFAULT_WIDTH'/,
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
    (spawn worker as w0
      (params
        (LANE_SET shared.LANES))))
  (transaction worker
    (params
      (LANE_SET (0 0)))
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' parameter 'LANE_SET' package constant 'shared\.LANES' must resolve to a scalar numeric or exact-width literal value/,
        'aggregate package constants remain deferred as activation overrides',
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
    (spawn worker as w0
      (params
        (LANE shared.LANES[0]))))
  (transaction worker
    (params
      (LANE 0))
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' parameter 'LANE' package constant 'shared\.LANES' aggregate\/member path 'shared\.LANES\[0\]' remains deferred/,
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
    (spawn worker as w0
      (params
        (MODE mode.BUSY))))
  (transaction worker
    (params
      (MODE 0))
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' parameter 'MODE' token 'mode\.BUSY' is ambiguous: it matches local enum member 'mode\.BUSY' and imported package constant 'mode\.BUSY'/,
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
