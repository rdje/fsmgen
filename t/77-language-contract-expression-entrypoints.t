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

subtest 'pipeline and CLI do not emit HDL for unsupported RHS expression operators' => sub {
    assert_pipeline_and_cli_reject(
        'bad_rhs_operator_cli.fsm',
        <<'FSM',
(?fsm:bad_rhs_operator_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 8)
    (B 8)
    (C 8)
  )
  (-dt
    (A = (bogus B C))
  )
)
FSM
        qr/Unsupported expression operator 'bogus'/,
        'unsupported RHS operator',
    );
};

subtest 'pipeline and CLI do not emit HDL for malformed RHS expression arity' => sub {
    assert_pipeline_and_cli_reject(
        'bad_rhs_arity_cli.fsm',
        <<'FSM',
(?fsm:bad_rhs_arity_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 8)
    (B 8)
  )
  (-dt
    (A = (== B))
  )
)
FSM
        qr/Malformed expression operator '==' with 1 operand\(s\)/,
        'malformed RHS operator arity',
    );
};

subtest 'pipeline and CLI do not emit HDL for guard-only tokens in ordinary RHS expression position' => sub {
    assert_pipeline_and_cli_reject(
        'bad_rhs_scalar_cli.fsm',
        <<'FSM',
(?fsm:bad_rhs_scalar_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 8)
  )
  (-dt
    (A = <start)
  )
)
FSM
        qr/Unsupported expression token '<start'/,
        'guard-only RHS token',
    );
};

done_testing();

sub assert_pipeline_and_cli_reject {
    my ($filename, $fsm_text, $error_re, $label) = @_;

    my $fsm_path = write_fsm($filename, $fsm_text);
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, "pipeline rejects $label");
    like($pipeline_error, $error_re, "pipeline surfaces the explicit boundary for $label");

    my $out_path = File::Spec->catfile($tempdir, $filename . '.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, "CLI rejects $label");
    ok(!-e $out_path, "CLI does not emit output for $label");

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );
    like($combined_output, $error_re, "CLI surfaces the explicit boundary for $label");
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
