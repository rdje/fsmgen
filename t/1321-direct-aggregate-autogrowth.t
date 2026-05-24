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

subtest 'direct whole-signal targets infer aggregate contracts from whole aggregate constants' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_aggregate_constant_target_autogrowth.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_aggregate_constant_target_autogrowth.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_aggregate_constant_target_autogrowth
  (+system
    (clock clk)
    (sreset reset)
  )
  (+constants
    (FRAME ((tag const_4b1010) (flag 1)))
    (LANES (const_2b10 const_3b101))
  )
  (idle
    (= (OUT_FRAME> FRAME))
    (= (OUT_LANES> LANES))
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );
    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    my $hdl = $result->{hdl_code};

    like(
        $hdl,
        qr/typedef struct packed \{\n\s+logic \[3:0\] tag;\n\s+logic flag;\n\} fsmgen_inferred_OUT_FRAME__fsmgen_t; \/\/ fsmgen_inferred_OUT_FRAME/s,
        'pipeline emits an inferred packed record typedef for the aggregate constant target',
    );
    like(
        $hdl,
        qr/typedef struct packed \{\n\s+logic \[1:0\] item_0;\n\s+logic \[2:0\] item_1;\n\} fsmgen_inferred_OUT_LANES__fsmgen_t; \/\/ fsmgen_inferred_OUT_LANES/s,
        'pipeline emits an inferred packed list typedef for the aggregate constant target',
    );
    like(
        $hdl,
        qr/\boutput\s+fsmgen_inferred_OUT_FRAME__fsmgen_t\s+OUT_FRAME\b/s,
        'pipeline exposes the inferred record target through the generated module port',
    );
    like(
        $hdl,
        qr/\boutput\s+fsmgen_inferred_OUT_LANES__fsmgen_t\s+OUT_LANES\b/s,
        'pipeline exposes the inferred list target through the generated module port',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--output', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});
    my $output_text = slurp_file($output_path);

    ok($success, 'CLI accepts aggregate constant target autogrowth');
    ok(-e $output_path, 'CLI emits HDL for aggregate constant target autogrowth');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for aggregate constant target autogrowth');
    unlike($combined_output, qr/aggregate contract|whole aggregate RHS/s, 'successful CLI run does not report aggregate-contract failures');
    like(
        $output_text,
        qr/\boutput\s+fsmgen_inferred_OUT_FRAME__fsmgen_t\s+OUT_FRAME\b/s,
        'CLI output preserves the inferred record target typedef',
    );
};

subtest 'explicit scalar target declarations remain authoritative' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_explicit_scalar_blocks_aggregate_autogrowth.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_explicit_scalar_blocks_aggregate_autogrowth
  (+system
    (clock clk)
    (sreset reset)
  )
  (+constants
    (FRAME ((tag const_4b1010) (flag 1)))
  )
  (+size
    (OUT 5)
  )
  (idle
    (= (OUT> FRAME))
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );
    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    my $hdl = $result->{hdl_code};

    unlike(
        $hdl,
        qr/fsmgen_inferred_OUT/s,
        'explicit scalar +size target does not receive an inferred aggregate typedef',
    );
    like(
        $hdl,
        qr/\boutput\s+reg\s+\[4:0\]\s+OUT\b/s,
        'explicit scalar +size target remains a width-only output',
    );
};

subtest 'direct RHS concat can infer undeclared whole-signal list contracts' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_rhs_concat_target_autogrowth.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_rhs_concat_target_autogrowth.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_rhs_concat_target_autogrowth
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (FLAG 1)
    (DATA 2)
    (TAG 4)
  )
  (idle
    (= (OUT> (concat FLAG DATA)))
    (= (NESTED> (concat (concat FLAG DATA) TAG)))
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );
    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    my $hdl = $result->{hdl_code};

    like(
        $hdl,
        qr/typedef struct packed \{\n\s+logic item_0;\n\s+logic \[1:0\] item_1;\n\} fsmgen_inferred_OUT__fsmgen_t; \/\/ fsmgen_inferred_OUT/s,
        'pipeline emits an inferred packed list typedef for a direct RHS concat target',
    );
    like(
        $hdl,
        qr/typedef struct packed \{\n\s+struct packed \{\n\s+logic item_0;\n\s+logic \[1:0\] item_1;\n\s+\} item_0;\n\s+logic \[3:0\] item_1;\n\} fsmgen_inferred_NESTED__fsmgen_t; \/\/ fsmgen_inferred_NESTED/s,
        'pipeline emits an inferred nested packed list typedef for a nested direct RHS concat target',
    );
    like(
        $hdl,
        qr/\boutput\s+fsmgen_inferred_OUT__fsmgen_t\s+OUT\b/s,
        'pipeline exposes the inferred concat list target through the generated module port',
    );
    like(
        $hdl,
        qr/\boutput\s+fsmgen_inferred_NESTED__fsmgen_t\s+NESTED\b/s,
        'pipeline exposes the inferred nested concat list target through the generated module port',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--output', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});
    my $output_text = slurp_file($output_path);

    ok($success, 'CLI accepts direct RHS concat target autogrowth');
    ok(-e $output_path, 'CLI emits HDL for direct RHS concat target autogrowth');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for direct RHS concat target autogrowth');
    unlike($combined_output, qr/aggregate contract|whole aggregate RHS/s, 'successful CLI run does not report concat aggregate-contract failures');
    like(
        $output_text,
        qr/\boutput\s+fsmgen_inferred_OUT__fsmgen_t\s+OUT\b/s,
        'CLI output preserves the inferred concat list target typedef',
    );
};

subtest 'explicit scalar targets still block direct RHS concat autogrowth' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_explicit_scalar_blocks_concat_autogrowth.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_explicit_scalar_blocks_concat_autogrowth
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (FLAG 1)
    (DATA 2)
    (OUT 3)
  )
  (idle
    (= (OUT> (concat FLAG DATA)))
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );
    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    my $hdl = $result->{hdl_code};

    unlike(
        $hdl,
        qr/fsmgen_inferred_OUT/s,
        'explicit scalar +size target does not receive an inferred concat list typedef',
    );
    like(
        $hdl,
        qr/\boutput\s+reg\s+\[2:0\]\s+OUT\b/s,
        'explicit scalar +size target remains a width-only concat output',
    );
};

subtest 'conflicting later aggregate constants still fail against the inferred contract' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'bad_direct_aggregate_constant_target_autogrowth_conflict.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:bad_direct_aggregate_constant_target_autogrowth_conflict
  (+system
    (clock clk)
    (sreset reset)
  )
  (+constants
    (FRAME ((tag const_4b1010) (flag 1)))
    (BAD ((mode const_2b10) (flag const_3b101)))
  )
  (idle
    (= (OUT> FRAME))
  )
  (busy
    (= (OUT> BAD))
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/assignment to 'OUT'.*whole aggregate RHS 'BAD'.*does not match declared type/s,
        'pipeline rejects conflicting aggregate constants against the inferred target contract',
    );
};

subtest 'conflicting later RHS concat order fails against the inferred list contract' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'bad_direct_rhs_concat_target_autogrowth_conflict.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:bad_direct_rhs_concat_target_autogrowth_conflict
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (FLAG 1)
    (DATA 2)
  )
  (idle
    (= (OUT> (concat FLAG DATA)))
  )
  (busy
    (= (OUT> (concat DATA FLAG)))
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/assignment to 'OUT'.*whole aggregate RHS '\{DATA, FLAG\}'.*does not match declared type 'list<bit, bits\[2\]>'/s,
        'pipeline rejects a later width-equal concat with the wrong inferred list item order',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub slurp_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path for read: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}
