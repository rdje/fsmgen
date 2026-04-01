#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);
my $test_lib = File::Spec->catdir($FindBin::Bin, 'lib');
my $fsm_path = File::Spec->catfile($tempdir, 'extension_diagnostic_smoke.fsm');

write_file(
    $fsm_path,
    <<'FSM'
(?fsm:extension_diagnostic_smoke
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (OUT 1)
  )
  (idle
    (OUT <= 1)
  )
)
FSM
);

subtest 'pipeline keeps source file plus extension module/stage for parse-hook failures' => sub {
    local $ENV{FSM_TEST_EXTENSION_FAIL_STAGE} = 'after_parse_source';

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        extension_modules => ['FSM::TestExtension::Exploding'],
    );

    my $error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $error = $@ if !$error;

    like(
        $error,
        qr/Source file:\s+'\Q$fsm_path\E'.*Extension module:\s+'FSM::TestExtension::Exploding'.*Extension stage:\s+'after_parse_source'.*Exploding test extension forced failure at stage 'after_parse_source'/s,
        'pipeline parse-hook failure keeps source file plus extension module and stage context',
    );
};

subtest 'pipeline keeps source file plus extension module/stage for result-hook failures' => sub {
    local $ENV{FSM_TEST_EXTENSION_FAIL_STAGE} = 'after_generate_result';

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        extension_modules => ['FSM::TestExtension::Exploding'],
    );

    my $error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $error = $@ if !$error;

    like(
        $error,
        qr/Source file:\s+'\Q$fsm_path\E'.*Extension module:\s+'FSM::TestExtension::Exploding'.*Extension stage:\s+'after_generate_result'.*Exploding test extension forced failure at stage 'after_generate_result'/s,
        'pipeline result-hook failure keeps source file plus extension module and stage context',
    );
};

subtest 'CLI keeps the same extension failure context and does not emit output' => sub {
    for my $case (
        ['after_parse_source', File::Spec->catfile($tempdir, 'extension_fail_parse.sv')],
        ['after_generate_result', File::Spec->catfile($tempdir, 'extension_fail_result.sv')],
    ) {
        my ($stage, $out_path) = @$case;
        local $ENV{FSM_TEST_EXTENSION_FAIL_STAGE} = $stage;

        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => [
                $^X,
                '-I', $test_lib,
                './bin/fsmgen',
                '--extension-module', 'FSM::TestExtension::Exploding',
                '--quiet',
                '-o', $out_path,
                $fsm_path,
            ],
        );

        ok(!$success, "CLI fails when the extension explodes at $stage");
        ok(!-e $out_path, "CLI does not emit output when the extension explodes at $stage");

        my $combined_output = join(
            '',
            @{ $stdout_buf || [] },
            @{ $stderr_buf || [] },
            ($error_message || ''),
        );

        like(
            $combined_output,
            qr/Source file:\s+'\Q$fsm_path\E'.*Extension module:\s+'FSM::TestExtension::Exploding'.*Extension stage:\s+'\Q$stage\E'.*Exploding test extension forced failure at stage '\Q$stage\E'/s,
            "CLI keeps source file plus extension module and stage context at $stage",
        );
    }
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
