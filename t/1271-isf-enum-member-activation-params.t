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

subtest 'actor-local enum members specialize spawn and generated do overrides' => sub {
    my $source = <<'ISF';
(actor local_enum_activation_params
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (MODE mode.BUSY)))
    (do worker
      (params
        (MODE mode.BUSY)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (MODE 0))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'local-enum-activation-params.isf');
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply(
        [ map { $_->{parameter_overrides} } @{$ir->{spawn_instances}} ],
        [
            [ { name => 'MODE', value => '1' } ],
            [ { name => 'MODE', value => '1' } ],
        ],
        'spawn and generated do overrides resolve enum members to literal values before IR publication',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $top_fsm = $scheduler->lower($actor)->{files}{'local_enum_activation_params_top.fsm'};
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(MODE 1\)\s+\)\s+\)/s,
        'spawn generated top applies resolved enum override');
    like($top_fsm, qr/\(\?fsmc:parent_worker_do_0 worker\s+\(params\s+\(MODE 1\)\s+\)\s+\)/s,
        'generated do top applies resolved enum override');

    my $report = decode_json($scheduler->report($actor));
    is_deeply(
        [ map { $_->{parameter_bindings} } @{$report->{generated_composition}{instances}} ],
        [
            [ { name => 'MODE', source => 'override', value => '1' } ],
            [ { name => 'MODE', source => 'override', value => '1' } ],
        ],
        'schedule report exposes resolved enum override values',
    );

    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_enum_activation_params.isf');
    write_file($isf_path, $source);
    my $hdl_path = File::Spec->catfile($dir, 'local_enum_activation_params.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local enum-backed activation overrides');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local enum-backed activation overrides');
    ok(-s $hdl_path, 'CLI writes HDL for local enum-backed activation overrides');
};

subtest 'actor-local enum members specialize parameterized rule triggers' => sub {
    my $source = <<'ISF';
(actor local_enum_trigger_params
  (enums
    (mode (IDLE 0) (BUSY 1)))
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
      (MODE 0))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (MODE mode.BUSY)))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'local-enum-trigger-params.isf');
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply(
        $ir->{spawn_instances}[0]{parameter_overrides},
        [ { name => 'MODE', value => '1' } ],
        'rule-trigger override resolves enum member before generated instance metadata',
    );

    my $top_fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_enum_trigger_params_top.fsm'};
    like($top_fsm, qr/\(\?fsmc:launch_worker_trigger_0 worker\s+\(params\s+\(MODE 1\)\s+\)\s+\)/s,
        'rule-trigger generated top applies resolved enum override');
};

subtest 'package enum members specialize activation parameter overrides' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'package_enum_activation_params.isf');
    write_file($isf_path, <<'ISF');
(actor package_enum_activation_params
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
        (MODE shared.mode.BUSY)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (MODE 0))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply(
        $ir->{spawn_instances}[0]{parameter_overrides},
        [ { name => 'MODE', value => '1' } ],
        'package enum activation override resolves to a literal value',
    );

    my $top_fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_enum_activation_params_top.fsm'};
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(MODE 1\)\s+\)\s+\)/s,
        'generated top applies resolved package enum override');
    unlike($top_fsm, qr/MODE shared\.mode\.BUSY/,
        'generated top does not emit package enum tokens in activation overrides');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_activation_params.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package enum-backed activation overrides');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package enum-backed activation overrides');
    ok(-s $hdl_path, 'CLI writes HDL for package enum-backed activation overrides');
};

subtest 'activation parameter enum diagnostics stay scalar-override only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor unknown_enum_activation_param
  (enums
    (mode (IDLE 0)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (spawn worker as w0
      (params
        (MODE mode.BUSY))))
  (transaction worker
    (params
      (MODE 0))
    (complete done)))
ISF
        qr/transaction 'main' spawn instance 'w0' parameter 'MODE' references unknown enum member 'mode\.BUSY'/,
        'unknown activation enum override fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor enum_activation_param_list_leaf_deferred
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (spawn worker as w0
      (params
        (MODES (mode.BUSY 1)))))
  (transaction worker
    (params
      (MODES (0 0)))
    (complete done)))
ISF
        qr/transaction 'main' spawn instance 'w0' parameter 'MODES' uses unsupported aggregate\/list override leaf 'mode\.BUSY'; activation parameter aggregate\/list overrides accept numeric, exact-width, and actor-constant leaves only, while enum member leaves remain deferred/,
        'enum leaves inside aggregate/list activation overrides remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor enum_trigger_target_still_deferred
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input fire)
    (output done))
  (transaction worker
    (complete done))
  (rule launch fire
    (trigger mode.BUSY)))
ISF
        qr/rule 'launch' triggers unknown transaction 'mode\.BUSY' in actor 'enum_trigger_target_still_deferred'/,
        'enum-looking activation structural operands remain ordinary transaction names',
    );
};

done_testing();

sub assert_parse_rejected {
    my ($source, $regex, $label) = @_;
    my $ok = eval {
        FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
        1;
    };
    ok(!$ok, "$label is rejected");
    like($@, $regex, "$label diagnostic");
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content;
    close $fh or die "close $path: $!";
    return $path;
}
