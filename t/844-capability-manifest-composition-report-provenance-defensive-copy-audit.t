#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CompositionReportContract qw(build_composition_report_contract);
my $sentinel = '__manifest_composition_report_mutation__';

subtest 'manifest-embedded composition report tested_by and guidance lists rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{composition_report};
    mutate_structure($mutated->{'tested_by'});
    mutate_structure($mutated->{'guidance'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{composition_report};
    my $expected = build_composition_report_contract();
    is_deeply($contract->{'tested_by'}, $expected->{'tested_by'}, 'fresh manifest composition report rebuilds clean tested_by');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'fresh manifest composition report rebuilds clean guidance');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
