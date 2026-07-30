#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT::Backend::VHDL;
use FSM::Pipeline::HDLGenerator;
use FSM::ProjectDataLocality qw(configure_project_temp_environment create_project_tempdir repository_root);

my $repo_root = repository_root();
configure_project_temp_environment(purpose => 'tests');
my $workspace = create_project_tempdir(purpose => 'tests');

subtest 'public scalar and vector truthiness lower without foreign tokens' => sub {
    my $path = File::Spec->catfile($workspace, 'direct_vhdl_reduction_truthiness.fsm');
    write_file(
        $path,
        <<'FSM'
(?fsm:direct_vhdl_reduction_truthiness
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (SCALAR 1)
    (VECTOR 4)
    (SCALAR_SEEN 1)
    (VECTOR_SEEN 1)
    (SCALAR_CLEAR 1)
    (VECTOR_CLEAR 1)
  )
  (idle
    (<SCALAR (= (SCALAR_SEEN 1)))
    (<VECTOR (= (VECTOR_SEEN 1)))
    (<!SCALAR (= (SCALAR_CLEAR 1)))
    (<!VECTOR (= (VECTOR_CLEAR 1)))
  )
)
FSM
    );

    my $systemverilog = generate_hdl($path, 'systemverilog');
    like(
        $systemverilog,
        qr/assign idle_scalar_seen_1_en = idle_en & SCALAR;/,
        'scalar nonzero truthiness is already emitted as scalar identity',
    );
    like(
        $systemverilog,
        qr/assign idle_scalar_clear_1_en = idle_en & !SCALAR;/,
        'scalar zero truthiness is already emitted as scalar complement',
    );
    like(
        $systemverilog,
        qr/assign idle_vector_seen_1_en = idle_en & \(\|VECTOR\);/,
        'vector nonzero truthiness emits unary reduction OR',
    );
    like(
        $systemverilog,
        qr/assign idle_vector_clear_1_en = idle_en & \(~\|VECTOR\);/,
        'vector zero truthiness emits complemented unary reduction OR',
    );

    my $scalar_path = File::Spec->catfile($workspace, 'direct_vhdl_scalar_reduction_truthiness.fsm');
    write_file(
        $scalar_path,
        <<'FSM'
(?fsm:direct_vhdl_scalar_reduction_truthiness
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (SCALAR 1)
    (SCALAR_SEEN 1)
    (SCALAR_CLEAR 1)
  )
  (idle
    (<SCALAR (= (SCALAR_SEEN 1)))
    (<!SCALAR (= (SCALAR_CLEAR 1)))
  )
)
FSM
    );
    my $vhdl = generate_hdl($scalar_path, 'vhdl');
    like(
        $vhdl,
        qr/idle_scalar_seen_1_en <= idle_en and SCALAR;/,
        'direct VHDL preserves scalar identity truthiness',
    );
    like(
        $vhdl,
        qr/idle_scalar_clear_1_en <= idle_en and not SCALAR;/,
        'direct VHDL preserves scalar complement truthiness',
    );
    my $vector_vhdl = generate_hdl($path, 'vhdl');
    like(
        $vector_vhdl,
        qr/idle_vector_seen_1_en <= idle_en and \(fsmgen_direct_vhdl_reduce_or\(VECTOR\)\);/,
        'vector truthiness lowers through the backend-owned OR fold',
    );
    like(
        $vector_vhdl,
        qr/idle_vector_clear_1_en <= idle_en and \(not fsmgen_direct_vhdl_reduce_or\(VECTOR\)\);/,
        'complemented vector truthiness applies not to the folded result',
    );
};

subtest 'converter matrix lowers scalar and vector OR AND XOR reductions' => sub {
    my $backend = FSM::HDL::FlattenedDT::Backend::VHDL->new(
        flattened_dt => bless({}, 'FSMGenReductionAuditDummy'),
    );

    my @cases;
    for my $operator ('|', '&', '^') {
        push @cases,
            ["scalar unary $operator", '', "(${operator}X)", output => qr/Y <= \(X\);/],
            ["scalar complemented unary $operator", '', "(~${operator}X)", output => qr/Y <= \(not X\);/],
            ["vector unary $operator", '[3:0] ', "(${operator}X)", output => vector_pattern($operator, 0)],
            ["vector complemented unary $operator", '[3:0] ', "(~${operator}X)", output => vector_pattern($operator, 1)];
    }

    for my $case (@cases) {
        my ($label, $range, $expression, $expectation, $pattern) = @$case;
        my $systemverilog = <<"SV";
module reduction_matrix (
  input wire ${range}X
);
wire Y;
assign Y = $expression;
endmodule
SV

        my ($vhdl, $error);
        my $ok = eval {
            $vhdl = $backend->convert_systemverilog_to_vhdl($systemverilog);
            1;
        };
        $error = $@ unless $ok;

        if ($expectation eq 'output') {
            ok($ok, "$label lowers");
            like($vhdl, $pattern, "$label has the selected fold or scalar semantics");
        }
        else {
            ok(!$ok, "$label fails closed");
            like($error, $pattern, "$label names the vector reduction boundary");
        }
    }
};

