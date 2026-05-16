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

subtest 'actor-local enum members specialize aggregate activation overrides' => sub {
    my $source = <<'ISF';
(actor local_enum_activation_aggregate_params
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
        (MODES (mode.BUSY mode.IDLE))))
    (do worker
      (params
        (MODES (mode.IDLE mode.BUSY))))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (MODES (0 0)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'local-enum-activation-aggregate-params.isf');
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply(
        [ map { $_->{parameter_overrides} } @{$ir->{spawn_instances}} ],
        [
            [ { name => 'MODES', value => [ '1', '0' ] } ],
            [ { name => 'MODES', value => [ '0', '1' ] } ],
        ],
        'spawn and generated do aggregate overrides resolve enum leaves before IR publication',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $top_fsm = $scheduler->lower($actor)->{files}{'local_enum_activation_aggregate_params_top.fsm'};
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(MODES \(1 0\)\)\s+\)\s+\)/s,
        'spawn generated top applies resolved aggregate enum leaves');
    like($top_fsm, qr/\(\?fsmc:parent_worker_do_0 worker\s+\(params\s+\(MODES \(0 1\)\)\s+\)\s+\)/s,
        'generated do top applies resolved aggregate enum leaves');

    my $report = decode_json($scheduler->report($actor));
    is_deeply(
        [ map { $_->{parameter_bindings} } @{$report->{generated_composition}{instances}} ],
        [
            [ { name => 'MODES', source => 'override', value => '(1 0)' } ],
            [ { name => 'MODES', source => 'override', value => '(0 1)' } ],
        ],
        'schedule report exposes resolved aggregate enum override leaves',
    );

    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_enum_activation_aggregate_params.isf');
    write_file($isf_path, $source);
    my $hdl_path = File::Spec->catfile($dir, 'local_enum_activation_aggregate_params.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local enum aggregate activation overrides');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local enum aggregate activation overrides');
    ok(-s $hdl_path, 'CLI writes HDL for local enum aggregate activation overrides');
};

subtest 'package enum members specialize aggregate activation overrides' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'package_enum_activation_aggregate_params.isf');
    write_file($isf_path, <<'ISF');
(actor package_enum_activation_aggregate_params
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
        (MODES (shared.mode.BUSY shared.mode.IDLE))))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (MODES (0 0)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply(
        $ir->{spawn_instances}[0]{parameter_overrides},
        [ { name => 'MODES', value => [ '1', '0' ] } ],
        'package enum aggregate activation override leaves resolve to literal values',
    );

    my $top_fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_enum_activation_aggregate_params_top.fsm'};
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(MODES \(1 0\)\)\s+\)\s+\)/s,
        'generated top applies resolved package aggregate enum leaves');
    unlike($top_fsm, qr/shared\.mode\./,
        'generated top does not emit package enum tokens in activation aggregate overrides');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_activation_aggregate_params.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package enum aggregate activation overrides');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package enum aggregate activation overrides');
    ok(-s $hdl_path, 'CLI writes HDL for package enum aggregate activation overrides');
};

subtest 'aggregate activation override enum diagnostics remain bounded' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor unknown_enum_activation_aggregate_param
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
        (MODES (mode.BUSY 0)))))
  (transaction worker
    (params
      (MODES (0 0)))
    (complete done)))
ISF
        qr/transaction 'main' spawn instance 'w0' parameter 'MODES' references unknown enum member 'mode\.BUSY'/,
        'unknown aggregate activation enum leaf fails before lowering',
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
