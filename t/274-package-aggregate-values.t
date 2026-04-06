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

subtest 'pipeline and CLI resolve package aggregate leaves for direct-root expressions' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $fsm_path = File::Spec->catfile($tempdir, 'direct_package_aggregate_root.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_external.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_package_aggregate_root.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_external
  (+constants
    (BYTES (8'hA5 8'h3C 0))
    (FRAME ((mode 3) (flag 1)))
    (NEST ((header ((nibble 4'hA))) (tail (1 0))))
  )
)
FSM
    );

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_package_aggregate_root
  (+import shared_local shared_external)
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (SEL 8)
    (OUT 8)
    (FLAG 1)
    (NIBBLE 4)
    (TAIL0 1)
    (HIT 1)
  )
  (idle
    (OUT = shared_external.BYTES[1])
    (FLAG = shared_external.FRAME.flag)
    (NIBBLE = shared_external.NEST.header.nibble)
    (TAIL0 = shared_external.NEST.tail[0])
    (HIT = 1 <SEL=shared_local.SETTINGS.mode)
  )
)

(?pkg:shared_local
  (+constants
    (SETTINGS ((mode 3) (enable 1)))
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );
    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    my $fsm_module = $result->{fsm_module};
    my $hdl = $result->{hdl_code};

    my %assignment_by_target = %{ assignments_by_target($fsm_module, 'idle') };
    is_literal_assignment($assignment_by_target{OUT}, '3C', 8, 'OUT resolves package list leaf to a literal');
    is_literal_assignment($assignment_by_target{FLAG}, '1', undef, 'FLAG resolves package hash leaf to a literal');
    is_literal_assignment($assignment_by_target{NIBBLE}, 'A', 4, 'NIBBLE resolves nested package hash leaf to a literal');
    is_literal_assignment($assignment_by_target{TAIL0}, '1', undef, 'TAIL0 resolves nested package list leaf to a literal');

    my %conditional_by_target = %{ conditionals_by_target($fsm_module, 'idle') };
    assert_condition_equality(
        $conditional_by_target{HIT}->condition,
        'SEL',
        '3',
        'package aggregate leaf resolves in direct-root condition context',
    );

    unlike(
        $hdl,
        qr/shared_external\.BYTES\[1\]|shared_external\.FRAME\.flag|shared_external\.NEST\.header\.nibble|shared_local\.SETTINGS\.mode/s,
        'generated HDL lowers package aggregate leaves before emission',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '-o', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});
    my $output_text = slurp_file($output_path);

    ok($success, 'CLI accepts direct-root package aggregate leaves');
    ok(-e $output_path, 'CLI emits HDL for direct-root package aggregate leaves');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for direct-root package aggregate leaves');
    unlike($combined_output, qr/aggregate-valued package symbol|package aggregate value support is blocked/s, 'successful direct-root aggregate CLI run does not report aggregate-package failures');
    unlike(
        $output_text,
        qr/shared_external\.BYTES\[1\]|shared_external\.FRAME\.flag|shared_external\.NEST\.header\.nibble|shared_local\.SETTINGS\.mode/s,
        'CLI output also lowers package aggregate leaves before emission',
    );
};

subtest 'pipeline and CLI resolve package aggregate leaves for composition actuals' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $composition_path = File::Spec->catfile($tempdir, 'package_aggregate_top.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_external.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'package_aggregate_top.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_external
  (+constants
    (BYTES (8'hA5 8'h3C 0))
    (FRAME ((mode 3) (flag 1)))
    (NIBBLES (4'h5 4'hA))
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:package_aggregate_top
  (+import shared_local shared_external)
  (?ports:public_io
    byte_out>8
    flag_out>
    packed_out>5
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=shared_external.BYTES[0]/byte_out/
    /=shared_external.FRAME.flag/flag_out/
    /=shared_local.SETTINGS.enable,=shared_external.NIBBLES[1]/packed_out/
    /=shared_external.BYTES[1]/uart_tx.data_in/
    /=shared_local.SETTINGS.enable/uart_tx.enable/
  )
)

(?pkg:shared_local
  (+constants
    (SETTINGS ((mode 3) (enable 1)))
  )
)

(?rtlif:uart_tx
  data_in<8:data
  enable<1:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $hdl = $result->{hdl_code};

    is(
        $result->{composition_spec}->top->top_symbols->resolve_actual_payload('shared_external.BYTES[0]'),
        "8'hA5",
        'resolved top symbols expose imported package list leaves by namespace',
    );
    is(
        $result->{composition_spec}->top->top_symbols->resolve_actual_payload('shared_external.FRAME.flag'),
        '1',
        'resolved top symbols expose imported package hash leaves by namespace',
    );
    is(
        $result->{composition_spec}->top->top_symbols->resolve_actual_payload('shared_local.SETTINGS.enable'),
        '1',
        'resolved top symbols expose imported embedded package aggregate leaves by namespace',
    );

    like($hdl, qr/assign\s+byte_out\s*=\s*8'b10100101\s*;/, 'generated HDL emits package-backed list-leaf top-output assignments');
    like($hdl, qr/assign\s+flag_out\s*=\s*1'b1\s*;/, 'generated HDL emits package-backed hash-leaf top-output assignments');
    like($hdl, qr/assign\s+packed_out\s*=\s*\{1'b1,\s*4'b1010\}\s*;/, 'generated HDL emits package-backed aggregate-leaf concat operands');
    like($hdl, qr/\.data_in\(8'b00111100\)/, 'generated HDL binds imported package aggregate list leaves into child inputs');
    like($hdl, qr/\.enable\(1'b1\)/, 'generated HDL binds imported package aggregate hash leaves into child inputs');

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '-o', $output_path, $composition_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok($success, 'CLI accepts package aggregate leaves on the bounded composition path');
    ok(-e $output_path, 'CLI emits HDL for composition sources that use package aggregate leaves');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for package-backed composition aggregate generation');
    unlike($combined_output, qr/package aggregate value support is blocked|aggregate-valued package symbol/s, 'successful composition aggregate CLI run does not report aggregate-package failures');
};

subtest 'pipeline and CLI reject unresolved aggregate package roots in direct-root expressions' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $fsm_path = File::Spec->catfile($tempdir, 'bad_package_aggregate_root_ref.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_external.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_package_aggregate_root_ref.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_external
  (+constants
    (FRAME ((mode 3) (flag 1)))
  )
)
FSM
    );

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:bad_package_aggregate_root_ref
  (+import shared_external)
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (OUT 8)
  )
  (idle
    (OUT = shared_external.FRAME)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Unsupported aggregate-valued package symbol 'shared_external\.FRAME'/s,
        'pipeline rejects unresolved aggregate package roots with a targeted direct-root diagnostic',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '-o', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok(!$success, 'CLI rejects unresolved aggregate package roots');
    ok(!-e $output_path, 'CLI does not emit HDL for unresolved aggregate package roots');
    like(
        $combined_output,
        qr/Unsupported aggregate-valued package symbol 'shared_external\.FRAME'/s,
        'CLI surfaces the targeted aggregate-root boundary',
    );
    isnt($error_code, 0, 'CLI exits non-zero for unresolved aggregate package roots');
};

subtest 'pipeline and CLI reject mixed package aggregate value shapes' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $fsm_path = File::Spec->catfile($tempdir, 'bad_package_aggregate_shape_root.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_external.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_package_aggregate_shape_root.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_external
  (+constants
    (BROKEN ((mode 3) 0))
  )
)
FSM
    );

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:bad_package_aggregate_shape_root
  (+import shared_external)
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (OUT 8)
  )
  (idle
    (OUT = 0)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/mixed aggregate value/s,
        'pipeline rejects mixed package aggregate value shapes explicitly',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '-o', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok(!$success, 'CLI rejects mixed package aggregate value shapes');
    ok(!-e $output_path, 'CLI does not emit HDL for mixed package aggregate value shapes');
    like(
        $combined_output,
        qr/mixed aggregate value/s,
        'CLI surfaces the mixed package aggregate value boundary',
    );
    isnt($error_code, 0, 'CLI exits non-zero for mixed package aggregate value shapes');
};

done_testing();

sub assignments_by_target {
    my ($fsm_module, $state_name) = @_;
    my %assignment_by_target;

    for my $element (@{ state_elements($fsm_module, $state_name) }) {
        next unless $element->isa('FSM::CoreAST::Assignment') || $element->isa('FSM::CoreAST::RegisterAssignment');
        my $target = extract_target_name($element);
        $assignment_by_target{$target} = $element if defined $target;
    }

    return \%assignment_by_target;
}

sub conditionals_by_target {
    my ($fsm_module, $state_name) = @_;
    my %conditional_by_target;

    for my $element (@{ state_elements($fsm_module, $state_name) }) {
        next unless $element->isa('FSM::CoreAST::ConditionalBranch');
        my $assignment = $element->branches->[0]{actions}[0];
        my $target = extract_target_name($assignment);
        $conditional_by_target{$target} = $element if defined $target;
    }

    return \%conditional_by_target;
}

sub state_elements {
    my ($fsm_module, $state_name) = @_;
    my ($state) = grep { $_->name eq $state_name } @{ $fsm_module->states || [] };
    ok($state, "found state '$state_name'");
    return [] unless $state;

    my @elements;
    for my $dt (@{ $state->decision_trees || [] }) {
        push @elements, @{ $dt->elements || [] };
    }
    return \@elements;
}

sub extract_target_name {
    my ($assignment) = @_;
    return undef unless $assignment && $assignment->can('target');
    my $target = $assignment->target;
    return undef unless $target;

    if ($target->can('signal') && $target->signal && $target->signal->can('name')) {
        return $target->signal->name;
    }

    return undef;
}

sub is_literal_assignment {
    my ($assignment, $expected_value, $expected_width, $label) = @_;
    ok($assignment, "$label assignment exists");
    return unless $assignment;

    ok($assignment->source->isa('FSM::CoreAST::Literal'), "$label source is stored as a literal");
    return unless $assignment->source->isa('FSM::CoreAST::Literal');

    is($assignment->source->value, $expected_value, "$label value matches");
    if (defined $expected_width) {
        is($assignment->source->width, $expected_width, "$label width matches");
    } else {
        ok(!defined($assignment->source->width), "$label width remains implicit");
    }
}

sub assert_condition_equality {
    my ($condition, $lhs_name, $rhs_value, $label) = @_;
    ok($condition && $condition->isa('FSM::CoreAST::BinaryOp'), "$label condition is a BinaryOp");
    return unless $condition && $condition->isa('FSM::CoreAST::BinaryOp');

    is($condition->operator, '==', "$label uses equality comparison");
    ok($condition->left->isa('FSM::CoreAST::SignalRef'), "$label left operand is a signal reference");
    ok($condition->right->isa('FSM::CoreAST::Literal'), "$label right operand is a literal");
    return unless $condition->left->isa('FSM::CoreAST::SignalRef') && $condition->right->isa('FSM::CoreAST::Literal');

    is($condition->left->signal->name, $lhs_name, "$label left signal matches");
    is($condition->right->value, $rhs_value, "$label right literal matches");
}

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
