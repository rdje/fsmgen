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
my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
my $hdl_gen = FSM::HDL::FlattenedDT->new(debug => 0);

my $fsm_one = parse_fsm_module(
    $adapter,
    File::Spec->catfile($tempdir, 'reuse_alpha.fsm'),
    <<'FSM',
(?fsm:reuse_alpha
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-alpha_dt
    (OUTA = INA)
  )
  (+size
    (OUTA 1)
    (INA 1)
  )
)
FSM
);

my $hdl_one = $hdl_gen->generate_systemverilog($fsm_one);
my $state_plan_one = $hdl_gen->{enable_graph}->build_state_register_plan($fsm_one);

like(
    $hdl_one,
    qr/\bassign\s+alpha_dt_en\s*=\s*1'b1\s*;/,
    'first generation emits the first standalone DT enable',
);
ok(
    exists $hdl_gen->{dt_enables}->{'-alpha_dt'},
    'first generation records the first standalone DT enable in live state',
);
ok(
    ref($hdl_gen->{dt_enables}->{'-alpha_dt'}) && $hdl_gen->{dt_enables}->{'-alpha_dt'}->can('to_systemverilog'),
    'first generation stores the first standalone DT enable as an AST-backed condition',
);
is(
    $hdl_gen->{dt_enables}->{'-alpha_dt'}->to_systemverilog,
    "1'b1",
    'first generation keeps the standalone DT enable condition semantically true',
);
ok(
    !$state_plan_one->{has_state_registers},
    'standalone-DT-only generation keeps state register planning disabled',
);
is(
    scalar(@{$state_plan_one->{encodings} || []}),
    0,
    'standalone-DT-only generation exposes no state encodings in the state plan',
);
ok(
    exists $hdl_gen->{lhs_assignments}->{OUTA},
    'first generation records first-run lhs_assignments data',
);
ok(
    exists $hdl_gen->{assignment_analysis}->{OUTA},
    'first generation records first-run assignment analysis',
);

my $fsm_two = parse_fsm_module(
    $adapter,
    File::Spec->catfile($tempdir, 'reuse_beta.fsm'),
    <<'FSM',
(?fsm:reuse_beta
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-beta_dt
    (OUTB = INB)
  )
  (+size
    (OUTB 1)
    (INB 1)
  )
)
FSM
);

my $hdl_two = $hdl_gen->generate_systemverilog($fsm_two);
my $state_plan_two = $hdl_gen->{enable_graph}->build_state_register_plan($fsm_two);

ok(
    !exists $hdl_gen->{dt_enables}->{'-alpha_dt'},
    'second generation clears the first standalone DT enable from live state',
);
ok(
    exists $hdl_gen->{dt_enables}->{'-beta_dt'},
    'second generation records the second standalone DT enable in live state',
);
ok(
    ref($hdl_gen->{dt_enables}->{'-beta_dt'}) && $hdl_gen->{dt_enables}->{'-beta_dt'}->can('to_systemverilog'),
    'second generation stores the second standalone DT enable as an AST-backed condition',
);
is(
    $hdl_gen->{dt_enables}->{'-beta_dt'}->to_systemverilog,
    "1'b1",
    'second generation keeps the standalone DT enable condition semantically true',
);
ok(
    !$state_plan_two->{has_state_registers},
    'reused generation keeps state register planning disabled for the second standalone-DT-only FSM',
);
ok(
    !exists $hdl_gen->{lhs_assignments}->{OUTA},
    'second generation clears first-run lhs_assignments data',
);
ok(
    exists $hdl_gen->{lhs_assignments}->{OUTB},
    'second generation records second-run lhs_assignments data',
);
ok(
    !exists $hdl_gen->{assignment_analysis}->{OUTA},
    'second generation clears first-run assignment analysis',
);
ok(
    exists $hdl_gen->{assignment_analysis}->{OUTB},
    'second generation records second-run assignment analysis',
);
unlike(
    $hdl_two,
    qr/\bOUTA\b/,
    'second generated HDL does not leak first-run signal names',
);
like(
    $hdl_two,
    qr/\bOUTB\b/,
    'second generated HDL includes second-run signal names',
);
like(
    $hdl_two,
    qr/\bassign\s+beta_dt_en\s*=\s*1'b1\s*;/,
    'second generation emits only the second standalone DT enable',
);

done_testing();

sub parse_fsm_module {
    my ($adapter, $path, $content) = @_;
    write_file($path, $content);
    my $raw_ast = Lispish::multi($path);
    return $adapter->parse_fsm($raw_ast);
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
