#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::HDLGeneratorResolvedPackageImportsContract qw(build_hdl_generator_resolved_package_imports_contract);
my $sentinel = '__resolved_package_imports_contract_full_surface_mutation__';

subtest 'resolved package imports contract full surface rebuilds cleanly' => sub {
    my $first = build_hdl_generator_resolved_package_imports_contract();
    mutate_structure($first);
    my $second = build_hdl_generator_resolved_package_imports_contract();
    my $expected = build_hdl_generator_resolved_package_imports_contract();
    is_deeply($second, $expected, 'fresh resolved package imports contract rebuilds clean full surface');
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
