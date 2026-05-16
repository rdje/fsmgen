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

subtest 'actor-local aggregate type aliases lower on storage var carriers' => sub {
    my $actor = parse_source(<<'ISF', 'local-aggregate-storage.isf');
(actor local_aggregate_storage
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input frame_in (width 3))
    (output frame_out (width 3)))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (set frame frame_in)
    (set frame_out frame)))
ISF

    my $storage = $actor->{storage}[0];
    is($storage->{width}, 3, 'local record alias resolves packed storage width');
    is($storage->{type}, 'frame_t', 'storage keeps authored type token');
    is($storage->{type_spec}{kind}, 'record', 'storage records resolved aggregate kind privately');
    is_deeply($storage->{type_spec}{member_order}, [qw(mode flag)], 'record member order is preserved');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'local_aggregate_storage.fsm'};
    like($fsm, qr/\(\+types\s+\(type frame_t \(record \(mode \(bits 2\)\) \(flag bit\)\)\)\s+\)/s,
        'scheduled .fsm emits local aggregate +types declaration');
    like($fsm, qr/\(\+size[\s\S]*\(frame_in 3\)[\s\S]*\(frame_out 3\)[\s\S]*\(frame frame_t\)/,
        'scheduled .fsm preserves aggregate type alias in +size review artifact');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    my $frame = entry_by_name($report->{inferred_storage}, 'frame');
    ok($frame, 'schedule report exposes declared aggregate storage carrier');
    is($frame->{kind}, 'register', 'aggregate storage report keeps register kind') if $frame;
    is($frame->{role}, 'actor_storage', 'aggregate storage report keeps actor_storage role') if $frame;
    is($frame->{width}, 3, 'aggregate storage report exposes packed width') if $frame;
    is($frame->{type}, 'frame_t', 'aggregate storage report exposes bounded authored type name') if $frame;
    is($frame->{type_kind}, 'record', 'aggregate storage report exposes bounded type kind') if $frame;
};

subtest 'package aggregate type aliases remain CLI-reachable on storage var carriers' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type frame_t (record (mode (bits 2)) (flag bit))))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_aggregate_storage.isf');
    write_file($isf_path, <<'ISF');
(actor package_aggregate_storage
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input frame_in (width 3))
    (output frame_out (width 3)))
  (storage
    (var frame (type shared.frame_t)))
  (transaction main
    (on start)
    (set frame frame_in)
    (set frame_out frame)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{width}, 3, 'package record alias resolves packed storage width');
    is($actor->{storage}[0]{type_spec}{kind}, 'record', 'package aggregate storage records resolved kind');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_aggregate_storage.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\+size[\s\S]*\(frame shared\.frame_t\)/,
        'scheduled .fsm preserves package-qualified aggregate type alias in +size');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+types[\s\S]*\(type frame_t \(record \(mode \(bits 2\)\) \(flag bit\)\)\)/,
        'scheduled .fsm embeds imported aggregate package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_aggregate_storage.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package aggregate storage alias');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package aggregate storage alias');
    ok(-s $hdl_path, 'CLI writes HDL for package aggregate storage alias');
};

subtest 'aggregate storage carrier diagnostics fail closed outside the slice' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor aggregate_interface_port
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input frame (type frame_t)))
  (transaction main))
ISF
        qr/interface port 'frame' references aggregate type 'frame_t'; this ISF slice accepts aggregate type aliases only on actor-owned storage variables/,
        'aggregate aliases are still rejected on interface ports',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_transaction_port
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start))
  (transaction main
    (ports
      (input payload (type frame_t)))))
ISF
        qr/transaction 'main' port 'payload' references aggregate type 'frame_t'; this ISF slice accepts aggregate type aliases only on actor-owned storage variables/,
        'aggregate aliases are still rejected on transaction ports',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_bank
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start))
  (storage
    (bank frames (type frame_t) (depth 2)))
  (transaction main))
ISF
        qr/storage 'frames' references aggregate type 'frame_t'; this ISF slice accepts aggregate type aliases only on actor-owned storage variables/,
        'aggregate aliases are still rejected on storage banks',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_partial_update
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (set frame.flag 1)))
ISF
        qr/references aggregate storage path 'frame\.flag'; this ISF slice accepts only whole actor-owned aggregate storage carriers, not member\/item access or partial aggregate updates/,
        'partial aggregate updates are deferred',
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

sub entry_by_name {
    my ($items, $name) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$items || []};
    return $entry;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content;
    close $fh or die "close $path: $!";
    return $path;
}
