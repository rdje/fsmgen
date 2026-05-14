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

subtest 'actor-owned storage declarations lower to deterministic scalar storage' => sub {
    my $source = storage_fixture_source();
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'storage-fixture.isf');

    ok(ref($actor->{storage}) eq 'ARRAY', 'parser returns actor storage array');
    is(scalar(@{$actor->{storage}}), 4, 'parser records three registers and one bank');

    my ($bank) = grep { $_->{kind} eq 'bank' && $_->{name} eq 'data' } @{$actor->{storage}};
    ok($bank, 'parser records the data storage bank');
    is($bank->{depth}, 4, 'bank records depth 4');
    is_deeply(
        [map { $_->{name} } @{$bank->{signals}}],
        [qw(data_0 data_1 data_2 data_3)],
        'bank scalarizes to deterministic element names',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'storage_fixture.fsm'};
    ok(defined($fsm), 'scheduler emits the storage fixture .fsm');
    like($fsm, qr/\(\+size[\s\S]*\(rd_ptr 2\)/, 'scheduled .fsm declares rd_ptr width');
    like($fsm, qr/\(\+size[\s\S]*\(wr_ptr 2\)/, 'scheduled .fsm declares wr_ptr width');
    like($fsm, qr/\(\+size[\s\S]*\(occupancy 3\)/, 'scheduled .fsm declares occupancy width');
    like($fsm, qr/\(\+size[\s\S]*\(data_0 8\)[\s\S]*\(data_3 8\)/, 'scheduled .fsm declares all scalarized bank elements');
    like($fsm, qr/\(<- \(data_0 wdata\)\)/, 'scheduled .fsm can assign a scalarized bank element');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    assert_actor_storage($report, 'rd_ptr', 2);
    assert_actor_storage($report, 'wr_ptr', 2);
    assert_actor_storage($report, 'occupancy', 3);
    assert_actor_storage($report, 'data_0', 8);
    assert_actor_storage($report, 'data_3', 8);
};

subtest 'actor-owned storage declarations reach SystemVerilog generation' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'storage_fixture.isf');
    my $output = File::Spec->catfile($dir, 'storage_fixture.sv');
    write_file($path, storage_fixture_source());

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--quiet',
            '--outdir',
            $dir,
            '--output',
            $output,
            $path,
        ],
    );

    ok($success, 'CLI generation succeeds for actor-owned storage declarations')
        or diag(join('', @{$full_buf || []}) || $error_message || 'no command output');
    is(join('', @{$stderr_buf || []}), '', 'CLI generation keeps stderr empty');
    ok(-f $output, 'CLI writes generated HDL');

    my $hdl = slurp($output);
    like($hdl, qr/\bmodule\s+storage_fixture\b/, 'generated HDL contains the storage fixture module');
    like($hdl, qr/\bdata_0\b/, 'generated HDL contains scalarized bank element data_0');
    like($hdl, qr/\bdata_3\b/, 'generated HDL contains scalarized bank element data_3');
    like($hdl, qr/\bwr_ptr\b/, 'generated HDL contains declared write pointer storage');
    like($hdl, qr/\boccupancy\b/, 'generated HDL contains declared occupancy storage');
};

subtest 'actor-owned storage declarations fail closed for unsupported shapes' => sub {
    assert_parse_rejected(<<'ISF', qr/storage bank 'data' requires '\(depth N\)'/, 'bank without depth is rejected');
(actor bad_bank
  (clock clk)
  (interface (input start) (output done))
  (storage
    (bank data (width 8)))
  (transaction main
    (on start)
    (complete done)))
ISF

    assert_parse_rejected(<<'ISF', qr/storage signal 'rd_ptr' conflicts with interface input port 'rd_ptr'/, 'storage cannot reuse an interface port name');
(actor storage_port_conflict
  (clock clk)
  (interface (input start) (input rd_ptr) (output done))
  (storage
    (register rd_ptr (width 2)))
  (transaction main
    (on start)
    (complete done)))
ISF

    assert_parse_rejected(<<'ISF', qr/lowers to duplicate signal 'data_0'/, 'scalarized storage element names must be unique');
(actor storage_duplicate_scalar
  (clock clk)
  (interface (input start) (output done))
  (storage
    (register data_0 (width 8))
    (bank data (width 8) (depth 4)))
  (transaction main
    (on start)
    (complete done)))
ISF

    assert_parse_rejected(<<'ISF', qr/duplicate actor clause 'storage'/, 'storage is a singleton actor clause');
(actor duplicate_storage
  (clock clk)
  (interface (input start) (output done))
  (storage
    (register rd_ptr (width 2)))
  (storage
    (register wr_ptr (width 2)))
  (transaction main
    (on start)
    (complete done)))
ISF
};

done_testing();

sub storage_fixture_source {
    return <<'ISF';
(actor storage_fixture
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input wdata (width 8))
    (output done))
  (storage
    (register rd_ptr (width 2))
    (register wr_ptr (width 2))
    (register occupancy (width 3))
    (bank data (width 8) (depth 4)))
  (transaction main
    (on start)
    (update data_0 wdata)
    (update data_1 wdata)
    (update data_2 wdata)
    (update data_3 wdata)
    (update wr_ptr (+ wr_ptr 1))
    (update occupancy (+ occupancy 1))
    (complete done)))
ISF
}

sub assert_actor_storage {
    my ($report, $name, $width) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$report->{inferred_storage} || []};

    ok($entry, "schedule report includes actor storage '$name'");
    is($entry->{kind}, 'register', "actor storage '$name' reports register kind") if $entry;
    is($entry->{role}, 'actor_storage', "actor storage '$name' reports actor_storage role") if $entry;
    is($entry->{width}, $width, "actor storage '$name' reports width") if $entry;
}

sub assert_parse_rejected {
    my ($source, $diagnostic_re, $label) = @_;
    my $ok = eval {
        FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, $label);
    like($diagnostic, $diagnostic_re, "$label diagnostic");
}

sub write_file {
    my ($path, $source) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $source;
    close $fh or die "cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}
