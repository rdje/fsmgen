#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;

subtest 'depth-4 FIFO controller interface and matrix lower through HDL' => sub {
    my $fixture = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'fifo_controller.isf');
    my $actor = FSM::Adapter::ISF->new()->parse_file($fixture);

    is_deeply(
        [map { $_->{name} } @{$actor->{interface}{inputs}}],
        [qw(write_req data_in read_req)],
        'FIFO interface exposes only write request, write data, and read request as inputs',
    );
    is_deeply(
        [map { $_->{name} } @{$actor->{interface}{outputs}}],
        [qw(full empty data_out)],
        'FIFO interface exposes actor-maintained full/empty and read data as outputs',
    );
    is((grep { $_->{kind} eq 'var' } @{$actor->{storage}}), 3, 'FIFO scalar storage is authored as var');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply($ir->{conflict_issues}, [], 'same-cycle FIFO matrix has no conflict issues');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'fifo_update_matrix.fsm'};
    ok(defined($fsm), 'scheduler emits the FIFO matrix .fsm');

    like(
        $fsm,
        qr/\(-idle_occ0\s+<\(& \(! write_req\) \(! read_req\) \(== occupancy 0\)\)[\s\S]*\(<- \(empty> 1\)\)[\s\S]*\(<- \(full> 0\)\)/,
        'occupancy 0 drives empty=1 and full=0',
    );
    like(
        $fsm,
        qr/\(-idle_occ4\s+<\(& \(! write_req\) \(! read_req\) \(== occupancy 4\)\)[\s\S]*\(<- \(empty> 0\)\)[\s\S]*\(<- \(full> 1\)\)/,
        'occupancy 4 drives empty=0 and full=1',
    );
    like(
        $fsm,
        qr/\(-push_only_occ3\s+<\(& write_req \(! read_req\) \(== occupancy 3\)\)[\s\S]*\(<- \(occupancy 4\)\)[\s\S]*\(<- \(full> 1\)\)/,
        'push-only from occupancy 3 reaches full occupancy',
    );
    like(
        $fsm,
        qr/\(-pop_only_occ1\s+<\(& \(! write_req\) read_req \(== occupancy 1\)\)[\s\S]*\(<- \(occupancy 0\)\)[\s\S]*\(<- \(empty> 1\)\)/,
        'pop-only from occupancy 1 reaches empty occupancy',
    );
    like(
        $fsm,
        qr/\(-push_pop_occ4\s+<\(& write_req read_req \(== occupancy 4\)\)[\s\S]*\(<- \(occupancy 4\)\)[\s\S]*\(<- \(full> 1\)\)/,
        'push+pop from full preserves full occupancy',
    );
    like(
        $fsm,
        qr/\(-write_at_3\s+<\(& write_req \(\| \(! \(== occupancy 4\)\) read_req\) \(== wr_ptr 3\)\)[\s\S]*\(<- \(wr_ptr 0\)\)/,
        'write pointer wraps from entry 3 to entry 0',
    );
    like(
        $fsm,
        qr/\(-read_from_3\s+<\(& read_req \(! \(== occupancy 0\)\) \(== rd_ptr 3\)\)[\s\S]*\(<- \(rd_ptr 0\)\)/,
        'read pointer wraps from entry 3 to entry 0',
    );
    unlike($fsm, qr/\bdata_0\b/, 'controller matrix does not invent scalarized FIFO data-bank storage');

    my $report = decode_json($scheduler->report($actor));
    is($report->{inputs}, 3, 'schedule report counts only the three FIFO inputs');
    is($report->{outputs}, 3, 'schedule report counts only the three FIFO outputs');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');
    assert_actor_storage($report, 'wr_ptr', 2);
    assert_actor_storage($report, 'rd_ptr', 2);
    assert_actor_storage($report, 'occupancy', 3);

    assert_fsm_reaches_hdl($fsm, 'fifo_update_matrix');
};

done_testing();

sub assert_actor_storage {
    my ($report, $name, $width) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$report->{inferred_storage} || []};

    ok($entry, "schedule report includes actor storage '$name'");
    is($entry->{role}, 'actor_storage', "actor storage '$name' reports actor_storage role") if $entry;
    is($entry->{width}, $width, "actor storage '$name' reports width") if $entry;
}

sub assert_fsm_reaches_hdl {
    my ($fsm, $module_name) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, "$module_name.fsm");
    write_file($fsm_path, $fsm);

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file    => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast     => $raw_ast,
        debug_level => 0,
    );
    ok($fsm_module, 'FIFO matrix scheduled .fsm parses through the normal .fsm frontend');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bmodule\s+\Q$module_name\E\b/, 'FIFO matrix scheduled .fsm reaches HDL generation');
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
