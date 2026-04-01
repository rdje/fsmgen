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
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;

my $tempdir = tempdir(CLEANUP => 1);
my $fsm_path = File::Spec->catfile($tempdir, 'strict_empty_size.fsm');
my $out_path = File::Spec->catfile($tempdir, 'strict_empty_size.sv');

write_file(
    $fsm_path,
    <<'FSM'
(?fsm:strict_empty_size
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size)
  (+size
    (OUT 1)
    (IN 1)
  )
  (idle
    (OUT = IN)
  )
)
FSM
);

subtest 'default mode still accepts legacy empty +size as compatibility residue' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    like(
        $result->{hdl_code},
        qr/\bmodule\s+strict_empty_size\b/s,
        'default-mode pipeline still generates HDL for the legacy empty +size no-op',
    );
};

subtest 'shared frontend strict boundary rejects legacy empty +size explicitly' => sub {
    my $raw_ast = Lispish::multi($fsm_path);

    my $error = eval {
        FSM::Pipeline::SourceFrontend->create_fsm_module(
            raw_ast => $raw_ast,
            debug_level => 0,
            strict_mode => 1,
            source_label => $fsm_path,
        );
        undef;
    };
    $error = $@ if !$error;

    like(
        $error,
        qr/Strict mode rejects the legacy empty '\(\+size\)' section in source '\Q$fsm_path\E'/,
        'shared frontend surfaces the new strict empty +size boundary',
    );
    like(
        $error,
        qr/replace it with explicit '\(\+size \(signal width\) \.\.\.\)' entries/,
        'shared frontend gives the explicit migration hint',
    );
};

subtest 'strict pipeline and CLI reject legacy empty +size and do not emit HDL' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Source file:\s+'\Q$fsm_path\E'.*Strict mode rejects the legacy empty '\(\+size\)' section/s,
        'strict pipeline keeps source-file context around the new empty +size boundary',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $out_path, $fsm_path],
    );

    ok(!$success, 'CLI strict mode rejects the legacy empty +size no-op');
    ok(!-e $out_path, 'CLI strict mode does not emit output for the legacy empty +size no-op');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Source file:\s+'\Q$fsm_path\E'.*Strict mode rejects the legacy empty '\(\+size\)' section/s,
        'CLI strict mode surfaces the same source-local empty +size boundary',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
