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

subtest 'legacy non-state DT aliases normalize to the same internal identities' => sub {
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

    ok(!$sync_reset_state->is_regular_state, 'first alias is not treated as a regular encoded state');
    ok(!$async_reset_state->is_regular_state, 'second alias is not treated as a regular encoded state');
    ok($sync_reset_state->is_standalone_dt, 'first alias participates in the non-state DT family');
    ok($async_reset_state->is_standalone_dt, 'second alias participates in the non-state DT family');
    ok($regular_state->is_regular_state, 'ordinary state stays part of the regular-state set');
};

subtest 'legacy non-state DT aliases stay out of the encoded state plan and generate guarded DT-style enables' => sub {
    my $fsm_module = parse_fsm_module(<<'FSM');
(?fsm:reset_state_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (force_sync 1)
    (force_async 1)
    (RESET_SYNC_OUT 1)
    (RESET_ASYNC_OUT 1)
    (REG_OUT 1)
    (IN 1)
  )
  (-syncrst <force_sync
    (<!rstn
      (RESET_SYNC_OUT <= 0)
    )
  )
  (-asyncreset <!force_async
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
    is($state_plan->{state_count}, 1, 'legacy aliases do not count as encoded states');
    is($state_plan->{reset_state_name}, 'S0', 'regular state reset target stays the first regular state');
    is(join(',', map { $_->{localparam_name} } @{$state_plan->{encodings} || []}), 'S0', 'state encodings exclude legacy aliases');

    ok(!exists $hdl_gen->{state_enables}->{syncreset}, 'first alias does not get a regular-state enable');
    ok(!exists $hdl_gen->{state_enables}->{asyncreset}, 'second alias does not get a regular-state enable');
    ok(exists $hdl_gen->{dt_enables}->{syncreset}, 'first alias gets a DT-style enable');
    ok(exists $hdl_gen->{dt_enables}->{asyncreset}, 'second alias gets a DT-style enable');

    like($hdl, qr/\bassign\s+syncreset_en\s*=\s*force_sync\s*;/, 'generated HDL emits a shared-rendered guarded DT-style enable for syncreset');
    like($hdl, qr/\bassign\s+asyncreset_en\s*=\s*!force_async\s*;/, 'generated HDL emits a shared-rendered guarded DT-style enable for asyncreset');
    unlike($hdl, qr/current_state\s*==\s*SYNCRESET/, 'generated HDL does not encode syncreset as a regular state');
    unlike($hdl, qr/current_state\s*==\s*ASYNCRESET/, 'generated HDL does not encode asyncreset as a regular state');
};

subtest 'legacy non-state DT aliases are accepted in standalone ?dt roots' => sub {
    my $fsm_module = parse_fsm_module(<<'FSM');
(?dt:reset_named_dt_root_contract
  (+size
    (force_sync 1)
    (OUT 1)
    (IN 1)
  )
  (-syncrst <force_sync
    (= (OUT 0))
  )
  (-route
    (= (OUT IN))
  )
)
FSM

    my @states = @{$fsm_module->states || []};
    is(scalar(@states), 2, 'standalone DT root keeps the alias plus the ordinary non-state DT');

    my ($sync_reset_dt) = grep { $_->name eq 'syncreset' } @states;
    my ($route_dt) = grep { $_->name eq '-route' } @states;

    ok($sync_reset_dt, 'alias is present in the standalone DT root');
    ok($route_dt, 'ordinary non-state DT is present in the standalone DT root');
    ok($sync_reset_dt->is_standalone_dt, 'alias uses the non-state DT root path');
    ok($route_dt->is_standalone_dt, 'ordinary non-state DT uses the non-state DT root path');

    my $hdl_gen = FSM::HDL::FlattenedDT->new(debug => 0);
    my $hdl = $hdl_gen->generate_systemverilog($fsm_module);

    ok(exists $hdl_gen->{dt_enables}->{syncreset}, 'standalone ?dt root registers alias DT enable');
    like($hdl, qr/\bassign\s+syncreset_en\s*=\s*force_sync\s*;/, 'standalone ?dt root emits the alias DT header guard through shared AST rendering');
    unlike($hdl, qr/current_state\s*==\s*SYNCRESET/, 'standalone ?dt root does not encode aliases as states');
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
