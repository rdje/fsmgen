#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Spec;
use FSM::Composition::Top;

sub expected_snapshot {
    return {
        embedded_fsm_sources => {
            child => ['?fsm:child', ['idle']],
        },
        embedded_dt_sources => {
            route => ['?dt:route', ['-route']],
        },
        embedded_package_sources => {
            types_pkg => ['?pkg:types_pkg', ['+types']],
        },
        raw_ast => ['?top:top', ['?fsmc:child']],
    };
}

sub make_spec {
    my %args = %{expected_snapshot()};
    return FSM::Composition::Spec->new(
        top => FSM::Composition::Top->new(name => 'top'),
        %args,
    );
}

sub snapshot {
    my ($spec) = @_;
    return {
        embedded_fsm_sources => $spec->embedded_fsm_sources,
        embedded_dt_sources => $spec->embedded_dt_sources,
        embedded_package_sources => $spec->embedded_package_sources,
        raw_ast => $spec->raw_ast,
    };
}

subtest 'Spec constructor copies mutable embedded-source containers' => sub {
    my %args = %{expected_snapshot()};
    my $top = FSM::Composition::Top->new(name => 'top');
    my $spec = FSM::Composition::Spec->new(
        top => $top,
        %args,
    );

    $args{embedded_fsm_sources}{child}[1][0] = 'mutated';
    $args{embedded_dt_sources}{route}[1][0] = 'mutated';
    $args{embedded_package_sources}{types_pkg}[1][0] = 'mutated';
    $args{raw_ast}[1][0] = '?mutated';

    is($spec->top, $top, 'top accessor preserves the owned parsed top object');
    is_deeply(snapshot($spec), expected_snapshot(), 'composition spec containers are isolated from constructor mutation');
};

subtest 'Spec accessors return caller-owned embedded-source containers' => sub {
    my $spec = make_spec();

    my $embedded_fsm_sources = $spec->embedded_fsm_sources;
    $embedded_fsm_sources->{child}[1][0] = 'mutated';

    my $embedded_dt_sources = $spec->embedded_dt_sources;
    $embedded_dt_sources->{route}[1][0] = 'mutated';

    my $embedded_package_sources = $spec->embedded_package_sources;
    $embedded_package_sources->{types_pkg}[1][0] = 'mutated';

    my $raw_ast = $spec->raw_ast;
    $raw_ast->[1][0] = '?mutated';

    is_deeply(snapshot($spec), expected_snapshot(), 'composition spec containers are isolated from accessor mutation');
};

done_testing;
