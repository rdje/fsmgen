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
my $modern_path = File::Spec->catfile($tempdir, 'strict_modern_ok.fsm');
my $modern_out_path = File::Spec->catfile($tempdir, 'strict_modern_ok.sv');
my $flat_legacy_path = File::Spec->catfile($tempdir, 'strict_flat_legacy.fsm');
my $flat_legacy_out_path = File::Spec->catfile($tempdir, 'strict_flat_legacy.sv');
my $nested_legacy_path = File::Spec->catfile($tempdir, 'strict_nested_legacy.fsm');
my $nested_legacy_out_path = File::Spec->catfile($tempdir, 'strict_nested_legacy.sv');

write_file(
    $modern_path,
    <<'FSM'
(?fsm:strict_modern_ok
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
);

write_file(
    $flat_legacy_path,
    <<'FSM'
(+fsm strict_flat_legacy)
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
FSM
);

write_file(
    $nested_legacy_path,
    <<'FSM'
(+fsm strict_nested_legacy
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
);

subtest 'strict pipeline still accepts modern explicit ?fsm roots' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($modern_path);
    like(
        $result->{hdl_code},
        qr/\bmodule\s+strict_modern_ok\b/s,
        'strict pipeline still generates HDL for the modern explicit root family',
    );
};

subtest 'strict pipeline rejects both flattened and nested legacy +fsm roots' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    for my $case (
        [$flat_legacy_path, 'flattened legacy +fsm root'],
        [$nested_legacy_path, 'nested legacy +fsm root'],
    ) {
        my ($path, $label) = @$case;
        my $error = eval {
            $pipeline->generate_hdl_from_file($path);
            undef;
        };
        $error = $@;

        like(
            $error,
            qr/Strict mode rejects the legacy '\+fsm' root family/,
            "strict pipeline rejects $label explicitly",
        );
        like(
            $error,
            qr/\?fsm:module_name/,
            "strict pipeline gives a modern-root migration hint for $label",
        );
    }
};

subtest 'CLI strict mode mirrors the same boundary and keeps help discoverable' => sub {
    my ($help_success, $help_error_message, $help_full_buf, $help_stdout_buf, $help_stderr_buf) = run(
        command => ['./bin/fsmgen', '--help'],
    );

    ok($help_success, 'CLI help succeeds');

    my $help_output = join(
        '',
        @{ $help_stdout_buf || [] },
        @{ $help_stderr_buf || [] },
        ($help_error_message || ''),
    );

    like(
        $help_output,
        qr/--strict\s+Enable strict support-tier enforcement/s,
        'CLI help now documents the strict-mode option',
    );

    my ($modern_success, $modern_error_message, $modern_full_buf, $modern_stdout_buf, $modern_stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $modern_out_path, $modern_path],
    );

    ok($modern_success, 'CLI strict mode still accepts the modern explicit root family');
    ok(-e $modern_out_path, 'CLI strict mode emits output for the modern explicit root family');

    for my $case (
        [$flat_legacy_path, $flat_legacy_out_path, 'flattened legacy +fsm root'],
        [$nested_legacy_path, $nested_legacy_out_path, 'nested legacy +fsm root'],
    ) {
        my ($path, $out_path, $label) = @$case;
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $out_path, $path],
        );

        ok(!$success, "CLI strict mode rejects $label");
        ok(!-e $out_path, "CLI strict mode does not emit output for $label");

        my $combined_output = join(
            '',
            @{ $stdout_buf || [] },
            @{ $stderr_buf || [] },
            ($error_message || ''),
        );

        like(
            $combined_output,
            qr/Strict mode rejects the legacy '\+fsm' root family/,
            "CLI strict mode surfaces the explicit strict boundary for $label",
        );
        like(
            $combined_output,
            qr/\?fsm:module_name/,
            "CLI strict mode gives the modern-root migration hint for $label",
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
