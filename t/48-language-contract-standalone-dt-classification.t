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

subtest 'general/combinational DT blocks now keep explicit standalone_dt classification' => sub {
    my $fsm_module = parse_fsm_module(<<'FSM');
(?fsm:standalone_dt_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (REG_OUT 1)
    (DT_OUT 1)
    (IN 1)
  )
  (idle
    (REG_OUT <= IN)
  )
  (-misc
    (DT_OUT = REG_OUT)
  )
  (-mycombDT
    (DT_OUT = 0)
  )
)
FSM

    my @states = @{$fsm_module->states || []};
    is(scalar(@states), 3, 'FSM keeps one FSM-state DT plus two standalone DT blocks');

    my ($regular_state) = grep { $_->name eq 'idle' } @states;
    my ($misc_dt) = grep { $_->name eq '-misc' } @states;
    my ($comb_dt) = grep { $_->name eq '-mycombDT' } @states;

    ok($regular_state, 'regular FSM-state DT stays present');
    ok($misc_dt, 'first standalone DT block stays present');
    ok($comb_dt, 'second standalone DT block stays present');

    is($regular_state->state_type, 'normal', 'regular FSM-state DT keeps normal state_type');
    is($misc_dt->state_type, 'standalone_dt', 'hyphen-prefixed general DT gets standalone_dt state_type');
    is($comb_dt->state_type, 'standalone_dt', 'another hyphen-prefixed general DT also gets standalone_dt state_type');

    ok($regular_state->is_regular_state, 'regular FSM-state DT stays in the encoded-state family');
    ok(!$regular_state->can('is_standalone_dt') || !$regular_state->is_standalone_dt, 'regular FSM-state DT is not marked as standalone');
    ok(!$misc_dt->is_regular_state, 'standalone DT is not treated as a regular encoded state');
    ok($misc_dt->is_standalone_dt, 'standalone DT is marked explicitly');
    ok(!$comb_dt->is_regular_state, 'second standalone DT is not treated as a regular encoded state');
    ok($comb_dt->is_standalone_dt, 'second standalone DT is marked explicitly');
};

subtest 'general/combinational DT blocks stay out of the encoded state plan and use DT-style enables' => sub {
    my $fsm_module = parse_fsm_module(<<'FSM');
(?fsm:standalone_dt_enable_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (REG_OUT 1)
    (DT_OUT 1)
    (IN 1)
  )
  (idle
    (REG_OUT <= IN)
  )
  (-misc
    (DT_OUT = REG_OUT)
  )
)
FSM

    my $hdl_gen = FSM::HDL::FlattenedDT->new(debug => 0);
    my $hdl = $hdl_gen->generate_systemverilog($fsm_module);
    my $state_plan = $hdl_gen->{enable_graph}->build_state_register_plan($fsm_module);

    ok($state_plan->{has_state_registers}, 'regular state plan stays enabled when a real FSM state exists');
    is($state_plan->{state_count}, 1, 'standalone DT blocks do not count as encoded states');
    is(join(',', map { $_->{localparam_name} } @{$state_plan->{encodings} || []}), 'IDLE', 'state encodings include only the FSM-state DT');

    ok(exists $hdl_gen->{state_enables}->{idle}, 'FSM-state DT keeps a regular state enable');
    ok(!exists $hdl_gen->{state_enables}->{'-misc'}, 'standalone DT does not get a regular-state enable');
    ok(exists $hdl_gen->{dt_enables}->{'-misc'}, 'standalone DT gets a DT-style enable');

    like($hdl, qr/\bassign\s+misc_en\s*=\s*1'b1\s*;/, 'generated HDL emits a DT-style enable for the standalone DT');
    unlike($hdl, qr/current_state\s*==\s*MISC/, 'generated HDL does not encode the standalone DT as a regular state');
};

done_testing();

sub parse_fsm_module {
    my ($fsm_text) = @_;
    my $fsm_path = File::Spec->catfile($tempdir, 'standalone_dt_' . int(rand(1_000_000)) . '.fsm');
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
