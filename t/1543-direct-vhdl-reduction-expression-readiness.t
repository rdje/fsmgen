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

subtest 'public scalar and vector truthiness expose the exact direct VHDL seam' => sub {
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

    my $vhdl = generate_hdl($path, 'vhdl');
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
    like(
        $vhdl,
        qr/idle_vector_seen_1_en <= idle_en and \(\|VECTOR\);/,
        'current direct VHDL leaks vector unary reduction OR',
    );
    like(
        $vhdl,
        qr/idle_vector_clear_1_en <= idle_en and \(~\|VECTOR\);/,
        'current direct VHDL leaks complemented vector unary reduction OR',
    );
};

subtest 'converter matrix characterizes scalar and vector OR AND XOR reductions' => sub {
    my $backend = FSM::HDL::FlattenedDT::Backend::VHDL->new(
        flattened_dt => bless({}, 'FSMGenReductionAuditDummy'),
    );

    my @cases = (
        [scalar => '',      '|', output => qr/Y <= \(\|X\);/],
        [scalar => '',      '&', output => qr/Y <= \( and X\);/],
        [scalar => '',      '^', error  => qr/arithmetic expression '\(\^X\)' is outside the direct VHDL scaffold/],
        [vector => '[3:0] ', '|', output => qr/Y <= \(\|X\);/],
        [vector => '[3:0] ', '&', output => qr/Y <= \( and X\);/],
        [vector => '[3:0] ', '^', error  => qr/arithmetic expression '\(\^X\)' is outside the direct VHDL scaffold/],
    );

    for my $case (@cases) {
        my ($shape, $range, $operator, $expectation, $pattern) = @$case;
        my $systemverilog = <<"SV";
module reduction_$shape (
  input wire ${range}X
);
wire Y;
assign Y = (${operator}X);
endmodule
SV

        my ($vhdl, $error);
        my $ok = eval {
            $vhdl = $backend->convert_systemverilog_to_vhdl($systemverilog);
            1;
        };
        $error = $@ unless $ok;

        if ($expectation eq 'output') {
            ok($ok, "$shape unary $operator currently returns output");
            like($vhdl, $pattern, "$shape unary $operator current output is characterized");
        }
        else {
            ok(!$ok, "$shape unary $operator currently fails closed");
            like($error, $pattern, "$shape unary $operator current diagnostic is characterized");
        }
    }
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
