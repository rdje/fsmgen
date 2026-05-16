#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'actor-local enum members are valid standalone rule guards' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_enum_rule_standalone_guard.isf');
    write_file($isf_path, <<'ISF');
(actor local_enum_rule_standalone_guard
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (output fire))
  (rule fire_when_busy mode.BUSY
    (set fire 1)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my %rule_by_name = map { $_->{name} => $_ } @{$actor->{rules}};
    is_deeply(
        $rule_by_name{fire_when_busy}{when},
        ['when', 'mode.BUSY'],
        'local standalone enum rule guard normalizes into the public when field',
    );

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_enum_rule_standalone_guard.fsm'};
    like($fsm, qr/\(\+enums\s+\(mode \(IDLE 0\) \(BUSY 1\)\)\s+\)/s,
        'scheduled .fsm preserves local enum declaration');
    like($fsm, qr/\(-fire_when_busy\s+<mode\.BUSY\s+\(<- \(fire> 1\)\)\s+\)/s,
        'scheduled .fsm preserves standalone local enum member rule guard');

    my $hdl_path = File::Spec->catfile($dir, 'local_enum_rule_standalone_guard.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local standalone enum rule guards');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local standalone enum rule guards');
    ok(-s $hdl_path, 'CLI writes HDL for local standalone enum rule guards');
};

subtest 'package enum members are valid long-form standalone rule guards' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_enum_rule_standalone_guard.isf');
    write_file($isf_path, <<'ISF');
(actor package_enum_rule_standalone_guard
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (output fire))
  (rule fire_when_busy
    (when shared.mode.BUSY)
    (set fire 1)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my %rule_by_name = map { $_->{name} => $_ } @{$actor->{rules}};
    is_deeply(
        $rule_by_name{fire_when_busy}{when},
        ['when', 'shared.mode.BUSY'],
        'package standalone enum rule guard normalizes into the public when field',
    );

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_enum_rule_standalone_guard.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(-fire_when_busy\s+<shared\.mode\.BUSY\s+\(<- \(fire> 1\)\)\s+\)/s,
        'scheduled .fsm preserves standalone package enum member rule guard');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+enums[\s\S]*\(mode \(IDLE 0\) \(BUSY 1\)\)/,
        'scheduled .fsm embeds imported enum package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_rule_standalone_guard.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package standalone enum rule guards');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package standalone enum rule guards');
    ok(-s $hdl_path, 'CLI writes HDL for package standalone enum rule guards');
};

subtest 'standalone enum rule guard diagnostics stay resolved-member-only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor enum_rule_standalone_guard_unknown_member
  (enums
    (mode (IDLE 0)))
  (clock clk)
  (reset rst)
  (interface
    (output fire))
  (rule fire_when_busy mode.BUSY
    (set fire 1)))
ISF
        qr/rule 'fire_when_busy' guard references unknown enum member 'mode\.BUSY'/,
        'unknown standalone enum rule guard fails before lowering',
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
