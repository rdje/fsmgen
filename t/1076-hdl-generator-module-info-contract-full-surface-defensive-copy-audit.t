#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::HDLGeneratorModuleInfoContract qw(build_hdl_generator_module_info_contract);
my $sentinel = '__hdl_generator_module_info_contract_full_surface_mutation__';

subtest 'HDLGenerator module info contract full surface rebuilds cleanly' => sub {
    my $first = build_hdl_generator_module_info_contract();
    mutate_structure($first);
    my $second = build_hdl_generator_module_info_contract();
    my $expected = build_hdl_generator_module_info_contract();
    is_deeply($second, $expected, 'fresh module info contract rebuilds clean full surface');
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
