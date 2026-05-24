#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);

my $tempdir = tempdir(CLEANUP => 1);
my $ok_path = File::Spec->catfile($tempdir, 'quiet_banner_ok.fsm');
my $bad_path = File::Spec->catfile($tempdir, 'quiet_banner_bad.fsm');
my $ok_out_path = File::Spec->catfile($tempdir, 'quiet_banner_ok.sv');
my $quiet_out_path = File::Spec->catfile($tempdir, 'quiet_banner_quiet.sv');

write_file(
    $ok_path,
    <<'FSM'
(?fsm:quiet_banner_ok
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 1)
    (IN 1)
  )
  (idle
    (= (OUT IN))
  )
)
FSM
);

write_file($bad_path, q{});

subtest 'non-quiet success keeps the interactive banner' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $ok_out_path, $ok_path],
    );

    ok($success, 'non-quiet CLI success still succeeds');
    ok(-e $ok_out_path, 'non-quiet CLI success still emits HDL');
    my $stdout = join('', @{$stdout_buf || []});
    like($stdout, qr/=== FSM HDL Generator ===/s, 'non-quiet success keeps the banner');
    like($stdout, qr/Processing FSM file:\s+\Q$ok_path\E/s, 'non-quiet success keeps the processing line');
    is(join('', @{$stderr_buf || []}), '', 'non-quiet success keeps stderr empty');
};

subtest 'quiet success suppresses the interactive banner' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $quiet_out_path, $ok_path],
    );

    ok($success, 'quiet CLI success still succeeds');
    ok(-e $quiet_out_path, 'quiet CLI success still emits HDL');
    my $combined_output = combined_output($error_message, $stdout_buf, $stderr_buf);
    unlike($combined_output, qr/=== FSM HDL Generator ===/s, 'quiet success suppresses the banner');
    unlike($combined_output, qr/Processing FSM file:/s, 'quiet success suppresses the processing line');
};

subtest 'quiet failure suppresses the interactive banner but keeps diagnostics' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', $bad_path],
    );

    ok(!$success, 'quiet CLI failure still fails');
    my $combined_output = combined_output($error_message, $stdout_buf, $stderr_buf);
    unlike($combined_output, qr/=== FSM HDL Generator ===/s, 'quiet failure suppresses the banner');
    unlike($combined_output, qr/Processing FSM file:/s, 'quiet failure suppresses the processing line');
    like($combined_output, qr/Source file:\s+'\Q$bad_path\E'/s, 'quiet failure keeps source context');
    like($combined_output, qr/is empty/s, 'quiet failure keeps the diagnostic text');
};

done_testing();

sub combined_output {
    my ($error_message, $stdout_buf, $stderr_buf) = @_;
    return join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
