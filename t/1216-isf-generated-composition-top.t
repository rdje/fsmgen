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

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'spawn fixture lowers a generated composition top with drive handoff wiring' => sub {
    my $lowered = lower_fixture('spawn_parent.isf');
    my $top_fsm = $lowered->{files}{'spawn_parent_top.fsm'};
    my $parent_fsm = $lowered->{files}{'spawn_parent.fsm'};
    my $child_fsm = $lowered->{files}{'child_worker.fsm'};

    ok(defined($top_fsm), 'lowering emits generated top .fsm');
    like($top_fsm, qr/\A\(\?top:spawn_parent_top\b/, 'generated top is a composition root');
    like($top_fsm, qr/\(\?fsmc:spawn_parent spawn_parent\)/, 'generated top instantiates the parent');
    like($top_fsm, qr/\(\?fsmc:w0 child_worker\)/, 'generated top instantiates the first spawned child');
    like($top_fsm, qr{/spawn_parent\.w0_start/w0\.start/}, 'top wires parent start output to child start input');
    like($top_fsm, qr{/w0\.done/spawn_parent\.w0_done/}, 'top wires child done output to parent done input');
    like($top_fsm, qr{/w0\.rdata_start/spawn_parent\.w0_rdata_start/}, 'top wires child drive request to parent per-instance input');
    like($top_fsm, qr{/w0\.rdata_val/spawn_parent\.w0_rdata_val/}, 'top wires child drive payload to parent per-instance input');
    like($top_fsm, qr{/trigger/w0\.trigger/}, 'top fans public actor inputs into spawned children');

    like($parent_fsm, qr/\(w0_rdata_start 1\)/, 'parent declares per-instance drive request input width');
    like($parent_fsm, qr/\(w0_rdata_val 32\)/, 'parent declares per-instance drive payload input width');
    like($parent_fsm, qr/\(-rdata\s+.*\(<- \(rdata> w0_rdata_val\) <w0_rdata_start\).*<-\s+\(rdata> w1_rdata_val\) <w1_rdata_start/s, 'parent drive DT aggregates child drive handoffs');

    like($child_fsm, qr/\(rdata_start 1\)/, 'child declares drive request handoff width');
    like($child_fsm, qr/\(rdata_val 32\)/, 'child declares drive payload handoff width');
    like($child_fsm, qr/\(= \(rdata_start> 1\)\)/, 'child exposes drive request as an output');
    like($child_fsm, qr/\(= \(rdata_val> val\)\)/, 'child exposes drive payload as an output');
    unlike($child_fsm, qr/\n\s+\(rdata 32\)\n/, 'child does not expose the actor data output directly');
};

subtest 'CLI compiles generated top through the normal composition pipeline' => sub {
    my $isf_file = File::Spec->catfile($repo_root, 'isf', 'spawn_parent.isf');
    my $outdir = tempdir(CLEANUP => 1);
    my $output = File::Spec->catfile($outdir, 'spawn_parent.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--quiet',
            '--outdir',
            $outdir,
            '--output',
            $output,
            $isf_file,
        ],
    );

    ok($success, 'CLI generation succeeds from the .isf source');
    is(join('', @{$stderr_buf || []}), '', 'CLI generation keeps stderr empty');
    ok(-f File::Spec->catfile($outdir, 'spawn_parent_top.fsm'), 'CLI writes generated top .fsm');
    ok(-f $output, 'CLI writes generated top HDL output');

    my $hdl = slurp($output);
    like($hdl, qr/\bmodule\s+spawn_parent_top\b/, 'HDL contains generated top module');
    like($hdl, qr/spawn_parent spawn_parent \([\s\S]*?\.w0_rdata_start\(comp_link_w0_rdata_start\)/, 'parent instance consumes per-instance drive request');
    like($hdl, qr/child_worker w0 \([\s\S]*?\.rdata_start\(comp_link_w0_rdata_start\)/, 'child instance produces per-instance drive request');
};

done_testing();

sub lower_fixture {
    my ($fixture) = @_;
    my $path = File::Spec->catfile($repo_root, 'isf', $fixture);
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}
