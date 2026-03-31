#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'pipeline and CLI surface Source file context for top-level parse failures' => sub {
    my $fsm_path = write_fsm('bad_top_level_form_with_source_context.fsm', <<'FSM');
(?fsm:bad_top_level_form_with_source_context
  (tester_reset := 1)
  (-dt
    (A = 1)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    ok($pipeline_error, 'pipeline rejects malformed top-level form');
    like(
        $pipeline_error,
        qr/Source file:\s+'\Q$fsm_path\E'/s,
        'pipeline failure now keeps the offending source file path',
    );
    like(
        $pipeline_error,
        qr/Unsupported top-level form '\(tester_reset := 1\)'/s,
        'pipeline still keeps the underlying construct-family diagnostic',
    );

    my $out_path = File::Spec->catfile($tempdir, 'bad_top_level_form_with_source_context.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $out_path, $fsm_path],
    );

    ok(!$success, 'CLI rejects malformed top-level form');
    ok(!-e $out_path, 'CLI does not emit output for malformed top-level form');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Source file:\s+'\Q$fsm_path\E'/s,
        'CLI failure now keeps the offending source file path',
    );
    like(
        $combined_output,
        qr/Unsupported top-level form '\(tester_reset := 1\)'/s,
        'CLI still keeps the underlying construct-family diagnostic',
    );
};

subtest 'pipeline and CLI surface Source file context for strict-mode boundary failures' => sub {
    my $legacy_path = write_fsm('strict_legacy_with_source_context.fsm', <<'FSM');
(+fsm strict_legacy_with_source_context
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (OUT 1)
    (IN 1)
  )
  (idle
    (OUT = IN)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($legacy_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    ok($pipeline_error, 'strict pipeline rejects legacy +fsm root');
    like(
        $pipeline_error,
        qr/Source file:\s+'\Q$legacy_path\E'/s,
        'strict pipeline failure now keeps the offending source file path',
    );
    like(
        $pipeline_error,
        qr/Strict mode rejects the legacy '\+fsm' root family/s,
        'strict pipeline still keeps the underlying support-tier diagnostic',
    );

    my $out_path = File::Spec->catfile($tempdir, 'strict_legacy_with_source_context.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $out_path, $legacy_path],
    );

    ok(!$success, 'CLI strict mode rejects legacy +fsm root');
    ok(!-e $out_path, 'CLI strict mode does not emit output for legacy +fsm root');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Source file:\s+'\Q$legacy_path\E'/s,
        'CLI strict-mode failure now keeps the offending source file path',
    );
    like(
        $combined_output,
        qr/Strict mode rejects the legacy '\+fsm' root family/s,
        'CLI strict-mode failure still keeps the underlying support-tier diagnostic',
    );
};

done_testing();

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
