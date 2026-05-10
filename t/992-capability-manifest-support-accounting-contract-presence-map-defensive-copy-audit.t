#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SupportAccountingContract qw(build_support_accounting_contract);
my $sentinel = '__manifest_support_accounting_mutation__';

subtest 'manifest support accounting contract presence key family map rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{support_accounting}{section_contract};
    mutate_structure($mutated->{'presence_key_family_map'});

    my $second = build_capability_manifest();
    my $contract = $second->{support_accounting}{section_contract};
    my $expected = build_support_accounting_contract();
    is_deeply($contract->{'presence_key_family_map'}, $expected->{'presence_key_family_map'}, 'fresh manifest support accounting contract rebuilds clean presence_key_family_map');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
