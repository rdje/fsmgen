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

subtest 'actor-local enum members are valid scalar transaction parameter defaults' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_enum_transaction_param.isf');
    write_file($isf_path, <<'ISF');
(actor local_enum_transaction_param
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (DEFAULT_MODE mode.BUSY))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is($ir->{children}{worker}{params}[0]{value}, 'mode.BUSY',
        'child transaction parameter preserves authored enum member token');
    is($ir->{children}{worker}{params}[0]{resolved_value}, '1',
        'child transaction parameter records resolved enum member value');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    like($child_fsm, qr/\(\+enums\s+\(mode \(IDLE 0\) \(BUSY 1\)\)\s+\)/s,
        'generated child .fsm preserves local enum declaration');
    like($child_fsm, qr/\(\+params\s+\(DEFAULT_MODE mode\.BUSY\)\s+\)/s,
        'generated child .fsm preserves local enum-backed transaction parameter default');

    my $report = decode_json($scheduler->report($actor));
    is_deeply(
        $report->{generated_composition}{children}[0]{parameters},
        [{ name => 'DEFAULT_MODE', default => 'mode.BUSY' }],
        'schedule report child parameter summary preserves authored enum default',
    );
    is_deeply(
        $report->{generated_composition}{instances}[0]{parameter_bindings},
        [{ name => 'DEFAULT_MODE', source => 'default', value => 'mode.BUSY' }],
        'schedule report instance binding preserves enum-backed default source',
    );

    my $hdl_path = File::Spec->catfile($dir, 'local_enum_transaction_param.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local enum-backed transaction parameters');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local enum-backed transaction parameters');
    ok(-s $hdl_path, 'CLI writes HDL for local enum-backed transaction parameters');
};

subtest 'package enum members are valid scalar transaction parameter defaults' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'package_enum_transaction_param.isf');
    write_file($isf_path, <<'ISF');
(actor package_enum_transaction_param
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (DEFAULT_MODE shared.mode.BUSY))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is($ir->{children}{worker}{params}[0]{value}, 'shared.mode.BUSY',
        'package child transaction parameter preserves authored enum member token');
    is($ir->{children}{worker}{params}[0]{resolved_value}, '1',
        'package child transaction parameter records resolved enum member value');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    like($child_fsm, qr/\(\+import\s+shared\s+\)/s,
        'generated child .fsm emits package import');
    like($child_fsm, qr/\(\+params\s+\(DEFAULT_MODE shared\.mode\.BUSY\)\s+\)/s,
        'generated child .fsm preserves package enum-backed transaction parameter default');
    like($child_fsm, qr/\(\?pkg:shared[\s\S]*\(\+enums[\s\S]*\(mode \(IDLE 0\) \(BUSY 1\)\)/,
        'generated child .fsm embeds imported enum package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_transaction_param.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package enum-backed transaction parameters');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package enum-backed transaction parameters');
    ok(-s $hdl_path, 'CLI writes HDL for package enum-backed transaction parameters');
};

subtest 'transaction parameter enum diagnostics stay scalar-default only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor unknown_enum_transaction_param
  (enums
    (mode (IDLE 0)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (spawn worker as w0))
  (transaction worker
    (params
      (DEFAULT_MODE mode.BUSY))
    (complete done)))
ISF
        qr/transaction 'worker' parameter 'DEFAULT_MODE' references unknown enum member 'mode\.BUSY'/,
        'unknown local enum member transaction parameter default fails before lowering',
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
