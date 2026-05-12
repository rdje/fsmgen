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

subtest 'CLI --outdir writes the scheduled lower-result files' => sub {
    my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'spawn_parent.isf');
    my $outdir = tempdir(CLEANUP => 1);
    my $hdl_output = File::Spec->catfile($outdir, 'spawn_parent.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--quiet',
            '--outdir',
            $outdir,
            '--output',
            $hdl_output,
            $isf_file,
        ],
    );

    ok($success, '--outdir lowering succeeds for a multi-file ISF fixture');
    is(join('', @{$stderr_buf || []}), '', '--outdir lowering keeps stderr clean');
    ok(-f $hdl_output, '--outdir lowering keeps generated HDL in the requested output file');

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    is_deeply(
        sorted([keys %{$lowered->{files}}]),
        [qw(child_worker.fsm spawn_parent.fsm)],
        'fixture lowers to the expected scheduled file set',
    );

    for my $basename (sort keys %{$lowered->{files}}) {
        my $path = File::Spec->catfile($outdir, $basename);
        ok(-f $path, "--outdir writes $basename");
        is(slurp($path), $lowered->{files}{$basename}, "--outdir $basename matches in-process lowering");
    }
};

done_testing();

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