subtest 'vector helpers use explicit four-state std_logic folds' => sub {
    my $backend = FSM::HDL::FlattenedDT::Backend::VHDL->new(
        flattened_dt => bless({}, 'FSMGenReductionHelperContractDummy'),
    );
    my $systemverilog = <<'SV';
module reduction_helper_contract (
  input wire [3:0] X
);
wire OR_Y;
wire AND_Y;
wire XOR_Y;
assign OR_Y = (|X);
assign AND_Y = (&X);
assign XOR_Y = (^X);
endmodule
SV
    my $vhdl = $backend->convert_systemverilog_to_vhdl($systemverilog);
    for my $case (
        ['or',  '0'],
        ['and', '1'],
        ['xor', '0'],
    ) {
        my ($operator, $identity) = @$case;
        like(
            $vhdl,
            qr/function fsmgen_direct_vhdl_reduce_$operator\(value : std_logic_vector\) return std_logic is\s+variable result : std_logic := '$identity';\s+begin\s+for index in value'range loop\s+result := result $operator value\(index\);\s+end loop;\s+return result;\s+end function fsmgen_direct_vhdl_reduce_$operator;/s,
            "vector $operator helper folds std_logic from the correct identity",
        );
    }
    unlike(
        $vhdl,
        qr/<=\s*\(~?[|&^]X\)/,
        'helper-backed output contains no SystemVerilog reduction token',
    );
};

subtest 'static bit selects lower and every other operand shape fails closed' => sub {
    my $backend = FSM::HDL::FlattenedDT::Backend::VHDL->new(
        flattened_dt => bless({}, 'FSMGenReductionOperandContractDummy'),
    );

    for my $operator ('|', '&', '^') {
        for my $complement ('', '~') {
            my $expression = "(${complement}${operator}X[2])";
            my $vhdl = convert_expression(
                $backend,
                "input wire [3:0] X",
                $expression,
            );
            my $expected = $complement ? 'Y <= (not X(2));' : 'Y <= (X(2));';
            like(
                $vhdl,
                qr/\Q$expected\E/,
                "$expression lowers through the static bit-select contract",
            );
        }
    }

    my @unsupported = (
        ["(|X[2:2])", "input wire [3:0] X", qr/operand 'X\[2:2\]' is a 1-bit range slice/],
        ["(|X[5])", "input wire [3:0] X", qr/operand 'X\[5\]' selects outside declared range \[3:0\]/],
        ["(|X[0])", "input wire X", qr/operand 'X\[0\]' selects a scalar declaration/],
        ["(|UNKNOWN)", "input wire X", qr/operand 'UNKNOWN' has no resolved declaration/],
        ["(|(X & X))", "input wire X", qr/operand shape is unresolved or compound/],
        ["(|X[INDEX])", "input wire [3:0] X,\n  input wire [1:0] INDEX", qr/operand shape is unresolved or compound/],
    );

    for my $case (@unsupported) {
        my ($expression, $declarations, $pattern) = @$case;
        my $error;
        my $ok = eval {
            convert_expression($backend, $declarations, $expression);
            1;
        };
        $error = $@ unless $ok;
        ok(!$ok, "$expression fails closed");
        like($error, $pattern, "$expression receives its targeted operand diagnostic");
    }

    my $signed_vhdl = convert_expression(
        $backend,
        'input logic signed [3:0] X',
        '(^X)',
    );
    like(
        $signed_vhdl,
        qr/Y <= \(fsmgen_direct_vhdl_reduce_xor\(std_logic_vector\(X\)\)\);/,
        'signed vector reduction casts explicitly into the std_logic fold helper',
    );

    my $collision_error;
    my $collision_ok = eval {
        convert_expression(
            $backend,
            "input wire [3:0] X,\n  input wire fsmgen_direct_vhdl_reduce_or",
            '(|X)',
        );
        1;
    };
    $collision_error = $@ unless $collision_ok;
    ok(!$collision_ok, 'vector helper name collision fails closed');
    like(
        $collision_error,
        qr/vector reduction helper name 'fsmgen_direct_vhdl_reduce_or' collides with a generated declaration/,
        'helper collision receives the targeted direct-scaffold diagnostic',
    );
};

