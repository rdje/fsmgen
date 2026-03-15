#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'future-looking top-level infix init forms are rejected explicitly' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:bad_top_level_infix_init
  (tester_reset := 1)
  (-dt
    (A = 1)
  )
)
FSM

    like($error, qr/Unsupported top-level form '\(tester_reset := 1\)'/, 'top-level infix init form gets a targeted diagnostic');
};

subtest 'other malformed top-level bare forms are rejected explicitly' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:bad_top_level_bare_form
  (BROKEN 1)
  (-dt
    (A = 1)
  )
)
FSM

    like($error, qr/Unsupported top-level form '\(BROKEN 1\)'/, 'malformed top-level bare scalar form gets a targeted diagnostic');
};

subtest 'pipeline and CLI do not silently ignore unsupported top-level bare forms' => sub {
    my $fsm_path = write_fsm('pipeline_bad_top_level_form.fsm', <<'FSM');
(?fsm:pipeline_bad_top_level_form
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

    my $pipeline_exception = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_exception = $@;

    like(
        $pipeline_exception,
        qr/Unsupported top-level form '\(tester_reset := 1\)'/,
        'pipeline surfaces the unsupported top-level form clearly',
    );

    my $out_path = File::Spec->catfile($tempdir, 'pipeline_bad_top_level_form.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects unsupported top-level bare forms');
    ok(!-e $out_path, 'CLI does not emit output for unsupported top-level bare forms');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Unsupported top-level form '\(tester_reset := 1\)'/,
        'CLI surfaces the unsupported top-level form clearly',
    );
};

done_testing();

sub parse_failure {
    my ($fsm_text) = @_;
    my $error = eval {
        my $path = write_fsm('parse_failure_case.fsm', $fsm_text);
        my $raw_ast = Lispish::multi($path);
        my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
        $adapter->parse_fsm($raw_ast);
        undef;
    };
    $error = $@;
    ok($error, 'parse failed as expected');
    return $error;
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
