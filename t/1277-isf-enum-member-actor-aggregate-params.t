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

subtest 'actor-local enum members are valid actor aggregate parameter leaves' => sub {
    my $source = <<'ISF';
(actor local_enum_actor_aggregate_param
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (params
    (DEFAULT_MODES (mode.BUSY mode.IDLE)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'local-enum-actor-aggregate-param.isf');
    is_deeply($actor->{params}[0]{value}, [ 'mode.BUSY', 'mode.IDLE' ],
        'actor parameter preserves authored local enum aggregate leaves');
    is_deeply($actor->{params}[0]{resolved_value}, [ '1', '0' ],
        'actor parameter records resolved local enum aggregate leaves');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply($ir->{params}[0]{value}, [ 'mode.BUSY', 'mode.IDLE' ],
        'lowering IR preserves authored local enum aggregate leaves');
    is_deeply($ir->{params}[0]{resolved_value}, [ '1', '0' ],
        'lowering IR records resolved local enum aggregate leaves');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $fsm = $scheduler->lower($actor)->{files}{'local_enum_actor_aggregate_param.fsm'};
    like($fsm, qr/\(\+params\s+\(DEFAULT_MODES \(mode\.BUSY mode\.IDLE\)\)\s+\)/s,
        'scheduled .fsm preserves local enum aggregate parameter default');
    is_deeply(
        decode_json($scheduler->report($actor))->{actor_params},
        [{ name => 'DEFAULT_MODES', value => [ 'mode.BUSY', 'mode.IDLE' ] }],
        'schedule report preserves authored local enum aggregate parameter default',
    );

    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_enum_actor_aggregate_param.isf');
    write_file($isf_path, $source);
    my $hdl_path = File::Spec->catfile($dir, 'local_enum_actor_aggregate_param.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local enum aggregate actor parameters');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local enum aggregate actor parameters');
    ok(-s $hdl_path, 'CLI writes HDL for local enum aggregate actor parameters');
};

subtest 'package enum members are valid actor aggregate parameter leaves' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'package_enum_actor_aggregate_param.isf');
    write_file($isf_path, <<'ISF');
(actor package_enum_actor_aggregate_param
  (imports
    (package shared))
  (params
    (DEFAULT_MODES (shared.mode.BUSY shared.mode.IDLE)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is_deeply($actor->{params}[0]{value}, [ 'shared.mode.BUSY', 'shared.mode.IDLE' ],
        'actor parameter preserves authored package enum aggregate leaves');
    is_deeply($actor->{params}[0]{resolved_value}, [ '1', '0' ],
        'actor parameter records resolved package enum aggregate leaves');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_enum_actor_aggregate_param.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\+params\s+\(DEFAULT_MODES \(shared\.mode\.BUSY shared\.mode\.IDLE\)\)\s+\)/s,
        'scheduled .fsm preserves package enum aggregate parameter default');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+enums[\s\S]*\(mode \(IDLE 0\) \(BUSY 1\)\)/,
        'scheduled .fsm embeds imported enum package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_actor_aggregate_param.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package enum aggregate actor parameters');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package enum aggregate actor parameters');
    ok(-s $hdl_path, 'CLI writes HDL for package enum aggregate actor parameters');
};

subtest 'actor aggregate parameter enum diagnostics remain bounded' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor unknown_enum_actor_aggregate_param
  (enums
    (mode (IDLE 0)))
  (params
    (DEFAULT_MODES (mode.BUSY 0)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF
        qr/actor 'unknown_enum_actor_aggregate_param' parameter 'DEFAULT_MODES' references unknown enum member 'mode\.BUSY'/,
        'unknown aggregate actor parameter enum leaf fails before lowering',
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
