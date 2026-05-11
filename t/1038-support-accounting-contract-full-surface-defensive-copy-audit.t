#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::SupportAccountingContract qw(build_support_accounting_contract);
my $sentinel = '__support_accounting_contract_full_surface_mutation__';

subtest 'support accounting contract full surface rebuilds cleanly' => sub {
    my $first = build_support_accounting_contract();
    mutate_structure($first);
    my $second = build_support_accounting_contract();
    my $expected = build_support_accounting_contract();
    is_deeply($second, $expected, 'fresh support accounting contract rebuilds clean full surface');
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
