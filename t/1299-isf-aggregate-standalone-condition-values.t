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

subtest 'actor-local aggregate storage leaves are valid standalone transaction conditions' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_aggregate_standalone_condition.isf');
    write_file($isf_path, <<'ISF');
(actor local_aggregate_standalone_condition
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input frame_in (width 3))
    (output fire)
    (output done))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (set frame frame_in)
    (when frame.flag
      (set fire 1))
    (while frame.flag
      (set fire 0))
    (until frame.flag
      (complete done))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_aggregate_standalone_condition.fsm'};
    my $flag_condition_count = () = $fsm =~ /\(\?\(frame\.flag\)/g;
    cmp_ok($flag_condition_count, '>=', 3,
        'scheduled .fsm uses computed selectors for standalone aggregate leaf conditions');

    my $hdl_path = File::Spec->catfile($dir, 'local_aggregate_standalone_condition.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local standalone aggregate conditions');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local standalone aggregate conditions');
    ok(-s $hdl_path, 'CLI writes HDL for local standalone aggregate conditions');
};

subtest 'package aggregate storage leaves are valid standalone transaction conditions' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type lanes_t (list bit (bits 2))))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_aggregate_standalone_condition.isf');
    write_file($isf_path, <<'ISF');
(actor package_aggregate_standalone_condition
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input lanes_in (width 3))
    (output fire)
    (output done))
  (storage
    (var lanes (type shared.lanes_t)))
  (transaction main
    (on start)
    (set lanes lanes_in)
    (when lanes[0]
      (set fire 1))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_aggregate_standalone_condition.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\?\(lanes\[0\]\)/,
        'scheduled .fsm uses computed selector for package aggregate leaf condition');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+types[\s\S]*\(type lanes_t \(list bit \(bits 2\)\)\)/,
        'scheduled .fsm embeds imported aggregate package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_aggregate_standalone_condition.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package standalone aggregate conditions');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package standalone aggregate conditions');
    ok(-s $hdl_path, 'CLI writes HDL for package standalone aggregate conditions');
};

subtest 'standalone aggregate condition diagnostics stay scalar-leaf-only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor aggregate_standalone_condition_unknown_member
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (when frame.missing
      (complete done))))
ISF
        qr/invalid aggregate storage path 'frame\.missing': record member 'missing' is not declared; known members: mode, flag/,
        'unknown record member standalone condition fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_standalone_condition_subaggregate
  (types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (mode (bits 2)) (payload payload_t))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (when frame.payload
      (complete done))))
ISF
        qr/transaction 'main' when condition references aggregate storage path 'frame\.payload' that resolves to aggregate kind 'list'; this ISF slice accepts only scalar aggregate leaf reads/,
        'subaggregate standalone conditions remain deferred',
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
