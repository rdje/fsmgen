#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

subtest 'SignalRef slice containers are owned by the reference' => sub {
    my $signal = FSM::CoreAST::Signal->new(name => 'DATA', width => 8);
    my $slice = [7, 4];
    my $ref = FSM::CoreAST::SignalRef->new($signal, slice => $slice);

    $slice->[0] = 3;
    push @$slice, 0;

    is_deeply($ref->slice, [7, 4], 'constructor slice mutation cannot contaminate signal reference');
    is($ref->signal, $signal, 'referenced signal object identity is preserved');

    my $slice_view = $ref->slice;
    $slice_view->[1] = 2;
    push @$slice_view, 'mutated_output';

    is_deeply($ref->slice, [7, 4], 'slice accessor returns a fresh list container');
    is($ref->to_verilog, 'DATA[7:4]', 'Verilog rendering still reads the owned slice');
    is($ref->to_vhdl, 'DATA(7 downto 4)', 'VHDL rendering still reads the owned slice');
};

subtest 'unsliced SignalRef keeps undef slice identity' => sub {
    my $signal = FSM::CoreAST::Signal->new(name => 'READY');
    my $ref = FSM::CoreAST::SignalRef->new($signal);

    is($ref->slice, undef, 'unsliced reference reports undef slice');
    is($ref->to_systemverilog, 'READY', 'unsliced SystemVerilog rendering is unchanged');
};

done_testing();
