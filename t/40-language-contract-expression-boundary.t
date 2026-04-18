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
use FSM::HDL::FlattenedDT;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'unknown RHS expression operators are rejected explicitly' => sub {
    my $fsm_path = write_fsm('unknown_rhs_operator.fsm', <<'FSM');
(?fsm:unknown_rhs_operator
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

    my $error = parse_error_for($fsm_path);
    like($error, qr/Unsupported expression operator 'bogus'/, 'unknown RHS operator gets a targeted diagnostic');
};

subtest 'inline scalar comparison tokens remain supported inside expressions' => sub {
    my $fsm_path = write_fsm('inline_scalar_comparison.fsm', <<'FSM');
(?fsm:inline_scalar_comparison
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (MATCH 1)
    (cnt 3)
  )
  (-dt
    (MATCH = cnt[2:1]!=2'2)
  )
)
FSM

    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $fsm_module = $adapter->parse_fsm($raw_ast);
    ok($fsm_module, 'inline scalar comparison fixture parses successfully');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bcnt\[2:1\]\s*!=\s*2(?:'d)?2\b/, 'generated HDL preserves the inline scalar comparison semantics');
};

subtest 'negated n-ary bitwise expression families lower through ordinary AST operators' => sub {
    my $fsm_path = write_fsm('negated_nary_rhs_ops.fsm', <<'FSM');
(?fsm:negated_nary_rhs_ops
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (B 1)
    (C 1)
    (D 1)
    (E 1)
  )
  (-dt
    (A = (!& B C))
    (D = (!| B C))
    (E = (xnor B C))
  )
)
FSM

    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $fsm_module = $adapter->parse_fsm($raw_ast);
    ok($fsm_module, 'negated n-ary RHS fixture parses successfully');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bwire intermediate_and_B_C_1;/, 'negated and declares the parser-created intermediate carrier');
    like($hdl, qr/\bassign intermediate_and_B_C_1 = B & C; \/\/ Source: fsmgen_parsing\b/, 'negated and lowers through an ordinary bitwise-and AST');
    like($hdl, qr/\bassign intermediate_or_B_C_2 = B \| C; \/\/ Source: fsmgen_parsing\b/, 'negated or lowers through an ordinary bitwise-or AST');
    like($hdl, qr/\bassign intermediate_xor_B_C_3 = B \^ C; \/\/ Source: fsmgen_parsing\b/, 'xnor alias lowers through an ordinary bitwise-xor AST');
    like($hdl, qr/A = !\(intermediate_and_B_C_1\);/, 'negated n-ary operators lower through unary not over the factored intermediate');
};

subtest 'malformed active RHS operator arity is rejected explicitly' => sub {
    my $fsm_path = write_fsm('bad_rhs_arity.fsm', <<'FSM');
(?fsm:bad_rhs_arity
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 8)
    (B 8)
    (C 8)
    (D 8)
  )
  (-dt
    (A = (== B))
  )
)
FSM

    my $error = parse_error_for($fsm_path);
    like($error, qr/Malformed expression operator '==' with 1 operand\(s\)/, 'bad RHS equality arity gets a targeted diagnostic');
};

subtest 'invalid RHS scalar tokens are rejected explicitly' => sub {
    my $fsm_path = write_fsm('bad_rhs_scalar.fsm', <<'FSM');
(?fsm:bad_rhs_scalar
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 8)
    (B 8)
  )
  (-dt
    (A = <start)
  )
)
FSM

    my $error = parse_error_for($fsm_path);
    like($error, qr/Unsupported expression token '<start'/, 'guard-like RHS scalar gets a targeted diagnostic');
};

done_testing();

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}

sub parse_error_for {
    my ($fsm_path) = @_;
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);

    my $error = eval {
        $adapter->parse_fsm($raw_ast);
        undef;
    };
    $error = $@;
    ok($error, "parse fails for '$fsm_path'");
    return $error;
}
