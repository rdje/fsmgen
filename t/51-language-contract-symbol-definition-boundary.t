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

subtest 'empty symbol-definition sections are rejected explicitly' => sub {
    my $constants_error = parse_failure(<<'FSM');
(?fsm:empty_constants_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants)
  (-dt
    (OUT = 1)
  )
)
FSM
    like($constants_error, qr/Malformed '\+constants' section/, 'empty +constants gets a targeted section diagnostic');

    my $define_error = parse_failure(<<'FSM');
(?fsm:empty_define_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+define)
  (-dt
    (OUT = 1)
  )
)
FSM
    like($define_error, qr/Malformed '\+define' directive/, 'empty +define gets a targeted directive diagnostic');

    my $params_error = parse_failure(<<'FSM');
(?fsm:empty_params_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+params)
  (-dt
    (OUT = 1)
  )
)
FSM
    like($params_error, qr/Malformed '\+params' section/, 'empty +params gets a targeted section diagnostic');

    my $enums_error = parse_failure(<<'FSM');
(?fsm:empty_enums_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+enums)
  (-dt
    (OUT = 1)
  )
)
FSM
    like($enums_error, qr/Malformed '\+enums' section/, 'empty +enums gets a targeted section diagnostic');
};

subtest 'malformed symbol-definition entries are rejected explicitly' => sub {
    my $constants_entry_error = parse_failure(<<'FSM');
(?fsm:bad_constants_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants
    BROKEN
  )
  (-dt
    (OUT = 1)
  )
)
FSM
    like($constants_entry_error, qr/Malformed '\+constants' entry/, 'bad +constants payload gets a targeted entry diagnostic');

    my $define_entry_error = parse_failure(<<'FSM');
(?fsm:bad_define_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+define
    (D0)
  )
  (-dt
    (OUT = 1)
  )
)
FSM
    like($define_entry_error, qr/Malformed '\+define'/, 'short +define entry gets a targeted diagnostic');

    my $params_entry_error = parse_failure(<<'FSM');
(?fsm:bad_params_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+params
    (P0)
  )
  (-dt
    (OUT = 1)
  )
)
FSM
    like($params_entry_error, qr/Malformed '\+params' entry/, 'short +params entry gets a targeted diagnostic');

    my $enums_member_error = parse_failure(<<'FSM');
(?fsm:bad_enums_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+enums
    (mode
      BROKEN
    )
  )
  (-dt
    (OUT = 1)
  )
)
FSM
    like($enums_member_error, qr/Malformed '\+enums' member for enum 'mode'/, 'bad enum member payload gets a targeted diagnostic');
};

subtest 'unresolved parameter value names are rejected before generation' => sub {
    my $params_symbol_error = parse_failure(<<'FSM');
(?fsm:bad_param_symbol_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+params
    (P_BAD NO_SUCH_SYMBOL)
  )
  (-dt
    (OUT = 1)
  )
)
FSM
    like(
        $params_symbol_error,
        qr/Direct source parameter 'P_BAD'.*parameter\/generic values currently accept scalar integer literals.*NO_SUCH_SYMBOL/s,
        'unresolved +params value names remain invalid semantic values'
    );
};

subtest 'scalar parameter expressions reject aggregate operands before generation' => sub {
    my $params_aggregate_operand_error = parse_failure(<<'FSM');
(?fsm:bad_param_expression_operand_contract
  (+constants
    (LANES (8'hA5 8'h3C))
  )
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+params
    (P_BAD (+ LANES 1))
  )
  (-dt
    (OUT = 1)
  )
)
FSM
    like(
        $params_aggregate_operand_error,
        qr/Direct source parameter 'P_BAD' expression operand for '\+'.*scalar parameter\/generic expressions may use only scalar operands.*resolved to 'list'/s,
        'scalar +params expressions reject aggregate operands before generation'
    );
};

subtest 'cyclic parameter value references are rejected before generation' => sub {
    my $params_cycle_error = parse_failure(<<'FSM');
(?fsm:cyclic_param_symbol_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+params
    (P_A P_B)
    (P_B P_A)
  )
  (-dt
    (OUT = 1)
  )
)
FSM
    like(
        $params_cycle_error,
        qr/Malformed '\+params' dependency graph.*parameter dependency cycles are blocked.*parameter 'P_A' -> parameter 'P_B' -> parameter 'P_A'/s,
        'cyclic +params references get a targeted dependency-graph diagnostic'
    );
};

subtest 'duplicate parameter declarations are rejected before generation' => sub {
    my $params_duplicate_error = parse_failure(<<'FSM');
(?fsm:duplicate_param_symbol_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+params
    (P_A 1)
    (P_A 2)
  )
  (-dt
    (OUT = 1)
  )
)
FSM
    like(
        $params_duplicate_error,
        qr/Malformed '\+params' entry for parameter 'P_A'.*may bind a parameter\/generic name at most once/s,
        'duplicate +params declarations get a targeted uniqueness diagnostic'
    );
};

subtest 'pipeline and CLI do not emit HDL for malformed symbol-definition sections' => sub {
    my $fsm_path = write_fsm('bad_symbols_cli.fsm', <<'FSM');
(?fsm:bad_symbols_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+enums
    (mode
      BROKEN
    )
  )
  (-dt
    (OUT = 1)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, 'pipeline rejects malformed +enums payload');
    like($pipeline_error, qr/Malformed '\+enums' member for enum 'mode'/, 'pipeline surfaces the explicit +enums boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bad_symbols_cli.sv');
    my $success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $out_path, $fsm_path) == 0;
    ok(!$success, 'CLI rejects malformed +enums payload');
    ok(!-e $out_path, 'CLI does not emit output for malformed +enums payload');
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
    ok($error, "parse fails for generated fixture");
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
