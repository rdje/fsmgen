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

subtest 'actor-local enum members resolve in actor constants' => sub {
    my $actor = parse_source(<<'ISF', 'local-enum-constant.isf');
(actor local_enum_constant
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (constants
    (BUSY_WAIT mode.BUSY))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (wait BUSY_WAIT)
    (complete done)))
ISF

    is($actor->{constants}[0]{value}, 'mode.BUSY', 'actor constant preserves authored enum member token');
    is($actor->{constants}[0]{resolved_value}, '1', 'actor constant records resolved enum member value');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'local_enum_constant.fsm'};
    like($fsm, qr/\(\+enums\s+\(mode \(IDLE 0\) \(BUSY 1\)\)\s+\)/s,
        'scheduled .fsm preserves local enum declaration');
    like($fsm, qr/\(\+constants\s+\(BUSY_WAIT mode\.BUSY\)\s+\)/s,
        'scheduled .fsm preserves enum-backed actor constant review artifact');
    like($fsm, qr/\(main_wait_1[\s\S]*\(-> main_done_2\)/,
        'enum-backed actor constant resolves for static wait lowering');

    is_deeply(
        decode_json(FSM::Scheduler::ISF->new()->report($actor))->{actor_constants},
        [{ name => 'BUSY_WAIT', value => 'mode.BUSY' }],
        'schedule report preserves authored enum-backed actor constant value',
    );
};

subtest 'package enum members resolve in actor constants and remain CLI-reachable' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_enum_constant.isf');
    write_file($isf_path, <<'ISF');
(actor package_enum_constant
  (imports
    (package shared))
  (constants
    (REMOTE_WAIT shared.mode.BUSY))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (wait REMOTE_WAIT)
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{constants}[0]{value}, 'shared.mode.BUSY', 'package enum constant preserves authored token');
    is($actor->{constants}[0]{resolved_value}, '1', 'package enum constant records resolved value');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_enum_constant.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\+constants\s+\(REMOTE_WAIT shared\.mode\.BUSY\)\s+\)/s,
        'scheduled .fsm preserves package enum-backed constant');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+enums[\s\S]*\(mode \(IDLE 0\) \(BUSY 1\)\)/,
        'scheduled .fsm embeds imported enum package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_constant.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package enum-backed actor constant');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package enum-backed actor constant');
    ok(-s $hdl_path, 'CLI writes HDL for package enum-backed actor constant');
};

subtest 'enum-backed actor constant diagnostics fail closed' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor unknown_local_enum_member
  (enums
    (mode (IDLE 0)))
  (constants
    (BAD mode.BUSY))
  (clock clk)
  (reset rst)
  (interface
    (input start))
  (transaction main))
ISF
        qr/constant 'BAD' references unknown enum member 'mode\.BUSY'/,
        'unknown local enum member',
    );

    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0)))
)
FSM
    my $bad_package_source = File::Spec->catfile($dir, 'bad_package_member.isf');
    write_file($bad_package_source, <<'ISF');
(actor unknown_package_enum_member
  (imports
    (package shared))
  (constants
    (BAD shared.mode.BUSY))
  (clock clk)
  (reset rst)
  (interface
    (input start))
  (transaction main))
ISF
    assert_parse_file_rejected(
        $bad_package_source,
        qr/constant 'BAD' references unknown enum member 'shared\.mode\.BUSY'/,
        'unknown package enum member',
    );

    assert_parse_rejected(
        <<'ISF',
(actor unsupported_constant_symbol
  (constants
    (BAD MODE))
  (clock clk)
  (reset rst)
  (interface
    (input start))
  (transaction main))
ISF
        qr/constant 'BAD' requires a non-negative integer literal value or enum member reference/,
        'unsupported scalar constant symbol',
    );
};

done_testing();

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, $label);
}

sub assert_parse_rejected {
    my ($source, $regex, $label) = @_;
    my $ok = eval {
        parse_source($source, "$label.isf");
        1;
    };
    ok(!$ok, "$label is rejected");
    like($@, $regex, "$label diagnostic");
}

sub assert_parse_file_rejected {
    my ($path, $regex, $label) = @_;
    my $ok = eval {
        FSM::Adapter::ISF->new()->parse_file($path);
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
