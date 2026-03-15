#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'malformed guard shorthand payloads are rejected explicitly' => sub {
    my $missing_rhs_error = parse_failure(<<'FSM');
(?fsm:bad_guard_payload_missing_rhs
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (<mode=
      (A = 1)
    )
  )
)
FSM

    like(
        $missing_rhs_error,
        qr/Malformed guard condition payload 'mode='/,
        'guard shorthand missing RHS gets a targeted diagnostic',
    );

    my $missing_lhs_error = parse_failure(<<'FSM');
(?fsm:bad_guard_payload_missing_lhs
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (<==3
      (A = 1)
    )
  )
)
FSM

    like(
        $missing_lhs_error,
        qr/Malformed guard condition payload '==3'/,
        'guard shorthand missing LHS gets a targeted diagnostic',
    );
};

subtest 'malformed inline comparison tokens are rejected explicitly' => sub {
    my $missing_rhs_error = parse_failure(<<'FSM');
(?fsm:bad_inline_comparison_missing_rhs
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
  )
  (-dt
    (A = cnt[2:1]!=)
  )
)
FSM

    like(
        $missing_rhs_error,
        qr/Malformed inline comparison expression 'cnt\[2:1\]!=`?'/,
        'inline comparison missing RHS gets a targeted diagnostic',
    );

    my $missing_lhs_error = parse_failure(<<'FSM');
(?fsm:bad_inline_comparison_missing_lhs
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
  )
  (-dt
    (A = =3)
  )
)
FSM

    like(
        $missing_lhs_error,
        qr/Malformed inline comparison expression '=3'/,
        'inline comparison missing LHS gets a targeted diagnostic',
    );
};

subtest 'pipeline and CLI do not emit HDL for malformed guard or inline-comparison payloads' => sub {
    my $guard_fsm_path = write_fsm('bad_guard_payload_cli.fsm', <<'FSM');
(?fsm:bad_guard_payload_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (<mode=
      (A = 1)
    )
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $guard_pipeline_error = eval {
        $pipeline->generate_hdl_from_file($guard_fsm_path);
        undef;
    };
    $guard_pipeline_error = $@ if !$guard_pipeline_error;
    ok($guard_pipeline_error, 'pipeline rejects malformed guard payload');
    like(
        $guard_pipeline_error,
        qr/Malformed guard condition payload 'mode='/,
        'pipeline surfaces the explicit malformed-guard boundary',
    );

    my $guard_out_path = File::Spec->catfile($tempdir, 'bad_guard_payload_cli.sv');
    my $guard_success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $guard_out_path, $guard_fsm_path) == 0;
    ok(!$guard_success, 'CLI rejects malformed guard payload');
    ok(!-e $guard_out_path, 'CLI does not emit output for malformed guard payload');

    my $expr_fsm_path = write_fsm('bad_inline_comparison_cli.fsm', <<'FSM');
(?fsm:bad_inline_comparison_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
  )
  (-dt
    (A = cnt[2:1]!=)
  )
)
FSM

    my $expr_pipeline_error = eval {
        $pipeline->generate_hdl_from_file($expr_fsm_path);
        undef;
    };
    $expr_pipeline_error = $@ if !$expr_pipeline_error;
    ok($expr_pipeline_error, 'pipeline rejects malformed inline comparison');
    like(
        $expr_pipeline_error,
        qr/Malformed inline comparison expression 'cnt\[2:1\]!=`?'/,
        'pipeline surfaces the explicit malformed-inline-comparison boundary',
    );

    my $expr_out_path = File::Spec->catfile($tempdir, 'bad_inline_comparison_cli.sv');
    my $expr_success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $expr_out_path, $expr_fsm_path) == 0;
    ok(!$expr_success, 'CLI rejects malformed inline comparison');
    ok(!-e $expr_out_path, 'CLI does not emit output for malformed inline comparison');
};

done_testing();

sub parse_failure {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_failure_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);

    my $error = eval {
        $adapter->parse_fsm($raw_ast);
        undef;
    };
    $error = $@ if !$error;
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
