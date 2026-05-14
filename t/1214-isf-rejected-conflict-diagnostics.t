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

my $source = <<'ISF';
(actor conflicting_rules
  (clock clk)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (transaction main
    (on start)
    (complete done))
  (rule r0 a
    (valid 1))
  (rule r1 b
    (valid 0)))
ISF

subtest 'in-process scheduler rejects provable rule conflicts with targeted diagnostic' => sub {
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'conflicting-rules.isf');
    my $scheduler = FSM::Scheduler::ISF->new();

    assert_conflict_diagnostic(
        sub { $scheduler->lower($actor) },
        'in-process lower(...)',
    );
    assert_conflict_diagnostic(
        sub { $scheduler->report($actor) },
        'in-process report(...)',
    );
};

subtest 'CLI schedule-report path rejects provable rule conflicts with targeted diagnostic' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'conflicting_rules.isf');

    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $source;
    close $fh or die "cannot close $path: $!";

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok(!$success, 'CLI schedule-report command fails closed');
    is(join('', @{$stdout_buf || []}), '', 'CLI does not emit successful schedule JSON on rejected conflict');
    assert_conflict_text(join('', @{$stderr_buf || []}), 'CLI diagnostic');
};

done_testing();

sub assert_conflict_diagnostic {
    my ($code, $label) = @_;
    my $ok = eval { $code->(); 1 };
    my $diagnostic = $@;

    ok(!$ok, "$label fails closed");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    assert_conflict_text($diagnostic, "$label diagnostic");
}

sub assert_conflict_text {
    my ($diagnostic, $label) = @_;

    like(
        $diagnostic,
        qr/ISF conflict 'isf_conflicting_rule_writes' on target 'valid'/,
        "$label names stable code and target",
    );
    like(
        $diagnostic,
        qr/overlapping rule data writes select different values/,
        "$label explains the conflict reason",
    );
    like(
        $diagnostic,
        qr/rule 'r0'.*rule_action.*<- 1/s,
        "$label names first conflicting owner and value",
    );
    like(
        $diagnostic,
        qr/rule 'r1'.*rule_action.*<- 0/s,
        "$label names second conflicting owner and value",
    );
}
