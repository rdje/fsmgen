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

subtest 'pipeline and CLI resolve embedded and external package imports for direct-root expressions' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $fsm_path = File::Spec->catfile($tempdir, 'direct_package_import_root.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_external.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_package_import_root.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_external
  (+constants
    (RESET_BYTE 8'hA5)
    (ZERO_BYTE 0)
  )
)
FSM
    );

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_package_import_root
  (+import shared_local shared_external)
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (SEL 8)
    (OUT 8)
    (FLAG 1)
    (BUSY_SEEN 1)
    (ZERO_SEEN 1)
  )
  (idle
    (OUT = shared_external.RESET_BYTE)
    (FLAG = shared_local.mode.BUSY)
    (BUSY_SEEN = 1 <SEL=shared_local.mode.BUSY)
    (ZERO_SEEN = 1 <SEL=shared_external.ZERO_BYTE)
  )
)

(?pkg:shared_local
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1)
    )
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

    is_deeply(
        $fsm_module->{attributes}{package_imports},
        [qw(shared_local shared_external)],
        'direct-root module records the explicit package import list',
    );
    is_deeply(
        [sort keys %{ $result->{resolved_package_imports} || {} }],
        [qw(shared_external shared_local)],
        'direct pipeline result reports resolved package imports',
    );
    is(
        $result->{source_info}{package_import_count},
        2,
        'direct pipeline result source_info reports imported package count',
    );
    is_deeply(
        $result->{source_info}{package_import_names},
        [qw(shared_local shared_external)],
        'direct pipeline result source_info preserves imported package names in authored order',
    );

    my %assignment_by_target = %{ assignments_by_target($fsm_module, 'idle') };
    is_literal_assignment($assignment_by_target{OUT}, 'A5', 8, 'OUT resolves imported package constant to a literal');
    is_literal_assignment($assignment_by_target{FLAG}, '1', undef, 'FLAG resolves imported package enum member to a literal');

    my %conditional_by_target = %{ conditionals_by_target($fsm_module, 'idle') };
    assert_condition_equality(
        $conditional_by_target{BUSY_SEEN}->condition,
        'SEL',
        '1',
        'package enum member resolves in direct-root condition context',
    );
    assert_condition_equality(
        $conditional_by_target{ZERO_SEEN}->condition,
        'SEL',
        '0',
        'package constant resolves in direct-root condition context',
    );

    like($hdl, qr/module\s+direct_package_import_root\b/s, 'pipeline still emits HDL for direct-root package imports');
    unlike($hdl, qr/shared_external\.RESET_BYTE|shared_local\.mode\.BUSY/s, 'generated HDL does not leak package symbol tokens');

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '-o', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});
    my $output_text = slurp_file($output_path);

    ok($success, 'CLI accepts direct-root package imports');
    ok(-e $output_path, 'CLI emits HDL for direct-root package imports');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for direct-root package imports');
    unlike($combined_output, qr/package-source .* blocked|Malformed '\+import'/s, 'successful CLI run does not report package-import failures');
    unlike($output_text, qr/shared_external\.RESET_BYTE|shared_local\.mode\.BUSY/s, 'CLI output also lowers package symbols away before emission');
};

