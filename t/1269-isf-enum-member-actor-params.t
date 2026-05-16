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

subtest 'actor-local enum members are valid scalar actor parameter defaults' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_enum_actor_param.isf');
    write_file($isf_path, <<'ISF');
(actor local_enum_actor_param
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (params
    (DEFAULT_MODE mode.BUSY))
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
    is($actor->{params}[0]{value}, 'mode.BUSY', 'actor parameter preserves authored enum member token');
    is($actor->{params}[0]{resolved_value}, '1', 'actor parameter records resolved enum member value');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $fsm = $scheduler->lower($actor)->{files}{'local_enum_actor_param.fsm'};
    like($fsm, qr/\(\+enums\s+\(mode \(IDLE 0\) \(BUSY 1\)\)\s+\)/s,
        'scheduled .fsm preserves local enum declaration');
    like($fsm, qr/\(\+params\s+\(DEFAULT_MODE mode\.BUSY\)\s+\)/s,
        'scheduled .fsm preserves local enum-backed parameter default');
    is_deeply(
        decode_json($scheduler->report($actor))->{actor_params},
        [{ name => 'DEFAULT_MODE', value => 'mode.BUSY' }],
        'schedule report preserves authored enum-backed actor parameter value',
    );

    my $hdl_path = File::Spec->catfile($dir, 'local_enum_actor_param.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local enum-backed actor parameters');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local enum-backed actor parameters');
    ok(-s $hdl_path, 'CLI writes HDL for local enum-backed actor parameters');
};

subtest 'package enum members are valid scalar actor parameter defaults' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_enum_actor_param.isf');
    write_file($isf_path, <<'ISF');
(actor package_enum_actor_param
  (imports
    (package shared))
  (params
    (DEFAULT_MODE shared.mode.BUSY))
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
    is($actor->{params}[0]{value}, 'shared.mode.BUSY', 'package actor parameter preserves authored enum member token');
    is($actor->{params}[0]{resolved_value}, '1', 'package actor parameter records resolved enum member value');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $fsm = $scheduler->lower($actor)->{files}{'package_enum_actor_param.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\+params\s+\(DEFAULT_MODE shared\.mode\.BUSY\)\s+\)/s,
        'scheduled .fsm preserves package enum-backed parameter default');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+enums[\s\S]*\(mode \(IDLE 0\) \(BUSY 1\)\)/,
        'scheduled .fsm embeds imported enum package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_actor_param.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package enum-backed actor parameters');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package enum-backed actor parameters');
    ok(-s $hdl_path, 'CLI writes HDL for package enum-backed actor parameters');
};

subtest 'actor parameter enum diagnostics stay scalar-default only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor unknown_enum_actor_param
  (enums
    (mode (IDLE 0)))
  (params
    (DEFAULT_MODE mode.BUSY))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF
        qr/actor 'unknown_enum_actor_param' parameter 'DEFAULT_MODE' references unknown enum member 'mode\.BUSY'/,
        'unknown local enum member parameter default fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor enum_actor_param_list_leaf_deferred
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (params
    (DEFAULT_MODES (mode.BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF
        qr/parameter 'DEFAULT_MODES' uses unsupported aggregate\/list parameter leaf 'mode\.BUSY'; actor parameter aggregate\/list defaults accept numeric and exact-width literal leaves only, while enum member leaves remain deferred/,
        'enum leaves inside aggregate/list actor parameters remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor enum_activation_param_aggregate_leaf_still_deferred
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
	    (on start)
	    (spawn child as c0
	      (params
	        (DEFAULT_MODES (mode.BUSY 1)))))
	  (transaction child
	    (params
	      (DEFAULT_MODES (0 1)))
	    (complete done)))
ISF
        qr/transaction 'main' spawn instance 'c0' parameter 'DEFAULT_MODES' uses unsupported aggregate\/list override leaf 'mode\.BUSY'; activation parameter aggregate\/list overrides accept numeric, exact-width, and actor-constant leaves only, while enum member leaves remain deferred/,
        'aggregate/list activation parameter enum override leaves remain deferred',
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
