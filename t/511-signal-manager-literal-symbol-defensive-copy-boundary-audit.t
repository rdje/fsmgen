#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::CoreAST;

subtest 'constant literal storage and lookup are caller-owned' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
    my $literal = FSM::CoreAST::Literal->new('A5', width => 8, radix => 'hex');

    $signal_manager->store_constant('BYTE', $literal);
    $literal->{value} = '00';
    $literal->{width} = 1;
    $literal->{radix} = 'binary';

    is(
        $signal_manager->resolve_symbol('BYTE')->to_systemverilog,
        q{8'hA5},
        'constant expression lookup reads from stored literal snapshot',
    );
    is_deeply(
        $signal_manager->resolve_parameter_value_symbol_payload('BYTE'),
        {
            kind => 'scalar',
            payload => q{8'hA5},
        },
        'constant parameter payload lookup reads from stored literal snapshot',
    );
    is($signal_manager->resolve_positive_integer_scalar('BYTE'), 165, 'constant width scalar lookup reads from stored literal snapshot');

    my $resolved = $signal_manager->resolve_symbol('BYTE');
    $resolved->{value} = '00';
    $resolved->{width} = 1;
    $resolved->{radix} = 'binary';

    is(
        $signal_manager->resolve_symbol('BYTE')->to_systemverilog,
        q{8'hA5},
        'constant expression lookup returns a fresh literal',
    );
    is_deeply(
        $signal_manager->resolve_parameter_value_symbol_payload('BYTE'),
        {
            kind => 'scalar',
            payload => q{8'hA5},
        },
        'constant parameter payload lookup is not affected by resolved literal mutation',
    );
};

subtest 'define literal storage and lookup are caller-owned' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
    my $literal = FSM::CoreAST::Literal->new('1010', width => 4, radix => 'binary');

    $signal_manager->store_define('MASK', $literal);
    $literal->{value} = '0000';

    is(
        $signal_manager->resolve_symbol('MASK')->to_systemverilog,
        q{4'b1010},
        'define expression lookup reads from stored literal snapshot',
    );
    is_deeply(
        $signal_manager->resolve_parameter_value_symbol_payload('MASK'),
        {
            kind => 'scalar',
            payload => q{4'b1010},
        },
        'define parameter payload lookup reads from stored literal snapshot',
    );

    my $resolved = $signal_manager->resolve_symbol('MASK');
    $resolved->{value} = '1111';

    is(
        $signal_manager->resolve_symbol('MASK')->to_systemverilog,
        q{4'b1010},
        'define expression lookup returns a fresh literal',
    );
};

done_testing;