subtest 'generated composition children may also use direct-root package imports' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $package_path = File::Spec->catfile($libdir, 'shared_external.fsm');
    my $child_path = File::Spec->catfile($libdir, 'producer.fsm');
    my $helper_path = File::Spec->catfile($libdir, 'helper.fsm');
    my $composition_path = File::Spec->catfile($tempdir, 'child_package_import_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'child_package_import_top.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_external
  (+constants
    (RESET_BYTE 8'hA5)
    (FLAG_ONE 1)
  )
)
FSM
    );

    write_file(
        $child_path,
        <<'FSM'
(?fsm:producer
  (+import shared_external)
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (out_byte 8)
    (flag 1)
  )
  (idle
    (out_byte> = shared_external.RESET_BYTE)
    (flag> = shared_external.FLAG_ONE)
  )
)
FSM
    );

    write_file(
        $helper_path,
        <<'FSM'
(?fsm:helper
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (helper_flag 1)
  )
  (idle
    (helper_flag> = 1)
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:child_package_import_top
  (?ports:public_io
    child_out>8
    child_flag>
    helper_seen>
  )
  (?fsmc:producer)
  (?fsmc:helper)
  (?toplink:wiring
    /producer.out_byte/child_out/
    /producer.flag/child_flag/
    /helper.helper_flag/helper_seen/
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
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $hdl = $result->{hdl_code};

    like($hdl, qr/module\s+producer\b/s, 'composition result includes generated child HDL');
    unlike($hdl, qr/shared_external\.RESET_BYTE|shared_external\.FLAG_ONE/s, 'generated child HDL lowers imported package symbols before composition emission');

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '-o', $output_path, $composition_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});
    my $output_text = slurp_file($output_path);

    ok($success, 'CLI accepts generated-child sources that use package imports');
    ok(-e $output_path, 'CLI emits HDL for composition tops with package-backed generated children');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for package-backed generated children');
    unlike($combined_output, qr/package-source .* blocked|Malformed '\+import'/s, 'successful generated-child CLI run does not report package-import failures');
    unlike($output_text, qr/shared_external\.RESET_BYTE|shared_external\.FLAG_ONE/s, 'CLI output for package-backed generated children also lowers package symbols away');
};

subtest 'pipeline and CLI reject malformed direct-root +import package names' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'bad_direct_import_name.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_direct_import_name.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:bad_direct_import_name
  (+import bad-name)
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (OUT = 1)
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
        qr/Malformed '\+import' package name 'bad-name' in source '\?fsm:bad_direct_import_name'/s,
        'pipeline reports the direct-root +import token boundary explicitly',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '-o', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok(!$success, 'CLI rejects malformed direct-root +import package names');
    ok(!-e $output_path, 'CLI does not emit HDL for malformed direct-root +import package names');
    like(
        $combined_output,
        qr/Malformed '\+import' package name 'bad-name' in source '\?fsm:bad_direct_import_name'/s,
        'CLI surfaces the same direct-root +import token boundary',
    );
    isnt($error_code, 0, 'CLI exits non-zero for malformed direct-root +import package names');
};

subtest 'standalone dt roots may also use direct-root package imports' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $dt_path = File::Spec->catfile($tempdir, 'dt_package_import_root.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_external.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'dt_package_import_root.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_external
  (+constants
    (RESET_BYTE 8'hA5)
  )
)
FSM
    );

    write_file(
        $dt_path,
        <<'FSM'
(?dt:dt_package_import_root
  (+import shared_external)
  (+size
    (OUT 8)
  )
  (-route
    (OUT> = shared_external.RESET_BYTE)
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
    my $result = $pipeline->generate_hdl_from_file($dt_path);
    my $hdl = $result->{hdl_code};

    is_deeply(
        $result->{fsm_module}{attributes}{package_imports},
        ['shared_external'],
        'standalone dt root also records the explicit package import list',
    );
    is_deeply(
        [sort keys %{ $result->{resolved_package_imports} || {} }],
        ['shared_external'],
        'standalone dt pipeline result also reports resolved package imports',
    );
    unlike($hdl, qr/shared_external\.RESET_BYTE/s, 'standalone dt HDL also lowers imported package symbols before emission');

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '-o', $output_path, $dt_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $output_text = slurp_file($output_path);

    ok($success, 'CLI accepts standalone dt package imports');
    ok(-e $output_path, 'CLI emits HDL for standalone dt package imports');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for standalone dt package imports');
    unlike($output_text, qr/shared_external\.RESET_BYTE/s, 'standalone dt CLI output also lowers imported package symbols before emission');
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