subtest 'condition conversion receives declaration context' => sub {
    my $backend = FSM::HDL::FlattenedDT::Backend::VHDL->new(
        flattened_dt => bless({}, 'FSMGenReductionConditionContractDummy'),
    );

    my $scalar_systemverilog = <<'SV';
module scalar_reduction_condition (
  input logic X,
  output reg Y
);
always_comb begin
  Y = 1'b0;
  if ((|X)) begin
    Y = 1'b1;
  end
end
endmodule
SV
    my $scalar_vhdl = $backend->convert_systemverilog_to_vhdl($scalar_systemverilog);
    like(
        $scalar_vhdl,
        qr/if \(\(X\)\) = '1' then/,
        'scalar reduction in a generated condition lowers with declaration context',
    );
    unlike(
        $scalar_vhdl,
        qr/function fsmgen_direct_vhdl_reduce_/,
        'scalar-only conditions do not emit an unused vector helper',
    );

    my $vector_systemverilog = $scalar_systemverilog;
    $vector_systemverilog =~ s/input logic X/input logic [3:0] X/;
    my $vector_vhdl = $backend->convert_systemverilog_to_vhdl($vector_systemverilog);
    like(
        $vector_vhdl,
        qr/if \(\(fsmgen_direct_vhdl_reduce_or\(X\)\)\) = '1' then/,
        'vector reduction in a generated condition uses the declaration-aware helper',
    );
    like(
        $vector_vhdl,
        qr/function fsmgen_direct_vhdl_reduce_or\(value : std_logic_vector\) return std_logic is/,
        'condition lowering emits its required vector helper',
    );
};

subtest 'explicit unary reduction source forms remain outside the public language' => sub {
    for my $case (
        ['or',  '|'],
        ['and', '&'],
        ['xor', '^'],
    ) {
        my ($name, $operator) = @$case;
        my $source = <<"FSM";
(?fsm:direct_vhdl_unary_${name}_source
  (+system (clock clk) (sreset reset))
  (+size (X 4) (Y 1))
  (idle (= (Y (${operator} X))))
)
FSM
        my $payload = failed_check_json($source, "direct_vhdl_unary_${name}_source.fsm");
        ok(!$payload->{success}, "explicit unary $name source is rejected");
        is($payload->{diagnostic_summary}{diagnostic_count}, 1, "explicit unary $name has one diagnostic");
        like(
            $payload->{diagnostics}[0]{message},
            qr/Malformed expression operator '\Q$operator\E' with 1 operand\(s\).*requires at least 2 operands/s,
            "explicit unary $name retains the n-ary arity boundary",
        );
    }
};

done_testing();

sub generate_hdl {
    my ($path, $target_language) = @_;
    return FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => $target_language,
        quiet => 1,
    )->generate_hdl_from_file($path)->{hdl_code};
}

sub convert_expression {
    my ($backend, $declarations, $expression) = @_;
    my $systemverilog = <<"SV";
module reduction_operand_contract (
  $declarations
);
wire Y;
assign Y = $expression;
endmodule
SV
    return $backend->convert_systemverilog_to_vhdl($systemverilog);
}

sub vector_pattern {
    my ($operator, $complement) = @_;
    my %names = (
        '|' => 'or',
        '&' => 'and',
        '^' => 'xor',
    );
    my $call = "fsmgen_direct_vhdl_reduce_$names{$operator}(X)";
    my $expression = $complement ? "(not $call)" : "($call)";
    return qr/Y <= \Q$expression\E;/;
}

sub failed_check_json {
    my ($source, $basename) = @_;
    my $path = File::Spec->catfile($workspace, $basename);
    write_file($path, $source);
    my ($success, undef, undef, $stdout, $stderr) = run(
        command => [
            File::Spec->catfile($repo_root, 'bin', 'fsmgen'),
            '--quiet', '--strict', '--check', '--json', $path,
        ],
    );
    ok(!$success, "$basename fails public check JSON");
    is(join('', @{$stderr || []}), '', "$basename keeps stderr clean");
    my $json = join('', @{$stdout || []});
    isnt($json, '', "$basename emits JSON on stdout");
    return decode_json($json);
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
}
