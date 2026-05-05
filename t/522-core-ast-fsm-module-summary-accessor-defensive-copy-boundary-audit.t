#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

subtest 'FSMModule summary accessors return isolated mutable containers' => sub {
    my $module = FSM::CoreAST::FSMModule->new(
        name => 'summary_boundary',
        attributes => {
            system_contract => {
                clock => 'clk',
                reset => 'rst_n',
                metadata => {
                    reset_policy => 'async_low',
                },
            },
            package_imports => [qw(pkg_a pkg_b)],
        },
    );

    my $first_contract = $module->explicit_system_contract;
    my $first_imports = $module->package_imports;

    $first_contract->{clock} = 'mutated_clk';
    $first_contract->{metadata}{reset_policy} = 'mutated_policy';
    push @$first_imports, 'mutated_pkg';

    is_deeply(
        $module->explicit_system_contract,
        {
            clock => 'clk',
            reset => 'rst_n',
            metadata => {
                reset_policy => 'async_low',
            },
        },
        'mutating explicit_system_contract accessor output does not alter module state',
    );
    is_deeply(
        $module->package_imports,
        [qw(pkg_a pkg_b)],
        'mutating package_imports accessor output does not alter module state',
    );

    isnt(
        $module->explicit_system_contract,
        $module->explicit_system_contract,
        'explicit_system_contract returns a fresh hash each time',
    );
    isnt(
        $module->package_imports,
        $module->package_imports,
        'package_imports returns a fresh array each time',
    );
};

done_testing();
