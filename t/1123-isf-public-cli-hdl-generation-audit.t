#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

subtest 'CLI file.isf path generates HDL through the scheduled FSM pipeline' => sub {
    my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $outdir = tempdir(CLEANUP => 1);
    my $hdl_output = File::Spec->catfile($outdir, 'apb_requester.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--quiet',
            '--output',
            $hdl_output,
            $isf_file,
        ],
    );

    ok($success, 'file.isf CLI generation succeeds for the APB fixture');
    is(join('', @{$stderr_buf || []}), '', 'file.isf CLI generation keeps stderr clean');
    ok(-f $hdl_output, 'file.isf CLI generation writes the requested HDL output');

    my $hdl = slurp($hdl_output);
    like($hdl, qr/\bmodule\s+apb_requester\b/, 'generated HDL contains the APB module');
    like($hdl, qr/\bAPB_TRANSFER_IDLE_0\b/, 'generated HDL contains scheduled APB state encoding');
    like($hdl, qr/\binput\s+wire\s+clk\b/, 'generated HDL keeps the scheduled clock port');
};

done_testing();

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}
