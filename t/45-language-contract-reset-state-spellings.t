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

subtest 'canonical and legacy reset-state spellings normalize to the same internal state identities' => sub {
    my $fsm_module = parse_fsm_module(<<'FSM');
(?fsm:reset_state_spellings
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (OUT 1)
    (IN 1)
  )
  (-syncreset
    (<!rstn
      (OUT <= 0)
    )
  )
  (-asyncreset
    (<!rstn
      (OUT <= 1)
    )
  )
  (s0
    (OUT = IN)
  )
)
FSM

    my @states = @{$fsm_module->states || []};
    is(scalar(@states), 3, 'FSM keeps the reset blocks plus one regular state');

    my ($sync_reset_state) = grep { $_->name eq 'syncreset' } @states;
    my ($async_reset_state) = grep { $_->name eq 'asyncreset' } @states;
    my ($regular_state) = grep { $_->name eq 's0' } @states;

    ok($sync_reset_state, 'legacy -syncreset spelling normalizes to syncreset');
    ok($async_reset_state, 'legacy -asyncreset spelling normalizes to asyncreset');
    ok($regular_state, 'regular state still stays present');

    is($sync_reset_state->state_type, 'sync_reset', 'legacy sync reset keeps sync_reset state_type');
    is($async_reset_state->state_type, 'async_reset', 'legacy async reset keeps async_reset state_type');
    is($regular_state->state_type, 'normal', 'regular state keeps normal state_type');

    ok(!$sync_reset_state->is_regular_state, 'sync reset block is not treated as a regular encoded state');
    ok(!$async_reset_state->is_regular_state, 'async reset block is not treated as a regular encoded state');
    ok($regular_state->is_regular_state, 'ordinary state stays part of the regular-state set');
};

subtest 'reset-state spellings stay out of the encoded state plan and generate DT-style enables' => sub {
    my $fsm_module = parse_fsm_module(<<'FSM');
(?fsm:reset_state_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (RESET_SYNC_OUT 1)
    (RESET_ASYNC_OUT 1)
    (REG_OUT 1)
    (IN 1)
  )
  (-syncrst
    (<!rstn
      (RESET_SYNC_OUT <= 0)
    )
  )
  (-asyncreset
    (<!rstn
      (RESET_ASYNC_OUT <= 1)
    )
  )
  (s0
    (REG_OUT <= IN)
  )
)
FSM

    my $hdl_gen = FSM::HDL::FlattenedDT->new(debug => 0);
    my $hdl = $hdl_gen->generate_systemverilog($fsm_module);
    my $state_plan = $hdl_gen->{enable_graph_module_planning_support}->build_state_register_plan($fsm_module);

    ok($state_plan->{has_state_registers}, 'regular state plan stays enabled when a regular state exists');
    is($state_plan->{state_count}, 1, 'reset blocks do not count as encoded states');
    is($state_plan->{reset_state_name}, 'S0', 'regular state reset target stays the first regular state');
    is(join(',', map { $_->{localparam_name} } @{$state_plan->{encodings} || []}), 'S0', 'state encodings exclude reset blocks');

    ok(!exists $hdl_gen->{state_enables}->{syncreset}, 'sync reset block does not get a regular-state enable');
    ok(!exists $hdl_gen->{state_enables}->{asyncreset}, 'async reset block does not get a regular-state enable');
    ok(exists $hdl_gen->{dt_enables}->{syncreset}, 'sync reset block gets a DT-style enable');
    ok(exists $hdl_gen->{dt_enables}->{asyncreset}, 'async reset block gets a DT-style enable');

    like($hdl, qr/\bassign\s+syncreset_en\s*=\s*1'b1\s*;/, 'generated HDL emits a DT-style enable for syncreset');
    like($hdl, qr/\bassign\s+asyncreset_en\s*=\s*1'b1\s*;/, 'generated HDL emits a DT-style enable for asyncreset');
    unlike($hdl, qr/current_state\s*==\s*SYNCRESET/, 'generated HDL does not encode syncreset as a regular state');
    unlike($hdl, qr/current_state\s*==\s*ASYNCRESET/, 'generated HDL does not encode asyncreset as a regular state');
};

done_testing();

sub parse_fsm_module {
    my ($fsm_text) = @_;
    my $fsm_path = File::Spec->catfile($tempdir, 'reset_state_' . int(rand(1_000_000)) . '.fsm');
    write_file($fsm_path, $fsm_text);

    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    return $adapter->parse_fsm($raw_ast);
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
