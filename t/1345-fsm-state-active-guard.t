#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;

subtest 'state_active guard reaches HDL without fake input ports' => sub {
    my $hdl = hdl_from_fsm(<<'FSM');
(?fsm:state_active_guard
  (+system
    (clock clk)
    (sreset rst_n)
  )
  (+interface
    (output out)
  )
  (s0
    (-> s1)
  )
  (s1
    (-> s1)
  )
  (-force
    (<- (out> 1) <(! (state_active s1)))
  )
)
FSM

    like(
        $hdl,
        qr/\bassign\s+force_out_1_en\s*=\s*force_en\s*&\s*not_current_state_eq_const_S1\s*;/,
        'non-state DT assignment is guarded by inverse state activity',
    );
    like(
        $hdl,
        qr/\bassign\s+current_state_eq_const_S1\s*=\s*current_state\s*==\s*S1\s*;/,
        'state activity lowers to an internal current_state comparison',
    );
    unlike($hdl, qr/\binput\s+wire\s+current_state\b/, 'current_state is not exposed as an input');
    unlike($hdl, qr/\binput\s+wire\s+S1\b/, 'state enum literal is not exposed as an input');
    unlike($hdl, qr/\binput\s+wire\s+s1_en\b/, 'generated state enable is not exposed as an input');
};

subtest 'state_active validates referenced regular state' => sub {
    assert_fsm_rejected(<<'FSM', qr/State-active guard references unknown regular FSM state 'missing'/);
(?fsm:bad_state_active_guard
  (+system
    (clock clk)
    (sreset rst_n)
  )
  (+interface
    (output out)
  )
  (s0
    (-> s0)
  )
  (-force
    (<- (out> 1) <(! (state_active missing)))
  )
)
FSM
};

subtest 'state_active requires one scalar state name' => sub {
    assert_fsm_rejected(<<'FSM', qr/bounded state-active guard form requires exactly one FSM state name/);
(?fsm:malformed_state_active_guard
  (+system
    (clock clk)
    (sreset rst_n)
  )
  (+interface
    (output out)
  )
  (s0
    (-> s0)
  )
  (-force
    (<- (out> 1) <(! (state_active)))
  )
)
FSM
};

subtest 'state_active references do not leak across parser reuse' => sub {
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $parser = $adapter->{parser};

    my $bad_raw_ast = Lispish::multi(\<<'FSM');
(?fsm:bad_reused_state_active_guard
  (+system
    (clock clk)
    (sreset rst_n)
  )
  (+interface
    (output out)
  )
  (s0
    (-> s0)
  )
  (-force
    (<- (out> 1) <(! (state_active missing)))
  )
)
FSM

    my $bad_ok = eval {
        $parser->parse_fsm($bad_raw_ast);
        1;
    };
    ok(!$bad_ok, 'first reused-parser source is rejected');
    like(
        $@,
        qr/State-active guard references unknown regular FSM state 'missing'/,
        'first diagnostic is targeted',
    );

    my $good_raw_ast = Lispish::multi(\<<'FSM');
(?fsm:good_reused_state_active_guard
  (+system
    (clock clk)
    (sreset rst_n)
  )
  (+interface
    (output out)
  )
  (s0
    (-> s0)
  )
)
FSM

    my $good_module = eval { $parser->parse_fsm($good_raw_ast) };
    is($@, '', 'second reused-parser source is not contaminated by prior state_active failure');
    isa_ok($good_module, 'FSM::CoreAST::FSMModule');
};

done_testing();

sub hdl_from_fsm {
    my ($source) = @_;
    my $module = module_from_fsm($source);
    return FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($module);
}

sub module_from_fsm {
    my ($source) = @_;
    my $raw_ast = Lispish::multi(\$source);
    return FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast     => $raw_ast,
        debug_level => 0,
    );
}

sub assert_fsm_rejected {
    my ($source, $diagnostic_re) = @_;
    my $ok = eval {
        module_from_fsm($source);
        1;
    };

    ok(!$ok, 'source is rejected');
    like($@, $diagnostic_re, 'diagnostic is targeted');
}
