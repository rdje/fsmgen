#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Backend;
use FSM::Template;

subtest 'backend options are isolated from constructor and accessor mutation' => sub {
    my $constructor_options = {
        nested => {
            mode => 'strict',
            families => ['sv'],
        },
    };
    my $backend = FSM::Backend::SystemVerilog->new(options => $constructor_options);

    $constructor_options->{nested}{mode} = 'mutated';
    push @{$constructor_options->{nested}{families}}, 'late';

    is_deeply(
        $backend->get_option('nested'),
        {
            mode => 'strict',
            families => ['sv'],
        },
        'constructor options are copied into backend state',
    );

    my $options = $backend->options;
    $options->{nested}{mode} = 'mutated';
    push @{$options->{nested}{families}}, 'late';
    $options->{late} = 1;

    is_deeply(
        $backend->options->{nested},
        {
            mode => 'strict',
            families => ['sv'],
        },
        'options accessor returns a fresh options snapshot',
    );
    ok(!exists $backend->options->{late}, 'new option keys do not enter backend state through options accessor');
};

subtest 'set_option and get_option use caller-owned structured values' => sub {
    my $backend = FSM::Backend::Base->new(
        template_engine => FSM::Template::create_template_engine('systemverilog'),
    );
    my $value = {
        flags => ['a'],
    };

    $backend->set_option('structured', $value);
    $value->{flags}[0] = 'mutated';

    my $first = $backend->get_option('structured');
    $first->{flags}[0] = 'mutated';

    is_deeply(
        $backend->get_option('structured'),
        {
            flags => ['a'],
        },
        'set_option stores and get_option returns structured option snapshots',
    );

    my $default = {
        flags => ['default'],
    };
    my $returned_default = $backend->get_option('missing', $default);
    $returned_default->{flags}[0] = 'mutated';
    is_deeply($default, { flags => ['default'] }, 'get_option returns a copy of structured defaults');
};

done_testing;
