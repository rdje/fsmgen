#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

subtest 'CLI --strict remains accepted for ISF HDL generation' => sub {
    my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $outdir = tempdir(CLEANUP => 1);
    my $hdl_output = File::Spec->catfile($outdir, 'apb_requester_strict.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--output',
            $hdl_output,
            $isf_file,
        ],
    );

    ok($success, '--strict file.isf CLI generation succeeds for the APB fixture');
    is(join('', @{$stderr_buf || []}), '', '--strict file.isf CLI generation keeps stderr clean');
    ok(-f $hdl_output, '--strict file.isf CLI generation writes the requested HDL output');
    like(slurp($hdl_output), qr/\bmodule\s+apb_requester\b/, '--strict generated HDL contains the APB module');
};

done_testing();

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}
