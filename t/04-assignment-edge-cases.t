#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 17;
use File::Spec;
use File::Temp qw/ tempdir /;
use IPC::Cmd qw(run);

my $tempdir = tempdir(CLEANUP => 1);

my $pulse_n0 = run_fsmgen_case(
    'pulse_n0',
    <<'FSM'
(?fsm:pulse_n0
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (PPOS <0 1)
    (PNEG <0 0)
  )
  (+size
    (PPOS 1)
    (PNEG 1)
  )
)
FSM
);

ok($pulse_n0->{success}, "accepts delayed-pulse operator with N=0");
ok($pulse_n0->{output_exists}, "writes HDL output for N=0 pulse case");
like(
    $pulse_n0->{hdl},
    qr{// Delayed pulse logic for: PPOS \(<0, exact Q\+0\)}s,
    "PPOS includes exact Q+0 delayed pulse annotation"
);
like(
    $pulse_n0->{hdl},
    qr{// Delayed pulse logic for: PNEG \(<0, exact Q\+0\)}s,
    "PNEG includes exact Q+0 delayed pulse annotation"
);
like(
    $pulse_n0->{hdl},
    qr/\bPPOS\s*<=\s*\([^;]+\)\s*\?\s*1'b1\s*:\s*1'b0;/s,
    "PPOS <0 1 emits immediate positive one-cycle pulse assignment"
);
like(
    $pulse_n0->{hdl},
    qr/\bPNEG\s*<=\s*\([^;]+\)\s*\?\s*1'b0\s*:\s*1'b1;/s,
    "PNEG <0 0 emits immediate negative one-cycle pulse assignment"
);
unlike(
    $pulse_n0->{hdl},
    qr/\b(?:PPOS|PNEG)_pulse_delay_pipe\b/s,
    "N=0 pulse implementation does not create delay-pipeline registers"
);
like(
    $pulse_n0->{hdl},
    qr/\bif\s*\(!rstn\)\s*begin\s*\n\s*PPOS\s*<=\s*1'b0;\s*\n\s*end\s*else\s*begin/s,
    "PPOS <0 1 reset/rest level is 0"
);
like(
    $pulse_n0->{hdl},
    qr/\bif\s*\(!rstn\)\s*begin\s*\n\s*PNEG\s*<=\s*1'b1;\s*\n\s*end\s*else\s*begin/s,
    "PNEG <0 0 reset/rest level is 1"
);

my $invalid_rhs = run_fsmgen_case(
    'pulse_invalid_rhs',
    <<'FSM'
(?fsm:pulse_invalid_rhs
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (P <1 B)
  )
  (+size
    (P 1)
    (B 1)
  )
)
FSM
);

ok(!$invalid_rhs->{success}, "rejects <N pulse when RHS is not literal 0/1");
like(
    $invalid_rhs->{combined_output},
    qr/Delayed pulse '<N' requires RHS literal 0 or 1/s,
    "reports precise parser error for invalid <N RHS literal requirement"
);

my $mixed_comb_seq = run_fsmgen_case(
    'mixed_comb_seq',
    <<'FSM'
(?fsm:mixed_comb_seq
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (A = B)
    (A <= C)
  )
  (+size
    (A 8)
    (B 8)
    (C 8)
  )
)
FSM
);

ok(!$mixed_comb_seq->{success}, "rejects mixed combinational and sequential families on same LHS");
like(
    $mixed_comb_seq->{combined_output},
    qr/Mixed combinational '=' and sequential operators/s,
    "reports conflict for '=' mixed with sequential family"
);

my $mixed_pulse_nonpulse = run_fsmgen_case(
    'mixed_pulse_nonpulse',
    <<'FSM'
(?fsm:mixed_pulse_nonpulse
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (P <2 1)
    (P <= D)
  )
  (+size
    (P 1)
    (D 1)
  )
)
FSM
);

ok(!$mixed_pulse_nonpulse->{success}, "rejects mixed pulse-delayed and non-pulse sequential families");
like(
    $mixed_pulse_nonpulse->{combined_output},
    qr/Mixed pulse-delayed and non-pulse sequential operators/s,
    "reports pulse/non-pulse sequential family conflict"
);

my $multi_delay = run_fsmgen_case(
    'multi_delay',
    <<'FSM'
(?fsm:multi_delay
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (P <2 1)
    (P <3 1)
  )
  (+size
    (P 1)
  )
)
FSM
);

ok(!$multi_delay->{success}, "rejects multiple <N delay values for same LHS");
like(
    $multi_delay->{combined_output},
    qr/Multiple pulse delays .* unsupported/s,
    "reports conflict when same LHS mixes different pulse delays"
);

sub run_fsmgen_case {
    my ($case_name, $fsm_text) = @_;
    my $fsm_path = File::Spec->catfile($tempdir, "$case_name.fsm");
    my $out_path = File::Spec->catfile($tempdir, "$case_name.sv");
    
    write_file($fsm_path, $fsm_text);
    
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) =
        run(command => ["./bin/fsmgen", "-o", $out_path, "--quiet", $fsm_path]);
    
    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || '')
    );
    
    my $hdl = '';
    if (-e $out_path) {
        open my $fh, '<', $out_path or die "Cannot open $out_path: $!";
        local $/ = undef;
        $hdl = <$fh>;
        close $fh or die "Cannot close $out_path: $!";
    }
    
    return {
        success => $success ? 1 : 0,
        output_exists => (-e $out_path) ? 1 : 0,
        out_path => $out_path,
        hdl => $hdl,
        combined_output => $combined_output,
    };
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
