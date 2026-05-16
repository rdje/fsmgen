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

subtest 'actor-local aggregate storage leaves are valid transaction switch selectors' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_aggregate_switch_selector.isf');
    write_file($isf_path, <<'ISF');
(actor local_aggregate_switch_selector
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input frame_in (width 3))
    (output seen)
    (output done))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (set frame frame_in)
    (switch frame.mode
      (1
        (set seen 1))
      (default
        (set seen 0)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{type_spec}{kind}, 'record', 'record carrier type resolves before switch selector validation');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_aggregate_switch_selector.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(frame frame_t\)/,
        'scheduled .fsm preserves aggregate carrier type');
    like($fsm, qr/\(\?\(frame\.mode\)\s+.*?\(=1 \(-> main_set_\d+\)\)/s,
        'scheduled .fsm emits record member switch selector through computed selector syntax');

    my $hdl_path = File::Spec->catfile($dir, 'local_aggregate_switch_selector.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local aggregate switch selectors');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local aggregate switch selectors');
    ok(-s $hdl_path, 'CLI writes HDL for local aggregate switch selectors');
};

subtest 'package aggregate storage leaves are valid transaction switch selectors' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type lanes_t (list bit (bits 2))))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_aggregate_switch_selector.isf');
    write_file($isf_path, <<'ISF');
(actor package_aggregate_switch_selector
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input lanes_in (width 3))
    (output seen)
    (output done))
  (storage
    (var lanes (type shared.lanes_t)))
  (transaction main
    (on start)
    (set lanes lanes_in)
    (switch lanes[1]
      (2
        (set seen 1))
      (default
        (set seen 0)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{type_spec}{kind}, 'list', 'package list carrier type resolves before switch selector validation');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_aggregate_switch_selector.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\?\(lanes\[1\]\)\s+.*?\(=2 \(-> main_set_\d+\)\)/s,
        'scheduled .fsm emits package list item switch selector through computed selector syntax');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+types[\s\S]*\(type lanes_t \(list bit \(bits 2\)\)\)/,
        'scheduled .fsm embeds imported aggregate package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_aggregate_switch_selector.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package aggregate switch selectors');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package aggregate switch selectors');
    ok(-s $hdl_path, 'CLI writes HDL for package aggregate switch selectors');
};

subtest 'switch aggregate selector diagnostics stay scalar-leaf only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor aggregate_switch_selector_unknown_member
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output seen))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (switch frame.missing
      (1
        (set seen 1)))))
ISF
        qr/transaction 'main' switch selector references invalid aggregate storage path 'frame\.missing': record member 'missing' is not declared; known members: mode, flag/,
        'unknown record member switch selector fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_switch_selector_subaggregate_value
  (types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (mode (bits 2)) (payload payload_t))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output seen))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (switch frame.payload
      (1
        (set seen 1)))))
ISF
        qr/transaction 'main' switch selector references aggregate storage path 'frame\.payload' that resolves to aggregate kind 'list'; this ISF slice accepts only scalar aggregate leaf reads/,
        'subaggregate switch selectors remain deferred',
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
